function Write-MsBuildInfo([string] $message) {
	Write-Host "[MsBuild] $message" -f blue
}

function Throw-MsBuildError([string] $message) {
	throw "[MsBuild-Error] $message"
}

$availableModules = Get-Module -ListAvailable

if (-not($availableModules | where {$_.Name -eq "common-utils" })) {
	Throw-MsBuildError "Could not find module dependency. Install common-utils"	
}

if (-not(Get-Module module-extensions)) {
	Import-Module common-utils
}

function Start-MsBuild{
		param(
				[parameter(Mandatory=$true)] 
				[string[]]$Solutions, 
				[parameter(Mandatory=$true)] 
				[string]$OutDir, 
				[string]$BuildConfiguration="Release", 				
				[bool]$RunCodeAnalysis=$True				
			 )			

	$netfxCurrent = Get-NetFxCurrent $netfxVersion
	$msbuildExe = dir "$netfxCurrent\msbuild.exe"

	if (-not(Test-Path($msbuildExe))) { Throw-MsBuildError "Could not locate msbuild executable at $MsBuildExe" }

	Write-MsBuildInfo "Building $Solutions"

	$Solutions | % {
		$solution = dir $_						
		exec { &$msbuildExe $solution /target:Rebuild /ds /m:4 /p:RunCodeAnalysis=$RunCodeAnalysis /p:OutDir=$OutDir /p:CopyToPublishedApplications=true /p:Configuration=$BuildConfiguration /v:d }
	}
}

Export-ModuleMember Start-MsBuild