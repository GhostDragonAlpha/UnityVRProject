# VR Controller Tracking - Quick Reference

## Endpoint
```
GET http://127.0.0.1:8080/state/scene
```

## Response Structure

```json
{
  "timestamp": number,
  "fps": number,
  "vr_main": "found" | "not_found",

  "vr_origin": {
    "found": boolean,
    "position": [x, y, z]
  },

  "camera": {
    "found": boolean,
    "position": [x, y, z]
  },

  "left_controller": {
    "found": boolean,
    "position": [x, y, z],      // meters
    "rotation": [x, y, z],      // radians
    "trigger": float,           // 0.0 to 1.0
    "grip": float              // 0.0 to 1.0
  },

  "right_controller": {
    "found": boolean,
    "position": [x, y, z],
    "rotation": [x, y, z],
    "trigger": float,
    "grip": float
  }
}
```

## Usage Examples

### Python
```python
import requests

response = requests.get("http://127.0.0.1:8080/state/scene")
data = response.json()

left = data.get("left_controller", {})
if left.get("found"):
    print(f"Left hand: {left['position']}")
    print(f"Trigger: {left['trigger']:.2f}")
```

### Bash/curl
```bash
curl http://127.0.0.1:8080/state/scene | jq '.left_controller'
```

## Code Location
**File:** `C:/godot/addons/godot_debug_connection/godot_bridge.gd`
**Lines:** 1448-1490

## Testing
```bash
cd C:/godot
python test_vr_tracking.py
```

## Notes
- Controllers only appear when VR headset is connected
- XROrigin3D must be initialized (requires OpenXR runtime)
- Position/rotation are in global world space
- Trigger/grip values are normalized (0.0 = released, 1.0 = fully pressed)
