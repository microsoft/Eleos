from helper.azure_config import AzureConfig

import json
from langchain.chains import create_history_aware_retriever
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains.retrieval import create_retrieval_chain
from langchain.memory import ConversationBufferWindowMemory
from langchain_community.chat_message_histories.cosmos_db import CosmosDBChatMessageHistory
from langchain_community.vectorstores.azuresearch import AzureSearch
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_core.prompts.chat import ChatPromptTemplate, MessagesPlaceholder, PromptTemplate
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_openai import AzureChatOpenAI, AzureOpenAIEmbeddings

class ChatService:
    def __init__(self, config: AzureConfig, user_id: str, session_id: str):
        self.store = {}
        self.user_id = user_id
        self.session_id = session_id
        self.cosmos_db = CosmosDBChatMessageHistory(
                cosmos_endpoint=config.history_store_address,
                cosmos_database=config.history_store_database,
                cosmos_container=config.history_store_container,
                session_id=session_id,
                user_id=user_id,
                connection_string=config.history_connection_string             
        )

        self.embeddings: AzureOpenAIEmbeddings = AzureOpenAIEmbeddings(
            azure_deployment=config.azure_emdedding_deployment,
            openai_api_version=config.azure_openai_api_version,
            azure_endpoint=config.azure_endpoint,
            api_key=config.azure_openai_api_key,
        )
        index_name: str = config.index_name
        self.vector_store: AzureSearch = AzureSearch(
            azure_search_endpoint=config.vector_store_address,
            azure_search_key=config.vector_store_password,
            index_name=index_name,
            embedding_function=self.embeddings.embed_query,
        )
        self.llm: AzureChatOpenAI = AzureChatOpenAI(
            temperature=0.3,
            azure_deployment=config.azure_deployment,
            openai_api_version=config.azure_openai_api_version,
            azure_endpoint=config.azure_endpoint,
            api_key=config.azure_openai_api_key,
        )
        self.system_prompt = """You are an agent helping developers find API endpoints to build their applications.
                    You will reply with the path to an endpoint or a set of endpoints that will answer the user's question.
                    You should reply with usage instructions in JSON format with a text field
                    Within the instructions will be implementation and a portal as just content
                    portal_url=https://apim-deveportal.contoso.com/api-details#api=api=patients-api&operation=sendMessage
                    Do not return with ```JSON```
                    Do not make up any endpoints. If you are not sure about the answer, say \"I don't know\".
                    Include the order in which the endpoints should be used if there are multiple endpoint calls needed. Ej.Option1, Option2, etc.
                    Do not include any language that is not necessary to make the API call.       
                   
                   Example:
                    Question:How do I find claim status

                        "text" : "Claim status can be found with the endpoint /claims-api/v1/status
                                option 1 Make a POST request to /claims-api/v1/status 
                                            body: claim_id = 1234
                                endpoint https://localhost:3000/ClaimService/claims-api/v1/status
                                portal_url https://apim-deveportal.contoso.com/api-details#api=api=claims-api&operation=status

                                option 2 Make a POST request to /claims-api/v1/somethingelse
                                            body: claim_id = 1234
                                endpoint: https://localhost:3000/ClaimService/claims-api/v1/somethingelse
                                portal_url: https://apim-deveportal.contoso.com/api-details#api=api=claims-api&operation=somethingelse"
                       
                    
                    SOURCES:
                    {context}
                    """

        self.prompt = ChatPromptTemplate.from_messages(
            [
                ("system", self.system_prompt),
                MessagesPlaceholder("chat_history"),
                ("human", "{input}"),
            ]
        )
        self.contextualize_system_prompt = """Given a chat history and the latest user question
            which might reference context in the chat history, formulate a standalone question
            which can be understood without the chat history. Do NOT answer the question,
            just reformulate it if needed and otherwise return it as is.
            """
        self.contextualize_prompt = ChatPromptTemplate.from_messages(
        [
            ("system", self.contextualize_system_prompt),
            MessagesPlaceholder("chat_history"),
            ("human", "{input}"),
        ]
        )
        self.history_aware_retriever = create_history_aware_retriever(
            self.llm, 
            self.vector_store.as_retriever(), 
            self.contextualize_prompt
        )
        self.question_answer_chain = create_stuff_documents_chain(
            llm=self.llm,
            prompt=self.prompt,
            document_prompt=PromptTemplate.from_template('{page_content}\n')
        )
        self.rag_chain = create_retrieval_chain(self.history_aware_retriever, self.question_answer_chain)
       
        self.conversational_rag_chain = RunnableWithMessageHistory(         
            self.rag_chain,
            self.get_session_history,                        
            input_messages_key="input",
            history_messages_key="chat_history",
            output_messages_key="answer",
        )


    def chat(self, user_msg: str) -> str:
        response=self.conversational_rag_chain.invoke(
            {
                "input": user_msg
            },
            config={
                "configurable":
                    {
                        "session_id": self.session_id
                    }
                }
            )

        self.save_current_session(self.session_id)

        return response["answer"]


    async def chat_streaming(self, user_msg: str): # -> IterableReadableStream<RunOutput>:
        input = json.dumps({
                "input": user_msg
                }, config={
                    "configurable":
                    {
                        "session_id": self.session_id
                    }
                })
        
        async for chunk in self.conversational_rag_chain.astream(input):
            yield chunk

        self.save_current_session(self.session_id)

    def get_session_history(self, session_id: str) -> InMemoryChatMessageHistory:        
        if session_id not in self.store: 
            history =  self.load_session_history()                              
            if len(history.messages) == 0:
                self.store[session_id]=InMemoryChatMessageHistory()  #load_session_history()
                return self.store[session_id]
            else:
                self.store[session_id]=InMemoryChatMessageHistory(messages=history.messages)
                return self.store[session_id]
        memory = ConversationBufferWindowMemory(
            chat_memory=self.store[session_id],
            k=5,
            return_messages=True,
        )
        assert len(memory.memory_variables) == 1
        key = memory.memory_variables[0]
        messages = memory.load_memory_variables({})[key]
        self.store[session_id] = InMemoryChatMessageHistory(messages=messages)
        return self.store[session_id]


    def load_session_history(self) -> CosmosDBChatMessageHistory: 
        self.cosmos_db.prepare_cosmos()      
        self.cosmos_db.load_messages()  
        return self.cosmos_db


    def save_current_session(self, session_id: str): 
        self.cosmos_db.prepare_cosmos()  
        messages_to_add = self.store[session_id].messages
        self.cosmos_db.load_messages()
        if(len(self.cosmos_db.messages) > 0):
            self.cosmos_db.clear()
        self.cosmos_db.add_messages(messages_to_add)
