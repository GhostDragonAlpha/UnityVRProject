# Jetpack Fuel Consumption Bug Report

## Summary

Jetpack fuel remains at 100% despite active use and correct consumption code.

## Test Evidence

- **Initial fuel:** 100.0%
- **After 2 seconds:** 100.0% (NO CHANGE)
- **Expected:** ~80% (10%/sec × 2s = 20% consumed)
- **Jetpack thrust:** WORKS (altitude changes observed: 0.58m gain during test)
- **Player status:** NOT on floor during test

## Root Cause Analysis

### Primary Suspect: Walking Controller Inactive

**File:** `C:/godot/scripts/player/walking_controller.gd`
**Lines:** 240-241

```gdscript
func _physics_process(delta: float) -> void:
    if not is_active:  # <-- EARLY RETURN IF NOT ACTIVE
        return
    # ALL fuel consumption code below is skipped if is_active = false
```

**Hypothesis:** The walking controller's `is_active` flag is FALSE, causing `_physics_process` to return early. This means:
- NO fuel consumption code executes
- NO velocity changes from jetpack thrust
- Yet the test observed altitude changes

**Questions:**
1. Is the walking controller actually activated during the test?
2. Is there another system applying thrust based on Space key input?
3. Are we testing the wrong Player node?

### Secondary Suspect: On-Floor Detection Timing

**File:** `C:/godot/scripts/player/walking_controller.gd`
**Lines:** 272-276

```gdscript
else:
    is_jetpack_active = false
    if is_on_floor():  # <-- Checks collision from PREVIOUS frame
        current_fuel += jetpack_fuel_recharge * delta
        if current_fuel > jetpack_fuel:
            current_fuel = jetpack_fuel  # Resets to max
```

**Hypothesis:** The `is_on_floor()` call might incorrectly return TRUE due to:
- Checking state from previous frame's `move_and_slide()` (line 307)
- Frame timing issues where player briefly touches ground
- Recharge rate (5%/sec) partially offsetting consumption (10%/sec)

**But:** This doesn't fully explain 0% consumption (would show partial consumption)

### Tertiary Suspect: Export Variable Override

**File:** `C:/godot/scenes/player/walking_controller.tscn`
**Lines:** 11-16

**Status:** Scene file does NOT override jetpack parameters. Uses script defaults:
- `jetpack_fuel = 100.0` ✓
- `jetpack_fuel_consumption = 10.0` ✓
- `jetpack_fuel_recharge = 5.0` ✓

**Conclusion:** NOT the root cause

## Expected vs Actual Behavior

### Expected Fuel Consumption

```
Physics rate: 90 FPS
Delta per frame: ~0.0111 seconds
Consumption per frame: 10.0 * 0.0111 = 0.111%
Frames in 2 seconds: 180
Total consumption: 0.111 * 180 = 19.98%
Expected fuel: 100 - 19.98 = 80.02%
```

### Actual Behavior

```
Initial fuel: 100.0%
After 2 seconds: 100.0%
Consumption: 0.0%
```

## Diagnostic Steps

### Step 1: Verify Walking Controller is Active

Add debug logging to `_physics_process`:

```gdscript
func _physics_process(delta: float) -> void:
    if not is_active:
        print("[WalkingController] INACTIVE - _physics_process skipped")
        return
    print("[WalkingController] ACTIVE - _physics_process running")
    # ... rest of function
```

### Step 2: Log Fuel Consumption

Add logging to jetpack code (lines 261-268):

```gdscript
if jetpack_enabled and is_jetpack_thrust_pressed() and current_fuel > 0:
    is_jetpack_active = true
    velocity += -gravity_direction * jetpack_thrust * delta
    var fuel_before = current_fuel
    current_fuel -= jetpack_fuel_consumption * delta
    if current_fuel < 0.0:
        current_fuel = 0.0
    print("[Jetpack] consumed: ", jetpack_fuel_consumption * delta,
          " fuel: ", fuel_before, " -> ", current_fuel)
```

### Step 3: Log Recharge Events

Add logging to recharge code (lines 272-276):

```gdscript
else:
    is_jetpack_active = false
    if is_on_floor():
        var fuel_before = current_fuel
        current_fuel += jetpack_fuel_recharge * delta
        if current_fuel > jetpack_fuel:
            current_fuel = jetpack_fuel
        print("[Jetpack] recharged: ", jetpack_fuel_recharge * delta,
              " fuel: ", fuel_before, " -> ", current_fuel)
```

### Step 4: Check Test Setup

Verify the test is actually using the WalkingController:

```python
# In quick_jetpack_test.py, add:
response = requests.get(f"{BASE_URL}/state/scene")
player = response.json().get("player")
print(f"Player type: {player['type']}")  # Should be CharacterBody3D
print(f"Player name: {player['name']}")  # Should be related to WalkingController
```

## Recommended Fix

Based on root cause #1 (most likely), the fix is:

### Fix #1: Ensure Walking Controller is Activated

**File:** Test setup or transition system

Ensure the walking controller is properly activated before testing:

```gdscript
# In transition_system or test setup
walking_controller.activate()  # <-- ADD THIS
# Then run jetpack test
```

### Fix #2: Move Recharge Check After move_and_slide()

**File:** `C:/godot/scripts/player/walking_controller.gd`

Move the fuel recharge logic to AFTER `move_and_slide()` so `is_on_floor()` reflects current state:

```gdscript
func _physics_process(delta: float) -> void:
    # ... existing code ...

    # Handle jetpack thrust
    if jetpack_enabled and is_jetpack_thrust_pressed() and current_fuel > 0:
        is_jetpack_active = true
        velocity += -gravity_direction * jetpack_thrust * delta
        current_fuel -= jetpack_fuel_consumption * delta
        if current_fuel < 0.0:
            current_fuel = 0.0
    else:
        is_jetpack_active = false

    # ... movement code ...

    # Move the character
    move_and_slide()

    # Update ground detection
    update_ground_detection()

    # NOW check fuel recharge (after move_and_slide)
    if not is_jetpack_active and is_on_floor():
        current_fuel += jetpack_fuel_recharge * delta
        if current_fuel > jetpack_fuel:
            current_fuel = jetpack_fuel
```

## Verification Steps

After applying the fix:

1. Run `python quick_jetpack_test.py`
2. Check Godot console for debug output
3. Verify fuel decreases during jetpack use
4. Verify fuel recharges when on ground and not using jetpack
5. Verify `is_active = true` in logs

## Expected Output After Fix

```
[WalkingController] ACTIVE - _physics_process running
[Jetpack] consumed: 0.111 fuel: 100.0 -> 99.889
[Jetpack] consumed: 0.111 fuel: 99.889 -> 99.778
...
[Jetpack] consumed: 0.111 fuel: 80.222 -> 80.111

Test Results:
  Initial fuel: 100.0%
  Final fuel: 80.1%
  Fuel consumed: 19.9% ✓
```

## Files Involved

- `C:/godot/scripts/player/walking_controller.gd` - Main bug location
- `C:/godot/scripts/player/transition_system.gd` - Creates walking controller
- `C:/godot/scenes/player/walking_controller.tscn` - Scene configuration
- `C:/godot/quick_jetpack_test.py` - Test script
- `C:/godot/addons/godot_debug_connection/godot_bridge.gd` - State reporting

## Next Actions

1. ☐ Add debug logging to identify root cause
2. ☐ Verify walking controller activation state
3. ☐ Apply fix #1 or #2 based on findings
4. ☐ Re-run tests to verify fix
5. ☐ Remove debug logging once fixed
6. ☐ Add regression test to prevent future occurrences
