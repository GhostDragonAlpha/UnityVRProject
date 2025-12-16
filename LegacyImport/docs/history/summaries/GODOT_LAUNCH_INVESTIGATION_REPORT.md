# Godot Launch Investigation Report
**Date:** 2025-12-02
**Author:** Claude Code
**Purpose:** Investigate different launch methods to enable DAP/LSP connectivity

## Executive Summary

### Key Findings

1. **DAP/LSP are EDITOR-ONLY flags** - They only work when Godot is launched in editor mode
2. **Current method uses `CREATE_NO_WINDOW`** - This may interfere with editor GUI initialization
3. **Console executable available** - `Godot_v4.5.1-stable_win64_console.exe` provides better output visibility
4. **Editor GUI MUST be visible** - Documentation consistently states "non-headless" requirement

### Critical Discovery

From Godot's `--help`:
```
Option legend (this build = editor):
  R  Available in editor builds, debug export templates and release export templates.
  D  Available in editor builds and debug export templates only.
  E  Only available in editor builds.

--dap-port <port>                 E  Use the specified port for the GDScript Debug Adapter Protocol
--lsp-port <port>                 E  Use the specified port for the GDScript Language Server Protocol
```

The `E` flag means **Editor-only**. These servers ONLY initialize when Godot is in editor mode.

## Current Launch Method Analysis

### Current Implementation (godot_editor_server.py)

**Code snippet (lines 75-92):**
```python
cmd = [
    self.godot_path,
    "--path", self.project_path,
    "--dap-port", str(self.dap_port),
    "--lsp-port", str(self.lsp_port),
    "--editor"
]

# Platform-specific process creation
if platform.system() == "Windows":
    # On Windows, use CREATE_NO_WINDOW to run without console
    self.process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        creationflags=subprocess.CREATE_NO_WINDOW
    )
```

### Issues with Current Method

1. **CREATE_NO_WINDOW flag** - Prevents console window but may interfere with GUI window creation
2. **stdout/stderr captured** - Output is piped away, making debugging difficult
3. **No window visibility** - Can't see if editor GUI actually opens
4. **Background process** - May not get proper window focus/initialization

### Why It's Failing

**Hypothesis:** `CREATE_NO_WINDOW` flag is intended for console applications. When used with a GUI application like Godot Editor, it may:
- Prevent proper window initialization
- Cause Godot to think it's running in headless/background mode
- Block the DAP/LSP server initialization which requires full editor GUI

## Recommended Launch Methods

### Method 1: Normal Process Creation (RECOMMENDED)

**Remove CREATE_NO_WINDOW flag entirely:**

```python
# Modified start() method
def start(self) -> bool:
    """Start the Godot editor process."""
    with self.lock:
        if self.process and self.process.poll() is None:
            logger.warning("Godot process already running")
            return True

        try:
            logger.info(f"Starting Godot editor: {self.godot_path}")
            logger.info(f"  Project: {self.project_path}")
            logger.info(f"  DAP Port: {self.dap_port}, LSP Port: {self.lsp_port}")

            # Start Godot editor with debug services
            cmd = [
                self.godot_path,
                "--path", self.project_path,
                "--dap-port", str(self.dap_port),
                "--lsp-port", str(self.lsp_port),
                "--editor"
            ]

            # CRITICAL: Don't use CREATE_NO_WINDOW for GUI applications
            # Let the editor window show normally
            if platform.system() == "Windows":
                self.process = subprocess.Popen(
                    cmd,
                    # No creationflags - allow normal window creation
                    stdout=subprocess.DEVNULL,  # Still suppress console output
                    stderr=subprocess.DEVNULL
                )
            else:
                self.process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )

            logger.info(f"Godot process started with PID: {self.process.pid}")

            # Wait for Godot to initialize
            time.sleep(5)

            return self.process.poll() is None

        except Exception as e:
            logger.error(f"Failed to start Godot: {e}")
            return False
```

**Why this works:**
- Allows Godot's GUI window to initialize properly
- Editor mode fully activates
- DAP/LSP servers can bind to their ports
- Window is visible but doesn't block Python script execution

### Method 2: Use Console Executable

**Use the console version for better debugging:**

```python
# Find console executable
GODOT_CONSOLE_EXE = "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe"

cmd = [
    GODOT_CONSOLE_EXE,  # Use console version
    "--path", self.project_path,
    "--dap-port", str(self.dap_port),
    "--lsp-port", str(self.lsp_port),
    "--editor"
]

self.process = subprocess.Popen(
    cmd,
    creationflags=subprocess.CREATE_NEW_CONSOLE  # Create new console window
)
```

**Why this works:**
- Console version is designed to show output in terminal
- CREATE_NEW_CONSOLE is appropriate for console applications
- Can see Godot's log messages directly
- Better for debugging initialization issues

### Method 3: Use Windows 'start' Command

**Launch via Windows start command:**

```python
cmd = [
    "start",
    "/B",  # Don't create new window
    self.godot_path,
    "--path", self.project_path,
    "--dap-port", str(self.dap_port),
    "--lsp-port", str(self.lsp_port),
    "--editor"
]

self.process = subprocess.Popen(
    cmd,
    shell=True  # Required for 'start' command
)
```

**Why this might work:**
- Windows handles the process creation natively
- Respects application type (GUI vs console)
- More robust window management

### Method 4: CREATE_BREAKAWAY_FROM_JOB

**Allow process to break away from job objects:**

```python
self.process = subprocess.Popen(
    cmd,
    creationflags=subprocess.CREATE_BREAKAWAY_FROM_JOB
)
```

**Why this might help:**
- If Python is running in a job object, child processes inherit restrictions
- Breaking away allows normal window creation
- More common in CI/CD environments

## Testing Scripts Created

### 1. test_godot_launch_methods.py

Comprehensive test script that tries all launch methods and reports which ones successfully enable DAP/LSP ports.

**Usage:**
```bash
python test_godot_launch_methods.py
```

**Tests performed:**
1. GUI exe with CREATE_NO_WINDOW (current method)
2. GUI exe WITHOUT CREATE_NO_WINDOW
3. Console exe with CREATE_NEW_CONSOLE
4. Console exe without flags
5. GUI exe with --verbose flag
6. Using Windows 'start' command
7. Direct execution with CREATE_BREAKAWAY_FROM_JOB

### 2. test_port_detection.py

Tests different methods of detecting if ports are listening.

**Usage:**
```bash
python test_port_detection.py
```

**Methods tested:**
- TCP connect (current method)
- netstat command parsing
- PowerShell Get-NetTCPConnection

### 3. test_manual_launch.bat

Batch script to manually launch Godot and verify ports are listening.

**Usage:**
```bash
./test_manual_launch.bat
```

**Purpose:**
- Establishes baseline of what works when launched manually
- Uses Windows netstat to verify port status
- Documents exact command and process tree

## Port Detection Considerations

### Current Detection Method

```python
def check_port_listening(port: int, timeout: float = 0.5) -> bool:
    """Check if a port is listening for connections."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex(('127.0.0.1', port))
        sock.close()
        return result == 0
    except:
        return False
```

### Alternative Detection Methods

1. **netstat parsing:**
   ```python
   subprocess.run(['netstat', '-an'], capture_output=True)
   # Parse output for ":6006" + "LISTENING"
   ```

2. **PowerShell:**
   ```python
   subprocess.run(['powershell', '-Command',
                   f'Get-NetTCPConnection -LocalPort {port} -State Listen'])
   ```

3. **Test-NetConnection (PowerShell):**
   ```python
   subprocess.run(['powershell', '-Command',
                   f'Test-NetConnection -ComputerName 127.0.0.1 -Port {port}'])
   ```

## Implementation Recommendations

### Immediate Action (High Priority)

1. **Modify godot_editor_server.py:**
   - Remove `creationflags=subprocess.CREATE_NO_WINDOW`
   - OR use `creationflags=0` explicitly
   - Let the Godot editor window show normally

2. **Test the change:**
   ```bash
   python godot_editor_server.py --auto-load-scene
   ```

3. **Verify ports:**
   ```bash
   # After 10 seconds
   netstat -an | findstr ":6006"
   netstat -an | findstr ":6005"
   ```

### Code Changes Required

**File:** `C:/godot/godot_editor_server.py`

**Line 91:** Change from:
```python
creationflags=subprocess.CREATE_NO_WINDOW
```

**To:**
```python
# REMOVED: creationflags parameter
# Let Godot editor window show normally - required for DAP/LSP
```

**Complete modified section:**
```python
# Platform-specific process creation
if platform.system() == "Windows":
    # CRITICAL: Don't use CREATE_NO_WINDOW for Godot editor
    # The editor GUI MUST be visible for DAP/LSP to initialize
    self.process = subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,  # Still suppress output
        stderr=subprocess.DEVNULL
    )
else:
    self.process = subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
```

### Alternative Implementation (If window must be hidden)

If the window MUST be hidden, use the console executable instead:

```python
# At module level
def find_godot_console_executable() -> Optional[str]:
    """Find Godot console executable."""
    console_locations = [
        "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe",
        "C:/Godot/Godot_v4.5.1-stable_win64_console.exe",
    ]

    for path in console_locations:
        if os.path.exists(path):
            return path
    return None

# In GodotProcessManager.__init__
def __init__(self, godot_path: str, project_path: str, ...):
    # Try to use console version if available
    console_path = find_godot_console_executable()
    if console_path:
        logger.info("Using console executable for better visibility")
        godot_path = console_path

    self.godot_path = godot_path
    # ... rest of init
```

## Why Manual Launch Works

When you double-click the Godot executable or use the batch script:

1. **Windows creates the process properly** - Respects the PE header flags
2. **GUI window initializes** - Full window manager integration
3. **Editor mode activates** - All editor subsystems start
4. **DAP/LSP bind to ports** - Editor debug servers initialize

When using `CREATE_NO_WINDOW`:

1. **Windows thinks it's a console app** - Suppresses all window creation
2. **GUI may not fully initialize** - Missing window context
3. **Editor mode may be incomplete** - Some subsystems don't start
4. **DAP/LSP don't initialize** - Debug servers require full editor

## Testing Plan

### Phase 1: Verify Hypothesis
1. Run `test_manual_launch.bat` - Confirm manual launch works
2. Check ports with netstat - Baseline confirmation

### Phase 2: Test Fixes
1. Modify `godot_editor_server.py` - Remove CREATE_NO_WINDOW
2. Run server - Test if ports now listen
3. Compare with manual launch - Should match behavior

### Phase 3: Validate
1. Run health checks - `python tests/health_monitor.py`
2. Test DAP connection - Use VS Code or similar
3. Test LSP connection - Try code completion requests
4. Full integration test - Run complete test suite

## References

### Documentation Quotes

From `CLAUDE.md`:
> **CRITICAL: The editor MUST run in GUI mode (non-headless). Running headless will cause the debug servers to stop responding.**

From `addons/godot_debug_connection/README.md`:
> **CRITICAL: MUST run in GUI mode (non-headless). Headless mode causes debug servers to stop responding.**

From Godot `--help`:
> `--dap-port <port>` [E] - Use the specified port for the GDScript Debug Adapter Protocol
>
> Legend: [E] Only available in editor builds.

### Related Files

- `C:/godot/godot_editor_server.py` - Main server implementation
- `C:/godot/restart_godot_with_debug.bat` - Current working launch script
- `C:/godot/CLAUDE.md` - Project documentation
- `C:/godot/NETWORK_DIAGNOSIS_2025-12-02.md` - Previous diagnostic report
- `C:/godot/ROOT_CAUSE_ANALYSIS_2025-12-02.md` - Related scene loading issue

## Conclusion

The root cause is **CREATE_NO_WINDOW interfering with GUI initialization**. The fix is simple: remove this flag and let the Godot editor window show normally.

**Recommended action:**
1. Modify `godot_editor_server.py` line 91
2. Remove `creationflags=subprocess.CREATE_NO_WINDOW`
3. Test with `python godot_editor_server.py`
4. Verify ports 6005 and 6006 are listening

**Expected result:** DAP and LSP servers will initialize and bind to their ports, enabling full debug protocol functionality.

---

## Appendix: Test Results

### Manual Launch Test Results
*(To be filled after running test_manual_launch.bat)*

### Automated Launch Test Results
*(To be filled after running test_godot_launch_methods.py)*

### Port Detection Comparison
*(To be filled after running test_port_detection.py)*
