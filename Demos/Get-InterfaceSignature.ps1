Function Get-InterfaceSignature{
#Affiche les signatures des membres d'une interface
 param (
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
  [string] $TypeName
 )

 process {
  Write-debug "Typename : $TypeName"

  [System.Type]$Type=$null
  if (-not [System.Management.Automation.LanguagePrimitives]::TryConvertTo($TypeName,[Type],[ref] $Type))
  {
    $Exception=New-Object System.ArgumentException('Le type est inconnu.','TypeName')
    Write-Error -Exception $Exception
    return
  }
  if (-not $Type.isInterface)
  {
    Write-Warning "Le type $Type n'est pas une interface."
    return
  }
  $Members=$Type.GetMembers()
  $isContainsEvent=@($Members|Where {$_.membertype -eq 'Event'}|Select -First 1).Count -ne 0

  if ((-not $isContainsEvent))
  {
    #Pour les propriétées d'interfaces,
    #les méthodes suffisent à l'implémentation de la propriété
    #todo setter R/O
   $Members=$Members|Group-object MemberType -AsHashTable -AsString
   $body="`tthrow 'Not implemented'"
    #Recherche les propriété indexées
   Foreach($PropertiesGroup in $Members.Property|Group Name){
    Foreach($Property in $PropertiesGroup.Group){
       $Indexers=$Property.GetIndexParameters()
       $isIndexers=$Indexers.Count -gt 0
       if ($isIndexers)
       {
          #todo Decorate the class definition
         Write-Output "#TODO [System.Reflection.DefaultMember('$($Property.Name)')]"
         #Note: une classe VB.Net peut avoir + indexers via des propriétés
         #  test  'System.Collections.IList'
         Break
       }
    }
   }
   Write-Output "`r`n `r`n   # $TypeName`r`n"
   Foreach($Method in $Members.Method){
      $Ofs=",`r`n"
      $Parameters="$(
         Foreach ($Parameter in $Method.GetParameters())
         {
            Write-Output ('[{0}] ${1}' -f $Parameter.ParameterType,$Parameter.Name)
         }
      )"

      Write-Output ("[{0}] {1}($Parameters){{`r`n$Body`r`n}}`r`n`r`n" -f $Method.ReturnType,$Method.Name)
   }
  }
  Else
  {
   Write-Error "L’interface [$Type] contient un ou des événement. Son implémentation est impossible sous Powershell."
  }
 }
} #Get-InterfaceSignature