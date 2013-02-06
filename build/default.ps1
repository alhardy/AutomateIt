#scripts
. .\utils.ps1

#locals
$script:version = getVersion
$script:nugetAccessKey = getNugetAccessKey($nugetAccessKeyPath)

task Initialise-It {
	"Initialising build for version $version..."  
        
    if (Test-Path $outputDirectory){ Remove-Item -Force -recurse $outputDirectory -ErrorAction SilentlyContinue }		
	New-Item $outputDirectory, $artifactsDirectory, $publishedWebsitesDirectory, $publishedApplicationsDirectory, $testResultsDirectory -type directory	
}

task Test-It -depends Build-It {
	"Testing version $version"

	Start-MsTest -TestAssembliesPatterns $testAssemblyPattern -TestResultsFile $testResultsReport -TestSettings $mstestSettings -TestRunSettings $mstestRunSettings
}

task Build-It -depends Initialise-It, Version-It {
	"Building version $version..."
	
	Start-MsBuild -Solutions $solutions -OutDir $outputDirectory -BuildConfiguration $buildConfiguration -RunCodeAnalysis $runCodeAnalaysis
}

task Package-It -depends Build-It {    
    "Packaging artifacts as nupkgs for version $version..." 

    Export-Artifacts -ParentDirectoryContainingCompiledApplications $publishedApplicationsDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
    Export-Artifacts -ParentDirectoryContainingCompiledApplications $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
}

task PackageAndPush-It -depends Package-It {
	"Publishing version $version nupkgs to deployment artifact server..." 
		
    Publish-Artifacts -AccessKey $nugetAccessKey -Source $nugetSource -ArtifactDirectory $artifactsDirectory
}

task PackageWithTestsAndPush-It -depends Test-It, PackageAndPush-It { }

task Version-It -depends Initialise-It {
    "Setting nuspecs and global assembly version to version $version..."   
    
    Update-GlobalAssemblyVersion $globalAssemblyInfoFile $version $buildConfiguration    
}