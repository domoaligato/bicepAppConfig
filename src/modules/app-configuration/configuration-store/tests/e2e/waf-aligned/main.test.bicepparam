using './main.test.bicep'

param resourceGroupName = 'dep-${namePrefix}-appconfiguration.configurationstores-${serviceShort}-rg'
param resourceLocation = 'westus2'
param serviceShort = 'accwaf'
param namePrefix = 'joe'

