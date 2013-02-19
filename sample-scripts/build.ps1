param(
        [switch]$ReInstallThirdPartyModules # Downloads latest third party modules and re-installs
     )
$psModuleRoot = Resolve-Path ..\core\ps-modules

. .\build-config.ps1

Remove-Module [b]uild-it -ErrorAction SilentlyContinue
Import-Module $psModuleRoot\build-it.psm1
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Import-Module -Name $psModuleRoot\module-extensions.psm1 -Verbose -Force
Install-ModuleWithPsGet -Module psake -GetLatest:$ReInstallThirdPartyModules.IsPresent

Invoke-Psake build-default.ps1 Zip-It

Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue