// dnsZone.bicep
// Deploys the public DNS zone for motosmarketplace.com and its record sets.
//
// The NS and SOA records at the apex are created and managed by Azure when the
// zone is created, so they are intentionally not declared here — redeclaring
// them would fight with the platform's own values.
//
// Mail (MX/SPF/DMARC) is handled by ImprovMX forwarding; transactional mail is
// sent through SendGrid, which owns the em2858 and *._domainkey CNAMEs.

@description('Name of the public DNS zone (the apex domain).')
param dnsZoneName string = 'motosmarketplace.com'

@description('Resource ID of the Static Web App the apex A alias record points at.')
param staticWebAppId string

@description('Default hostname of the Static Web App, used as the target of the www CNAME.')
param staticWebAppDefaultHostname string

@description('Domain ownership validation token issued by Static Web Apps for the apex custom domain.')
param staticWebAppValidationToken string = '_ef0citwjb3b4m9oc06ozdsk7g0o1a7e'

@description('Default TTL, in seconds, applied to the record sets in this zone.')
param recordTtl int = 3600

// Public DNS zones are always global — they have no regional placement.
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZoneName
  location: 'global'
  properties: {
    zoneType: 'Public'
  }
}

// -------------------------------------------------------------------------
// Apex — motosmarketplace.com
// -------------------------------------------------------------------------

// Alias record: an apex domain can't be a CNAME, so Azure DNS resolves the
// Static Web App resource directly. This keeps working if the Static Web App's
// front-end IPs ever change.
resource apexAlias 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: '@'
  properties: {
    TTL: recordTtl
    targetResource: {
      id: staticWebAppId
    }
  }
}

resource apexMx 'Microsoft.Network/dnsZones/MX@2018-05-01' = {
  parent: dnsZone
  name: '@'
  properties: {
    TTL: recordTtl
    MXRecords: [
      {
        preference: 10
        exchange: 'mx1.improvmx.com'
      }
      {
        preference: 20
        exchange: 'mx2.improvmx.com'
      }
    ]
  }
}

// Both the Static Web App domain validation token and the SPF policy live in
// the same apex TXT record set — they must be declared together, since a record
// set replaces every value at that name.
resource apexTxt 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: dnsZone
  name: '@'
  properties: {
    TTL: recordTtl
    TXTRecords: [
      {
        value: [
          staticWebAppValidationToken
        ]
      }
      {
        value: [
          'v=spf1 include:spf.improvmx.com ~all'
        ]
      }
    ]
  }
}

resource dmarcTxt 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: dnsZone
  name: '_dmarc'
  properties: {
    TTL: recordTtl
    TXTRecords: [
      {
        value: [
          'v=DMARC1; p=none'
        ]
      }
    ]
  }
}

// -------------------------------------------------------------------------
// www — front end
// -------------------------------------------------------------------------
resource wwwCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: 'www'
  properties: {
    TTL: recordTtl
    CNAMERecord: {
      cname: staticWebAppDefaultHostname
    }
  }
}

// -------------------------------------------------------------------------
// SendGrid — link branding and DKIM for outbound mail
// -------------------------------------------------------------------------
resource sendGridMailCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: 'em2858'
  properties: {
    TTL: recordTtl
    CNAMERecord: {
      cname: 'u108956344.wl095.sendgrid.net'
    }
  }
}

resource sendGridDkim1Cname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: 's1._domainkey'
  properties: {
    TTL: recordTtl
    CNAMERecord: {
      cname: 's1.domainkey.u108956344.wl095.sendgrid.net'
    }
  }
}

resource sendGridDkim2Cname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: 's2._domainkey'
  properties: {
    TTL: recordTtl
    CNAMERecord: {
      cname: 's2.domainkey.u108956344.wl095.sendgrid.net'
    }
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------
output dnsZoneId string = dnsZone.id
output dnsZoneName string = dnsZone.name
output nameServers array = dnsZone.properties.nameServers
