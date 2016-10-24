Param (
 # Specific to the development computer
 [string] $VcsPathRepository='' #"G:\PS\Plaster\TestProject\Out\Create"
) 

if (Test-Path env:APPVEYOR_BUILD_FOLDER)
{
  $VcsPathRepository=$env:APPVEYOR_BUILD_FOLDER
}

if (!(Test-Path $VcsPathRepository))
{
  Throw 'Configuration error, the variable $VcsPathRepository should be configured.'
}

# Common variable for development computers
if ( $null -eq [System.Environment]::GetEnvironmentVariable('ProfileTemplate','User'))
{ 
 [Environment]::SetEnvironmentVariable('ProfileTemplate',$VcsPathRepository, 'User')
  #refresh the Powershell environment provider
 $env:ProfileTemplate=$VcsPathRepository 
}

 # Specifics variables  to the development computer
$TemplateDelivery= "${env:Temp}\Delivery\Template"   
$TemplateLogs= "{$env:Temp}\Logs\Template" 
$TemplateDelivery, $TemplateLogs|
 Foreach-Object {
  new-item $_ -ItemType Directory -EA SilentlyContinue         
 }

 # Commons variable for all development computers
 # Their content is specific to the development computer 
$TemplateBin= "$VcsPathRepository\Bin"
$TemplateHelp= "$VcsPathRepository\Documentation\Helps"
$TemplateSetup= "$VcsPathRepository\Setup"
$TemplateVcs= "$VcsPathRepository"
$TemplateTests= "$VcsPathRepository\Tests"
$TemplateTools= "$VcsPathRepository\Tools"
$TemplateUrl='https://github.com/LaurentDardenne/Template' 

 #PSDrive to the project directory 
$null=New-PsDrive -Scope Global -Name Template -PSProvider FileSystem -Root $TemplateVcs 

Write-Host 'Settings of the variables of Template project.' -Fore Green

rv VcsPathRepository

