function ConvertTo-GBPEuro
{
  param([int]$Pounds)
  $Currency = New-WebServiceProxy -Uri http://www.webservicex.net/CurrencyConvertor.asmx?WSDL
  $GBPEURConversionRate = $Currency.ConversionRate('GBP','EUR')
  $Euros = $Pounds * $GBPEURConversionRate
  Write-Host “$Pounds British Pounds convert to $Euros Euros”
}

function Convert-BWAtoGNU {
  <#
.SYNOPSIS
Converts a CSV export from BWA to a GnuCash suitable format.

.DESCRIPTION
GnuCash has a limited date format and this function removes the unnecessary fields and converts the date text format. The BWA CSV export has the date in dd/mm/yyyy format however GnuCash will only accept d-m-y. Additionally the debits field needs to have the sign flipped. 

.PARAMETER FirstParameter
CSV Content from BWA. 

.INPUTS
CSV Content from BWA. 

.OUTPUTS
CSV Content for GnuCash

.EXAMPLE
Import-Csv -Path BWAExport.csv | Convert-BWAtoGNU | Export-Csv -Path GnuCashBWAExport.csv

.EXAMPLE
$BWACSVData = Import-Csv -Path BWAExport.csv
$GNUCsvData = Convert-BWAtoGNU $BWACSVData
Export-Csv -inputobject $GNUCsvData -path GnuCashBWAExport.csv

#>



  [CmdletBinding()]

  param([Parameter(
      Position = 0,
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)
    ]
    [Alias('CSV Content')]
    $BWACSVContent)


  begin {
  }
  process {
    foreach ($transaction in $BWACSVContent) {
      $newtrans = New-Object -TypeName PSObject
      $newtrans | Add-Member -MemberType NoteProperty -Name TransDate -Value $transaction.'Transaction Date'.replace("/","-")
      $newtrans | Add-Member -MemberType NoteProperty -Name Description -Value $transaction.Narration
      $newtrans | Add-Member -MemberType NoteProperty -Name Withdrawal -Value ([decimal]($transaction.Debit) * -1)
      $newtrans | Add-Member -MemberType NoteProperty -Name Deposit -Value $transaction.Credit
      $newtrans | Add-Member -MemberType NoteProperty -Name Balance -Value $transaction.Balance
      Write-Output $newtrans
    }
  }
  end {
  }
}


function Get-AuthenticationFromFile
{
  <#
.SYNOPSIS
Gets (and sets) a password from file.

.DESCRIPTION
This was made for the storage of passwords for scheduled scripts to run.  

.PARAMETER PasswordFile
Path to the file where the password is stored.

.PARAMETER UserName
For display purposes, the username.

.PARAMETER ReturnSecure
What is the return format? String object or SecureString. 

.OUTPUTS
String object or SecureString. 

.EXAMPLE
Get-AuthenticationFromFile -PasswordFile passwordfile.cfg -UserName johndoe@domain.com -ReturnSecure $true

#>
  [CmdletBinding()]

  param([Parameter(
      Position = 1,
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [string]$PasswordFile,
    [Parameter(
      Position = 2,
      Mandatory = $true,
      ValueFromPipeline = $false,
      ValueFromPipelineByPropertyName = $true)]
    [string]$UserName,
    [Parameter(
      Position = 3,
      ValueFromPipelineByPropertyName = $true)]
    [bool]$ReturnSecure)

  process {
    if (!(Test-Path $PasswordFile))
    {
      Read-Host "Enter Password for $UserName" -AsSecureString | ConvertFrom-SecureString | Out-File $PasswordFile
    }
    $Password = Get-Content $PasswordFile | ConvertTo-SecureString
    if ($ReturnSecure)
    {
      Write-Output $Password
    }
    else
    {
      $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Password)
      $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
      Write-Output $result
    }
  }
}


function Test-Admin
{
  $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
  $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
  $prp.IsInRole($adm)  
}

function Show-OpenFileDialog
{
 [CmdletBinding()]

  param([Parameter(
      Position = 1,
      Mandatory = $false,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [string]$InitialDirectory,
    [Parameter(
      Position = 2,
      Mandatory = $false,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [bool]$MultiSelect)

    begin
    {

    Add-Type -AssemblyName System.Windows.Forms
    }
  process {
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = $InitialDirectory
    Multiselect = $MultiSelect
}
 
[void]$FileBrowser.ShowDialog()
write-output $FileBrowser.FileNames
 }

}


function Write-ConfigToFile
{
<#
.SYNOPSIS
Writes a config object as JSON to file.

.DESCRIPTION
This is a config object for script automation.  

.PARAMETER ConfigFile
Path to the file where the config is stored.

.PARAMETER ConfigObject
For display purposes, the username.

.PARAMETER Force
If the file exists then overwrite.

.OUTPUTS
Success status. 

.EXAMPLE
Write-ConfigToFile -ConfigFile MyProgram.cfg -ConfigObject $SessionConfig

.EXAMPLE
$SessionConfig | Write-ConfigToFile -ConfigFile MyProgram.cfg 

.EXAMPLE
This is an example of a config object.

$SessionConfig = New-Object -TypeName PSObject
$SessionConfig | add-member -membertype NoteProperty -name ServiceName -Value "Office365"
$SessionConfig | add-member -membertype NoteProperty -name InstanceName -Value "MyInstance"
$SessionConfig | add-member -membertype NoteProperty -name Username -Value "username@domain.onmicrosoft.com"
$SessionConfig | add-member -membertype NoteProperty -name PasswordFileName -Value "userpasswordfile.txt"
$SessionConfig | add-member -membertype NoteProperty -name SharepointURL -Value "domain.sharepoint.com"

$SessionConfig | Write-ConfigToFile -ConfigFile MyProgram.cfg 


#>
[CmdletBinding()]

Param( [Parameter(
Position=1,
Mandatory=$true,
ValueFromPipeline=$false,
ValueFromPipelineByPropertyName=$true)]
[String] $ConfigFile, 
       [Parameter(
Position=2,
Mandatory=$true,
ValueFromPipeline=$true,
ValueFromPipelineByPropertyName=$true)]
[String] $ConfigObject,

[switch] $Force)
       
PROCESS{
       if((Test-Path $ConfigFile) -and (!($Foce))) 
       {
         Write-Debug "File exists. Overwrite not selected."
         Write-Output $false
       } else {
         ConvertTo-Json -InputObject $ConfigObject | Out-File -FilePath $ConfigFile
         Write-Output $true
       }
}
}





function Read-ConfigFromFile
{
<#
.SYNOPSIS
Reads a config object as JSON from file.

.DESCRIPTION
This is a config object for script automation.  

.PARAMETER ConfigFile
Path to the file where the config is stored.

.OUTPUTS
Config Object. 

.EXAMPLE
Read-ConfigFromFile -ConfigFile MyProgram.cfg 

.EXAMPLE
$ConfigObject = Read-ConfigFromFile -ConfigFile MyProgram.cfg 


#>
[CmdletBinding()]

Param( [Parameter(
Position=1,
Mandatory=$true,
ValueFromPipeline=$true,
ValueFromPipelineByPropertyName=$true)]
[String] $ConfigFile)
       
PROCESS{
Write-Output (ConvertFrom-Json -InputObject ((Get-Content $ConfigFile) -join "`n"))
}

}



function Start-SPOLibraries {

[CmdletBinding()]
Param ()

PROCESS {
#Add references to SharePoint client assemblies and authenticate to Office 365 site - required for CSOM
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
}
}

function Get-SPOCredSet {
[CmdletBinding()]
Param( [Parameter(
Position=1,
Mandatory=$true,
ValueFromPipeline=$true,
ValueFromPipelineByPropertyName=$true)]
[String] $Username,
[Parameter(
Position=2,
Mandatory=$true,
ValueFromPipeline=$true,
ValueFromPipelineByPropertyName=$true)]
[System.Security.SecureString] $Password)

PROCESS {
$Credset = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $Password)
Write-Output $Credset
}
}

function Get-SPOContext {
[CmdletBinding()]
Param( [Parameter(
Position=1,
Mandatory=$true,
ValueFromPipeline=$true,
ValueFromPipelineByPropertyName=$true)]
[String] $URL)

PROCESS {
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($URL)
Write-Output $Context
}
}

