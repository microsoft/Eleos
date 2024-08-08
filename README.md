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

# Starting to work with Eleos

These instructions are a WIP. Please forgive the age old transgression of docs lagging way behind code.

These instructions presume a Windows development environment. You'll want
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure Function Core Tools CLI](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Python 3.11.x](https://docs.python.org/3.11/)
- [NPM](https://docs.npmjs.com/)
- [Node v20.x](https://nodejs.org/docs/v20.9.0/api/)

To get started, you'll want to azd up - this will populate your .env file in your .azure folder with all the necessary service values. Alternatively, if you're a glutton for punishment you can fill it out by hand - it currently looks like this:

```
API_BASE_URL=""
APPLICATIONINSIGHTS_CONNECTION_STRING=""
AZURE_COSMOS_CONNECTION_STRING_KEY=""
AZURE_COSMOS_DATABASE_NAME=""
AZURE_ENV_NAME=""
AZURE_KEY_VAULT_ENDPOINT=""
AZURE_KEY_VAULT_NAME=""
AZURE_LOCATION=""
AZURE_SUBSCRIPTION_ID=""
AZURE_TENANT_ID=""
REACT_APP_WEB_BASE_URL=""
SERVICE_API_ENDPOINTS=""
USE_APIM=""

AZURE_OPENAI_ENDPOINT=""
AZURE_OPENAI_API_KEY=""
AZURE_OPENAI_API_VERSION=""
AZURE_OPENAI_DEPLOYMENT_NAME=""
```
To run, you'll ctrl+shift+p > run tasks > Start API and Web
This will just run the projects... right now debugging is only one project at a time but you can layer them yourself by just starting to debug the other project while you're debugging whichever one you started debugging first. Read someone else explain it better [here](https://code.visualstudio.com/Docs/editor/debugging#_multitarget-debugging)

When trying to add new dependencies to the python azure function, I'd recommend using a terminal scoped to the /src/api directory and running the pip command like so:

```
./api_env/scripts/pip.exe install <...rest of your pip command here>
```

## todos
- add a compound configuration to debug both projects
- add swa cli to compound configuration

# Static React Web App + Functions with Python API and MongoDB on Azure

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/azure-samples/todo-python-mongo-swa-func)
[![Open in Dev Container](https://img.shields.io/static/v1?style=for-the-badge&label=Dev+Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/azure-samples/todo-python-mongo-swa-func)

A blueprint for getting a React web app with Python (FastAPI) API and a MongoDB database running on Azure. The frontend, currently a ToDo application, is designed as a placeholder that can easily be removed and replaced with your own frontend code. This architecture is for hosting static web apps with serverless logic and functionality.

Let's jump in and get this up and running in Azure. When you are finished, you will have a fully functional web app deployed to the cloud. In later steps, you'll see how to setup a pipeline and monitor the application.

!["Screenshot of deployed ToDo app"](assets/web.png)

<sup>Screenshot of the deployed ToDo app</sup>

### Prerequisites
> This template will create infrastructure and deploy code to Azure. If you don't have an Azure Subscription, you can sign up for a [free account here](https://azure.microsoft.com/free/). Make sure you have contributor role to the Azure subscription.

The following prerequisites are required to use this application. Please ensure that you have them all installed locally, or open the project in Github Codespaces or [VS Code](https://code.visualstudio.com/) with the [Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) where they will be installed automatically.

- [Azure Developer CLI](https://aka.ms/azd-install)
- [Azure Functions Core Tools (4+)](https://docs.microsoft.com/azure/azure-functions/functions-run-local)
- [Python (3.10+)](https://www.python.org/downloads/) - for the API backend

### Quickstart
To learn how to get started with any template, follow the steps in [this quickstart](https://learn.microsoft.com/azure/developer/azure-developer-cli/get-started?tabs=localinstall&pivots=programming-language-python) with this template(`Azure-Samples/todo-python-mongo-swa-func`).

This quickstart will show you how to authenticate on Azure, initialize using a template, provision infrastructure and deploy code on Azure via the following commands:

```bash
# Log in to azd. Only required once per-install.
azd auth login

# First-time project setup. Initialize a project in the current directory, using this template. 
azd init --template Azure-Samples/todo-python-mongo-swa-func

# Provision and deploy to Azure
azd up
```

### Application Architecture

This application utilizes the following Azure resources:

- [**Azure Static Web Apps**](https://docs.microsoft.com/azure/static-web-apps/) to host the Web frontend
- [**Azure Function Apps**](https://docs.microsoft.com/azure/azure-functions/) to host the API backend
- [**Azure Cosmos DB API for MongoDB**](https://docs.microsoft.com/azure/cosmos-db/mongodb/mongodb-introduction) for storage
- [**Azure Monitor**](https://docs.microsoft.com/azure/azure-monitor/) for monitoring and logging
- [**Azure Key Vault**](https://docs.microsoft.com/azure/key-vault/) for securing secrets

Here's a high level architecture diagram that illustrates these components. Notice that these are all contained within a single [resource group](https://docs.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal), that will be created for you when you create the resources.

!["Application architecture diagram"](assets/resources.png)

### Cost of provisioning and deploying this template
This template provisions resources to an Azure subscription that you will select upon provisioning them. Refer to the [Pricing calculator for Microsoft Azure](https://azure.microsoft.com/pricing/calculator/) to estimate the cost you might incur when this template is running on Azure and, if needed, update the included Azure resource definitions found in `infra/main.bicep` to suit your needs.

### Application Code

This template is structured to follow the [Azure Developer CLI](https://aka.ms/azure-dev/overview). You can learn more about `azd` architecture in [the official documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create#understand-the-azd-architecture).

### Next Steps

At this point, you have a complete application deployed on Azure. But there is much more that the Azure Developer CLI can do. These next steps will introduce you to additional commands that will make creating applications on Azure much easier. Using the Azure Developer CLI, you can setup your pipelines, monitor your application, test and debug locally.

> Note: Needs to manually install [setup-azd extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azd) for Azure DevOps (azdo).

- [`azd pipeline config`](https://learn.microsoft.com/azure/developer/azure-developer-cli/configure-devops-pipeline?tabs=GitHub) - to configure a CI/CD pipeline (using GitHub Actions or Azure DevOps) to deploy your application whenever code is pushed to the main branch. 

- [`azd monitor`](https://learn.microsoft.com/azure/developer/azure-developer-cli/monitor-your-app) - to monitor the application and quickly navigate to the various Application Insights dashboards (e.g. overview, live metrics, logs)

- [Run and Debug Locally](https://learn.microsoft.com/azure/developer/azure-developer-cli/debug?pivots=ide-vs-code) - using Visual Studio Code and the Azure Developer CLI extension

- [`azd down`](https://learn.microsoft.com/azure/developer/azure-developer-cli/reference#azd-down) - to delete all the Azure resources created with this template 

- [Enable optional features, like APIM](./OPTIONAL_FEATURES.md) - for enhanced backend API protection and observability

### Additional `azd` commands

The Azure Developer CLI includes many other commands to help with your Azure development experience. You can view these commands at the terminal by running `azd help`. You can also view the full list of commands on our [Azure Developer CLI command](https://aka.ms/azure-dev/ref) page.

## Security

### Roles

This template creates a [managed identity](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview) for your app inside your Azure Active Directory tenant, and it is used to authenticate your app with Azure and other services that support Azure AD authentication like Key Vault via access policies. You will see principalId referenced in the infrastructure as code files, that refers to the id of the currently logged in Azure Developer CLI user, which will be granted access policies and permissions to run the application locally. To view your managed identity in the Azure Portal, follow these [steps](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/how-to-view-managed-identity-service-principal-portal).

### Key Vault

This template uses [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/general/overview) to securely store your Cosmos DB connection string for the provisioned Cosmos DB account. Key Vault is a cloud service for securely storing and accessing secrets (API keys, passwords, certificates, cryptographic keys) and makes it simple to give other Azure services access to them. As you continue developing your solution, you may add as many secrets to your Key Vault as you require.


## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
