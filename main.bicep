targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('SQL Server admin login.')
param sqlAdminLogin string

@description('SQL Server admin password.')
@secure()
param sqlAdminPassword string

module sql 'modules/sqlServer.bicep' = {
  name: 'sqlServerDeployment'
  params: {
    location: location
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}
module storage 'modules/storageAccounts.bicep' = {
  name: 'storageAccountsDeployment'
  params: {
    location: location
  }
}
module staticWebApp 'modules/staticWebApp.bicep' = {
  name: 'staticWebAppDeployment'
}

 module apiAppService 'modules/apiAppService.bicep' = {
  name: 'apiAppServiceDeployment'
  params: {
    location: location
  }
}

output sqlServerFqdn string = sql.outputs.sqlServerFqdn
