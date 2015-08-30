#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module .\clc-powershell.psm1 -Force

Describe "Get-ClcUri" {
	Context "Base URL is 'https://api.ctl.io/v2'" {

		$uri = Get-ClcUri

		It "Should be TypeOf Uri" {
			$uri.GetType() | Should Be 'Uri'
		}

		It "Base Uri Should Be 'https://api.ctl.io/'"  {			
			$uri.AbsoluteUri | Should Be 'https://api.ctl.io/'
		}
	}
		Context "With Path, no /" {

		$uri = Get-ClcUri -Path "v2/authentication/login"
	
		It "Should be TypeOf Uri" {
			$uri.GetType() | Should Be 'Uri'
		}

		It "Base + 'authentication/login' Should Be 'https://api.ctl.io/v2/authentication/login'" {
			$uri.AbsoluteUri | Should Be 'https://api.ctl.io/v2/authentication/login'
		}
	}
		Context "With Path, with /" {

		$uri = Get-ClcUri -Path "/v2/authentication/login"

		It "Should be TypeOf Uri" {
			$uri.GetType() | Should Be 'Uri'
		}

		It "Base + '/authentication/login' Should Be 'https://api.ctl.io/v2/authentication/login'" {
			$uri.AbsoluteUri | Should Be 'https://api.ctl.io/v2/authentication/login'
		}
	}
}

Describe "Get-ClcAuthenticationHeader" {
	Context "OAuth Token" {
		Mock -ModuleName clc-powershell -CommandName Invoke-RestMethod -MockWith {return [PSCustomObject]@{userName = 'UserName'; accountAlias = 'ABC'; locationAlias = 'VA1'; roles = '{AccountAdmin}'; bearerToken = 'LCJ1cm46dGllcjM6Y'}}

		$fauxCred = New-Object System.Management.Automation.PSCredential ('test@test.test', (ConvertTo-SecureString 'password' -AsPlainText -Force))

		$testHeader = Get-ClcAuthenticationHeader -Credential $fauxCred

		It "Returns token 'Bearer LCJ1cm46dGllcjM6Y'" {
			$testHeader.Authorization | Should Be " Bearer LCJ1cm46dGllcjM6Y"
		}
	}

}

Remove-Module clc-powershell