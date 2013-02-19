task Set-IISExpress {
	"Starting Websites and Services..."
	Start-LocalIISExpress
}

task Set-Hosts {
	"Setting Host file entries..."
	Set-LocalHosts
}

task Build-Local {
	"Building Local Websites and Services..."
	Build-LocalSites
}

task Start-LocalWebFromConfig -depends Build-Local, Set-Hosts, Set-IISExpress {
	"Starting Local Websites and Services..."
}