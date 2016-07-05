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
            Write-Verbose "Creating CIM Sessions using kerberos authentication.."
            $session = New-CimSession -Authentication Kerberos -PSComputerName $server.name
          #  $Bios = Get-CimInstance -ClassName cim_bioselement  -Property * -ComputerName $server.Name -ErrorAction Stop -ErrorVariable CurrentError
           # $Computersystem = Get-WmiObject Win32_Computersystem -Property * -ComputerName $Server.Name -ErrorAction Stop -ErrorVariable CurrentError
           # $OperatingSystem = Get-WmiObject Win32_OperatingSystem -Property * -ComputerName $Server.Name -ErrorAction Stop -ErrorVariable CurrentError
           # $WindowsFeatures = Get-WmiObject Win32_OptionalFeature -Filter {InstallState = '1'} -ComputerName $Server.Name -ErrorAction Stop -ErrorVariable CurrentError
           # $NetworkAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter {IPEnabled = 'True'} -ComputerName $Server.Name -ErrorAction Stop -ErrorVariable CurrentError
            $Properties = [Ordered]@{
            'ComputerName' = $server.Name
            'NICs' = (Get-CimInstance -ClassName win32_networkadapterconfiguration -Filter "IPEnabled = 'true'").caption.split("]")[1].trimstart()
            'SerialNumber' = $Bios.SerialNumber
            'ManuFacturer' = $Computersystem.Manufacturer
            'Model' = $Computersystem.Model
            'OS' = $OperatingSystem.Caption
            'OSVersion' = $OperatingSystem.Version
#                    'OSAcrhitecture' = $OperatingSystem.OSArchitecture
            'InstalledWinFeatures' = ((($WindowsFeatures | Sort Name).Name | Out-String).Trim())
            }
        }
    }

}
