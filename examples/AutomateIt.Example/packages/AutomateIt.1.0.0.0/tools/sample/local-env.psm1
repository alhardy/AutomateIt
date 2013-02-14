function Set-Environment{
	param(
		[string]$ProjectName,
		[string]$ProjectPath,
		[string]$Env,
		[switch]$GetLatestModules
	)	

	$psModuleRoot = Resolve-Path $PSScriptRoot\..\core\ps-modules
	
	$solutionRoot = Resolve-Path $PSScriptRoot\..\..\
	$env = "dev"
	$envVarPath = Resolve-Path $solutionRoot\env

	Remove-Module [e]nv -ErrorAction SilentlyContinue
	Import-Module -Name $psModuleRoot\env.psm1 -Verbose -Force

	$envConfigs = "$ProjectPath\_Config\$Env\*"

	if (Test-Path $envConfigs){
		$configsForEnv = Resolve-Path $envConfigs
		Copy-Item $configsForEnv $ProjectPath -Recurse -Force
		Set-SensitiveData -ProjectPath $ProjectPath -Env $Env -EnvPath $envVarPath 
	}			
	
	Remove-Module [e]nv -ErrorAction SilentlyContinue
}

Export-ModuleMember Set-Environment