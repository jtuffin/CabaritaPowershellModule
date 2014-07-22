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
