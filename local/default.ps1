properties{    
    $Env
    $EnvVarPath
    $SolutionRoot    
}

task Set-IISExpress {
	"Configuring IIS Express with local settings and running"

	$iisExpressExe = '"c:\Program Files (x86)\IIS Express\iisexpress.exe"'
	$path = Resolve-Path "C:\Source\BuildTestDeploy\BuildTestAndDeploy.Web"
	$params = "/systray:true /config:C:\Source\BuildTestDeploy\scripts\iisexpress\applicationhost.config /site:BuildTestDeploy"
	$command = "$iisExpressExe $params"
	cmd /c start cmd /k "$command"
}

task Set-Environment {
	"Applying '$Env' environment variables"  

	$projectsSharedConfigs = "$SolutionRoot\SharedConfiguration"    

	Get-ChildItem -Path $SolutionRoot -Recurse -Include "*.csproj", "*.vbproj" | %{$projects = @{}} { $projects[$_.Name]=$_.DirectoryName}

	$count = $projects.Count
	Write-Host "Found $count projects, updating config files with '$env' settings" -f yellow

	$projects.Keys | % {		
		Set-EnvVariables -ProjectPath $projects[$_] -Env $env -EnvPath $envVarPath
	}

	# Set environment variables on shared configs if they exist
	if (Test-Path($projectsSharedConfigs)) {
		Set-EnvVariables -ProjectPath $projectsSharedConfigs -Env $env -EnvPath $envVarPath 
	}	
}

task Configure-ForMyBox -depends Set-Environment, Set-IISExpress {
	"Configuring $SolutionRoot for $Env"
	
}