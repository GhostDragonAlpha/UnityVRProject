extends Node3D
class_name JetpackEffectsBasic
## Visual and audio effects for jetpack thrust (Basic Version)
## Attached to WalkingController at feet position

## NOTE: Use scripts/player/jetpack_effects.gd for full-featured version
signal effects_started
signal effects_stopped

## State
var is_active: bool = false
var thrust_intensity: float = 0.0

## References
var walking_controller: WalkingController = null

## Effect nodes
var thrust_particles: GPUParticles3D = null
var thrust_light: OmniLight3D = null
var audio_player: AudioStreamPlayer3D = null

## Effect settings
@export var particle_amount: int = 50
@export var light_energy: float = 1.5
@export var sound_enabled: bool = true


func _ready() -> void:
	create_thrust_particles()
	create_thrust_light()
	create_audio_player()


## Set reference to walking controller
func set_walking_controller(controller: WalkingController) -> void:
	walking_controller = controller


## Create jetpack thrust particles
func create_thrust_particles() -> void:
	thrust_particles = GPUParticles3D.new()
	thrust_particles.name = "ThrustParticles"

	# Configure particle material
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.2

	# Direction (downward thrust)
	material.direction = Vector3(0, -1, 0)
	material.spread = 20.0
	material.initial_velocity_min = 8.0
	material.initial_velocity_max = 12.0

	# Gravity (opposite, since we're fighting gravity)
	material.gravity = Vector3(0, -5.0, 0)
	material.damping_min = 1.0
	material.damping_max = 2.0

	# Scale
	material.scale_min = 0.15
	material.scale_max = 0.3

	# Color (bright blue/white thrust)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.8, 1.0, 1.0))  # Bright blue-white
	gradient.add_point(0.5, Color(0.3, 0.6, 1.0, 0.6))  # Blue
	gradient.add_point(1.0, Color(0.1, 0.3, 0.6, 0.0))  # Dark transparent
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	thrust_particles.process_material = material
	thrust_particles.amount = particle_amount
	thrust_particles.lifetime = 0.4
	thrust_particles.emitting = false
	thrust_particles.one_shot = false

	# Add quad mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.2)
	thrust_particles.draw_pass_1 = quad_mesh

	add_child(thrust_particles)
	print("[JetpackEffects] Thrust particles created")


## Create thrust glow light
func create_thrust_light() -> void:
	thrust_light = OmniLight3D.new()
	thrust_light.name = "ThrustLight"
	thrust_light.position = Vector3(0, 0, 0)

	# Light properties (blue glow)
	thrust_light.light_color = Color(0.5, 0.7, 1.0)
	thrust_light.light_energy = 0.0  # Start off
	thrust_light.omni_range = 5.0
	thrust_light.omni_attenuation = 2.0

	add_child(thrust_light)
	print("[JetpackEffects] Thrust light created")


## Create audio player for thrust sound
func create_audio_player() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "ThrustAudio"
	audio_player.max_distance = 50.0
	audio_player.unit_size = 1.0

	# Note: Would need actual audio file for thrust sound
	# For now, just set up the player structure

	add_child(audio_player)
	print("[JetpackEffects] Audio player created")


## Start jetpack effects
func start_effects() -> void:
	if is_active:
		return

	is_active = true

	# Start particles
	if thrust_particles:
		thrust_particles.emitting = true

	# Start audio
	if audio_player and sound_enabled:
		# Would play thrust sound here if we had audio file
		pass

	effects_started.emit()
	print("[JetpackEffects] Jetpack effects started")


## Stop jetpack effects
func stop_effects() -> void:
	if not is_active:
		return

	is_active = false

	# Stop particles
	if thrust_particles:
		thrust_particles.emitting = false

	# Stop audio
	if audio_player:
		audio_player.stop()

	# Turn off light
	if thrust_light:
		thrust_light.light_energy = 0.0

	effects_stopped.emit()
	print("[JetpackEffects] Jetpack effects stopped")


## Update thrust effects based on intensity and fuel
func update_thrust_effects(intensity: float, fuel_percent: float) -> void:
	thrust_intensity = intensity

	# Update particle amount based on intensity
	if thrust_particles:
		thrust_particles.amount = int(particle_amount * intensity)

	# Update light energy
	if thrust_light:
		var target_energy = light_energy * intensity
		thrust_light.light_energy = target_energy

	# Adjust effects based on fuel (reduce intensity as fuel depletes)
	var fuel_factor = fuel_percent / 100.0
	if fuel_factor < 0.3:
		# Sputtering effect at low fuel
		if thrust_particles:
			thrust_particles.amount = int(thrust_particles.amount * fuel_factor)
		if thrust_light:
			thrust_light.light_energy *= fuel_factor


## Cleanup
func _exit_tree() -> void:
	if thrust_particles and thrust_particles.get_parent():
		thrust_particles.queue_free()
	if thrust_light and thrust_light.get_parent():
		thrust_light.queue_free()
	if audio_player and audio_player.get_parent():
		audio_player.queue_free()
