## PlanetGenerator - Procedural Planetary Terrain Generation
## Generates planetary terrain using deterministic noise functions with
## heightmaps, normal maps, and biome-based coloring.
##
## Requirements: 53.1, 53.2, 53.3, 53.4, 53.5
## - 53.1: Use deterministic noise functions seeded by planet coordinates
## - 53.2: Generate heightmaps with multiple octaves of noise for realistic features
## - 53.3: Generate surface details (rocks, craters, vegetation) procedurally
## - 53.4: Ensure same coordinates always produce identical terrain features
## - 53.5: Use lower LOD meshes for distant terrain, progressively increase detail
extends Node
class_name PlanetGenerator

## Emitted when a heightmap is generated
signal heightmap_generated(heightmap: Image, planet_seed: int)
## Emitted when a terrain mesh is generated
signal terrain_mesh_generated(mesh: ArrayMesh, lod_level: int)
## Emitted when a normal map is generated
signal normal_map_generated(normal_map: Image)

## Biome type enumeration matching design document
enum BiomeType {
	ICE,
	DESERT,
	FOREST,
	OCEAN,
	VOLCANIC,
	BARREN,
	TOXIC
}

## LOD level enumeration
enum LODLevel {
	ULTRA = 0,    # Highest detail (walking distance)
	HIGH = 1,     # High detail (close approach)
	MEDIUM = 2,   # Medium detail (orbital view)
	LOW = 3,      # Low detail (distant view)
	MINIMAL = 4   # Minimal detail (very far)
}

## Resolution for each LOD level (vertices per side)
const LOD_RESOLUTIONS: Dictionary = {
	LODLevel.ULTRA: 256,
	LODLevel.HIGH: 128,
	LODLevel.MEDIUM: 64,
	LODLevel.LOW: 32,
	LODLevel.MINIMAL: 16
}

## Default noise parameters
const DEFAULT_OCTAVES: int = 8
const DEFAULT_PERSISTENCE: float = 0.5
const DEFAULT_LACUNARITY: float = 2.0
const DEFAULT_FREQUENCY: float = 0.005

## Height scale multiplier
const DEFAULT_HEIGHT_SCALE: float = 50.0

## Crater generation parameters
const CRATER_PROBABILITY: float = 0.3
const MAX_CRATERS_PER_REGION: int = 5
const MIN_CRATER_RADIUS: float = 5.0
const MAX_CRATER_RADIUS: float = 50.0

## Prime numbers for hash functions (deterministic generation)
const HASH_PRIME_1: int = 73856093
const HASH_PRIME_2: int = 19349663
const HASH_PRIME_3: int = 83492791

#region Configuration Properties

## Number of noise octaves for terrain generation
## Requirement 53.2: Multiple octaves of noise for realistic features
@export var noise_octaves: int = DEFAULT_OCTAVES:
	set(value):
		noise_octaves = clampi(value, 1, 16)

## Persistence value for noise (amplitude reduction per octave)
@export var noise_persistence: float = DEFAULT_PERSISTENCE:
	set(value):
		noise_persistence = clampf(value, 0.1, 1.0)

## Lacunarity value for noise (frequency increase per octave)
@export var noise_lacunarity: float = DEFAULT_LACUNARITY:
	set(value):
		noise_lacunarity = clampf(value, 1.0, 4.0)

## Base frequency for noise
@export var base_frequency: float = DEFAULT_FREQUENCY:
	set(value):
		base_frequency = clampf(value, 0.0001, 1.0)

## Height scale multiplier for terrain
@export var height_scale: float = DEFAULT_HEIGHT_SCALE:
	set(value):
		height_scale = maxf(value, 0.1)

## Whether to generate craters
@export var generate_craters: bool = true

## Whether to apply biome coloring
@export var apply_biome_colors: bool = true

#endregion

#region Runtime Properties

## FastNoiseLite instance for terrain generation
var _terrain_noise: FastNoiseLite = null

## FastNoiseLite instance for biome distribution
var _biome_noise: FastNoiseLite = null

## FastNoiseLite instance for detail generation
var _detail_noise: FastNoiseLite = null

## Current planet seed
var _current_seed: int = 0

## Cache for generated heightmaps
var _heightmap_cache: Dictionary = {}

## Maximum cache size
var _max_cache_size: int = 10

#endregion


func _ready() -> void:
	_initialize_noise_generators()


## Initialize noise generators with default settings
func _initialize_noise_generators() -> void:
	"""Initialize the FastNoiseLite instances."""
	_terrain_noise = FastNoiseLite.new()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_terrain_noise.fractal_octaves = noise_octaves
	_terrain_noise.fractal_gain = noise_persistence
	_terrain_noise.fractal_lacunarity = noise_lacunarity
	_terrain_noise.frequency = base_frequency
	
	_biome_noise = FastNoiseLite.new()
	_biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_biome_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_biome_noise.frequency = 0.002
	
	_detail_noise = FastNoiseLite.new()
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_detail_noise.fractal_octaves = 4
	_detail_noise.frequency = 0.02


#region Heightmap Generation

## Generate a heightmap for a planet
## Requirement 53.1: Use deterministic noise functions seeded by planet coordinates
## Requirement 53.4: Same coordinates always produce identical terrain features
func generate_heightmap(planet_seed: int, resolution: int = 256) -> Image:
	"""Generate a heightmap image for a planet using deterministic noise."""
	# Check cache first
	var cache_key = _make_cache_key(planet_seed, resolution)
	if _heightmap_cache.has(cache_key):
		return _heightmap_cache[cache_key]
	
	# Set seed for deterministic generation
	_set_seed(planet_seed)
	
	# Create heightmap image
	var heightmap = Image.create(resolution, resolution, false, Image.FORMAT_RF)
	
	# Generate height values
	for y in range(resolution):
		for x in range(resolution):
			var height = _sample_terrain_height(x, y, resolution)
			heightmap.set_pixel(x, y, Color(height, height, height, 1.0))
	
	# Apply crater modifications if enabled
	if generate_craters:
		_apply_craters(heightmap, planet_seed, resolution)
	
	# Cache the result
	_cache_heightmap(cache_key, heightmap)
	
	heightmap_generated.emit(heightmap, planet_seed)
	return heightmap


## Generate a heightmap for a specific region (for LOD streaming)
## Requirement 53.5: Progressive detail increase as player approaches
func generate_heightmap_region(planet_seed: int, region_x: int, region_y: int, 
							   region_size: int, resolution: int) -> Image:
	"""Generate a heightmap for a specific region of a planet."""
	_set_seed(planet_seed)
	
	var heightmap = Image.create(resolution, resolution, false, Image.FORMAT_RF)
	
	# Calculate world coordinates for this region
	var world_offset_x = region_x * region_size
	var world_offset_y = region_y * region_size
	var scale = float(region_size) / float(resolution)
	
	for y in range(resolution):
		for x in range(resolution):
			var world_x = world_offset_x + x * scale
			var world_y = world_offset_y + y * scale
			var height = _sample_terrain_height_world(world_x, world_y)
			heightmap.set_pixel(x, y, Color(height, height, height, 1.0))
	
	return heightmap


## Sample terrain height at a normalized position
## Requirement 53.2: Multiple octaves of noise for realistic features
func _sample_terrain_height(x: int, y: int, resolution: int) -> float:
	"""Sample terrain height at a grid position."""
	var nx = float(x) / float(resolution)
	var ny = float(y) / float(resolution)
	
	# Get base terrain height from noise
	var base_height = _terrain_noise.get_noise_2d(x, y)
	
	# Normalize from [-1, 1] to [0, 1]
	base_height = (base_height + 1.0) * 0.5
	
	# Add detail noise for surface variation
	var detail = _detail_noise.get_noise_2d(x * 4, y * 4) * 0.1
	
	# Combine and clamp
	var final_height = clampf(base_height + detail, 0.0, 1.0)
	
	return final_height


## Sample terrain height at world coordinates
func _sample_terrain_height_world(world_x: float, world_y: float) -> float:
	"""Sample terrain height at world coordinates."""
	var base_height = _terrain_noise.get_noise_2d(world_x, world_y)
	base_height = (base_height + 1.0) * 0.5
	
	var detail = _detail_noise.get_noise_2d(world_x * 4, world_y * 4) * 0.1
	
	return clampf(base_height + detail, 0.0, 1.0)


## Apply crater modifications to heightmap
## Requirement 53.3: Generate surface details (craters) procedurally
func _apply_craters(heightmap: Image, planet_seed: int, resolution: int) -> void:
	"""Apply crater deformations to the heightmap."""
	# Use deterministic random for crater placement
	var rng = RandomNumberGenerator.new()
	rng.seed = planet_seed + HASH_PRIME_1
	
	# Determine number of craters based on probability
	if rng.randf() > CRATER_PROBABILITY:
		return
	
	var num_craters = rng.randi_range(1, MAX_CRATERS_PER_REGION)
	
	for _i in range(num_craters):
		var crater_x = rng.randi_range(0, resolution - 1)
		var crater_y = rng.randi_range(0, resolution - 1)
		var crater_radius = rng.randf_range(MIN_CRATER_RADIUS, MAX_CRATER_RADIUS)
		var crater_depth = rng.randf_range(0.1, 0.3)
		
		_apply_single_crater(heightmap, crater_x, crater_y, 
							 crater_radius / resolution * 100, crater_depth)


## Apply a single crater to the heightmap
func _apply_single_crater(heightmap: Image, center_x: int, center_y: int, 
						  radius: float, depth: float) -> void:
	"""Apply a single crater deformation."""
	var resolution = heightmap.get_width()
	var pixel_radius = int(radius * resolution / 100.0)
	
	for dy in range(-pixel_radius, pixel_radius + 1):
		for dx in range(-pixel_radius, pixel_radius + 1):
			var px = center_x + dx
			var py = center_y + dy
			
			if px < 0 or px >= resolution or py < 0 or py >= resolution:
				continue
			
			var dist = sqrt(dx * dx + dy * dy)
			if dist > pixel_radius:
				continue
			
			# Crater profile: bowl shape with raised rim
			var normalized_dist = dist / pixel_radius
			var crater_factor: float
			
			if normalized_dist < 0.8:
				# Inside crater: depression
				crater_factor = -depth * (1.0 - normalized_dist / 0.8)
			else:
				# Rim: slight elevation
				var rim_factor = (normalized_dist - 0.8) / 0.2
				crater_factor = depth * 0.2 * (1.0 - rim_factor)
			
			var current_color = heightmap.get_pixel(px, py)
			var new_height = clampf(current_color.r + crater_factor, 0.0, 1.0)
			heightmap.set_pixel(px, py, Color(new_height, new_height, new_height, 1.0))

#endregion



#region Terrain Mesh Generation

## Generate a terrain mesh from a heightmap
## Requirement 53.5: Use lower LOD meshes for distant terrain
func generate_terrain_mesh(heightmap: Image, lod_level: LODLevel = LODLevel.MEDIUM) -> ArrayMesh:
	"""Generate a terrain mesh from a heightmap at the specified LOD level."""
	var resolution = LOD_RESOLUTIONS[lod_level]
	var mesh = ArrayMesh.new()
	
	# Resize heightmap to match LOD resolution if needed
	var working_heightmap = heightmap
	if heightmap.get_width() != resolution:
		working_heightmap = heightmap.duplicate()
		working_heightmap.resize(resolution, resolution, Image.INTERPOLATE_BILINEAR)
	
	# Generate mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate vertices
	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []
	
	for y in range(resolution):
		for x in range(resolution):
			var height = working_heightmap.get_pixel(x, y).r * height_scale
			var vertex = Vector3(
				float(x) - resolution * 0.5,
				height,
				float(y) - resolution * 0.5
			)
			vertices.append(vertex)
			uvs.append(Vector2(float(x) / resolution, float(y) / resolution))
	
	# Calculate normals
	normals = _calculate_normals(vertices, resolution)
	
	# Generate triangles
	for y in range(resolution - 1):
		for x in range(resolution - 1):
			var idx = y * resolution + x
			var idx_right = idx + 1
			var idx_down = idx + resolution
			var idx_down_right = idx + resolution + 1
			
			# First triangle
			surface_tool.set_uv(uvs[idx])
			surface_tool.set_normal(normals[idx])
			surface_tool.add_vertex(vertices[idx])
			
			surface_tool.set_uv(uvs[idx_down])
			surface_tool.set_normal(normals[idx_down])
			surface_tool.add_vertex(vertices[idx_down])
			
			surface_tool.set_uv(uvs[idx_right])
			surface_tool.set_normal(normals[idx_right])
			surface_tool.add_vertex(vertices[idx_right])
			
			# Second triangle
			surface_tool.set_uv(uvs[idx_right])
			surface_tool.set_normal(normals[idx_right])
			surface_tool.add_vertex(vertices[idx_right])
			
			surface_tool.set_uv(uvs[idx_down])
			surface_tool.set_normal(normals[idx_down])
			surface_tool.add_vertex(vertices[idx_down])
			
			surface_tool.set_uv(uvs[idx_down_right])
			surface_tool.set_normal(normals[idx_down_right])
			surface_tool.add_vertex(vertices[idx_down_right])
	
	mesh = surface_tool.commit()
	
	terrain_mesh_generated.emit(mesh, lod_level)
	return mesh


## Generate terrain mesh using ArrayMesh directly (more efficient for large meshes)
func generate_terrain_mesh_array(heightmap: Image, lod_level: LODLevel = LODLevel.MEDIUM) -> ArrayMesh:
	"""Generate terrain mesh using ArrayMesh for better performance."""
	var resolution = LOD_RESOLUTIONS[lod_level]
	
	# Resize heightmap if needed
	var working_heightmap = heightmap
	if heightmap.get_width() != resolution:
		working_heightmap = heightmap.duplicate()
		working_heightmap.resize(resolution, resolution, Image.INTERPOLATE_BILINEAR)
	
	# Create arrays for mesh data
	var vertices = PackedVector3Array()
	var normals_array = PackedVector3Array()
	var uvs_array = PackedVector2Array()
	var indices = PackedInt32Array()
	
	vertices.resize(resolution * resolution)
	uvs_array.resize(resolution * resolution)
	
	# Generate vertices and UVs
	for y in range(resolution):
		for x in range(resolution):
			var idx = y * resolution + x
			var height = working_heightmap.get_pixel(x, y).r * height_scale
			
			vertices[idx] = Vector3(
				float(x) - resolution * 0.5,
				height,
				float(y) - resolution * 0.5
			)
			uvs_array[idx] = Vector2(float(x) / resolution, float(y) / resolution)
	
	# Calculate normals
	var normals_list = _calculate_normals_packed(vertices, resolution)
	normals_array = PackedVector3Array(normals_list)
	
	# Generate indices for triangles
	var num_triangles = (resolution - 1) * (resolution - 1) * 2
	indices.resize(num_triangles * 3)
	
	var index_offset = 0
	for y in range(resolution - 1):
		for x in range(resolution - 1):
			var idx = y * resolution + x
			
			# First triangle
			indices[index_offset] = idx
			indices[index_offset + 1] = idx + resolution
			indices[index_offset + 2] = idx + 1
			
			# Second triangle
			indices[index_offset + 3] = idx + 1
			indices[index_offset + 4] = idx + resolution
			indices[index_offset + 5] = idx + resolution + 1
			
			index_offset += 6
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals_array
	arrays[Mesh.ARRAY_TEX_UV] = uvs_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	terrain_mesh_generated.emit(mesh, lod_level)
	return mesh


## Calculate normals for terrain vertices
func _calculate_normals(vertices: Array[Vector3], resolution: int) -> Array[Vector3]:
	"""Calculate normals for terrain vertices using central differences."""
	var normals: Array[Vector3] = []
	normals.resize(vertices.size())
	
	for y in range(resolution):
		for x in range(resolution):
			var idx = y * resolution + x
			
			# Get neighboring heights
			var left_idx = y * resolution + maxi(x - 1, 0)
			var right_idx = y * resolution + mini(x + 1, resolution - 1)
			var up_idx = maxi(y - 1, 0) * resolution + x
			var down_idx = mini(y + 1, resolution - 1) * resolution + x
			
			var left = vertices[left_idx]
			var right = vertices[right_idx]
			var up = vertices[up_idx]
			var down = vertices[down_idx]
			
			# Calculate normal using cross product of tangent vectors
			var tangent_x = right - left
			var tangent_z = down - up
			var normal = tangent_z.cross(tangent_x).normalized()
			
			normals[idx] = normal
	
	return normals


## Calculate normals for packed vertex array
func _calculate_normals_packed(vertices: PackedVector3Array, resolution: int) -> Array[Vector3]:
	"""Calculate normals for packed vertex array."""
	var normals: Array[Vector3] = []
	normals.resize(vertices.size())
	
	for y in range(resolution):
		for x in range(resolution):
			var idx = y * resolution + x
			
			var left_idx = y * resolution + maxi(x - 1, 0)
			var right_idx = y * resolution + mini(x + 1, resolution - 1)
			var up_idx = maxi(y - 1, 0) * resolution + x
			var down_idx = mini(y + 1, resolution - 1) * resolution + x
			
			var left = vertices[left_idx]
			var right = vertices[right_idx]
			var up = vertices[up_idx]
			var down = vertices[down_idx]
			
			var tangent_x = right - left
			var tangent_z = down - up
			var normal = tangent_z.cross(tangent_x).normalized()
			
			normals[idx] = normal
	
	return normals

#endregion


#region Normal Map Generation

## Generate a normal map from a heightmap
func generate_normal_map(heightmap: Image) -> Image:
	"""Generate a normal map from a heightmap for surface detail."""
	var resolution = heightmap.get_width()
	var normal_map = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	
	for y in range(resolution):
		for x in range(resolution):
			# Sample neighboring heights
			var left_x = maxi(x - 1, 0)
			var right_x = mini(x + 1, resolution - 1)
			var up_y = maxi(y - 1, 0)
			var down_y = mini(y + 1, resolution - 1)
			
			var left = heightmap.get_pixel(left_x, y).r
			var right = heightmap.get_pixel(right_x, y).r
			var up = heightmap.get_pixel(x, up_y).r
			var down = heightmap.get_pixel(x, down_y).r
			
			# Calculate normal using Sobel operator
			var dx = (right - left) * height_scale
			var dy = (down - up) * height_scale
			
			var normal = Vector3(-dx, 2.0, -dy).normalized()
			
			# Convert from [-1, 1] to [0, 1] for storage
			var color = Color(
				normal.x * 0.5 + 0.5,
				normal.y * 0.5 + 0.5,
				normal.z * 0.5 + 0.5,
				1.0
			)
			
			normal_map.set_pixel(x, y, color)
	
	normal_map_generated.emit(normal_map)
	return normal_map

#endregion


#region Biome System

## Determine biome type at a position based on planet properties
## Requirement 53.3: Generate surface details procedurally
func determine_biome(planet_seed: int, x: float, y: float, 
					 height: float, temperature: float, moisture: float) -> BiomeType:
	"""Determine the biome type at a given position."""
	_set_seed(planet_seed)
	
	# Get biome noise value for variation
	var biome_value = _biome_noise.get_noise_2d(x, y)
	biome_value = (biome_value + 1.0) * 0.5  # Normalize to [0, 1]
	
	# Determine biome based on temperature, moisture, and height
	if height > 0.8:
		# High altitude: ice or barren
		if temperature < 0.3:
			return BiomeType.ICE
		else:
			return BiomeType.BARREN
	
	if height < 0.2:
		# Low altitude: ocean or volcanic
		if temperature > 0.8:
			return BiomeType.VOLCANIC
		else:
			return BiomeType.OCEAN
	
	# Mid altitude: depends on temperature and moisture
	if temperature < 0.2:
		return BiomeType.ICE
	elif temperature > 0.8:
		if moisture < 0.3:
			return BiomeType.DESERT
		else:
			return BiomeType.VOLCANIC
	else:
		if moisture > 0.6:
			return BiomeType.FOREST
		elif moisture < 0.3:
			return BiomeType.DESERT
		else:
			# Use biome noise for variation
			if biome_value > 0.7:
				return BiomeType.TOXIC
			else:
				return BiomeType.BARREN
	
	return BiomeType.BARREN


## Get color for a biome type
func get_biome_color(biome: BiomeType) -> Color:
	"""Get the base color for a biome type."""
	match biome:
		BiomeType.ICE:
			return Color(0.9, 0.95, 1.0)
		BiomeType.DESERT:
			return Color(0.9, 0.8, 0.5)
		BiomeType.FOREST:
			return Color(0.2, 0.5, 0.2)
		BiomeType.OCEAN:
			return Color(0.1, 0.3, 0.6)
		BiomeType.VOLCANIC:
			return Color(0.3, 0.1, 0.05)
		BiomeType.BARREN:
			return Color(0.5, 0.45, 0.4)
		BiomeType.TOXIC:
			return Color(0.4, 0.5, 0.2)
	
	return Color(0.5, 0.5, 0.5)


## Apply biome-based coloring to a mesh
func apply_biome_colors_to_mesh(mesh: ArrayMesh, heightmap: Image,
						planet_seed: int, temperature: float = 0.5,
						moisture: float = 0.5) -> StandardMaterial3D:
	"""Create a material with biome-based vertex colors."""
	var resolution = heightmap.get_width()
	
	# Generate biome color texture
	var color_map = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	
	for y in range(resolution):
		for x in range(resolution):
			var height = heightmap.get_pixel(x, y).r
			var biome = determine_biome(planet_seed, float(x), float(y),
									   height, temperature, moisture)
			var color = get_biome_color(biome)
			
			# Add some variation based on height
			var height_variation = (height - 0.5) * 0.2
			color = color.lightened(height_variation)
			
			color_map.set_pixel(x, y, color)
	
	# Create texture from color map
	var texture = ImageTexture.create_from_image(color_map)
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.8
	material.metallic = 0.0
	
	return material


## Generate a biome map for a planet
func generate_biome_map(planet_seed: int, resolution: int,
						temperature: float = 0.5, moisture: float = 0.5) -> Image:
	"""Generate a biome distribution map for a planet."""
	var heightmap = generate_heightmap(planet_seed, resolution)
	var biome_map = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	
	for y in range(resolution):
		for x in range(resolution):
			var height = heightmap.get_pixel(x, y).r
			var biome = determine_biome(planet_seed, float(x), float(y),
									   height, temperature, moisture)
			var color = get_biome_color(biome)
			biome_map.set_pixel(x, y, color)
	
	return biome_map

#endregion


#region Surface Detail Generation

## Generate surface details (rocks, vegetation) for a region
## Requirement 53.3: Generate surface details procedurally
func generate_surface_details(planet_seed: int, region_x: float, region_y: float,
							  region_size: float, biome: BiomeType) -> Array[Dictionary]:
	"""Generate surface detail objects for a region."""
	var details: Array[Dictionary] = []
	
	# Use deterministic random for detail placement
	var rng = RandomNumberGenerator.new()
	var region_hash = _hash_region(planet_seed, int(region_x), int(region_y))
	rng.seed = region_hash
	
	# Determine detail density based on biome
	var density = _get_biome_detail_density(biome)
	var num_details = int(density * region_size * region_size / 100.0)
	
	for _i in range(num_details):
		var detail = _generate_single_detail(rng, region_x, region_y, region_size, biome)
		if detail.size() > 0:
			details.append(detail)
	
	return details


## Generate a single surface detail object
func _generate_single_detail(rng: RandomNumberGenerator, region_x: float, 
							 region_y: float, region_size: float, 
							 biome: BiomeType) -> Dictionary:
	"""Generate a single surface detail object."""
	var detail_type = _get_random_detail_type(rng, biome)
	if detail_type.is_empty():
		return {}
	
	var local_x = rng.randf() * region_size
	var local_y = rng.randf() * region_size
	var scale = rng.randf_range(0.5, 2.0)
	var rotation = rng.randf() * TAU
	
	return {
		"type": detail_type,
		"position": Vector2(region_x + local_x, region_y + local_y),
		"scale": scale,
		"rotation": rotation
	}


## Get detail density for a biome
func _get_biome_detail_density(biome: BiomeType) -> float:
	"""Get the detail object density for a biome."""
	match biome:
		BiomeType.FOREST:
			return 0.8  # High density for forests
		BiomeType.DESERT:
			return 0.2  # Low density for deserts
		BiomeType.ICE:
			return 0.1  # Very low for ice
		BiomeType.VOLCANIC:
			return 0.3  # Some rocks
		BiomeType.BARREN:
			return 0.4  # Moderate rocks
		BiomeType.TOXIC:
			return 0.5  # Strange formations
		BiomeType.OCEAN:
			return 0.0  # No surface details underwater
	
	return 0.3


## Get a random detail type for a biome
func _get_random_detail_type(rng: RandomNumberGenerator, biome: BiomeType) -> String:
	"""Get a random detail type appropriate for the biome."""
	var types: Array[String] = []
	
	match biome:
		BiomeType.FOREST:
			types = ["tree", "bush", "rock", "grass"]
		BiomeType.DESERT:
			types = ["rock", "cactus", "dune"]
		BiomeType.ICE:
			types = ["ice_spike", "snow_mound"]
		BiomeType.VOLCANIC:
			types = ["rock", "lava_rock", "vent"]
		BiomeType.BARREN:
			types = ["rock", "boulder", "pebbles"]
		BiomeType.TOXIC:
			types = ["crystal", "fungus", "rock"]
		BiomeType.OCEAN:
			return ""
	
	if types.is_empty():
		return ""
	
	return types[rng.randi() % types.size()]


## Hash a region for deterministic detail generation
func _hash_region(planet_seed: int, region_x: int, region_y: int) -> int:
	"""Generate a deterministic hash for a region."""
	var hash_value = planet_seed
	hash_value ^= region_x * HASH_PRIME_1
	hash_value ^= region_y * HASH_PRIME_2
	hash_value ^= (hash_value >> 13)
	hash_value ^= (hash_value << 7)
	return absi(hash_value)

#endregion


#region Seed and Cache Management

## Set the seed for all noise generators
## Requirement 53.1, 53.4: Deterministic generation from seed
func _set_seed(seed_value: int) -> void:
	"""Set the seed for deterministic generation."""
	if _current_seed == seed_value:
		return
	
	_current_seed = seed_value
	
	if _terrain_noise:
		_terrain_noise.seed = seed_value
	if _biome_noise:
		_biome_noise.seed = seed_value + HASH_PRIME_1
	if _detail_noise:
		_detail_noise.seed = seed_value + HASH_PRIME_2


## Create a cache key for heightmaps
func _make_cache_key(planet_seed: int, resolution: int) -> String:
	"""Create a unique cache key."""
	return "%d_%d" % [planet_seed, resolution]


## Cache a heightmap
func _cache_heightmap(key: String, heightmap: Image) -> void:
	"""Cache a heightmap, evicting old entries if necessary."""
	if _heightmap_cache.size() >= _max_cache_size:
		var first_key = _heightmap_cache.keys()[0]
		_heightmap_cache.erase(first_key)
	
	_heightmap_cache[key] = heightmap


## Clear the heightmap cache
func clear_cache() -> void:
	"""Clear the heightmap cache."""
	_heightmap_cache.clear()


## Set maximum cache size
func set_max_cache_size(size: int) -> void:
	"""Set the maximum cache size."""
	_max_cache_size = maxi(size, 1)

#endregion


#region Configuration Methods

## Configure noise parameters
func configure_noise(octaves: int = DEFAULT_OCTAVES, 
					 persistence: float = DEFAULT_PERSISTENCE,
					 lacunarity: float = DEFAULT_LACUNARITY,
					 frequency: float = DEFAULT_FREQUENCY) -> void:
	"""Configure the noise generator parameters."""
	noise_octaves = octaves
	noise_persistence = persistence
	noise_lacunarity = lacunarity
	base_frequency = frequency
	
	if _terrain_noise:
		_terrain_noise.fractal_octaves = noise_octaves
		_terrain_noise.fractal_gain = noise_persistence
		_terrain_noise.fractal_lacunarity = noise_lacunarity
		_terrain_noise.frequency = base_frequency


## Get current configuration
func get_configuration() -> Dictionary:
	"""Get the current generator configuration."""
	return {
		"noise_octaves": noise_octaves,
		"noise_persistence": noise_persistence,
		"noise_lacunarity": noise_lacunarity,
		"base_frequency": base_frequency,
		"height_scale": height_scale,
		"generate_craters": generate_craters,
		"apply_biome_colors": apply_biome_colors,
		"cache_size": _heightmap_cache.size(),
		"max_cache_size": _max_cache_size
	}

#endregion


#region Utility Methods

## Generate a complete planet terrain package
func generate_planet_terrain(planet_seed: int, lod_level: LODLevel = LODLevel.MEDIUM,
							 temperature: float = 0.5, moisture: float = 0.5) -> Dictionary:
	"""Generate a complete terrain package for a planet."""
	var resolution = LOD_RESOLUTIONS[lod_level]
	
	# Generate heightmap
	var heightmap = generate_heightmap(planet_seed, resolution)
	
	# Generate normal map
	var normal_map = generate_normal_map(heightmap)
	
	# Generate mesh
	var mesh = generate_terrain_mesh_array(heightmap, lod_level)
	
	# Generate material with biome colors
	var material = apply_biome_colors_to_mesh(mesh, heightmap, planet_seed, temperature, moisture)
	
	# Apply normal map to material
	var normal_texture = ImageTexture.create_from_image(normal_map)
	material.normal_enabled = true
	material.normal_texture = normal_texture
	
	return {
		"heightmap": heightmap,
		"normal_map": normal_map,
		"mesh": mesh,
		"material": material,
		"lod_level": lod_level,
		"resolution": resolution,
		"planet_seed": planet_seed
	}


## Get the recommended LOD level based on distance
## Requirement 53.5: Progressive detail based on distance
func get_lod_for_distance(distance: float) -> LODLevel:
	"""Get the recommended LOD level based on distance from the planet."""
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


## Validate that terrain generation is deterministic
## Requirement 53.4: Same coordinates always produce identical terrain
func validate_determinism(planet_seed: int, resolution: int = 64) -> bool:
	"""Validate that terrain generation is deterministic."""
	# Generate heightmap twice
	clear_cache()
	var heightmap1 = generate_heightmap(planet_seed, resolution)
	
	clear_cache()
	var heightmap2 = generate_heightmap(planet_seed, resolution)
	
	# Compare all pixels
	for y in range(resolution):
		for x in range(resolution):
			var h1 = heightmap1.get_pixel(x, y).r
			var h2 = heightmap2.get_pixel(x, y).r
			if absf(h1 - h2) > 0.0001:
				return false
	
	return true

#endregion


#region VoxelTerrain Integration

## Create a VoxelTerrain node for a planet
## This integrates existing PlanetGenerator with voxel terrain system
func create_voxel_terrain(planet_seed: int, planet_type: String = "rocky",
						  planet_radius_m: float = 1000.0) -> Node3D:
	"""Create a VoxelTerrain node with procedurally generated terrain."""

	# Check if godot_voxel plugin is available
	if not ClassDB.class_exists("VoxelTerrain"):
		push_error("VoxelTerrain class not available - godot_voxel plugin not loaded")
		return null

	# Set seed for deterministic generation
	_set_seed(planet_seed)

	# Create VoxelTerrain node
	var terrain: Node3D = ClassDB.instantiate("VoxelTerrain")
	if terrain == null:
		push_error("Failed to instantiate VoxelTerrain")
		return null

	# Create stream for the terrain using our noise generators
	var stream = _create_voxel_stream(planet_seed, planet_type, planet_radius_m)
	if stream:
		terrain.call("set_stream", stream)

	# Configure terrain properties
	terrain.call("set_generate_collisions", true)

	# Set view distance based on planet radius (smaller planets = smaller view distance)
	var view_distance := _calculate_voxel_view_distance(planet_radius_m)
	terrain.call("set_view_distance", view_distance)

	# Configure collision layers
	terrain.set("collision_layer", 1)  # Terrain on layer 1
	terrain.set("collision_mask", 0)   # Terrain doesn't detect collisions

	# Set mesher for smooth terrain
	var mesher = _create_voxel_mesher()
	if mesher:
		terrain.call("set_mesher", mesher)

	print("[PlanetGenerator] Created VoxelTerrain: seed=%d, radius=%.1fm, view_distance=%d"
		  % [planet_seed, planet_radius_m, view_distance])

	return terrain


## Create a voxel stream that uses our noise generators
func _create_voxel_stream(planet_seed: int, planet_type: String, radius: float) -> Object:
	"""Create a VoxelStream configured with planet-specific noise."""

	# Check if VoxelGeneratorNoise is available
	if not ClassDB.class_exists("VoxelGeneratorNoise"):
		push_warning("VoxelGeneratorNoise not available, using basic generator")
		return _create_basic_voxel_stream()

	var generator = ClassDB.instantiate("VoxelGeneratorNoise")
	if generator == null:
		return _create_basic_voxel_stream()

	# Configure noise parameters from our settings
	generator.set("seed", planet_seed)
	generator.set("height_range", height_scale)

	# Adjust parameters based on planet type
	var type_params := _get_planet_type_params(planet_type)

	# Set noise frequency based on planet radius (larger planets = lower frequency)
	var terrain_frequency := base_frequency * (1000.0 / maxf(radius, 100.0))
	generator.set("frequency", terrain_frequency)

	# Create and configure the stream
	if ClassDB.class_exists("VoxelStreamNoise"):
		var stream = ClassDB.instantiate("VoxelStreamNoise")
		if stream:
			stream.set("generator", generator)
			return stream

	return generator


## Create a basic voxel stream for fallback
func _create_basic_voxel_stream() -> Object:
	"""Create a basic flat terrain stream as fallback."""
	if ClassDB.class_exists("VoxelGeneratorFlat"):
		var generator = ClassDB.instantiate("VoxelGeneratorFlat")
		if generator:
			generator.set("height", 0.0)
			return generator
	return null


## Create a voxel mesher for smooth terrain
func _create_voxel_mesher() -> Object:
	"""Create a VoxelMesher for smooth terrain rendering."""

	# Try to use smooth mesher
	if ClassDB.class_exists("VoxelMesherTransvoxel"):
		var mesher = ClassDB.instantiate("VoxelMesherTransvoxel")
		return mesher

	# Fallback to blocky mesher
	if ClassDB.class_exists("VoxelMesherBlocky"):
		var mesher = ClassDB.instantiate("VoxelMesherBlocky")
		return mesher

	return null


## Calculate appropriate view distance for voxel terrain based on planet radius
func _calculate_voxel_view_distance(radius: float) -> int:
	"""Calculate view distance based on planet size."""

	# Small planets (< 500m radius): 128 view distance
	if radius < 500.0:
		return 128

	# Medium planets (500-2000m): 256 view distance
	elif radius < 2000.0:
		return 256

	# Large planets (> 2000m): 512 view distance
	else:
		return 512


## Get terrain parameters based on planet type
func _get_planet_type_params(planet_type: String) -> Dictionary:
	"""Get terrain generation parameters based on planet type."""

	match planet_type.to_lower():
		"rocky":
			return {
				"height_scale": height_scale,
				"roughness": 0.8,
				"crater_probability": CRATER_PROBABILITY
			}
		"ice":
			return {
				"height_scale": height_scale * 0.6,  # Smoother terrain
				"roughness": 0.5,
				"crater_probability": CRATER_PROBABILITY * 1.5  # More craters
			}
		"gas":
			return {
				"height_scale": height_scale * 2.0,  # Very rough atmosphere
				"roughness": 1.0,
				"crater_probability": 0.0  # No craters on gas giants
			}
		"volcanic":
			return {
				"height_scale": height_scale * 1.5,  # Rough volcanic terrain
				"roughness": 0.9,
				"crater_probability": CRATER_PROBABILITY * 0.5  # Fewer craters
			}
		"desert":
			return {
				"height_scale": height_scale * 0.8,  # Rolling dunes
				"roughness": 0.6,
				"crater_probability": CRATER_PROBABILITY
			}
		_:
			# Default rocky planet
			return {
				"height_scale": height_scale,
				"roughness": 0.7,
				"crater_probability": CRATER_PROBABILITY
			}


## Generate planet terrain using voxel system
## This maintains compatibility with existing code while adding voxel support
func generate_planet_terrain_voxel(planet_seed: int, planet_type: String = "rocky",
								   planet_radius_m: float = 1000.0) -> Dictionary:
	"""Generate planet terrain using voxel system."""

	var terrain_node := create_voxel_terrain(planet_seed, planet_type, planet_radius_m)

	if terrain_node == null:
		push_error("Failed to create voxel terrain")
		return {}

	return {
		"terrain_node": terrain_node,
		"terrain_type": "voxel",
		"planet_seed": planet_seed,
		"planet_type": planet_type,
		"planet_radius": planet_radius_m
	}

#endregion
