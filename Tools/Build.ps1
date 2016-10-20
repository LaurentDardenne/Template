#Build.ps1
#Construit la version de Template  
 [CmdletBinding(DefaultParameterSetName = "Debug")]
 Param(
     [Parameter(ParameterSetName="Release")]
   [switch] $Release
 ) 
# Le profile du projet (Template_ProjectProfile.ps1) doit être chargé

Set-Location $TemplateTools

try {
 'Psake'|
 Foreach {
   $name=$_
   Import-Module $Name -EA stop -force
 }
} catch {
 Throw "Module $name is unavailable."
}  

$Error.Clear()
Invoke-Psake .\Release.ps1 -parameters @{"Config"="$($PsCmdlet.ParameterSetName)"} -nologo


