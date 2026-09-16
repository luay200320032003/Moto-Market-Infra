// appInsights.bicep
// Deploys Application Insights for the API App Service.
// Workspace-based (IngestionMode: LogAnalytics) — backed by the default Log
// Analytics workspace Azure auto-provisions in a separate resource group
// (DefaultResourceGroup-CCAN) the first time App Insights is created via the
// Portal's App Service "Application Insights" extension. That workspace is
// referenced by ID, not managed here.

@description('Azure region for Application Insights.')
param location string = resourceGroup().location

@description('Name of the Application Insights component. Matches the API App Service name, following the Portal convention for auto-created resources.')
param appInsightsName string = 'Moto-Market-API-App-Service'

@description('Resource ID of the Log Analytics workspace backing this workspace-based Application Insights instance.')
param logAnalyticsWorkspaceId string = '/subscriptions/fbfce0dc-2f0b-4054-9df4-6aeb55329767/resourceGroups/DefaultResourceGroup-CCAN/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-fbfce0dc-2f0b-4054-9df4-6aeb55329767-CCAN'

@description('Data retention, in days.')
param retentionInDays int = 90

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaWebAppExtensionCreate'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    RetentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output appInsightsId string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
