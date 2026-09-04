@description('Azure region for the SQL resources.')
param location string = resourceGroup().location

@description('Name of the logical SQL server. Must be globally unique.')
param sqlServerName string = 'moto-market-sql-server'

@description('Name of the database.')
param sqlDatabaseName string = 'MotoMarketDB'

@description('SQL Server admin login username.')
param sqlAdminLogin string

@description('SQL Server admin password. Pass via Key Vault reference or pipeline secret.')
@secure()
param sqlAdminPassword string

@description('Auto-pause delay in minutes for the serverless tier.')
param autoPauseDelayMinutes int = 60

@description('Max vCores for the serverless database.')
param maxVCores int = 1

@description('Min vCores for the serverless database.')
param minVCores string = '0.5'

@description('Allow Azure services to reach this server.')
param allowAzureServices bool = true

@description('Your current public IP, for local dev access. Leave empty to skip.')
param clientIpAddress string = ''

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: maxVCores
  }
  properties: {
    autoPauseDelay: autoPauseDelayMinutes
    minCapacity: json(minVCores)
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Geo'
  }
}

resource allowAzureServicesRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (allowAzureServices) {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource allowClientIpRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (!empty(clientIpAddress)) {
  parent: sqlServer
  name: 'AllowClientIp'
  properties: {
    startIpAddress: clientIpAddress
    endIpAddress: clientIpAddress
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlServerId string = sqlServer.id
output sqlDatabaseId string = sqlDatabase.id
