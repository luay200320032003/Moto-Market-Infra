// storageAccounts.bicep
// Deploys the two existing storage accounts:
//   - motomarketbackups: private, used for SQL BACPAC exports
//   - motomarketblob: app storage (webjobs, function releases, listing images)

@description('Azure region for the backups storage account (motomarketbackups).')
param location string = resourceGroup().location

@description('Azure region for the app/blob storage account (motomarketblob). This account was originally created in East US and is kept there to avoid a destructive recreate.')
param blobStorageLocation string = 'eastus'

@description('Name of the backups storage account. Must be globally unique, lowercase, no dashes.')
param backupsStorageAccountName string = 'motomarketbackups'

@description('Name of the app/blob storage account. Must be globally unique, lowercase, no dashes.')
param blobStorageAccountName string = 'motomarketblob'

// -------------------------------------------------------------------------
// motomarketbackups — private storage for database backups
// -------------------------------------------------------------------------
resource backupsStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: backupsStorageAccountName
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource backupsBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: backupsStorage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource dbBackupContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: backupsBlobService
  name: 'dbbackup'
  properties: {
    publicAccess: 'None'
  }
}

// -------------------------------------------------------------------------
// motomarketblob — app storage: webjobs, function releases, listing images
// -------------------------------------------------------------------------
resource blobStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: blobStorageAccountName
  location: blobStorageLocation
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true // required: listing-images container is public
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobServiceDefault 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: blobStorage
  name: 'default'
}

resource listingImagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServiceDefault
  name: 'listing-images'
  properties: {
    publicAccess: 'Blob' // public read access for individual blobs, matches existing config
  }
}

resource azureWebjobsHostsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServiceDefault
  name: 'azure-webjobs-hosts'
  properties: {
    publicAccess: 'None'
  }
}

resource azureWebjobsSecretsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServiceDefault
  name: 'azure-webjobs-secrets'
  properties: {
    publicAccess: 'None'
  }
}

resource functionReleasesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServiceDefault
  name: 'function-releases'
  properties: {
    publicAccess: 'None'
  }
}

resource scmReleasesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServiceDefault
  name: 'scm-releases'
  properties: {
    publicAccess: 'None'
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------
output backupsStorageAccountId string = backupsStorage.id
output backupsStorageAccountName string = backupsStorage.name
output blobStorageAccountId string = blobStorage.id
output blobStorageAccountName string = blobStorage.name
