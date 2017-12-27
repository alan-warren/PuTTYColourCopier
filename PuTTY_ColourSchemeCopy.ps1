[CmdletBinding(SupportsShouldProcess=$true)]
param([Object]$Objects)

. "$PSScriptRoot\Select-FromArray.ps1"

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
Write-Host $sessionNames
$choice = Select-FromArray $sessionNames "Pick Host to Copy From" 3 $true
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

foreach($sess in $sessionNames) {
    if($sess -eq $templateSessionName) {
        continue
    }
    $decoded = [System.Web.HttpUtility]::UrlDecode($sess)
    $doIt = Read-Host -Prompt "Apply colour scheme to $($decoded) (Y/N)?"
    if($doIt.trim().ToUpper()[0] -eq "Y"){
        Write-Output "Doing it!"
        $targetSession = $sessionList.OpenSubKey($sess, $true)
        $changes = 0
        foreach($key in $srcKeyValuePair.Keys){
            $curVal = $targetSession.GetValue($key);
            $newVal = $srcKeyValuePair[$key]
            $targetSession.SetValue($key, $newVal)
            $readBack = $targetSession.GetValue($key)
            if($curVal -ne $newVal){
                $changes++
                Write-Output "$key `tCurVal:$curVal`tNewVal:$newVal`tReadback:$readBack"
            }
        }
        Write-Output "Changed $changes keys"
        $targetSession.close()
    }
}