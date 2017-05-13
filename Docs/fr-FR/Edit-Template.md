---
external help file: Template-help.xml
online version:
schema: 2.0.0
---

# Edit-Template

## SYNOPSIS
Supprime dans un fichier source toutes les lignes placées entre deux directives de 'parsing conditionnal', tels que #<DEFINE %DEBUG%> et #<UNDEF %DEBUG%>.

Il est également possible d'inclure des fichiers,de décommenter des lignes de commentaires ou de supprimer des lignes.

## SYNTAX

### NoKeyword (Default)
```
Edit-Template -InputObject <Object> [-Container <String>] [-Encoding <FileSystemCmdletProviderEncoding>]
 [-Remove] [-Include] [-UnComment] [<CommonParameters>]
```

### Keyword
```
Edit-Template -InputObject <Object> [[-ConditionnalsKeyWord] <String[]>] [-Container <String>]
 [-Encoding <FileSystemCmdletProviderEncoding>] [-Remove] [-Include] [-UnComment] [<CommonParameters>]
```

### Clean
```
Edit-Template -InputObject <Object> [-Container <String>] [-Encoding <FileSystemCmdletProviderEncoding>]
 [-Clean] [-Remove] [-Include] [-UnComment] [<CommonParameters>]
```

## DESCRIPTION
La fonction Edit-Template filtre dans une collection de chaîne de caractères toutes les lignes placées entre deux directives de  'parsing conditionnal'.

La fonction lit la collection  ligne par ligne, une collection de lignes contenue dans une seule chaîne pourra provoquer des erreurs de traitement.

PowerShell ne propose pas de mécanisme similaire à ceux de la compilation conditionnelle, qui permet à l'aide de directives d'ignorer certaines parties du texte source.


Cette fonction utilise les constructions suivantes :

-pour déclarer une directive : #<DEFINE %Nom_De_Directive_A%>


-pour annuler une directive :  #<UNDEF %Nom_De_Directive_A%>


Chacune de ces directives doit être placée en début de ligne et peut être précédées d'un ou plusieurs caractères espaces ou tabulation.

Le nom de directive ne doit pas contenir d'espace ou de tabulation.

Ces directives peuvent êtres imbriquées:

\#<DEFINE %Nom_De_Directive_A%>

 \#<DEFINE %Nom_De_Directive_B%>

 \#<UNDEF %Nom_De_Directive_B%>

\#<UNDEF %Nom_De_Directive_A%>

Par principe la construction suivante n'est pas autorisée :

\#<DEFINE %Nom_De_Directive_A%>

  \#<DEFINE %Nom_De_Directive_B%>

  \#<UNDEF %Nom_De_Directive_A%>  #fin de directive erronée

\#<UNDEF %Nom_De_Directive_B%>


Ni celle-ci :

 \#<DEFINE %Nom_De_Directive_A%>

   \#<UNDEF %Nom_De_Directive_B%>

   \#<DEFINE %Nom_De_Directive_B%>

 \#<UNDEF %Nom_De_Directive_A%>

La présence de directives DEFINE ou UNDEF orpheline génére une erreur.

La directive REMOVE doit être placée en fin de ligne  :

  Write-Debug 'Test'#<%REMOVE%>

La directive UNCOMMENT doit être placée en début de ligne  :

  \#<%UNCOMMENT%>[FunctionalType('PathFile')]

   ...

  \#<%UNCOMMENT%>Write-Debug 'Test'

Ces lignes seront tranformées en :

   [FunctionalType('PathFile')]

   ...

   Write-Debug 'Test'

La directive INCLUDE insére le contenu d'un fichier externe.

   Write-Host 'Code avant'

  #<INCLUDE %'C:\Temp\Test.ps1'%>"

   Write-Host 'Code aprés'

Ces lignes seront tranformées en :

   Write-Host 'Code avant'

   Write-Host "Insertion du contenus du fichier 'C:\Temp\Test.ps1'"

   Write-Host 'Code aprés'

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$Code=@'
Function Test-Directive {
    Write-Host "Test"
   #<DEFINE %DEBUG%>
    Write-Debug "$DebugPreference"
   #<UNDEF %DEBUG%>
  }
'@

Edit-Template -Input ($code -split "\`n") -ConditionnalsKeyWord  "DEBUG"
```

Ces instructions créent une variable contenant du code, dans lequel on déclare une directive DEBUG.
Cette variable étant du type chaîne de caractères, on doit la transformer en un tableau de chaîne, à l'aide de l'opérateur -Split, avant de l'affecter au paramétre -Input.

Le paramétre ConditionnalsKeyWord déclare une seule directive nommée 'DEBUG', ainsi configuré le code transformé correspondra à ceci :

   Function Test-Directive {
    Write-Host "Test"
   }

Les lignes comprisent entre la directive #<DEFINE %DEBUG%> et la directive#<UNDEF %DEBUG%> sont filtrées.

### -------------------------- EXAMPLE 2 --------------------------
```
$Code=@'
Function Test-Directive {
    Write-Host "Test"
   #<DEFINE %DEBUG%>
    Write-Debug "$DebugPreference"
   #<UNDEF %DEBUG%>
  }
'@

($code -split "\`n")|Edit-Template -ConditionnalsKeyWord  "DEBUG"
```

Cet exemple provoquera les erreurs suivantes :
  Edit-Template : Parsing annulé.
  Les directives suivantes n'ont pas de mot clé de fin : DEBUG:1

  throw : Parsing annulé.
  La directive#<UNDEF %DEBUG%> n'est pas associée à une directive DEFINE ('DEBUG:1')

Le message d'erreur contient le nom de la directive suivi du numéro de ligne du code source où elle est déclarée.

La cause de l'erreur est due au type d'objet transmit dans le pipeline, cette syntaxe transmet les objets contenus dans le tableau les uns à la suite des autres, l'analyse ne peut donc se faire sur l'intégralité du code source, car la fonction opére sur une seule ligne et autant de fois qu'elle reçoit de ligne.

Pour éviter ce problème on doit forcer l'émission du tableau en spécifiant une virgule AVANT la variable de type tableau :

,($code -split "\`n")|Edit-Template -ConditionnalsKeyWord  "DEBUG"

### -------------------------- EXAMPLE 3 --------------------------
```
$Code=@'
Function Test-Directive {
    Write-Host "Test"
   #<DEFINE %DEBUG%>
    Write-Debug "$DebugPreference"
   #<UNDEF %DEBUG%>
  }
'@ > C:\Temp\Test1.PS1

Get-Content C:\Temp\Test1.PS1 -ReadCount 0|
 Edit-Template -Clean
```

La première instruction crée un fichier contenant du code, dans lequel on déclare une directive DEBUG.

La seconde instruction lit le fichier en une seule étape, car on indique à l'aide du paramétre -ReadCount de récupèrer un tableau de chaînes.

Le paramétre Clean filtrera toutes les lignes contenant une directive, ainsi configuré le code transformé correspondra à ceci :

  Function Test-Directive {
    Write-Host "Test"
    Write-Debug "$ErrorActionPreference"
  }

Les lignes comprisent entre la directive#<DEFINE %DEBUG%> et la directive#<UNDEF %DEBUG%> ne sont pas filtrées, par contre les lignes contenant une déclaration de directive le sont.

### -------------------------- EXAMPLE 4 --------------------------
```
$Code=@'
Function Test-Directive {
    param (
       [FunctionalType('FilePath')] #<%REMOVE%>
     [String]$Serveur
    )
   #<DEFINE %DEBUG%>
    Write-Debug "$DebugPreference"
   #<UNDEF %DEBUG%>

    Write-Host "Test"

   #<DEFINE %TEST%>
    Test-Connection $Serveur
   #<UNDEF %TEST%>
  }
'@ > C:\Temp\Test2.PS1

Get-Content C:\Temp\Test2.PS1 -ReadCount 0|
 Edit-Template -ConditionnalsKeyWord  "DEBUG"|
 Edit-Template -Clean
```

Ces instructions déclarent une variable contenant du code, dans lequel on déclare deux directives, DEBUG et TEST.

On applique le filtre de la directive 'DEBUG' puis on filtre les déclarations des directives restantes, ici 'TEST'.

Le code transformé correspondra à ceci :

  Function Test-Directive {
    param (
     [String]$Serveur
    )
    Write-Host "Test"
    Test-Connection $Serveur
  }

### -------------------------- EXAMPLE 5 --------------------------
```
$code=@'
#<DEFINE %V3%>
#Requires -Version 3.0
#<UNDEF %V3%>

#<DEFINE %V2%>
#Requires -Version 2.0
#<UNDEF %V2%>

Filter Test {
#<DEFINE %V2%>
 dir | Foreach-Object { $_.FullName } #v2
#<UNDEF %V2%>

#<DEFINE %V3%>
 (dir).FullName   #v3
#<UNDEF %V3%>

#<DEFINE %DEBUG%>
 Write-Debug "$DebugPreference"
#<UNDEF %DEBUG%>
}
'@ -split "\`n"

 #Le code est compatible avec la v2 uniquement
,$Code|
  Edit-Template -ConditionnalsKeyWord  "V3","DEBUG"|
  Edit-Template -Clean

 #Le code est compatible avec la v3 uniquement
,$Code|
  Edit-Template -ConditionnalsKeyWord  "V2","DEBUG"|
  Edit-Template -Clean
```

Ces instructions génèrent, selon le paramétrage, un code dédié à une version spécifique de Powershell.

En précisant la directive 'V3', on supprime le code spécifique à la version 3.
On génère donc du code compatible avec la version 2 de Powershell.
Le code transformé correspondra à ceci :

 #Requires -Version 2.0
  Filter Test {
   dir | Foreach-Object { $_.FullName } #v2
  }

En précisant la directive V2 on supprime le code spécifique à la version 2 on génère donc du code compatible avec la version 3 de Powershell.
Le code transformé correspondra à ceci :

 #Requires -Version 3.0
  Filter Test {
   (dir).FullName   #v3
  }

### -------------------------- EXAMPLE 6 --------------------------
```
$PathSource="C:\Temp"
$code=@'
 Filter Test {
#<DEFINE %SEVEN%>
  #http://psclientmanager.codeplex.com/  #<%REMOVE%>
 Import-Module PSClientManager   #Seven
 Add-ClientFeature -Name TelnetServer
#<UNDEF %SEVEN%>

#<DEFINE %2008R2%>
 Import-Module ServerManager  #2008R2
 Add-WindowsFeature Telnet-Server
#<UNDEF %2008R2%>
}
'@ > "$PathSource\Add-FeatureTelnetServer.PS1"


$VerbosePreference='Continue'
$Livraison='C:\Temp\Livraison'
Del "$Livraison\*.ps1" -ea 'SilentlyContinue'

  #Le code est compatible avec Windows 2008R2 uniquement
$Directives=@('SEVEN')

Dir "$PathSource\Add-FeatureTelnetServer.PS1"|
 Foreach {
  Write-Verbose "Parse :$($_.FullName)"
  $CurrentFileName=$_.Name
  $_
 }|
 Get-Content -ReadCount 0|
 Edit-Template -ConditionnalsKeyWord $Directives -REMOVE|
 Edit-Template -Clean|
 Set-Content -Path (Join-Path $Livraison $CurrentFileName) -Force -Verbose
```

Ces instructions génèrent un code dédié à une version spécifique de Windows.
On lit le fichier script prenant en compte plusieurs versions de Windows, on le transforme, puis on le réécrit dans un répertoire de livraison.

Dans cette exemple on génère un script contenant du code dédié à Windows 2008R2 :

 Filter Test {
   Import-Module ServerManager  #2008R2
   Add-WindowsFeature Telnet-Server
 }

En précisant la directive '2008R2' on génèrerait du code dédié à Windows SEVEN.

### -------------------------- EXAMPLE 7 --------------------------
```
@'
#Fichier d'inclusion C:\Temp\Test1.ps1
1-un
'@ > C:\Temp\Test1.ps1
#
#
@'
#Fichier d'inclusion C:\Temp\Test2.ps1
#<INCLUDE %'C:\Temp\Test3.ps1'%>
2-un
#<DEFINE %DEBUG%>
2-deux
#<UNDEF %DEBUG%>
'@ > C:\Temp\Test2.ps1
#
#
@'
#Fichier d'inclusion C:\Temp\Test3.ps1
3-un
#<INCLUDE %'C:\Temp\Test1.ps1'%>
$Logger.Debug('Test') #<%REMOVE%>
#<DEFINE %PSV2%>
3-deux
#<UNDEF %PSV2%>
'@ > C:\Temp\Test3.ps1
#
#
Dir C:\Temp\Test2.ps1|
 Get-Content -ReadCount 0 -Encoding Unicode|
 Edit-Template -ConditionnalsKeyWord 'DEBUG' -Include -Container 'C:\Temp\Test2.ps1'
```

Ces instructions créent trois fichiers avec l'encodage par défaut, puis l'appel à Edit-Template génère le code suivant :

\#Fichier d'inclusion C:\Temp\Test2.ps1
\#Fichier d'inclusion C:\Temp\Test3.ps1
3-un
\#Fichier d'inclusion C:\Temp\Test1.ps1
1-un
\#<DEFINE %PSV2%>
3-deux
\#<UNDEF %PSV2%>
2-un


Chaque appel interne à Edit-Template utilisera les directives déclarées lors du premier appel.

La présence du paramètre -Container permet en cas d'erreur de retrouver le nom du fichier en cours de traitement.

## PARAMETERS

### -Clean
Déclenche une opération de nettoyage des directives, ce traitement devrait être la dernière tâche de transformation d'un code source ou d'un ficheir texte.

Ce paramètre filtre toutes les lignes contenant une directive.

Cette opération supprime seulement les lignes contenant une directive et pas le texte entre deux directives.

Pour la directive UNCOMMENT, la ligne reste commentée.


Il est possible de combiner ce paramètre avec un ou plusieurs des paramètres suivant :  -Remove -UnComment -Include

```yaml
Type: SwitchParameter
Parameter Sets: Clean
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConditionnalsKeyWord
Tableau de chaîne de caractères contenant les directives à rechercher et à traiter.

A la différence des directives conditionnelles des langages de programmation cette fonction inverse le comportement, les directives précisent le code que l'on veut supprimer.


Il n'est pas possible de combiner ce paramètre avec le paramètre -Clean.

Les noms de directive 'REMOVE','INCLUDE' et 'UNCOMMENT' sont réservées.


Chaque nom de directive ne doit pas contenir d'espace, ni de tabulation.

Le nom de directive 'NOM' et distinct de '1NOM',de 'NOM2' ou de 'PRENOM'.

```yaml
Type: String[]
Parameter Sets: Keyword
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Container
Contient le nom de la source de données d'où ont été extraite les lignes du code source à transformer.

En cas de traitement de la directive INCLUDE, ce paramètre contiendra le nom du fichier déclaré dans cette directive.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Encoding
Indique le type d'encodage à utiliser lors de l'inclusion de fichiers.

La valeur par défault est ASCII.

Pour plus de détails sur les type d'encodage disponible, consultez l'aide en ligne du cmdlet Get-Content.

```yaml
Type: FileSystemCmdletProviderEncoding
Parameter Sets: (All)
Aliases:
Accepted values: Unknown, String, Unicode, Byte, BigEndianUnicode, UTF8, UTF7, UTF32, Ascii, Default, Oem, BigEndianUTF32

Required: False
Position: Named
Default value: ASCII
Accept pipeline input: False
Accept wildcard characters: False
```

### -Include
Inclus le fichier précisé dans les directives : #<INCLUDE %'FullPathName'%>

Cette directive doit être placée en début de ligne :

  #<INCLUDE %'C:\Temp\Test.ps1'%>"


Ici le fichier 'C:\Temp\Test.ps1' sera inclus dans le code source en cours de traitement.

Vous devez vous assurer de l'existence du fichier.

Ce nom de fichier doit être précédé de %' et suivi de '%>


L'imbrication de fichiers contenant des directives INCLUDE est possible, car ce traitement appel récursivement la fonction Edit-Template en propageant la valeur des paramètres.

Tous les fichiers inclus seront donc traités avec les mêmes directives.


Cette directive attend un seul nom de fichier.

Les espaces en début et fin de chaîne sont supprimés.

Ne placez pas de texte à la suite de cette directive.


Il est possible de combiner ce paramètre avec le paramètre -Clean.


Par défaut la lecture des fichiers à inclure utilise l'encodage ASCII.


L'usage d'un PSDrive dédié évitera de coder en dur des noms de chemin.

Par exemple cette création de drive  :

 $null=New-PsDrive -Scope Global -Name 'MyProject' -PSProvider FileSystem -Root 'C:\project\MyProject\Trunk'

autorisera la déclaration suivante :

 #<INCLUDE %'MyProject:\Tools\New-PSPathInfo.ps1'%>

au lieu de

 #<INCLUDE %'C:\project\MyProject\Trunk\Tools\New-PSPathInfo.ps1'%>

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Spécifie un objet hébergeant le texte du code source à transformer.

Cet objet doit pouvoir être énumérer en tant que collection de chaîne de caractères afin de traiter chaque ligne du code source.


Si le texte est contenu dans une seule chaîne de caractères l'analyse des directives échouera, dans ce cas le code source ne sera pas transformé.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Remove
Supprime les lignes de code source contenant la directive <%REMOVE%>.

Il est possible de combiner ce paramètre avec le paramètre -Clean.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UnComment
Décommente les lignes de code source commentées portant la directive <%UNCOMMENT%>.


Il est possible de combiner ce paramètre avec le paramètre -Clean.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### [string[]]

## NOTES

## RELATED LINKS

