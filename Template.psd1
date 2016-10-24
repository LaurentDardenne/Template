# Module manifest for module 'Template'

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Template.psm1'

# Version number of this module.
ModuleVersion = '0.1.0'

# ID used to uniquely identify this module
GUID = '7cd7d08e-4560-479c-92f5-ae9937d9408b'

# Author of this module
Author = 'Laurent Dardenne'

# Company or vendor of this module
CompanyName = ''

# Copyright statement for this module
Copyright = 'Copyleft'

# Description of the functionality provided by this module
Description = 'Functions to manage Template files'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
 #<Remove%> Log4Posh use clr 2.0
CLRVersion = '2.0'

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

#<DEFINE %DEBUG%>
# Modules that must be imported into the global environment prior to importing this module
RequiredModules=@(
    @{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="2.0.0"}
)
#<UNDEF %DEBUG%>

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @('Initialize-TemplateModule.ps1')

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = @(
   'Edit-String',
   'Edit-Template',
   'Out-ArrayOfString'
)

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

         # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Template','Replace','Text','Transform','Regex','Conditionnal','Parsing')

         # A URL to the license for this module.
        LicenseUri = 'https://creativecommons.org/licenses/by-nc-sa/4.0'

         # A URL to the main website for this project.
        ProjectUri = 'https://github.com/LaurentDardenne/Template'

         # A URL to an icon representing this module.
        #IconUri = ''

         # ReleaseNotes of this module
        #ReleaseNotes = ''  #todo Template
    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}



