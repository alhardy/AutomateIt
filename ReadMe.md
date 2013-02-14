The idea behind AutomateIt is to quickly perform automated builds, tests, artifact packaging and replacement of sensitive data you want to keep out of source control. AutomateIt also has the ability to push generated artifacts  to a nuget repository, perform configuration transforms and sensitive data replacement on deploy rather than build and helps with automating deployments.

**Installation**

Open an new shell, cd to the packages directory in the root of your solution execute the following commands

	> nuget install AutomateIt
	> cd .\AutomateIt.{version}\tools
	> .\installIt.ps1
	  
installIt.ps1 will copy the required scripts to the root of your solution. This step could be accomplished using init.ps1 within the nuget package and installed within Visual Studio, however this would require the solution to be contained in the root of your workspace.
	  
**Using AutomateIt to build your solution**

Open a new powershell instance run the following in the root of your workspace

	> .\scripts\AutomateIt\custom\build.ps1

This will by default build, test and package all projects referenced by solutions in the root of you workspace. If multiple solutions exist in your workspace open *.\scripts\AutomateIt\custom\build-config.ps1* and adjust the *$global:solutions* variable to include any other solutions you wish to build.

By default artifacts will be generated as zip files located in the *out* directory in the root of your workspace.

**Building non-web applications**

By default web projects import an msbuild target to publish web applications to a web *_PublishedWebsites*  directory in the OutDir specified when running MSBuild. Any other project type however does not have this ability by default.

To package artifacts when compiling multiple projects this is necessary to generate project specific artifacts. For example if a solution contained mulitple web projects, running MsBuild on the solution would result in

`{OutDir}/_PublishedWebsites/WebProject1`

`{OutDir}/_PublishedWebsites/WebProject2`

This allows us to package both directories as individual artifacts. 

To achieve the same affect for all other applications AutomateIt includes a custom MsBuild target. To make use of this add the following line to your .csproj just beneath ` <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />`

 `<Import Project="..\scripts\AutomateIt\core\msbuild\CopyToPublishedApplications.msbuild" />`

Now when building with AutomateIt the script will generate a *_PublishedApplications* directory containing all compiled Non-Web applications.

**Versioning**

**Nuget vs Zip Artifacts**

**Removing Sensitive Data**

**Pushing Artifacts to a Nuget Repository**