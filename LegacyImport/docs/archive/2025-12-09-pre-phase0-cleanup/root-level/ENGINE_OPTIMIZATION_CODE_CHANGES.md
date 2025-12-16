# Engine.gd Optimization - Exact Code Changes

## File: C:/godot/scripts/core/engine.gd

### Change 1: Add Cache Variables (After line 48)

**Location**: After `var _last_fps := 0.0` (line 48)

**Add these lines**:
```gdscript
## Subsystem update method availability cache (eliminates per-frame has_method() calls)
## These flags are set during initialization and dramatically improve performance
## Performance gain: ~720 method lookups per second eliminated at 90 FPS target
var _vr_has_update := false
var _vr_comfort_has_update := false
var _relativity_has_update := false
var _floating_origin_has_update := false
var _physics_has_update := false
var _time_manager_has_update := false
var _renderer_has_update := false
var _audio_has_update := false
var _fractal_zoom_has_update := false
```

---

### Change 2: Add Cache Function (After line 134)

**Location**: After `_init_subsystem()` function (after line 134)

**Add this new function**:
```gdscript

func _cache_subsystem_methods() -> void:
	"""Cache which subsystems have update() methods to avoid per-frame has_method() calls.

	This is called once during initialization and stores boolean flags for each subsystem's
	update() method availability. Per-frame update calls then check these flags instead of
	calling has_method(), eliminating ~720 method lookups per second at 90 FPS target.

	Performance benefit:
	  Before: 8 subsystems × 90 FPS × has_method() cost = 720 lookups/second
	  After:  8 subsystems × 90 FPS × boolean check = negligible overhead
	"""
	_vr_has_update = vr_manager != null and vr_manager.has_method("update")
	_vr_comfort_has_update = vr_comfort_system != null and vr_comfort_system.has_method("update")
	_relativity_has_update = relativity != null and relativity.has_method("update")
	_floating_origin_has_update = floating_origin != null and floating_origin.has_method("update")
	_physics_has_update = physics_engine != null and physics_engine.has_method("update")
	_time_manager_has_update = time_manager != null and time_manager.has_method("update")
	_renderer_has_update = renderer != null and renderer.has_method("update")
	_audio_has_update = audio_manager != null and audio_manager.has_method("update")
	_fractal_zoom_has_update = fractal_zoom != null and fractal_zoom.has_method("update")

	log_debug("Cached subsystem update methods: VR=%s, Comfort=%s, Relativity=%s, FloatingOrigin=%s, Physics=%s, TimeManager=%s, Renderer=%s, Audio=%s, FractalZoom=%s" % [
		_vr_has_update, _vr_comfort_has_update, _relativity_has_update, _floating_origin_has_update,
		_physics_has_update, _time_manager_has_update, _renderer_has_update, _audio_has_update, _fractal_zoom_has_update
	])
```

---

### Change 3: Call Cache Function (In _initialize_engine)

**Location**: In `_initialize_engine()` function, after line 112 (after SaveSystem init)

**Find this code**:
```gdscript
	# Phase 7: Persistence
	init_success = init_success and _init_subsystem("SettingsManager", _init_settings_manager)
	init_success = init_success and _init_subsystem("SaveSystem", _init_save_system)

	if init_success:
```

**Replace with**:
```gdscript
	# Phase 7: Persistence
	init_success = init_success and _init_subsystem("SettingsManager", _init_settings_manager)
	init_success = init_success and _init_subsystem("SaveSystem", _init_save_system)

	# CRITICAL: Cache subsystem method availability after initialization
	_cache_subsystem_methods()

	if init_success:
```

---

### Change 4-12: Optimize All Update Methods (Lines 468-519)

#### Update Method 1: _update_vr (Line 468)

**Find**:
```gdscript
func _update_vr(delta: float) -> void:
	"""Update VR tracking and input."""
	if vr_manager != null and vr_manager.has_method("update"):
		vr_manager.update(delta)
```

**Replace with**:
```gdscript
func _update_vr(delta: float) -> void:
	"""Update VR tracking and input.

	OPTIMIZATION: Checks cached _vr_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _vr_has_update:
		vr_manager.update(delta)
```

---

#### Update Method 2: _update_vr_comfort (Line 474)

**Find**:
```gdscript
func _update_vr_comfort(delta: float) -> void:
	"""Update VR comfort system."""
	if vr_comfort_system != null and vr_comfort_system.has_method("update"):
		vr_comfort_system.update(delta)
```

**Replace with**:
```gdscript
func _update_vr_comfort(delta: float) -> void:
	"""Update VR comfort system.

	OPTIMIZATION: Checks cached _vr_comfort_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _vr_comfort_has_update:
		vr_comfort_system.update(delta)
```

---

#### Update Method 3: _update_relativity (Line 480)

**Find**:
```gdscript
func _update_relativity(delta: float) -> void:
	"""Update relativistic effects."""
	if relativity != null and relativity.has_method("update"):
		relativity.update(delta)
```

**Replace with**:
```gdscript
func _update_relativity(delta: float) -> void:
	"""Update relativistic effects.

	OPTIMIZATION: Checks cached _relativity_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _relativity_has_update:
		relativity.update(delta)
```

---

#### Update Method 4: _update_floating_origin (Line 486)

**Find**:
```gdscript
func _update_floating_origin(delta: float) -> void:
	"""Update floating origin system."""
	if floating_origin != null and floating_origin.has_method("update"):
		floating_origin.update(delta)
```

**Replace with**:
```gdscript
func _update_floating_origin(delta: float) -> void:
	"""Update floating origin system.

	OPTIMIZATION: Checks cached _floating_origin_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _floating_origin_has_update:
		floating_origin.update(delta)
```

---

#### Update Method 5: _update_physics (Line 492)

**Find**:
```gdscript
func _update_physics(delta: float) -> void:
	"""Update physics simulation."""
	if physics_engine != null and physics_engine.has_method("update"):
		physics_engine.update(delta)
```

**Replace with**:
```gdscript
func _update_physics(delta: float) -> void:
	"""Update physics simulation.

	OPTIMIZATION: Checks cached _physics_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _physics_has_update:
		physics_engine.update(delta)
```

---

#### Update Method 6: _update_time_manager (Line 498)

**Find**:
```gdscript
func _update_time_manager(delta: float) -> void:
	"""Update simulation time."""
	if time_manager != null and time_manager.has_method("update"):
		time_manager.update(delta)
```

**Replace with**:
```gdscript
func _update_time_manager(delta: float) -> void:
	"""Update simulation time.

	OPTIMIZATION: Checks cached _time_manager_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _time_manager_has_update:
		time_manager.update(delta)
```

---

#### Update Method 7: _update_renderer (Line 504)

**Find**:
```gdscript
func _update_renderer(delta: float) -> void:
	"""Update rendering systems."""
	if renderer != null and renderer.has_method("update"):
		renderer.update(delta)
```

**Replace with**:
```gdscript
func _update_renderer(delta: float) -> void:
	"""Update rendering systems.

	OPTIMIZATION: Checks cached _renderer_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _renderer_has_update:
		renderer.update(delta)
```

---

#### Update Method 8: _update_audio (Line 510)

**Find**:
```gdscript
func _update_audio(delta: float) -> void:
	"""Update audio systems."""
	if audio_manager != null and audio_manager.has_method("update"):
		audio_manager.update(delta)
```

**Replace with**:
```gdscript
func _update_audio(delta: float) -> void:
	"""Update audio systems.

	OPTIMIZATION: Checks cached _audio_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _audio_has_update:
		audio_manager.update(delta)
```

---

#### Update Method 9: _update_fractal_zoom (Line 516)

**Find**:
```gdscript
func _update_fractal_zoom(delta: float) -> void:
	"""Update fractal zoom system."""
	if fractal_zoom != null and fractal_zoom.has_method("update"):
		fractal_zoom.update(delta)
```

**Replace with**:
```gdscript
func _update_fractal_zoom(delta: float) -> void:
	"""Update fractal zoom system.

	OPTIMIZATION: Checks cached _fractal_zoom_has_update flag instead of calling has_method().
	This eliminates per-frame method lookup overhead.
	"""
	if _fractal_zoom_has_update:
		fractal_zoom.update(delta)
```

---

### Change 5: Update _process() Documentation (Line 424)

**Find**:
```gdscript
func _process(delta: float) -> void:
	"""Main process loop - updates all subsystems that need per-frame updates."""
	if not _is_initialized or _is_shutting_down:
		return
```

**Replace with**:
```gdscript
func _process(delta: float) -> void:
	"""Main process loop - updates all subsystems that need per-frame updates.

	OPTIMIZATION: Uses cached _*_has_update flags instead of calling has_method()
	on every frame. This eliminates ~720 method lookups per second at 90 FPS target.
	"""
	if not _is_initialized or _is_shutting_down:
		return
```

---

### Change 6: Update _physics_process() Documentation (Line 441)

**Find**:
```gdscript
func _physics_process(delta: float) -> void:
	"""Physics process loop - updates physics-related subsystems at fixed timestep."""
	if not _is_initialized or _is_shutting_down:
		return
```

**Replace with**:
```gdscript
func _physics_process(delta: float) -> void:
	"""Physics process loop - updates physics-related subsystems at fixed timestep.

	OPTIMIZATION: Uses cached _*_has_update flags instead of calling has_method()
	on every frame. This eliminates ~720 method lookups per second at 90 FPS target.
	"""
	if not _is_initialized or _is_shutting_down:
		return
```

---

## Summary of Changes

- **Lines Added**: ~80 lines
- **Lines Modified**: 17 lines (9 update methods + 2 process functions + 1 init call)
- **New Functions**: 1 (_cache_subsystem_methods)
- **New Variables**: 9 (boolean flags)
- **Files Modified**: 1 (engine.gd)

## Validation Checklist

After making all changes:

1. [ ] GDScript syntax is valid (no red squiggles in editor)
2. [ ] All 9 update methods use their corresponding cache flags
3. [ ] `_cache_subsystem_methods()` is called after all subsystems are initialized
4. [ ] No `has_method()` calls remain in update methods
5. [ ] Null checks removed from update methods (cached flags handle this)
6. [ ] Documentation updated to reference optimization
7. [ ] Test game launches without errors
8. [ ] Frame rate stays at 90 FPS
9. [ ] All subsystems update correctly despite optimization

## Testing Commands

After making changes, run:

```bash
# Start Godot with the modified engine
python godot_editor_server.py --port 8090

# Run health checks
cd tests
python health_monitor.py

# Run full test suite
python test_runner.py

# Check FPS in game
# Target: 90 FPS ± 5%
```

