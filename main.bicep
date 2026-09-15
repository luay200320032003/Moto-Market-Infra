targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('SQL Server admin login.')
param sqlAdminLogin string

@description('SQL Server admin password.')
@secure()
param sqlAdminPassword string

@description('Storage account key for the backups storage account, used by the Logic App export action.')
@secure()
param backupsStorageKey string

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

module functionApp 'modules/functionApp.bicep' = {
  name: 'functionAppDeployment'
  params: {
    location: location
  }
}
module logicApp 'modules/logicApp.bicep' = {
  name: 'logicAppDeployment'
  params: {
    location: location
    sqlAdminPassword: sqlAdminPassword
    backupsStorageKey: backupsStorageKey
  }
}

module dnsZone 'modules/dnsZone.bicep' = {
  name: 'dnsZoneDeployment'
  params: {
    staticWebAppId: staticWebApp.outputs.staticWebAppId
    staticWebAppDefaultHostname: staticWebApp.outputs.staticWebAppDefaultHostname
  }
}

@description('Object ID of the admin user for Key Vault RBAC access.')
param adminPrincipalId string

module keyVault 'modules/keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    adminPrincipalId: adminPrincipalId
  }
}

output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output dnsNameServers array = dnsZone.outputs.nameServers
