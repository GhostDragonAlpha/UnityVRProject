extends Node
class_name MoonTutorialManager
## Tutorial manager specifically for moon landing experience
## Guides players through landing, exiting, and exploring the moon
##
## Integrates with existing Tutorial system and MissionSystem

signal tutorial_step_completed(step_name: String)
signal tutorial_sequence_completed
signal tutorial_skipped

## Tutorial steps enum
enum TutorialStep {
	WELCOME,           # Welcome message
	THRUST_FORWARD,    # W key for forward thrust
	ALTITUDE_CONTROL,  # SPACE key for upward thrust
	SPEED_CONTROL,     # Watch speed for landing
	GENTLE_LANDING,    # Touch down gently
	EXIT_SPACECRAFT,   # Press SPACE to exit
	FIRST_JUMP,        # Jump on the moon
	COMPLETED          # Tutorial done
}

## Current tutorial state
var current_step: TutorialStep = TutorialStep.WELCOME
var tutorial_active: bool = true
var tutorial_completed: bool = false
var skip_tutorial: bool = false

## Step completion tracking
var steps_completed: Dictionary = {}
var step_start_time: float = 0.0

## Tutorial messages for each step
const TUTORIAL_MESSAGES: Dictionary = {
	TutorialStep.WELCOME: {
		"title": "Welcome to Lunar Descent!",
		"instruction": "You're approaching the Moon. Let's learn the controls for landing.",
		"hint": "This tutorial can be skipped at any time by pressing ESC",
		"duration": 5.0
	},
	TutorialStep.THRUST_FORWARD: {
		"title": "Forward Thrust",
		"instruction": "Press [W] to thrust forward and control your horizontal movement.",
		"hint": "Small adjustments work best. Don't over-correct!",
		"completion": "forward_thrust_used"
	},
	TutorialStep.ALTITUDE_CONTROL: {
		"title": "Altitude Control",
		"instruction": "Press [SPACE] to thrust upward and control your descent rate.",
		"hint": "Balance your descent - too fast and you'll crash!",
		"completion": "upward_thrust_used"
	},
	TutorialStep.SPEED_CONTROL: {
		"title": "Landing Speed",
		"instruction": "Keep your speed below 5 m/s for a safe landing.",
		"hint": "Watch the speed indicator on your HUD. Green = safe, Red = dangerous!",
		"completion": "maintained_safe_speed"
	},
	TutorialStep.GENTLE_LANDING: {
		"title": "Touch Down",
		"instruction": "Gently touch down on the Moon surface.",
		"hint": "The landing detector will turn green when you're close enough and slow enough.",
		"completion": "landed_successfully"
	},
	TutorialStep.EXIT_SPACECRAFT: {
		"title": "Exit Spacecraft",
		"instruction": "Press [SPACE] to exit your spacecraft and walk on the Moon!",
		"hint": "You'll experience low lunar gravity - just 1/6th of Earth's!",
		"completion": "walking_mode_active"
	},
	TutorialStep.FIRST_JUMP: {
		"title": "Lunar Jump",
		"instruction": "Press [SPACE] to jump and experience lunar gravity!",
		"hint": "In low gravity, you can jump much higher than on Earth.",
		"completion": "first_jump_made"
	}
}

## References to scene systems
var landing_detector: LandingDetector = null
var spacecraft: Spacecraft = null
var moon_hud: MoonHUD = null
var transition_system: TransitionSystem = null
var tutorial_ui: Control = null

## Tracking variables
var forward_thrust_used: bool = false
var upward_thrust_used: bool = false
var maintained_safe_speed: bool = false
var safe_speed_timer: float = 0.0
const SAFE_SPEED_DURATION: float = 2.0  # Maintain safe speed for 2 seconds

var landed_successfully: bool = false
var walking_mode_active: bool = false
var first_jump_made: bool = false
var was_on_ground: bool = false


func _ready() -> void:
	# Load tutorial completion state
	_load_tutorial_state()

	# Don't start until initialized
	set_process(false)


## Initialize tutorial system with scene references
func initialize(detector: LandingDetector, craft: Spacecraft, hud: MoonHUD,
				trans_sys: TransitionSystem = null, ui: Control = null) -> void:
	landing_detector = detector
	spacecraft = craft
	moon_hud = hud
	transition_system = trans_sys
	tutorial_ui = ui

	# Connect signals
	if landing_detector:
		landing_detector.landing_detected.connect(_on_landing_detected)
		landing_detector.walking_mode_requested.connect(_on_walking_mode_requested)

	# Check if tutorial was already completed
	if tutorial_completed:
		tutorial_active = false
		set_process(false)
		return

	# Start tutorial
	if tutorial_active and not skip_tutorial:
		start_tutorial()

	set_process(true)


func _process(delta: float) -> void:
	if not tutorial_active or tutorial_completed:
		return

	# Update step progress
	_update_current_step(delta)

	# Check for skip input
	if Input.is_action_just_pressed("ui_cancel"):
		_skip_tutorial()


## Start the tutorial sequence
func start_tutorial() -> void:
	print("[MoonTutorialManager] Starting tutorial")
	current_step = TutorialStep.WELCOME
	tutorial_active = true
	step_start_time = Time.get_ticks_msec() / 1000.0

	_show_tutorial_message(current_step)


## Update current tutorial step
func _update_current_step(delta: float) -> void:
	match current_step:
		TutorialStep.WELCOME:
			_check_welcome_step()

		TutorialStep.THRUST_FORWARD:
			_check_thrust_forward_step(delta)

		TutorialStep.ALTITUDE_CONTROL:
			_check_altitude_control_step(delta)

		TutorialStep.SPEED_CONTROL:
			_check_speed_control_step(delta)

		TutorialStep.GENTLE_LANDING:
			_check_gentle_landing_step()

		TutorialStep.EXIT_SPACECRAFT:
			_check_exit_spacecraft_step()

		TutorialStep.FIRST_JUMP:
			_check_first_jump_step()


## Step completion checks

func _check_welcome_step() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - step_start_time
	var duration = TUTORIAL_MESSAGES[TutorialStep.WELCOME]["duration"]

	if elapsed >= duration:
		_complete_step(TutorialStep.WELCOME)
		_advance_to_step(TutorialStep.THRUST_FORWARD)


func _check_thrust_forward_step(delta: float) -> void:
	if not spacecraft:
		return

	# Check if player is using forward thrust (W key)
	if Input.is_key_pressed(KEY_W):
		forward_thrust_used = true

	# Complete after using forward thrust for a bit
	if forward_thrust_used:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - step_start_time
		if elapsed >= 2.0:  # Used for 2 seconds
			_complete_step(TutorialStep.THRUST_FORWARD)
			_advance_to_step(TutorialStep.ALTITUDE_CONTROL)


func _check_altitude_control_step(delta: float) -> void:
	if not spacecraft:
		return

	# Check if player is using upward thrust (SPACE key)
	if Input.is_key_pressed(KEY_SPACE):
		upward_thrust_used = true

	# Complete after using upward thrust for a bit
	if upward_thrust_used:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - step_start_time
		if elapsed >= 2.0:  # Used for 2 seconds
			_complete_step(TutorialStep.ALTITUDE_CONTROL)
			_advance_to_step(TutorialStep.SPEED_CONTROL)


func _check_speed_control_step(delta: float) -> void:
	if not landing_detector:
		return

	var speed = landing_detector.get_speed()

	# Check if maintaining safe speed (< 5 m/s)
	if speed < 5.0:
		safe_speed_timer += delta

		if safe_speed_timer >= SAFE_SPEED_DURATION:
			maintained_safe_speed = true
			_complete_step(TutorialStep.SPEED_CONTROL)
			_advance_to_step(TutorialStep.GENTLE_LANDING)
	else:
		safe_speed_timer = 0.0


func _check_gentle_landing_step() -> void:
	# This is completed by signal from landing detector
	pass


func _check_exit_spacecraft_step() -> void:
	# This is completed by signal when walking mode is requested
	pass


func _check_first_jump_step() -> void:
	if not transition_system:
		return

	# Get walking controller
	var walking_controller = transition_system.get_walking_controller()
	if not walking_controller:
		return

	# Detect jump (when player leaves ground)
	var is_on_ground = walking_controller.is_on_floor()

	if was_on_ground and not is_on_ground:
		# Just jumped!
		first_jump_made = true
		_complete_step(TutorialStep.FIRST_JUMP)
		_complete_tutorial()

	was_on_ground = is_on_ground


## Step completion and advancement

func _complete_step(step: TutorialStep) -> void:
	steps_completed[step] = true
	print("[MoonTutorialManager] Completed step: ", _get_step_name(step))
	tutorial_step_completed.emit(_get_step_name(step))
	_save_tutorial_state()


func _advance_to_step(next_step: TutorialStep) -> void:
	current_step = next_step
	step_start_time = Time.get_ticks_msec() / 1000.0
	_show_tutorial_message(current_step)


func _complete_tutorial() -> void:
	print("[MoonTutorialManager] Tutorial sequence completed!")
	tutorial_completed = true
	tutorial_active = false
	current_step = TutorialStep.COMPLETED
	tutorial_sequence_completed.emit()
	_save_tutorial_state()

	# Hide tutorial UI
	if tutorial_ui:
		tutorial_ui.visible = false


func _skip_tutorial() -> void:
	print("[MoonTutorialManager] Tutorial skipped")
	skip_tutorial = true
	tutorial_completed = true
	tutorial_active = false
	tutorial_skipped.emit()
	_save_tutorial_state()

	# Hide tutorial UI
	if tutorial_ui:
		tutorial_ui.visible = false


## Signal handlers

func _on_landing_detected(craft: Node3D, planet: CelestialBody) -> void:
	if current_step == TutorialStep.GENTLE_LANDING:
		landed_successfully = true
		_complete_step(TutorialStep.GENTLE_LANDING)
		_advance_to_step(TutorialStep.EXIT_SPACECRAFT)


func _on_walking_mode_requested() -> void:
	if current_step == TutorialStep.EXIT_SPACECRAFT:
		walking_mode_active = true
		_complete_step(TutorialStep.EXIT_SPACECRAFT)
		_advance_to_step(TutorialStep.FIRST_JUMP)


## Tutorial message display

func _show_tutorial_message(step: TutorialStep) -> void:
	if not tutorial_ui:
		print("[MoonTutorialManager] Tutorial UI not set - printing to console")
		var msg = TUTORIAL_MESSAGES[step]
		print("  TUTORIAL: ", msg["title"])
		print("  ", msg["instruction"])
		if msg.has("hint"):
			print("  HINT: ", msg["hint"])
		return

	# Update tutorial UI with step info
	var msg = TUTORIAL_MESSAGES[step]
	tutorial_ui.show_tutorial_step(msg["title"], msg["instruction"],
									msg.get("hint", ""))


## Save/Load tutorial state

func _save_tutorial_state() -> void:
	var config = ConfigFile.new()
	config.set_value("moon_tutorial", "completed", tutorial_completed)
	config.set_value("moon_tutorial", "skip", skip_tutorial)
	config.set_value("moon_tutorial", "steps_completed", steps_completed)

	var err = config.save("user://moon_tutorial_progress.cfg")
	if err != OK:
		push_error("[MoonTutorialManager] Failed to save tutorial state")


func _load_tutorial_state() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://moon_tutorial_progress.cfg")

	if err != OK:
		# No save file - first time
		tutorial_completed = false
		skip_tutorial = false
		return

	tutorial_completed = config.get_value("moon_tutorial", "completed", false)
	skip_tutorial = config.get_value("moon_tutorial", "skip", false)
	steps_completed = config.get_value("moon_tutorial", "steps_completed", {})


## Utility methods

func _get_step_name(step: TutorialStep) -> String:
	match step:
		TutorialStep.WELCOME: return "welcome"
		TutorialStep.THRUST_FORWARD: return "thrust_forward"
		TutorialStep.ALTITUDE_CONTROL: return "altitude_control"
		TutorialStep.SPEED_CONTROL: return "speed_control"
		TutorialStep.GENTLE_LANDING: return "gentle_landing"
		TutorialStep.EXIT_SPACECRAFT: return "exit_spacecraft"
		TutorialStep.FIRST_JUMP: return "first_jump"
		TutorialStep.COMPLETED: return "completed"
		_: return "unknown"


func get_current_step_name() -> String:
	return _get_step_name(current_step)


func is_tutorial_active() -> bool:
	return tutorial_active and not tutorial_completed


func get_progress() -> float:
	if tutorial_completed:
		return 1.0

	var total_steps = TutorialStep.COMPLETED
	return float(steps_completed.size()) / float(total_steps)


func reset_tutorial() -> void:
	tutorial_completed = false
	skip_tutorial = false
	tutorial_active = true
	current_step = TutorialStep.WELCOME
	steps_completed.clear()

	# Reset tracking vars
	forward_thrust_used = false
	upward_thrust_used = false
	maintained_safe_speed = false
	safe_speed_timer = 0.0
	landed_successfully = false
	walking_mode_active = false
	first_jump_made = false
	was_on_ground = false

	_save_tutorial_state()

	if tutorial_ui:
		tutorial_ui.visible = true

	start_tutorial()
