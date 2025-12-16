$source = "C:\Ignotus"
$dest = "C:\Users\allen\.gemini\antigravity\scratch\UnityVRProject\LegacyImport"

if (-not (Test-Path $source)) {
    Write-Host "Source not found: $source"
    exit 1
}

Write-Host "Copying relevant scripts from $source to $dest..."

# Only copy scripts to save time/space (.gd, .tscn, .md, .txt)
Robocopy $source $dest *.gd *.tscn *.md *.txt /S /R:1 /W:1

Write-Host "Import Complete."
