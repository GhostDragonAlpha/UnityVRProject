extends Node
class_name MoonLandingPolish
## Applies visual polish to moon landing scene
## Improves materials, lighting, and adds environment effects

## Preload classes
const CameraShake = preload("res://scripts/vfx/camera_shake.gd")
const LandingEffects = preload("res://scripts/vfx/landing_effects.gd")
const WalkingDustEffects = preload("res://scripts/vfx/walking_dust_effects.gd")

## References
var moon_mesh: MeshInstance3D = null
var earth_mesh: MeshInstance3D = null
var spacecraft_mesh: MeshInstance3D = null
var directional_light: DirectionalLight3D = null
var walking_controller: WalkingController = null
var world_environment: WorldEnvironment = null

## Created effects
var walking_dust_effects: WalkingDustEffects = null
var landing_effects: LandingEffects = null
var starfield: Node3D = null
var earth_atmosphere_glow: OmniLight3D = null
var camera_shake: CameraShake = null


func _ready() -> void:
	# Wait one frame for scene to load
	await get_tree().process_frame

	# Find scene nodes
	find_scene_nodes()

	# Apply polish
	improve_moon_material()
	improve_earth_material()
	improve_spacecraft_material()
	setup_lighting()
	create_starfield()
	add_earth_atmosphere()
	setup_landing_effects()
	setup_walking_dust_effects()
	setup_camera_shake()

	print("[MoonLandingPolish] Visual polish applied!")


## Find all necessary nodes in the scene
func find_scene_nodes() -> void:
	# Find Moon
	var moon = get_node_or_null("../Moon")
	if moon:
		moon_mesh = moon.get_node_or_null("MoonMesh")

	# Find Earth
	var earth = get_node_or_null("../Earth")
	if earth:
		earth_mesh = earth.get_node_or_null("EarthMesh")

	# Find Spacecraft
	var spacecraft = get_node_or_null("../Spacecraft")
	if spacecraft:
		for child in spacecraft.get_children():
			if child is MeshInstance3D:
				spacecraft_mesh = child
				break

	# Find Environment
	var environment = get_node_or_null("../Environment")
	if environment:
		directional_light = environment.get_node_or_null("DirectionalLight3D")
		world_environment = environment.get_node_or_null("WorldEnvironment")


## Improve moon surface material
func improve_moon_material() -> void:
	if not moon_mesh:
		print("[MoonLandingPolish] Moon mesh not found!")
		return

	var material = StandardMaterial3D.new()

	# Base color (lunar gray)
	material.albedo_color = Color(0.5, 0.5, 0.5, 1.0)

	# Roughness (very rough surface)
	material.roughness = 0.95
	material.metallic = 0.0

	# Normal map simulation (would be better with actual texture)
	# For now, use high roughness to simulate rough surface

	# Disable emission
	material.emission_enabled = false

	# Enable shadows
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	moon_mesh.material_override = material
	print("[MoonLandingPolish] Moon material improved")


## Improve Earth material with atmosphere effect
func improve_earth_material() -> void:
	if not earth_mesh:
		print("[MoonLandingPolish] Earth mesh not found!")
		return

	var material = StandardMaterial3D.new()

	# Base color (ocean blue)
	material.albedo_color = Color(0.1, 0.3, 0.7, 1.0)

	# Slight metallic for water reflection
	material.metallic = 0.3
	material.roughness = 0.6

	# Add emission for atmosphere glow
	material.emission_enabled = true
	material.emission = Color(0.2, 0.4, 0.8, 1.0)
	material.emission_energy_multiplier = 0.3

	earth_mesh.material_override = material
	print("[MoonLandingPolish] Earth material improved")


## Improve spacecraft material (metallic)
func improve_spacecraft_material() -> void:
	if not spacecraft_mesh:
		print("[MoonLandingPolish] Spacecraft mesh not found!")
		return

	var material = StandardMaterial3D.new()

	# Base color (metallic gray)
	material.albedo_color = Color(0.7, 0.7, 0.75, 1.0)

	# Metallic properties
	material.metallic = 0.8
	material.roughness = 0.3

	# Rim lighting for dramatic effect
	material.rim_enabled = true
	material.rim = 0.5
	material.rim_tint = 0.5

	# Enable reflections
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	spacecraft_mesh.material_override = material
	print("[MoonLandingPolish] Spacecraft material improved")


## Setup dramatic lighting
func setup_lighting() -> void:
	if not directional_light:
		print("[MoonLandingPolish] Directional light not found!")
		return

	# Adjust light for dramatic shadows
	directional_light.light_energy = 2.0
	directional_light.light_color = Color(1.0, 0.98, 0.95, 1.0)  # Slightly warm sunlight

	# Improve shadows
	directional_light.shadow_enabled = true
	directional_light.shadow_bias = 0.1

	# Setup environment if available
	if world_environment:
		setup_environment()

	print("[MoonLandingPolish] Lighting improved")


## Setup world environment
func setup_environment() -> void:
	if not world_environment:
		return

	var environment = Environment.new()

	# Background (solid black for space)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK

	# Ambient light (very low for space)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.05, 0.05, 0.1, 1.0)
	environment.ambient_light_energy = 0.2

	# Disable fog (space has no atmosphere)
	environment.fog_enabled = false

	# Enable glow for bright lights
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_strength = 0.9
	environment.glow_bloom = 0.3

	# Adjust exposure for space
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.2

	world_environment.environment = environment
	print("[MoonLandingPolish] Environment configured")


## Create simple starfield
func create_starfield() -> void:
	starfield = Node3D.new()
	starfield.name = "Starfield"

	# Create random star positions far away
	for i in range(200):
		var star = create_star()
		starfield.add_child(star)

	# Add to scene
	var environment = get_node_or_null("../Environment")
	if environment:
		environment.add_child(starfield)

	print("[MoonLandingPolish] Starfield created with 200 stars")


## Create a single star (small glowing point)
func create_star() -> OmniLight3D:
	var star_light = OmniLight3D.new()

	# Random position on sphere far away
	var distance = randf_range(50000, 100000)
	var theta = randf() * TAU
	var phi = randf() * PI

	var x = distance * sin(phi) * cos(theta)
	var y = distance * sin(phi) * sin(theta)
	var z = distance * cos(phi)

	star_light.position = Vector3(x, y, z)

	# Random brightness and slight color variation
	star_light.light_color = Color(
		randf_range(0.9, 1.0),
		randf_range(0.9, 1.0),
		randf_range(0.95, 1.0),
		1.0
	)
	star_light.light_energy = randf_range(0.5, 1.5)
	star_light.omni_range = randf_range(100, 300)
	star_light.omni_attenuation = 2.0

	return star_light


## Add atmosphere glow to Earth
func add_earth_atmosphere() -> void:
	if not earth_mesh:
		return

	earth_atmosphere_glow = OmniLight3D.new()
	earth_atmosphere_glow.name = "AtmosphereGlow"
	earth_atmosphere_glow.position = Vector3.ZERO

	# Blue atmospheric glow
	earth_atmosphere_glow.light_color = Color(0.3, 0.5, 1.0, 1.0)
	earth_atmosphere_glow.light_energy = 2.0
	earth_atmosphere_glow.omni_range = 80.0
	earth_atmosphere_glow.omni_attenuation = 0.5

	# Add to Earth node
	var earth = get_node_or_null("../Earth")
	if earth:
		earth.add_child(earth_atmosphere_glow)

	print("[MoonLandingPolish] Earth atmosphere glow added")


## Setup landing effects on spacecraft
func setup_landing_effects() -> void:
	setup_walking_dust_effects()
	var spacecraft = get_node_or_null("../Spacecraft") as Spacecraft
	if not spacecraft:
		print("[MoonLandingPolish] Spacecraft not found!")
		return

	landing_effects = LandingEffects.new()
	landing_effects.name = "LandingEffects"
	spacecraft.add_child(landing_effects)
	landing_effects.setup(spacecraft)

	# Connect to landing detector for dust trigger
	var landing_detector = spacecraft.get_node_or_null("LandingDetector")
	if landing_detector:
		landing_detector.landing_detected.connect(_on_landing_detected)

	print("[MoonLandingPolish] Landing effects added to spacecraft")


## Trigger landing dust when spacecraft lands
func _on_landing_detected(spacecraft_node: Node3D, planet: CelestialBody) -> void:
	if landing_effects:
		landing_effects.trigger_landing_dust()

	# Trigger camera shake on landing impact
	if camera_shake and spacecraft_node:
		var velocity = spacecraft_node.linear_velocity.length()
		camera_shake.impact_shake(velocity, 1.0)

	print("[MoonLandingPolish] Landing detected - dust triggered!")


## Setup camera shake for VR camera
func setup_camera_shake() -> void:
	# Find XRCamera3D (VR) or fallback to Camera3D (desktop)
	var xr_origin = get_node_or_null("../XROrigin3D")
	var camera: Node3D = null

	if xr_origin:
		camera = xr_origin.get_node_or_null("XRCamera3D")

	# Fallback to desktop camera if no VR
	if not camera:
		var environment = get_node_or_null("../Environment")
		if environment:
			camera = environment.get_node_or_null("Camera3D")

	if not camera:
		print("[MoonLandingPolish] No camera found for shake!")
		return

	# Create camera shake system
	camera_shake = CameraShake.new()
	camera_shake.name = "CameraShake"
	add_child(camera_shake)
	camera_shake.setup(camera)

	# Connect to spacecraft signals
	var spacecraft = get_node_or_null("../Spacecraft") as Spacecraft
	if spacecraft:
		# Connect collision signal for impact shake
		spacecraft.collision_occurred.connect(_on_spacecraft_collision)

		# Connect thrust signal for continuous shake
		spacecraft.thrust_applied.connect(_on_spacecraft_thrust)

	print("[MoonLandingPolish] Camera shake setup complete!")


## Trigger impact shake on spacecraft collision
func _on_spacecraft_collision(collision_info: Dictionary) -> void:
	if camera_shake and collision_info.has("impulse"):
		var impulse = collision_info.get("impulse", Vector3.ZERO)
		var impact_force = impulse.length()
		# Scale shake based on collision force
		camera_shake.impact_shake(impact_force * 0.1, 0.8)


## Apply continuous shake during thrust
func _on_spacecraft_thrust(force: Vector3) -> void:
	if camera_shake:
		var thrust_magnitude = force.length()
		# Subtle continuous shake proportional to thrust
		var shake_intensity = clampf(thrust_magnitude / 100000.0, 0.0, 0.3)
		camera_shake.continuous_shake(shake_intensity, get_process_delta_time())




## Setup walking dust effects
## INCLUDES: Footstep dust clouds AND jump landing dust (GPUParticles3D)
func setup_walking_dust_effects() -> void:
	# Walking controller may not exist yet (created during landing)
	# We will defer connection until walking mode starts

	# Try to find transition system to connect to walking mode signal
	var spacecraft = get_node_or_null("../Spacecraft") as Spacecraft
	if not spacecraft:
		print("[MoonLandingPolish] Spacecraft not found - walking dust will be setup on walking_started signal")
		return

	var transition_system = spacecraft.get_node_or_null("TransitionSystem")
	if transition_system and transition_system.has_signal("walking_mode_enabled"):
		transition_system.walking_mode_enabled.connect(_on_walking_mode_enabled)
		print("[MoonLandingPolish] Connected to walking_mode_enabled signal")
	else:
		print("[MoonLandingPolish] TransitionSystem not found - will setup walking dust manually")


## Called when walking mode is enabled
func _on_walking_mode_enabled() -> void:
	print("[MoonLandingPolish] Walking mode enabled - setting up walking dust effects")

	# Find walking controller (should be created by now)
	var scene_root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	walking_controller = find_walking_controller(scene_root)

	if not walking_controller:
		print("[MoonLandingPolish] WalkingController not found!")
		return

	# Create walking dust effects
	walking_dust_effects = WalkingDustEffects.new()
	walking_dust_effects.name = "WalkingDustEffects"
	walking_controller.add_child(walking_dust_effects)
	walking_dust_effects.set_walking_controller(walking_controller)

	# Connect to walking signals
	if walking_controller.has_signal("walking_started"):
		walking_controller.walking_started.connect(_on_walking_started)
	if walking_controller.has_signal("walking_stopped"):
		walking_controller.walking_stopped.connect(_on_walking_stopped)

	print("[MoonLandingPolish] Walking dust effects added (footsteps + jump landings)")


## Recursively find WalkingController in scene tree
func find_walking_controller(node: Node) -> WalkingController:
	if node is WalkingController:
		return node

	for child in node.get_children():
		var result = find_walking_controller(child)
		if result:
			return result

	return null


## Called when walking mode starts
func _on_walking_started() -> void:
	print("[MoonLandingPolish] Walking started - dust effects active")


## Called when walking mode stops
func _on_walking_stopped() -> void:
	print("[MoonLandingPolish] Walking stopped - dust effects paused")



## Cleanup
func _exit_tree() -> void:
	if starfield and starfield.get_parent():
		starfield.queue_free()
	if earth_atmosphere_glow and earth_atmosphere_glow.get_parent():
		earth_atmosphere_glow.queue_free()
	if camera_shake:
		camera_shake.queue_free()
	if walking_dust_effects:
		walking_dust_effects.queue_free()

