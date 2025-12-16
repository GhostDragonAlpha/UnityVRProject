## StarCatalog - Stellar Background Rendering System
## Renders accurate star fields based on real stellar catalog data (Hipparcos/Gaia).
## Uses MultiMesh for efficient rendering of thousands of stars as point sources.
##
## Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 24.5
## - 17.1: Display stars based on real stellar catalog data (Hipparcos or Gaia)
## - 17.2: Render stars with accurate positions, magnitudes, and colors
## - 17.3: Maintain point-source rendering to prevent unrealistic disk appearance
## - 17.4: Display the galactic plane (Milky Way) with appropriate brightness
## - 17.5: Occlude background stars behind planet silhouettes
## - 24.5: Display the galactic plane with appropriate brightness and structure
extends Node3D
class_name StarCatalog

## Emitted when the star catalog is fully loaded
signal catalog_loaded(star_count: int)
## Emitted when star visibility changes due to occlusion
signal stars_occluded(occluded_count: int)
## Emitted when the Milky Way visibility changes
signal milky_way_visibility_changed(visible: bool)

## Star data structure for internal use
class StarData:
	var id: int = 0
	var right_ascension: float = 0.0  # Radians
	var declination: float = 0.0       # Radians
	var magnitude: float = 0.0         # Apparent magnitude
	var color_index: float = 0.0       # B-V color index
	var position: Vector3 = Vector3.ZERO  # Cartesian position on celestial sphere
	var color: Color = Color.WHITE
	var size: float = 1.0

## Constants for star rendering
const CELESTIAL_SPHERE_RADIUS: float = 100000.0  # Large radius for background stars
const MIN_STAR_SIZE: float = 0.5
const MAX_STAR_SIZE: float = 4.0
const MAGNITUDE_LIMIT: float = 6.5  # Naked eye visibility limit
const BRIGHT_STAR_MAGNITUDE: float = 2.0  # Stars brighter than this get extra glow

## Spectral type temperature ranges (Kelvin) for color calculation
const SPECTRAL_TEMPERATURES: Dictionary = {
	"O": 30000.0,
	"B": 20000.0,
	"A": 9500.0,
	"F": 7200.0,
	"G": 5800.0,  # Sun-like
	"K": 4500.0,
	"M": 3200.0
}

## Milky Way rendering parameters
const MILKY_WAY_PARTICLE_COUNT: int = 50000
const MILKY_WAY_WIDTH: float = 15.0  # Degrees from galactic plane
const GALACTIC_CENTER_RA: float = 266.4  # Degrees (Sagittarius)
const GALACTIC_CENTER_DEC: float = -29.0  # Degrees

#region Exported Properties

## Path to the star catalog data file (JSON or CSV)
@export var catalog_path: String = "res://data/ephemeris/star_catalog.json"

## Maximum number of stars to render
@export var max_stars: int = 10000

## Minimum apparent magnitude to display (higher = dimmer)
@export var magnitude_cutoff: float = 6.5

## Base size multiplier for star points
@export var star_size_multiplier: float = 1.0

## Enable Milky Way rendering
@export var render_milky_way: bool = true

## Milky Way brightness (0.0 to 1.0)
@export var milky_way_brightness: float = 0.3

## Enable star occlusion by planets
@export var enable_occlusion: bool = true

#endregion

#region Runtime Properties

## Array of loaded star data
var _stars: Array[StarData] = []

## MultiMeshInstance3D for rendering stars
var _star_mesh_instance: MultiMeshInstance3D = null

## MultiMesh resource for star instances
var _star_multimesh: MultiMesh = null

## GPUParticles3D for Milky Way rendering
var _milky_way_particles: GPUParticles3D = null

## Material for star rendering
var _star_material: ShaderMaterial = null

## List of occluding bodies (planets, moons)
var _occluding_bodies: Array[Node3D] = []

## Whether the catalog is loaded
var _is_loaded: bool = false

## Camera reference for occlusion calculations
var _camera: Camera3D = null

#endregion


func _ready() -> void:
	_setup_star_rendering()
	if render_milky_way:
		_setup_milky_way()


## Initialize the star catalog system
func initialize() -> bool:
	"""Initialize the star catalog and load star data."""
	if _is_loaded:
		return true
	
	# Try to load from file first
	if FileAccess.file_exists(catalog_path):
		if _load_catalog_from_file(catalog_path):
			_update_star_instances()
			_is_loaded = true
			catalog_loaded.emit(_stars.size())
			return true
	
	# Fall back to generating procedural stars based on real catalog patterns
	_generate_procedural_catalog()
	_update_star_instances()
	_is_loaded = true
	catalog_loaded.emit(_stars.size())
	print("StarCatalog: Initialized with %d stars" % _stars.size())
	return true


## Setup the MultiMesh for star rendering
## Requirements 17.3: Maintain point-source rendering
func _setup_star_rendering() -> void:
	"""Set up the MultiMesh system for efficient star rendering."""
	# Create MultiMeshInstance3D
	_star_mesh_instance = MultiMeshInstance3D.new()
	_star_mesh_instance.name = "StarField"
	add_child(_star_mesh_instance)
	
	# Create the MultiMesh
	_star_multimesh = MultiMesh.new()
	_star_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_star_multimesh.use_colors = true
	_star_multimesh.use_custom_data = true  # For magnitude/size data
	
	# Create a simple quad mesh for each star (billboard)
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(1.0, 1.0)
	_star_multimesh.mesh = quad_mesh
	
	# Create star material with billboard and additive blending
	_star_material = _create_star_material()
	_star_mesh_instance.material_override = _star_material
	
	_star_mesh_instance.multimesh = _star_multimesh
	
	# Disable shadows and ensure always visible
	_star_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_star_mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED


## Create the shader material for star rendering
func _create_star_material() -> ShaderMaterial:
	"""Create a shader material for point-source star rendering."""
	var material := ShaderMaterial.new()
	
	# Create a simple billboard shader for stars
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

instance uniform vec4 star_color : source_color = vec4(1.0);
instance uniform float star_size = 1.0;

varying flat vec4 v_color;

void vertex() {
	// Billboard transformation - always face camera
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(INV_VIEW_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]
	);
	
	// Scale by star size
	VERTEX *= star_size;
	
	// Pass color to fragment
	v_color = COLOR;
}

void fragment() {
	// Create circular point with soft edges
	vec2 uv_centered = UV * 2.0 - 1.0;
	float dist = length(uv_centered);
	
	// Soft circular falloff for point-source appearance
	float alpha = 1.0 - smoothstep(0.0, 1.0, dist);
	alpha = pow(alpha, 2.0);  // Sharper falloff
	
	// Add glow for brighter stars
	float glow = exp(-dist * 3.0) * 0.5;
	
	ALBEDO = v_color.rgb;
	ALPHA = (alpha + glow) * v_color.a;
	EMISSION = v_color.rgb * (alpha + glow * 2.0);
}
"""
	material.shader = shader
	return material


## Setup Milky Way particle system
## Requirements 17.4, 24.5: Display the galactic plane with appropriate brightness
func _setup_milky_way() -> void:
	"""Set up GPUParticles3D for Milky Way rendering."""
	_milky_way_particles = GPUParticles3D.new()
	_milky_way_particles.name = "MilkyWay"
	add_child(_milky_way_particles)
	
	# Configure particle system
	_milky_way_particles.amount = MILKY_WAY_PARTICLE_COUNT
	_milky_way_particles.lifetime = 1000.0  # Effectively infinite
	_milky_way_particles.one_shot = true
	_milky_way_particles.explosiveness = 1.0  # All particles spawn at once
	_milky_way_particles.fixed_fps = 0  # No animation needed
	
	# Create process material for Milky Way distribution
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = CELESTIAL_SPHERE_RADIUS
	process_material.direction = Vector3.ZERO
	process_material.spread = 180.0
	process_material.initial_velocity_min = 0.0
	process_material.initial_velocity_max = 0.0
	process_material.gravity = Vector3.ZERO
	
	# Scale for distant appearance
	process_material.scale_min = 50.0
	process_material.scale_max = 200.0
	
	_milky_way_particles.process_material = process_material
	
	# Create draw pass with quad mesh
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	_milky_way_particles.draw_pass_1 = quad
	
	# Create material for Milky Way particles
	var milky_way_material := _create_milky_way_material()
	_milky_way_particles.material_override = milky_way_material
	
	# Disable shadows
	_milky_way_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Restart to apply settings
	_milky_way_particles.restart()


## Create material for Milky Way rendering
func _create_milky_way_material() -> ShaderMaterial:
	"""Create shader material for Milky Way glow effect."""
	var material := ShaderMaterial.new()
	
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

uniform float brightness : hint_range(0.0, 1.0) = 0.3;
uniform vec3 milky_way_color : source_color = vec3(0.8, 0.85, 1.0);

void vertex() {
	// Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(INV_VIEW_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
	vec2 uv_centered = UV * 2.0 - 1.0;
	float dist = length(uv_centered);
	float alpha = exp(-dist * 2.0) * brightness;
	
	ALBEDO = milky_way_color;
	ALPHA = alpha * 0.1;
	EMISSION = milky_way_color * alpha * 0.5;
}
"""
	material.shader = shader
	material.set_shader_parameter("brightness", milky_way_brightness)
	return material


#region Catalog Loading

## Load star catalog from JSON file
## Requirements 17.1: Display stars based on real stellar catalog data
func _load_catalog_from_file(path: String) -> bool:
	"""Load star catalog from a JSON file."""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("StarCatalog: Could not open catalog file: %s" % path)
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("StarCatalog: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false
	
	var data = json.get_data()
	if not data is Dictionary or not data.has("stars"):
		push_error("StarCatalog: Invalid catalog format")
		return false
	
	_stars.clear()
	var stars_array: Array = data["stars"]
	var count := 0
	
	for star_dict in stars_array:
		if count >= max_stars:
			break
		
		var star := StarData.new()
		star.id = star_dict.get("id", count)
		star.right_ascension = deg_to_rad(star_dict.get("ra", 0.0))
		star.declination = deg_to_rad(star_dict.get("dec", 0.0))
		star.magnitude = star_dict.get("mag", 5.0)
		star.color_index = star_dict.get("bv", 0.65)  # Default to sun-like
		
		# Skip stars dimmer than cutoff
		if star.magnitude > magnitude_cutoff:
			continue
		
		# Calculate 3D position on celestial sphere
		star.position = _celestial_to_cartesian(star.right_ascension, star.declination)
		
		# Calculate color from B-V index
		star.color = _bv_to_color(star.color_index)
		
		# Calculate size from magnitude
		star.size = _magnitude_to_size(star.magnitude)
		
		_stars.append(star)
		count += 1
	
	print("StarCatalog: Loaded %d stars from %s" % [_stars.size(), path])
	return true


## Generate procedural star catalog based on real distribution patterns
## This is used when no catalog file is available
func _generate_procedural_catalog() -> void:
	"""Generate a procedural star catalog mimicking real stellar distribution."""
	_stars.clear()
	
	# Seed for reproducibility
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Fixed seed for deterministic generation
	
	var star_count := mini(max_stars, 9000)  # Approximate Hipparcos bright star count
	
	for i in range(star_count):
		var star := StarData.new()
		star.id = i
		
		# Generate position with galactic concentration
		var ra := rng.randf() * TAU  # 0 to 2π
		
		# Declination with slight concentration toward galactic plane
		var dec_raw := rng.randf() * 2.0 - 1.0  # -1 to 1
		var dec := asin(dec_raw)  # Convert to proper spherical distribution
		
		# Add galactic plane concentration
		var galactic_bias := rng.randf()
		if galactic_bias < 0.3:  # 30% of stars concentrated near galactic plane
			dec = dec * 0.3 + _get_galactic_latitude(ra) * 0.7
		
		star.right_ascension = ra
		star.declination = dec
		
		# Generate magnitude with realistic distribution
		# More dim stars than bright ones (exponential distribution)
		var mag_random := rng.randf()
		star.magnitude = -1.5 + pow(mag_random, 0.3) * (magnitude_cutoff + 1.5)
		
		# Skip if too dim
		if star.magnitude > magnitude_cutoff:
			continue
		
		# Generate B-V color index (most stars are G/K type)
		var bv_random := rng.randf()
		star.color_index = -0.3 + pow(bv_random, 0.7) * 2.3  # Range -0.3 to 2.0
		
		# Calculate derived properties
		star.position = _celestial_to_cartesian(star.right_ascension, star.declination)
		star.color = _bv_to_color(star.color_index)
		star.size = _magnitude_to_size(star.magnitude)
		
		_stars.append(star)
	
	print("StarCatalog: Generated %d procedural stars" % _stars.size())

#endregion


#region Coordinate Conversions

## Convert celestial coordinates (RA, Dec) to Cartesian position
## Requirements 17.2: Render stars with accurate positions
func _celestial_to_cartesian(ra: float, dec: float) -> Vector3:
	"""Convert right ascension and declination to 3D Cartesian coordinates."""
	# RA is measured eastward from vernal equinox
	# Dec is measured from celestial equator
	var cos_dec := cos(dec)
	return Vector3(
		CELESTIAL_SPHERE_RADIUS * cos_dec * cos(ra),
		CELESTIAL_SPHERE_RADIUS * sin(dec),
		CELESTIAL_SPHERE_RADIUS * cos_dec * sin(ra)
	)


## Get approximate galactic latitude for a given right ascension
func _get_galactic_latitude(ra: float) -> float:
	"""Get approximate galactic latitude for galactic plane concentration."""
	# Simplified galactic plane model
	# The galactic plane is tilted ~63° to the celestial equator
	var galactic_tilt := deg_to_rad(63.0)
	var galactic_node := deg_to_rad(282.0)  # Ascending node
	
	return sin(ra - galactic_node) * galactic_tilt

#endregion

#region Color and Magnitude Calculations

## Convert B-V color index to RGB color
## Requirements 17.2: Render stars with accurate colors
func _bv_to_color(bv: float) -> Color:
	"""Convert B-V color index to RGB color using blackbody approximation."""
	# Clamp B-V to valid range
	bv = clampf(bv, -0.4, 2.0)
	
	# Convert B-V to approximate temperature
	var temp := _bv_to_temperature(bv)
	
	# Convert temperature to RGB using Planck's law approximation
	return _temperature_to_color(temp)


## Convert B-V color index to temperature (Kelvin)
func _bv_to_temperature(bv: float) -> float:
	"""Convert B-V color index to effective temperature."""
	# Ballesteros formula (2012)
	# T = 4600 * (1 / (0.92 * BV + 1.7) + 1 / (0.92 * BV + 0.62))
	var t1 := 1.0 / (0.92 * bv + 1.7)
	var t2 := 1.0 / (0.92 * bv + 0.62)
	return 4600.0 * (t1 + t2)


## Convert temperature to RGB color
func _temperature_to_color(temp: float) -> Color:
	"""Convert blackbody temperature to RGB color."""
	# Simplified blackbody color calculation
	temp = clampf(temp, 1000.0, 40000.0)
	temp = temp / 100.0
	
	var r: float
	var g: float
	var b: float
	
	# Red
	if temp <= 66.0:
		r = 1.0
	else:
		r = 1.29293618606 * pow(temp - 60.0, -0.1332047592)
		r = clampf(r, 0.0, 1.0)
	
	# Green
	if temp <= 66.0:
		g = 0.390081578769 * log(temp) - 0.631841443788
	else:
		g = 1.12989086089 * pow(temp - 60.0, -0.0755148492)
	g = clampf(g, 0.0, 1.0)
	
	# Blue
	if temp >= 66.0:
		b = 1.0
	elif temp <= 19.0:
		b = 0.0
	else:
		b = 0.543206789110 * log(temp - 10.0) - 1.19625408914
		b = clampf(b, 0.0, 1.0)
	
	return Color(r, g, b, 1.0)


## Convert apparent magnitude to visual size
## Requirements 17.3: Maintain point-source rendering
func _magnitude_to_size(magnitude: float) -> float:
	"""Convert apparent magnitude to star point size."""
	# Brighter stars (lower magnitude) should appear larger
	# Use logarithmic scale: size = base_size * 10^((mag_ref - mag) / 2.5)
	var mag_ref := 6.0  # Reference magnitude (dim star)
	var size_factor := pow(10.0, (mag_ref - magnitude) / 2.5)
	
	# Clamp to reasonable range
	var size := MIN_STAR_SIZE + (MAX_STAR_SIZE - MIN_STAR_SIZE) * clampf(size_factor / 100.0, 0.0, 1.0)
	return size * star_size_multiplier

#endregion


#region Star Instance Management

## Update MultiMesh instances with star data
func _update_star_instances() -> void:
	"""Update the MultiMesh with current star data."""
	if _star_multimesh == null or _stars.is_empty():
		return
	
	_star_multimesh.instance_count = _stars.size()
	
	for i in range(_stars.size()):
		var star := _stars[i]
		
		# Create transform for star position
		var transform := Transform3D()
		transform.origin = star.position
		
		# Scale by star size
		transform = transform.scaled(Vector3.ONE * star.size)
		
		_star_multimesh.set_instance_transform(i, transform)
		_star_multimesh.set_instance_color(i, star.color)
		
		# Store magnitude in custom data for shader use
		_star_multimesh.set_instance_custom_data(i, Color(star.magnitude / 10.0, star.size, 0.0, 1.0))


## Update star visibility (called each frame if occlusion is enabled)
func _process(delta: float) -> void:
	if enable_occlusion and _camera != null:
		_update_occlusion()

#endregion

#region Star Occlusion

## Register an occluding body (planet, moon)
## Requirements 17.5: Occlude background stars behind planet silhouettes
func register_occluding_body(body: Node3D) -> void:
	"""Register a celestial body that can occlude stars."""
	if body != null and not _occluding_bodies.has(body):
		_occluding_bodies.append(body)


## Unregister an occluding body
func unregister_occluding_body(body: Node3D) -> void:
	"""Unregister a celestial body from occlusion."""
	_occluding_bodies.erase(body)


## Set the camera for occlusion calculations
func set_camera(camera: Camera3D) -> void:
	"""Set the camera reference for occlusion calculations."""
	_camera = camera


## Update star occlusion based on occluding bodies
## Requirements 17.5: Occlude background stars behind planet silhouettes
func _update_occlusion() -> void:
	"""Update star visibility based on occluding bodies."""
	if _camera == null or _occluding_bodies.is_empty():
		return
	
	var camera_pos := _camera.global_position
	var occluded_count := 0
	
	for i in range(_stars.size()):
		var star := _stars[i]
		var star_direction := star.position.normalized()
		
		var is_occluded := false
		
		for body in _occluding_bodies:
			if not is_instance_valid(body):
				continue
			
			# Check if star is behind the body from camera's perspective
			var body_pos := body.global_position
			var to_body := body_pos - camera_pos
			var body_distance := to_body.length()
			
			# Get body radius (assume it has a radius property or use scale)
			var body_radius := _get_body_radius(body)
			
			# Calculate angular size of body
			var angular_radius := atan(body_radius / body_distance)
			
			# Calculate angle between star direction and body direction
			var body_direction := to_body.normalized()
			var angle := acos(clampf(star_direction.dot(body_direction), -1.0, 1.0))
			
			# Star is occluded if within angular radius of body
			if angle < angular_radius:
				is_occluded = true
				occluded_count += 1
				break
		
		# Update star visibility (using alpha in color)
		var current_color := _star_multimesh.get_instance_color(i)
		if is_occluded:
			current_color.a = 0.0
		else:
			current_color.a = 1.0
		_star_multimesh.set_instance_color(i, current_color)
	
	if occluded_count > 0:
		stars_occluded.emit(occluded_count)


## Get the radius of an occluding body
func _get_body_radius(body: Node3D) -> float:
	"""Get the radius of an occluding body."""
	# Check if it's a CelestialBody
	if body.has_method("get") and body.get("radius") != null:
		return body.radius
	
	# Fall back to scale-based estimation
	var scale := body.scale
	return maxf(scale.x, maxf(scale.y, scale.z)) * 100.0  # Assume base radius of 100

#endregion


#region Public API

## Get the number of loaded stars
func get_star_count() -> int:
	"""Get the number of stars in the catalog."""
	return _stars.size()


## Check if the catalog is loaded
func is_loaded() -> bool:
	"""Check if the star catalog is loaded."""
	return _is_loaded


## Get star data by index
func get_star(index: int) -> StarData:
	"""Get star data by index."""
	if index >= 0 and index < _stars.size():
		return _stars[index]
	return null


## Get stars within a cone (for queries)
func get_stars_in_cone(direction: Vector3, half_angle: float) -> Array[StarData]:
	"""Get all stars within a cone defined by direction and half-angle."""
	var result: Array[StarData] = []
	var cos_half_angle := cos(half_angle)
	var dir_normalized := direction.normalized()
	
	for star in _stars:
		var star_dir := star.position.normalized()
		if star_dir.dot(dir_normalized) >= cos_half_angle:
			result.append(star)
	
	return result


## Get the brightest stars
func get_brightest_stars(count: int) -> Array[StarData]:
	"""Get the N brightest stars in the catalog."""
	var sorted_stars := _stars.duplicate()
	sorted_stars.sort_custom(func(a, b): return a.magnitude < b.magnitude)
	
	var result: Array[StarData] = []
	for i in range(mini(count, sorted_stars.size())):
		result.append(sorted_stars[i])
	
	return result


## Set the magnitude cutoff and refresh
func set_magnitude_cutoff(cutoff: float) -> void:
	"""Set the magnitude cutoff and refresh the display."""
	magnitude_cutoff = cutoff
	if _is_loaded:
		# Re-filter stars based on new cutoff
		var visible_count := 0
		for i in range(_stars.size()):
			var star := _stars[i]
			var color := _star_multimesh.get_instance_color(i)
			if star.magnitude <= cutoff:
				color.a = 1.0
				visible_count += 1
			else:
				color.a = 0.0
			_star_multimesh.set_instance_color(i, color)


## Set star size multiplier
func set_star_size_multiplier(multiplier: float) -> void:
	"""Set the star size multiplier and refresh."""
	star_size_multiplier = multiplier
	if _is_loaded:
		for i in range(_stars.size()):
			var star := _stars[i]
			star.size = _magnitude_to_size(star.magnitude)
			var transform := _star_multimesh.get_instance_transform(i)
			transform = Transform3D().translated(star.position).scaled(Vector3.ONE * star.size)
			_star_multimesh.set_instance_transform(i, transform)


## Set Milky Way brightness
func set_milky_way_brightness(brightness: float) -> void:
	"""Set the Milky Way brightness."""
	milky_way_brightness = clampf(brightness, 0.0, 1.0)
	if _milky_way_particles != null and _milky_way_particles.material_override != null:
		_milky_way_particles.material_override.set_shader_parameter("brightness", milky_way_brightness)


## Enable or disable Milky Way rendering
func set_milky_way_visible(visible: bool) -> void:
	"""Enable or disable Milky Way rendering."""
	render_milky_way = visible
	if _milky_way_particles != null:
		_milky_way_particles.visible = visible
	milky_way_visibility_changed.emit(visible)


## Get the MultiMeshInstance3D for external manipulation
func get_star_mesh_instance() -> MultiMeshInstance3D:
	"""Get the star field MultiMeshInstance3D."""
	return _star_mesh_instance


## Get the Milky Way particles node
func get_milky_way_particles() -> GPUParticles3D:
	"""Get the Milky Way GPUParticles3D node."""
	return _milky_way_particles

#endregion


#region Serialization

## Save star catalog to JSON file
func save_catalog(path: String) -> bool:
	"""Save the current star catalog to a JSON file."""
	var stars_array: Array = []
	
	for star in _stars:
		stars_array.append({
			"id": star.id,
			"ra": rad_to_deg(star.right_ascension),
			"dec": rad_to_deg(star.declination),
			"mag": star.magnitude,
			"bv": star.color_index
		})
	
	var data := {
		"format": "star_catalog",
		"version": "1.0",
		"source": "procedural",
		"star_count": _stars.size(),
		"stars": stars_array
	}
	
	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("StarCatalog: Could not write to file: %s" % path)
		return false
	
	file.store_string(json_text)
	file.close()
	
	print("StarCatalog: Saved %d stars to %s" % [_stars.size(), path])
	return true


## Load a subset of the Hipparcos catalog (bright stars)
## This creates a sample catalog file for testing
func generate_sample_catalog(output_path: String) -> bool:
	"""Generate a sample star catalog with well-known bright stars."""
	var sample_stars: Array = [
		# Name, RA (deg), Dec (deg), Magnitude, B-V
		{"name": "Sirius", "ra": 101.287, "dec": -16.716, "mag": -1.46, "bv": 0.00},
		{"name": "Canopus", "ra": 95.988, "dec": -52.696, "mag": -0.72, "bv": 0.15},
		{"name": "Arcturus", "ra": 213.915, "dec": 19.182, "mag": -0.05, "bv": 1.23},
		{"name": "Vega", "ra": 279.235, "dec": 38.784, "mag": 0.03, "bv": 0.00},
		{"name": "Capella", "ra": 79.172, "dec": 45.998, "mag": 0.08, "bv": 0.80},
		{"name": "Rigel", "ra": 78.634, "dec": -8.202, "mag": 0.13, "bv": -0.03},
		{"name": "Procyon", "ra": 114.825, "dec": 5.225, "mag": 0.34, "bv": 0.42},
		{"name": "Betelgeuse", "ra": 88.793, "dec": 7.407, "mag": 0.42, "bv": 1.85},
		{"name": "Achernar", "ra": 24.429, "dec": -57.237, "mag": 0.46, "bv": -0.16},
		{"name": "Hadar", "ra": 210.956, "dec": -60.373, "mag": 0.61, "bv": -0.23},
		{"name": "Altair", "ra": 297.696, "dec": 8.868, "mag": 0.77, "bv": 0.22},
		{"name": "Aldebaran", "ra": 68.980, "dec": 16.509, "mag": 0.85, "bv": 1.54},
		{"name": "Antares", "ra": 247.352, "dec": -26.432, "mag": 0.96, "bv": 1.83},
		{"name": "Spica", "ra": 201.298, "dec": -11.161, "mag": 0.97, "bv": -0.23},
		{"name": "Pollux", "ra": 116.329, "dec": 28.026, "mag": 1.14, "bv": 1.00},
		{"name": "Fomalhaut", "ra": 344.413, "dec": -29.622, "mag": 1.16, "bv": 0.09},
		{"name": "Deneb", "ra": 310.358, "dec": 45.280, "mag": 1.25, "bv": 0.09},
		{"name": "Regulus", "ra": 152.093, "dec": 11.967, "mag": 1.35, "bv": -0.11},
		{"name": "Castor", "ra": 113.650, "dec": 31.888, "mag": 1.58, "bv": 0.03},
		{"name": "Polaris", "ra": 37.954, "dec": 89.264, "mag": 1.98, "bv": 0.60}
	]
	
	var stars_array: Array = []
	for i in range(sample_stars.size()):
		var s = sample_stars[i]
		stars_array.append({
			"id": i,
			"name": s.name,
			"ra": s.ra,
			"dec": s.dec,
			"mag": s.mag,
			"bv": s.bv
		})
	
	var data := {
		"format": "star_catalog",
		"version": "1.0",
		"source": "hipparcos_sample",
		"star_count": stars_array.size(),
		"stars": stars_array
	}
	
	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("StarCatalog: Could not write sample catalog to: %s" % output_path)
		return false
	
	file.store_string(json_text)
	file.close()
	
	print("StarCatalog: Generated sample catalog with %d bright stars at %s" % [stars_array.size(), output_path])
	return true

#endregion
