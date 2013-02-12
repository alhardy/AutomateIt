param(
[string]$SolutionDir,
[string]$ProjectName,
[string]$ProjectPath,
[string]$BuildConfiguration,
[string]$TargetPath
)
$source = Join-Path $SolutionDir Configuration\$ProjectName
$dest = Join-Path $TargetPath _Config
Write-Host "copying $source to $dest"
Copy-Item $source $dest -Recurse -Force

if($BuildConfiguration -eq "Debug"){
  Import-Module E:\Source\MySource-Git\AutomateIt\local\local.psm1
  Set-Environment -ProjectName $ProjectName -ProjectPath $TargetPath -Env dev -GetLatestModules
}