#Requires -Modules psake
 [CmdletBinding(DefaultParameterSetName = "PowershellGallery")]
 Param(
      #see appveyor.yml
     [Parameter(ParameterSetName="Other")]
     [ValidateNotNullOrEmpty()]
     $RepositoryName
 )

 #The default repo is used.
 if ( PsCmdlet.ParameterSetName -eq 'PowershellGallery'))
 { $RepositoryName='PSGallery' }

# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList Build -parameters @{"RepositoryName"=$RepositoryName}
