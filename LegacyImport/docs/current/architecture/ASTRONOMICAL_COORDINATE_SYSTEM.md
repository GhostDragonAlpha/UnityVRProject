# Astronomical Coordinate System Architecture

**Status:** In Development
**Date:** 2025-12-09
**Version:** 1.0

---

## Problem Statement

Godot's coordinate system uses 32-bit floats for positions, which breaks down beyond ~16,000 units from origin due to floating-point precision loss. We need to represent:
- Planetary surfaces (meters)
- Solar systems (AU - Astronomical Units, 1 AU = 149,597,870,700 meters)
- Interstellar space (light-years, 1 ly = 9.46 trillion meters)

**Current Issue:** Objects exceed Godot's coordinate limits, causing "Object went too far away" errors.

**Solution:** Multi-layered coordinate system where player stays at origin and universe translates around them.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│ AstronomicalCoordinateSystem (Autoload)                 │
│ - Manages universe-scale coordinate tracking             │
│ - Converts between local/AU/light-year coordinates       │
│ - Integrates with FloatingOriginSystem                   │
│ - Tracks all celestial objects                           │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Layer 1: Local Space (meters)                           │
│ - Range: ±5,000 meters from origin                      │
│ - Player always at/near (0,0,0)                          │
│ - Full physics simulation                                │
│ - FloatingOriginSystem shifts when player > threshold   │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Layer 2: System Space (AU)                              │
│ - Range: ±1,000 AU                                       │
│ - Planets, moons, asteroids                              │
│ - Simplified physics (orbital calculations)              │
│ - Only nearby objects instantiated in Layer 1            │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Layer 3: Galactic Space (light-years)                   │
│ - Range: unlimited                                       │
│ - Stars, nebulae, galaxies                               │
│ - No physics, pure visual (skybox/billboards)           │
│ - Procedural generation on demand                        │
└──────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### 1. Astronomical Position (AstroPos)

Every object in the universe has an **AstronomicalPosition**:

```gdscript
class_name AstroPos
extends RefCounted

## Coordinates in different scales
var local_meters: Vector3 = Vector3.ZERO    # Local space position (±5km)
var system_au: Vector3 = Vector3.ZERO       # System position in AU
var galactic_ly: Vector3 = Vector3.ZERO     # Galactic position in light-years

## Which coordinate system is authoritative
enum CoordSystem { LOCAL, SYSTEM, GALACTIC }
var authoritative: CoordSystem = CoordSystem.LOCAL

## Parent object (for orbital mechanics)
var parent_astro_id: int = -1
```

### 2. The Player is Always at Origin

**Player never moves in astronomical coordinates**. Instead:
- Player moves in local space (±5,000m)
- When player exceeds threshold, FloatingOriginSystem shifts universe
- AstronomicalCoordinateSystem updates all astronomical positions

### 3. Coordinate Conversion

```gdscript
# Constants
const METERS_PER_AU := 149_597_870_700.0
const METERS_PER_LY := 9.461e15
const AU_PER_LY := 63_241.0

# Convert AU to local meters (for rendering nearby objects)
func au_to_local(au_pos: Vector3, player_au: Vector3) -> Vector3:
    var relative_au = au_pos - player_au
    return relative_au * METERS_PER_AU

# Convert local meters to AU (for astronomical tracking)
func local_to_au(local_pos: Vector3, player_au: Vector3) -> Vector3:
    return player_au + (local_pos / METERS_PER_AU)
```

### 4. Object Registration & Tracking

```gdscript
# Register celestial object
func register_object(node: Node3D, astro_pos: AstroPos) -> int:
    var astro_id = _next_id
    _next_id += 1

    _objects[astro_id] = {
        "node": node,
        "astro_pos": astro_pos,
        "layer": _determine_layer(astro_pos)
    }

    return astro_id

# Update object's astronomical position
func update_position(astro_id: int, new_pos: AstroPos) -> void:
    if not _objects.has(astro_id):
        return

    _objects[astro_id].astro_pos = new_pos
    _recalculate_local_position(astro_id)
```

### 5. Integration with FloatingOriginSystem

```gdscript
# Called by FloatingOriginSystem when universe shifts
func on_universe_shift(shift_offset: Vector3) -> void:
    # Update player's astronomical position
    _player_astro_pos.local_meters -= shift_offset

    # Convert local shift to AU shift
    var au_shift = shift_offset / METERS_PER_AU
    _player_astro_pos.system_au += au_shift

    # Update all tracked objects
    for astro_id in _objects:
        _recalculate_local_position(astro_id)
```

---

## Layer Determination & LOD

### Layer 1: Local Space (Full Detail)

**Criteria:** Distance from player < 5,000 meters in local space

**Rendering:**
- Full 3D mesh with LOD
- Full physics simulation (RigidBody3D/CharacterBody3D)
- Collision detection enabled
- Atmospheric scattering
- Surface detail (voxel terrain, etc.)

**Objects:**
- Player ship
- Nearby asteroids
- Planet surface (when landed)
- Space stations
- Other ships

### Layer 2: System Space (Simplified)

**Criteria:** Distance from player 5km - 1000 AU

**Rendering:**
- Simplified mesh or impostor
- Simplified physics (orbital mechanics only)
- No collision detection
- Atmospheric glow (shader-based)
- No surface detail

**Objects:**
- Planets in current system
- Moons
- Large asteroids
- Stars (local)

### Layer 3: Galactic Space (Visual Only)

**Criteria:** Distance from player > 1000 AU

**Rendering:**
- Billboard sprites or skybox
- No physics
- No collision
- Point light sources
- Procedural noise for nebulae

**Objects:**
- Distant stars
- Nebulae
- Galaxies
- Background sky

---

## API Reference

### AstronomicalCoordinateSystem (Autoload)

```gdscript
# Player tracking
func set_player(player_node: Node3D) -> void
func get_player_position() -> AstroPos

# Object registration
func register_object(node: Node3D, astro_pos: AstroPos) -> int
func unregister_object(astro_id: int) -> void
func update_position(astro_id: int, new_pos: AstroPos) -> void

# Coordinate conversion
func au_to_local(au_pos: Vector3) -> Vector3
func local_to_au(local_pos: Vector3) -> Vector3
func ly_to_au(ly_pos: Vector3) -> Vector3
func au_to_ly(au_pos: Vector3) -> Vector3

# Distance queries
func get_distance_au(astro_id_a: int, astro_id_b: int) -> float
func get_distance_ly(astro_id_a: int, astro_id_b: int) -> float

# Layer management
func get_objects_in_layer(layer: int) -> Array[int]
func force_update_layers() -> void

# Integration
func on_universe_shift(shift_offset: Vector3) -> void  # Called by FloatingOriginSystem

# Debug
func print_status() -> void
func get_stats() -> Dictionary
```

---

## Implementation Plan

### Phase 1: Core System (Week 1)
1. Create `AstroPos` class (scripts/core/astro_pos.gd)
2. Create `AstronomicalCoordinateSystem` autoload (scripts/core/astronomical_coordinate_system.gd)
3. Implement coordinate conversion functions
4. Implement object registration/tracking
5. Add to engine.gd initialization (Phase 1 - before FloatingOriginSystem)

### Phase 2: Integration (Week 1)
1. Connect to FloatingOriginSystem
2. Update FloatingOriginSystem to call on_universe_shift()
3. Test with floating_origin_test.gd
4. Verify coordinate conversions

### Phase 3: Layer System (Week 2)
1. Implement layer determination logic
2. Implement LOD switching
3. Create visual impostors for distant objects
4. Test with multiple objects at different scales

### Phase 4: Celestial Objects (Week 2-3)
1. Update PlanetGenerator to use AstroPos
2. Update StarCatalog to use AstroPos
3. Create procedural asteroid belts
4. Test full solar system

---

## Testing Strategy

### Unit Tests (GdUnit4)

```gdscript
# test_astronomical_coordinate_system.gd
func test_au_to_local_conversion():
    var player_au = Vector3(1.0, 0, 0)  # 1 AU from star
    var object_au = Vector3(1.5, 0, 0)  # 1.5 AU from star

    var local_pos = AstroCoords.au_to_local(object_au, player_au)

    # Should be 0.5 AU away = ~75 million km in local space
    # But we'll never render this - would use impostor
    assert_almost_equal(local_pos.x, 0.5 * METERS_PER_AU, 1000.0)

func test_universe_shift():
    # Register object 1000m away
    var obj_pos = AstroPos.new()
    obj_pos.local_meters = Vector3(1000, 0, 0)

    var id = AstroCoords.register_object(some_node, obj_pos)

    # Simulate universe shift
    AstroCoords.on_universe_shift(Vector3(500, 0, 0))

    # Object should now be 500m away in local space
    var updated = AstroCoords.get_position(id)
    assert_eq(updated.local_meters.x, 500.0)
```

### Integration Tests

1. **Planetary Landing Test** - Player transitions from space (AU scale) to surface (meter scale)
2. **Interstellar Travel Test** - Player travels light-years, verify star positions update
3. **Orbital Mechanics Test** - Planets orbit star while player moves

---

## Performance Considerations

### Memory Budget
- Store only astronomical positions for distant objects (48 bytes per object)
- Instantiate full nodes only for nearby objects
- Use object pooling for frequent instantiation/destruction

### CPU Budget
- Update layers once per second, not every frame
- Use spatial partitioning (octree) for layer queries
- Defer distant object updates to background threads

### Precision Maintenance
- Use double precision for astronomical coordinates (AU/light-years)
- Use single precision for local coordinates (meters)
- Periodically re-normalize coordinates to prevent drift

---

## Compatibility Notes

### Works With:
- FloatingOriginSystem (primary integration point)
- GravityManager (uses local coordinates)
- VoxelTerrain (uses local coordinates)
- PhysicsEngine (uses local coordinates)

### Requires Changes To:
- PlanetGenerator - Must register planets with AstroPos
- StarCatalog - Must use galactic coordinates
- Spacecraft - Must track position in both local and AU

---

## Example Usage

### Creating a Planet

```gdscript
# Create planet node
var planet = Planet.new()
planet.radius = 6371000.0  # Earth radius in meters

# Create astronomical position
var astro_pos = AstroPos.new()
astro_pos.system_au = Vector3(1.0, 0, 0)  # 1 AU from star
astro_pos.authoritative = AstroPos.CoordSystem.SYSTEM

# Register with coordinate system
var planet_id = AstronomicalCoordinateSystem.register_object(planet, astro_pos)

# Coordinate system will:
# 1. Calculate distance from player
# 2. Determine appropriate layer
# 3. Update local position if in Layer 1
# 4. Create impostor if in Layer 2/3
```

### Player Movement

```gdscript
# In player controller
func _physics_process(delta):
    # Move in local space normally
    velocity += thrust * delta
    move_and_slide()

    # FloatingOriginSystem automatically shifts universe when needed
    # AstronomicalCoordinateSystem automatically updates positions

    # Query astronomical position (for UI/navigation)
    var my_astro_pos = AstronomicalCoordinateSystem.get_player_position()
    print("Position: %.2f AU from star" % my_astro_pos.system_au.length())
```

---

## Future Enhancements

1. **Relativistic Effects** - Time dilation at high speeds
2. **N-Body Physics** - Gravitational interactions between bodies
3. **Procedural Galaxy** - Generate stars/systems on-demand
4. **Wormholes** - Instant coordinate system transitions
5. **Binary Star Systems** - Multiple coordinate origins

---

**Status:** Design Complete - Ready for Implementation
**Next Step:** Implement AstroPos class and AstronomicalCoordinateSystem autoload
