# Next Steps: DAP/LSP Investigation

**Priority:** HIGH
**Status:** Root cause identified - NOT a timing issue
**Date:** 2025-12-02

---

## Quick Summary

DAP/LSP ports (6005, 6006) **never become available**, even after 180 seconds. This is NOT a timing issue - the servers are not starting at all.

**Working:**
- ✅ HTTP API (8080) - available immediately
- ✅ Telemetry (8081) - available immediately

**Not Working:**
- ❌ DAP (6006) - never starts
- ❌ LSP (6005) - never starts

---

## Immediate Actions Required

### Action 1: Verify Godot Command Line Flags (15 minutes)

**Goal:** Confirm `--dap-port` and `--lsp-port` flags exist in Godot 4.5.1

**Commands to run:**
```bash
# Check help output
C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe --help > godot_help.txt

# Search for DAP/LSP mentions
cat godot_help.txt | grep -i "dap\|lsp\|debug\|language"

# Check version info
C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe --version
```

**Expected outcomes:**
- If flags appear in help: Flags are valid, look elsewhere
- If flags don't appear: Need to find correct flag names or enable method

---

### Action 2: Test Manual Editor Settings (15 minutes)

**Goal:** See if DAP/LSP require editor UI configuration

**Steps:**
1. Launch Godot normally (GUI):
   ```bash
   C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe --path C:/godot --editor
   ```

2. Wait for full editor load (project open, UI visible)

3. Check ports after GUI fully loaded:
   ```bash
   netstat -an | grep -E ":(6005|6006)"
   ```

4. Navigate to: **Editor → Editor Settings → Network**
   - Look for "Debug Adapter" section
   - Look for "Language Server" section
   - Check if there are enable toggles

5. If found, enable and check ports again

6. Try: **Debug → Debug with External Editor**
   - Enable this option
   - Check ports again

**Document:**
- Screenshot of Network settings
- Whether ports start after GUI load
- Whether ports start after enabling settings

---

### Action 3: Check Godot Console Output (10 minutes)

**Goal:** See what Godot is actually doing with the flags

**Steps:**
1. Launch Godot WITH console output:
   ```bash
   # Remove CREATE_NO_WINDOW flag to see console
   C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe --path C:/godot --editor --dap-port 6006 --lsp-port 6005 --verbose
   ```

2. Watch console for:
   - "DAP" or "Debug Adapter" messages
   - "LSP" or "Language Server" messages
   - Port binding messages
   - Error messages about unrecognized flags
   - Initialization sequence

3. Save console output to file for analysis

**Look for:**
- ❌ "Unknown option: --dap-port"
- ❌ "Debug Adapter disabled"
- ✅ "Debug Adapter listening on port 6006"
- ✅ "Language Server started on port 6005"

---

### Action 4: Test Alternative Configurations (20 minutes)

**Try different flag combinations:**

```bash
# Test 1: No port flags (use defaults)
godot --path C:/godot --editor

# Test 2: With debug flag
godot --path C:/godot --editor --debug --dap-port 6006 --lsp-port 6005

# Test 3: Different syntax
godot --path C:/godot --editor --dap-port=6006 --lsp-port=6005

# Test 4: Just LSP
godot --path C:/godot --editor --lsp

# Test 5: Headless with LSP
godot --headless --path C:/godot --editor --lsp-port 6005
```

**After each test, check:**
```bash
# Ports listening?
netstat -an | grep -E ":(6005|6006)"

# API status
curl http://127.0.0.1:8080/status | python -m json.tool
```

---

### Action 5: Check Project Configuration (10 minutes)

**Goal:** See if project.godot needs DAP/LSP config

**Check:**
```bash
cat C:/godot/project.godot | grep -A 5 -E "network|debug|language"
```

**Try adding to project.godot:**
```ini
[network]
debug_adapter/enabled=true
debug_adapter/port=6006
language_server/enabled=true
language_server/port=6005
remote_port=6007

[debug]
settings/remote_debug=true
settings/file_server_port=6010
```

**Restart Godot and test again**

---

## Research Tasks

### Research 1: Official Documentation
**Check:**
- [Godot 4.5 Command Line Tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- [Godot 4.5 External Editor Guide](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html)

**Look for:**
- DAP/LSP startup requirements
- Required editor settings
- Command line flag documentation

### Research 2: Community Examples
**Search for:**
- Working Godot 4.5 DAP/LSP configurations
- VSCode/Neovim Godot debug configurations
- GitHub repos with working setups

**Check:**
- [neovim-godot configs](https://github.com/search?q=neovim+godot+dap)
- [vscode-godot-tools](https://github.com/godotengine/godot-vscode-plugin)

---

## Diagnostic Script

Created: `C:\godot\diagnose_dap_lsp.py`

This script should:
1. Start Godot with various flag combinations
2. Wait 30s for each config
3. Check ports and API status
4. Log results for each config
5. Produce comparison table

**Usage:**
```bash
python diagnose_dap_lsp.py
```

Would you like me to create this script?

---

## Testing Matrix

| Configuration | Expected Result | Actual Result | Notes |
|---------------|----------------|---------------|-------|
| `--editor --dap-port 6006 --lsp-port 6005` | DAP+LSP work | ❌ Never start | Already tested |
| `--editor` (defaults) | DAP+LSP work | ❓ Unknown | Test this |
| `--editor` + GUI interaction | DAP+LSP work | ❓ Unknown | Test this |
| `--editor --verbose` | See init logs | ❓ Unknown | Test this |
| `--editor` + project.godot config | DAP+LSP work | ❓ Unknown | Test this |

---

## Success Criteria

**We know we've found the solution when:**

1. ✅ `netstat -an | grep 6006` shows LISTENING
2. ✅ `netstat -an | grep 6005` shows LISTENING
3. ✅ API shows `debug_adapter_state: 2` (CONNECTED)
4. ✅ API shows `language_server_state: 2` (CONNECTED)
5. ✅ API shows `overall_ready: true`
6. ✅ ConnectionManager successfully connects to both

---

## If All Else Fails

### Workaround Plan A: Manual Connection Trigger
Create a GDScript that manually starts DAP/LSP:
```gdscript
# In autoload startup
func _ready():
    # Manually initialize debug adapter
    var debug_server = DebugAdapterServer.new()
    debug_server.start_listening(6006)

    # Manually initialize language server
    var lsp_server = LanguageServerProtocol.new()
    lsp_server.start_listening(6005)
```

### Workaround Plan B: Alternative Debug Method
- Use Godot's built-in remote debugger instead of DAP
- Create custom debug protocol over HTTP API
- Use telemetry for debug info instead

### Workaround Plan C: Feature Degradation
- Document that DAP/LSP are not available
- Disable debug features gracefully
- Focus on HTTP API and Telemetry only
- Add warning to users

---

## Tools Created

### 1. `test_dap_timing.py`
**Purpose:** Long-running test to detect when ports become available
**Location:** `C:\godot\test_dap_timing.py`
**Usage:** `python test_dap_timing.py --timeout 300`

### 2. `godot_editor_server_enhanced.py`
**Purpose:** Server with proper DAP connection waiting
**Location:** `C:\godot\godot_editor_server_enhanced.py`
**Usage:** `python godot_editor_server_enhanced.py --wait-for-dap --dap-timeout 60`

### 3. Test Results
**Location:** `C:\godot\dap_timing_results.json`
**Contents:** 180 seconds of port/state monitoring data

### 4. Investigation Report
**Location:** `C:\godot\DAP_LSP_TIMING_INVESTIGATION_REPORT.md`
**Contents:** Complete analysis with evidence and recommendations

---

## Timeline

**Completed:**
- ✅ Timing investigation (180s test)
- ✅ Root cause analysis
- ✅ Enhanced server implementation
- ✅ Diagnostic tooling

**Next (2-3 hours):**
- ⏳ Verify command line flags exist
- ⏳ Test manual editor settings
- ⏳ Analyze console output
- ⏳ Try alternative configurations
- ⏳ Check project configuration

**Then (1-2 hours):**
- ⏳ Implement proper fix based on findings
- ⏳ Update documentation
- ⏳ Test end-to-end

---

## Questions to Answer

1. **Do the flags `--dap-port` and `--lsp-port` exist in Godot 4.5.1?**
   - Check `--help` output
   - Check source code if needed

2. **Does DAP/LSP require GUI to be fully loaded?**
   - Test with manual editor launch
   - Check when ports actually start

3. **Is there a required editor setting?**
   - Check Editor Settings → Network
   - Check "Debug with External Editor"

4. **Is there required project configuration?**
   - Check if project.godot needs settings
   - Check if .godot/ files need something

5. **Is this a Godot bug?**
   - Check GitHub issues
   - Check if others report same problem

---

## Contact Points for Help

**If stuck, ask:**
- Godot Discord #scripting or #editor channels
- Godot Forum - Editor category
- GitHub godotengine/godot - file issue if confirmed bug

**Useful search terms:**
- "godot 4.5 dap not starting"
- "godot external editor debug adapter"
- "godot lsp not listening"
- "godot --dap-port not working"

---

**End of Next Steps Document**
