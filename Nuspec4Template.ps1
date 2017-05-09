
$ModuleVersion=(Import-ManifestData "$PSScriptRoot\Release\Template\Template.psd1").ModuleVersion

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
        iconUrl='https://raw.githubusercontent.com/LaurentDardenne/Template/master/Assets/Template.png'
        releaseNotes="$(Get-Content "$PSScriptRoot\CHANGELOG.md" -raw)"
        tags='Template Conditionnal Directive Regex'
   }

   files {
        file -src "$PSScriptRoot\Release\Template\*"
   }
}

$Result|
  Push-nupkg -Path $TemplateDelivery -Source 'https://www.myget.org/F/ottomatt/api/v2/package'

