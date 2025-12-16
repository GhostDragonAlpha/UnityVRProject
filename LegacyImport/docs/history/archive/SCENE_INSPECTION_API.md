# Scene Inspection HTTP API Reference
**Last Updated**: 2025-12-01
**Version**: 1.0

---

## Quick Reference

```bash
# Status check
curl http://127.0.0.1:8080/status

# Scene inspection
curl http://127.0.0.1:8080/state/scene

# Game state
curl http://127.0.0.1:8080/state/game

# Player state
curl http://127.0.0.1:8080/state/player
```

---

## Endpoint: GET /state/scene

**Purpose**: Get comprehensive scene state including player, ground, and physics data

**URL**: `http://127.0.0.1:8080/state/scene`

**Method**: GET

**Response Time**: <1 second (typically ~200ms)

**Success Response**:

```json
{
  "timestamp": 28941,
  "fps": 90.0,
  "vr_main": "found",
  "spawn_system": "found",

  "ground": {
    "found": true,
    "name": "Ground",
    "type": "CSGBox3D",
    "position": [0.0, -0.5, 0.0],
    "size": [20.0, 1.0, 20.0]
  },

  "player": {
    "found": true,
    "name": "Player",
    "type": "CharacterBody3D",
    "position": [6.05, 0.90, 8.16],
    "velocity": [0.0, 0.0, 0.0],
    "on_floor": true,
    "gravity": 9.798,
    "gravity_dir": [-0.59, -0.09, -0.80],
    "current_planet": "TestPlanet",
    "jetpack_fuel": 100.0
  },

  "camera": {
    "found": false
  },

  "vr_origin": {
    "found": false
  }
}
```

**Response Fields**:

| Field | Type | Description |
|-------|------|-------------|
| timestamp | number | Game time in milliseconds |
| fps | number | Current frames per second |
| vr_main | string | "found" or "not_found" |
| spawn_system | string | "found" or "not_found" |
| ground | object | Ground platform information |
| ground.found | boolean | Whether ground exists |
| ground.name | string | Node name |
| ground.type | string | Node class (CSGBox3D, etc.) |
| ground.position | array | [x, y, z] coordinates |
| ground.size | array | [width, height, depth] in meters |
| player | object | Player information |
| player.found | boolean | Whether player exists |
| player.name | string | Player node name |
| player.type | string | CharacterBody3D |
| player.position | array | [x, y, z] in world space |
| player.velocity | array | [x, y, z] velocity m/s |
| player.on_floor | boolean | Standing on ground |
| player.gravity | number | Current gravity strength (m/s²) |
| player.gravity_dir | array | Normalized gravity direction vector |
| player.current_planet | string | Name of planet providing gravity |
| player.jetpack_fuel | number | Fuel percentage (0-100) |
| camera | object | Camera information |
| vr_origin | object | VR origin transform |

**Error Response**:

```json
{
  "error": "VRMain scene not found"
}
```

**Status Code**: 200 (always, even for errors - check response body)

---

## Endpoint: GET /status

**Purpose**: Check if Godot is running and HTTP server is responsive

**URL**: `http://127.0.0.1:8080/status`

**Method**: GET

**Response Time**: <100ms

**Success Response**:

```json
{
  "debug_adapter": {
    "port": 6006,
    "state": 1,
    "last_activity": 5.0
  },
  "language_server": {
    "port": 6005,
    "state": 1,
    "last_activity": 0.0
  },
  "overall_ready": false
}
```

---

## Endpoint: GET /state/game

**Purpose**: Get high-level game state

**URL**: `http://127.0.0.1:8080/state/game`

**Method**: GET

**Success Response**:

```json
{
  "fps": 90.0,
  "time": 36.443,
  "scene": "VRMain",
  "engine_initialized": true
}
```

---

## Implementation Details

### Location

**File**: `addons/godot_debug_connection/godot_bridge.gd`

**Function**: `_handle_state_scene(client: StreamPeerTCP) -> void` (line 1038)

### Design Decisions

1. **Direct Node Paths Only**
   ```gdscript
   # CORRECT - Fast, reliable
   var vr_main = get_tree().root.get_node_or_null("VRMain")
   var player = spawn_system.get_node_or_null("Player")

   # WRONG - Causes infinite hang!
   var player = get_tree().root.find_child("Player", true, false)
   ```

2. **Property Checks Before Access**
   ```gdscript
   # CORRECT
   if "velocity" in player:
       report["velocity"] = [player.velocity.x, player.velocity.y, player.velocity.z]

   # WRONG - Can crash if property doesn't exist
   report["velocity"] = [player.velocity.x, player.velocity.y, player.velocity.z]
   ```

3. **Method Checks Before Calling**
   ```gdscript
   # CORRECT
   if player.has_method("is_on_floor"):
       report["on_floor"] = player.is_on_floor()

   # WRONG - Can crash if method doesn't exist
   report["on_floor"] = player.is_on_floor()
   ```

4. **Avoid Collision Detection Methods**
   ```gdscript
   # WRONG - Causes timeout!
   var collision = player.get_slide_collision(0)

   # CORRECT - Use simple property checks
   var on_floor = player.is_on_floor()
   ```

### Known Limitations

- **No collision object detection**: Cannot determine what player is standing on via collision methods
- **No VR camera data yet**: XRCamera3D not found in current implementation
- **No real-time physics queries**: Raycast and physics queries not supported

---

## Usage Examples

### Python

```python
import urllib.request
import json

# Get scene state
with urllib.request.urlopen("http://127.0.0.1:8080/state/scene", timeout=3) as response:
    data = json.loads(response.read().decode())

    if data.get("player", {}).get("found"):
        player = data["player"]
        print(f"Player at: {player['position']}")
        print(f"On floor: {player['on_floor']}")
        print(f"Gravity: {player['gravity']} m/s²")
```

### Bash

```bash
#!/bin/bash

# Check if player is on ground
SCENE=$(curl -s http://127.0.0.1:8080/state/scene)
ON_FLOOR=$(echo $SCENE | python -c "import sys, json; print(json.load(sys.stdin)['player']['on_floor'])")

if [ "$ON_FLOOR" = "True" ]; then
    echo "Player is standing on ground"
else
    echo "Player is falling!"
fi
```

### Quick Diagnostic Script

```python
#!/usr/bin/env python3
import urllib.request
import json
import sys

def check_scene():
    try:
        with urllib.request.urlopen("http://127.0.0.1:8080/state/scene", timeout=3) as response:
            data = json.loads(response.read().decode())

            player = data.get("player", {})
            if not player.get("found"):
                print("[ERROR] Player not found!")
                return False

            pos = player.get("position", [0,0,0])
            print(f"[OK] Player at [{pos[0]:.2f}, {pos[1]:.2f}, {pos[2]:.2f}]")

            if not player.get("on_floor"):
                print("[WARNING] Player is falling!")
                return False

            gravity = player.get("gravity", 0)
            if gravity < 5.0:
                print(f"[WARNING] Gravity too weak: {gravity} m/s²")
                return False

            print(f"[OK] Gravity: {gravity:.2f} m/s²")
            print(f"[OK] Fuel: {player.get('jetpack_fuel', 0):.1f}%")
            return True

    except Exception as e:
        print(f"[ERROR] {e}")
        return False

if __name__ == "__main__":
    sys.exit(0 if check_scene() else 1)
```

---

## Troubleshooting

### Timeout on /state/scene

**Symptom**: Request times out after 3+ seconds

**Causes**:
1. Using `find_child()` in scene inspector code
2. Calling collision detection methods
3. Infinite loop in node traversal

**Solution**: Check `godot_bridge.gd:1038` for problematic methods

### Player Not Found

**Symptom**: `"player": {"found": false}`

**Causes**:
1. Player hasn't spawned yet (wait 8-10 seconds after start)
2. Wrong node path (check scene tree structure)
3. Async spawn function not awaited

**Solution**:
```bash
# Wait longer
sleep 10
curl http://127.0.0.1:8080/state/scene

# Check if spawn system exists
curl http://127.0.0.1:8080/state/scene | grep spawn_system
```

### Empty Response

**Symptom**: `{}`

**Causes**:
1. GDScript error in scene inspector
2. VRMain scene not loaded
3. HTTP server started before scene ready

**Solution**: Check Godot console for errors

---

## Performance Considerations

- **Response time**: Typically 100-200ms
- **Scene complexity**: Scales linearly with node count
- **Network overhead**: Minimal (~2KB JSON response)
- **FPS impact**: <0.1% (tested at 90 FPS)

**Best practices**:
- Poll at 1Hz maximum (once per second)
- Use `/status` endpoint for health checks (faster)
- Cache results when possible
- Add timeouts to all requests (3s recommended)

---

## Version History

### v1.0 (2025-12-01)
- Initial implementation
- Player state reporting
- Ground detection
- Physics data (gravity, velocity)
- Jetpack fuel monitoring
- Direct node path navigation
- Auto-terminating tests

### Planned v1.1
- Collision object detection (what player is standing on)
- VR camera tracking
- Controller position data
- Scene hierarchy tree
- Performance metrics

---

## See Also

- `AUTOMATED_TESTING_METHODOLOGY.md` - Complete testing workflow
- `vr_game_controller.py` - Centralized game control
- `quick_diagnostic.py` - Fast scene inspection tool
- `HTTP_API.md` - Complete HTTP API reference (all endpoints)
