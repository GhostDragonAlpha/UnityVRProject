## MissionSystem - Mission Objectives and Goals Management
## Manages mission objectives, tracks completion, and provides feedback.
##
## Requirements: 37.1, 37.2, 37.3, 37.4, 37.5
## - 37.1: Present primary objective when game starts
## - 37.2: Display objectives in 3D HUD panel within cockpit
## - 37.3: Provide visual and audio feedback on objective completion
## - 37.4: Notify player with non-intrusive indicator for new objectives
## - 37.5: Display navigation marker pointing toward current objective
extends Node
class_name MissionSystem

## Emitted when a new mission is started
signal mission_started(mission: MissionData)
## Emitted when a mission is completed
signal mission_completed(mission: MissionData)
## Emitted when an objective is completed
signal objective_completed(objective: ObjectiveData)
## Emitted when a new objective becomes available
signal new_objective_available(objective: ObjectiveData)
## Emitted when the active objective changes
signal active_objective_changed(objective: ObjectiveData)

## Mission states
enum MissionState {
	NOT_STARTED,
	IN_PROGRESS,
	COMPLETED,
	FAILED
}

## Objective types
enum ObjectiveType {
	REACH_LOCATION,    ## Navigate to a specific location
	COLLECT_ITEM,      ## Collect a specific item or resource
	SCAN_OBJECT,       ## Scan a celestial body or object
	SURVIVE_TIME,      ## Survive for a duration
	DESTROY_TARGET,    ## Destroy a target using resonance
	DISCOVER_SYSTEM,   ## Discover a new star system
	RESONANCE_SCAN,    ## Scan objects with specific frequency ranges
	RESONANCE_CANCEL,  ## Cancel objects using destructive interference
	RESONANCE_AMPLIFY, ## Amplify objects to target amplitude
	RESONANCE_MATCH,   ## Match frequencies within time limits
	RESONANCE_CHAIN,   ## Chain resonance effects across multiple objects
	CUSTOM             ## Custom objective with callback
}

## Current active mission
var current_mission: MissionData = null
## All available missions
var available_missions: Array[MissionData] = []
## Completed missions
var completed_missions: Array[MissionData] = []
## Navigation marker node
var navigation_marker: Marker3D = null
## HUD display node (SubViewport)
var hud_viewport: SubViewport = null
## HUD container for 3D display
var hud_container: Node3D = null
## Audio player for feedback
var audio_player: AudioStreamPlayer = null

## Configuration
var show_navigation_marker: bool = true
var marker_update_interval: float = 0.1  ## Seconds between marker updates
var _marker_update_timer: float = 0.0

## Objective completion sounds (paths to audio files)
var completion_sound_path: String = "res://data/audio/objective_complete.wav"
var new_objective_sound_path: String = "res://data/audio/new_objective.wav"
var mission_complete_sound_path: String = "res://data/audio/mission_complete.wav"


func _ready() -> void:
	_setup_audio_player()
	_setup_navigation_marker()


func _process(delta: float) -> void:
	_update_navigation_marker(delta)
	_check_objective_completion()


## Setup Methods

func _setup_audio_player() -> void:
	"""Set up the audio player for feedback sounds."""
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "MissionAudioPlayer"
	audio_player.bus = "SFX"  ## Use SFX bus if available
	add_child(audio_player)


func _setup_navigation_marker() -> void:
	"""Set up the navigation marker for objective tracking."""
	navigation_marker = Marker3D.new()
	navigation_marker.name = "ObjectiveNavigationMarker"
	navigation_marker.visible = false
	add_child(navigation_marker)


## Mission Management

func start_mission(mission: MissionData) -> bool:
	"""Start a new mission.
	Requirements: 37.1 - Present primary objective when game starts
	"""
	if mission == null:
		push_error("MissionSystem: Cannot start null mission")
		return false
	
	if current_mission != null and current_mission.state == MissionState.IN_PROGRESS:
		push_warning("MissionSystem: Abandoning current mission to start new one")
	
	current_mission = mission
	current_mission.state = MissionState.IN_PROGRESS
	current_mission.start_time = Time.get_unix_time_from_system()
	
	# Set first objective as active
	if current_mission.objectives.size() > 0:
		set_active_objective(current_mission.objectives[0])
	
	mission_started.emit(current_mission)
	_play_sound(new_objective_sound_path)
	
	print("MissionSystem: Started mission '%s'" % mission.title)
	return true


func complete_mission() -> void:
	"""Complete the current mission.
	Requirements: 37.3 - Provide visual and audio feedback on completion
	"""
	if current_mission == null:
		return
	
	current_mission.state = MissionState.COMPLETED
	current_mission.completion_time = Time.get_unix_time_from_system()
	completed_missions.append(current_mission)
	
	mission_completed.emit(current_mission)
	_play_sound(mission_complete_sound_path)
	_show_completion_feedback()
	
	print("MissionSystem: Completed mission '%s'" % current_mission.title)
	current_mission = null
	_hide_navigation_marker()


func fail_mission(reason: String = "") -> void:
	"""Fail the current mission."""
	if current_mission == null:
		return
	
	current_mission.state = MissionState.FAILED
	current_mission.failure_reason = reason
	
	print("MissionSystem: Failed mission '%s' - %s" % [current_mission.title, reason])
	current_mission = null
	_hide_navigation_marker()


func add_available_mission(mission: MissionData) -> void:
	"""Add a mission to the available missions list.
	Requirements: 37.4 - Notify player with non-intrusive indicator
	"""
	if mission not in available_missions:
		available_missions.append(mission)
		new_objective_available.emit(mission.objectives[0] if mission.objectives.size() > 0 else null)
		_play_sound(new_objective_sound_path)


## Objective Management

func set_active_objective(objective: ObjectiveData) -> void:
	"""Set the currently active objective."""
	if current_mission == null:
		return
	
	current_mission.active_objective = objective
	active_objective_changed.emit(objective)
	
	# Update navigation marker
	if objective != null and objective.target_position != Vector3.ZERO:
		_update_marker_position(objective.target_position)
		_show_navigation_marker()
	else:
		_hide_navigation_marker()


func complete_objective(objective: ObjectiveData) -> void:
	"""Mark an objective as completed.
	Requirements: 37.3 - Provide visual and audio feedback
	"""
	if objective == null or current_mission == null:
		return
	
	objective.is_completed = true
	objective.completion_time = Time.get_unix_time_from_system()
	
	objective_completed.emit(objective)
	_play_sound(completion_sound_path)
	_show_objective_completion_feedback(objective)
	
	print("MissionSystem: Completed objective '%s'" % objective.description)
	
	# Check if all objectives are complete
	if _all_objectives_completed():
		complete_mission()
	else:
		# Move to next objective
		_advance_to_next_objective()


func _all_objectives_completed() -> bool:
	"""Check if all mission objectives are completed."""
	if current_mission == null:
		return false
	
	for objective in current_mission.objectives:
		if not objective.is_completed and not objective.is_optional:
			return false
	return true


func _advance_to_next_objective() -> void:
	"""Advance to the next incomplete objective."""
	if current_mission == null:
		return
	
	for objective in current_mission.objectives:
		if not objective.is_completed:
			set_active_objective(objective)
			return


func _check_objective_completion() -> void:
	"""Check if any objectives have been completed based on their conditions."""
	if current_mission == null or current_mission.active_objective == null:
		return
	
	var objective := current_mission.active_objective
	if objective.is_completed:
		return
	
	# Check completion based on objective type
	match objective.objective_type:
		ObjectiveType.REACH_LOCATION:
			_check_location_objective(objective)
		ObjectiveType.SURVIVE_TIME:
			_check_survival_objective(objective)
		ObjectiveType.RESONANCE_SCAN:
			_check_resonance_scan_objective(objective)
		ObjectiveType.RESONANCE_CANCEL:
			_check_resonance_cancel_objective(objective)
		ObjectiveType.RESONANCE_AMPLIFY:
			_check_resonance_amplify_objective(objective)
		ObjectiveType.RESONANCE_MATCH:
			_check_resonance_match_objective(objective)
		ObjectiveType.RESONANCE_CHAIN:
			_check_resonance_chain_objective(objective)
		# Other types are checked externally via complete_objective()


func _check_location_objective(objective: ObjectiveData) -> void:
	"""Check if player has reached the target location."""
	if objective.target_position == Vector3.ZERO:
		return
	
	# Get player position (will need to be connected to actual player)
	var player_pos := _get_player_position()
	var distance := player_pos.distance_to(objective.target_position)
	
	if distance <= objective.completion_radius:
		complete_objective(objective)


func _check_survival_objective(objective: ObjectiveData) -> void:
	"""Check if survival time has been met."""
	if objective.start_time <= 0:
		objective.start_time = Time.get_unix_time_from_system()
		return
	
	var elapsed := Time.get_unix_time_from_system() - objective.start_time
	if elapsed >= objective.required_duration:
		complete_objective(objective)


## Resonance Objective Checkers

func _check_resonance_scan_objective(objective: ObjectiveData) -> void:
	"""Check if resonance scan objective is complete."""
	if objective.target_frequency_range.size() == 0:
		return
	
	# Check if required number of objects have been scanned in frequency range
	if objective.scanned_objects_in_range >= objective.required_scans:
		complete_objective(objective)


func _check_resonance_cancel_objective(objective: ObjectiveData) -> void:
	"""Check if resonance cancel objective is complete."""
	if objective.cancelled_objects >= objective.required_cancellations:
		complete_objective(objective)


func _check_resonance_amplify_objective(objective: ObjectiveData) -> void:
	"""Check if resonance amplify objective is complete."""
	if objective.amplified_objects >= objective.required_amplifications:
		complete_objective(objective)


func _check_resonance_match_objective(objective: ObjectiveData) -> void:
	"""Check if resonance match objective is complete."""
	if objective.is_completed:
		return
	
	# Check if time limit has expired
	if objective.has_time_limit() and objective.is_time_expired():
		fail_mission("Time limit expired for frequency matching")
		return
	
	# Check if frequency was matched within tolerance
	if objective.frequency_match_achieved:
		complete_objective(objective)


func _check_resonance_chain_objective(objective: ObjectiveData) -> void:
	"""Check if resonance chain objective is complete."""
	if objective.chain_objects_completed >= objective.required_chain_objects:
		complete_objective(objective)


## Navigation Marker

func _update_navigation_marker(delta: float) -> void:
	"""Update navigation marker position and visibility.
	Requirements: 37.5 - Display navigation marker toward current objective
	"""
	if not show_navigation_marker or current_mission == null:
		return
	
	_marker_update_timer += delta
	if _marker_update_timer < marker_update_interval:
		return
	_marker_update_timer = 0.0
	
	var objective := current_mission.active_objective
	if objective == null or objective.target_position == Vector3.ZERO:
		_hide_navigation_marker()
		return
	
	_update_marker_position(objective.target_position)


func _update_marker_position(target_pos: Vector3) -> void:
	"""Update the marker to point toward target position."""
	if navigation_marker == null:
		return
	
	navigation_marker.global_position = target_pos
	navigation_marker.visible = show_navigation_marker


func _show_navigation_marker() -> void:
	"""Show the navigation marker."""
	if navigation_marker != null:
		navigation_marker.visible = true


func _hide_navigation_marker() -> void:
	"""Hide the navigation marker."""
	if navigation_marker != null:
		navigation_marker.visible = false


func toggle_navigation_marker() -> void:
	"""Toggle navigation marker visibility.
	Requirements: 37.5 - Display marker when player requests it
	"""
	show_navigation_marker = not show_navigation_marker
	if navigation_marker != null:
		navigation_marker.visible = show_navigation_marker and current_mission != null


## HUD Display

func setup_hud_display(viewport: SubViewport, container: Node3D) -> void:
	"""Set up the HUD display for showing objectives.
	Requirements: 37.2 - Display objectives in 3D HUD panel
	"""
	hud_viewport = viewport
	hud_container = container
	_update_hud_display()


func _update_hud_display() -> void:
	"""Update the HUD with current objective information."""
	if hud_viewport == null:
		return
	
	# This will be expanded when HUD system is implemented
	# For now, we emit signals that the HUD can listen to


func get_objective_display_text() -> String:
	"""Get formatted text for displaying current objective.
	Requirements: 37.2 - Display objectives in 3D HUD panel
	"""
	if current_mission == null:
		return "No active mission"
	
	var text := "Mission: %s\n" % current_mission.title
	
	if current_mission.active_objective != null:
		var obj := current_mission.active_objective
		text += "Objective: %s\n" % obj.description
		
		if obj.target_position != Vector3.ZERO:
			var distance := _get_player_position().distance_to(obj.target_position)
			text += "Distance: %.1f km" % (distance / 1000.0)
	
	return text


func get_mission_progress() -> float:
	"""Get mission completion progress as a percentage (0.0 to 1.0)."""
	if current_mission == null or current_mission.objectives.size() == 0:
		return 0.0
	
	var completed_count := 0
	var required_count := 0
	
	for objective in current_mission.objectives:
		if not objective.is_optional:
			required_count += 1
			if objective.is_completed:
				completed_count += 1
	
	if required_count == 0:
		return 1.0
	
	return float(completed_count) / float(required_count)


## Audio Feedback

func _play_sound(sound_path: String) -> void:
	"""Play a feedback sound.
	Requirements: 37.3 - Provide audio feedback
	"""
	if audio_player == null:
		return
	
	# Check if file exists
	if not ResourceLoader.exists(sound_path):
		# Use a simple beep as fallback
		_play_fallback_beep()
		return
	
	var stream := load(sound_path) as AudioStream
	if stream != null:
		audio_player.stream = stream
		audio_player.play()


func _play_fallback_beep() -> void:
	"""Play a simple generated beep as fallback audio."""
	# Generate a simple sine wave beep
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	audio_player.stream = generator
	audio_player.play()
	
	# Fill buffer with sine wave
	var playback := audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback != null:
		var phase := 0.0
		var increment := 440.0 / 44100.0  ## 440 Hz
		for i in range(4410):  ## 0.1 seconds
			playback.push_frame(Vector2.ONE * sin(phase * TAU) * 0.3)
			phase = fmod(phase + increment, 1.0)


## Visual Feedback

func _show_completion_feedback() -> void:
	"""Show visual feedback for mission completion.
	Requirements: 37.3 - Provide visual feedback
	"""
	# This will trigger visual effects in the rendering system
	# For now, we just print and emit signals
	print("MissionSystem: [VISUAL FEEDBACK] Mission Complete!")


func _show_objective_completion_feedback(objective: ObjectiveData) -> void:
	"""Show visual feedback for objective completion.
	Requirements: 37.3 - Provide visual feedback
	"""
	print("MissionSystem: [VISUAL FEEDBACK] Objective Complete: %s" % objective.description)


## Helper Methods

func _get_player_position() -> Vector3:
	"""Get the current player position."""
	# Try to get player from the scene tree
	var player := get_tree().get_first_node_in_group("player")
	if player is Node3D:
		return player.global_position
	return Vector3.ZERO


func get_current_mission() -> MissionData:
	"""Get the current active mission."""
	return current_mission


func get_active_objective() -> ObjectiveData:
	"""Get the currently active objective."""
	if current_mission != null:
		return current_mission.active_objective
	return null


func has_active_mission() -> bool:
	"""Check if there is an active mission."""
	return current_mission != null and current_mission.state == MissionState.IN_PROGRESS


func get_distance_to_objective() -> float:
	"""Get distance to current objective target."""
	if current_mission == null or current_mission.active_objective == null:
		return -1.0
	
	var target := current_mission.active_objective.target_position
	if target == Vector3.ZERO:
		return -1.0
	
	return _get_player_position().distance_to(target)


## Serialization for Save/Load

func serialize() -> Dictionary:
	"""Serialize mission state for saving."""
	var data := {
		"current_mission": current_mission.serialize() if current_mission != null else null,
		"completed_missions": [],
		"show_navigation_marker": show_navigation_marker
	}
	
	for mission in completed_missions:
		data["completed_missions"].append(mission.serialize())
	
	return data


func deserialize(data: Dictionary) -> void:
	"""Deserialize mission state from save data."""
	if data.has("current_mission") and data["current_mission"] != null:
		current_mission = MissionData.new()
		current_mission.deserialize(data["current_mission"])
	
	if data.has("completed_missions"):
		completed_missions.clear()
		for mission_data in data["completed_missions"]:
			var mission := MissionData.new()
			mission.deserialize(mission_data)
			completed_missions.append(mission)
	
	if data.has("show_navigation_marker"):
		show_navigation_marker = data["show_navigation_marker"]
