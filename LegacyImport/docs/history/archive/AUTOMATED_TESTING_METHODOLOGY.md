# Automated Testing Methodology for Game Development
**Date**: 2025-12-01
**Status**: Active Development Methodology

---

## Overview

This document describes the autonomous testing and debugging methodology developed for SpaceTime VR game development. This approach eliminates the need for screenshots and manual visual inspection by providing programmatic access to scene state.

---

## Core Principles

1. **Autonomous Scene Inspection** - Claude can see game state without user screenshots
2. **Auto-Terminating Tests** - All diagnostics complete within 15 seconds maximum
3. **Real-Time Telemetry** - HTTP API provides instant access to scene data
4. **Incremental Development** - Build features, test automatically, fix issues autonomously

---

## The Scene Inspection System

### HTTP Endpoint

**Endpoint**: `GET http://127.0.0.1:8080/state/scene`

**Response Format**:
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
  "camera": {"found": false},
  "vr_origin": {"found": false}
}
```

### Implementation

**File**: `addons/godot_debug_connection/godot_bridge.gd:1038`

**Key Design Decisions**:
- Use **direct node paths** (`get_node_or_null()`) instead of `find_child()` to avoid infinite hangs
- Avoid **collision detection methods** like `get_slide_collision()` - they cause timeouts
- Check property existence with `in` operator before accessing: `if "velocity" in player`
- Use **method checks** before calling: `if player.has_method("is_on_floor")`

**Critical Bug Fix**:
```gdscript
# WRONG - Causes infinite hang
var player = get_tree().root.find_child("Player", true, false)

# RIGHT - Fast direct access
var vr_main = get_tree().root.get_node_or_null("VRMain")
var spawn_system = vr_main.get_node_or_null("PlayerSpawnSystem")
var player = spawn_system.get_node_or_null("Player")
```

---

## Quick Diagnostic Tool

### File: `quick_diagnostic.py`

**Purpose**: Fast, auto-terminating scene inspection with formatted output

**Features**:
- 15 second maximum runtime (auto-terminates)
- 2 second HTTP server check timeout
- 3 second scene report fetch timeout
- Formatted console output
- Exit code indicates success/failure

**Usage**:
```bash
python quick_diagnostic.py
```

**Sample Output**:
```
============================================================
QUICK DIAGNOSTIC - 15 SECOND MAX
============================================================
[23:11:28] Checking HTTP server...
  [OK] HTTP server responding
[23:11:29] Fetching scene report...
  [OK] Scene report received

============================================================
SCENE STATUS
============================================================

[OK] PLAYER FOUND: Player
  Position: [6.04, 0.90, 8.16]
  Velocity: [0.0, 0.0, 0.0]
  On Floor: True
  Gravity: 9.798
  Gravity Dir: [-0.59, -0.09, -0.80]
  Jetpack Fuel: 100.0

[X] CAMERA NOT FOUND
[X] VR ORIGIN NOT FOUND

============================================================

[TIME]  Completed in 1.0s
```

---

## Development Workflow

### 1. Start Development Session

```bash
# Start Godot with debug services
python vr_game_controller.py start

# Wait 8-10 seconds for scene initialization
```

### 2. Inspect Current State

```bash
# Quick check
python quick_diagnostic.py

# Raw JSON data
curl -s http://127.0.0.1:8080/state/scene | python -m json.tool
```

### 3. Identify Issues

Example from session:
```json
{
  "player": {
    "on_floor": false,
    "velocity": [0.0, -0.11, 0.0],  // FALLING!
    "gravity": 0.1                   // TOO WEAK!
  }
}
```

### 4. Fix Issues

**Issue**: Gravity too weak (0.1 instead of 9.8)

**Root Cause**: Planet mass too low
```gdscript
# Before: vr_setup.gd:98
test_planet.mass = 1000000.0  // Gives gravity = 0.1 m/s²

# After:
test_planet.mass = 1.468e15  // Gives gravity = 9.8 m/s²
```

**Formula**: `gravity = (G * mass) / (radius²)`
- G = 6.67430e-11 (gravitational constant)
- For 9.8 m/s² at 100m radius: mass = 1.468×10¹⁵ kg

### 5. Verify Fix

```bash
# Restart with changes
python vr_game_controller.py stop
python vr_game_controller.py start

# Wait for init
timeout 10 python -c "import time; time.sleep(10)"

# Check results
python quick_diagnostic.py
```

**Result**:
```
[OK] PLAYER FOUND: Player
  Velocity: [0.0, 0.0, 0.0]  ✓ STABLE
  On Floor: True             ✓ STANDING
  Gravity: 9.798            ✓ CORRECT
```

---

## Common Issues and Solutions

### Issue 1: Scene Inspector Timeout

**Symptom**: `curl http://127.0.0.1:8080/state/scene` times out

**Cause**: Using `find_child()` or collision detection methods

**Solution**: Use direct node paths only

### Issue 2: Player Not Found

**Symptom**: `"player": {"found": false}`

**Causes**:
1. Player not spawned yet (wait longer)
2. Wrong node path
3. Async function not awaited

**Example Fix**:
```gdscript
# vr_setup.gd:48
# WRONG - Function returns before player spawns
_setup_planetary_survival()

# RIGHT - Wait for completion
await _setup_planetary_survival()
```

### Issue 3: Player Falling Through Ground

**Symptom**: `on_floor: false`, negative Y velocity

**Debugging Steps**:
1. Check gravity value: Should be ~9.8 m/s²
2. Check ground exists: Look for "Ground" in scene report
3. Check player position vs ground position
4. Verify collision layers match

---

## Testing Best Practices

### 1. Always Use Auto-Terminating Tests

```python
# GOOD - Self-terminating
def main():
    start_time = time.time()
    MAX_RUNTIME = 15

    if time.time() - start_time > MAX_RUNTIME:
        sys.exit(1)
```

### 2. Add Timeouts to All Network Calls

```python
# GOOD - Won't hang forever
urllib.request.urlopen("http://127.0.0.1:8080/state/scene", timeout=3)

# BAD - Can hang indefinitely
urllib.request.urlopen("http://127.0.0.1:8080/state/scene")
```

### 3. Check Server Availability First

```python
# Test /status before /state/scene
try:
    response = urllib.request.urlopen("http://127.0.0.1:8080/status", timeout=2)
    # Server is up, proceed with tests
except:
    print("Server not running")
    sys.exit(1)
```

### 4. Use Formatted Output

```python
# GOOD - Easy to read
print(f"[OK] PLAYER FOUND: {player['name']}")
print(f"  Position: {player['position']}")

# BAD - Hard to parse
print(player)
```

---

## Integration with Git Workflow

### Before Committing

```bash
# 1. Run quick diagnostic
python quick_diagnostic.py

# 2. Verify key systems
# - Player spawns successfully
# - Physics working (gravity, collision)
# - No errors in scene report

# 3. Document findings
echo "Player stable at position [X, Y, Z]" >> SESSION_NOTES.md
```

### Creating Pull Requests

Include diagnostic output in PR description:
```markdown
## Test Results

```bash
python quick_diagnostic.py
```

Output:
```
[OK] PLAYER FOUND: Player
  Position: [0.0, 2.0, 0.0]
  On Floor: True
  Gravity: 9.798
```
```

---

## Key Files

| File | Purpose | Location |
|------|---------|----------|
| godot_bridge.gd | Scene inspection endpoint | addons/godot_debug_connection/godot_bridge.gd:1038 |
| quick_diagnostic.py | Fast scene inspection tool | C:/godot/quick_diagnostic.py |
| vr_game_controller.py | Centralized game control | C:/godot/vr_game_controller.py |
| vr_setup.gd | Player spawning and physics setup | C:/godot/vr_setup.gd |

---

## Lessons Learned (Session 2025-12-01)

### 1. Scene Tree Navigation
- **Never use `find_child()` in HTTP endpoints** - causes infinite hangs
- Use direct paths: `get_node_or_null("NodeName")`
- Build path incrementally: root → VRMain → PlayerSpawnSystem → Player

### 2. Async/Await in Godot
- Functions with `await` must be called with `await`
- Missing `await` causes function to return before completion
- Example: Player not spawning because `_setup_planetary_survival()` wasn't awaited

### 3. Physics Calculation
- Real physics formulas work in Godot: `gravity = (G * mass) / (radius²)`
- Planet mass must be realistic for gameplay gravity
- Test planet (100m radius) needs ~1.5×10¹⁵ kg for Earth-like gravity

### 4. Collision Detection
- `get_slide_collision()` methods cause timeouts in HTTP endpoints
- Use simple property checks instead: `is_on_floor()`, `velocity`
- Collision info available from player properties, not physics queries

### 5. Testing Methodology
- Write self-terminating tests (15s max)
- Add timeouts to all network calls
- Test incrementally: simple → complex
- Document what works and what hangs

---

## Future Enhancements

### Planned Improvements

1. **Visual Collision Debugging**
   - Ray casting to detect what player is standing on
   - Physics layer visualization

2. **Performance Metrics**
   - Frame time breakdown
   - Physics tick monitoring
   - Memory usage tracking

3. **Automated Movement Testing**
   - Walk forward/backward tests
   - Jump and jetpack tests
   - Edge detection tests

4. **Scene Hierarchy Visualization**
   - Tree structure reporting
   - Node count by type
   - Missing node detection

---

## Conclusion

This methodology enables autonomous game development by providing programmatic access to scene state. No more screenshots needed - all game state is available via HTTP API with sub-second response times.

**Key Success Metrics**:
- Scene inspection completes in <1 second
- All tests auto-terminate within 15 seconds
- Full player state visible (position, physics, fuel, etc.)
- Ground and planet information accessible
- 90 FPS maintained during inspection

This is now the **standard development workflow** for SpaceTime VR.
