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
# .ExternalHelp Template-Help.xml
 if ([string]::IsNullOrEmpty($_))
 {$_}
 else
 { $_ -split "(`n|`r`n)" }
}

Function Edit-Template {
# .ExternalHelp Template-Help.xml
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

   $RegexREMOVE="#<"+"%REMOVE%>" #Avoid wrong matching, this pattern can be present inside the text of documentation
                                 #limit : we parse string not an Ast or tokens
   $RegexUNCOMMENT="#<"+"%UNCOMMENT%>"
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
       $DebugLogger.PSDebug( "`t[$LineNumber]Lit  $Line `t  isDirectiveBloc=$isDirectiveBloc") #<%REMOVE%>
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
        $RegexREMOVE {
                           $DebugLogger.PSDebug("Match REMOVE") #<%REMOVE%>
                           if ($Remove.isPresent)
                           {
                             $DebugLogger.PSDebug("`tREMOVE Line") #<%REMOVE%>
                             continue
                           }
                           if ($Clean.isPresent)
                           {
                             $DebugLogger.PSDebug("`tREMOVE directive") #<%REMOVE%>
                             $Line -replace $RegexREMOVE,''
                             $DebugLogger.PSDebug("`tEcrit la directive : $($Line -replace $RegexREMOVE,'')") #<%REMOVE%>
                           }
                           else
                           {
                             $DebugLogger.PSDebug("`tEcrit la directive : $Line") #<%REMOVE%>
                             $Line
                           }
                           continue
                        }#REMOVE

          #Décommente la ligne
       $RegexUNCOMMENT  {
                             $DebugLogger.PSDebug( "Match UNCOMMENT") #<%REMOVE%>
                             if ($UnComment.isPresent)
                             {
                               $DebugLogger.PSDebug( "`tUNCOMMENT  Line") #<%REMOVE%>
                               $Line -replace "^(\s*)#*<%UNCOMMENT%>(.*)",'$1$2'
                               $DebugLogger.PSDebug("`tEcrit la directive : $($Line -replace "^(\s*)#*<%UNCOMMENT%>(.*)",'$1$2')") #<%REMOVE%>
                             }
                             elseif ($Clean.isPresent)
                             {
                               $DebugLogger.PSDebug( "`tRemove UNCOMMENT directive") #<%REMOVE%>
                               $Line -replace "^(\s*)#*<%UNCOMMENT%>(.*)",'$1#$2'
                             }
                             else
                             {
                               $DebugLogger.PSDebug("`tEcrit la directive : $Line") #<%REMOVE%>
                               $Line
                             }
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
# .ExternalHelp Template-Help.xml
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

#<%REMOVE%> Les scriptblock sont éxécuté dans la portée de leur déclaration
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
      param($Parameters, $ParameterString)

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
            $WrongDictionnaryEntry=-not (isParameterWellFormed $Parameters $ParameterString)
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

    $TKVCount=$TabKeyValue.Count
    for ($i=0; $i -lt $TKVCount; $i++)
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

#<DEFINE %DEBUG%>
# Suppression des objets du module
Function OnRemoveTemplate {
  param()

  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemoveTemplate
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemoveTemplate }
#<UNDEF %DEBUG%>

