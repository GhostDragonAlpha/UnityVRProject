# DAP/LSP Timing Investigation Report

**Date:** 2025-12-02
**Investigator:** Claude Code
**Issue:** DAP/LSP ports (6005, 6006) never start listening despite proper command line flags

---

## Executive Summary

After comprehensive testing over 180 seconds (3 minutes), **DAP and LSP ports NEVER became available**, even though:
- HTTP API (port 8080) started immediately (0.0s)
- Telemetry (port 8081) started immediately (0.0s)
- Godot editor was running with proper flags: `--editor --dap-port 6006 --lsp-port 6005`
- API consistently reported `debug_adapter_state: 0` (DISCONNECTED)
- API consistently reported `language_server_state: 0` (DISCONNECTED)

**Conclusion:** This is NOT a timing issue. The DAP/LSP servers are not starting at all.

---

## Test Results

### Test Configuration
- **Godot Version:** 4.5.1-stable
- **Test Duration:** 180 seconds (3 minutes)
- **Poll Interval:** 5 seconds
- **Total Polls:** 36
- **Command Line:** `godot --path C:/godot --dap-port 6006 --lsp-port 6005 --editor`

### Port Availability Timeline

| Service | Port | Available At | Status |
|---------|------|--------------|--------|
| HTTP API | 8080 | 0.0s | ✅ WORKING |
| Telemetry | 8081 | 0.0s | ✅ WORKING |
| DAP | 6006 | NEVER | ❌ NOT WORKING |
| LSP | 6005 | NEVER | ❌ NOT WORKING |

### State Tracking Over Time

Throughout all 36 polls (0-180 seconds):
- `debug_adapter_state` remained at **0 (DISCONNECTED)**
- `language_server_state` remained at **0 (DISCONNECTED)**
- `overall_ready` remained **false**
- Ports 6006 and 6005 never appeared in `netstat` output

### Last Known API Error

From `/status` endpoint:
```json
{
  "debug_adapter": {
    "last_error": "Connection timed out",
    "retry_count": 1,
    "state": 0
  }
}
```

---

## Analysis

### What Works
1. ✅ Godot process starts successfully
2. ✅ HTTP API server (GodotBridge) initializes immediately
3. ✅ Telemetry server initializes immediately
4. ✅ ConnectionManager loads and attempts to connect
5. ✅ DAPAdapter and LSPAdapter instantiate correctly

### What Doesn't Work
1. ❌ DAP server never starts listening on port 6006
2. ❌ LSP server never starts listening on port 6005
3. ❌ ConnectionManager can't connect to nonexistent servers
4. ❌ No state transition from DISCONNECTED (0)

### Root Cause Analysis

The issue is **NOT** timing-related. The DAP/LSP servers are fundamentally not starting. Possible causes:

#### 1. Command Line Flags Not Recognized (MOST LIKELY)
The `--dap-port` and `--lsp-port` flags may:
- Not exist in Godot 4.5.1
- Have different names
- Require additional flags to enable
- Only work in specific contexts

#### 2. Editor State Requirements
Based on research, DAP/LSP may require:
- Full editor GUI initialization (not just `--editor` flag)
- User interaction to enable debug mode
- Specific editor settings to be configured
- "Debug with External Editor" enabled in settings

#### 3. Build Configuration
The Godot build may:
- Not have DAP/LSP compiled in
- Require a special editor build
- Need additional plugins or modules

#### 4. Port Binding Issues
Less likely, but possible:
- Ports blocked by firewall (but should see connection refused, not timeout)
- Insufficient permissions to bind ports
- Port already in use (but API reports DISCONNECTED, not error)

---

## Evidence

### 1. Immediate HTTP/Telemetry Success
```
[   0.0s] HTTP API (8080) became available
[   0.0s] Telemetry (8081) became available
```
This proves Godot's autoload system works and network services can start.

### 2. Persistent DISCONNECTED State
Every poll from 0-180 seconds showed:
```json
{
  "debug_adapter_state": 0,  // DISCONNECTED
  "language_server_state": 0  // DISCONNECTED
}
```

### 3. No Port Activity
```bash
netstat -an | grep -E ":(6005|6006)"
# No results for 180 seconds
```

### 4. Connection Manager Code Analysis
From `C:\godot\addons\godot_debug_connection\connection_manager.gd`:
```gdscript
func connect_services() -> void:
    # Connect to DAP
    var dap_result = dap_adapter.connect_to_debug_adapter()
    # Connect to LSP
    var lsp_result = lsp_adapter.connect_to_language_server()
```

The ConnectionManager correctly attempts connections, but the servers don't exist.

### 5. DAPAdapter Connection Logic
From `C:\godot\addons\godot_debug_connection\dap_adapter.gd`:
```gdscript
func connect_to_debug_adapter(port: int = PRIMARY_DAP_PORT) -> Error:
    connection = StreamPeerTCP.new()
    var status = connection.connect_to_host("127.0.0.1", port)
```

Standard TCP connection to localhost - should work if server is listening.

---

## Research Findings

### Official Documentation
Based on web search results:

1. **LSP Support Added in Godot 4.2+**
   - `--lsp-port` flag added via PR #81844
   - Default port: 6005
   - Requires running editor instance

2. **DAP Support Added in Godot 4.2+**
   - Implemented via PR #50454
   - Default port varies (6006 or 6009 mentioned)
   - Requires "Debug with External Editor" enabled

3. **Editor GUI Requirement**
   - LSP can potentially run headless with special config
   - DAP requires editor to be running
   - Both are integrated into editor, not standalone servers

### Key Issue
From GitHub Issue #107880 and forum discussions:
> "When trying to run with `--headless --editor --lsp` flags, there was no output indicating that the LSP server was starting up."

This suggests DAP/LSP may **require full GUI editor**, not just `--editor` flag.

**Sources:**
- [LSP Command Line PR](https://github.com/godotengine/godot/pull/81844)
- [DAP Implementation PR](https://github.com/godotengine/godot/pull/50454)
- [Debug Server Issue](https://github.com/godotengine/godot/issues/94227)
- [JetBrains Rider Godot Docs](https://www.jetbrains.com/help/rider/Godot.html)

---

## Recommended Next Steps

### Immediate Investigation
1. **Verify command line flags exist:**
   ```bash
   C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe --help
   ```
   Look for `--dap-port` and `--lsp-port` in output

2. **Check Godot version capabilities:**
   - Confirm Godot 4.5.1 has DAP/LSP support
   - Check if special build is needed
   - Verify flags in official docs

3. **Test with manual GUI interaction:**
   - Launch Godot normally with flags
   - Wait for full GUI load
   - Check Editor Settings → Network → Debug Adapter
   - Enable "Debug with External Editor"
   - Check if ports start listening

4. **Check Godot console output:**
   - Look for DAP/LSP initialization messages
   - Check for errors or warnings
   - See what flags are actually recognized

### Configuration Changes to Test

#### Test 1: Different Port Flag Syntax
```bash
# Try with equals sign
--dap-port=6006 --lsp-port=6005

# Try without flags (use defaults)
--editor

# Try explicit LSP enable
--editor --lsp
```

#### Test 2: Editor Settings Prerequisite
```gdscript
# In project.godot or editor settings
[network]
debug_adapter/enabled = true
debug_adapter/port = 6006
language_server/enabled = true
language_server/port = 6005
```

#### Test 3: Debug Mode Flags
```bash
# Try enabling debug mode explicitly
--editor --debug --dap-port 6006 --lsp-port 6005

# Try verbose output
--editor --verbose --dap-port 6006 --lsp-port 6005
```

---

## Code Improvements Made

### 1. Created `test_dap_timing.py`
**Location:** `C:\godot\test_dap_timing.py`

Comprehensive test script that:
- Starts Godot with debug flags
- Polls ports every 5 seconds for up to 5 minutes
- Checks both `netstat` and `/status` endpoint
- Logs all state changes with timestamps
- Saves detailed JSON results

**Usage:**
```bash
python test_dap_timing.py --timeout 300
```

### 2. Created `godot_editor_server_enhanced.py`
**Location:** `C:\godot\godot_editor_server_enhanced.py`

Enhanced server with:
- `DAPConnectionWaiter` class that polls for `debug_adapter_state == 2`
- Configurable timeout (default: 60s)
- Detailed logging during wait with state transitions
- `--wait-for-dap` flag to block server start until DAP ready
- Separate tracking of HTTP API vs Debug services

**Usage:**
```bash
python godot_editor_server_enhanced.py --wait-for-dap --dap-timeout 60
```

**Key Features:**
```python
def wait_for_dap_connection(self) -> bool:
    """Wait for DAP to connect (debug_adapter_state == 2)."""
    # Polls every 5 seconds
    # Logs state changes: DISCONNECTED -> CONNECTING -> CONNECTED
    # Returns True if connected within timeout
```

---

## Current Server Behavior Analysis

### Original `godot_editor_server.py`

**Wait Logic:**
```python
# Line 103: Wait for Godot to initialize
time.sleep(5)
```

**Problem:**
- Only waits 5 seconds for process start
- No polling for DAP/LSP readiness
- Assumes services are ready if HTTP API is ready

### Health Monitoring Gap

The `HealthMonitor` class checks:
- ✅ Godot process running
- ✅ HTTP API responding
- ❌ **Does NOT check DAP/LSP state**

**Missing logic:**
```python
def _monitor_loop(self):
    # Should check:
    status = godot_api.request("GET", "/status")
    if status.get("overall_ready") == False:
        # Take action or log warning
```

---

## Timing Is NOT The Issue - Conclusion

### Why Increased Wait Time Won't Help

1. **No state progression observed**
   - State stayed at 0 (DISCONNECTED) for entire 180s test
   - No transition to 1 (CONNECTING) even briefly
   - Indicates connection never attempted by Godot

2. **Ports never bind**
   - `netstat` showed no LISTENING state on 6005/6006
   - Can't connect to ports that don't exist
   - No amount of waiting will make non-listening ports appear

3. **HTTP API works immediately**
   - Proves Godot can bind ports and start servers
   - Proves autoload system works
   - Proves timing is not an issue for working services

### What This Means

**The current hypothesis was:** "DAP/LSP need more time to initialize after GUI startup."

**The data shows:** "DAP/LSP servers are not starting at all, regardless of time."

**New hypothesis:** "Godot 4.5.1 is not actually starting DAP/LSP servers with the flags provided, possibly due to missing configuration, unrecognized flags, or editor state requirements."

---

## Enhanced Server Implementation Value

Despite timing not being the issue, the enhanced server is still valuable because:

1. **Proper Status Detection**
   - Can detect when/if DAP actually connects
   - Provides clear feedback to users
   - Distinguishes "not ready yet" from "will never be ready"

2. **Fail-Fast Behavior**
   - After timeout, clearly report DAP unavailable
   - Don't leave users wondering why debug features don't work
   - Can proceed with HTTP/Telemetry-only mode

3. **Future-Proof**
   - When DAP/LSP issue is fixed, server will work correctly
   - Polling logic is sound for actual slow-to-start services
   - Provides telemetry on actual connection times

---

## Recommended Implementation Strategy

### Phase 1: Diagnose Root Cause (HIGH PRIORITY)
1. Verify `--dap-port` and `--lsp-port` flags exist in Godot 4.5.1
2. Check if DAP/LSP require editor settings to be enabled
3. Test manual GUI interaction to enable debug servers
4. Review Godot console output for clues

### Phase 2: Implement Workarounds
1. **If flags don't exist:** Find correct flags or configuration method
2. **If settings required:** Auto-configure via GDScript on startup
3. **If GUI required:** Detect when GUI is ready, trigger connection then
4. **If not supported:** Document limitation, disable features gracefully

### Phase 3: Deploy Enhanced Server
1. Use `godot_editor_server_enhanced.py` with reasonable timeout (60s)
2. Clear error messages when DAP unavailable
3. Graceful degradation to HTTP/Telemetry-only mode
4. Log diagnostic info for further troubleshooting

---

## Test Data Reference

**Full results:** `C:\godot\dap_timing_results.json`
**Test logs:** `C:\godot\dap_timing_test.log`

**Key metrics:**
- HTTP API: Available at 0.0s ✅
- Telemetry: Available at 0.0s ✅
- DAP: Never available (0-180s) ❌
- LSP: Never available (0-180s) ❌
- Total polls: 36
- State changes: 0 (remained DISCONNECTED throughout)

---

## Conclusion

**Timing is definitively NOT the issue.** The DAP/LSP servers are not starting at all, regardless of wait time. The problem lies in:

1. Command line flags not being recognized/working
2. Missing editor configuration or settings
3. GUI state requirements not met
4. Build configuration issues

**Next Steps:**
1. Investigate Godot 4.5.1 DAP/LSP startup requirements
2. Test with manual GUI interaction
3. Check Godot help output and documentation
4. Implement proper detection and error reporting

**The enhanced server with DAP polling is still valuable** for detecting and reporting this issue clearly, but increasing timeout beyond 60 seconds is pointless until the underlying configuration issue is resolved.

---

**End of Report**
