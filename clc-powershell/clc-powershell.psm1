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

<#
.Synopsis
   Get CenturyLink Cloud Auth Token
.DESCRIPTION
   Get an OAuth Token for authenticating with the CenturyLink Cloud API v2.
.EXAMPLE
   PS C:\> Get-ClcAuthenticationHeader -Credential user.name

   Name                           Value
   ----                           -----
   Authorization                   Bearer abcxyz123...
.OUTPUTS
   A hash table containing the authentication parameters for API calls.
.NOTES
   Use this API operation before you call any other API operation. It shows a user's roles, primary data center, and a valid bearer token.
.COMPONENT
   CenturyLink
.ROLE
   API Wrapper
#>
function Get-ClcAuthenticationHeader {
	[CmdletBinding()]
    [Alias()]
    [OutputType([System.Collections.Hashtable])]
    Param ( 

		# Specifies a user account that has permission to send the request.
		[Parameter(Mandatory, Position=0)]
		[PSCredential]$Credential 
	)

	$body = ( 
		@{
			username = $Credential.UserName;
			password = $Credential.GetNetworkCredential().Password 
		} | ConvertTo-Json)

	[Uri]$uri = Get-ClcUri -Path 'authentication/login'
	Write-Verbose $uri.AbsolutePath

	$response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $body
	$token = $response.bearerToken

	$authHeader = @{Authorization = " Bearer " + $token}

	$authHeader | Write-Output
}