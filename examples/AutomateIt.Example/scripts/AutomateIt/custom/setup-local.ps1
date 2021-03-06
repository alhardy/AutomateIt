param(
        [switch]$ReInstallThirdPartyModules # Downloads latest third party modules and re-installs
     )

$global:scriptPath = Split-Path $script:MyInvocation.MyCommand.Path -parent
write-warning $scriptPath
if(-not(Test-Path "$scriptPath\user-config.ps1" )) {
    throw "user-config.ps1 does not exist."
}

$psModuleRoot = Resolve-Path $scriptPath\..\core\ps-modules

Remove-Module [p]sget -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [l]ocal-webbootstrap -ErrorAction SilentlyContinue

Import-Module -Name $psModuleRoot\module-extensions -Verbose -Force
Install-ModuleWithPsGet -Module psake -GetLatest:$ReInstallThirdPartyModules.IsPresent
Import-Module -Name $psModuleRoot\local-webboostrap -Verbose -Force

Invoke-Psake $scriptPath\localweb-default.ps1 Start-LocalWebFromConfig

Remove-Module [p]sget -ErrorAction SilentlyContinue
Remove-Module [p]sake -ErrorAction SilentlyContinue
Remove-Module [m]odule-extensions -ErrorAction SilentlyContinue
Remove-Module [l]ocal-webbootstrap -ErrorAction SilentlyContinue