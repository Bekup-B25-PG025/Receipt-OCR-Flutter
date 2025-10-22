# Fix deprecated withOpacity to withValues
$files = Get-ChildItem -Path "lib\screens" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Replace .withOpacity( with .withValues(alpha: 
    $newContent = $content -replace '\.withOpacity\(', '.withValues(alpha: '
    
    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Host "Fixed: $($file.Name)"
    }
}

Write-Host "`nDone!"
