param (
    [string]$PackageName
)

if (-not $PackageName) {
    Write-Host "Usage: choco-install.ps1 <PackageName>" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Attempting to install package: $PackageName" -ForegroundColor Green
    choco install $PackageName -y
    Write-Host "Package '$PackageName' installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to install package: $PackageName" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
