Function Select-FromArray
{
    Param(
        [Object[]]$Options, 
        [String]$Prompt, 
        [int]$colWidth, 
        [Boolean]$requireValid
    )
    $ctr = 0
    $outLine = ""
    $keepGoing = $true
    Write-Host "options:$Options"
    Write-Host "Prompt:$Prompt"
    Write-Host "colwidth:$colWidth"
    while($keepGoing){
        foreach($opt in $Options) {
            $ctr++
            $DecodedOpt = [System.Web.HttpUtility]::UrlDecode($opt) 
            $outLine += "[$ctr] $DecodedOpt`t"
            if($ctr % $colWidth -eq 0){ 
                Write-Host $outLine
                $outLine = ""
            }
        }
        if($ctr % $colWidth -ne 0){
            #Output the extra value
            Write-Host $outLine
        }
        
        $choiceStr = Read-Host -Prompt $Prompt
        $choiceStr = $choiceStr.Trim()
        if($choiceStr.Substring(0, 1) -eq "Q"){
            $keepGoing = $false
            return 0
        }
        try {
            $choice = [Convert]::ToInt32($choiceStr)
        } catch {
            $choice = 0
        }
        if($choice -eq 0 -Or $choice -gt $Options.Length){
            Write-Host "Not a valid choice"
            $outLine = ""
            $ctr = 0
            if($requireValid){
                $keepGoing = $true
            } else {
                $keepGoing = $false
            }
        } else {
            $keepGoing = $false
        }
        #adjust to 0 index
        $choice--
    }
    return $choice
}