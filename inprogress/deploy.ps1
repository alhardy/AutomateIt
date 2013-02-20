param(
    [parameter(Mandatory=$true)] 
    [string]$Env
)

Remove-Module [i]is6 -ErrorAction SilentlyContinue
Remove-Module [e]nv -ErrorAction SilentlyContinue
Import-Module .\iis6.psm1
Import-Module .\env.psm1

$baseDir = Resolve-Path .\
$websiteName = "testing"
$envVarPath = Resolve-Path .\env

Stop-IIS6WebSite -Name $websiteName

if (Test-Path $envVarPath){  	     	 
	Set-SensitiveData -ProjectPath $baseDir -Env $Env -EnvPath $envVarPath 
}   

Update-IIS6WebsitePhysicalPath -Name $websiteName -PhysicalPath $baseDir
Start-IIS6WebSite -Name $websiteName

Remove-Module [i]is6 -ErrorAction SilentlyContinue
Remove-Module [e]nv -ErrorAction SilentlyContinue
