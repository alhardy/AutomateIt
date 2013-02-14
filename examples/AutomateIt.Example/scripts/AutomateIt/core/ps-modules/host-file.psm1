function Add-HostEntry{
  param(
    [parameter(Mandatory=$true,position=0)]
	[string]
	$IPAddress,
	[parameter(Mandatory=$true,position=1)]
	[string]
	$HostName
  )

	$HostsLocation = "$env:windir\System32\drivers\etc\hosts";
	$NewHostEntry = "`t$IPAddress`t$HostName";	

	Write-Host $content

	if((Get-Content $HostsLocation) -contains $NewHostEntry) {
	  Write-Host "The hosts file already contains the entry: $NewHostEntry. File not updated.";
	}
	else {
    	Write-Host "The hosts file does not contain the entry: $NewHostEntry. Attempting to update.";
		Add-Content -Path $HostsLocation -Value $NewHostEntry;
	}
	
	if((Get-Content $HostsLocation) -contains $NewHostEntry) {
		Write-Host "New entry, $NewHostEntry, added to $HostsLocation.";
	}
	else {
    	Write-Host "The new entry, $NewHostEntry, was not added to $HostsLocation.";
	}
}

Export-ModuleMember Add-HostEntry