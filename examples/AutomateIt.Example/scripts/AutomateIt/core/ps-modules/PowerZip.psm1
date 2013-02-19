# Zip PowerShell Module
# http://powershell.codeplex.com
Function New-Zip
{
	Param (
	[ValidateNotNullOrEmpty()]
		[Parameter(
    		Mandatory = $true)
    	]
			[string] $Source,
		[Parameter(
    		Mandatory = $true)
    	]
			[string] $ZipFile,
		[switch] $Recurse,
		[array] $Include,
		[array] $Exclude,
		[switch] $AbsolutePaths,
		[switch] $DeleteAfterZip )

	$IncludeArgument,$ExcludeArgument,$RecurseArgument = $null
	$ErrorsArray,$ItemsNotZipped = @()
	$Source = $Source -replace "\\$|\/$",""
	$CheckSource = Get-Item -Path $Source -Force -ErrorAction SilentlyContinue
	if ( -not $CheckSource ) { Write-Output "! Source not found {$Source}" }
	else
	{
		if ( $CheckSource.psIsContainer )
		{
			$RootPath = ( Resolve-Path -Path $Source -ErrorAction SilentlyContinue ).ProviderPath
		}
		else
		{
			$RootPath = ( Resolve-Path -Path $Source -ErrorAction SilentlyContinue ).ProviderPath
			if ( $RootPath )
			{
				$RootPath = Split-Path -Path $RootPath -ErrorAction SilentlyContinue
			}
		}
	}
	if ( $ZipFile -notmatch "\.zip$" ) { $ZipFile = $ZipFile -replace "$",".zip" }
	if ( $Recurse -eq $true ) { $RecurseArgument = "-Recurse" }
	if ( $Include )
	{
		$Include = $Include -join ","
		$IncludeArgument = "-Include $Include"
		$Source = $Source+"\*"
	}
	if ( $Exclude )
	{
		$Exclude = $Exclude -join ","
		$ExcludeArgument = "-Exclude $Exclude"
	}
	$GetCommand = "Get-ChildItem -Path '$Source' $RecurseArgument $IncludeArgument $ExcludeArgument -Force -ErrorAction SilentlyContinue"
	$ItemsToZip = Invoke-Expression -Command $GetCommand
	$SizeBeforeZip = ( $ItemsToZip | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue ).Sum
	$SizeBeforeZipInMB = $SizeBeforeZip | ForEach-Object { "{0:N2}" -f ($_ / 1MB) }
	if ( -not $SizeBeforeZip )
	{
		Write-Output "NOTHING TO ZIP"
		return $true
		break
	}
	$CreateZIPContainer = New-Item -ItemType File -Path $ZipFile -Force -ErrorAction SilentlyContinue
	if ( -not $CreateZIPContainer ) { Write-Output "! Unable to create ZIP container {$ZipFile}" }
	else { $ZipFile = ( Resolve-Path -Path $ZipFile -ErrorAction SilentlyContinue ).ProviderPath }
	$oZipOutputStream = New-Object -TypeName ICSharpCode.SharpZipLib.Zip.ZipOutputStream([System.IO.File]::Create($ZipFile))
	if ( $? -ne $true )
	{
		$ErrorsArray += @("! Unable to create ZIP stream {$ZipFile}")
	}	
	[byte[]] $Buffer = New-Object Byte[] 4096
	$StartTime = Get-Date
	Write-Output "`n===================================`n=> Start Time : $($StartTime.ToString(""dd/MM/yyyy-HH:mm:ss""))`n"
	Write-Output "TOTAL SIZE BEFORE ZIP : {$SizeBeforeZipInMB MB}`n"
	foreach ( $Item in $ItemsToZip )
	{
		if ( $Item.FullName -ne $ZipFile )
		{
			if ( Test-Path ( $Item.FullName ) -ErrorAction SilentlyContinue )
			{
				$ZipEntry = $Item.FullName
				if ( -not $AbsolutePaths )
				{
					$ReplacePath = [Regex]::Escape( $RootPath+"\" )
					$ZipEntry = $Item.FullName -replace $ReplacePath,""
				}
				if ( $Item.psIsContainer -eq $true )
				{
					if ( $Recurse -eq $true )
					{
						Write-Output "Processing ZIP of Directory {$($Item.FullName)} ..."
						$OldErrorActionPreference = $ErrorActionPreference
						$ErrorActionPreference = "SilentlyContinue"
						$oZipEntry = New-Object -TypeName ICSharpCode.SharpZipLib.Zip.ZipEntry("$ZipEntry/")
						$oZipEntry.DateTime = ([System.IO.FileInfo] $Item.FullName).LastWriteTime
						$oZipEntry.Size = ([System.IO.FileInfo] $Item.FullName).Length
						$oZipOutputStream.PutNextEntry($oZipEntry)
						if ( $? -ne $true )
						{
							$ItemsNotZipped += @($Item.FullName)
							$ErrorsArray += @("! Unable to ZIP Directory {$($Item.FullName)}")
						}
						$ErrorActionPreference = $OldErrorActionPreference
					}
				}
				else
				{
					Write-Output "Processing ZIP of File {$($Item.FullName)} ..."
					$OldErrorActionPreference = $ErrorActionPreference
					$ErrorActionPreference = "SilentlyContinue"
					$FileStream = [IO.File]::OpenRead($Item.FullName)
					$oZipEntry = New-Object -TypeName ICSharpCode.SharpZipLib.Zip.ZipEntry("$ZipEntry")
					$oZipEntry.DateTime = ([System.IO.FileInfo] $Item.FullName).LastWriteTime
					$oZipEntry.Size = ([System.IO.FileInfo] $Item.FullName).Length
					$oZipOutputStream.PutNextEntry($oZipEntry)
					[ICSharpCode.SharpZipLib.Core.StreamUtils]::Copy($FileStream,$oZipOutputStream,$Buffer)
					if ( $? -ne $true )
					{
						$ItemsNotZipped += @($Item.FullName)
						$ErrorsArray += @("! Unable to ZIP File {$($Item.FullName)}")
					}
					$FileStream.Close()
					$ErrorActionPreference = $OldErrorActionPreference
				}
			}
		}
	}
	$oZipOutputStream.Finish()
	$oZipOutputStream.Close()
	if ( $? -eq $true )
	{
		if ( $DeleteAfterZip -eq $true )
		{
			$ItemsToZip | Where-Object { $ItemsNotZipped -notcontains $_.FullName } | ForEach-Object {
				if ( $_.psIsContainer -ne $true )
				{
					if ( Test-Path ( $_.FullName ) -ErrorAction SilentlyContinue )
					{
						Write-Output "Processing Delete of File {$($_.FullName)} ..."
						$RemoveItem = Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
						if ( $? -ne $true )
						{
							$ErrorsArray += @("! Unable to Delete File {$($_.FullName)}")
						}
					}
				}
			}
			if ( $Recurse )
			{
				$ItemsToZip | Where-Object { $ItemsNotZipped -notcontains ( Split-Path -Parent $_.FullName ) } | ForEach-Object {
					if ( $_.psIsContainer -eq $true )
					{
						if ( Test-Path ( $_.FullName ) -ErrorAction SilentlyContinue )
						{
							Write-Output "Processing Delete of Directory {$($_.FullName)} ..."
							$RemoveItem = Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
							if ( $? -ne $true )
							{
								$ErrorsArray += @("! Unable to Delete Directory {$($_.FullName)}")
							}
						}
					}
				}
			}
		}
		Write-Output "`nZIP File Created {$ZipFile} ...`n"
	}
	else
	{
		$ErrorsArray += @("! ZIP Archive {$ZipFile} Creation Failed`n")
	}
	$EndTime = Get-Date
	$ExecutionTime = ($EndTime-$StartTime)
	Write-Output "`nExecution Time : $ExecutionTime`n"
	Write-Output "=> End Time : $($EndTime.ToString(""dd/MM/yyyy-HH:mm:ss""))`n=================================`n"
	if ( $ErrorsArray )
	{
		Write-Output "`n[ ERRORS OCCURED ]"
		$ErrorsArray
		return $false
	}
	else
	{
		$SizeAfterZip = ( Get-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue ).Sum
		$SizeAfterZipInMB = $SizeAfterZip | ForEach-Object { "{0:N2}" -f ($_ / 1MB) }
		Write-Output "`nTOTAL SIZE AFTER ZIP : {$SizeAfterZipInMB MB}`n"
		$Gain = ( $SizeBeforeZip - $SizeAfterZip )
		$GainInMB = $Gain | ForEach-Object { "{0:N2}" -f ($_ / 1MB) }
		if ( $Gain -gt 0 )
		{
			$GainInPercent = (($SizeBeforeZip - $SizeAfterZip) / $SizeBeforeZip) * 100 | ForEach-Object { "{0:N2}" -f $_ }
			Write-Output "GAIN : {$GainInMB MB} ($GainInPercent %)`n"
		}
		return $true
	}
}
Function New-AutoZip
{
	Param (
		[ValidateNotNullOrEmpty()]
			[Parameter(
	    		Mandatory = $true)
	    	]
				[string] $Source,
			[int] $RetentionDays,
			[array] $Include,
			[array] $Exclude,
			[switch] $Recurse )

	$IncludeArgument,$ExcludeArgument,$RecurseArgument = $null
	$ErrorsArray,$DirectoryToZipArray = @()
	if ( -not ( Test-Path -Path "$Source" -ErrorAction SilentlyContinue ) )
	{
		Write-Output "ERROR : Source not found { $Source }"
	}
	$DirectoryTimeStamp = (Get-Date).ToString("yyyy\\MM")
	$ArchiveTimeStamp = (Get-Date).ToString("yyyyMMddHHmmss")
	if ( $Recurse -eq $true ) { $RecurseArgument = "-Recurse" }
	if ( $Include )
	{
		$Include = $Include -join ","
		$IncludeArgument = "-Include $Include"
		$Source = $Source+"\*"
	}
	$Exclude += @("*.zip")
	$Exclude = $Exclude -join ","
	$ExcludeArgument = "-Exclude $Exclude"
	$GetCommand = "Get-ChildItem -Path '$Source' $IncludeArgument $ExcludeArgument $RecurseArgument -Force -ErrorAction SilentlyContinue"
	Invoke-Expression -Command $GetCommand | Where-Object { ( $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) ) -and ( $_.psIsContainer -eq $false ) -and ( $_ -cnotmatch "\\_AutoArchive_\\" ) } | ForEach-Object {
		$ArchiveDirectory = $_.DirectoryName
		$ArchiveDirectory = "$ArchiveDirectory\_AutoArchive_\$DirectoryTimeStamp"
		Write-Output "Moving { $($_.FullName) } to { $ArchiveDirectory } ..."
		$DirectoryToZipArray += @($ArchiveDirectory)
		if ( -not ( Test-Path -Path "$ArchiveDirectory" -ErrorAction SilentlyContinue ) )
		{
			New-Item -ItemType Directory -Path "$ArchiveDirectory" -Force -ErrorAction SilentlyContinue | Out-Null
			if ( $? -ne $true )
			{
				$ErrorsArray += @("! Unable to create directory {$ArchiveDirectory}")
			}
		}
		Move-Item -Path $_.FullName -Destination "$ArchiveDirectory" -Force -ErrorAction SilentlyContinue
		if ( $? -ne $true )
		{
			$ErrorsArray += @("! Unable to move file {$($_.FullName)}")
		}
	}
	foreach ( $DirectoryToZip in $DirectoryToZipArray | Sort-Object -Unique )
	{
		Write-Output "Zipping { $DirectoryToZip } ..."
		$ZipFile = "$DirectoryToZip\$ArchiveTimeStamp.zip"
		$Zip = New-Zip -Source "$DirectoryToZip" -ZipFile "$ZipFile" -DeleteAfterZip -Exclude "*.zip"
		if ( $? -ne $true )
		{
			$ErrorsArray += @("! Unable to zip directory {$DirectoryToZip}")
		}
	}
	if ( $ErrorsArray )
	{
		Write-Output "`n[ ERRORS OCCURED ]"
		$ErrorsArray
		return "===> $env:ComputerName - $Source",$false,$ErrorsArray
	}
	else
	{
		return "===> $env:ComputerName - $Source",$true
	}
}
Function Get-FileFromZip
{
	Param (
	[ValidateNotNullOrEmpty()]
		[Parameter(
    		Mandatory = $true)
    	]
			[string] $ZipFile,
		[Parameter(
    		Mandatory = $true)
    	]
			[string] $Destination,
		[string] $Filter )

	$CheckZipFile = Get-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue
	if ( -not $CheckZipFile ) { throw "! Zip File not found {$ZipFile}" }
	$oFastZip = New-Object ICSharpCode.SharpZipLib.Zip.FastZip
	$ExtractZip = $oFastZip.ExtractZip("$ZipFile","$Destination","$Filter")
	if ( $? -ne $true )
	{
		Write-Output "! Unable to extract ZIP File {$ZipFile}"
		return $false
	}
	else
	{
		return $true
	}
}