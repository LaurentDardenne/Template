#TODO
# Localized Template.Resources.psd1 : en-US

ConvertFrom-StringData @'
# Edit-String
WellFormedKeyNullOrEmptyValue  =The 'Replace' key do not exist or it is `$null
WellFormedInvalidCast          =The key value {0} dot not convert to {1}.
WellFormedInvalidValueNotLower =The key value 'Max' cant not less than -1.
WellFormedInvalidValueNotZero  =The key value 'StartAt'must be greater to zero.
ReplaceSimpleEmptyString       =The parameter -SimpleReplace does not allow an empty search string.
ReplaceRegExCreate             =[Regex build] {0}
ReplaceRegExStarAt             ={0}`r`nStartAt({1}) is greater the string length({2})
ReplaceObjectPropertyNotString =The property'{0}' is not a string type.
ReplaceObjectPropertyReadOnly  = The property '{0}' is readonly.
ReplaceSimpleScriptBlockError  ={0}={{{1}}}`r`n{2}
ObjectReplaceShouldProcess     =Object [{0}] property : {1}
StringReplaceShouldProcess     ={0} by {1}
WarningSwitchSimpleReplace     =The switch -SimpleReplace does not use all features of a hashtable SimpleReplace @ {Replace = 'X'; Max = n; n = StartAt, Options = 'Y'} `r`nUse a simple string.
WarningConverTo                =The conversion, by Converto (), returns an empty string.`r`n {0}

# Edit-Template
DirectiveContainsSpace          =The directive '%{0}%' contains spaces.
DirectiveNameReserved           =These names are reserved directives : {0}. Use the associated parameter.
DirectivesIncorrectlyNested     =Parsing canceled.`r`n{0}`r`nThe directives declarations '{1}' et '{2}:{3}' are not nested.
OrphanDirective                 =Parsing canceled.`r`n{0}`r`nThe  directive #<UNDEF %{1}%> is not associated with a DEFINE directive ('{1}:{2}')
IncludedFileNotFound            =A file to include does not exist'{0}'
DirectiveIncomplet              =Parsing canceled.`r`n{0}`r`n the following directives have no end keyword : {1}
'@
