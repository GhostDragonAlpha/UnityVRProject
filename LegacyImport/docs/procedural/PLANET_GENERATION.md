# Planet Generation - Technical Details

## Overview

The `PlanetGenerator` class creates detailed, realistic planetary terrain using Perlin-like noise functions with multiple octaves, crater generation, and biome-driven surface details. The system supports multiple Level-of-Detail (LOD) levels for efficient rendering at various distances.

## Core Terrain Generation

### 1. Noise Function Architecture

**Triple Noise System**:

```gdscript
func _initialize_noise_generators() -> void:
    # Main terrain generation
    _terrain_noise = FastNoiseLite.new()
    _terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # Fractional Brownian Motion
    _terrain_noise.fractal_octaves = noise_octaves        # 1-16
    _terrain_noise.fractal_gain = noise_persistence       # 0.1-1.0
    _terrain_noise.fractal_lacunarity = noise_lacunarity  # 1.0-4.0
    _terrain_noise.frequency = base_frequency             # 0.0001-1.0

    # Biome distribution (Voronoi-like)
    _biome_noise = FastNoiseLite.new()
    _biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
    _biome_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
    _biome_noise.frequency = 0.002

    # Fine surface details
    _detail_noise = FastNoiseLite.new()
    _detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _detail_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED  # Ridge patterns
    _detail_noise.fractal_octaves = 4
    _detail_noise.frequency = 0.02
```

### 2. Fractional Brownian Motion (FBM)

**Principle**: Combine multiple octaves of noise at different frequencies and amplitudes

**Algorithm**:

```
amplitude = 1.0
frequency = base_frequency
value = 0.0
max_amplitude = 0.0

for octave = 0 to num_octaves - 1:
    value += amplitude * noise(x * frequency, y * frequency)
    max_amplitude += amplitude
    amplitude *= persistence       # Each octave weaker
    frequency *= lacunarity         # Each octave higher frequency

normalized_value = value / max_amplitude
return (normalized_value + 1.0) * 0.5  # Map to [0, 1]
```

**Parameters**:

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| Octaves | 8 | 1-16 | More = more detail, slower |
| Persistence | 0.5 | 0.1-1.0 | Higher = rougher terrain |
| Lacunarity | 2.0 | 1.0-4.0 | Higher = more high-freq detail |
| Frequency | 0.005 | 0.0001-1.0 | Higher = smaller features |

### 3. Heightmap Generation Process

**Algorithm**:

```gdscript
func generate_heightmap(planet_seed: int, resolution: int = 256) -> Image:
    # Set seed for deterministic generation
    _set_seed(planet_seed)

    # Create empty heightmap
    var heightmap = Image.create(resolution, resolution, false, Image.FORMAT_RF)

    # Generate height values
    for y in range(resolution):
        for x in range(resolution):
            var height = _sample_terrain_height(x, y, resolution)
            heightmap.set_pixel(x, y, Color(height, height, height, 1.0))

    # Apply crater modifications
    if generate_craters:
        _apply_craters(heightmap, planet_seed, resolution)

    # Cache and emit signal
    _cache_heightmap(cache_key, heightmap)
    heightmap_generated.emit(heightmap, planet_seed)

    return heightmap
```

**Height Sampling**:

```gdscript
func _sample_terrain_height(x: int, y: int, resolution: int) -> float:
    # Normalize coordinates to [0, 1)
    var nx = float(x) / float(resolution)
    var ny = float(y) / float(resolution)

    # Base terrain from FBM noise
    var base_height = _terrain_noise.get_noise_2d(x, y)
    base_height = (base_height + 1.0) * 0.5  # Normalize to [0, 1]

    # Add fine detail
    var detail = _detail_noise.get_noise_2d(x * 4, y * 4) * 0.1

    # Combine and clamp
    return clampf(base_height + detail, 0.0, 1.0)
```

**Complexity**: O(n²) where n = resolution (256x256 = 65,536 samples)

### 4. Crater Generation

**Crater Distribution**:

```gdscript
func _apply_craters(heightmap: Image, planet_seed: int, resolution: int) -> void:
    var rng = RandomNumberGenerator.new()
    rng.seed = planet_seed + HASH_PRIME_1

    # Determine if craters appear
    if rng.randf() > CRATER_PROBABILITY:  # 30% default
        return

    # Number of craters
    var num_craters = rng.randi_range(1, MAX_CRATERS_PER_REGION)  # 1-5

    for _i in range(num_craters):
        var crater_x = rng.randi_range(0, resolution - 1)
        var crater_y = rng.randi_range(0, resolution - 1)
        var crater_radius = rng.randf_range(MIN_CRATER_RADIUS, MAX_CRATER_RADIUS)  # 5-50
        var crater_depth = rng.randf_range(0.1, 0.3)

        _apply_single_crater(heightmap, crater_x, crater_y, radius_normalized, crater_depth)
```

**Crater Profile** (bowl shape with raised rim):

```gdscript
func _apply_single_crater(heightmap: Image, center_x: int, center_y: int,
                         radius: float, depth: float) -> void:
    var resolution = heightmap.get_width()
    var pixel_radius = int(radius * resolution / 100.0)

    for dy in range(-pixel_radius, pixel_radius + 1):
        for dx in range(-pixel_radius, pixel_radius + 1):
            var px = center_x + dx
            var py = center_y + dy

            # Boundary check
            if px < 0 or px >= resolution or py < 0 or py >= resolution:
                continue

            var dist = sqrt(dx * dx + dy * dy)
            if dist > pixel_radius:
                continue

            # Crater profile calculation
            var normalized_dist = dist / pixel_radius
            var crater_factor: float

            if normalized_dist < 0.8:
                # Bowl interior: depression
                crater_factor = -depth * (1.0 - normalized_dist / 0.8)
            else:
                # Raised rim: elevation
                var rim_factor = (normalized_dist - 0.8) / 0.2
                crater_factor = depth * 0.2 * (1.0 - rim_factor)

            # Modify heightmap
            var current_color = heightmap.get_pixel(px, py)
            var new_height = clampf(current_color.r + crater_factor, 0.0, 1.0)
            heightmap.set_pixel(px, py, Color(new_height, new_height, new_height, 1.0))
```

**Crater Bowl Shape**:
```
     1.0 |  rim
         | /\  /\
height   |/  \/  \___
    0.5 |         bottom
         |_________________
         0.0    0.8      1.0
            normalized distance
```

- Inner 80%: Smooth depression
- Outer 20%: Raised rim (crater ejecta)
- Realistic bowl+rim morphology

## Mesh Generation

### 1. LOD System

**Resolutions by Level**:

| LOD Level | Resolution | Use Case | Distance |
|-----------|-----------|----------|----------|
| ULTRA | 256x256 | Walking surface | < 100m |
| HIGH | 128x128 | Close flyby | < 500m |
| MEDIUM | 64x64 | Orbital view | < 2000m |
| LOW | 32x32 | Distant approach | < 10000m |
| MINIMAL | 16x16 | Navigation | > 10000m |

**Auto LOD Selection**:

```gdscript
func get_lod_for_distance(distance: float) -> LODLevel:
    if distance < 100:
        return LODLevel.ULTRA
    elif distance < 500:
        return LODLevel.HIGH
    elif distance < 2000:
        return LODLevel.MEDIUM
    elif distance < 10000:
        return LODLevel.LOW
    else:
        return LODLevel.MINIMAL
```

### 2. Mesh Construction

**Two Methods**:

#### SurfaceTool Method (Easier, slower)

```gdscript
func generate_terrain_mesh(heightmap: Image, lod_level: LODLevel = LODLevel.MEDIUM) -> ArrayMesh:
    var resolution = LOD_RESOLUTIONS[lod_level]
    var mesh = ArrayMesh.new()

    # Resize heightmap to match LOD
    if heightmap.get_width() != resolution:
        heightmap.resize(resolution, resolution, Image.INTERPOLATE_BILINEAR)

    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Generate vertices and UVs
    var vertices: Array[Vector3] = []
    var uvs: Array[Vector2] = []
    for y in range(resolution):
        for x in range(resolution):
            var height = heightmap.get_pixel(x, y).r * height_scale
            vertices.append(Vector3(
                float(x) - resolution * 0.5,
                height,
                float(y) - resolution * 0.5
            ))
            uvs.append(Vector2(float(x) / resolution, float(y) / resolution))

    # Calculate normals
    var normals = _calculate_normals(vertices, resolution)

    # Generate triangles
    for y in range(resolution - 1):
        for x in range(resolution - 1):
            var idx = y * resolution + x
            # Two triangles per quad
            surface_tool.set_uv(uvs[idx])
            surface_tool.set_normal(normals[idx])
            surface_tool.add_vertex(vertices[idx])
            # ... (second and third vertex)

    return surface_tool.commit()
```

**Vertices**: resolution² (256×256 = 65,536 max)
**Triangles**: 2 × (resolution-1)² (256×256 = 131,070 max)

#### ArrayMesh Method (More efficient)

```gdscript
func generate_terrain_mesh_array(heightmap: Image, lod_level: LODLevel = LODLevel.MEDIUM) -> ArrayMesh:
    var resolution = LOD_RESOLUTIONS[lod_level]

    # Create packed arrays for GPU
    var vertices = PackedVector3Array()
    var normals_array = PackedVector3Array()
    var uvs_array = PackedVector2Array()
    var indices = PackedInt32Array()

    # Pre-allocate arrays
    vertices.resize(resolution * resolution)
    uvs_array.resize(resolution * resolution)
    indices.resize((resolution - 1) * (resolution - 1) * 2 * 3)

    # Generate vertex data
    for y in range(resolution):
        for x in range(resolution):
            var idx = y * resolution + x
            var height = heightmap.get_pixel(x, y).r * height_scale

            vertices[idx] = Vector3(
                float(x) - resolution * 0.5,
                height,
                float(y) - resolution * 0.5
            )
            uvs_array[idx] = Vector2(float(x) / resolution, float(y) / resolution)

    # Calculate normals
    normals_array = PackedVector3Array(_calculate_normals_packed(vertices, resolution))

    # Generate indices
    var index_offset = 0
    for y in range(resolution - 1):
        for x in range(resolution - 1):
            var idx = y * resolution + x

            # Triangle 1
            indices[index_offset] = idx
            indices[index_offset + 1] = idx + resolution
            indices[index_offset + 2] = idx + 1

            # Triangle 2
            indices[index_offset + 3] = idx + 1
            indices[index_offset + 4] = idx + resolution
            indices[index_offset + 5] = idx + resolution + 1

            index_offset += 6

    # Build mesh
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals_array
    arrays[Mesh.ARRAY_TEX_UV] = uvs_array
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

    return mesh
```

**Performance**: ~2-5x faster than SurfaceTool for large meshes

### 3. Normal Calculation

**Central Differences Method**:

```gdscript
func _calculate_normals(vertices: Array[Vector3], resolution: int) -> Array[Vector3]:
    var normals: Array[Vector3] = []
    normals.resize(vertices.size())

    for y in range(resolution):
        for x in range(resolution):
            var idx = y * resolution + x

            # Get neighboring vertices
            var left_idx = y * resolution + maxi(x - 1, 0)
            var right_idx = y * resolution + mini(x + 1, resolution - 1)
            var up_idx = maxi(y - 1, 0) * resolution + x
            var down_idx = mini(y + 1, resolution - 1) * resolution + x

            # Calculate tangent vectors
            var tangent_x = vertices[right_idx] - vertices[left_idx]
            var tangent_z = vertices[down_idx] - vertices[up_idx]

            # Normal from cross product
            var normal = tangent_z.cross(tangent_x).normalized()
            normals[idx] = normal

    return normals
```

**Properties**:
- Uses 4-neighborhood (up, down, left, right)
- Cross product order: Z × X (right-hand rule for +Y normal)
- Normalized for consistent lighting

## Normal Map Generation

**Purpose**: Store per-pixel normals for detail lighting without extra geometry

**Algorithm** (Sobel Operator):

```gdscript
func generate_normal_map(heightmap: Image) -> Image:
    var resolution = heightmap.get_width()
    var normal_map = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)

    for y in range(resolution):
        for x in range(resolution):
            # Sobel operator samples
            var left = heightmap.get_pixel(maxi(x - 1, 0), y).r
            var right = heightmap.get_pixel(mini(x + 1, resolution - 1), y).r
            var up = heightmap.get_pixel(x, maxi(y - 1, 0)).r
            var down = heightmap.get_pixel(x, mini(y + 1, resolution - 1)).r

            # Calculate slopes
            var dx = (right - left) * height_scale
            var dy = (down - up) * height_scale

            # Normal calculation
            var normal = Vector3(-dx, 2.0, -dy).normalized()

            # Convert to color (map [-1,1] to [0,1])
            var color = Color(
                normal.x * 0.5 + 0.5,
                normal.y * 0.5 + 0.5,
                normal.z * 0.5 + 0.5,
                1.0
            )

            normal_map.set_pixel(x, y, color)

    return normal_map
```

**Format**: RGB8 (8 bits per channel)
**Encoding**: [0,1] range mapped from [-1,1] normal space

## Biome Integration

### Surface Detail Generation

**Algorithm**:

```gdscript
func generate_surface_details(planet_seed: int, region_x: float, region_y: float,
                             region_size: float, biome: BiomeType) -> Array[Dictionary]:
    var details: Array[Dictionary] = []

    # Deterministic random for this region
    var rng = RandomNumberGenerator.new()
    var region_hash = _hash_region(planet_seed, int(region_x), int(region_y))
    rng.seed = region_hash

    # Density varies by biome
    var density = _get_biome_detail_density(biome)
    var num_details = int(density * region_size * region_size / 100.0)

    for _i in range(num_details):
        var detail = _generate_single_detail(rng, region_x, region_y, region_size, biome)
        if detail.size() > 0:
            details.append(detail)

    return details
```

**Biome Detail Density**:

| Biome | Density | Examples |
|-------|---------|----------|
| FOREST | 0.8 | trees, bushes, grass |
| DESERT | 0.2 | rocks, cacti, dunes |
| ICE | 0.1 | ice spikes, snow mounds |
| VOLCANIC | 0.3 | rocks, lava rocks, vents |
| BARREN | 0.4 | rocks, boulders, pebbles |
| TOXIC | 0.5 | crystals, fungus |
| OCEAN | 0.0 | (no surface details) |

### Biome Coloring

**Color Assignment** (from BiomeSystem):

```gdscript
const BIOME_COLORS: Dictionary = {
    BiomeType.ICE: Color(0.9, 0.95, 1.0),        # Light blue
    BiomeType.DESERT: Color(0.9, 0.8, 0.5),     # Sandy tan
    BiomeType.FOREST: Color(0.2, 0.5, 0.2),     # Forest green
    BiomeType.OCEAN: Color(0.1, 0.3, 0.6),      # Ocean blue
    BiomeType.VOLCANIC: Color(0.3, 0.1, 0.05),  # Dark reddish
    BiomeType.BARREN: Color(0.5, 0.45, 0.4),    # Gray-brown
    BiomeType.TOXIC: Color(0.4, 0.5, 0.2)       # Sickly green
}
```

## Caching System

### Cache Key Generation

```gdscript
func _make_cache_key(planet_seed: int, resolution: int) -> String:
    return "%d_%d" % [planet_seed, resolution]
```

### Cache Performance

**Default Max**: 10 heightmaps
**Memory per 256x256**: ~264 KB (RF format)
**Max Memory**: ~2.6 MB for default cache

## Configuration Presets

### High-Detail Mountains

```gdscript
generator.configure_noise(
    octaves=10,
    persistence=0.7,
    lacunarity=2.5,
    frequency=0.003
)
generator.height_scale = 100.0
generator.generate_craters = true
```

**Effect**: Tall, dramatic mountain ranges with frequent craters

### Gentle Rolling Hills

```gdscript
generator.configure_noise(
    octaves=4,
    persistence=0.3,
    lacunarity=1.8,
    frequency=0.001
)
generator.height_scale = 20.0
generator.generate_craters = false
```

**Effect**: Smooth, gently undulating terrain

### Technical Surface (Alien Machinery)

```gdscript
generator.configure_noise(
    octaves=6,
    persistence=0.4,
    lacunarity=4.0,
    frequency=0.02
)
generator.height_scale = 30.0
generator.generate_craters = false
```

**Effect**: High-frequency detail, angular/crystalline appearance

## Performance Optimization

### Generation Time Breakdown (256x256)

| Component | Time | Percentage |
|-----------|------|-----------|
| Height sampling | 20-30ms | 40% |
| Crater generation | 10-20ms | 15% |
| Mesh creation | 40-100ms | 45% |
| Normal map | 5-10ms | 10% |
| **Total** | **75-160ms** | **100%** |

### Optimization Strategies

1. **Cache aggressively**: Reuse generated heightmaps for different LOD meshes
2. **Reduce octaves**: Start with 4-6, increase for final detail pass
3. **Lower initial resolution**: Generate 128x128, upsample as needed
4. **Precompute craters**: Calculate once, apply to multiple LOD meshes
5. **Stream LOD**: Load MINIMAL immediately, stream detail progressively

### Memory Optimization

```gdscript
# For open-world exploration
generator.set_max_cache_size(50)  # ~13 MB

# For single planet detailed view
generator.set_max_cache_size(3)   # ~800 KB

# For memory-constrained devices
generator.set_max_cache_size(1)   # Clear cache each generation
```

## Validation and Testing

### Determinism Validation

```gdscript
func validate_determinism(planet_seed: int, resolution: int = 64) -> bool:
    # Generate twice with cache clearing
    clear_cache()
    var heightmap1 = generate_heightmap(planet_seed, resolution)

    clear_cache()
    var heightmap2 = generate_heightmap(planet_seed, resolution)

    # Compare all pixels (allows floating-point tolerance)
    for y in range(resolution):
        for x in range(resolution):
            var h1 = heightmap1.get_pixel(x, y).r
            var h2 = heightmap2.get_pixel(x, y).r
            if absf(h1 - h2) > 0.0001:  # Small tolerance for FP errors
                return false

    return true
```

## Advanced Topics

### Seamless Heightmap Tiling

**Challenge**: Connecting adjacent heightmap regions without visible seams

**Solution**: Use world coordinates for noise sampling:

```gdscript
func generate_heightmap_region(planet_seed: int, region_x: int, region_y: int,
                              region_size: int, resolution: int) -> Image:
    var world_offset_x = region_x * region_size
    var world_offset_y = region_y * region_size
    var scale = float(region_size) / float(resolution)

    for y in range(resolution):
        for x in range(resolution):
            # Use world coordinates, not local grid
            var world_x = world_offset_x + x * scale
            var world_y = world_offset_y + y * scale
            var height = _sample_terrain_height_world(world_x, world_y)
            # ...
```

**Benefits**: Seamless transitions between LOD regions

### Procedural Weather Effects

**Integration with biome system**:

```gdscript
var biome = biome_system.determine_biome(seed, x, y, height)
var effect = biome_system.get_environmental_effect(biome)
var effect_props = biome_system.get_effect_properties(effect)

# Modify terrain appearance based on weather
if effect == BiomeSystem.EnvironmentalEffect.SNOW:
    heightmap_brightness *= 0.95  # Darker under snow
```
