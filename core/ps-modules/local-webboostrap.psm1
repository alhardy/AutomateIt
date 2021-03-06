function Throw-LocalWebBootstrapError([string] $message) {
	Write-Host "[LocalWebBootstrap-Error] $message" -f Cyan
}

if(-not(Test-Path ".\user-config.ps1")){
	$path = Resolve-Path .\
	Throw-LocalWebBootstrapError "$path\user-config.ps1 is required."
}

if(-not(Test-Path ".\web-config.ps1")){
	$path = Resolve-Path .\
	Throw-LocalWebBootstrapError "$path\web-config.ps1 is required."	
}

. .\user-config.ps1
. .\web-config.ps1

$sitesKeys = $sites.Keys | Where { $sitesToStart -Contains $_ } 

if(-not($sitesKeys)){
	Throw-LocalWebBootstrapError "There were no sites found to start. Edit SitesToStart in user-config.ps1"
}

function Start-LocalIISExpress {
	$iisExpressExe = '"%programfiles%\IIS Express\iisexpress.exe"'
	if(-not($iisExpressExe)){
		Throw-LocalWebBootstrapError "IIS Express needs to be installed before continuing. http://www.microsoft.com/en-au/download/details.aspx?id=34679"
	}

	$config = Get-Content .\applicationhost.config

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

	Set-Content -Path .\applicationhost.user.config -value $config

	$sitesKeys | % {
		$siteName = $sites[$_].SiteName
		$params = "/systray:true /trace:error /config:.\applicationhost.user.config /site:$siteName"
		$command = "$iisExpressExe $params"
		cmd /c start cmd /k "$command"
	}
}

function Set-LocalHosts {
	Import-Module ..\core\ps-modules\host-file.psm1

	$sites.Keys | % {
		$site = $sites[$_]
		$sites[$_].HostHeaders | % {
			Add-HostEntry $site.IPAddress $_
		}		
	}

	Remove-Module [h]ost-file
}

function Build-LocalSites {
	Import-Module ..\core\ps-modules\msbuild.psm1
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

Export-ModuleMember Start-LocalIISExpress, Set-LocalHosts, Build-LocalSites, Start-LocalWebFromConfig