// logicApp.bicep
// Deploys the weekly SQL BACPAC export Logic App.
// IMPORTANT: sqlAdminPassword and storageKey are passed as secure params —
// never hardcode them here. Supply via pipeline variable group / Key Vault.

@description('Azure region for the Logic App.')
param location string = resourceGroup().location

@description('Name of the Logic App.')
param logicAppName string = 'MotoMarket-weekly-db-backup'

@description('SQL admin login used by the export action.')
param sqlAdminLogin string = 'MotoMarketDB'

@description('SQL admin password used by the export action.')
@secure()
param sqlAdminPassword string

@description('Storage account key for the backups storage account.')
@secure()
param backupsStorageKey string

@description('Subscription ID, used to build the SQL export API URL.')
param subscriptionId string = subscription().subscriptionId

@description('Resource group name, used to build the SQL export API URL.')
param resourceGroupName string = resourceGroup().name

@description('SQL server name.')
param sqlServerName string = 'moto-market-sql-server'

@description('SQL database name.')
param sqlDatabaseName string = 'MotoMarketDB'

@description('Backups storage account name.')
param backupsStorageAccountName string = 'motomarketbackups'

@description('Container name for backup files.')
param backupContainerName string = 'dbbackup'

@description('Windows time zone ID. Use "Central Standard Time" for US Central Time (not "Central America Standard Time").')
param timeZone string = 'Central Standard Time'

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Week'
            interval: 1
            schedule: {
              hours: [2]
              weekDays: ['Sunday']
            }
            timeZone: timeZone
          }
        }
      }
      actions: {
        HTTP: {
          type: 'Http'
          runAfter: {}
          inputs: {
            method: 'POST'
            uri: 'https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Sql/servers/${sqlServerName}/databases/${sqlDatabaseName}/export?api-version=2021-11-01'
            headers: {
              'Content-Type': 'application/json'
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://management.azure.com/'
            }
            body: {
              storageKeyType: 'StorageAccessKey'
              storageKey: backupsStorageKey
              storageUri: 'https://${backupsStorageAccountName}.blob.core.windows.net/${backupContainerName}/${sqlDatabaseName}-weekly-@{formatDateTime(utcNow(),\'yyyy-MM-dd\')}.bacpac'
              administratorLogin: sqlAdminLogin
              administratorLoginPassword: sqlAdminPassword
              authenticationType: 'SQL'
            }
          }
          runtimeConfiguration: {
            contentTransfer: {
              transferMode: 'Chunked'
            }
            secureData: {
              properties: ['inputs']
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}

output logicAppId string = logicApp.id
output logicAppPrincipalId string = logicApp.identity.principalId
