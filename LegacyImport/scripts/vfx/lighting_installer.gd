extends Node
class_name LightingInstaller
## Installs dynamic thruster and warning lights on spacecraft
## Drop-in solution - just add this node to moon_landing.tscn

const CockpitIndicators = preload("res://scripts/ui/cockpit_indicators.gd")

var cockpit_indicators: CockpitIndicators = null


func _ready() -> void:
	await get_tree().process_frame
	install_lighting()


func install_lighting() -> void:
	var spacecraft = get_node_or_null("../Spacecraft") as Spacecraft
	if not spacecraft:
		print("[LightingInstaller] ERROR: Spacecraft not found!")
		return

	print("[LightingInstaller] Installing dynamic lighting...")

	# Create thruster lights
	create_thruster_light(spacecraft, "ThrusterLightMain", Vector3(0, -1.5, 2.5), 10.0)
	create_thruster_light(spacecraft, "ThrusterLightLeft", Vector3(-1.5, 0, 1.5), 5.0)
	create_thruster_light(spacecraft, "ThrusterLightRight", Vector3(1.5, 0, 1.5), 5.0)

	# Create warning lights
	create_warning_light(spacecraft, "WarningLightAltitude", Vector3(-0.8, 0.5, -1.8))
	create_warning_light(spacecraft, "WarningLightFuel", Vector3(0, 0.5, -1.8))
	create_warning_light(spacecraft, "WarningLightSpeed", Vector3(0.8, 0.5, -1.8))

	# Setup cockpit indicators system
	cockpit_indicators = CockpitIndicators.new()
	cockpit_indicators.name = "CockpitIndicators"
	add_child(cockpit_indicators)

	var landing_detector = spacecraft.get_node_or_null("LandingDetector")
	cockpit_indicators.initialize(spacecraft, landing_detector)

	print("[LightingInstaller] Dynamic lighting installed successfully!")


func create_thruster_light(parent: Node, light_name: String, pos: Vector3, range_val: float) -> void:
	var light = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = Color(0.8, 0.9, 1.0)  # Cool blue-white
	light.light_energy = 0.0
	light.omni_range = range_val
	light.omni_attenuation = 2.0
	light.visible = false
	parent.add_child(light)


func create_warning_light(parent: Node, light_name: String, pos: Vector3) -> void:
	var light = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = Color(0.2, 1.0, 0.2)  # Green (safe state)
	light.light_energy = 1.0
	light.omni_range = 1.5
	light.omni_attenuation = 1.5
	light.visible = true
	parent.add_child(light)
