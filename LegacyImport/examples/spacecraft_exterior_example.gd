## Spacecraft Exterior Example
## Demonstrates the spacecraft exterior model with LOD switching,
## material configuration, and engine effects.
extends Node3D

## Reference to spacecraft exterior
var spacecraft_exterior: SpacecraftExterior

## Camera for viewing
var camera: Camera3D

## Camera orbit parameters
var orbit_distance: float = 20.0
var orbit_angle: float = 0.0
var orbit_height: float = 5.0
var orbit_speed: float = 0.3

## Engine throttle simulation
var throttle: float = 0.0
var throttle_direction: float = 1.0

## UI labels
var ui_container: Control
var lod_label: Label
var distance_label: Label
var throttle_label: Label
var stats_label: Label


func _ready() -> void:
	print("\n=== Spacecraft Exterior Example ===")
	print("This example demonstrates the spacecraft exterior model")
	print("with LOD switching, materials, and engine effects.\n")
	
	# Create spacecraft exterior
	_create_spacecraft()
	
	# Create camera
	_create_camera()
	
	# Create UI
	_create_ui()
	
	# Create environment
	_create_environment()
	
	print("Controls:")
	print("  Mouse: Rotate camera")
	print("  Scroll: Zoom in/out")
	print("  1-4: Force LOD level")
	print("  Q: Toggle high quality materials")
	print("  R: Toggle glass refraction")
	print("  ESC: Quit\n")


func _process(delta: float) -> void:
	# Update camera orbit
	_update_camera(delta)
	
	# Simulate engine throttle
	_update_throttle(delta)
	
	# Update UI
	_update_ui()
	
	# Handle input
	_handle_input()


func _create_spacecraft() -> void:
	"""Create the spacecraft exterior model."""
	var scene = load("res://scenes/spacecraft/spacecraft_exterior.tscn")
	spacecraft_exterior = scene.instantiate()
	add_child(spacecraft_exterior)
	
	# Position at origin
	spacecraft_exterior.global_position = Vector3.ZERO
	spacecraft_exterior.global_rotation = Vector3.ZERO
	
	print("✓ Spacecraft exterior loaded")


func _create_camera() -> void:
	"""Create orbiting camera."""
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera)
	
	# Set initial position
	camera.global_position = Vector3(orbit_distance, orbit_height, 0)
	camera.look_at(Vector3.ZERO)
	
	print("✓ Camera created")


func _create_ui() -> void:
	"""Create UI overlay."""
	# Create UI container
	ui_container = Control.new()
	ui_container.name = "UI"
	ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_container)
	
	# LOD label
	lod_label = Label.new()
	lod_label.position = Vector2(10, 10)
	lod_label.add_theme_font_size_override("font_size", 16)
	ui_container.add_child(lod_label)
	
	# Distance label
	distance_label = Label.new()
	distance_label.position = Vector2(10, 35)
	distance_label.add_theme_font_size_override("font_size", 16)
	ui_container.add_child(distance_label)
	
	# Throttle label
	throttle_label = Label.new()
	throttle_label.position = Vector2(10, 60)
	throttle_label.add_theme_font_size_override("font_size", 16)
	ui_container.add_child(throttle_label)
	
	# Stats label
	stats_label = Label.new()
	stats_label.position = Vector2(10, 85)
	stats_label.add_theme_font_size_override("font_size", 14)
	ui_container.add_child(stats_label)
	
	print("✓ UI created")


func _create_environment() -> void:
	"""Create lighting and environment."""
	# Create WorldEnvironment
	var world_env = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Configure environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)  # Dark space
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.1, 0.1, 0.15)
	environment.ambient_light_energy = 0.3
	
	world_env.environment = environment
	add_child(world_env)
	
	# Create directional light (sun)
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.5
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)
	
	print("✓ Environment created")


func _update_camera(delta: float) -> void:
	"""Update camera orbit around spacecraft."""
	# Update orbit angle
	orbit_angle += orbit_speed * delta
	
	# Calculate camera position
	var x = cos(orbit_angle) * orbit_distance
	var z = sin(orbit_angle) * orbit_distance
	camera.global_position = Vector3(x, orbit_height, z)
	
	# Look at spacecraft
	camera.look_at(Vector3.ZERO)


func _update_throttle(delta: float) -> void:
	"""Simulate engine throttle changes."""
	# Oscillate throttle between 0 and 1
	throttle += throttle_direction * delta * 0.5
	
	if throttle >= 1.0:
		throttle = 1.0
		throttle_direction = -1.0
	elif throttle <= 0.0:
		throttle = 0.0
		throttle_direction = 1.0
	
	# Update engine intensity
	if spacecraft_exterior:
		spacecraft_exterior.set_engine_intensity(throttle)


func _update_ui() -> void:
	"""Update UI labels."""
	if not spacecraft_exterior:
		return
	
	# Get current LOD
	var current_lod = spacecraft_exterior.get_current_lod()
	lod_label.text = "LOD Level: " + str(current_lod) + " / 3"
	
	# Get distance to camera
	var distance = spacecraft_exterior.global_position.distance_to(camera.global_position)
	distance_label.text = "Distance: " + str(snapped(distance, 0.1)) + "m"
	
	# Show throttle
	throttle_label.text = "Engine Throttle: " + str(snapped(throttle * 100, 1)) + "%"
	
	# Show statistics
	var stats = spacecraft_exterior.get_statistics()
	stats_label.text = "High Quality: " + str(stats.high_quality) + " | Glass Refraction: " + str(stats.glass_refraction)


func _handle_input() -> void:
	"""Handle keyboard input."""
	# Force LOD levels
	if Input.is_action_just_pressed("ui_text_1"):
		spacecraft_exterior.force_lod_level(0)
		print("Forced LOD 0 (Highest Detail)")
	elif Input.is_action_just_pressed("ui_text_2"):
		spacecraft_exterior.force_lod_level(1)
		print("Forced LOD 1 (Medium Detail)")
	elif Input.is_action_just_pressed("ui_text_3"):
		spacecraft_exterior.force_lod_level(2)
		print("Forced LOD 2 (Low Detail)")
	elif Input.is_action_just_pressed("ui_text_4"):
		spacecraft_exterior.force_lod_level(3)
		print("Forced LOD 3 (Minimal Detail)")
	
	# Toggle high quality materials
	if Input.is_key_pressed(KEY_Q):
		var current = spacecraft_exterior.enable_high_quality_materials
		spacecraft_exterior.set_high_quality_materials(not current)
		print("High Quality Materials: ", not current)
	
	# Toggle glass refraction
	if Input.is_key_pressed(KEY_R):
		var current = spacecraft_exterior.enable_glass_refraction
		spacecraft_exterior.set_glass_refraction(not current)
		print("Glass Refraction: ", not current)
	
	# Zoom with scroll (simulated with +/-)
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_PLUS):
		orbit_distance = maxf(5.0, orbit_distance - 0.5)
	elif Input.is_key_pressed(KEY_MINUS):
		orbit_distance = minf(100.0, orbit_distance + 0.5)


func _input(event: InputEvent) -> void:
	"""Handle input events."""
	# Quit on ESC
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			print("\nExiting example...")
			get_tree().quit()
