#Release.ps1
#Construit la version Release via Psake

Task default -Depends CreateZip 

Task CreateZip -Depends Delivery,PSScriptAnalyzer,TestBomFinal {

  $zipFile = "$env:\Temp\Template.zip"
  Add-Type -assemblyname System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::CreateFromDirectory($TemplateDelivery, $zipFile)
  if (Test-Path env:APPVEYOR)
  { Push-AppveyorArtifact $zipFile }     
}

Task Delivery -Depends Clean,RemoveConditionnal {
 #Recopie les fichiers dans le répertoire de livraison  
$VerbosePreference='Continue'
 
#log4Net config
# on copie la config de dev nécessaire au build. 
   Copy "$TemplateVcs\Log4Net.Config.xml" "$TemplateDelivery"

#Doc xml localisée
   #US
   Copy "$TemplateVcs\Template.Resources.psd1" "$TemplateDelivery\Template.Resources.psd1" 
   Copy "$TemplateVcs\en-US\about_Template.help.txt" "$TemplateDelivery\en-US\about_Template.help.txt"

  #Fr 
   Copy "$TemplateVcs\fr-FR\$Template.Resources.psd1" "$TemplateDelivery\fr-FR\Template.Resources.psd1"
   Copy "$TemplateVcs\fr-FR\about_Template.help.txt" "$TemplateDelivery\fr-FR\about_Template.help.txt"
 

#Demos
   Copy "$TemplateVcs\Demos" "$TemplateDelivery\Demos" -Recurse

#PS1xml   

#Licence                         

#Module
      #Template.psm1 est créé par la tâche RemoveConditionnal
   Copy "$TemplateVcs\Template.psd1" "$TemplateDelivery"
   
#Setup
   Copy "$TemplateSetup\TemplateSetup.ps1" "$TemplateDelivery"

#Other 
   Copy "$TemplateVcs\Revisions.txt" "$TemplateDelivery"
} #Delivery

Task RemoveConditionnal -Depend TestLocalizedData {
#Traite les pseudo directives de parsing conditionnelle
  
   $VerbosePreference='Continue'
   ."$TemplateTools\Remove-Conditionnal.ps1"
   Write-debug "Configuration=$Configuration"
   Dir "$TemplateVcs\Template.psm1"|
    Foreach {
      $Source=$_
      Write-Verbose "Parse :$($_.FullName)"
      $CurrentFileName="$TemplateDelivery\$($_.Name)"
      Write-Warning "CurrentFileName=$CurrentFileName"
      if ($Configuration -eq "Release")
      { 
         Write-Warning "`tTraite la configuration Release"
         #Supprime les lignes de code de Debug et de test
         #On traite une directive et supprime les lignes demandées. 
         #On inclut les fichiers.       
        Get-Content -Path $_ -ReadCount 0 -Encoding UTF8|
         Remove-Conditionnal -ConditionnalsKeyWord 'DEBUG' -Include -Remove -Container $Source|
         Remove-Conditionnal -Clean| 
         Set-Content -Path $CurrentFileName -Force -Encoding UTF8        
      }
      else
      { 
         #On ne traite aucune directive et on ne supprime rien. 
         #On inclut uniquement les fichiers.
        Write-Warning "`tTraite la configuration DEBUG" 
         #Directive inexistante et on ne supprime pas les directives
         #sinon cela génére trop de différences en cas de comparaison de fichier
        Get-Content -Path $_ -ReadCount 0 -Encoding UTF8|
         Remove-Conditionnal -ConditionnalsKeyWord 'NODEBUG' -Include -Container $Source|
         Set-Content -Path $CurrentFileName -Force -Encoding UTF8       
         
      }
    }#foreach
} #RemoveConditionnal

Task TestLocalizedData -ContinueOnError {
 ."$TemplateTools\Test-LocalizedData.ps1"

 $SearchDir="$TemplateVcs"
 Foreach ($Culture in $Cultures)
 {
   Dir "$SearchDir\Template.psm1"|          
    Foreach-Object {
       #Construit un objet contenant des membres identiques au nombre de 
       #paramètres de la fonction Test-LocalizedData 
      New-Object PsCustomObject -Property @{
                                     Culture=$Culture;
                                     Path="$SearchDir";
                                       #convention de nommage de fichier d'aide
                                     LocalizedFilename="$($_.BaseName)LocalizedData.psd1";
                                     FileName=$_.Name;
                                       #convention de nommage de variable
                                     PrefixPattern="$($_.BaseName)Msgs\."
                                  }
    }|   
    Test-LocalizedData -verbose
 }
} #TestLocalizedData

Task Clean -Depends Init {
# Supprime, puis recrée le dossier de livraison   

   $VerbosePreference='Continue'
   Remove-Item $TemplateDelivery -Recurse -Force -ea SilentlyContinue
   "$TemplateDelivery\en-US", 
   "$TemplateDelivery\fr-FR", 
   "$TemplateDelivery\FormatData",
   "$TemplateDelivery\TypeData",
   "$TemplateDelivery\Logs"|
   Foreach {
    md $_ -Verbose -ea SilentlyContinue > $null
   } 
} #Clean

Task Init -Depends TestBOM {
#validation à minima des prérequis

 Write-host "Mode $Configuration"
  if (-not (Test-Path Env:ProfileTemplate))
  {Throw 'La variable $ProfileTemplate n''est pas déclarée.'}
    
} #Init

Task TestBOM {
#Validation de l'encodage des fichiers AVANT la génération  
  Write-Host "Validation de l'encodage des fichiers du répertoire : $TemplateVcs"
  
  Import-Module DTW.PS.FileSystem -Global
  
  $InvalidFiles=@(&"$TemplateTools\Test-BOMFile.ps1" $TemplateVcs)
  if ($InvalidFiles.Count -ne 0)
  { 
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
} #TestBOM

#On duplique la tâche, car PSake ne peut exécuter deux fois une même tâche
Task TestBOMFinal {

#Validation de l'encodage des fichiers APRES la génération  
  
  Write-Host "Validation de l'encodage des fichiers du répertoire : $TemplateDelivery"
  $InvalidFiles=@(&"$TemplateTools\Test-BOMFile.ps1" $TemplateDelivery)
  if ($InvalidFiles.Count -ne 0)
  { 
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
} #TestBOMFinal

Task PSScriptAnalyzer {
  Write-host "Todo ValideParameterSet etc"
}#PSScriptAnalyzer

