if(! (Test-Path variable:TemplateVcs))
{ throw "The project configuration is required, see the 'Template_ProjectProfile.ps1' script." }

$ModuleVersion=(Import-ManifestData "$TemplateVcs\Template.psd1").ModuleVersion

$Result=nuspec 'Template' $ModuleVersion {
   properties @{
        Authors='Dardenne Laurent'
        Owners='Dardenne Laurent'
        Description=@'
Code generation by using text templates. A template specifies a text template with placeholders for data to be extracted from models.

The 'Template' module offers these features:

    text replacement, simple or by regex or regex with MatchEvaluator (Scriptblock)
    file inclusion
    directive to run embedded scripts
    Conditionnal directive (#Define & #Undef)
    Removal and uncomment directive
'@
        title='Template module'
        summary='Code generation by using text templates.'
        copyright='Copyleft'
        language='fr-FR'
        licenseUrl='https://creativecommons.org/licenses/by-nc-sa/4.0/'
        projectUrl='https://github.com/LaurentDardenne/Template'
        #iconUrl='https://github.com/LaurentDardenne/Template/blob/master/icon/Template.png'
        releaseNotes="$(Get-Content "$TemplateVcs\CHANGELOG.md" -raw)"
        tags='Template Conditionnal Directive Regex'
   }

   dependencies {
        dependency Log4Posh 2.0.0
   }

   files {
        file -src "$TemplateVcs\Template.psd1"
        file -src "$TemplateVcs\Template.psm1"
        file -src "G:\PS\Template\Template.Resources.psd1"
        file -src "$TemplateVcs\Initialize-TemplateModule.ps1"
        file -src "$TemplateVcs\README.md"
        file -src "$TemplateVcs\Demos\" -target "Demos\"
   }
}

$Result|
  Push-nupkg -Path $TemplateDelivery -Source 'https://www.myget.org/F/ottomatt/api/v2/package'

