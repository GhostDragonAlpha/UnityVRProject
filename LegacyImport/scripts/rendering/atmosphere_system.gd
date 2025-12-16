extends Node
class_name AtmosphereSystem
## Handles atmospheric effects during planetary descent
## Applies drag forces, heat effects, and visual atmosphere rendering
##
## Requirements:
## - 54.1: Apply atmospheric drag forces to slow spacecraft
## - 54.2: Render heat shimmer and plasma effects
## - 54.3: Increase audio intensity with rumbling
## - 54.4: Apply heat damage at excessive speeds
## - 54.5: Reverse effects when exiting atmosphere

signal drag_applied(force: Vector3)
signal heat_damage_applied(damage: float)
signal atmosphere_effects_updated(intensity: float)

@export var drag_coefficient: float = 0.5
@export var cross_sectional_area: float = 10.0  # m²
@export var heat_damage_threshold: float = 500.0  # m/s
@export var max_heat_damage: float = 10.0  # damage per second

var active: bool = false
var current_planet: CelestialBody = null
var atmosphere_density: float = 1.225  # kg/m³ at sea level (Earth-like)
var spacecraft: RigidBody3D = null

# Visual effects
var atmosphere_material: ShaderMaterial = null
var heat_shimmer_mesh: MeshInstance3D = null
var heat_shimmer_material: ShaderMaterial = null
var plasma_effect: GPUParticles3D = null

# Audio
var rumble_audio: AudioStreamPlayer3D = null
var wind_audio: AudioStreamPlayer3D = null

# Effect intensity tracking
var current_heat_intensity: float = 0.0
var current_audio_intensity: float = 0.0

# Atmosphere color caching (optimization to reduce allocations per frame)
var _cached_atmosphere_ratio: float = -1.0
var _cached_atmosphere_color: Color = Color.BLACK

# Pre-computed color gradient stops for smooth atmospheric transitions
# Avoids creating new Color objects every frame
const ATMOSPHERE_COLOR_GRADIENT: Array[Color] = [
	Color(0.0, 0.0, 0.0, 0.0),      # 0.0: Space (black)
	Color(0.1, 0.1, 0.2, 0.3),      # 0.2: Thin atmosphere (dark blue)
	Color(0.3, 0.5, 0.9, 0.6),      # 0.5: Medium atmosphere (blue)
	Color(0.5, 0.7, 1.0, 0.8),      # 0.8: Dense atmosphere (bright blue)
	Color(0.6, 0.8, 1.0, 1.0),      # 1.0: Very dense (brightest)
]

# Ratio stops corresponding to the gradient colors
const ATMOSPHERE_RATIO_STOPS: Array[float] = [
	0.0, 0.2, 0.5, 0.8, 1.0
]

func _ready() -> void:
	setup_visual_effects()
	setup_audio_effects()
	set_process(false)

func setup_visual_effects() -> void:
	# Create atmosphere shader material
	atmosphere_material = ShaderMaterial.new()
	var shader = load("res://shaders/atmosphere.gdshader")
	if shader:
		atmosphere_material.shader = shader
	
	# Create heat shimmer effect mesh (full-screen quad)
	# Requirement 54.2: Render heat shimmer and plasma effects
	heat_shimmer_mesh = MeshInstance3D.new()
	heat_shimmer_mesh.name = "HeatShimmerMesh"
	
	# Create a quad mesh for the heat shimmer
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(2.0, 2.0)
	heat_shimmer_mesh.mesh = quad_mesh
	
	# Create heat shimmer material
	heat_shimmer_material = ShaderMaterial.new()
	var shimmer_shader = load("res://shaders/heat_shimmer.gdshader")
	if shimmer_shader:
		heat_shimmer_material.shader = shimmer_shader
		heat_shimmer_material.set_shader_parameter("intensity", 0.0)
		heat_shimmer_material.set_shader_parameter("time_scale", 1.0)
		heat_shimmer_material.set_shader_parameter("plasma_color", Vector3(1.0, 0.5, 0.2))
		heat_shimmer_mesh.material_override = heat_shimmer_material
	
	add_child(heat_shimmer_mesh)
	heat_shimmer_mesh.visible = false
	
	# Create plasma effect particles
	# Requirement 54.2: Render plasma effects
	plasma_effect = GPUParticles3D.new()
	plasma_effect.name = "PlasmaEffect"
	plasma_effect.emitting = false
	plasma_effect.amount = 200
	plasma_effect.lifetime = 0.8
	plasma_effect.explosiveness = 0.3
	plasma_effect.randomness = 0.5
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 5.0
	particle_material.direction = Vector3(0, 0, -1)
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 10.0
	particle_material.initial_velocity_max = 20.0
	particle_material.gravity = Vector3.ZERO
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	particle_material.color = Color(1.0, 0.6, 0.2, 0.8)
	plasma_effect.process_material = particle_material
	
	# Create particle mesh
	var particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(0.5, 0.5)
	plasma_effect.draw_pass_1 = particle_mesh
	
	add_child(plasma_effect)

func setup_audio_effects() -> void:
	# Requirement 54.3: Increase audio intensity with rumbling
	# Create rumble audio for atmospheric entry
	rumble_audio = AudioStreamPlayer3D.new()
	rumble_audio.name = "RumbleAudio"
	rumble_audio.bus = "SFX"
	rumble_audio.max_distance = 100.0
	rumble_audio.unit_size = 10.0
	add_child(rumble_audio)
	
	# Create wind audio
	wind_audio = AudioStreamPlayer3D.new()
	wind_audio.name = "WindAudio"
	wind_audio.bus = "SFX"
	wind_audio.max_distance = 100.0
	wind_audio.unit_size = 10.0
	add_child(wind_audio)

func activate(planet: CelestialBody, craft: RigidBody3D = null) -> void:
	active = true
	current_planet = planet
	spacecraft = craft
	set_process(true)
	
	# Get atmosphere density from planet
	if planet.has_method("get_atmosphere_density"):
		atmosphere_density = planet.get_atmosphere_density()
	else:
		atmosphere_density = 1.225  # Default density (Earth-like)
	
	print("[AtmosphereSystem] Activated for ", planet.body_name, " (density: ", atmosphere_density, " kg/m³)")

func deactivate() -> void:
	# Requirement 54.5: Reverse effects when exiting atmosphere
	active = false
	current_planet = null
	spacecraft = null
	set_process(false)
	
	# Stop all effects
	stop_visual_effects()
	stop_audio_effects()
	
	# Reset intensity tracking
	current_heat_intensity = 0.0
	current_audio_intensity = 0.0
	
	print("[AtmosphereSystem] Deactivated")

func _process(delta: float) -> void:
	if not active:
		return
	
	# Effects are updated via update_effects() called by TransitionSystem

func update_effects(atmosphere_ratio: float, velocity: Vector3) -> void:
	if not active:
		return
	
	var speed = velocity.length()
	
	# Requirement 54.1: Apply atmospheric drag forces
	apply_drag_force(velocity, atmosphere_ratio)
	
	# Requirement 54.4: Apply heat damage at excessive speeds
	if speed > heat_damage_threshold:
		apply_heat_effects(speed, atmosphere_ratio)
	
	# Requirement 54.2: Render heat shimmer and plasma effects
	update_visual_effects(speed, atmosphere_ratio)
	
	# Requirement 54.3: Increase audio intensity with rumbling
	update_audio_effects(speed, atmosphere_ratio)
	
	# Emit signal for other systems
	var overall_intensity = calculate_overall_intensity(speed, atmosphere_ratio)
	atmosphere_effects_updated.emit(overall_intensity)

func apply_drag_force(velocity: Vector3, atmosphere_ratio: float) -> void:
	# Requirement 54.1: Apply atmospheric drag forces based on velocity and density
	# Formula: F = 0.5 * ρ * v² * Cd * A
	if not spacecraft:
		return
	
	var speed = velocity.length()
	if speed < 0.1:
		return
	
	# Calculate effective atmospheric density
	var effective_density = atmosphere_density * atmosphere_ratio
	
	# Calculate drag force magnitude
	# F = 0.5 * ρ * v² * Cd * A
	var drag_magnitude = 0.5 * effective_density * speed * speed * drag_coefficient * cross_sectional_area
	
	# Drag force opposes velocity direction
	var drag_direction = -velocity.normalized()
	var drag_force = drag_direction * drag_magnitude
	
	# Apply force directly to spacecraft
	spacecraft.apply_central_force(drag_force)
	
	# Emit signal for monitoring
	drag_applied.emit(drag_force)

func apply_heat_effects(speed: float, atmosphere_ratio: float) -> void:
	# Requirement 54.4: Apply heat damage at excessive speeds
	# Heat damage increases with speed above threshold and atmosphere density
	var speed_ratio = (speed - heat_damage_threshold) / heat_damage_threshold
	var heat_damage = speed_ratio * max_heat_damage * atmosphere_ratio
	
	heat_damage = clamp(heat_damage, 0.0, max_heat_damage)
	
	if heat_damage > 0.0:
		heat_damage_applied.emit(heat_damage)
		print("[AtmosphereSystem] Heat damage: ", heat_damage, " (speed: ", speed, " m/s)")

func update_visual_effects(speed: float, atmosphere_ratio: float) -> void:
	# Requirement 54.2: Render heat shimmer and plasma effects
	
	# Update atmosphere shader
	if atmosphere_material:
		atmosphere_material.set_shader_parameter("density", atmosphere_ratio)
		atmosphere_material.set_shader_parameter("tint", get_atmosphere_color(atmosphere_ratio))
	
	# Calculate heat intensity based on speed
	var heat_intensity = 0.0
	if speed > heat_damage_threshold:
		heat_intensity = clamp((speed - heat_damage_threshold) / heat_damage_threshold, 0.0, 1.0)
	
	# Smooth heat intensity changes
	current_heat_intensity = lerp(current_heat_intensity, heat_intensity * atmosphere_ratio, 0.1)
	
	# Update heat shimmer effect
	if heat_shimmer_material:
		heat_shimmer_material.set_shader_parameter("intensity", current_heat_intensity)
		heat_shimmer_material.set_shader_parameter("time_scale", 1.0 + current_heat_intensity * 2.0)
		
		# Show/hide shimmer mesh based on intensity
		if heat_shimmer_mesh:
			heat_shimmer_mesh.visible = current_heat_intensity > 0.01
	
	# Update plasma particle effect
	if plasma_effect:
		var should_emit = speed > heat_damage_threshold * 0.8 and atmosphere_ratio > 0.3
		
		if should_emit:
			if not plasma_effect.emitting:
				plasma_effect.emitting = true
				print("[AtmosphereSystem] Plasma effect started")
			
			# Adjust particle emission based on intensity
			plasma_effect.amount_ratio = current_heat_intensity
			
			# Position plasma effect relative to spacecraft
			if spacecraft:
				plasma_effect.global_position = spacecraft.global_position
		else:
			if plasma_effect.emitting:
				plasma_effect.emitting = false
				print("[AtmosphereSystem] Plasma effect stopped")

func update_audio_effects(speed: float, atmosphere_ratio: float) -> void:
	# Requirement 54.3: Increase audio intensity with rumbling and wind sounds
	
	# Calculate target audio intensity
	var target_audio_intensity = atmosphere_ratio * (1.0 + speed / 500.0)
	target_audio_intensity = clamp(target_audio_intensity, 0.0, 2.0)
	
	# Smooth audio intensity changes
	current_audio_intensity = lerp(current_audio_intensity, target_audio_intensity, 0.05)
	
	# Update rumble audio intensity
	if rumble_audio:
		var rumble_volume = current_audio_intensity * 0.6
		rumble_volume = clamp(rumble_volume, 0.0, 1.0)
		
		if rumble_volume > 0.05:
			if not rumble_audio.playing:
				rumble_audio.play()
				print("[AtmosphereSystem] Rumble audio started")
			
			rumble_audio.volume_db = linear_to_db(rumble_volume)
			# Increase pitch with speed for more intensity
			rumble_audio.pitch_scale = 0.7 + (speed / 1000.0) * 0.6
			
			# Position audio at spacecraft
			if spacecraft:
				rumble_audio.global_position = spacecraft.global_position
		else:
			if rumble_audio.playing:
				rumble_audio.stop()
				print("[AtmosphereSystem] Rumble audio stopped")
	
	# Update wind audio
	if wind_audio:
		var wind_volume = current_audio_intensity * 0.5
		wind_volume = clamp(wind_volume, 0.0, 1.0)
		
		if wind_volume > 0.05:
			if not wind_audio.playing:
				wind_audio.play()
				print("[AtmosphereSystem] Wind audio started")
			
			wind_audio.volume_db = linear_to_db(wind_volume)
			# Wind pitch increases with speed
			wind_audio.pitch_scale = 0.8 + (speed / 500.0) * 0.5
			
			# Position audio at spacecraft
			if spacecraft:
				wind_audio.global_position = spacecraft.global_position
		else:
			if wind_audio.playing:
				wind_audio.stop()
				print("[AtmosphereSystem] Wind audio stopped")

func get_atmosphere_color(atmosphere_ratio: float) -> Color:
	## Optimized atmosphere color calculation with caching
	## Returns a smooth color transition from space (black) to atmosphere (blue)
	## using a pre-computed gradient to avoid allocations every frame.

	# Early return if ratio hasn't changed (cache hit)
	if _cached_atmosphere_ratio == atmosphere_ratio:
		return _cached_atmosphere_color

	# Clamp ratio to valid range [0.0, 1.0]
	var clamped_ratio = clamp(atmosphere_ratio, 0.0, 1.0)

	# Find the two gradient stops to interpolate between
	var result_color: Color = Color.BLACK

	if clamped_ratio <= ATMOSPHERE_RATIO_STOPS[0]:
		# Below first stop: use first color
		result_color = ATMOSPHERE_COLOR_GRADIENT[0]
	elif clamped_ratio >= ATMOSPHERE_RATIO_STOPS[ATMOSPHERE_RATIO_STOPS.size() - 1]:
		# Above last stop: use last color
		result_color = ATMOSPHERE_COLOR_GRADIENT[ATMOSPHERE_COLOR_GRADIENT.size() - 1]
	else:
		# Find surrounding stops and interpolate
		for i in range(ATMOSPHERE_RATIO_STOPS.size() - 1):
			var stop1 = ATMOSPHERE_RATIO_STOPS[i]
			var stop2 = ATMOSPHERE_RATIO_STOPS[i + 1]

			if clamped_ratio >= stop1 and clamped_ratio <= stop2:
				# Interpolate between these two stops
				var color1 = ATMOSPHERE_COLOR_GRADIENT[i]
				var color2 = ATMOSPHERE_COLOR_GRADIENT[i + 1]

				# Calculate local interpolation factor [0.0, 1.0]
				var local_t = (clamped_ratio - stop1) / (stop2 - stop1)

				# Lerp between the two colors
				result_color = color1.lerp(color2, local_t)
				break

	# Cache the result to avoid recalculation next frame if ratio unchanged
	_cached_atmosphere_ratio = atmosphere_ratio
	_cached_atmosphere_color = result_color

	return result_color

func stop_visual_effects() -> void:
	# Requirement 54.5: Reverse effects when exiting atmosphere
	if plasma_effect:
		plasma_effect.emitting = false
	
	if heat_shimmer_material:
		heat_shimmer_material.set_shader_parameter("intensity", 0.0)
	
	if heat_shimmer_mesh:
		heat_shimmer_mesh.visible = false

func stop_audio_effects() -> void:
	# Requirement 54.5: Reverse effects when exiting atmosphere
	if rumble_audio and rumble_audio.playing:
		rumble_audio.stop()
		print("[AtmosphereSystem] Rumble audio stopped (exit)")
	
	if wind_audio and wind_audio.playing:
		wind_audio.stop()
		print("[AtmosphereSystem] Wind audio stopped (exit)")

func get_drag_force(velocity: Vector3, atmosphere_ratio: float = 1.0) -> Vector3:
	"""Calculate drag force for a given velocity and atmosphere ratio."""
	if not active:
		return Vector3.ZERO
	
	var speed = velocity.length()
	if speed < 0.1:
		return Vector3.ZERO
	
	var effective_density = atmosphere_density * atmosphere_ratio
	var drag_magnitude = 0.5 * effective_density * speed * speed * drag_coefficient * cross_sectional_area
	return -velocity.normalized() * drag_magnitude

func calculate_overall_intensity(speed: float, atmosphere_ratio: float) -> float:
	"""Calculate overall effect intensity for external systems."""
	var speed_factor = clamp(speed / 500.0, 0.0, 1.0)
	return atmosphere_ratio * (0.5 + speed_factor * 0.5)

func is_active() -> bool:
	return active

func get_current_planet() -> CelestialBody:
	return current_planet

func get_heat_intensity() -> float:
	"""Get current heat effect intensity."""
	return current_heat_intensity

func get_audio_intensity() -> float:
	"""Get current audio effect intensity."""
	return current_audio_intensity
