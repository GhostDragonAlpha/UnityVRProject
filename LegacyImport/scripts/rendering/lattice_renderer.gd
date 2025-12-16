## LatticeRenderer - Renders the harmonic lattice visualization
## Displays the 3D wireframe grid representing spacetime as discrete harmonic oscillator nodes.
## Implements gravity well distortions, Doppler shift coloring, and harmonic pulse animations.
##
## Requirements: 5.1, 5.2, 5.3, 5.4, 5.5 - Lattice grid rendering
## Requirements: 6.1, 6.2, 6.3, 6.4, 6.5 - Relativistic effects
## Requirements: 7.1, 7.2, 7.3 - Doppler shift coloring
## Requirements: 8.1, 8.2, 8.3, 8.4, 8.5 - Gravity well distortions
extends MeshInstance3D
class_name LatticeRenderer

## Emitted when the lattice is initialized
signal lattice_initialized
## Emitted when a gravity well is added
signal gravity_well_added(position: Vector3, mass: float)
## Emitted when a gravity well is removed
signal gravity_well_removed(index: int)
## Emitted when grid density changes
signal grid_density_changed(new_density: float)

## The shader material for the lattice
var shader_material: ShaderMaterial = null

## Grid density (spacing between grid lines in game units)
var grid_density: float = 10.0

## Grid size (number of cells in each direction from center)
var grid_size: int = 50

## Pulse frequency for harmonic animation (Hz)
var pulse_frequency: float = 1.0

## Pulse amplitude for harmonic animation
var pulse_amplitude: float = 0.2

## Base color for the lattice (cyan)
var base_color: Color = Color(0.0, 1.0, 1.0, 1.0)

## Secondary color for the lattice (magenta)
var secondary_color: Color = Color(1.0, 0.0, 1.0, 1.0)

## Glow intensity for the lattice lines
var glow_intensity: float = 2.0

## Line thickness for the grid
var line_thickness: float = 0.05

## Array of gravity wells: [{position: Vector3, mass: float}, ...]
var gravity_wells: Array[Dictionary] = []

## Maximum number of gravity wells supported by the shader
const MAX_GRAVITY_WELLS: int = 16

## Current time for animation
var _time: float = 0.0

## Current player velocity for Doppler shift
var _player_velocity: Vector3 = Vector3.ZERO

## Current player forward direction
var _player_forward: Vector3 = Vector3.FORWARD

## Whether the lattice is initialized
var _initialized: bool = false

## Reference to ShaderManager (optional)
var _shader_manager: ShaderManager = null

## Shader path
const LATTICE_SHADER_PATH := "res://shaders/lattice.gdshader"


func _ready() -> void:
	# Don't auto-initialize - let the parent system call initialize()
	pass


func _process(delta: float) -> void:
	if _initialized:
		update(delta)


## Initialize the lattice renderer
## @param shader_manager: Optional ShaderManager for shader loading
func initialize(shader_manager: ShaderManager = null) -> bool:
	_shader_manager = shader_manager
	
	# Create the grid mesh
	if not _create_grid_mesh():
		push_error("LatticeRenderer: Failed to create grid mesh")
		return false
	
	# Load or create the shader material
	if not _setup_shader_material():
		push_error("LatticeRenderer: Failed to setup shader material")
		return false
	
	# Apply the material to the mesh
	material_override = shader_material
	
	# Initialize shader parameters
	_update_shader_parameters()
	
	_initialized = true
	lattice_initialized.emit()
	print("LatticeRenderer: Initialized with grid density %.1f, size %d" % [grid_density, grid_size])
	return true


## Update the lattice each frame
func update(dt: float) -> void:
	_time += dt
	
	# Update time-based shader parameters
	if shader_material != null:
		shader_material.set_shader_parameter("time", _time)
		shader_material.set_shader_parameter("pulse_phase", sin(_time * pulse_frequency * TAU) * pulse_amplitude)


## Create the 3D grid mesh using ArrayMesh
func _create_grid_mesh() -> bool:
	var array_mesh := ArrayMesh.new()
	var surface_tool := SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var half_size := grid_size * grid_density
	var step := grid_density
	
	# Generate grid lines along X axis (varying Y and Z)
	for y in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			var y_pos := y * step
			var z_pos := z * step
			
			# Line along X
			surface_tool.set_uv(Vector2(0.0, 0.0))
			surface_tool.set_color(base_color)
			surface_tool.add_vertex(Vector3(-half_size, y_pos, z_pos))
			
			surface_tool.set_uv(Vector2(1.0, 0.0))
			surface_tool.set_color(base_color)
			surface_tool.add_vertex(Vector3(half_size, y_pos, z_pos))
	
	# Generate grid lines along Y axis (varying X and Z)
	for x in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			var x_pos := x * step
			var z_pos := z * step
			
			# Line along Y
			surface_tool.set_uv(Vector2(0.0, 0.5))
			surface_tool.set_color(secondary_color)
			surface_tool.add_vertex(Vector3(x_pos, -half_size, z_pos))
			
			surface_tool.set_uv(Vector2(1.0, 0.5))
			surface_tool.set_color(secondary_color)
			surface_tool.add_vertex(Vector3(x_pos, half_size, z_pos))
	
	# Generate grid lines along Z axis (varying X and Y)
	for x in range(-grid_size, grid_size + 1):
		for y in range(-grid_size, grid_size + 1):
			var x_pos := x * step
			var y_pos := y * step
			
			# Line along Z
			surface_tool.set_uv(Vector2(0.0, 1.0))
			surface_tool.set_color(base_color)
			surface_tool.add_vertex(Vector3(x_pos, y_pos, -half_size))
			
			surface_tool.set_uv(Vector2(1.0, 1.0))
			surface_tool.set_color(base_color)
			surface_tool.add_vertex(Vector3(x_pos, y_pos, half_size))
	
	surface_tool.commit(array_mesh)
	mesh = array_mesh
	
	return mesh != null


## Setup the shader material
func _setup_shader_material() -> bool:
	shader_material = ShaderMaterial.new()
	
	# Try to load the shader from file
	var shader: Shader = null
	
	if _shader_manager != null:
		shader = _shader_manager.load_shader("lattice", LATTICE_SHADER_PATH)
	elif FileAccess.file_exists(LATTICE_SHADER_PATH):
		shader = load(LATTICE_SHADER_PATH) as Shader
	
	# If shader file doesn't exist, create a basic inline shader
	if shader == null:
		shader = _create_fallback_shader()
	
	shader_material.shader = shader
	return shader_material.shader != null


## Create a fallback shader if the main shader file doesn't exist
func _create_fallback_shader() -> Shader:
	var shader := Shader.new()
	shader.code = _get_fallback_shader_code()
	return shader


## Get the fallback shader code (basic version without all features)
func _get_fallback_shader_code() -> String:
	return """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 base_color : source_color = vec3(0.0, 1.0, 1.0);
uniform vec3 secondary_color : source_color = vec3(1.0, 0.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float time : hint_range(0.0, 1000.0) = 0.0;
uniform float pulse_phase : hint_range(-1.0, 1.0) = 0.0;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.8;

// Doppler shift parameters
uniform vec3 player_velocity = vec3(0.0);
uniform vec3 player_forward = vec3(0.0, 0.0, -1.0);
uniform float doppler_strength : hint_range(0.0, 1.0) = 0.5;

// Gravity well parameters (up to 16 wells)
uniform int gravity_well_count : hint_range(0, 16) = 0;
uniform vec3 gravity_well_positions[16];
uniform float gravity_well_masses[16];
uniform float gravity_displacement_scale : hint_range(0.0, 100.0) = 10.0;

varying vec3 world_position;
varying float vertex_displacement;

void vertex() {
	vec3 displaced_vertex = VERTEX;
	vertex_displacement = 0.0;
	
	// Apply gravity well displacement (inverse square law)
	// Requirements 8.1, 8.2, 8.3: Gravity well distortions
	for (int i = 0; i < gravity_well_count && i < 16; i++) {
		vec3 to_well = gravity_well_positions[i] - displaced_vertex;
		float dist = length(to_well);
		float min_dist = 1.0; // Prevent division by zero
		dist = max(dist, min_dist);
		
		// Inverse square law: displacement = -k / distance²
		// Requirements 8.2: Apply inverse square law formula
		float displacement_magnitude = gravity_well_masses[i] * gravity_displacement_scale / (dist * dist);
		
		// Displace downward (toward the gravity well) to create funnel shape
		// Requirements 8.1: Displace vertices downward to create funnel
		vec3 displacement_dir = normalize(to_well);
		displaced_vertex += displacement_dir * displacement_magnitude;
		vertex_displacement += displacement_magnitude;
	}
	
	// Apply harmonic pulse animation
	// Requirements 5.4: Animate lattice with harmonic pulse effect
	float pulse = pulse_phase * 0.1;
	displaced_vertex += NORMAL * pulse;
	
	VERTEX = displaced_vertex;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Base color with UV-based variation
	vec3 color = mix(base_color, secondary_color, UV.y);
	
	// Apply Doppler shift coloring
	// Requirements 7.1, 7.2, 7.3: Doppler shift for lattice
	float velocity_magnitude = length(player_velocity);
	if (velocity_magnitude > 0.01) {
		vec3 view_dir = normalize(world_position - CAMERA_POSITION_WORLD);
		vec3 vel_dir = normalize(player_velocity);
		float doppler = dot(vel_dir, view_dir);
		
		// Blueshift for approaching (positive doppler), redshift for receding
		vec3 blue_shift = vec3(0.3, 0.5, 1.0);
		vec3 red_shift = vec3(1.0, 0.3, 0.2);
		
		if (doppler > 0.0) {
			// Moving toward this point - blueshift
			color = mix(color, blue_shift, doppler * doppler_strength);
		} else {
			// Moving away from this point - redshift
			color = mix(color, red_shift, abs(doppler) * doppler_strength);
		}
	}
	
	// Apply glow based on displacement (brighter near gravity wells)
	// Requirements 8.5: Increase visual depth near gravity wells
	float glow = glow_intensity + vertex_displacement * 0.5;
	
	// Harmonic pulse effect on brightness
	float pulse_brightness = 1.0 + pulse_phase * 0.2;
	
	ALBEDO = color * glow * pulse_brightness;
	ALPHA = line_alpha;
	
	// Emission for glow effect
	EMISSION = color * glow * 0.5;
}
"""


## Update all shader parameters
func _update_shader_parameters() -> void:
	if shader_material == null:
		return
	
	shader_material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	shader_material.set_shader_parameter("secondary_color", Vector3(secondary_color.r, secondary_color.g, secondary_color.b))
	shader_material.set_shader_parameter("glow_intensity", glow_intensity)
	shader_material.set_shader_parameter("time", _time)
	shader_material.set_shader_parameter("pulse_phase", 0.0)
	shader_material.set_shader_parameter("line_alpha", 0.8)
	shader_material.set_shader_parameter("player_velocity", _player_velocity)
	shader_material.set_shader_parameter("player_forward", _player_forward)
	shader_material.set_shader_parameter("doppler_strength", 0.5)
	shader_material.set_shader_parameter("gravity_displacement_scale", 10.0)
	
	_update_gravity_wells_in_shader()


## Update gravity well data in the shader
func _update_gravity_wells_in_shader() -> void:
	if shader_material == null:
		return
	
	var positions: Array[Vector3] = []
	var masses: Array[float] = []
	
	# Fill arrays up to MAX_GRAVITY_WELLS
	for i in range(MAX_GRAVITY_WELLS):
		if i < gravity_wells.size():
			positions.append(gravity_wells[i].get("position", Vector3.ZERO))
			masses.append(gravity_wells[i].get("mass", 0.0))
		else:
			positions.append(Vector3.ZERO)
			masses.append(0.0)
	
	shader_material.set_shader_parameter("gravity_well_count", mini(gravity_wells.size(), MAX_GRAVITY_WELLS))
	shader_material.set_shader_parameter("gravity_well_positions", positions)
	shader_material.set_shader_parameter("gravity_well_masses", masses)


## Add a gravity well to the lattice
## Requirements 8.1, 8.3: Support multiple gravity sources
## @param position: World position of the gravity well
## @param mass: Mass of the gravity source (affects displacement strength)
func add_gravity_well(position: Vector3, mass: float) -> void:
	if gravity_wells.size() >= MAX_GRAVITY_WELLS:
		push_warning("LatticeRenderer: Maximum gravity wells (%d) reached" % MAX_GRAVITY_WELLS)
		return
	
	gravity_wells.append({"position": position, "mass": mass})
	_update_gravity_wells_in_shader()
	gravity_well_added.emit(position, mass)


## Remove a gravity well by index
func remove_gravity_well(index: int) -> void:
	if index < 0 or index >= gravity_wells.size():
		push_error("LatticeRenderer: Invalid gravity well index %d" % index)
		return
	
	gravity_wells.remove_at(index)
	_update_gravity_wells_in_shader()
	gravity_well_removed.emit(index)


## Update a gravity well's position
func update_gravity_well_position(index: int, new_position: Vector3) -> void:
	if index < 0 or index >= gravity_wells.size():
		return
	
	gravity_wells[index]["position"] = new_position
	_update_gravity_wells_in_shader()


## Update a gravity well's mass
func update_gravity_well_mass(index: int, new_mass: float) -> void:
	if index < 0 or index >= gravity_wells.size():
		return
	
	gravity_wells[index]["mass"] = new_mass
	_update_gravity_wells_in_shader()


## Clear all gravity wells
func clear_gravity_wells() -> void:
	gravity_wells.clear()
	_update_gravity_wells_in_shader()


## Get the number of active gravity wells
func get_gravity_well_count() -> int:
	return gravity_wells.size()


## Set the Doppler shift parameters based on player velocity
## Requirements 7.1, 7.2, 7.3: Doppler shift coloring
## @param velocity: Player's current velocity vector
## @param forward: Player's forward direction
func set_doppler_shift(velocity: Vector3, forward: Vector3 = Vector3.FORWARD) -> void:
	_player_velocity = velocity
	_player_forward = forward.normalized()
	
	if shader_material != null:
		shader_material.set_shader_parameter("player_velocity", _player_velocity)
		shader_material.set_shader_parameter("player_forward", _player_forward)


## Set the Doppler shift strength
func set_doppler_strength(strength: float) -> void:
	if shader_material != null:
		shader_material.set_shader_parameter("doppler_strength", clampf(strength, 0.0, 1.0))


## Set the grid density (spacing between lines)
## Requirements 5.2: Render grid lines at regular intervals
func set_grid_density(density: float) -> void:
	if density <= 0:
		push_error("LatticeRenderer: Grid density must be positive")
		return
	
	var old_density := grid_density
	grid_density = density
	
	# Regenerate the mesh with new density
	if _initialized:
		_create_grid_mesh()
		grid_density_changed.emit(density)
		print("LatticeRenderer: Grid density changed from %.1f to %.1f" % [old_density, density])


## Set the grid size (number of cells from center)
func set_grid_size(size: int) -> void:
	if size <= 0:
		push_error("LatticeRenderer: Grid size must be positive")
		return
	
	grid_size = size
	
	# Regenerate the mesh with new size
	if _initialized:
		_create_grid_mesh()


## Set the pulse frequency for harmonic animation
## Requirements 5.4: Animate lattice with harmonic pulse effect
func set_pulse_frequency(frequency: float) -> void:
	pulse_frequency = maxf(frequency, 0.0)


## Set the pulse amplitude
func set_pulse_amplitude(amplitude: float) -> void:
	pulse_amplitude = maxf(amplitude, 0.0)


## Set the base color of the lattice
## Requirements 5.2: Glowing cyan/magenta colors
func set_base_color(color: Color) -> void:
	base_color = color
	if shader_material != null:
		shader_material.set_shader_parameter("base_color", Vector3(color.r, color.g, color.b))


## Set the secondary color of the lattice
func set_secondary_color(color: Color) -> void:
	secondary_color = color
	if shader_material != null:
		shader_material.set_shader_parameter("secondary_color", Vector3(color.r, color.g, color.b))


## Set the glow intensity
func set_glow_intensity(intensity: float) -> void:
	glow_intensity = maxf(intensity, 0.0)
	if shader_material != null:
		shader_material.set_shader_parameter("glow_intensity", glow_intensity)


## Set the gravity displacement scale
## Requirements 8.2: Control displacement magnitude
func set_gravity_displacement_scale(scale: float) -> void:
	if shader_material != null:
		shader_material.set_shader_parameter("gravity_displacement_scale", maxf(scale, 0.0))


## Set the line alpha (transparency)
func set_line_alpha(alpha: float) -> void:
	if shader_material != null:
		shader_material.set_shader_parameter("line_alpha", clampf(alpha, 0.0, 1.0))


## Check if the lattice is initialized
func is_initialized() -> bool:
	return _initialized


## Get the shader material
func get_shader_material() -> ShaderMaterial:
	return shader_material


## Get statistics about the lattice
func get_statistics() -> Dictionary:
	return {
		"initialized": _initialized,
		"grid_density": grid_density,
		"grid_size": grid_size,
		"gravity_well_count": gravity_wells.size(),
		"pulse_frequency": pulse_frequency,
		"pulse_amplitude": pulse_amplitude,
		"time": _time
	}


## Shutdown and cleanup
func shutdown() -> void:
	_initialized = false
	gravity_wells.clear()
	shader_material = null
	mesh = null
	print("LatticeRenderer: Shutdown complete")
