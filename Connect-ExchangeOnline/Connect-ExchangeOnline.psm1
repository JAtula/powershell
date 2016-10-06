<#
.Synopsis
   Connect to Exchange Online. 
.EXAMPLE
    PS C:\> Connect-ExchangeOnline -emailAddress admin@company.onmicrosoft.com
    WARNING: The names of some imported commands from the module 'tmp_3cjh1l1z.bfp' include unapproved verbs that 
    might make them less discoverable. To find the commands with unapproved verbs, run the Import-Module command a
    gain with the Verbose parameter. For a list of approved verbs, type Get-Verb.

    ModuleType Version    Name                                ExportedCommands                                   
    ---------- -------    ----                                ----------------                                   
    Script     1.0        tmp_3cjh1l1z.bfp                    {Add-AvailabilityAddressSpace, Add-DistributionG...

    Connected to Microsoft.Exchange
#>
function Connect-ExchangeOnline
{
    [CmdletBinding()]
    Param
    (
        # Emailaddress input
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string]$emailAddress

    )

    Begin
    {
        [string]$mail = ""
        
        #Get user pwd.
        Write-Verbose "Input password"
        [System.Security.SecureString]$secString = Read-Host 'Password' -AsSecureString
        $OldPSSession = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}
    }
    Process
    {
        #Remove existing session.
        Write-Verbose "Remove existing session"
        if($OldPSSession -ne $null){
            Remove-PSSession -Id $OldPSSession.Id -ErrorAction SilentlyContinue
        }
        
        try
        {
            #Test emailaddress validity.
            Write-Verbose "Test email address validity"
            $mail = New-Object System.Net.Mail.MailAddress($emailAddress) -ErrorAction stop
        }
        catch
        {
            Write-Host "Mail format invalid." -ForegroundColor Red
            return
        }
        
        $cred = New-Object System.Management.Automation.PSCredential($mail,$secString)

        try{
            #Connect MSOL service.
            Write-Verbose "Connect MSOL service"
            Connect-MsolService -Credential $cred -ErrorAction Stop | Out-Null
        }
        catch{
            Write-Host $Error[0].Exception.Message -ForegroundColor Red
            return
        }

        try{
            #Connect to Exchange Online
            Write-Verbose "Connect to Exchange Online"
            $PSSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $cred -Authentication Basic -AllowRedirection -ErrorAction Stop 
            Import-Module (Import-PSSession $PSSession -AllowClobber -DisableNameChecking) -Global | Out-Null 
        }
        catch{
            write-host $Error[0].Exception.Message -ForegroundColor Red
            return
        }
       
    }
    End
    {
        if($PSSession -ne $null){
            Write-Host "`nConnected to $($PSSession.ConfigurationName)" -ForegroundColor Yellow
        }else{
            Write-Host "Session import failed." -ForegroundColor Red
        }
    }
}