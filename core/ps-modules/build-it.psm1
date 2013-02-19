$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

function getNugetAccessKey() {
    if ((Test-Path $accessKeyFilePath)){
            $nugetApiKey = Get-Content $accessKeyFilePath
            return [string]$nugetApiKey.trim()              
    } else {
            Write-Warning "$accessKeyFilePath/nuget-access-key does not exist. Attempting to push packages to a remote repository may require this key."
    }
}

function Initialize-Build {
    Write-Host "Initialising build..."  
        
    if (Test-Path $outputDirectory){ Remove-Item -Force -recurse $outputDirectory -ErrorAction SilentlyContinue }       
    New-Item $outputDirectory, $artifactsDirectory, $publishedWebsitesDirectory, $publishedApplicationsDirectory, $testResultsDirectory -type directory 
}

function Version-Build {
    Write-Host "Versioning..."   
    
    Import-Module $scriptPath\semver.psm1

    $BuildNumber = 0
    if ((Test-Path env:$buildNumberEnv)){
        $BuildNumber = (Get-Item env:$buildNumberEnv).Value
        Set-GlobalAssemblyFileVersion -BuildVersion $BuildNumber -Directory $globalAssemblyInfoFile
    }
    if ((Test-Path env:$buildTimeStampEnv)){
        $BuildNumber += "." + (Get-Item env:$buildTimeStampEnv).Value
    }

    Set-GlobalAssemblyInfoBuildVersion -BuildVersion $BuildNumber -Directory $globalAssemblyInfoFile 

    Remove-Module [s]emver
}

function Set-BuildVersion {
    Write-Host "Versioning..."   
    
    Import-Module $scriptPath\semver.psm1

    $BuildNumber = 0
    if ((Get-Item env:$buildNumberEnv).Value){
        $BuildNumber = (Get-Item env:$buildNumberEnv).Value
        Set-GlobalAssemblyFileVersion -BuildVersion $BuildNumber -Directory $globalAssemblyInfoFile
    }
    if ((Get-Item env:$buildTimeStampEnv).Value){
        $BuildNumber += "." + (Get-Item env:$buildTimeStampEnv).Value
    }

    Set-GlobalAssemblyInfoBuildVersion -BuildVersion $BuildNumber -Directory $globalAssemblyInfoFile 

    Remove-Module [s]emver
}

function Test-Build {
    param(
            [parameter(Mandatory=$true)] 
            [string[]]$TestAssembliesPatterns, 
            [parameter(Mandatory=$true)]                
            [string]$TestResultsFile,                   
            [string]$TestSettings, 
            [string]$TestRunSettings                
         )
    Write-Host "Testing build..."

    Import-Module $scriptPath\test.psm1

    Start-MsTest -TestAssembliesPatterns $TestAssembliesPatterns -TestResultsFile $TestResultsFile -TestSettings $TestSettings -TestRunSettings $TestRunSettings

    Remove-Module [t]est
}

function Start-Build {  
    param(
            [parameter(Mandatory=$true)] 
            [string[]]$Solutions, 
            [parameter(Mandatory=$true)] 
            [string]$OutDir, 
            [string]$BuildConfiguration="Release",              
            [bool]$RunCodeAnalysis=$True                
         )  
    Write-Host "Building..."

    Import-Module $scriptPath\msbuild.psm1

    Start-MsBuild -Solutions $Solutions -OutDir $OutDir -BuildConfiguration $BuildConfiguration -RunCodeAnalysis $RunCodeAnalysis

    Remove-Module [m]sbuild
}

function Export-BuildArtifactsAsZip{
    param(
            [parameter(Mandatory=$true)]            
            [string]$PublishedApplicationsDirectory,
            [parameter(Mandatory=$true)]            
            [string]$PublishedWebsitesDirectory,            
            [parameter(Mandatory=$true)]
            [string]$OutputDirectory            
         )  

    Write-Host "Packaging artifacts as zips..." 

    Import-Module $scriptPath\semver.psm1
    $version = Get-GlobalAssemblyInfoFileVersionString -Directory $globalAssemblyInfoFile
    Remove-Module [s]emver

    if(-not($version)) { Write-Error "Version information is missing" }
    
    Import-Module $scriptPath\artifacts.psm1

    Export-ZipArtifacts -ParentDirectoryContainingCompiledApplications $PublishedApplicationsDirectory -OutputDirectory $OutputDirectory -Version $version
    Export-ZipArtifacts -ParentDirectoryContainingCompiledApplications $PublishedWebsitesDirectory -OutputDirectory $OutputDirectory -Version $version    

    Remove-Module [a]rtifacts
}

function Export-BuildArtifactsAsNuget { 
    param(
            [parameter(Mandatory=$true)]            
            [string]$PublishedApplicationsDirectory,
            [parameter(Mandatory=$true)]            
            [string]$PublishedWebsitesDirectory,
            [parameter(Mandatory=$true)] 
            [string]$NuspecDirectory,
            [parameter(Mandatory=$true)]
            [string]$OutputDirectory            
         )  

    Write-Host "Packaging artifacts as nupkgs..." 

    Import-Module $scriptPath\semver.psm1
    $version = Get-GlobalAssemblyInfoVersionString -Directory $globalAssemblyInfoFile
    Remove-Module [s]emver

    if(-not($version)) { Write-Error "Cannot package nupkgs, version information is missing" }
    
    Import-Module $scriptPath\artifacts.psm1

    Export-NugetArtifacts -ParentDirectoryContainingCompiledApplications $PublishedApplicationsDirectory -NuspecDirectory $NuspecDirectory -OutputDirectory $OutputDirectory -Version $version
    Export-NugetArtifacts -ParentDirectoryContainingCompiledApplications $PublishedWebsitesDirectory -NuspecDirectory $NuspecDirectory -OutputDirectory $OutputDirectory -Version $version    

    Remove-Module [a]rtifacts
}

function Publish-NugetBuildArtifacts {
    param(
            [parameter(Mandatory=$true)] 
            [string]$Source,
            [parameter(Mandatory=$true)]
            [string]$ArtifactDirectory
        )
    Write-Host "Publishing to deployment artifact server..." 

    $nugetAccessKey = getNugetAccessKey($nugetAccessKeyPath)

    Import-Module $scriptPath\artifacts.psm1

    if($nugetAccessKey){
        Publish-NugetArtifacts -AccessKey $nugetAccessKey -Source $Source -ArtifactDirectory $ArtifactDirectory
    }else {
        Publish-NugetArtifacts -Source $Source -ArtifactDirectory $ArtifactDirectory
    }

    Remove-Module [a]rtifacts
}

Export-ModuleMember Initialize-Build, Version-Build, Set-BuildVersion, Test-Build, Start-Build, Export-BuildArtifactsAsZip, Export-BuildArtifactsAsNuget, Publish-NugetBuildArtifacts