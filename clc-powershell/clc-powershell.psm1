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
function Get-CLCDataCenter
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
		$DataCenter,

		[Parameter()]
		[Switch]
		$GroupLink
    )

	$path = "$VERSION/datacenters/$AccountAlias/$DataCenter"

	if ($GroupLink)
	{
		$path += '?groupLinks=true'
	}

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
		$results = @()

		if ($PSBoundParameters.InbputObject)
		{
			$list = $InbputObject			
		}
		else
		{
			$list = Get-CLCGroup -AccountAlias $AccountAlias -GroupId $GroupId -Authentication $Authentication
		}

		$list | Expand-ClcLink -Relation server -Authentication $Authentication
	}
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
function New-ClcServer
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param
    (
		# Name of the server to create. Alphanumeric characters and dashes only. Must be between 1-8 characters depending on the length of the account alias. The combination of account alias and server name here must be no more than 10 characters in length. (This name will be appended with a two digit number and prepended with the datacenter code and account alias to make up the final server name.)
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
		[ValidateLength(1,8)]
		[string]
		$Name,

		# ID of the parent group. Retrieved from query to parent group, or by looking at the URL on the UI pages in the Control Portal.
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=1)]
		[string]
		$GroupId,

        # ID of the server to use a source. May be the ID of a template, or when cloning, an existing server ID. The list of available templates for a given account in a data center can be retrieved from the Get Data Center Deployment Capabilities API operation. (Ignored for bare metal servers.)
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=2)]
		[ValidateSet('BOSH-OPENSTACK-CLC-UBUNTU-TRUSTY-GO_AGENT_2922','BOSH-OPENSTACK-CLC-UBUNTU-TRUSTY-GO_AGENT_3012','BOSH-OPENSTACK-CLC-UBUNTU-TRUSTY-GO_AGENT_3026','BOSH-OPENSTACK-CLC-UBUNTU-TRUSTY-GO_AGENT','BOSH-STEMCELL','VBLK-10
0-TEMPLATE','BOSH-OPENSTACK-CLC-UBUNTU-TRUSTY-GO_AGENT_2989','CENTOS-5-64-TEMPLATE','CENTOS-6-64-TEMPLATE','DEBIAN-6-64-TEMPLATE','DEBIAN-7-64-TEMPLATE','PXE-TEMPLATE','RHEL-5-64-TEMPLATE','RHEL-6-64-TEMPLATE','RHE
L-7-64-TEMPLATE','UBUNTU-12-64-TEMPLATE','UBUNTU-14-64-TEMPLATE','WIN2008R2DTC-64','WIN2008R2ENT-64','WIN2008R2STD-64','WIN2012DTC-64','WIN2012R2DTC-64')]
		[string]
        $SourceServerID,

        # User-defined description of this server
		[Parameter(ValueFromPipelineByPropertyName, Position=3)]
        [string]
        $Description,

        # Primary DNS to set on the server. If not supplied the default value set on the account will be used.
		[Parameter(ValueFromPipelineByPropertyName, Position=4)]
        [string]
        $PrimaryDns,

		# Secondary DNS to set on the server. If not supplied the default value set on the account will be used.
		[Parameter(ValueFromPipelineByPropertyName, Position=5)]
        [string]
        $SecondaryDns,

		# ID of the network to which to deploy the server. If not provided, a network will be chosen automatically. If your account has not yet been assigned a network, leave this blank and one will be assigned automatically. The list of available networks for a given account in a data center can be retrieved from the Get Data Center Deployment Capabilities API operation.
		[Parameter(ValueFromPipelineByPropertyName, Position=6)]
        [string]
        $NetworkId,

		# IP address to assign to the server. If not provided, one will be assigned automatically. (Ignored for bare metal servers.)
		[Parameter(ValueFromPipelineByPropertyName, Position=6)]
        [string]
        $IpAddress,

		# Password of administrator or root user on server. If not provided, one will be generated automatically.
		[Parameter(Position=7)]
        [String]
        $Password,

		# Number of processors to configure the server with (1-16) (ignored for bare metal servers)
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=8)]
		[ValidateRange(1,16)]
		[int]
		$Cpu,

		# Number of GB of memory to configure the server with (1-128) (ignored for bare metal servers)
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=9)]
		[ValidateRange(1,128)]
		[int]
		$MemoryGB,

		# Whether to create a standard, hyperscale, or bareMetal server
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=10)]
		[ValidateSet('standard','hyperscale','bareMetal')]
		[string]
		$Type,

		# For standard servers, whether to use standard or premium storage. If not provided, will default to premium storage. For hyperscale servers, storage type must be hyperscale. (Ignored for bare metal servers.)
		[Parameter(ValueFromPipelineByPropertyName, Position=11)]
		[ValidateSet('standard','premium','hyperscale')]
		[string]
		$StorageType,

		# Collection of disk parameters (ignored for bare metal servers) eg. @(@{path="data"; sizeGB=50; type="partitioned"})
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=11)]
		[Hashtable[]]
		$AdditionalDisks,

		# Only required for bare metal servers. Specifies the OS to provision with the bare metal server. Currently, the only supported OS types are redHat6_64Bit, centOS6_64Bit, windows2012R2Standard_64Bit, ubuntu14_64Bit. A list of importable OS types for a given data center can be retrieved from the Get Data Center Bare Metal Capabilities API operation. (Ignored for standard and hyperscale servers.)
		[Parameter(ValueFromPipelineByPropertyName, Position=12)]
		[ValidateSet('redHat6_64Bit', 'centOS6_64Bit', 'windows2012R2Standard_64Bit', 'ubuntu14_64Bit')]
		[string]
		$OsType,

		# Whether to create the server as managed or not. Default is false. (Ignored for bare metal servers.)
		[Parameter(ValueFromPipelineByPropertyName)]
		[switch]
		$ManagedOS,

		# Whether to add managed backup to the server. Must be a managed OS server. (Ignored for bare metal servers.)
		[Parameter(ValueFromPipelineByPropertyName)]
		[switch]
		$ManagedBackup
    )

    Begin
    {
    }
    Process
    {
		$server = @{}

		$server.Add('name', $Name)
		$server.Add('groupId', $GroupId)
		$server.Add('sourceServerid', $SourceServerID)
		$server.Add('cpu', $Cpu)
		$server.Add('memoryGB', $MemoryGB)
		$server.Add('type', $Type)
		
		if (![string]::IsNullOrWhiteSpace($Description)) { $server.Add('description', $Description) }
		if (![string]::IsNullOrWhiteSpace($PrimaryDns)) { $server.Add('primaryDns', $PrimaryDns) }
		if (![string]::IsNullOrWhiteSpace($SecondaryDns)) { $server.Add('secondaryDns', $SecondaryDns) }
		if (![string]::IsNullOrWhiteSpace($NetworkId)) { $server.Add('networkId', $NetworkId) }
		if (![string]::IsNullOrWhiteSpace($IpAddress)) { $server.Add('ipAddress', $IpAddress) }
		if (![string]::IsNullOrWhiteSpace($StorageType)) { $server.Add('storageType', $StorageType) }
		if ($AdditionalDisks -ne $null) { $server.Add('additionalDisks', ($AdditionalDisks | ConvertTo-Json -Depth 2 -Compress)) }
		if (![string]::IsNullOrWhiteSpace($OsType)) { $server.Add('osType', $OsType) }
		if ($ManagedOS) { $server.Add('isManagedOS', $true) }
		if ($ManagedBackup) { $server.Add('isManagedBackup', $true) }

		Write-Output -InputObject $server
    }
    End
    {
    }
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
function Expand-ClcLink
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        $InbputObject,

		# Param1 help description
        [Parameter(Mandatory, Position=1)]
		[ValidateSet("billing", "server", "group", "groups")]
        [String]
        $Relation,

        # Param1 help description
        [Parameter(Mandatory, Position=2)]
        [System.Collections.Hashtable]
        $Authentication
    )

	Process 
	{
		if ($PSBoundParameters.InbputObject)
		{
			$InbputObject.links | Where-Object {$_.rel -eq $Relation} | ForEach-Object {
				$uri =  Get-ClcUri -Path $_.href
				Invoke-RestMethod $uri -Method Get -ContentType 'application/json' -Headers $Authentication
			}

		}
	}
}