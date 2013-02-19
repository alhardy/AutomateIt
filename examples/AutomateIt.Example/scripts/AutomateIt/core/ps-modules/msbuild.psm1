$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

function Write-MsBuildInfo([string] $message) {
	Write-Host "[MsBuild] $message" -f blue
}

function Throw-MsBuildError([string] $message) {
	throw "[MsBuild-Error] $message"
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

	Import-Module $scriptPath\common-utils.psm1

	$netfxCurrent = Get-NetFxCurrent $netfxVersion
	$msbuildExe = dir "$netfxCurrent\msbuild.exe"

	if (-not(Test-Path($msbuildExe))) { Throw-MsBuildError "Could not locate msbuild executable at $MsBuildExe" }

	Write-MsBuildInfo "Building $Solutions"

	$Solutions | % {
		$solution = dir $_						
		exec { &$msbuildExe $solution /target:Rebuild /ds /m:4 /p:RunCodeAnalysis=$RunCodeAnalysis /p:OutDir=$OutDir /p:CopyToPublishedApplications=true /p:Configuration=$BuildConfiguration /v:d }
	}

	Remove-Module [c]ommon-utils
}

Export-ModuleMember Start-MsBuild