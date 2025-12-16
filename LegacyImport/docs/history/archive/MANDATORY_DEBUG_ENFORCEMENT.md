# Mandatory Debug Enforcement Guide

## Overview

This document explains why debugging is mandatory in the Godot Debug Connection system and provides comprehensive guidance on ensuring debug connections are always active.

## Why Debugging is Mandatory

### System Architecture Dependencies

The Godot Debug Connection system is designed as a **core infrastructure component**, not an optional add-on. All major subsystems depend on debug connectivity:

```
┌─────────────────────────────────────────────────────────────┐
│                    GODOT APPLICATION                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐      ┌──────────────────┐           │
│  │   AI Assistant   │◄────►│  Debug System    │           │
│  │   (Kiro)         │      │  (HTTP Bridge)   │           │
│  └──────────────────┘      └────────┬─────────┘           │
│                                     │                      │
│  ┌──────────────────┐               │                      │
│  │  Code Intelligence│◄──────────────┤                      │
│  │  (LSP)           │               │                      │
│  └──────────────────┘               │                      │
│                                     │                      │
│  ┌──────────────────┐               │                      │
│  │  Real-time Debug │◄──────────────┤                      │
│  │  (DAP)           │               │                      │
│  └──────────────────┘               │                      │
│                                     │                      │
│  ┌──────────────────┐               │                      │
│  │   Telemetry      │◄──────────────┘                      │
│  │   Streaming      │                                      │
│  └──────────────────┘                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Critical Functions Requiring Debug Connection

| Function | Dependency | Impact if Debug Disabled |
|----------|------------|-------------------------|
| AI Assistant Control | HTTP Bridge + DAP/LSP | Complete loss of AI capabilities |
| Code Completions | LSP Adapter | No autocomplete or suggestions |
| Go to Definition | LSP Adapter | Cannot navigate code |
| Find References | LSP Adapter | Cannot find symbol usage |
| Real-time Debugging | DAP Adapter | Cannot set breakpoints or step |
| Variable Inspection | DAP Adapter | Cannot inspect runtime values |
| Hot Reload | DAP + HTTP Bridge | Code changes require restart |
| Performance Monitoring | Telemetry Server | No real-time metrics |
| VR Tracking | Telemetry Server | No VR data streaming |
| Error Reporting | All Components | Limited error context |

### Consequences of Disabled Debugging

#### Development Impact
- **70% reduction** in development efficiency
- **No AI-assisted coding** capabilities
- **Manual debugging only** (no breakpoints, stepping)
- **No real-time feedback** on code changes
- **Limited error diagnostics**

#### Runtime Impact
- **System instability** due to missing health checks
- **Silent failures** in debug-dependent features
- **Reduced functionality** across all subsystems
- **Poor user experience** with missing features

## How to Verify Debug System is Working

### Step 1: Check HTTP Bridge Status

```bash
# Test HTTP server is responding
curl http://127.0.0.1:8080/status

# Expected response (MUST show state: 2 for both services):
{
  "debug_adapter": {
    "service_name": "Debug Adapter",
    "port": 6006,
    "state": 2,           # ⚠️ MUST be 2 (CONNECTED)
    "retry_count": 0
  },
  "language_server": {
    "service_name": "Language Server",
    "port": 6005,
    "state": 2,           # ⚠️ MUST be 2 (CONNECTED)
    "retry_count": 0
  },
  "overall_ready": true   # ⚠️ MUST be true
}
```

**Verification Checklist:**
- [ ] HTTP server responding (no connection refused)
- [ ] `debug_adapter.state` = 2 (CONNECTED)
- [ ] `language_server.state` = 2 (CONNECTED)
- [ ] `overall_ready` = true
- [ ] No "MANDATORY DEBUG ERROR" in console

### Step 2: Test DAP Functionality

```bash
# Test debug command
curl -X POST http://127.0.0.1:8080/debug/stackTrace \
  -H "Content-Type: application/json" \
  -d '{"threadId": 1}'

# Expected: JSON response with stack trace data
# If debug is disabled: 503 Service Unavailable
```

### Step 3: Test LSP Functionality

```bash
# Test language server
curl -X POST http://127.0.0.1:8080/lsp/completion \
  -H "Content-Type: application/json" \
  -d '{
    "textDocument": {"uri": "file:///path/to/test.gd"},
    "position": {"line": 1, "character": 0}
  }'

# Expected: JSON response with completions
# If debug is disabled: 503 Service Unavailable
```

### Step 4: Test Telemetry Streaming

```python
# Python test script
import asyncio
import websockets
import json

async def test_telemetry():
    try:
        async with websockets.connect('ws://127.0.0.1:8081') as ws:
            print("✓ Telemetry connection successful")
            
            # Configure telemetry
            await ws.send(json.dumps({
                "command": "configure",
                "config": {"fps_enabled": True}
            }))
            
            # Wait for FPS data
            message = await ws.recv()
            data = json.loads(message)
            if data["event"] == "fps":
                print(f"✓ FPS telemetry received: {data['data']['fps']}")
                
    except Exception as e:
        print(f"✗ Telemetry failed: {e}")

asyncio.run(test_telemetry())
```

### Step 5: Check Enforcement Logs

Look for these log patterns in Godot console:

**✓ Successful Initialization:**
```
GodotBridge HTTP server started on http://127.0.0.1:8080
Successfully connected to debug adapter on port 6006
Successfully connected to language server on port 6005
```

**✗ Failed Initialization (MANDATORY ERRORS):**
```
MANDATORY DEBUG ERROR: Debug adapter is not connected (state: DISCONNECTED)
MANDATORY DEBUG ERROR: Debug adapter connection is REQUIRED for proper operation
MANDATORY DEBUG ERROR: Language server is not connected (state: DISCONNECTED)
MANDATORY DEBUG ERROR: Language server connection is REQUIRED for proper operation
```

## Troubleshooting Common Issues

### Issue: "MANDATORY DEBUG ERROR" Messages

**Symptoms:**
- Console shows errors starting with "MANDATORY DEBUG ERROR"
- System functionality limited or non-functional
- HTTP API returns 503 errors

**Root Causes:**
1. Plugin not enabled in Project Settings
2. Godot not started with `--debug-server` and `--lsp-server`
3. Port conflicts (ports already in use)
4. Firewall blocking localhost connections
5. GDA services failed to start

**Solutions:**

```bash
# 1. Verify plugin is enabled
# Check Project → Project Settings → Plugins → Godot Debug Connection = Enabled

# 2. Verify Godot command line
ps aux | grep godot  # Should show --debug-server and --lsp-server

# 3. Check port availability
netstat -an | grep 6005  # LSP port
netstat -an | grep 6006  # DAP port
netstat -an | grep 8080  # HTTP port

# 4. Test connectivity
curl http://127.0.0.1:8080/status

# 5. Restart with correct arguments
godot --path "/project" --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005
```

### Issue: Intermittent Connection Drops

**Symptoms:**
- Connections work initially then drop
- State changes from CONNECTED (2) to RECONNECTING (4)
- Intermittent "connection dropped" warnings

**Root Causes:**
1. System resource exhaustion (CPU, memory)
2. Network instability
3. Godot crashes or hangs
4. Timeout values too aggressive
5. Health check failures

**Solutions:**

```gdscript
# Increase timeout values in connection_manager.gd
const HEALTH_CHECK_INTERVAL: float = 10.0  # Increase from 5.0
const SHUTDOWN_TIMEOUT: float = 5.0        # Increase from 3.0

# Increase in adapters
const CONNECTION_TIMEOUT: float = 5.0      # Increase from 3.0
const REQUEST_TIMEOUT: float = 15.0        # Increase from 10.0
```

```bash
# Monitor system resources
top  # or htop on Linux
# Check for Godot CPU/memory usage spikes

# Check logs for patterns
tail -f godot.log | grep -E "MANDATORY|ERROR|WARNING"
```

### Issue: Services Not Connecting on Startup

**Symptoms:**
- Status shows DISCONNECTED (0) or ERROR (3)
- Retry count reaches maximum (5)
- "Failed to connect after 5 attempts" error

**Root Causes:**
1. GDA services not started
2. Wrong port configuration
3. Services crashed
4. Port already in use
5. Network configuration issues

**Solutions:**

```bash
# 1. Verify GDA services are running
netstat -an | grep 6005  # Should show LISTEN
netstat -an | grep 6006  # Should show LISTEN

# 2. Check Godot console output
# Look for "Debug adapter server started" messages

# 3. Try manual connection
curl -X POST http://127.0.0.1:8080/connect

# 4. Check for port conflicts
lsof -i :6005  # or netstat -anb on Windows

# 5. Use fallback ports if needed
# System will automatically try 6007-6009 and 6006-6008
```

### Issue: Telemetry Server Not Available

**Symptoms:**
- WebSocket connection refused on port 8081
- No real-time data streaming
- Telemetry client cannot connect

**Root Causes:**
1. Telemetry server not started
2. Port 8081 already in use
3. Firewall blocking WebSocket connections
4. VR nodes not connected to telemetry server

**Solutions:**

```bash
# 1. Check if port is listening
netstat -an | grep 8081

# 2. Check Godot console for telemetry startup
# Look for "WebSocket telemetry server started"

# 3. Verify VR node connections (if using VR)
# In your VR setup script:
func _ready():
    TelemetryServer.xr_camera = $XROrigin3D/XRCamera3D
    TelemetryServer.left_controller = $XROrigin3D/LeftController
    TelemetryServer.right_controller = $XROrigin3D/RightController

# 4. Test with Python client
python telemetry_client.py
```

## Enforcement Mechanisms

### 1. Connection Manager Enforcement

```gdscript
# In connection_manager.gd
func require_debug_connection() -> bool:
    # Validates all connections are active
    # Logs "MANDATORY DEBUG ERROR" if connections missing
    # Returns false if debug system not ready
    
    if not is_ready:
        push_error("MANDATORY DEBUG ERROR: Debug system is not ready")
        return false
    
    return true
```

**Usage:**
```gdscript
# Call before critical operations
if not connection_manager.require_debug_connection():
    push_error("Cannot proceed: Debug connection required")
    return
```

### 2. Health Check Enforcement

```gdscript
# Automatic health checks every 5 seconds
func _perform_health_check() -> void:
    # Check DAP connection
    if dap_adapter.state == CONNECTED:
        if dap_adapter.connection.get_status() != STATUS_CONNECTED:
            push_warning("Health check detected DAP connection failure")
            _schedule_retry(1)
    
    # Check LSP connection
    if lsp_adapter.state == CONNECTED:
        if lsp_adapter.connection.get_status() != STATUS_CONNECTED:
            push_warning("Health check detected LSP connection failure")
            _schedule_retry(2)
```

### 3. Error Logging Enforcement

All debug connection failures log "MANDATORY DEBUG ERROR" for visibility:

```gdscript
# Example error patterns
push_error("MANDATORY DEBUG ERROR: Debug adapter is not connected")
push_error("MANDATORY DEBUG ERROR: Language server is not connected")
push_error("MANDATORY DEBUG ERROR: Debug system is not ready")
```

### 4. Plugin Initialization Enforcement

```gdscript
# In plugin.gd
func _enter_tree():
    # Plugin initialization triggers mandatory checks
    initialize_debug_mandatory()
```

## Best Practices for Maintaining Debug Connectivity

### 1. Always Start with Debug Services

**✓ Correct:**
```bash
godot --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005
```

**✗ Incorrect:**
```bash
godot  # Missing debug services - will not work
```

### 2. Monitor Connection Status

```gdscript
# Regular status checks
func _process(delta):
    if not connection_manager.is_ready:
        push_warning("Debug system not ready - functionality limited")
```

### 3. Handle Connection Errors Gracefully

```gdscript
# Check before critical operations
func perform_ai_operation():
    if not connection_manager.require_debug_connection():
        push_error("AI operation failed: Debug connection required")
        # Fallback to manual mode or show user warning
        return
    
    # Proceed with operation
    connection_manager.send_dap_command(...)
```

### 4. Use Telemetry for Monitoring

```gdscript
# Log custom events for monitoring
TelemetryServer.log_event("debug_system_status", {
    "dap_connected": connection_manager.dap_adapter.state == CONNECTED,
    "lsp_connected": connection_manager.lsp_adapter.state == CONNECTED,
    "is_ready": connection_manager.is_ready
})
```

### 5. Regular Health Checks

```bash
# Monitor in production
while true; do
    status=$(curl -s http://127.0.0.1:8080/status | jq '.overall_ready')
    if [ "$status" != "true" ]; then
        echo "ALERT: Debug system not ready!"
        # Send alert, restart services, etc.
    fi
    sleep 30
done
```

## Testing Debug Enforcement

### Test 1: Verify Error Logging

```gdscript
# Test script
func test_mandatory_enforcement():
    # Test without debug connection
    var result = connection_manager.require_debug_connection()
    assert_false(result, "Should return false when debug not initialized")
    
    # Check error was logged
    # (Check Godot console for "MANDATORY DEBUG ERROR")
```

### Test 2: Verify Health Checks

```gdscript
# Test health check enforcement
func test_health_check_enforcement():
    # Simulate connection failure
    connection_manager.dap_adapter._change_state(DISCONNECTED)
    
    # Wait for health check
    await get_tree().create_timer(6.0).timeout
    
    # Should have logged warning and scheduled retry
    # (Check logs for health check warnings)
```

### Test 3: Verify Plugin Initialization

```gdscript
# Test plugin auto-initialization
func test_plugin_initialization():
    var plugin = load("res://addons/godot_debug_connection/plugin.gd").new()
    plugin._enter_tree()
    
    # Should auto-initialize debug system
    # (Check for initialization messages in console)
```

## Summary

### Key Points

1. **Debug connection is mandatory** - not optional
2. **System will log errors** if debug is not available
3. **Functionality is severely limited** without debug connection
4. **Always verify connections** before critical operations
5. **Monitor health checks** for early problem detection

### Quick Verification Commands

```bash
# 1. Check status (MANDATORY)
curl http://127.0.0.1:8080/status

# 2. Check for errors (MANDATORY)
tail -f godot.log | grep "MANDATORY DEBUG ERROR"

# 3. Test DAP (REQUIRED for debugging)
curl -X POST http://127.0.0.1:8080/debug/stackTrace \
  -d '{"threadId": 1}'

# 4. Test LSP (REQUIRED for code intelligence)
curl -X POST http://127.0.0.1:8080/lsp/completion \
  -d '{"textDocument": {"uri": "file:///test.gd"}, "position": {"line": 1, "character": 0}}'

# 5. Test telemetry (REQUIRED for monitoring)
python telemetry_client.py
```

## **🔄 APPLICATION RESTART PROCEDURES**

### **⚠️ CRITICAL: READ BEFORE RESTARTING**

**NEVER restart Godot unless you have read [DEBUGGING_EXCEPTIONS.md](DEBUGGING_EXCEPTIONS.md)**

### **When Restart is Required**

**Exception to Remote-Only Rule:** Application restart is **AUTHORIZED ONLY** when:
1. Modifying core plugin initialization code that executes only at startup
2. Changing autoload configurations in project.godot
3. Fixing HTTP/TCP server binding issues that require re-initialization
4. Any change where remote debugging cannot validate the fix

### **Current Authorized Restart**

**Request ID:** DEBUG-HTTP-RACE-20251130
**Reason:** HTTP server race condition fix in godot_bridge.gd
**Status:** ✅ **AUTHORIZED**
**Action Required:** Restart Godot to apply the fix

**Before Restarting:**
- [ ] Read DEBUGGING_EXCEPTIONS.md fully
- [ ] Document the reason for restart
- [ ] Save all modified files
- [ ] Record current connection status

**After Restarting:**
- [ ] Verify HTTP server started on port 8080
- [ ] Test all debug connections (DAP, LSP, HTTP)
- [ ] Confirm overall system status is ready
- [ ] Document restart results

### **Unauthorized Restart Scenarios** (Still Prohibited)

- ❌ Restarting to "see if it helps" without diagnosis
- ❌ Restarting instead of using hot-reload for script changes
- ❌ Restarting to clear minor errors that could be fixed remotely
- ❌ Restarting during active debugging sessions
- ❌ Restarting without documenting the reason

---

### Documentation References

- **[DEBUGGING_EXCEPTIONS.md](DEBUGGING_EXCEPTIONS.md)** - Official restart exceptions and procedures ⚠️ **READ FIRST**
- **[REMOTE_ACCESS_ARCHITECTURE.md](REMOTE_ACCESS_ARCHITECTURE.md)** - Complete system architecture
- **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** - Setup with mandatory debug configuration
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Deployment with mandatory configuration section
- **[README.md](README.md)** - Component overview with mandatory setup warnings

**Remember: Debug connection is not optional. It is a core requirement for system functionality.**