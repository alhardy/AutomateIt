task Initialize-It {	   
    Initialize-Build
}

task Version-It -depends Initialize-It {
    Version-Build
}

task Build-It -depends Initialize-It, Version-It {
    Start-Build -Solutions $solutions -OutDir $outputDirectory -BuildConfiguration $buildConfiguration -RunCodeAnalysis $runCodeAnalaysis
}

task Test-It -depends Build-It {
	Test-Build -TestAssembliesPatterns $testAssemblyPattern -TestResultsFile $testResultsReport -TestSettings $mstestSettings -TestRunSettings $mstestRunSettings
}

task Package-It -depends Test-It {    
    Export-BuildArtifacts -PublishedApplicationsDirectory $publishedApplicationsDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
}

task PackageAndPush-It -depends Package-It {	
    Publish-BuildArtifacts -AccessKey $nugetAccessKey -Source $nugetSource -ArtifactDirectory $artifactsDirectory
}

task PackageWithTestsAndPush-It -depends Test-It, PackageAndPush-It { }