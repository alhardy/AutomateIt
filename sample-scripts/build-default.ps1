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

task NugetPack-It -depends Test-It {    
    Export-NugetArtifacts -PublishedApplicationsDirectory $publishedApplicationsDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
    Export-NugetArtifacts -PublishedApplicationsDirectory $publishedWebsitesDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
}

task Zip-It -depends Test-It {
	Export-ZipArtifacts -PublishedApplicationsDirectory $publishedApplicationsDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -OutputDirectory $artifactsDirectory -Version $version	
	Export-ZipArtifacts -PublishedApplicationsDirectory $publishedWebsitesDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -OutputDirectory $artifactsDirectory -Version $version
}

task NugetPackAndPush-It -depends Package-It {	
    Publish-NugetArtifacts -AccessKey $nugetAccessKey -Source $nugetSource -ArtifactDirectory $artifactsDirectory
}