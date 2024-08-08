param(
    [string] [Parameter(Mandatory=$true)] $searchServiceName,
    [string] [Parameter(Mandatory=$true)] $indexDefinition
    # [string] [Parameter(Mandatory=$true)] $identity,
    # [string] [Parameter(Mandatory=$true)] $tenant,
    # [string] [Parameter(Mandatory=$true)] $subscription
)

$ErrorActionPreference = 'Stop'

# Connect-AzAccount -Identity $identity -Tenant $tenant -Subscription $subscription

$apiversion = '2020-06-30'
$token = Get-AzAccessToken -ResourceUrl https://search.azure.com | select -expand Token
$headers = @{ 'Authorization' = "Bearer $token"; 'Content-Type' = 'application/json'; }
$uri = "https://$searchServiceName.search.windows.net"
$indexDefinitionJson = ConvertTo-Json $indexDefinition

$DeploymentScriptOutputs['indexName'] = $indexDefinitionJson.name

try {
    # https://learn.microsoft.com/rest/api/searchservice/create-index
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/indexes/$($indexDefinition['name'])?api-version=$apiversion" `
        -Headers  $headers `
        -Body $indexDefinitionJson

} catch {
    Write-Error $_.ErrorDetails.Message
    throw
}
