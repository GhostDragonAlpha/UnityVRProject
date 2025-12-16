## JetpackEffects - Visual and Audio Effects for Jetpack System
##
## Manages immersive particle effects, spatial audio, haptic feedback,
## and environmental interactions for the jetpack system.
##
## Requirements:
## - Create thrust particle system (fire, smoke, sparks)
## - Implement audio system with pitch/volume scaling
## - Add haptic feedback for VR controllers
## - Apply environmental effects (dust, force)
## - Integrate with walking_controller.gd

extends Node3D
class_name JetpackEffects

## Emitted when effects are started
signal effects_started
## Emitted when effects are stopped
signal effects_stopped
## Emitted when fuel level changes color warning
signal fuel_warning_changed(warning_level: int)

## Warning levels for fuel
enum FuelWarning {
	NORMAL = 0,   ## > 50% fuel
	LOW = 1,      ## 20-50% fuel
	CRITICAL = 2  ## < 20% fuel
}

#region Effect Nodes

## Particle systems
var thrust_particles: GPUParticles3D = null
var smoke_particles: GPUParticles3D = null
var spark_particles: GPUParticles3D = null
var ground_dust_particles: GPUParticles3D = null

## Audio players
var thrust_sound: AudioStreamPlayer3D = null
var ignition_sound: AudioStreamPlayer3D = null
var shutdown_sound: AudioStreamPlayer3D = null
var low_fuel_warning_sound: AudioStreamPlayer3D = null
var sputter_sound: AudioStreamPlayer3D = null

## Visual effects
var fuel_tank_glow: MeshInstance3D = null
var heat_distortion: MeshInstance3D = null

#endregion

#region Configuration

## Thrust particle configuration
@export_group("Thrust Particles")
@export var thrust_particle_count: int = 150
@export var thrust_cone_angle: float = 30.0  # degrees
@export var thrust_speed_min: float = 5.0
@export var thrust_speed_max: float = 15.0
@export var thrust_lifetime: float = 0.75

## Smoke particle configuration
@export_group("Smoke Particles")
@export var smoke_particle_count: int = 35
@export var smoke_speed_min: float = 1.0
@export var smoke_speed_max: float = 3.0
@export var smoke_lifetime: float = 3.0
@export var smoke_size_start: float = 0.1
@export var smoke_size_end: float = 0.5

## Spark particle configuration
@export_group("Spark Particles")
@export var spark_particle_count: int = 30
@export var spark_speed_min: float = 10.0
@export var spark_speed_max: float = 20.0
@export var spark_lifetime: float = 0.2
@export var spark_thrust_threshold: float = 0.8  # Only spawn above 80% thrust

## Audio configuration
@export_group("Audio")
@export var thrust_base_pitch: float = 0.8
@export var thrust_pitch_range: float = 0.4
@export var thrust_base_volume_db: float = -10.0
@export var ignition_volume_db: float = -5.0
@export var shutdown_volume_db: float = -8.0
@export var warning_volume_db: float = -12.0

## Haptic configuration
@export_group("Haptic Feedback")
@export var haptic_enabled: bool = true
@export var haptic_base_intensity: float = 0.3
@export var haptic_max_intensity: float = 0.6
@export var haptic_base_frequency: float = 50.0
@export var haptic_max_frequency: float = 200.0

## Environmental effects
@export_group("Environmental")
@export var ground_dust_distance: float = 2.0  # Distance to trigger dust
@export var thrust_force_radius: float = 3.0   # Radius for push force
@export var thrust_force_strength: float = 5.0  # Force magnitude

#endregion

#region State

## Current effect state
var is_active: bool = false
var current_thrust: float = 0.0
var current_fuel_percent: float = 100.0
var current_warning_level: FuelWarning = FuelWarning.NORMAL

## Performance state
var effects_quality: int = 2  # 0=Low, 1=Medium, 2=High

## References
var vr_manager: VRManager = null
var haptic_manager: HapticManager = null
var audio_manager: AudioManager = null
var walking_controller: WalkingController = null

## Ground detection
var ground_raycast: RayCast3D = null
var distance_to_ground: float = INF

## Overheat system
var continuous_thrust_time: float = 0.0
var overheat_threshold: float = 5.0
var is_overheated: bool = false

#endregion

#region Initialization

func _ready() -> void:
	# Get references to managers
	_get_manager_references()

	# Create effect nodes
	_create_particle_systems()
	_create_audio_players()
	_create_visual_effects()
	_create_ground_detection()

	# Start inactive
	set_process(false)
	_log_info("JetpackEffects initialized")

## Get references to manager nodes
func _get_manager_references() -> void:
	var engine = _get_engine()
	if engine:
		if engine.has_method("get_vr_manager"):
			vr_manager = engine.get_vr_manager()
		if engine.has_method("get_haptic_manager"):
			haptic_manager = engine.get_haptic_manager()
		if engine.has_method("get_audio_manager"):
			audio_manager = engine.get_audio_manager()

	# Try direct node paths if engine methods not available
	if not vr_manager:
		vr_manager = get_node_or_null("/root/ResonanceEngine/VRManager")
	if not haptic_manager:
		haptic_manager = get_node_or_null("/root/ResonanceEngine/HapticManager")
	if not audio_manager:
		audio_manager = get_node_or_null("/root/ResonanceEngine/AudioManager")

## Create all particle systems
func _create_particle_systems() -> void:
	# Create thrust particles (main exhaust)
	thrust_particles = _create_thrust_particle_system()
	thrust_particles.name = "ThrustParticles"
	add_child(thrust_particles)

	# Create smoke particles (trailing smoke)
	smoke_particles = _create_smoke_particle_system()
	smoke_particles.name = "SmokeParticles"
	add_child(smoke_particles)

	# Create spark particles (high-thrust sparks)
	spark_particles = _create_spark_particle_system()
	spark_particles.name = "SparkParticles"
	add_child(spark_particles)

	# Create ground dust particles
	ground_dust_particles = _create_ground_dust_system()
	ground_dust_particles.name = "GroundDustParticles"
	add_child(ground_dust_particles)

	_log_info("Particle systems created")

## Create thrust particle system
func _create_thrust_particle_system() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.amount = thrust_particle_count
	particles.lifetime = thrust_lifetime
	particles.explosiveness = 0.0
	particles.randomness = 0.3
	particles.visibility_aabb = AABB(Vector3(-2, -5, -2), Vector3(4, 5, 4))
	particles.emitting = false

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission shape - cone pointing downward
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.1

	# Direction - downward cone
	material.direction = Vector3(0, -1, 0)
	material.spread = thrust_cone_angle

	# Velocity
	material.initial_velocity_min = thrust_speed_min
	material.initial_velocity_max = thrust_speed_max

	# Gravity
	material.gravity = Vector3(0, -9.8, 0)

	# Color - orange to transparent
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.6, 0.2, 1.0))  # Bright orange
	gradient.set_color(0.5, Color(1.0, 0.4, 0.0, 0.8))  # Orange
	gradient.set_color(1, Color(0.3, 0.1, 0.0, 0.0))  # Dark red transparent
	material.color_ramp = gradient

	# Size
	material.scale_min = 0.2
	material.scale_max = 0.4

	particles.process_material = material

	# Create draw pass mesh (billboard quad)
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.3, 0.3)
	particles.draw_pass_1 = quad_mesh

	return particles

## Create smoke particle system
func _create_smoke_particle_system() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.amount = smoke_particle_count
	particles.lifetime = smoke_lifetime
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.visibility_aabb = AABB(Vector3(-3, -6, -3), Vector3(6, 6, 6))
	particles.emitting = false

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission shape - sphere
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.2

	# Direction - random spread
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0

	# Velocity
	material.initial_velocity_min = smoke_speed_min
	material.initial_velocity_max = smoke_speed_max

	# Gravity (less affected)
	material.gravity = Vector3(0, -2.0, 0)

	# Color - gray gradient
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.3, 0.3, 0.3, 0.0))  # Start transparent
	gradient.set_color(0.2, Color(0.4, 0.4, 0.4, 0.6))  # Fade in
	gradient.set_color(1, Color(0.2, 0.2, 0.2, 0.0))  # Fade out
	material.color_ramp = gradient

	# Size - grows over lifetime
	var size_curve = Curve.new()
	size_curve.add_point(Vector2(0, 0.2))
	size_curve.add_point(Vector2(0.5, 0.5))
	size_curve.add_point(Vector2(1, 1.0))
	material.scale_curve = size_curve
	material.scale_min = smoke_size_start
	material.scale_max = smoke_size_end

	particles.process_material = material

	# Create draw pass mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.5, 0.5)
	particles.draw_pass_1 = quad_mesh

	return particles

## Create spark particle system
func _create_spark_particle_system() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.amount = spark_particle_count
	particles.lifetime = spark_lifetime
	particles.explosiveness = 0.8
	particles.randomness = 0.8
	particles.visibility_aabb = AABB(Vector3(-2, -4, -2), Vector3(4, 4, 4))
	particles.emitting = false
	particles.one_shot = true

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission shape - point
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.1

	# Direction - random
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0

	# Velocity
	material.initial_velocity_min = spark_speed_min
	material.initial_velocity_max = spark_speed_max

	# Gravity
	material.gravity = Vector3(0, -9.8, 0)

	# Color - yellow-white
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 0.8, 1.0))  # Bright yellow
	gradient.set_color(0.5, Color(1.0, 0.7, 0.2, 0.8))  # Orange
	gradient.set_color(1, Color(1.0, 0.3, 0.0, 0.0))  # Red transparent
	material.color_ramp = gradient

	# Size
	material.scale_min = 0.05
	material.scale_max = 0.1

	particles.process_material = material

	# Create draw pass mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = quad_mesh

	return particles

## Create ground dust particle system
func _create_ground_dust_system() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.amount = 50
	particles.lifetime = 2.0
	particles.explosiveness = 0.2
	particles.randomness = 0.6
	particles.visibility_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 3, 6))
	particles.emitting = false
	particles.local_coords = false

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission shape - ring on ground
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_axis = Vector3(0, 1, 0)
	material.emission_ring_height = 0.1
	material.emission_ring_radius = 1.0
	material.emission_ring_inner_radius = 0.5

	# Direction - outward and up
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0

	# Velocity
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0

	# Gravity
	material.gravity = Vector3(0, -3.0, 0)

	# Color - dust colored
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.6, 0.5, 0.4, 0.0))
	gradient.set_color(0.2, Color(0.7, 0.6, 0.5, 0.5))
	gradient.set_color(1, Color(0.5, 0.4, 0.3, 0.0))
	material.color_ramp = gradient

	# Size
	material.scale_min = 0.3
	material.scale_max = 0.6

	particles.process_material = material

	# Create draw pass mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.4, 0.4)
	particles.draw_pass_1 = quad_mesh

	return particles

## Create audio players
func _create_audio_players() -> void:
	# Thrust sound (continuous)
	thrust_sound = AudioStreamPlayer3D.new()
	thrust_sound.name = "ThrustSound"
	thrust_sound.bus = "SFX"
	thrust_sound.max_distance = 50.0
	thrust_sound.unit_size = 5.0
	add_child(thrust_sound)

	# Ignition sound (one-shot)
	ignition_sound = AudioStreamPlayer3D.new()
	ignition_sound.name = "IgnitionSound"
	ignition_sound.bus = "SFX"
	ignition_sound.max_distance = 30.0
	ignition_sound.unit_size = 5.0
	add_child(ignition_sound)

	# Shutdown sound (one-shot)
	shutdown_sound = AudioStreamPlayer3D.new()
	shutdown_sound.name = "ShutdownSound"
	shutdown_sound.bus = "SFX"
	shutdown_sound.max_distance = 30.0
	shutdown_sound.unit_size = 5.0
	add_child(shutdown_sound)

	# Low fuel warning (looping)
	low_fuel_warning_sound = AudioStreamPlayer3D.new()
	low_fuel_warning_sound.name = "LowFuelWarning"
	low_fuel_warning_sound.bus = "SFX"
	low_fuel_warning_sound.max_distance = 20.0
	low_fuel_warning_sound.unit_size = 3.0
	add_child(low_fuel_warning_sound)

	# Sputter sound (intermittent)
	sputter_sound = AudioStreamPlayer3D.new()
	sputter_sound.name = "SputterSound"
	sputter_sound.bus = "SFX"
	sputter_sound.max_distance = 25.0
	sputter_sound.unit_size = 4.0
	add_child(sputter_sound)

	_log_info("Audio players created")

	# TODO: Load actual audio streams when available
	# For now, these are empty and will need audio files

## Create visual effects
func _create_visual_effects() -> void:
	# TODO: Create fuel tank glow mesh
	# TODO: Create heat distortion mesh
	_log_info("Visual effects created (placeholders)")

## Create ground detection raycast
func _create_ground_detection() -> void:
	ground_raycast = RayCast3D.new()
	ground_raycast.name = "GroundDetectionRay"
	ground_raycast.target_position = Vector3(0, -ground_dust_distance - 1.0, 0)
	ground_raycast.enabled = true
	ground_raycast.collide_with_areas = false
	ground_raycast.collide_with_bodies = true
	add_child(ground_raycast)

#endregion

#region Update Loop

func _process(delta: float) -> void:
	if not is_active:
		return

	# Update ground detection
	_update_ground_detection()

	# Update overheat tracking
	_update_overheat(delta)

	# Update environmental effects
	_update_environmental_effects(delta)

## Update ground distance detection
func _update_ground_detection() -> void:
	if ground_raycast and ground_raycast.is_colliding():
		var collision_point = ground_raycast.get_collision_point()
		distance_to_ground = global_position.distance_to(collision_point)
	else:
		distance_to_ground = INF

## Update overheat system
func _update_overheat(delta: float) -> void:
	if current_thrust > 0.1:
		continuous_thrust_time += delta
		if continuous_thrust_time > overheat_threshold and not is_overheated:
			is_overheated = true
			_apply_overheat_effects()
	else:
		# Cool down
		continuous_thrust_time = max(0.0, continuous_thrust_time - delta * 0.5)
		if continuous_thrust_time < overheat_threshold * 0.5 and is_overheated:
			is_overheated = false
			_clear_overheat_effects()

## Apply overheat visual/audio effects
func _apply_overheat_effects() -> void:
	_log_warning("Jetpack overheating!")
	# TODO: Add heat distortion shader
	# TODO: Play warning beep sound
	# TODO: Spawn warning particles

## Clear overheat effects
func _clear_overheat_effects() -> void:
	_log_info("Jetpack cooled down")
	# TODO: Remove heat distortion
	# TODO: Stop warning sound

## Update environmental effects
func _update_environmental_effects(delta: float) -> void:
	# Ground dust when close to surface
	if distance_to_ground < ground_dust_distance and current_thrust > 0.3:
		if not ground_dust_particles.emitting:
			ground_dust_particles.emitting = true
			# Position at ground level
			if ground_raycast.is_colliding():
				ground_dust_particles.global_position = ground_raycast.get_collision_point()
	else:
		if ground_dust_particles.emitting:
			ground_dust_particles.emitting = false

	# Apply thrust force to nearby objects
	if current_thrust > 0.5:
		_apply_thrust_force_to_nearby()

## Apply downward force to nearby physics objects
func _apply_thrust_force_to_nearby() -> void:
	# Use physics query to find nearby RigidBody3D nodes
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return

	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = thrust_force_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1  # Default physics layer

	var results = space_state.intersect_shape(query, 10)

	for result in results:
		var collider = result.get("collider")
		if collider and collider is RigidBody3D:
			# Apply force away from jetpack
			var direction = (collider.global_position - global_position).normalized()
			var force = direction * thrust_force_strength * current_thrust
			collider.apply_central_force(force)

#endregion

#region Public API

## Start jetpack effects
func start_effects() -> void:
	if is_active:
		return

	is_active = true
	set_process(true)

	# Start particle systems
	if thrust_particles:
		thrust_particles.emitting = true
	if smoke_particles:
		smoke_particles.emitting = true

	# Play ignition sound
	if ignition_sound:
		ignition_sound.volume_db = ignition_volume_db
		ignition_sound.play()

	effects_started.emit()
	_log_debug("Jetpack effects started")

## Stop jetpack effects
func stop_effects() -> void:
	if not is_active:
		return

	is_active = false
	set_process(false)

	# Stop particle systems
	if thrust_particles:
		thrust_particles.emitting = false
	if smoke_particles:
		smoke_particles.emitting = false
	if spark_particles:
		spark_particles.emitting = false
	if ground_dust_particles:
		ground_dust_particles.emitting = false

	# Stop thrust sound
	if thrust_sound and thrust_sound.playing:
		thrust_sound.stop()

	# Stop warning sound
	if low_fuel_warning_sound and low_fuel_warning_sound.playing:
		low_fuel_warning_sound.stop()

	# Play shutdown sound
	if shutdown_sound:
		shutdown_sound.volume_db = shutdown_volume_db
		shutdown_sound.play()

	# Stop haptics
	if haptic_manager and haptic_enabled:
		haptic_manager.stop_continuous_effect("both", "jetpack_thrust")

	effects_stopped.emit()
	_log_debug("Jetpack effects stopped")

## Update thrust effects based on current thrust amount and fuel level
## Args:
##   thrust_amount: Thrust intensity (0.0 to 1.0)
##   fuel_percent: Fuel percentage (0.0 to 100.0)
func update_thrust_effects(thrust_amount: float, fuel_percent: float) -> void:
	current_thrust = clamp(thrust_amount, 0.0, 1.0)
	current_fuel_percent = clamp(fuel_percent, 0.0, 100.0)

	# Update particles
	_update_particle_effects()

	# Update audio
	_update_audio_effects()

	# Update haptics
	_update_haptic_effects()

	# Update fuel warnings
	_update_fuel_warning()

## Update particle emission based on thrust
func _update_particle_effects() -> void:
	if not thrust_particles or not smoke_particles:
		return

	# Scale particle emission by thrust
	thrust_particles.amount_ratio = current_thrust
	smoke_particles.amount_ratio = current_thrust * 0.7

	# Color shift based on fuel efficiency
	var fuel_ratio = current_fuel_percent / 100.0
	var thrust_color: Color

	if fuel_ratio > 0.5:
		# High fuel: bright orange/white
		thrust_color = Color(1.0, 0.8, 0.6)
	elif fuel_ratio > 0.2:
		# Medium fuel: orange
		thrust_color = Color(1.0, 0.5, 0.2)
	else:
		# Low fuel: blue sputtering
		thrust_color = Color(0.3, 0.5, 1.0)

	# Update thrust particle color
	if thrust_particles.process_material is ParticleProcessMaterial:
		var material = thrust_particles.process_material as ParticleProcessMaterial
		if material.color_ramp:
			var gradient = material.color_ramp
			# Modulate the gradient with fuel color
			gradient.set_color(0, thrust_color)

	# Spawn sparks at high thrust
	if current_thrust > spark_thrust_threshold and spark_particles:
		if not spark_particles.emitting:
			spark_particles.restart()
			spark_particles.emitting = true

## Update audio playback based on thrust
func _update_audio_effects() -> void:
	if not thrust_sound:
		return

	# Start/stop thrust sound
	if current_thrust > 0.1:
		if not thrust_sound.playing:
			thrust_sound.play()

		# Pitch scales with thrust (0.8 to 1.2)
		thrust_sound.pitch_scale = thrust_base_pitch + (current_thrust * thrust_pitch_range)

		# Volume scales with thrust
		var volume_linear = current_thrust
		thrust_sound.volume_db = thrust_base_volume_db + (20.0 * log(volume_linear) / log(10.0))
	else:
		if thrust_sound.playing:
			thrust_sound.stop()

	# Low fuel sputtering
	var fuel_ratio = current_fuel_percent / 100.0
	if fuel_ratio < 0.2 and current_thrust > 0.1:
		if sputter_sound and not sputter_sound.playing:
			sputter_sound.play()
	else:
		if sputter_sound and sputter_sound.playing:
			sputter_sound.stop()

## Update haptic feedback for VR controllers
func _update_haptic_effects() -> void:
	if not haptic_manager or not haptic_enabled:
		return

	if not vr_manager or not vr_manager.is_vr_active():
		return

	if current_thrust > 0.1:
		# Vibrate controllers based on thrust
		var intensity = haptic_base_intensity + (current_thrust * (haptic_max_intensity - haptic_base_intensity))
		var frequency = haptic_base_frequency + (current_thrust * (haptic_max_frequency - haptic_base_frequency))

		# Apply continuous haptic effect
		haptic_manager.start_continuous_effect(
			"both",
			"jetpack_thrust",
			intensity,
			0.1  # Short duration, continuously renewed
		)

		# Use built-in trigger_haptic for each frame
		haptic_manager.trigger_haptic("left", intensity, 0.1)
		haptic_manager.trigger_haptic("right", intensity, 0.1)
	else:
		# Stop haptics when thrust stops
		haptic_manager.stop_continuous_effect("both", "jetpack_thrust")

## Update fuel warning state
func _update_fuel_warning() -> void:
	var fuel_ratio = current_fuel_percent / 100.0
	var new_warning_level: FuelWarning

	if fuel_ratio > 0.5:
		new_warning_level = FuelWarning.NORMAL
	elif fuel_ratio > 0.2:
		new_warning_level = FuelWarning.LOW
	else:
		new_warning_level = FuelWarning.CRITICAL

	# Emit signal if warning level changed
	if new_warning_level != current_warning_level:
		current_warning_level = new_warning_level
		fuel_warning_changed.emit(current_warning_level)

		# Update warning audio
		if current_warning_level == FuelWarning.CRITICAL:
			if low_fuel_warning_sound and not low_fuel_warning_sound.playing:
				low_fuel_warning_sound.volume_db = warning_volume_db
				low_fuel_warning_sound.play()
		else:
			if low_fuel_warning_sound and low_fuel_warning_sound.playing:
				low_fuel_warning_sound.stop()

## Set the walking controller reference
func set_walking_controller(controller: WalkingController) -> void:
	walking_controller = controller

## Set effects quality level
func set_quality_level(quality: int) -> void:
	effects_quality = clamp(quality, 0, 2)

	# Adjust particle counts based on quality
	match effects_quality:
		0:  # Low
			if thrust_particles:
				thrust_particles.amount = thrust_particle_count / 2
			if smoke_particles:
				smoke_particles.amount = smoke_particle_count / 2
			if spark_particles:
				spark_particles.amount = spark_particle_count / 2
		1:  # Medium
			if thrust_particles:
				thrust_particles.amount = int(thrust_particle_count * 0.75)
			if smoke_particles:
				smoke_particles.amount = int(smoke_particle_count * 0.75)
			if spark_particles:
				spark_particles.amount = int(spark_particle_count * 0.75)
		2:  # High
			if thrust_particles:
				thrust_particles.amount = thrust_particle_count
			if smoke_particles:
				smoke_particles.amount = smoke_particle_count
			if spark_particles:
				spark_particles.amount = spark_particle_count

## Get current effect status
func get_effect_status() -> Dictionary:
	return {
		"active": is_active,
		"thrust": current_thrust,
		"fuel_percent": current_fuel_percent,
		"warning_level": current_warning_level,
		"distance_to_ground": distance_to_ground,
		"overheated": is_overheated,
		"continuous_thrust_time": continuous_thrust_time,
		"particle_counts": {
			"thrust": thrust_particles.amount if thrust_particles else 0,
			"smoke": smoke_particles.amount if smoke_particles else 0,
			"sparks": spark_particles.amount if spark_particles else 0
		}
	}

#endregion

#region Helper Methods

## Get reference to ResonanceEngine
func _get_engine() -> Node:
	return get_node_or_null("/root/ResonanceEngine")

## Logging helpers
func _log_debug(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_debug"):
		engine.log_debug("[JetpackEffects] " + message)
	else:
		print("[DEBUG] [JetpackEffects] " + message)

func _log_info(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_info"):
		engine.log_info("[JetpackEffects] " + message)
	else:
		print("[INFO] [JetpackEffects] " + message)

func _log_warning(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_warning"):
		engine.log_warning("[JetpackEffects] " + message)
	else:
		push_warning("[JetpackEffects] " + message)

func _log_error(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_error"):
		engine.log_error("[JetpackEffects] " + message)
	else:
		push_error("[JetpackEffects] " + message)

#endregion
