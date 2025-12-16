extends Control
class_name MoonHUD
## HUD for moon landing experience with visual feedback
## Shows objectives, status, and landing instructions with color coding

## UI Labels
@onready var status_label: Label = $StatusLabel
@onready var altitude_label: Label = $AltitudeLabel
@onready var velocity_label: Label = $VelocityLabel
@onready var objectives_label: Label = $ObjectivesLabel
@onready var landing_prompt: Label = $LandingPrompt

## References
var landing_detector: LandingDetector = null
var walking_controller: WalkingController = null
var vr_manager: VRManager = null
var is_vr_mode: bool = false

## Objectives tracking
var objectives: Dictionary = {
	"land_on_moon": {"completed": false, "text": "Land on the Moon"},
	"exit_spacecraft": {"completed": false, "text": "Exit Spacecraft and Walk on Moon"},
	"jump_10_times": {"completed": false, "text": "Jump 10 times on Moon", "count": 0, "target": 10},
	"explore_100m": {"completed": false, "text": "Explore 100m from landing site", "distance": 0.0, "target": 100.0}
}

var landing_position: Vector3 = Vector3.ZERO
var jump_count: int = 0
var was_on_ground: bool = false

## Animation state
var altitude_warning_flash: float = 0.0
var objective_completion_animations: Dictionary = {}


func _ready() -> void:
	# Hide landing prompt initially
	if landing_prompt:
		landing_prompt.visible = false

	# Get VR manager
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("get_vr_manager"):
		vr_manager = engine.get_vr_manager()
		if vr_manager:
			is_vr_mode = vr_manager.is_vr_active()

	update_objectives_display()


func _process(delta: float) -> void:
	update_status_display(delta)
	check_objectives()
	update_animations(delta)


## Initialize HUD with references
func initialize(detector: LandingDetector, walker: WalkingController = null) -> void:
	landing_detector = detector
	walking_controller = walker

	# Connect signals
	if landing_detector:
		if not landing_detector.landing_detected.is_connected(_on_landing_detected):
			landing_detector.landing_detected.connect(_on_landing_detected)
		if not landing_detector.walking_mode_requested.is_connected(_on_walking_mode_started):
			landing_detector.walking_mode_requested.connect(_on_walking_mode_started)

	if walking_controller:
		walking_controller.walking_started.connect(_on_walking_started)


## Update status display with visual feedback
func update_status_display(delta: float) -> void:
	if not landing_detector:
		return

	var status = landing_detector.get_landing_status()

	# Update altitude with color coding
	if altitude_label:
		var altitude = status.altitude
		if altitude < 1000:
			altitude_label.text = "Altitude: %.1f m" % altitude

			# Color code altitude based on danger level
			if altitude < 20:
				# Very close - flash warning if descending fast
				if status.speed > 3.0:
					altitude_warning_flash += delta * 10.0
					var flash_alpha = (sin(altitude_warning_flash) + 1.0) / 2.0
					altitude_label.modulate = Color.RED.lerp(Color.WHITE, flash_alpha)
				else:
					altitude_label.modulate = Color.YELLOW
			elif altitude < 50:
				altitude_label.modulate = Color.YELLOW
			elif altitude < 100:
				altitude_label.modulate = Color(1.0, 0.8, 0.4)  # Orange
			else:
				altitude_label.modulate = Color.WHITE
		else:
			altitude_label.text = "Altitude: High"
			altitude_label.modulate = Color.WHITE

	# Update velocity with color coding
	if velocity_label:
		var speed = status.speed
		velocity_label.text = "Speed: %.1f m/s" % speed

		# Color code based on safe landing speed
		if status.altitude < 50:  # Only show warning when close to surface
			if speed > 5.0:
				velocity_label.modulate = Color.RED  # Too fast!
			elif speed > 3.0:
				velocity_label.modulate = Color.ORANGE  # Caution
			else:
				velocity_label.modulate = Color.GREEN  # Safe landing speed
		else:
			velocity_label.modulate = Color.WHITE

	# Update status
	if status_label:
		if status.is_landed:
			status_label.text = "Status: LANDED"
			status_label.modulate = Color.GREEN
		elif status.altitude < 100:
			status_label.text = "Status: APPROACHING SURFACE"
			status_label.modulate = Color.YELLOW
		else:
			status_label.text = "Status: IN FLIGHT"
			status_label.modulate = Color.WHITE

	# Show landing prompt if can exit
	if landing_prompt:
		landing_prompt.visible = status.can_exit and not objectives["exit_spacecraft"].completed
		if landing_prompt.visible:
			# Show different prompt for VR vs desktop
			if is_vr_mode:
				landing_prompt.text = "Press [A/X Button] to Exit Spacecraft"
			else:
				landing_prompt.text = "Press [SPACE] to Exit Spacecraft"


## Check and update objectives
func check_objectives() -> void:
	# Check if walking mode is active
	if walking_controller and walking_controller.is_walking_active():
		# Track jumps
		var is_on_ground = walking_controller.is_on_floor()
		if not was_on_ground and is_on_ground:
			# Just landed from a jump
			jump_count += 1
			objectives["jump_10_times"]["count"] = jump_count
			if jump_count >= 10 and not objectives["jump_10_times"].completed:
				objectives["jump_10_times"].completed = true
				print("[MoonHUD] Objective completed: Jump 10 times!")

				# Trigger completion animation
				objective_completion_animations["jump_10_times"] = 1.0

				update_objectives_display()
			else:
				# Update progress display
				update_objectives_display()
		was_on_ground = is_on_ground

		# Track distance from landing site
		if landing_position != Vector3.ZERO:
			var distance = walking_controller.global_position.distance_to(landing_position)
			objectives["explore_100m"]["distance"] = distance
			if distance >= 100.0 and not objectives["explore_100m"].completed:
				objectives["explore_100m"].completed = true
				print("[MoonHUD] Objective completed: Explored 100m!")

				# Trigger completion animation
				objective_completion_animations["explore_100m"] = 1.0

				update_objectives_display()


## Update objectives display with animations
func update_objectives_display() -> void:
	if not objectives_label:
		return

	var text = "OBJECTIVES:\n"

	for key in objectives:
		var obj = objectives[key]
		var status_icon = "[X]" if obj.completed else "[ ]"
		var obj_text = obj.text

		# Add progress for counting objectives
		if obj.has("count") and obj.has("target"):
			obj_text += " (%d/%d)" % [obj.count, obj.target]
		elif obj.has("distance") and obj.has("target"):
			obj_text += " (%.1f/%.1f m)" % [obj.distance, obj.target]

		text += "%s %s\n" % [status_icon, obj_text]

	objectives_label.text = text


## Update UI animations
func update_animations(delta: float) -> void:
	# Animate recently completed objectives with green flash
	for key in objective_completion_animations.keys():
		objective_completion_animations[key] -= delta
		if objective_completion_animations[key] <= 0:
			objective_completion_animations.erase(key)

	# Apply green tint to objectives label if any objectives just completed
	if objective_completion_animations.size() > 0:
		var flash_intensity = 0.0
		for time_remaining in objective_completion_animations.values():
			flash_intensity = max(flash_intensity, time_remaining)
		var green_tint = Color.WHITE.lerp(Color.GREEN, flash_intensity)
		objectives_label.modulate = green_tint
	else:
		objectives_label.modulate = Color.WHITE


## Signal handlers

func _on_landing_detected(spacecraft: Node3D, planet: CelestialBody) -> void:
	objectives["land_on_moon"].completed = true
	print("[MoonHUD] Objective completed: Land on the Moon!")

	# Trigger completion animation
	objective_completion_animations["land_on_moon"] = 1.0

	update_objectives_display()

	# Record landing position
	if spacecraft:
		landing_position = spacecraft.global_position


func _on_walking_mode_started() -> void:
	objectives["exit_spacecraft"].completed = true
	print("[MoonHUD] Objective completed: Exit spacecraft!")

	# Trigger completion animation
	objective_completion_animations["exit_spacecraft"] = 1.0

	update_objectives_display()


func _on_walking_started() -> void:
	# Hide landing prompt when walking starts
	if landing_prompt:
		landing_prompt.visible = false
