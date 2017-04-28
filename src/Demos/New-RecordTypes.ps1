Function New-ClassDefinition{
#create definitions
# $T=@(
#  New-ClassDefinition -ClassName 'MyClass' -Header 'string Name, string EMail, int MBSize'
#  New-ClassDefinition -ClassName 'DiskReport' -Header 'String HostName, string Letter, int Size'
#  New-ClassDefinition -ClassName 'ClassDefinition' -Header 'string Name, string Header'
# )
# $ofs=$null
# $T|New-RecordType
   param(
       [Parameter(Mandatory=$True,position=0)]
      $ClassName,
       [Parameter(Mandatory=$True,position=1)]
      $Header
   )

  [pscustomobject]@{
    PSTypeName='ClassDefinition';
    ClassName=$ClassName;
    Header=$Header;
   }
}# New-ClassDefinition

Function New-RecordType{
 #create a basic class
 #New-RecordType -ClassName 'MyClass' -Header 'string Name, string EMail, int MBSize'
  param(
           [Parameter(Mandatory=$True,position=0,ValueFromPipelineByPropertyName)]
           [ValidateNotNullOrEmpty()]
          [string]$ClassName,

           [Parameter(Mandatory=$True,position=1,ValueFromPipelineByPropertyName)]
           [ValidateNotNullOrEmpty()]
          [string]$Header
  )
 begin {
  function New-ToStringMethod {
   param ($Properties)
 $ofs=' + " " + $this.'
 $line=$Properties|Select-Object -ExpandProperty Name
@"

`t[string] ToString()
`t{
`t  return `$this.$Line
`t}
"@
 }
  function NewClassDefinition {
    $Members=New-Object System.Collections.ArrayList 5
    $Definition -split ',' |
     foreach-object {
       $Type,$Name = $_.Trim() -split '\s+'
       if ([string]::IsNullOrEmpty($Type))
       {
         Throw "The content of the Header parameter is wrong for the string '$_'. It must be 'TypeName Name , TypeName Name'."
         $Type=$Type.Trim()
       }
       if ([string]::IsNullOrEmpty($Name))
       {
         Throw "The content of the Header parameter is wrong for the string '$_'. It must be 'TypeName Name, TypeName Name'."
         $Name=$Name.Trim()
       }

       $CP=[pscustomobject]@{
          PSTypeName='ClassParameter';
          Type=$Type;
          Name=$Name;
       }
       $Members.Add( $CP ) > $null
     }
    $Properties=$Members| Foreach-Object { "[{0}] `${1}" -F $_.Type,$_.Name }
    "Class $ClassName {"

    $oldofs,$ofs=$ofs,";`r`n`t"
    "`t$Properties"

    $ofs=", "
    "`r`n`t$ClassName($Properties){"
    $Members| Foreach-Object { "`t`t`$this.{0} = `${0};" -F $_.Name }
    "`t}"

    New-ToStringMethod -Properties $members

    "`r`n} #$ClassName"
     #todo ps v6-7 ? Accesssors 'public [$Type] $Name  {get{ return $this.$Name;}}'
   $ofs=$oldofs
  }#NewClassDefinition
 }
 process {
  $Definition=$Header.Trim()
  if ($Definition -ne [string]::Empty)
  {
    $ClassDef=NewClassDefinition
    $Code=$ClassDef|Out-string
    Write-Debug ($Code)
    if ($PSVersionTable.PSVersion -ge ([Version]'5.0') )
    {
        try {
           #Analyze the code before emit it
          [scriptblock]::create($Code)
          $ClassDef
        }
        catch {
            #The class name can be erronous
          throw $_.Exception.InnerException
        }
   }
   else
   {write-verbose "Unable to validate the class definition. Require Powershell version 5.0 or superior."}
  }
  else
  { Throw "The content of the Header is empty or contains only spaces." }
 }
}

return
#Exemple
$ClassDef=New-RecordType -ClassName 'MyClass' -Header 'string Name, string EMail, int MBSize'
# Class MyClass {
#         [string] $Nom;
#         [string] $EMail;
#         [int] $MBSize

#         MyClass([string] $Nom, [string] $EMail, [int] $MBSize){
#                 $this.Nom = $Nom;
#                 $this.EMail = $EMail;
#                 $this.MBSize = $MBSize;
#         }
# } #MyClass

Invoke-Expression ($ClassDef|out-string)
[MyClass]::new('Name','Name@Org.com', 150)
# Nom  EMail        MBSize
# ---  -----        ------
# Name Name@Org.com    150
