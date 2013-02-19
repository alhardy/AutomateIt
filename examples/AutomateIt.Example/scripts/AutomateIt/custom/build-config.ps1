#directory locations
$global:baseDirectory =  Resolve-Path ../../../
$global:outputDirectory = "$baseDirectory\out"    
$global:publishedWebsitesDirectory = "$outputDirectory\_PublishedWebsites"
$global:publishedApplicationsDirectory = "$outputDirectory\_PublishedApplications"
$global:artifactsDirectory = "$outputDirectory\_Artifacts"  
$global:toolsDirectory = "$baseDirectory\Tools"    
$global:sourceDirectory = "$baseDirectory\src"  

#test variables
$global:testResultsDirectory = "$outputDirectory\_MsTestResults"
$global:testResultsReport = "$testResultsDirectory\testresults.trx"
$global:mstestSettings = "$baseDirectory\Local.testsettings"
$global:mstestRunSettings = "$baseDirectory\Local.runsettings"
$global:testAssemblyPattern = @("$outputDirectory\*.Tests.dll", "$outputDirectory\*.*Tests.dll")

#artifactProcessing variables
$global:nugetSpecs = "$baseDirectory\nuget_specs"
$global:nugetAccessKeyPath = "$baseDirectory\nuget-access-key"
$global:nugetSource = "http://local.nuget.com.au/"
$global:nugetInstallSource = "http://local.nuget.com.au/nuget"

#solution and build
$global:solutions = @("$baseDirectory\*.sln")
$global:globalAssemblyInfoFile = "$baseDirectory\GlobalAssemblyInfo.cs"
$global:buildConfiguration = "Release"
$global:runCodeAnalaysis = $false

#environment variables
$global:buildNumberEnv = "bamboo.buildNumber"
$global:buildTimeStampEnv = "bamboo.buildTimeStamp"

#netfx and visual studio
$global:vsVersion = "11.0" # used to determin mstest installation path
$global:netfxVersion = "v4.0.30319" # used to determine msbuild installation path
