$ROOT = 'https://api.ctl.io'
$VERSION = '/v2'

<#
	My Function
#>
function Get-ClcUri ( [string]$Path ) {
	
	$UriString = "$ROOT$VERSION"

	if (! [string]::IsNullOrEmpty($Path) )
	{
		If ($Path[0] -ne '/')
		{
			$UriString += '/'
		}

		$UriString += $Path

	}

	New-Object System.Uri -ArgumentList $UriString | Write-Output

}