extends Node
class_name MoonProgressionTracker
## Tracks player progression and achievements in moon landing experience
## Manages missions, scoring, and unlockables

signal achievement_unlocked(achievement: Dictionary)
signal mission_completed(mission: Dictionary)
signal new_high_score(category: String, score: float)
signal statistic_updated(stat_name: String, value: Variant)

## Achievement definitions
enum Achievement {
	FIRST_LANDING,        # Complete first landing
	SMOOTH_LANDING,       # Land under 2 m/s
	PERFECT_LANDING,      # Land under 1 m/s at designated zone
	LUNAR_EXPLORER,       # Travel 100m from landing
	LONG_DISTANCE,        # Travel 500m from landing
	MARATHON,             # Travel 1000m from landing
	JUMPER,               # Jump 10 times
	HIGH_JUMPER,          # Jump 20 times
	OLYMPIC_JUMPER,       # Jump 50 times
	FUEL_EFFICIENT,       # Complete landing with high fuel remaining
	QUICK_LANDING,        # Land within time limit
	MULTI_LANDING,        # Land successfully 5 times
}

## Mission definitions
enum Mission {
	TUTORIAL_LANDING,     # Mission 1: First landing (tutorial)
	PRECISION_LANDING,    # Mission 2: Land in target zone
	SPEED_CHALLENGE,      # Mission 3: Land quickly
	FUEL_CHALLENGE,       # Mission 4: Land with fuel remaining
	EXPLORATION,          # Mission 5: Explore and find locations
	LUNAR_OLYMPICS,       # Mission 6: Jump challenges
}

## Achievement data
var achievements: Dictionary = {
	Achievement.FIRST_LANDING: {
		"name": "First Steps",
		"description": "Complete your first moon landing",
		"unlocked": false,
		"points": 100
	},
	Achievement.SMOOTH_LANDING: {
		"name": "Smooth Operator",
		"description": "Land with speed under 2 m/s",
		"unlocked": false,
		"points": 200
	},
	Achievement.PERFECT_LANDING: {
		"name": "Perfection",
		"description": "Land with speed under 1 m/s in target zone",
		"unlocked": false,
		"points": 500
	},
	Achievement.LUNAR_EXPLORER: {
		"name": "Lunar Explorer",
		"description": "Travel 100m from landing site",
		"unlocked": false,
		"points": 150
	},
	Achievement.LONG_DISTANCE: {
		"name": "Long Distance Walker",
		"description": "Travel 500m from landing site",
		"unlocked": false,
		"points": 300
	},
	Achievement.MARATHON: {
		"name": "Lunar Marathon",
		"description": "Travel 1000m from landing site",
		"unlocked": false,
		"points": 1000
	},
	Achievement.JUMPER: {
		"name": "Jumper",
		"description": "Jump 10 times on the moon",
		"unlocked": false,
		"points": 100
	},
	Achievement.HIGH_JUMPER: {
		"name": "High Jumper",
		"description": "Jump 20 times on the moon",
		"unlocked": false,
		"points": 200
	},
	Achievement.OLYMPIC_JUMPER: {
		"name": "Lunar Olympian",
		"description": "Jump 50 times on the moon",
		"unlocked": false,
		"points": 500
	},
	Achievement.FUEL_EFFICIENT: {
		"name": "Fuel Efficient",
		"description": "Complete landing with 50% fuel remaining",
		"unlocked": false,
		"points": 300
	},
	Achievement.QUICK_LANDING: {
		"name": "Speedrunner",
		"description": "Complete landing in under 60 seconds",
		"unlocked": false,
		"points": 400
	},
	Achievement.MULTI_LANDING: {
		"name": "Veteran Pilot",
		"description": "Complete 5 successful landings",
		"unlocked": false,
		"points": 600
	}
}

## Mission data
var missions: Dictionary = {
	Mission.TUTORIAL_LANDING: {
		"name": "First Landing",
		"description": "Complete the tutorial and land on the moon",
		"completed": false,
		"objectives": ["Land successfully", "Exit spacecraft", "Jump on moon"],
		"reward_points": 500,
		"unlocked": true
	},
	Mission.PRECISION_LANDING: {
		"name": "Precision Landing",
		"description": "Land within the marked target zone",
		"completed": false,
		"objectives": ["Land in target zone", "Speed under 2 m/s"],
		"reward_points": 1000,
		"unlocked": false
	},
	Mission.SPEED_CHALLENGE: {
		"name": "Quick Descent",
		"description": "Complete landing in under 60 seconds",
		"completed": false,
		"objectives": ["Land within time limit", "Maintain safe speed"],
		"reward_points": 1500,
		"unlocked": false
	},
	Mission.FUEL_CHALLENGE: {
		"name": "Fuel Conservation",
		"description": "Land with at least 50% fuel remaining",
		"completed": false,
		"objectives": ["Land successfully", "Fuel > 50%"],
		"reward_points": 1200,
		"unlocked": false
	},
	Mission.EXPLORATION: {
		"name": "Lunar Survey",
		"description": "Visit all marked locations on the moon",
		"completed": false,
		"objectives": ["Visit 3 survey points", "Return to lander"],
		"reward_points": 2000,
		"unlocked": false
	},
	Mission.LUNAR_OLYMPICS: {
		"name": "Lunar Olympics",
		"description": "Complete jump challenges in low gravity",
		"completed": false,
		"objectives": ["Jump 50 times", "Jump height > 5m", "Long jump > 20m"],
		"reward_points": 2500,
		"unlocked": false
	}
}

## Statistics tracking
var statistics: Dictionary = {
	"total_landings": 0,
	"successful_landings": 0,
	"failed_landings": 0,
	"total_jumps": 0,
	"max_distance_traveled": 0.0,
	"total_distance_traveled": 0.0,
	"fastest_landing_time": 0.0,
	"smoothest_landing_speed": 999.9,
	"total_play_time": 0.0,
	"current_session_time": 0.0
}

## Scoring
var total_score: int = 0
var high_scores: Dictionary = {
	"landing_speed": 999.9,  # Lower is better
	"landing_time": 999.9,   # Lower is better
	"distance_traveled": 0.0, # Higher is better
	"jump_count": 0          # Higher is better
}

## Current session tracking
var landing_position: Vector3 = Vector3.ZERO
var landing_start_time: float = 0.0
var session_jump_count: int = 0
var max_session_distance: float = 0.0

## References
var landing_detector: LandingDetector = null
var spacecraft: Spacecraft = null
var transition_system: TransitionSystem = null

## Session active
var session_active: bool = false


func _ready() -> void:
	_load_progression_data()
	set_process(false)


func _process(delta: float) -> void:
	if session_active:
		statistics["current_session_time"] += delta
		statistics["total_play_time"] += delta
		_check_progression_conditions(delta)


## Initialize with scene references
func initialize(detector: LandingDetector, craft: Spacecraft,
				trans_sys: TransitionSystem = null) -> void:
	landing_detector = detector
	spacecraft = craft
	transition_system = trans_sys

	# Connect signals
	if landing_detector:
		landing_detector.landing_detected.connect(_on_landing_detected)
		landing_detector.walking_mode_requested.connect(_on_walking_started)

	set_process(true)


## Start a landing session
func start_landing_session() -> void:
	session_active = true
	landing_start_time = Time.get_ticks_msec() / 1000.0
	session_jump_count = 0
	max_session_distance = 0.0
	statistics["total_landings"] += 1

	print("[MoonProgressionTracker] Landing session started")


## Complete a landing session
func complete_landing_session(landing_speed: float, success: bool) -> void:
	if not session_active:
		return

	var landing_time = (Time.get_ticks_msec() / 1000.0) - landing_start_time

	if success:
		statistics["successful_landings"] += 1

		# Calculate score
		var score = _calculate_landing_score(landing_speed, landing_time)
		total_score += score

		# Check for new high scores
		_check_high_scores(landing_speed, landing_time)

		# Check for achievements
		_check_landing_achievements(landing_speed, landing_time)

		print("[MoonProgressionTracker] Landing completed - Score: ", score)
	else:
		statistics["failed_landings"] += 1
		print("[MoonProgressionTracker] Landing failed")

	_save_progression_data()
	session_active = false


## Calculate landing score based on performance
func _calculate_landing_score(speed: float, time: float) -> int:
	var score: int = 1000  # Base score

	# Speed bonus (lower is better)
	if speed < 1.0:
		score += 500  # Perfect landing
	elif speed < 2.0:
		score += 300  # Smooth landing
	elif speed < 5.0:
		score += 100  # Safe landing

	# Time bonus (faster is better, but not too fast)
	if time < 30.0:
		score += 200
	elif time < 60.0:
		score += 100

	# Distance bonus
	score += int(max_session_distance / 10.0)  # 1 point per 10m

	# Jump bonus
	score += session_jump_count * 10

	return score


## Check for high scores
func _check_high_scores(speed: float, time: float) -> void:
	# Landing speed (lower is better)
	if speed < high_scores["landing_speed"]:
		high_scores["landing_speed"] = speed
		new_high_score.emit("landing_speed", speed)
		print("[MoonProgressionTracker] New high score: Landing Speed %.2f m/s" % speed)

	# Landing time (lower is better)
	if time < high_scores["landing_time"] or high_scores["landing_time"] == 999.9:
		high_scores["landing_time"] = time
		new_high_score.emit("landing_time", time)
		print("[MoonProgressionTracker] New high score: Landing Time %.1f s" % time)

	# Distance (higher is better)
	if max_session_distance > high_scores["distance_traveled"]:
		high_scores["distance_traveled"] = max_session_distance
		new_high_score.emit("distance_traveled", max_session_distance)
		print("[MoonProgressionTracker] New high score: Distance %.1f m" % max_session_distance)

	# Jumps (higher is better)
	if session_jump_count > high_scores["jump_count"]:
		high_scores["jump_count"] = session_jump_count
		new_high_score.emit("jump_count", session_jump_count)
		print("[MoonProgressionTracker] New high score: Jumps %d" % session_jump_count)


## Check for landing achievements
func _check_landing_achievements(speed: float, time: float) -> void:
	# First landing
	if not achievements[Achievement.FIRST_LANDING]["unlocked"]:
		_unlock_achievement(Achievement.FIRST_LANDING)

	# Smooth landing
	if speed < 2.0 and not achievements[Achievement.SMOOTH_LANDING]["unlocked"]:
		_unlock_achievement(Achievement.SMOOTH_LANDING)

	# Perfect landing
	if speed < 1.0 and not achievements[Achievement.PERFECT_LANDING]["unlocked"]:
		_unlock_achievement(Achievement.PERFECT_LANDING)

	# Quick landing
	if time < 60.0 and not achievements[Achievement.QUICK_LANDING]["unlocked"]:
		_unlock_achievement(Achievement.QUICK_LANDING)

	# Multi landing
	if statistics["successful_landings"] >= 5 and not achievements[Achievement.MULTI_LANDING]["unlocked"]:
		_unlock_achievement(Achievement.MULTI_LANDING)


## Check progression conditions during session
func _check_progression_conditions(delta: float) -> void:
	if not transition_system:
		return

	var walking_controller = transition_system.get_walking_controller()
	if not walking_controller or not walking_controller.is_walking_active():
		return

	# Track distance from landing site
	if landing_position != Vector3.ZERO:
		var distance = walking_controller.global_position.distance_to(landing_position)
		max_session_distance = max(max_session_distance, distance)
		statistics["max_distance_traveled"] = max(statistics["max_distance_traveled"], distance)

		# Distance achievements
		if distance >= 100.0 and not achievements[Achievement.LUNAR_EXPLORER]["unlocked"]:
			_unlock_achievement(Achievement.LUNAR_EXPLORER)
		if distance >= 500.0 and not achievements[Achievement.LONG_DISTANCE]["unlocked"]:
			_unlock_achievement(Achievement.LONG_DISTANCE)
		if distance >= 1000.0 and not achievements[Achievement.MARATHON]["unlocked"]:
			_unlock_achievement(Achievement.MARATHON)

	# Jump tracking (done via signal in actual implementation)
	_check_jump_achievements()


## Track jumps
func record_jump() -> void:
	session_jump_count += 1
	statistics["total_jumps"] += 1
	statistic_updated.emit("total_jumps", statistics["total_jumps"])
	_check_jump_achievements()


func _check_jump_achievements() -> void:
	var total_jumps = statistics["total_jumps"]

	if total_jumps >= 10 and not achievements[Achievement.JUMPER]["unlocked"]:
		_unlock_achievement(Achievement.JUMPER)
	if total_jumps >= 20 and not achievements[Achievement.HIGH_JUMPER]["unlocked"]:
		_unlock_achievement(Achievement.HIGH_JUMPER)
	if total_jumps >= 50 and not achievements[Achievement.OLYMPIC_JUMPER]["unlocked"]:
		_unlock_achievement(Achievement.OLYMPIC_JUMPER)


## Unlock achievement
func _unlock_achievement(achievement: Achievement) -> void:
	if achievements[achievement]["unlocked"]:
		return

	achievements[achievement]["unlocked"] = true
	var points = achievements[achievement]["points"]
	total_score += points

	var achievement_data = achievements[achievement]
	achievement_unlocked.emit(achievement_data)

	print("[MoonProgressionTracker] Achievement unlocked: ", achievement_data["name"])
	print("  +", points, " points")

	# Check if achievement unlocks new missions
	_check_mission_unlocks()

	_save_progression_data()


## Check if any missions should be unlocked
func _check_mission_unlocks() -> void:
	# Unlock Precision Landing after first landing
	if achievements[Achievement.FIRST_LANDING]["unlocked"] and not missions[Mission.PRECISION_LANDING]["unlocked"]:
		missions[Mission.PRECISION_LANDING]["unlocked"] = true
		print("[MoonProgressionTracker] New mission unlocked: Precision Landing")

	# Unlock Speed Challenge after smooth landing
	if achievements[Achievement.SMOOTH_LANDING]["unlocked"] and not missions[Mission.SPEED_CHALLENGE]["unlocked"]:
		missions[Mission.SPEED_CHALLENGE]["unlocked"] = true
		print("[MoonProgressionTracker] New mission unlocked: Quick Descent")

	# Unlock Exploration after traveling some distance
	if achievements[Achievement.LUNAR_EXPLORER]["unlocked"] and not missions[Mission.EXPLORATION]["unlocked"]:
		missions[Mission.EXPLORATION]["unlocked"] = true
		print("[MoonProgressionTracker] New mission unlocked: Lunar Survey")

	# Unlock Olympics after jumping enough
	if achievements[Achievement.JUMPER]["unlocked"] and not missions[Mission.LUNAR_OLYMPICS]["unlocked"]:
		missions[Mission.LUNAR_OLYMPICS]["unlocked"] = true
		print("[MoonProgressionTracker] New mission unlocked: Lunar Olympics")


## Complete a mission
func complete_mission(mission: Mission) -> void:
	if missions[mission]["completed"]:
		return

	missions[mission]["completed"] = true
	var points = missions[mission]["reward_points"]
	total_score += points

	var mission_data = missions[mission]
	mission_completed.emit(mission_data)

	print("[MoonProgressionTracker] Mission completed: ", mission_data["name"])
	print("  +", points, " points")

	_save_progression_data()


## Signal handlers

func _on_landing_detected(craft: Node3D, planet: CelestialBody) -> void:
	if craft:
		landing_position = craft.global_position

	# Get landing speed
	var speed = landing_detector.get_speed() if landing_detector else 5.0

	complete_landing_session(speed, true)


func _on_walking_started() -> void:
	print("[MoonProgressionTracker] Walking mode started")


## Save/Load progression data

func _save_progression_data() -> void:
	var data = {
		"achievements": achievements,
		"missions": missions,
		"statistics": statistics,
		"total_score": total_score,
		"high_scores": high_scores
	}

	var file = FileAccess.open("user://moon_progression.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[MoonProgressionTracker] Progression saved")
	else:
		push_error("[MoonProgressionTracker] Failed to save progression data")


func _load_progression_data() -> void:
	if not FileAccess.file_exists("user://moon_progression.json"):
		print("[MoonProgressionTracker] No save file found - starting fresh")
		return

	var file = FileAccess.open("user://moon_progression.json", FileAccess.READ)
	if not file:
		push_error("[MoonProgressionTracker] Failed to load progression data")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("[MoonProgressionTracker] Failed to parse progression JSON")
		return

	var data = json.data

	if data.has("achievements"):
		achievements = data["achievements"]
	if data.has("missions"):
		missions = data["missions"]
	if data.has("statistics"):
		statistics = data["statistics"]
	if data.has("total_score"):
		total_score = data["total_score"]
	if data.has("high_scores"):
		high_scores = data["high_scores"]

	print("[MoonProgressionTracker] Progression loaded")
	print("  Total Score: ", total_score)
	print("  Successful Landings: ", statistics["successful_landings"])


## Query methods

func get_unlocked_achievements() -> Array:
	var unlocked = []
	for key in achievements:
		if achievements[key]["unlocked"]:
			unlocked.append(achievements[key])
	return unlocked


func get_unlocked_missions() -> Array:
	var unlocked = []
	for key in missions:
		if missions[key]["unlocked"]:
			unlocked.append(missions[key])
	return unlocked


func get_completion_percentage() -> float:
	var total_achievements = achievements.size()
	var unlocked_count = get_unlocked_achievements().size()
	return (float(unlocked_count) / float(total_achievements)) * 100.0


func reset_progression() -> void:
	# Reset all achievements
	for key in achievements:
		achievements[key]["unlocked"] = false

	# Reset all missions
	for key in missions:
		missions[key]["completed"] = false
		missions[key]["unlocked"] = false

	# Tutorial mission is always unlocked
	missions[Mission.TUTORIAL_LANDING]["unlocked"] = true

	# Reset statistics
	statistics = {
		"total_landings": 0,
		"successful_landings": 0,
		"failed_landings": 0,
		"total_jumps": 0,
		"max_distance_traveled": 0.0,
		"total_distance_traveled": 0.0,
		"fastest_landing_time": 0.0,
		"smoothest_landing_speed": 999.9,
		"total_play_time": 0.0,
		"current_session_time": 0.0
	}

	total_score = 0
	high_scores = {
		"landing_speed": 999.9,
		"landing_time": 999.9,
		"distance_traveled": 0.0,
		"jump_count": 0
	}

	_save_progression_data()
	print("[MoonProgressionTracker] Progression reset")
