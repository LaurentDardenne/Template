
#Requires -version 3.0

Function New-PSCustomObjectFunction {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                     Justification="Edit-Template do not use ShouldProcess.")]
    #crée une fonction génèrant un objet personnalisé simple
    #tous ses paramètres sont obligatoires et ne sont pas typé
    #
    # Par défaut génère du code sans la signature du mot clé Function
    # Le paramètre -FILE génére du code avec la signature du mot clé Function
    # Le paramètre -AsPSVariableProperty génére un objet dont
    #  les propriétés sont basées sur la classe PSVariableProperty. Requière le module PSObjectHelper

  param(
       [Parameter(Mandatory=$true,position=0)]
       [ValidateNotNullOrEmpty()]
      $Noun,
       [Parameter(Mandatory=$true,position=1)]
       [ValidateNotNullOrEmpty()]
      [String[]]$Parameters,
      [switch] $asFunction
  )
$ofs=' '
$Borne=$Parameters.count-1
$code=@"
$(if ($asFunction) {"Function New-$Noun{"})
param(
    $(For ($I=0;$I -le $Borne;$I++)
      { $Name=$Parameters[$I]
        @"
`t [Parameter(Mandatory=`$True,position=$I)]
`t`$${Name}$(if ($I -Ne $borne) {",`r`n"})
"@
      }
     )
)
 $( "`r`n  [pscustomobject]@{`r`n"
    "   PSTypeName='$Noun';"
  $( $Parameters|
     Foreach-Object {
      "`r`n    {0}=`${1};" -F $_,$_
     }
   )
  "`r`n   }"
  )

$(if ($asFunction) {"`r`n}# New-$Noun"})
"@
$Code
}#New-PSCustomObjectFunction

# New-PSCustomObjectFunction -noun montruc -Parameters computer,name
#
# Function New-montruc{
# #Requires -version 4
#  -#requires -module PSObjectHelper  #bug du parseur avec la v2 !!!
# param(
#          [Parameter(Mandatory=$True,position=0)]
#         $computer,
#          [Parameter(Mandatory=$True,position=1)]
#         $name
# )
#    $O=[pscustomobject]@{
#        PSTypeName='montruc'
#      }
#   $PSBoundParameters.GetEnumerator()|
#    Foreach {
#      #$O.PSObject.Properties.Add( (New-PSVariableProperty $_.Key $_.Value -ReadOnly) )
#    }
#  $O
# }# New-montruc
# New-montruc aa bb