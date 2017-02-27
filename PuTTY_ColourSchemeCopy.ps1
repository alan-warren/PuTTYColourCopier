[CmdletBinding(SupportsShouldProcess=$true)]
param([Object]$Objects)
$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath/Select-Item.ps1"

Try {
    $sessionList = Get-Item -Path Registry::HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\Sessions -ErrorAction Stop
} Catch {
    echo "No sessions in registry"
    exit
}
$sessionNames = $sessionList.GetSubKeyNames()
$colourCount = 21

<# 
    If you want to copy fields other than colours from one profile to others, you can redefine this array
    to start off non-empty
    ex. $fieldsToCopy = "BeepInd", "Font"
#>
$fieldsToCopy = @()

$templateNum = Select-Item -Caption "PuTTY Sesssion Colour Template" -Message "Choose the PuTTY session to source colours from" -choiceList $sessionNames
$templateSession = $sessionList.OpenSubKey($sessionNames[$templateNum])
$srcKeyValuePair = @{}

#Add the colours to the list of fields we'll be copying. Pretty inefficient, but only do it once per script exec.
for($i = 0; $i -le $colourCount; $i++){
    $fieldsToCopy += "Colour$i"
}
#Copy the key-value pairs we want so we don't keep going to the registry
foreach($field in $fieldsToCopy){
    $srcKeyValuePair[$field] = $templateSession.GetValue($field)
}
echo "Using colours from $($templateSession.ToString())"
$templateSession.Close()
#this is in here to test if the -WhatIf automatically flows to called cmdlets
Remove-Item $scriptPath\testFile.txt

foreach($sess in $sessionNames) {
    $doIt = Read-Host -Prompt "Apply colour scheme to $($sess) (Y/N)?"
    if($doIt.trim().ToUpper()[0] -eq "Y"){
        echo "Doing it!"
        $targetSession = $sessionList.OpenSubKey($sess)
        foreach($key in $srcKeyValuePair.Keys){
            $curVal = $targetSession.GetValue($field);
            $newVal = $srcKeyValuePair[$key]
            echo "Current value is $curVal"
            echo "Template value is $newVal"
        }
        $targetSession.close()
    }
}