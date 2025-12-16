## MoonAudioManager - Audio System for Moon Landing Experience
##
## Manages all audio for the moon landing gameplay, including:
## - Spacecraft engine and thruster sounds
## - Landing impact and dust settling
## - Moon walking footsteps and jetpack sounds
## - UI feedback sounds
## - Ambient space/cockpit sounds
##
## This manager coordinates with the existing AudioManager and SpatialAudio systems
## to provide immersive audio feedback for the moon landing experience.

extends Node
class_name MoonAudioManager

## Signals
signal audio_event(event_name: String, intensity: float)

## References to audio managers
var audio_manager: AudioManager = null
var spatial_audio: SpatialAudio = null

## References to spacecraft and player
var spacecraft: Spacecraft = null
var walking_controller: WalkingController = null
var landing_detector: LandingDetector = null

## Audio players for spacecraft
var engine_thrust_player: AudioStreamPlayer3D = null
var rcs_thruster_player: AudioStreamPlayer3D = null
var cockpit_ambience_player: AudioStreamPlayer3D = null
var landing_gear_player: AudioStreamPlayer3D = null

## Audio players for landing
var impact_player: AudioStreamPlayer3D = null
var dust_settling_player: AudioStreamPlayer3D = null
var success_chime_player: AudioStreamPlayer = null

## Audio players for walking
var footstep_player: AudioStreamPlayer3D = null
var jetpack_thrust_player: AudioStreamPlayer3D = null
var jetpack_ignition_player: AudioStreamPlayer3D = null
var jetpack_shutdown_player: AudioStreamPlayer3D = null
var landing_thud_player: AudioStreamPlayer3D = null
var breathing_player: AudioStreamPlayer = null

## Audio players for UI
var objective_complete_player: AudioStreamPlayer = null
var warning_beep_player: AudioStreamPlayer = null
var notification_player: AudioStreamPlayer = null

## Audio configuration
@export_group("Engine Audio")
@export var engine_base_pitch: float = 0.6
@export var engine_pitch_range: float = 0.6
@export var engine_base_volume_db: float = -8.0
@export var engine_max_volume_db: float = 0.0

@export_group("Thruster Audio")
@export var thruster_volume_db: float = -6.0
@export var thruster_pitch: float = 1.2

@export_group("Landing Audio")
@export var impact_volume_scale: float = 20.0  # Scale impact by velocity
@export var impact_min_velocity: float = 0.5  # Min velocity to play impact

@export_group("Footstep Audio")
@export var footstep_interval: float = 0.5  # Time between footsteps when walking
@export var footstep_volume_db: float = -12.0
@export var footstep_pitch_variation: float = 0.2

@export_group("Jetpack Audio")
@export var jetpack_base_pitch: float = 0.8
@export var jetpack_pitch_range: float = 0.4
@export var jetpack_base_volume_db: float = -10.0

## State tracking
var is_initialized: bool = false
var is_engine_running: bool = false
var current_throttle: float = 0.0
var footstep_timer: float = 0.0
var last_walking_speed: float = 0.0
var was_on_ground: bool = false

## Audio file paths (to be populated with actual audio files)
const AUDIO_PATHS = {
	# Spacecraft sounds
	"engine_thrust_loop": "res://audio/sfx/spacecraft/engine_thrust_loop.ogg",
	"rcs_thruster_burst": "res://audio/sfx/spacecraft/rcs_thruster_burst.ogg",
	"cockpit_ambience_loop": "res://audio/sfx/spacecraft/cockpit_ambience_loop.ogg",
	"landing_gear_deploy": "res://audio/sfx/spacecraft/landing_gear_deploy.ogg",

	# Landing sounds
	"landing_impact_soft": "res://audio/sfx/landing/landing_impact_soft.ogg",
	"landing_impact_medium": "res://audio/sfx/landing/landing_impact_medium.ogg",
	"landing_impact_hard": "res://audio/sfx/landing/landing_impact_hard.ogg",
	"dust_settling": "res://audio/sfx/landing/dust_settling.ogg",
	"success_chime": "res://audio/sfx/ui/success_chime.ogg",

	# Moon walking sounds
	"footstep_moon_01": "res://audio/sfx/walking/footstep_moon_01.ogg",
	"footstep_moon_02": "res://audio/sfx/walking/footstep_moon_02.ogg",
	"footstep_moon_03": "res://audio/sfx/walking/footstep_moon_03.ogg",
	"jetpack_thrust_loop": "res://audio/sfx/walking/jetpack_thrust_loop.ogg",
	"jetpack_ignition": "res://audio/sfx/walking/jetpack_ignition.ogg",
	"jetpack_shutdown": "res://audio/sfx/walking/jetpack_shutdown.ogg",
	"landing_thud": "res://audio/sfx/walking/landing_thud.ogg",
	"breathing_loop": "res://audio/sfx/walking/breathing_loop.ogg",

	# UI sounds
	"objective_complete": "res://audio/sfx/ui/objective_complete.ogg",
	"warning_beep": "res://audio/sfx/ui/warning_beep.ogg",
	"notification": "res://audio/sfx/ui/notification.ogg",
}

func _ready() -> void:
	# Get references to audio managers
	_get_manager_references()

	# Create audio players
	_create_audio_players()

	print("[MoonAudioManager] Initialized (audio files not yet loaded)")

## Get references to manager nodes
func _get_manager_references() -> void:
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine:
		if engine.has_method("get_audio_manager"):
			audio_manager = engine.get_audio_manager()
		else:
			audio_manager = engine.get_node_or_null("AudioManager")

		if audio_manager and audio_manager.has_method("get_spatial_audio"):
			spatial_audio = audio_manager.get_spatial_audio()

## Create all audio player nodes
func _create_audio_players() -> void:
	# Spacecraft audio players (3D positional)
	engine_thrust_player = _create_3d_player("EngineThrust", true)
	rcs_thruster_player = _create_3d_player("RCSThruster", false)
	cockpit_ambience_player = _create_3d_player("CockpitAmbience", true)
	landing_gear_player = _create_3d_player("LandingGear", false)

	# Landing audio players (3D positional)
	impact_player = _create_3d_player("LandingImpact", false)
	dust_settling_player = _create_3d_player("DustSettling", false)

	# Walking audio players (3D positional)
	footstep_player = _create_3d_player("Footstep", false)
	jetpack_thrust_player = _create_3d_player("JetpackThrust", true)
	jetpack_ignition_player = _create_3d_player("JetpackIgnition", false)
	jetpack_shutdown_player = _create_3d_player("JetpackShutdown", false)
	landing_thud_player = _create_3d_player("LandingThud", false)

	# UI audio players (2D non-positional)
	success_chime_player = _create_2d_player("SuccessChime")
	objective_complete_player = _create_2d_player("ObjectiveComplete")
	warning_beep_player = _create_2d_player("WarningBeep")
	notification_player = _create_2d_player("Notification")
	breathing_player = _create_2d_player("Breathing")
	breathing_player.bus = "Ambient"  # Breathing is ambient, not UI

	print("[MoonAudioManager] Audio players created")

## Create a 3D audio player
func _create_3d_player(node_name: String, looping: bool = false) -> AudioStreamPlayer3D:
	var player = AudioStreamPlayer3D.new()
	player.name = node_name
	player.bus = "SFX"
	player.max_distance = 100.0
	player.unit_size = 5.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	add_child(player)
	return player

## Create a 2D audio player
func _create_2d_player(node_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = node_name
	player.bus = "SFX"
	add_child(player)
	return player

## Initialize with gameplay references
func initialize(craft: Spacecraft, walker: WalkingController = null, detector: LandingDetector = null) -> void:
	spacecraft = craft
	walking_controller = walker
	landing_detector = detector

	# Connect signals
	if spacecraft:
		spacecraft.thrust_applied.connect(_on_thrust_applied)
		spacecraft.velocity_changed.connect(_on_velocity_changed)
		spacecraft.collision_occurred.connect(_on_collision_occurred)

		# Position spacecraft audio at spacecraft location
		_update_spacecraft_audio_positions()

	if landing_detector:
		landing_detector.landing_detected.connect(_on_landing_detected)

	if walking_controller:
		walking_controller.walking_started.connect(_on_walking_started)
		walking_controller.walking_stopped.connect(_on_walking_stopped)

	# Start cockpit ambience
	_start_cockpit_ambience()

	is_initialized = true
	print("[MoonAudioManager] Initialized with gameplay references")

func _process(delta: float) -> void:
	if not is_initialized:
		return

	# Update spacecraft audio
	if spacecraft and is_instance_valid(spacecraft):
		_update_spacecraft_audio(delta)
		_update_spacecraft_audio_positions()

	# Update walking audio
	if walking_controller and walking_controller.is_walking_active():
		_update_walking_audio(delta)
		_update_walking_audio_positions()

## Update spacecraft audio based on current state
func _update_spacecraft_audio(delta: float) -> void:
	# Update engine thrust sound based on throttle
	var throttle = spacecraft.get_throttle()
	current_throttle = throttle

	if abs(throttle) > 0.01:
		if not engine_thrust_player.playing:
			engine_thrust_player.play()
			is_engine_running = true

		# Adjust pitch and volume based on throttle
		var throttle_abs = abs(throttle)
		engine_thrust_player.pitch_scale = engine_base_pitch + (throttle_abs * engine_pitch_range)

		# Volume scales with throttle (logarithmic)
		var volume_range = engine_max_volume_db - engine_base_volume_db
		engine_thrust_player.volume_db = engine_base_volume_db + (throttle_abs * volume_range)
	else:
		if engine_thrust_player.playing:
			engine_thrust_player.stop()
			is_engine_running = false

	# Check velocity for warning beeps (descending too fast)
	if landing_detector:
		var status = landing_detector.get_landing_status()
		if status.altitude < 100 and status.speed > status.velocity_threshold * 1.5:
			# Descending too fast - play warning beep periodically
			if not warning_beep_player.playing:
				play_warning_beep()

## Update spacecraft audio positions
func _update_spacecraft_audio_positions() -> void:
	if not spacecraft or not is_instance_valid(spacecraft):
		return

	var pos = spacecraft.global_position
	engine_thrust_player.global_position = pos
	rcs_thruster_player.global_position = pos
	cockpit_ambience_player.global_position = pos
	landing_gear_player.global_position = pos

## Update walking audio
func _update_walking_audio(delta: float) -> void:
	if not walking_controller:
		return

	# Update footsteps based on movement
	var speed = walking_controller.get_current_speed()
	var is_moving = speed > 0.3

	if is_moving:
		footstep_timer += delta
		var step_interval = footstep_interval / (speed / walking_controller.walk_speed)

		if footstep_timer >= step_interval:
			footstep_timer = 0.0
			play_footstep()
	else:
		footstep_timer = 0.0

	# Update jetpack thrust sound
	var is_jetpack_active = walking_controller.is_jetpack_firing()
	if is_jetpack_active:
		if not jetpack_thrust_player.playing:
			jetpack_ignition_player.play()
			jetpack_thrust_player.play()

		# Vary pitch slightly based on fuel level
		var fuel_percent = walking_controller.get_jetpack_fuel_percent()
		jetpack_thrust_player.pitch_scale = jetpack_base_pitch + (fuel_percent * jetpack_pitch_range)
		jetpack_thrust_player.volume_db = jetpack_base_volume_db
	else:
		if jetpack_thrust_player.playing:
			jetpack_thrust_player.stop()
			jetpack_shutdown_player.play()

	# Detect landing after jump/flight
	var is_on_ground = walking_controller.is_on_floor()
	if not was_on_ground and is_on_ground:
		# Just landed - play thud sound
		var fall_velocity = abs(walking_controller.velocity.y)
		if fall_velocity > 2.0:  # Minimum velocity to play sound
			landing_thud_player.volume_db = -12.0 + (fall_velocity * 2.0)
			landing_thud_player.pitch_scale = 0.9 + randf_range(-0.1, 0.1)
			landing_thud_player.play()
	was_on_ground = is_on_ground

	last_walking_speed = speed

## Update walking audio positions
func _update_walking_audio_positions() -> void:
	if not walking_controller or not is_instance_valid(walking_controller):
		return

	var pos = walking_controller.global_position
	footstep_player.global_position = pos
	jetpack_thrust_player.global_position = pos
	jetpack_ignition_player.global_position = pos
	jetpack_shutdown_player.global_position = pos
	landing_thud_player.global_position = pos

## Start cockpit ambience loop
func _start_cockpit_ambience() -> void:
	if cockpit_ambience_player:
		cockpit_ambience_player.volume_db = -18.0
		cockpit_ambience_player.play()

## Play a footstep sound
func play_footstep() -> void:
	if not footstep_player:
		return

	# Vary pitch slightly for realism
	footstep_player.pitch_scale = 1.0 + randf_range(-footstep_pitch_variation, footstep_pitch_variation)
	footstep_player.volume_db = footstep_volume_db
	footstep_player.play()

	audio_event.emit("footstep", 1.0)

## Play warning beep
func play_warning_beep() -> void:
	if warning_beep_player:
		warning_beep_player.play()
		audio_event.emit("warning", 1.0)

## Play objective complete sound
func play_objective_complete() -> void:
	if objective_complete_player:
		objective_complete_player.play()
		audio_event.emit("objective_complete", 1.0)

## Play notification sound
func play_notification() -> void:
	if notification_player:
		notification_player.play()
		audio_event.emit("notification", 0.5)

## Signal handlers

func _on_thrust_applied(force: Vector3) -> void:
	# Play RCS thruster burst if rotation input is active
	if spacecraft and spacecraft.rotation_input.length() > 0.1:
		if not rcs_thruster_player.playing:
			rcs_thruster_player.volume_db = thruster_volume_db
			rcs_thruster_player.pitch_scale = thruster_pitch
			rcs_thruster_player.play()

func _on_velocity_changed(velocity: Vector3, speed: float) -> void:
	audio_event.emit("velocity_changed", speed)

func _on_collision_occurred(collision_info: Dictionary) -> void:
	# Play impact sound based on velocity
	if collision_info.has("velocity"):
		var velocity: Vector3 = collision_info.velocity
		var impact_speed = velocity.length()

		if impact_speed > impact_min_velocity:
			var volume = -20.0 + min(impact_speed * impact_volume_scale, 20.0)
			impact_player.volume_db = volume
			impact_player.pitch_scale = 0.8 + randf_range(-0.1, 0.1)
			impact_player.play()

			audio_event.emit("collision", impact_speed)

func _on_landing_detected(craft: Node3D, planet: CelestialBody) -> void:
	print("[MoonAudioManager] Landing detected!")

	# Play landing impact sound
	if craft and craft.has_method("get_velocity"):
		var velocity = craft.get_velocity()
		var impact_speed = velocity.length()

		if impact_speed > impact_min_velocity:
			var volume = -15.0 + min(impact_speed * 3.0, 15.0)
			impact_player.volume_db = volume
			impact_player.play()

	# Play dust settling sound
	if dust_settling_player:
		dust_settling_player.volume_db = -10.0
		dust_settling_player.play()

	# Play success chime after a short delay
	await get_tree().create_timer(1.0).timeout
	if success_chime_player:
		success_chime_player.play()

	audio_event.emit("landing_success", 1.0)

func _on_walking_started() -> void:
	print("[MoonAudioManager] Walking mode started")

	# Start breathing ambience
	if breathing_player:
		breathing_player.volume_db = -24.0
		breathing_player.play()

	# Stop cockpit ambience
	if cockpit_ambience_player and cockpit_ambience_player.playing:
		var tween = create_tween()
		tween.tween_property(cockpit_ambience_player, "volume_db", -60.0, 0.5)
		tween.finished.connect(func(): cockpit_ambience_player.stop())

	audio_event.emit("walking_started", 1.0)

func _on_walking_stopped() -> void:
	print("[MoonAudioManager] Walking mode stopped")

	# Stop walking sounds
	if footstep_player and footstep_player.playing:
		footstep_player.stop()

	if breathing_player and breathing_player.playing:
		breathing_player.stop()

	# Restart cockpit ambience
	_start_cockpit_ambience()

	audio_event.emit("walking_stopped", 0.0)

## Load audio files (to be called when actual audio files exist)
func load_audio_files() -> void:
	if not audio_manager:
		push_warning("[MoonAudioManager] AudioManager not found, cannot load audio files")
		return

	var loaded_count = 0
	var missing_files: Array[String] = []

	for key in AUDIO_PATHS:
		var path = AUDIO_PATHS[key]
		if ResourceLoader.exists(path):
			var stream = audio_manager.load_audio(path)
			if stream:
				loaded_count += 1
		else:
			missing_files.append(path)

	print("[MoonAudioManager] Loaded %d/%d audio files" % [loaded_count, AUDIO_PATHS.size()])
	if missing_files.size() > 0:
		print("[MoonAudioManager] Missing audio files:")
		for path in missing_files:
			print("  - ", path)

## Get list of required audio files
func get_required_audio_files() -> Dictionary:
	return AUDIO_PATHS.duplicate()

## Stop all audio
func stop_all_audio() -> void:
	# Stop all 3D players
	for child in get_children():
		if child is AudioStreamPlayer3D or child is AudioStreamPlayer:
			if child.playing:
				child.stop()

	is_engine_running = false
	print("[MoonAudioManager] All audio stopped")
