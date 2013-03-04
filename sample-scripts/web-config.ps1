$sites = @{
	Website1 = @{
		IPAddress = "127.0.0.1";
		HostHeaders = @("dev.website1.com.au", "dev1.website1.com.au");				
		ProjectFile = "{enter path and file name to project file minus the solution root path defined in $global:SolutionRoot }";
		SiteName = "{Website1}";
		ApplicationHostConfigSiteNameKey = "{Website1 site name}";			
		ApplicationHostConfigPhysicalPathKey = "{Website1 physical path}";
		ApplicationHostConfigHostHeaderKey = "{Website1 host header}";
	};
	Website2 = @{
		IPAddress = "127.0.0.1";
		HostHeaders = @("dev.website2.com.au");				
		ProjectFile = "{enter path and file name to project file minus the solution root path defined in $global:SolutionRoot }";
		SiteName = "{Website1}";
		ApplicationHostConfigSiteNameKey = "{Website2 site name}";			
		ApplicationHostConfigPhysicalPathKey = "{Website2 physical path}";
		ApplicationHostConfigHostHeaderKey = "{Website2 host header}";
	};
}