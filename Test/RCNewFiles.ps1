$PathSource="$Env:Temp\RC"
Write-Host "Create files test" -fore green
if (Test-Path $PathSource)  
{ 
  Write-Host "Remove old files test" -fore green
  Remove-Item $PathSource -rec -force 
}
new-item $PathSource -ItemType Directory > $null 

@'
#<%UNCOMMENT%>[FunctionalType('PathFile')]
# Test principe de base
#<DEFINE %A%>
Write-Debug "A"
#<UNDEF %A%>
Write-Debug 'Test'#<%REMOVE%>
Write-Debug "Suite hors define"
#<INCLUDE %'Z:\FileInclude.ps1'%>
'@ | Set-Content -Path "$PathSource\Test0-1.ps1" -Force -Encoding UTF8 -verbose

@'
#[FunctionalType('PathFile')]
# Test principe de base
Write-Debug "A"
Write-Debug 'Test'
Write-Debug "Suite hors define"
'@ | Set-Content -Path "$PathSource\Test0-1.new.ps1" -Force -Encoding UTF8

@'
# Test principe de base
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %B%>
Write-Debug "B"
#<DEFINE %C%>
Write-Debug "C"
#<UNDEF %C%>
Write-Debug "suite B"
#<UNDEF %B%>
Write-Debug "suite A"
#<UNDEF %A%>
Write-Debug "Suite hors define"
'@ | Set-Content -Path "$PathSource\Test0.ps1" -Force -Encoding UTF8

@'
# Test principe de base
Write-Debug "A"
Write-Debug "B"
Write-Debug "C"
Write-Debug "suite B"
Write-Debug "suite A"
Write-Debug "Suite hors define"
'@ | Set-Content -Path "$PathSource\Test0.new.ps1" -Force -Encoding UTF8

@'
# Test -Remove
Write-Debug 'Test' #<%REMOVE%>
Write-Debug "Suite"
'@ | Set-Content -Path "$PathSource\Test0-2.ps1" -Force -Encoding UTF8

@'
# Test -Remove
Write-Debug "Suite"
'@ | Set-Content -Path "$PathSource\Test0-2.new.ps1" -Force -Encoding UTF8

@'
# Test principe de base
Write-Debug "A"
Write-Debug "B"
Write-Debug "suite B"
Write-Debug "suite A"
Write-Debug "Suite hors define"
'@ | Set-Content -Path "$PathSource\Test0.newC.ps1" -Force -Encoding UTF8      

@'
# Test principe de base
Write-Debug "A"
Write-Debug "suite A"
Write-Debug "Suite hors define"
'@ | Set-Content -Path "$PathSource\Test0.newB.ps1" -Force -Encoding UTF8      


@'
# Test principe de base
Write-Debug "Suite hors define"
'@ | Set-Content -Path "$PathSource\Test0.newA.ps1" -Force -Encoding UTF8      

@'
# Test imbrication DEFINE erronée
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %C%>
Write-Debug "B"
#<DEFINE %B%>
Write-Debug "C"
#<UNDEF %C%>
Write-Debug "suite B"
#<UNDEF %B%>
Write-Debug "suite A"
#<UNDEF %A%>
Write-Debug "Suite hors define"
'@ > "$PathSource\Test01.ps1"


@'
# Test imbrication UNDEF erronée
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %B%>
Write-Debug "B"
#<DEFINE %C%>
Write-Debug "C"
#<UNDEF %B%>
Write-Debug "suite B"
#<UNDEF %C%>
Write-Debug "suite A"
#<UNDEF %A%>  
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test02.ps1"

@'
# Test directive DEFINE seule
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %B%>
Write-Debug "B"
Write-Debug "suite B"
Write-Debug "suite A"
#<UNDEF %A%>  
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test03.ps1"

@'
# Test directive DEFINE seule, pas imbriqué
#<DEFINE %A%>
Write-Debug "A"
Write-Debug "suite A"
#<UNDEF %A%>
#<DEFINE %B%>
Write-Debug "B"
Write-Debug "suite B"
  
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test031.ps1"

@'
# Test directive UNDEF seule
#<DEFINE %A%>
Write-Debug "A"
Write-Debug "B"
Write-Debug "suite B"
#<UNDEF %B%>
Write-Debug "suite A"
#<UNDEF %A%>  
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test04.ps1"

@'
# Test directive UNDEF seule, pas imbriqué
#<DEFINE %A%>
Write-Debug "A"
Write-Debug "suite A"
#<UNDEF %A%>
Write-Debug "B"
Write-Debug "suite B"
#<UNDEF %B%>
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test041.ps1"

@'
# Test directive UNDEF manquante
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %B%>
Write-Debug "B"
#<DEFINE %C%>
Write-Debug "C"
#<UNDEF %C%>
Write-Debug "suite B"
#<UNDEF %B%>
Write-Debug "suite A"
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test05.ps1"

@'
# Test directive UNDEF manquante
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %B%>
Write-Debug "B"
#<DEFINE %C%>
Write-Debug "C"
Write-Debug "suite B"
Write-Debug "suite A"
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test06.ps1"

@'
# Test directive UNDEF manquante
Write-Debug "A"
#<UNDEF %A%>
Write-Debug "B"
#<UNDEF %B%>
Write-Debug "C"
#<UNDEF %C%>
Write-Debug "suite B"
Write-Debug "suite A"
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test07.ps1"

@'
# Test directive UNDEF manquante
#<DEFINE %X%>
Write-Debug "A"
#<DEFINE %Y%>
Write-Debug "B"
#<DEFINE %Z%>
Write-Debug "A"
#<UNDEF %A%>
Write-Debug "B"
#<UNDEF %B%>
Write-Debug "C"
#<UNDEF %C%>
Write-Debug "suite B"
Write-Debug "suite A"
Write-Debug "Suite hors define" 
'@ > "$PathSource\Test08.ps1"

@'
# Inversion des directives DEFINE et UNDEF
Write-Debug "A"
#<UNDEF %A%>
Write-Debug "B"
#<UNDEF %B%>
Write-Debug "C"
#<UNDEF %C%>
Write-Debug "suite B"
Write-Debug "suite A"
#<DEFINE %A%>
Write-Debug "A"
#<DEFINE %B%>
Write-Debug "B"
#<DEFINE %C%>
Write-Debug "C"
Write-Debug "Suite hors define"
'@ > "$PathSource\Test09.ps1"

@'
    Write-Host "Insertion du contenus du fichier FileInclude.ps1"
'@ | Set-Content -Path "$PathSource\FileInclude.ps1" -Force -Encoding UTF8    

@"
       Write-Host 'Code avant'
       #<INCLUDE %'$PathSource\FileInclude.ps1'%>
       Write-Host 'Code aprés'
"@ | Set-Content -Path "$PathSource\TestInclude1.ps1" -Force -Encoding UTF8              

@'       
       Write-Host 'Code avant'
    Write-Host "Insertion du contenus du fichier FileInclude.ps1"
       Write-Host 'Code aprés'
'@ | Set-Content -Path "$PathSource\TestInclude1.new.ps1" -Force -Encoding UTF8


@"
       Write-Host 'Code avant'
       #<INCLUDE %'$PathSource\NotExist.ps1'%>
       Write-Host 'Code aprés'
"@ | Set-Content -Path "$PathSource\TestInclude2.ps1" -Force -Encoding UTF8              


@'
       Write-Host 'Code avant'
       #<INCLUDE %'Z:\FileInclude.ps1'%>
       Write-Host 'Code aprés'
'@ | Set-Content -Path "$PathSource\TestInclude3.ps1" -Force -Encoding UTF8              


@'
       #<%UNCOMMENT%>[FunctionalType('PathFile')]
       ...
       #<%UNCOMMENT%>Write-Debug 'Test'
'@ | Set-Content -Path "$PathSource\TestUNCOMMENT.ps1" -Force -Encoding UTF8

@'
       [FunctionalType('PathFile')]
       ...
       Write-Debug 'Test'
'@ | Set-Content -Path "$PathSource\TestUNCOMMENT.new.ps1" -Force -Encoding UTF8       

@'
#Test Imbrication de directive
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"
#<DEFINE %DEBUG%>
# Texte de la PREMIERE directive Debug
#<UNDEF %DEBUG%>
#<DEFINE %TEST%>
# Texte 1 de la directive TEST
#<DEFINE %DEBUG%>
# Texte de la SECONDE directive Debug
#<UNDEF %DEBUG%>
# Texte 2 de la directive TEST
#<UNDEF %TEST%>
} #test
'@ | Set-Content -Path "$PathSource\Combination1.ps1" -Force -Encoding UTF8  

@'
#Test Imbrication de directive
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"
# Texte de la PREMIERE directive Debug
# Texte 1 de la directive TEST
# Texte de la SECONDE directive Debug
# Texte 2 de la directive TEST
} #test
'@ | Set-Content -Path "$PathSource\Combination1-Clean.ps1" -Force -Encoding UTF8  

@'
#Test Imbrication de directive
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"
#<DEFINE %TEST%>
# Texte 1 de la directive TEST
# Texte 2 de la directive TEST
#<UNDEF %TEST%>
} #test
'@ | Set-Content -Path "$PathSource\Combination1-Debug.ps1" -Force -Encoding UTF8

@'
#Test Imbrication de directive
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"
#<DEFINE %DEBUG%>
# Texte de la PREMIERE directive Debug
#<UNDEF %DEBUG%>
} #test
'@ | Set-Content -Path "$PathSource\Combination1-Test.ps1" -Force -Encoding UTF8

@'
#Test Imbrication de directive
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"
} #test
'@ | Set-Content -Path "$PathSource\Combination1-Debug+Test.ps1" -Force -Encoding UTF8

#todo : est gérée
@'
#Test erreur : Une directive sans mot clé de fin
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"

Write-Debug "$TempFile"
Write-Debug "$FullPath" 
#<UNDEF %DEBUG%>   
} #test
'@ | Set-Content -Path "$PathSource\UndefOrphan.ps1" -Force -Encoding UTF8

#todo : est gérée
@'
#Test erreur : deux directives. La première directive Debug est associè à la seconde directive Debug.
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"

#<DEFINE %DEBUG%>
Write-Debug "$TempFile"
Write-Debug "$FullPath" 
#<UN DEF %DEBUG%>    

#Imbrication de directive
#<DEFINE %TEST%>     
Set-Location C:\Temp
#<DE FINE %DEBUG%>
  Write-Debug "bug"
#<UNDEF %DEBUG%>     
"Remove-Conditionnal.ps1"|Remove-Conditionnal  "TEST"
#<UNDEF %TEST%>   
 
#<DEFINE %DEBUG%>
  Write-Debug "Fin"
#<UNDEF %DEBUG%>     
   
} #test
'@ > "$PathSource\Bug3.ps1"

#todo : est gérée
@'
#Test erreur : deux directives. La première directive Debug est associè à la seconde directive Debug.
Filter Test {
param (
    [String]$ConditionnalsKeyWord
)
Write-Host "Code de la fonction"

#<DEFINE %DEBUG%>
Write-Debug "$TempFile"
Write-Debug "$FullPath" 
#<UNDEF %DEBUG%>    

#Imbrication de directive
#<DEFINE %TEST%>     
Set-Location C:\Temp
#<DEFINE %DEBUG%>
  Write-Debug "bug"
#<UNDEF %DEBUG%>     
"Remove-Conditionnal.ps1"|Remove-Conditionnal  "TEST"
#<UNDEF %TEST%>   
 
#<DEFINE %DEBUG%>
  Write-Debug "Fin"
#<UNDEF %DEBUG%>     
   
} #test
'@ > "$PathSource\Bug4.ps1"
