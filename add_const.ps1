# Add const to constructors based on flutter analyze output
$output = flutter analyze --no-fatal-infos 2>&1 | Select-String "prefer_const_constructors"

$changes = @{}

foreach ($line in $output) {
    if ($line -match 'lib\\(.+\.dart):(\d+):(\d+)') {
        $file = "lib\$($matches[1])"
        $lineNum = [int]$matches[2]
        
        if (-not $changes.ContainsKey($file)) {
            $changes[$file] = @()
        }
        $changes[$file] += $lineNum
    }
}

foreach ($file in $changes.Keys) {
    Write-Host "Fixing: $file"
    $lines = Get-Content $file
    $sortedLines = $changes[$file] | Sort-Object -Descending
    
    foreach ($lineNum in $sortedLines) {
        $idx = $lineNum - 1
        $line = $lines[$idx]
        
        # Add const if not already present
        if ($line -notmatch '\bconst\s') {
            # Find the widget constructor and add const before it
            $lines[$idx] = $line -replace '(\s+)(new\s+)?([A-Z]\w+(\.\w+)?\()', '$1const $3'
        }
    }
    
    Set-Content -Path $file -Value $lines
    Write-Host "  Fixed $($sortedLines.Count) lines"
}

Write-Host "`nDone! Fixed $($changes.Keys.Count) files"
