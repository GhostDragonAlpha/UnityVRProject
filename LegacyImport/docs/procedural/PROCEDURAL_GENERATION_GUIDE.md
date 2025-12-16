# Procedural Generation Systems - Architecture Guide

## Overview

The SpaceTime project implements a comprehensive three-tier procedural generation system designed for infinite, deterministic universe generation. The system enables seamless exploration of a procedurally generated galaxy with realistic physics-based celestial mechanics and detailed planetary terrain.

### System Architecture Tiers

```
Tier 1: Universe Generation
├── Star System Generation (UniverseGenerator)
├── Planetary System Creation
└── Filament Network Creation

    ↓

Tier 2: Planet Generation
├── Heightmap Generation (PlanetGenerator)
├── Terrain Mesh Creation (LOD-based)
├── Normal Map Generation
└── Surface Detail Placement

    ↓

Tier 3: Environmental Systems
├── Biome Assignment (BiomeSystem)
├── Biome Blending & Transitions
├── Environmental Effects
└── Habitability Calculation
```

## Core Design Principles

### 1. Deterministic Generation

All generation is **fully deterministic** - given the same seed and coordinates, the system always produces identical results. This enables:

- **Infinite universe**: No need to pre-generate or store content
- **Seamless exploration**: Players can travel anywhere in the 3D space
- **Reproducibility**: Same universe can be recreated with same seed
- **Network efficiency**: Players can synchronize positions without downloading data

**Implementation**: All systems use seeded pseudo-random number generation and hash-based functions that depend only on input coordinates, never on generation order or timing.

### 2. Hierarchical Spatial Organization

Generation works at multiple scales:

- **Sector Level** (1000m): Groups star systems; 30% contain active stars
- **System Level**: Multiple planets orbit each star
- **Planet Level**: Regional terrain generation with LOD support
- **Local Level**: Surface details (rocks, vegetation, effects)

### 3. Physics-Based Generation

Rather than arbitrary parameters, systems use real astronomical/physical principles:

- **Stellar Classification**: Uses real Hertzsprung-Russell diagram distributions
- **Orbital Mechanics**: Titius-Bode-like planetary distributions
- **Temperature Zones**: Inverse-square law for stellar radiation
- **Biome Assignment**: Based on temperature, moisture, and altitude

### 4. Level-of-Detail (LOD) Management

Resources are allocated based on distance:

- **ULTRA** (256x256): Walking distance terrain detail
- **HIGH** (128x128): Close planetary approach
- **MEDIUM** (64x64): Orbital view
- **LOW** (32x32): Distant observation
- **MINIMAL** (16x16): Navigation view

## System Integration Flow

```
Player Position in Universe
           ↓
UniverseGenerator.get_sector_for_position(world_pos)
           ↓
get_nearby_systems(world_pos, radius_sectors=1)
           ↓
[For each nearby system with planets]
           ↓
PlanetGenerator.generate_planet_terrain(planet_seed, lod_level)
           ↓
BiomeSystem.generate_biome_map(planet_seed, heightmap)
           ↓
Final terrain rendering with effects
```

## Performance Characteristics

### Memory Efficiency

| Resource | Size | Cache Size | Notes |
|----------|------|-----------|-------|
| Star System | ~1KB | 1000 entries | Cached by sector coordinates |
| Heightmap (256x256) | ~264KB | 10 entries | Per planet, variable LOD |
| Biome Map (256x256) | ~192KB | 5 entries | Derived from heightmap |
| Terrain Mesh (256x256) | ~7.5MB | 1-3 meshes | GPU memory, LOD-based |

### Generation Time (Approximate)

| Operation | Time | Conditions |
|-----------|------|-----------|
| Star system generation | <1ms | Per sector, cached |
| Heightmap generation (256x256) | 50-100ms | Includes crater generation |
| Terrain mesh generation | 100-200ms | SurfaceTool or ArrayMesh |
| Biome map generation | 50-150ms | Includes blending pass |
| Full planet package | 200-450ms | All operations combined |

### Computational Complexity

- **Hash function**: O(1) - constant time lookup
- **Heightmap generation**: O(n²) where n = resolution
- **Terrain mesh**: O(n²) vertices and O(n²) triangles
- **Biome blending**: O(n²) with kernel size factor
- **Filament generation**: O(s² × log s) where s = system count

## Customization and Configuration

### Universe Generator Customization

```gdscript
# Create with custom seed
var universe = UniverseGenerator.new(12345)

# Configure cache behavior
universe.use_cache = true
universe.set_max_cache_size(500)

# Get statistics
var stats = universe.get_statistics()
print("Cached systems: ", stats["cached_systems"])
```

### Planet Generator Customization

```gdscript
var generator = PlanetGenerator.new()

# Configure noise parameters
generator.configure_noise(
    octaves=8,
    persistence=0.5,
    lacunarity=2.0,
    frequency=0.005
)

# Set terrain scale
generator.height_scale = 50.0

# Enable/disable features
generator.generate_craters = true
generator.apply_biome_colors = true

# Get current configuration
var config = generator.get_configuration()
```

### Biome System Customization

```gdscript
var biome_system = BiomeSystem.new()

# Configure planet properties
biome_system.configure_planet(
    distance_from_star=1.0,
    temp_modifier=0.0,
    moisture=0.5,
    atmosphere=1.0
)

# Control effects
biome_system.effects_enabled = true

# Get statistics
var stats = biome_system.get_planet_biome_statistics(seed, heightmap)
```

## Signal Integration

### UniverseGenerator Signals

```gdscript
signal system_generated(system: StarSystem)     # New system created
signal filaments_generated(filaments: Array[Filament])  # Network created
```

### PlanetGenerator Signals

```gdscript
signal heightmap_generated(heightmap: Image, planet_seed: int)
signal terrain_mesh_generated(mesh: ArrayMesh, lod_level: int)
signal normal_map_generated(normal_map: Image)
```

### BiomeSystem Signals

```gdscript
signal biome_map_generated(biome_map: Image, planet_seed: int)
signal environmental_effect_changed(biome: BiomeType, effect: EnvironmentalEffect)
signal biome_determined(position: Vector2, biome: BiomeType)
```

## Data Classes and Types

### StarSystem
```gdscript
class StarSystem:
    var coordinates: Vector3i              # Sector coordinates
    var local_position: Vector3            # Position within sector
    var has_star: bool                     # System contains star
    var system_name: String                # Procedural name
    var star_type: String                  # "O", "B", "A", "F", "G", "K", "M"
    var star_mass: float                   # Solar masses
    var star_radius: float                 # Solar radii
    var star_temperature: float            # Kelvin
    var planets: Array[PlanetData]         # Orbiting planets
    var discovered: bool                   # Exploration flag
```

### PlanetData
```gdscript
class PlanetData:
    var planet_name: String                # b, c, d, e, etc.
    var planet_type: PlanetType            # TERRESTRIAL, GAS_GIANT, etc.
    var mass: float                        # Earth masses
    var radius: float                      # Earth radii
    var orbital_distance: float            # AU
    var eccentricity: float                # 0-0.3
    var inclination: float                 # radians
    var rotation_period: float             # hours
    var axial_tilt: float                  # radians
    var has_rings: bool                    # Ring presence
    var moon_count: int                    # Natural satellites
```

### Filament
```gdscript
class Filament:
    var start_system: StarSystem           # Origin system
    var end_system: StarSystem             # Destination system
    var length: float                      # Connection distance
    var density: float                     # 0.1-1.0, shorter = denser
```

## Validation and Testing

### Determinism Validation

Each system provides determinism validation:

```gdscript
# Planet terrain
var is_deterministic = generator.validate_determinism(seed, 64)

# Biome system
var is_deterministic = biome_system.validate_determinism(seed, 64)
```

### System Consistency Checks

```gdscript
# Verify no overlapping star systems
var no_overlap = universe.validate_no_overlaps(
    Vector3i(-2, -2, -2),
    Vector3i(2, 2, 2)
)

# Check system separation
var min_distance = UniverseGenerator.MIN_SYSTEM_SEPARATION
var color_distance = UniverseGenerator.SECTOR_SIZE * 3
```

## Common Patterns and Best Practices

### Pattern 1: Generating and Caching a Planet

```gdscript
var generator = PlanetGenerator.new()
var planet_seed = get_planet_seed()

# Generate full planet package
var terrain_pkg = generator.generate_planet_terrain(
    planet_seed,
    PlanetGenerator.LODLevel.MEDIUM,
    temperature=0.5,
    moisture=0.5
)

# Access components
var mesh = terrain_pkg["mesh"]
var material = terrain_pkg["material"]
var heightmap = terrain_pkg["heightmap"]
```

### Pattern 2: Dynamic LOD Management

```gdscript
var generator = PlanetGenerator.new()
var distance_to_planet = player.global_position.distance_to(planet_position)

# Get appropriate LOD
var lod = generator.get_lod_for_distance(distance_to_planet)

# Generate at LOD resolution
var heightmap = generator.generate_heightmap(seed, 256)
var mesh = generator.generate_terrain_mesh(heightmap, lod)
```

### Pattern 3: Exploring the Universe

```gdscript
var universe = UniverseGenerator.new(universe_seed)
var player_pos = player.global_position

# Get nearby systems
var systems = universe.get_nearby_systems(player_pos, radius_sectors=2)

# Filter for habitable planets
var habitable_systems = systems.filter(func(sys):
    return sys.has_star and sys.planets.any(func(p):
        return p.planet_type == UniverseGenerator.PlanetType.TERRESTRIAL
    )
)
```

### Pattern 4: Biome-Based Environmental Setup

```gdscript
var biome_system = BiomeSystem.new()
biome_system.configure_planet(1.0, 0.0, 0.5, 1.0)

var heightmap = generator.generate_heightmap(seed, 256)
var biome_map = biome_system.generate_biome_map_with_legend(seed, heightmap)

# Get detailed statistics
var stats = biome_system.get_planet_biome_statistics(seed, heightmap)
print("Dominant biome: ", stats["dominant_biome_name"])
print("Habitability: ", stats["habitability"])

# Apply environmental effects
var biome = biome_system.determine_biome(seed, 100, 100, 0.5)
var effect = biome_system.get_environmental_effect(biome)
var effect_props = biome_system.get_effect_properties(effect)
```

## Scaling and Performance Optimization

### Cache Management

All systems support cache configuration:

```gdscript
# Increase cache for large explorations
universe.set_max_cache_size(5000)
generator.set_max_cache_size(50)
biome_system.set_max_cache_size(20)

# Clear cache when memory pressure increases
if get_free_memory() < MEMORY_THRESHOLD:
    universe.clear_cache()
    generator.clear_cache()
    biome_system.clear_cache()
```

### Streaming Strategy

```gdscript
# Only generate systems near player
var nearby = universe.get_nearby_systems(player_pos, radius_sectors=1)

# Stream planet details as distance decreases
for system in nearby:
    if system.has_star:
        for planet in system.planets:
            var distance = calculate_distance(planet)
            if distance < STREAMING_THRESHOLD:
                stream_planet_details(planet)
```

### Noise Parameter Tuning

For different environment requirements:

```gdscript
# Mountain-heavy terrain
generator.configure_noise(
    octaves=10,
    persistence=0.7,
    lacunarity=2.5,
    frequency=0.003
)

# Gentle rolling hills
generator.configure_noise(
    octaves=4,
    persistence=0.3,
    lacunarity=1.8,
    frequency=0.001
)

# High-frequency detail
generator.configure_noise(
    octaves=12,
    persistence=0.4,
    lacunarity=2.2,
    frequency=0.01
)
```

## Troubleshooting

### Issue: Slow Generation

**Causes**: Large LOD resolutions, excessive cache size, high octave counts

**Solutions**:
- Reduce initial LOD level (start with MEDIUM, stream to HIGH)
- Lower noise octaves to 4-6 for faster generation
- Use streaming LOD system instead of generating all at once
- Monitor cache hit rates

### Issue: Memory Usage Growing

**Causes**: Unbounded cache growth, high-resolution heightmaps retained

**Solutions**:
- Set explicit max cache size: `set_max_cache_size(10)`
- Clear cache periodically: `clear_cache()`
- Use LOD levels appropriately for distance
- Pre-allocate maximum needed cache size

### Issue: Inconsistent Terrain Across Reloads

**Causes**: Seed not being persisted, floating-point rounding errors

**Solutions**:
- Always store seed for reproducibility
- Use integer coordinates for hashing
- Don't rely on floating-point comparisons in hashing
- Test with `validate_determinism()` method

### Issue: Biome Boundaries Too Harsh

**Causes**: Low blend distance, large noise frequency

**Solutions**:
- Increase `BIOME_BLEND_DISTANCE` value
- Reduce noise frequency for larger biome regions
- Increase temperature/moisture noise octaves for smoother transitions
- Use interpolated properties for smooth material transitions

## References and Constants

### Key Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| GOLDEN_RATIO | 1.618... | Star system spacing |
| SECTOR_SIZE | 1000.0 | Spatial partitioning unit |
| MIN_SYSTEM_SEPARATION | 100.0 | Minimum distance between stars |
| MAX_STARS_PER_SECTOR | 5 | Density limit |
| DEFAULT_HEIGHT_SCALE | 50.0 | Terrain vertical scale |
| BIOME_BLEND_DISTANCE | 0.05 | Transition zone size |

### Configuration Presets

**Space Exploration Focus**
- Large sectors: `SECTOR_SIZE = 2000.0`
- Fewer systems: `MAX_STARS_PER_SECTOR = 2`
- Gentle terrain: `height_scale = 20.0`

**Ground Exploration Focus**
- Detailed terrain: `height_scale = 100.0`
- Complex biomes: `noise_octaves = 10`
- Frequent effects: `effect_probability = 0.7`

**Performance Mode**
- Minimal cache: `max_cache_size = 100`
- Low detail: `LODLevel.LOW`
- Fewer craters: `CRATER_PROBABILITY = 0.1`

## Next Steps

- See **UNIVERSE_GENERATION.md** for detailed star system generation algorithms
- See **PLANET_GENERATION.md** for terrain generation and LOD details
- See **API_REFERENCE.md** for complete method documentation with examples
