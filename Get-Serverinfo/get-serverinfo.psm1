<#
.Synopsis
   Scan a domain environment for computers with OS like *server* and are online. © Juhani Atula 2016
.DESCRIPTION
   Scan a domain environment for computers with OS like *server* and are online. © Juhani Atula 2016
.EXAMPLE
   Get-ServerInfo -outvariable table
#>
workflow Get-ServerInfo ()
{
[CmdletBinding(HelpUri = 'http://github.com/JAtula',
                ConfirmImpact='Medium')]
                param()

    $servers = Search-Onlineservers
    
    foreach -parallel ($server in $servers)
    {
        sequence
        {
        
            Write-Verbose "Found..$($server.name)"

            inlinescript{
                        Write-Verbose "$($using:server.name) online. Creating CIM session with it."
                        $session = New-CimSession -ComputerName $using:server.name -Authentication kerberos

                        $Properties = [Ordered]@{
                            'ComputerName' = $using:server.Name
                            'InstallDate' = $((Get-CimInstance -CimSession $session -ClassName win32_operatingsystem).InstallDate)
                            'NIC' = $(((Get-CimInstance -CimSession $session win32_networkadapterconfiguration -Filter "IPEnabled = 'true'" | select @{Name='Description';Expression={[string]::join(";",($_.description))}}).description))
                            'IPAddress' = $(((Get-CimInstance -CimSession $session -ClassName win32_networkadapterconfiguration -Filter "IPEnabled = 'true'" | select @{Name='IPAddress';Expression={[string]::join(";",($_.ipaddress))}}).IPAddress))
                            'SMBIOSBIOSVersion' = $((Get-CimInstance -CimSession $session -ClassName win32_bios).smbiosbiosversion)  
                            'ManuFacturer' = $((Get-CimInstance -CimSession $session -ClassName win32_computersystem).manufacturer)
                            'Model' = $((Get-CimInstance -CimSession $session -ClassName win32_computersystem).model)
                            'OS' = $((Get-CimInstance -CimSession $session -ClassName win32_operatingsystem).caption)
                            'OSVersion' = $((Get-CimInstance -CimSession $session -ClassName win32_operatingsystem).version)
                            'InstalledFeatures' = $(((Get-CimInstance -CimSession $session -ClassName win32_optionalfeature | sort name).name).trim())
                            'Ping' = 'True'
                        }
                        $obj = New-Object -TypeName psobject -Property $Properties
                        $obj
 
             }

        }

     }
    
}

function Search-OnlineServers{
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $temp = Get-ADComputer -Filter {operatingsystem -like "*server*"} -SearchBase "$($searcher.SearchRoot.Path.Substring(7))" -SearchScope Subtree -Properties *
        ForEach ($t in $temp){
            if((Test-NetConnection -ComputerName $t.name -Hops 1 -WarningAction SilentlyContinue).pingsucceeded -eq 'true'){
                [array]$servers += $t 
            }
        }
    $servers
}