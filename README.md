# Template
Code generation by using text templates.

Template : A template specifies a text template with placeholders for data to be extracted from models.


The Template module offers these features:
 * text replacement, simple or by regex or regex with [MatchEvaluator](https://msdn.microsoft.com/en-us/library/system.text.regularexpressions.matchevaluator(v=vs.110).aspx) (Scriptblock)
 * file inclusion
 * directive to run embeded scripts
 * Conditionnal directive (#Define & #Undef)
 * Removal and uncomment directive

## Principle
A template is a file that serves as a starting point for a new document.
With the content of these file :
```Powershell
$File='C:\temp\Code.T.PS1'
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
        New-PSCustomObjectFunction -Noun ProcessLight -Parameters Name,VirtualMemorySize -File
    #<UNDEF %V3%>
#>
Write 'Text after the directive'
'@ > $File
```
The following script :
```Powershell
[string[]]$Lines=Get-Content -Path $File  -ReadCount 0 -Encoding UTF8
,$Lines|Edit-Template -ConditionnalsKeyWord  "V5"|
 Edit-Template -Clean
```
Transform the content to :
```Powershell
Write 'Text before the directive'
<#%ScriptBlock%

        . New-PSCustomObjectFunction.ps1
        #PSCustomObject >= v3
        New-PSCustomObjectFunction -Noun ProcessLight -Parameters Name,VirtualMemorySize -File
#>
Write 'Text after the directive'
```
The text between \#&lt;DEFINE %V5%&gt; and \#&lt;UNDEF %V5%&gt; is deleted.
The parameter _*-Clean*_ remove the remaining directives inside the text.

With this script :
```Powershell
Get-Content -Path $File  -ReadCount 0 -Encoding UTF8|
 Edit-Template -ConditionnalsKeyWord  "V3"|
 Edit-Template -Clean|
 Out-string|
 Edit-String -Hashtable $h #Todo example
```
The result text is :
```Powershell
Write 'Text before the directive'
class ProcessLight
{
        [string] $Name;
        [int] $VirtualMemorySize;

        ProcessLight([System.Diagnostics.Process] $Process) {
                $this.Name = $Process.Name
                $this.VirtualMemorySize = $Process.VirtualMemorySize

        }
} #ProcessLight
Write 'Text after the directive'
```
