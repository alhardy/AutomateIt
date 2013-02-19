$sites = @{
	AutomateItWeb = @{
		IPAddress = "127.0.0.1";
		HostHeader = "dev.automateit.com.au";				
		ProjectFile = "AutomateIt.Example.Web\AutomateIt.Example.Web.csproj";						
		SiteName = "AutomateItWebExample";
		ApplicationHostConfigSiteNameKey = "{AutomateItWebExampleSiteName}";			
		ApplicationHostConfigPhysicalPathKey = "{AutomateItWebExamplePhysicalPath}";
		ApplicationHostConfigHostHeaderKey = "{AutomateItWebExampleHostHeader}";
	};
	AutomateItWebTwo = @{
		IPAddress = "127.0.0.1";
		HostHeader = "dev.automateittwo.com.au";				
		ProjectFile = "AutomateIt.Example.WebTwo\AutomateIt.Example.WebTwo.csproj";						
		SiteName = "AutomateItWebTwoExample";
		ApplicationHostConfigSiteNameKey = "{AutomateItWebTwoExampleSiteName}";			
		ApplicationHostConfigPhysicalPathKey = "{AutomateItWebTwoExamplePhysicalPath}";
		ApplicationHostConfigHostHeaderKey = "{AutomateItWebTwoExampleHostHeader}";
	};
}