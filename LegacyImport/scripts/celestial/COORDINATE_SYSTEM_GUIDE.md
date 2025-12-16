# Coordinate System Guide

## Overview

The `CoordinateSystem` class provides comprehensive support for multiple reference frames and coordinate transformations in Project Resonance. It enables accurate position and velocity transformations between different coordinate systems, essential for astronomical simulations.

## Requirements Addressed

- **18.1**: Support heliocentric, barycentric, and planetocentric coordinate systems
- **18.2**: Apply correct transformation matrices
- **18.3**: Format coordinates with appropriate units (km, AU, light-years)
- **18.4**: Correctly interpret coordinate system metadata
- **18.5**: Handle floating-point precision for vast distances

## Coordinate System Types

### SystemType Enum

```gdscript
enum SystemType {
    HELIOCENTRIC,      # Origin at the Sun
    BARYCENTRIC,       # Origin at the solar system barycenter
    PLANETOCENTRIC,    # Origin at a specific planet
    GALACTIC,          # Galactic coordinate system
    LOCAL              # Local coordinate system (floating origin)
}
```

### Distance Units

```gdscript
enum DistanceUnit {
    METERS,
    KILOMETERS,
    ASTRONOMICAL_UNITS,  # AU
    LIGHT_YEARS,
    PARSECS,
    GAME_UNITS           # Internal game units
}
```

## Creating Coordinate Frames

### Heliocentric Frame

Centered on the Sun, used for planetary orbital calculations:

```gdscript
var sun = get_node("Sun")  # CelestialBody
var helio_frame = CoordinateSystem.create_heliocentric_frame(sun)
```

### Planetocentric Frame

Centered on a specific planet, used for surface operations:

```gdscript
var earth = get_node("Earth")  # CelestialBody
var earth_frame = CoordinateSystem.create_planetocentric_frame(earth)
```

### Barycentric Frame

Centered at the center of mass of multiple bodies:

```gdscript
var bodies: Array[CelestialBody] = [sun, earth, mars, jupiter]
var bary_frame = CoordinateSystem.create_barycentric_frame(bodies)
```

### Local Frame

Custom frame at a specific position:

```gdscript
var local_frame = CoordinateSystem.create_local_frame(
    Vector3(1000, 500, 250),  # Position
    Basis.IDENTITY,            # Rotation
    "Spacecraft Frame"         # Name
)
```

## Coordinate Transformations

### Position Transformation

Transform a position from one frame to another:

```gdscript
# Position in heliocentric coordinates
var pos_helio = Vector3(1000, 500, 0)

# Transform to Earth-centric coordinates
var pos_earth = CoordinateSystem.transform_position(
    pos_helio,
    helio_frame,
    earth_frame
)
```

### Velocity Transformation

Transform velocity accounting for frame motion:

```gdscript
# Velocity in heliocentric frame
var vel_helio = Vector3(10, 5, 0)
var pos_helio = Vector3(1000, 500, 0)

# Transform to Earth-centric frame
var vel_earth = CoordinateSystem.transform_velocity(
    vel_helio,
    pos_helio,
    helio_frame,
    earth_frame
)
```

### State Transformation

Transform both position and velocity together:

```gdscript
var state = CoordinateSystem.transform_state(
    position,
    velocity,
    from_frame,
    to_frame
)

var new_position = state.position
var new_velocity = state.velocity
```

### Transformation Matrix

Get the transformation matrix between frames:

```gdscript
var transform = CoordinateSystem.get_transformation_matrix(
    from_frame,
    to_frame
)

# Apply to multiple points
var transformed_pos = transform * position
```

## Distance Formatting

### Format with Specific Units

```gdscript
var distance = 149597.870700  # Game units

# Format as kilometers
var km_str = CoordinateSystem.format_distance(
    distance,
    CoordinateSystem.DistanceUnit.KILOMETERS,
    2  # Precision
)
# Output: "149597870.70 km"

# Format as AU
var au_str = CoordinateSystem.format_distance(
    distance,
    CoordinateSystem.DistanceUnit.ASTRONOMICAL_UNITS,
    3
)
# Output: "1.000 AU"
```

### Automatic Unit Selection

```gdscript
# Automatically choose the best unit
var formatted = CoordinateSystem.format_distance_auto(distance, 2)
# Chooses AU for large distances, km for medium, m for small
```

### Format Position Vectors

```gdscript
var position = Vector3(1000, 500, 250)

# Format with specific units
var pos_str = CoordinateSystem.format_position(
    position,
    CoordinateSystem.DistanceUnit.KILOMETERS,
    2
)
# Output: "(1000000.00 km, 500000.00 km, 250000.00 km)"
```

### Format Velocity Vectors

```gdscript
var velocity = Vector3(10.5, 5.2, 3.1)
var vel_str = CoordinateSystem.format_velocity(velocity, 2)
# Output: "(10.50, 5.20, 3.10) units/s"
```

## Unit Conversion

### Convert Between Units

```gdscript
# Convert 1 AU to kilometers
var km = CoordinateSystem.convert_distance(
    1.0,
    CoordinateSystem.DistanceUnit.ASTRONOMICAL_UNITS,
    CoordinateSystem.DistanceUnit.KILOMETERS
)
# Result: 149597870.7 km

# Convert game units to light years
var ly = CoordinateSystem.convert_distance(
    1000000.0,
    CoordinateSystem.DistanceUnit.GAME_UNITS,
    CoordinateSystem.DistanceUnit.LIGHT_YEARS
)
```

## Barycenter Calculations

### Calculate Center of Mass

```gdscript
var bodies: Array[CelestialBody] = [sun, earth, mars]
var barycenter_pos = CoordinateSystem.calculate_barycenter(bodies)
```

### Calculate Barycentric Velocity

```gdscript
var barycenter_vel = CoordinateSystem.calculate_barycentric_velocity(bodies)
```

## Validation and Precision

### Validate Coordinate Frames

```gdscript
if CoordinateSystem.validate_frame(my_frame):
    print("Frame is valid")
else:
    print("Frame has errors")
```

### Check Frame Compatibility

```gdscript
if CoordinateSystem.are_frames_compatible(frame1, frame2):
    # Safe to transform between frames
    var pos = CoordinateSystem.transform_position(...)
```

### Floating-Point Precision

```gdscript
# Check if position is within safe precision range
if CoordinateSystem.is_position_safe(position, 1e6):
    print("Position is safe")
else:
    print("Consider rebasing coordinates")

# Calculate precision error
var error = CoordinateSystem.calculate_precision_error(position)
print("Estimated precision error: ", error)

# Get rebasing threshold
var threshold = CoordinateSystem.get_rebasing_threshold(frame)
```

## Integration with Floating Origin System

The coordinate system works seamlessly with the floating origin system:

```gdscript
# When rebasing occurs
func on_rebase(offset: Vector3) -> void:
    # Update local frame origin
    local_frame.origin_position -= offset

    # Transformations continue to work correctly
    var pos = CoordinateSystem.transform_position(...)
```

## Property 14: Round-Trip Transformation

The coordinate system guarantees that transforming from frame A to frame B and back to frame A preserves the original position within tolerance:

```gdscript
# Original position in heliocentric frame
var original = Vector3(1000, 500, 250)

# Transform to planetocentric and back
var in_planet = CoordinateSystem.transform_position(
    original, helio_frame, planet_frame
)
var back_to_helio = CoordinateSystem.transform_position(
    in_planet, planet_frame, helio_frame
)

# Should match within 0.1 units
assert((back_to_helio - original).length() < 0.1)
```

## Common Use Cases

### Spacecraft Navigation

```gdscript
# Get spacecraft position in heliocentric coordinates
var spacecraft_pos_helio = spacecraft.global_position

# Transform to target planet's frame for landing
var spacecraft_pos_planet = CoordinateSystem.transform_position(
    spacecraft_pos_helio,
    helio_frame,
    target_planet_frame
)

# Calculate altitude above surface
var altitude = spacecraft_pos_planet.length() - target_planet.radius
```

### Orbital Mechanics

```gdscript
# Calculate orbit in heliocentric frame
var orbit_elements = orbit_calculator.elements_from_state_vectors(
    position_helio,
    velocity_helio,
    sun.mass * CelestialBody.G,
    current_time
)

# Transform to planetocentric for SOI calculations
var position_planet = CoordinateSystem.transform_position(
    position_helio,
    helio_frame,
    planet_frame
)

if planet.is_point_in_soi(position_planet):
    print("Entered planet's sphere of influence")
```

### HUD Display

```gdscript
# Display position in appropriate units
func update_position_display() -> void:
    var pos = spacecraft.global_position

    # Format for display
    var pos_str = CoordinateSystem.format_position(
        pos,
        CoordinateSystem.DistanceUnit.ASTRONOMICAL_UNITS,
        3
    )

    position_label.text = "Position: " + pos_str
```

## Performance Considerations

1. **Frame Caching**: Create frames once and reuse them
2. **Batch Transformations**: Use transformation matrices for multiple points
3. **Precision Monitoring**: Check precision errors for very large distances
4. **Coordinate Rebasing**: Use with floating origin system for vast distances

## Error Handling

The coordinate system includes comprehensive error handling:

- Invalid frames return identity transformations
- Division by zero is prevented with epsilon values
- Warnings are logged for invalid configurations
- Validation functions help catch errors early

## Testing

Run the unit tests to verify coordinate system functionality:

```bash
# Run coordinate system tests
godot --headless --script tests/unit/test_coordinate_system.gd
```

Tests cover:

- Frame creation for all system types
- Position and velocity transformations
- Round-trip transformation accuracy
- Unit conversion and formatting
- Barycenter calculations
- Precision handling

## References

- Requirements: 18.1, 18.2, 18.3, 18.4, 18.5
- Property 14: Coordinate System Round Trip
- Related: `CelestialBody`, `OrbitCalculator`, `FloatingOriginSystem`
