# Orbital Mechanics Implementation

## Overview

The `OrbitalMechanics` class provides a high-level API for spacecraft orbital calculations in the SpaceTime VR project. It wraps the lower-level `OrbitCalculator` class and provides spacecraft-specific functionality for calculating orbits, predicting trajectories, and planning maneuvers.

## File Location

- **Implementation**: `C:/godot/scripts/celestial/orbital_mechanics.gd`
- **Example Usage**: `C:/godot/examples/orbital_mechanics_example.gd`
- **Dependencies**:
  - `OrbitCalculator` (`scripts/celestial/orbit_calculator.gd`)
  - `CelestialBody` (`scripts/celestial/celestial_body.gd`)

## Core Methods

### 1. Calculate Orbit (`calculate_orbit`)

**Purpose**: Convert spacecraft position and velocity into orbital elements.

**Input**:
- `spacecraft_position`: Vector3 - Current position of spacecraft
- `spacecraft_velocity`: Vector3 - Current velocity of spacecraft
- `central_body`: CelestialBody - The body being orbited

**Output**: `OrbitalElements` structure containing:
- `semi_major_axis`: Average orbital radius (defines orbit size)
- `eccentricity`: Orbital shape (0=circular, <1=elliptical, 1=parabolic, >1=hyperbolic)
- `inclination`: Angle from reference plane (radians)
- `longitude_ascending_node`: Where orbit crosses reference plane (radians)
- `argument_of_periapsis`: Direction to closest approach (radians)
- `mean_anomaly_at_epoch`: Current position in orbit (radians)

**Key Formula**: State vector to orbital elements conversion
```
μ = G * M  (standard gravitational parameter)
r = spacecraft_position - central_body.position
v = spacecraft_velocity

h = r × v  (angular momentum)
e = (v × h)/μ - r/|r|  (eccentricity vector)
ε = v²/2 - μ/r  (specific energy)
a = -μ/(2ε)  (semi-major axis)
```

**Usage Example**:
```gdscript
var orbital_calc = OrbitalMechanics.new()
var elements = orbital_calc.calculate_orbit(
    spacecraft.global_position,
    spacecraft.linear_velocity,
    earth
)
print("Orbit eccentricity: ", elements.eccentricity)
```

### 2. Predict Position (`predict_position`)

**Purpose**: Calculate future spacecraft position and velocity from orbital elements.

**Input**:
- `elements`: OrbitalElements - Orbital parameters
- `time_offset`: float - Time delta from epoch (can be negative for past)

**Output**: `StateVector` containing:
- `position`: Vector3 - Predicted position
- `velocity`: Vector3 - Predicted velocity
- `time`: float - Time of prediction

**Key Formula**: Kepler's equation and coordinate transformation
```
M = M₀ + n·Δt  (mean anomaly at time t)
M = E - e·sin(E)  (Kepler's equation, solve for E)
ν = 2·atan(√((1+e)/(1-e))·tan(E/2))  (true anomaly)
r = a(1-e²)/(1+e·cos(ν))  (orbital radius)
```

**Usage Example**:
```gdscript
# Predict position 10 seconds in the future
var future_state = orbital_calc.predict_position(elements, 10.0)
print("Future position: ", future_state.position)
print("Future velocity: ", future_state.velocity)
```

### 3. Escape Velocity (`escape_velocity`)

**Purpose**: Calculate minimum velocity needed to escape from a celestial body.

**Input**:
- `spacecraft_position`: Vector3 - Current spacecraft position
- `central_body`: CelestialBody - Body to escape from

**Output**: float - Minimum escape velocity (scalar)

**Key Formula**: Energy conservation at escape
```
v_escape = √(2μ/r)

where:
  μ = G·M (gravitational parameter)
  r = distance from body center

Derivation:
  At escape: KE + PE = 0
  (1/2)mv² - GMm/r = 0
  v = √(2GM/r)
```

**Usage Example**:
```gdscript
var v_esc = orbital_calc.escape_velocity(
    spacecraft.global_position,
    planet
)
var current_speed = spacecraft.linear_velocity.length()
print("Need %.1f more m/s to escape" % (v_esc - current_speed))
```

### 4. Orbital Period (`orbital_period`)

**Purpose**: Calculate the time for one complete orbit.

**Input**:
- `elements`: OrbitalElements - Orbital parameters

**Output**: float - Period in seconds (INF for unbound orbits)

**Key Formula**: Kepler's third law
```
T = 2π√(a³/μ)

where:
  a = semi-major axis
  μ = G·M

This shows T² ∝ a³ for all orbits around the same body
```

**Usage Example**:
```gdscript
var period = orbital_calc.orbital_period(elements)
print("One orbit takes %.1f minutes" % (period / 60.0))
```

## Additional Features

### Trajectory Prediction

**Method**: `predict_trajectory(position, velocity, body, duration, steps)`

Calculates multiple future positions along the orbital path.

```gdscript
# Get 100 points over next orbit
var trajectory = orbital_calc.predict_trajectory(
    spacecraft.global_position,
    spacecraft.linear_velocity,
    earth,
    orbital_calc.orbital_period(elements),
    100
)

# Draw trajectory line
for i in range(trajectory.size() - 1):
    draw_line(trajectory[i], trajectory[i+1])
```

### Orbital Properties

Additional calculations available:

- `calculate_periapsis_distance()` - Closest approach distance
- `calculate_apoapsis_distance()` - Farthest point distance
- `calculate_periapsis_velocity()` - Speed at periapsis
- `calculate_apoapsis_velocity()` - Speed at apoapsis
- `calculate_specific_energy()` - Total orbital energy per unit mass
- `calculate_circular_orbit_velocity()` - Speed for circular orbit at current radius
- `is_escape_trajectory()` - Check if orbit is unbound
- `will_collide()` - Check if orbit intersects body surface

### Delta-V Calculations

**Hohmann Transfer**: Most efficient two-burn orbit change

```gdscript
var hohmann = orbital_calc.calculate_hohmann_transfer_dv(
    current_radius,
    target_radius,
    mu
)
print("First burn: ", hohmann.departure_dv, " m/s")
print("Second burn: ", hohmann.arrival_dv, " m/s")
print("Total: ", hohmann.total_dv, " m/s")
print("Transfer time: ", hohmann.transfer_time, " seconds")
```

**Circularization**: Convert elliptical orbit to circular

```gdscript
var circ_dv = orbital_calc.calculate_circularization_dv(
    spacecraft.global_position,
    spacecraft.linear_velocity,
    planet
)
print("Need ", circ_dv, " m/s to circularize")
```

### Timing Calculations

- `time_to_periapsis()` - Seconds until closest approach
- `time_to_apoapsis()` - Seconds until farthest point

### Comprehensive Info

Get all orbital parameters at once:

```gdscript
var info = orbital_calc.get_orbital_info(elements)
# Returns dictionary with:
#   - All orbital elements
#   - Periapsis/apoapsis distances and velocities
#   - Period
#   - Specific energy
#   - Orbit type (elliptical, parabolic, hyperbolic)
```

## Key Formulas Reference

### Fundamental Equations

1. **Vis-viva equation** (velocity at any point in orbit):
   ```
   v² = μ(2/r - 1/a)
   ```

2. **Orbital energy** (conserved quantity):
   ```
   ε = v²/2 - μ/r = -μ/(2a)
   ```

3. **Angular momentum** (conserved vector):
   ```
   h = r × v  (magnitude: h = √(μ·a·(1-e²)))
   ```

4. **Kepler's equation** (position in orbit over time):
   ```
   M = E - e·sin(E)
   M = n·(t - t₀)  where n = √(μ/a³)
   ```

5. **Orbital radius** (distance as function of angle):
   ```
   r = a(1-e²)/(1+e·cos(ν))
   ```

### Orbit Types by Eccentricity

- **e = 0**: Circular orbit
- **0 < e < 1**: Elliptical orbit (bound)
- **e = 1**: Parabolic trajectory (escape)
- **e > 1**: Hyperbolic trajectory (escape)

### Special Orbits

- **Circular orbit velocity**: v = √(μ/r)
- **Escape velocity**: v = √(2μ/r) = √2 × v_circular
- **Periapsis distance**: r_p = a(1 - e)
- **Apoapsis distance**: r_a = a(1 + e)

## Integration with Spacecraft

### Basic Usage Pattern

```gdscript
extends Spacecraft

var orbital_calc: OrbitalMechanics
var current_orbit: OrbitCalculator.OrbitalElements
var orbiting_body: CelestialBody

func _ready():
    orbital_calc = OrbitalMechanics.new()
    orbiting_body = find_nearest_body()

func _physics_process(delta):
    # Update orbital elements each frame
    current_orbit = orbital_calc.calculate_orbit(
        global_position,
        linear_velocity,
        orbiting_body
    )

    # Display orbital info to player
    update_hud()

func update_hud():
    var period = orbital_calc.orbital_period(current_orbit)
    var v_esc = orbital_calc.escape_velocity(global_position, orbiting_body)

    hud.set_text("Orbital Period: %.1f s" % period)
    hud.set_text("Escape Velocity: %.1f m/s" % v_esc)
    hud.set_text("Eccentricity: %.3f" % current_orbit.eccentricity)
```

### Maneuver Planning

```gdscript
func plan_orbit_raise():
    # Calculate current orbit
    var elements = orbital_calc.calculate_orbit(
        global_position,
        linear_velocity,
        orbiting_body
    )

    # Get current altitude
    var current_radius = (global_position - orbiting_body.global_position).length()
    var target_radius = current_radius * 1.5  # 50% higher orbit

    # Calculate Hohmann transfer
    var mu = OrbitalMechanics.G * orbiting_body.mass
    var transfer = orbital_calc.calculate_hohmann_transfer_dv(
        current_radius,
        target_radius,
        mu
    )

    # Show to player
    print("Orbit raise maneuver:")
    print("  Burn 1: %.1f m/s" % transfer.departure_dv)
    print("  Wait: %.1f seconds" % transfer.transfer_time)
    print("  Burn 2: %.1f m/s" % transfer.arrival_dv)
    print("  Total cost: %.1f m/s" % transfer.total_dv)
```

### Trajectory Visualization

```gdscript
func draw_orbital_path():
    var elements = orbital_calc.calculate_orbit(
        global_position,
        linear_velocity,
        orbiting_body
    )

    var period = orbital_calc.orbital_period(elements)
    var trajectory = orbital_calc.predict_trajectory(
        global_position,
        linear_velocity,
        orbiting_body,
        period,
        64  # 64 points for smooth line
    )

    # Draw with ImmediateMesh or Line3D
    for i in range(trajectory.size()):
        var next_i = (i + 1) % trajectory.size()
        draw_line_3d(trajectory[i], trajectory[next_i], Color.CYAN)
```

## Performance Considerations

- Orbital element calculations are relatively expensive (involves solving Kepler's equation)
- Cache orbital elements and update only when needed (e.g., after maneuvers)
- Use `predict_trajectory()` with reasonable step counts (16-64 for visualization)
- Energy conservation check is fast and useful for validation

## Energy Conservation

The implementation maintains energy conservation within 0.01% error tolerance (Requirement 14.4):

```gdscript
# Verify energy is conserved over one orbit
var state1 = OrbitCalculator.StateVector.new(pos1, vel1, t1)
var state2 = OrbitCalculator.StateVector.new(pos2, vel2, t2)
var mu = OrbitalMechanics.G * body.mass

var error = orbital_calc.verify_energy_conservation(state1, state2, mu)
assert(error < 0.0001, "Energy not conserved within tolerance")
```

## Testing

Run the example to verify implementation:

```bash
# From Godot editor
# Open examples/orbital_mechanics_example.gd in script editor
# Attach to a test scene node and run

# Or load via autoload for testing
```

Expected output shows:
- Orbital element calculations
- Position predictions
- Escape velocity calculations
- Trajectory predictions
- Hohmann transfer delta-v
- Energy conservation validation

## References

### Mathematical Background

- Kepler's laws of planetary motion
- Two-body problem solution
- Orbital mechanics fundamentals
- Vis-viva equation derivation

### Related Files

- `orbit_calculator.gd` - Low-level Keplerian orbital calculations
- `celestial_body.gd` - Celestial body properties and gravity
- `spacecraft.gd` - Spacecraft physics and controls
- `physics_engine.gd` - N-body gravitational simulation

### Requirements Met

- **6.4**: Time dilation support for celestial mechanics
- **7.1-7.5**: Relativistic effects integration
- **9.1**: Newton's law of gravitation (F = G·m₁·m₂/r²)
- **14.4**: Energy conservation within 0.01% tolerance

## Future Enhancements

Possible additions:

1. **Orbital maneuvers**:
   - Plane change calculations
   - Bi-elliptic transfers
   - Low-thrust trajectories

2. **Advanced mechanics**:
   - Perturbations (J2, atmospheric drag)
   - Three-body problem (Lagrange points)
   - Gravitational assists

3. **Navigation**:
   - Lambert's problem (intercept trajectories)
   - Rendezvous planning
   - Transfer windows

4. **Optimization**:
   - Optimal maneuver timing
   - Fuel-optimal transfers
   - Time-optimal transfers
