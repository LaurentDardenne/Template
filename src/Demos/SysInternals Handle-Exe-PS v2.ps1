#powershell version 2.0

function ConvertFrom-CliXml {
# http://poshcode.org/4545
# by Joel Bennett, modification David Sjstrand, Poshoholic
  param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [String[]]$InputObject
  )
  begin
  {
      function TruncateString{
       param($Object,[int]$SizeMax=512)
        $Msg= $Object.ToString()
        $Msg.Substring(0,([Math]::Min(($Msg.Length),$Sizemax)))
      }#TruncateString
      
      $OFS = "`n"
      [String]$xmlString = ""
  }
  process
  {
      $xmlString += $InputObject
  }
  end
  {
    try {
      $type = [PSObject].Assembly.GetType('System.Management.Automation.Deserializer')
      $ctor = $type.GetConstructor('instance,nonpublic', $null, @([xml.xmlreader]), $null)
      $sr = New-Object System.IO.StringReader $xmlString
      $xr = New-Object System.Xml.XmlTextReader $sr
      $deserializer = $ctor.Invoke($xr)
      $done = $type.GetMethod('Done', [System.Reflection.BindingFlags]'nonpublic,instance')
      while (!$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $deserializer, @()))
      {
          try {
              $type.InvokeMember("Deserialize", "InvokeMethod,NonPublic,Instance", $null, $deserializer, @())
          } catch {
              #bug fix : 
              # En cas d'exception, la version d'origine boucle en continue, 
              #car dans ce cas 'Done' ne sera jamais à $true
              Write-Error "Could not deserialize '$(TruncateString $xmlstring)' : $_"  
              break 
          }
      }
    } 
    catch [System.Xml.XmlException]{
      Write-Error "Could not contruct xmlreader with this object  '$(TruncateString $xmlstring)' : $_"  
    }
    Finally {
      $xr.Close()
      $sr.Dispose()
    }
  }
}#ConvertFrom-CliXml

function ConvertTo-CliXml {
#from http://poshcode.org/4544
#by Joel Bennett,modification Poshoholic
  param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]$InputObject
  )
  begin {
      $type = [PSObject].Assembly.GetType('System.Management.Automation.Serializer')
      $ctor = $type.GetConstructor('instance,nonpublic', $null, @([System.Xml.XmlWriter]), $null)
      $sw = New-Object System.IO.StringWriter
      $xw = New-Object System.Xml.XmlTextWriter $sw
      $serializer = $ctor.Invoke($xw)
  }
  process {
      try {
          [void]$type.InvokeMember("Serialize", "InvokeMethod,NonPublic,Instance", $null, $serializer, [object[]]@($InputObject))
      } catch {
          Write-Warning "Could not serialize $($InputObject.GetType()): $_"
      }
  }
  end {    
      [void]$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $serializer, @())
      $sw.ToString()
      $xw.Close()
      $sw.Dispose()
  }
}#ConvertTo-CliXml
Ipmo template


$h=new-object System.Collections.Specialized.OrderedDictionary
 #Build an object from lines emit by the handle.exe program

$h.'^(?<program>\S*)\s*pid: (?<pid>\d*)\s*(?<user>.*)$'={
 param ($Match)

  $Groups=$Match.Groups  
   
   #Scope Script: required for this eventhandler.
   #Line specifying the name of the program that has a handle on one or more files.
   #As long as we do not analyze a new line of this type, we reuse this information.                     
  $script:id = $Groups['pid'].Value            
  $script:program = $Groups['program'].Value            
  $script:user = $Groups['user'].Value            
}                        
$h.'^\s*(?<handle>[\da-z]*): File  \((?<attr>...)\)\s*(?<file>(\\\\)|([a-z]:).*)'={
 param ($Match) 
  #The eventhandler receives an object of type: System.Text.RegularExpressions.Match 
  #and returns a String

 $Groups=$Match.Groups  
 
 $ObjectProperties=@{
    "Pid"=$id 
    "Program"=$program 
    "User"=$user 
    "Handle"=$Groups['handle'].Value 
    "attr"=$Groups['attr'].Value 
    "Path"=$Groups['file'].Value
  }
 ConvertTo-CliXml -InputObject $ObjectProperties
}

#Case of the lines coming from handle.exe which are not used for this processing, 
# one emits an empty string
$h.'^.*$'={}  

#Nthandle v4.1 - Handle viewer
$o=&"C:\Tools\sysinternal\Handle\handle.exe"|
    Edit-String $h -unique|
    Where {$_ -ne [string]::Empty}|
    Foreach {
     $hashtable=ConvertFrom-CliXml -InputObject $_
     New-Object PSObject -Property $hashtable
    }

$ProgramWithTheMostOpenFiles=$o|Group-Object program|Sort-Object count|Select-Object -last 1
$ProgramWithTheMostOpenFiles.Name
$ProgramWithTheMostOpenFiles.Group|Select-Object path -unique|Sort-Object path

#Files opened by Powershell
($o|Group-Object program|Where-Object {$_.name -eq "Powershell.exe"}).Group|Select-Object path -unique|Sort-object path
