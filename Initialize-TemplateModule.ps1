﻿
 # Default settings for Edit-String
$TemplateDefaultSettings=@{}

 #Substitute a token by the variable content :
 # <%=$VariableName%> or <%=${VariableName}%>
$TemplateDefaultSettings.'(?ims)(<%=)(.*?)(%>)'= {
  param($match)
    $expr = $match.groups[2].value
    $ExecutionContext.InvokeCommand.ExpandString($Expr)
}

 #Invoke a scriptblock, then emit its result into the pipeline
 #  #<#%ScriptBlock%
 #    Write-Output "#Lines generated by Edit-String"
 #    FunctionToGenerateStringLines
 #  #>
$TemplateDefaultSettings.'(?ism)<#%(ScriptBlock|SB)%(?<Code>.*)#>'= {
  param($match)
    $expr = $match.groups[2].value
    write-Debug "%ScriptBlock% match :`r`n $Expr"

     $Result=$Expr.Split(@("`t",' ',"`r","`n"),[System.StringSplitOptions]::RemoveEmptyEntries)
     if ($Result.Count -eq 0)
     { Write-Error 'No line of code in the scriptblock directive [$($match.Index)]'}
     else
     {
         write-Debug "Invoke code"
         $ExecutionContext.InvokeCommand.InvokeScript($Expr)
     }
}

