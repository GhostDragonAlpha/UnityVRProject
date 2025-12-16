# Gravity Well Capture Event System Guide

## Overview

The Capture Event System provides dramatic transitions when a spacecraft's velocity falls below escape velocity within a gravity well. This creates an immersive "falling into" experience that transitions the player from interstellar space to the interior of a star system.

## Quick Start

### Basic Setup

```gdscript
# In your main scene or game manager:
extends Node3D

var spacecraft: Spacecraft
var pilot_controller: PilotController

func _ready():
    # Get engine reference
    var engine = get_node("/root/ResonanceEngine")

    # Initialize capture event system
    engine.initialize_capture_event_system(spacecraft, pilot_controller)

    # Connect to signals (optional)
    engine.capture_event_system.capture_detected.connect(_on_capture_detected)
    engine.capture_event_system.spiral_completed.connect(_on_spiral_completed)
    engine.capture_event_system.level_transition_completed.connect(_on_level_loaded)

func _on_capture_detected(body: RigidBody3D, source: Node3D):
    print("Captured by: ", source.name)
    # Play capture sound, show UI notification, etc.

func _on_spiral_completed(body: RigidBody3D, source: Node3D):
    print("Spiral complete, transitioning...")
    # Fade screen, prepare for level transition

func _on_level_loaded(level_name: String):
    print("Loaded interior system: ", level_name)
    # Update UI, spawn player at entry point, etc.
```

## How It Works

### 1. Detection Phase

The PhysicsEngine continuously monitors spacecraft velocity relative to escape velocity:

```gdscript
# In PhysicsEngine._check_capture_events():
if distance < sphere_of_influence and velocity < escape_velocity:
    capture_event_triggered.emit(body, celestial_body)
```

### 2. Control Lock Phase

When capture is detected, player controls are locked:

```gdscript
# In CaptureEventSystem:
pilot_controller.set_controls_locked(true)
spacecraft.set_throttle(0.0)
spacecraft.set_rotation_input(Vector3.ZERO)
```

### 3. Spiral Animation Phase

The spacecraft follows a spiral trajectory toward the gravity source:

- **Duration**: 3 seconds (configurable)
- **Rotations**: 2.5 full rotations (configurable)
- **Radius**: Decreases from current distance to near-zero
- **Velocity**: Reduces by 80% during spiral
- **Orientation**: Spacecraft faces toward target

### 4. Zoom Transition Phase

When the spiral completes, fractal zoom is triggered:

```gdscript
# Zooms IN to reveal interior system
fractal_zoom.zoom(FractalZoomSystem.ZoomDirection.IN)
```

### 5. Level Transition Phase

After zoom completes, the interior system is loaded:

```gdscript
# Placeholder for actual implementation
_load_interior_system()
level_transition_completed.emit("interior_" + source.name)
```

## Configuration

### Adjusting Spiral Parameters

```gdscript
# In capture_event_system.gd, modify constants:
const SPIRAL_DURATION: float = 3.0           # Animation time in seconds
const SPIRAL_ROTATIONS: float = 2.5          # Number of full rotations
const ZOOM_TRIGGER_DISTANCE: float = 50.0    # Distance to trigger zoom early
```

### Enabling/Disabling Captures

```gdscript
# Disable capture events (for testing, cutscenes, etc.)
var engine = get_node("/root/ResonanceEngine")
engine.set_capture_events_enabled(false)

# Re-enable later
engine.set_capture_events_enabled(true)
```

### Cancelling In-Progress Capture

```gdscript
# Cancel capture (for emergency escape, player death, etc.)
var engine = get_node("/root/ResonanceEngine")
if engine.is_capture_in_progress():
    engine.cancel_capture_event()
```

## Signals Reference

### capture_detected(body: RigidBody3D, source: Node3D)

Emitted when a capture event is first detected.

- **body**: The spacecraft being captured
- **source**: The celestial body causing the capture

### spiral_started(body: RigidBody3D, source: Node3D)

Emitted when the spiral animation begins.

### spiral_completed(body: RigidBody3D, source: Node3D)

Emitted when the spiral animation finishes.

### zoom_transition_started(source: Node3D)

Emitted when fractal zoom begins.

### level_transition_completed(new_level: String)

Emitted when the interior system is loaded.

- **new_level**: Name of the loaded level/system

### capture_cancelled()

Emitted when a capture is manually cancelled.

## Advanced Usage

### Custom Spiral Animation

You can modify the spiral trajectory calculation in `_update_spiral_position()`:

```gdscript
func _update_spiral_position(progress: float) -> void:
    # Custom radius function (e.g., exponential decay)
    var current_radius = _spiral_start_radius * exp(-progress * 3.0)

    # Custom angle function (e.g., accelerating rotation)
    var angle = progress * progress * SPIRAL_ROTATIONS * TAU

    # ... rest of position calculation
```

### Adding Visual Effects

Connect to signals to trigger effects:

```gdscript
func _on_spiral_started(body, source):
    # Add particle effects
    var particles = GPUParticles3D.new()
    particles.emitting = true
    body.add_child(particles)

    # Add screen effects
    var post_process = get_node("PostProcess")
    post_process.enable_warp_effect()

    # Play audio
    var audio = AudioStreamPlayer3D.new()
    audio.stream = preload("res://audio/capture_whoosh.ogg")
    audio.play()
```

### Implementing Interior System Loading

Replace the placeholder in `_load_interior_system()`:

```gdscript
func _load_interior_system() -> void:
    # Get the captured celestial body's data
    var system_data = _get_system_data(_capture_target)

    # Generate or load interior system
    var interior_scene = _generate_interior_system(system_data)

    # Scale the star to become skybox
    var star_skybox = _create_star_skybox(_capture_target)
    interior_scene.add_child(star_skybox)

    # Position player at system edge
    spacecraft.global_position = _calculate_entry_position(system_data)

    # Update floating origin
    var engine = get_node("/root/ResonanceEngine")
    engine.floating_origin.rebase_to_position(spacecraft.global_position)

    # Load the scene
    get_tree().change_scene_to_packed(interior_scene)

    level_transition_completed.emit("interior_" + _capture_target.name)
```

## Troubleshooting

### Capture Not Triggering

1. **Check PhysicsEngine**: Ensure capture events are enabled

   ```gdscript
   physics_engine.set_capture_events_enabled(true)
   ```

2. **Verify Celestial Body**: Ensure the gravity source is registered

   ```gdscript
   physics_engine.add_celestial_body(star, mass, radius)
   ```

3. **Check Velocity**: Ensure spacecraft velocity is actually below escape velocity
   ```gdscript
   var escape_vel = physics_engine.calculate_escape_velocity(...)
   print("Escape velocity: ", escape_vel)
   print("Current velocity: ", spacecraft.linear_velocity.length())
   ```

### Controls Not Locking

1. **Check PilotController**: Ensure it's passed to initialization

   ```gdscript
   capture_system.initialize(spacecraft, pilot_controller)
   ```

2. **Verify Method Exists**: Check that PilotController has `set_controls_locked()`
   ```gdscript
   if pilot_controller.has_method("set_controls_locked"):
       print("Method exists")
   ```

### Spiral Animation Jerky

1. **Check Frame Rate**: Ensure game is running at target FPS
2. **Adjust Tween Settings**: Modify transition type in `_start_spiral_animation()`
   ```gdscript
   _spiral_tween.set_trans(Tween.TRANS_SINE)  # Try different transitions
   _spiral_tween.set_ease(Tween.EASE_IN_OUT)
   ```

### Zoom Not Triggering

1. **Check FractalZoomSystem**: Ensure it's initialized

   ```gdscript
   if fractal_zoom == null:
       print("FractalZoomSystem not available")
   ```

2. **Verify Player Node**: Ensure fractal zoom has player reference
   ```gdscript
   engine.set_fractal_zoom_player(spacecraft, environment_root)
   ```

## Performance Considerations

- **Single Tween**: Uses one tween for smooth animation without overhead
- **Minimal Calculations**: Position updates are lightweight
- **Automatic Cleanup**: Resources are freed after completion
- **Signal Efficiency**: Signals only emitted at key moments

## Best Practices

1. **Always Initialize**: Call `initialize()` before captures can occur
2. **Connect Signals Early**: Set up signal handlers in `_ready()`
3. **Handle Cancellation**: Provide escape mechanism for players
4. **Test Edge Cases**: Test with various velocities and distances
5. **Provide Feedback**: Use signals to give player visual/audio cues
6. **Save State**: Store capture state in save files if needed

## Example: Complete Integration

```gdscript
extends Node3D

@onready var spacecraft = $Spacecraft
@onready var pilot_controller = $PilotController
@onready var camera = $Camera3D
@onready var ui = $UI

var engine: Node
var capture_system: CaptureEventSystem

func _ready():
    engine = get_node("/root/ResonanceEngine")

    # Initialize capture system
    engine.initialize_capture_event_system(spacecraft, pilot_controller)
    capture_system = engine.capture_event_system

    # Connect all signals
    capture_system.capture_detected.connect(_on_capture_detected)
    capture_system.spiral_started.connect(_on_spiral_started)
    capture_system.spiral_completed.connect(_on_spiral_completed)
    capture_system.zoom_transition_started.connect(_on_zoom_started)
    capture_system.level_transition_completed.connect(_on_level_loaded)
    capture_system.capture_cancelled.connect(_on_capture_cancelled)

func _on_capture_detected(body, source):
    ui.show_notification("Entering gravity well of " + source.name)
    $AudioManager.play_sound("capture_warning")

func _on_spiral_started(body, source):
    ui.show_message("Falling into " + source.name + "...")
    camera.enable_cinematic_mode()
    $ParticleEffects.enable_warp_particles()

func _on_spiral_completed(body, source):
    ui.fade_to_black(1.0)

func _on_zoom_started(source):
    $AudioManager.play_sound("zoom_transition")

func _on_level_loaded(level_name):
    ui.fade_from_black(1.0)
    ui.show_message("Arrived at " + level_name)
    camera.disable_cinematic_mode()

func _on_capture_cancelled():
    ui.show_message("Capture sequence cancelled")
    camera.disable_cinematic_mode()

func _input(event):
    # Allow player to cancel capture with escape key
    if event.is_action_pressed("ui_cancel"):
        if engine.is_capture_in_progress():
            engine.cancel_capture_event()
```

## See Also

- `PhysicsEngine` - Handles gravity calculations and capture detection
- `FractalZoomSystem` - Manages scale transitions
- `PilotController` - Handles player input and control locking
- `FloatingOriginSystem` - Manages coordinate rebasing during transitions
