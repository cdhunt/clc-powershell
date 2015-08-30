$ROOT = 'https://api.ctl.io'
$VERSION = '/v2'

<#
	My Function
#>
function Get-ClcUri ( [string]$Path ) {
	
	$UriString = "$ROOT"

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

	[Uri]$uri = Get-ClcUri -Path "$VERSION/authentication/login"
	Write-Verbose $uri.AbsolutePath

	$response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $body
	$token = $response.bearerToken

	$authHeader = @{Authorization = " Bearer " + $token}

	$authHeader | Write-Output
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-CLCGroup
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory, Position=0)]
		[System.Collections.Hashtable]
        $Authentication,

        # Param2 help description
		[Parameter(Mandatory, Position=1)]
        [String]
        $AccountAlias,

		[Parameter(Mandatory, Position=2)]
		[String]
		$GroupId
    )

	$path = "$VERSION/groups/$AccountAlias/$GroupId"

	$uri = Get-ClcUri -Path $path

	$results = Invoke-RestMethod -Uri $uri -Method Get -Headers $Authentication -ContentType 'application/json' 

	Write-Output -InputObject $results

}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-ClcServersFromGroup
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(ValueFromPipeline, Position=0, ParameterSetname='Default')]
        $InbputObject,

        # Param2 help description
		[Parameter(Mandatory, Position=0, ParameterSetname='Group')]
        [String]
        $AccountAlias,

		[Parameter(Mandatory, Position=1, ParameterSetname='Group')]
		[String]
		$GroupId,

        # Param1 help description
        [Parameter(ValueFromPipeline, Position=1, ParameterSetname='Default')]
		[Parameter(ValueFromPipeline, Position=2, ParameterSetname='Group')]
        [System.Collections.Hashtable]
        $Authentication
    )

	Process 
	{
		if ($PSBoundParameters.InbputObject)
		{
			$InbputObject.links | Where-Object {$_.rel -eq 'server'} | ForEach-Object {
				$uri =  Get-ClcUri -Path $_.href
				Invoke-RestMethod $uri -Method Get -ContentType 'application/json' -Headers $Authentication
			}

		}
	}
}