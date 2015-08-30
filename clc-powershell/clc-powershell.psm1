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

function Get-ClcAuthenticationHeader ([PSCredential]$Credential) {

	$body = ( 
		@{
			username = $Credential.UserName;
			password = $Credential.Password | ConvertFrom-SecureString
		} | ConvertTo-Json)

	[Uri]$uri = Get-ClcUri -Path 'authentication/login'
	Write-Verbose $uri.AbsolutePath

	$response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $body
	$token = $response.bearerToken

	$authHeader = @{Authorization = " Bearer " + $token}

	$authHeader | Write-Output
}