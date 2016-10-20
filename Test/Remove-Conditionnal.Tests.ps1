$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\RCNewFiles.ps1"

$here = $Here|Split-Path -Parent
. "$here\$sut"

$PathSource="$Env:Temp\RC"
. "$ProjectToolsVcs\Remove-Conditionnal.ps1"

function normalizeEnds([string]$text)
{
    $text -replace "`r`n?|`n", "`r`n"
}


$TestCases=@(
 @{File="$PathSource\Test0.ps1";New="$PathSource\Test0.newC.ps1";Key='C'}
 @{File="$PathSource\Test0.ps1";New="$PathSource\Test0.newB.ps1";Key='B'}
 @{File="$PathSource\Test0.ps1";New="$PathSource\Test0.newA.ps1";Key='A'}
)

$TestCasesCombinations=@(
 @{File="$PathSource\Combination1.ps1";New="$PathSource\Combination1-Debug.ps1";Key='Debug'}
 @{File="$PathSource\Combination1.ps1";New="$PathSource\Combination1-Test.ps1";Key='Test'}
 @{File="$PathSource\Combination1.ps1";New="$PathSource\Combination1-Debug+Test.ps1";Key=@('Debug','Test')}
)

$ErrorCases=@(
 @{File="$PathSource\Test05.ps1";Key='C';FQE='IncompletDirective,Remove-Conditionnal'}
 @{File="$PathSource\Test06.ps1";Key='C';FQE='IncompletDirective,Remove-Conditionnal'}
 @{File="$PathSource\Test07.ps1";Key='C';FQE='OrphanDirective,Remove-Conditionnal'}
 @{File="$PathSource\Test09.ps1";Key='C';FQE='OrphanDirective,Remove-Conditionnal'}
)

function CompareStr{
 param([string[]]$Generate,[string[]]$Expected)         
 
 $set1 = New-Object System.Collections.Generic.HashSet[String](,$Generate)
 return ( $set1.SetEquals($Expected) ) 
}


Describe "Remove-Conditionnal" {
 
 Context "When there is no error" {
  
  It "basic principle -Clean directives"{
    [string[]]$A=Get-Content -Path "$PathSource\Test0-1.ps1"  -ReadCount 0 -Encoding UTF8 | Remove-Conditionnal -Clean 
    [string[]]$B=Get-Content -Path "$PathSource\Test0-1.new.ps1" -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true
  } 


  It "basic principle -Clean directives"{
    [string[]]$A=Get-Content -Path "$PathSource\Combination1.ps1"  -ReadCount 0 -Encoding UTF8 | Remove-Conditionnal -Clean 
    [string[]]$B=Get-Content -Path "$PathSource\Combination1-Clean.ps1" -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true
  } 
    
  
  It "basic principle -Remove directive"{
    [string[]]$A=Get-Content -Path "$PathSource\Test0-2.ps1"  -ReadCount 0 -Encoding UTF8 | Remove-Conditionnal -Remove 
    [string[]]$B=Get-Content -Path "$PathSource\Test0-2.new.ps1" -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true
  } 

 
  It "basic principle use 'Include' directive" {
    [string[]]$A=Get-Content -Path "$PathSource\TestInclude1.ps1"  -ReadCount 0 -Encoding UTF8 | Remove-Conditionnal -Include 
    [string[]]$B=Get-Content -Path "$PathSource\TestInclude1.new.ps1" -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true
  }   

  It "basic principle use 'Uncomment' directive" {
    [string[]]$A=Get-Content -Path "$PathSource\TestUNCOMMENT.ps1"  -ReadCount 0 -Encoding UTF8 | Remove-Conditionnal -UnComment 
    [string[]]$B=Get-Content -Path "$PathSource\TestUNCOMMENT.new.ps1" -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true
  }   

  It "basic principle -ConditionnalsKeyWord" -TestCase $TestCases {
    Param(
      [string]$File,
      [string]$New,
      [string]$Key
     )  
    Write-Host "key=$key" 
    [string[]]$A=Get-Content -Path $File -ReadCount 0 -Encoding UTF8 |
                  Remove-Conditionnal -ConditionnalsKeyWord $Key |
                  Remove-Conditionnal -Clean 
     
    [string[]]$B=Get-Content -Path $New -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true
  } 
  
  It "basic principle -ConditionnalsKeyWord nested + combinations" -TestCase $TestCasesCombinations {
    Param(
      [string]$File,
      [string]$New,
      [string[]]$Key
     )  
    Write-Host "key=$key" 
    [string[]]$A=Get-Content -Path $File -ReadCount 0 -Encoding UTF8 |
                  Remove-Conditionnal -ConditionnalsKeyWord $Key

    [string[]]$B=Get-Content -Path $New -ReadCount 0 -Encoding UTF8        
  
    CompareStr $A $B| Should Be $true                      
  }
 }

 Context "When there error" {
  
  It "basic principle use 'Include' directive, file do not exist" {
    try {
      $ErrorActionPreference = "Stop"
      [string[]]$A=Get-Content -Path "$PathSource\TestInclude2.ps1"  -ReadCount 0 -Encoding UTF8 | 
        Remove-Conditionnal -Include 
    } 
    catch
    {
      $s="Include - the file do not exist '$PathSource\NotExist.ps1',Remove-Conditionnal"
      $_.FullyQualifiedErrorId | Should be 'IncludedFileNotFound,Remove-Conditionnal'
    } 
  }   
  
  It "basic principle use 'Include' directive, Drive do not exist" {
    try {
      $ErrorActionPreference = "Stop"
      [string[]]$A=Get-Content -Path "$PathSource\TestInclude3.ps1"  -ReadCount 0 -Encoding UTF8 | 
        Remove-Conditionnal -Include 
    } 
    catch
    {
      $_.FullyQualifiedErrorId | Should be 'IncludedFileNotFound,Remove-Conditionnal'
    } 
  }    

  It "basic principle -ConditionnalsKeyWord. Nesting 'DEFINE' erroneous "{
   #peut importe la clé, la fonction valide l'ensemble des déclarations 
    try {
     $ErrorActionPreference = "Stop"
     Get-Content -Path "$PathSource\Test01.ps1"  -ReadCount 0 -Encoding UTF8 |
      Remove-Conditionnal -ConditionnalsKeyWord 'A'
    } 
    catch
    {
      $_.FullyQualifiedErrorId | Should be 'DirectivesIncorrectlyNested,Remove-Conditionnal'
    } 
  }
  
  It "basic principle -ConditionnalsKeyWord. Nesting 'UNDEF' erroneous "{
   try { 
    $ErrorActionPreference = "Stop"     
    Get-Content -Path "$PathSource\Test02.ps1"  -ReadCount 0 -Encoding UTF8 |
      Remove-Conditionnal -ConditionnalsKeyWord 'A'
   }
   catch
   {
     $_.FullyQualifiedErrorId | Should be 'DirectivesIncorrectlyNested,Remove-Conditionnal'
   } 
   }

  It "basic principle -ConditionnalsKeyWord. Nesting 'DEFINE' orphan"{
   try { 
    $ErrorActionPreference = "Stop"
     Get-Content -Path "$PathSource\Test03.ps1"  -ReadCount 0 -Encoding UTF8 |
      Remove-Conditionnal -ConditionnalsKeyWord 'A'
    }
    catch
    {
      $_.FullyQualifiedErrorId | Should be 'DirectivesIncorrectlyNested,Remove-Conditionnal'
    } 
  }  

  It "basic principle -ConditionnalsKeyWord. 'DEFINE' is not nested, but orphan"{
   try {
    $ErrorActionPreference = "Stop"
    Get-Content -Path "$PathSource\Test031.ps1"  -ReadCount 0 -Encoding UTF8 |
       Remove-Conditionnal -ConditionnalsKeyWord 'A'
   }
   catch
   {
     $_.FullyQualifiedErrorId | Should be 'IncompletDirective,Remove-Conditionnal'
   } 
  }  

  It "basic principle -ConditionnalsKeyWord. Nesting 'UNDEF' orphan"{
   try {
    $ErrorActionPreference = "Stop"
    Get-Content -Path "$PathSource\Test04.ps1"  -ReadCount 0 -Encoding UTF8 | 
      Remove-Conditionnal -ConditionnalsKeyWord 'A' 
   }
   catch
   {
     $_.FullyQualifiedErrorId | Should be 'DirectivesIncorrectlyNested,Remove-Conditionnal'
   } 
  }  

  It "basic principle -ConditionnalsKeyWord. 'UNDEF' is not nested, but orphan"{
   try {
    $ErrorActionPreference = "Stop"
    Get-Content -Path "$PathSource\Test041.ps1"  -ReadCount 0 -Encoding UTF8 |
      Remove-Conditionnal -ConditionnalsKeyWord 'A'
   }
   catch
   {
     $_.FullyQualifiedErrorId | Should be 'OrphanDirective,Remove-Conditionnal'
   } 
  } 

  It "basic principle -ConditionnalsKeyWord. 'UNDEF' missing" -Testcase $ErrorCases{
    Param(
      [string]$File,
      [string]$Key,
      [string] $FQE
     )      
    Write-Host "`tFile : $File"
   try { 
    $ErrorActionPreference = "Stop" 
    Get-Content -Path $File  -ReadCount 0 -Encoding UTF8 |
      Remove-Conditionnal -ConditionnalsKeyWord $Key
   }
   catch
   {
     $_.FullyQualifiedErrorId | Should be $FQE
   }      
  } 

  It "basic principle -ConditionnalsKeyWord. 'DEFINE4 and 'UNDEF' are inverted" {
   try {
    $ErrorActionPreference = "Stop" 
    Get-Content -Path "$PathSource\Test09.ps1" -ReadCount 0 -Encoding UTF8 |
      Remove-Conditionnal -ConditionnalsKeyWord 'NotExist'
   }
   catch
   {
     $_.FullyQualifiedErrorId | Should be 'OrphanDirective,Remove-Conditionnal'
   }         
  } 
 }
}
