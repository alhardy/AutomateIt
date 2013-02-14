# TODO: Add member for VSTest.Console.exe - http://msdn.microsoft.com/en-us/library/vstudio/jj155796.aspx

function Write-Test([string] $message) {
	Write-Host "[Test] $message" -f Green
}

function Throw-MsBuildError([string] $message) {
	throw "[Test] $message"
}


$availableModules = Get-Module -ListAvailable

if (-not($availableModules | where {$_.Name -eq "common-utils" })) {
	Throw-TestError "Could not find module dependency. Install common-utils"	
}

if (-not(Get-Module common-utils)) {
	Import-Module common-utils
}

function Start-MsTest {
		param(
				[parameter(Mandatory=$true)] 
				[string[]]$TestAssembliesPatterns, 
				[parameter(Mandatory=$true)] 				
				[string]$TestResultsFile, 					
				[string]$TestSettings, 
				[string]$TestRunSettings				
			 )

	$vsInstallPath = Get-VsInstallPath $vsVersion
	$msTestExe = dir "$vsInstallPath\mstest.exe"

	$hasTestSettings = $TestSettings -ne $null -and $TestSettings.Length -gt 0 -and (Test-Path($TestSettings))	
	$hasTestRunSettings = $TestRunSettings -ne $null -and $TestRunSettings.Length -gt 0 -and (Test-Path($TestRunSettings))

	if (-not(Test-Path($msTestExe))) {
		throw "Could not locate mstest executable at $msTestExe" 
	}	
	if (-not $hasTestSettings) {
		Write-Test "$TestSettings does not exist" 
	}
	if (-not $hasTestRunSettings) {
		Write-Test "$TestRunSettings does not exist"
	}	

	$testAssemblies = @()
	$TestAssembliesPatterns | % {		
		$testAssemblies += dir $_		
	}

	if($testAssemblies.count -eq 0) {
		Write-Test "No tests assemblies were found"
		return
	}	

	$testAssemblies = $testAssemblies | select -uniq
	$testcontainer = "/testcontainer:" + ($testAssemblies -join " /testcontainer:")
	
	$command = "'$MsTestExe' $testcontainer /resultsfile:$TestResultsFile"

	if($hasTestSettings){		
		$command += " /testsettings:$TestSettings"
	} 

	if($hasTestRunSettings){
		$command += " /runconfig:$TestRunSettings"
	} 

	Write-Test "Executing $command"

	Invoke-Expression "& $command"
}

Export-ModuleMember Start-MsTest