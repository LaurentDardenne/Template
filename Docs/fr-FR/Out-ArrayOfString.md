---
external help file: Template-help.xml
online version: 
schema: 2.0.0
---

# Out-ArrayOfString

## SYNOPSIS
Ce filtre scinde une chaine de caractères contenant des retour chariot et ou des 'line feed' en un tableau de chaîne de caractères.

## SYNTAX

```
Out-ArrayOfString [<CommonParameters>]
```

## DESCRIPTION
Ce filtre scinde une chaîne de caractères contenant des retour chariot et ou des 'line feed' en un tableau de chaîne de caractères.
On ne peut utiliser ce traitement qu'avec le pipeline.

## EXAMPLES

### Example 1
```
PS C:\> $S=@"
Première ligne
Seconde ligne
troisieme ligne

Cinquiéme ligne
"@

$T=$S|Out-ArrayOfString
$T.Count
#5
```

La chaîne de caractères contenue dans la variable $S est transformée en un tableau contenant 5 chaînes de caractères.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

