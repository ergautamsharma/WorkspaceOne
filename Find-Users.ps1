<#
.SYNOPSIS
  This script for interacting with WS1 via various REST APIs

.DESCRIPTION
  This script for interacting with WS1 via various REST APIs
  This will used to search duplicate WS1 users

.INPUTS
  Input.txt file will be used to supply the Email address or User name
  
.OUTPUTS
  Output will be available as following:
  MultiID.csv - duplicate WS1 accounts
  UserCountMoreThan2.txt - list users having more than 3 WS1 accounts
  AllUser.csv - all users

.EXAMPLE
    .\Find-Users.ps1

.Requirement
    API key
    Console Admin credential

.Limitations
This script does not support proxy.

.NOTES
  Version:             1.0
  Author:              Gautam Sharma @ergautamsharma
  Source:              https://github.com/ergautamsharma/WorkspaceOne
  Creation Date:       December 9, 2022
  Last Update Date:    December 9, 2022

#>
#Get Console Admin credential
Function Get-BasicUserForAuth {
    $Credential = Get-Credential
    $EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName,$Credential.GetNetworkCredential().Password)))
    Return "Basic " + $EncodedUsernamePassword
}

#Set the URL Header
Function Set-Header {

    Param([string]$authorizationString, [string]$tenantCode, [string]$acceptType, [string]$contentType)

    $authString = $authorizationString
    $tcode = $tenantCode
    $accept = $acceptType
    $content = $contentType

    Write-Verbose("---------- Headers ----------")
    Write-Verbose("Authorization: " + $authString)
    Write-Verbose("aw-tenant-code:" + $tcode)
    Write-Verbose("Accept: " + $accept)
    Write-Verbose("Content-Type: " + $content)
    Write-Verbose("------------------------------")
    Write-Verbose("")
    $header = @{"Authorization" = $authString; "aw-tenant-code" = $tcode; "Accept" = $accept; "Content-Type" = $content}
     
    Return $header
}

#updating the inputs/config
$restUserName = Get-BasicUserForAuth
$tenantAPIKey = 'f8qE7xxxx+xxxxx7rh9g2f6xxxxxxxxxxbyna9PIcj8=' #Required to update the API Key
$airwatchServer = "cn000.awmdm.com" #Required to update the Host Name
$organizationGroupID = "xxxxx46000XX" #Required to update the top OG groupID
$version1 = "application/json;version=1"


$EmailUserNames = Get-Content .\input.txt
#$EmailUserNames = Get-Content .\UserID.txt

$EmailUserNamesCount = $EmailUserNames.Count
$pcti = 0

foreach ($EmailUserName in $EmailUserNames)
{
    $pcti = $pcti + 1
    $pct = $pcti/$EmailUserNamesCount * 100
    Write-Progress -Activity "Searching users on WS1 Portal using API" -Status "Processing user $pcti of $EmailUserNamesCount - $EmailUserName" -PercentComplete $pct 

    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
    $endpointURL = "https://${airwatchServer}/API/system/users/search?Email=${EmailUserName}"
    #$endpointURL = "https://${airwatchServer}/API/system/users/search?UserName=${EmailUserName}"
    
    $webReturn = Invoke-RestMethod -Method GET -Uri $endpointURL -Headers $headers
    $filterPer = $webReturn.Users | Where-Object {$_.Group -ne 'Personal'}
    $filter = $filterPer | Where-Object {$_.Status -eq 'True'}
    $count = ($filter | Measure-Object).Count
    if ($count -eq '2')
    {
        $defSecurityType = $filter[0].SecurityType -ne $filter[1].SecurityType
        if ($defSecurityType)
        {
            $filter | Select-Object UserName, Email, Status, SecurityType, Group | Export-Csv -Append MultiID.csv -NoTypeInformation
        }
        
    }
    if ($count -gt '2')
    {
        $message = "$EmailUserName is having $count WS1 active accounts"
        $message | Out-File -FilePath UserCountMoreThan2.txt -Append
    }
    else{
        $filter | Select-Object UserName, Email, Status, SecurityType, Group | Export-Csv -Append AllUser.csv -NoTypeInformation
    }
}
