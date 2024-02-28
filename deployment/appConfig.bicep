targetScope = 'subscription'

metadata name = 'WAF-aligned'
metadata description = 'This instance deploys the module in alignment with the best-practices of the Azure Well-Architected Framework.'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'rg-appconfig-ecp-westus2-01'

@description('Optional. The location to deploy resources to.')
param resourceLocation string = deployment().location

@description('Optional. name of the appconfig resource.')
param name string = 'appconfig-iac-ecp-westus2-01'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: resourceLocation
}

// ============== //
// Execution      //
// ============== //

module configurationStore '../src/modules/app-configuration/configuration-store/main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, resourceLocation)}-test-appconfig-01'
  params: {
    name: name
    location: resourceLocation
    createMode: 'Default'
    disableLocalAuth: false
    enablePurgeProtection: false
    keyValues: [
      {
        // https://www.iana.org/assignments/media-types/media-types.xhtml
        contentType: 'application/json'
        name: 'privateEndpointSubnets'
        value: '''
          {
            "pbc-shared-dev": "resourceid for pbc-shared-dev",
            "pbc-shared-test": "resourceid for pbc-shared-test"
          }
        '''
      }
    ]
    softDeleteRetentionInDays: 1
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}

@description('The name of the app configuration.')
output name string = configurationStore.outputs.name

@description('The resource ID of the app configuration.')
output resourceId string = configurationStore.outputs.resourceId

@description('The resource group the app configuration store was deployed into.')
output resourceGroupName string = configurationStore.outputs.resourceGroupName

@description('The principal ID of the system assigned identity.')
output systemAssignedMIPrincipalId string = configurationStore.outputs.systemAssignedMIPrincipalId

@description('The location the resource was deployed into.')
output location string = configurationStore.outputs.location
