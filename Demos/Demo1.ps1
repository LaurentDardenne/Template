
Import-Module Template

$File='C:\temp\Code.T.PS1'
@'
Write 'avant'
<#%ScriptBlock%
    #<DEFINE %V5%>
        . C:\Tools\Tutoriel-DVP\LesClassesPsV5\Convert-ObjectToClass.ps1
        #Classe PS >= v5
        Convert-ObjectToClass -InputObject (Get-Process|Select Name,VirtualMemorySize -First 1)
    #<UNDEF %V5%>

    #<DEFINE %V3%>
        . C:\Users\Laurent\Documents\WindowsPowerShell\Scripts\New-PSCustomObjectFunctionV3.ps1
        #PSCustomObject >= v3
        New-PSCustomObjectFunction -Noun ProcessLight -Parameters Name,VirtualMemorySize -File
    #<UNDEF %V3%>
#>
Write 'après'
'@ > $File

#Hastable de paramètrage pour la fonction Edit-String
$h=@{}
$h.'(?ism)<#%(ScriptBlock|SB)%(?<Code>.*)#>'= {
    param($match)
    $expr = $match.groups[2].value
     write-warning "match : $expr"

     $Result=$Expr.Split(@("`t",' ',"`r","`n"),[System.StringSplitOptions]::RemoveEmptyEntries)
     if ($Result.Count -eq 0)
     { Write-Error 'Aucune ligne de code dans la directive Scriptblock (todo line number)'}
     else
     {
         write-warning "Invoke code"
         $ExecutionContext.InvokeCommand.InvokeScript($Expr)
     }
}

#génération de code pour PS v3
#Edit-Template attend un tableau de chaînes
[string[]]$Lines=Get-Content -Path $File  -ReadCount 0 -Encoding UTF8
 #On itère pas les obets du tableau, on passe un objet: le tableau en entier
$Result=,$Lines|Edit-Template -ConditionnalsKeyWord  "V5"|
 Edit-Template -Clean

#Attend une string:transforme un tableau en une string
$ofs="`r`n"
"$Result"|
 Edit-String -Hashtable $h

#génération de code pour PS v5
Get-Content -Path $File  -ReadCount 0 -Encoding UTF8|
 Edit-Template -ConditionnalsKeyWord  "V3"|
 Edit-Template -Clean|
 Out-string| #Transforme toutes les ignes reçues en une chaine de caractères
 Edit-String -Hashtable $h

${T4_Name}='Génération de texte à base de modèle'
$h=@{}
$h.'(?ims)(<%=)(.*?)(%>)'= {
    param($match)
    $expr = $match.groups[2].value
    $ExecutionContext.InvokeCommand.ExpandString($Expr)
}

$S=@'
 #comment
Write-host "Projet : <%=${T4_Name}%>"
'@
$S| Edit-String -Hashtable $h

#Note:
    #La chaîne $S référence un nom de variable
    #Le scriptblock associé à la regex est déclaré dans la portée de l'appelant (ce script)
    #La fonction Edit-String exécute, dans la portée de son module, le scriptblock en tant que
    # délégué d'une regex.
    #En interne Powershell exécute le scriptblock dans la portée où il a été déclaré.
    #Donc ici pas de problème de portée !
#todo a tester