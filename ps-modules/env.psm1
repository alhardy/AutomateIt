$script:SharedConfigDir = "SharedConfiguration"
$script:SharedSdFileName = "SharedConfiguration"

function replaceAppSettingsConfig($xml, $appSettings) { 				
	$appSettings.Keys | % {						
		$value = [string]$appSettings.Item($_)
		$xml.appSettings.selectsinglenode("add[@key='" + $_ + "']").value = $value
	}		
}

function replaceConnectionsConfig($xml, $connectionStrings) { 	
	$connectionStrings.Keys | % {
		$value = [string]$connectionStrings.Item($_)					
		$xml.connectionStrings.selectsinglenode("add[@name='" + $_ + "']").connectionString = $value
	}	
}

# Since the xml schema is not known, configs other than app settings and connection strings
# use a token replacement i.e. {token}
function replaceKeyInConfig($xml, $variables) {					
	$data = [string]$xml.OuterXml	
	$variables.Keys | % {
		$value = $variables.Item($_)
		if ($data.contains("{$_}")){
			$data = $data -replace "{$_}", $value			
		}else{
			Write-Env "MISSING key: $_"
		}
	}	
	return [xml]$data	
}

$script:possibleConfigPaths = @("Configuration", "Config", "bin")
$script:configUpdateMethod = @{
  "appSettings.config" = (gi function:replaceAppSettingsConfig);
  "connectionStrings.config" = (gi function:replaceConnectionsConfig);  
  "connections.config" = (gi function:replaceConnectionsConfig);  
}

function Set-SensitiveData {
		param(
				[parameter(Mandatory=$true)] 
				[string]$ProjectPath,								
				[parameter(Mandatory=$true)] 
				[string]$Env, 
				[parameter(Mandatory=$true)] 
				[string]$EnvPath,
				[string]$Version = $null
			 )			

	if (-not(Test-Path($EnvPath))) { throw "$EnvPath does not exist." }		
 
	$projectName = Split-Path $ProjectPath -Leaf -Resolve

	if($Version){		
		$ProjectPath = "$ProjectPath.$Version"
	}	

	if($Version){
		$projectName = $projectName -Replace ".$Version", ""
	}		

	$sensitiveData = Get-ChildItem -Path "$EnvPath" -Filter "$projectName*.sd"
	if (-not($sensitiveData)){
		Write-Env "Could not locate '$Env' sensitive data for $projectName. $EnvPath does not contain any $Env.sd files for this project." 
		return	
	}

	$projectConfigs = @()
	$projectConfigs += Get-ChildItem -Path $ProjectPath -Filter "*.config"
	$possibleConfigPaths | % {
		$configPath = "$ProjectPath\$_"
		if (Test-Path($configPath)) {
			$projectConfigs += Get-ChildItem -Path "$ProjectPath\$_" -Filter "*.config"
		}		
	}				
	Write-Env "SUBSTITUTING for project name: $projectName" -f blue	
	$sensitiveData | Where { $_.Name.EndsWith(".$Env.sd") } | % {
		$config = $_.Name
		$configPath = $_.FullName			
		Get-Content $configPath | Out-String | Invoke-Expression				
				
		$projectConfigs | Where { $_ } | % {			
			$fullName = $_.FullName
			$name = $_.Name
			$variableName = $_.Name -Replace ".config", ""
			$sharedVariableName = "shared_$variableName"
			if ($_.Name -eq "$projectName.exe.config"){
				# MSBuild converts app.configs to {exe_name.exe.config}
				$variableName = "app"
				$fullName = "$ProjectPath\$projectName.exe.config"
				$name = "projectName.exe.config"
			}
			elseif(Test-Path variable:$sharedVariableName){
				Get-Content "$EnvPath\$SharedSdFileName.$Env.sd" | Out-String | Invoke-Expression
				Write-Env "SHARED variable: $variableName for project config: $_"
			}
			if(Test-Path variable:$variableName) {
				Write-Env "MATCHED variable: $variableName for project config: $_"
				#Populate Sensitive data within the config			
				$xml = [xml](Get-Content $fullName)	
				$var = Get-Variable -Name $variableName -ValueOnly															
				$var
				if ($configUpdateMethod.ContainsKey($name)) { &$configUpdateMethod[$name] $xml $var }					
				else { $xml = replaceKeyInConfig $xml $var }		
				$xml.Save($fullName)
				Write-Env "POPULATED project config: $_"
			}								
		}					
	}
}

function Set-EnvVariables{
		param(
				[parameter(Mandatory=$true)] 
				[string]$ProjectPath,								
				[parameter(Mandatory=$true)] 
				[string]$Env, 
				[parameter(Mandatory=$true)] 
				[string]$EnvPath,
				[string]$Version = $null
			 )			

	if (-not(Test-Path($EnvPath))) { throw "Could not locate path containing environment variables. $EnvPath does not exist." }	
	if (-not(Test-Path("$EnvPath\$SharedConfigDir"))) { New-Item -Path "$EnvPath\$SharedConfigDir" -Type Directory }		

	if($Version){		
		$ProjectPath = "$ProjectPath.$Version"
	}

	$projectName = Split-Path $ProjectPath -Leaf -Resolve

	if($Version){
		$projectName = $projectName -Replace ".$Version", ""
	}	

	$projectEnvVariablePath = "$EnvPath\$projectName"	

	if (-not(Test-Path("$projectEnvVariablePath"))) { 
		Write-Env "Could not locate '$Env' variables for $projectName. $projectEnvVariablePath does not exist." 
		return
	}	

	$envConfigs = Get-ChildItem -Path "$projectEnvVariablePath" -Filter "*.$Env.env"	
	if ($envConfigs -eq $null){
		Write-Env "Could not locate '$Env' variables for $projectName. $projectEnvVariablePath does not contain any $Env.env files" 
		return	
	}

	$projectConfigs = @()
	$projectConfigs += Get-ChildItem -Path $ProjectPath -Filter "*.config"
	$possibleConfigPaths | % {
		$configPath = "$ProjectPath\$_"
		if (Test-Path($configPath)) {
			$projectConfigs += Get-ChildItem -Path "$ProjectPath\$_" -Filter "*.config"
		}		
	}				
	
	# Foreach environment config, find the matching project config
	$matchingConfigs = @{}	
	$envConfigs | % {
		$config = $_.Name				
		$foundConfig = $False
		# To avoid copy and paste of shared configuration files a placeholder 
		# config prefixed with shared. can be used to read configuration from a SharedConfiguration 
		# folder instead
		if($config.StartsWith("shared.")){
			$linkedConfig = $config -Replace "shared.", ""			
			$sharedConfig = "$EnvPath\$SharedConfigDir\$linkedConfig"			
			if(Test-Path($sharedConfig)){
				$matchingConfigs[$config] = $projectConfigs | where { "$_.$Env.env" -eq $linkedConfig }				
				$foundConfig = $True
			}
		}
		# MSBuild converts app.configs to {exe_name.exe.config}
		if($config.StartsWith("app.config") -and -not($foundConfig)){
			$exeConfig = "$ProjectPath\$projectName.exe.config"
			if (Test-Path($exeConfig)){
				$matchingConfigs[$config] = Get-ChildItem -Path $exeConfig
				$foundConfig = $True
			}			
		}		
		if(-not($foundConfig)){
			$filteredEnvConfigs = $projectConfigs | where { "$_.$Env.env" -eq $config }
			if ($filteredEnvConfigs -ne $null){
				$filteredEnvConfigs | % {
					$matchingConfigs[$config] = $_
				}			
			}	
		}			
	}

	if($matchingConfigs -eq $null){
		Write-Env "Could not locate any matching environment variables for $projectName"
		return
	}

	# Replace each configs environment settings with those defined in the {environment}.env file
	$matchingConfigs.Keys | % { 	
		$fullName = $matchingConfigs[$_].FullName
		$name = $matchingConfigs[$_].Name							
		if ($fullName -eq $null -or -not(Test-Path($fullName))){ 
			Write-Env "Skipping $_ for project $projectName because it did not exist {$fullName}"
			return 
		}						
		$xml = [xml](Get-Content $fullName)	
		$envVarPath = "$projectEnvVariablePath\$_"
		if ($_.StartsWith("shared.")){
			$config = $_ -Replace "shared.", ""
			$envVarPath = "$EnvPath\$SharedConfigDir\$config"
		}
		
		Get-Content -Path $envVarPath | %{$envVariables = @{}} {if ($_ -match '(.*)="(.*)"') {$envVariables[$matches[1]]=$matches[2];}}

		Write-Env "Setting '$env' environment variables from '$_' for project $projectName. {$fullName}"					

		# Do the replacement
		if ($configUpdateMethod.ContainsKey($name)) { &$configUpdateMethod[$name] $xml $envVariables }
		else { $xml = replaceKeyInConfig $xml $envVariables }		

		$xml.Save($fullName)
	}	
}

function Invoke-TransformConfigs {
	param(
			[parameter(Mandatory=$true)] 
			[string]$ProjectPath,								
			[parameter(Mandatory=$true)] 
			[string]$Env, 
			[parameter(Mandatory=$true)] 
			[string]$EnvPath,
			[string]$Version = $null,
			[parameter(Mandatory=$true)] 
			[string]$ConfigTransformerPath
		 )	
	
	$configTransformer = "$ConfigTransformerPath\WebConfigTransformRunner.exe"	

	if($Version){		
		$ProjectPath = "$ProjectPath.$Version"
	}

	$projectConfigs = @()
	$projectConfigs += Get-ChildItem -Path $ProjectPath -Filter "*.config"
	$possibleConfigPaths | % {
		$configPath = "$ProjectPath\$_"
		if (Test-Path($configPath)) {
			$projectConfigs += Get-ChildItem -Path "$ProjectPath\$_" -Filter "*.config"
		}		
	}	

	$configsToTransform = @{}
	$projectConfigs | % {
		$currentConfigName = $_ -Replace ".config", ""		
		$tranformConfig = $projectConfigs | where { "$currentConfigName.$Env.config" -eq $_ }
		if ($tranformConfig){
			$configsToTransform[$_] = $tranformConfig
		}		
	}

	if ($configsToTransform){
		$count = $configsToTransform.Count
		Write-Env "Found $count tranform configs"
		$configsToTransform
	}

	$configsToTransform.Keys | % {
		$sourceConfig = $_.FullName
		$tranformConfig = $configsToTransform[$_].FullName		
		Write-Env "Transforming $sourceConfig using $tranformConfig"		
		exec { &$configTransformer "$sourceConfig" "$tranformConfig" "$sourceConfig" }	
	}   
}

function Write-Env([string] $message) {
	Write-Host "[Env] $message" -f DarkBlue
}

Export-ModuleMember Set-EnvVariables, Invoke-TransformConfigs, Set-SensitiveData