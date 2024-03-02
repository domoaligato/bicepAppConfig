targetScope = 'subscription'

metadata name = 'WAF-aligned'
metadata description = 'This instance deploys the module in alignment with the best-practices of the Azure Well-Architected Framework.'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'rg-appconfig-ecp-westus2-01'

@description('Optional. name of the appconfig resource.')
param name string = 'appconfig-iac-ecp-westus2-01'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing ={
  name: resourceGroupName
}

// ============== //
// Execution      //
// ============== //

resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
#disable-next-line BCP334
  name: name
  scope: resourceGroup
}

resource privateEndpointSubnets 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' existing = {
  name: 'privateEndpointSubnets'
  parent: appConfiguration
}

resource vmSubnets 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' existing = {
  name: 'privateEndpointSubnets'
  parent: appConfiguration
}

// ============== //
// Outputs        //
// ============== //

@description('The name of the app configuration keyValue.')
output privateEndpointSubnetsObj object = json(privateEndpointSubnets.properties.value)

@description('The name of the app configuration keyValue.')
output vmSubnetsObj object = json(vmSubnets.properties.value)
