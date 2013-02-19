properties{    
    $Env
    $EnvVarPath
    $SolutionRoot    
}

$sites = @{
	GovGo = @{
		IPAddress = "127.0.0.1";
		HostHeader = "dev.govgo.com.au";		
		ProjectFile = "src\Fairfax.Marketplaces.Employment.Web\Fairfax.Marketplaces.Employment.Web\Fairfax.Marketplaces.Employment.Web.csproj";		
		ApplicationHostConfigPhysicalPathKey = "{GovGoPhysicalPath}";
		SiteName = "GovGo";
	};
}

task Set-IISExpress {
	$iisExpressExe = '"%programfiles%\IIS Express\iisexpress.exe"'
	if(-not($iisExpressExe)){
		throw "IIS Express needs to be installed before continuing. http://www.microsoft.com/en-au/download/details.aspx?id=34679"
	}

	$sites.Keys | % {	
		$path = Split-Path $sites[$_].ProjectFile -Resolve	
		$siteName = $sites[$_].SiteName
		$config = Get-Content .\applicationhost.config
		$config = $config -Replace $sites[$_].ApplicationHostConfigPhysicalPathKey, $path
		Set-Content -Path .\applicationhost.user.config -value $config
		$params = "/systray:true /trace:error /config:.\applicationhost.user.config /site:$siteName"
		$command = "$iisExpressExe $params"
		cmd /c start cmd /k "$command"
	}	
}

task Set-Hosts {
	Import-Module ..\core\ps-modules\host-file.psm1

	$sites.Keys | % {
		Add-HostEntry $sites[$_].IPAddress $sites[$_].HostHeader
	}

	Remove-Module [h]ost-file
}

task Build-Local {
	Import-Module ..\core\ps-modules\msbuild.psm1
	$sites.Keys | % {		
		$projects = @("$SolutionRoot\$sites[$_].ProjectFile")
		Write-Warning $SolutionRoot
		return
		Start-LocalMsBuild -ProjectsOrSolutions $projects
	}

	Remove-Module [m]sbuild
}

task Set-Environment {
	$sites.Keys | % {
		
	}
}

task Configure-ForMyBox -depends Build-Local, Set-Hosts, Set-IISExpress {
	"Configuring $SolutionRoot for $Env"
}