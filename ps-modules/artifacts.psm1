$base = Resolve-Path .
$nugetExe = "$base\nuget.exe"

function Write-Artifact([string] $message) {
	Write-Host "[Artifacts] $message" -f darkcyan
}

function Throw-ArtifactError([string] $message) {
	Write-Host "[Artifacts-Error] $message" -f darkcyan
}

if (-not(Test-Path "$nugetExe")){
	Write-Artifact "Downloading nuget.exe"
	(New-Object Net.WebClient).DownloadFile("https://nuget.org/nuget.exe", "$nugetExe")
}

function Export-Artifacts{
	param(
			[parameter(Mandatory=$true)] 			
			[string]$ParentDirectoryContainingCompiledApplications,
			[parameter(Mandatory=$true)] 
			[string]$NuspecDirectory,
			[parameter(Mandatory=$true)]
			[string]$OutputDirectory,
			[parameter(Mandatory=$true)]
			[string]$Version
		 )	

	if(-not(Test-Path $NuspecDirectory)){Throw-ArtifactError "$NuspecDirectory does not exist."}	
	if(-not(Test-Path $OutputDirectory)){Throw-ArtifactError "$OutputDirectory does not exist."}	

	if (-not(Test-Path $ParentDirectoryContainingCompiledApplications)){
		Write-Artifact "There are no applications to package in directory $ParentDirectoryContainingCompiledApplications"
		return
	}

	$fc = New-Object -com scripting.filesystemobject
    $folder = $fc.getfolder($ParentDirectoryContainingCompiledApplications)
    Write-Artifact "Packing applications in $ParentDirectoryContainingCompiledApplications from nuget specs"
	foreach($app in $folder.subfolders) {									
		if (Test-Path ($NuspecDirectory + "\" + $app.Name + ".nuspec")){
			Write-Artifact "Packing" $app.Name "-version:" $Version
			Copy-Item ($NuspecDirectory + "\" + $app.Name + ".nuspec") $app.Path
			Write-Artifact "Executing: $nugetExe  pack ($app.Path + "\" + $app.Name + ".nuspec") -OutputDirectory $OutputDirectory -version $Version"
			exec { &$nugetExe pack ($app.Path + "\" + $app.Name + ".nuspec") -OutputDirectory $OutputDirectory -version $Version  }
		}		
	}
	Write-Artifact "Finished packing applications in $ParentDirectoryContainingCompiledApplications from nuget specs"
}

function Edit-ArtifactSpecsVersion {	
	param(
			[parameter(Mandatory=$true)] 
			[string]$NuspecDirectory,
			[parameter(Mandatory=$true)] 
			[string]$Version
		 )

	if(-not(Test-Path $NuspecDirectory)){Throw-ArtifactError "$NuspecDirectory does not exist."}	

	Write-Artifact "Starting to update nuget specs version"
	$specs = Get-ChildItem $NuspecDirectory *.nuspec -recurse
	$specs | ForEach-Object {
		$nuspec = [xml](Get-Content $_.FullName)		
		$nuspec.package.metadata.version = $Version
		$nuspec.save($_.FullName)		
	}
	Write-Artifact "Nuget specs version successfully updated to $Version"
}

function Publish-Artifacts {		
	param(
			[parameter(Mandatory=$true)] 
			[string]$AccessKey,
			[parameter(Mandatory=$true)] 
			[string]$Source,
			[parameter(Mandatory=$true)]
			[string]$ArtifactDirectory
	 	)

	if(-not(Test-Path $ArtifactDirectory)){Throw-ArtifactError "Artifact directory $ArtifactDirectory does not exist."}	

	Write-Artifact "Executing: $nugetExe setapikey $AccessKey -source $Source"
	exec { &$nugetExe setapikey $AccessKey -source $Source }
	$nupkgs = Get-ChildItem $ArtifactDirectory *.nupkg -recurse	
	$nupkgs | ForEach-Object {								
		exec { &$nugetExe push $_.FullName -s $Source }
	}	
}

function Install-Artifact {
	param(
			[string]$Version,
			[string]$Id,
			[parameter(Mandatory=$true)] 
			[string]$Source,
			[parameter(Mandatory=$true)] 
			[string]$OutputDirectory
		 )
	
	if(-not(Test-Path $OutputDirectory)){Throw-ArtifactError "OutputDirectory directory $OutputDirectory does not exist."}		

	Write-Artifact "Executing: $nugetExe install $Id -Version $Version -OutputDirectory $OutputDirectory -Source $Source"
	exec { &$nugetExe install $Id -Version $Version -OutputDirectory $OutputDirectory -Source $Source }
}

Export-ModuleMember Export-Artifacts, Edit-ArtifactSpecsVersion, Publish-Artifacts, Install-Artifact
