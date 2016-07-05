function Search-servers
{
    Get-ADComputer -Filter {operatingsystem -like "*server*"} -SearchBase "$($searcher.SearchRoot.Path.Substring(7))" -SearchScope Subtree -Properties *
    #return $servers
}
function PingServer() {
    param([string]$hostname)
    $ping = new-object System.Net.NetworkInformation.Ping
    $Reply = $ping.send($HostName)
    if ($Reply.status –eq "Success")
    {
        return $true
    }
        return $false
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this workflow
.EXAMPLE
   Another example of how to use this workflow
.INPUTS
   Inputs to this workflow (if any)
.OUTPUTS
   Output from this workflow (if any)
.NOTES
   General notes
.FUNCTIONALITY
   The functionality that best describes this workflow
#>
workflow Get-ServerInfo ()
{
[CmdletBinding(
HelpUri = 'http://www.microsoft.com/',
ConfirmImpact='Medium')]
param()

    $servers = Search-servers
    foreach -parallel ($server in $servers)
    {
        Write-Verbose "Looking for servers.."
        $ServerObj = New-Object psObject
        if(PingServer -hostname $server.dnshostname -eq $true){
            try
            {
                Write-Verbose "Creating CIM Sessions using kerberos authentication.."
                $session = New-CimSession -Authentication Kerberos -PSComputerName $server.name
                $Properties = [Ordered]@{
                'ComputerName' = $server.Name
                'NICs and Addresses' = Get-CimInstance -CimSession $Session -ClassName win32_networkadapterconfiguration -Filter "IPEnabled = 'true'" | select @{Name='Description';Expression={[string]::join(";",($_.description))}}, @{Name='IPAddress';Expression={[string]::join(";",($_.ipaddress))}} 
                'SMBIOSBIOSVersion' = (Get-CimInstance -CimSession $session -ClassName win32_bios).smbiosbiosversion  
                'ManuFacturer' = (Get-CimInstance -CimSession $session -ClassName win32_computersystem).manufacturer
                'Model' = (Get-CimInstance -CimSession $session -ClassName win32_computersystem).model
                'OS' = (Get-CimInstance -CimSession $session -ClassName win32_operatingsystem).caption
                'OSVersion' = (Get-CimInstance -CimSession $session -ClassName win32_operatingsystem).version
                'InstalledWinFeatures' = ((($WindowsFeatures | Sort Name).Name | Out-String).Trim())
                }
            }
            catch
            {
                Write-Error -Message "Could not compute with computer $($server.name)" -erroraction Continue
            }
        }
    }
}
