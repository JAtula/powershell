<#
.Author
    Juhani Atula © 2016 v. 1.0
.Synopsis
   Create a AES key and Password hash and dump them to .txt files.
.Description
    Create a AES key and use it to sign a password. Password is a multivalue parameter. Save both the key and the password hash to .txt files. Remember to store the key securely.
.EXAMPLE
   New-PasswordHash -password "pass123" -filepath C:\temp
#>
function New-PasswordHash
{
    [CmdletBinding()]
    Param
    (
        # Password to be used.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$password,

        # Path for the folder to be used.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]$filepath

    )

        # Generate a random 256 bit AES Encryption Key.
        Write-Verbose "Generate 256 bit AES key.."
        $AESKey = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)

        try
        {
            Write-Verbose "Sign password with key and save the key and password hash to .txt files.."
            #Any existing AES key will be overwritten.
            if($password.Count -gt 1){
                foreach($pass in $password) {
                    $i++
                    $secureStringPwd = $pass | ConvertTo-SecureString -AsPlainText -Force

                    Set-Content "$filepath\key$i.txt" $AESKey -ErrorAction Stop
                    $finalpass = $secureStringPwd | ConvertFrom-SecureString -Key $AESKey
                    Set-Content "$filepath\hash$i.txt" $finalpass
                }
            }else{
                $secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force
                
                Set-Content "$filepath\key.txt" $AESKey -ErrorAction Stop
                $finalpass = $secureStringPwd | ConvertFrom-SecureString -Key $AESKey
                Set-Content "$filepath\hash.txt" $finalpass 
            }
        }
        catch
        {
            Write-Host "Path not found." -ForegroundColor Red
        }

}

