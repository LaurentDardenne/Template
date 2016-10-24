if(! (Test-Path variable:TemplateVcs))
{ throw "The project configuration is required, see the 'Template_ProjectProfile.ps1' script." }

$ModuleVersion=(Import-ManifestData "$TemplateVcs\Modules\Template\Template.psd1").ModuleVersion

$Result=nuspec 'Template' $ModuleVersion {
   properties @{
        Authors='Dardenne Laurent'
        Owners='Dardenne Laurent'
        Description='PSScriptAnalyzer rules to validate the param block of a function.'
        title='Template module'
        summary='PSScriptAnalyzer rules to validate the param block of a function.'
        copyright='Copyleft'
        language='fr-FR'
        licenseUrl='https://creativecommons.org/licenses/by-nc-sa/4.0/'
        projectUrl='https://github.com/LaurentDardenne/Template'
        #iconUrl='https://github.com/LaurentDardenne/Template/blob/master/icon/Template.png'
#todo
        releaseNotes="$(Get-Content "$TemplateVcs\Modules\Template\CHANGELOG.md" -raw)"
        tags='Template'
   }

   dependencies {
        dependency Log4Posh 2.0.0
   }

   files {
        file -src "$TemplateVcs\Modules\Template\Template.psd1"
        file -src "$TemplateVcs\Modules\Template\Template.psm1"
        #file -src "$TemplateVcs\Modules\Template\README.md"
        #file -src "$TemplateVcs\Modules\Template\releasenotes.md"
   }
}

$Result|
  Push-nupkg -Path $PSScriptAnalyzerRulesDelivery -Source 'https://www.myget.org/F/ottomatt/api/v2/package'

