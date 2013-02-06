function Confirm-PsGetIsInstall{
	param(
			[switch]$GetLatest
		 )

	$availableModules = Get-Module -ListAvailable

	if (-not($availableModules | where {$_.Name -eq "PsGet" }) -or $GetLatest) {
		Write-Warning "Downloading PsGet"
		(New-Object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
		$GotLatestPsGet = $True
	}

	if (-not(Get-Module PsGet)) {
		Import-Module -Name PsGet -Verbose -Force
	}	
}

function Install-ModuleWithPsGet {
	param(
			[switch]$GetLatest,
			[string]$Module,
			[string]$Url,
			[string]$ModulePath
		 )
	
	Confirm-PsGetIsInstall -GetLatest:$GetLatest.IsPresent

	$availableModules = Get-Module -ListAvailable
	$justInstalled = $False
	
	if (-not($availableModules | where {$_.Name -eq $Module })) {
		Write-Warning "Downloading $Module and Importing"
		if ($Url) { Install-Module -ModuleUrl $Url }
		elseif ($ModulePath) { Install-Module -ModulePath $ModulePath }
		else { Install-Module -Module $Module }
		$justInstalled = $True
	}

	if ($GetLatest -and -not($justInstalled)){
		Write-Warning "Updating $Module and Importing"
		if ($Url) { Install-Module -ModuleUrl $Url } 
		elseif ($ModulePath) { Install-Module -ModulePath $ModulePath -Force }
		else { Update-Module -Module $Module }
	}
	
	Import-Module -Name $Module -Verbose -Force -Global	
}

Export-ModuleMember Confirm-PsGetIsInstall, Install-ModuleWithPsGet, Restore-Module