# HazardSystem Guide

## Overview

The HazardSystem manages environmental hazards and challenges in Project Resonance, including asteroid fields, black holes, and nebulae. It provides hazard generation, tracking, warning systems, and damage calculation.

## Quick Start

```gdscript
# Add to your scene
var hazard_system = HazardSystem.new()
add_child(hazard_system)

# Set player reference for tracking
hazard_system.set_player(player_node)

# Connect to signals
hazard_system.hazard_warning.connect(_on_hazard_warning)
hazard_system.hazard_entered.connect(_on_hazard_entered)
hazard_system.hazard_damage_applied.connect(_on_hazard_damage)
```

## Hazard Types

### Asteroid Fields

Dense regions of space debris that require careful navigation.

```gdscript
var hazard_id = hazard_system.generate_asteroid_field(
    Vector3(1000, 0, 0),  # Center position
    500.0,                 # Radius
    0.1                    # Density (asteroids per cubic unit)
)
```

**Properties:**

- Uses MultiMeshInstance3D for efficient rendering
- Deterministic generation based on position
- Collision damage based on density
- Severity: LOW to EXTREME based on density

### Black Holes

Extreme gravitational hazards with event horizons.

```gdscript
var hazard_id = hazard_system.create_black_hole(
    Vector3(5000, 0, 0),  # Position
    10000.0,               # Mass
    100.0                  # Event horizon radius
)
```

**Properties:**

- 100x gravity multiplier
- Instant death inside event horizon
- Distance-based damage outside event horizon
- Visual accretion disk
- Severity: Always EXTREME

### Nebulae

Cloudy regions that reduce visibility and increase signal noise.

```gdscript
var hazard_id = hazard_system.create_nebula(
    Vector3(3000, 0, 0),           # Center position
    800.0,                          # Radius
    Color(0.5, 0.2, 0.8, 0.5)      # Fog color (optional)
)
```

**Properties:**

- 70% visibility reduction
- 2x signal noise multiplier
- Volumetric fog effects
- Particle system atmosphere
- Severity: Based on radius

## Signals

### hazard_warning(hazard_type: String, distance: float, severity: float)

Emitted when player approaches a hazard (within 3x hazard radius).

```gdscript
func _on_hazard_warning(hazard_type: String, distance: float, severity: float):
    if severity > 0.8:
        show_critical_warning(hazard_type)
    elif severity > 0.5:
        show_warning(hazard_type)
```

### hazard_entered(hazard_type: String, hazard_data: Dictionary)

Emitted when player enters a hazard zone.

```gdscript
func _on_hazard_entered(hazard_type: String, hazard_data: Dictionary):
    print("Entered ", hazard_type)
    apply_hazard_effects(hazard_data)
```

### hazard_exited(hazard_type: String)

Emitted when player exits a hazard zone.

```gdscript
func _on_hazard_exited(hazard_type: String):
    print("Exited ", hazard_type)
    remove_hazard_effects()
```

### hazard_damage_applied(damage_amount: float, hazard_type: String)

Emitted when hazard deals damage to player (every 0.5 seconds).

```gdscript
func _on_hazard_damage(damage: float, hazard_type: String):
    player_health -= damage
    show_damage_effect()
```

## Hazard Management

### Removing Hazards

```gdscript
hazard_system.remove_hazard(hazard_id)
```

### Querying Hazards

```gdscript
# Check if position is in a hazard
var hazard_data = hazard_system.get_hazard_at_position(position)
if not hazard_data.is_empty():
    print("Position is in hazard: ", hazard_data["type"])

# Get all hazards of a type
var black_holes = hazard_system.get_hazards_by_type(HazardSystem.HazardType.BLACK_HOLE)

# Get hazard by ID
var data = hazard_system.get_hazard_data(hazard_id)

# Check if hazard exists
if hazard_system.has_hazard(hazard_id):
    print("Hazard exists")
```

### Clearing All Hazards

```gdscript
hazard_system.clear_all_hazards()
```

## Getting Hazard Effects

Get combined effects at any position for integration with other systems:

```gdscript
var effects = hazard_system.get_hazard_effects_at_position(player_position)

# Apply to rendering system
if effects["visibility_multiplier"] < 1.0:
    set_fog_density(1.0 - effects["visibility_multiplier"])

# Apply to signal manager
if effects["signal_noise_multiplier"] > 1.0:
    signal_manager.add_noise(effects["signal_noise_multiplier"])

# Apply to physics
if effects["gravity_multiplier"] > 1.0:
    apply_extra_gravity(effects["gravity_multiplier"])

# Check damage rate
if effects["damage_rate"] > 0:
    print("Taking ", effects["damage_rate"], " damage per check")
```

## Save/Load Support

```gdscript
# Save
var save_data = hazard_system.serialize()
save_file.store_var(save_data)

# Load
var save_data = save_file.get_var()
hazard_system.deserialize(save_data)
```

## Configuration Constants

You can modify these in the HazardSystem class:

```gdscript
const ASTEROID_FIELD_DENSITY: float = 0.1
const ASTEROID_MIN_SIZE: float = 1.0
const ASTEROID_MAX_SIZE: float = 50.0
const ASTEROID_COLLISION_DAMAGE: float = 10.0

const BLACK_HOLE_GRAVITY_MULTIPLIER: float = 100.0
const BLACK_HOLE_EVENT_HORIZON_DAMAGE: float = 100.0
const BLACK_HOLE_DISTORTION_RADIUS: float = 5000.0

const NEBULA_VISIBILITY_REDUCTION: float = 0.7
const NEBULA_SIGNAL_NOISE_MULTIPLIER: float = 2.0
const NEBULA_FOG_DENSITY: float = 0.5

const WARNING_DISTANCE_MULTIPLIER: float = 3.0
const DAMAGE_CHECK_INTERVAL: float = 0.5
```

## Integration Examples

### With SignalManager

```gdscript
func _process(delta):
    var effects = hazard_system.get_hazard_effects_at_position(player.position)
    signal_manager.noise_multiplier = effects["signal_noise_multiplier"]
```

### With PhysicsEngine

```gdscript
func calculate_gravity(position: Vector3) -> Vector3:
    var base_gravity = celestial_body.calculate_gravity_at_point(position)
    var effects = hazard_system.get_hazard_effects_at_position(position)
    return base_gravity * effects["gravity_multiplier"]
```

### With Rendering System

```gdscript
func update_fog():
    var effects = hazard_system.get_hazard_effects_at_position(camera.position)
    environment.fog_density = base_fog * (1.0 - effects["visibility_multiplier"])
```

## Performance Tips

1. **Asteroid Limits**: Asteroid fields are capped at 1000 instances for VR performance
2. **Damage Checks**: Damage is calculated every 0.5 seconds, not every frame
3. **Warning Updates**: Warnings update every frame but use minimal calculations
4. **MultiMesh**: Asteroid fields use MultiMeshInstance3D for efficient rendering
5. **Deterministic Generation**: Asteroids are generated deterministically to avoid storing large datasets

## Best Practices

1. **Player Reference**: Always set the player reference for automatic tracking
2. **Signal Connections**: Connect to signals early for proper warning/damage handling
3. **Effect Integration**: Use `get_hazard_effects_at_position()` for system integration
4. **Hazard Cleanup**: Remove hazards when no longer needed to free resources
5. **Save Support**: Include hazard state in save files for persistence

## Troubleshooting

**Warnings not appearing:**

- Ensure player reference is set: `hazard_system.set_player(player_node)`
- Check player is in "player" group or set manually
- Verify signal connections

**Damage not applying:**

- Connect to `hazard_damage_applied` signal
- Check player is actually inside hazard zone
- Verify damage check interval (0.5 seconds)

**Visual issues:**

- Ensure hazard nodes are added to scene tree
- Check material transparency settings
- Verify particle systems are emitting

**Performance issues:**

- Reduce asteroid field density
- Limit number of active hazards
- Use LOD for distant hazards
- Check MultiMesh instance counts
