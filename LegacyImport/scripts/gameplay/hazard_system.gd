extends Node
class_name HazardSystem

## Environmental Hazards and Challenges System
## Generates and manages asteroid fields, black holes, nebulae, and other hazards
## Requirements: 45.1, 45.2, 45.3, 45.4, 45.5

signal hazard_entered(hazard_type: String, hazard_data: Dictionary)
signal hazard_exited(hazard_type: String)
signal hazard_warning(hazard_type: String, distance: float, severity: float)
signal hazard_damage_applied(damage_amount: float, hazard_type: String)

## Hazard types
enum HazardType {
	ASTEROID_FIELD,
	BLACK_HOLE,
	NEBULA,
	RADIATION_ZONE,
	DEBRIS_FIELD
}

## Hazard severity levels
enum Severity {
	LOW,
	MEDIUM,
	HIGH,
	EXTREME
}

## Configuration constants
const ASTEROID_FIELD_DENSITY: float = 0.1  ## Asteroids per cubic unit
const ASTEROID_MIN_SIZE: float = 1.0
const ASTEROID_MAX_SIZE: float = 50.0
const ASTEROID_COLLISION_DAMAGE: float = 10.0

const BLACK_HOLE_GRAVITY_MULTIPLIER: float = 100.0
const BLACK_HOLE_EVENT_HORIZON_DAMAGE: float = 100.0  ## Instant death
const BLACK_HOLE_DISTORTION_RADIUS: float = 5000.0

const NEBULA_VISIBILITY_REDUCTION: float = 0.7  ## 70% visibility reduction
const NEBULA_SIGNAL_NOISE_MULTIPLIER: float = 2.0
const NEBULA_FOG_DENSITY: float = 0.5

const WARNING_DISTANCE_MULTIPLIER: float = 3.0  ## Warn at 3x hazard radius
const DAMAGE_CHECK_INTERVAL: float = 0.5  ## Seconds between damage checks

## Active hazards in the scene
var active_hazards: Dictionary = {}  ## Key: hazard_id, Value: hazard data

## Player reference (set externally)
var player: Node3D = null

## Damage check timer
var _damage_timer: float = 0.0

## Current hazard the player is in
var _current_hazard: String = ""


func _ready() -> void:
	set_process(true)
	_find_player()


func _process(delta: float) -> void:
	_update_hazard_warnings(delta)
	_check_hazard_damage(delta)


#region Asteroid Field Generation

## Generate an asteroid field using MultiMeshInstance3D
## Requirements: 45.1, 45.2
func generate_asteroid_field(center: Vector3, radius: float, density: float = ASTEROID_FIELD_DENSITY) -> String:
	"""Generate an asteroid field at the specified location.
	
	Args:
		center: Center position of the asteroid field
		radius: Radius of the asteroid field
		density: Density of asteroids (asteroids per cubic unit)
	
	Returns:
		Hazard ID for tracking
	"""
	var hazard_id = "asteroid_field_%d" % Time.get_ticks_msec()
	
	# Calculate number of asteroids based on volume and density
	var volume = (4.0 / 3.0) * PI * pow(radius, 3)
	var asteroid_count = int(volume * density)
	asteroid_count = clampi(asteroid_count, 10, 1000)  ## Limit for performance
	
	# Create MultiMeshInstance3D for efficient rendering
	var multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.name = hazard_id
	multi_mesh_instance.position = center
	
	# Create MultiMesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = asteroid_count
	
	# Create asteroid mesh (simple sphere for now)
	var asteroid_mesh = SphereMesh.new()
	asteroid_mesh.radial_segments = 8
	asteroid_mesh.rings = 6
	multi_mesh.mesh = asteroid_mesh
	
	# Create material for asteroids
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4, 0.4)
	material.roughness = 0.9
	multi_mesh_instance.material_override = material
	
	# Generate random positions and sizes for asteroids
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(center)  ## Deterministic based on position
	
	for i in range(asteroid_count):
		# Random position within sphere
		var theta = rng.randf_range(0, TAU)
		var phi = rng.randf_range(0, PI)
		var r = rng.randf_range(0, radius)
		
		var x = r * sin(phi) * cos(theta)
		var y = r * sin(phi) * sin(theta)
		var z = r * cos(phi)
		var pos = Vector3(x, y, z)
		
		# Random size
		var size = rng.randf_range(ASTEROID_MIN_SIZE, ASTEROID_MAX_SIZE)
		
		# Random rotation
		var rotation = Vector3(
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU)
		)
		
		# Create transform
		var transform = Transform3D()
		transform = transform.scaled(Vector3.ONE * size)
		transform = transform.rotated(Vector3.RIGHT, rotation.x)
		transform = transform.rotated(Vector3.UP, rotation.y)
		transform = transform.rotated(Vector3.BACK, rotation.z)
		transform.origin = pos
		
		multi_mesh.set_instance_transform(i, transform)
	
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)
	
	# Store hazard data
	active_hazards[hazard_id] = {
		"type": HazardType.ASTEROID_FIELD,
		"center": center,
		"radius": radius,
		"density": density,
		"node": multi_mesh_instance,
		"severity": _calculate_severity(HazardType.ASTEROID_FIELD, density)
	}
	
	print("HazardSystem: Generated asteroid field '%s' with %d asteroids at %v" % [hazard_id, asteroid_count, center])
	return hazard_id

#endregion


#region Black Hole Hazards

## Create a black hole hazard with extreme gravity
## Requirements: 45.2, 45.4
func create_black_hole(position: Vector3, mass: float, event_horizon_radius: float) -> String:
	"""Create a black hole hazard with extreme gravitational forces.
	
	Args:
		position: Position of the black hole
		mass: Mass of the black hole (affects gravity strength)
		event_horizon_radius: Radius of the event horizon (instant death zone)
	
	Returns:
		Hazard ID for tracking
	"""
	var hazard_id = "black_hole_%d" % Time.get_ticks_msec()
	
	# Create a visual representation (accretion disk effect)
	var black_hole_visual = Node3D.new()
	black_hole_visual.name = hazard_id
	black_hole_visual.position = position
	
	# Create event horizon sphere (black)
	var event_horizon = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = event_horizon_radius
	sphere_mesh.height = event_horizon_radius * 2.0
	event_horizon.mesh = sphere_mesh
	
	var black_material = StandardMaterial3D.new()
	black_material.albedo_color = Color.BLACK
	black_material.emission_enabled = true
	black_material.emission = Color(0.1, 0.0, 0.2)  ## Slight purple glow
	black_material.emission_energy_multiplier = 0.5
	event_horizon.material_override = black_material
	
	black_hole_visual.add_child(event_horizon)
	
	# Create accretion disk (glowing ring)
	var accretion_disk = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = event_horizon_radius * 2.0
	torus_mesh.outer_radius = event_horizon_radius * 3.0
	torus_mesh.rings = 32
	torus_mesh.ring_segments = 64
	accretion_disk.mesh = torus_mesh
	
	var disk_material = StandardMaterial3D.new()
	disk_material.albedo_color = Color(1.0, 0.5, 0.0)  ## Orange glow
	disk_material.emission_enabled = true
	disk_material.emission = Color(1.0, 0.5, 0.0)
	disk_material.emission_energy_multiplier = 2.0
	disk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disk_material.albedo_color.a = 0.7
	accretion_disk.material_override = disk_material
	
	black_hole_visual.add_child(accretion_disk)
	add_child(black_hole_visual)
	
	# Store hazard data
	active_hazards[hazard_id] = {
		"type": HazardType.BLACK_HOLE,
		"position": position,
		"mass": mass,
		"event_horizon_radius": event_horizon_radius,
		"distortion_radius": BLACK_HOLE_DISTORTION_RADIUS,
		"node": black_hole_visual,
		"severity": Severity.EXTREME
	}
	
	print("HazardSystem: Created black hole '%s' at %v with event horizon radius %.1f" % [hazard_id, position, event_horizon_radius])
	return hazard_id


## Apply extreme gravity near black holes
## Requirements: 45.2
func apply_black_hole_gravity(black_hole_data: Dictionary, target_position: Vector3) -> Vector3:
	"""Calculate extreme gravitational force from a black hole.
	
	Args:
		black_hole_data: Dictionary containing black hole properties
		target_position: Position to calculate gravity at
	
	Returns:
		Gravitational acceleration vector
	"""
	var bh_position = black_hole_data["position"]
	var bh_mass = black_hole_data["mass"]
	
	var direction = bh_position - target_position
	var distance = direction.length()
	
	# Prevent division by zero
	if distance < 1.0:
		distance = 1.0
	
	# Apply extreme gravity multiplier for black holes
	# Requirements: 45.2
	var G = 6.674  ## Gravitational constant (same as CelestialBody)
	var acceleration_magnitude = (G * bh_mass * BLACK_HOLE_GRAVITY_MULTIPLIER) / (distance * distance)
	
	return direction.normalized() * acceleration_magnitude

#endregion


#region Nebula Hazards

## Create a nebula region with reduced visibility and increased signal noise
## Requirements: 45.3, 45.4
func create_nebula(center: Vector3, radius: float, fog_color: Color = Color(0.5, 0.2, 0.8, 0.5)) -> String:
	"""Create a nebula hazard that reduces visibility and increases signal noise.
	
	Args:
		center: Center position of the nebula
		radius: Radius of the nebula
		fog_color: Color of the nebula fog
	
	Returns:
		Hazard ID for tracking
	"""
	var hazard_id = "nebula_%d" % Time.get_ticks_msec()
	
	# Create nebula visual using particles or fog volume
	var nebula_visual = Node3D.new()
	nebula_visual.name = hazard_id
	nebula_visual.position = center
	
	# Create a sphere mesh to represent the nebula boundary
	var nebula_sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	nebula_sphere.mesh = sphere_mesh
	
	# Create translucent material with fog effect
	var nebula_material = StandardMaterial3D.new()
	nebula_material.albedo_color = fog_color
	nebula_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	nebula_material.cull_mode = BaseMaterial3D.CULL_DISABLED  ## Render both sides
	nebula_material.emission_enabled = true
	nebula_material.emission = Color(fog_color.r, fog_color.g, fog_color.b)
	nebula_material.emission_energy_multiplier = 0.5
	nebula_sphere.material_override = nebula_material
	
	nebula_visual.add_child(nebula_sphere)
	
	# Add particle system for nebula effect
	var particles = GPUParticles3D.new()
	particles.amount = 100
	particles.lifetime = 10.0
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.visibility_aabb = AABB(Vector3.ONE * -radius, Vector3.ONE * radius * 2)
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = radius
	particle_material.direction = Vector3.ZERO
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 0.1
	particle_material.initial_velocity_max = 0.5
	particle_material.gravity = Vector3.ZERO
	particles.process_material = particle_material
	
	# Create particle mesh
	var particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(10, 10)
	particles.draw_pass_1 = particle_mesh
	
	nebula_visual.add_child(particles)
	particles.emitting = true
	
	add_child(nebula_visual)
	
	# Store hazard data
	active_hazards[hazard_id] = {
		"type": HazardType.NEBULA,
		"center": center,
		"radius": radius,
		"fog_color": fog_color,
		"visibility_reduction": NEBULA_VISIBILITY_REDUCTION,
		"signal_noise_multiplier": NEBULA_SIGNAL_NOISE_MULTIPLIER,
		"node": nebula_visual,
		"severity": _calculate_severity(HazardType.NEBULA, radius)
	}
	
	print("HazardSystem: Created nebula '%s' at %v with radius %.1f" % [hazard_id, center, radius])
	return hazard_id


## Apply nebula effects (reduced visibility and increased noise)
## Requirements: 45.3
func apply_nebula_effects(nebula_data: Dictionary, target_position: Vector3) -> Dictionary:
	"""Calculate nebula effects on visibility and signal.
	
	Args:
		nebula_data: Dictionary containing nebula properties
		target_position: Position to check effects at
	
	Returns:
		Dictionary with visibility_multiplier and signal_noise_multiplier
	"""
	var nebula_center = nebula_data["center"]
	var nebula_radius = nebula_data["radius"]
	
	var distance = (target_position - nebula_center).length()
	
	# Calculate effect strength based on distance from center
	# Stronger effect near center, weaker at edges
	var distance_ratio = clampf(distance / nebula_radius, 0.0, 1.0)
	var effect_strength = 1.0 - distance_ratio
	
	# Apply visibility reduction
	# Requirements: 45.3
	var visibility_multiplier = 1.0 - (NEBULA_VISIBILITY_REDUCTION * effect_strength)
	
	# Apply signal noise increase
	var signal_noise_multiplier = 1.0 + (NEBULA_SIGNAL_NOISE_MULTIPLIER * effect_strength)
	
	return {
		"visibility_multiplier": visibility_multiplier,
		"signal_noise_multiplier": signal_noise_multiplier,
		"effect_strength": effect_strength
	}

#endregion


#region Hazard Management

## Remove a hazard from the scene
func remove_hazard(hazard_id: String) -> void:
	"""Remove a hazard from the scene.
	
	Args:
		hazard_id: ID of the hazard to remove
	"""
	if not active_hazards.has(hazard_id):
		push_warning("HazardSystem: Hazard '%s' not found" % hazard_id)
		return
	
	var hazard_data = active_hazards[hazard_id]
	
	# Remove visual node
	if hazard_data.has("node") and is_instance_valid(hazard_data["node"]):
		hazard_data["node"].queue_free()
	
	# Remove from tracking
	active_hazards.erase(hazard_id)
	
	print("HazardSystem: Removed hazard '%s'" % hazard_id)


## Get all active hazards of a specific type
func get_hazards_by_type(hazard_type: HazardType) -> Array:
	"""Get all active hazards of a specific type.
	
	Args:
		hazard_type: Type of hazard to filter by
	
	Returns:
		Array of hazard data dictionaries
	"""
	var hazards = []
	
	for hazard_id in active_hazards.keys():
		var hazard_data = active_hazards[hazard_id]
		if hazard_data["type"] == hazard_type:
			hazards.append(hazard_data)
	
	return hazards


## Check if a position is inside any hazard
func get_hazard_at_position(position: Vector3) -> Dictionary:
	"""Check if a position is inside any hazard.
	
	Args:
		position: Position to check
	
	Returns:
		Hazard data dictionary if inside a hazard, empty dictionary otherwise
	"""
	for hazard_id in active_hazards.keys():
		var hazard_data = active_hazards[hazard_id]
		
		if _is_position_in_hazard(position, hazard_data):
			return hazard_data
	
	return {}


## Check if a position is inside a specific hazard
func _is_position_in_hazard(position: Vector3, hazard_data: Dictionary) -> bool:
	"""Check if a position is inside a hazard.
	
	Args:
		position: Position to check
		hazard_data: Hazard data dictionary
	
	Returns:
		True if position is inside the hazard
	"""
	var hazard_type = hazard_data["type"]
	
	match hazard_type:
		HazardType.ASTEROID_FIELD, HazardType.NEBULA:
			var center = hazard_data.get("center", Vector3.ZERO)
			var radius = hazard_data.get("radius", 0.0)
			return (position - center).length() <= radius
		
		HazardType.BLACK_HOLE:
			var bh_position = hazard_data.get("position", Vector3.ZERO)
			var distortion_radius = hazard_data.get("distortion_radius", 0.0)
			return (position - bh_position).length() <= distortion_radius
	
	return false


## Clear all hazards
func clear_all_hazards() -> void:
	"""Remove all hazards from the scene."""
	var hazard_ids = active_hazards.keys()
	
	for hazard_id in hazard_ids:
		remove_hazard(hazard_id)
	
	print("HazardSystem: Cleared all hazards")

#endregion


#region Warning System

## Update hazard warnings for the player
## Requirements: 45.4
func _update_hazard_warnings(delta: float) -> void:
	"""Check for nearby hazards and emit warnings.
	Requirements: 45.4 - Provide sensor warnings
	"""
	if player == null:
		return
	
	var player_pos = player.global_position
	
	for hazard_id in active_hazards.keys():
		var hazard_data = active_hazards[hazard_id]
		var distance = _get_distance_to_hazard(player_pos, hazard_data)
		var warning_distance = _get_hazard_warning_distance(hazard_data)
		
		# Check if player is approaching hazard
		if distance <= warning_distance and distance > 0:
			var severity = _calculate_warning_severity(distance, warning_distance)
			hazard_warning.emit(HazardType.keys()[hazard_data["type"]], distance, severity)
		
		# Check if player entered hazard
		if _is_position_in_hazard(player_pos, hazard_data):
			if _current_hazard != hazard_id:
				_current_hazard = hazard_id
				hazard_entered.emit(HazardType.keys()[hazard_data["type"]], hazard_data)
		elif _current_hazard == hazard_id:
			# Player exited hazard
			_current_hazard = ""
			hazard_exited.emit(HazardType.keys()[hazard_data["type"]])


## Get distance from position to hazard
func _get_distance_to_hazard(position: Vector3, hazard_data: Dictionary) -> float:
	"""Calculate distance from a position to a hazard.
	
	Args:
		position: Position to check from
		hazard_data: Hazard data dictionary
	
	Returns:
		Distance to hazard boundary
	"""
	var hazard_type = hazard_data["type"]
	
	match hazard_type:
		HazardType.ASTEROID_FIELD, HazardType.NEBULA:
			var center = hazard_data.get("center", Vector3.ZERO)
			var radius = hazard_data.get("radius", 0.0)
			var distance_to_center = (position - center).length()
			return max(0.0, distance_to_center - radius)
		
		HazardType.BLACK_HOLE:
			var bh_position = hazard_data.get("position", Vector3.ZERO)
			return (position - bh_position).length()
	
	return INF


## Get warning distance for a hazard
func _get_hazard_warning_distance(hazard_data: Dictionary) -> float:
	"""Get the distance at which to warn about a hazard.
	
	Args:
		hazard_data: Hazard data dictionary
	
	Returns:
		Warning distance
	"""
	var hazard_type = hazard_data["type"]
	
	match hazard_type:
		HazardType.ASTEROID_FIELD, HazardType.NEBULA:
			var radius = hazard_data.get("radius", 0.0)
			return radius * WARNING_DISTANCE_MULTIPLIER
		
		HazardType.BLACK_HOLE:
			var distortion_radius = hazard_data.get("distortion_radius", 0.0)
			return distortion_radius * WARNING_DISTANCE_MULTIPLIER
	
	return 1000.0


## Calculate warning severity based on distance
func _calculate_warning_severity(distance: float, warning_distance: float) -> float:
	"""Calculate warning severity (0.0 to 1.0) based on distance.
	
	Args:
		distance: Current distance to hazard
		warning_distance: Distance at which warning starts
	
	Returns:
		Severity from 0.0 (far) to 1.0 (very close)
	"""
	if warning_distance <= 0:
		return 0.0
	
	var ratio = clampf(distance / warning_distance, 0.0, 1.0)
	return 1.0 - ratio

#endregion


#region Damage System

## Check and apply hazard damage
## Requirements: 45.5
func _check_hazard_damage(delta: float) -> void:
	"""Check if player is in hazard and apply damage.
	Requirements: 45.5 - Calculate hazard damage
	"""
	if player == null:
		return
	
	_damage_timer += delta
	if _damage_timer < DAMAGE_CHECK_INTERVAL:
		return
	_damage_timer = 0.0
	
	var player_pos = player.global_position
	
	# Check each hazard for damage
	for hazard_id in active_hazards.keys():
		var hazard_data = active_hazards[hazard_id]
		
		if _is_position_in_hazard(player_pos, hazard_data):
			var damage = _calculate_hazard_damage(player_pos, hazard_data)
			
			if damage > 0:
				hazard_damage_applied.emit(damage, HazardType.keys()[hazard_data["type"]])


## Calculate damage from a hazard
## Requirements: 45.5
func _calculate_hazard_damage(position: Vector3, hazard_data: Dictionary) -> float:
	"""Calculate damage amount from a hazard.
	
	Args:
		position: Position to calculate damage at
		hazard_data: Hazard data dictionary
	
	Returns:
		Damage amount per check interval
	"""
	var hazard_type = hazard_data["type"]
	
	match hazard_type:
		HazardType.ASTEROID_FIELD:
			# Asteroid collision damage (simplified - actual collision would be handled by physics)
			var density = hazard_data.get("density", ASTEROID_FIELD_DENSITY)
			return ASTEROID_COLLISION_DAMAGE * density * DAMAGE_CHECK_INTERVAL
		
		HazardType.BLACK_HOLE:
			var bh_position = hazard_data.get("position", Vector3.ZERO)
			var event_horizon = hazard_data.get("event_horizon_radius", 0.0)
			var distance = (position - bh_position).length()
			
			# Instant death inside event horizon
			if distance <= event_horizon:
				return BLACK_HOLE_EVENT_HORIZON_DAMAGE
			
			# Increasing damage as approaching event horizon
			var distortion_radius = hazard_data.get("distortion_radius", BLACK_HOLE_DISTORTION_RADIUS)
			if distance <= distortion_radius:
				var danger_ratio = 1.0 - ((distance - event_horizon) / (distortion_radius - event_horizon))
				return danger_ratio * 50.0 * DAMAGE_CHECK_INTERVAL
		
		HazardType.NEBULA:
			# Nebula doesn't directly damage, but increases signal noise
			# Damage is indirect through signal degradation
			return 0.0
	
	return 0.0


## Get hazard effects for external systems (e.g., signal manager, rendering)
func get_hazard_effects_at_position(position: Vector3) -> Dictionary:
	"""Get all hazard effects at a position for external systems.
	
	Args:
		position: Position to check effects at
	
	Returns:
		Dictionary with various effect multipliers and values
	"""
	var effects = {
		"gravity_multiplier": 1.0,
		"visibility_multiplier": 1.0,
		"signal_noise_multiplier": 1.0,
		"in_hazard": false,
		"hazard_type": "",
		"damage_rate": 0.0
	}
	
	for hazard_id in active_hazards.keys():
		var hazard_data = active_hazards[hazard_id]
		
		if _is_position_in_hazard(position, hazard_data):
			effects["in_hazard"] = true
			effects["hazard_type"] = HazardType.keys()[hazard_data["type"]]
			
			match hazard_data["type"]:
				HazardType.BLACK_HOLE:
					effects["gravity_multiplier"] = BLACK_HOLE_GRAVITY_MULTIPLIER
				
				HazardType.NEBULA:
					var nebula_effects = apply_nebula_effects(hazard_data, position)
					effects["visibility_multiplier"] = nebula_effects["visibility_multiplier"]
					effects["signal_noise_multiplier"] = nebula_effects["signal_noise_multiplier"]
			
			effects["damage_rate"] = _calculate_hazard_damage(position, hazard_data)
			break  # Only apply effects from first hazard found
	
	return effects

#endregion


#region Utility Methods

## Find the player node in the scene
func _find_player() -> void:
	"""Find the player node in the scene tree."""
	# Try to find player by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("HazardSystem: Found player node")
		return
	
	# Try to find by class name
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_warning("HazardSystem: Player node not found. Set manually via set_player()")


## Set the player node manually
func set_player(player_node: Node3D) -> void:
	"""Set the player node manually.
	
	Args:
		player_node: The player node to track
	"""
	player = player_node
	print("HazardSystem: Player node set manually")


## Calculate severity level for a hazard
func _calculate_severity(hazard_type: HazardType, magnitude: float) -> Severity:
	"""Calculate severity level based on hazard type and magnitude.
	
	Args:
		hazard_type: Type of hazard
		magnitude: Magnitude parameter (density, radius, etc.)
	
	Returns:
		Severity level
	"""
	match hazard_type:
		HazardType.ASTEROID_FIELD:
			if magnitude < 0.05:
				return Severity.LOW
			elif magnitude < 0.15:
				return Severity.MEDIUM
			elif magnitude < 0.3:
				return Severity.HIGH
			else:
				return Severity.EXTREME
		
		HazardType.NEBULA:
			if magnitude < 500:
				return Severity.LOW
			elif magnitude < 1500:
				return Severity.MEDIUM
			elif magnitude < 3000:
				return Severity.HIGH
			else:
				return Severity.EXTREME
		
		HazardType.BLACK_HOLE:
			return Severity.EXTREME
	
	return Severity.MEDIUM


## Get all active hazard IDs
func get_active_hazard_ids() -> Array:
	"""Get all active hazard IDs.
	
	Returns:
		Array of hazard ID strings
	"""
	return active_hazards.keys()


## Get hazard data by ID
func get_hazard_data(hazard_id: String) -> Dictionary:
	"""Get hazard data by ID.
	
	Args:
		hazard_id: ID of the hazard
	
	Returns:
		Hazard data dictionary, or empty dictionary if not found
	"""
	return active_hazards.get(hazard_id, {})


## Check if a hazard exists
func has_hazard(hazard_id: String) -> bool:
	"""Check if a hazard exists.
	
	Args:
		hazard_id: ID of the hazard
	
	Returns:
		True if hazard exists
	"""
	return active_hazards.has(hazard_id)


## Get count of active hazards
func get_hazard_count() -> int:
	"""Get the number of active hazards.
	
	Returns:
		Number of active hazards
	"""
	return active_hazards.size()


## Serialize hazard system state for saving
func serialize() -> Dictionary:
	"""Serialize hazard system state for saving.
	
	Returns:
		Dictionary containing serialized state
	"""
	var serialized_hazards = []
	
	for hazard_id in active_hazards.keys():
		var hazard_data = active_hazards[hazard_id]
		var serialized = {
			"id": hazard_id,
			"type": hazard_data["type"]
		}
		
		# Serialize type-specific data
		match hazard_data["type"]:
			HazardType.ASTEROID_FIELD:
				serialized["center"] = var_to_str(hazard_data["center"])
				serialized["radius"] = hazard_data["radius"]
				serialized["density"] = hazard_data["density"]
			
			HazardType.BLACK_HOLE:
				serialized["position"] = var_to_str(hazard_data["position"])
				serialized["mass"] = hazard_data["mass"]
				serialized["event_horizon_radius"] = hazard_data["event_horizon_radius"]
			
			HazardType.NEBULA:
				serialized["center"] = var_to_str(hazard_data["center"])
				serialized["radius"] = hazard_data["radius"]
				serialized["fog_color"] = var_to_str(hazard_data["fog_color"])
		
		serialized_hazards.append(serialized)
	
	return {
		"hazards": serialized_hazards,
		"current_hazard": _current_hazard
	}


## Deserialize hazard system state from save data
func deserialize(data: Dictionary) -> void:
	"""Deserialize hazard system state from save data.
	
	Args:
		data: Dictionary containing serialized state
	"""
	# Clear existing hazards
	clear_all_hazards()
	
	if not data.has("hazards"):
		return
	
	# Recreate hazards
	for hazard_data in data["hazards"]:
		var hazard_type = hazard_data["type"]
		
		match hazard_type:
			HazardType.ASTEROID_FIELD:
				var center = str_to_var(hazard_data["center"])
				var radius = hazard_data["radius"]
				var density = hazard_data["density"]
				generate_asteroid_field(center, radius, density)
			
			HazardType.BLACK_HOLE:
				var position = str_to_var(hazard_data["position"])
				var mass = hazard_data["mass"]
				var event_horizon = hazard_data["event_horizon_radius"]
				create_black_hole(position, mass, event_horizon)
			
			HazardType.NEBULA:
				var center = str_to_var(hazard_data["center"])
				var radius = hazard_data["radius"]
				var fog_color = str_to_var(hazard_data["fog_color"])
				create_nebula(center, radius, fog_color)
	
	if data.has("current_hazard"):
		_current_hazard = data["current_hazard"]
	
	print("HazardSystem: Deserialized %d hazards" % active_hazards.size())

#endregion
