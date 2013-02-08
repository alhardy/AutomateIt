param($installPath, $toolsPath, $package, $project)
$root = Resolve-Path .\
$scriptDirName = "AutomateItScripts"

if(Test-Path "$root\scripts\$scriptDirName"){
    Remove-Item "$root\scripts\$scriptDirName"
}
