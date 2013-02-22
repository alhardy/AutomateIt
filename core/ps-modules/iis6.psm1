function Write-IIS6([string] $message) {
    Write-Host "[IIS6] $message" -f Magenta
}

function Throw-IIS6([string] $message) {
    Write-Host "[IIS6-Error] $message" -f Magenta
    exec { cmd /c exit (1) }
}

function Confirm-II6Support {
    try {
       [wmiclass] 'root/MicrosoftIISv2:IIsWebServer' > $null
    }
    catch {
        Write-Error "The IIS WMI Provider for II6 is not installed"
    }
}

Confirm-II6Support

function Start-IIS6WebSite {
    param (
        [parameter(Mandatory=$true)]
        [string]$Name
    )    

    $webServerSetting = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IISWebServerSetting -Filter "ServerComment = '$Name'"
    
    if ($webServerSetting) {
        $webServers = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IIsWebServer
        $targetServer = $webServers | Where-Object { $_.Name -eq $webServerSetting.Name }
        $targetServer.Start()
        
        Write-IIS6 "Started website '$Name'"
    }
    else {
        Throw-IIS6 "Could not find website '$Name' to start"
    }
}

function Stop-IIS6WebSite {
    param (
        [parameter(Mandatory=$true)]        
        [string] $Name
    )

    $webServerSetting = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IISWebServerSetting -Filter "ServerComment = '$Name'"
    
    if ($webServerSetting) {
        $webServers = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IIsWebServer
        $targetServer = $webServers | Where-Object { $_.Name -eq $webServerSetting.Name }
        $targetServer.Stop()
        
        Write-IIS6 "Stopped website '$Name'"
    }
    else {
        Throw-IIS6 "Could not find website '$Name' to stop"
    }
}

function Remove-IIS6WebSite {
    param (
        [parameter(Mandatory=$true)]        
        [string]$Name
    )    

	$webServerSetting = Get-WmiObject -Namespace "root\MicrosoftIISv2" -Class IISWebServerSetting -Filter "ServerComment = '$Name'"
    
	if ($webServerSetting) {
        $webServerSetting.Delete()
        Write-IIS6 "Deleted website '$Name'"
    }
    else {
        Throw-IIS6 "Could not find website '$Name' to delete"
    }
}

function New-IIS6WebSite {
    param (
        [parameter(Mandatory=$true)]   
        [string]$Name,
        [parameter(Mandatory=$true)]   
        [string]$Path,
        [parameter(Mandatory=$true)]   
        [string]$AppPool,
        [string[]]$Ips = $null,
        [string[]]$Ports = $null,
        [string[]]$HostHeaders = $null,
        [string]$DefaultDoc = $null,
        [switch]$DefaultAccess,
        [switch]$Force
    )    

    $webServerSetting = Get-WmiObject -Namespace "root\MicrosoftIISv2" -Class IISWebServerSetting -Filter "ServerComment = '$Name'"

    if($webServerSetting -and !$Force) {
        write-output "Website '$Name' already exists. Use -Force to re-create."
        return
    }elseif ($webServerSetting){
        write-output "Re-creating website '$Name'..."
        Remove-IIS6WebSite $Name
    }

    $service = Get-WmiObject -namespace "root\MicrosoftIISv2" -class "IIsWebService"    
    
    $bindingClass = [wmiclass]"root\MicrosoftIISv2:ServerBinding"
    $secureBindingClass = [wmiclass]"root\MicrosoftIISv2:SecureBinding"    
    $bindings = [array]::CreateInstance('System.Management.ManagementBaseObject', $HostHeaders.Count)

    for($i = 0; $i -lt $HostHeaders.Count; $i++){         
        if($Ports[$i] -eq "443"){
            throw "WARNING: Not yet implemented - script configuring of SSL Cert to use for this binding"
            #$binding = $secureBindingClass.CreateInstance()        
            #$binding.Port = $Ports[2]    
            #$binding.IP = $IPs[2]              
            #$bindings[2] = $binding     
        }else{
            $binding = $bindingClass.CreateInstance()
            $binding.Hostname = $HostHeaders[$i]
            $binding.Port = $Ports[$i]        
            $binding.IP = $IPs[$i]          
            $bindings[$i] = $binding     
        }            
    }    

    $webSite = $service.CreateNewSite($Name, $bindings, $Path)

    $webServerSetting = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IISWebServerSetting -Filter "ServerComment = '$Name'"

    $webServerSetting.AppPoolId = $AppPool
    $webServerSetting.ServerAutoStart = $true
    
    if ($DefaultDoc) {
        $webServerSetting.EnableDefaultDoc = $true
        $webServerSetting.DefaultDoc = $DefaultDoc  
    }
    
    if ($DefaultAccess) {
        $webServerSetting.AuthAnonymous = $true
        $webServerSetting.AccessRead = $true
        $webServerSetting.AccessScript = $true
    }
    
    [Void]$webServerSetting.Put()
    
    # Set implicit ROOT application properties
    $rootVirtualDirName = $webServerSetting.Name + '/ROOT'
    $virtualDirSetting = Get-WmiObject -Namespace 'root\MicrosoftIISv2' -Class IISWebVirtualDirSetting -Filter "Name = '$rootVirtualDirName'"
    $virtualDirSetting.AppPoolId = $AppPool
    [Void]$virtualDirSetting.Put()
    
    Write-IIS6 "Created new website '$Name' pointing to '$Path'"
}

function Get-IIS6WebSitePhysicalPath {
      param(
            [parameter(Mandatory=$true)]   
            [string]$Name            
        )

    $iis = [ADSI]"IIS://localhost/W3SVC"
    $site = $iis.psbase.children | where { $_.keyType -eq "IIsWebServer" -AND $_.ServerComment -eq $Name }
    $path = [adsi]($site.psbase.path+"/ROOT")    
    return $path.psbase.properties.path[0]
}

function Update-IIS6WebSitePhysicalPath {
    param(
            [parameter(Mandatory=$true)]   
            [string]$Name,
            [parameter(Mandatory=$true)]   
            [string]$PhysicalPath 
        )

    $iis = [ADSI]"IIS://localhost/W3SVC"
    $site = $iis.psbase.children | where { $_.keyType -eq "IIsWebServer" -AND $_.ServerComment -eq $Name }
    $path = [adsi]($site.psbase.path+"/ROOT")    
    if (-not($path.psbase.properties.path[0])){
        Throw-IIS6 "Could not find website '$Name'"
    }
    $path.psbase.properties.path[0] = $PhysicalPath    
    $path.psbase.CommitChanges()
    Write-IIS6 "Updated Website '$Name' Physical Path to $PhysicalPath"    
}

Export-ModuleMember Start-IIS6WebSite, Stop-IIS6WebSite, Remove-IIS6WebSite, New-IIS6WebSite, Update-IIS6WebSitePhysicalPath, Get-IIS6WebSitePhysicalPath