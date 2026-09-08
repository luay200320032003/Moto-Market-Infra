// staticWebApp.bicep
// Deploys the Static Web App hosting the Motos Marketplace frontend.
// Note: Static Web Apps have a limited set of supported regions, separate
// from where the rest of the infrastructure lives (Canada Central).

@description('Region for the Static Web App. Must be a region that supports Static Web Apps.')
param location string = 'East US 2'

@description('Name of the Static Web App.')
param staticWebAppName string = 'moto-market-ui-app-service'

@description('SKU tier for the Static Web App: Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param skuTier string = 'Free'

@description('Custom domain to attach to the Static Web App (root apex domain).')
param customDomainName string = 'motosmarketplace.com'

@description('Custom domain to attach to the Static Web App (www subdomain).')
param wwwDomainName string = 'www.motosmarketplace.com'

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: skuTier
    tier: skuTier
  }
  properties: {
    // Repository/build config is intentionally left out here — Static Web
    // Apps created via GitHub Actions manage their build/deploy pipeline
    // separately from this resource definition. Re-declaring repositoryUrl
    // here would require a GitHub token and could disrupt the existing
    // deployment pipeline, so it's left unset intentionally.
  }
}

resource wwwCustomDomain 'Microsoft.Web/staticSites/customDomains@2023-01-01' = {
  parent: staticWebApp
  name: wwwDomainName
}

resource apexCustomDomain 'Microsoft.Web/staticSites/customDomains@2023-01-01' = {
  parent: staticWebApp
  name: customDomainName
}

output staticWebAppId string = staticWebApp.id
output staticWebAppDefaultHostname string = staticWebApp.properties.defaultHostname
