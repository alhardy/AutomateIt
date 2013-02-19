#Reference http://semver.org/

function Write-Semver([string] $message) {
	Write-Host "[Semver] $message" -f cyan
}

function Throw-SemverError([string] $message) {
	Write-Host "[Semver-Error] $message" -f cyan
	exec { cmd /c exit (1) }
}

function UpdateGlobalAssemblyInfo {
	param(			
			[parameter(Mandatory=$true)] 
		  	[string] $Directory,
		  	[parameter(Mandatory=$true)] 
		  	[string] $Pattern,
		  	[parameter(Mandatory=$true)] 
		  	[string] $VersionString,
		  	[parameter(Mandatory=$true)] 
		  	[string] $Name
		 )

	$fileName = "GlobalAssemblyInfo.cs"

	Get-ChildItem $Directory -Recurse -Filter $fileName | ForEach-Object {
		$currentFile = $_.FullName
		$tempFile = ("{0}.tmp" -f $_.FullName)
 
		Get-Content $currentFile | ForEach-Object {
			% { $_ -Replace $Pattern, $VersionString }			
		} | Set-Content $tempFile
 
		Remove-Item $currentFile
		Rename-Item $tempFile $currentFile
 
		Write-Semver "Updated $Name version to: $VersionString in $currentFile"
	}
}

function CloneObject{
	param([PSObject] $object = $(throw "Object is a required parameter."))
 
	$clone = New-Object PSObject
	$object.psobject.properties | % { $clone | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value }
 
	return $clone
}

function BumpNumericVersion{
	param(
			[parameter(Mandatory=$true)] 
			[int] $Current
		 )
	return $Current + 1;
} 

function Get-GlobalAssemblyInfoVersion {
	param(
		 	[string]$Directory = (Resolve-Path .)	 	
		 )
 	
	$versionPattern = 'AssemblyVersion\("([0-9]+)+\.([0-9]+)+\.([0-9]+)"\)' 	
	$fileName = "GlobalAssemblyInfo.cs" 
	$assemblyInfo = Get-ChildItem $Directory -Recurse | 
						Where-Object {$_.Name -eq $fileName} | 
						Select-Object -First 1
 
	if(!$assemblyInfo) { throw "Could not find assembly info file" }
 
	$matchedLine = Get-Content $assemblyInfo.FullName |
					   Where-Object { $_ -match $versionPattern } |
					   Select-Object -First 1
 
	if(!$matchedLine) { throw "Could not find line containing assembly version in assembly info file" }					   
 
	$major, $minor, $patch = ([regex]$versionPattern).matches($matchedLine) |
										  foreach {$_.Groups } | 
										  Select-Object -Skip 1
 
	return New-Object PSObject -Property @{
		Major = $major.Value
		Minor = $minor.Value		
		Patch = $patch.Value		
	}
}

function Get-GlobalAssemblyInfoFileVersionString {
	param(
		 	[string]$Directory = (Resolve-Path .)	 	
		 )
 	
	$versionPattern = 'AssemblyFileVersion\("([0-9]+)+\.([0-9]+)+\.([0-9]+)+\.([0-9]+)"\)' 
	$fileName = "GlobalAssemblyInfo.cs" 
	$assemblyInfo = Get-ChildItem $Directory -Recurse | 
						Where-Object {$_.Name -eq $fileName} | 
						Select-Object -First 1
 
	if(!$assemblyInfo) { throw "Could not find assembly info file" }
 
	$matchedLine = Get-Content $assemblyInfo.FullName |
					   Where-Object { $_ -match $versionPattern } |
					   Select-Object -First 1
 
	if(!$matchedLine) { throw "Could not find line containing assembly version in assembly info file" }					   
 
	$major, $minor, $patch, $revision = ([regex]$versionPattern).matches($matchedLine) |
										  foreach {$_.Groups } | 
										  Select-Object -Skip 1
 
	$version = New-Object PSObject -Property @{
		Major = $major.Value
		Minor = $minor.Value		
		Patch = $patch.Value
		Revision = $revision.Value		
	}
 
	$versionString = $version.Major + "." + $version.Minor + "." + $version.Patch + "." + $version.Revision
	return $versionString	
}

function Get-GlobalAssemblyInfoVersionString {
	param(
		 	[string]$Directory = (Resolve-Path .)	 	
		 )	

	$version = Get-GlobalAssemblyInfoVersion -Directory $Directory
	$versionString = $version.Major + "." + $version.Minor + "." + $version.Patch	
	return $versionString
}

function Set-GlobalAssemblyInfoBuildVersion {
	param(
			[parameter(Mandatory=$true)] 
			[string]$BuildVersion,
			[string]$Directory = (Resolve-Path .)
		 )
 
 	$assemblyInformationalVersionPattern = '(?<=\[assembly: AssemblyInformationalVersion\(").*(?="\)\])'
	$versionString = Get-GlobalAssemblyInfoVersionString -Directory $Directory
	$versionString += "+build.$BuildVersion"

	UpdateGlobalAssemblyInfo -Directory $Directory -Pattern $assemblyInformationalVersionPattern -VersionString $versionString -Name "AssemblyInformationalVersion"
}

function Set-GlobalAssemblyFileVersion {
	param(
			[parameter(Mandatory=$true)] 
			[string] $BuildVersion,
			[string] $Directory = (Resolve-Path .)
		 )
 
 	$assemblyFileVersionPattern = '(?<=\[assembly: AssemblyFileVersion\(").*(?="\)\])'
	$versionString = Get-GlobalAssemblyInfoVersionString -Directory $Directory
	$versionString += ".$BuildVersion"

	$buildVersion = 0
	if ((Get-Item env:$buildNumberEnv).Value){
        $buildVersion = (Get-Item env:$buildNumberEnv).Value
    }

    $version += ".$buildVersion"

	UpdateGlobalAssemblyInfo -Directory $Directory -Pattern $assemblyFileVersionPattern -VersionString $versionString -Name "AssemblyFileVersion"
}
 
function Bump-Version {
	param(
			[parameter(Mandatory=$true)] 
			[string]$Part,			
			[string]$Directory = (Resolve-Path .)
		  )
 
	$version = Get-GlobalAssemblyInfoVersion -Directory $Directory
	$bumpedVersion = CloneObject -Object $version
 
	switch -wildcard ($Part)
	{
		"ma*" { $bumpedVersion.Major = BumpNumericVersion -Current $version.Major }
		"mi*" { $bumpedVersion.Minor = BumpNumericVersion -Current $version.Minor }
		"p*" { $bumpedVersion.Patch = BumpNumericVersion -Current $version.Patch }
		"b*" { throw "Use Set-BuildVersion to update the build version part" }
		default { throw "Parameter Part should be: minor, major, patch or build"}
	}
 
	if($bumpedVersion.Major -eq $version.Major -and 
	   $bumpedVersion.Minor -eq $version.Minor -and
	   $bumpedVersion.Patch -eq $version.Patch)
	{
		Write-Semver "Version didn't change"
	}
 
	Set-GlobalAssemblyInfoVersion -Directory $Directory -BumpedVersion $bumpedVersion
}

function Set-GlobalAssemblyInfoVersion{
	param(
			[parameter(Mandatory=$true)] 
			[PSObject] $bumpedVersion,
			[string] $Directory = (Resolve-Path .)	  	
		 )
 
 	$assemblyVersionPattern = '(?<=\[assembly: AssemblyVersion\(").*(?="\)\])'
 	$assemblyFileVersionPattern = '(?<=\[assembly: AssemblyFileVersion\(").*(?="\)\])'
 
	$version = ("{0}.{1}.{2}" -f $bumpedVersion.Major, $bumpedVersion.Minor, $bumpedVersion.Patch)	

	UpdateGlobalAssemblyInfo -Directory $Directory -Pattern $assemblyVersionPattern -VersionString $version -Name "AssemblyVersion"
	UpdateGlobalAssemblyInfo -Directory $Directory -Pattern $assemblyFileVersionPattern -VersionString $version -Name "AssemblyFileVersion"
}

Export-ModuleMember Bump-Version, Get-GlobalAssemblyInfoVersionString, Get-GlobalAssemblyInfoFileVersionString, Get-GlobalAssemblyInfoVersion, Set-GloablAssemblyInfoVersion, Set-GlobalAssemblyInfoBuildVersion, Set-GlobalAssemblyFileVersion