import json
import logging
import azure.functions as func 
from flask import json, jsonify
from helper.azure_config import AzureConfig
from langchain_community.vectorstores.azuresearch import AzureSearch
from langchain_openai import AzureOpenAIEmbeddings, AzureChatOpenAI
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains.retrieval import create_retrieval_chain
from langchain_core.prompts.chat import ChatPromptTemplate, PromptTemplate, MessagesPlaceholder
from langchain_community.chat_message_histories.cosmos_db import CosmosDBChatMessageHistory
from langchain.memory import ConversationBufferWindowMemory
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain.chains import create_history_aware_retriever
from langchain_core.chat_history import BaseChatMessageHistory, InMemoryChatMessageHistory


chatpost = func.Blueprint() 
session_id = "abc123"
store={}

@chatpost.route(route="chat-post", auth_level=func.AuthLevel.FUNCTION)
def postChat(req: func.HttpRequest) -> func.HttpResponse:    
    logging.info('Python HTTP trigger function processed a request.')
    request_body = req.get_json()
    user_question = request_body.get('messages')
    if not user_question or len(user_question) == 0:
        return func.HttpResponse(json.dumps({'error': 'Invalid or missing messages in the request body'}),
                                 status_code=400)
    
    config = AzureConfig()

    embeddings: AzureOpenAIEmbeddings = AzureOpenAIEmbeddings(
        azure_deployment=config.azure_emdedding_deployment,
        openai_api_version=config.azure_openai_api_version,
        azure_endpoint=config.azure_endpoint,
        api_key=config.azure_openai_api_key,
    )

    index_name: str = config.index_name
    vector_store: AzureSearch = AzureSearch(
        azure_search_endpoint=config.vector_store_address,
        azure_search_key=config.vector_store_password,
        index_name=index_name,
        embedding_function=embeddings.embed_query,
    )

    llm: AzureChatOpenAI = AzureChatOpenAI(
        temperature=0.3,
        azure_deployment=config.azure_deployment,
        openai_api_version=config.azure_openai_api_version,
        azure_endpoint=config.azure_endpoint,
        api_key=config.azure_openai_api_key,
    )

    system_prompt = """You are an agent helping developers find API endpoints to build their applications.
                    You will reply with the path to an endpoint or a set of endpoints that will answer the user's question.
                    You should reply in JSON format and include summary, description, url:url+path and portal_url=https://some.url.com?api=patients-api&operation=sendMessage of the API.
                    Do not make up any endpoints. If you are not sure about the answer, say \"I don't know\".
                    Include the order in which the endpoints should be used if there are multiple endpoint calls needed. Ej.Step1, Step2, etc.
                    Do not include any language that is not necessary to make the API call.       
    SOURCES:
    {context}
    """

    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            MessagesPlaceholder("chat_history"),
            ("human", "{input}"),
        ]
    )

    contextualize_system_prompt = """Given a chat history and the latest user question
    which might reference context in the chat history, formulate a standalone question
    which can be understood without the chat history. Do NOT answer the question,
    just reformulate it if needed and otherwise return it as is.
    """

    contextualize_prompt = ChatPromptTemplate.from_messages(
        [
            ("system", contextualize_system_prompt),
            MessagesPlaceholder("chat_history"),
            ("human", "{input}"),
        ]
    )

    history_aware_retriever = create_history_aware_retriever(
         llm, 
         vector_store.as_retriever(), 
         contextualize_prompt
    )

    question_answer_chain = create_stuff_documents_chain(
        llm=llm,
        prompt=prompt,
        document_prompt=PromptTemplate.from_template('{page_content}\n')
    )
    rag_chain = create_retrieval_chain(history_aware_retriever, question_answer_chain)
    
    conversational_rag_chain = RunnableWithMessageHistory(         
        rag_chain,
        get_session_history,                        
        input_messages_key="input",
        history_messages_key="chat_history",
        output_messages_key="answer",
    )

    response=conversational_rag_chain.invoke(
         {"input": user_question},
            config={"configurable":{"session_id": session_id}}
         )

    save_all_sessions()

    return response["answer"]

def get_session_history(session_id: str) -> InMemoryChatMessageHistory:        
    if session_id not in store:                                     
        store[session_id] = InMemoryChatMessageHistory()
        return store[session_id]
    
    memory = ConversationBufferWindowMemory(
        chat_memory=store[session_id],
        k=3,
        return_messages=True,
    )
    assert len(memory.memory_variables) == 1
    key = memory.memory_variables[0]
    messages = memory.load_memory_variables({})[key]
    store[session_id] = InMemoryChatMessageHistory(messages=messages)

    return store[session_id]


def load_session_history(session_id: str) -> CosmosDBChatMessageHistory:      
    cosmos_db: CosmosDBChatMessageHistory = CosmosDBChatMessageHistory(
            cosmos_endpoint=history_store_address,
            cosmos_database=history_store_database,
            cosmos_container=history_store_container,
            session_id=session_id,
            user_id="user123",
            # credential=history_store_password
            connection_string=history_connection_string             
        )
    cosmos_db.prepare_cosmos()      
    cosmos_db = cosmos_db.load_messages()  
    return cosmos_db

def save_all_sessions():
    cosmos_db: CosmosDBChatMessageHistory = CosmosDBChatMessageHistory(
            cosmos_endpoint=history_store_address,
            cosmos_database=history_store_database,
            cosmos_container=history_store_container,
            session_id=session_id,
            user_id="user123",
            # credential=history_store_password
            connection_string=history_connection_string             
        )
    cosmos_db.prepare_cosmos()  
   
    for message in store[session_id].messages:        
        cosmos_db.add_message(message)




async def create_json_stream(chunks):
    for chunk in chunks:
        if not chunk['answer']:
            continue

        response_chunk = {
            'delta': {
                'content': chunk['answer'],
                'role': 'assistant',
            }
        }

        yield json.dumps(response_chunk) + '\n'

