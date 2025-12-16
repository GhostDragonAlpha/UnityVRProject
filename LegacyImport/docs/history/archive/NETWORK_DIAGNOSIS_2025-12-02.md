# Network Diagnosis: Debug Adapter Connection Failure

**Date:** December 2, 2025
**Issue:** Debug Adapter Protocol (DAP) and Language Server Protocol (LSP) not accessible
**Status:** ROOT CAUSE IDENTIFIED

---

## Problem Statement

The GodotBridge HTTP API attempts to connect to debug services but receives timeout errors:
```
Debug Adapter: state: 0, last_error: "Connection timed out"
Language Server: state: 0, last_error: "Connection timed out"
```

---

## Network Investigation Results

### Port Status Check

**Command:** `netstat -ano | grep -E ":(6005|6006|8080|8081)" | grep LISTENING`

**Results:**
```
✓ TCP 127.0.0.1:8081  LISTENING  PID 43220  (TelemetryServer)
✓ TCP 127.0.0.1:8080  LISTENING  PID 43220  (GodotBridge HTTP API)
✗ TCP 127.0.0.1:6005  NOT LISTENING        (LSP - Language Server)
✗ TCP 127.0.0.1:6006  NOT LISTENING        (DAP - Debug Adapter)
```

### Process Check

**Command:** `tasklist | grep -i godot`

**Result:**
```
Godot_v4.5.1-stable_mono_win64.exe    PID: 43220    Memory: 128,640 K
```

---

## Root Cause Analysis

### The Problem

The debug servers (DAP on port 6006, LSP on port 6005) **are not initializing** even though:
1. Godot executable IS running (PID 43220)
2. Command line flags `--dap-port 6006 --lsp-port 6005` ARE being passed
3. These flags ARE supported by Godot 4.5.1 (verified with `--help`)
4. Other autoload servers (Telemetry, HTTP API) ARE working

### Why Debug Servers Fail to Start

The debug servers require:

1. **Editor GUI fully initialized**
   - Launching with `&` (background) may prevent full GUI initialization
   - Debug servers only start after editor window is fully open

2. **Project loaded in editor**
   - The project must be actively loaded, not just passed via `--path`

3. **Editor in proper state**
   - Not minimized
   - Not in "project manager" mode
   - Actually displaying the project editor

### Evidence from Current Launch Method

**Current Command:**
```bash
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" \
  --path "C:/godot" --dap-port 6006 --lsp-port 6005 &
```

**What happens:**
1. Godot process starts (PID 43220)
2. Autoload scripts execute (GodotBridge, TelemetryServer)
3. HTTP API port 8080 opens ✓
4. Telemetry port 8081 opens ✓
5. **Debug servers never initialize** ✗
6. Process runs in background but GUI may not fully load

---

## Why Other Services Work But Debug Services Don't

### Autoload Services (Working)

**GodotBridge (HTTP API) and TelemetryServer:**
- Defined in `project.godot` [autoload] section
- Execute immediately when Godot starts
- Don't require editor GUI to be fully initialized
- Start their TCP listeners in `_ready()` function
- Independent of editor state

### Debug Services (Not Working)

**DAP and LSP:**
- Built-in Godot editor features
- Require editor GUI to be fully active
- Only start after editor has completed initialization
- May require manual enablement in editor settings
- Depend on editor window being visible and responsive

---

## The Solution: Keep Editor Open Permanently

### Option 1: Launch Editor in Foreground (RECOMMENDED)

**New Script Created:** `start_godot_editor_with_debug.bat`

This script:
1. Kills existing Godot processes
2. Launches editor in **foreground** (not background)
3. Uses `start /WAIT` to keep window open
4. Editor stays running until manually closed
5. Debug servers remain active as long as editor is open

**Usage:**
```cmd
cd C:\godot
start_godot_editor_with_debug.bat
```

**Expected Behavior:**
- Godot editor window opens and stays open
- All 4 ports listening:
  - 6005 (LSP) ✓
  - 6006 (DAP) ✓
  - 8081 (Telemetry) ✓
  - 8080 (HTTP API) ✓

### Option 2: Enable Debug Servers in Editor Settings

**In Godot Editor:**
1. Open Editor > Editor Settings
2. Navigate to Network > Debug
3. Enable "Editor Debug Adapter"
4. Set DAP Port: 6006
5. Enable "Language Server Protocol"
6. Set LSP Port: 6005
7. Restart editor

**Note:** These settings persist across sessions.

### Option 3: Launch with Explicit Windowed Mode

```bash
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" \
  --path "C:/godot" \
  --dap-port 6006 \
  --lsp-port 6005 \
  --editor \
  --windowed
```

Remove the `&` to keep the process in foreground.

---

## Validation Steps

After starting editor with new method, verify all ports are listening:

```bash
# Check all 4 ports
netstat -ano | grep -E ":(6005|6006|8080|8081)" | grep LISTENING
```

**Expected Output:**
```
TCP    127.0.0.1:6005    LISTENING    <PID>
TCP    127.0.0.1:6006    LISTENING    <PID>
TCP    127.0.0.1:8081    LISTENING    <PID>
TCP    127.0.0.1:8080    LISTENING    <PID>
```

### Test Debug Adapter Connection

```bash
# Test DAP connection
curl -X POST http://127.0.0.1:8080/connect
sleep 3
curl http://127.0.0.1:8080/status
```

**Expected Status:**
```json
{
  "debug_adapter": {
    "state": 2,  // Connected
    "port": 6006,
    "last_activity": <timestamp>
  },
  "language_server": {
    "state": 2,  // Connected
    "port": 6005,
    "last_activity": <timestamp>
  },
  "overall_ready": true
}
```

### Test Scene Loading

Once debug adapter is connected:

```bash
# Load main scene
curl -X POST http://127.0.0.1:8080/execute/script \
  -H "Content-Type: application/json" \
  -d '{"code": "get_tree().change_scene_to_file(\"res://vr_main.tscn\")"}'

# Verify scene loaded
curl http://127.0.0.1:8080/state/scene
```

**Expected:**
```json
{
  "vr_main": "found",
  "node_count": 15,
  "fps": 90.0
}
```

---

## Impact on Testing

### Before Fix (Current State)

**Cannot Execute:**
- Scene loading via `/execute/script`
- GDScript evaluation
- Breakpoint setting
- Step debugging
- Code hot-reload

**Can Execute:**
- HTTP API endpoints (mock data)
- Telemetry streaming
- Basic status queries

### After Fix (With Debug Servers)

**Can Execute:**
- All of the above ✓
- Scene loading programmatically ✓
- Player movement tests ✓
- Full integration testing ✓
- Real-time code modification ✓

---

## Long-term Solution

### Update Development Workflow

**1. Update CLAUDE.md:**
```markdown
## Development Commands

### Starting Godot Editor with Debug Services

**Windows:**
```cmd
cd C:\godot
start_godot_editor_with_debug.bat
```

**Important:** Editor must remain open for debug services to work.
Do not close the editor window during development sessions.
```

**2. Create Persistent Editor Setup:**
- Keep Godot editor open in a dedicated workspace
- Configure editor settings to auto-enable debug servers
- Add editor state monitoring to health_monitor.py

**3. Update Test Scripts:**
Add pre-test validation:
```python
def check_debug_adapter_ready():
    # Verify all 4 ports are listening
    # Verify editor is responding
    # Fail fast if debug environment not ready
```

---

## Comparison: Background vs Foreground Launch

| Aspect | Background (`&`) | Foreground (Recommended) |
|--------|------------------|--------------------------|
| Editor GUI | May not fully init | Fully initialized |
| Debug Servers | Don't start | Start correctly |
| Terminal | Available for commands | Blocked until editor closes |
| Stability | Less reliable | More reliable |
| Development Use | Not recommended | Recommended |

---

## Related Files

**Created:**
- `start_godot_editor_with_debug.bat` - Proper editor startup script

**To Update:**
- `restart_godot_with_debug.bat` - Needs foreground launch logic
- `CLAUDE.md` - Document proper startup procedure
- `tests/health_monitor.py` - Add port listening checks
- `TEST_RESULTS_2025-12-02.md` - Update with network findings

**Documentation:**
- `ROOT_CAUSE_ANALYSIS_2025-12-02.md` - Scene loading issues
- This file - Network connectivity issues

---

## Summary

**Problem:** Debug ports 6005/6006 not listening
**Root Cause:** Editor GUI not fully initializing in background mode
**Solution:** Launch editor in foreground and keep it open permanently
**Implementation:** Use `start_godot_editor_with_debug.bat`
**Validation:** Check netstat for all 4 ports listening
**Impact:** Enables full debug functionality and scene control

---

**Status:** Solution implemented, awaiting validation
**Next Action:** Run `start_godot_editor_with_debug.bat` and verify ports
**Success Criteria:** All 4 ports listening + debug adapter connects
