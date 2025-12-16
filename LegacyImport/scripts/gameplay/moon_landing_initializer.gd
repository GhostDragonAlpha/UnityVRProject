extends Node
class_name MoonLandingInitializer
## Initializes the moon landing scene
## Sets up references, applies lunar gravity, and connects all systems

@export var moon: CelestialBody = null
@export var earth: CelestialBody = null
@export var spacecraft: Spacecraft = null
@export var pilot_controller: PilotController = null
@export var transition_system: TransitionSystem = null
@export var landing_detector: LandingDetector = null
@export var moon_hud: MoonHUD = null
@export var vr_controller: Node = null  # MoonLandingVRController


func _ready() -> void:
	# Wait one frame for scene to fully load
	await get_tree().process_frame

	# Find references if not set
	find_scene_nodes()

	# Initialize all systems
	initialize_moon()
	initialize_spacecraft()
	initialize_vr_controller()
	initialize_landing_detector()
	initialize_hud()
	apply_lunar_gravity()
	connect_signals()

	print("[MoonLandingInitializer] Moon landing scene initialized!")
	print("  - Moon gravity: %.2f m/s²" % moon.get_surface_gravity() if moon else "  - Moon: NOT FOUND")
	print("  - Spacecraft altitude: %.1f m" % landing_detector.get_altitude() if landing_detector else "  - Landing detector: NOT FOUND")


func find_scene_nodes() -> void:
	"""Find all necessary nodes in the scene."""
	if not moon:
		moon = get_node_or_null("../Moon")
	if not earth:
		earth = get_node_or_null("../Earth")
	if not spacecraft:
		spacecraft = get_node_or_null("../Spacecraft")
	if not pilot_controller:
		pilot_controller = get_node_or_null("../Spacecraft/PilotController")
	if not transition_system:
		transition_system = get_node_or_null("../Spacecraft/TransitionSystem")
	if not landing_detector:
		landing_detector = get_node_or_null("../Spacecraft/LandingDetector")
	if not moon_hud:
		moon_hud = get_node_or_null("../UI/MoonHUD")
	if not vr_controller:
		vr_controller = get_node_or_null("../VRController")


func initialize_moon() -> void:
	"""Initialize the Moon celestial body."""
	if not moon:
		push_error("[MoonLandingInitializer] Moon node not found!")
		return

	# Moon is already set up with proper mass and radius
	# Real moon: mass = 7.342e22 kg, radius = 1737.4 km
	# Our moon: radius = 500m (scaled for gameplay)
	# This gives lunar gravity of approximately 1.62 m/s²

	# Add to celestial_bodies group for detection
	moon.add_to_group("celestial_bodies")

	print("[MoonLandingInitializer] Moon initialized: ", moon.body_name)
	print("  - Mass: ", moon.mass, " kg")
	print("  - Radius: %.1f m" % moon.radius)
	print("  - Surface gravity: %.2f m/s²" % moon.get_surface_gravity())


func initialize_spacecraft() -> void:
	"""Initialize the spacecraft and its controllers."""
	if not spacecraft:
		push_error("[MoonLandingInitializer] Spacecraft node not found!")
		return

	# Connect pilot controller to spacecraft
	if pilot_controller:
		pilot_controller.set_spacecraft(spacecraft)
		print("[MoonLandingInitializer] Pilot controller connected to spacecraft")

	# Initialize transition system
	if transition_system:
		# Note: We don't have LOD manager, floating origin, or atmosphere system in this simple demo
		transition_system.initialize(spacecraft, null, null, null, null)
		print("[MoonLandingInitializer] Transition system initialized")


func initialize_vr_controller() -> void:
	"""Initialize the VR controller."""
	if not vr_controller:
		push_warning("[MoonLandingInitializer] VR controller not found - VR mode may not work properly")
		return

	print("[MoonLandingInitializer] VR controller initialized")


func initialize_landing_detector() -> void:
	"""Initialize the landing detector."""
	if not landing_detector:
		push_error("[MoonLandingInitializer] Landing detector not found!")
		return

	if not spacecraft or not moon:
		push_error("[MoonLandingInitializer] Cannot initialize landing detector - missing spacecraft or moon")
		return

	landing_detector.initialize(spacecraft, moon, transition_system)

	# Connect VR controller to landing detector
	if vr_controller:
		landing_detector.vr_controller = vr_controller

	print("[MoonLandingInitializer] Landing detector initialized")


func initialize_hud() -> void:
	"""Initialize the HUD."""
	if not moon_hud:
		push_error("[MoonLandingInitializer] Moon HUD not found!")
		return

	# Get walking controller from transition system if it exists
	var walking_controller: WalkingController = null
	if transition_system:
		walking_controller = transition_system.get_walking_controller()

	moon_hud.initialize(landing_detector, walking_controller)
	print("[MoonLandingInitializer] HUD initialized")


func apply_lunar_gravity() -> void:
	"""Apply lunar gravity to the spacecraft."""
	if not spacecraft or not moon:
		return

	# The spacecraft is a RigidBody3D with gravity_scale = 0.0
	# We need to manually apply gravitational force each physics frame
	# This is a simple implementation - in production, PhysicsEngine would handle this

	# Calculate initial gravitational force
	var gravity_accel = moon.calculate_gravity_at_point(spacecraft.global_position)
	print("[MoonLandingInitializer] Initial gravity acceleration: ", gravity_accel.length(), " m/s²")


func _physics_process(delta: float) -> void:
	"""Apply lunar gravity to spacecraft each physics frame."""
	if not spacecraft or not moon:
		return

	# Calculate gravitational force from the moon
	var gravity_force = moon.calculate_gravitational_force(spacecraft.global_position, spacecraft.mass)

	# Apply the force to the spacecraft
	spacecraft.apply_central_force(gravity_force)


func connect_signals() -> void:
	"""Connect signals between systems."""
	if not vr_controller or not landing_detector:
		return

	# Connect landing detector signal to VR controller for mode switching
	if landing_detector.has_signal("walking_mode_requested"):
		landing_detector.walking_mode_requested.connect(_on_walking_mode_requested)

	print("[MoonLandingInitializer] Signals connected")


func _on_walking_mode_requested() -> void:
	"""Handle walking mode request."""
	if vr_controller and vr_controller.has_method("switch_to_walking_mode"):
		vr_controller.switch_to_walking_mode()
		print("[MoonLandingInitializer] Switching to walking mode via VR controller")
