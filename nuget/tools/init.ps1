param($installPath, $toolsPath, $package, $project)
$root = Resolve-Path .\
$scriptDirName = "AutomateItScripts"

if(-not(Test-Path env)){
    Write-Host "Creating env directory..."
    New-Item -Path env -Type Directory
}
if(-not(Test-Path "$root\scripts")){
    New-Item -Path "$root\scripts" -Type Directory
}

$install = $True

if(Test-Path "$root\scripts\$scriptDirName"){
    $title = "Replace Files"
    $message = "Do you want to replace files in $root\scripts\$scriptDirName?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Replaces all the files in the folder."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retains all the files in the folder."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
    {
        0 {
            $install = $True
          }
        1 {
            $install = $False
          }
    }  
} 

if($install){
    Write-Host "Copying scripts to $root\scripts\$scriptDirName"
    if(Test-Path "$root\scripts\$scriptDirName"){
        Remove-Item "$root\scripts\$scriptDirName" -Recurse
    }else{
        Move-Item "$toolsPath\scripts" "$root\scripts\$scriptDirName"
    }          
}

Write-Host "Complete"