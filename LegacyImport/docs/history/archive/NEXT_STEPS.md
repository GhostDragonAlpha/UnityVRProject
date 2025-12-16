# Next Steps for Planetary Survival Development

**Current Phase**: 1 - First 5 Minutes (75% complete)
**Immediate Goal**: Complete VR automated testing infrastructure
**Time Estimate**: 6-8 hours total

---

## Context (Read This First!)

You're implementing **automated VR playtesting** for the Planetary Survival game. Every feature must be validated with automated tests that send keyboard/VR controller inputs to Godot and verify the results.

**Why**: Manual VR testing is slow and error-prone. Automated tests ensure features work correctly in VR and maintain 90 FPS performance.

**What's Done**:
- ✅ VR Playtest Framework created (`tests/vr_playtest_framework.py`)
- ✅ Most Phase 1 features implemented (terrain, resources, crafting, base building)

**What's Missing**:
- ⏳ HTTP API endpoints for input injection
- ⏳ HTTP API endpoints for state queries
- ⏳ Phase 1 checkpoint test scripts

---

## Step-by-Step Instructions

### Before You Start

1. **Read these files** (in order):
   - `PLANETARY_SURVIVAL_STATUS.md` - Current status
   - `.claude/agents/vr-playtest-developer.md` - How to work
   - `tests/vr_playtest_framework.py` - Framework API

2. **Start dev session**:
   ```bash
   start_dev_session.bat
   ```

3. **Verify services running**:
   ```bash
   curl http://127.0.0.1:8080/status
   # Should show: overall_ready: true
   ```

---

## Task 1: Add Input Injection Endpoints (2-3 hours)

### Goal
Add HTTP API endpoints to `godot_bridge.gd` that allow Python tests to send keyboard and VR controller inputs.

### Step 1.1: Add Routing

**File**: `addons\godot_debug_connection\godot_bridge.gd`

**Location**: In the `_route_request()` function, after the `/execute/` endpoint check (around line 257)

**Add this code**:
```gdscript
	# Input injection endpoints (for automated testing)
	elif path.begins_with("/input/"):
		_handle_input_endpoint(client, method, path, body)
```

**Verify**: The routing is added between `/execute/` and `else:` blocks.

### Step 1.2: Add Input Handler Function

**File**: `addons\godot_debug_connection\godot_bridge.gd`

**Location**: At the end of the file (before the last `func` or at the very end)

**Add this function**:
```gdscript
## Handle input injection endpoints (for automated testing)
func _handle_input_endpoint(client: StreamPeerTCP, method: String, path: String, body: String) -> void:
	# Parse request body
	var json = JSON.new()
	var parse_result = json.parse(body)
	if parse_result != OK:
		_send_error_response(client, 400, "Bad Request", "Invalid JSON in request body")
		return

	var request_data = json.get_data()
	if typeof(request_data) != TYPE_DICTIONARY:
		_send_error_response(client, 400, "Bad Request", "Request body must be a JSON object")
		return

	var input_command = path.substr(7)  # Remove "/input/" prefix

	match input_command:
		"keyboard":
			_handle_input_keyboard(client, request_data)
		"vr_button":
			_handle_input_vr_button(client, request_data)
		"vr_controller":
			_handle_input_vr_controller(client, request_data)
		_:
			_send_error_response(client, 404, "Not Found", "Unknown input command: " + input_command)
```

### Step 1.3: Add Keyboard Input Handler

**Add this function** (after the previous one):
```gdscript
## Handle keyboard input injection
func _handle_input_keyboard(client: StreamPeerTCP, request_data: Dictionary) -> void:
	if not request_data.has("key"):
		_send_error_response(client, 400, "Bad Request", "Missing required parameter: key")
		return

	var key = request_data.get("key", "")
	var pressed = request_data.get("pressed", true)
	var duration = request_data.get("duration", 0.1)

	# Create and send keyboard event
	var event = InputEventKey.new()
	event.keycode = OS.find_keycode_from_string(key)
	event.pressed = pressed

	Input.parse_input_event(event)

	# If duration specified, schedule key release
	if pressed and duration > 0:
		await get_tree().create_timer(duration).timeout
		event.pressed = false
		Input.parse_input_event(event)

	_send_json_response(client, 200, {
		"status": "success",
		"key": key,
		"pressed": pressed,
		"duration": duration
	})
```

### Step 1.4: Add VR Button Input Handler

**Add this function**:
```gdscript
## Handle VR button input injection
func _handle_input_vr_button(client: StreamPeerTCP, request_data: Dictionary) -> void:
	if not request_data.has("button"):
		_send_error_response(client, 400, "Bad Request", "Missing required parameter: button")
		return

	var button = request_data.get("button", "")
	var pressed = request_data.get("pressed", true)
	var duration = request_data.get("duration", 0.1)

	# Map button name to XR action
	var action_name = ""
	match button:
		"trigger_left":
			action_name = "trigger_click"  # Adjust to match your input map
		"trigger_right":
			action_name = "trigger_click"
		"grip_left":
			action_name = "grip_click"
		"grip_right":
			action_name = "grip_click"
		_:
			_send_error_response(client, 400, "Bad Request", "Unknown button: " + button)
			return

	# Inject input action
	if pressed:
		Input.action_press(action_name)
	else:
		Input.action_release(action_name)

	# Schedule release if needed
	if pressed and duration > 0:
		await get_tree().create_timer(duration).timeout
		Input.action_release(action_name)

	_send_json_response(client, 200, {
		"status": "success",
		"button": button,
		"pressed": pressed,
		"duration": duration
	})
```

### Step 1.5: Add VR Controller Position Handler

**Add this function**:
```gdscript
## Handle VR controller position injection
func _handle_input_vr_controller(client: StreamPeerTCP, request_data: Dictionary) -> void:
	if not request_data.has("controller"):
		_send_error_response(client, 400, "Bad Request", "Missing required parameter: controller")
		return
	if not request_data.has("position"):
		_send_error_response(client, 400, "Bad Request", "Missing required parameter: position")
		return

	var controller_name = request_data.get("controller", "left")
	var position = request_data.get("position", [0.0, 0.0, 0.0])
	var rotation = request_data.get("rotation", [0.0, 0.0, 0.0])

	# Find the VR controller node
	var vr_origin = get_tree().root.get_node_or_null("VRMain/XROrigin3D")
	if not vr_origin:
		_send_error_response(client, 500, "Internal Server Error", "VR origin not found")
		return

	var controller_node_name = "LeftController" if controller_name == "left" else "RightController"
	var controller = vr_origin.get_node_or_null(controller_node_name)
	if not controller:
		_send_error_response(client, 500, "Internal Server Error", "Controller not found: " + controller_node_name)
		return

	# Set position and rotation
	controller.position = Vector3(position[0], position[1], position[2])
	controller.rotation = Vector3(rotation[0], rotation[1], rotation[2])

	_send_json_response(client, 200, {
		"status": "success",
		"controller": controller_name,
		"position": position,
		"rotation": rotation
	})
```

### Step 1.6: Test the Endpoints

**Test keyboard input**:
```bash
curl -X POST http://127.0.0.1:8080/input/keyboard \
  -H "Content-Type: application/json" \
  -d '{"key": "W", "pressed": true, "duration": 0.5}'
```

**Test VR button**:
```bash
curl -X POST http://127.0.0.1:8080/input/vr_button \
  -H "Content-Type: application/json" \
  -d '{"button": "trigger_right", "pressed": true, "duration": 0.3}'
```

**Expected**: Both should return `{"status": "success", ...}`

---

## Task 2: Add State Query Endpoints (1-2 hours)

### Goal
Add HTTP API endpoints that allow tests to query game state, player state, and FPS.

### Step 2.1: Add Routing

**File**: `addons\godot_debug_connection\godot_bridge.gd`

**Location**: In `_route_request()`, after the `/input/` endpoint

**Add this code**:
```gdscript
	# State query endpoints (for automated testing)
	elif path.begins_with("/state/"):
		_handle_state_endpoint(client, method, path, body)
```

### Step 2.2: Add State Handler Function

**Add this function**:
```gdscript
## Handle state query endpoints
func _handle_state_endpoint(client: StreamPeerTCP, method: String, path: String, body: String) -> void:
	var state_query = path.substr(7)  # Remove "/state/" prefix

	match state_query:
		"game":
			_handle_state_game(client)
		"player":
			_handle_state_player(client)
		_:
			_send_error_response(client, 404, "Not Found", "Unknown state query: " + state_query)
```

### Step 2.3: Add Game State Handler

**Add this function**:
```gdscript
## Get overall game state
func _handle_state_game(client: StreamPeerTCP) -> void:
	var state = {
		"fps": Engine.get_frames_per_second(),
		"time": Time.get_ticks_msec() / 1000.0,
		"scene": get_tree().current_scene.name if get_tree().current_scene else "none"
	}

	# Add ResonanceEngine state if available
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine:
		state["engine_initialized"] = engine._is_initialized

	_send_json_response(client, 200, state)
```

### Step 2.4: Add Player State Handler

**Add this function**:
```gdscript
## Get player state
func _handle_state_player(client: StreamPeerTCP) -> void:
	var state = {}

	# Try to find player/spacecraft node
	var player = get_tree().root.find_child("Spacecraft", true, false)
	if not player:
		player = get_tree().root.find_child("WalkingController", true, false)

	if player:
		state["position"] = [player.global_position.x, player.global_position.y, player.global_position.z]
		state["exists"] = true

		# Check for inventory
		var inventory = player.get_node_or_null("Inventory")
		if inventory:
			state["inventory"] = {}  # Add inventory items here

		# Check for life support
		var life_support = get_node_or_null("/root/LifeSupportSystem")
		if life_support:
			state["oxygen"] = life_support.get("oxygen_level") if "oxygen_level" in life_support else 100.0
			state["hunger"] = life_support.get("hunger_level") if "hunger_level" in life_support else 100.0
			state["thirst"] = life_support.get("thirst_level") if "thirst_level" in life_support else 100.0
	else:
		state["exists"] = false
		state["message"] = "Player node not found"

	_send_json_response(client, 200, state)
```

### Step 2.5: Add FPS Query (in /debug/)

**Update the `/debug/` routing** to add getFPS:

Find the `_handle_debug_endpoint()` function's match statement and add:
```gdscript
match command:
	# ... existing commands ...
	"getFPS":
		_handle_debug_get_fps(client)
```

**Add the handler function**:
```gdscript
## Get current FPS
func _handle_debug_get_fps(client: StreamPeerTCP) -> void:
	var fps = Engine.get_frames_per_second()
	_send_json_response(client, 200, {
		"fps": fps,
		"target_fps": 90
	})
```

### Step 2.6: Test the Endpoints

```bash
# Test game state
curl http://127.0.0.1:8080/state/game

# Test player state
curl http://127.0.0.1:8080/state/player

# Test FPS
curl http://127.0.0.1:8080/debug/getFPS
```

**Expected**: All should return JSON with the requested data.

---

## Task 3: Write Phase 1 Checkpoint Tests (3-4 hours)

### Goal
Create automated VR playtest scripts that validate all Phase 1 features.

### Step 3.1: Create Test File

**Create file**: `tests\phase1_checkpoint_tests.py`

**Template**:
```python
#!/usr/bin/env python3
"""
Phase 1 Checkpoint Tests - Automated VR Playtests
Tests the first 5 minutes of gameplay: spawn, mine, craft, survive
"""

import pytest
import asyncio
from vr_playtest_framework import (
    VRPlaytestFramework,
    PlaytestStep,
    VRButton,
    TestResult
)


@pytest.mark.asyncio
async def test_player_spawn():
    """Test: Player spawns correctly in VR"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        PlaytestStep(
            name="Wait for game start",
            action="wait 3.0",
            duration=3.0
        ),
        PlaytestStep(
            name="Verify player exists",
            action="wait 0.5",
            duration=0.5,
            validation=lambda: _player_exists(framework),
            timeout=10.0
        ),
        PlaytestStep(
            name="Verify FPS is good",
            action="wait 1.0",
            duration=1.0,
            validation=lambda: _fps_above_90(framework)
        ),
    ]

    result = await framework.run_playtest("Player Spawn Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS
    assert result.fps_min >= 90.0


@pytest.mark.asyncio
async def test_first_excavation():
    """Test: Player can excavate terrain and collect soil"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        PlaytestStep(
            name="Wait for spawn",
            action="wait 2.0",
            duration=2.0
        ),
        # TODO: Add steps to:
        # 1. Equip terrain tool
        # 2. Aim at ground
        # 3. Press trigger to excavate
        # 4. Verify canister has soil
        # 5. Verify FPS maintained
    ]

    result = await framework.run_playtest("First Excavation Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS


@pytest.mark.asyncio
async def test_resource_gathering():
    """Test: Player can mine resource nodes and collect fragments"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        # TODO: Implement
        PlaytestStep(
            name="TODO",
            action="wait 1.0",
            duration=1.0
        ),
    ]

    result = await framework.run_playtest("Resource Gathering Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS


@pytest.mark.asyncio
async def test_first_crafting():
    """Test: Player can craft oxygen canister from resources"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        # TODO: Implement
        PlaytestStep(
            name="TODO",
            action="wait 1.0",
            duration=1.0
        ),
    ]

    result = await framework.run_playtest("First Crafting Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS


@pytest.mark.asyncio
async def test_oxygen_depletion():
    """Test: Oxygen depletes and warnings trigger correctly"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        # TODO: Implement
        PlaytestStep(
            name="TODO",
            action="wait 1.0",
            duration=1.0
        ),
    ]

    result = await framework.run_playtest("Oxygen Depletion Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS


# Helper functions
async def _player_exists(framework):
    """Check if player node exists"""
    state = await framework.get_player_state()
    return state.get("exists", False)


async def _fps_above_90(framework):
    """Check if FPS is above 90"""
    fps = await framework.get_fps()
    return fps >= 90.0


if __name__ == "__main__":
    # Run all tests
    pytest.main([__file__, "-v"])
```

### Step 3.2: Implement Each Test

**For each test function**:
1. Add meaningful `PlaytestStep` sequences
2. Add validation lambdas to check conditions
3. Test locally
4. Fix any failures

**Example complete test**:
```python
@pytest.mark.asyncio
async def test_first_excavation():
    """Test: Player can excavate terrain and collect soil"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        PlaytestStep(
            name="Wait for spawn",
            action="wait 2.0",
            duration=2.0
        ),
        PlaytestStep(
            name="Equip terrain tool (press E)",
            action="key E",
            duration=0.5,
            validation=lambda: _tool_equipped(framework, "terrain_tool"),
            timeout=5.0
        ),
        PlaytestStep(
            name="Excavate ground (hold trigger)",
            action="vr_button trigger_right",
            duration=3.0
        ),
        PlaytestStep(
            name="Verify soil collected",
            action="wait 0.5",
            duration=0.5,
            validation=lambda: _canister_has_soil(framework),
            timeout=5.0
        ),
        PlaytestStep(
            name="Verify FPS maintained",
            action="wait 1.0",
            duration=1.0,
            validation=lambda: _fps_above_90(framework)
        ),
    ]

    result = await framework.run_playtest("First Excavation Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS
    assert result.fps_min >= 90.0
    assert result.fps_avg >= 90.0


async def _tool_equipped(framework, tool_name):
    """Check if specific tool is equipped"""
    state = await framework.get_player_state()
    return state.get("equipped_tool") == tool_name


async def _canister_has_soil(framework):
    """Check if canister has any soil"""
    state = await framework.get_player_state()
    return state.get("canister_soil", 0) > 0
```

### Step 3.3: Run Tests

```bash
cd tests
python -m pytest phase1_checkpoint_tests.py::test_player_spawn -v
python -m pytest phase1_checkpoint_tests.py::test_first_excavation -v
# ... etc for each test
```

**Fix failures** until all tests pass.

### Step 3.4: Run Full Phase 1 Checkpoint

```bash
python -m pytest phase1_checkpoint_tests.py -v
```

**Expected**: All 5 tests pass with 90+ FPS.

---

## Task 4: Manual VR Validation (1-2 hours)

### Step 4.1: Put on VR Headset

1. Start Godot (should already be running)
2. Put on VR headset
3. Start the game in VR mode

### Step 4.2: Play Through First 10 Minutes

- [ ] Spawn in world
- [ ] See tutorial prompts
- [ ] Equip terrain tool
- [ ] Excavate some terrain
- [ ] See canister fill with soil
- [ ] Mine a resource node
- [ ] Collect resource fragments
- [ ] Open inventory
- [ ] Craft oxygen canister
- [ ] Use oxygen canister
- [ ] Survive for 10 minutes

### Step 4.3: Check VR Comfort

- [ ] No judder or stuttering
- [ ] UI text is readable
- [ ] No VR sickness
- [ ] Controls feel natural
- [ ] Performance feels smooth

### Step 4.4: Check FPS

- Enable FPS counter in VR
- Verify 90 FPS maintained throughout

### Step 4.5: Document Results

Create `PHASE1_VALIDATION_REPORT.md`:
```markdown
# Phase 1 Manual VR Validation Report

**Date**: [Today's date]
**Tester**: [Your name or "AI Agent"]
**Duration**: [How long you played]

## Checklist

- [ ] Player spawn works
- [ ] Terrain excavation works
- [ ] Resource gathering works
- [ ] Crafting works
- [ ] Oxygen system works
- [ ] FPS >= 90 throughout
- [ ] No VR sickness
- [ ] UI readable

## Issues Found

- [List any issues]

## Notes

- [Any additional observations]

## Result

PASS / FAIL

[If FAIL, list blocking issues]
```

---

## Task 5: Mark Phase 1 Complete (15 min)

### Step 5.1: Update tasks.md

**File**: `.kiro\specs\planetary-survival\tasks.md`

Find tasks 3 and 4, mark them complete:
```markdown
- [x] 3. Build terrain tool VR controller
- [x] 4. Checkpoint - Verify terrain deformation works in VR
```

### Step 5.2: Verify Progress

```bash
python check_progress.py
```

**Expected**:
```
[*] CURRENT PHASE: 2 - First Hour - Base Foundation
    Goal: Build first base, establish power, create safety
```

### Step 5.3: Commit Changes

```bash
git add .
git commit -m "feat: Phase 1 complete - VR automated testing infrastructure

- Added input injection endpoints to godot_bridge.gd
- Added state query endpoints to godot_bridge.gd
- Created phase1_checkpoint_tests.py with 5 automated VR playtests
- All tests passing with 90+ FPS
- Manual VR validation complete
- Phase 1: First 5 Minutes - COMPLETE"
```

### Step 5.4: Update Status Files

**Update `PLANETARY_SURVIVAL_STATUS.md`**:
- Change "Current Phase" to 2
- Change "Progress" to 8/8 tasks (100%)
- Update "Last Updated" date
- Move Phase 1 to "Completed Features"

---

## Troubleshooting

### Godot Not Responding
```bash
taskkill /IM Godot*.exe /F
./restart_godot_with_debug.bat
```

### Endpoints Returning 404
- Check routing in `_route_request()`
- Verify function names match
- Check for typos in path strings

### Tests Timing Out
- Increase timeout values in PlaytestStep
- Check if game state is actually changing
- Add debug prints to validation functions

### FPS Below 90
- Profile with: `./run_performance_test.bat`
- Check telemetry: `python telemetry_client.py`
- Disable features to isolate issue

### State Queries Returning Empty
- Verify node paths in handlers
- Check if systems are initialized
- Add fallback values for missing data

---

## Success Criteria

Before marking complete:

- ✅ All input injection endpoints working
- ✅ All state query endpoints working
- ✅ All 5 Phase 1 tests passing
- ✅ FPS >= 90 throughout tests
- ✅ Manual VR validation passed
- ✅ No critical bugs found
- ✅ Documentation updated
- ✅ Changes committed

---

## Time Estimates

- Task 1: 2-3 hours (input injection endpoints)
- Task 2: 1-2 hours (state query endpoints)
- Task 3: 3-4 hours (write tests)
- Task 4: 1-2 hours (manual VR validation)
- Task 5: 15 min (mark complete)

**Total: 6-8 hours**

---

## Next Phase Preview

Once Phase 1 is complete, Phase 2 begins:

**Phase 2: First Hour - Base Foundation**
- Goal: Player builds first base, establishes power, creates safety zone
- Tasks:
  - Starter base module placement
  - Pressurization & oxygen regeneration
  - First power system
- Checkpoint: Functioning base with oxygen regeneration

See `DEVELOPMENT_WORKFLOW.md` for full Phase 2 details.

---

**Ready to start? Begin with Task 1: Add Input Injection Endpoints**

Good luck! 🚀
