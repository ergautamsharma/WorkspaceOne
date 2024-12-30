<#
.SYNOPSIS
  This script retrieves a list of applications from WS1. 

.DESCRIPTION
  This script for interacting with WS1 via various REST APIs and retrieves a list of applications from WS1.
  
  
.OUTPUTS
  Output will be available in CSV


.EXAMPLE
    .\WS1-GetAppList.ps1

.Requirement
    API key
    Console Admin credential

.Limitations
This script does not support proxy.

.NOTES
  Version:             1.1
  Author:              Gautam Sharma @ergautamsharma
  Source:              https://github.com/ergautamsharma/WorkspaceOne
  Creation Date:       December 9, 2022
  Last Update Date:    December 30, 2024

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
$version1 = "application/json;version=1"

$tenantAPIKey = 'WS1APIKey' #Required to update the API Key
$airwatchServer = "as***.awmdm.com" #Required to update the Host Name
$organizationGroupID = "OG GroupID" #Required to update the top OG groupID


#Search Apps
$pageSize = "10000"
$headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
$endpointURL = "https://${airwatchServer}/API/mam/apps/search?pagesize=${pageSize}"
$webReturn = Invoke-RestMethod -Method GET -Uri $endpointURL -Headers $headers
$webReturn.Application | Measure-Object
$apps = $webReturn.Application

foreach ($app in $apps)
{
    $hashtable = New-Object -TypeName psobject -Property(
    [ordered]@{

        ApplicationName = $app.ApplicationName
        ApplicationFileName = $app.ApplicationFileName
        BundleId = $app.BundleId
        AppVersion = $app.AppVersion
        ActualFileVersion = $app.ActualFileVersion 
        AppType = $app.AppType
        Status = $app.Status  
        Platform = $app.Platform  
        AssignmentStatus = $app.AssignmentStatus  
        ApplicationSize = $app.ApplicationSize  
        RootLocationGroupName = $app.RootLocationGroupName
        AssignedDeviceCount = $app.AssignedDeviceCount 
        InstalledDeviceCount = $app.InstalledDeviceCount 
        SupportedModelName = $app.SupportedModels.Model.ModelName -join ';'
        
    })

    $hashtable | Export-Csv -NoTypeInformation "AppList.csv" -Append -Encoding UTF8

}