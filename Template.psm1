#Template.psm1

Import-LocalizedData -BindingVariable Messages -Filename Template.Resources.psd1 -EA Stop

#<DEFINE %DEBUG%>
$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

  #This code create the following variables : $script:DebugLogger, $script:InfoLogger, $script:DefaultLogFile
$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4NetModule}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\TemplateLog4Posh.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
}
&$InitializeLogging @Params
#<UNDEF %DEBUG%>


filter Out-ArrayOfString {
 if ([string]::IsNullOrEmpty($_))
 {$_}
 else
 { $_ -split "(`n|`r`n)" }
}

Function Edit-Template {
<#
.SYNOPSIS
    Supprime dans un fichier source toutes les lignes placées entre deux
    directives de 'parsing conditionnal', tels que #<DEFINE %DEBUG%> et
    #<UNDEF %DEBUG%>. Il est également possible d'inclure des fichiers,
    de décommenter des lignes de commentaires ou de supprimer des lignes.

.DESCRIPTION
    La fonction Edit-Template filtre dans une collection de chaîne
    de caractères toutes les lignes placées entre deux directives de
     'parsing conditionnal'.
    La fonction lit la collection  ligne par ligne, une collection de lignes
    contenue dans une seule chaîne pourra provoquer des erreurs de traitement.
.
    PowerShell ne propose pas de mécanisme similaire à ceux de la compilation
    conditionnelle, qui permet à l'aide de directives d'ignorer certaines
     parties du texte source.
.
    Cette fonction utilise les constructions suivantes :
       . pour déclarer une directive : #<DEFINE %Nom_De_Directive_A%>
       . pour annuler une directive :   #<UNDEF %Nom_De_Directive_A%>.
.
    Chacune de ces directives doit être placée en début de ligne et peut être
    précédées d'un ou plusieurs caractères espaces ou tabulation.
    Le nom de directive ne doit pas contenir d'espace ou de tabulation.
.
    Ces directives peuvent êtres imbriquées:
     #<DEFINE %Nom_De_Directive_A%>

      #<DEFINE %Nom_De_Directive_B%>
      #<UNDEF %Nom_De_Directive_B%>

     #<UNDEF %Nom_De_Directive_A%>
.
    Par principe la construction suivante n'est pas autorisée :
     #<DEFINE %Nom_De_Directive_A%>

      #<DEFINE %Nom_De_Directive_B%>
      #<UNDEF %Nom_De_Directive_A%>  #fin de directive erronée

     #<UNDEF %Nom_De_Directive_B%>
.
    Ni celle-ci :
     #<DEFINE %Nom_De_Directive_A%>

      #<UNDEF %Nom_De_Directive_B%>
      #<DEFINE %Nom_De_Directive_B%>

     #<UNDEF %Nom_De_Directive_A%>
.
    La présence de directives DEFINE ou UNDEF orpheline génére une erreur.
.
    La directive REMOVE doit être placée en fin de ligne  :
       Write-Debug 'Test' #<%REMOVE%>
.
    La directive UNCOMMENT doit être placée en début de ligne  :
       #<%UNCOMMENT%>[FunctionalType('PathFile')]
       ...
       #<%UNCOMMENT%>Write-Debug 'Test'
.
    Ces lignes seront tranformées en :
       [FunctionalType('PathFile')]
       ...
       Write-Debug 'Test'
.
      Le directive INCLUDE insére le contenu d'un fichier externe.
       Write-Host 'Code avant'
       #<INCLUDE %'C:\Temp\Test.ps1'%>"
       Write-Host 'Code aprés'
.
     Ces lignes seront tranformées en :
       Write-Host 'Code avant'
       Write-Host "Insertion du contenus du fichier 'C:\Temp\Test.ps1'"
       Write-Host 'Code aprés'

.PARAMETER InputObject
    Spécifie un objet hébergeant le texte du code source à transformer.
    Cet objet doit pouvoir être énumérer en tant que collection de chaîne
    de caractères afin de traiter chaque ligne du code source.
.
    Si le texte est contenu dans une seule chaîne de caractères l'analyse des
    directives échouera, dans ce cas le code source ne sera pas transformé.

.PARAMETER ConditionnalsKeyWord
    Tableau de chaîne de caractères contenant les directives à rechercher et
    à traiter.
    A la différence des directives conditionnelles des langages de programmation
    cette fonction inverse le comportement, on précise les noms de directives
    que l'on veut supprimer.

.
    Il n'est pas possible de combiner ce paramètre avec le paramètre -Clean.
    les noms de directive 'REMOVE','INCLUDE' et 'UNCOMMENT' sont réservées.
.
    Chaque nom de directive ne doit pas contenir d'espace, ni de tabulation.
    Le nom de directive 'NOM' et distinct de '1NOM',de 'NOM2' ou de 'PRENOM'.

.PARAMETER Container
    Contient le nom de la source de données d'où ont été extraite les lignes du
    code source à transformer.
    En cas de traitement de la directive INCLUDE, ce paramètre contiendra
    le nom du fichier déclaré dans cette directive.

.PARAMETER Clean
    Déclenche une opération de nettoyage des directives, ce traitement devrait
    être la dernière tâche de transformation d'un code source ou d'un ficheir texte.
    Ce paramètre filtre toutes les lignes contenant une directive.
    Cette opération supprime seulement les lignes contenant une directive et pas le texte
    entre deux directives. Pour la directive UNCOMMENT, la ligne reste
    commentée.
.
    Il est possible de combiner ce paramètre avec un ou plusieurs des
    paramètres suivant :  -Remove -UnComment -Include

.PARAMETER Encoding
    Indique le type d'encodage à utiliser lors de l'inclusion de fichiers.
    La valeur par défault est ASCII.
    Pour plus de détails sur les type d'encodage disponible, consultez l'aide en
    ligne du cmdlet Get-Content.

.PARAMETER Include
    Inclus le fichier précisé dans les directives : #<INCLUDE %'FullPathName'%>
    Cette directive doit être placée en début de ligne :
      #<INCLUDE %'C:\Temp\Test.ps1'%>"
.
    Ici le fichier 'C:\Temp\Test.ps1' sera inclus dans le code source en
    cours de traitement. Vous devez vous assurer de l'existence du fichier.
    Ce nom de fichier doit être précédé de %' et suivi de '%>
.
    L'imbrication de fichiers contenant des directives INCLUDE est possible,
    car ce traitement appel récursivement la fonction Edit-Template en
    propageant la valeur des paramètres. Tous les fichiers inclus seront donc
    traités avec les mêmes directives.
.
    Cette directive attend un seul nom de fichier.
    Les espaces en début et fin de chaîne sont supprimés.
    Ne placez pas de texte à la suite de cette directive.
.
    Il est possible de combiner ce paramètre avec le paramètre -Clean.
.
    Par défaut la lecture des fichiers à inclure utilise l'encodage ASCII.
.
    L'usage d'un PSDrive dédié évitera de coder en dur des noms de chemin.
    Par exemple cette création de drive  :
     $null=New-PsDrive -Scope Global -Name 'MyProject' -PSProvider FileSystem -Root 'C:\project\MyProject\Trunk'
    autorisera la déclaration suivante :
     #<INCLUDE %'MyProject:\Tools\New-PSPathInfo.ps1'%>
    au lieu de
     #<INCLUDE %'C:\project\MyProject\Trunk\Tools\New-PSPathInfo.ps1'%>

.PARAMETER Remove
    Supprime les lignes de code source contenant la directive <%REMOVE%>.
.
    Il est possible de combiner ce paramètre avec le paramètre -Clean.

.PARAMETER UnComment
    Décommente les lignes de code source commentées portant la
    directive <%UNCOMMENT%>.
.
    Il est possible de combiner ce paramètre avec le paramètre -Clean.

.EXAMPLE
    $Code=@'
      Function Test-Directive {
        Write-Host "Test"
       #<DEFINE %DEBUG%>
        Write-Debug "$DebugPreference"
       #<UNDEF %DEBUG%>
      }
    '@

    Edit-Template -Input ($code -split "`n") -ConditionnalsKeyWord  "DEBUG"
.
    Description
    -----------
    Ces instructions créent une variable contenant du code, dans lequel on
    déclare une directive DEBUG. Cette variable étant du type chaîne de
    caractères, on doit la transformer en un tableau de chaîne, à l'aide de
    l'opérateur -Split, avant de l'affecter au paramétre -Input.
.
    Le paramétre ConditionnalsKeyWord déclare une seule directive nommée
    'DEBUG', ainsi configuré le code transformé correspondra à ceci :

       Function Test-Directive {
        Write-Host "Test"
       }

    Les lignes comprisent entre la directive #<DEFINE %DEBUG%> et la directive
    #<UNDEF %DEBUG%> sont filtrées.

.EXAMPLE
    $Code=@'
      Function Test-Directive {
        Write-Host "Test"
       #<DEFINE %DEBUG%>
        Write-Debug "$DebugPreference"
       #<UNDEF %DEBUG%>
      }
    '@

    ($code -split "`n")|Edit-Template -ConditionnalsKeyWord  "DEBUG"
.
    Description
    -----------
    Cet exemple provoquera les erreurs suivantes :
      Edit-Template : Parsing annulé.
      Les directives suivantes n'ont pas de mot clé de fin : DEBUG:1

      throw : Parsing annulé.
      La directive #<UNDEF %DEBUG%> n'est pas associée à une directive DEFINE ('DEBUG:1')

    Le message d'erreur contient le nom de la directive suivi du numéro de
    ligne du code source où elle est déclarée.
.
    La cause de l'erreur est due au type d'objet transmit dans le pipeline,
    cette syntaxe transmet les objets contenus dans le tableau les uns à la
    suite des autres, l'analyse ne peut donc se faire sur l'intégralité du code
    source, car la fonction opére sur une seule ligne et autant de fois qu'elle
    reçoit de ligne.
.
    Pour éviter ce problème on doit forcer l'émission du tableau en spécifiant
    une virgule AVANT la variable de type tableau :

    ,($code -split "`n")|Edit-Template -ConditionnalsKeyWord  "DEBUG"

.EXAMPLE
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
.
    Description
    -----------
    La première instruction crée un fichier contenant du code, dans lequel on
    déclare une directive DEBUG. La seconde instruction lit le fichier en
    une seule étape, car on indique à l'aide du paramétre -ReadCount de
    récupèrer un tableau de chaînes. Le paramétre Clean filtrera toutes les
    lignes contenant une directive, ainsi configuré le code transformé
    correspondra à ceci :

      Function Test-Directive {
        Write-Host "Test"
        Write-Debug "$ErrorActionPreference"
      }

    Les lignes comprisent entre la directive #<DEFINE %DEBUG%> et la directive
    #<UNDEF %DEBUG%> ne sont pas filtrées, par contre les lignes contenant
    une déclaration de directive le sont.

.EXAMPLE
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
.
    Description
    -----------
    Ces instructions déclarent une variable contenant du code, dans lequel on
    déclare deux directives, DEBUG et TEST.
    On applique le filtre de la directive 'DEBUG' puis on filtre les
    déclarations des directives restantes, ici 'TEST'.
.
    Le code transformé correspondra à ceci :

      Function Test-Directive {
        param (
         [String]$Serveur
        )
        Write-Host "Test"
        Test-Connection $Serveur
      }

.EXAMPLE
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
    '@ -split "`n"

     #Le code est compatible avec la v2 uniquement
    ,$Code|
      Edit-Template -ConditionnalsKeyWord  "V3","DEBUG"|
      Edit-Template -Clean

     #Le code est compatible avec la v3 uniquement
    ,$Code|
      Edit-Template -ConditionnalsKeyWord  "V2","DEBUG"|
      Edit-Template -Clean
.
    Description
    -----------
    Ces instructions génèrent, selon le paramétrage, un code dédié à une
    version spécifique de Powershell.
.
    En précisant la directive 'V3', on supprime le code spécifique à la version
    3. On génère donc du code compatible avec la version 2 de Powershell.
    Le code transformé correspondra à ceci :

      #Requires -Version 2.0
      Filter Test {
       dir | Foreach-Object { $_.FullName } #v2
      }
.
    En précisant la directive V2 on supprime le code spécifique à la version 2
    on génère donc du code compatible avec la version 3 de Powershell.
    Le code transformé correspondra à ceci :

      #Requires -Version 3.0
      Filter Test {
       (dir).FullName   #v3
      }

.EXAMPLE
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
.
    Description
    -----------
    Ces instructions génèrent un code dédié à une version spécifique de Windows.
    On lit le fichier script prenant en compte plusieurs versions de Windows,
    on le transforme, puis on le réécrit dans un répertoire de livraison.
.
    Dans cette exemple on génère un script contenant du code
    dédié à Windows 2008R2 :
     Filter Test {
       Import-Module ServerManager  #2008R2
       Add-WindowsFeature Telnet-Server
     }
.
    En précisant la directive '2008R2' on génèrerait du code dédié à Windows
    SEVEN.

.EXAMPLE
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
.
    Description
    -----------
    Ces instructions créent trois fichiers avec l'encodage par défaut,
    puis l'appel à Edit-Template génère le code suivant :
    #Fichier d'inclusion C:\Temp\Test2.ps1
    #Fichier d'inclusion C:\Temp\Test3.ps1
    3-un
    #Fichier d'inclusion C:\Temp\Test1.ps1
    1-un
    #<DEFINE %PSV2%>
    3-deux
    #<UNDEF %PSV2%>
    2-un
.
    Chaque appel interne à Edit-Template utilisera les directives déclarées
    lors du premier appel.
    La présence du paramètre -Container permet en cas d'erreur de retrouver
    le nom du fichier en cours de traitement.

.INPUTS
    System.Management.Automation.PSObject

.OUTPUTS
    [string[]]

.COMPONENT
    parsing

#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess","",
                                                   Justification="Edit-Template do not use ShouldProcess.")]
[CmdletBinding(DefaultParameterSetName="NoKeyword")]
[OutputType([System.Array])] #PSSA, mais renvoie [String[]]
param (
         #S'attend à traiter une collection de chaîne de caractères
        [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
      $InputObject,

        [ValidateNotNullOrEmpty()]
        [Parameter(position=0,ParameterSetName="Keyword")]
      [String[]]$ConditionnalsKeyWord,

       #Nom de la source hébergeant les données à traiter
        [AllowNull()]
      [String]$Container,

      [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding] $Encoding='ASCII',
       [Parameter(ParameterSetName="Clean")]
      [Switch] $Clean, #L'opération de nettoyage des directives devrait être la dernière tâche de transformation
      [Switch] $Remove, #on peut vouloir nettoyer les directives inutilisées et supprimer une ligne
      [Switch] $Include, #idem et inclure un fichier
      [Switch] $UnComment #idem, mais ne pas décommenter

)
 Begin {
   function New-ParsingDirective {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                       Justification="New-ParsingDirective do not change the system state.")]
    param(
         [Parameter(Mandatory=$true,position=0)]
        $Name,
         [Parameter(Mandatory=$true,position=1)]
        $Line,
         [Parameter(Mandatory=$true,position=2)]
        $isFilterParent
    )
     $O=New-Object PSObject -Property $PSBoundParameters
     $O.PsObject.TypeNames[0] = "ParsingDirective"
     $O|Add-Member ScriptMethod ToString {'{0}:{1}' -F $this.Name,$this.Line} -force -pass
   }#New-ParsingDirective

   $DebugLogger.PSDebug("PSBoundParameters:") #<%REMOVE%>
   $PSBoundParameters.GetEnumerator() | Foreach-Object { $DebugLogger.PSDebug( "`t$($_.key)=$($_.value)") } #<%REMOVE%>

   $RegexDEFINE="^\s*#<\s*DEFINE\s*%(?<DEFINE>.*[^%\s])%>"
   $RegexUNDEF="^\s*#<\s*UNDEF\s*%(?<UNDEF>.*[^%\s])%>"
     #Directives liées à un paramètre
   $ReservedKeyWord=@('Clean','Remove','Include','UnComment')
   $RegexConditionnalsKeyWord=[string]::Empty

   $oldofs,$ofs=$ofs,'|'
   $isConditionnalsKeyWord=$PSBoundParameters.ContainsKey('ConditionnalsKeyWord')
   if( $isConditionnalsKeyWord)
   {
     $DebugLogger.PSDebug( "Traite ConditionnalsKeyWord : $ConditionnalsKeyWord") #<%REMOVE%>
     $ConditionnalsKeyWord=$ConditionnalsKeyWord|Select-Object -Unique
     $RegexConditionnalsKeyWord="$ConditionnalsKeyWord"

     foreach ($Directive in $ConditionnalsKeyWord) {
       if ($Directive.Contains(' '))
       {
         $ex=new-object System.Exception ($Messages.DirectiveContainsSpace -F $Directive)
         $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $Ex,
                                                                              'InvalidDirectiveName',
                                                                              "InvalidArgument",
                                                                              $Directive
         $PSCmdlet.ThrowTerminatingError($ER)
       }
    }

     $ofs=','
     $KeyWordsNotAllowed=@(Compare-object $ConditionnalsKeyWord $ReservedKeyWord -IncludeEqual -PassThru|
      Where-Object {$_.SideIndicator -eq "=="})
     if ($KeyWordsNotAllowed.Count -gt 0)
     {
        $ofs=','
        $ex=new-object System.Exception ($Messages.DirectiveNameReserved -F $KeyWordsNotAllowed)
        $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $Ex,
                                                                              'UseReservedDirectiveName',
                                                                              "InvalidArgument",
                                                                              $KeyWordsNotAllowed
        $PSCmdlet.ThrowTerminatingError($ER)
     }
   }
   $Directives=New-Object System.Collections.Stack
   $ofs=$oldofs
 }#begin

 Process {
   $LineNumber=0;
   $isDirectiveBloc=$False
   $DebugLogger.PSDebug( "InputObject.Count: $($InputObject.Count)") #<%REMOVE%>
   $Result=$InputObject|
     Foreach-Object {
       $LineNumber++
       [string]$Line=$_
       $DebugLogger.PSDebug( "`tLit  $Line `t  isDirectiveBloc=$isDirectiveBloc") #<%REMOVE%>
       switch -regex ($Line)
       {
          #Recherche le mot clé de début d'une directive, puis l'empile
         $RegexDEFINE {
                          $CurrentDirective=$Matches.DEFINE
                          $DebugLogger.PSDebug( "DEFINE: Debut de la directive '$CurrentDirective'") #<%REMOVE%>
                          if (-not $Clean.isPresent)
                          {
                            if ($RegexConditionnalsKeyWord -ne [string]::Empty)
                            { $isFilter=$CurrentDirective -match $RegexConditionnalsKeyWord}
                            else
                            { $isFilter=$false }
                            $DebugLogger.PSDebug( "Doit-on filtrer la directive trouvée : $isFilter") #<%REMOVE%>

                            if ($Directives.Count -gt 0 )
                            {
                              $DebugLogger.PSDebug( "Filtre du parent '$($Directives.Peek().Name)' en cours : $($Directives.Peek().isFilterParent)") #<%REMOVE%>
                               #La directive parente est-elle activée ?
                              if ($isFilter -eq $false )
                              {
                                  #La directive courante est imbriquée, le parent détermine le filtrage courant
                                 $isFilter=$Directives.Peek().isFilterParent
                              }
                            }
                            $DebugLogger.PSDebug( "Filtre en cours : $isFilter") #<%REMOVE%>
                              #Mémorise la directive DEFINE,
                              #le numéro de ligne du fichier courant et
                              #l'état du filtrage en cours.
                            $O=New-ParsingDirective $CurrentDirective $LineNumber $isFilter
                            $Directives.Push($O)

                            if ($isFilter)
                            { $isDirectiveBloc=$True }
                            else
                            {
                                 $DebugLogger.PSDebug("`tEcrit la directive : $Line") #<%REMOVE%>
                                 $Line
                            }
                            $DebugLogger.PSDebug( "Demande du filtrage des lignes =$($isDirectiveBloc -eq $true)") #<%REMOVE%>
                          }
                          continue
                       }#$RegexDEFINE

           #Recherche le mot clé de fin de la directive courante, puis dépile
          $RegexUNDEF  {
                          $FoundDirective=$Matches.UNDEF
                          $DebugLogger.PSDebug( "UNDEF: Fin de la directive '$FoundDirective'") #<%REMOVE%>
                          if (-not $Clean.isPresent)
                          {
                             #Gére le cas d'une directive UNDEF sans directive DEFINE associée
                            $isDirectiveOrphan=$Directives.Count -eq 0
                            if ($Directives.Count -gt 0)
                            {
                               $Last=$Directives.Peek()
                               $LastDirective=$Last.Name

                               if ($LastDirective -ne $FoundDirective)
                               {
                                   $msg=$Messages.DirectivesIncorrectlyNested -F $Container,$Last,$FoundDirective,$LineNumber
                                   $ex=new-object System.Exception $msg
                                   $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                                                        'DirectivesIncorrectlyNested',
                                                                                                        "ParserError",
                                                                                                        $Last
                                   $PSCmdlet.ThrowTerminatingError($ER)
                               }
                               $DebugLogger.PSDebug( "Pop $LastDirective") #<%REMOVE%>
                               [void]$Directives.Pop()
                            }

                            if ($isDirectiveOrphan)
                            {
                                $msg=$Messages.OrphanDirective -F $Container,$FoundDirective,$LineNumber
                                $ex=new-object System.Exception $msg
                                $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                                                       'OrphanDirective',
                                                                                                       "ParserError",
                                                                                                       $FoundDirective
                                $PSCmdlet.ThrowTerminatingError($ER)
                            }

                            if ($Directives.Count -eq 0)
                            {
                              $DebugLogger.PSDebug( "Fin d'imbrication. On arrête le filtre") #<%REMOVE%>
                              $isDirectiveBloc=$False
                            }
                            elseif (-not $Directives.Peek().isFilterParent )
                            {
                              $DebugLogger.PSDebug( "La directive '$($Directives.Peek().Name)' ne filtre pas. On arrête le filtre") #<%REMOVE%>
                              $isDirectiveBloc=$False
                            }
                             #Si le parent ne filtre pas on émet la ligne
                            if (-not $Last.isFilterParent )
                            {
                               $DebugLogger.PSDebug("`tEcrit la directive : $Line") #<%REMOVE%>
                               $Line
                            }

                            $DebugLogger.PSDebug("Demande d'arrêt du filtre des lignes =$($isDirectiveBloc -eq $true)") #<%REMOVE%>
                          }
                          continue
                      }#$RegexUNDEF

          #Supprime la ligne
         "#<%REMOVE%>"  {  $DebugLogger.PSDebug("Match REMOVE") #<%REMOVE%>
                           if ($Remove.isPresent)
                           {
                             $DebugLogger.PSDebug("`tREMOVE Line") #<%REMOVE%>
                             continue
                           }
                           if ($Clean.isPresent)
                           {
                             $DebugLogger.PSDebug("`tREMOVE directive") #<%REMOVE%>
                             $Line -replace "#<%REMOVE%>",''
                           }
                           else
                           { $Line }
                           continue
                        }#REMOVE

          #Décommente la ligne
         "#<%UNCOMMENT%>"  { $DebugLogger.PSDebug( "Match UNCOMMENT") #<%REMOVE%>
                             if ($UnComment.isPresent)
                             {
                               $DebugLogger.PSDebug( "`tUNCOMMENT  Line") #<%REMOVE%>
                               $Line -replace "^(\s*)#*<%UNCOMMENT%>(.*)",'$1$2'
                             }
                             elseif ($Clean.isPresent)
                             {
                               $DebugLogger.PSDebug( "`tRemove UNCOMMENT directive") #<%REMOVE%>
                               $Line -replace "^(\s*)#*<%UNCOMMENT%>(.*)",'$1#$2'
                             }
                             else
                             { $Line }
                             continue
                           } #%UNCOMMENT

          #Traite un fichier la fois
          #L'utilisateur à la charge de valider le nom et l'existence du fichier
         "^\s*#<INCLUDE\s{1,}%'(?<FileName>.*)'%>" {
                             $DebugLogger.PSDebug( "Match INCLUDE") #<%REMOVE%>
                             if ($Include.isPresent)
                             {
                               $FileName=$Matches.FileName.Trim()
                               if (-not (Test-Path $FileName))
                               {
                                 $ex=new-object System.Exception ($Messages.IncludedFileNotFound -F $FileName)
                                 $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                                                       'IncludedFileNotFound',
                                                                                                       "ReadError",
                                                                                                       $FileName
                                 $PSCmdlet.ThrowTerminatingError($ER)
                               }
                               else
                               {
                                 try {
                                    $IncludeContent=Get-Content $FileName -ReadCount 0 -Encoding:$Encoding
                                 } catch {
                                    $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $_,
                                                                                                        'UnableToReadIncludedFile',
                                                                                                        "ReadError",
                                                                                                        $FileName
                                    $PSCmdlet.ThrowTerminatingError($ER)
                                 }
                               }
                               $DebugLogger.PSDebug( "Inclut le fichier '$FileName'") #<%REMOVE%>
                                #Lit le fichier, le transforme à son tour, puis l'envoi dans le pipe
                                #L'imbrication de directives INCLUDE est possible
                                #Exécution dans une nouvelle portée
                               if ($Clean.isPresent)
                               {
                                  $DebugLogger.PSDebug( "Recurse Edit-Template -Clean") #<%REMOVE%>
                                  $NestedResult= $IncludeContent|
                                                  Edit-Template -Clean -Remove:$Remove -Include:$Include -UnComment:$UnComment -Container:$FileName
                                  #Ici on émet le contenu du tableau et pas le tableau reçu
                                  #Seul le résultat final est renvoyé en tant que tableau
                                  #todo [OutputType(?)] $DebugLogger.PSDebug(  gettype())
                                 $NestedResult
                               }
                               else #if (-not $Clean.isPresent)
                               {
                                  $DebugLogger.PSDebug( "Recurse Edit-Template $ConditionnalsKeyWord") #<%REMOVE%>
                                  if ($isConditionnalsKeyWord)
                                  {
                                    $NestedResult= $IncludeContent|
                                                    Edit-Template -ConditionnalsKeyWord $ConditionnalsKeyWord `
                                                                      -Remove:$Remove `
                                                                      -Include:$Include `
                                                                      -UnComment:$UnComment `
                                                                      -Container:$FileName
                                  }
                                  else
                                  {
                                    $NestedResult= $IncludeContent|
                                                    Edit-Template -Remove:$Remove `
                                                    -Include:$Include `
                                                    -UnComment:$UnComment `
                                                    -Container:$FileName
                                  }

                                 $NestedResult
                               }
                             }
                             elseif (-not $Clean.isPresent)
                             { $Line }
                             continue
                           } #%INCLUDE


         default {
             #Emet les lignes qui ne sont pas filtrées
           if ($isDirectiveBloc -eq $false)
           {
               $DebugLogger.PSDebug( "`tEmet : $Line") #<%REMOVE%>
               $Line
           }
           #<DEFINE %DEBUG%>
           else
           {  $DebugLogger.PSDebug( "`tFILTRE : $Line") }
           #<UNDEF %DEBUG%>
         }#default
      }#Switch
   }#Foreach

   $DebugLogger.PSDebug( "Directives.Count: $($Directives.Count)") #<%REMOVE%>
   if ($Directives.Count -gt 0)
   {
     $oldofs,$ofs=$ofs,','
     $ex=new-object System.Exception ($Messages.DirectiveIncomplet -F $Container,$Directives)
     $ER= New-Object -Typename System.Management.Automation.ErrorRecord -Argumentlist $ex,
                                                                        'IncompletDirective',
                                                                        "ParserError",
                                                                        $Directives
     $PSCmdlet.ThrowTerminatingError($ER)
     $ofs=$oldofs
  }
   else
   { ,$Result } #Renvoi un tableau, permet d'imbriquer un second appel sans transformation du résultat
   $Directives.Clear()
 }#process
} #Edit-Template

Function Edit-String{
<#
.SYNOPSIS
    Remplace toutes les occurrences d'un modèle de caractère, défini par
    une chaîne de caractère simple ou par une expression régulière, par une
    chaîne de caractères de remplacement.

.DESCRIPTION
    La fonction Edit-String remplace dans une chaîne de caractères toutes
    les occurrences d'une chaîne de caractères par une autre chaîne de caractères.
    Le contenu de la chaîne recherchée peut-être soit une chaîne de caractère
    simple soit une expression régulière.
.
    Le paramétrage du modèle de caractère et de la chaîne de caractères de
    remplacement se fait via une hashtable. Celle-ci permet un remplacement
    multiple sur une même chaîne de caractères. Ces multiples remplacements se
    font les uns à la suite des autres et pas en une seule fois.
    Chaque opération de remplacement reçoit la chaîne résultante du
    remplacement précédent.

.PARAMETER InputObject
    Chaîne à modifier.
    Peut référencer une valeur de type [Object], dans ce cas l'objet sera
    converti en [String] sauf si le paramètre -Property est renseigné.

.PARAMETER Setting
    Hashtable contenant les textes à rechercher et celui de leur remplacement
    respectif  :
     $MyHashtable."TexteARechercher"="TexteDeRemplacement"
     $MyHashtable."AncienTexte"="NouveauTexte"
    Sont autorisées toutes les instances de classe implémentant l'interface
    [System.Collections.IDictionary].
.
.
    Chaque entrée de la hashtable est une paire nom-valeur :
     ° Le nom contient la chaîne à rechercher, c'est une simple chaîne de
       caractères qui peut contenir une expression régulière.
       Il peut être de type [Object], dans ce cas l'objet sera
       converti en [String], même si c'est une collection d'objets.
       Si la variable $OFS est déclarée elle sera utilisée lors de cette
       conversion.
     ° La valeur contient la chaîne de remplacement et peut référencer :
        - une simple chaîne de caractères qui peut contenir une capture
          nommée, exemple :
           $HT."(Texte)"='$1 AjoutTexteSéparéParUnEspace'
           $HT."(Groupe1Capturé)=(Groupe2Capturé)"='$2=$1'
           $HT."(?<NomCapture>Texte)"='${NomCapture}AjoutTexteSansEspace'
          Cette valeur peut être $null ou contenir une chaîne vide.
.
          Note : Pour utiliser '$1" comme chaîne ce remplacement et non pas
          comme référence à une capture nommée, vous devez échapper le signe
          dollar ainsi '$$1'.
.
        - un Scriptblock, implicitement de type [System.Text.RegularExpressions.MatchEvaluator] :
            #Remplace le caractère ':' par '<:>'
           $h.":"={"<$($args[0])>"}
.
          Dans ce cas, pour chaque occurrence de remplacement trouvée, on
          évalue le remplacement en exécutant le Scriptblock qui reçoit dans
          $args[0] l'occurence trouvée et renvoie comme résultat une chaîne
          de caractères.
          Les conversions de chaînes de caractères en dates, contenues dans
          le scriptblock, se font en utilisant les informations de la
          classe .NET InvariantCulture (US).
.
          Note : En cas d'exception déclenchée dans le scriptblock,
          n'hésitez pas à consulter le contenu de son membre nommé
          InnerException.
          ATTENTION : Les scriptblock sont éxécutés dans la portée où ils sont
                      déclarés
.
        -une hashtable, les clés reconnues sont :
           -- Replace  Contient la valeur de remplacement.
                       Une chaîne vide est autorisée, mais pas la valeur
                       $null.
                       Cette clé est obligatoire.
                       Son type est [String] ou [ScriptBlock].
.
           -- Max      Nombre maximal de fois où le remplacement aura lieu.
                       Sa valeur par défaut est -1 (on remplace toutes les
                       occurrences trouvées) et ne doit pas être inférieure
                       à -1.
                       Pour une valeur $null ou une chaîne vide on affecte
                       la valeur par défaut.
.
                       Cette clé est optionnelle et s'applique uniquement
                       aux expressions régulières.
                       Son type est [Integer], sinon une tentative de
                       conversion est effectuée.
.
           -- StartAt  Position du caractère, dans la chaîne d'entrée, où
                       la recherche débutera.
                       Sa valeur par défaut est zéro (début de chaîne) et
                       doit être supérieure à zéro.
                       Pour une valeur $null ou une chaîne vide on affecte
                       la valeur par défaut.
.
                       Cette clé est optionnelle et s'applique uniquement
                       aux expressions régulières.
                       Son type est [Integer], sinon une tentative de
                       conversion est effectuée.
.
           -- Options  L'expression régulière est créée avec les options
                       spécifiées.
                       Sa valeur par défaut est "IgnoreCase" (la correspondance
                       ne respecte pas la casse).
                       Si vous spécifiez cette clé, l'option "IgnoreCase"
                       est écrasée par la nouvelle valeur.
                       Pour une valeur $null ou une chaîne vide on affecte
                       la valeur par défaut.
                       Peut contenir une valeur de type [Object], dans ce
                       cas l'objet sera converti en [String]. Si la variable
                       $OFS est déclarée elle sera utilisée lors de cette
                       conversion.
.
                       Cette clé est optionnelle et s'applique uniquement
                       aux expressions régulières.
                       Son type est [System.Text.RegularExpressions.RegexOptions].
.
                       Note: En lieu et place de cette clé/valeur, il est
                       possible d'utiliser une construction d'options inline
                       dans le corps de l'expression régulière (voir un des
                       exemples).
                       Ces options inlines sont prioritaires et
                       complémentaires par rapport à celles définies par
                       cette clé.
.
         Si la hashtable ne contient pas de clé nommée 'Replace', la fonction
         émet une erreur non-bloquante.
         Si une des clés 'Max','StartAt' et 'Options' est absente, elle est
         insérée avec sa valeur par défaut.
         La présence de noms de clés inconnues ne provoque pas d'erreur.
.
         Rappel : Les règles de conversion de .NET s'appliquent.
         Par exemple pour :
          [double] $Start=1,6
          $h."a"=@{Replace="X";StartAt=$Start}
         où $Start contient une valeur de type [Double], celle-ci sera
         arrondie, ici à 2.

.PARAMETER ReplaceInfo
    Indique que la fonction retourne un objet personnalisé [PSReplaceInfo].
    Celui-ci contient les membres suivants :
     -[ArrayList] Replaces  : Contient le résultat d'exécution de chaque
                              entrée du paramètre -Setting.
     -[Boolean]   isSuccess : Indique si un remplacement a eu lieu, que
                              $InputObject ait un contenu différent ou pas.
     -            Value     : Contient la valeur de retour de $InputObject,
                              qu'il y ait eu ou non de modifications .
.
    Le membre Replaces contient une liste d'objets personnalisés de type
    [PSReplaceInfoItem]. A chaque clé du paramètre -Setting correspond
    un objet personnalisé.
    L'ordre d'insertion dans la liste suit celui de l'exécution.
.
    PSReplaceInfoItem contient les membres suivants :
      - [String]  Old       : Contient la ligne avant la modification.
                              Si -Property est précisé, ce champ contiendra
                              toujours $null.
      - [String]  New       : Si le remplacement réussi, contient la ligne
                              après la modification, sinon contient $null.
                              Si -Property est précisé, ce champ contiendra
                              toujours $null.
      - [String]  Pattern   : Contient le pattern de recherche.
      - [Boolean] isSuccess : Indique s'il y a eu un remplacement.
                              Dans le cas où on remplace une occurrence 'A'
                              par 'A', une expression régulière permet de
                              savoir si un remplacement a eu lieu, même à
                              l'identique. Si vous utilisez -SimpleReplace
                              ce n'est plus le cas, cette propriété contiendra
                              $false.
    Notez que si le paramètre -Property est précisé, une seule opération sera
    enregistrée dans le tableau Replaces, les noms des propriétés traitées
    ne sont pas mémorisés.
.
    Note :
    Attention à la consommation mémoire si $InputObject est une chaîne de
    caractère de taille importante.
    Si vous mémorisez le résultat dans une variable, l'objet contenu dans
    le champ PSReplaceInfo.Value sera toujours référencé.
    Pensez à supprimer rapidement cette variable afin de ne pas retarder la
    libération automatique des objets référencés.

.PARAMETER Property
    Spécifie le ou les noms des propriétés d'un objet concernées lors du
    remplacement. Seules sont traités les propriétés de type [string]
    possédant un assesseur en écriture (Setter).
    Pour chaque propriété on effectue tous les remplacements précisés dans
    le paramètre -Setting, tout en tenant compte de la valeur des paramètres
    -Unique et -SimpleReplace.
    On réémet l'objet reçu, après avoir modifié les propriétés indiquées.
    Le paramètre -Inputobject n'est donc pas converti en type [String].
    Une erreur non-bloquante sera déclenchée si l'opération ne peut aboutir.
.
    Les jokers sont autorisés dans les noms de propriétés.
    Comme les objets reçus peuvent être de différents types, le traitement
    des propriétés inexistante ne génére pas d'erreur.

.PARAMETER Unique
    Pas de recherche/remplacement multiple.
.
    L'exécution ne concerne qu'une seule opération de recherche et de
    remplacement, la première qui réussit, même si le paramètre -Setting
    contient plusieurs entrées.
    Si le paramètre -Property est précisé, l'opération unique se fera sur
    toutes les propriétés indiquées.
    Ce paramètre ne remplace pas l'information précisée par la clé 'Max'.
.
    Note : La présence du switch -Whatif influence le comportement du switch
    -Unique. Puisque -Whatif n'effectue aucun traitement, on ne peut pas
    savoir si un remplacement a eu lieu, dans ce cas le traitement de
    toutes les clés sera simulé.

.PARAMETER SimpleReplace
    Utilise une correspondance simple plutôt qu'une correspondance d'expression
    régulière. La recherche et le remplacement utilisent la méthode
    String.Replace() en lieu et place d'une expression régulière.
    ATTENTION cette dernière méthode effectue une recherche de mots en
    respectant la casse et tenant compte de la culture.
.
    L'usage de ce switch ne permet pas d'utiliser toutes les fonctionnalités
    du paramètre -Setting, ex :  @{Replace="X";Max=n;StartAt=n;Options="Compiled"}.
    Si vous couplez ce paramètre avec ce type de hashtable, seule la clé
    'Replace' sera prise en compte.
    Un avertissement est généré, pour l'éviter utiliser le paramétrage
    suivant :
     -WarningAction:SilentlyContinue #bug en v2
     ou
     $WarningPreference="SilentlyContinue"

.EXAMPLE
    $S= "Caractères : 33 \d\d"
    $h=@{}
    $h."a"="?"
    $h."\d"='X'
    Edit-String -i $s $h
.
    Description
    -----------
    Ces commandes effectuent un remplacement multiple dans la chaîne $S,
    elles remplacent toutes les lettres 'a' par le caractère '?' et tous
    les chiffres par la lettre 'X'.
.
    La hashtable $h contient deux entrées, chaque clé est utilisée comme
    étant la chaîne à rechercher et la valeur de cette clé est utilisée
    comme chaîne de remplacement. Dans ce cas on effectue deux opérations
    de remplacement sur chaque chaîne de caractère reçu.
.
    Le résultat, de type chaîne de caractères, est égal à :
    C?r?ctères : XX \d\d
.
.
    La hashtable $H contenant deux entrées, Edit-String effectuera deux
    opérations de remplacement sur la chaîne $S.
.
    Ces deux opérations sont équivalentes à la suite d'instructions suivantes :
    $Resultat=$S -replace "a",'?'
    $Resultat=$Resultat -replace "\d",'X'
    $Resultat

.EXAMPLE
    $S= "Caractères : 33 \d\d"
    $h=@{}
    $h."a"="?"
    $h."\d"='X'
    Edit-String -i $s $h -SimpleReplace
.
    Description
    -----------
    Ces commandes effectuent un remplacement multiple dans la chaîne $S,
    elles remplacent toutes les lettres 'a' par le caractère '?', tous les
    chiffres ne seront pas remplacés par la lettre 'X', mais toutes les
    combinaisons de caractères "\d" le seront, car le switch SimpleReplace
    est précisé. Dans ce cas, la valeur de la clé est considérée comme une
    simple chaîne de caractères et pas comme une expression régulière.
.
    Le résultat, de type chaîne de caractères, est égal à :
    C?r?ctères : 33 XX
.
    La hashtable $H contenant deux entrées, Edit-String effectuera deux
    opérations de remplacement sur la chaîne $S.
.
    Ces deux opérations sont équivalentes à la suite d'instructions suivantes :
    $Resultat=$S.Replace("a",'?')
    $Resultat=$Resultat.Replace("\d",'X')
    $Resultat
     #ou
    $Resultat=$S.Replace("a",'?').Replace("\d",'X')

.EXAMPLE
    $S= "Caractères : 33"
    $h=@{}
    $h."a"="?"
    $h."\d"='X'
    Edit-String -i $s $h -Unique
.
    Description
    -----------
    Ces commandes effectuent un seul remplacement dans la chaîne $S, elles
    remplacent toutes les lettres 'a' par le caractère '?'.
.
    L'usage du paramètre -Unique arrête le traitement, pour l'objet en cours,
    dés qu'une opération de recherche et remplacement réussit.
.
    Le résultat, de type chaîne de caractères, est égal à :
    C?r?ctères : 33

.EXAMPLE
    $S= "Caractères : 33"
    $h=@{}
    $h."a"="?"
     #Substitution à l'aide de capture nommée
    $h."(?<Chiffre>\d)"='${Chiffre}X'
    $S|Edit-String $h

    Description
    -----------
    Ces commandes effectuent un remplacement multiple dans la chaîne $S,
    elles remplacent toutes les lettres 'a' par le caractère '?' et tous
    les chiffres par la sous-chaîne trouvée, correspondant au groupe
    (?<Chiffre>\d), suivie de la lettre 'X'.
.
    Le résultat, de type chaîne de caractères, est égal à :
    C?r?ctères : 3X3X
.
    L'utilisation d'une capture nommée, en lieu et place d'un numéro de
    groupe, comme $h."\d"='$1 X', évite de séparer le texte du nom de groupe
    par au moins un caractère espace.
    Le parsing par le moteur des expressions régulières reconnait $1, mais
    pas $1X.

.EXAMPLE
    $S= "Caractères : 33"
    $h=@{}
    $h."a"="?"
    $h."(?<Chiffre>\d)"='${Chiffre}X'
    $h.":"={ Write-Warning "Call delegate"; return "<$($args[0])>"}
    $S|Edit-String $h

    Description
    -----------
    Ces commandes effectuent un remplacement multiple dans la chaîne $S,
    elles remplacent :
     -toutes les lettres 'a' par le caractère '?',
     -tous les chiffres par la sous-chaîne trouvée, correspondant au groupe
     (?<Chiffre>\d), suivie de la lettre 'X',
     -et tous les caractères ':' par le résultat de l'exécution du
     ScriptBlock {"<$($args[0])>"}.
.
    Le Scriptblock est implicitement casté en un délégué du type
    [System.Text.RegularExpressions.MatchEvaluator].
.
    Son usage permet, pour chaque occurrence trouvée, d'évaluer le remplacement
    à l'aide d'instructions du langage PowerShell.
    Son exécution renvoie comme résultat une chaîne de caractères.
    Il est possible d'y référencer des variables globales (voir les règles
    de portée de PowerShell) ou l'objet référencé par le paramètre
    $InputObject.
.
    Le résultat, de type chaîne de caractères, est égal à :
    C?r?ctères <:> 3X3X

.EXAMPLE
    $S= "CAractères : 33"
    $h=@{}
    $h."a"=@{Replace="?";StartAt=3;Options="IgnoreCase"}
    $h."\d"=@{Replace='X';Max=1}
    $S|Edit-String $h

    Description
    -----------
    Ces commandes effectuent un remplacement multiple dans la chaîne $S.
    On paramètre chaque expression régulière à l'aide d'une hashtable
    'normalisée'.
.
    Pour l'expression régulière "a" on remplace toutes les lettres 'a',
    situées après le troisième caractère, par le caractère '?'. La recherche
    est insensible à la casse, on ne tient pas compte des majuscules et de
    minuscules, les caractères 'A' et 'a' sont concernés.
    Pour l'expression régulière "\d" on remplace un seul chiffre, le premier
    trouvé, par la lettre 'X'.
.
    Pour les clés de la hashtable 'normalisée' qui sont indéfinies, on
    utilisera les valeurs par défaut. La seconde clé est donc égale à :
     $h."\d"=@{Replace='X';Max=1;StartAt=0;Options="IgnoreCase"}
.
    Le résultat, de type chaîne de caractères, est égal à :
    CAr?ctères : X3

.EXAMPLE
    $S="( Date ) Test d'effet de bord : modification de mot"

    $h=@{}
    $h."Date"=(Get-Date).ToString("dddd d MMMM yyyy")
    $h."mot"="Date"
    $s|Edit-String $h -unique|Write-host -Fore White
    $s|Edit-String $h|Write-host -Fore White
    #
    #
    $od=new-object System.Collections.Specialized.OrderedDictionary
    $od."Date"=(Get-Date).ToString("dddd d MMMM yyyy")
    $od."mot"="Date"
    $s|Edit-String $od -unique|Write-host -Fore Green
    $s|Edit-String $od|Write-host -Fore Green

    Description
    -----------
    Ces deux exemples effectuent un remplacement multiple dans la chaîne $S.
    Les éléments d'une hashtable, déclarée par @{}, ne sont par ordonnés, ce
    qui fait que l'ordre d'exécution des expressions régulières peut ne pas
    respecter celui de l'insertion.
.
    Dans le premier exemple, cela peut provoquer un effet de bord. Si on
    exécute les deux expressions régulières, la seconde modifie également
    la seconde occurrence du terme 'Date' qui a précédemment été insérée
    lors du remplacement de l'occurrence du terme 'mot'.
    Dans ce cas, on peut utiliser le switch -Unique afin d'éviter cet effet
    de bord indésirable.
.
    Le second exemple utilise une hashtable ordonnée qui nous assure d'
    exécuter les expressions régulières dans l'ordre de leur insertion.
.
    Les résultats, de type chaîne de caractères, sont respectivement :
    ( NomJour nn NomMois année ) Test d'effet de bord : modification de NomJour nn NomMois année
    ( NomJour nn NomMois année ) Test d'effet de bord : modification de Date

.EXAMPLE
    $S=@"
#  Version :  1.1.0 b
#
#     Date    :     30 Octobre 2009
"@
    $NumberVersion="1.2.1"
    $Version="# Version : $Numberversion"

    $od=new-object System.Collections.Specialized.OrderedDictionary
     # \s* recherche les espaces et les tabulations
     #On échappe le caractère diése(#)
    $od.'(?im-s)^\s*\#\s*Version\s*:(.*)$'=$Version
    # équivalent à :
    #$od.'^\s*\#\s*Version\s*:(.*)$'=@{Replace=$Version;Options="IgnoreCase,MultiLine"}
    $LongDatePattern=[System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.LongDatePattern
    $od.'(?im-s)^\s*\#\s*Date\s*:(.*)$'="# Date    : $(Get-Date -format $LongDatePattern)"
    $S|Edit-String $od

    Description
    -----------
    Ces instructions effectuent un remplacement multiple dans la chaîne $S.
    On utilise une construction d'options inline '(?im-s)', celle-ci active
    l'option 'IgnoreCase' et 'Multiline', et désactive l'option 'Singleline'.
    Ces options inlines sont prioritaires et complémentaires par rapport à
    celles définies dans la clé 'Options' d'une entrée du paramètre
    -Setting.
.
    La Here-String $S est une chaîne de caractères contenant des retours
    chariot(CR+LF), on doit donc spécifier le mode multiligne (?m) qui
    modifie la signification de ^ et $ dans l'expression régulière, de
    telle sorte qu'ils correspondent, respectivement, au début et à la fin
    de n'importe quelle ligne et non simplement au début et à la fin de la
    chaîne complète.
.
    Le résultat, de type chaîne de caractères, est égal à :
# Version : 1.2.1
#
# Date    : NomDeJour xx NomDeMois Année
.
.   Note :
    Sous PS v2, un bug fait qu'une nouvelle ligne dans une Here-String est
    représentée par l'unique caractère "`n" et pas par la suite de caractères
    "`r`n".

.EXAMPLE
    $S=@"
@echo OFF
 rem Otto Matt
 rem
set ORACLE_BASE=D:\Oracle
set ORACLE_HOME=%ORACLE_BASE%\ora81
set ORACLE_SID=#SID#

%ORACLE_HOME%\bin\oradim -new -sid #SID# -intpwd %lINTPWD% -startmode manual -pfile "%ORACLE_BASE%\admin\#SID#\pfile\init#SID#.ora"
rem ...
%ORACLE_HOME%\bin\oradim -edit -sid #SID# -startmode auto
"@
    $h=@{}
    $h."#SID#"="BaseTest"
    $Result=$S|Edit-String $h -ReplaceInfo -SimpleReplace
    $Result|ft
    $Result.Replaces[0]|fl
    $Result|Set-Content C:\Temp\NewOrabase.cmd -Force
    Type C:\temp\NewOrabase.cmd
#   En une ligne :
#    $S|Edit-String $h -ReplaceInfo -SimpleReplace|
#     Set-Content C:\Temp\NewOrabase.cmd -Force

    Description
    -----------
    Ces instructions effectuent un remplacement simple dans la chaîne $S.
    On utilise ici Edit-String pour générer un script batch à partir
    d'un template (gabarit ou modèle de conception).
    Toutes les occurrences du texte '#SID#' sont remplacées par la chaîne
    'BaseTest'. Le résultat de la fonction est un objet personnalisé de type
    [PSReplaceInfo].
.
    Ce résultat peut être émis directement vers le cmdlet Set-Content, car
    le membre 'Value' de la variable $Result est automatiquement lié au
    paramètre -Value du cmdlet Set-Content.

.EXAMPLE
    $S="Un petit deux-roues, c'est trois fois rien."
    $Alternatives=@("un","deux","trois")
     #En regex '|' est le métacaractère
     #pour les alternatives.
    $ofs="|"
    $h=@{}
    $h.$Alternatives={
       switch ($args[0].Groups[0].Value) {
        "un"    {"1"; break}
        "deux"  {"2"; break}
        "trois" {"3"; break}
      }#switch
    }#$s
    $S|Edit-String $h
    $ofs=""

    Description
    -----------
    Ces instructions effectuent un remplacement multiple dans la chaîne $S.
    On utilise ici un tableau de chaînes qui se seront transformées, à
    l'aide de la variable PowerShell $OFS, en une chaîne d'expression
    régulière contenant une alternative "un|deux|trois". On lui associe un
    Scriptblock dans lequel on déterminera, selon l'occurrence trouvée, la
    valeur correspondante à renvoyer.
.
    Le résultat, de type chaîne de caractères, est égal à :
    1 petit 2-roues, c'est 3 fois rien.

.EXAMPLE
     #Paramètrage
    $NumberVersion="1.2.1"
    $Version="# Version : $Numberversion"
     #La date est substituée une seule fois lors
     #de la création de la hashtable.
    $Modifications= @{
       "^\s*\#\s*Version\s*:(.*)$"=$Version;
       '^\s*\#\s*Date\s*:(.*)$'="# Date    : $(Get-Date -format 'd MMMM yyyy')"
    }
    $RunWinMerge=$False

    #Fichiers de test :
    # http://projets.developpez.com/projects/add-lib/files

    cd "C:\Temp\Edit-String\TestReplace"
     #Cherche et remplace dans tous les fichiers d'une arborescence, sauf les .bak
     #Chaque fichier est recopié en .bak avant les modifications
    Get-ChildItem "$PWD" *.ps1 -exclude *.bak -recurse|
     Where-Object {!$_.PSIsContainer} |
     ForEach-Object {
       $CurrentFile=$_
       $BackupFile="$($CurrentFile).bak"
       Copy-Item $CurrentFile $BackupFile

       Get-Content $BackupFile|
        Edit-String $Modifications|
        Set-Content -path $CurrentFile

        #compare le résultat à l'aide de Winmerge
      if ($RunWinMerge)
       {Microsoft.PowerShell.Management\start-process  "C:\Program Files\WinMerge\WinMergeU.exe" -Argument "/maximize /e /s /u $BackupFile $CurrentFile"  -wait}
    } #foreach

    Description
    -----------
    Ces instructions effectuent un remplacement multiple sur le contenu
    d'un ensemble de fichiers '.ps1'.
    On remplace dans l'entête de chaque fichier le numéro de version et la
    date. Avant le traitement, chaque fichier .ps1 est recopié en .bak dans
    le même répertoire. Une fois le traitement d'un fichier effectué, on
    peut visualiser les différences à l'aide de l'utilitaire WinMerge.

.EXAMPLE
    $AllObjects=dir Variable:
    $AllObjects| Ft Name,Description|More
      $h=@{}
      $h."^$"={"Nouvelle description de la variable $($InputObject.Name)"}
       #PowerShell V2 FR
      $h."(^Nombre|^Indique|^Entraîne)(.*)$"='POWERSHELL $1$2'
      $Result=$AllObjects|Edit-String $h -property "Description" -ReplaceInfo -Unique
    $AllObjects| Ft Name,Description|More

    Description
    -----------
    Ces instructions effectuent un remplacement unique sur le contenu d'une
    propriété d'un objet, ici de type [PSVariable].
    La première expression régulière recherche les objets dont la propriété
    'Description', de type [string], n'est pas renseignée.
    La seconde modifie celles contenant en début de chaîne un des trois mots
    précisés dans une alternative. La chaîne de remplacement reconstruit le
    contenu en insérant le mot 'PowerShell' en début de chaîne.
.
    Le contenu de la propriété 'Description' d'un objet de type
    [PSVariable] n'est pas persistant, cette opération ne présente donc
    aucun risque.

.EXAMPLE
    try {
       Reg Save HKEY_CURRENT_USER\Environment C:\temp\RegistryHiveTest.hiv
       REG LOAD HKU\PowerShell_TEST C:\temp\RegistryHiveTest.hiv
       new-Psdrive -name Test -Psprovider Registry -root HKEY_USERS\PowerShell_Test
       cd Test:
       $key = Get-Item $pwd
       $values = Get-ItemProperty $key.PSPath
       $key.Property.GetEnumerator()|
         Foreach {
           New-Object PSObject -Property @{
             Path=$key.PSPath;
             Name="$_";
             Value=$values."$_"
           }#Property
         }|
         Edit-String @{"C:\\"="D:\"} -Property Value|
         Set-ItemProperty -name {$_.Name} -Whatif
     }#try
    finally
     {
       cd C:
       Remove-PSDrive Test
       key=$null;values=$null
      [GC]::Collect(GC]::MaxGeneration)
      REG UNLOAD HKU\PowerShell_TEST
    }#finally

    Description
    -----------
    La première instruction crée une sauvegarde des informations de la ruche
    'HKEY_CURRENT_USER\Environment', la seconde charge la sauvegarde dans
    une nouvelle ruche nommée 'HKEY_USer\PowerShell_TEST' et la troisième
    crée un drive PowerShell nommé 'Test'.
.
    Les instructions suivantes récupèrent les clés de registre et leurs
    valeurs. À partir de celles-ci on crée autant d'objets personnalisés
    qu'il y a de clés. Les noms des membres de cet objet personnalisé
    correspondent à des noms de paramètres du cmdlet Set-ItemProperty qui
    acceptent l'entrée de pipeline (ValueFromPipelineByPropertyName).
.
    Ensuite, à l'aide de Edit-String, on recherche et remplace dans la
    propriété 'Value' de chaque objet créé, les occurrences de 'C:\' par
    'D:\'.
    Edit-String émet directement les objets vers le cmdlet
    Set-ItemProperty.
    Et enfin, celui-ci lit les informations à mettre à jour à partir des
    propriétés de l'objet personnalisé reçu.
.
    Pour terminer, on supprime le drive PowerShell et on décharge la ruche
    de test.
    Note:
     Sous PowerShell l'usage de Set-ItemProperty (à priori) empêche la
     libération de la ruche chargée, on obtient l'erreur 'Access Denied'.
     Pour finaliser cette opération, on doit fermer la console PowerShell
     et exécuter cmd.exe afin d'y libérer correctement la ruche :
      Cmd /k "REG UNLOAD HKU\PowerShell_TEST"

.INPUTS
    System.Management.Automation.PSObject
     Vous pouvez diriger tout objet ayant une méthode ToString vers
     Edit-String.

.OUTPUTS
    System.String
    System.Object
    System.PSReplaceInfo

     Edit-String retourne tous les objets qu'il soient modifiés ou pas.

.NOTES
    Vous pouvez consulter la documentation Française sur les expressions
    régulières, via les liens suivants :
.
    Options des expressions régulières  :
     http://msdn.microsoft.com/fr-fr/library/yd1hzczs(v=VS.80).aspx
     http://msdn.microsoft.com/fr-fr/library/yd1hzczs(v=VS.100).aspx
.
    Éléments du langage des expressions régulières :
     http://msdn.microsoft.com/fr-fr/library/az24scfc(v=VS.80).aspx
.
    Compilation et réutilisation de regex :
     http://msdn.microsoft.com/fr-fr/library/8zbs0h2f(vs.80).aspx
.
.
    Au coeur des dictionnaires en .Net 2.0 :
     http://mehdi-fekih.developpez.com/articles/dotnet/dictionnaires
.
    Outil de création d'expression régulière, info et Tips
    pour PowerShell :
     http://powershell-scripting.com/index.php?option=com_joomlaboard&Itemid=76&func=view&catid=4&id=3731
.
.
    Il est possible d'utiliser la librairie de regex du projet PSCX :
     "un deux deux trois"|Edit-String @{$PSCX:RegexLib.RepeatedWord="Deux"}
     #renvoi
     #un deux trois

.COMPONENT
    expression régulière
#>

  [CmdletBinding(DefaultParameterSetName = "asString",SupportsShouldProcess=$True)]
  [OutputType("asString", [String])]
  [OutputType("asReplaceInfo", [PSObject])]
  [OutputType("asObject", [Object])]
  param (
          [ValidateNotNull()]
          [AllowEmptyString()]
           #pas de position
           #si on n'utilise pas le pipe on doit préciser son nom -InputObject ou -I
           #le paramètre suivant sera considéré comme étant en position 0, car innommé
          [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
        [System.Management.Automation.PSObject] $InputObject,

#<%REMOVE%> Les scriptblock sont éxécuté dans la porté de leur déclaration
          [ValidateNotNullOrEmpty()]
          [Parameter(Position=0, Mandatory=$true)]
        [System.Collections.IDictionary] $Setting,

         [ValidateNotNullOrEmpty()]
         [Parameter(Position=1, ParameterSetName="asObject")]
        [string[]] $Property,

        [switch] $Unique,
        [switch] $SimpleReplace,
        [switch] $ReplaceInfo)


  begin {
     function New-Exception {
      [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                         Justification="New-Exception do not change the system state.")]
      param ($Exception,$Message=$null)
      #Crée et renvoi un objet exception pour l'utiliser avec $PSCmdlet.WriteError()

        if ($Exception.GetType().IsNotPublic)
         {
            #Le constructeur de la classe de l'exception trappée est inaccessible
           $ExceptionClassName="System.Exception"
            #On mémorise l'exception courante.
           $InnerException=$Exception
         }
        else
         {
           $ExceptionClassName=$Exception.GetType().FullName
           $InnerException=$Null
         }
        if ($null -eq $Message)
         {$Message=$Exception.Message}

          #Recrée l'exception trappée avec un message personnalisé
        New-Object $ExceptionClassName($Message,$InnerException)
     } #New-Exception

     Function Test-InputObjectProperty($CurrentProperty) {
      #Valide les prérequis d'une propriété d'objet
      #Elle doit exister, être de type [String] et être en écriture.

       $PropertyName=$CurrentProperty.Name
       if ($CurrentProperty.TypeNameOfValue -ne "System.String")
        {throw (New-Object System.ArgumentException(($Messages.ReplaceObjectPropertyNotString  -F $PropertyName),$PropertyName)) }
       if (-not $CurrentProperty.IsSettable)
        {throw (New-Object System.ArgumentException(($Messages.ReplaceObjectPropertyReadOnly -F $PropertyName),$PropertyName)) }
     }#Test-InputObjectProperty

    function ConvertTo-String($Value){
       #Conversion PowerShell
       #Par exemple converti $T=@("un","Deux") en "un deux"
       # ce qui est équivalent à "$T"
       #Au lieu de System.Object[] si on utilise $InputObject.ToString()
       #De plus un PSObject peut ne pas avoir de méthode ToString()
     [System.Management.Automation.LanguagePrimitives]::ConvertTo($Value,
                                                                   [string],
                                                                   [System.Globalization.CultureInfo]::InvariantCulture)
    }#ConvertTo-String

    function Convert-DictionnaryEntry($Parameters)
    {   #Converti un DictionnaryEntry en une string "clé=valeur clé=valeur..."
      "$($Parameters.GetEnumerator()|ForEach-Object {"$($_.key)=$($_.value)"})"
    }#Convert-DictionnaryEntry

    function New-ObjectReplaceInfo{
      [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                         Justification="New-Exception do not change the system state.")]
      param()
       #Crée un objet contenant le résultat d'un remplacement
       #Permet d'émettre la chaîne modifiée et de savoir si
       # une modification a eu lieu.
      $Result=New-Object PSObject -Property @{
         #Contient le résultat d'exécution de chaque entrée
        Replaces=New-Object System.Collections.ArrayList(6)
         #Indique si $InputObject a été modifié ou non
        isSuccess=$False
         #Contient la valeur de retour de $InputObject,
         #qu'il ait été modifié ou non.
        Value=$Null
      }
     $Result.PsObject.TypeNames[0] = "PSReplaceInfo"
     $Result
    }#New-ObjectReplaceInfo

    function isParameterWellFormed {
     #Renvoi true si l'entrée de hashtable $Parameters est correcte
     #la recherche préliminaire par ContainsKey est dicté par la possible
     #déclaration de set-strictmode -version 2.0
    #Replace
      param($Parameters)

      if (-not $Parameters.ContainsKey('Replace') -or ($null -eq $Parameters.Replace))
      {  #[string]::Empty est valide, même pour la clé
  		 $PSCmdlet.WriteError(
           (New-Object System.Management.Automation.ErrorRecord(
              #inverse nomParam,msg
     				 (New-Object System.ArgumentNullException('Replace',$Messages.WellFormedKeyNullOrEmptyValue)),
               "WellFormedKeyNullOrEmptyValue",
               "InvalidData",
               $ParameterString # Si $ErrorView="CategoryView" l'information est affichée
            )
           )
         )#WriteError
         return $false
      }
      else
       {
         $Parameters.Replace=$Parameters.Replace -as [string]
         if ($null -eq $Parameters.Replace)
          {
      		$PSCmdlet.WriteError(
             (New-Object System.Management.Automation.ErrorRecord(
         			 (New-Object System.InvalidCastException ($Messages.WellFormedInvalidCast -F "Replace",'[String]')),
         			   "WellFormedInvalidCast",
         			   "InvalidType",
         			   $ParameterString
              )
             )
            )#WriteError
            return $false
          }
       }
    #Max
      if (-not $Parameters.ContainsKey('Max') -or ($null -eq $Parameters.Max -or $Parameters.Max -eq [String]::Empty))
       {$Parameters.Max=-1}
      else
       {
         $Parameters.Max=$Parameters.Max -as [int]
         if ($null -eq $Parameters.Max)
          {
            $PSCmdlet.WriteError(
              (New-Object System.Management.Automation.ErrorRecord(
         				 (New-Object System.InvalidCastException ($Messages.WellFormedInvalidCast -F 'Max','[int]')),
                   "WellFormedInvalidCast",
                   "InvalidData",
                   $ParameterString
               )
              )
            )#WriteError
            return $false
          }
        elseif ($Parameters.Max -lt -1)
          {
            $PSCmdlet.WriteError(
             (New-Object System.Management.Automation.ErrorRecord(
     		   (New-Object System.ArgumentException($Messages.WellFormedInvalidValueNotLower,'Max')),
                "WellFormedInvalidValueNotLower",
                "InvalidData",
                $ParameterString
     		  )
             )
            )#WriteError
            return $false
          }
       }
    #StartAt
      if (-not $Parameters.ContainsKey('StartAt') -or ($null -eq $Parameters.StartAt))
       {$Parameters.StartAt=0}
      else
       {
         $Parameters.StartAt=$Parameters.StartAt -as [int]
          #si StartAt=[String]::Empty -> StartAt=0
         if ($null -eq $Parameters.StartAt)
          {
            $PSCmdlet.WriteError(
              (New-Object System.Management.Automation.ErrorRecord(
                 (New-Object System.InvalidCastException ($Messages.WellFormedInvalidCast -F 'StartAt','[int]')),
                 "WellFormedInvalidCast",
                 "InvalidData",
                 $ParameterString
                )
              )
            )#WriteError
            return $false
          }
         elseif ($Parameters.StartAt -lt 0)
          {
            $PSCmdlet.WriteError(
              (New-Object System.Management.Automation.ErrorRecord(
                (New-Object System.ArgumentException($Messages.WellFormedInvalidValueNotZero,'StartAt')),
                "WellFormedInvalidValueNotZero",
                "InvalidData",
                $ParameterString
               )
              )
            )#WriteError
            return $false
          }
       }
    #Options
      if (-not $Parameters.ContainsKey('Options') -or (($null -eq $Parameters.Options) -or ($Parameters.Options -eq [String]::Empty)))
       {$Parameters.Options="IgnoreCase"}
      else
       {
          #La présence d'espaces ne gêne pas la conversion.
         $Parameters.Options=(ConvertTo-String $Parameters.Options) -as [System.Text.RegularExpressions.RegexOptions]
         if ($null -eq $Parameters.Options)
          {
            $PSCmdlet.WriteError(
              (New-Object System.Management.Automation.ErrorRecord(
         		(New-Object System.InvalidCastException ($Messages.WellFormedInvalidCast -F 'Options','[System.Text.RegularExpressions.RegexOptions]')),
                "WellFormedInvalidCast",
                "InvalidData",
                $ParameterString
               )
              )
            )#WriteError
            return $false
          }
       }
      return $true
    }#isParameterWellFormed

    function BuildList {
       #Construit une liste avec des DictionaryEntry valides
     $Setting.GetEnumerator()|
       Foreach-Object {
         $Parameters=$_.Value
         $WrongDictionnaryEntry=$false
            #Analyse la valeur de l'entrée courante de $Setting
            #puis la transforme en un type hashtable 'normalisée'
         if ($Parameters -is [System.Collections.IDictionary])
         {  #On ne modifie pas la hashtable d'origine
             #Les objets référencés ne sont pas clonés, on duplique l'adresse.
            $Parameters=$Parameters.Clone()

            $ParameterString="$($_.Key) = @{$(Convert-DictionnaryEntry $Parameters)}"
            $WrongDictionnaryEntry=-not (isParameterWellFormed $Parameters)
            #<DEFINE %DEBUG%>
            if ($WrongDictionnaryEntry -and ($DebugPreference -eq "Continue"))
            { $DebugLogger.PSDebug("[DictionaryEntry][Error]$ParameterString")}
            #<UNDEF %DEBUG%>
            if ($SimpleReplace)
            { $PSCmdlet.WriteWarning($Messages.WarningSwitchSimpleReplace) }
         }#-is [System.Collections.IDictionary]
         else
         {   #Dans tous les cas on utilise une hashtable normalisée
              #pour récupèrer les paramètres.
             if ($null -eq $Parameters)
             {$Parameters=[String]::Empty}
             $Parameters=@{Replace=$Parameters;Max=-1;StartAt=0;Options="IgnoreCase"}
         }

         if  ($_.Key -isnot [String])
         {
             #La clé peut être un objet,
             #on tente une conversion de la clé en [string].
             #On laisse la possibilité de dupliquer les clés
             #issues de cette conversion.
           [string]$Key= ConvertTo-String $_.Key
           if ($Key -eq [string]::Empty)
            { $PSCmdlet.WriteWarning(($Messages.WarningConverTo -F $_.Key))}
         }
         else
         {$key=$_.Key}

         if ($SimpleReplace -and ($Key -eq [String]::Empty))
         {
            $WrongDictionnaryEntry =$true
            $PSCmdlet.WriteError(
              (New-Object System.Management.Automation.ErrorRecord(
         		(New-Object System.ArgumentException($Messages.ReplaceSimpleEmptyString,'Replace')),
                 "ReplaceSimpleEmptyString",
                 "InvalidData",
                 (Convert-DictionnaryEntry $Parameters)
                )
              )
            )#WriteError
         }

         if (-not $WrongDictionnaryEntry )
         {
            $DEntry=new-object System.Collections.DictionaryEntry($Key,$Parameters)
            $RegExError=$False
             #Construit les regex
            if (-not $SimpleReplace)
            {
                 #Construit une expression régulière dont le pattern est
                 #le nom de la clé de l'entrée courante de $TabKeyValue
               try
               {
                 $Expression=New-Object System.Text.RegularExpressions.RegEx($Key,$Parameters.Options)
                 $DEntry=$DEntry|Add-Member NoteProperty RegEx $Expression -PassThru
               }catch {
                 $PSCmdlet.WriteError(
                  (New-Object System.Management.Automation.ErrorRecord(
            		 (New-Exception $_.Exception ($Messages.ReplaceRegExCreate -F $_.Exception.Message)),
                      "ReplaceRegExCreate",
                      "InvalidOperation",
                      ("[{0}]" -f $Key)
                     )
                  )
                 )#WriteError
                 $DebugLogger.PSDebug("Regex erronée, remplacement suivant.")#<%REMOVE%>
                 $RegExError=$True
               }
            }
            if (-not $RegExError)
            {
               #Si on utilise un simple arraylist
               # les propriétés personnalisées sont perdues
              [void]$TabKeyValue.Add($DEntry)
            }
          } #sinon on ne crée pas l'entrée invalide
       }#Foreach
    }#BuildList

    $DebugLogger.PSDebug("ParameterSetName :$($PsCmdlet.ParameterSetName)")#<%REMOVE%>
     #Manipule-t-on une chaîne ou un objet ?
    [Switch] $AsObject= $PSBoundParameters.ContainsKey('Property')
    $DebugLogger.PSDebug("AsObject: $AsObject")#<%REMOVE%>

     #On doit explicitement rechercher
     #la présence des paramètres communs
    [Switch] $Whatif= $null
    [void]$PSBoundParameters.TryGetValue('Whatif',[REF]$Whatif)

    #<DEFINE %DEBUG%>
    $DebugLogger.PSDebug("Whatif: $WhatIf")#<%REMOVE%>
    $DebugLogger.PSDebug("ReplaceInfo: $ReplaceInfo")#<%REMOVE%>
    if ($AsObject) # Si set-strictmode -version 2.0
    {$DebugLogger.PSDebug("Properties : $Property")}
    #<UNDEF %DEBUG%>
      #On construit une liste afin de filtrer les éléments invalides
      #et faciliter l'usage de break/continue dans la boucle du
      #traitement principal du bloc process.
    $TabKeyValue=New-Object 'System.Collections.Generic.List[PSObject]'
    BuildList
    if ($DebugPreference -eq "Continue")
    {
       $TabKeyValue|
        Foreach-Object {
          if ($_.value -is [System.Collections.IDictionary])
           { $h=$_.value.GetEnumerator()|ForEach-Object {"$($_.key)=$($_.value)"} }
          else
           { $h=$_.value }
          $DebugLogger.PSDebug("[DictionaryEntry]$($_.key)=$h")#<%REMOVE%>
        }
    }
  }#begin

  process {
    #Si $TabKeyValue ne contient aucun élément,
    #on construit tout de même l'object ReplaceInfo

    if ($InputObject -isnot [String])
    {  #Si on ne manipule pas les propriétés d'un objet,
       #on force la conversion en [string].
      if ($AsObject -eq $false)
       {
         $ObjTemp=$InputObject
         [string]$InputObject= ConvertTo-String $InputObject
         If ($InputObject -eq [String]::Empty)
          { $PSCmdlet.WriteWarning(($Messages.WarningConverTo -F $ObjTemp))}
       }
    }
     #on crée l'objet contenant
     #la collection de résultats détaillés
    if ($ReplaceInfo)
    {$Resultat=New-ObjectReplaceInfo}

     #Savoir si au moins une opération de remplacement a réussie.
    [Boolean] $AllSuccessReplace=$false

    for ($i=0; $i -lt $TabKeyValue.Count; $i++)
    {
       #$Key contient la chaîne à rechercher
      $Key=$TabKeyValue[$i].Key

       #$parameters contient les informations de remplacement
      $Parameters=$TabKeyValue[$i].Value

       #L'opération de remplacement courante a-t-elle réussie ?
      [Boolean] $CurrentSuccessReplace=$false

      if ($ReplaceInfo)
       {  #Crée, pour la clé courante, un objet résultat
         if ($AsObject)
            #on ne crée pas de référence sur l'objet,
            #car les champs Old et New pointe sur le même objet.
            #Seul les champs pattern et Key sont renseignés.
          {$CurrentListItem=New-Object PSObject -Property @{Old=$Null;New=$Null;isSuccess=$False;Pattern=$Key} }
         else
          {$CurrentListItem=New-Object PSObject -Property @{Old=$InputObject;New=$null;isSuccess=$False;Pattern=$Key} }
         $CurrentListItem.PsObject.TypeNames[0] = "PSReplaceInfoItem"
       }

      #<DEFINE %DEBUG%>
      $DebugLogger.PSDebug(@"
[InputObject][$($InputObject.Gettype().Fullname)]$InputObject
On remplace $Key avec $(Convert-DictionnaryEntry $Parameters)
"@)
      #<UNDEF %DEBUG%>
      if ($SimpleReplace)
      {  #Récupère la chaîne de remplacement
        if ($Parameters.Replace -is [ScriptBlock])
         { try {
              #$ReplaceValue contiendra la chaîne de remplacement
             $ReplaceValue=&$Parameters.Replace
             $DebugLogger.PSDebug("`t[ScriptBlock] $($Parameters.Replace)`r`n$ReplaceValue")#<%REMOVE%>
           } catch {
             $PSCmdlet.WriteError(
                (New-Object System.Management.Automation.ErrorRecord (
           		  (New-Exception $_.Exception ($Messages.ReplaceSimpleScriptBlockError -F $Key,$Parameters.Replace.ToString(),$_)),
                  "ReplaceSimpleScriptBlockError",
                  "InvalidOperation",
                  ("[{0}]" -f $Parameters.Replace)
                )
               )
             )#WriteError
             continue
           }#catch
         }#-is [ScriptBlock]
        else
         {$ReplaceValue=$Parameters.Replace}

          #On traite des propriétés d'un objet
        if ($AsObject)
         {
            $Property|
              #prérequis: Le nom de la propriété courante ne pas doit pas être null ni vide.
              #On recherche les propriétés à chaque fois, on laisse ainsi la possibilité au
              # code d'un scriptblock de modifier/ajouter des propriétés dynamiquement sur
              # le paramètre $InputObject.
              #Celui-ci doit être de type PSObject pour être modifié directement, sinon
              #seul l'objet renvoyé sera concerné.
             Foreach-object {
                $DebugLogger.PSDebug("[Traitement des wildcards] $_")#<%REMOVE%>
                # Ex : Pour PS* on récupère plusieurs propriétés
                #La liste contient toutes les propriétés ( .NET + PS).
                #Si la propriété courante ne match pas, on itère sur les éléments de $Property
               $InputObject.PSObject.Properties.Match($_)|
               Foreach-Object {
                  $DebugLogger.PSDebug("[Wildcard property]$_")#<%REMOVE%>
                  $CurrentProperty=$_
                  $CurrentPropertyName=$CurrentProperty.Name
                  try {
                      #Si -Whatif n'est pas précisé on exécute le traitement
                    if ($PSCmdlet.ShouldProcess(($Messages.ObjectReplaceShouldProcess -F $InputObject.GetType().Name,$CurrentPropertyName)))
                     {
                        #Logiquement il ne devrait y avoir qu'un bloc ShouldProcess
                        #englobant tous les traitements, ici cela permet d'afficher
                        #le détails des opérations imbriquées tout en précisant
                        #les valeurs effectives utilisées lors du remplacement.
                       Test-InputObjectProperty $CurrentProperty
                       $DebugLogger.PSDebug("`t[String-Before][Object] : $InputObject.$CurrentPropertyName")#<%REMOVE%>
                       $OriginalProperty=$InputObject.$CurrentPropertyName
                         $InputObject.$CurrentPropertyName=$OriginalProperty.Replace($Key,$ReplaceValue)
                         #On affecte une seule fois la valeur $true
                       if (-not $CurrentSuccessReplace)
                        {$CurrentSuccessReplace= -not ($OriginalProperty -eq $InputObject.$CurrentPropertyName) }
                       $DebugLogger.PSDebug("`t[String-After][Object] : $InputObject.$CurrentPropertyName")#<%REMOVE%>
                     }#ShouldProcess
                  } catch {
                      #La propriété est en R/O,
                      #La propriété n'est pas du type String, etc.

                      #Par défaut recrée l'exception trappée avec un message personnalisé
                     $PSCmdlet.WriteError(
                      (New-Object System.Management.Automation.ErrorRecord (
                           #Recrée l'exception trappée avec un message personnalisé
                 		  $_.Exception,
                          "EdittringObjectPropertyError",
                          "InvalidOperation",
                          $InputObject
                 		)
                      )
                     )#WriteError
                   }#catch
              }#Foreach $CurrentPropertyName
            }#Foreach  $Property
         } #AsObject
        else
         {
           if ($PSCmdlet.ShouldProcess(($Messages.StringReplaceShouldProcess -F $Key,$ReplaceValue)))
            {
               $OriginalStr=$InputObject
               $InputObject=$InputObject.Replace($Key,$ReplaceValue)
               $CurrentSuccessReplace= -not ($OriginalStr -eq $InputObject)
              $DebugLogger.PSDebug("`t[String] : $InputObject")#<%REMOVE%>
            }#ShouldProcess
         }
      }#SimpleReplace
      else
      {    #Replace via RegEx
        $Expression=($TabKeyValue[$i]).Regex
        $DebugLogger.PSDebug("`t[Regex] : $($expression.ToString()) $($Expression|Select-Object *)")#<%REMOVE%>

         #Récupère la chaîne de remplacement
        if  (($Parameters.Replace -isnot [String]) -and ($Parameters.Replace -isnot [ScriptBlock]))
         {
             #Appel soit
             #  Regex.Replace (String, String, Int32, Int32)
             # soit
             #  Regex.Replace (String, MatchEvaluator, Int32, Int32)
             #
             #On évite, selon le type du paramètre fourni, un possible problème
             #de cast lors de l'exécution interne de la recherche de la signature
             #la plus adaptée (Distance Algorithm). (A l'origine code PS V2)
             # cf. ([regex]"\d").Replace.OverloadDefinitions
             # "test 123"|Edit-String @{"\d"=get-date}
             # Error : Impossible de convertir l'argument « 1 » (valeur « 17/07/2010 13:31:56 ») de « Replace »
             #  en type « System.Text.RegularExpressions.MatchEvaluator » 
             #
             #InvalidCastException :
             #Cette exception se produit lorsqu'une conversion particulière n'est pas prise en charge.
             #Un InvalidCastException est levé pour les conversions suivantes :
             # - Conversions de DateTime en tout autre type sauf String.
             # ...
             #Autre solution :
             # "test 123"|Edit-String @{"\d"=@(get-date)}
             #Mais cette solution apporte un autre problème, dans ce cas on utilise plus la culture courante,
             # mais celle US, car le scriptblock est exécuté dans un contexte où les conversions de chaînes de
             #caractères en dates se font en utilisant les informations de la classe .NET InvariantCulture.
             #cf. http://janel.spaces.live.com/blog/cns!9B5AA3F6FA0088C2!185.entry
           $DebugLogger.PSDebug( "`t[ConverTo] $($Parameters.Replace.GetType())")#<%REMOVE%>
           [string]$ReplaceValue=ConvertTo-String $Parameters.Replace
         } #Replace via RegEx
        else
         {$ReplaceValue=$Parameters.Replace }

          #On traite des propriétés d'un objet
        if ($AsObject)
         {
            $Property|
               # Le nom de la propriété courante ne pas doit pas être null ni vide.
              Foreach-object {
                $DebugLogger.PSDebug("[Traitement des wildcards]$_")#<%REMOVE%>
                # Ex : Pour PS* on récupère plusieurs propriétés
               $InputObject.PSObject.Properties.Match($_)|
               Foreach-object {
                  $DebugLogger.PSDebug("[Wildcard property]$_")#<%REMOVE%>
                  $CurrentProperty=$_
                  $CurrentPropertyName=$CurrentProperty.Name
                   try {
                     if ($PSCmdlet.ShouldProcess(($Messages.ObjectReplaceShouldProcess -F $InputObject.GetType().Name,$CurrentPropertyName)))
                      {
                        Test-InputObjectProperty $CurrentProperty
                        $DebugLogger.PSDebug("`t[RegEx-Before][Object] $CurrentPropertyName : $($InputObject.$CurrentPropertyName)")#<%REMOVE%>
                            #On ne peut rechercher au delà de la longueur de la chaîne.
                        if (($InputObject.$CurrentPropertyName).Length -ge $Parameters.StartAt)
                         {
                           $isMatch=$Expression.isMatch($InputObject.$CurrentPropertyName,$Parameters.StartAt)
                           if ($isMatch)
                            {
                              $InputObject.$CurrentPropertyName=$Expression.Replace( $InputObject.$CurrentPropertyName,
                                                                                     $ReplaceValue,
                                                                                     $Parameters.Max,
                                                                                     $Parameters.StartAt)
                              $DebugLogger.PSDebug("`t[RegEx-After][Object] $CurrentPropertyName : $($InputObject.$CurrentPropertyName)")#<%REMOVE%>
                            }
                         }
                        else
                         {
                           $PSCmdlet.WriteWarning(($Messages.ReplaceRegExStarAt -F $InputObject.$CurrentPropertyName,
                                                                                   $Parameters.StartAt,
                                                                                   $InputObject.$CurrentPropertyName.Length))
                           $DebugLogger.PSDebug($msg)#<%REMOVE%>
                           $isMatch=$false
                         }
                        $DebugLogger.PSDebug("`t[RegEx][Object] ismatch : $ismatch")#<%REMOVE%>
                         #On ne mémorise pas les infos de remplacement (replaceInfo) pour les propriétés,
                         #seulement pour les clés (pattern)
                        if (-not $CurrentSuccessReplace)
                         {$CurrentSuccessReplace=$isMatch }
                      }#ShouldProcess
                  } catch {
                      $isMatch=$False #l'erreur peut provenir du ScriptBlock (MachtEvaluator)
                      #La propriété est en R/O,
                      #La propriété n'est pas du type String, etc.
                      $PSCmdlet.WriteError(
                       (New-Object System.Management.Automation.ErrorRecord (
                            #Recrée l'exception trappée avec un message personnalisé
                           $_.Exception,
                           "ReplaceRegexObjectPropertyError",
                           "InvalidOperation",
                           $InputObject
                          )
                       )
                      )#WriteError
                  } #catch
              }#Foreach $CurrentPropertyName
            }#Foreach  $Property
         } #AsObject
        else
         {
            if ($PSCmdlet.ShouldProcess(($Messages.StringReplaceShouldProcess -F $Key,$ReplaceValue)))
             {
                $DebugLogger.PSDebug("`t[RegEx-Before] : $InputObject")#<%REMOVE%>
                  #On ne peut rechercher au delà de la longueur de la chaîne.
                if ($InputObject.Length -ge $Parameters.StartAt)
                 {
                   $isMatch=$Expression.isMatch($InputObject,$Parameters.StartAt)
                   if ($isMatch)
                    { try {
                        $InputObject=$Expression.Replace($InputObject,$ReplaceValue,$Parameters.Max,$Parameters.StartAt)
                        $DebugLogger.PSDebug("`t[RegEx-After] : $InputObject")#<%REMOVE%>
                      } catch {
                         $isMatch=$False #l'erreur peut provenir du ScriptBlock (MachtEvaluator)
                         $PSCmdlet.WriteError(
                          (New-Object System.Management.Automation.ErrorRecord (
                               #Recrée l'exception trappée avec un message personnalisé
                     		 $_.Exception,
                             "StringReplaceRegexError",
                             "InvalidOperation",
                             ("[{0}]" -f $InputObject)
                             )
                          )
                         )#WriteError
                      } #catch
                    }#$ismatch
                 }
                else
                 {
                   $PSCmdlet.WriteWarning(($Messages.ReplaceRegExStarAt -F $InputObject,$Parameters.StartAt,$InputObject.Length))
                   $DebugLogger.PSDebug("`t$Msg")#<%REMOVE%>
                   $isMatch=$false
                 }
                $DebugLogger.PSDebug("`t[RegEx] ismatch : $ismatch")#<%REMOVE%>
                $CurrentSuccessReplace=$isMatch
             }#ShouldProcess
         }
      }#Replace via RegEx

      #On construit la liste PSReplaceInfo.PSReplaceInfoItem
      #contenant le résultat de l'opération courante.
     if ($ReplaceInfo)
     {
         #Si Whatif est précisé l'opération n'est pas effectuée
         #On ne renvoit rien dans le pipeline
        if (-not $Whatif)
        {
          if (($AsObject -eq $False) -and $CurrentSuccessReplace)
          { $CurrentListItem.New=$InputObject }
          elseif ($CurrentSuccessReplace)
          { $CurrentListItem.New='Pas renseigné' }
           #On affecte une seule fois la valeur $true
          if (-not $AllSuccessReplace)
          { $AllSuccessReplace=$CurrentSuccessReplace }
          $CurrentListItem.isSuccess=$CurrentSuccessReplace
          [void]$Resultat.Replaces.Add($CurrentListItem)
          $DebugLogger.PSDebug("[ReplaceInfo] : $($CurrentListItem|Select-Object *)")#<%REMOVE%>
       }#$Whatif
     }#$ReplaceInfo

      #Est-ce qu'on effectue une seule opération de remplacement ?
     if ($Unique -and $CurrentSuccessReplace)
      {
        $DebugLogger.PSDebug("-Unique détecté et le dernier remplacement a réussi. Break.")#<%REMOVE%>
        break
      }
   }# For $TabKeyValue.Count

   if (-not $Whatif)
   {
       #Emission du résultat
       #On a effectué n traitements sur une seule ligne ou un seul object
      if ($ReplaceInfo)
      {
        $Resultat.isSuccess=$AllSuccessReplace
        $Resultat.Value=$InputObject
         #En cas d'émission sur un cmdlet, utilisant Value comme
         #propriété de binding (ValueFromPipelineByPropertyName),
         #on redéclare la méthode ToString afin que l'objet $Resultat
         #renvoie le contenu de son membre Value comme donnée à lier.
        $Resultat=$Resultat|Add-member ScriptMethod ToString {$this.Value} -Force -Passthru
          #Passe un tableau d'objet contenant un élément, un objet.
          #PS énumére le tableau et renvoi un seul objet.
          #
          #Dans ce contexte ceci est valable, même
          #si l'objet est un IEnumerable.
        $PSCmdlet.WriteObject(@($Resultat),$true)
      }#$ReplaceInfo
     else
      {$PSCmdlet.WriteObject(@($InputObject),$true)}

  }
  $DebugLogger.PSDebug("[Pipeline] Next object.")#<%REMOVE%>
 }#process
}#Edit-String

#<DEFINE %Log4Net%>
# Suppression des objets du module
Function OnRemoveTemplate {
  param()

  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemoveTemplate
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemoveTemplate }
#<UNDEF %Log4Net%>
Export-ModuleMember -Alias * -Function Edit-String,Edit-Template,Out-ArrayOfString
