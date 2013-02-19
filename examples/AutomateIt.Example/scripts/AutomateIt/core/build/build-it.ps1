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

function Set-BuildVersion {
    Write-Host "Versioning..."   
    
    Import-Module .\semver.psm1

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

    Import-Module .\test.psm1

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

    Import-Module .\msbuild.psm1

	Start-MsBuild -Solutions $Solutions -OutDir $OutDir -BuildConfiguration $BuildConfiguration -RunCodeAnalysis $RunCodeAnalysis

    Remove-Module [m]sbuild
}

function Export-BuildArtifacts { 
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

    if(-not($Version)) { Write-Error "Cannot package nupkgs, version information is missing" }
    
    Import-Module .\artifacts.psm1


	Export-Artifacts -ParentDirectoryContainingCompiledApplications $PublishedApplicationsDirectory -NuspecDirectory $NuspecDirectory -OutputDirectory $OutputDirectory -Version $Version
    Export-Artifacts -ParentDirectoryContainingCompiledApplications $PublishedWebsitesDirectory -NuspecDirectory $NuspecDirectory -OutputDirectory $OutputDirectory -Version $Version    

    Remove-Module [a]rtifacts
}

function Publish-BuildArtifacts {
    param(
            [parameter(Mandatory=$true)] 
            [string]$Source,
            [parameter(Mandatory=$true)]
            [string]$ArtifactDirectory
        )
	Write-Host "Publishing to deployment artifact server..." 

    $nugetAccessKey = getNugetAccessKey($nugetAccessKeyPath)

    Import-Module .\artifacts.psm1

    if($nugetAccessKey){
        Publish-Artifacts -AccessKey $nugetAccessKey -Source $Source -ArtifactDirectory $ArtifactDirectory
    }else {
        Publish-Artifacts -Source $Source -ArtifactDirectory $ArtifactDirectory
    }

    Remove-Module [a]rtifacts
}

Export-ModuleMember Initialize-Build, Set-BuildVersion, Test-Build, Start-Build, Export-BuildArtifacts, Publish-BuildArtifacts