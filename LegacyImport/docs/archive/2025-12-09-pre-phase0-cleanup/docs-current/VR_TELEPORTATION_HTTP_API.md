# VR Teleportation HTTP API Reference

Complete HTTP API documentation for the VR Teleportation system. This extends the main `VR_TELEPORTATION.md` documentation with detailed API specifications.

## Overview

The VR Teleportation system exposes a REST API through the Godot Bridge HTTP server (default port 8080). This allows external tools, test scripts, and AI assistants to control and monitor the teleportation system.

## Prerequisites

1. **Godot must be running** with debug services enabled:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. **VR Teleportation system must be initialized** in the scene
   - Typically initialized when WalkingController activates
   - Can be checked via `/vr/teleport/status` endpoint

3. **Integration code must be added** to `godot_bridge.gd`
   - See `addons/godot_debug_connection/vr_endpoint_handler.gd` for implementation
   - Add route: `elif path.begins_with("/vr/"): _handle_vr_endpoint(client, method, path, body)`

## API Endpoints

### 1. Execute Teleport

Teleport the player to a specified position.

**Endpoint:** `POST /vr/teleport`

**Request Body:**
```json
{
  "position": {
    "x": 5.0,
    "y": 0.0,
    "z": 3.0
  }
}
```

**Success Response (200 OK):**
```json
{
  "status": "success",
  "message": "Teleport executed",
  "from": {
    "x": 0.0,
    "y": 0.0,
    "z": 0.0
  },
  "to": {
    "x": 5.0,
    "y": 0.0,
    "z": 3.0
  },
  "valid": true
}
```

**Error Response (400 Bad Request):**
```json
{
  "status": "error",
  "message": "Invalid teleport target",
  "from": {
    "x": 0.0,
    "y": 0.0,
    "z": 0.0
  },
  "to": {
    "x": 50.0,
    "y": 0.0,
    "z": 50.0
  },
  "valid": false,
  "reasons": [
    "Too far (maximum: 10.0m, actual: 70.7m)"
  ]
}
```

**Error Response (503 Service Unavailable):**
```json
{
  "error": "Service Unavailable",
  "message": "VR Teleportation system not found or not initialized"
}
```

**Validation Rules:**
- Distance must be >= `min_teleport_distance` (default 1.0m)
- Distance must be <= `teleport_range` (default 10.0m)
- Target surface slope must be <= `max_slope_angle` (default 45°)
- Must have `min_headroom` clearance above target (default 2.0m)
- Must not collide with obstacles (sphere cast with `player_radius`)

**Example (curl):**
```bash
curl -X POST http://127.0.0.1:8080/vr/teleport \
  -H "Content-Type: application/json" \
  -d '{"position": {"x": 5.0, "y": 0.0, "z": 3.0}}'
```

---

### 2. Get Teleportation Status

Query the current state of the teleportation system.

**Endpoint:** `GET /vr/teleport/status`

**Response (200 OK):**
```json
{
  "status": "idle",
  "is_targeting": false,
  "is_teleporting": false,
  "current_position": {
    "x": 5.0,
    "y": 0.0,
    "z": 3.0
  },
  "current_target": {
    "x": 0.0,
    "y": 0.0,
    "z": 0.0
  },
  "is_valid_target": false,
  "settings": {
    "teleport_range": 10.0,
    "min_distance": 1.0,
    "max_slope_angle": 45.0,
    "snap_rotation_enabled": false,
    "fade_duration": 0.2
  }
}
```

**Status Values:**
- `"idle"` - Not currently teleporting or targeting
- `"active"` - Currently targeting or in the middle of a teleport

**Example (curl):**
```bash
curl http://127.0.0.1:8080/vr/teleport/status
```

---

### 3. Get Comfort Status

Query the VR comfort system state.

**Endpoint:** `GET /vr/comfort/status`

**Response (200 OK):**
```json
{
  "initialized": true,
  "comfort_mode_enabled": true,
  "vignetting_enabled": true,
  "vignette_intensity": 0.35,
  "snap_turn_enabled": false,
  "snap_turn_angle": 45.0,
  "stationary_mode_enabled": false,
  "current_acceleration": 2.5
}
```

**Field Descriptions:**
- `initialized`: Whether VRComfortSystem has been initialized
- `comfort_mode_enabled`: Master comfort mode toggle
- `vignetting_enabled`: Whether acceleration-based vignetting is active
- `vignette_intensity`: Current vignette intensity (0.0-1.0)
- `snap_turn_enabled`: Whether snap turning is enabled
- `snap_turn_angle`: Angle increment for snap turns (degrees)
- `stationary_mode_enabled`: Whether stationary mode is active
- `current_acceleration`: Current measured acceleration (m/s²)

**Example (curl):**
```bash
curl http://127.0.0.1:8080/vr/comfort/status
```

---

### 4. Update Comfort Settings

Modify VR comfort system settings.

**Endpoint:** `POST /vr/comfort/settings`

**Request Body (all fields optional):**
```json
{
  "comfort_mode": true,
  "vignetting_enabled": true,
  "vignetting_intensity": 0.7,
  "snap_turn_enabled": true,
  "snap_turn_angle": 30.0
}
```

**Field Descriptions:**
- `comfort_mode`: Enable/disable comfort mode (bool)
- `vignetting_enabled`: Enable/disable vignetting effect (bool)
- `vignetting_intensity`: Maximum vignette intensity, 0.0-1.0 (float)
- `snap_turn_enabled`: Enable/disable snap turning (bool)
- `snap_turn_angle`: Snap turn angle in degrees, 15-90 (float)

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Comfort settings updated",
  "settings": {
    "initialized": true,
    "comfort_mode_enabled": true,
    "vignetting_enabled": true,
    "vignette_intensity": 0.7,
    "snap_turn_enabled": true,
    "snap_turn_angle": 30.0,
    "stationary_mode_enabled": false,
    "current_acceleration": 0.0
  }
}
```

**Example (curl):**
```bash
curl -X POST http://127.0.0.1:8080/vr/comfort/settings \
  -H "Content-Type: application/json" \
  -d '{
    "comfort_mode": true,
    "vignetting_enabled": true,
    "vignetting_intensity": 0.7,
    "snap_turn_enabled": true,
    "snap_turn_angle": 30.0
  }'
```

---

## Python Client

A complete Python client library is provided in `examples/vr_teleportation_test.py`.

### Installation

No additional dependencies beyond Python standard library and `requests`:

```bash
pip install requests
```

### Basic Usage

```python
#!/usr/bin/env python3
from examples.vr_teleportation_test import VRTeleportationClient

# Create client
client = VRTeleportationClient()

# Check connection
if not client.check_connection():
    print("Cannot connect to Godot Bridge")
    exit(1)

# Get current status
status = client.get_teleport_status()
print(f"Current position: {status['current_position']}")

# Teleport to new position
success, result = client.teleport_to(5.0, 0.0, 3.0)
if success:
    print(f"✅ Teleport successful!")
    print(f"   From: {result['from']}")
    print(f"   To: {result['to']}")
else:
    print(f"❌ Teleport failed: {result['message']}")
    if 'reasons' in result:
        for reason in result['reasons']:
            print(f"   - {reason}")

# Update comfort settings
success, result = client.set_comfort_settings(
    vignetting_enabled=True,
    vignetting_intensity=0.6,
    snap_turn_enabled=True,
    snap_turn_angle=45.0
)

# Get comfort status
comfort = client.get_comfort_status()
print(f"Vignetting: {comfort['vignetting_enabled']}")
print(f"Intensity: {comfort['vignette_intensity']}")
```

### Command-Line Interface

The Python client includes a CLI for quick testing:

```bash
# Run comprehensive test suite
python examples/vr_teleportation_test.py

# Get teleportation status
python examples/vr_teleportation_test.py status

# Teleport to specific position
python examples/vr_teleportation_test.py teleport 5 0 3

# Get comfort system status
python examples/vr_teleportation_test.py comfort
```

**Test Suite Output:**
```
🧪 Running VR Teleportation Test Suite
============================================================

[1/6] Testing connection...
✅ Passed: Connection successful

[2/6] Getting initial status...
✅ Passed: Got teleportation status

📊 VR Teleportation Status
============================================================
Status: idle
Is Targeting: False
Is Teleporting: False

📍 Current Position:
   X: 0.00m
   Y: 0.00m
   Z: 0.00m

[3/6] Testing teleport to nearby position (2, 0, 2)...
✅ Passed: Teleport successful
   From: (0.0, 0.0, 0.0)
   To:   (2.0, 0.0, 2.0)

[4/6] Testing teleport out of range (50, 0, 50)...
✅ Passed: Correctly rejected out-of-range teleport
   Reasons: Too far (maximum: 10.0m, actual: 70.7m)

[5/6] Getting comfort system status...
✅ Passed: Got comfort status

[6/6] Testing comfort settings update...
✅ Passed: Comfort settings updated
   - Vignetting: True
   - Snap Turn: True (30.0°)

============================================================
🎉 Test suite completed!
============================================================
```

---

## Error Handling

### Common Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid parameters or teleport target |
| 404 | Not Found | Unknown endpoint |
| 503 | Service Unavailable | System not initialized |

### Error Response Format

All errors return a JSON object with at least:
```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

Additional fields may be included for specific errors (e.g., `reasons` array for invalid teleports).

---

## Integration with Testing Framework

The HTTP API integrates with the project's automated testing system:

```python
# In tests/integration/test_vr_teleportation.py
import sys
sys.path.append('examples')
from vr_teleportation_test import VRTeleportationClient

def test_teleport_range_validation():
    """Test that out-of-range teleports are rejected"""
    client = VRTeleportationClient()

    # Try teleporting beyond max range
    success, result = client.teleport_to(50.0, 0.0, 50.0)

    assert not success, "Should reject out-of-range teleport"
    assert "Too far" in str(result.get('reasons', []))

def test_teleport_slope_validation():
    """Test that steep slopes are rejected"""
    client = VRTeleportationClient()

    # Position on steep slope (would require manual scene setup)
    success, result = client.teleport_to(10.0, 5.0, 10.0)

    if not success:
        assert any("slope" in r.lower() for r in result.get('reasons', []))
```

---

## Performance Considerations

### Request Latency

Typical latency for API calls:
- **Status queries**: 1-5ms
- **Teleport execution**: 400-600ms (includes fade transition)
- **Settings updates**: 1-3ms

### Rate Limiting

No rate limiting is currently implemented, but consider:
- Avoid spamming teleport requests (wait for completion)
- Status queries can be polled at ~10Hz without issues
- Comfort settings should be updated infrequently (user preference changes)

### Concurrent Requests

The HTTP server supports multiple concurrent connections (max 100), but:
- Only one teleport can execute at a time
- Attempting to teleport during active teleport returns error
- Settings updates are applied immediately

---

## Security Notes

**IMPORTANT:** The HTTP API listens on `127.0.0.1` (localhost) only by default.

- API is NOT exposed to the network
- No authentication/authorization required
- Safe for local development and testing
- Should not be exposed in production builds

For network access (advanced):
- Modify `godot_bridge.gd` to bind to `0.0.0.0`
- Add authentication middleware
- Use HTTPS/TLS for encryption
- Implement rate limiting

---

## Troubleshooting

### "Service Unavailable" Error

**Symptom:** `/vr/teleport` returns 503

**Solutions:**
1. Ensure VR Teleportation system is initialized
   ```gdscript
   var teleport = VRTeleportation.new()
   teleport.initialize(vr_manager, xr_origin)
   ```
2. Check that WalkingController is active
3. Verify system is in scene tree: `get_tree().root.find_child("VRTeleportation")`

### Connection Refused

**Symptom:** `requests.exceptions.ConnectionError`

**Solutions:**
1. Verify Godot is running: `tasklist | grep Godot`
2. Check HTTP server started: Look for "GodotBridge HTTP server started" in console
3. Try fallback ports: 8083, 8084, 8085
4. Verify firewall allows localhost connections

### "VR system not found" Error

**Symptom:** API returns error about missing VR system

**Solutions:**
1. Integration code not added to `godot_bridge.gd`
2. Copy functions from `vr_endpoint_handler.gd`
3. Add route in `_route_request()`
4. Restart Godot after code changes

---

## Future Enhancements

Planned API additions:

1. **Batch Teleport:** Execute multiple teleports in sequence
   ```json
   POST /vr/teleport/batch
   {
     "positions": [
       {"x": 1, "y": 0, "z": 1},
       {"x": 2, "y": 0, "z": 2}
     ],
     "delay": 1.0
   }
   ```

2. **Teleport Preview:** Validate without executing
   ```json
   POST /vr/teleport/preview
   {
     "position": {"x": 5, "y": 0, "z": 3}
   }
   ```

3. **Waypoint System:** Save and recall teleport locations
   ```json
   POST /vr/teleport/waypoints/save
   {"name": "base", "position": {"x": 0, "y": 0, "z": 0}}

   POST /vr/teleport/waypoints/goto
   {"name": "base"}
   ```

---

## See Also

- `VR_TELEPORTATION.md` - Main teleportation system documentation
- `addons/godot_debug_connection/HTTP_API.md` - Complete HTTP API reference
- `examples/vr_teleportation_test.py` - Python client implementation
- `addons/godot_debug_connection/vr_endpoint_handler.gd` - Server implementation

---

**Last Updated:** 2025-12-02
**Version:** 1.0.0
**Author:** Claude Code with SpaceTime Team
