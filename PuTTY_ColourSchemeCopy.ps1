[CmdletBinding(SupportsShouldProcess=$true)]
param([Object]$Objects)
$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath/Select-Item.ps1"

Try {
    $sessionList = Get-Item -Path Registry::HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\Sessions -ErrorAction Stop
} Catch {
    Write-Output "No sessions in registry"
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
$ctr = 0
$colWidth = 3
$outLine = ""
foreach($session in $sessionNames) {
    $ctr++
    $outLine += "[$ctr] $session`t"
    if($ctr % $colWidth -eq 0){ 
        Write-Output $objLine
        $outLine = ""
    }
}
if($ctr % $colWidth -ne 0){
    #Output the extra value
    Write-Output $outLine
}
$choiceStr = Read-Host -Prompt "Pick a session to copy from"
$choice = [Convert]::ToInt32($choiceStr)
$choice--
$templateSessionName = $sessionNames[$choice]
$templateSession = $sessionList.OpenSubKey($templateSessionName)
$srcKeyValuePair = @{}

#Add the colours to the list of fields we'll be copying. Pretty inefficient, but only do it once per script exec.
for($i = 0; $i -le $colourCount; $i++){
    $fieldsToCopy += "Colour$i"
}
#Copy the key-value pairs we want so we don't keep going to the registry
foreach($field in $fieldsToCopy){
    $srcKeyValuePair[$field] = $templateSession.GetValue($field)
}
Write-Output "Using colours from $($templateSession.ToString())"
$templateSession.Close()
#this is in here to test if the -WhatIf automatically flows to called cmdlets
#Remove-Item $scriptPath\testFile.txt

foreach($sess in $sessionNames) {
    if($sess -eq $templateSessionName) {
        continue
    }
    $doIt = Read-Host -Prompt "Apply colour scheme to $($sess) (Y/N)?"
    if($doIt.trim().ToUpper()[0] -eq "Y"){
        Write-Output "Doing it!"
        $targetSession = $sessionList.OpenSubKey($sess, $true)
        foreach($key in $srcKeyValuePair.Keys){
            Write-Output $key
            $curVal = $targetSession.GetValue($key);
            $newVal = $srcKeyValuePair[$key]
            Write-Output "Current value is $curVal"
            Write-Output "Template value is $newVal"
            $targetSession.SetValue($key, $newVal)
            $curVal = $targetSession.GetValue($key)
        }
        $targetSession.close()
    }
}