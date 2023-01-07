Write-Host ""
Write-Host "What would you like to do?"
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"

$decision = Read-Host -Prompt "Please enter 'A' or 'B'"

Write-Host ""
# Write-Host "User entered $($decision)"

Function Calculate-File-Hash($filepath) {

    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash

}

Function Erase-Baseline-If-Exists() {

    $baselineStatus = Test-Path -Path .\baseline.txt

    if ($baselineStatus) {
        Remove-Item -Path .\baseline.txt
    }

}

if ($decision -eq "A".ToUpper()) {

    # Delete baseline.txt if it already exists
    Erase-Baseline-If-Exists

    # Calculate Hash from the target files and store in baseline.txt
    Write-Host "User selected calculate Hashes and make new baseline.txt" -ForegroundColor Cyan

    $files = Get-ChildItem -Path .\files

    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
    
}
elseif ($decision -eq "B".ToUpper()) {

    Write-Host "User selected read existing baseline.txt and monitor files" -ForegroundColor Cyan

    # Load file|hash from baseline.txt and store in a dictionary
    $fileHashDict = @{}
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes) {
        $temppath, $temphash = $f.Split("|")
        $fileHashDict.Add($temppath, $temphash)
    }

    # Begin monitoring files with saved Baseline
    while ($true) {
        Start-Sleep -Seconds 1

        # Write-Host "Checking if files match..."
        $files = Get-ChildItem -Path .\files

        foreach ($p in $fileHashDict.Keys) {
            $fileStatus = Test-Path -Path $p

            if ($fileStatus) {
                # All files still there
            }
            else {
                # A file has been deleted; notify immediately
                Write-Host "$($p) has been deleted!" -ForegroundColor Red
            }
        }

        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName

            if ($fileHashDict[$hash.Path] -eq $null) {
                # A new file has been created; notify immediately
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            else {
                if ($fileHashDict[$hash.Path] -eq $hash.Hash) {
                    # No changes
                }
                else {
                    # A file has been compromised; notify immediately
                    Write-Host "$($hash.Path) has been modified!" -ForegroundColor Yellow
                }
            }
        } 
    }

}
