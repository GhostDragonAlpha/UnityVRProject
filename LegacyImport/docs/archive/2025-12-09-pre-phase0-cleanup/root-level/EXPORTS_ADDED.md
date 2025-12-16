# @export Annotations Added to Core Systems

## Summary
Added 10 @export annotations across 4 core system files, making tunable parameters adjustable in the Godot Editor inspector.

---

## File-by-File Summary

### 1. C:/godot/scripts/core/physics_engine.gd
**Parameters Added: 2**

- `@export var max_interaction_radius: float = 10000.0`
  - Maximum distance for gravity calculations
  - Default: 10,000 units
  - Impact: Controls performance vs. physics accuracy trade-off

- `@export var _grid_cell_size: float = 1000.0`
  - Spatial grid cell size for physics optimization
  - Default: 1,000 units per cell
  - Impact: Adjusts spatial partitioning granularity

---

### 2. C:/godot/scripts/core/haptic_manager.gd
**Parameters Added: 5**

Converted haptic duration constants to @export variables with backward-compatible properties:

- `@export var duration_instant: float = 0.05`
  - Very brief haptic pulses
  - Used for: Resource collection feedback

- `@export var duration_short: float = 0.1`
  - Short haptic pulses
  - Used for: Control activation, damage feedback

- `@export var duration_medium: float = 0.2`
  - Medium duration haptic feedback
  - Used for: Collision feedback

- `@export var duration_long: float = 0.5`
  - Long sustained haptic feedback
  - Used for: Extended effects

- `@export var duration_continuous: float = 1.0`
  - Continuous looping haptic effect
  - Used for: Gravity well vibration

**Backward Compatibility:** Added property getters to maintain existing code:
```gdscript
var DURATION_INSTANT: float:
    get: return duration_instant
# ... etc for all 5 durations
```

---

### 3. C:/godot/scripts/core/floating_origin.gd
**Parameters Added: 2**

Converted floating-point precision management constants to @export variables:

- `@export var rebase_threshold: float = 5000.0`
  - Distance from origin that triggers coordinate rebasing
  - Default: 5,000 units
  - Impact: Prevents floating-point precision loss in large universes

- `@export var min_rebase_distance: float = 100.0`
  - Minimum movement distance to trigger rebasing
  - Default: 100 units
  - Impact: Prevents unnecessary rebasing operations

**Backward Compatibility:** Added property getters:
```gdscript
var REBASE_THRESHOLD: float:
    get: return rebase_threshold
var MIN_REBASE_DISTANCE: float:
    get: return min_rebase_distance
```

---

### 4. C:/godot/scripts/core/time_manager.gd
**Parameters Added: 1**

- `@export var transition_duration: float = 0.5`
  - Duration of smooth acceleration transitions
  - Default: 0.5 seconds
  - Impact: Controls how smoothly time factor changes occur

**Backward Compatibility:** Added property getter:
```gdscript
var TRANSITION_DURATION: float:
    get: return transition_duration
```

---

## Designer Usage

All parameters are now visible and editable in the Godot Editor inspector when any of these systems are selected or when they exist as autoloads:

### To Adjust Parameters:
1. Open Godot Editor
2. Navigate to the ResonanceEngine node in the scene tree
3. Select the appropriate subsystem (PhysicsEngine, HapticManager, etc.)
4. Modify the @export variable values in the Inspector panel
5. Changes apply immediately on play

### Tuning Guidelines:

**Physics Performance:**
- Increase `max_interaction_radius` for more accurate distant gravity (higher CPU cost)
- Adjust `_grid_cell_size` larger for better performance, smaller for better accuracy

**Haptic Feedback:**
- Increase any `duration_*` values for longer feedback
- Reduce for quicker, snappier feedback
- Adjust `master_intensity` multiplier separately if needed

**Floating-Point Precision:**
- Lower `rebase_threshold` for safer precision (more frequent rebasing)
- Increase `min_rebase_distance` to avoid thrashing (fewer rebasing operations)

**Time Transitions:**
- Increase `transition_duration` for smoother time acceleration changes
- Decrease for snappier, more immediate time factor changes

---

## Technical Implementation

All exported parameters maintain backward compatibility through property getters. This allows:
- Existing code using constant names (e.g., `DURATION_SHORT`) to continue working
- New code to reference either the constant property or the exported variable
- Runtime adjustment without code changes

Example:
```gdscript
# Both work identically:
trigger_haptic("left", 0.5, self.DURATION_SHORT)        # Old constant style
trigger_haptic("left", 0.5, self.duration_short)        # New exported variable
```

---

## Total Export Count: 10 parameters

| File | Exports | Type |
|------|---------|------|
| physics_engine.gd | 2 | Physics tuning |
| haptic_manager.gd | 5 | VR feedback |
| floating_origin.gd | 2 | Coordinate system |
| time_manager.gd | 1 | Simulation timing |
| **TOTAL** | **10** | **Multi-system** |

All exports are now available for designer/playtester tuning in the Godot Editor Inspector.
