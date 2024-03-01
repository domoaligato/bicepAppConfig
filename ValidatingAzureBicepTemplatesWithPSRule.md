# Validating Azure Bicep templates with PSRule

Original article [link](https://blogs.infosupport.com/validating-azure-bicep-templates-with-psrule/)

[PSRule](https://microsoft.github.io/PSRule/v2/) is a Powershell module to validate Bicep and ARM templates using rules. It goes beyond simple linting and performs static analysis on resources before those are deployed to Azure.
It also resolves parameters, conditional resources, and variables. This way, it is possible to check locally whether our generated resource names are correct.

In this blog post, we will set up PSRule for Bicep, validate our infrastructure against Microsoft’s guidelines, and create our own rules.

## Getting started

First, we need to install the following two Powershell modules.

``` Powershell
Install-Module -Name 'PsRule' -Repository PSGallery -Scope CurrentUser -Force
Install-Module -Name 'PSRule.Rules.Azure' -Repository PSGallery -Scope CurrentUser -Force
```

We create in our working directory the configuration file ps-rule.yaml with the following contents.

``` Yaml
include:
  module:
    # Import all the Azure Well-Architected Framework rules
    - PSRule.Rules.Azure
 
configuration:
  # Enable code analysis of bicep files
  AZURE_BICEP_FILE_EXPANSION: true
  # Validate that the bicep CLI is used
  AZURE_BICEP_CHECK_TOOL: true
 
input:
  pathIgnore:
  # Exclude module files
  - '**/*.bicep'
  # Include test files for modules
  - '!**/*.tests.bicep'
 
execution:
  # Disable warnings that files cannot be processed
  notProcessedWarning: false
   
output:
  # Show results for rules with the Fail, Pass, or Error outcome
  outcome: 'Processed'
```

Now we have set up our environment and it’s time to look at a few examples.

## Validate against guidelines from Microsoft

Microsoft has created guidelines in its Well-Architected Framework that you can use to improve the quality of your Azure solutions. PSRule has a set of rules that will validate your own infrastructure against those guidelines. These are included in the installed PSRule.Rules.Azure package.

For our first test case, we create a storage account module and validate that we use all best practices from Microsoft.

In our own working directory we create a storage module src/modules/storage.bicep with the following contents.

``` Bicep
@description('Azure region of the deployment')
param location string
 
@description('Tags to add to the resources')
param tags object
 
@description('Name of the storage account')
param storageName string
 
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'blob${storageName}'
  tags: union(tags, {
    classification: 'general'
  })
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}
 
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  name: 'default'
  parent: storage
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
```

Next, we create the file src/modules/tests/storage.tests.bicep with our test case. Each module that we define in this file can be seen as a sample deployment to validate.

All rules that we included in our .ps-rule.yaml config will be used to validate every module included in this file.

``` Bicep
@description('Azure region of the deployment')
param location string = resourceGroup().location
 
module test_storage_best_practices '../storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location 
    storageName: 'documents001'
    tags: {
      environment: 'dev'
    }
  }
}
```

The only thing left is this command that runs the test in our src folder. It will run all the Azure Well-Architected Framework rules.

``` Powershell
Assert-PSRule  -InputPath 'src/'
```

Tip: Receive an error that the Bicep CLI cannot be found? The following one-liner fixes it for default Bicep installations on Windows.

``` Powershell
[Environment]::SetEnvironmentVariable("PSRULE_AZURE_BICEP_PATH", "%USERPROFILE%\.Azure\bin\bicep.exe", "User")
```

After the validation run finishes, the output shows that we fail one rule. We no longer permit a secure TLS version.

![image](/ps-rule-image1.png)

Update the property minimumTlsVersion in the storage module to TLS1_2 and run the test again. Now we pass the rule!

![image](/ps-rule-image2.png)

## Create your own rules

We can also create our own rules. To demonstrate this we will create two rules that check of the name of our storage account meets our naming convention, and tagging strategy.

Start with creating a custom rule file .ps-rule\My.Storage.Rule.yaml with the following contents.

``` Yaml
# Synopsis: Storage account names need to be between 3 and 24 characters long and start with 'st'.
apiVersion: github.com/microsoft/PSRule/v1
kind: Rule
metadata:
  name: My.Storage.NameConvention
spec:
  type:
  - Microsoft.Storage/storageAccounts
  condition:
    allOf:
      - name: '.'
        greaterOrEquals: 3
      - name: '.'
        lessOrEquals: 24
      - name: '.'
        startsWith: 'st'
 
---
 
# Synopsis: Storage accounts need at least a tag with the name 'purpose'
apiVersion: github.com/microsoft/PSRule/v1
kind: Rule
metadata:
  name: My.Storage.PurposeTag
spec:
  type:
  - Microsoft.Storage/storageAccounts
  condition:
    field: tags.purpose
    exists: true
```

**Tip**: More complex rules can also be created in Powershell. Good examples can be found [here](https://github.com/Azure/PSRule.Rules.Azure/tree/main/src/PSRule.Rules.Azure/rules).

If we were to run our validation again, our rules will not work! We also need to explicitly enable custom rules and create bindings. Without these bindings, PSRule cannot match the rules with our bicep files. So we add the following lines to the ps-rule.yaml.

``` Yaml
rule:
  # Enable local rules
  includeLocal: true
   
binding:
  # Bindings are required for local rules
  targetType:
  - type
  - resourceType
```

We run the rules again and see the following in the console output.

We change our storage resource name from blob${storageName} to st${storageName} and next to the classification, we add a tag with the name purpose.

We run the rules once more and finally see that every rule has passed!

Hopefully, this will give you a basic idea of how PSRule works and how you can validate your own infrastructure scripts. If you are interested in other features, here are some that you can further explore:

[Run the tests in a pipeline](https://microsoft.github.io/PSRule/v2/scenarios/validation-pipeline/validation-pipeline/)
[Test rules against already deployed Azure resources](https://azure.github.io/PSRule.Rules.Azure/export-rule-data/)
[Use rules for Kubernetes resources](https://microsoft.github.io/PSRule/v2/scenarios/kubernetes-resources/kubernetes-resources/)
