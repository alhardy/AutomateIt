function Get-NetFxPath(){
	$registryPath = "HKLM:\SOFTWARE\Microsoft\.NETFramework"
	$isSysWow64Os = Get-IsSysWow64Os
	if ($isSysWow64Os -eq $false) {$registryPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework"}
   	$registryItem = Get-ItemProperty -path $registryPath -name InstallRoot
   	return $registryItem.InstallRoot
}

function Get-VsInstallPath(){
		param(
				[parameter(Mandatory=$true)] 
				[string]$VsVersion
			 )
	$isSysWow64Os = Get-IsSysWow64Os
	$registryPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\$VsVersion"
	if ($isSysWow64Os -eq $false) {$registryPath = "HKLM:\SOFTWARE\Microsoft\VisualStudio\$VsVersion"}
	$registryItem = Get-ItemProperty -path $registryPath -name InstallDir
	return $registryItem.InstallDir
}

function Get-NetFxCurrent(){
	param(
			[parameter(Mandatory=$true)] 
			[string]$NetfxVersion
		  )
	$netfxInstallRoot = Get-NetFxPath
	return "$netfxInstallRoot\$NetfxVersion"
}

function Get-IsSysWow64Os(){
	$os = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture 
	return $os.OSArchitecture -eq "64-bit"
}

#TODO: Append build number from build server and don't use token replacement
function Update-GlobalAssemblyVersion($globalAssemblyInfo, $version, $buildConfiguration){			
	$new = (Get-Content $globalAssemblyInfo) -replace "{AssemblyVersion}", $version -replace "{AssemblyFileVersion}", $version -replace "{AssemblyConfiguration}", $buildConfiguration -replace "{Year}", (get-date).year
	Set-Content $globalAssemblyInfo $new
}

Export-ModuleMember Get-NetFxPath, Get-VsInstallPath, Get-NetFxCurrent, Get-IsSysWow64Os, Update-GlobalAssemblyVersion