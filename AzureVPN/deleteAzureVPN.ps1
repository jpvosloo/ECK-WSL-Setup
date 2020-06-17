
#Install Powershell module
#https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.2.0&viewFallbackFrom=azps-3.3.0
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
      'Az modules installed at the same time is not supported.')
} else {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

#Delete VPN
Remove-AzResourceGroup -Name TestRG1
