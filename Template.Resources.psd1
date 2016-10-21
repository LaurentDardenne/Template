#TODO
# Localized Template.Resources.psd1 : en-US

ConvertFrom-StringData @'
# Edit-String
WellFormedKeyNullOrEmptyValue  =La clé 'Replace' n'existe pas ou sa valeur est `$null
WellFormedInvalidCast          =La valeur de la clé {0} ne peut pas être convertie en {1}.
WellFormedInvalidValueNotLower =La valeur de la clé 'Max' ne peut pas être inférieure à -1.
WellFormedInvalidValueNotZero  =La valeur de la clé 'StartAt' doit être supérieure à zéro.
ReplaceSimpleEmptyString       =L'option SimpleReplace ne permet pas une chaîne de recherche vide.
ReplaceRegExCreate             =[Construction de regex] {0}
ReplaceRegExStarAt             ={0}`r`nStartAt({1}) est supérieure à la longueur de la chaîne({2})
ReplaceObjectPropertyNotString =La propriété '{0}' n'est pas du type string.
ReplaceObjectPropertyReadOnly = La propriété '{0}' est en lecture seule.
ReplaceSimpleScriptBlockError  ={0}={{{1}}}`r`n{2}
ObjectReplaceShouldProcess     =Objet [{0}] Propriété : {1}
StringReplaceShouldProcess     ={0} par {1}
WarningSwitchSimpleReplace     =Le switch SimpleReplace n'utilise pas toutes les fonctionnalités d'une hashtable de type @{Replace='X';Max=n;StartAt=n,Options='Y'}.`r`n Utilisez une simple chaîne de caractères.
WarningConverTo                =La conversion, par ConverTo(), renvoi une chaîne vide.`r`n{0}

# Edit-Template
DirectiveContainsSpace          =La directive '%{0}%' contient des espaces.
DirectiveNameReserved           =Ces noms de directive sont réservées : {0}. Utilisez le paramétre associé.
DirectivesIncorrectlyNested     =Parsing annulé.`r`n{0}`r`nLes déclarations des directives '{1}' et '{2}:{3}' ne sont pas imbriquées.
OrphanDirective                 =Parsing annulé.`r`n{0}`r`nLa directive #<UNDEF %{1}%> n'est pas associée à une directive DEFINE ('{1}:{2}')
IncludedFileNotFound            =Un fichier à inclure n'existe pas '{0}'
DirectiveIncomplet              =Parsing annulé.`r`n{0}`r`nLes directives suivantes n'ont pas de mot clé de fin : {1}
'@
