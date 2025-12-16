# Procedural Generation API Reference

## UniverseGenerator Class

### Constructor

```gdscript
func _init(seed_value: int = 0) -> void
```

Creates a new universe generator with optional seed.

**Parameters:**
- `seed_value`: Integer seed for deterministic generation (0 = random seed)

**Example:**
```gdscript
var universe = UniverseGenerator.new(12345)
```

---

### Star System Queries

#### get_star_system

```gdscript
func get_star_system(sector_x: int, sector_y: int, sector_z: int) -> StarSystem
```

Gets or generates a star system at sector coordinates.

**Parameters:**
- `sector_x`, `sector_y`, `sector_z`: Sector coordinates (world_position / 1000)

**Returns:** `StarSystem` object

**Example:**
```gdscript
var system = universe.get_star_system(0, 0, 0)
if system.has_star:
    print("Star type: ", system.star_type)
    print("Mass: ", system.star_mass, " solar masses")
```

**Signals:** Emits `system_generated(system)`

---

#### get_systems_in_region

```gdscript
func get_systems_in_region(min_sector: Vector3i, max_sector: Vector3i) -> Array[StarSystem]
```

Gets all star systems in a rectangular region.

**Parameters:**
- `min_sector`: Minimum sector coordinates (inclusive)
- `max_sector`: Maximum sector coordinates (inclusive)

**Returns:** Array of `StarSystem` objects

**Example:**
```gdscript
var systems = universe.get_systems_in_region(
    Vector3i(-2, -2, -2),
    Vector3i(2, 2, 2)
)
print("Found %d systems" % systems.size())
```

---

#### get_nearby_systems

```gdscript
func get_nearby_systems(world_pos: Vector3, radius_sectors: int = 1) -> Array[StarSystem]
```

Gets star systems within a radius of a world position.

**Parameters:**
- `world_pos`: World position in game units
- `radius_sectors`: Search radius in sectors (default: 1)

**Returns:** Array of `StarSystem` objects

**Example:**
```gdscript
var player_pos = player.global_position
var nearby = universe.get_nearby_systems(player_pos, radius_sectors=2)

# Filter for habitable planets
var habitable = nearby.filter(func(s):
    return s.has_star and s.planets.any(func(p):
        return p.planet_type == UniverseGenerator.PlanetType.TERRESTRIAL
    )
)
```

---

#### find_nearest_system

```gdscript
func find_nearest_system(world_pos: Vector3, search_radius: int = 3) -> StarSystem
```

Finds the nearest star system to a position.

**Parameters:**
- `world_pos`: World position in game units
- `search_radius`: Initial search radius in sectors

**Returns:** Nearest `StarSystem` or null

**Example:**
```gdscript
var nearest = universe.find_nearest_system(player.global_position)
if nearest:
    var distance = player.global_position.distance_to(
        universe.get_system_world_position(nearest)
    )
    print("Nearest system is %.1f km away" % (distance / 1000))
```

---

### Spatial Utilities

#### get_sector_for_position

```gdscript
func get_sector_for_position(world_pos: Vector3) -> Vector3i
```

Converts a world position to sector coordinates.

**Parameters:**
- `world_pos`: World position in game units

**Returns:** `Vector3i` sector coordinates

**Example:**
```gdscript
var sector = universe.get_sector_for_position(Vector3(5000, 0, -3000))
# sector = (5, 0, -3)
```

---

#### get_system_world_position

```gdscript
func get_system_world_position(system: StarSystem) -> Vector3
```

Converts system coordinates to world position.

**Parameters:**
- `system`: `StarSystem` object

**Returns:** `Vector3` world position

**Example:**
```gdscript
var system = universe.get_star_system(1, 0, 0)
var world_pos = universe.get_system_world_position(system)
# Position within sector + global offset
```

---

### Filament Generation

#### generate_filaments

```gdscript
func generate_filaments(systems: Array[StarSystem]) -> Array[Filament]
```

Generates cosmic web filaments connecting star systems.

**Parameters:**
- `systems`: Array of `StarSystem` objects

**Returns:** Array of `Filament` objects

**Example:**
```gdscript
var systems = universe.get_nearby_systems(player_pos, 3)
var filaments = universe.generate_filaments(systems)

# Draw filaments on map
for filament in filaments:
    draw_line(filament.start_system.local_position,
              filament.end_system.local_position)
```

**Signals:** Emits `filaments_generated(filaments)`

---

### Validation

#### check_system_overlap

```gdscript
func check_system_overlap(system1: StarSystem, system2: StarSystem) -> bool
```

Checks if two star systems overlap (too close together).

**Parameters:**
- `system1`, `system2`: `StarSystem` objects

**Returns:** `true` if systems overlap

**Example:**
```gdscript
if universe.check_system_overlap(sys1, sys2):
    print("ERROR: Systems are overlapping!")
```

---

#### validate_no_overlaps

```gdscript
func validate_no_overlaps(min_sector: Vector3i, max_sector: Vector3i) -> bool
```

Validates that no star systems in a region overlap.

**Parameters:**
- `min_sector`, `max_sector`: Region boundaries

**Returns:** `true` if all systems are properly separated

**Example:**
```gdscript
if universe.validate_no_overlaps(Vector3i(-1, -1, -1), Vector3i(1, 1, 1)):
    print("Universe validation passed")
```

---

### Cache Management

#### set_max_cache_size

```gdscript
func set_max_cache_size(size: int) -> void
```

Sets the maximum number of cached star systems.

**Parameters:**
- `size`: Maximum cache entries (minimum 10)

**Example:**
```gdscript
universe.set_max_cache_size(500)  # Cache up to 500 systems
```

---

#### clear_cache

```gdscript
func clear_cache() -> void
```

Clears all cached star systems.

**Example:**
```gdscript
# Free memory before exploring new region
universe.clear_cache()
```

---

#### get_statistics

```gdscript
func get_statistics() -> Dictionary
```

Returns statistics about the universe generator.

**Returns:** Dictionary with keys:
- `seed`: Universe seed
- `cached_systems`: Number of cached systems
- `max_cache_size`: Maximum cache size
- `sector_size`: Size of each sector
- `min_separation`: Minimum system separation
- `golden_ratio`: Golden ratio constant

**Example:**
```gdscript
var stats = universe.get_statistics()
print("Cached: %d/%d" % [stats["cached_systems"], stats["max_cache_size"]])
```

---

### Seed Management

#### get_seed

```gdscript
func get_seed() -> int
```

Returns the current universe seed.

---

#### set_seed

```gdscript
func set_seed(new_seed: int) -> void
```

Sets the universe seed and clears cache.

**Parameters:**
- `new_seed`: New seed value

**Example:**
```gdscript
universe.set_seed(54321)
# Universe is now completely different
```

---

## PlanetGenerator Class

### Constructor and Initialization

#### _ready

```gdscript
func _ready() -> void
```

Initializes FastNoiseLite instances. Called automatically.

---

### Heightmap Generation

#### generate_heightmap

```gdscript
func generate_heightmap(planet_seed: int, resolution: int = 256) -> Image
```

Generates a heightmap for a planet.

**Parameters:**
- `planet_seed`: Unique seed for the planet
- `resolution`: Image size (256, 128, 64, 32, or 16)

**Returns:** `Image` (FORMAT_RF, single-channel float)

**Example:**
```gdscript
var generator = PlanetGenerator.new()
var heightmap = generator.generate_heightmap(planet_seed, 256)
print("Generated %dx%d heightmap" % [heightmap.get_width(), heightmap.get_height()])
```

**Signals:** Emits `heightmap_generated(heightmap, planet_seed)`

---

#### generate_heightmap_region

```gdscript
func generate_heightmap_region(planet_seed: int, region_x: int, region_y: int,
                              region_size: int, resolution: int) -> Image
```

Generates a heightmap for a specific region (for LOD streaming).

**Parameters:**
- `planet_seed`: Planet identifier
- `region_x`, `region_y`: Region coordinates
- `region_size`: Size of region in world units
- `resolution`: Output resolution

**Returns:** `Image` heightmap for region

**Example:**
```gdscript
# Generate high-detail region near player
var region_heightmap = generator.generate_heightmap_region(
    seed,
    player_region_x, player_region_y,
    1000,  # 1000m regions
    256    # Full detail
)
```

---

### Mesh Generation

#### generate_terrain_mesh

```gdscript
func generate_terrain_mesh(heightmap: Image,
                          lod_level: LODLevel = LODLevel.MEDIUM) -> ArrayMesh
```

Generates terrain mesh from heightmap using SurfaceTool (easier, slower).

**Parameters:**
- `heightmap`: Source heightmap image
- `lod_level`: Detail level (ULTRA, HIGH, MEDIUM, LOW, MINIMAL)

**Returns:** `ArrayMesh` ready for rendering

**Example:**
```gdscript
var mesh = generator.generate_terrain_mesh(heightmap, PlanetGenerator.LODLevel.MEDIUM)
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = mesh
```

**Signals:** Emits `terrain_mesh_generated(mesh, lod_level)`

---

#### generate_terrain_mesh_array

```gdscript
func generate_terrain_mesh_array(heightmap: Image,
                                lod_level: LODLevel = LODLevel.MEDIUM) -> ArrayMesh
```

Generates terrain mesh using ArrayMesh (faster, more efficient).

**Parameters:**
- `heightmap`: Source heightmap image
- `lod_level`: Detail level

**Returns:** `ArrayMesh` ready for rendering

**Signals:** Emits `terrain_mesh_generated(mesh, lod_level)`

**Note:** Preferred over `generate_terrain_mesh` for production code.

---

### Normal Maps

#### generate_normal_map

```gdscript
func generate_normal_map(heightmap: Image) -> Image
```

Generates a normal map from a heightmap for detail lighting.

**Parameters:**
- `heightmap`: Source heightmap

**Returns:** `Image` (FORMAT_RGB8) with encoded normals

**Example:**
```gdscript
var normal_map = generator.generate_normal_map(heightmap)
material.normal_texture = ImageTexture.create_from_image(normal_map)
```

**Signals:** Emits `normal_map_generated(normal_map)`

---

### Complete Terrain Generation

#### generate_planet_terrain

```gdscript
func generate_planet_terrain(planet_seed: int,
                            lod_level: LODLevel = LODLevel.MEDIUM,
                            temperature: float = 0.5,
                            moisture: float = 0.5) -> Dictionary
```

Generates complete terrain package in one call.

**Parameters:**
- `planet_seed`: Planet identifier
- `lod_level`: Detail level
- `temperature`: 0-1 (used by BiomeSystem)
- `moisture`: 0-1 (used by BiomeSystem)

**Returns:** Dictionary with:
- `heightmap`: Generated heightmap
- `normal_map`: Generated normal map
- `mesh`: Generated mesh
- `material`: StandardMaterial3D with biome colors
- `lod_level`: Used LOD level
- `resolution`: Actual resolution used
- `planet_seed`: Input seed

**Example:**
```gdscript
var terrain = generator.generate_planet_terrain(
    planet_seed,
    PlanetGenerator.LODLevel.HIGH,
    temperature=0.6,
    moisture=0.4
)

var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = terrain["mesh"]
mesh_instance.set_surface_override_material(0, terrain["material"])
```

---

### Configuration

#### configure_noise

```gdscript
func configure_noise(octaves: int = DEFAULT_OCTAVES,
                    persistence: float = DEFAULT_PERSISTENCE,
                    lacunarity: float = DEFAULT_LACUNARITY,
                    frequency: float = DEFAULT_FREQUENCY) -> void
```

Configures noise generation parameters.

**Parameters:**
- `octaves`: 1-16 (default: 8)
- `persistence`: 0.1-1.0 (default: 0.5)
- `lacunarity`: 1.0-4.0 (default: 2.0)
- `frequency`: 0.0001-1.0 (default: 0.005)

**Example:**
```gdscript
# High detail, mountainous terrain
generator.configure_noise(
    octaves=10,
    persistence=0.7,
    lacunarity=2.2,
    frequency=0.003
)

# Smooth, rolling hills
generator.configure_noise(
    octaves=4,
    persistence=0.3,
    lacunarity=1.8,
    frequency=0.001
)
```

---

#### get_configuration

```gdscript
func get_configuration() -> Dictionary
```

Gets current generator configuration.

**Returns:** Dictionary with current noise and rendering settings

---

### LOD Management

#### get_lod_for_distance

```gdscript
func get_lod_for_distance(distance: float) -> LODLevel
```

Automatically selects appropriate LOD based on distance.

**Parameters:**
- `distance`: Distance to planet in game units

**Returns:** `LODLevel` enum value

**Example:**
```gdscript
var distance = player.global_position.distance_to(planet_position)
var lod = generator.get_lod_for_distance(distance)
var mesh = generator.generate_terrain_mesh(heightmap, lod)
```

---

### Cache Management

#### set_max_cache_size

```gdscript
func set_max_cache_size(size: int) -> void
```

Sets maximum number of cached heightmaps.

**Parameters:**
- `size`: Maximum cache entries (minimum 1)

---

#### clear_cache

```gdscript
func clear_cache() -> void
```

Clears all cached heightmaps.

---

### Properties

```gdscript
@export var noise_octaves: int = DEFAULT_OCTAVES
@export var noise_persistence: float = DEFAULT_PERSISTENCE
@export var noise_lacunarity: float = DEFAULT_LACUNARITY
@export var base_frequency: float = DEFAULT_FREQUENCY
@export var height_scale: float = DEFAULT_HEIGHT_SCALE
@export var generate_craters: bool = true
@export var apply_biome_colors: bool = true
```

All properties can be modified and will take effect on next generation.

---

### Validation

#### validate_determinism

```gdscript
func validate_determinism(planet_seed: int, resolution: int = 64) -> bool
```

Validates that terrain generation is deterministic.

**Parameters:**
- `planet_seed`: Planet seed to test
- `resolution`: Test resolution (smaller = faster)

**Returns:** `true` if generation is deterministic

**Example:**
```gdscript
if not generator.validate_determinism(seed):
    print("ERROR: Generation not deterministic!")
```

---

## BiomeSystem Class

### Configuration

#### configure_planet

```gdscript
func configure_planet(distance_from_star: float,
                     temp_modifier: float = 0.0,
                     moisture: float = 0.5,
                     atmosphere: float = 1.0) -> void
```

Configures planet properties for biome generation.

**Parameters:**
- `distance_from_star`: Distance in AU (0.1-5.0 typical)
- `temp_modifier`: Temperature adjustment (-1.0 to 1.0)
- `moisture`: Planet moisture level (0.0-1.0)
- `atmosphere`: Atmosphere density (0.0-2.0)

**Example:**
```gdscript
var biome_system = BiomeSystem.new()

# Hot, moist planet far from star
biome_system.configure_planet(
    distance_from_star=2.0,
    temp_modifier=0.5,
    moisture=0.8,
    atmosphere=1.5
)
```

---

#### get_configuration

```gdscript
func get_configuration() -> Dictionary
```

Gets current biome system configuration.

---

### Biome Assignment

#### determine_biome

```gdscript
func determine_biome(planet_seed: int, x: float, y: float, height: float) -> BiomeType
```

Determines the biome type at a position.

**Parameters:**
- `planet_seed`: Planet identifier
- `x`, `y`: Position coordinates
- `height`: Altitude (0.0-1.0)

**Returns:** `BiomeType` enum value

**Example:**
```gdscript
var biome = biome_system.determine_biome(seed, 100, 200, 0.5)
match biome:
    BiomeSystem.BiomeType.FOREST:
        print("Forest biome with trees and rain")
    BiomeSystem.BiomeType.DESERT:
        print("Desert biome with sand and rocks")
    BiomeSystem.BiomeType.ICE:
        print("Ice biome with snow and blizzards")
```

**Signals:** Emits `biome_determined(position, biome)`

---

### Biome Colors and Properties

#### get_biome_color

```gdscript
func get_biome_color(biome: BiomeType) -> Color
```

Gets base color for biome type.

**Parameters:**
- `biome`: `BiomeType` enum value

**Returns:** `Color` RGB

**Example:**
```gdscript
var forest_color = biome_system.get_biome_color(BiomeSystem.BiomeType.FOREST)
# Returns Color(0.2, 0.5, 0.2)  # Green
```

---

#### get_biome_secondary_color

```gdscript
func get_biome_secondary_color(biome: BiomeType) -> Color
```

Gets secondary color for terrain variation.

---

#### get_biome_name

```gdscript
func get_biome_name(biome: BiomeType) -> String
```

Gets display name for biome type.

**Returns:** Human-readable biome name

**Example:**
```gdscript
var name = biome_system.get_biome_name(BiomeSystem.BiomeType.VOLCANIC)
print(name)  # "Volcanic"
```

---

#### get_biome_material_properties

```gdscript
func get_biome_material_properties(biome: BiomeType) -> Dictionary
```

Gets PBR material properties for biome.

**Returns:** Dictionary with:
- `albedo`: Color
- `roughness`: 0.0-1.0
- `metallic`: 0.0-1.0

**Example:**
```gdscript
var props = biome_system.get_biome_material_properties(biome)
material.albedo_color = props["albedo"]
material.roughness = props["roughness"]
material.metallic = props["metallic"]
```

---

#### create_biome_material

```gdscript
func create_biome_material(biome: BiomeType) -> StandardMaterial3D
```

Creates a StandardMaterial3D configured for a biome.

**Returns:** `StandardMaterial3D` ready for use

**Example:**
```gdscript
var material = biome_system.create_biome_material(biome)
mesh_instance.set_surface_override_material(0, material)
```

---

### Biome Blending

#### get_blended_color

```gdscript
func get_blended_color(planet_seed: int, x: float, y: float, height: float) -> Color
```

Gets smoothly blended color accounting for nearby biomes.

**Parameters:**
- `planet_seed`: Planet identifier
- `x`, `y`: Position
- `height`: Altitude

**Returns:** Blended `Color`

**Example:**
```gdscript
# For smooth transitions at biome boundaries
var color = biome_system.get_blended_color(seed, pos.x, pos.y, height)
```

---

#### calculate_blend_factor

```gdscript
func calculate_blend_factor(planet_seed: int, x1: float, y1: float,
                           x2: float, y2: float, height: float) -> float
```

Calculates blend factor between two positions.

**Returns:** 0.0 (same biome) to 1.0 (different biome)

---

#### get_interpolated_properties

```gdscript
func get_interpolated_properties(planet_seed: int, x: float, y: float, height: float) -> Dictionary
```

Gets interpolated biome properties for smooth transitions.

**Returns:** Dictionary with interpolated material properties

---

### Biome Maps

#### generate_biome_map

```gdscript
func generate_biome_map(planet_seed: int, heightmap: Image,
                       resolution: int = DEFAULT_BIOME_MAP_RESOLUTION) -> Image
```

Generates a biome distribution map.

**Parameters:**
- `planet_seed`: Planet identifier
- `heightmap`: Planet heightmap
- `resolution`: Output resolution (default 256)

**Returns:** `Image` (FORMAT_RGB8) with biome colors

**Example:**
```gdscript
var biome_map = biome_system.generate_biome_map(seed, heightmap)
var texture = ImageTexture.create_from_image(biome_map)
biome_display.texture = texture
```

**Signals:** Emits `biome_map_generated(biome_map, planet_seed)`

---

#### generate_biome_map_with_legend

```gdscript
func generate_biome_map_with_legend(planet_seed: int, heightmap: Image,
                                   resolution: int = DEFAULT_BIOME_MAP_RESOLUTION) -> Dictionary
```

Generates biome map with statistical metadata.

**Returns:** Dictionary with:
- `biome_map`: Generated map image
- `biome_counts`: Pixel counts per biome
- `biome_percentages`: Percentages of each biome
- `resolution`: Resolution used
- `planet_seed`: Input seed

**Example:**
```gdscript
var result = biome_system.generate_biome_map_with_legend(seed, heightmap)
for biome in result["biome_percentages"]:
    var name = biome_system.get_biome_name(biome)
    var pct = result["biome_percentages"][biome]
    print("%s: %.1f%%" % [name, pct])
```

---

### Environmental Effects

#### get_environmental_effect

```gdscript
func get_environmental_effect(biome: BiomeType) -> EnvironmentalEffect
```

Gets random environmental effect for a biome.

**Parameters:**
- `biome`: `BiomeType` enum value

**Returns:** `EnvironmentalEffect` enum value

**Example:**
```gdscript
var effect = biome_system.get_environmental_effect(biome)
if effect == BiomeSystem.EnvironmentalEffect.RAIN:
    start_rain_particle_system()
```

---

#### update_environmental_effect

```gdscript
func update_environmental_effect(planet_seed: int, x: float, y: float, height: float) -> EnvironmentalEffect
```

Updates environmental effect for current position.

**Parameters:**
- `planet_seed`: Planet identifier
- `x`, `y`: Position
- `height`: Altitude

**Returns:** Current `EnvironmentalEffect`

**Signals:** Emits `environmental_effect_changed(biome, effect)` if changed

---

#### get_effect_properties

```gdscript
func get_effect_properties(effect: EnvironmentalEffect) -> Dictionary
```

Gets rendering properties for an environmental effect.

**Returns:** Dictionary with:
- `intensity`: 0.0-1.0
- `particle_type`: String ("snow", "rain", "dust", etc.)
- `visibility_reduction`: 0.0-1.0
- `particle_color`: Color
- `particle_size`: Float
- `fall_speed`: Float

**Example:**
```gdscript
var props = biome_system.get_effect_properties(effect)
particles.process_material.initial_velocity_min = props["fall_speed"]
particles.modulate = props["particle_color"]
```

---

### Statistics and Utilities

#### get_all_biome_types

```gdscript
func get_all_biome_types() -> Array[BiomeType]
```

Gets array of all biome types.

**Returns:** Array of all `BiomeType` enum values

---

#### is_biome_habitable

```gdscript
func is_biome_habitable(biome: BiomeType) -> bool
```

Checks if a biome is habitable.

**Returns:** `true` for FOREST and OCEAN

---

#### get_biome_danger_level

```gdscript
func get_biome_danger_level(biome: BiomeType) -> float
```

Gets danger level of a biome.

**Returns:** 0.0 (safe) to 1.0 (extremely dangerous)

---

#### get_biome_detail_types

```gdscript
func get_biome_detail_types(biome: BiomeType) -> Array
```

Gets surface detail types for a biome.

**Returns:** Array of strings (e.g., ["tree", "rock", "grass"])

---

#### get_planet_biome_statistics

```gdscript
func get_planet_biome_statistics(planet_seed: int, heightmap: Image) -> Dictionary
```

Gets detailed biome statistics for a planet.

**Returns:** Dictionary with:
- `biome_map`: Generated biome map
- `biome_counts`: Pixel counts
- `biome_percentages`: Percentages
- `dominant_biome`: Most common biome type
- `dominant_biome_name`: Name of dominant biome
- `habitability`: Overall habitability score (0-1)

**Example:**
```gdscript
var stats = biome_system.get_planet_biome_statistics(seed, heightmap)
print("Planet habitability: %.1f%%" % (stats["habitability"] * 100))
print("Dominant biome: %s" % stats["dominant_biome_name"])
```

---

### Cache Management

#### set_max_cache_size

```gdscript
func set_max_cache_size(size: int) -> void
```

Sets maximum number of cached biome maps.

---

#### clear_cache

```gdscript
func clear_cache() -> void
```

Clears all cached biome maps.

---

### Properties

```gdscript
@export var star_distance: float = 1.0          # Distance from star (AU)
@export var temperature_modifier: float = 0.0   # Temperature adjustment (-1 to 1)
@export var moisture_level: float = 0.5         # Moisture (0 to 1)
@export var atmosphere_density: float = 1.0     # Atmosphere density (0 to 2)
@export var effects_enabled: bool = true        # Enable weather effects
```

---

### Validation

#### validate_determinism

```gdscript
func validate_determinism(planet_seed: int, resolution: int = 64) -> bool
```

Validates that biome generation is deterministic.

**Returns:** `true` if deterministic

---

## Enumerations

### UniverseGenerator.PlanetType

```gdscript
enum PlanetType {
    TERRESTRIAL,  # Rocky planets (Earth-like)
    GAS_GIANT,    # Large gas planets (Jupiter-like)
    ICE_GIANT,    # Ice-covered planets (Neptune-like)
    DWARF         # Small planets
}
```

---

### PlanetGenerator.LODLevel

```gdscript
enum LODLevel {
    ULTRA = 0,    # 256x256 (< 100m distance)
    HIGH = 1,     # 128x128 (< 500m distance)
    MEDIUM = 2,   # 64x64 (< 2000m distance)
    LOW = 3,      # 32x32 (< 10000m distance)
    MINIMAL = 4   # 16x16 (> 10000m distance)
}
```

---

### PlanetGenerator.BiomeType

```gdscript
enum BiomeType {
    ICE,
    DESERT,
    FOREST,
    OCEAN,
    VOLCANIC,
    BARREN,
    TOXIC
}
```

---

### BiomeSystem.EnvironmentalEffect

```gdscript
enum EnvironmentalEffect {
    NONE,
    SNOW,
    RAIN,
    DUST_STORM,
    ASH_FALL,
    TOXIC_FOG,
    BLIZZARD,
    SANDSTORM
}
```

---

## Data Classes

### StarSystem

```gdscript
class StarSystem:
    var coordinates: Vector3i              # Sector coordinates
    var local_position: Vector3            # Position within sector
    var has_star: bool                     # Contains star
    var system_name: String                # Procedural name
    var star_type: String                  # "O"-"M"
    var star_mass: float                   # Solar masses
    var star_radius: float                 # Solar radii
    var star_temperature: float            # Kelvin
    var planets: Array[PlanetData]         # Orbiting planets
    var discovered: bool                   # Exploration flag

    func get_star_color() -> Color:        # Color based on temperature
```

---

### PlanetData

```gdscript
class PlanetData:
    var planet_name: String                # b, c, d, e, etc.
    var planet_type: PlanetType            # Terrestrial, Gas Giant, etc.
    var mass: float                        # Earth masses
    var radius: float                      # Earth radii
    var orbital_distance: float            # AU
    var eccentricity: float                # 0-0.3
    var inclination: float                 # radians
    var rotation_period: float             # hours
    var axial_tilt: float                  # radians
    var has_rings: bool                    # Ring presence
    var moon_count: int                    # Natural satellites

    func get_type_name() -> String:        # "Terrestrial", "Gas Giant", etc.
```

---

### Filament

```gdscript
class Filament:
    var start_system: StarSystem           # Origin system
    var end_system: StarSystem             # Destination system
    var length: float                      # Distance
    var density: float                     # 0.1-1.0

    func get_midpoint() -> Vector3:        # Filament center point
```

---

## Signals Reference

### UniverseGenerator

```gdscript
signal system_generated(system: StarSystem)
signal filaments_generated(filaments: Array[Filament])
```

### PlanetGenerator

```gdscript
signal heightmap_generated(heightmap: Image, planet_seed: int)
signal terrain_mesh_generated(mesh: ArrayMesh, lod_level: int)
signal normal_map_generated(normal_map: Image)
```

### BiomeSystem

```gdscript
signal biome_map_generated(biome_map: Image, planet_seed: int)
signal environmental_effect_changed(biome: BiomeType, effect: EnvironmentalEffect)
signal biome_determined(position: Vector2, biome: BiomeType)
```

---

## Constants Reference

### UniverseGenerator

```gdscript
const GOLDEN_RATIO: float = 1.618033988749
const GOLDEN_RATIO_INVERSE: float = 0.618033988749
const MIN_SYSTEM_SEPARATION: float = 100.0
const SECTOR_SIZE: float = 1000.0
const MAX_STARS_PER_SECTOR: int = 5
```

### PlanetGenerator

```gdscript
const DEFAULT_OCTAVES: int = 8
const DEFAULT_PERSISTENCE: float = 0.5
const DEFAULT_LACUNARITY: float = 2.0
const DEFAULT_FREQUENCY: float = 0.005
const DEFAULT_HEIGHT_SCALE: float = 50.0
const CRATER_PROBABILITY: float = 0.3
const MAX_CRATERS_PER_REGION: int = 5
```

### BiomeSystem

```gdscript
const BIOME_BLEND_DISTANCE: float = 0.05
const DEFAULT_BIOME_MAP_RESOLUTION: int = 256
```

---

## Common Patterns

### Pattern 1: Complete Universe Exploration

```gdscript
var universe = UniverseGenerator.new(seed)
var generator = PlanetGenerator.new()
var biome_system = BiomeSystem.new()

# Get nearby systems
var systems = universe.get_nearby_systems(player_pos, radius_sectors=2)

for system in systems:
    if not system.has_star:
        continue

    # Generate each planet
    for planet in system.planets:
        # Generate terrain
        var terrain = generator.generate_planet_terrain(
            hash(system.system_name + planet.planet_name),
            PlanetGenerator.LODLevel.MEDIUM
        )

        # Generate biomes
        biome_system.configure_planet(planet.orbital_distance)
        var biome_map = biome_system.generate_biome_map(
            hash(system.system_name + planet.planet_name),
            terrain["heightmap"]
        )

        # Display planet
        var node = create_planet_node(system, planet, terrain, biome_map)
```

### Pattern 2: Streaming LOD

```gdscript
var current_lod = PlanetGenerator.LODLevel.MEDIUM
var target_distance = player.global_position.distance_to(planet_pos)

while true:
    var new_lod = generator.get_lod_for_distance(target_distance)

    if new_lod != current_lod:
        # Update terrain detail
        var new_mesh = generator.generate_terrain_mesh(heightmap, new_lod)
        mesh_instance.mesh = new_mesh
        current_lod = new_lod

    await get_tree().process_frame
    target_distance = player.global_position.distance_to(planet_pos)
```

### Pattern 3: Dynamic Biome Effects

```gdscript
# Update effects as player moves
func _on_player_position_changed(pos: Vector3):
    var height = get_height_at_position(pos)
    var new_effect = biome_system.update_environmental_effect(
        planet_seed, pos.x, pos.y, height
    )

    # Effects automatically update via signal
```
