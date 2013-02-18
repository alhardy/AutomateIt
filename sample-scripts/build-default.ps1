$coreBuild = Resolve-Path ..\core\build\default.ps1
. $coreBuild

task Initialise-It {       
    InitialiseBuild
}

task Version-It -depends Initialise-It {
    VersionBuild
}

task Build-It -depends Initialise-It, Version-It {
    Build -Solutions $solutions -OutDir $outputDirectory -BuildConfiguration $buildConfiguration -RunCodeAnalysis $runCodeAnalaysis
}

task Test-It -depends Build-It {
    TestBuild -TestAssembliesPatterns $testAssemblyPattern -TestResultsFile $testResultsReport -TestSettings $mstestSettings -TestRunSettings $mstestRunSettings
}

task Package-It -depends Test-It {    
    PackageBuildArtifacts -PublishedApplicationsDirectory $publishedApplicationsDirectory -PublishedWebsitesDirectory $publishedWebsitesDirectory -NuspecDirectory $nugetSpecs -OutputDirectory $artifactsDirectory -Version $version
}

task PackageAndPush-It -depends Package-It {    
    PublishBuildArtifacts -AccessKey $nugetAccessKey -Source $nugetSource -ArtifactDirectory $artifactsDirectory
}

task PackageWithTestsAndPush-It -depends Test-It, PackageAndPush-It { }