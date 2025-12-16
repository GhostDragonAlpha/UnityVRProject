extends Node3D
class_name LandingEffects
## Manages visual effects for moon landing spacecraft
## Includes thruster particles, engine glow, landing dust, and other effects

signal effects_started
signal effects_stopped

## References to spacecraft
var spacecraft: Spacecraft = null
var spacecraft_mesh: MeshInstance3D = null

## Effect nodes
var thruster_particles: GPUParticles3D = null
var engine_glow_light: OmniLight3D = null
var landing_dust: GPUParticles3D = null
var landing_lights: Array[SpotLight3D] = []

## State tracking
var is_near_surface: bool = false
var last_throttle: float = 0.0
var landing_light_distance: float = 100.0  # Turn on lights within 100m

## Effect settings
@export var thruster_intensity: float = 1.0
@export var engine_glow_intensity: float = 2.0
@export var dust_on_landing: bool = true


func _ready() -> void:
	# Effects will be initialized when setup() is called
	pass


## Initialize effects system with spacecraft reference
func setup(craft: Spacecraft) -> void:
	spacecraft = craft

	# Find spacecraft mesh
	for child in spacecraft.get_children():
		if child is MeshInstance3D:
			spacecraft_mesh = child
			break

	if not spacecraft_mesh:
		push_error("[LandingEffects] Could not find spacecraft mesh!")
		return

	# Create all effect nodes
	create_thruster_effects()
	create_engine_glow()
	create_landing_lights()
	create_landing_dust()

	# Connect to spacecraft signals
	if spacecraft:
		spacecraft.thrust_applied.connect(_on_thrust_applied)

	print("[LandingEffects] Landing effects initialized")


## Create thruster particle effects
func create_thruster_effects() -> void:
	thruster_particles = GPUParticles3D.new()
	thruster_particles.name = "ThrusterParticles"

	# Position at rear of spacecraft (exhaust position)
	thruster_particles.position = Vector3(0, -0.5, 2.5)

	# Configure particle process material
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.3

	# Direction and spread
	material.direction = Vector3(0, 0, 1)  # Forward from spacecraft
	material.spread = 15.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 15.0

	# Gravity and damping
	material.gravity = Vector3.ZERO  # Space environment
	material.damping_min = 0.5
	material.damping_max = 1.0

	# Scale
	material.scale_min = 0.2
	material.scale_max = 0.5

	# Color over lifetime (bright white/orange to transparent)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.6, 1.0))  # Bright orange-white
	gradient.add_point(0.5, Color(1.0, 0.5, 0.2, 0.5))  # Orange
	gradient.add_point(1.0, Color(0.3, 0.1, 0.0, 0.0))  # Dark transparent
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	thruster_particles.process_material = material
	thruster_particles.amount = 100
	thruster_particles.lifetime = 0.5
	thruster_particles.emitting = false
	thruster_particles.one_shot = false

	# Add glow material
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.3, 0.3)
	thruster_particles.draw_pass_1 = quad_mesh

	spacecraft.add_child(thruster_particles)
	print("[LandingEffects] Thruster particles created")


## Create engine glow light
func create_engine_glow() -> void:
	engine_glow_light = OmniLight3D.new()
	engine_glow_light.name = "EngineGlow"
	engine_glow_light.position = Vector3(0, -0.5, 2.5)  # Same as thruster

	# Light properties
	engine_glow_light.light_color = Color(1.0, 0.7, 0.4)  # Orange glow
	engine_glow_light.light_energy = 0.0  # Start off
	engine_glow_light.omni_range = 10.0
	engine_glow_light.omni_attenuation = 2.0

	spacecraft.add_child(engine_glow_light)
	print("[LandingEffects] Engine glow created")


## Create landing lights
func create_landing_lights() -> void:
	# Create 4 landing lights around the spacecraft
	var positions = [
		Vector3(1.5, -0.8, 0),   # Right
		Vector3(-1.5, -0.8, 0),  # Left
		Vector3(0, -0.8, 2.0),   # Front
		Vector3(0, -0.8, -2.0)   # Back
	]

	for i in positions.size():
		var spotlight = SpotLight3D.new()
		spotlight.name = "LandingLight%d" % i
		spotlight.position = positions[i]

		# Point downward
		spotlight.rotation_degrees = Vector3(-90, 0, 0)

		# Light properties
		spotlight.light_color = Color.WHITE
		spotlight.light_energy = 0.0  # Start off
		spotlight.spot_range = 200.0
		spotlight.spot_angle = 45.0
		spotlight.spot_attenuation = 1.0
		spotlight.shadow_enabled = true

		spacecraft.add_child(spotlight)
		landing_lights.append(spotlight)

	print("[LandingEffects] %d landing lights created" % landing_lights.size())


## Create landing dust effect
func create_landing_dust() -> void:
	landing_dust = GPUParticles3D.new()
	landing_dust.name = "LandingDust"
	landing_dust.position = Vector3(0, -1.5, 0)  # Below spacecraft

	# Configure particle material
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.0

	# Direction (radial outward and up)
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 10.0

	# Gravity (pull back down)
	material.gravity = Vector3(0, -1.62, 0)  # Lunar gravity
	material.damping_min = 1.0
	material.damping_max = 2.0

	# Scale
	material.scale_min = 0.5
	material.scale_max = 1.5

	# Color (gray dust)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.6, 0.6, 0.8))
	gradient.add_point(0.3, Color(0.5, 0.5, 0.5, 0.5))
	gradient.add_point(1.0, Color(0.4, 0.4, 0.4, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	landing_dust.process_material = material
	landing_dust.amount = 200
	landing_dust.lifetime = 2.0
	landing_dust.one_shot = true
	landing_dust.emitting = false

	# Add sphere mesh for particles
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	landing_dust.draw_pass_1 = sphere_mesh

	spacecraft.add_child(landing_dust)
	print("[LandingEffects] Landing dust created")


func _process(delta: float) -> void:
	if not spacecraft:
		return

	# Update thruster effects based on throttle
	update_thruster_effects(delta)

	# Update landing lights based on altitude
	update_landing_lights(delta)


## Update thruster effects intensity
func update_thruster_effects(delta: float) -> void:
	if not spacecraft or not thruster_particles or not engine_glow_light:
		return

	var throttle = spacecraft.get_throttle()
	var vertical_thrust = spacecraft.vertical_thrust
	var total_thrust = abs(throttle) + abs(vertical_thrust)

	# Clamp to 0-1 range
	total_thrust = clampf(total_thrust, 0.0, 1.0)

	# Update particles
	if total_thrust > 0.1:
		if not thruster_particles.emitting:
			thruster_particles.emitting = true
		# Adjust particle amount based on thrust
		thruster_particles.amount = int(50 + total_thrust * 150)
	else:
		if thruster_particles.emitting:
			thruster_particles.emitting = false

	# Update engine glow - smooth interpolation
	var target_energy = total_thrust * engine_glow_intensity * 3.0
	engine_glow_light.light_energy = lerp(engine_glow_light.light_energy, target_energy, delta * 10.0)

	last_throttle = total_thrust


## Update landing lights based on altitude
func update_landing_lights(delta: float) -> void:
	if not spacecraft or landing_lights.is_empty():
		return

	# Get altitude from landing detector if available
	var altitude = get_altitude_to_surface()

	# Turn on lights when near surface
	var target_energy = 0.0
	if altitude < landing_light_distance:
		is_near_surface = true
		# Fade in lights as we approach
		target_energy = 1.5 * (1.0 - altitude / landing_light_distance)
	else:
		is_near_surface = false

	# Smoothly fade lights
	for light in landing_lights:
		light.light_energy = lerp(light.light_energy, target_energy, delta * 5.0)


## Get altitude to nearest surface
func get_altitude_to_surface() -> float:
	if not spacecraft:
		return INF

	# Try to find LandingDetector
	var landing_detector = spacecraft.get_node_or_null("LandingDetector")
	if landing_detector and landing_detector.has_method("get_altitude"):
		return landing_detector.get_altitude()

	# Fallback: raycast downward
	var space_state = spacecraft.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		spacecraft.global_position,
		spacecraft.global_position + Vector3(0, -1000, 0)
	)
	var result = space_state.intersect_ray(query)

	if result:
		return spacecraft.global_position.distance_to(result.position)

	return INF


## Trigger landing dust effect
func trigger_landing_dust() -> void:
	if not landing_dust or not dust_on_landing:
		return

	# Reset and emit
	landing_dust.restart()
	landing_dust.emitting = true
	print("[LandingEffects] Landing dust triggered!")


## Signal handler for thrust applied
func _on_thrust_applied(force: Vector3) -> void:
	# Could add additional effects based on thrust force
	pass


## Enable/disable effects
func set_effects_enabled(enabled: bool) -> void:
	if thruster_particles:
		thruster_particles.emitting = enabled and last_throttle > 0.1
	if engine_glow_light:
		if not enabled:
			engine_glow_light.light_energy = 0.0
	for light in landing_lights:
		if not enabled:
			light.light_energy = 0.0


## Cleanup
func _exit_tree() -> void:
	# Clean up effects
	if thruster_particles and thruster_particles.get_parent():
		thruster_particles.queue_free()
	if engine_glow_light and engine_glow_light.get_parent():
		engine_glow_light.queue_free()
	if landing_dust and landing_dust.get_parent():
		landing_dust.queue_free()
	for light in landing_lights:
		if light and light.get_parent():
			light.queue_free()
