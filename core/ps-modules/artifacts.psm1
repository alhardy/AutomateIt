$base = Resolve-Path .
$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$nugetExe = "$base\nuget.exe"

function Write-Artifact([string] $message) {
	Write-Host "[Artifacts] $message" -f darkcyan
}

function Throw-ArtifactError([string] $message) {
	Write-Host "[Artifacts-Error] $message" -f darkcyan
	exec { cmd /c exit (1) }
}

function EnsureNugetExists(){
	if (-not(Test-Path "$nugetExe")){	
		Write-Artifact "Downloading nuget.exe to $nugetExe"
		$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
		$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
		$wc = new-object system.net.WebClient
		$wc.proxy = $proxy
		$wc.DownloadFile("https://nuget.org/nuget.exe", "$nugetExe")
	}
}

function Export-ZipArtifacts{
	param(
			[parameter(Mandatory=$true)] 			
			[string]$ParentDirectoryContainingCompiledApplications,			
			[parameter(Mandatory=$true)]
			[string]$OutputDirectory,
			[parameter(Mandatory=$true)]
			[string]$Version
		 )	

	if(-not(Test-Path $OutputDirectory)){Throw-ArtifactError "$OutputDirectory does not exist."}		

	if (-not(Test-Path $ParentDirectoryContainingCompiledApplications)){
		Write-Artifact "There are no applications to package in directory $ParentDirectoryContainingCompiledApplications"
		return
	}

	Import-Module $scriptPath\PowerZip.psm1

	$fc = New-Object -com scripting.filesystemobject
    $folder = $fc.getfolder($ParentDirectoryContainingCompiledApplications)
    Write-Artifact "Zipping applications in $ParentDirectoryContainingCompiledApplications"
	foreach($app in $folder.subfolders) {									
		Write-Artifact "Zipping" $app.Name "-version:" $Version
		$appZipName = $app.Name, $Version, "zip" -Join "."
		$zipFile = $OutputDirectory, $appZipName
		New-Zip -Source $app.Path -ZipFile $zipFile -Recurse -DeleteAfterZip
	}
	Write-Artifact "Finished zipping applications in $ParentDirectoryContainingCompiledApplications"

	Remove-Module [P]owerZip
}

function Export-NugetArtifacts{
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

	EnsureNugetExists

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

function Edit-NugetArtifactSpecsVersion {	
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

function Publish-NugetArtifacts {		
	param(
			[parameter(Mandatory=$true)] 
			[string]$AccessKey,
			[parameter(Mandatory=$true)] 
			[string]$Source,
			[parameter(Mandatory=$true)]
			[string]$ArtifactDirectory
	 	)	

	if(-not(Test-Path $ArtifactDirectory)){Throw-ArtifactError "Artifact directory $ArtifactDirectory does not exist."}	

	EnsureNugetExists

	Write-Artifact "Executing: $nugetExe setapikey $AccessKey -source $Source"
	exec { &$nugetExe setapikey $AccessKey -source $Source }
	$nupkgs = Get-ChildItem $ArtifactDirectory *.nupkg -recurse	
	$nupkgs | ForEach-Object {								
		exec { &$nugetExe push $_.FullName -s $Source }
	}	
}

function Install-NugetArtifact {
	param(
			[string]$Version,
			[string]$Id,
			[parameter(Mandatory=$true)] 
			[string]$Source,
			[parameter(Mandatory=$true)] 
			[string]$OutputDirectory
		 )
	
	if(-not(Test-Path $OutputDirectory)){Throw-ArtifactError "OutputDirectory directory $OutputDirectory does not exist."}		

	EnsureNugetExists

	Write-Artifact "Executing: $nugetExe install $Id -Version $Version -OutputDirectory $OutputDirectory -Source $Source"
	exec { &$nugetExe install $Id -Version $Version -OutputDirectory $OutputDirectory -Source $Source }
}

Export-ModuleMember Export-ZipArtifacts, Export-NugetArtifacts, Edit-NugetArtifactSpecsVersion, Publish-NugetArtifacts, Install-NugetArtifact
