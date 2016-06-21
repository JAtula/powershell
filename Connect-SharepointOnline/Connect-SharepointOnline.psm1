<#
.Synopsis
   Connect to SharePoint Online. 
.EXAMPLE
   
#>
function Connect-SharePointOnline
{
    [CmdletBinding()]
    Param
    (
        # Emailaddress input
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string]$emailAddress,


         # Tenant name
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=1)]
        [string]$tenant

    )

    Begin
    {
        [string]$mail = ""

        #Import Sharepoint Online module.
        Write-Verbose "Importing Sharepoint Online module.."
        if(!(Get-Module).Name -ne "Microsoft.Online.Sharepoint.Powershell"){
            try{
                Import-Module 'C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell' | Out-Null
            }
            catch{
                write-host $Error[0].exception.message -ForegroundColor Red
                return
            }
        }
        
        #Get user pwd.
        [System.Security.SecureString]$secString = Read-Host "Password" -AsSecureString
        
       <# #Remove existing session.
        Write-Verbose "Removing existing session.."
        $PSSession = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}
        if($PSSession){
            Remove-PSSession -Id $PSSession.id -ErrorAction SilentlyContinue
        }#>
    }
    Process
    {
        try
        {
            #Test emailaddress validity.
            Write-Verbose "Testing emailaddress validity.."
            $mail = New-Object System.Net.Mail.MailAddress($emailAddress) -ErrorAction stop
        }
        catch
        {
            Write-Host "Mail format invalid." -ForegroundColor Red
            return
        }
        
        $cred = New-Object System.Management.Automation.PSCredential($mail,$secString)

        try{
            #Connect Sharepoint Online service.
            Connect-SPOService -Url "https://$($tenant)-admin.sharepoint.com" -Credential $cred
            $PSSession = $true
        }
        catch{
            Write-Host $Error[0].Exception.Message -ForegroundColor Red
            return
        }

       <# try{
            #Connect to Exchange Online
            $PSSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection -ErrorAction Stop
            Import-PSSession $PSSession -ErrorAction Stop
        }
        catch{
            write-host $Error[0].Exception.Message -ForegroundColor Red
            return
        } #>
       
    }
    End
    {
        if($PSSession){
            Write-Host "`nConnected to $($tenant) Sharepoint Online" -ForegroundColor Yellow
        }else{
            Write-Host "Session import failed." -ForegroundColor Red
        }
    }
}