# Godot Launch Method Comparison
**Date:** 2025-12-02

## Quick Reference

### Current Method (BROKEN)
```python
# godot_editor_server.py line 87-92
self.process = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    creationflags=subprocess.CREATE_NO_WINDOW  # ← PROBLEM
)
```

**Result:** DAP/LSP ports don't bind ❌

### Fixed Method (WORKING)
```python
# godot_editor_server_fixed.py line 141-149
self.process = subprocess.Popen(
    cmd,
    # NO creationflags parameter
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)
```

**Result:** DAP/LSP ports should bind ✅

## Side-by-Side Comparison

| Aspect | Current Method | Fixed Method |
|--------|---------------|--------------|
| **creationflags** | `CREATE_NO_WINDOW` | None (default) |
| **Window Visible** | No | Yes |
| **DAP Port (6006)** | ❌ Not listening | ✅ Should listen |
| **LSP Port (6005)** | ❌ Not listening | ✅ Should listen |
| **HTTP API (8080)** | ✅ Works | ✅ Works |
| **Editor GUI** | Hidden/Broken | Visible |
| **Debugging** | Difficult | Easy |

## Why CREATE_NO_WINDOW Breaks It

### What CREATE_NO_WINDOW Does
From Windows documentation:
> Creates a process that has no console window. This flag is used when the process doesn't need a console for input/output.

### The Problem
1. Godot Editor is a **GUI application**, not a console app
2. `CREATE_NO_WINDOW` tells Windows to suppress **all** window creation
3. This prevents the Editor GUI from initializing properly
4. DAP/LSP are **Editor-only** features (marked with `[E]` in `--help`)
5. Without full Editor initialization, DAP/LSP don't start

### Visual Explanation
```
Current Method:
Python subprocess → CREATE_NO_WINDOW → Windows suppresses window
                                     → Godot thinks it's headless
                                     → Editor GUI incomplete
                                     → DAP/LSP don't initialize ❌

Fixed Method:
Python subprocess → No flags → Windows creates window normally
                             → Godot Editor GUI fully initializes
                             → Editor subsystems start
                             → DAP/LSP bind to ports ✅
```

## Testing Commands

### Test Current Method
```bash
python godot_editor_server.py --auto-load-scene

# Check ports after 15 seconds
netstat -an | findstr ":6006"  # DAP - should be empty ❌
netstat -an | findstr ":6005"  # LSP - should be empty ❌
netstat -an | findstr ":8080"  # HTTP - should show LISTENING ✅
```

### Test Fixed Method
```bash
python godot_editor_server_fixed.py --auto-load-scene

# Check ports after 15 seconds
netstat -an | findstr ":6006"  # DAP - should show LISTENING ✅
netstat -an | findstr ":6005"  # LSP - should show LISTENING ✅
netstat -an | findstr ":8080"  # HTTP - should show LISTENING ✅
```

### Compare with Manual Launch
```bash
# Kill existing Godot
taskkill /IM Godot*.exe /F

# Launch manually (known to work)
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" --path "C:/godot" --dap-port 6006 --lsp-port 6005 --editor

# Wait 15 seconds, then check ports
netstat -an | findstr ":600"
```

## Implementation Steps

### Step 1: Backup Current Version
```bash
cp godot_editor_server.py godot_editor_server_backup.py
```

### Step 2: Apply Fix
Edit `godot_editor_server.py` line 87-92:

**Before:**
```python
if platform.system() == "Windows":
    # On Windows, use CREATE_NO_WINDOW to run without console
    self.process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        creationflags=subprocess.CREATE_NO_WINDOW
    )
```

**After:**
```python
if platform.system() == "Windows":
    # CRITICAL: Don't use CREATE_NO_WINDOW for GUI applications
    # The editor window MUST be visible for DAP/LSP to initialize
    self.process = subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
        # No creationflags parameter
    )
```

### Step 3: Test
```bash
# Stop existing server
curl -X POST http://127.0.0.1:8090/stop

# Start with fix
python godot_editor_server.py --auto-load-scene

# Wait 15 seconds
sleep 15

# Verify ports
netstat -an | findstr ":6006"  # Should show LISTENING
netstat -an | findstr ":6005"  # Should show LISTENING
```

### Step 4: Verify DAP Connection
```bash
# Try to connect to DAP port
python -c "import socket; s = socket.socket(); s.connect(('127.0.0.1', 6006)); print('DAP Connected!'); s.close()"

# Try to connect to LSP port
python -c "import socket; s = socket.socket(); s.connect(('127.0.0.1', 6005)); print('LSP Connected!'); s.close()"
```

## Alternative Solutions

### Option 1: Use Console Executable
If you absolutely must hide the main window, use the console executable:

```python
godot_console_path = "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe"

self.process = subprocess.Popen(
    cmd,
    creationflags=subprocess.CREATE_NEW_CONSOLE  # Appropriate for console apps
)
```

### Option 2: Minimize Window
Keep window visible but minimized:

```python
import win32con
import win32process

self.process = subprocess.Popen(
    cmd,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)

# Minimize window after creation
time.sleep(2)
hwnd = win32gui.FindWindow(None, "Godot Engine")
if hwnd:
    win32gui.ShowWindow(hwnd, win32con.SW_MINIMIZE)
```

### Option 3: Run on Virtual Desktop
Use Windows virtual desktop feature to hide window:

```bash
# PowerShell
New-Desktop -Name "Godot"
Start-Process -Desktop "Godot" "godot.exe" -ArgumentList "--path", "C:/godot", "--dap-port", "6006", "--lsp-port", "6005", "--editor"
```

## Expected Behavior After Fix

1. **Godot editor window appears** - Taskbar icon visible
2. **Ports bind successfully:**
   - `127.0.0.1:6006` - DAP server listening
   - `127.0.0.1:6005` - LSP server listening
   - `127.0.0.1:8081` - HTTP API listening
   - `127.0.0.1:8081` - Telemetry WebSocket listening
3. **DAP client can connect** - VS Code, other debuggers
4. **LSP client can connect** - Code completion, definitions
5. **Full functionality** - All debug protocol features work

## Troubleshooting

### Still Not Working After Fix?

1. **Check firewall:**
   ```powershell
   Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Godot*"}
   ```

2. **Verify Godot version supports flags:**
   ```bash
   godot --help | grep "dap-port\|lsp-port"
   ```

3. **Check if ports are already in use:**
   ```bash
   netstat -an | findstr ":6006 :6005"
   ```

4. **Look at Godot logs:**
   - Check `%APPDATA%/Godot/app_userdata/` for logs
   - Enable verbose mode: `--verbose` flag

5. **Try manual launch first:**
   - If manual launch doesn't work, it's not a subprocess issue
   - Check Godot installation and project configuration

## Documentation Updates Needed

After confirming fix works:

1. Update `CLAUDE.md` with corrected launch method
2. Update `godot_controller.py` if it uses similar approach
3. Update `README.md` with subprocess caveat
4. Add troubleshooting section about CREATE_NO_WINDOW
5. Document in `addons/godot_debug_connection/README.md`

## References

- Windows CreateProcess documentation: https://learn.microsoft.com/en-us/windows/win32/procthread/process-creation-flags
- Godot command line reference: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Python subprocess documentation: https://docs.python.org/3/library/subprocess.html

---

**Next Steps:**
1. Test the fixed version
2. Verify DAP/LSP ports are listening
3. Test actual DAP/LSP connections
4. Update production code if successful
5. Document the fix
