#Reference http://semver.org/

function Bump-Version
{
	param(
			[parameter(Mandatory=$true)] 
			[string]$Part,
			[parameter(Mandatory=$true)] 
			[string]$Directory
		  )
 
	$version = Get-AssemblyInfoVersion -Directory $Directory -GlobalAssemblyInfo $true
	$bumpedVersion = Clone-Object -Object $version
 
	switch -wildcard ($Part)
	{
		"ma*" { $bumpedVersion.Major = Bump-NumericVersion -Current $version.Major }
		"mi*" { $bumpedVersion.Minor = Bump-NumericVersion -Current $version.Minor }
		"p*" { $bumpedVersion.Patch = Bump-NumericVersion -Current $version.Patch }
		"b*" { $bumpedVersion.Build = Bump-NumericVersion -Current $version.Build }
		default { throw "Parameter Part should be: minor, major, patch or build"}
	}
 
	if($bumpedVersion.Major -eq $version.Major -and 
	   $bumpedVersion.Minor -eq $version.Minor -and
	   $bumpedVersion.Patch -eq $version.Patch -and
	   $bumpedVersion.Build -eq $version.build)
	{
		Write-Host "Version didn't change"
	}
 
	Update-AssemblyInfoVersion -Directory $Directory -GlobalAssemblyInfo $true -BumpedVersion $bumpedVersion
}
 
function Bump-NumericVersion
{
	param(
			[parameter(Mandatory=$true)] 
			[int] $Current
		 )
	return $Current + 1;
}
 
 
function Clone-Object
{
	param([PSObject] $object = $(throw "Object is a required parameter."))
 
	$clone = New-Object PSObject
	$object.psobject.properties | % { $clone | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value }
 
	return $clone
} 

function Get-AssemblyInfoVersionString{
	param(
		 	[parameter(Mandatory=$true)] 
		 	[string] $Directory,
		 	[bool] $GlobalAssemblyInfo = $true
		 )	

	$version = Get-AssemblyInfoVersion -Directory $Directory -GlobalAssemblyInfo $GlobalAssemblyInfo
	$versionString = $version.Major + "." + $version.Minor + "." + $version.Patch
	if ($version.Build){
		$versionString = $versionString + $version.build
	}
	return $versionString
}

function Get-AssemblyInfoVersion
{
	param(
		 	[parameter(Mandatory=$true)] 
		 	[string] $Directory,
		 	[bool] $GlobalAssemblyInfo = $true
		 )
 
	$fileName = "AssemblyInfo.cs"
	$versionPattern = 'AssemblyVersion\("([0-9])+\.([0-9])+\.([0-9])+\-?(.*)?"\)'
 
	if($GlobalAssemblyInfo)
	{
		$fileName = "GlobalAssemblyInfo.cs"
	}
 
	$assemblyInfo = Get-ChildItem $Directory -Recurse | 
						Where-Object {$_.Name -eq $fileName} | 
						Select-Object -First 1
 
	if(!$assemblyInfo)
	{
		throw "Could not find assembly info file"
	}
 
	$matchedLine = Get-Content $assemblyInfo.FullName |
					   Where-Object { $_ -match $versionPattern } |
					   Select-Object -First 1
 
	if(!$matchedLine)
	{
		throw "Could not find line containing assembly version in assembly info file"
	}					   
 
	$major, $minor, $patch, $build = ([regex]$versionPattern).matches($matchedLine) |
										  foreach {$_.Groups } | 
										  Select-Object -Skip 1
 
 	$buildValue = [string]$build.Value.Replace("+build", "") 	
	return New-Object PSObject -Property @{
		Minor = $minor.Value
		Major = $major.Value
		Patch = $patch.Value
		Build = $buildValue
	}
}
 
function Update-AssemblyInfoVersion
{
	param(
			[parameter(Mandatory=$true)] 
			[PSObject] $bumpedVersion,
			[parameter(Mandatory=$true)] 
		  	[string] $Directory,
		  	[bool] $GlobalAssemblyInfo = $true
		 )
 
	$assemblyVersionPattern = 'AssemblyVersion\("([0-9])+\.([0-9])+\.([0-9])+\-?(.*)?"\)'
	$assemblyFileVersionPattern = 'AssemblyFileVersion\("([0-9])+\.([0-9])+\.([0-9])+\-?(.*)?"\)'
 
	$version = ("{0}.{1}.{2}" -f $bumpedVersion.Major, $bumpedVersion.Minor, $bumpedVersion.Patch)
	if($bumpedVersion.Build)
	{
		#TODO: change the information version to this, also update year		http://stackoverflow.com/questions/64602/what-are-differences-between-assemblyversion-assemblyfileversion-and-assemblyin
		$version = "{0}+build{1}" -f $version, $bumpedVersion.Build
	}
 
	$assemblyVersion = 'AssemblyVersion("' + $version + '")'
	$fileVersion = 'AssemblyFileVersion("' + $version + '")'
 
	$fileName = "AssemblyInfo.cs"
	if($GlobalAssemblyInfo)
	{
		$fileName = "GlobalAssemblyInfo.cs"
	}
 
	Get-ChildItem $Directory -Recurse -Filter $fileName | ForEach-Object {
		$currentFile = $_.FullName
		$tempFile = ("{0}.tmp" -f $_.FullName)
 
		Get-Content $currentFile | ForEach-Object {
			% { $_ -Replace $assemblyVersionPattern, $assemblyVersion } |
			% { $_ -Replace $assemblyFileVersionPattern, $fileVersion }
		} | Set-Content $tempFile
 
		Remove-Item $currentFile
		Rename-Item $tempFile $currentFile
 
		Write-Host "Updated version to: $version in $currentFile"
	}
}
 
Export-ModuleMember Bump-Version, Get-AssemblyInfoVersionString, Get-AssemblyInfoVersion, Update-AssemblyInfoVersion