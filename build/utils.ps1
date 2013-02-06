function getVersion {  
    $versionPath = "$baseDirectory\version"
    $version = get-content $versionPath
    return [string]$version.trim()          
}       

function getNugetAccessKey($accessKeyFilePath) {
    if ((test-path $accessKeyFilePath)){
            $nugetApiKey = get-content $accessKeyFilePath
            return [string]$nugetApiKey.trim()              
    } else {
            throw "$accessKeyFilePath/nuget-access-key does not exist. This file containing the nuget repository is required to continue"
    }
}