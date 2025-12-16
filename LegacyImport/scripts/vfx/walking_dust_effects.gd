extends Node3D
class_name WalkingDustEffects
## Dust puff effects for moon walking
## Triggers on footsteps and jumps

signal footstep_triggered(position: Vector3)

## References
var walking_controller: WalkingController = null

## Effect nodes
var footstep_particles: GPUParticles3D = null
var jump_landing_particles: GPUParticles3D = null

## State tracking
var was_on_ground: bool = false
var last_footstep_time: float = 0.0
var footstep_interval: float = 0.4  # seconds between footsteps

## Effect settings
@export var dust_enabled: bool = true
@export var footstep_dust_amount: int = 20
@export var landing_dust_amount: int = 50


func _ready() -> void:
	create_footstep_particles()
	create_jump_landing_particles()


## Set reference to walking controller
func set_walking_controller(controller: WalkingController) -> void:
	walking_controller = controller


## Create footstep dust particles
func create_footstep_particles() -> void:
	footstep_particles = GPUParticles3D.new()
	footstep_particles.name = "FootstepParticles"
	footstep_particles.position = Vector3(0, 0, 0)

	# Configure particle material
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.3

	# Direction (low and outward)
	material.direction = Vector3(0, 0.3, 0)
	material.spread = 45.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 2.0

	# Gravity
	material.gravity = Vector3(0, -1.62, 0)  # Lunar gravity
	material.damping_min = 0.5
	material.damping_max = 1.0

	# Scale
	material.scale_min = 0.1
	material.scale_max = 0.3

	# Color (gray dust)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.6, 0.6, 0.6))
	gradient.add_point(0.5, Color(0.5, 0.5, 0.5, 0.4))
	gradient.add_point(1.0, Color(0.4, 0.4, 0.4, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	footstep_particles.process_material = material
	footstep_particles.amount = footstep_dust_amount
	footstep_particles.lifetime = 1.0
	footstep_particles.one_shot = true
	footstep_particles.emitting = false

	# Add sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	footstep_particles.draw_pass_1 = sphere_mesh

	add_child(footstep_particles)
	print("[WalkingDustEffects] Footstep particles created")


## Create jump landing dust particles (bigger burst)
func create_jump_landing_particles() -> void:
	jump_landing_particles = GPUParticles3D.new()
	jump_landing_particles.name = "JumpLandingParticles"
	jump_landing_particles.position = Vector3(0, 0, 0)

	# Configure particle material
	var material = ParticleProcessMaterial.new()

	# Emission (wider spread for landing impact)
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.5

	# Direction (radial outward and up)
	material.direction = Vector3(0, 1, 0)
	material.spread = 60.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0

	# Gravity
	material.gravity = Vector3(0, -1.62, 0)  # Lunar gravity
	material.damping_min = 1.0
	material.damping_max = 2.0

	# Scale (larger particles)
	material.scale_min = 0.2
	material.scale_max = 0.5

	# Color (gray dust)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.6, 0.6, 0.8))
	gradient.add_point(0.3, Color(0.5, 0.5, 0.5, 0.5))
	gradient.add_point(1.0, Color(0.4, 0.4, 0.4, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	jump_landing_particles.process_material = material
	jump_landing_particles.amount = landing_dust_amount
	jump_landing_particles.lifetime = 1.5
	jump_landing_particles.one_shot = true
	jump_landing_particles.emitting = false

	# Add sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.08
	sphere_mesh.height = 0.16
	jump_landing_particles.draw_pass_1 = sphere_mesh

	add_child(jump_landing_particles)
	print("[WalkingDustEffects] Jump landing particles created")


func _process(delta: float) -> void:
	if not walking_controller or not dust_enabled:
		return

	# Check if landed from jump
	var is_on_ground = walking_controller.is_on_floor()

	if not was_on_ground and is_on_ground:
		# Just landed - trigger landing dust
		trigger_landing_dust()

	# Check for footstep dust while walking on ground
	if is_on_ground and walking_controller.is_walking():
		last_footstep_time += delta
		if last_footstep_time >= footstep_interval:
			trigger_footstep_dust()
			last_footstep_time = 0.0

	was_on_ground = is_on_ground


## Trigger footstep dust
func trigger_footstep_dust() -> void:
	if not footstep_particles:
		return

	footstep_particles.restart()
	footstep_particles.emitting = true
	footstep_triggered.emit(global_position)


## Trigger landing dust (from jump)
func trigger_landing_dust() -> void:
	if not jump_landing_particles:
		return

	jump_landing_particles.restart()
	jump_landing_particles.emitting = true
	print("[WalkingDustEffects] Landing dust triggered!")


## Enable/disable dust effects
func set_dust_enabled(enabled: bool) -> void:
	dust_enabled = enabled


## Cleanup
func _exit_tree() -> void:
	if footstep_particles and footstep_particles.get_parent():
		footstep_particles.queue_free()
	if jump_landing_particles and jump_landing_particles.get_parent():
		jump_landing_particles.queue_free()
