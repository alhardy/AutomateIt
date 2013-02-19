param(
		[switch]$GetLatestModules
	 )

if(-not(Test-Path ".\user-config.ps1" )) {
    throw "user-config.ps1 does not exist."
}

. .\user-config.ps1

$psModuleRoot = Resolve-Path ..\core\ps-modules
$solutionRoot = Resolve-Path $global:ProjectRootPath
$env = "dev"

if(-not(Test-Path "$solutionRoot\env" )) {
    throw "$solutionRoot\env does not exist. $env sensitive data files are required to setup the solution locally"
}

$envVarPath = Resolve-Path $solutionRoot\env

Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Import-Module -Name $psModuleRoot\module-extensions -Verbose -Force
Install-ModuleWithPsGet -Module psake

Invoke-Psake Configure-ForMyBox -parameters @{"Env"=$env;"EnvVarPath"=$envVarPath;"SolutionRoot"=$solutionRoot;}

Remove-Module [p]sget -ErrorAction SilentlyContinue
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue