Function Get-InterfaceSignature{
#Transforms the signatures of the members of an interface
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
  $isContainsEvent=@($Members|Where-Object {$_.MemberType -eq 'Event'}|Select-Object -First 1).Count -ne 0

  if ((-not $isContainsEvent))
  {
   $Members=$Members|Group-object MemberType -AsHashTable -AsString
   $Script=New-Object System.Text.StringBuilder "`r`n# $TypeName`r`n"

    #Find indexed properties
   $PropertiesGroup=$Members.Property|Group-Object Name
    Foreach ($Property in $PropertiesGroup.Group){
       $Indexers=$Property.GetIndexParameters()
       if ($Indexers.Count -gt 0)
       {
         #Note: une classe VB.Net peut avoir + indexers via des propriétés
         #  test  'System.Collections.IList'
            $Script.AppendLine(@"
  #Todo Decorate the class definition with the following line :
  [System.Reflection.DefaultMember('$($Property.Name)')]
"@ ) >$null
         Break
       }
    }

   Foreach ($Property in $Members.Property){
    Write-debug "Add property : $($Property.Name)"
    $Script.AppendLine( ("`t[{0}] `${1}" -F $Property.PropertyType, $Property.Name) ) >$null
   }

   Foreach($Method in $Members.Method){
      $oldOfs,$Ofs=$ofs,",`r`n"
      Write-Debug "Method name : $($Method.Name)"
      if ($Method.Name -match '^(?<Accessor>G|S)et_(?<Name>.*$)')
      {
        if ($Matches.Accessor -eq 'G')
        { $Body="`t  return `$this.{0}" -F $Matches.Name }
        else
        { $Body="`t  `$this.{0} = `${1}" -F $Matches.Name,($Method.GetParameters())[0].Name }
      }
      else
      { $Body="`t  throw 'Not implemented'" }

      $Parameters= Foreach ($Parameter in $Method.GetParameters())
        {
           Write-debug "Add parameter method : $($Parameter.Name)"
           "`t`t[{0}] `${1}" -f $Parameter.ParameterType,$Parameter.Name
        }
      if ($Parameters.Count -ne 0)
      {
        $Script.AppendLine( ("`r`n`t[{0}] {1}(`r`n$Parameters){{`r`n$Body`r`n`t}}`r`n" -f $Method.ReturnType,$Method.Name) ) >$null
      }
      else
      { $Script.AppendLine( ("`r`n`t[{0}] {1}(){{`r`n$Body`r`n`t}}`r`n" -f $Method.ReturnType,$Method.Name) ) >$null }
   }
   Write-Output $Script.ToString()
  }
  Else
  { Write-Error "The interface [$Type] contains one or more events. Its implementation is impossible with Powershell." }
 }
} #Get-InterfaceSignature


Add-Type -TypeDefinition @'
 public interface Interface2 {
  bool Property { get;set; }
  bool Method();
 }
'@
Get-InterfaceSignature Interface2
## Interface2
#         [System.Boolean] $Property
#
#         [System.Boolean] get_Property(){
#           return $this.Property
#         }
#
#
#         [System.Void] set_Property(
#                 [System.Boolean] $value){
#           $this.Property = $value
#         }
#
#
#         [System.Boolean] Method(){
#           throw 'Not implemented'
#         }

#Todo
# [System.Int32] $Item -> [System.Int32[]] $Item
#setter/gettter
# $this.Item = $index -> $this[$Index].Item = $value
Add-Type -TypeDefinition @'
public interface ISomeInterface
{
  // Indexer declaration:
  int this[int index]
  {
      get;
      set;
  }

  string this[string name]
  {
      get;
      set;
  }
}
'@
Get-InterfaceSignature ISomeInterface
#Todo : http://netcode.ru/dotnet/?lang=&katID=30&skatID=261&artID=6977
