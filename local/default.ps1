properties{    
    $Env
    $EnvVarPath
    $SolutionRoot    
}

task Set-IISExpress {
	"Configuring IIS Express with local settings and running"

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