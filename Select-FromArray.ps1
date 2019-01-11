Add-Type -AssemblyName System.Web
Function Select-FromArray {
    Param(
        [Object[]]$Options, 
        [String]$Prompt, 
        [int]$colWidth = 3, 
        [switch]$allowInvalid = $false,
        [switch]$allowMulti = $false
    )
 
    if($allowInvalid) { $requireValid = $false }
    else { $requireValid = $true }
    $outLine = ""
    $keepGoing = $true
    $selected = @()
    while ($keepGoing) {
        $ctr = 0
        $outLine = ""
        $selected = @()
        $foundInvalid = $false
        foreach ($opt in $Options) {
            $ctr++
            $DecodedOpt = [System.Web.HttpUtility]::UrlDecode($opt) 
            $outLine += "[$ctr] $DecodedOpt`t"
            if ($ctr % $colWidth -eq 0) { 
                Write-Host $outLine
                $outLine = ""
            }
        }
        if ($ctr % $colWidth -ne 0) {
            #Output the extra value
            Write-Host $outLine
        }
        
        $choiceStr = Read-Host -Prompt $Prompt
        try {
            $choiceStr = $choiceStr.Trim()
            $choices = $choiceStr.Split(",")
            if ($choices.Length -gt 1 -and -not ($allowMulti)) {
                $keepGoing = $true
                Write-Warning "-allowMulti not set"
                continue;
            }
        }
        catch {
            continue;
        }
        if ($choiceStr.Substring(0, 1) -eq "Q") {
            $keepGoing = $false
            return 0
        }
        
        foreach ($choiceStr in $choices) {
            try {
                $choice = [Convert]::ToInt32($choiceStr)
            }
            catch {
                $choice = $null
            }
            if (!$choice -Or $choice -gt $Options.Length) {
                Write-Warning "Not a valid choice:$choiceStr"
                if ($requireValid) {
                    $foundInvalid = $true
                    $keepGoing = $true
                }
                else {
                    $keepGoing = $false
                }
            }
            else {
                $keepGoing = $false
                #Found a valid entry
                #adjust to 0 index, and append to result array
                $selected += $choice--
            }
        }
        if ($foundInvalid -and $allowMulti) {
            $keepGoing = $true
        }
    }
    return $selected
}