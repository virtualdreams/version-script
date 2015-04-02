<#
	Notes:
		Author: Thomas Kindler
		Date:	01.04.2015
	
	Parameters
		file: path to file
		git: path to git binary
	
	Example:
		PS C:\ git-hash.ps1 -file "/foo/bar"
		powershell -file "/path/to/git-hash.ps1" -file "/path/to/file" [-git "/path/to/git"]
#>
param
(
	[string]$file = '.\Properties\AssemblyInfo.cs',
	[string]$git = 'C:\Program Files (x86)\Git\bin\git.exe'
)

[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US';

### test if target file exists
if(!$file -or !(Test-Path $file))
{
	Write-Host "Path is not set or found."
	return
}

### test if git executeable exists
if(!(Test-Path $git))
{
	Write-Host "git command could not be found."
	return
}

### set git exe as alias
New-item alias:git -value $git | Out-Null
if(!(Get-Command git -TotalCount 1 -ErrorAction SilentlyContinue))
{
	Write-Host "git alias could not be found."
	return
}

$commits = git rev-list HEAD --count
$information = git describe --long --always --dirty=-dev

$major = "1"
$minor = "0"
$m = $false

### look if a tag like v1.0-release is created and extract the version number
if($information -match "^v(\d+).(\d+).*") {
	$major = [string]$matches[1]
	$minor = [string]$matches[2]
	
	$m = $true
}

(Get-Content $file -Encoding UTF8) | Foreach-Object {
	if($_ -match "\[assembly: AssemblyFileVersion\(""(\d+)\.(\d+)\.(\d+)\.(\d+)\""\)\]") {
		if($m) {
			$_ -replace "\[assembly: AssemblyFileVersion\(""(\d+)\.(\d+)\.(\d+)\.(\d+)\""\)\]", "[assembly: AssemblyFileVersion(""$major.$minor.`$3.$commits"")]"
			Write-Host ([string]::Format("Version (from tag): {0}.{1}.{2}.{3}", $major, $minor, [string]$matches[3], $commits))
		}
		else {
			$_ -replace "\[assembly: AssemblyFileVersion\(""(\d+)\.(\d+)\.(\d+)\.(\d+)\""\)\]", "[assembly: AssemblyFileVersion(""`$1.`$2.`$3.$commits"")]"
			Write-Host ([string]::Format("Version (from file): {0}.{1}.{2}.{3}", [string]$matches[1], [string]$matches[2], [string]$matches[3], $commits))
		}
	}
	elseif($_ -match "\[assembly: AssemblyInformationalVersion\(""(.*)""\)\]") {
		$_ -replace "\[assembly: AssemblyInformationalVersion\(""(.*)""\)\]", "[assembly: AssemblyInformationalVersion(""$information"")]"
		Write-Host ([string]::Format("Information: {0}", $information))
	}
	else
	{
		$_
	}
} | Out-File $file -Encoding UTF8
