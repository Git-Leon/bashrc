param (
    [string]$PackageName
)

if (-not $PackageName) {
    Write-Host "Usage: choco-uninstall.ps1 <PackageName>" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Attempting to uninstall package: $PackageName" -ForegroundColor Green
    choco uninstall $PackageName -y
    Write-Host "Package '$PackageName' uninstalled successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to uninstall package: $PackageName" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
