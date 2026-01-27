# create ram-usage directory inside system temp
$ramDir = Join-Path $env:TEMP 'ram-usage'
if (-not (Test-Path -Path $ramDir)) {
    New-Item -Path $ramDir -ItemType Directory -Force | Out-Null
}

# Export running processes + RAM usage to a timestamped CSV in the ram-usage temp directory
$out = Join-Path $ramDir ("process-ram-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

Get-Process |
    Select-Object `
        @{Name='ProcessName'; Expression={$_.ProcessName}},
        @{Name='Id';          Expression={$_.Id}},
        @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
        @{Name='PrivateMB';   Expression={ if ($_.PrivateMemorySize64) {[math]::Round($_.PrivateMemorySize64 / 1MB, 2)} else {$null} }},
        @{Name='CPUSeconds';  Expression={ if ($_.CPU) {[math]::Round($_.CPU, 2)} else {$null} }},
        @{Name='StartTime';   Expression={ try { $_.StartTime } catch { $null } }} |
    Sort-Object WorkingSetMB -Descending |
    Export-Csv -Path $out -NoTypeInformation -Encoding UTF8

Write-Host "Wrote: $out"

# open the ram-usage directory in VS Code
Start-Process -FilePath 'code' -ArgumentList '.' -WorkingDirectory $ramDir