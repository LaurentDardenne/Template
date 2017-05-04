﻿#Install.psake.ps1

###############################################################################
# Dot source the user's customized properties and extension tasks.
###############################################################################
. $PSScriptRoot\Install.settings.ps1

Task default -Depends Install,Update

#todo traitement lié à la config personelle
Task Install -Depends RegisterPSRepository -Precondition { $Mode -eq  'Install'}  {

  #Suppose : PowershellGet à jour

   #On précise le repository car Pester est également sur Nuget
  PowershellGet\Install-Module -Name $PSGallery.Modules -Repository PSGallery -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck
  PowershellGet\Install-Module -Name $MyGet.Modules -Repository OttoMatt -Scope AllUsers -Force -AllowClobber

  #todo
  # Set-location $Env:Temp
  # nuget install ReportUnit
  # #&"$Env:Temp\ReportUnit.1.2.1\tools\ReportUnit.exe"
}

Task RegisterPSRepository {
 try{
  Get-PSRepository OttoMatt -EA Stop >$null
 } catch {
   if ($_.CategoryInfo.Category -ne 'ObjectNotFound')
   { throw $_ }
   else
   {
     # https://github.com/PowerShell/PowerShellGet/issues/76#issuecomment-275099482
     Register-PSRepository -Name OttoMatt -SourceLocation $MyGetSourceUri -PublishLocation $MyGetPublishUri `
                           -ScriptSourceLocation "$MyGetSourceUri\" -ScriptPublishLocation $MyGetSourceUri -InstallationPolicy Trusted
   }
 }

 try{
  Get-PSRepository DevOttoMatt -EA Stop >$null
 } catch {
   if ($_.CategoryInfo.Category -ne 'ObjectNotFound')
   { throw $_ }
   else
   { Register-PSRepository -Name DevOttoMatt -SourceLocation $DEV_MyGetSourceUri -PublishLocation $DEV_MyGetPublishUri `
                           -ScriptSourceLocation "$DEV_MyGetSourceUri\" -ScriptPublishLocation $DEV_MyGetPublishUri -InstallationPolicy Trusted
   }
 }
}

Task Update -Precondition { $Mode -eq 'Update'}  {
  #todo factoriser
  $sbUpdateOrInstallModule={
      $ModuleName=$_
      try {
        Write-Host "Update module $ModuleName"
        Update-Module -name $ModuleName
      }
      catch [Microsoft.PowerShell.Commands.WriteErrorException]{
        if ($_.FullyQualifiedErrorId -match ('^ModuleNotInstalledOnThisMachine'))
        {
          Write-Host "`tInstall module $ModuleName"
          Install-Module -Name $ModuleName -Repository $CurrentRepository -Scope AllUsers
        }
        else
        { throw $_ }
      }
  }

   $sbUpdateOrInstallScript={
      $ScriptName=$_
      try {
        Write-Host "Update script $ScriptName"
        Update-Script -name $ScriptName
      }
      catch [Microsoft.PowerShell.Commands.WriteErrorException]{
        if ($_.FullyQualifiedErrorId -match ('^ScriptNotInstalledOnThisMachine'))
        {
          Write-Host "`tInstall script $ScriptName"
          Install-Script -Name $ScriptName -Repository $CurrentRepository -Scope AllUsers
        }
        else
        { throw $_ }
      }
  }
  $CurrentRepository='PSGallery'
   $PSGallery.Modules|Foreach-Object $sbUpdateOrInstallModule
   $PSGallery.Scripts|Foreach-Object $sbUpdateOrInstallScript

  $CurrentRepository='OttoMatt'
   $MyGet.Modules|Foreach-Object $sbUpdateOrInstallModule
   $MyGet.Scripts|Foreach-Object $sbUpdateOrInstallScript
}
