# Input the package name to search for
$packageName = $args[0]

# Get the list of installed packages and filter for the package name
$package = choco list --local-only | findstr $packageName

if ($package) {
    # Extract the package name from the output
    $packageNameExtracted = $package -replace '\|.*$', ''
    $packageNameExtractedSimple = $packageNameExtracted -replace '\s*\d.*$', ''
    

    Write-Output "Package: $packageNameExtracted"
    Write-Output "Package: $packageNameExtractedSimple"
    choco info $packageNameExtractedSimple

} else {
    Write-Output "No package found matching '$packageName'."
}
