# Walking System Quick Reference

## Quick Start

```gdscript
# Enable walking mode
transition_system.enable_walking_mode()

# Disable walking mode
transition_system.disable_walking_mode()

# Check if walking
if transition_system.is_walking_mode_active():
    print("Walking!")
```

## VR Controls

| Action | Left Controller  | Right Controller |
| ------ | ---------------- | ---------------- |
| Move   | Thumbstick       | -                |
| Sprint | Thumbstick Click | -                |
| Turn   | -                | Thumbstick L/R   |
| Jump   | -                | A Button         |
| Return | -                | B Button         |

## Desktop Controls

| Action | Key     |
| ------ | ------- |
| Move   | W/A/S/D |
| Look   | Mouse   |
| Sprint | Shift   |
| Jump   | Space   |
| Return | E       |

## Key Functions

```gdscript
# WalkingController
walking_controller.initialize(vr_manager, planet, spawn_pos, spacecraft)
walking_controller.activate()
walking_controller.deactivate()
walking_controller.get_current_gravity()
walking_controller.get_distance_to_spacecraft()
walking_controller.is_walking_active()
walking_controller.is_walking()

# TransitionSystem
transition_system.enable_walking_mode()
transition_system.disable_walking_mode()
transition_system.is_walking_mode_active()
transition_system.get_walking_controller()
transition_system.on_spacecraft_landed()
```

## Signals

```gdscript
# WalkingController
walking_controller.walking_started.connect(func(): print("Started"))
walking_controller.walking_stopped.connect(func(): print("Stopped"))
walking_controller.returned_to_spacecraft.connect(func(): print("Returned"))

# TransitionSystem
transition_system.walking_mode_enabled.connect(func(): print("Enabled"))
transition_system.walking_mode_disabled.connect(func(): print("Disabled"))
```

## Configuration

```gdscript
# In walking_controller.gd or scene properties
walk_speed = 2.0  # m/s
sprint_speed = 4.0  # m/s
jump_velocity = 4.0  # m/s
snap_turn_angle = 45.0  # degrees
```

## Common Patterns

### Enable walking when landed

```gdscript
func _on_spacecraft_landed():
    transition_system.on_spacecraft_landed()
    # Show UI prompt to exit spacecraft
    show_exit_prompt()

func _on_exit_button_pressed():
    transition_system.enable_walking_mode()
```

### Monitor walking state

```gdscript
func _process(delta):
    if transition_system.is_walking_mode_active():
        var controller = transition_system.get_walking_controller()
        var speed = controller.get_current_speed()
        var distance = controller.get_distance_to_spacecraft()
        update_hud(speed, distance)
```

### Custom gravity

```gdscript
# Gravity is calculated automatically from planet
# But you can override if needed
walking_controller.current_gravity = 3.7  # Mars gravity
```

## Troubleshooting

| Problem               | Solution                         |
| --------------------- | -------------------------------- |
| Falls through terrain | Check terrain collision layers   |
| Wrong gravity         | Verify planet mass/radius        |
| Controls not working  | Check VRManager initialization   |
| Can't return          | Check spacecraft position is set |

## Requirements

- VRManager initialized
- CelestialBody with mass and radius
- Spacecraft Node3D reference
- TransitionSystem initialized

## See Also

- Full Guide: `WALKING_SYSTEM_GUIDE.md`
- Tests: `tests/unit/test_walking_controller.gd`
- Scene: `scenes/player/walking_controller.tscn`
