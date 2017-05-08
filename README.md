[![Build status](https://ci.appveyor.com/api/projects/status/ll5tv37ggguiulva?svg=true)](https://ci.appveyor.com/project/LaurentDardenne/template)
                                                                                    
![Logo](https://raw.githubusercontent.com/LaurentDardenne/Template/master/Assets/Template.png)

# Template
Code generation by using text templates.
A template specifies a text template with placeholders for data to be extracted from models.

The 'Template' module offers these features:
 * [Text replacement](https://github.com/LaurentDardenne/Template/wiki/Text-replacement), simple or by regex or regex with [MatchEvaluator](https://msdn.microsoft.com/en-us/library/system.text.regularexpressions.matchevaluator(v=vs.110).aspx) (Scriptblock)
 * [File inclusion](https://github.com/LaurentDardenne/Template/wiki/File-inclusion)
 * [Directive to run embedded scripts](https://github.com/LaurentDardenne/Template/wiki/Directive-to-run-embedded-scripts)
 * [Conditionnal directive](https://github.com/LaurentDardenne/Template/wiki/Conditionnal-directives) (#Define & #Undef)
 * [Removal and uncomment directive](https://github.com/LaurentDardenne/Template/wiki/Removal-and-uncomment-directive)

## Install
```powershell
$PSGalleryPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
$PSGallerySourceUri = 'https://www.myget.org/F/ottomatt/api/v2'
Register-PSRepository -Name OttoMatt -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri #-InstallationPolicy Trusted

Install-Module Template -Repository OttoMatt
```
## Principle
A template is a file that serves as a starting point for a new document.
The 'Template' module, allow to insert directives, as a comment, inside the source code.
For example :
```Powershell
    Write-Debug 'Test' #<%REMOVE%>
```
In this case, the presence of this directive does not require to transform the source code before to execute it.

For this example, the directives require a transformation :
```Powershell
Import-Module Template
 #Initialize-TemplateModule.ps1 create the hashtable $TemplateDefaultSettings

$File='C:\temp\Code.PS1'
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
```
The following script transform the content:
```Powershell
[string[]]$Lines=Get-Content -Path $File  -ReadCount 0 -Encoding UTF8
  #Edit-Template need an ARRAY of string
$Result=,$Lines|Edit-Template -ConditionnalsKeyWord  "V5"|
 Edit-Template -Clean
$Result
```
to :
```Powershell
Write 'Text before the directive'
<#%ScriptBlock%

        . .\New-PSCustomObjectFunction.ps1
        #PSCustomObject >= v3
        New-PSCustomObjectFunction -Noun ProcessLight -Parameters Name,VirtualMemorySize -File
#>
Write 'Text after the directive'
```
The text between the directive \#&lt;DEFINE %V5%&gt; and \#&lt;UNDEF %V5%&gt; is deleted.
The parameter _*-Clean*_ remove the remaining directives inside the text.

The second step, invoke the script to generate text :
```Powershell
 #Edit-String need a string
$ofs="`r`n"
"$Result"|
 Edit-String -Setting  $TemplateDefaultSettings
```
The final source code :
```Powershell
Write 'Text before the directive'
Function New-ProcessLight{
param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
         [Parameter(Mandatory=$True,position=1)]
        $VirtualMemorySize
)

  [pscustomobject]@{
    PSTypeName='ProcessLight';
    Name=$Name;
    VirtualMemorySize=$VirtualMemorySize;
   }


}# New-ProcessLight
Write 'Text after the directive'
```

With this script :
```Powershell
Get-Content -Path $File  -ReadCount 0 -Encoding UTF8|
 Edit-Template -ConditionnalsKeyWord  "V3"|
 Edit-Template -Clean|
 Out-string|
 Edit-String -Hashtable $TemplateDefaultSettings
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
