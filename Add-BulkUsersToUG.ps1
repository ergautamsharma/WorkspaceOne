<#
.SYNOPSIS
  This script for interacting with WS1 via various REST APIs

.DESCRIPTION
  This script for interacting with WS1 via various REST APIs
  This will used to add WS1 users to WS1 User Group

.INPUTS
  Input.txt file will be used to supply the UserID's
  UserGroupID

.OUTPUTS
  None (Users will be part of group)

.EXAMPLE
    .\Add-BulkUserToUG.ps1

.Requirement
    API key
    Console Admin credential

.Limitations
This script does not support proxy.

.NOTES
  Version:        1.0
  Author:         Gautam Sharma @ergautamsharma
  Source:         https://github.com/ergautamsharma/WorkspaceOne
  Creation Date:  October 12, 2022
  Update Date:    October 12, 2022

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

#update the inputs/config
$restUserName = Get-BasicUserForAuth
$tenantAPIKey = 'f8qE7xxxx+xxxxx7rh9g2f6xxxxxxxxxxbyna9PIcj8=' #Required to update the API Key
$airwatchServer = "cn000.awmdm.com" #Required to update the Host Name
$organizationGroupID = "xxxxx46000XX" #Required to update the top OG groupID
$version1 = "application/json;version=1"
$UserGroupID = "0000" #Required to update the New UsergroupID

#Import list of users
$users = Get-Content input.txt

#Adding users in a group
foreach ($user in $users)
{
    #$user = "123456"
    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
    $endpointURL = "https://${airwatchServer}/API/system/usergroups/${UserGroupID}/user/${user}/addusertogroup"
    $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers
    Start-Sleep -Milliseconds 10

}
