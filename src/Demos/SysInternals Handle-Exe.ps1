#powershell version >= 3.0 

Ipmo Template

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
  [System.Management.Automation.PSSerializer]::Serialize($ObjectProperties)
}

#Case of the lines coming from handle.exe which are not used for this processing, 
# one emits an empty string
$h.'^.*$'={}  

#Nthandle v4.1 - Handle viewer
$o=&"C:\Tools\sysinternal\Handle\handle.exe"|
    Edit-String $h -unique|
    Where {$_ -ne [string]::Empty}|
    Foreach {
     $hashtable=[System.Management.Automation.PSSerializer]::Deserialize($_)
     New-Object PSObject -Property $hashtable
    }

$ProgramWithTheMostOpenFiles=$o|Group-Object program|Sort-Object count|Select-Object -last 1
$ProgramWithTheMostOpenFiles.Name
$ProgramWithTheMostOpenFiles.Group|Select-Object path -unique|Sort-Object path

#Files opened by Powershell
($o|Group-Object program|Where-Object {$_.name -eq "Powershell.exe"}).Group|Select-Object path -unique|Sort-object path
