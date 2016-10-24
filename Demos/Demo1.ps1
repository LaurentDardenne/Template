
Import-Module Template
#Initialize-TemplateModule.ps1 create the hashtable $TemplateDefaultSettings

Set-Location $PSScriptRoot
$File="$env:temp\Code.T.PS1"
@'
Write 'Text before the directive'
<#%ScriptBlock%
    #<DEFINE %V5%>
        . .\Convert-ObjectToClass.ps1
        #Class PS >= v5
        Convert-ObjectToClass -InputObject (Get-Process|Select Name,VirtualMemorySize -First 1)
    #<UNDEF %V5%>

    #<DEFINE %V3%>
        . .\New-PSCustomObjectFunction.ps1
        #PSCustomObject >= v3
        New-PSCustomObjectFunction -Noun ProcessLight -Parameters Name,VirtualMemorySize -AsFunction
    #<UNDEF %V3%>
#>
Write 'Text after the directive'
'@ > $File

#code generation for Powershell version 3
#Edit-Template need an ARRAY of string
[string[]]$Lines=Get-Content -Path $File  -ReadCount 0 -Encoding UTF8
 #On itère pas les obets du tableau, on passe un objet: le tableau en entier
$Result=,$Lines|Edit-Template -ConditionnalsKeyWord  "V5"|
 Edit-Template -Clean

#Edit-String need a string
$ofs="`r`n"
"$Result"|Edit-String -Setting  $TemplateDefaultSettings

#code generation for Powershell version 5
Get-Content -Path $File  -ReadCount 0 -Encoding UTF8|
 Edit-Template -ConditionnalsKeyWord  "V3"|
 Edit-Template -Clean|
 Out-string|
 Edit-String -Setting  $TemplateDefaultSettings


#Substitute variable 'à la Plaster'
$T_Name='Text Transformation'
$Text=@'
 #comment
Write-host "Project : <%=${T_Name}%>"
'@
$Text| Edit-String -Setting $TemplateDefaultSettings

#Note:
    #La chaîne $Text référence un nom de variable
    #Le scriptblock associé à la regex est déclaré dans la portée de l'appelant (ce script)
    #La fonction Edit-String exécute, dans la portée de son module, le scriptblock en tant que
    # délégué d'une regex.
    #En interne Powershell exécute le scriptblock dans la portée où il a été déclaré.

#Define class with interface implementation
$Code=
@'
<#%ScriptBlock%
  . .\Get-InterfaceSignature.ps1

  $T=@(
   'System.ICloneable',
   'System.Collections.ICollection',
   'System.Collections.IEnumerable'
   )

   " #Implement an interface`r`n"

   $ofs=', '
   "Class TodoName:$T {`r`n"

   $T | Get-InterfaceSignature
#>
} #MyCollection
'@
$Code| Edit-String -Setting $TemplateDefaultSettings

#Or
. .\Get-InterfaceSignature.ps1

$T=@(
 'System.ICloneable',
 'System.Collections.ICollection',
 'System.Collections.IEnumerable'
)


$Code=
@'
<#%ScriptBlock%
   " #Implement an interface`r`n"

   $ofs=', '
   "Class TodoName:$T {`r`n"

   $T | Get-InterfaceSignature
#>
} #MyCollection
'@
$Code| Edit-String -Setting $TemplateDefaultSettings


$Code=
@'
<#%ScriptBlock%
$ofs=$null
New-RecordType -ClassName 'MyClass' -Header 'string Name, string EMail, int MBSize' | Out-String
Write-output "`r`n"
New-RecordType -ClassName 'DiskReport' -Header 'String HostName, string Letter, int Size' | Out-String
Write-output "`r`n"
New-RecordType -ClassName 'ClassDefinition' -Header 'string Name, string Header' | Out-String
Write-output "`r`n"
#>
'@
$Code| Edit-String -Setting $TemplateDefaultSettings

$T=@(
 New-ClassDefinition -ClassName 'MyClass' -Header 'string Name, string EMail, int MBSize'
 New-ClassDefinition -ClassName 'DiskReport' -Header 'String HostName, string Letter, int Size'
 New-ClassDefinition -ClassName 'ClassDefinition' -Header 'string Name, string Header'
)

$Code=
@'
<#%ScriptBlock%
   $ofs=$null
   $T|
    New-RecordType|
    Foreach {
     Write-output "$_`r`n`r`n"
    }
#>
'@
$Code| Edit-String -Setting $TemplateDefaultSettings
