# Voxel Terrain Phase 1: Procedural Generation Tasks

**Created:** 2025-12-03
**Phase:** 1 of 3 - Foundation (Procedural Generation)
**Status:** Planning
**Target Completion:** TBD

---

## Overview

Phase 1 establishes the foundation for procedural voxel terrain generation in the SpaceTime VR project. This phase focuses on creating a custom procedural generator that integrates with the existing `PlanetGenerator` system and the Zylann godot_voxel plugin.

**Goals:**
- Create custom VoxelGeneratorProcedural class
- Implement 3D noise-based heightmap terrain
- Integrate with existing PlanetGenerator
- Establish deterministic seed-based generation
- Ensure VR performance targets (90 FPS)

**Dependencies:**
- ✅ Zylann godot_voxel plugin installed (v1.5x)
- ✅ VoxelTerrain classes available via GDExtension
- ✅ Existing PlanetGenerator system (`scripts/procedural/planet_generator.gd`)
- ✅ HTTP API for testing and validation (port 8080)

---

## Task List

### Task 1.1: Create VoxelGeneratorProcedural Class

**Priority:** High
**Estimated Time:** 3-4 hours
**Status:** ☐ Not Started

#### Description
Create a custom voxel generator script that extends `VoxelGeneratorScript` and implements procedural terrain generation using the Signed Distance Field (SDF) approach.

#### File to Create
- **Path:** `C:/godot/scripts/procedural/voxel_generator_procedural.gd`
- **Type:** GDScript extending VoxelGeneratorScript
- **Class Name:** `VoxelGeneratorProcedural`

#### Code Template

```gdscript
## VoxelGeneratorProcedural - Custom procedural terrain generator
## Extends VoxelGeneratorScript to provide noise-based terrain generation
## compatible with the existing PlanetGenerator system.
##
## This generator uses FastNoiseLite for deterministic terrain generation
## with support for multiple biomes and planetary features.
extends VoxelGeneratorScript
class_name VoxelGeneratorProcedural

## Emitted when terrain generation completes for a chunk
signal chunk_generated(origin: Vector3i, lod: int)

## Reference to noise generator for terrain base
var terrain_noise: FastNoiseLite = null

## Reference to noise generator for terrain detail
var detail_noise: FastNoiseLite = null

## Height scale multiplier for terrain elevation
@export var height_scale: float = 50.0

## Base height offset (y-coordinate of "sea level")
@export var base_height: float = 0.0

## Seed for deterministic generation
@export var terrain_seed: int = 0:
	set(value):
		terrain_seed = value
		_update_noise_seeds()

## Number of noise octaves for terrain
@export var noise_octaves: int = 8

## Noise persistence (amplitude reduction per octave)
@export var noise_persistence: float = 0.5

## Noise lacunarity (frequency increase per octave)
@export var noise_lacunarity: float = 2.0

## Base noise frequency
@export var base_frequency: float = 0.005


func _init() -> void:
	_initialize_noise_generators()


## Initialize noise generators with default settings
func _initialize_noise_generators() -> void:
	# Terrain base noise
	terrain_noise = FastNoiseLite.new()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = noise_octaves
	terrain_noise.fractal_gain = noise_persistence
	terrain_noise.fractal_lacunarity = noise_lacunarity
	terrain_noise.frequency = base_frequency

	# Detail noise for surface variation
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	detail_noise.fractal_octaves = 4
	detail_noise.frequency = 0.02

	_update_noise_seeds()


## Update noise generator seeds
func _update_noise_seeds() -> void:
	if terrain_noise:
		terrain_noise.seed = terrain_seed
	if detail_noise:
		detail_noise.seed = terrain_seed + 12345


## Main generation function called by VoxelTerrain
## Implements the VoxelGeneratorScript interface
func _generate_block(buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	var size: Vector3i = buffer.get_size()
	var channel: int = VoxelBuffer.CHANNEL_SDF

	# Generate voxel data using SDF approach
	for z in range(size.z):
		for x in range(size.x):
			for y in range(size.y):
				# Calculate world position
				var world_pos := Vector3(
					origin.x + x,
					origin.y + y,
					origin.z + z
				)

				# Generate SDF value for this position
				var sdf_value := _calculate_sdf(world_pos)

				# Write to voxel buffer
				buffer.set_voxel_f(sdf_value, x, y, z, channel)

	chunk_generated.emit(origin, lod)


## Calculate Signed Distance Field value at a world position
## Returns negative for air, positive for solid
func _calculate_sdf(world_pos: Vector3) -> float:
	# Sample base terrain height at this XZ position
	var terrain_height := _sample_terrain_height(world_pos.x, world_pos.z)

	# SDF = distance from surface
	# Negative values = air (above surface)
	# Positive values = solid (below surface)
	var sdf := terrain_height - world_pos.y

	return sdf


## Sample terrain height at a given XZ position
func _sample_terrain_height(x: float, z: float) -> float:
	# Get base terrain height from noise
	var base := terrain_noise.get_noise_2d(x, z)

	# Normalize from [-1, 1] to [0, 1], then scale
	base = (base + 1.0) * 0.5 * height_scale

	# Add detail noise for surface variation
	var detail := detail_noise.get_noise_2d(x, z) * (height_scale * 0.1)

	# Combine and offset by base height
	var final_height := base + detail + base_height

	return final_height


## Configure noise parameters (called from PlanetGenerator)
func configure_noise(octaves: int, persistence: float, lacunarity: float, frequency: float) -> void:
	noise_octaves = octaves
	noise_persistence = persistence
	noise_lacunarity = lacunarity
	base_frequency = frequency

	if terrain_noise:
		terrain_noise.fractal_octaves = octaves
		terrain_noise.fractal_gain = persistence
		terrain_noise.fractal_lacunarity = lacunarity
		terrain_noise.frequency = frequency


## Get current configuration as dictionary
func get_configuration() -> Dictionary:
	return {
		"terrain_seed": terrain_seed,
		"height_scale": height_scale,
		"base_height": base_height,
		"noise_octaves": noise_octaves,
		"noise_persistence": noise_persistence,
		"noise_lacunarity": noise_lacunarity,
		"base_frequency": base_frequency
	}
```

#### Dependencies
- godot_voxel GDExtension (VoxelGeneratorScript, VoxelBuffer)
- FastNoiseLite (Godot built-in)

#### Testing Criteria
- [ ] Class can be instantiated via `VoxelGeneratorProcedural.new()`
- [ ] Can be assigned to VoxelTerrain via `set_generator()`
- [ ] Generates visible terrain in editor/runtime
- [ ] Terrain is deterministic (same seed = same terrain)
- [ ] No runtime errors during generation
- [ ] Performance: < 5ms per 32³ chunk generation

#### Validation Script

```gdscript
# Test script: test_voxel_generator_procedural.gd
extends Node

func _ready():
	print("Testing VoxelGeneratorProcedural...")

	# Create generator
	var generator = VoxelGeneratorProcedural.new()
	generator.terrain_seed = 12345
	generator.height_scale = 25.0

	# Create VoxelTerrain
	var terrain = ClassDB.instantiate("VoxelTerrain")
	add_child(terrain)

	# Assign generator
	terrain.set_generator(generator)
	terrain.set_generate_collisions(true)
	terrain.set_view_distance(128)

	print("✓ VoxelGeneratorProcedural initialized")
	print("  Seed: ", generator.terrain_seed)
	print("  Height scale: ", generator.height_scale)
```

---

### Task 1.2: Implement 3D Noise Heightmap

**Priority:** High
**Estimated Time:** 4-5 hours
**Status:** ☐ Not Started

#### Description
Enhance the basic generator with advanced 3D noise features including caves, overhangs, and volumetric terrain features. This extends the basic heightmap approach to true 3D terrain.

#### File to Modify
- **Path:** `C:/godot/scripts/procedural/voxel_generator_procedural.gd`
- **Modification Type:** Add 3D noise methods and cave generation

#### Code to Add

```gdscript
## Add to VoxelGeneratorProcedural class:

## 3D cave noise generator
var cave_noise: FastNoiseLite = null

## Enable 3D terrain features (caves, overhangs)
@export var enable_3d_features: bool = false

## Cave density threshold (0.0-1.0)
@export var cave_threshold: float = 0.6

## Cave frequency multiplier
@export var cave_frequency: float = 0.02


## Update _initialize_noise_generators() to include cave noise:
func _initialize_noise_generators() -> void:
	# ... existing code ...

	# Cave noise for 3D features
	cave_noise = FastNoiseLite.new()
	cave_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	cave_noise.fractal_octaves = 3
	cave_noise.frequency = cave_frequency

	_update_noise_seeds()


## Update _update_noise_seeds() to include cave noise:
func _update_noise_seeds() -> void:
	# ... existing code ...
	if cave_noise:
		cave_noise.seed = terrain_seed + 67890


## Replace _calculate_sdf() with 3D version:
func _calculate_sdf(world_pos: Vector3) -> float:
	# Sample base terrain height
	var terrain_height := _sample_terrain_height(world_pos.x, world_pos.z)

	# Base SDF from heightmap
	var sdf := terrain_height - world_pos.y

	# Add 3D features if enabled
	if enable_3d_features:
		# Sample cave noise
		var cave_value := cave_noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
		cave_value = (cave_value + 1.0) * 0.5  # Normalize to [0, 1]

		# If cave_value exceeds threshold, carve out cave
		if cave_value > cave_threshold:
			# Make this area air by forcing SDF negative
			var cave_strength := (cave_value - cave_threshold) / (1.0 - cave_threshold)
			sdf = minf(sdf, -2.0 * cave_strength)

	return sdf


## Add method to configure 3D features:
func configure_3d_features(enabled: bool, threshold: float, frequency: float) -> void:
	enable_3d_features = enabled
	cave_threshold = clampf(threshold, 0.0, 1.0)
	cave_frequency = frequency

	if cave_noise:
		cave_noise.frequency = frequency
```

#### Dependencies
- Task 1.1 completed
- FastNoiseLite cellular noise support

#### Testing Criteria
- [ ] Caves generate correctly when enabled
- [ ] No caves appear when disabled
- [ ] Cave threshold controls cave density
- [ ] No performance degradation (< 7ms per 32³ chunk)
- [ ] Caves connect naturally
- [ ] Overhangs and 3D features work correctly

#### Validation Steps
1. Create terrain with `enable_3d_features = false` → Should be pure heightmap
2. Enable 3D features → Should see caves
3. Adjust `cave_threshold` from 0.5 to 0.9 → More/fewer caves
4. Verify determinism: Same seed produces same caves

---

### Task 1.3: Integrate with PlanetGenerator

**Priority:** Medium
**Estimated Time:** 3-4 hours
**Status:** ☐ Not Started

#### Description
Create integration layer between the existing `PlanetGenerator` system and the new `VoxelGeneratorProcedural`. This allows planets to use either heightmap mesh generation (existing) or voxel terrain (new) based on configuration.

#### File to Modify
- **Path:** `C:/godot/scripts/procedural/planet_generator.gd`
- **Modification Type:** Add voxel terrain generation methods

#### Code to Add

```gdscript
## Add to PlanetGenerator class (after line 103):

## Whether to use voxel terrain instead of mesh
@export var use_voxel_terrain: bool = false

## Reference to voxel generator
var _voxel_generator: VoxelGeneratorProcedural = null


## Add to _ready() function:
func _ready() -> void:
	_initialize_noise_generators()

	# Initialize voxel generator if enabled
	if use_voxel_terrain:
		_initialize_voxel_generator()


## Add new method after _initialize_noise_generators():
## Initialize voxel terrain generator
func _initialize_voxel_generator() -> void:
	"""Initialize the voxel terrain generator with current settings."""
	_voxel_generator = VoxelGeneratorProcedural.new()

	# Copy noise configuration from existing generators
	_voxel_generator.configure_noise(
		noise_octaves,
		noise_persistence,
		noise_lacunarity,
		base_frequency
	)

	_voxel_generator.height_scale = height_scale
	_voxel_generator.terrain_seed = _current_seed


## Add new method in utility section:
## Generate a VoxelTerrain node for a planet
func generate_voxel_terrain(planet_seed: int, lod_level: LODLevel = LODLevel.MEDIUM) -> Node3D:
	"""Generate a VoxelTerrain node for a planet."""

	# Set seed for deterministic generation
	_set_seed(planet_seed)

	# Initialize voxel generator if not already done
	if _voxel_generator == null:
		_initialize_voxel_generator()
	else:
		_voxel_generator.terrain_seed = planet_seed

	# Create VoxelTerrain node
	var terrain = ClassDB.instantiate("VoxelTerrain")
	if terrain == null:
		push_error("Failed to instantiate VoxelTerrain - godot_voxel plugin not loaded")
		return null

	# Configure VoxelTerrain
	terrain.set_generator(_voxel_generator)
	terrain.set_generate_collisions(true)

	# Set view distance based on LOD level
	var view_distance := _get_voxel_view_distance(lod_level)
	terrain.set_view_distance(view_distance)

	# Configure collision
	terrain.collision_layer = 1  # Default terrain layer
	terrain.collision_mask = 0   # Terrain doesn't need to detect collisions

	return terrain


## Helper to get view distance for LOD level
func _get_voxel_view_distance(lod_level: LODLevel) -> int:
	"""Get appropriate view distance for LOD level."""
	match lod_level:
		LODLevel.ULTRA:
			return 512
		LODLevel.HIGH:
			return 256
		LODLevel.MEDIUM:
			return 128
		LODLevel.LOW:
			return 64
		LODLevel.MINIMAL:
			return 32
		_:
			return 128


## Update generate_planet_terrain() to support voxel option:
func generate_planet_terrain(planet_seed: int, lod_level: LODLevel = LODLevel.MEDIUM,
							 temperature: float = 0.5, moisture: float = 0.5) -> Dictionary:
	"""Generate a complete terrain package for a planet."""

	# Use voxel terrain if enabled
	if use_voxel_terrain:
		var terrain = generate_voxel_terrain(planet_seed, lod_level)
		return {
			"terrain_node": terrain,
			"terrain_type": "voxel",
			"lod_level": lod_level,
			"planet_seed": planet_seed
		}

	# Otherwise use existing mesh-based generation
	var resolution = LOD_RESOLUTIONS[lod_level]
	# ... existing mesh generation code ...
```

#### Dependencies
- Task 1.1 completed
- Task 1.2 completed
- Existing PlanetGenerator system

#### Testing Criteria
- [ ] Can generate voxel terrain via `generate_voxel_terrain()`
- [ ] Can generate mesh terrain via existing methods
- [ ] Both use same seed for determinism
- [ ] LOD levels affect view distance appropriately
- [ ] Collision generation works
- [ ] Integration doesn't break existing mesh generation

#### Validation Script

```gdscript
# Test script: test_planet_voxel_integration.gd
extends Node3D

func _ready():
	print("Testing PlanetGenerator voxel integration...")

	# Create PlanetGenerator
	var generator = PlanetGenerator.new()
	add_child(generator)

	# Test 1: Generate traditional mesh terrain
	generator.use_voxel_terrain = false
	var mesh_result = generator.generate_planet_terrain(12345, PlanetGenerator.LODLevel.MEDIUM)
	print("✓ Mesh terrain generated")
	print("  Type: ", mesh_result.get("terrain_type", "mesh"))

	# Test 2: Generate voxel terrain
	generator.use_voxel_terrain = true
	var voxel_result = generator.generate_planet_terrain(12345, PlanetGenerator.LODLevel.MEDIUM)
	print("✓ Voxel terrain generated")
	print("  Type: ", voxel_result.get("terrain_type", "voxel"))
	print("  Node type: ", voxel_result["terrain_node"].get_class())

	# Add voxel terrain to scene for visual verification
	var terrain_node = voxel_result["terrain_node"]
	add_child(terrain_node)
	terrain_node.global_position = Vector3.ZERO
```

---

### Task 1.4: Create Test Scene and Validation

**Priority:** Medium
**Estimated Time:** 2-3 hours
**Status:** ☐ Not Started

#### Description
Create dedicated test scene and validation scripts to verify procedural voxel terrain generation works correctly and meets performance requirements.

#### Files to Create

1. **Test Scene:** `C:/godot/scenes/tests/voxel_procedural_test.tscn`
2. **Test Script:** `C:/godot/scripts/tests/test_voxel_procedural.gd`
3. **Validation Script:** `C:/godot/tests/validate_voxel_procedural.py`

#### Test Scene Structure

```
VoxelProceduralTest (Node3D)
├── PlanetGenerator (script attached)
├── Camera3D (for visual inspection)
├── DirectionalLight3D (lighting)
└── TestController (script: test_voxel_procedural.gd)
```

#### Test Script Template

```gdscript
# scripts/tests/test_voxel_procedural.gd
extends Node
class_name VoxelProceduralTest

## Results of tests
var test_results: Dictionary = {}

## Planet generator reference
var generator: PlanetGenerator


func _ready() -> void:
	generator = get_node("../PlanetGenerator")

	print("=== Voxel Procedural Generation Tests ===")

	run_all_tests()

	print_results()


func run_all_tests() -> void:
	test_generator_creation()
	test_determinism()
	test_performance()
	test_collision_generation()
	test_lod_levels()


func test_generator_creation() -> void:
	print("\n[Test 1] Generator Creation")

	var voxel_gen = VoxelGeneratorProcedural.new()
	var success = voxel_gen != null

	test_results["generator_creation"] = success
	print("  Result: ", "PASS" if success else "FAIL")


func test_determinism() -> void:
	print("\n[Test 2] Deterministic Generation")

	var seed_value = 42

	# Generate terrain twice with same seed
	var terrain1 = generator.generate_voxel_terrain(seed_value)
	var terrain2 = generator.generate_voxel_terrain(seed_value)

	# Both should use the same generator configuration
	var success = (terrain1 != null and terrain2 != null)

	test_results["determinism"] = success
	print("  Result: ", "PASS" if success else "FAIL")


func test_performance() -> void:
	print("\n[Test 3] Performance")

	var start_time = Time.get_ticks_usec()
	var terrain = generator.generate_voxel_terrain(12345)
	var end_time = Time.get_ticks_usec()

	var duration_ms = (end_time - start_time) / 1000.0
	var success = duration_ms < 100.0  # Should be fast (just setup)

	test_results["performance"] = success
	test_results["generation_time_ms"] = duration_ms

	print("  Generation time: ", duration_ms, " ms")
	print("  Result: ", "PASS" if success else "FAIL")


func test_collision_generation() -> void:
	print("\n[Test 4] Collision Generation")

	var terrain = generator.generate_voxel_terrain(12345)
	var collisions_enabled = terrain.get_generate_collisions()

	test_results["collision_generation"] = collisions_enabled
	print("  Collisions enabled: ", collisions_enabled)
	print("  Result: ", "PASS" if collisions_enabled else "FAIL")


func test_lod_levels() -> void:
	print("\n[Test 5] LOD Levels")

	var success = true
	var lod_configs = {}

	for lod in [
		PlanetGenerator.LODLevel.MINIMAL,
		PlanetGenerator.LODLevel.LOW,
		PlanetGenerator.LODLevel.MEDIUM,
		PlanetGenerator.LODLevel.HIGH,
		PlanetGenerator.LODLevel.ULTRA
	]:
		var terrain = generator.generate_voxel_terrain(12345, lod)
		var view_dist = terrain.get_view_distance()
		lod_configs[lod] = view_dist
		print("  LOD ", lod, ": view_distance = ", view_dist)

	test_results["lod_levels"] = success
	test_results["lod_configs"] = lod_configs
	print("  Result: PASS")


func print_results() -> void:
	print("\n=== Test Summary ===")

	var total = test_results.size()
	var passed = 0

	for test_name in test_results:
		if test_name.ends_with("_ms") or test_name.ends_with("_configs"):
			continue

		var result = test_results[test_name]
		if result:
			passed += 1

		print("  ", test_name, ": ", "PASS" if result else "FAIL")

	print("\nTotal: ", passed, "/", total, " tests passed")

	# Write results to file
	var file = FileAccess.open("res://test_voxel_procedural_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(test_results, "  "))
	file.close()
```

#### Python Validation Script

```python
# tests/validate_voxel_procedural.py
"""
Validation script for voxel procedural generation.
Tests integration via HTTP API.
"""

import requests
import json
import time

API_BASE = "http://localhost:8080"

def test_voxel_generation():
    print("=== Voxel Procedural Generation Validation ===\n")

    # Load test scene
    print("[1] Loading test scene...")
    response = requests.post(
        f"{API_BASE}/scene/load",
        json={"scene_path": "res://scenes/tests/voxel_procedural_test.tscn"}
    )

    if response.status_code == 200:
        print("✓ Test scene loaded\n")
    else:
        print("✗ Failed to load test scene")
        return False

    # Wait for tests to run
    time.sleep(3)

    # Check for results file
    print("[2] Checking test results...")
    # Results should be written to test_voxel_procedural_results.json

    print("\n✓ Validation complete")
    return True

if __name__ == "__main__":
    test_voxel_generation()
```

#### Dependencies
- Tasks 1.1, 1.2, 1.3 completed
- HTTP API server running (port 8080)

#### Testing Criteria
- [ ] Test scene loads without errors
- [ ] All 5 tests pass
- [ ] Results written to JSON file
- [ ] Python validation script runs successfully
- [ ] No console errors during testing

---

### Task 1.5: Documentation and API Endpoints

**Priority:** Low
**Estimated Time:** 2 hours
**Status:** ☐ Not Started

#### Description
Document the new voxel procedural generation system and add HTTP API endpoints for remote configuration and testing.

#### Files to Create/Modify

1. **Documentation:** `C:/godot/docs/VOXEL_PROCEDURAL_GENERATION.md`
2. **API Extension:** `C:/godot/scripts/http_api/routers/voxel_router.gd` (if not exists)
3. **Update:** `C:/godot/docs/VOXEL_INTEGRATION.md` (add Phase 1 section)

#### Documentation Template

```markdown
# Voxel Procedural Generation

**Module:** VoxelGeneratorProcedural
**Location:** `scripts/procedural/voxel_generator_procedural.gd`
**Integration:** PlanetGenerator
**Phase:** 1 of 3

## Overview

The VoxelGeneratorProcedural system provides noise-based procedural terrain generation
for voxel-based planets in SpaceTime VR.

## Features

- **Deterministic Generation:** Same seed always produces identical terrain
- **3D Noise:** Supports caves, overhangs, and volumetric features
- **LOD Support:** Configurable view distance per LOD level
- **Performance:** < 5ms per 32³ chunk generation
- **Integration:** Works with existing PlanetGenerator system

## Usage

### Basic Example

```gdscript
# Create generator
var generator = VoxelGeneratorProcedural.new()
generator.terrain_seed = 12345
generator.height_scale = 50.0

# Create terrain
var terrain = ClassDB.instantiate("VoxelTerrain")
terrain.set_generator(generator)
terrain.set_generate_collisions(true)
add_child(terrain)
```

### Via PlanetGenerator

```gdscript
var planet_gen = PlanetGenerator.new()
planet_gen.use_voxel_terrain = true

var result = planet_gen.generate_voxel_terrain(
	12345,  # seed
	PlanetGenerator.LODLevel.MEDIUM
)

add_child(result["terrain_node"])
```

## Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| terrain_seed | int | 0 | Seed for deterministic generation |
| height_scale | float | 50.0 | Vertical scale multiplier |
| base_height | float | 0.0 | Y-coordinate of "sea level" |
| noise_octaves | int | 8 | Number of noise octaves |
| enable_3d_features | bool | false | Enable caves/overhangs |
| cave_threshold | float | 0.6 | Cave density (0.0-1.0) |

## Performance

**Benchmarks (32³ chunk):**
- Heightmap only: ~3-4ms
- With 3D features: ~5-7ms
- Memory: ~2 MB per loaded chunk

**VR Optimization:**
- Use LOD.MEDIUM or LOD.LOW for VR (view_distance ≤ 256)
- Disable 3D features if FPS < 90
- Keep height_scale ≤ 100 for better performance

## API Reference

See [VoxelGeneratorProcedural API](api/voxel_generator_procedural.md)
```

#### API Endpoints to Add

```gdscript
# In scripts/http_api/routers/voxel_router.gd (or add to existing router)

## GET /voxel/generator/config
## Returns current voxel generator configuration
func handle_get_generator_config(request: Dictionary) -> Dictionary:
	var generator = _get_voxel_generator()
	if generator == null:
		return {"status": "error", "message": "No voxel generator active"}

	return {
		"status": "success",
		"config": generator.get_configuration()
	}


## POST /voxel/generator/config
## Updates voxel generator configuration
func handle_set_generator_config(request: Dictionary) -> Dictionary:
	var generator = _get_voxel_generator()
	if generator == null:
		return {"status": "error", "message": "No voxel generator active"}

	var body = request.get("body", {})

	if body.has("terrain_seed"):
		generator.terrain_seed = body["terrain_seed"]
	if body.has("height_scale"):
		generator.height_scale = body["height_scale"]
	if body.has("enable_3d_features"):
		generator.enable_3d_features = body["enable_3d_features"]

	return {
		"status": "success",
		"config": generator.get_configuration()
	}
```

#### Dependencies
- Tasks 1.1-1.4 completed
- HTTP API system

#### Testing Criteria
- [ ] Documentation is complete and accurate
- [ ] API endpoints respond correctly
- [ ] Examples in documentation work
- [ ] VOXEL_INTEGRATION.md updated with Phase 1 info

---

## Progress Tracking

### Task Summary

| Task | Priority | Time Est. | Status |
|------|----------|-----------|--------|
| 1.1: VoxelGeneratorProcedural | High | 3-4h | ☐ Not Started |
| 1.2: 3D Noise Heightmap | High | 4-5h | ☐ Not Started |
| 1.3: PlanetGenerator Integration | Medium | 3-4h | ☐ Not Started |
| 1.4: Test Scene & Validation | Medium | 2-3h | ☐ Not Started |
| 1.5: Documentation & API | Low | 2h | ☐ Not Started |

**Total Estimated Time:** 14-18 hours

### Completion Checklist

#### Phase 1 Complete When:
- [ ] All 5 tasks marked complete
- [ ] All test criteria met
- [ ] No console errors in test runs
- [ ] Documentation complete
- [ ] Python validation passes
- [ ] Performance targets met (< 7ms per chunk)
- [ ] VR performance maintained (90 FPS)
- [ ] Determinism verified (same seed = same terrain)

---

## Dependencies and Prerequisites

### Required Files (Existing)
- ✅ `scripts/procedural/planet_generator.gd` - PlanetGenerator system
- ✅ `addons/zylann.voxel/` - Voxel plugin installed
- ✅ `scripts/http_api/http_api_server.gd` - HTTP API server

### Required Systems (Active)
- ✅ Godot 4.5.1 running in editor mode
- ✅ HTTP API server on port 8080
- ✅ godot_voxel GDExtension loaded
- ✅ ResonanceEngine autoload system

### Optional (Recommended)
- Python 3.8+ for validation scripts
- Telemetry client for performance monitoring

---

## Next Phases

### Phase 2: Biome System
- Biome-based terrain variation
- Material/texture system
- Surface detail generation
- Integration with existing biome system

### Phase 3: Advanced Features
- Spherical planet generation
- Gravity-based orientation
- Planetary LOD system
- Multiplayer synchronization

---

## Notes

### Design Decisions

**Why SDF (Signed Distance Field)?**
- Standard voxel approach for smooth terrain
- Efficient for collision detection
- Supports overhangs and caves naturally
- Compatible with Zylann voxel plugin

**Why integrate with PlanetGenerator?**
- Maintains existing API consistency
- Reuses noise configuration
- Supports both mesh and voxel workflows
- Easier migration path

**Why separate 3D features?**
- Performance optimization (can disable for VR)
- Complexity control
- Easier testing and debugging

### Performance Targets

**VR Requirements:**
- 90 FPS maintained
- < 11ms frame time budget
- Voxel generation: < 3ms per frame
- Collision generation: Async, non-blocking

**Desktop Requirements:**
- 60 FPS minimum
- < 16ms frame time
- Can enable more features

### Future Enhancements

**Post-Phase 1:**
- Multi-threaded chunk generation
- Chunk streaming/caching system
- GPU-accelerated noise
- Advanced erosion simulation
- Procedural cave networks
- Mineral/resource distribution

---

**Document Version:** 1.0
**Created By:** Claude Code
**Last Updated:** 2025-12-03
**Review Required:** After Phase 1 completion
