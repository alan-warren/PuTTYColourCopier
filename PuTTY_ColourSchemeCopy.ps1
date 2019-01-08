[CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName="Colours Only")]
param(
    [parameter(Mandatory = $false, ParameterSetName = "Colours Only")]
    [boolean]$ColoursOnly=$true,
    [parameter(Mandatory = $false, ParameterSetName = "Template Setup")]
    [switch]$SetupTemplates,
    [string]$TemplateNamesStartWith = "zzz_colour_",
    [parameter(Mandatory = $false, ParameterSetName = "AllFields")]
    [switch]$AllFields
)
<#
.SYNOPSIS
Tools hacked together to enable copying settings around between PuTTY sessions.
.DESCRIPTION
Orignally built to copy colours from one PuTTY config to others, I'm now working to expand it
to support copying entire profiles or colour settings.

So, let's say you download some colour profiles from 
https://github.com/AlexAkulov/putty-color-themes

Grab a few of them, put them into one new .reg file and name them with a convention. The convention
I'm using is zzz_colours_NAME
[HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\Sessions\zzz_colours_Monokai_Dimmed]
This also has the benefit of sorting to the bottom of your list.  If desired, you can delete
the source session after copying.

That's great, but I'm also standardizing my fonts (powerline compatible), keyboard config,
timeout settings (work VPN boots VPN sessions it considers idle), and others.  In fact the only thing I
don't really want to copy between configs is the hostname.  Note, that it would be better to set these values
in your "Default Settings" profile in PuTTY, but if you're like me you've already got dozens of profiles defined.

So, merge your .reg file (Right click + Merge in explorer). Then run 
.\PuTTY_ColourSchemeCopy.ps1 -SetupTemplates
You'll then be asked to select a template to copy everything but colours (and hostname) from.

Now you can run with -AllFields to copy all values from your zzz_colour_ template session to
other sessions (presented interactively, so you don't need to apply to all)

Finally, you can run with -ColoursOnly to only copy the colour configuration (presented interactively)
#>

. "$PSScriptRoot\Select-FromArray.ps1"

Function CopySessionFields() {
    param(
        [Object]$templateSession,
        [Object[]]$sessionsToUpdate,
        [Object[]]$fieldsToCopy
    )
    #Copy the key-value pairs we want so we don't keep going to the registry
    $srcKeyValuePair = @{}
    foreach ($field in $fieldsToCopy) {
        $srcKeyValuePair[$field] = $templateSession.GetValue($field)
    }
    Write-Output "Using settings from $($templateSession.ToString())"
    $templateSession.Close()
    foreach ($sess in $sessionsToUpdate) {
        $decoded = [System.Web.HttpUtility]::UrlDecode($sess)
        $doIt = Read-Host -Prompt "Apply settings to $($decoded) (Y/N)?"
        if ($doIt.trim().ToUpper()[0] -eq "Y") {
            $targetSession = $sessionList.OpenSubKey($sess, $true)
            $changes = 0
            foreach($key in $srcKeyValuePair.Keys){
                $curVal = $targetSession.GetValue($key);
                $newVal = $srcKeyValuePair[$key]
                #Commenting out the line that actually pushes the change into the registry
                #$targetSession.SetValue($key, $newVal)
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
}

Function DefineFieldsToCopy() {
    param(
        [Object]$session
    )
    <# 
    If you want to copy fields other than colours from one profile to others, you can redefine this array
    to start off non-empty
    ex. $fieldsToCopy = "BeepInd", "Font"   
    #>
    $fieldsToCopy = @()
    $fieldsToNeverCopy = @("HostName")
    $colourCount = 21
    if ($ColoursOnly -Or $SetupTemplates) {
        #Add the colours to the list of fields we'll be copying. Pretty inefficient, but only do it once per script exec.
        for ($i = 0; $i -le $colourCount; $i++) {
            $fieldsToCopy += "Colour$i"
        }
    }
    if($SetupTemplates){
        #We don't actually want to copy to the colours, so move them to fieldsToNeverCopy
        $fieldsToNeverCopy += $fieldsToCopy
        $fieldsToCopy = @()
    }

    if($AllFields -Or $SetupTemplates){
        #Step through the fields and add them to the list to be copied, unless they're in our exclusion list
        $regValueNames = $session.GetValueNames()
        foreach($regValueName in $regValueNames){
            if($fieldsToNeverCopy.Contains($regValueName)){
                Write-Debug "Skipping $regValueName"
                continue;
            }
            $fieldsToCopy += $regValueName
        }
    }
    return $fieldsToCopy
}

Try {
    $sessionList = Get-Item -Path Registry::HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\Sessions -ErrorAction Stop
} Catch {
    Write-Output "No sessions in registry"
    exit
}

$sessionNames = $sessionList.GetSubKeyNames()
if ($SetupTemplates) {
    #Update the zzz_colours_* sessions with fields from the selected session
    $templateNum = Select-FromArray $sessionNames "Pick a template for non colour config" 3 $true
    $toUpdate = $sessionNames -match "$($TemplateNamesStartWith)*"
    $ColoursOnly = $false
}
if ($ColoursOnly) {
    $templateNum = Select-FromArray $sessionNames "Pick a template for colour copy" 3 $true
    $toUpdate = $sessionNames -notmatch "$($TemplateNamesStartWith)*"
}

$templateSession = $sessionList.OpenSubKey($sessionNames[$templateNum])


$fieldsToCopy = DefineFieldsToCopy -session $templateSession
CopySessionFields -templateSession $templateSession -sessionsToUpdate $toUpdate -fieldsToCopy $fieldsToCopy

