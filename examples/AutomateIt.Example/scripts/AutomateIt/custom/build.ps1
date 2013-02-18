param(
		[switch]$GetLatestModules
	 )
$psModuleRoot = Resolve-Path ..\core\ps-modules

. .\build-config.ps1

Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Import-Module -Name $psModuleRoot\module-extensions.psm1 -Verbose -Force

Install-ModuleWithPsGet -Module psake -GetLatest:$GetLatestModules.IsPresent
Install-ModuleWithPsGet -Module common-utils -ModulePath $psModuleRoot\common-utils.psm1 -GetLatest:$GetLatestModules.IsPresent
Install-ModuleWithPsGet -Module msbuild -ModulePath $psModuleRoot\msbuild.psm1 -GetLatest:$GetLatestModules.IsPresent
Install-ModuleWithPsGet -Module test -ModulePath $psModuleRoot\test.psm1 -GetLatest:$GetLatestModules.IsPresent
Install-ModuleWithPsGet -Module artifacts -ModulePath $psModuleRoot\artifacts.psm1 -GetLatest:$GetLatestModules.IsPresent
Install-ModuleWithPsGet -Module semver -ModulePath $psModuleRoot\semver.psm1 -GetLatest:$GetLatestModules.IsPresent

Invoke-Psake ..\core\build\default.ps1 Package-It

Remove-Module [p]sget -ErrorAction SilentlyContinue
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue
Remove-Module [e]nv -ErrorAction SilentlyContinue
Remove-Module [t]est -ErrorAction SilentlyContinue
Remove-Module [M]Sbuild -ErrorAction SilentlyContinue
Remove-Module [s]emver -ErrorAction SilentlyContinue