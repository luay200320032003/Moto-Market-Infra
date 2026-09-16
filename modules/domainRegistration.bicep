// domainRegistration.bicep
// References the existing App Service Domain registration for
// motosmarketplace.com so its state is visible from this template's outputs.
//
// This module deliberately does NOT manage the domain's create/update
// lifecycle. A Microsoft.DomainRegistration/domains PUT requires full
// registrant/admin/billing/tech contact objects (name, email, phone,
// physical address) on every deployment — that's PII we don't want
// persisted in this repo's git history, and redeploying with a stale or
// incomplete contact payload risks the registrar rejecting the update or
// the domain silently losing its WHOIS privacy protection. The domain is
// purchased and renewed through the Portal or `az` directly; this module
// only reads its current state.

@description('The registered domain name.')
param domainName string = 'motosmarketplace.com'

resource domain 'Microsoft.DomainRegistration/domains@2023-01-01' existing = {
  name: domainName
}

output domainId string = domain.id
output autoRenew bool = domain.properties.autoRenew
output expirationTime string = domain.properties.expirationTime
output registrationStatus string = domain.properties.registrationStatus
