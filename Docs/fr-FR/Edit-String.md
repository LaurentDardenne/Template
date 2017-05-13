---
external help file: Template-help.xml
online version: 
schema: 2.0.0
---

# Edit-String

## SYNOPSIS
Remplace toutes les occurrences d'un modèle de caractère, défini par une chaîne de caractère simple ou par une expression régulière, par une chaîne de caractères de remplacement.

## SYNTAX

### asString (Default)
```
Edit-String -InputObject <PSObject> [-Setting] <IDictionary> [-Unique] [-SimpleReplace] [-ReplaceInfo]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### asObject
```
Edit-String -InputObject <PSObject> [-Setting] <IDictionary> [[-Property] <String[]>] [-Unique]
 [-SimpleReplace] [-ReplaceInfo] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
La fonction Edit-String remplace dans une chaîne de caractères toutes les occurrences d'une chaîne de caractères par une autre chaîne de caractères.
Le contenu de la chaîne recherchée peut-être soit une chaîne de caractère simple soit une expression régulière.

Le paramétrage du modèle de caractère et de la chaîne de caractères de remplacement se fait via une hashtable.
Celle-ci permet un remplacement multiple sur une même chaîne de caractères.
Ces multiples remplacements se font les uns à la suite des autres et pas en une seule fois.
Chaque opération de remplacement reçoit la chaîne résultante duremplacement précédent.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$S= "Caractères : 33 \d\d"
$h=@{}
$h."a"="?"
$h."\d"='X'
Edit-String -i $s $h
```

Ces commandes effectuent un remplacement multiple dans la chaîne $S, elles remplacent toutes les lettres 'a' par le caractère '?' et tous les chiffres par la lettre 'X'.

La hashtable $h contient deux entrées, chaque clé est utilisée comme étant la chaîne à rechercher et la valeur de cette clé est utilisée comme chaîne de remplacement.
Dans ce cas on effectue deux opérations de remplacement sur chaque chaîne de caractères reçu.

Le résultat, de type chaîne de caractères, est égal à
 C?r?ctères : XX \d\d


La hashtable $H contenant deux entrées, Edit-String effectuera deux opérations de remplacement sur la chaîne $S.

Ces deux opérations sont équivalentes à la suite d'instructions suivantes

$Resultat=$S -replace "a",'?'
$Resultat=$Resultat -replace "\d",'X'
$Resultat

### -------------------------- EXAMPLE 2 --------------------------
```
$S= "Caractères : 33 \d\d"
$h=@{}
$h."a"="?"
$h."\d"='X'
Edit-String -i $s $h -SimpleReplace
```

Ces commandes effectuent un remplacement multiple dans la chaîne $S, elles remplacent toutes les lettres 'a' par le caractère '?', tous les chiffres ne seront pas remplacés par la lettre 'X', mais toutes les combinaisons de caractères "\d" le seront, car le switch SimpleReplace est précisé.

Dans ce cas, la valeur de la clé est considérée comme une simple chaîne de caractères et pas comme une expression régulière.

Le résultat, de type chaîne de caractères, est égal à :
C?r?ctères : 33 XX

La hashtable $H contenant deux entrées, Edit-String effectuera deux opérations de remplacement sur la chaîne $S.

Ces deux opérations sont équivalentes à la suite d'instructions suivantes :

$Resultat=$S.Replace("a",'?')
$Resultat=$Resultat.Replace("\d",'X')
$Resultat
 \#ou
$Resultat=$S.Replace("a",'?').Replace("\d",'X')

### -------------------------- EXAMPLE 3 --------------------------
```
$S= "Caractères : 33"
$h=@{}
$h."a"="?"
$h."\d"='X'
Edit-String -i $s $h -Unique
```

Ces commandes effectuent un seul remplacement dans la chaîne $S, elles remplacent toutes les lettres 'a' par le caractère '?'.

L'usage du paramètre -Unique arrête le traitement, pour l'objet en cours, dés qu'une opération de recherche et remplacement réussit.

Le résultat, de type chaîne de caractères, est égal à :
C?r?ctères : 33

### -------------------------- EXAMPLE 4 --------------------------
```
$S= "Caractères : 33"
$h=@{}
$h."a"="?"
 #Substitution à l'aide de capture nommée
$h."(?\<Chiffre\>\d)"='${Chiffre}X'
$S|Edit-String $h
```

Ces commandes effectuent un remplacement multiple dans la chaîne $S, elles remplacent toutes les lettres 'a' par le caractère '?' et tous les chiffres par la sous-chaîne trouvée, correspondant au groupe (?\<Chiffre\>\d), suivie de la lettre 'X'.

Le résultat, de type chaîne de caractères, est égal à :
C?r?ctères : 3X3X

L'utilisation d'une capture nommée, en lieu et place d'un numéro de
groupe, comme $h."\d"='$1 X', évite de séparer le texte du nom de groupe par au moins un caractère espace.
Le parsing par le moteur des expressions régulières reconnait $1, mais pas $1X.

### -------------------------- EXAMPLE 5 --------------------------
```
$S= "Caractères : 33"
$h=@{}
$h."a"="?"
$h."(?\<Chiffre\>\d)"='${Chiffre}X'
$h.":"={ Write-Warning "Call delegate"; return "\<$($args\[0\])\>"}
$S|Edit-String $h
```

Ces commandes effectuent un remplacement multiple dans la chaîne $S,
elles remplacent :
 -toutes les lettres 'a' par le caractère '?',
 -tous les chiffres par la sous-chaîne trouvée, correspondant au groupe
 (?\<Chiffre\>\d), suivie de la lettre 'X',
 -et tous les caractères ':' par le résultat de l'exécution du
 ScriptBlock {"\<$($args\[0\])\>"}.

Le Scriptblock est implicitement casté en un délégué du type
\[System.Text.RegularExpressions.MatchEvaluator\].

Son usage permet, pour chaque occurrence trouvée, d'évaluer le remplacement
à l'aide d'instructions du langage PowerShell.
Son exécution renvoie comme résultat une chaîne de caractères.
Il est possible d'y référencer des variables globales (voir les règles
de portée de PowerShell) ou l'objet référencé par le paramètre
$InputObject.

Le résultat, de type chaîne de caractères, est égal à :
C?r?ctères \<:\> 3X3X

### -------------------------- EXAMPLE 6 --------------------------
```
$S= "CAractères : 33"
$h=@{}
$h."a"=@{Replace="?";StartAt=3;Options="IgnoreCase"}
$h."\d"=@{Replace='X';Max=1}
$S|Edit-String $h
```

Ces commandes effectuent un remplacement multiple dans la chaîne $S.
On paramètre chaque expression régulière à l'aide d'une hashtable
'normalisée'.

Pour l'expression régulière "a" on remplace toutes les lettres 'a',
situées après le troisième caractère, par le caractère '?'.
La recherche
est insensible à la casse, on ne tient pas compte des majuscules et de
minuscules, les caractères 'A' et 'a' sont concernés.
Pour l'expression régulière "\d" on remplace un seul chiffre, le premier
trouvé, par la lettre 'X'.

Pour les clés de la hashtable 'normalisée' qui sont indéfinies, on
utilisera les valeurs par défaut.
La seconde clé est donc égale à :

 $h."\d"=@{Replace='X';Max=1;StartAt=0;Options="IgnoreCase"}

Le résultat, de type chaîne de caractères, est égal à :
CAr?ctères : X3

### -------------------------- EXAMPLE 7 --------------------------
```
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
```

Ces deux exemples effectuent un remplacement multiple dans la chaîne $S.
Les éléments d'une hashtable, déclarée par @{}, ne sont par ordonnés, ce
qui fait que l'ordre d'exécution des expressions régulières peut ne pas
respecter celui de l'insertion.

Dans le premier exemple, cela peut provoquer un effet de bord.
Si on exécute les deux expressions régulières, la seconde modifie également
la seconde occurrence du terme 'Date' qui a précédemment été insérée
lors du remplacement de l'occurrence du terme 'mot'.
Dans ce cas, on peut utiliser le switch -Unique afin d'éviter cet effet
de bord indésirable.

Le second exemple utilise une hashtable ordonnée qui nous assure d'
exécuter les expressions régulières dans l'ordre de leur insertion.

Les résultats, de type chaîne de caractères, sont respectivement :
( NomJour nn NomMois année ) Test d'effet de bord : modification de NomJour nn NomMois année
( NomJour nn NomMois année ) Test d'effet de bord : modification de Date

### -------------------------- EXAMPLE 8 --------------------------
```
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
$LongDatePattern=\[System.Threading.Thread\]::CurrentThread.CurrentCulture.DateTimeFormat.LongDatePattern
$od.'(?im-s)^\s*\#\s*Date\s*:(.*)$'="# Date    : $(Get-Date -format $LongDatePattern)"
$S|Edit-String $od
```

Ces instructions effectuent un remplacement multiple dans la chaîne $S.
On utilise une construction d'options inline '(?im-s)', celle-ci active
l'option 'IgnoreCase' et 'Multiline', et désactive l'option 'Singleline'.
Ces options inlines sont prioritaires et complémentaires par rapport à
celles définies dans la clé 'Options' d'une entrée du paramètre
-Setting.

La Here-String $S est une chaîne de caractères contenant des retours
chariot(CR+LF), on doit donc spécifier le mode multiligne (?m) qui
modifie la signification de ^ et $ dans l'expression régulière, de
telle sorte qu'ils correspondent, respectivement, au début et à la fin
de n'importe quelle ligne et non simplement au début et à la fin de la
chaîne complète.

Le résultat, de type chaîne de caractères, est égal à :

\# Version : 1.2.1
\#
\# Date    : NomDeJour xx NomDeMois Année

Note :
Sous PS v2, un bug fait qu'une nouvelle ligne dans une Here-String est
représentée par l'unique caractère "\`n" et pas par la suite de caractères
"\`r\`n".

### -------------------------- EXAMPLE 9 --------------------------
```
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
$Result.Replaces\[0\]|fl
$Result|Set-Content C:\Temp\NewOrabase.cmd -Force
Type C:\temp\NewOrabase.cmd
#   En une ligne :
#    $S|Edit-String $h -ReplaceInfo -SimpleReplace|
#     Set-Content C:\Temp\NewOrabase.cmd -Force
```

Ces instructions effectuent un remplacement simple dans la chaîne $S.
On utilise ici Edit-String pour générer un script batch à partir
d'un template (gabarit ou modèle de conception).
Toutes les occurrences du texte '#SID#' sont remplacées par la chaîne
'BaseTest'.
Le résultat de la fonction est un objet personnalisé de type
\[PSReplaceInfo\].

Ce résultat peut être émis directement vers le cmdlet Set-Content, car
le membre 'Value' de la variable $Result est automatiquement lié au
paramètre -Value du cmdlet Set-Content.

### -------------------------- EXAMPLE 10 --------------------------
```
$S="Un petit deux-roues, c'est trois fois rien."
$Alternatives=@("un","deux","trois")
 #En regex '|' est le métacaractère
 #pour les alternatives.
$ofs="|"
$h=@{}
$h.$Alternatives={
   switch ($args\[0\].Groups\[0\].Value) {
    "un"    {"1"; break}
    "deux"  {"2"; break}
    "trois" {"3"; break}
  }#switch
}#$s
$S|Edit-String $h
$ofs=""
```

Ces instructions effectuent un remplacement multiple dans la chaîne $S.
On utilise ici un tableau de chaînes qui se seront transformées, à
l'aide de la variable PowerShell $OFS, en une chaîne d'expression
régulière contenant une alternative "un|deux|trois".
On lui associe un
Scriptblock dans lequel on déterminera, selon l'occurrence trouvée, la
valeur correspondante à renvoyer.

Le résultat, de type chaîne de caractères, est égal à :
1 petit 2-roues, c'est 3 fois rien.

### -------------------------- EXAMPLE 11 --------------------------
```
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
```

Ces instructions effectuent un remplacement multiple sur le contenu
d'un ensemble de fichiers '.ps1'.
On remplace dans l'entête de chaque fichier le numéro de version et la
date.
Avant le traitement, chaque fichier .ps1 est recopié en .bak dans
le même répertoire.
Une fois le traitement d'un fichier effectué, on peut visualiser les
différences à l'aide de l'utilitaire WinMerge.

### -------------------------- EXAMPLE 12 --------------------------
```
$AllObjects=dir Variable:
$AllObjects| Ft Name,Description|More
  $h=@{}
  $h."^$"={"Nouvelle description de la variable $($InputObject.Name)"}
   #PowerShell V2 FR
  $h."(^Nombre|^Indique|^Entraîne)(.*)$"='POWERSHELL $1$2'
  $Result=$AllObjects|Edit-String $h -property "Description" -ReplaceInfo -Unique
$AllObjects| Ft Name,Description|More
```

Ces instructions effectuent un remplacement unique sur le contenu d'une
propriété d'un objet, ici de type \[PSVariable\].
La première expression régulière recherche les objets dont la propriété
'Description', de type \[string\], n'est pas renseignée.
La seconde modifie celles contenant en début de chaîne un des trois mots
précisés dans une alternative.
La chaîne de remplacement reconstruit le contenu en insérant le mot 'PowerShell'
en début de chaîne.

Le contenu de la propriété 'Description' d'un objet de type
\[PSVariable\] n'est pas persistant, cette opération ne présente donc
aucun risque.

### -------------------------- EXAMPLE 13 --------------------------
```
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
     Edit-String @{"C:\\\\"="D:\"} -Property Value|
     Set-ItemProperty -name {$_.Name} -Whatif
 }#try
finally
 {
   cd C:
   Remove-PSDrive Test
   key=$null;values=$null
  \[GC\]::Collect(GC\]::MaxGeneration)
  REG UNLOAD HKU\PowerShell_TEST
}#finally
```

La première instruction crée une sauvegarde des informations de la ruche
'HKEY_CURRENT_USER\Environment', la seconde charge la sauvegarde dans
une nouvelle ruche nommée 'HKEY_USer\PowerShell_TEST' et la troisième
crée un drive PowerShell nommé 'Test'.

Les instructions suivantes récupèrent les clés de registre et leurs
valeurs.
À partir de celles-ci on crée autant d'objets personnalisés
qu'il y a de clés.
Les noms des membres de cet objet personnalisé
correspondent à des noms de paramètres du cmdlet Set-ItemProperty qui
acceptent l'entrée de pipeline (ValueFromPipelineByPropertyName).

Ensuite, à l'aide de Edit-String, on recherche et remplace dans la
propriété 'Value' de chaque objet créé, les occurrences de 'C:\' par 'D:\'.

Edit-String émet directement les objets vers le cmdlet Set-ItemProperty.
Et enfin, celui-ci lit les informations à mettre à jour à partir des
propriétés de l'objet personnalisé reçu.

Pour terminer, on supprime le drive PowerShell et on décharge la ruche
de test.

Note:
 Sous PowerShell l'usage de Set-ItemProperty (à priori) empêche la
 libération de la ruche chargée, on obtient l'erreur 'Access Denied'.
 Pour finaliser cette opération, on doit fermer la console PowerShell
 et exécuter cmd.exe afin d'y libérer correctement la ruche :
  Cmd /k "REG UNLOAD HKU\PowerShell_TEST"

## PARAMETERS

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Chaîne à modifier.
Peut référencer une valeur de type \[Object\], dans ce cas l'objet sera
converti en \[String\] sauf si le paramètre -Property est renseigné.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Property
Spécifie le ou les noms des propriétés d'un objet concernées lors du remplacement.

Seules sont traités les propriétés de type \[string\] possédant un assesseur en écriture (Setter).

Pour chaque propriété on effectue tous les remplacements précisés dans le paramètre -Setting, tout en tenant compte de la valeur des paramètres -Unique et -SimpleReplace.

On réémet l'objet reçu, après avoir modifié les propriétés indiquées.
Le paramètre -Inputobject n'est donc pas converti en type \[String\].
Une erreur non-bloquante sera déclenchée si l'opération ne peut aboutir.


Les jokers sont autorisés dans les noms de propriétés.
Comme les objets reçus peuvent être de différents types, le traitement des propriétés inexistante ne génére pas d'erreur.

```yaml
Type: String[]
Parameter Sets: asObject
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReplaceInfo
Indique que la fonction retourne un objet personnalisé \[PSReplaceInfo\].

Celui-ci contient les membres suivants :

 -\[ArrayList\] Replaces  :

  Contient le résultat d'exécution de chaque entrée du paramètre -Setting.


 -\[Boolean\]   isSuccess :

  Indique si un remplacement a eu lieu, que $InputObject ait un contenu différent ou pas.


 - Value     :

  Contient la valeur de retour de $InputObject, qu'il y ait eu ou non des modifications.

Le membre Replaces contient une liste d'objets personnalisés de type \[PSReplaceInfoItem\].
A chaque clé du paramètre -Setting correspond un objet personnalisé.
L'ordre d'insertion dans la liste suit celui de l'exécution.

PSReplaceInfoItem contient les membres suivants :

  - \[String\]  Old       :

   Contient la ligne avant la modification.
   Si -Property est précisé, ce champ contiendra toujours $null.


  - \[String\]  New       :

   Si le remplacement réussi, contient la ligne après la modification, sinon contient $null.
   Si -Property est précisé, ce champ contiendra toujours $null.

  - \[String\]  Pattern   :

   Contient le pattern de recherche.


  - \[Boolean\] isSuccess :

  Indique s'il y a eu un remplacement.
  Dans le cas où on remplace une occurrence 'A' par 'A', une expression régulière permet de savoir si un remplacement a eu lieu, même à l'identique.


Si vous utilisez -SimpleReplace  ce n'est plus le cas, cette propriété contiendra $false.
Notez que si le paramètre -Property est précisé, une seule opération sera enregistrée dans le tableau Replaces, les noms des propriétés traitées ne sont pas mémorisés.

Note :
Attention à la consommation mémoire si $InputObject est une chaîne de caractère de taille importante.

Si vous mémorisez le résultat dans une variable, l'objet contenu dans le champ PSReplaceInfo.Value sera toujours référencé.

Pensez à supprimer rapidement cette variable afin de ne pas retarder la libération automatique des objets référencés.

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

### -Setting
Hashtable contenant les textes à rechercher et celui de leur remplacement respectif  :

 $MyHashtable."TexteARechercher"="TexteDeRemplacement"
 $MyHashtable."AncienTexte"="NouveauTexte"

Sont autorisées toutes les instances de classe implémentant l'interface \[System.Collections.IDictionary\].


Chaque entrée de la hashtable est une paire nom-valeur :

 - Le nom contient la chaîne à rechercher, c'est une simple chaîne de  caractères qui peut contenir une expression régulière.

   Il peut être de type \[Object\], dans ce cas l'objet sera converti en \[String\], même si c'est une collection d'objets.

   Si la variable $OFS est déclarée elle sera utilisée lors de cette conversion.


 - La valeur contient la chaîne de remplacement et peut référencer :

    - une simple chaîne de caractères qui peut contenir une capture nommée, exemple :

       $HT."(Texte)"='$1 AjoutTexteSéparéParUnEspace'

       $HT."(Groupe1Capturé)=(Groupe2Capturé)"='$2=$1'

       $HT."(?\<NomCapture\>Texte)"='${NomCapture}AjoutTexteSansEspace'

      Cette valeur peut être $null ou contenir une chaîne vide.


      Note : Pour utiliser '$1" comme chaîne ce remplacement et non pas comme référence à une capture nommée, vous devez échapper le signe dollar ainsi '$$1'.


    - un Scriptblock, implicitement de type \[System.Text.RegularExpressions.MatchEvaluator\] :

        #Remplace le caractère ':' par '\<:\>'

      $h.":"={"\<$($args\[0\])\>"}


      Dans ce cas, pour chaque occurrence de remplacement trouvée, on évalue le remplacement en exécutant le Scriptblock qui reçoit dans $args\[0\] l'occurence trouvée et renvoie comme résultat une chaîne de caractères.

      Les conversions de chaînes de caractères en dates, contenues dans le scriptblock, se font en utilisant les informations de la classe .NET InvariantCulture (US).


      Note :


      En cas d'exception déclenchée dans le scriptblock, n'hésitez pas à consulter le contenu de son membre nommé  InnerException.

      ATTENTION : Les scriptblock sont éxécutés dans la portée où ils sont déclarés


    * une hashtable, les clés reconnues sont :

       - Replace

       Contient la valeur de remplacement.

       Une chaîne vide est autorisée, mais pas la valeur $null.

       Cette clé est obligatoire.

       Son type est \[String\] ou \[ScriptBlock\].


       - Max

        Nombre maximal de fois où le remplacement aura lieu.

        Sa valeur par défaut est -1 (on remplace toutes les occurrences trouvées) et ne doit pas être inférieure à -1.

        Pour une valeur $null ou une chaîne vide on affecte la valeur par défaut.



        Cette clé est optionnelle et s'applique uniquement aux expressions régulières.

        Son type est \[Integer\], sinon une tentative de conversion est effectuée.


       - StartAt

        Position du caractère, dans la chaîne d'entrée, où la recherche débutera.

        Sa valeur par défaut est zéro (début de chaîne) et doit être supérieure à zéro.

        Pour une valeur $null ou une chaîne vide on affecte la valeur par défaut.


        Cette clé est optionnelle et s'applique uniquement aux expressions régulières.

        Son type est \[Integer\], sinon une tentative de conversion est effectuée.


       - Options

        L'expression régulière est créée avec les options spécifiées.

        Sa valeur par défaut est "IgnoreCase" (la correspondance ne respecte pas la casse).

        Si vous spécifiez cette clé, l'option "IgnoreCase" est écrasée par la nouvelle valeur.

        Pour une valeur $null ou une chaîne vide on affecte la valeur par défaut.

        Peut contenir une valeur de type \[Object\], dans ce cas l'objet sera converti en \[String\].

        Si la variable $OFS est déclarée elle sera utilisée lors de cette conversion.


        Cette clé est optionnelle et s'applique uniquement aux expressions régulières.

        Son type est \[System.Text.RegularExpressions.RegexOptions\].


        Note:

        En lieu et place de cette clé/valeur, il est possible d'utiliser une construction d'options inline dans le corps de l'expression régulière (voir un des exemples).

       Ces options inlines sont prioritaires et complémentaires par rapport à celles définies par cette clé.


     Si la hashtable ne contient pas de clé nommée 'Replace', la fonction émet une erreur non-bloquante.

     Si une des clés 'Max','StartAt' et 'Options' est absente, elle est insérée avec sa valeur par défaut.

     La présence de noms de clés inconnues ne provoque pas d'erreur.


     Rappel : Les règles de conversion de .NET s'appliquent.

     Par exemple pour :

      \[double\] $Start=1,6

      $h."a"=@{Replace="X";StartAt=$Start}

     où $Start contient une valeur de type \[Double\], celle-ci sera arrondie, ici à 2.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases: 

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SimpleReplace
Utilise une correspondance simple plutôt qu'une correspondance d'expression régulière.

La recherche et le remplacement utilisent la méthode String.Replace() en lieu et place d'une expression régulière.

ATTENTION cette dernière méthode effectue une recherche de mots en respectant la casse et tenant compte de la culture.


L'usage de ce switch ne permet pas d'utiliser toutes les fonctionnalités du paramètre -Setting, ex :

 @{Replace="X";Max=n;StartAt=n;Options="Compiled"}

Si vous couplez ce paramètre avec ce type de hashtable, seule la clé 'Replace' sera prise en compte.


Un avertissement est généré, pour l'éviter utiliser le paramétrage suivant :

 -WarningAction:SilentlyContinue #bug en v2

 ou

 $WarningPreference="SilentlyContinue"

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

### -Unique
Pas de recherche/remplacement multiple.


L'exécution ne concerne qu'une seule opération de recherche et de remplacement, la première qui réussit, même si le paramètre -Setting contient plusieurs entrées.

Si le paramètre -Property est précisé, l'opération unique se fera sur toutes les propriétés indiquées.

Ce paramètre ne remplace pas l'information précisée par la clé 'Max'.


Note : La présence du switch -Whatif influence le comportement du switch

* -Unique.

Puisque -Whatif n'effectue aucun traitement, on ne peut pas savoir si un remplacement a eu lieu, dans ce cas le traitement de toutes les clés sera simulé.

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

### -WhatIf
Shows what would happen if the cmdlet runs.

The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject
 Vous pouvez diriger tout objet ayant une méthode ToString vers Edit-String.

## OUTPUTS

### System.String
System.Object
System.PSReplaceInfo

 Edit-String retourne tous les objets qu'il soient modifiés ou pas.

## NOTES
Options des expressions régulières  :

 http://msdn.microsoft.com/fr-fr/library/yd1hzczs(v=VS.80).aspx
 http://msdn.microsoft.com/fr-fr/library/yd1hzczs(v=VS.100).aspx


Éléments du langage des expressions régulières :

 http://msdn.microsoft.com/fr-fr/library/az24scfc(v=VS.80).aspx


Compilation et réutilisation de regex :

 http://msdn.microsoft.com/fr-fr/library/8zbs0h2f(vs.80).aspx



Au coeur des dictionnaires en .Net 2.0 :

 http://mehdi-fekih.developpez.com/articles/dotnet/dictionnaires


Outil de création d'expression régulière, info et Tips
pour PowerShell :

 http://powershell-scripting.com/index.php?option=com_joomlaboard&Itemid=76&func=view&catid=4&id=3731



Il est possible d'utiliser la librairie de regex du projet PSCX :

 "un deux deux trois"|Edit-String @{$PSCX:RegexLib.RepeatedWord="Deux"}

 #renvoi
 #un deux trois

## RELATED LINKS

