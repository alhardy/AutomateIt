function Throw-LocalWebBootstrapError([string] $message) {
	Write-Host "[LocalWebBootstrap-Error] $message" -f Cyan
}

$script:scriptExecutionPath = Resolve-Path .\

$script:sitesKeys = @()
$script:sites = @()

function Load-UserAndWebConfigs {
	param(			
			[parameter(Mandatory=$true)] 
		  	[string] $ScriptExecutionPath		  	
	 )	

	if(-not(Test-Path "$ScriptExecutionPath\user-config.ps1")){	
		Throw-LocalWebBootstrapError "$ScriptExecutionPath\user-config.ps1 is required."
	}

	if(-not(Test-Path "$ScriptExecutionPath\web-config.ps1")){	
		Throw-LocalWebBootstrapError "$ScriptExecutionPath\web-config.ps1 is required."	
	}	

	. $ScriptExecutionPath\user-config.ps1
	. $ScriptExecutionPath\web-config.ps1

	$script:sitesKeys = $sites.Keys | Where { $sitesToStart -Contains $_ } 
	$script:scriptExecutionPath = $ScriptExecutionPath	
	$script:sites = $sites
}

function Start-LocalIISExpress {	
	$sitesKeys = $sites.Keys | Where { $SitesToStart -Contains $_ } 

	if(-not($sitesKeys)){
		Throw-LocalWebBootstrapError "There were no sites found to start. Edit SitesToStart in user-config.ps1"
	}

	$iisExpressExe = '"%programfiles%\IIS Express\iisexpress.exe"'
	if(-not($iisExpressExe)){
		Throw-LocalWebBootstrapError "IIS Express needs to be installed before continuing. http://www.microsoft.com/en-au/download/details.aspx?id=34679"
	}

	$config = Get-Content $scriptExecutionPath\applicationhost.config

	$sitesKeys | % {	
		$site = $sites[$_]
		$project = $SolutionRoot, $site.ProjectFile -Join '\'
		$path = Split-Path $project -Resolve					
		$config = $config -Replace $site.ApplicationHostConfigPhysicalPathKey, $path -Replace $site.ApplicationHostConfigSiteNameKey, $site.SiteName
		$site.HostHeaders | % {$i = 1} {
			$currentKey = $site.ApplicationHostConfigHostHeaderKey -Replace "}", "$i}"						
			$config = $config -Replace $currentKey, $_
			$i++
		}		
	}		
	
	Set-Content -Path $scriptExecutionPath\applicationhost.user.config -value $config

	$sitesKeys | % {
		$siteName = $sites[$_].SiteName		
		$params = "/systray:true /trace:error /config:$scriptExecutionPath\applicationhost.user.config /site:$siteName"
		$command = "$iisExpressExe $params"
		cmd /c start cmd /k "$command"
	}
}

function Set-LocalHosts {		
	Import-Module $scriptExecutionPath\..\core\ps-modules\host-file.psm1

	$sites.Keys | % {
		$site = $sites[$_]
		$sites[$_].HostHeaders | % {
			Add-HostEntry $site.IPAddress $_
		}		
	}

	Remove-Module [h]ost-file
}

function Build-LocalSites {		
	Import-Module $scriptExecutionPath\..\core\ps-modules\msbuild.psm1
	$projects = @()

	$sitesKeys | % {			
		$project = $SolutionRoot, $sites[$_].ProjectFile -Join '\'	
		$projects += @($project)
	}	

	Start-LocalMsBuild -ProjectsOrSolutions $projects

	Remove-Module [m]sbuild
}

function Start-LocalWebFromConfig {
	Build-Sites
	Set-Hosts
	Start-IISExpress
}

Export-ModuleMember Start-LocalIISExpress, Set-LocalHosts, Build-LocalSites, Start-LocalWebFromConfig, Load-UserAndWebConfigs