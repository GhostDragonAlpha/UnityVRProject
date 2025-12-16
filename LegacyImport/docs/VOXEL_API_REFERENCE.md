# Voxel Terrain System - API Reference

**Version:** 1.0.0
**Created:** 2025-12-03
**Status:** Phase 1 - Foundation
**Project:** SpaceTime VR - Planetary Survival System

---

## Table of Contents

1. [Overview](#overview)
2. [VoxelGeneratorProcedural API](#voxelgeneratorprocedural-api)
3. [TerrainNoiseGenerator API](#terrainnoisegenerator-api)
4. [VoxelPerformanceMonitor API](#voxelperformancemonitor-api)
5. [VoxelTerrain API](#voxelterrain-api)
6. [Integration with Existing Systems](#integration-with-existing-systems)
7. [Usage Examples](#usage-examples)
8. [Performance Tuning Guide](#performance-tuning-guide)
9. [Advanced Topics](#advanced-topics)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Voxel Terrain System provides procedural generation, modification, and rendering of deformable 3D terrain in SpaceTime VR. The system integrates with the existing `PlanetGenerator`, supports VR interaction, and maintains 90 FPS performance targets.

### Architecture Components

```
VoxelTerrain System
├── VoxelGeneratorProcedural    # Procedural terrain generation
├── TerrainNoiseGenerator       # Multi-layer noise configuration
├── VoxelPerformanceMonitor     # Performance tracking and optimization
├── VoxelTerrain                # Main terrain management (Zylann plugin)
├── VoxelChunk                  # Individual terrain chunks
└── TerrainTool                 # VR terrain modification tool
```

### Key Features

- **Procedural Generation**: Deterministic seed-based terrain with 3D noise
- **Deformable Terrain**: Excavate, elevate, and flatten operations
- **VR Performance**: Optimized for 90 FPS with LOD system
- **Resource Integration**: Embedded resource nodes in terrain
- **Physics Support**: Automatic collision generation
- **Multiplayer Ready**: Synchronizable terrain modifications

### Dependencies

- **Godot Engine**: 4.5.1+
- **godot_voxel Plugin**: v1.5+ by Zylann (GDExtension)
- **FastNoiseLite**: Built-in Godot noise library
- **ResonanceEngine**: Core engine coordinator
- **PlanetGenerator**: Procedural planet generation system

---

## VoxelGeneratorProcedural API

**Location:** `scripts/procedural/voxel_generator_procedural.gd`
**Extends:** `VoxelGeneratorScript` (from godot_voxel plugin)
**Class Name:** `VoxelGeneratorProcedural`

### Description

Custom procedural terrain generator that uses Signed Distance Field (SDF) approach with multi-octave noise for realistic planetary terrain. Supports both 2D heightmap generation and full 3D features (caves, overhangs).

### Signals

#### `chunk_generated(origin: Vector3i, lod: int)`

Emitted when terrain generation completes for a chunk.

**Parameters:**
- `origin` (Vector3i): World-space origin of the generated chunk
- `lod` (int): Level of detail (0 = highest detail)

**Example:**
```gdscript
generator.chunk_generated.connect(_on_chunk_generated)

func _on_chunk_generated(origin: Vector3i, lod: int):
    print("Chunk generated at ", origin, " with LOD ", lod)
```

---

### Properties

#### `terrain_noise: FastNoiseLite`

Reference to the primary noise generator for terrain base elevation.

**Type:** `FastNoiseLite`
**Access:** Read/Write
**Default:** Auto-initialized with TYPE_SIMPLEX_SMOOTH

**Configuration:**
- Noise Type: `FastNoiseLite.TYPE_SIMPLEX_SMOOTH`
- Fractal Type: `FastNoiseLite.FRACTAL_FBM`
- Octaves: Controlled by `noise_octaves` property
- Frequency: Controlled by `base_frequency` property

---

#### `detail_noise: FastNoiseLite`

Reference to secondary noise generator for fine surface detail.

**Type:** `FastNoiseLite`
**Access:** Read/Write
**Default:** Auto-initialized with TYPE_SIMPLEX_SMOOTH, FRACTAL_RIDGED

**Configuration:**
- Noise Type: `FastNoiseLite.TYPE_SIMPLEX_SMOOTH`
- Fractal Type: `FastNoiseLite.FRACTAL_RIDGED`
- Octaves: 4 (fixed)
- Frequency: 0.02 (fixed)

---

#### `cave_noise: FastNoiseLite`

Reference to 3D noise generator for cave and overhang generation.

**Type:** `FastNoiseLite`
**Access:** Read/Write
**Default:** Auto-initialized with TYPE_CELLULAR

**Configuration:**
- Noise Type: `FastNoiseLite.TYPE_CELLULAR`
- Fractal Type: `FastNoiseLite.FRACTAL_FBM`
- Octaves: 3 (fixed)
- Frequency: Controlled by `cave_frequency` property

---

#### `height_scale: float`

Height scale multiplier for terrain elevation. Controls the vertical amplitude of terrain features.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `50.0`
**Range:** `> 0.0` (recommended: 10.0 - 200.0)

**Usage:**
```gdscript
# Generate flat terrain
generator.height_scale = 10.0

# Generate mountainous terrain
generator.height_scale = 100.0

# Generate extreme peaks
generator.height_scale = 200.0
```

**Performance Impact:** Higher values increase terrain complexity but don't significantly affect generation time.

---

#### `base_height: float`

Y-coordinate offset for "sea level" or base terrain height.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `0.0`
**Range:** Any float value

**Usage:**
```gdscript
# Terrain at origin
generator.base_height = 0.0

# Elevated terrain (floating islands)
generator.base_height = 50.0

# Submerged terrain (ocean floor)
generator.base_height = -20.0
```

---

#### `terrain_seed: int`

Seed for deterministic terrain generation. Same seed always produces identical terrain.

**Type:** `int`
**Access:** Read/Write (Exported)
**Default:** `0`
**Range:** Any integer

**Setter Behavior:** Automatically updates all noise generator seeds when changed.

**Usage:**
```gdscript
# Generate specific planet terrain
generator.terrain_seed = 12345

# Random terrain each time
generator.terrain_seed = randi()

# Coordinate-based seed for infinite terrain
generator.terrain_seed = hash(planet_coordinates)
```

**Note:** Changing the seed triggers `_update_noise_seeds()` to ensure all noise generators are synchronized.

---

#### `noise_octaves: int`

Number of noise octaves for terrain generation. More octaves = more detail at finer scales.

**Type:** `int`
**Access:** Read/Write (Exported)
**Default:** `8`
**Range:** `1-16` (recommended: 6-10 for performance)

**Performance Impact:**
- 4 octaves: ~2ms per chunk
- 8 octaves: ~4ms per chunk
- 12 octaves: ~6ms per chunk
- 16 octaves: ~8ms per chunk

**Visual Impact:**
- Low (4-6): Smooth, rolling hills
- Medium (8-10): Realistic terrain with varied features
- High (12-16): Highly detailed, complex terrain

---

#### `noise_persistence: float`

Amplitude reduction per octave. Controls how quickly detail diminishes at higher frequencies.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `0.5`
**Range:** `0.1-1.0`

**Effect:**
- `0.2-0.3`: Smooth terrain, fine details barely visible
- `0.5`: Balanced detail distribution (default)
- `0.7-0.9`: High contrast, pronounced fine details

**Formula:** Each octave amplitude = previous amplitude × persistence

---

#### `noise_lacunarity: float`

Frequency multiplier per octave. Controls how quickly detail frequency increases.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `2.0`
**Range:** `1.0-4.0`

**Effect:**
- `1.5-2.0`: Natural, organic terrain
- `2.0-2.5`: Standard fractal terrain (default)
- `3.0-4.0`: Chaotic, highly varied terrain

**Formula:** Each octave frequency = previous frequency × lacunarity

---

#### `base_frequency: float`

Base noise frequency. Controls the scale of the largest terrain features.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `0.005`
**Range:** `0.0001-1.0`

**Effect:**
- `0.001-0.003`: Continental-scale features (large, gradual)
- `0.005-0.01`: Planetary terrain (balanced, default)
- `0.02-0.1`: Small-scale, rapid variation

**Relationship to Scale:**
- Lower frequency = larger features
- Higher frequency = smaller, more frequent features

---

#### `enable_3d_features: bool`

Enable 3D terrain features such as caves, overhangs, and volumetric detail.

**Type:** `bool`
**Access:** Read/Write (Exported)
**Default:** `false`

**Performance Impact:**
- Disabled: ~4ms per chunk
- Enabled: ~6-7ms per chunk

**Usage:**
```gdscript
# Enable for underground gameplay
generator.enable_3d_features = true

# Disable for VR performance
generator.enable_3d_features = false
```

**Note:** When enabled, uses `cave_noise` to carve out caves and create overhangs.

---

#### `cave_threshold: float`

Cave density threshold. Higher values = fewer, larger caves.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `0.6`
**Range:** `0.0-1.0`

**Effect:**
- `0.3-0.4`: Many small caves, Swiss cheese terrain
- `0.5-0.6`: Moderate cave density (default)
- `0.7-0.9`: Few large caverns

**Only Active:** When `enable_3d_features = true`

---

#### `cave_frequency: float`

Cave noise frequency multiplier. Controls cave size and distribution.

**Type:** `float`
**Access:** Read/Write (Exported)
**Default:** `0.02`
**Range:** `0.001-0.1`

**Effect:**
- `0.005-0.01`: Large, interconnected cave systems
- `0.02-0.03`: Medium caves (default)
- `0.05-0.1`: Small, scattered pockets

---

### Methods

#### `_init() -> void`

Constructor. Initializes noise generators with default settings.

**Called:** Automatically when creating instance via `.new()`

**Behavior:**
1. Calls `_initialize_noise_generators()`
2. Sets up terrain_noise, detail_noise, cave_noise
3. Applies initial seed values

**Example:**
```gdscript
var generator = VoxelGeneratorProcedural.new()
# Noise generators now initialized and ready
```

---

#### `_initialize_noise_generators() -> void`

Internal method to initialize all noise generators with default configurations.

**Access:** Private
**Called By:** `_init()`

**Behavior:**
1. Creates `FastNoiseLite` instance for `terrain_noise`
   - Sets noise type to SIMPLEX_SMOOTH
   - Configures FBM fractal with exported octaves
   - Applies base frequency
2. Creates `FastNoiseLite` instance for `detail_noise`
   - Sets noise type to SIMPLEX_SMOOTH
   - Configures RIDGED fractal with 4 octaves
   - Sets frequency to 0.02
3. Creates `FastNoiseLite` instance for `cave_noise`
   - Sets noise type to CELLULAR
   - Configures FBM fractal with 3 octaves
   - Applies cave frequency
4. Calls `_update_noise_seeds()`

**Example Override:**
```gdscript
# Custom initialization if needed
func _initialize_noise_generators() -> void:
    super._initialize_noise_generators()

    # Add custom noise layer
    custom_noise = FastNoiseLite.new()
    custom_noise.noise_type = FastNoiseLite.TYPE_PERLIN
```

---

#### `_update_noise_seeds() -> void`

Internal method to synchronize all noise generator seeds with `terrain_seed`.

**Access:** Private
**Called By:** `_init()`, `terrain_seed` setter

**Behavior:**
1. Sets `terrain_noise.seed = terrain_seed`
2. Sets `detail_noise.seed = terrain_seed + 12345`
3. Sets `cave_noise.seed = terrain_seed + 67890`

**Seed Offsets:** Different offsets ensure each noise layer is decorrelated.

---

#### `_generate_block(buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void`

Main generation function called by VoxelTerrain. Implements the `VoxelGeneratorScript` interface.

**Access:** Private (Called by godot_voxel plugin)
**Parameters:**
- `buffer` (VoxelBuffer): Voxel buffer to fill with SDF values
- `origin` (Vector3i): World-space origin of the chunk
- `lod` (int): Level of detail (0 = highest)

**Behavior:**
1. Gets buffer size (typically 32×32×32 voxels)
2. Iterates through all voxel positions (x, y, z)
3. Calculates world position for each voxel
4. Calls `_calculate_sdf()` to get SDF value
5. Writes SDF value to buffer at CHANNEL_SDF
6. Emits `chunk_generated` signal when complete

**Performance:** This is the most performance-critical function. Optimizations:
- Inner loop over Y for cache coherency
- SDF calculation inlined where possible
- Minimal branching in hot path

**Example (Internal):**
```gdscript
# Called automatically by VoxelTerrain
func _generate_block(buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
    var size := buffer.get_size()
    var channel := VoxelBuffer.CHANNEL_SDF

    for z in range(size.z):
        for x in range(size.x):
            for y in range(size.y):
                var world_pos := Vector3(
                    origin.x + x,
                    origin.y + y,
                    origin.z + z
                )

                var sdf_value := _calculate_sdf(world_pos)
                buffer.set_voxel_f(sdf_value, x, y, z, channel)

    chunk_generated.emit(origin, lod)
```

---

#### `_calculate_sdf(world_pos: Vector3) -> float`

Calculate Signed Distance Field value at a world position.

**Access:** Private
**Parameters:**
- `world_pos` (Vector3): World-space position to sample

**Returns:** `float` - SDF value (negative = air, positive = solid)

**Algorithm:**
1. Sample terrain height at XZ position via `_sample_terrain_height()`
2. Calculate base SDF: `height - world_pos.y`
3. If `enable_3d_features`:
   - Sample 3D cave noise
   - Normalize to [0, 1]
   - If above `cave_threshold`, carve cave (force SDF negative)
4. Return final SDF value

**SDF Convention:**
- `SDF < 0`: Air (empty space)
- `SDF = 0`: Surface boundary
- `SDF > 0`: Solid terrain

**Example:**
```gdscript
# Sample terrain at player position
var player_pos = player.global_position
var sdf = generator._calculate_sdf(player_pos)

if sdf > 0:
    print("Player is underground")
elif sdf < 0:
    print("Player is in air")
else:
    print("Player is on surface")
```

---

#### `_sample_terrain_height(x: float, z: float) -> float`

Sample terrain height at a given XZ position.

**Access:** Private
**Parameters:**
- `x` (float): World X coordinate
- `z` (float): World Z coordinate

**Returns:** `float` - Terrain height (Y coordinate) at this position

**Algorithm:**
1. Sample `terrain_noise.get_noise_2d(x, z)` → range [-1, 1]
2. Normalize to [0, 1]: `(value + 1) * 0.5`
3. Scale by `height_scale`
4. Sample `detail_noise.get_noise_2d(x, z)` → add fine detail
5. Scale detail by `height_scale * 0.1`
6. Add `base_height` offset
7. Return final height

**Example:**
```gdscript
# Query terrain height at specific coordinates
var height = generator._sample_terrain_height(100, 200)
print("Terrain height at (100, 200): ", height)

# Find safe landing position
var landing_height = generator._sample_terrain_height(
    landing_zone.x,
    landing_zone.z
)
spawn_player_at(Vector3(landing_zone.x, landing_height + 2, landing_zone.z))
```

---

#### `configure_noise(octaves: int, persistence: float, lacunarity: float, frequency: float) -> void`

Configure noise parameters (called from PlanetGenerator integration).

**Access:** Public
**Parameters:**
- `octaves` (int): Number of noise octaves (1-16)
- `persistence` (float): Amplitude reduction per octave (0.1-1.0)
- `lacunarity` (float): Frequency multiplier per octave (1.0-4.0)
- `frequency` (float): Base noise frequency (0.0001-1.0)

**Behavior:**
1. Sets exported properties
2. Updates `terrain_noise` generator configuration
3. Does NOT update detail_noise or cave_noise (they use fixed settings)

**Example:**
```gdscript
# Configure for Earth-like terrain
generator.configure_noise(
    8,      # octaves
    0.5,    # persistence
    2.0,    # lacunarity
    0.005   # frequency
)

# Configure for alien moon terrain
generator.configure_noise(
    12,     # more detail
    0.7,    # higher persistence
    2.5,    # more frequency variation
    0.01    # smaller scale features
)
```

---

#### `configure_3d_features(enabled: bool, threshold: float, frequency: float) -> void`

Configure 3D terrain features (caves, overhangs).

**Access:** Public
**Parameters:**
- `enabled` (bool): Enable/disable 3D features
- `threshold` (float): Cave density threshold (0.0-1.0)
- `frequency` (float): Cave noise frequency

**Behavior:**
1. Sets `enable_3d_features`
2. Clamps `threshold` to [0.0, 1.0]
3. Sets `cave_frequency`
4. Updates `cave_noise.frequency` if noise generator exists

**Example:**
```gdscript
# Enable moderate cave systems
generator.configure_3d_features(true, 0.6, 0.02)

# Disable caves for performance
generator.configure_3d_features(false, 0.0, 0.0)

# Dense cave network
generator.configure_3d_features(true, 0.4, 0.03)
```

---

#### `get_configuration() -> Dictionary`

Get current configuration as dictionary for serialization or inspection.

**Access:** Public
**Returns:** `Dictionary` - Current configuration values

**Dictionary Keys:**
- `terrain_seed` (int)
- `height_scale` (float)
- `base_height` (float)
- `noise_octaves` (int)
- `noise_persistence` (float)
- `noise_lacunarity` (float)
- `base_frequency` (float)

**Example:**
```gdscript
# Save configuration to file
var config = generator.get_configuration()
var file = FileAccess.open("res://terrain_config.json", FileAccess.WRITE)
file.store_string(JSON.stringify(config, "  "))
file.close()

# Copy configuration to another generator
var config = generator_a.get_configuration()
generator_b.configure_noise(
    config["noise_octaves"],
    config["noise_persistence"],
    config["noise_lacunarity"],
    config["base_frequency"]
)
generator_b.height_scale = config["height_scale"]
generator_b.terrain_seed = config["terrain_seed"]
```

---

### Usage Examples

#### Basic Terrain Generation

```gdscript
# Create and configure generator
var generator = VoxelGeneratorProcedural.new()
generator.terrain_seed = 12345
generator.height_scale = 50.0
generator.noise_octaves = 8

# Create VoxelTerrain node
var terrain = ClassDB.instantiate("VoxelTerrain")
add_child(terrain)

# Assign generator and enable features
terrain.set_generator(generator)
terrain.set_generate_collisions(true)
terrain.set_view_distance(128)
terrain.collision_layer = 1

# Position camera to view terrain
var camera = Camera3D.new()
camera.position = Vector3(0, 100, 100)
camera.look_at(Vector3.ZERO)
add_child(camera)
```

#### Cave System Generation

```gdscript
# Create generator with caves
var generator = VoxelGeneratorProcedural.new()
generator.terrain_seed = 98765
generator.height_scale = 80.0

# Enable 3D features
generator.enable_3d_features = true
generator.cave_threshold = 0.55  # Moderate cave density
generator.cave_frequency = 0.025

# Create terrain
var terrain = ClassDB.instantiate("VoxelTerrain")
terrain.set_generator(generator)
add_child(terrain)
```

#### Dynamic Configuration

```gdscript
# Create generator
var generator = VoxelGeneratorProcedural.new()

# Connect to chunk generation signal
generator.chunk_generated.connect(_on_chunk_generated)

# Configure based on player distance
func _process(delta):
    var player_distance = player.global_position.length()

    if player_distance < 100:
        # High detail near player
        generator.configure_noise(10, 0.6, 2.0, 0.008)
    else:
        # Lower detail far from player
        generator.configure_noise(6, 0.5, 2.0, 0.005)

func _on_chunk_generated(origin: Vector3i, lod: int):
    print("Generated chunk at ", origin)
```

#### Biome-Based Terrain

```gdscript
# Different generators for different biomes
var desert_generator = VoxelGeneratorProcedural.new()
desert_generator.height_scale = 30.0  # Flatter terrain
desert_generator.noise_octaves = 6

var mountain_generator = VoxelGeneratorProcedural.new()
mountain_generator.height_scale = 150.0  # Tall peaks
mountain_generator.noise_octaves = 12

# Switch based on biome
func apply_biome(biome_type: String):
    match biome_type:
        "desert":
            terrain.set_generator(desert_generator)
        "mountain":
            terrain.set_generator(mountain_generator)
```

---

## TerrainNoiseGenerator API

**Location:** `scripts/procedural/terrain_noise_generator.gd`
**Class Name:** `TerrainNoiseGenerator`
**Status:** Design Phase (See VOXEL_PHASE_1_TASKS.md)

### Description

Multi-layer noise configuration system for complex terrain generation. Supports noise layer blending, biome-based variation, and performance optimization through layer toggling.

**Note:** This is a planned component based on the design specifications. Current implementation uses `VoxelGeneratorProcedural` with integrated noise handling.

### Planned Architecture

```gdscript
class_name TerrainNoiseGenerator
extends Resource

## Noise layer configuration
class NoiseLayer:
    var noise: FastNoiseLite
    var weight: float
    var enabled: bool
    var blend_mode: BlendMode  # ADD, MULTIPLY, MIN, MAX

enum BlendMode {
    ADD,        # Additive blending
    MULTIPLY,   # Multiplicative blending
    MIN,        # Take minimum value
    MAX         # Take maximum value
}

## Noise layers for terrain generation
var layers: Array[NoiseLayer] = []

## Biome configuration
var biome_noise: FastNoiseLite
var biome_map: Dictionary  # biome_id -> NoiseLayer adjustments

## Methods
func add_layer(noise: FastNoiseLite, weight: float, blend: BlendMode) -> NoiseLayer
func remove_layer(layer: NoiseLayer) -> void
func sample_height(x: float, z: float) -> float
func sample_with_biome(x: float, z: float, biome_id: int) -> float
func configure_biome(biome_id: int, config: Dictionary) -> void
```

### Noise Layer Configuration

#### Layer Types

**Base Layer** - Primary terrain shape
```gdscript
var base = NoiseLayer.new()
base.noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
base.noise.fractal_octaves = 6
base.weight = 1.0
base.blend_mode = BlendMode.ADD
```

**Detail Layer** - Surface variation
```gdscript
var detail = NoiseLayer.new()
detail.noise.noise_type = FastNoiseLite.TYPE_PERLIN
detail.noise.fractal_octaves = 4
detail.noise.frequency = 0.05
detail.weight = 0.2
detail.blend_mode = BlendMode.ADD
```

**Ridge Layer** - Mountain ridges
```gdscript
var ridges = NoiseLayer.new()
ridges.noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
ridges.noise.fractal_octaves = 8
ridges.weight = 0.8
ridges.blend_mode = BlendMode.MAX
```

**Erosion Layer** - Valleys and drainage
```gdscript
var erosion = NoiseLayer.new()
erosion.noise.noise_type = FastNoiseLite.TYPE_CELLULAR
erosion.weight = 0.3
erosion.blend_mode = BlendMode.MIN
```

### Biome Integration

#### Biome Noise Configuration

```gdscript
# Setup biome selector
var biome_noise = FastNoiseLite.new()
biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
biome_noise.frequency = 0.002  # Large biome regions

# Map noise values to biomes
# -1.0 to -0.5: ICE
# -0.5 to 0.0:  FOREST
#  0.0 to 0.5:  DESERT
#  0.5 to 1.0:  VOLCANIC

func get_biome_at(x: float, z: float) -> BiomeType:
    var value = biome_noise.get_noise_2d(x, z)

    if value < -0.5:
        return BiomeType.ICE
    elif value < 0.0:
        return BiomeType.FOREST
    elif value < 0.5:
        return BiomeType.DESERT
    else:
        return BiomeType.VOLCANIC
```

#### Biome-Specific Adjustments

```gdscript
# Configure desert biome (flatter, dune-like)
var desert_config = {
    "base_amplitude": 0.6,      # Reduce height variation
    "detail_octaves": 4,         # Less detail
    "ridge_weight": 0.0          # No ridges
}
terrain_noise.configure_biome(BiomeType.DESERT, desert_config)

# Configure mountain biome (taller, more rugged)
var mountain_config = {
    "base_amplitude": 1.5,       # Increase height
    "detail_octaves": 10,        # More detail
    "ridge_weight": 1.2          # Emphasize ridges
}
terrain_noise.configure_biome(BiomeType.VOLCANIC, mountain_config)
```

### Performance Considerations

#### Layer Performance Impact

| Layers | Generation Time | Visual Quality | Recommended For |
|--------|----------------|----------------|-----------------|
| 1-2    | ~2ms/chunk     | Low            | Distant terrain |
| 3-4    | ~4ms/chunk     | Medium         | VR default      |
| 5-6    | ~6ms/chunk     | High           | Desktop/close   |
| 7+     | ~8ms+/chunk    | Ultra          | Screenshots     |

#### Optimization Strategies

**LOD-Based Layer Toggling**
```gdscript
func set_lod_level(lod: int):
    match lod:
        0:  # Ultra - All layers
            for layer in layers:
                layer.enabled = true
        1:  # High - Skip erosion
            erosion_layer.enabled = false
        2:  # Medium - Base + detail only
            for layer in layers:
                layer.enabled = false
            base_layer.enabled = true
            detail_layer.enabled = true
        3:  # Low - Base only
            for layer in layers:
                layer.enabled = false
            base_layer.enabled = true
```

**Dynamic Layer Adjustment**
```gdscript
func _process(delta):
    var fps = Engine.get_frames_per_second()

    if fps < 80:
        # Reduce quality
        disable_expensive_layers()
    elif fps > 95:
        # Increase quality
        enable_more_layers()
```

**Chunk Caching**
```gdscript
var height_cache: Dictionary = {}

func sample_height_cached(x: float, z: float) -> float:
    var key = Vector2i(int(x), int(z))

    if key in height_cache:
        return height_cache[key]

    var height = sample_height(x, z)
    height_cache[key] = height

    return height
```

### Usage Examples

#### Multi-Layer Terrain

```gdscript
var noise_gen = TerrainNoiseGenerator.new()

# Add base terrain
var base = noise_gen.add_layer(
    create_noise(TYPE_SIMPLEX_SMOOTH, 6, 0.005),
    1.0,
    BlendMode.ADD
)

# Add detail
var detail = noise_gen.add_layer(
    create_noise(TYPE_PERLIN, 4, 0.02),
    0.2,
    BlendMode.ADD
)

# Add ridges
var ridges = noise_gen.add_layer(
    create_ridged_noise(8, 0.01),
    0.5,
    BlendMode.MAX
)

# Sample height
var height = noise_gen.sample_height(100, 200)
```

#### Biome-Based Generation

```gdscript
var noise_gen = TerrainNoiseGenerator.new()

# Setup biome noise
noise_gen.biome_noise = FastNoiseLite.new()
noise_gen.biome_noise.frequency = 0.002

# Sample with biome
var biome_id = noise_gen.get_biome_at(x, z)
var height = noise_gen.sample_with_biome(x, z, biome_id)
```

---

## VoxelPerformanceMonitor API

**Location:** `scripts/rendering/voxel_performance_monitor.gd`
**Class Name:** `VoxelPerformanceMonitor`
**Status:** Design Phase (Extends PerformanceOptimizer)

### Description

Specialized performance monitoring and optimization for voxel terrain systems. Tracks chunk generation time, mesh update performance, collision generation, and provides automatic quality adjustment.

**Note:** Current implementation uses the general `PerformanceOptimizer` class. This is a planned specialization for voxel-specific metrics.

### Planned Architecture

```gdscript
class_name VoxelPerformanceMonitor
extends PerformanceOptimizer

## Voxel-specific metrics
var chunk_generation_times: Array[float] = []
var mesh_update_times: Array[float] = []
var collision_generation_times: Array[float] = []

## Current statistics
var active_chunks: int = 0
var visible_chunks: int = 0
var generating_chunks: int = 0

## Performance targets
const MAX_CHUNK_GEN_TIME_MS: float = 5.0
const MAX_MESH_UPDATE_TIME_MS: float = 3.0
const MAX_CHUNKS_PER_FRAME: int = 4

## Methods
func track_chunk_generation(duration_ms: float) -> void
func track_mesh_update(duration_ms: float) -> void
func track_collision_generation(duration_ms: float) -> void
func get_voxel_statistics() -> Dictionary
func adjust_voxel_quality() -> void
```

### Available Metrics

#### Core Metrics

**Chunk Generation Performance**
- `avg_chunk_gen_time_ms`: Average time to generate chunk SDF data
- `max_chunk_gen_time_ms`: Maximum chunk generation time observed
- `chunks_generated_per_second`: Throughput metric
- `chunk_gen_budget_exceeded`: Number of times budget was exceeded

**Mesh Generation Performance**
- `avg_mesh_update_time_ms`: Average time to generate mesh from SDF
- `max_mesh_update_time_ms`: Maximum mesh update time observed
- `meshes_updated_per_second`: Mesh update throughput
- `mesh_update_budget_exceeded`: Times budget was exceeded

**Collision Performance**
- `avg_collision_gen_time_ms`: Average collision shape generation time
- `collision_updates_per_second`: Collision update throughput
- `collision_cache_hits`: Number of cached collision reuses

**Memory Metrics**
- `total_voxel_memory_mb`: Total memory used by voxel data
- `chunk_cache_size`: Number of chunks in memory
- `mesh_cache_size`: Number of meshes cached
- `collision_cache_size`: Number of collision shapes cached

#### Live Statistics

**Chunk Status**
- `active_chunks`: Total chunks in memory
- `visible_chunks`: Chunks currently visible
- `generating_chunks`: Chunks currently being generated
- `queued_chunks`: Chunks waiting for generation

**Frame Budget**
- `voxel_time_ms`: Total time spent on voxel operations this frame
- `voxel_budget_remaining_ms`: Remaining budget for voxel work
- `budget_utilization_percent`: Percentage of budget used

### How to Access Stats

#### Real-Time Monitoring

```gdscript
# Get reference to monitor
var voxel_monitor = get_node("/root/ResonanceEngine/VoxelPerformanceMonitor")

# Read current stats
func _process(delta):
    var stats = voxel_monitor.get_voxel_statistics()

    print("Active chunks: ", stats["active_chunks"])
    print("Avg gen time: ", stats["avg_chunk_gen_time_ms"], "ms")
    print("FPS: ", Engine.get_frames_per_second())
```

#### Statistics Signals

```gdscript
# Connect to performance signals
voxel_monitor.chunk_generation_slow.connect(_on_slow_generation)
voxel_monitor.memory_warning.connect(_on_memory_warning)

func _on_slow_generation(duration_ms: float):
    print("Slow chunk generation detected: ", duration_ms, "ms")
    # Reduce view distance or quality

func _on_memory_warning(memory_mb: float):
    print("High memory usage: ", memory_mb, "MB")
    # Clear old chunks
```

#### HTTP API Access

```gdscript
# GET /performance/voxel endpoint (planned)
# Returns JSON with all voxel metrics

# Example response:
{
    "chunk_generation": {
        "avg_time_ms": 3.2,
        "max_time_ms": 7.8,
        "per_second": 15.5,
        "budget_exceeded": 3
    },
    "chunks": {
        "active": 128,
        "visible": 64,
        "generating": 4,
        "queued": 12
    },
    "memory": {
        "total_mb": 256.5,
        "chunk_cache": 128,
        "mesh_cache": 64
    },
    "performance": {
        "fps": 89.3,
        "voxel_time_ms": 2.1,
        "budget_remaining_ms": 9.0
    }
}
```

### Performance Tuning Tips

#### Optimize Chunk Generation

**1. Reduce Noise Octaves**
```gdscript
# Before: 12 octaves, ~6ms per chunk
generator.noise_octaves = 12

# After: 8 octaves, ~4ms per chunk
generator.noise_octaves = 8
```

**2. Disable 3D Features**
```gdscript
# Before: Caves enabled, ~7ms per chunk
generator.enable_3d_features = true

# After: Heightmap only, ~4ms per chunk
generator.enable_3d_features = false
```

**3. Adjust View Distance**
```gdscript
# Before: Large view distance
terrain.set_view_distance(256)  # 256 voxels = many chunks

# After: Reduced for VR
terrain.set_view_distance(128)  # Fewer active chunks
```

#### Optimize Mesh Updates

**1. Reduce Mesh LOD Distances**
```gdscript
# Configure LOD transitions
terrain.set_lod_count(4)
terrain.set_lod_distance(0, 32)   # Highest detail nearby
terrain.set_lod_distance(1, 64)
terrain.set_lod_distance(2, 128)
terrain.set_lod_distance(3, 256)  # Lowest detail far away
```

**2. Batch Terrain Modifications**
```gdscript
# Bad: Many small modifications (causes many mesh updates)
for i in 100:
    terrain.set_voxel_density(pos + Vector3(i, 0, 0), 0.0)

# Good: One large modification (single mesh update)
terrain.begin_batch_modifications()
for i in 100:
    terrain.set_voxel_density(pos + Vector3(i, 0, 0), 0.0)
terrain.end_batch_modifications()
```

**3. Defer Non-Critical Updates**
```gdscript
# Prioritize visible chunk updates
func update_chunks():
    var visible = get_visible_chunks()
    var non_visible = get_non_visible_chunks()

    # Update visible first
    for chunk in visible:
        chunk.update_mesh()

    # Update non-visible in background
    for chunk in non_visible:
        chunk.queue_mesh_update()  # Deferred, low priority
```

#### Optimize Memory Usage

**1. Configure Chunk Cache**
```gdscript
# Limit active chunks in memory
terrain.set_full_load_mode_enabled(false)
terrain.set_streaming_enabled(true)

# Set max cache size
terrain.set_max_chunk_cache_size(512)  # Max chunks in memory
```

**2. Enable Mesh Compression**
```gdscript
# Reduce mesh memory footprint
terrain.set_mesh_compression_enabled(true)
```

**3. Clear Old Chunks**
```gdscript
# Periodically clear distant chunks
func _on_memory_warning():
    var player_pos = player.global_position
    terrain.clear_chunks_outside_radius(player_pos, 200.0)
```

#### Monitor and React

**Dynamic Quality Adjustment**
```gdscript
func _process(delta):
    var stats = voxel_monitor.get_voxel_statistics()

    # Check if we're over budget
    if stats["avg_chunk_gen_time_ms"] > 5.0:
        # Reduce quality
        generator.noise_octaves = max(4, generator.noise_octaves - 1)
        print("Reduced noise octaves to ", generator.noise_octaves)

    # Check memory usage
    if stats["total_voxel_memory_mb"] > 500.0:
        # Reduce view distance
        var current = terrain.get_view_distance()
        terrain.set_view_distance(max(64, current - 16))
        print("Reduced view distance to ", terrain.get_view_distance())
```

**Profiling Integration**
```gdscript
# Track custom operations
var start_time = Time.get_ticks_usec()

# ... terrain modification code ...

var duration_ms = (Time.get_ticks_usec() - start_time) / 1000.0
voxel_monitor.track_custom_operation("terrain_excavation", duration_ms)
```

### Usage Examples

#### Basic Monitoring

```gdscript
extends Node3D

var voxel_monitor: VoxelPerformanceMonitor

func _ready():
    # Get monitor reference
    voxel_monitor = VoxelPerformanceMonitor.new()
    add_child(voxel_monitor)

    # Connect signals
    voxel_monitor.statistics_updated.connect(_on_stats_updated)

func _on_stats_updated(stats: Dictionary):
    # Display in debug UI
    $DebugLabel.text = "Chunks: %d\nGen Time: %.1fms" % [
        stats["active_chunks"],
        stats["avg_chunk_gen_time_ms"]
    ]
```

#### Automatic Optimization

```gdscript
var voxel_monitor: VoxelPerformanceMonitor
var terrain: VoxelTerrain

func _ready():
    voxel_monitor = get_node("VoxelPerformanceMonitor")
    voxel_monitor.auto_optimization_enabled = true

    # Set optimization thresholds
    voxel_monitor.target_fps = 90.0
    voxel_monitor.max_chunk_gen_time_ms = 5.0

func _process(delta):
    # Monitor automatically adjusts quality
    voxel_monitor.update_optimization(terrain, delta)
```

---

## VoxelTerrain API

**Location:** Native class from godot_voxel GDExtension
**Class Name:** `VoxelTerrain`
**Inherits:** `Node3D`

### Description

Main voxel terrain node from the Zylann godot_voxel plugin. Manages chunk streaming, LOD, mesh generation, and collision. This is the core node that developers interact with.

**Documentation:** See [godot_voxel official docs](https://voxel-tools.readthedocs.io/)

### Key Properties

#### `generator: VoxelGenerator`

The voxel generator used to create terrain data.

**Type:** `VoxelGenerator` (or any class extending `VoxelGeneratorScript`)
**Default:** `null`

**Usage:**
```gdscript
var terrain = ClassDB.instantiate("VoxelTerrain")
var generator = VoxelGeneratorProcedural.new()
terrain.set_generator(generator)
```

---

#### `view_distance: int`

Maximum distance (in voxels) from viewer where chunks will be loaded.

**Type:** `int`
**Default:** `128`
**Range:** `16-1024`

**Performance Impact:**
- 64: ~50 active chunks, minimal memory
- 128: ~200 active chunks, balanced
- 256: ~800 active chunks, high memory
- 512: ~3200 active chunks, very high memory

**VR Recommendation:** 128-256 for acceptable performance

---

#### `generate_collisions: bool`

Whether to generate collision shapes for terrain.

**Type:** `bool`
**Default:** `false`

**Note:** Enable for player physics interaction. Disabling improves performance but prevents physical interaction.

---

#### `collision_layer: int`

Physics layer for terrain collision.

**Type:** `int` (bitmask)
**Default:** `1`

**Usage:**
```gdscript
terrain.collision_layer = 1  # Layer 1
terrain.collision_mask = 0   # Doesn't detect anything
```

---

#### `lod_count: int`

Number of Level of Detail (LOD) levels.

**Type:** `int`
**Default:** `4`
**Range:** `1-8`

**Levels:**
- LOD 0: Full detail (closest)
- LOD 1: Half resolution
- LOD 2: Quarter resolution
- LOD 3+: Increasingly reduced detail

---

### Key Methods

#### `set_generator(generator: VoxelGenerator) -> void`

Assign voxel generator to terrain.

**Parameters:**
- `generator`: VoxelGenerator or VoxelGeneratorScript instance

---

#### `set_view_distance(distance: int) -> void`

Set chunk loading distance.

**Parameters:**
- `distance`: Distance in voxels

---

#### `set_generate_collisions(enabled: bool) -> void`

Enable/disable collision generation.

**Parameters:**
- `enabled`: Whether to generate collisions

---

#### `set_lod_distance(lod_index: int, distance: int) -> void`

Set distance for LOD transition.

**Parameters:**
- `lod_index`: LOD level (0-7)
- `distance`: Distance in voxels where this LOD activates

**Example:**
```gdscript
terrain.set_lod_count(4)
terrain.set_lod_distance(0, 32)
terrain.set_lod_distance(1, 64)
terrain.set_lod_distance(2, 128)
terrain.set_lod_distance(3, 256)
```

---

#### `get_voxel_tool() -> VoxelTool`

Get tool for terrain modification.

**Returns:** `VoxelTool` for runtime editing

**Example:**
```gdscript
var voxel_tool = terrain.get_voxel_tool()
voxel_tool.mode = VoxelTool.MODE_REMOVE
voxel_tool.do_sphere(player_position, 5.0)
```

---

### Integration Wrapper (SpaceTime)

**Location:** `scripts/planetary_survival/voxel/voxel_terrain.gd`
**Class Name:** `StubVoxelTerrain`

Wrapper class for project-specific voxel terrain functionality. Currently a stub but will provide:

```gdscript
class_name StubVoxelTerrain
extends Node3D

## Get voxel density at world position
func get_voxel_density(pos: Vector3) -> float:
    # Query native VoxelTerrain via tool
    var voxel_tool = terrain.get_voxel_tool()
    return voxel_tool.get_voxel_f(pos)

## Set voxel density (runtime modification)
func set_voxel_density(pos: Vector3, density: float) -> void:
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.set_voxel_f(pos, density)

## Get voxel type/material
func get_voxel_type(pos: Vector3) -> int:
    var voxel_tool = terrain.get_voxel_tool()
    return voxel_tool.get_voxel(pos)

## Set voxel type/material
func set_voxel_type(pos: Vector3, type: int) -> void:
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.set_voxel(pos, type)
```

---

## Integration with Existing Systems

### PlanetGenerator Integration

**Location:** `scripts/procedural/planet_generator.gd`

#### Overview

`PlanetGenerator` now supports both mesh-based and voxel-based terrain generation. Use `use_voxel_terrain` flag to toggle between modes.

#### Configuration

```gdscript
var planet_gen = PlanetGenerator.new()
planet_gen.use_voxel_terrain = true  # Enable voxel mode

# Noise parameters apply to both mesh and voxel
planet_gen.noise_octaves = 8
planet_gen.noise_persistence = 0.5
planet_gen.base_frequency = 0.005
planet_gen.height_scale = 50.0
```

#### Methods

##### `generate_voxel_terrain(planet_seed: int, lod_level: LODLevel = LODLevel.MEDIUM) -> Node3D`

Generate VoxelTerrain node for a planet.

**Parameters:**
- `planet_seed`: Seed for deterministic generation
- `lod_level`: Quality level (affects view_distance)

**Returns:** `VoxelTerrain` node (via ClassDB.instantiate)

**Example:**
```gdscript
var planet_gen = PlanetGenerator.new()
add_child(planet_gen)

# Generate voxel terrain
var terrain = planet_gen.generate_voxel_terrain(
    12345,  # seed
    PlanetGenerator.LODLevel.MEDIUM
)

add_child(terrain)
terrain.global_position = Vector3(0, 0, 0)
```

**LOD View Distances:**
- `LODLevel.ULTRA`: 512 voxels
- `LODLevel.HIGH`: 256 voxels
- `LODLevel.MEDIUM`: 128 voxels
- `LODLevel.LOW`: 64 voxels
- `LODLevel.MINIMAL`: 32 voxels

---

##### `generate_planet_terrain(planet_seed: int, lod_level: LODLevel, temperature: float, moisture: float) -> Dictionary`

Generate complete terrain package (mesh or voxel based on `use_voxel_terrain`).

**Parameters:**
- `planet_seed`: Planet seed
- `lod_level`: Detail level
- `temperature`: Biome temperature (0.0-1.0)
- `moisture`: Biome moisture (0.0-1.0)

**Returns:** Dictionary with:
- `terrain_node`: Node3D (Mesh or VoxelTerrain)
- `terrain_type`: "mesh" or "voxel"
- `lod_level`: LOD level used
- `planet_seed`: Seed used

**Example:**
```gdscript
var planet_gen = PlanetGenerator.new()
planet_gen.use_voxel_terrain = true

var result = planet_gen.generate_planet_terrain(
    12345,
    PlanetGenerator.LODLevel.HIGH,
    0.7,  # Hot
    0.3   # Dry (desert-like)
)

print("Terrain type: ", result["terrain_type"])  # "voxel"
add_child(result["terrain_node"])
```

---

#### Noise Synchronization

Both mesh and voxel generators use the same noise configuration:

```gdscript
# Configure PlanetGenerator
planet_gen.noise_octaves = 10
planet_gen.noise_persistence = 0.6
planet_gen.noise_lacunarity = 2.2
planet_gen.base_frequency = 0.008
planet_gen.height_scale = 75.0

# Internal: Automatically copied to VoxelGeneratorProcedural
# generator.configure_noise(
#     planet_gen.noise_octaves,
#     planet_gen.noise_persistence,
#     planet_gen.noise_lacunarity,
#     planet_gen.base_frequency
# )
# generator.height_scale = planet_gen.height_scale
```

This ensures consistent terrain features whether using mesh or voxel generation.

---

### Player Physics Interaction

**Location:** `scripts/player/` (various controllers)

#### WalkingController Integration

```gdscript
# WalkingController automatically detects voxel terrain collision
class_name WalkingController
extends CharacterBody3D

func _physics_process(delta):
    # Standard CharacterBody3D physics
    move_and_slide()

    # Automatically collides with VoxelTerrain
    # if terrain.collision_layer & collision_mask != 0
```

#### Configuration

```gdscript
# Setup player collision
player.collision_mask = 1  # Detect layer 1
player.collision_layer = 2  # Player on layer 2

# Setup terrain collision
terrain.collision_layer = 1  # Terrain on layer 1
terrain.collision_mask = 0   # Terrain passive
terrain.set_generate_collisions(true)
```

#### Terrain Raycasting

```gdscript
# Raycast to find terrain surface
var space_state = get_world_3d().direct_space_state
var query = PhysicsRayQueryParameters3D.create(
    start_position,
    end_position
)
query.collision_mask = 1  # Terrain layer

var result = space_state.intersect_ray(query)
if result:
    var hit_position = result["position"]
    var hit_normal = result["normal"]
    # Position player on terrain
    player.global_position = hit_position + hit_normal * 2.0
```

---

### Resource Node Embedding

**Location:** `scripts/planetary_survival/core/resource_node.gd`

#### Overview

Resource nodes can be embedded in voxel terrain during generation or placed dynamically.

#### ResourceNode Class

```gdscript
class_name ResourceNode
extends Resource

var resource_type: String = ""      # "iron", "copper", "uranium"
var position: Vector3 = Vector3.ZERO
var quantity: int = 0
var is_depleted: bool = false

func extract(amount: int) -> int:
    var extracted = min(amount, quantity)
    quantity -= extracted
    if quantity <= 0:
        is_depleted = true
    return extracted
```

#### Embedding During Generation

**Option 1: Modify Generator**

```gdscript
# Extend VoxelGeneratorProcedural
class_name ResourceEmbeddedGenerator
extends VoxelGeneratorProcedural

var resource_nodes: Array[ResourceNode] = []

func _calculate_sdf(world_pos: Vector3) -> float:
    var base_sdf = super._calculate_sdf(world_pos)

    # Check if near resource node
    for resource in resource_nodes:
        var dist = world_pos.distance_to(resource.position)
        if dist < 3.0:  # Resource influence radius
            # Make resource vein (different material/density)
            base_sdf = modify_for_resource(base_sdf, dist, resource.resource_type)

    return base_sdf
```

**Option 2: Place After Generation**

```gdscript
# Generate terrain first
var terrain = planet_gen.generate_voxel_terrain(12345)
add_child(terrain)

# Place resource nodes
var resource_system = get_node("/root/ResourceSystem")
for i in 50:  # 50 resource nodes
    var pos = get_random_surface_position(terrain)
    var resource = ResourceNode.new("iron", pos, randi_range(100, 500))
    resource_system.register_resource(resource)

    # Optional: Modify terrain to show resource vein
    mark_resource_in_terrain(terrain, resource)
```

#### Dynamic Resource Placement

```gdscript
func mark_resource_in_terrain(terrain: VoxelTerrain, resource: ResourceNode):
    var voxel_tool = terrain.get_voxel_tool()

    # Set resource voxel type (different material)
    voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
    voxel_tool.mode = VoxelTool.MODE_ADD
    voxel_tool.value = get_resource_voxel_type(resource.resource_type)

    # Create spherical resource deposit
    voxel_tool.do_sphere(resource.position, 2.0)
```

#### Resource Extraction Integration

```gdscript
# TerrainTool excavation + resource extraction
class_name TerrainTool
extends Node3D

func excavate_at_position(position: Vector3, radius: float):
    # Modify terrain
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.mode = VoxelTool.MODE_REMOVE
    voxel_tool.do_sphere(position, radius)

    # Check for resources
    var resource_system = get_node("/root/ResourceSystem")
    var resources = resource_system.get_resources_in_radius(position, radius)

    for resource in resources:
        # Extract resource fragments
        var extracted = resource.extract(10)
        inventory.add_item(resource.resource_type, extracted)
        print("Extracted ", extracted, " ", resource.resource_type)
```

#### Voxel Material Types

```gdscript
# Define voxel types for different materials
enum VoxelType {
    AIR = 0,
    ROCK = 1,
    SOIL = 2,
    IRON_ORE = 3,
    COPPER_ORE = 4,
    URANIUM_ORE = 5,
    ICE = 6,
    SAND = 7
}

func get_resource_voxel_type(resource_type: String) -> int:
    match resource_type:
        "iron":
            return VoxelType.IRON_ORE
        "copper":
            return VoxelType.COPPER_ORE
        "uranium":
            return VoxelType.URANIUM_ORE
        _:
            return VoxelType.ROCK
```

---

### VR System Integration

**Location:** `scripts/core/vr_manager.gd`, `vr_setup.gd`

#### VR Controller Input

```gdscript
# VR controller for terrain modification
var left_controller: XRController3D
var right_controller: XRController3D

func _on_trigger_pressed():
    var controller = right_controller
    var tool_position = controller.global_position
    var tool_direction = -controller.global_transform.basis.z

    # Raycast to find terrain
    var hit = raycast_to_terrain(tool_position, tool_direction)
    if hit:
        # Excavate at hit position
        excavate_terrain(hit["position"], excavate_radius)

func excavate_terrain(position: Vector3, radius: float):
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.mode = VoxelTool.MODE_REMOVE
    voxel_tool.do_sphere(position, radius)
```

#### VR Performance Considerations

```gdscript
# VR-optimized terrain settings
func setup_vr_terrain(terrain: VoxelTerrain):
    # Reduce view distance for performance
    terrain.set_view_distance(128)  # Max 128 for 90 FPS

    # Configure aggressive LOD
    terrain.set_lod_count(4)
    terrain.set_lod_distance(0, 16)   # High detail very close
    terrain.set_lod_distance(1, 32)
    terrain.set_lod_distance(2, 64)
    terrain.set_lod_distance(3, 128)

    # Enable collision for interaction
    terrain.set_generate_collisions(true)

    # Use simpler generator
    var generator = VoxelGeneratorProcedural.new()
    generator.noise_octaves = 6       # Reduced from 8
    generator.enable_3d_features = false  # Disable caves
    terrain.set_generator(generator)
```

#### Haptic Feedback

```gdscript
# Haptic feedback when hitting terrain
func _on_terrain_impact(controller: XRController3D, force: float):
    var haptic_strength = clampf(force * 0.5, 0.0, 1.0)
    var haptic_duration = 0.1

    controller.trigger_haptic_pulse(
        "haptic",
        haptic_strength,
        haptic_duration,
        0
    )
```

---

### FloatingOrigin System Integration

**Location:** `scripts/core/floating_origin_system.gd`

#### Coordinate Rebasing

Voxel terrain integrates with FloatingOrigin for large-scale space environments.

```gdscript
# FloatingOriginSystem manages coordinate rebasing
class_name FloatingOriginSystem

func rebase_origin(offset: Vector3):
    # Rebase all objects
    for node in get_tree().get_nodes_in_group("floating_origin"):
        if node is VoxelTerrain:
            # VoxelTerrain handles rebasing internally
            node.global_position -= offset
            # Chunks automatically update to new origin
```

#### Configuration

```gdscript
# Register terrain with floating origin
terrain.add_to_group("floating_origin")

# Terrain automatically handles rebasing
# No special handling needed
```

---

## Usage Examples

### Example 1: Basic Planetary Terrain

```gdscript
extends Node3D

func _ready():
    # Create planet generator
    var planet_gen = PlanetGenerator.new()
    planet_gen.use_voxel_terrain = true
    add_child(planet_gen)

    # Generate terrain
    var terrain_data = planet_gen.generate_planet_terrain(
        42,  # seed
        PlanetGenerator.LODLevel.MEDIUM,
        0.5,  # temperature
        0.5   # moisture
    )

    # Add to scene
    var terrain = terrain_data["terrain_node"]
    add_child(terrain)

    # Position player on surface
    var player = get_node("Player")
    player.global_position = Vector3(0, 100, 0)
```

---

### Example 2: VR Terrain Excavation

```gdscript
extends Node3D

var terrain: VoxelTerrain
var voxel_tool: VoxelTool
var right_controller: XRController3D

func _ready():
    # Get terrain reference
    terrain = get_node("VoxelTerrain")
    voxel_tool = terrain.get_voxel_tool()

    # Get VR controller
    right_controller = get_node("XROrigin3D/RightController")
    right_controller.button_pressed.connect(_on_button_pressed)

func _on_button_pressed(button_name: String):
    if button_name == "trigger_click":
        excavate_at_controller()

func excavate_at_controller():
    var controller_pos = right_controller.global_position
    var forward = -right_controller.global_transform.basis.z

    # Raycast to terrain
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        controller_pos,
        controller_pos + forward * 10.0
    )
    query.collision_mask = 1

    var result = space_state.intersect_ray(query)
    if result:
        # Excavate at hit point
        voxel_tool.mode = VoxelTool.MODE_REMOVE
        voxel_tool.do_sphere(result["position"], 2.0)

        # Haptic feedback
        right_controller.trigger_haptic_pulse("haptic", 0.5, 0.1, 0)
```

---

### Example 3: Resource-Embedded Terrain

```gdscript
extends Node3D

var terrain: VoxelTerrain
var resource_nodes: Array[ResourceNode] = []

func _ready():
    # Generate terrain
    var planet_gen = PlanetGenerator.new()
    planet_gen.use_voxel_terrain = true
    add_child(planet_gen)

    terrain = planet_gen.generate_voxel_terrain(12345)
    add_child(terrain)

    # Wait for initial terrain generation
    await get_tree().create_timer(2.0).timeout

    # Place resource nodes
    place_resources()

func place_resources():
    var voxel_tool = terrain.get_voxel_tool()

    for i in 20:  # 20 resource deposits
        var pos = get_random_surface_position()

        # Create resource node
        var resource = ResourceNode.new(
            "iron",
            pos,
            randi_range(100, 500)
        )
        resource_nodes.append(resource)

        # Mark in terrain (change voxel type)
        voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
        voxel_tool.mode = VoxelTool.MODE_ADD
        voxel_tool.value = 3  # Iron ore voxel type
        voxel_tool.do_sphere(pos, 2.0)

func get_random_surface_position() -> Vector3:
    var x = randf_range(-100, 100)
    var z = randf_range(-100, 100)

    # Raycast down to find surface
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        Vector3(x, 200, z),
        Vector3(x, -200, z)
    )
    query.collision_mask = 1

    var result = space_state.intersect_ray(query)
    if result:
        return result["position"]

    return Vector3(x, 0, z)
```

---

### Example 4: Dynamic Quality Adjustment

```gdscript
extends Node3D

var terrain: VoxelTerrain
var generator: VoxelGeneratorProcedural
var performance_monitor: PerformanceOptimizer

func _ready():
    # Setup terrain
    generator = VoxelGeneratorProcedural.new()
    generator.terrain_seed = 12345

    terrain = ClassDB.instantiate("VoxelTerrain")
    terrain.set_generator(generator)
    add_child(terrain)

    # Setup performance monitor
    performance_monitor = get_node("/root/ResonanceEngine/PerformanceOptimizer")

func _process(delta):
    # Check FPS
    var fps = Engine.get_frames_per_second()

    if fps < 85 and terrain.get_view_distance() > 64:
        # Reduce view distance
        var current = terrain.get_view_distance()
        terrain.set_view_distance(max(64, current - 16))
        print("Reduced view distance to ", terrain.get_view_distance())

    elif fps > 95 and terrain.get_view_distance() < 256:
        # Increase view distance
        var current = terrain.get_view_distance()
        terrain.set_view_distance(min(256, current + 16))
        print("Increased view distance to ", terrain.get_view_distance())
```

---

### Example 5: Biome-Based Terrain

```gdscript
extends Node3D

var terrain: VoxelTerrain
var generators: Dictionary = {}

func _ready():
    # Create generators for different biomes
    generators["desert"] = create_desert_generator()
    generators["forest"] = create_forest_generator()
    generators["mountain"] = create_mountain_generator()

    # Create terrain with desert biome
    terrain = ClassDB.instantiate("VoxelTerrain")
    terrain.set_generator(generators["desert"])
    add_child(terrain)

func create_desert_generator() -> VoxelGeneratorProcedural:
    var gen = VoxelGeneratorProcedural.new()
    gen.terrain_seed = 12345
    gen.height_scale = 20.0  # Flatter
    gen.noise_octaves = 6
    gen.enable_3d_features = false
    return gen

func create_forest_generator() -> VoxelGeneratorProcedural:
    var gen = VoxelGeneratorProcedural.new()
    gen.terrain_seed = 12345
    gen.height_scale = 50.0  # Rolling hills
    gen.noise_octaves = 8
    gen.enable_3d_features = false
    return gen

func create_mountain_generator() -> VoxelGeneratorProcedural:
    var gen = VoxelGeneratorProcedural.new()
    gen.terrain_seed = 12345
    gen.height_scale = 150.0  # Tall peaks
    gen.noise_octaves = 12
    gen.enable_3d_features = true  # Caves
    gen.cave_threshold = 0.7
    return gen

func switch_biome(biome_name: String):
    if biome_name in generators:
        terrain.set_generator(generators[biome_name])
        print("Switched to ", biome_name, " biome")
```

---

## Performance Tuning Guide

### VR Performance Targets

**Target:** 90 FPS (11.1ms frame budget)

**Budget Allocation:**
- Rendering: 5ms
- Physics: 2ms
- Voxel operations: 2ms
- Gameplay logic: 1ms
- Overhead: 1.1ms

### Optimization Strategies

#### 1. View Distance Tuning

**Desktop Settings:**
```gdscript
terrain.set_view_distance(256)  # ~800 chunks
# Acceptable for 60 FPS desktop
```

**VR Settings:**
```gdscript
terrain.set_view_distance(128)  # ~200 chunks
# Optimized for 90 FPS VR
```

**Performance Impact:**
| View Distance | Active Chunks | Memory (MB) | FPS (Typical) |
|---------------|---------------|-------------|---------------|
| 64            | ~50           | ~50         | 120+          |
| 128           | ~200          | ~200        | 90-100        |
| 256           | ~800          | ~800        | 60-70         |
| 512           | ~3200         | ~3200       | 30-40         |

---

#### 2. LOD Configuration

**Aggressive LOD (VR Optimized):**
```gdscript
terrain.set_lod_count(4)
terrain.set_lod_distance(0, 16)   # Very short high-detail range
terrain.set_lod_distance(1, 32)
terrain.set_lod_distance(2, 64)
terrain.set_lod_distance(3, 128)
```

**Balanced LOD (Desktop):**
```gdscript
terrain.set_lod_count(5)
terrain.set_lod_distance(0, 32)
terrain.set_lod_distance(1, 64)
terrain.set_lod_distance(2, 128)
terrain.set_lod_distance(3, 256)
terrain.set_lod_distance(4, 512)
```

---

#### 3. Generator Optimization

**Fast Generator (VR):**
```gdscript
generator.noise_octaves = 6           # Reduced detail
generator.enable_3d_features = false  # No caves
generator.height_scale = 40.0         # Moderate terrain
```

**Quality Generator (Desktop):**
```gdscript
generator.noise_octaves = 10          # High detail
generator.enable_3d_features = true   # With caves
generator.cave_threshold = 0.6
generator.height_scale = 80.0
```

**Performance Comparison:**
| Configuration | Gen Time (ms) | FPS Impact | Visual Quality |
|---------------|---------------|------------|----------------|
| VR Fast       | ~3ms          | Minimal    | Good           |
| Desktop       | ~6ms          | Moderate   | Excellent      |
| Ultra         | ~10ms         | High       | Amazing        |

---

#### 4. Collision Optimization

**Enable Only When Needed:**
```gdscript
# Near player: Enable collision
if distance_to_player < 100:
    terrain.set_generate_collisions(true)
else:
    terrain.set_generate_collisions(false)
```

**Collision LOD:**
```gdscript
# Use lower resolution collision far from player
terrain.set_collision_layer(1)
terrain.set_collision_margin(0.04)  # Slightly larger margin for performance
```

---

#### 5. Memory Management

**Chunk Streaming:**
```gdscript
# Enable streaming (don't keep all chunks in memory)
terrain.set_full_load_mode_enabled(false)
terrain.set_streaming_enabled(true)
```

**Cache Limits:**
```gdscript
# Limit cache size
terrain.set_max_chunk_cache_size(512)  # Max chunks in RAM
```

**Periodic Cleanup:**
```gdscript
# Clear distant chunks every 30 seconds
var cleanup_timer = Timer.new()
cleanup_timer.timeout.connect(_cleanup_chunks)
cleanup_timer.wait_time = 30.0
cleanup_timer.autostart = true
add_child(cleanup_timer)

func _cleanup_chunks():
    var player_pos = player.global_position
    terrain.clear_chunks_outside_radius(player_pos, 200.0)
```

---

### Performance Profiling

#### Frame Time Analysis

```gdscript
var frame_times: Array[float] = []

func _process(delta):
    # Track frame time
    frame_times.append(delta * 1000.0)  # Convert to ms

    if frame_times.size() > 60:
        frame_times.pop_front()

    # Calculate average
    var avg_frame_time = 0.0
    for ft in frame_times:
        avg_frame_time += ft
    avg_frame_time /= frame_times.size()

    # Check if over budget
    if avg_frame_time > 11.1:
        print("OVER BUDGET: ", avg_frame_time, "ms")
        reduce_quality()
```

#### Voxel Operation Profiling

```gdscript
func profile_chunk_generation():
    var start = Time.get_ticks_usec()

    # Generate chunk
    # ... generation code ...

    var duration = (Time.get_ticks_usec() - start) / 1000.0
    print("Chunk generation: ", duration, "ms")

    if duration > 5.0:
        print("WARNING: Slow chunk generation")
```

---

## Advanced Topics

### Custom Voxel Materials

#### Material Channels

VoxelBuffer supports multiple channels:
- `CHANNEL_SDF`: Signed Distance Field (density)
- `CHANNEL_TYPE`: Material/block type (integer)
- `CHANNEL_COLOR`: Per-voxel color (not commonly used)

#### Setting Material Types

```gdscript
# During generation
func _generate_block(buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
    for z in range(size.z):
        for x in range(size.x):
            for y in range(size.y):
                var world_pos = Vector3(origin.x + x, origin.y + y, origin.z + z)

                # Set SDF
                var sdf = _calculate_sdf(world_pos)
                buffer.set_voxel_f(sdf, x, y, z, VoxelBuffer.CHANNEL_SDF)

                # Set material type
                var material_type = get_material_at(world_pos)
                buffer.set_voxel(material_type, x, y, z, VoxelBuffer.CHANNEL_TYPE)

func get_material_at(pos: Vector3) -> int:
    if pos.y < -10:
        return 3  # Iron ore
    elif pos.y < 0:
        return 1  # Rock
    else:
        return 2  # Soil
```

#### Material Rendering

Configure VoxelTerrain material:
```gdscript
# Create material library
var material_lib = VoxelBlockyLibrary.new()

# Add materials
material_lib.create_voxel(1, "Rock")
material_lib.get_voxel(1).set_color(Color(0.5, 0.5, 0.5))

material_lib.create_voxel(2, "Soil")
material_lib.get_voxel(2).set_color(Color(0.4, 0.3, 0.2))

material_lib.create_voxel(3, "IronOre")
material_lib.get_voxel(3).set_color(Color(0.6, 0.3, 0.2))

# Assign to terrain
terrain.set_voxel_library(material_lib)
```

---

### Terrain Modification Batching

#### Inefficient (Many Mesh Updates)

```gdscript
# BAD: Each modification triggers mesh update
for i in 100:
    voxel_tool.do_sphere(pos + Vector3(i, 0, 0), 1.0)
# Result: 100 mesh updates = slow
```

#### Efficient (Batched)

```gdscript
# GOOD: Batch modifications
voxel_tool.begin_edit()
for i in 100:
    voxel_tool.do_sphere(pos + Vector3(i, 0, 0), 1.0)
voxel_tool.end_edit()
# Result: 1 mesh update = fast
```

---

### Procedural Caves and Structures

#### Advanced Cave Generation

```gdscript
func _calculate_sdf_with_caves(world_pos: Vector3) -> float:
    var terrain_height = _sample_terrain_height(world_pos.x, world_pos.z)
    var base_sdf = terrain_height - world_pos.y

    # Only generate caves underground
    if world_pos.y < terrain_height:
        # Primary cave noise
        var cave_1 = cave_noise.get_noise_3d(
            world_pos.x,
            world_pos.y,
            world_pos.z
        )

        # Secondary cave noise (different frequency)
        var cave_2 = cave_noise.get_noise_3d(
            world_pos.x * 0.5,
            world_pos.y * 0.5,
            world_pos.z * 0.5
        )

        # Combine cave noises
        var cave_value = (cave_1 + cave_2) * 0.5
        cave_value = (cave_value + 1.0) * 0.5  # Normalize

        # Carve caves
        if cave_value > cave_threshold:
            var cave_strength = (cave_value - cave_threshold) / (1.0 - cave_threshold)
            base_sdf = minf(base_sdf, -3.0 * cave_strength)

    return base_sdf
```

#### Procedural Structures

```gdscript
# Add structures during generation
func _calculate_sdf_with_structures(world_pos: Vector3) -> float:
    var base_sdf = _calculate_sdf(world_pos)

    # Check if near structure location
    var structure_pos = get_nearest_structure_position(world_pos)
    var dist_to_structure = world_pos.distance_to(structure_pos)

    if dist_to_structure < 20.0:
        # Carve out space for structure
        var structure_sdf = create_structure_sdf(world_pos, structure_pos)
        base_sdf = minf(base_sdf, structure_sdf)

    return base_sdf

func create_structure_sdf(pos: Vector3, center: Vector3) -> float:
    # Simple rectangular room
    var local_pos = pos - center

    # Room dimensions
    var room_size = Vector3(10, 5, 10)

    # Box SDF
    var q = Vector3(
        absf(local_pos.x) - room_size.x,
        absf(local_pos.y) - room_size.y,
        absf(local_pos.z) - room_size.z
    )

    var box_sdf = Vector3(
        maxf(q.x, 0.0),
        maxf(q.y, 0.0),
        maxf(q.z, 0.0)
    ).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)

    # Negative inside, positive outside
    return -box_sdf
```

---

### Multiplayer Synchronization

#### Terrain Modification Sync

```gdscript
# On client: Perform modification
func excavate_terrain(position: Vector3, radius: float):
    # Local modification
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.mode = VoxelTool.MODE_REMOVE
    voxel_tool.do_sphere(position, radius)

    # Send to server
    rpc_id(1, "_server_excavate", position, radius)

# On server: Validate and broadcast
@rpc("any_peer", "call_remote", "reliable")
func _server_excavate(position: Vector3, radius: float):
    var sender_id = multiplayer.get_remote_sender_id()

    # Validate modification
    if is_modification_valid(sender_id, position, radius):
        # Apply on server
        var voxel_tool = terrain.get_voxel_tool()
        voxel_tool.mode = VoxelTool.MODE_REMOVE
        voxel_tool.do_sphere(position, radius)

        # Broadcast to all clients (except sender)
        for peer_id in multiplayer.get_peers():
            if peer_id != sender_id:
                rpc_id(peer_id, "_client_apply_excavation", position, radius)

# On clients: Apply modification
@rpc("authority", "call_remote", "reliable")
func _client_apply_excavation(position: Vector3, radius: float):
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.mode = VoxelTool.MODE_REMOVE
    voxel_tool.do_sphere(position, radius)
```

---

## Troubleshooting

### Common Issues

#### 1. Terrain Not Generating

**Symptoms:**
- VoxelTerrain node visible but no mesh appears
- Console shows no errors

**Solutions:**

```gdscript
# Check generator is assigned
if terrain.get_generator() == null:
    print("ERROR: No generator assigned")
    terrain.set_generator(VoxelGeneratorProcedural.new())

# Check view distance
if terrain.get_view_distance() < 32:
    print("WARNING: View distance too low")
    terrain.set_view_distance(128)

# Check camera position
var camera = get_viewport().get_camera_3d()
print("Camera position: ", camera.global_position)
# Camera should be within view_distance of origin
```

---

#### 2. Poor Performance / Low FPS

**Symptoms:**
- FPS below 60 (desktop) or 90 (VR)
- Frame stuttering

**Solutions:**

```gdscript
# Reduce view distance
terrain.set_view_distance(64)

# Reduce noise octaves
generator.noise_octaves = 6

# Disable 3D features
generator.enable_3d_features = false

# Aggressive LOD
terrain.set_lod_count(4)
terrain.set_lod_distance(0, 16)
terrain.set_lod_distance(1, 32)
terrain.set_lod_distance(2, 64)
terrain.set_lod_distance(3, 128)

# Profile to find bottleneck
var stats = performance_monitor.get_voxel_statistics()
print("Chunk gen time: ", stats["avg_chunk_gen_time_ms"])
print("Active chunks: ", stats["active_chunks"])
```

---

#### 3. Collision Not Working

**Symptoms:**
- Player falls through terrain
- No terrain collision detected

**Solutions:**

```gdscript
# Enable collision generation
terrain.set_generate_collisions(true)

# Check collision layers
print("Terrain layer: ", terrain.collision_layer)
print("Player mask: ", player.collision_mask)

# Ensure layers overlap
terrain.collision_layer = 1
player.collision_mask = 1

# Wait for collision to generate
await get_tree().create_timer(2.0).timeout
# Collision shapes are generated asynchronously
```

---

#### 4. Terrain Not Deterministic

**Symptoms:**
- Same seed produces different terrain
- Terrain changes on reload

**Solutions:**

```gdscript
# Ensure seed is set BEFORE assigning to terrain
generator.terrain_seed = 12345
terrain.set_generator(generator)  # Must be after seed

# Check noise generator seeds
print("Terrain noise seed: ", generator.terrain_noise.seed)
print("Detail noise seed: ", generator.detail_noise.seed)
# Should be: terrain_seed, terrain_seed+12345

# Disable random factors
generator.enable_random_craters = false
```

---

#### 5. Memory Issues / Crashes

**Symptoms:**
- High memory usage (>2GB)
- Out of memory crashes
- Slow terrain loading

**Solutions:**

```gdscript
# Enable streaming
terrain.set_full_load_mode_enabled(false)
terrain.set_streaming_enabled(true)

# Limit cache size
terrain.set_max_chunk_cache_size(512)

# Reduce view distance
terrain.set_view_distance(128)

# Periodically clear distant chunks
func _on_cleanup_timer():
    var player_pos = player.global_position
    terrain.clear_chunks_outside_radius(player_pos, 150.0)
```

---

### Debug Utilities

#### Visualization Helpers

```gdscript
# Visualize chunk boundaries
func draw_chunk_boundaries():
    var chunk_size = 32
    var view_dist = terrain.get_view_distance()

    for x in range(-view_dist, view_dist, chunk_size):
        for z in range(-view_dist, view_dist, chunk_size):
            var chunk_origin = Vector3(x, 0, z)
            draw_cube_outline(chunk_origin, Vector3.ONE * chunk_size)

# Visualize LOD levels
func debug_lod_levels():
    var camera_pos = get_viewport().get_camera_3d().global_position

    for lod in range(terrain.get_lod_count()):
        var dist = terrain.get_lod_distance(lod)
        draw_sphere_outline(camera_pos, dist, get_lod_color(lod))
```

#### Performance Overlay

```gdscript
# Add to CanvasLayer for debug info
extends Label

var terrain: VoxelTerrain
var generator: VoxelGeneratorProcedural

func _process(delta):
    if not terrain:
        return

    var fps = Engine.get_frames_per_second()
    var frame_time = delta * 1000.0

    text = """
    FPS: %d (%.1f ms)
    View Distance: %d
    Noise Octaves: %d
    3D Features: %s
    """.strip_edges() % [
        fps,
        frame_time,
        terrain.get_view_distance(),
        generator.noise_octaves,
        "ON" if generator.enable_3d_features else "OFF"
    ]
```

---

## API Version History

### Version 1.0.0 (2025-12-03)

**Initial Release**
- VoxelGeneratorProcedural API
- TerrainNoiseGenerator design specification
- VoxelPerformanceMonitor design specification
- PlanetGenerator integration
- Basic usage examples
- Performance tuning guide

**Known Limitations:**
- TerrainNoiseGenerator not yet implemented (design only)
- VoxelPerformanceMonitor not yet implemented (design only)
- Biome system integration planned for Phase 2
- Multiplayer sync requires additional testing

---

## Contributing and Feedback

### Reporting Issues

When reporting voxel terrain issues, please include:

1. **System Information**
   - Godot version
   - godot_voxel plugin version
   - Platform (Windows/Linux/Mac)
   - VR headset (if applicable)

2. **Configuration**
   - Generator settings (seed, octaves, height_scale)
   - Terrain settings (view_distance, LOD config)
   - Performance stats

3. **Reproduction Steps**
   - Code snippet to reproduce issue
   - Expected vs actual behavior
   - Screenshots/videos if visual issue

### Example Issue Report

```
**Issue:** Terrain not generating caves despite enable_3d_features = true

**System:**
- Godot 4.5.1
- godot_voxel v1.5
- Windows 11

**Configuration:**
generator.terrain_seed = 12345
generator.enable_3d_features = true
generator.cave_threshold = 0.6
generator.cave_frequency = 0.02

**Steps to Reproduce:**
1. Create VoxelGeneratorProcedural
2. Set enable_3d_features = true
3. Assign to VoxelTerrain
4. Observe terrain - no caves visible

**Expected:** Caves should be generated underground
**Actual:** Only heightmap terrain, no caves

**Additional Notes:**
- Disabling and re-enabling 3D features has no effect
- Other noise settings work correctly
```

---

## Further Reading

### External Documentation

- [godot_voxel Official Docs](https://voxel-tools.readthedocs.io/)
- [Godot Engine Documentation](https://docs.godotengine.org/)
- [FastNoiseLite Documentation](https://github.com/Auburn/FastNoiseLite)

### Internal Documentation

- `docs/VOXEL_INTEGRATION.md` - Integration overview
- `docs/VOXEL_PHASE_1_TASKS.md` - Phase 1 task breakdown
- `docs/architecture/GAME_SYSTEMS.md` - System architecture
- `docs/procedural/PLANET_GENERATION.md` - Planetary generation guide

### Related Systems

- `docs/rendering/VR_OPTIMIZATION.md` - VR performance optimization
- `docs/performance/PROFILING.md` - Performance profiling guide
- `docs/multiplayer/SYNCHRONIZATION.md` - Multiplayer sync patterns

---

**End of API Reference**

**Document Version:** 1.0.0
**Last Updated:** 2025-12-03
**Next Review:** After Phase 2 completion
**Maintainer:** SpaceTime VR Development Team
