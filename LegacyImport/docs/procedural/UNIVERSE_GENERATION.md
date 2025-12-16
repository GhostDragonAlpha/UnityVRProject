# Universe Generation - Technical Details

## Overview

The `UniverseGenerator` class implements a fully deterministic, infinite universe generation system using spatial hashing and physically-based stellar classification. The system generates realistic star systems at arbitrary coordinates without pre-computation or storage.

## Core Algorithms

### 1. Deterministic Hash Function

**Purpose**: Map 3D sector coordinates to unique, reproducible values

**Algorithm**:
```gdscript
func hash_coordinates(x: int, y: int, z: int) -> int:
    var hash_value: int = universe_seed
    hash_value ^= x * HASH_PRIME_1
    hash_value ^= y * HASH_PRIME_2
    hash_value ^= z * HASH_PRIME_3

    # XOR shift mixing (improves distribution)
    hash_value ^= (hash_value >> 13)
    hash_value ^= (hash_value << 7)
    hash_value ^= (hash_value >> 17)

    return absi(hash_value)
```

**Properties**:
- Commutative: Order of XOR operations doesn't matter
- Sensitive to input: Small changes in coordinates produce very different hashes
- Uniform distribution: Prime multipliers ensure good dispersion
- Deterministic: Same input always produces same output

**Hash Prime Selection**:
- `HASH_PRIME_1 = 73856093`
- `HASH_PRIME_2 = 19349663`
- `HASH_PRIME_3 = 83492791`
- Large primes chosen to be relatively co-prime

### 2. Hash-to-Float Conversion

**Purpose**: Convert integer hash to normalized floating-point range

**Algorithm**:
```gdscript
func hash_to_float(hash_value: int) -> float:
    return float(hash_value % 1000000) / 1000000.0
```

**Range**: [0, 1)
**Modulo Operation**: Ensures value fits in integer range before division
**Normalization**: Division creates float in [0, 1) range

### 3. Secondary Hash Generation

**Purpose**: Generate multiple independent properties from same coordinate hash

**Algorithm**:
```gdscript
func secondary_hash(primary_hash: int, index: int) -> int:
    var secondary: int = primary_hash ^ (index * HASH_PRIME_4)
    secondary ^= (secondary >> 11)
    secondary ^= (secondary << 5)
    secondary ^= (secondary >> 3)
    return absi(secondary)
```

**Features**:
- Index parameter allows generating N different hashes from one primary hash
- Unique mixing for each index value
- Maintains avalanche property (small changes propagate)

## Star System Generation

### 1. Star Existence Determination

**Probability**: 30% of sectors contain active star systems

**Algorithm**:
```gdscript
var existence_hash = secondary_hash(primary_hash, 0)
var existence_chance = hash_to_float(existence_hash)
if existence_chance > 0.3:
    system.has_star = false
    return system
```

**Motivation**: Realistic stellar density in galaxy (sparse space with clusters)

### 2. Stellar Classification

**System**: Harvard spectral classification (O, B, A, F, G, K, M)

**Realistic Distribution** (based on actual stellar census):

```gdscript
const STAR_TYPE_THRESHOLDS: Array[float] = [
    0.0000003,  # O-type (very rare)      - 0.00003%
    0.0013,     # B-type                   - 0.13%
    0.006,      # A-type                   - 0.6%
    0.03,       # F-type                   - 3%
    0.076,      # G-type (Sun-like)        - 7.6%
    0.121,      # K-type                   - 12.1%
    1.0         # M-type (most common)     - 76.45%
]
```

**Star Type Properties**:

| Type | Mass Range | Radius Range | Temp Range | Color | Examples |
|------|-----------|--------------|-----------|-------|----------|
| O | 16-150 M☉ | 6.6-20 R☉ | 30000-52000 K | Blue | Albireo A |
| B | 2.1-16 M☉ | 1.8-6.6 R☉ | 10000-30000 K | Blue-white | Rigel |
| A | 1.4-2.1 M☉ | 1.4-1.8 R☉ | 7500-10000 K | White | Sirius A |
| F | 1.04-1.4 M☉ | 1.15-1.4 R☉ | 6000-7500 K | Yellow-white | Procyon A |
| G | 0.8-1.04 M☉ | 0.96-1.15 R☉ | 5200-6000 K | Yellow | Our Sun |
| K | 0.45-0.8 M☉ | 0.7-0.96 R☉ | 3700-5200 K | Orange | Aldebaran |
| M | 0.08-0.45 M☉ | 0.1-0.7 R☉ | 2400-3700 K | Red | Proxima Centauri |

**Generation Process**:
```gdscript
func _determine_star_type(hash_value: int) -> String:
    var type_value = hash_to_float(hash_value)

    for i in range(STAR_TYPE_THRESHOLDS.size()):
        if type_value < STAR_TYPE_THRESHOLDS[i]:
            return STAR_TYPES[i]

    return "M"  # Default
```

### 3. Stellar Properties Generation

**Mass Generation**:
```gdscript
var mass_hash = secondary_hash(primary_hash, 2)
system.star_mass = hash_to_range(mass_hash, props[0], props[1])
```

**Radius and Temperature**: Similar process using different secondary hash indices

**Luminosity Calculation** (implicit):
- Derived from mass and type
- L ∝ M^3.5 approximately
- Used for planet habitability zones

### 4. Golden Ratio Star Positioning

**Purpose**: Distribute star positions within sector to avoid overlapping

**Algorithm**:
```gdscript
func _calculate_star_position(hash_value: int, sector_x: int, sector_y: int, sector_z: int) -> Vector3:
    var x_hash = secondary_hash(hash_value, 10)
    var y_hash = secondary_hash(hash_value, 11)
    var z_hash = secondary_hash(hash_value, 12)

    # Apply Golden Ratio modulation
    var x_offset = fmod(float(x_hash) * GOLDEN_RATIO_INVERSE, 1.0)
    var y_offset = fmod(float(y_hash) * GOLDEN_RATIO_INVERSE, 1.0)
    var z_offset = fmod(float(z_hash) * GOLDEN_RATIO_INVERSE, 1.0)

    # Scale to sector with margin
    var margin = MIN_SYSTEM_SEPARATION / SECTOR_SIZE
    var usable_range = 1.0 - 2.0 * margin

    var local_x = margin + x_offset * usable_range
    var local_y = margin + y_offset * usable_range
    var local_z = margin + z_offset * usable_range

    return Vector3(local_x, local_y, local_z) * SECTOR_SIZE
```

**Golden Ratio Properties**:
- φ = 1.618033988749 (golden ratio)
- φ⁻¹ = 0.618033988749 (inverse)
- Uses property: fmod(n × φ⁻¹, 1) produces quasi-uniform distribution
- Guarantees uniform spacing with minimal clustering

**Validation**: No two stars in adjacent sectors can overlap
```gdscript
distance = sqrt((pos1.x - pos2.x)² + (pos1.y - pos2.y)² + (pos1.z - pos2.z)²)
distance >= MIN_SYSTEM_SEPARATION  # Always true
```

## Planetary System Generation

### 1. Planet Count Distribution

**Algorithm**:
```gdscript
var planet_count_hash = secondary_hash(primary_hash, 5)
var planet_count = int(hash_to_range(planet_count_hash, 0.0, 9.0))
```

**Range**: 0-8 planets per system

### 2. Orbital Distance Calculation

**Titius-Bode-like Progression**:
```gdscript
var base_distance = 0.4 + 0.3 * pow(2.0, planet_index)
var distance_variation = hash_to_range(secondary_hash(planet_hash, 1), 0.8, 1.2)
planet.orbital_distance = base_distance * distance_variation
```

**Formula**: a = 0.4 + 0.3 × 2^n (in AU)
- Planet 0: 0.4-0.8 AU
- Planet 1: 0.7-1.4 AU
- Planet 2: 1.3-2.6 AU
- Provides realistic spacing avoiding orbital resonances

### 3. Planet Type Distribution

**Distance-Based Type Selection**:

```gdscript
func _determine_planet_type(hash_value: int, distance_factor: float) -> PlanetType:
    var type_value = hash_to_float(hash_value)

    if distance_factor < 0.3:
        # Inner zone: mostly terrestrial
        if type_value < 0.7:
            return PlanetType.TERRESTRIAL
        elif type_value < 0.9:
            return PlanetType.DWARF
        else:
            return PlanetType.GAS_GIANT

    elif distance_factor < 0.6:
        # Middle zone: mix of types
        if type_value < 0.3:
            return PlanetType.TERRESTRIAL
        elif type_value < 0.7:
            return PlanetType.GAS_GIANT
        else:
            return PlanetType.ICE_GIANT

    else:
        # Outer zone: mostly ice giants and dwarfs
        if type_value < 0.2:
            return PlanetType.GAS_GIANT
        elif type_value < 0.6:
            return PlanetType.ICE_GIANT
        else:
            return PlanetType.DWARF
```

**Realistic Distribution**:
- Inner planets: Smaller, rocky, terrestrial
- Middle zone: Gas giants possible, transitional
- Outer planets: Ice giants and small bodies
- Matches observed exoplanet distributions

### 4. Planetary Properties

**Mass and Radius Generation**:

```gdscript
match planet.planet_type:
    PlanetType.TERRESTRIAL:
        planet.mass = hash_to_range(mass_hash, 0.1, 2.0)  # Earth masses
        planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 0.5, 1.5)
    PlanetType.GAS_GIANT:
        planet.mass = hash_to_range(mass_hash, 50.0, 500.0)
        planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 5.0, 15.0)
    PlanetType.ICE_GIANT:
        planet.mass = hash_to_range(mass_hash, 10.0, 50.0)
        planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 3.0, 6.0)
    PlanetType.DWARF:
        planet.mass = hash_to_range(mass_hash, 0.001, 0.1)
        planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 0.1, 0.5)
```

**Orbital Elements**:
- **Eccentricity**: 0.0-0.3 (realistic, circular to slightly elliptical)
- **Inclination**: 0.0-0.1 rad (most planets nearly coplanar)
- **Rotation period**: 10-1000 hours (Mars-like to Jupiter-like)
- **Axial tilt**: 0.0-0.5 rad (stable inclinations)

### 5. Rings and Moons

**Ring Generation**:
```gdscript
var ring_chance = 0.1 if planet.planet_type == PlanetType.TERRESTRIAL else 0.4
planet.has_rings = hash_to_float(ring_hash) < ring_chance
```

- Terrestrial: 10% chance
- Giants: 40% chance (realistic)

**Moon Generation**:
```gdscript
var max_moons = 2 if planet.planet_type == PlanetType.TERRESTRIAL else 10
var moon_count = int(hash_to_range(moon_count_hash, 0.0, float(max_moons)))
```

- Terrestrial: 0-2 moons
- Giants: 0-10 moons

## Filament Network Generation

### Purpose

Filaments represent cosmic web structure connecting star systems - used for navigation, trade routes, and cosmic energy flows in gameplay.

### Minimum Spanning Tree Approach

**Algorithm**:
```gdscript
func generate_filaments(systems: Array[StarSystem]) -> Array[Filament]:
    var connected: Array[int] = [0]
    var unconnected: Array[int] = []

    # Initialize unconnected list
    for i in range(1, systems.size()):
        unconnected.append(i)

    # Connect all systems using nearest neighbor (MST variant)
    while unconnected.size() > 0:
        var best_distance = INF
        var best_connected_idx = -1
        var best_unconnected_idx = -1

        # Find nearest pair across sets
        for c_idx in connected:
            for u_idx in unconnected:
                var distance = distance_between(systems[c_idx], systems[u_idx])
                if distance < best_distance:
                    best_distance = distance
                    best_connected_idx = c_idx
                    best_unconnected_idx = u_idx

        # Create connection
        var filament = Filament.new()
        filament.start_system = systems[best_connected_idx]
        filament.end_system = systems[best_unconnected_idx]
        filament.length = best_distance
        filament.density = _calculate_filament_density(best_distance)
        filaments.append(filament)

        # Move system to connected set
        connected.append(best_unconnected_idx)
        unconnected.erase(best_unconnected_idx)
```

**Complexity**: O(s² × log s) for s star systems

### Density Calculation

**Algorithm**:
```gdscript
func _calculate_filament_density(length: float) -> float:
    var max_length = SECTOR_SIZE * 5
    return clampf(1.0 - (length / max_length), 0.1, 1.0)
```

**Properties**:
- Shorter filaments: Higher density (max 1.0)
- Longer filaments: Lower density (min 0.1)
- Inverse relationship models cosmic web structure

### Redundancy Connections

**Additional 20% Connections**:
```gdscript
var extra_connections = int(systems.size() * 0.2)
for _i in range(extra_connections):
    var idx1 = randi() % systems.size()
    var idx2 = randi() % systems.size()

    if idx1 != idx2:
        var distance = distance_between(systems[idx1], systems[idx2])
        if distance < SECTOR_SIZE * 3:  # Only local connections
            # Create filament
```

**Purpose**: Create shortcuts and network redundancy without excessive complexity

## Naming Generation

### Star System Names

**Algorithm**:
```gdscript
func _generate_system_name(hash_value: int) -> String:
    var prefixes = ["Alpha", "Beta", "Gamma", ..., "Omega"]  # Greek letters
    var suffixes = ["Centauri", "Cygni", "Draconis", ..., "Virginis"]  # Actual constellation names

    var prefix_idx = hash_value % prefixes.size()
    var suffix_idx = secondary_hash(hash_value, 20) % suffixes.size()
    var number = (secondary_hash(hash_value, 21) % 999) + 1

    return "%s %s %d" % [prefixes[prefix_idx], suffixes[suffix_idx], number]
```

**Example Output**:
- Alpha Centauri 42
- Gamma Cygni 867
- Omega Virginis 123

**Prefix**: 24 Greek letters
**Suffix**: 17 real constellation genitive names
**Number**: 1-999

### Planet Designations

**Algorithm**:
```gdscript
func _generate_planet_name(hash_value: int, planet_index: int) -> String:
    var letters = ["b", "c", "d", "e", "f", "g", "h", "i"]
    if planet_index < letters.size():
        return letters[planet_index]
    return "p%d" % (planet_index + 1)
```

**Convention**: Follows astronomical naming (star = a, first planet = b, etc.)

## Caching System

### Cache Key Generation

**Algorithm**:
```gdscript
func _make_cache_key(x: int, y: int, z: int) -> String:
    return "%d_%d_%d" % [x, y, z]
```

### Cache Eviction Policy

**Simple FIFO** when cache reaches max size:
```gdscript
if _system_cache.size() >= _max_cache_size:
    var first_key = _system_cache.keys()[0]
    _system_cache.erase(first_key)
```

**Default**: 1000 systems cached
**Customizable**: `set_max_cache_size(size)`

### Memory Usage

- Per system: ~1 KB (coordinates, properties, planet array)
- 1000 systems: ~1 MB
- 10000 systems: ~10 MB (reasonable for exploration)

## Query Operations

### Get Systems in Region

**Complexity**: O(n × m) where n = sectors, m = generation per sector

```gdscript
func get_systems_in_region(min_sector: Vector3i, max_sector: Vector3i) -> Array[StarSystem]:
    var systems: Array[StarSystem] = []

    for x in range(min_sector.x, max_sector.x + 1):
        for y in range(min_sector.y, max_sector.y + 1):
            for z in range(min_sector.z, max_sector.z + 1):
                var system = get_star_system(x, y, z)
                if system.has_star:
                    systems.append(system)

    return systems
```

### Find Nearest System

**Complexity**: O(n²) for n nearby systems

```gdscript
func find_nearest_system(world_pos: Vector3, search_radius: int = 3) -> StarSystem:
    var systems = get_nearby_systems(world_pos, search_radius)

    var nearest: StarSystem = null
    var nearest_distance = INF

    for system in systems:
        if system.has_star:
            var distance = world_pos.distance_to(get_system_world_position(system))
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = system

    return nearest
```

## Performance Optimization Strategies

### 1. Lazy Generation
- Generate star systems only when queried
- Avoid pre-generating entire universe
- Cache only frequently accessed systems

### 2. Hierarchical Queries
- Start with large radius
- Narrow search gradually
- Reduces redundant calculations

### 3. Culling Strategies
- Skip empty sectors (70% of space)
- Filter for relevant planet types early
- Avoid processing distant systems

### 4. Seed Management
- Store universe seed with world data
- Allows exact universe recreation
- Enables multiplayer synchronization

## Configuration Examples

### Dense Galaxy Cluster
```gdscript
var universe = UniverseGenerator.new(seed)
# Increase sector existence probability from 30% to 50%
# (Requires code modification, not currently exposed)
```

### Sparse Universe
```gdscript
var universe = UniverseGenerator.new(seed)
# Decrease star count by filtering after generation
var filtered = universe.get_nearby_systems(pos, radius)
    .filter(func(s): return s.has_star and s.star_type != "M")
```

### Large Scale Exploration
```gdscript
universe.set_max_cache_size(10000)
universe.use_cache = true
```

## Limitations and Future Improvements

### Current Limitations

1. **Fixed probability**: Star existence at 30% is hardcoded
2. **Limited biome factors**: Only distance affects planetary biomes
3. **No stellar evolution**: Stars don't change over time
4. **Simple filaments**: No complex topological structures
5. **No exotic objects**: No black holes, neutron stars, pulsars

### Potential Improvements

1. **Variable star density**: Region-based probability
2. **Stellar evolution tracks**: Age-dependent properties
3. **Multiple star systems**: Binary and trinary stars
4. **Pulsars and exotic objects**: Expanded stellar catalog
5. **Procedural star names**: More varied naming schemes
6. **Habitable zone calculation**: Real planetary habitability scoring
