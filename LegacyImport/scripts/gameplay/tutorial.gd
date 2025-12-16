## Tutorial - Interactive Tutorial System
## Manages tutorial sequences for first-time players, introducing mechanics one at a time.
##
## Requirements: 36.1, 36.2, 36.3, 36.4, 36.5
## - 36.1: Launch tutorial sequence when player starts game for first time
## - 36.2: Introduce one mechanic at a time with visual demonstrations
## - 36.3: Provide safe practice area with visual speed indicators
## - 36.4: Show trajectory prediction lines and safe/danger zones
## - 36.5: Unlock next section and save progress when section is completed
extends Node
class_name Tutorial

## Emitted when a tutorial step is started
signal tutorial_step_started(step: TutorialStep)
## Emitted when a tutorial step is completed
signal tutorial_step_completed(step: TutorialStep)
## Emitted when the entire tutorial is completed
signal tutorial_completed()
## Emitted when tutorial is skipped
signal tutorial_skipped()
## Emitted when a demonstration is shown
signal demonstration_shown(demo_name: String)

## Tutorial step states
enum StepState {
	NOT_STARTED,
	IN_PROGRESS,
	COMPLETED,
	SKIPPED
}

## Tutorial sections
enum TutorialSection {
	BASIC_CONTROLS,      ## Basic VR controls and movement
	SPACECRAFT_FLIGHT,   ## Spacecraft thrust and rotation
	RELATIVISTIC_FLIGHT, ## High-speed flight and time dilation
	GRAVITY_WELLS,       ## Navigating gravity wells
	SIGNAL_MANAGEMENT,   ## Understanding SNR and entropy
	RESONANCE_BASICS,    ## Harmonic interaction mechanics
	NAVIGATION,          ## Using HUD and navigation tools
	COMPLETED            ## All tutorials done
}

## Tutorial step data
class TutorialStep:
	var section: TutorialSection
	var title: String
	var description: String
	var instructions: Array[String] = []
	var state: StepState = StepState.NOT_STARTED
	var completion_condition: Callable
	var demonstration_animation: String = ""
	var practice_area_enabled: bool = false
	var visual_aids: Array[String] = []  ## Names of visual aid nodes
	
	func _init(p_section: TutorialSection, p_title: String, p_description: String) -> void:
		section = p_section
		title = p_title
		description = p_description

## Current tutorial state
var current_section: TutorialSection = TutorialSection.BASIC_CONTROLS
var current_step: TutorialStep = null
var tutorial_steps: Array[TutorialStep] = []
var completed_steps: Array[TutorialStep] = []

## Tutorial configuration
var tutorial_enabled: bool = true
var first_time_player: bool = true
var save_file_path: String = "user://tutorial_progress.cfg"
var config: ConfigFile = ConfigFile.new()

## Practice area
var practice_area: Node3D = null
var safe_zone_indicator: Node3D = null
var danger_zone_indicator: Node3D = null
var speed_indicator: Label3D = null
var trajectory_line: ImmediateMesh = null

## Animation player for demonstrations
var animation_player: AnimationPlayer = null

## Visual aid nodes
var visual_aids: Dictionary = {}  ## String -> Node3D

## HUD elements
var tutorial_hud: Control = null
var instruction_label: Label = null
var progress_label: Label = null

## Timers
var step_timer: float = 0.0
var demonstration_timer: float = 0.0


func _ready() -> void:
	_load_tutorial_progress()
	_setup_tutorial_steps()
	_setup_animation_player()
	_setup_practice_area()
	_setup_hud()
	
	# Check if this is first time player
	# Requirements: 36.1 - Launch tutorial when player starts for first time
	if first_time_player and tutorial_enabled:
		call_deferred("start_tutorial")


func _process(delta: float) -> void:
	if current_step == null or current_step.state != StepState.IN_PROGRESS:
		return
	
	step_timer += delta
	_check_step_completion()
	_update_visual_aids()
	_update_hud()


## Setup Methods

func _setup_tutorial_steps() -> void:
	"""Initialize all tutorial steps."""
	tutorial_steps.clear()
	
	# Basic Controls
	_add_basic_controls_steps()
	
	# Spacecraft Flight
	_add_spacecraft_flight_steps()
	
	# Relativistic Flight
	_add_relativistic_flight_steps()
	
	# Gravity Wells
	_add_gravity_wells_steps()
	
	# Signal Management
	_add_signal_management_steps()
	
	# Resonance Basics
	_add_resonance_steps()
	
	# Navigation
	_add_navigation_steps()


func _add_basic_controls_steps() -> void:
	"""Add basic VR controls tutorial steps.
	Requirements: 36.2 - Introduce mechanics one at a time
	"""
	var step := TutorialStep.new(
		TutorialSection.BASIC_CONTROLS,
		"VR Controls",
		"Learn how to use your VR controllers to interact with the cockpit."
	)
	step.instructions = [
		"Look around by moving your head",
		"Reach out and touch the glowing control panel",
		"Press the trigger to activate controls"
	]
	step.demonstration_animation = "demo_vr_controls"
	step.completion_condition = func(): return _check_control_interaction()
	tutorial_steps.append(step)


func _add_spacecraft_flight_steps() -> void:
	"""Add spacecraft flight tutorial steps."""
	var step := TutorialStep.new(
		TutorialSection.SPACECRAFT_FLIGHT,
		"Basic Flight",
		"Learn how to control your spacecraft's thrust and rotation."
	)
	step.instructions = [
		"Use the right trigger to apply forward thrust",
		"Use the left thumbstick to rotate your spacecraft",
		"Practice maintaining a steady velocity"
	]
	step.demonstration_animation = "demo_basic_flight"
	step.practice_area_enabled = true
	step.visual_aids = ["speed_indicator", "velocity_vector"]
	step.completion_condition = func(): return _check_flight_practice()
	tutorial_steps.append(step)


func _add_relativistic_flight_steps() -> void:
	"""Add relativistic flight tutorial steps.
	Requirements: 36.3 - Provide safe practice area with visual speed indicators
	"""
	var step := TutorialStep.new(
		TutorialSection.RELATIVISTIC_FLIGHT,
		"High-Speed Flight",
		"Experience time dilation and relativistic effects at high velocities."
	)
	step.instructions = [
		"Accelerate to 50% of light speed",
		"Observe the lattice Doppler shift effects",
		"Notice how time dilation affects the universe",
		"Practice decelerating smoothly"
	]
	step.demonstration_animation = "demo_relativistic_flight"
	step.practice_area_enabled = true
	step.visual_aids = ["speed_indicator", "time_dilation_meter", "doppler_effect"]
	step.completion_condition = func(): return _check_relativistic_practice()
	tutorial_steps.append(step)


func _add_gravity_wells_steps() -> void:
	"""Add gravity well navigation tutorial steps.
	Requirements: 36.4 - Show trajectory prediction lines and safe/danger zones
	"""
	var step := TutorialStep.new(
		TutorialSection.GRAVITY_WELLS,
		"Gravity Wells",
		"Learn to navigate around massive objects and use gravity assists."
	)
	step.instructions = [
		"Approach the practice planet carefully",
		"Watch the trajectory prediction line",
		"Stay in the green safe zone",
		"Avoid the red danger zone near the surface",
		"Use gravity to slingshot around the planet"
	]
	step.demonstration_animation = "demo_gravity_wells"
	step.practice_area_enabled = true
	step.visual_aids = ["trajectory_line", "safe_zone", "danger_zone", "escape_velocity_indicator"]
	step.completion_condition = func(): return _check_gravity_practice()
	tutorial_steps.append(step)


func _add_signal_management_steps() -> void:
	"""Add signal/SNR management tutorial steps."""
	var step := TutorialStep.new(
		TutorialSection.SIGNAL_MANAGEMENT,
		"Signal Coherence",
		"Understand your Signal-to-Noise Ratio (SNR) and how to maintain it."
	)
	step.instructions = [
		"Your SNR is your 'health' as a digital consciousness",
		"Stay near star nodes to maintain signal strength",
		"Watch for visual glitches when SNR drops",
		"Distance from nodes increases signal attenuation"
	]
	step.demonstration_animation = "demo_signal_management"
	step.visual_aids = ["snr_meter", "signal_strength_indicator", "node_distance"]
	step.completion_condition = func(): return _check_signal_understanding()
	tutorial_steps.append(step)


func _add_resonance_steps() -> void:
	"""Add resonance mechanics tutorial steps."""
	var step := TutorialStep.new(
		TutorialSection.RESONANCE_BASICS,
		"Harmonic Resonance",
		"Learn to interact with objects through frequency matching."
	)
	step.instructions = [
		"Scan the target object to determine its frequency",
		"Match the frequency for constructive interference",
		"Invert the frequency for destructive interference",
		"Practice canceling the practice target"
	]
	step.demonstration_animation = "demo_resonance"
	step.practice_area_enabled = true
	step.visual_aids = ["frequency_display", "wave_visualization", "target_object"]
	step.completion_condition = func(): return _check_resonance_practice()
	tutorial_steps.append(step)


func _add_navigation_steps() -> void:
	"""Add navigation tools tutorial steps."""
	var step := TutorialStep.new(
		TutorialSection.NAVIGATION,
		"Navigation Tools",
		"Learn to use the HUD, star map, and navigation markers."
	)
	step.instructions = [
		"View your velocity and position in the HUD",
		"Check your current percentage of light speed",
		"Use navigation markers to find objectives",
		"Access the star map to plan routes"
	]
	step.demonstration_animation = "demo_navigation"
	step.visual_aids = ["hud_highlight", "nav_marker", "star_map"]
	step.completion_condition = func(): return _check_navigation_understanding()
	tutorial_steps.append(step)


func _setup_animation_player() -> void:
	"""Set up animation player for visual demonstrations.
	Requirements: 36.4 - Show visual demonstrations using AnimationPlayer
	"""
	animation_player = AnimationPlayer.new()
	animation_player.name = "TutorialAnimationPlayer"
	add_child(animation_player)
	
	# Create demonstration animations
	_create_demonstration_animations()


func _create_demonstration_animations() -> void:
	"""Create animations for tutorial demonstrations."""
	# Animations will be created procedurally or loaded from resources
	# For now, we set up the structure
	pass


func _setup_practice_area() -> void:
	"""Set up the safe practice area for tutorials.
	Requirements: 36.3 - Provide safe practice area
	"""
	practice_area = Node3D.new()
	practice_area.name = "TutorialPracticeArea"
	practice_area.visible = false
	add_child(practice_area)
	
	# Create safe zone indicator
	safe_zone_indicator = _create_zone_indicator(Color.GREEN, 5000.0)
	safe_zone_indicator.name = "SafeZone"
	practice_area.add_child(safe_zone_indicator)
	
	# Create danger zone indicator
	danger_zone_indicator = _create_zone_indicator(Color.RED, 1000.0)
	danger_zone_indicator.name = "DangerZone"
	practice_area.add_child(danger_zone_indicator)
	
	# Create speed indicator
	speed_indicator = Label3D.new()
	speed_indicator.name = "SpeedIndicator"
	speed_indicator.text = "Speed: 0 km/s"
	speed_indicator.font_size = 48
	speed_indicator.outline_size = 8
	speed_indicator.modulate = Color.CYAN
	practice_area.add_child(speed_indicator)
	
	# Store visual aids
	visual_aids["safe_zone"] = safe_zone_indicator
	visual_aids["danger_zone"] = danger_zone_indicator
	visual_aids["speed_indicator"] = speed_indicator


func _create_zone_indicator(color: Color, radius: float) -> MeshInstance3D:
	"""Create a visual zone indicator sphere."""
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	
	mesh_instance.mesh = sphere_mesh
	
	# Create transparent material
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.2)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh_instance.material_override = material
	return mesh_instance


func _setup_hud() -> void:
	"""Set up tutorial HUD elements."""
	# HUD will be created when integrated with main HUD system
	# For now, we prepare the structure
	pass


## Tutorial Control

func start_tutorial() -> void:
	"""Start the tutorial from the beginning or resume from saved progress.
	Requirements: 36.1 - Launch tutorial sequence for first-time players
	"""
	if not tutorial_enabled:
		return
	
	print("Tutorial: Starting tutorial sequence")
	
	# Find the first incomplete step
	var initial_step: TutorialStep = null
	for step in tutorial_steps:
		if step.state != StepState.COMPLETED:
			initial_step = step
			break
	
	if initial_step == null:
		# All steps completed
		current_section = TutorialSection.COMPLETED
		tutorial_completed.emit()
		return
	
	start_step(initial_step)


func start_step(step: TutorialStep) -> void:
	"""Start a specific tutorial step.
	Requirements: 36.2 - Introduce one mechanic at a time
	"""
	if step == null:
		return
	
	current_step = step
	current_step.state = StepState.IN_PROGRESS
	current_section = step.section
	step_timer = 0.0
	
	# Enable practice area if needed
	if step.practice_area_enabled and practice_area != null:
		practice_area.visible = true
	
	# Show visual aids
	_show_visual_aids(step.visual_aids)
	
	# Play demonstration animation
	if step.demonstration_animation != "" and animation_player != null:
		_play_demonstration(step.demonstration_animation)
	
	tutorial_step_started.emit(step)
	print("Tutorial: Started step '%s'" % step.title)


func complete_step(step: TutorialStep) -> void:
	"""Complete a tutorial step and move to the next.
	Requirements: 36.5 - Unlock next section and save progress
	"""
	if step == null:
		return
	
	step.state = StepState.COMPLETED
	completed_steps.append(step)
	
	# Hide visual aids
	_hide_visual_aids(step.visual_aids)
	
	# Hide practice area
	if practice_area != null:
		practice_area.visible = false
	
	tutorial_step_completed.emit(step)
	print("Tutorial: Completed step '%s'" % step.title)
	
	# Save progress
	_save_tutorial_progress()
	
	# Move to next step
	var next_step := _get_next_step(step)
	if next_step != null:
		# Small delay before starting next step
		await get_tree().create_timer(2.0).timeout
		start_step(next_step)
	else:
		# Tutorial complete
		complete_tutorial()


func complete_tutorial() -> void:
	"""Complete the entire tutorial sequence."""
	current_section = TutorialSection.COMPLETED
	current_step = null
	first_time_player = false
	
	tutorial_completed.emit()
	_save_tutorial_progress()
	
	print("Tutorial: Tutorial sequence completed!")


func skip_tutorial() -> void:
	"""Skip the tutorial entirely."""
	tutorial_enabled = false
	first_time_player = false
	current_section = TutorialSection.COMPLETED
	
	tutorial_skipped.emit()
	_save_tutorial_progress()
	
	print("Tutorial: Tutorial skipped")


func skip_current_step() -> void:
	"""Skip the current tutorial step."""
	if current_step == null:
		return
	
	current_step.state = StepState.SKIPPED
	
	var next_step := _get_next_step(current_step)
	if next_step != null:
		start_step(next_step)
	else:
		complete_tutorial()


func _get_next_step(current: TutorialStep) -> TutorialStep:
	"""Get the next tutorial step after the current one."""
	var current_index := tutorial_steps.find(current)
	if current_index == -1 or current_index >= tutorial_steps.size() - 1:
		return null
	
	return tutorial_steps[current_index + 1]


## Completion Checking

func _check_step_completion() -> void:
	"""Check if the current step's completion condition is met."""
	if current_step == null or current_step.completion_condition == null:
		return
	
	if current_step.completion_condition.call():
		complete_step(current_step)


func _check_control_interaction() -> bool:
	"""Check if player has interacted with controls."""
	# This will be connected to actual control system
	return step_timer > 5.0  ## Placeholder: complete after 5 seconds


func _check_flight_practice() -> bool:
	"""Check if player has practiced basic flight."""
	var player := _get_player()
	if player == null:
		return false
	
	# Check if player has maintained velocity for a period
	return step_timer > 10.0  ## Placeholder


func _check_relativistic_practice() -> bool:
	"""Check if player has practiced relativistic flight.
	Requirements: 36.3 - Practice area with visual speed indicators
	"""
	var player := _get_player()
	if player == null:
		return false
	
	# Check if player reached high speed
	return step_timer > 15.0  ## Placeholder


func _check_gravity_practice() -> bool:
	"""Check if player has practiced gravity well navigation.
	Requirements: 36.4 - Trajectory prediction and safe/danger zones
	"""
	var player := _get_player()
	if player == null:
		return false
	
	# Check if player successfully navigated gravity well
	return step_timer > 20.0  ## Placeholder


func _check_signal_understanding() -> bool:
	"""Check if player understands signal management."""
	return step_timer > 10.0  ## Placeholder


func _check_resonance_practice() -> bool:
	"""Check if player has practiced resonance mechanics."""
	return step_timer > 15.0  ## Placeholder


func _check_navigation_understanding() -> bool:
	"""Check if player understands navigation tools."""
	return step_timer > 10.0  ## Placeholder


## Visual Aids

func _show_visual_aids(aid_names: Array[String]) -> void:
	"""Show specified visual aids."""
	for aid_name in aid_names:
		if visual_aids.has(aid_name):
			var aid := visual_aids[aid_name] as Node3D
			if aid != null:
				aid.visible = true


func _hide_visual_aids(aid_names: Array[String]) -> void:
	"""Hide specified visual aids."""
	for aid_name in aid_names:
		if visual_aids.has(aid_name):
			var aid := visual_aids[aid_name] as Node3D
			if aid != null:
				aid.visible = false


func _update_visual_aids() -> void:
	"""Update visual aid displays based on current state."""
	if current_step == null:
		return
	
	# Update speed indicator
	if "speed_indicator" in current_step.visual_aids and speed_indicator != null:
		var player := _get_player()
		if player != null and player.has_method("get_velocity"):
			var velocity: Vector3 = player.get_velocity()
			var speed := velocity.length()
			speed_indicator.text = "Speed: %.1f km/s" % (speed / 1000.0)
			
			# Color code based on speed
			var c := 299792.458  ## Speed of light in km/s
			var percent_c := (speed / 1000.0) / c
			if percent_c < 0.1:
				speed_indicator.modulate = Color.GREEN
			elif percent_c < 0.5:
				speed_indicator.modulate = Color.YELLOW
			else:
				speed_indicator.modulate = Color.RED


## Demonstrations

func _play_demonstration(demo_name: String) -> void:
	"""Play a visual demonstration animation.
	Requirements: 36.4 - Show visual demonstrations using AnimationPlayer
	"""
	if animation_player == null:
		return
	
	if animation_player.has_animation(demo_name):
		animation_player.play(demo_name)
		demonstration_shown.emit(demo_name)
		print("Tutorial: Playing demonstration '%s'" % demo_name)
	else:
		print("Tutorial: Warning - demonstration '%s' not found" % demo_name)


## HUD Updates

func _update_hud() -> void:
	"""Update tutorial HUD with current information."""
	if current_step == null:
		return
	
	# This will be expanded when HUD system is integrated
	# For now, we just track the state


func get_current_instruction_text() -> String:
	"""Get formatted instruction text for display."""
	if current_step == null:
		return ""
	
	var text := "%s\n\n" % current_step.title
	text += "%s\n\n" % current_step.description
	
	for i in range(current_step.instructions.size()):
		text += "%d. %s\n" % [i + 1, current_step.instructions[i]]
	
	return text


func get_progress_text() -> String:
	"""Get tutorial progress text."""
	var completed := completed_steps.size()
	var total := tutorial_steps.size()
	return "Progress: %d / %d" % [completed, total]


func get_progress_percentage() -> float:
	"""Get tutorial completion percentage (0.0 to 1.0)."""
	if tutorial_steps.size() == 0:
		return 1.0
	return float(completed_steps.size()) / float(tutorial_steps.size())


## Save/Load Progress

func _save_tutorial_progress() -> void:
	"""Save tutorial progress to disk.
	Requirements: 36.5 - Save progress when section is completed
	"""
	config.set_value("tutorial", "enabled", tutorial_enabled)
	config.set_value("tutorial", "first_time_player", first_time_player)
	config.set_value("tutorial", "current_section", current_section)
	
	# Save completed steps
	var completed_indices: Array[int] = []
	for step in completed_steps:
		var index := tutorial_steps.find(step)
		if index != -1:
			completed_indices.append(index)
	
	config.set_value("tutorial", "completed_steps", completed_indices)
	
	var err := config.save(save_file_path)
	if err != OK:
		push_error("Tutorial: Failed to save progress: %d" % err)
	else:
		print("Tutorial: Progress saved")


func _load_tutorial_progress() -> void:
	"""Load tutorial progress from disk.
	Requirements: 36.5 - Load saved progress
	"""
	var err := config.load(save_file_path)
	if err != OK:
		# No save file exists, this is a first-time player
		first_time_player = true
		tutorial_enabled = true
		print("Tutorial: No save file found, starting fresh")
		return
	
	tutorial_enabled = config.get_value("tutorial", "enabled", true)
	first_time_player = config.get_value("tutorial", "first_time_player", true)
	current_section = config.get_value("tutorial", "current_section", TutorialSection.BASIC_CONTROLS)
	
	# Load completed steps
	var completed_indices: Array = config.get_value("tutorial", "completed_steps", [])
	completed_steps.clear()
	
	for index in completed_indices:
		if index >= 0 and index < tutorial_steps.size():
			var step := tutorial_steps[index]
			step.state = StepState.COMPLETED
			completed_steps.append(step)
	
	print("Tutorial: Progress loaded - %d steps completed" % completed_steps.size())


func reset_tutorial_progress() -> void:
	"""Reset tutorial progress to start from beginning."""
	first_time_player = true
	tutorial_enabled = true
	current_section = TutorialSection.BASIC_CONTROLS
	current_step = null
	completed_steps.clear()
	
	for step in tutorial_steps:
		step.state = StepState.NOT_STARTED
	
	_save_tutorial_progress()
	print("Tutorial: Progress reset")


## Helper Methods

func _get_player() -> Node:
	"""Get the player node from the scene tree."""
	return get_tree().get_first_node_in_group("player")


func is_tutorial_active() -> bool:
	"""Check if tutorial is currently active."""
	return current_step != null and current_step.state == StepState.IN_PROGRESS


func is_tutorial_completed() -> bool:
	"""Check if tutorial has been completed."""
	return current_section == TutorialSection.COMPLETED


func get_current_step() -> TutorialStep:
	"""Get the current tutorial step."""
	return current_step


func get_current_section() -> TutorialSection:
	"""Get the current tutorial section."""
	return current_section


func enable_tutorial() -> void:
	"""Enable the tutorial system."""
	tutorial_enabled = true
	_save_tutorial_progress()


func disable_tutorial() -> void:
	"""Disable the tutorial system."""
	tutorial_enabled = false
	_save_tutorial_progress()


## Serialization

func serialize() -> Dictionary:
	"""Serialize tutorial state for saving."""
	var completed_indices: Array[int] = []
	for step in completed_steps:
		var index := tutorial_steps.find(step)
		if index != -1:
			completed_indices.append(index)
	
	return {
		"tutorial_enabled": tutorial_enabled,
		"first_time_player": first_time_player,
		"current_section": current_section,
		"completed_steps": completed_indices
	}


func deserialize(data: Dictionary) -> void:
	"""Deserialize tutorial state from save data."""
	if data.has("tutorial_enabled"):
		tutorial_enabled = data["tutorial_enabled"]
	
	if data.has("first_time_player"):
		first_time_player = data["first_time_player"]
	
	if data.has("current_section"):
		current_section = data["current_section"]
	
	if data.has("completed_steps"):
		completed_steps.clear()
		for index in data["completed_steps"]:
			if index >= 0 and index < tutorial_steps.size():
				var step := tutorial_steps[index]
				step.state = StepState.COMPLETED
				completed_steps.append(step)
