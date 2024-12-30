<#
.SYNOPSIS
  This script for interacting with WS1 to get the list of smart group. 

.DESCRIPTION
  This script for interacting with WS1 to get the list of smart group. 

.INPUTS
  Input.txt file will be used to supply the Email address or User name
  
.OUTPUTS
  Output will be available as following:
  SmartGroup.csv

.EXAMPLE
    .\Export-WS1SmartGroups.ps1

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
$tenantAPIKey = 'MqUsig7OxD9ilpHa8xQrrPIsSl8JcUKEnWAeiwQzjAQ=' #Required to update the API Key
$airwatchServer = "cn99.airwatchportals.com" #Required to update the Host Name
$organizationGroupID = "Pepsi" #Required to update the top OG groupID
$version1 = "application/json;version=1"
#$EmailUserName = 'gautam.sharma.contractor@pepsico.com'


#Search Smart Groups
$pageSize = "10000"
$headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
$endpointURL = "https://${airwatchServer}/API/mdm/smartgroups/search?pagesize=${pageSize}"
$webReturn = Invoke-RestMethod -Method GET -Uri $endpointURL -Headers $headers
#$webReturn.SmartGroups | Measure-Object
$SGWithAssignment = $webReturn.SmartGroups | Where-Object {$_.Assignments -ne '0' -and $_.Devices -ne '0' } #| Select-Object -First 50 #| Measure-Object
#total Count    : 1752

#$SG = $webReturn.SmartGroups | Where-Object {$_.Name -like "*- PROD - 1:1 National*"}
#$SGID = $SG.SmartGroupID
#$SGUUID = $sg.SmartGroupUuid

$hashtable = $null

foreach ($SmartG in $SGWithAssignment)
{
    
    $SGID = $SmartG.SmartGroupID
    Write-Host "Smart Group Name: $($SmartG.Name) & ID is $SGID"
    #getting Smart Group details
    $SGendpointURL = "https://${airwatchServer}/API/mdm/smartgroups/${SGID}"
    $SGwebReturn = Invoke-RestMethod -Method GET -Uri $SGendpointURL -Headers $headers

    $hashtable = New-Object -TypeName psobject -Property(
    [ordered]@{

        "SmartGroup Name" = $SGwebReturn.Name
        "SmartGroup ID" = $SGwebReturn.SmartGroupID
        "Criteria Type" = $SGwebReturn.CriteriaType
        "Managed By ID" = $SGwebReturn.ManagedByOrganizationGroupId
        "Managed By Name" = $SGwebReturn.ManagedByOrganizationGroupName
        "Devices" = $SGwebReturn.Devices
        "Assignments" = $SGwebReturn.Assignments
        "Exclusions" = $SGwebReturn.Exclusions
        "OrganizationGroups Name" = $SGwebReturn.OrganizationGroups.Name -join ';'
        "OrganizationGroups id" = $SGwebReturn.OrganizationGroups.id -join ';'
        "UserGroups Name" = $SGwebReturn.UserGroups.Name -join ';'
        "UserGroups id" = $SGwebReturn.UserGroups.id -join ';'
        
        
    })

    $hashtable | Export-Csv -NoTypeInformation "SmartGroup.csv" -Append -Encoding UTF8
    $SGID = $null

}