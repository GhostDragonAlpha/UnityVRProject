extends Node3D
## Template for feature test scenes
## Copy this for each new feature
##
## USAGE:
## 1. Create new scene based on this template
## 2. Override _init_feature() to implement your feature logic
## 3. Add feature-specific nodes as children
## 4. Press F12 to quickly exit to main menu

@onready var engine := get_node("/root/ResonanceEngine") if has_node("/root/ResonanceEngine") else null

func _ready() -> void:
	print("[FeatureTemplate] Initializing...")

	# Check required autoloads
	if not engine:
		push_warning("ResonanceEngine not available - some features may not work")
	else:
		print("[FeatureTemplate] ResonanceEngine available")

	# Initialize feature
	_init_feature()

	print("[FeatureTemplate] Initialization complete")

func _init_feature() -> void:
	"""Override this in your feature scene script"""
	pass

func _unhandled_input(event: InputEvent) -> void:
	# F12 = Quick exit to main menu
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		print("[FeatureTemplate] F12 pressed - returning to main menu")
		# Check if main menu exists, otherwise go to minimal test scene
		if ResourceLoader.exists("res://scenes/production/main_menu.tscn"):
			get_tree().change_scene_to_file("res://scenes/production/main_menu.tscn")
		else:
			print("[FeatureTemplate] Main menu not found, going to minimal_test.tscn")
			get_tree().change_scene_to_file("res://minimal_test.tscn")
