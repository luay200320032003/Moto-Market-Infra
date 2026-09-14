// functionApp.bicep
// Deploys the Function App used for sync jobs. Runs on the SAME shared
// App Service Plan (Basic B1) as the API App Service — confirmed via
// `az resource list` that only one serverfarm exists in this resource group.
// Storage account (motomarketblob) is referenced, not created here —
// see storageAccounts.bicep for that resource.

@description('Azure region for the Function App.')
param location string = resourceGroup().location

@description('Name of the Function App.')
param functionAppName string = 'moto-market-sync-function'

@description('Name of the existing shared App Service Plan (also used by the API App Service).')
param existingAppServicePlanName string = 'ASP-MotoMarketResourceGroup-b8e1'

@description('Name of the storage account used by this Function App for internal operations.')
param storageAccountName string = 'motomarketblob'

@description('.NET isolated runtime version.')
param dotnetVersion string = 'DOTNET-ISOLATED|8.0'

// Reference the existing storage account (defined in storageAccounts.bicep)
// so we can build the connection string without hardcoding the key.
resource existingStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Reference the existing shared App Service Plan — NOT creating a new one.
resource existingAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' existing = {
  name: existingAppServicePlanName
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: existingAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: dotnetVersion
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorage.name};AccountKey=${existingStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
      ]
    }
  }
}

output functionAppId string = functionApp.id
output functionAppDefaultHostname string = functionApp.properties.defaultHostName
