Installation

Open an new shell, cd to the packages directory in the root of your solution  run 
	- nuget install AutomateIt
	- cd .\AutomateIt.{version}\tools
	- installIt.ps1
	  installIt.ps1 will copy the required scripts to the root of your solution. This step could be accomplished using init.ps1 within the nuget package and installed within Visual Studio, however this would require the solution to be contained in the root of your workspace.
	  

Using AutomateIt to build your solution

Within a powershell instance run the following in the root of your workspace
	- .\scripts\AutomateIt\custom\build.ps1

This will build, test and package all solutions in the root of you workspace. If their are multiple solutions in your workspace build-config.ps1 > $global:solutions variable can be adjusted to find other solutions you wish to build.

todo: add notes about zip artifacts by default and give directions on nuget packages
todo: give directions on versioning
todo: give directions on creating artifacts for console applications
todo: give directions on removing sensitive data
	