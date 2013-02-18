#scripts
. .\utils.ps1

#locals
$script:version = Get-GlobalAssemblyInfoVersionString -Directory $globalAssemblyInfoFile
$script:nugetAccessKey = getNugetAccessKey($nugetAccessKeyPath)

task Initialise-It {
	"Initialising build..."  
        
    if (Test-Path $outputDirectory){ Remove-Item -Force -recurse $outputDirectory -ErrorAction SilentlyContinue }		
	New-Item $outputDirectory, $artifactsDirectory, $publishedWebsitesDirectory, $publishedApplicationsDirectory, $testResultsDirectory -type directory	
}

task Test-It -depends Build-It {
	"Testing build..."

	Start-MsTest -TestAssembliesPatterns $testAssemblyPattern -TestResultsFile $testResultsReport -TestSettings $mstestSettings -TestRunSettings $mstestRunSettings
}

task Build-It -depends Initialise-It, Version-It {
	"Building..."
	
	Start-MsBuild -Solutions $solutions -OutDir $outputDirectory -BuildConfiguration $buildConfiguration -RunCodeAnalysis $runCodeAnalaysis
}

task Package-It -depends Test-It {    
    "Packaging artifacts as nupkgs..." 

    if(-not($version)) { Write-Error "Cannot package nupkgs, version information is missing" }
    
	Export-Artifacts -ParentDirectoryContainingCompiledApplications $publishedApplicationsDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
    Export-Artifacts -ParentDirectoryContainingCompiledApplications $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version    
}

task PackageAndPush-It -depends Package-It {
	"Publishing to deployment artifact server..." 
		
    Publish-Artifacts -AccessKey $nugetAccessKey -Source $nugetSource -ArtifactDirectory $artifactsDirectory
}

task PackageWithTestsAndPush-It -depends Test-It, PackageAndPush-It { }

task Version-It -depends Initialise-It {
    "Versioning..."   
    
    $BuildNumber = 0
    if ((Get-Item env:$buildNumberEnv).Value){
        $BuildNumber = (Get-Item env:$buildNumberEnv).Value
        Set-GlobalAssemblyFileVersion -BuildVersion $BuildNumber -Directory $globalAssemblyInfoFile
    }
    if ((Get-Item env:$buildTimeStampEnv).Value){
        $BuildNumber += "." + (Get-Item env:$buildTimeStampEnv).Value
    }

    Set-GlobalAssemblyInfoBuildVersion -BuildVersion $BuildNumber -Directory $globalAssemblyInfoFile 
}