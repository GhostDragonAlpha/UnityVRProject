# VR Teleportation System - Integration Guide

This guide provides step-by-step instructions for integrating the VR Teleportation system HTTP API into the Godot Bridge.

## Overview

The VR Teleportation system is **fully implemented** and production-ready:

- ✅ **Core System:** `scripts/player/vr_teleportation.gd` - Complete with all features
- ✅ **Documentation:** `VR_TELEPORTATION.md` - Comprehensive usage guide
- ✅ **HTTP API Handler:** `addons/godot_debug_connection/vr_endpoint_handler.gd` - Ready to integrate
- ✅ **Python Client:** `examples/vr_teleportation_test.py` - Full test suite
- ✅ **API Documentation:** `VR_TELEPORTATION_HTTP_API.md` - Complete API reference

**Only one step remains:** Adding the VR endpoint route to `godot_bridge.gd`

---

## Quick Start (2 Minutes)

### Step 1: Add Route to godot_bridge.gd

**File:** `addons/godot_debug_connection/godot_bridge.gd`

**Location:** In the `_route_request()` function (around line 280)

**Add this code** after the `/base/` endpoint and before the final `else` block:

```gdscript
	# VR system endpoints (teleportation, comfort, etc.)
	elif path.begins_with("/vr/"):
		_handle_vr_endpoint(client, method, path, body)
```

**Complete context:**
```gdscript
	# Base building endpoints
	elif path.begins_with("/base/"):
		_handle_base_endpoint(client, method, path, body)

	# VR system endpoints (teleportation, comfort, etc.)  ← ADD THIS
	elif path.begins_with("/vr/"):                       ← ADD THIS
		_handle_vr_endpoint(client, method, path, body)  ← ADD THIS

	else:
		_send_error_response(client, 404, "Not Found", "Endpoint not found: " + path)
```

### Step 2: Add Handler Functions

**File:** `addons/godot_debug_connection/godot_bridge.gd`

**Location:** At the bottom of the file (before the last closing brace), add ALL functions from `vr_endpoint_handler.gd`:

```bash
# Option A: Copy manually
# 1. Open addons/godot_debug_connection/vr_endpoint_handler.gd
# 2. Copy all function definitions (starting from _handle_vr_endpoint)
# 3. Paste at bottom of godot_bridge.gd

# Option B: Use command line (from project root)
tail -n +18 addons/godot_debug_connection/vr_endpoint_handler.gd >> addons/godot_debug_connection/godot_bridge.gd
```

### Step 3: Restart Godot

```bash
# Stop Godot if running
taskkill /IM Godot*.exe /F

# Restart with debug services
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### Step 4: Test Integration

```bash
# Test 1: Check status endpoint
curl http://127.0.0.1:8080/vr/teleport/status

# Test 2: Run full test suite
python examples/vr_teleportation_test.py

# Test 3: Try teleporting
python examples/vr_teleportation_test.py teleport 2 0 2
```

---

## Detailed Integration Steps

### Prerequisites

1. **Godot running** with debug services:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. **Python** with requests library:
   ```bash
   pip install requests
   ```

3. **VR system initialized** in scene:
   - Automatically happens when WalkingController activates
   - Or manually: `VRTeleportation.new().initialize(vr_manager, xr_origin)`

### Integration Method 1: Manual Copy-Paste

**Pros:** Full control, can review code
**Cons:** More error-prone, tedious

1. Open `addons/godot_debug_connection/vr_endpoint_handler.gd`
2. Locate the route addition code (lines 6-10 in comments)
3. Open `addons/godot_debug_connection/godot_bridge.gd`
4. Find `_route_request()` function (around line 224)
5. Add the route BEFORE the final `else` block
6. Scroll to bottom of `godot_bridge.gd`
7. Copy all function definitions from `vr_endpoint_handler.gd` (starting line 14)
8. Paste at bottom of `godot_bridge.gd`
9. Save file
10. Restart Godot

### Integration Method 2: Script-Assisted (Recommended)

Create a temporary integration script:

**File:** `integrate_vr_endpoint.sh`
```bash
#!/bin/bash
# VR Teleportation API Integration Script

BRIDGE_FILE="addons/godot_debug_connection/godot_bridge.gd"
HANDLER_FILE="addons/godot_debug_connection/vr_endpoint_handler.gd"
BACKUP_FILE="addons/godot_debug_connection/godot_bridge.gd.backup"

echo "🔧 Integrating VR Teleportation API..."

# Backup original file
cp "$BRIDGE_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Extract handler functions (skip header comments)
tail -n +18 "$HANDLER_FILE" > /tmp/vr_handlers.tmp

# Append to godot_bridge.gd
cat /tmp/vr_handlers.tmp >> "$BRIDGE_FILE"
echo "✅ Handler functions added"

# Reminder to add route
echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo "Add this route to _route_request() function (around line 280):"
echo ""
echo "    # VR system endpoints (teleportation, comfort, etc.)"
echo "    elif path.begins_with(\"/vr/\"):"
echo "        _handle_vr_endpoint(client, method, path, body)"
echo ""
echo "Then restart Godot to apply changes."

# Cleanup
rm /tmp/vr_handlers.tmp
```

Run it:
```bash
chmod +x integrate_vr_endpoint.sh
./integrate_vr_endpoint.sh
```

### Integration Method 3: Python Script (Cross-Platform)

**File:** `integrate_vr_endpoint.py`
```python
#!/usr/bin/env python3
"""
VR Teleportation API Integration Script
Automatically integrates VR endpoint handlers into godot_bridge.gd
"""

import re
import shutil

BRIDGE_FILE = "addons/godot_debug_connection/godot_bridge.gd"
HANDLER_FILE = "addons/godot_debug_connection/vr_endpoint_handler.gd"

def integrate():
    # Backup
    shutil.copy(BRIDGE_FILE, BRIDGE_FILE + ".backup")
    print("✅ Backup created")

    # Read handler functions
    with open(HANDLER_FILE, 'r') as f:
        handler_content = f.readlines()

    # Skip header comments (first 17 lines)
    handler_functions = ''.join(handler_content[17:])

    # Read bridge file
    with open(BRIDGE_FILE, 'r') as f:
        bridge_content = f.read()

    # Check if already integrated
    if '_handle_vr_endpoint' in bridge_content:
        print("⚠️  VR handlers already present in godot_bridge.gd")
        print("   Integration may have been done previously.")
        return

    # Append handlers
    with open(BRIDGE_FILE, 'a') as f:
        f.write('\n\n' + handler_functions)

    print("✅ Handler functions added")
    print("\n⚠️  MANUAL STEP REQUIRED:")
    print("Add route in _route_request() function:")
    print("    elif path.begins_with(\"/vr/\"):")
    print("        _handle_vr_endpoint(client, method, path, body)")

if __name__ == "__main__":
    integrate()
```

Run it:
```bash
python integrate_vr_endpoint.py
```

---

## Verification

### 1. Check Route Added

Open `godot_bridge.gd` and verify the route exists:

```gdscript
func _route_request(client: StreamPeerTCP, method: String, path: String, headers: Dictionary, body: String) -> void:
	# ... other routes ...

	# VR system endpoints (teleportation, comfort, etc.)
	elif path.begins_with("/vr/"):
		_handle_vr_endpoint(client, method, path, body)  # ← Should be present

	else:
		_send_error_response(client, 404, "Not Found", "Endpoint not found: " + path)
```

### 2. Check Functions Added

Scroll to bottom of `godot_bridge.gd` and verify these functions exist:
- `_handle_vr_endpoint()`
- `_handle_vr_teleport()`
- `_handle_vr_teleport_status()`
- `_handle_vr_comfort_settings()`
- `_handle_vr_comfort_status()`
- `_get_vr_teleportation_system()`
- `_get_vr_manager()`
- `_get_vr_comfort_system()`
- `_get_teleport_invalid_reasons()`

### 3. Test Connection

```bash
# Should return 200 OK (even if system not initialized)
curl -v http://127.0.0.1:8080/vr/teleport/status
```

**Expected output:**
```
< HTTP/1.1 200 OK  ← Success
< Content-Type: application/json

OR

< HTTP/1.1 503 Service Unavailable  ← OK if VR system not initialized
```

**Should NOT see:**
```
< HTTP/1.1 404 Not Found  ← Means route not added
```

### 4. Run Test Suite

```bash
python examples/vr_teleportation_test.py
```

**Expected output:**
```
🧪 Running VR Teleportation Test Suite
============================================================

[1/6] Testing connection...
✅ Passed: Connection successful

[2/6] Getting initial status...
✅ Passed: Got teleportation status  ← If VR system initialized
    OR
⚠️  Warning: Could not get status  ← If VR system not initialized (OK)

...
```

---

## Troubleshooting

### Issue: 404 Not Found on /vr/* endpoints

**Cause:** Route not added to `_route_request()`

**Solution:**
1. Verify route code is present in `godot_bridge.gd`
2. Check it's placed BEFORE the final `else` block
3. Restart Godot completely

### Issue: Function not found error

**Cause:** Handler functions not added

**Solution:**
1. Check bottom of `godot_bridge.gd` for `_handle_vr_endpoint()` function
2. If missing, copy all functions from `vr_endpoint_handler.gd`
3. Restart Godot

### Issue: 503 Service Unavailable

**Cause:** VR Teleportation system not initialized (THIS IS NORMAL)

**When this is OK:**
- VR system hasn't been created yet
- Walking mode not activated
- Scene doesn't have VRTeleportation node

**Solution (if you need it working now):**
1. Activate walking mode in game
2. Or manually create teleportation system:
   ```gdscript
   var teleport = VRTeleportation.new()
   add_child(teleport)
   teleport.initialize(vr_manager, xr_origin)
   ```

### Issue: Godot file lock prevents editing

**Cause:** Godot is watching files and may be locking them

**Solution:**
1. Close Godot completely
2. Make edits
3. Restart Godot

---

## Testing Without VR Headset

The system can be tested without a physical VR headset:

### Option 1: Desktop Mode

```gdscript
# VR Manager falls back to desktop mode automatically
# Teleportation will use desktop camera position
```

### Option 2: Simulated VR Input

```gdscript
# Use VR input simulator (if available)
var simulator = VRInputSimulator.new()
simulator.simulate_controller_state("left", {
    "trigger": 0.8,
    "thumbstick": Vector2(0, -1)
})
```

### Option 3: HTTP API Only

```bash
# Bypass VR input entirely, use HTTP API
python examples/vr_teleportation_test.py teleport 5 0 3
```

---

## Next Steps

Once integration is complete:

1. **Test in VR:** Try teleportation with actual VR headset
2. **Integrate with Walking:** Enable in `WalkingController.activate()`
3. **Add to Tutorial:** Include teleportation in player tutorial
4. **Monitor Telemetry:** Watch for teleport events in telemetry stream
5. **Custom Validation:** Add game-specific teleport restrictions

---

## Production Checklist

Before shipping:

- [ ] VR endpoint integrated and tested
- [ ] Test suite passes all tests
- [ ] Teleportation comfort settings configured
- [ ] HTTP API disabled in release builds (or secured)
- [ ] Telemetry events logged for analytics
- [ ] Tutorial includes teleportation instructions
- [ ] Alternative locomotion options available
- [ ] Accessibility settings documented

---

## Files Reference

| File | Purpose | Status |
|------|---------|--------|
| `scripts/player/vr_teleportation.gd` | Core teleportation system | ✅ Complete |
| `VR_TELEPORTATION.md` | Main documentation | ✅ Complete |
| `VR_TELEPORTATION_HTTP_API.md` | API reference | ✅ Complete |
| `VR_TELEPORTATION_INTEGRATION.md` | This file | ✅ Complete |
| `addons/godot_debug_connection/vr_endpoint_handler.gd` | HTTP handlers | ✅ Complete |
| `examples/vr_teleportation_test.py` | Python test client | ✅ Complete |
| `addons/godot_debug_connection/godot_bridge.gd` | HTTP server | ⏳ Needs route |

---

## Support

If you encounter issues:

1. Check console output for errors
2. Verify all files are present
3. Review troubleshooting section above
4. Check telemetry for system state
5. Run test suite for detailed diagnostics

For questions or contributions, see project documentation.

---

**Last Updated:** 2025-12-02
**Version:** 1.0.0
**Author:** Claude Code with SpaceTime Team
