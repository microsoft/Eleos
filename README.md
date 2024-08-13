---
page_type: sample
languages:
- azdeveloper
- python
- bicep
- typescript
- html
products:
- azure
- azure-cosmos-db
- azure-functions
- azure-monitor
- azure-pipelines
urlFragment: todo-python-mongo-swa-func
name: Static React Web App + Functions with Python API and MongoDB on Azure
description: A complete ToDo app with Python FastAPI and Azure Cosmos API for MongoDB for storage. Uses Azure Developer CLI (azd) to build, deploy, and monitor
---
<!-- YAML front-matter schema: https://review.learn.microsoft.com/en-us/help/contribute/samples/process/onboarding?branch=main#supported-metadata-fields-for-readmemd -->

# About

# Quickstart

## Prerequisites

These instructions presume a Windows development environment due to time constraints. Your mileage may vary on linux but there is nothing prohibitive about running the application on linux.
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure Function Core Tools CLI](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Python 3.11.x](https://docs.python.org/3.11/)
- [NPM](https://docs.npmjs.com/)
- [Node v20.x](https://nodejs.org/docs/v20.9.0/api/)

## With Azure Developer CLI

If you're not familiar with it, the Azure Developer CLI (linked above) can help you provision and deploy your code quickly and easily from the command line. It can work with existing resources - if you need to, see the next section. One awkward note, we were having some trouble configuring the expectation of where the .env file was so it is currently hardcoded to expect the environment name to be 'eleos' if you know how to configure this better, please submit the PR or make an issue.

1. Run _azd provision_ in the project root directory
2. Look up your [function app's function key](https://learn.microsoft.com/en-us/azure/azure-functions/security-concepts#function-access-keys) 
3. Run _azd env set AZURE_FUNCTION_KEY `<your function key here>`_ to add the function key to your Azure Developer CLI environment
4. Run _azd deploy_
5. Upload the documents in the data folder (or your own swagger documents) to the "swagger-docs" container in the ingeststore Azure Blob Storage instance.

Now your application should be running and the function app will spin up your index with the documents that you uploaded and you can start asking question from your Static Web App.

## Using Azure Developer CLI with existing resources

You'll want to use the _azd env set `key` `value`_ command for the environment variables corresponding to your existing resources. Once you've done that you can run azd provision normally.
```
APPLICATIONINSIGHTS_CONNECTION_STRING
AZURE_AISEARCH_ENDPOINT
AZURE_AISEARCH_INDEX_NAME
AZURE_AISEARCH_KEY
AZURE_BLOB_CONN_STR
AZURE_BLOB_STORAGE_INPUT_CONTAINER
AZURE_BLOB_STORAGE_KEY
AZURE_BLOB_STORAGE_OUTPUT_CONTAINER
AZURE_BLOB_STORAGE_URL
AZURE_COSMOSDB_CONNECTION_STRING
AZURE_COSMOSDB_CONTAINER_NAME
AZURE_COSMOSDB_DATABASE_NAME
AZURE_COSMOSDB_ENDPOINT
AZURE_COSMOSDB_KEY
AZURE_ENV_NAME
AZURE_FUNCTION_ENDPOINT
AZURE_FUNCTION_KEY
AZURE_LOCATION
AZURE_OPENAI_API_DEPLOYMENT_NAME
AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME
AZURE_OPENAI_API_ENDPOINT
AZURE_OPENAI_API_KEY
AZURE_OPENAI_API_VERSION
AZURE_SUBSCRIPTION_ID
```

## Without the Azure Developer CLI

Due to time constraints, the application configuration expects the organization of the Azure Developer CLI, so you must create .azure/eleos/azure

You'll also need to ensure that your developer account and API (function app) has the following RBAC permissions.

- Azure AI Developer on the Azure Open AI resource
- Storage Blob Data Contributor on the ingestion Azure Storage instance
- Search Index Data Contributor on the AI Search resource

Then you'll need to deploy. Depending on the permissiveness of your Azure environment you might be able to use the right+click deploy options off the Azure extensions ([SWA](https://learn.microsoft.com/en-us/shows/docs-azure/deploy-static-website-to-azure-from-visual-studio-code), [Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-develop-vs-code?tabs=node-v4%2Cpython-v2%2Cisolated-process%2Cquick-create&pivots=programming-language-python#republish-project-files))


To run, you'll ctrl+shift+p > run tasks > Start API and Web
This will just run the projects... right now debugging is only one project at a time but you can layer them yourself by just starting to debug the other project while you're debugging whichever one you started debugging first. Read someone else explain it better [here](https://code.visualstudio.com/Docs/editor/debugging#_multitarget-debugging). 

## Running Locally

You can use the standard Ctrl+F5 for debugging the python application. For the web, currently the best configuration is using your command palette to run the `Start Web` task. You can run them side by side and take advantage of the browser dev tools to debug the front end code.

When trying to add new dependencies to the python azure function, I'd recommend using a terminal in the /src/api directory and running the pip command like so:

```
./api_env/scripts/pip.exe install <...rest of your pip command here>
```
Alternatively you can simply add the requirement to your requirements.txt and run the task for pip install.

# Future Nice-to-Haves
- resolve .env setting path to be based on azd environment name
- add a compound configuration to debug both projects
- add swa cli to compound configuration

# Architecture

## Provisioned Resources

todo

## Application Flow

todo

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

# Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
