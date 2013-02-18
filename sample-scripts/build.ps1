param(
		[switch]$ReInstallLocalModules, # Downloads latest third party modules and re-installs
		[switch]$ReInstallThirdPartyModules # Re-installs latest local modules
	 )
$psModuleRoot = Resolve-Path ..\core\ps-modules

. .\build-config.ps1

Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Import-Module -Name $psModuleRoot\module-extensions.psm1 -Verbose -Force

Install-ModuleWithPsGet -Module psake -GetLatest:$ReInstallThirdPartyModules.IsPresent
Install-ModuleWithPsGet -Module common-utils -ModulePath $psModuleRoot\common-utils.psm1 -GetLatest:$ReInstallLocalModules.IsPresent
Install-ModuleWithPsGet -Module msbuild -ModulePath $psModuleRoot\msbuild.psm1 -GetLatest:$ReInstallLocalModules.IsPresent
Install-ModuleWithPsGet -Module test -ModulePath $psModuleRoot\test.psm1 -GetLatest:$ReInstallLocalModules.IsPresent
Install-ModuleWithPsGet -Module artifacts -ModulePath $psModuleRoot\artifacts.psm1 -GetLatest:$ReInstallLocalModules.IsPresent
Install-ModuleWithPsGet -Module semver -ModulePath $psModuleRoot\semver.psm1 -GetLatest:$ReInstallLocalModules.IsPresent

Invoke-Psake build-default.ps1 Initialise-It

Remove-Module [p]sget -ErrorAction SilentlyContinue
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue
Remove-Module [c]ommon-utils -ErrorAction SilentlyContinue
Remove-Module [m]sbuild -ErrorAction SilentlyContinue
Remove-Module [t]est -ErrorAction SilentlyContinue
Remove-Module [a]rtifacts -ErrorAction SilentlyContinue
Remove-Module [s]emver -ErrorAction SilentlyContinue