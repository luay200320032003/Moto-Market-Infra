// apiAppService.bicep
// Deploys the App Service Plan and Web App hosting the Motos Marketplace API.

@description('Azure region for the App Service resources.')
param location string = resourceGroup().location

@description('Name of the App Service Plan.')
param appServicePlanName string = 'ASP-MotoMarketResourceGroup-b8e1'

@description('Name of the API Web App.')
param apiAppServiceName string = 'Moto-Market-API-App-Service'

@description('App Service Plan SKU tier.')
param skuTier string = 'Basic'

@description('App Service Plan SKU name/size.')
param skuName string = 'B1'

@description('.NET runtime version for the Linux App Service.')
param dotnetVersion string = 'DOTNETCORE|8.0'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'linux'
  properties: {
    reserved: true // required for Linux plans
  }
}

resource apiAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: apiAppServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: dotnetVersion
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
    httpsOnly: true
  }
}

output appServicePlanId string = appServicePlan.id
output apiAppServiceId string = apiAppService.id
output apiAppServiceDefaultHostname string = apiAppService.properties.defaultHostName
