Function Get-InterfaceSignature{
#Affiche les signatures des membres d'une interface
 param (
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
  [string] $TypeName
 )

 process {
  Write-debug "TypeName : $TypeName"

  [System.Type]$Type=$null
  if (-not [System.Management.Automation.LanguagePrimitives]::TryConvertTo($TypeName,[Type],[ref] $Type))
  {
    $Exception=New-Object System.ArgumentException('Unknown type.','TypeName')
    Write-Error -Exception $Exception
    return
  }
  if (-not $Type.isInterface)
  {
    Write-Warning "The type $Type is not an interface."
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
   $body="`t  throw 'Not implemented'"
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
   [string]$Result=''
   Foreach($Method in $Members.Method){
      $oldOfs,$Ofs=$ofs,",`r`n"
      $Parameters= Foreach ($Parameter in $Method.GetParameters())
        {
          "`t`t[{0}] `${1}" -f $Parameter.ParameterType,$Parameter.Name
        }
      if ($Parameters.Count -ne 0)
      {
        $Ofs=$oldOfs
        $result +="`r`n`t[{0}] {1}(`r`n$Parameters){{`r`n$Body`r`n`t}}`r`n" -f $Method.ReturnType,$Method.Name
      }
      else
      { $result +="`r`n`t[{0}] {1}(){{`r`n$Body`r`n`t}}`r`n" -f $Method.ReturnType,$Method.Name }
   }
   [string]$Result="`r`n# $TypeName"+$Result
   Write-Output $Result
  }
  Else
  {
   Write-Error "The interface [$Type] contains one or more events. Its implementation is impossible with Powershell."
  }
 }
} #Get-InterfaceSignature