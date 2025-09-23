@description('Enter name of Integration')
param integrationName string

@description('Enter Location for your resources')
param location string

@description('Enter Environment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

var aiName = toLower('ai-${integrationName}-weu-${environment}')
var lwsName = toLower('lws-${integrationName}-weu-${environment}')

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  tags: resourceGroup().tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    SamplingPercentage: 100
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

output aiConnectString string = appInsightsComponents.properties.ConnectionString

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: lwsName
  location: location
  tags: resourceGroup().tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 5
    }
  }
}
