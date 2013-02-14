$versionContent = get-content ".\version"
$version = [string]$versionContent.trim() 
New-Item .\packages -Type Directory -Force
Write-Host "Packing AutomateIt version: $version"
nuget pack .\nuget\AutomateIt.nuspec -Version "$version" -OutputDirectory .\packages