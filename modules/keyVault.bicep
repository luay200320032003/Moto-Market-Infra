// keyVault.bicep
// Deploys the Key Vault and its RBAC role assignments.
// Uses RBAC authorization (not the legacy access-policy model) — confirmed
// via `az keyvault show` that enableRbacAuthorization is already true.
//
// Secret VALUES are never declared here. Secrets are created/rotated
// out-of-band (Portal, CLI, or a separate secure pipeline step) — this
// module only manages the vault itself and who/what can read from it.

@description('Azure region for the Key Vault.')
param location string = resourceGroup().location

@description('Name of the Key Vault.')
param keyVaultName string = 'moto-market-keyvault'

@description('Azure AD tenant ID.')
param tenantId string = subscription().tenantId

@description('Object ID of the admin user/group that should have full secret management (Key Vault Secrets Officer).')
param adminPrincipalId string

@description('Name of the existing API App Service, used to look up its managed identity.')
param apiAppServiceName string = 'Moto-Market-API-App-Service'

@description('Name of the existing Function App, used to look up its managed identity.')
param functionAppName string = 'moto-market-sync-function'

// Reference existing app resources to pull their managed identity principal IDs,
// rather than hardcoding GUIDs that would silently go stale if the apps were
// ever recreated.
resource apiAppService 'Microsoft.Web/sites@2023-01-01' existing = {
  name: apiAppServiceName
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: functionAppName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Built-in role definition IDs (these are fixed GUIDs defined by Azure, not
// specific to this subscription):
//   Key Vault Secrets Officer: b86a8fe4-44ce-4948-aee5-eccb2c155cd7
//   Key Vault Secrets User:    4633458b-17de-408a-b874-0445c86b69e6
var secretsOfficerRoleId = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
var secretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource adminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, adminPrincipalId, secretsOfficerRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretsOfficerRoleId)
    principalId: adminPrincipalId
    principalType: 'User'
  }
}

resource apiAppServiceRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, apiAppService.id, secretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretsUserRoleId)
    principalId: apiAppService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, functionApp.id, secretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretsUserRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
