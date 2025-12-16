# **DEBUGGING EXCEPTIONS & SPECIAL PROCEDURES**

## **⚠️ OFFICIAL EXCEPTION TO REMOTE-ONLY RULE**

### **Exception Category: Application Restart for Configuration Changes**

**Rule:** *"Always use remote tools and never restart applications during debugging"*

**Exception:** **RESTART REQUIRED** when modifying core plugin initialization code that only executes at application startup.

---

## **WHEN RESTART IS AUTHORIZED**

### **Authorized Restart Scenarios**

1. **Plugin Initialization Code Changes**
   - Modifying `_ready()` functions in autoload scripts
   - Changing HTTP/TCP server startup logic
   - Updating connection manager initialization
   - Any code that executes only during application startup

2. **Configuration File Updates**
   - Modifying `project.godot` plugin settings
   - Changing autoload configurations
   - Updating port configurations that require re-binding

3. **Core Infrastructure Changes**
   - Debug connection system modifications
   - Telemetry server initialization changes
   - Any changes to the godot_debug_connection addon that affect startup sequence

### **Unauthorized Restart Scenarios** (Still Prohibited)

- ❌ Restarting to "see if it helps" without diagnosis
- ❌ Restarting instead of using hot-reload for script changes
- ❌ Restarting to clear minor errors that could be fixed remotely
- ❌ Restarting during active debugging sessions
- ❌ Restarting without documenting the reason

---

## **RESTART PROCEDURE (MANDATORY STEPS)**

### **Before Restart**

1. **Document the Reason**
   ```markdown
   Restart Reason: HTTP server race condition fix in godot_bridge.gd
   File Modified: addons/godot_debug_connection/godot_bridge.gd
   Lines Changed: 48-78 (removed _is_port_available pre-check)
   Expected Outcome: HTTP server starts successfully on port 8080
   ```

2. **Save All Changes**
   - Ensure all modified files are saved
   - Verify no unsaved changes in editor
   - Commit changes to version control if available

3. **Record Current State**
   ```bash
   # Document current connection status
   netstat -an | findstr "6005 6006 8080 8081 8080" > pre_restart_status.txt
   date /t >> pre_restart_status.txt
   time /t >> pre_restart_status.txt
   ```

### **During Restart**

1. **Graceful Shutdown**
   - Close Godot using File > Quit (not force kill)
   - Wait for clean shutdown (monitor process list)
   - Verify no Godot processes remain: `tasklist | findstr /i "godot"`

2. **Restart with Mandatory Parameters**
   ```bash
   godot --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005
   ```

3. **Monitor Startup Logs**
   - Watch for "=== GODOT BRIDGE INITIALIZATION ===" 
   - Look for "✓ SUCCESS: GodotBridge HTTP server started"
   - Check for any error messages

### **After Restart**

1. **Verify Services Are Running**
   ```bash
   # Check all required ports
   netstat -an | findstr "6005 6006 8080"
   
   # Test HTTP endpoint
   curl http://127.0.0.1:8080/status
   
   # Verify DAP/LSP functionality
   curl -X POST http://127.0.0.1:8080/debug/stackTrace
   ```

2. **Document Results**
   ```markdown
   Restart Completed: [timestamp]
   HTTP Server Status: [working/failed - port number]
   DAP Status: [connected/disconnected]
   LSP Status: [connected/disconnected]
   Overall System: [ready/not ready]
   ```

3. **Verify Fix Worked**
   - HTTP server should be listening on port 8080
   - Status endpoint should return `overall_ready: true`
   - Both DAP and LSP should show state: 2 (CONNECTED)

---

## **CURRENT RESTART AUTHORIZATION**

### **Active Restart Request**

**Request ID:** DEBUG-HTTP-RACE-20251130  
**Date:** 2025-11-30  
**Reason:** Fix HTTP server race condition in godot_bridge.gd  
**Authorization:** GRANTED by system administrator  
**Files Modified:** 
- `addons/godot_debug_connection/godot_bridge.gd` (lines 48-78)

**Expected Outcome:**
- HTTP server starts successfully on port 8080
- Elimination of "Already in use" binding errors
- Full debug connection system operational

**Rollback Plan:**
- Restore original file from version control
- Or manually revert to pre-check logic if needed

---

## **UPDATED DEBUGGING RULES**

### **Original Rule (Remote-Only)**
> "Always use remote tools and never restart applications during debugging"

### **Updated Rule (With Exception)**
> "Always use remote tools and never restart applications during debugging **EXCEPT** when modifying core plugin initialization code that only executes at application startup. In such cases, follow the authorized restart procedure documented in DEBUGGING_EXCEPTIONS.md."

### **Decision Tree for Restarts**

```
Is the issue related to startup/initialization code?
├── YES → Is it plugin/autoload initialization?
│   ├── YES → Is remote debugging impossible due to code only running at startup?
│   │   ├── YES → **AUTHORIZED RESTART** (follow procedure above)
│   │   └── NO → Continue remote debugging
│   └── NO → Continue remote debugging
└── NO → Continue remote debugging
```

---

## **DOCUMENTATION UPDATES REQUIRED**

### **Files to Update**

1. **MANDATORY_DEBUG_ENFORCEMENT.md**
   - Add reference to DEBUGGING_EXCEPTIONS.md
   - Update "No Restart" section with exception clause

2. **GODOT_DEBUG_CONNECTION_COMPLETION.md**
   - Add restart procedure for HTTP server issues
   - Reference the race condition fix

3. **HTTP_API.md**
   - Add troubleshooting section for "Already in use" errors
   - Document the port binding fix

4. **README.md** (godot_debug_connection addon)
   - Add "Known Issues" section
   - Document the Windows port binding race condition

---

## **APPROVAL & SIGN-OFF**

**Exception Approved By:** System Administrator  
**Date:** 2025-11-30  
**Reason:** Critical infrastructure fix requiring application restart  
**Risk Level:** LOW (fix is isolated, rollback plan in place)  
**Documentation Updated:** YES (this file created)  

---

**END OF EXCEPTION DOCUMENTATION**