import azure.functions as func 
from chat_post import chatpost
from index_trigger import indextrigger

app = func.FunctionApp() 

app.register_functions(chatpost) 
app.register_functions(indextrigger)