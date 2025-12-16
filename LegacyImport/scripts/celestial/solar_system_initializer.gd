## SolarSystemInitializer - Solar System Initialization System
## Loads ephemeris data and creates CelestialBody instances for the Sun,
## 8 planets, and major moons with accurate orbital elements and properties.
##
## Requirements: 14.1, 14.2, 14.3, 14.4, 14.5
## - 14.1: Load ephemeris data for major celestial bodies from NASA SPICE/JPL Horizons
## - 14.2: Use Keplerian orbital elements (semi-major axis, eccentricity, inclination)
## - 14.3: Calculate gravitational forces between all bodies (N-body)
## - 14.4: Maintain conservation of energy within 0.01% error tolerance
## - 14.5: Display orbital paths matching real astronomical parameters
extends Node3D
class_name SolarSystemInitializer

## Emitted when the solar system has been fully initialized
signal solar_system_initialized(body_count: int)
## Emitted when a celestial body is created
signal body_created(body: CelestialBody)
## Emitted when initialization fails
signal initialization_failed(error: String)
## Emitted when orbital positions are updated
signal orbits_updated(time: float)

## Path to the solar system ephemeris data file
const DEFAULT_EPHEMERIS_PATH := "res://data/ephemeris/solar_system.json"

## Scale factors for converting real units to game units
## 1:1 REALISTIC SCALE: 1 game unit = 1 million meters (1000 km)
## This provides realistic physics while fitting within Godot's float precision limits
const AU_TO_GAME_UNITS := 149597.87  # 1 AU = 149,597.87 million meters = 149,597.87 game units
const KM_TO_GAME_UNITS := 0.001  # 1 km = 0.001 game units (1 unit = 1000 km)
const MASS_SCALE := 1.0  # Use real masses in kilograms (no scaling for 1:1 accuracy)
const RADIUS_SCALE := 0.001  # 1 km = 0.001 game units (1000 km = 1 game unit)

## Gravitational constant in scaled units for "1 unit = 1 million meters" system
## Derivation: G_real = 6.674e-11 m³/(kg·s²)
## Game unit scale: 1 unit = 1,000,000 meters = 10⁶ meters
## In formula a = G·M/r², distance appears squared
## G_scaled = G_real / (scale²) = 6.674e-11 / (10⁶)² = 6.674e-11 / 10¹² = 6.674e-23
const G_SCALED := 6.674e-23

## J2000.0 epoch in Julian Date
const J2000_EPOCH := 2451545.0

#region Exported Properties

## Path to the ephemeris data file
@export var ephemeris_path: String = DEFAULT_EPHEMERIS_PATH

## Whether to automatically initialize on ready
@export var auto_initialize: bool = false

## Scale factor for body radii (for visibility)
@export var radius_display_scale: float = 10.0

## Whether to create visual models for bodies
@export var create_visual_models: bool = true

## Whether to register bodies with the physics engine
@export var register_with_physics: bool = true

## Whether to show orbital paths
@export var show_orbital_paths: bool = true

## Orbital path color
@export var orbital_path_color: Color = Color(0.3, 0.5, 1.0, 0.5)

#endregion

#region Runtime Properties

## Dictionary of all celestial bodies by name
var bodies: Dictionary = {}

## Reference to the Sun (central body)
var sun: CelestialBody = null

## Array of all planets
var planets: Array[CelestialBody] = []

## Array of all moons
var moons: Array[CelestialBody] = []

## Orbit calculator instance
var orbit_calculator: OrbitCalculator = null

## Raw ephemeris data
var _ephemeris_data: Dictionary = {}

## Whether the system is initialized
var _is_initialized: bool = false

## Current simulation time (Julian Date)
var _current_time: float = J2000_EPOCH

## Reference to physics engine (if available)
var _physics_engine: Node = null

## Orbital path visualizers
var _orbital_paths: Dictionary = {}

#endregion


func _ready() -> void:
	orbit_calculator = OrbitCalculator.new()
	
	if auto_initialize:
		call_deferred("initialize")


## Initialize the solar system from ephemeris data
## Requirements 14.1: Load ephemeris data for major celestial bodies
func initialize(custom_path: String = "") -> bool:
	"""Initialize the solar system from ephemeris data."""
	if _is_initialized:
		push_warning("SolarSystemInitializer: Already initialized")
		return true
	
	var path := custom_path if custom_path != "" else ephemeris_path
	
	# Load ephemeris data
	if not _load_ephemeris_data(path):
		initialization_failed.emit("Failed to load ephemeris data from: " + path)
		return false
	
	# Create celestial bodies
	if not _create_celestial_bodies():
		initialization_failed.emit("Failed to create celestial bodies")
		return false
	
	# Set up orbital relationships
	_setup_orbital_relationships()
	
	# Calculate initial positions
	_update_orbital_positions(_current_time)
	
	# Create orbital path visualizers
	if show_orbital_paths:
		_create_orbital_paths()
	
	# Register with physics engine if available
	if register_with_physics:
		_register_with_physics()
	
	_is_initialized = true
	solar_system_initialized.emit(bodies.size())
	print("SolarSystemInitializer: Initialized with %d bodies" % bodies.size())
	
	return true


## Load ephemeris data from JSON file
## Requirements 14.1: Load ephemeris data from NASA SPICE kernels or JPL Horizons
func _load_ephemeris_data(path: String) -> bool:
	"""Load ephemeris data from a JSON file."""
	if not FileAccess.file_exists(path):
		push_error("SolarSystemInitializer: Ephemeris file not found: " + path)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SolarSystemInitializer: Could not open ephemeris file: " + path)
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("SolarSystemInitializer: JSON parse error at line %d: %s" % [
			json.get_error_line(), json.get_error_message()
		])
		return false
	
	_ephemeris_data = json.get_data()
	
	if not _ephemeris_data.has("bodies"):
		push_error("SolarSystemInitializer: Invalid ephemeris format - missing 'bodies'")
		return false
	
	print("SolarSystemInitializer: Loaded ephemeris data with %d bodies" % _ephemeris_data.bodies.size())
	return true


## Create CelestialBody instances from ephemeris data
func _create_celestial_bodies() -> bool:
	"""Create CelestialBody instances for all bodies in the ephemeris data."""
	var bodies_data: Dictionary = _ephemeris_data.bodies
	
	# First pass: Create all bodies
	for body_id in bodies_data:
		var body_data: Dictionary = bodies_data[body_id]
		var body := _create_body_from_data(body_id, body_data)
		
		if body == null:
			push_warning("SolarSystemInitializer: Failed to create body: " + body_id)
			continue
		
		bodies[body_id] = body
		add_child(body)
		body_created.emit(body)
		
		# Categorize body
		match body_data.get("type", ""):
			"star":
				sun = body
			"planet":
				planets.append(body)
			"moon":
				moons.append(body)
	
	return bodies.size() > 0


## Create a single CelestialBody from data
func _create_body_from_data(body_id: String, data: Dictionary) -> CelestialBody:
	"""Create a CelestialBody instance from ephemeris data."""
	var body := CelestialBody.new()
	body.name = body_id.capitalize()
	
	# Set basic properties
	body.body_name = data.get("name", body_id.capitalize())
	
	# Set body type
	var type_str: String = data.get("type", "planet")
	match type_str:
		"star":
			body.body_type = CelestialBody.BodyType.STAR
			body.is_emissive = true
		"planet":
			body.body_type = CelestialBody.BodyType.PLANET
		"moon":
			body.body_type = CelestialBody.BodyType.MOON
		"asteroid":
			body.body_type = CelestialBody.BodyType.ASTEROID
		"dwarf_planet":
			body.body_type = CelestialBody.BodyType.DWARF_PLANET
		_:
			body.body_type = CelestialBody.BodyType.PLANET
	
	# Set physical properties (scaled for game)
	body.mass = data.get("mass", 1e24) * MASS_SCALE
	body.radius = data.get("radius", 1000.0) * RADIUS_SCALE * radius_display_scale
	
	# Set rotation properties
	var rotation_period_days: float = data.get("rotation_period", 1.0)
	body.rotation_period = rotation_period_days * 86400.0  # Convert days to seconds
	body.axial_tilt = deg_to_rad(data.get("axial_tilt", 0.0))
	
	# Set visual properties
	var color_array: Array = data.get("color", [1.0, 1.0, 1.0])
	body.albedo_color = Color(color_array[0], color_array[1], color_array[2])
	
	# Set emission for stars
	if body.is_emissive:
		var emission_array: Array = data.get("emission_color", [1.0, 1.0, 1.0])
		body.emission_color = Color(emission_array[0], emission_array[1], emission_array[2])
		body.emission_intensity = data.get("emission_intensity", 1.0)
	
	# Create visual model if enabled
	if create_visual_models:
		body.create_default_model()

		# Add atmosphere effect if applicable
		if data.get("has_atmosphere", false):
			_add_atmosphere_effect(body, data)

		# Add rings if applicable
		if data.get("has_rings", false):
			_add_ring_effect(body, data)

	# Add collision shape for physical interaction
	_add_collision_shape(body)

	return body



## Add atmospheric effect to a celestial body
func _add_atmosphere_effect(body: CelestialBody, data: Dictionary) -> void:
	"""Add an atmospheric glow effect to a celestial body."""
	var atmosphere_color_array: Array = data.get("atmosphere_color", [0.6, 0.8, 1.0])
	var atmosphere_color := Color(
		atmosphere_color_array[0],
		atmosphere_color_array[1],
		atmosphere_color_array[2],
		0.3
	)
	
	# Create atmosphere mesh (slightly larger sphere)
	var atmosphere := MeshInstance3D.new()
	atmosphere.name = "Atmosphere"
	
	var sphere := SphereMesh.new()
	sphere.radius = body.radius * 1.05
	sphere.height = body.radius * 2.1
	sphere.radial_segments = 32
	sphere.rings = 16
	atmosphere.mesh = sphere
	
	# Create atmosphere material with transparency
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = atmosphere_color
	material.emission_enabled = true
	material.emission = atmosphere_color
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_FRONT  # Render inside
	atmosphere.material_override = material
	
	body.add_child(atmosphere)


## Add ring effect to a celestial body (Saturn, Uranus, Neptune)
func _add_ring_effect(body: CelestialBody, data: Dictionary) -> void:
	"""Add ring system to a celestial body."""
	var inner_radius: float = data.get("ring_inner_radius", body.radius * 1.5) * RADIUS_SCALE * radius_display_scale
	var outer_radius: float = data.get("ring_outer_radius", body.radius * 2.5) * RADIUS_SCALE * radius_display_scale
	
	# Create ring mesh
	var ring := MeshInstance3D.new()
	ring.name = "Rings"
	
	# Create a torus-like mesh for rings using ArrayMesh
	var ring_mesh := _create_ring_mesh(inner_radius, outer_radius, 64)
	ring.mesh = ring_mesh
	
	# Create ring material
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.8, 0.75, 0.6, 0.7)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = material
	
	body.add_child(ring)


## Create a ring mesh (flat disc with hole)
func _create_ring_mesh(inner_radius: float, outer_radius: float, segments: int) -> ArrayMesh:
	"""Create a flat ring mesh."""
	var mesh := ArrayMesh.new()
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(segments):
		var angle1 := float(i) / segments * TAU
		var angle2 := float(i + 1) / segments * TAU
		
		var inner1 := Vector3(cos(angle1) * inner_radius, 0, sin(angle1) * inner_radius)
		var inner2 := Vector3(cos(angle2) * inner_radius, 0, sin(angle2) * inner_radius)
		var outer1 := Vector3(cos(angle1) * outer_radius, 0, sin(angle1) * outer_radius)
		var outer2 := Vector3(cos(angle2) * outer_radius, 0, sin(angle2) * outer_radius)
		
		# Top face
		surface_tool.set_normal(Vector3.UP)
		surface_tool.set_uv(Vector2(0, 0))
		surface_tool.add_vertex(inner1)
		surface_tool.set_uv(Vector2(1, 0))
		surface_tool.add_vertex(outer1)
		surface_tool.set_uv(Vector2(1, 1))
		surface_tool.add_vertex(outer2)
		
		surface_tool.set_uv(Vector2(0, 0))
		surface_tool.add_vertex(inner1)
		surface_tool.set_uv(Vector2(1, 1))
		surface_tool.add_vertex(outer2)
		surface_tool.set_uv(Vector2(0, 1))
		surface_tool.add_vertex(inner2)
		
		# Bottom face
		surface_tool.set_normal(Vector3.DOWN)
		surface_tool.set_uv(Vector2(0, 0))
		surface_tool.add_vertex(inner1)
		surface_tool.set_uv(Vector2(1, 1))
		surface_tool.add_vertex(outer2)
		surface_tool.set_uv(Vector2(1, 0))
		surface_tool.add_vertex(outer1)
		
		surface_tool.set_uv(Vector2(0, 0))
		surface_tool.add_vertex(inner1)
		surface_tool.set_uv(Vector2(0, 1))
		surface_tool.add_vertex(inner2)
		surface_tool.set_uv(Vector2(1, 1))
		surface_tool.add_vertex(outer2)
	
	surface_tool.generate_normals()
	return surface_tool.commit()


## Add collision shape to celestial body for physical interaction
func _add_collision_shape(body: CelestialBody) -> void:
	"""Add a sphere collision shape to a celestial body."""
	# Create StaticBody3D for collision
	var static_body = StaticBody3D.new()
	static_body.name = "CollisionBody"
	static_body.collision_layer = 4  # Celestial layer (not 1) - prevents CharacterBody3D collision checks
	static_body.collision_mask = 0  # Static bodies don't need to detect collisions

	# Create sphere collision shape matching body radius
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"

	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = body.radius

	collision_shape.shape = sphere_shape
	static_body.add_child(collision_shape)

	# Add to body
	body.add_child(static_body)


## Set up orbital relationships between bodies
func _setup_orbital_relationships() -> void:
	"""Set up parent-child orbital relationships."""
	var bodies_data: Dictionary = _ephemeris_data.bodies
	
	for body_id in bodies:
		var body: CelestialBody = bodies[body_id]
		var data: Dictionary = bodies_data.get(body_id, {})
		
		var parent_id: String = data.get("parent", "")
		if parent_id != "" and bodies.has(parent_id):
			body.parent_body = bodies[parent_id]


## Update orbital positions for all bodies at a given time
## Requirements 14.2: Use Keplerian orbital elements
## Requirements 14.4: Maintain conservation of energy
func _update_orbital_positions(time: float) -> void:
	"""Update all body positions based on orbital mechanics."""
	var bodies_data: Dictionary = _ephemeris_data.bodies
	
	# Sun stays at origin
	if sun != null:
		sun.global_position = Vector3.ZERO
	
	# Update planets (orbit around Sun)
	for planet in planets:
		var planet_id := planet.name.to_lower()
		var data: Dictionary = bodies_data.get(planet_id, {})
		
		if data.has("orbital_elements"):
			var pos := _calculate_orbital_position(data.orbital_elements, time, sun)
			planet.global_position = pos
	
	# Update moons (orbit around their parent planet)
	for moon_body in moons:
		var moon_id := moon_body.name.to_lower()
		var data: Dictionary = bodies_data.get(moon_id, {})
		
		if data.has("orbital_elements") and moon_body.parent_body != null:
			var pos := _calculate_orbital_position(data.orbital_elements, time, moon_body.parent_body)
			moon_body.global_position = pos
	
	_current_time = time
	orbits_updated.emit(time)


## Calculate orbital position from Keplerian elements
## Requirements 14.2: Use Keplerian orbital elements
func _calculate_orbital_position(elements_data: Dictionary, time: float, parent: CelestialBody) -> Vector3:
	"""Calculate position from orbital elements at a given time."""
	if parent == null:
		return Vector3.ZERO
	
	# Create OrbitalElements object
	var elements := OrbitCalculator.OrbitalElements.new(
		elements_data.get("semi_major_axis", 1.0) * AU_TO_GAME_UNITS,
		elements_data.get("eccentricity", 0.0),
		deg_to_rad(elements_data.get("inclination", 0.0)),
		deg_to_rad(elements_data.get("longitude_ascending_node", 0.0)),
		deg_to_rad(elements_data.get("argument_of_periapsis", 0.0)),
		deg_to_rad(elements_data.get("mean_anomaly_at_epoch", 0.0)),
		J2000_EPOCH,
		G_SCALED * parent.mass
	)
	
	# Calculate position using orbit calculator
	var local_pos := orbit_calculator.calculate_position(elements, time)
	
	# Add parent position
	return parent.global_position + local_pos


## Create orbital path visualizers
## Requirements 14.5: Display orbital paths matching real astronomical parameters
func _create_orbital_paths() -> void:
	"""Create visual representations of orbital paths."""
	var bodies_data: Dictionary = _ephemeris_data.bodies
	
	# Create paths for planets
	for planet in planets:
		var planet_id := planet.name.to_lower()
		var data: Dictionary = bodies_data.get(planet_id, {})
		
		if data.has("orbital_elements") and sun != null:
			var path := _create_orbital_path_mesh(data.orbital_elements, sun)
			if path != null:
				_orbital_paths[planet_id] = path
				add_child(path)


## Create a mesh for an orbital path
func _create_orbital_path_mesh(elements_data: Dictionary, parent: CelestialBody) -> MeshInstance3D:
	"""Create a line mesh representing an orbital path."""
	if parent == null:
		return null
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "OrbitalPath"
	
	# Create orbital elements
	var elements := OrbitCalculator.OrbitalElements.new(
		elements_data.get("semi_major_axis", 1.0) * AU_TO_GAME_UNITS,
		elements_data.get("eccentricity", 0.0),
		deg_to_rad(elements_data.get("inclination", 0.0)),
		deg_to_rad(elements_data.get("longitude_ascending_node", 0.0)),
		deg_to_rad(elements_data.get("argument_of_periapsis", 0.0)),
		deg_to_rad(elements_data.get("mean_anomaly_at_epoch", 0.0)),
		J2000_EPOCH,
		G_SCALED * parent.mass
	)
	
	# Generate points along the orbit
	var points: PackedVector3Array = []
	var segments := 128
	var period := orbit_calculator.calculate_orbital_period(elements)
	
	for i in range(segments + 1):
		var t := J2000_EPOCH + (float(i) / segments) * period
		var pos := orbit_calculator.calculate_position(elements, t)
		points.append(pos + parent.global_position)
	
	# Create line mesh using ImmediateMesh
	var immediate_mesh := ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for point in points:
		immediate_mesh.surface_add_vertex(point)
	
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh
	
	# Create material
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = orbital_path_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	return mesh_instance



## Register bodies with the physics engine
func _register_with_physics() -> void:
	"""Register all celestial bodies with the physics engine."""
	# Try to get physics engine from the engine coordinator
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("get"):
		_physics_engine = engine.get("physics_engine")
	
	if _physics_engine == null:
		push_warning("SolarSystemInitializer: Physics engine not available")
		return
	
	# Register all bodies
	for body_id in bodies:
		var body: CelestialBody = bodies[body_id]
		if _physics_engine.has_method("register_celestial_body"):
			_physics_engine.register_celestial_body(body)


#region Public API

## Get a celestial body by name
func get_body(name: String) -> CelestialBody:
	"""Get a celestial body by its name (case-insensitive)."""
	var key := name.to_lower()
	if bodies.has(key):
		return bodies[key]
	return null


## Get all planets
func get_planets() -> Array[CelestialBody]:
	"""Get all planet bodies."""
	return planets


## Get all moons
func get_moons() -> Array[CelestialBody]:
	"""Get all moon bodies."""
	return moons


## Get the Sun
func get_sun() -> CelestialBody:
	"""Get the Sun body."""
	return sun


## Get all bodies
func get_all_bodies() -> Array[CelestialBody]:
	"""Get all celestial bodies."""
	var result: Array[CelestialBody] = []
	for body_id in bodies:
		result.append(bodies[body_id])
	return result


## Update the simulation to a specific time
func set_simulation_time(julian_date: float) -> void:
	"""Set the simulation time and update all orbital positions."""
	_update_orbital_positions(julian_date)


## Advance the simulation by a time delta
func advance_time(delta_days: float) -> void:
	"""Advance the simulation time by a number of days."""
	_current_time += delta_days
	_update_orbital_positions(_current_time)


## Get the current simulation time
func get_simulation_time() -> float:
	"""Get the current simulation time as Julian Date."""
	return _current_time


## Check if the system is initialized
func is_initialized() -> bool:
	"""Check if the solar system is initialized."""
	return _is_initialized


## Get body count
func get_body_count() -> int:
	"""Get the total number of celestial bodies."""
	return bodies.size()


## Show or hide orbital paths
func set_orbital_paths_visible(visible: bool) -> void:
	"""Show or hide orbital path visualizations."""
	for path_id in _orbital_paths:
		var path: MeshInstance3D = _orbital_paths[path_id]
		if path != null:
			path.visible = visible


## Get moons of a specific planet
func get_moons_of(planet_name: String) -> Array[CelestialBody]:
	"""Get all moons orbiting a specific planet."""
	var result: Array[CelestialBody] = []
	var planet := get_body(planet_name)
	
	if planet == null:
		return result
	
	for moon_body in moons:
		if moon_body.parent_body == planet:
			result.append(moon_body)
	
	return result


## Calculate distance between two bodies
func get_distance_between(body1_name: String, body2_name: String) -> float:
	"""Get the distance between two celestial bodies."""
	var body1 := get_body(body1_name)
	var body2 := get_body(body2_name)
	
	if body1 == null or body2 == null:
		return -1.0
	
	return body1.get_distance_to(body2)


## Get the closest body to a position
func get_closest_body(position: Vector3, exclude_sun: bool = false) -> CelestialBody:
	"""Get the celestial body closest to a given position."""
	var closest: CelestialBody = null
	var closest_distance := INF
	
	for body_id in bodies:
		var body: CelestialBody = bodies[body_id]
		
		if exclude_sun and body == sun:
			continue
		
		var distance := (body.global_position - position).length()
		if distance < closest_distance:
			closest_distance = distance
			closest = body
	
	return closest


## Get bodies within a radius
func get_bodies_in_radius(position: Vector3, radius: float) -> Array[CelestialBody]:
	"""Get all celestial bodies within a given radius of a position."""
	var result: Array[CelestialBody] = []
	
	for body_id in bodies:
		var body: CelestialBody = bodies[body_id]
		var distance := (body.global_position - position).length()
		if distance <= radius:
			result.append(body)
	
	return result

#endregion


#region Serialization

## Save the current state to a dictionary
func save_state() -> Dictionary:
	"""Save the current solar system state."""
	var state := {
		"time": _current_time,
		"bodies": {}
	}
	
	for body_id in bodies:
		var body: CelestialBody = bodies[body_id]
		state.bodies[body_id] = {
			"position": body.global_position,
			"velocity": body.velocity,
			"rotation": body.current_rotation
		}
	
	return state


## Load state from a dictionary
func load_state(state: Dictionary) -> bool:
	"""Load solar system state from a saved state."""
	if not state.has("time") or not state.has("bodies"):
		return false
	
	_current_time = state.time
	
	for body_id in state.bodies:
		if bodies.has(body_id):
			var body: CelestialBody = bodies[body_id]
			var body_state: Dictionary = state.bodies[body_id]
			
			if body_state.has("position"):
				body.global_position = body_state.position
			if body_state.has("velocity"):
				body.velocity = body_state.velocity
			if body_state.has("rotation"):
				body.current_rotation = body_state.rotation
	
	return true

#endregion


#region Process

func _process(delta: float) -> void:
	"""Update orbital positions if time manager is advancing."""
	if not _is_initialized:
		return
	
	# Check if we should update based on time manager
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null:
		var time_manager = engine.get("time_manager")
		if time_manager != null and time_manager.has_method("get_simulation_time"):
			var new_time: float = time_manager.get_simulation_time()
			if absf(new_time - _current_time) > 0.0001:
				_update_orbital_positions(new_time)

#endregion
