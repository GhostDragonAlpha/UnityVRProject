$wshell = New-Object -ComObject WScript.Shell
$proc = Get-Process Unity -ErrorAction SilentlyContinue

if (-not $proc) {
    Write-Host "Unity process not found."
    exit 1
}

# Try to bring to front using PID
$success = $wshell.AppActivate($proc.Id)

if ($success) {
    Write-Host "Success: Unity window focused (AppActivate)."
} else {
    # Fallback: Try by Window Title if PID fails (sometimes PID is Hub not Editor)
    $success = $wshell.AppActivate("Unity")
    if ($success) {
         Write-Host "Success: Unity window focused by Title."
    } else {
         Write-Host "Failed to focus Unity window."
    }
}
