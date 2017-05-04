﻿###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

#TODO : log4net:ERROR Exception while rendering object of type [System.Management.Automation.PSObject] System.NullReferenceException
#       ok sans la tâche Analyze ...


Function Test-CIEnvironment {
  Test-Path $env:APPVEYOR
}

Function Get-ApiKeyIntoCI {
     #Read Appveyro environment variable (encrypted)
    if ($BuildConfiguration -eq 'Debug')
    { return $Env:DevMyGetApiKey }
    else
    { return $Env:MyGetApiKey }
}

function GetPowershellGetPath {
 #extracted from PowerShellGet/PSModule.psm1

  $IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
  if($IsInbox)
  {
      $ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
  }
  else
  {
      $ProgramFilesPSPath = $PSHome
  }

  if($IsInbox)
  {
      try
      {
          $MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
      }
      catch
      {
          $MyDocumentsFolderPath = $null
      }

      $MyDocumentsPSPath = if($MyDocumentsFolderPath)
                                  {
                                      Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
                                  }
                                  else
                                  {
                                      Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
                                  }
  }
  elseif($IsWindows)
  {
      $MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath 'Documents\PowerShell'
  }
  else
  {
      $MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath ".local/share/powershell"
  }

  $Result=[PSCustomObject]@{

   AllUsersModules = Microsoft.PowerShell.Management\Join-Path -Path $ProgramFilesPSPath -ChildPath "Modules"
   AllUsersScripts = Microsoft.PowerShell.Management\Join-Path -Path $ProgramFilesPSPath -ChildPath "Scripts"

   CurrentUserModules = Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsPSPath -ChildPath "Modules"
   CurrentUserScripts = Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsPSPath -ChildPath "Scripts"
  }
  return $Result
}

function GetModulePath {
 param($Name)
  $List=@(Get-Module $Name -ListAvailable)
  if ($List.Count -eq 0)
  { Throw "Module '$Name' not found."}
   #Last version
  $List[0].Path
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Test-BOMFile{
  param (
    [Parameter(mandatory=$true)]
    $Path
   )

    $Params=@{
      Include=@('*.ps1','*.psm1','*.psd1','*.ps1xml','*.xml','*.txt');
      Exclude=@('*.bak','*.exe','*.dll')
    }

    Get-ChildItem -Path $Path -Recurse @Params |
        Where-Object { (-not $_.PSisContainer) -and ($_.Length -gt 0)}|
        ForEach-Object  {
        Write-Verbose "Test BOM for '$($_.FullName)'"
        # create storage object
        $EncodingInfo = 1 | Select FileName,Encoding,BomFound,Endian
        # store file base name (remove extension so easier to read)
        $EncodingInfo.FileName = $_.FullName
        # get full encoding object
        $Encoding = Get-DTWFileEncoding $_.FullName
        # store encoding type name
        $EncodingInfo.Encoding = $EncodingTypeName = $Encoding.ToString().SubString($Encoding.ToString().LastIndexOf(".") + 1)
        # store whether or not BOM found
        $EncodingInfo.BomFound = "$($Encoding.GetPreamble())" -ne ""
        $EncodingInfo.Endian = ""
        # if Unicode, get big or little endian
        if ($Encoding.GetType().FullName -eq ([System.Text.Encoding]::Unicode.GetType().FullName)) {
            if ($EncodingInfo.BomFound) {
            if ($Encoding.GetPreamble()[0] -eq 254) {
                $EncodingInfo.Endian = "Big"
            } else {
                $EncodingInfo.Endian = "Little"
            }
            } else {
            $FirstByte = Get-Content -Path $_.FullName -Encoding byte -ReadCount 1 -TotalCount 1
            if ($FirstByte -eq 0) {
                $EncodingInfo.Endian = "Big"
            } else {
                $EncodingInfo.Endian = "Little"
            }
            }
        }
        $EncodingInfo
        }|
        #PS v2 Big Endian plante la signature de script
        Where-Object {($_.Encoding -ne "UTF8Encoding") -or ($_.Endian -eq "Big")}
}

Properties {
    # ----------------------- Basic properties --------------------------------
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ProjectName= 'Template'

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ProjectUrl= 'https://github.com/LaurentDardenne/Template.git'

    # The root directories for the module's docs, src and test.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DocsRootDir = "$PSScriptRoot\docs"
    $SrcRootDir  = "$PSScriptRoot\src"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestRootDir = "$PSScriptRoot\test"

    # The name of your module should match the basename of the PSD1 file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ModuleName = Get-Item $SrcRootDir/*.psd1 |
                      Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } |
                      Select-Object -First 1 | Foreach-Object BaseName

    # The $OutDir is where module files and updatable help files are staged for signing, install and publishing.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $OutDir = "$PSScriptRoot\Release"

    # The local installation directory for the install task. Defaults to your home Modules location.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $A="Split-Path $($profile.CurrentUserAllHosts) -Parent"
    $b="Modules\$ModuleName\$((Test-ModuleManifest -Path $SrcRootDir\$ModuleName.psd1).Version.ToString())"
    Write-host "A='$a'"
    Write-host "B='$B'"
    $InstallPath = Join-Path (Split-Path $profile.CurrentUserAllHosts -Parent) `
                             "Modules\$ModuleName\$((Test-ModuleManifest -Path $SrcRootDir\$ModuleName.psd1).Version.ToString())"

    # Default Locale used for help generation, defaults to en-US.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DefaultLocale = 'en-US'

    # Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
    # Typically you wouldn't put any file under the src dir unless the file was going to ship with
    # the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Exclude = @('Template.psm1','Template.psd1','*.bak')

    # ------------------ Script analysis properties ---------------------------

    # Enable/disable use of PSScriptAnalyzer to perform script analysis.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalysisEnabled = $true

    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
    # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
    # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
    # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
    # "Any" will fail the build on any diagnostic record, regardless of severity.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    [ValidateSet('Error', 'Warning', 'Any', 'None')]
    $ScriptAnalysisFailBuildOnSeverityLevel = 'Error'

    # Path to the PSScriptAnalyzer settings file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalyzerSettingsPath = "$PSScriptRoot\ScriptAnalyzerSettings.psd1"

    # Module names for additionnale custom rule
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    [String[]]$PSSACustomRules=@()
    #   GetModulePath -Name OptimizationRules todo remove call log4net
    #   GetModulePath -Name ParameterSetRules
    # )

    #MeasureLocalizedData
     #Full path of the module to control
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $LocalizedDataModule="$SrcRootDir\Template.psm1"

     #Full path of the function to control. If $null is specified only the primary module is analyzed.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $LocalizedDataFunctions=$null

    #Cultures names to test the localized resources file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CulturesLocalizedData='en-US','fr-FR'

    # ------------------- Script signing properties ---------------------------

    # Set to $true if you want to sign your scripts. You will need to have a code-signing certificate.
    # You can specify the certificate's subject name below. If not specified, you will be prompted to
    # provide either a subject name or path to a PFX file.  After this one time prompt, the value will
    # saved for future use and you will no longer be prompted.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptSigningEnabled = $false

    # Specify the Subject Name of the certificate used to sign your scripts.  Leave it as $null and the
    # first time you build, you will be prompted to enter your code-signing certificate's Subject Name.
    # This variable is used only if $SignScripts is set to $true.
    #
    # This does require the code-signing certificate to be installed to your certificate store.  If you
    # have a code-signing certificate in a PFX file, install the certificate to your certificate store
    # with the command below. You may be prompted for the certificate's password.
    #
    # Import-PfxCertificate -FilePath .\myCodeSigingCert.pfx -CertStoreLocation Cert:\CurrentUser\My
    #
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertSubjectName = $null

    # Certificate store path.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertPath = "Cert:\"

    # -------------------- File catalog properties ----------------------------

    # Enable/disable generation of a catalog (.cat) file for the module.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CatalogGenerationEnabled = $false

    # Select the hash version to use for the catalog file: 1 for SHA1 (compat with Windows 7 and
    # Windows Server 2008 R2), 2 for SHA2 to support only newer Windows versions.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CatalogVersion = 2

    # ---------------------- Testing properties -------------------------------

    # Enable/disable Pester code coverage reporting.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageEnabled = $false

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageFiles = "$SrcRootDir\*.ps1", "$SrcRootDir\*.psm1"

    # -------------------- Publishing properties ------------------------------

    # Your NuGet API key for the nuget feed (PSGallery, Myget, Private).  Leave it as $null and the first time you publish,
    # you will be prompted to enter your API key.  The build will store the key encrypted in the
    # $NuGetApiKeyPath file, so that on subsequent publishes you will no longer be prompted for the API key.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Script:NuGetApiKey = $null

    # Name of the repository you wish to publish to.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PublishRepository = $RepositoryName

    # Name of the repository for the development version
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Dev_PublishRepository = 'DevOttoMatt'

    # Path to encrypted APIKey file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NuGetApiKeyPath = "$env:LOCALAPPDATA\Plaster\SecuredBuildSettings\$PublishRepository-ApiKey.clixml"

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    # The contents of this file are used during publishing for the ReleaseNotes parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ReleaseNotesPath = "$PSScriptRoot\ChangeLog.md"


    # ----------------------- Misc properties ---------------------------------

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter. PFX passwords will not be stored.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SettingsPath = "$env:LOCALAPPDATA\Plaster\SecuredBuildSettings\$ProjectName.clixml"

    # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
    # This is typically used to write out test results so that they can be sent to a CI
    # system like AppVeyor.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFile = $null

    # Specifies the test output format to use when the TestOutputFile property is given
    # a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFormat = "NUnitXml"

    # Specifies the paths of the installed scripts
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PSGetInstalledPath=GetPowershellGetPath

    # Execute or nor 'TestBOM' task
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $isTestBom=$true

    # Used by Edit-Template inside the 'RemoveConditionnal' task.
    # Valid values are 'Debug' or 'Release'
    # 'Release' : Remove the debugging/trace lines, include file, expand scriptblock, clean all directives
    # 'Debug' : Do not change anything
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    [ValidateSet('Release','Debug')]  $BuildConfiguration='Release'
     #todo 2 infos le type de construction et le repository associé
     # -> si Debug alors DevOttomatt

    #To manage the ApiKey differently
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $isCIEnvironment=Test-CIEnvironment

}

###############################################################################
# Customize these tasks for performing operations before and/or after file staging.
###############################################################################

Task RemoveConditionnal -requiredVariables BuildConfiguration, ModuleOutDir{
#Traite les pseudo directives de parsing conditionnelle
   #Import-Module Log4Posh -global #todo remove une fois template livré sans les logs
   #Import-Module Template -global
 try {
   $TempDirectory=New-TemporaryDirectory
   $ModuleOutDir="$OutDir\$ModuleName" #todo accesssible via clean ?

   Write-Verbose "Build with '$BuildConfiguration'"
   Get-ChildItem  "$SrcRootDir\Template.psm1","$SrcRootDir\Template.psd1"|
    Foreach-Object {
      $Source=$_
      $TempFileName="$TempDirectory\$($Source.Name)"
      Write-Verbose "Edit : $($Source.FullName)"
      Write-Verbose " to  : $TempFileName"
      if ($BuildConfiguration -eq 'Release')
      {
         #todo selon les associations de repository on peut vouloir supprimer la clé   ExternalModuleDependencies = @('PSScriptAnalyzer')

         #          on ne connait pas l'association MODULE-REPOSITORY !!

         #si on publie sur PSGallery, la clé  n'est pas nécessaire, c'est le même repo
         #si on publie sur Myget, la clé est nécessaire, ce n'est pas le même repo
         #si on publie sur DevMyget, la clé est nécessaire, ce n'est pas le même repo MAIS les dépendances sont sur Myget ....
         # A tester, collision possible , le premier trouvé ?

         #Supprime les lignes de code de Debug et de test
         #On traite une directive et supprime les lignes demandées.
         #On inclut les fichiers.
        Get-Content -Path $Source -Encoding UTF8 -ReadCount 0|
        #  Edit-String -Setting $TemplateDefaultSettings|
        #  Out-ArrayOfString
          #todo Pb : préserver les CR/LF lors de l'écriture du fichier...
         Edit-Template -ConditionnalsKeyWord 'DEBUG' -Include -Remove -Container $Source|
         Edit-Template -Clean|
         Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
      }
      elseif ($BuildConfiguration -eq 'Debug')
      {
         #On ne traite aucune directive et on ne supprime rien.
         #On inclut uniquement les fichiers.

         #'NODEBUG' est une directive inexistante et on ne supprime pas les directives
         #sinon cela génére trop de différences en cas de comparaison de fichier
        Get-Content -Path $Source -ReadCount 0 -Encoding UTF8|
        #  Edit-String -Setting  $TemplateDefaultSettings|
        #  Out-ArrayOfString
        Edit-Template -ConditionnalsKeyWord 'NODEBUG' -Include -Container $Source|
         Set-Content -Path $TempFileName -Force -Encoding UTF8
      }
      else
      { throw "Invalid configuration name '$BuildConfiguration'" }
     Copy-Item -Path $TempFileName -Destination $ModuleOutDir -Recurse -Verbose:($VerbosePreference -eq 'Continue')
    }#foreach
  } finally {
    if (Test-Path $TempDirectory)
    { Remove-Item $TempDirectory -Recurse -Force -Verbose:($VerbosePreference -eq 'Continue')  }
  }
}


# Executes before the StageFiles task.
Task BeforeStageFiles -Depends RemoveConditionnal{
}

#Verifying file encoding BEFORE generation
Task TestBOM -Precondition { $isTestBom } -requiredVariables SrcRootDir {
#La régle 'UseBOMForUnicodeEncodedFile' de PSScripAnalyzer s'assure que les fichiers qui
# ne sont pas encodés ASCII ont un BOM (cette régle est trop 'permissive' ici).
#On ne veut livrer que des fichiers UTF-8.

  Write-verbose "Validation de l'encodage des fichiers du répertoire : $SrcRootDir"

  Import-Module DTW.PS.FileSystem

  $InvalidFiles=Test-BOMFile -path $SrcRootDir
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
}

Task TestLocalizedData  {
    Import-module MeasureLocalizedData

    if ($null -eq $LocalizedDataFunctions)
    {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule }
    else
    {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule -Secondary $LocalizedDataFunctions}
    if ($Result.Count -ne 0)
    {
      $Result
      throw 'One or more MeasureLocalizedData errors were found. Build cannot continue!'
    }
}

# Executes after the StageFiles task.
Task AfterStageFiles -Depends TestBOM, TestLocalizedData {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BeforeStageFiles phase of the Build task.
Task BeforeBuild {
}

# #Verifying file encoding AFTER generation
Task TestBOMAfterAll -Precondition { $isTestBom } -requiredVariables OutDir {
   Import-Module DTW.PS.FileSystem

  Write-Verbose  "Validation finale de l'encodage des fichiers du répertoire : $OutDir"
  $InvalidFiles=Test-BOMFile -path $OutDir
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
}

# Executes after the Build task.
Task AfterBuild  -Depends TestBOMAfterAll {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the BuildHelp task.
Task BeforeBuildHelp {
}

# Executes after the BuildHelp task.
Task AfterBuildHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildUpdatableHelp.
###############################################################################

# Executes before the BuildUpdatableHelp task.
Task BeforeBuildUpdatableHelp {
}

# Executes after the BuildUpdatableHelp task.
Task AfterBuildUpdatableHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after GenerateFileCatalog.
###############################################################################

# Executes before the GenerateFileCatalog task.
Task BeforeGenerateFileCatalog {
}

# Executes after the GenerateFileCatalog task.
Task AfterGenerateFileCatalog {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the Install task.
Task BeforeInstall {
}

# Executes after the Install task.
Task AfterInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before the Publish task.
Task BeforePublish -depends GetApiKey -requiredVariables Projectname, OutDir, ModuleName, RepositoryName, Dev_PublishRepository {
    if ( (-not [string]::IsNullOrWhiteSpace($Dev_PublishRepository)) -and ($RepositoryName -eq $Dev_PublishRepository ))
    {
        #Increment  the module version for dev repository only
        Import-Module BuildHelpers
        $SourceLocation=(Get-PSRepository -Name $RepositoryName).SourceLocation
        if (-not $SourceLocation.EndsWith('/'))
        { $SourceLocation="$SourceLocation/"}
        # Get the latest version for a project
        $Version = Get-NextNugetPackageVersion -Name $ProjectName -PackageSourceUrl $SourceLocation

        "Update the module metadata with the new version : $version"
        Update-Metadata -Path "$OutDir\$ModuleName\$ModuleName.psd1"  -PropertyName ModuleVersion -Value $Version
    }
}

# Executes after the Publish task.
Task AfterPublish {
}

#todo
#  publier les test : Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Passed
#  publier le résultat du build sur devOttoMatt ( Push-AppveyorArtifact $_.FullName }
#  https://github.com/GitTools/GitVersion ?