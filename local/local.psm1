function Set-Environment{
	param(
		[string]$ProjectName,
		[string]$ProjectPath,
		[string]$Env,
		[switch]$GetLatestModules
	)	

	$psModuleRoot = Resolve-Path $PSScriptRoot\..\ps-modules
	
	$solutionRoot = Resolve-Path $PSScriptRoot\..\examples\WebExample
	$env = "dev"
	$envVarPath = Resolve-Path $solutionRoot\env

	Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
	Import-Module -Name $psModuleRoot\module-extensions -Verbose -Force

	Install-ModuleWithPsGet -Module psake
	Install-ModuleWithPsGet -Module env -ModulePath $psModuleRoot\env.psm1 -GetLatest:$GetLatestModules.IsPresent

	$configsForEnv = Resolve-Path $ProjectPath\_Config\$Env\*

	Copy-Item $configsForEnv $ProjectPath -Recurse -Force
	
	Set-SensitiveData -ProjectPath $ProjectPath -Env $Env -EnvPath $envVarPath 

	Remove-Module [p]sget -ErrorAction SilentlyContinue
	Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
	Remove-Module [p]sake -ErrorAction SilentlyContinue
	Remove-Module [e]nv -ErrorAction SilentlyContinue
}

Export-ModuleMember Set-Environment