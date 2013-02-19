function Write-HFile([string] $message) {
	Write-Host "[Host-File] $message" -f Blue
}

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

	if((Get-Content $HostsLocation) -contains $NewHostEntry) {
		Write-HFile "The hosts file already contains the entry: $NewHostEntry. File not updated."
		return
	}
	else {
    	Write-HFile "The hosts file does not contain the entry: $NewHostEntry. Attempting to update."
		Add-Content -Path $HostsLocation -Value $NewHostEntry;
	}
	
	Write-HFile "The new entry, $NewHostEntry, was not added to $HostsLocation."
}

Export-ModuleMember Add-HostEntry