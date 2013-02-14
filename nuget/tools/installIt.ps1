$toolsPath = Resolve-Path .\
$root = Resolve-Path ..\..\..\
$scriptDirName = "AutomateIt"

if(-not(Test-Path $root\env)){
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
    "Replaces all the files in the folder retaining the custom directory."

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
    
	if(-not(Test-Path "$root\scripts\$scriptDirName\core")){
        New-Item "$root\scripts\$scriptDirName\core" -Type Directory		
    }	        
	
	Copy-Item "$toolsPath\core\*" "$root\scripts\$scriptDirName\core" -Recurse -Force	
    if(-not(Test-Path "$root\scripts\$scriptDirName\custom")){ 
		write-host "didnt' find path"	
        New-Item "$root\scripts\$scriptDirName\custom" -Type Directory        
		Copy-Item "$toolsPath\sample\*" "$root\scripts\$scriptDirName\custom" -Recurse
    }
	
	Write-Host "$scriptDirName successfully installed"
}