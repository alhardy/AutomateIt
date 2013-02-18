function getVersion {  
    $versionPath = "$baseDirectory\version"
    if (Test-Path $versionPath){
		$version = get-content $versionPath
    	return [string]$version.trim()          
    } else{
    	Write-Warning "$versionPath does not exist. This may be required to update the Global Assembly info."
    } 
}       

function getNugetAccessKey($accessKeyFilePath) {
    if ((test-path $accessKeyFilePath)){
            $nugetApiKey = get-content $accessKeyFilePath
            return [string]$nugetApiKey.trim()              
    } else {
            Write-Warning "$accessKeyFilePath/nuget-access-key does not exist. Attempting to push packages to a remote repository may require this key."
    }
}