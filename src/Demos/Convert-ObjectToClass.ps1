function Convert-ObjectToClass{
#Adapted from: MSIgnite2016_PSV5Unplugged-Demo.ps1 ( Jeffrey Snover )

    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true)]
        $InputObject
    )

 function Get-ClassName {
   param()
    ($InputObject.pstypenames[0] -split '\.')[-1]
}

 function New-ClassName {
  param()
   $n=Get-ClassName
   "${n}Light"
 }

 function Get-TypeName {
  param()
   $InputObject.pstypenames[0] -Replace '^Selected\.',''
 }

 function New-MethodHeader {
  param()
   $type=Get-TypeName
   $n=Get-ClassName
   "`r`n`t$(New-ClassName)([${type}] `$$n) {`r`n"
 }

$ConstructorDef=[System.Collections.Arraylist]::new()
$ClassName=New-ClassName

@"
class $ClassName
{
$(
$Cname=Get-ClassName
foreach ($p in Get-Member -InputObject $InputObject -MemberType Properties |Sort-Object name)
{
    switch ($p.MemberType)
    {
        "NoteProperty" {
            $type = ($p.Definition -split " ")[0]
            if ($type -in "System.Management.Automation.PSCustomObject")
            {
                "`t[PSCustomObject] `$$($p.Name);`n"
            }else
            {
                "`t[$type] `$$($p.Name);`n"
            }
            $PName=$p.Name
            $ConstructorDef.Add("`t`t`$this.$Pname = `$$CName.$Pname`r`n") > $null
        }
    }
}#foreach
New-MethodHeader
$ConstructorDef
)
`t}
} #$ClassName
"@
}#Convert-ObjectToClass

# $C=Convert-ObjecttoClass -InputObject (Get-Process|Select Name,VirtualMemorySize -First 1)
# $C
# iex $C
# [ProcessLight]
# [Collections.Generic.List[ProcessLight]]$PL=[Collections.Generic.List[ProcessLight]]::new()
# $PL=Get-Process