$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#scripts
. $scriptPath\utils.ps1

#locals
$script:version = Get-GlobalAssemblyInfoVersionString -Directory $globalAssemblyInfoFile
$script:nugetAccessKey = getNugetAccessKey($nugetAccessKeyPath)

function InitialiseBuild {
    Write-Host "Initialising build..."  
        
    if (Test-Path $outputDirectory){ Remove-Item -Force -recurse $outputDirectory -ErrorAction SilentlyContinue }       
    New-Item $outputDirectory, $artifactsDirectory, $publishedWebsitesDirectory, $publishedApplicationsDirectory, $testResultsDirectory -type directory 
}

function VersionBuild {
    Write-Host "Versioning..."   
    
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

function TestBuild {
    param(
            [parameter(Mandatory=$true)] 
            [string[]]$TestAssembliesPatterns, 
            [parameter(Mandatory=$true)]                
            [string]$TestResultsFile,                   
            [string]$TestSettings, 
            [string]$TestRunSettings                
         )
    Write-Host "Testing build..."

    Start-MsTest -TestAssembliesPatterns $TestAssembliesPatterns -TestResultsFile $TestResultsFile -TestSettings $TestSettings -TestRunSettings $TestRunSettings
}

function Build {    
    param(
            [parameter(Mandatory=$true)] 
            [string[]]$Solutions, 
            [parameter(Mandatory=$true)] 
            [string]$OutDir, 
            [string]$BuildConfiguration="Release",              
            [bool]$RunCodeAnalysis=$True                
         )  
    Write-Host "Building..."

    Start-MsBuild -Solutions $Solutions -OutDir $OutDir -BuildConfiguration $BuildConfiguration -RunCodeAnalysis $RunCodeAnalysis
}

function PackageBuildArtifacts { 
    param(
            [parameter(Mandatory=$true)]            
            [string]$PublishedApplicationsDirectory,
            [parameter(Mandatory=$true)]            
            [string]$PublishedWebsitesDirectory,
            [parameter(Mandatory=$true)] 
            [string]$NuspecDirectory,
            [parameter(Mandatory=$true)]
            [string]$OutputDirectory,
            [parameter(Mandatory=$true)]
            [string]$Version
         )  

    Write-Host "Packaging artifacts as nupkgs..." 

    if(-not($version)) { Write-Error "Cannot package nupkgs, version information is missing" }
    
    Export-Artifacts -ParentDirectoryContainingCompiledApplications $PublishedApplicationsDirectory -NuspecDirectory $NuspecDirectory -OutputDirectory $OutputDirectory -Version $Version
    Export-Artifacts -ParentDirectoryContainingCompiledApplications $PublishedWebsitesDirectory -NuspecDirectory $NuspecDirectory -OutputDirectory $OutputDirectory -Version $Version    
}

function PublishBuildArtifacts {
    param(
            [parameter(Mandatory=$true)] 
            [string]$Source,
            [parameter(Mandatory=$true)]
            [string]$ArtifactDirectory
        )
    Write-Host "Publishing to deployment artifact server..." 
        
    Publish-Artifacts -AccessKey $nugetAccessKey -Source $Source -ArtifactDirectory $ArtifactDirectory
}