
function Write-Zip {
   param(
         [parameter(Mandatory=$true)] 
         [string[]]$OutputFile, 
         [parameter(Mandatory=$true)]           
         [string]$DirectoryToZip
       )

    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Packaging.ZipPackage" )
    $compressionLevel = [System.IO.Packaging.CompressionOption]::SuperFast
    [System.IO.Packaging.ZipPackage]::CreateFromDirectory( $DirectoryToZip, $OutputFile, $compressionLevel, $false )
}