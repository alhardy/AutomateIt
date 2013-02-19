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
    Export-BuildArtifactsAsNuget -PublishedApplicationsDirectory $publishedApplicationsDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory
}

task Zip-It -depends Test-It {
	Export-BuildArtifactsAsZip -PublishedApplicationsDirectory $publishedApplicationsDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -OutputDirectory $artifactsDirectory	
}

task PackageAndNugetPush-It -depends NugetPack-It {	
    Publish-NugetBuildArtifacts -AccessKey $nugetAccessKey -Source $nugetSource -ArtifactDirectory $artifactsDirectory
}