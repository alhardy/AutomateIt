param(
		[switch]$GetLatestModules
	 )

$psModuleRoot = Resolve-Path ..\ps-modules
$solutionRoot = Resolve-Path ..\examples\WebExample
$env = "dev"
$envVarPath = Resolve-Path $solutionRoot\env

Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Import-Module -Name $psModuleRoot\module-extensions -Verbose -Force

Install-ModuleWithPsGet -Module psake
Install-ModuleWithPsGet -Module env -ModulePath $psModuleRoot\env.psm1 -GetLatest:$GetLatestModules.IsPresent
Install-ModuleWithPsGet -Module host-file -ModulePath $psModuleRoot\host-file.psm1 -GetLatest:$GetLatestModules.IsPresent

Invoke-Psake Configure-ForMyBox -parameters @{"Env"=$env;"EnvVarPath"=$envVarPath;"SolutionRoot"=$solutionRoot}

Remove-Module [p]sget -ErrorAction SilentlyContinue
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue
Remove-Module [e]nv -ErrorAction SilentlyContinue
Remove-Module [h]ost-file -ErrorAction SilentlyContinue