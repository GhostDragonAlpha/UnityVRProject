## MissionData - Resource class for mission definitions
## Defines a mission with its objectives, rewards, and metadata.
##
## Requirements: 37.1, 37.2, 37.3, 37.4, 37.5
extends Resource
class_name MissionData

## Mission identifier
@export var id: String = ""
## Mission title displayed to player
@export var title: String = ""
## Mission description
@export var description: String = ""
## Mission category (main, side, tutorial, etc.)
@export var category: String = "main"

## Mission objectives
@export var objectives: Array[ObjectiveData] = []
## Currently active objective
var active_objective: ObjectiveData = null

## Mission state (from MissionSystem.MissionState enum)
var state: int = 0  ## NOT_STARTED

## Timing
var start_time: float = 0.0
var completion_time: float = 0.0
var time_limit: float = 0.0  ## 0 = no limit

## Failure tracking
var failure_reason: String = ""

## Prerequisites (mission IDs that must be completed first)
@export var prerequisites: Array[String] = []

## Rewards
@export var reward_experience: int = 0
@export var reward_currency: int = 0
@export var reward_items: Dictionary = {}  ## item_id: quantity

## Location data
@export var start_location: Vector3 = Vector3.ZERO
@export var mission_region: String = ""  ## Star system or region name


func _init() -> void:
	objectives = []
	prerequisites = []
	reward_items = {}


## Factory Methods

static func create(mission_id: String, mission_title: String, mission_desc: String = "") -> MissionData:
	"""Create a new mission with basic info."""
	var mission := MissionData.new()
	mission.id = mission_id
	mission.title = mission_title
	mission.description = mission_desc
	return mission


static func create_tutorial_mission(step: int) -> MissionData:
	"""Create a tutorial mission for the given step."""
	var mission := MissionData.new()
	mission.id = "tutorial_%d" % step
	mission.category = "tutorial"
	
	match step:
		1:
			mission.title = "Basic Controls"
			mission.description = "Learn to control your spacecraft"
			mission.add_objective(ObjectiveData.create_location(
				"reach_marker",
				"Fly to the navigation marker",
				Vector3(100, 0, 0),
				50.0
			))
		2:
			mission.title = "Understanding Gravity"
			mission.description = "Learn how gravity wells affect your trajectory"
			mission.add_objective(ObjectiveData.create_location(
				"orbit_planet",
				"Enter orbit around the planet",
				Vector3(500, 0, 0),
				100.0
			))
		3:
			mission.title = "Time Dilation"
			mission.description = "Experience relativistic effects at high speed"
			mission.add_objective(ObjectiveData.create_custom(
				"reach_speed",
				"Accelerate to 50% light speed"
			))
		_:
			mission.title = "Tutorial Step %d" % step
			mission.description = "Complete this tutorial step"
	
	return mission


static func create_exploration_mission(system_name: String, target_pos: Vector3) -> MissionData:
	"""Create an exploration mission to discover a star system."""
	var mission := MissionData.new()
	mission.id = "explore_%s" % system_name.to_lower().replace(" ", "_")
	mission.title = "Explore %s" % system_name
	mission.description = "Travel to and scan the %s system" % system_name
	mission.category = "exploration"
	mission.mission_region = system_name
	
	mission.add_objective(ObjectiveData.create_location(
		"reach_%s" % system_name.to_lower(),
		"Travel to %s" % system_name,
		target_pos,
		1000.0
	))
	
	mission.add_objective(ObjectiveData.create_scan(
		"scan_%s" % system_name.to_lower(),
		"Scan the primary star"
	))
	
	mission.reward_experience = 100
	mission.reward_currency = 50
	
	return mission


## Objective Management

func add_objective(objective: ObjectiveData) -> void:
	"""Add an objective to this mission."""
	if objective != null:
		objectives.append(objective)
		
		# Set first objective as active if none set
		if active_objective == null:
			active_objective = objective


func remove_objective(objective_id: String) -> bool:
	"""Remove an objective by ID."""
	for i in range(objectives.size()):
		if objectives[i].id == objective_id:
			var removed := objectives[i]
			objectives.remove_at(i)
			
			# Update active objective if needed
			if active_objective == removed:
				active_objective = objectives[0] if objectives.size() > 0 else null
			
			return true
	return false


func get_objective(objective_id: String) -> ObjectiveData:
	"""Get an objective by ID."""
	for objective in objectives:
		if objective.id == objective_id:
			return objective
	return null


func get_completed_objectives() -> Array[ObjectiveData]:
	"""Get all completed objectives."""
	var completed: Array[ObjectiveData] = []
	for objective in objectives:
		if objective.is_completed:
			completed.append(objective)
	return completed


func get_incomplete_objectives() -> Array[ObjectiveData]:
	"""Get all incomplete objectives."""
	var incomplete: Array[ObjectiveData] = []
	for objective in objectives:
		if not objective.is_completed:
			incomplete.append(objective)
	return incomplete


func get_required_objectives() -> Array[ObjectiveData]:
	"""Get all required (non-optional) objectives."""
	var required: Array[ObjectiveData] = []
	for objective in objectives:
		if not objective.is_optional:
			required.append(objective)
	return required


## State Queries

func is_complete() -> bool:
	"""Check if all required objectives are complete."""
	for objective in objectives:
		if not objective.is_optional and not objective.is_completed:
			return false
	return true


func is_failed() -> bool:
	"""Check if the mission has failed."""
	return state == 3  ## MissionState.FAILED


func is_in_progress() -> bool:
	"""Check if the mission is currently in progress."""
	return state == 1  ## MissionState.IN_PROGRESS


func get_progress() -> float:
	"""Get completion progress as percentage (0.0 to 1.0)."""
	var required := get_required_objectives()
	if required.size() == 0:
		return 1.0
	
	var completed_count := 0
	for objective in required:
		if objective.is_completed:
			completed_count += 1
	
	return float(completed_count) / float(required.size())


func get_elapsed_time() -> float:
	"""Get elapsed time since mission start."""
	if start_time <= 0:
		return 0.0
	
	if completion_time > 0:
		return completion_time - start_time
	
	return Time.get_unix_time_from_system() - start_time


func get_remaining_time() -> float:
	"""Get remaining time if mission has a time limit."""
	if time_limit <= 0:
		return -1.0  ## No limit
	
	var remaining := time_limit - get_elapsed_time()
	return max(0.0, remaining)


func has_time_limit() -> bool:
	"""Check if mission has a time limit."""
	return time_limit > 0


func is_time_expired() -> bool:
	"""Check if time limit has expired."""
	if not has_time_limit():
		return false
	return get_remaining_time() <= 0


## Prerequisite Checking

func are_prerequisites_met(completed_mission_ids: Array[String]) -> bool:
	"""Check if all prerequisites are met."""
	for prereq_id in prerequisites:
		if prereq_id not in completed_mission_ids:
			return false
	return true


## Serialization

func serialize() -> Dictionary:
	"""Serialize mission data for saving."""
	var data := {
		"id": id,
		"title": title,
		"description": description,
		"category": category,
		"state": state,
		"start_time": start_time,
		"completion_time": completion_time,
		"time_limit": time_limit,
		"failure_reason": failure_reason,
		"prerequisites": prerequisites,
		"reward_experience": reward_experience,
		"reward_currency": reward_currency,
		"reward_items": reward_items,
		"start_location": {
			"x": start_location.x,
			"y": start_location.y,
			"z": start_location.z
		},
		"mission_region": mission_region,
		"objectives": [],
		"active_objective_id": active_objective.id if active_objective != null else ""
	}
	
	for objective in objectives:
		data["objectives"].append(objective.serialize())
	
	return data


func deserialize(data: Dictionary) -> void:
	"""Deserialize mission data from save."""
	id = data.get("id", "")
	title = data.get("title", "")
	description = data.get("description", "")
	category = data.get("category", "main")
	state = data.get("state", 0)
	start_time = data.get("start_time", 0.0)
	completion_time = data.get("completion_time", 0.0)
	time_limit = data.get("time_limit", 0.0)
	failure_reason = data.get("failure_reason", "")
	prerequisites = data.get("prerequisites", [])
	reward_experience = data.get("reward_experience", 0)
	reward_currency = data.get("reward_currency", 0)
	reward_items = data.get("reward_items", {})
	mission_region = data.get("mission_region", "")
	
	if data.has("start_location"):
		var loc = data["start_location"]
		start_location = Vector3(loc.get("x", 0), loc.get("y", 0), loc.get("z", 0))
	
	# Deserialize objectives
	objectives.clear()
	if data.has("objectives"):
		for obj_data in data["objectives"]:
			var objective := ObjectiveData.new()
			objective.deserialize(obj_data)
			objectives.append(objective)
	
	# Restore active objective
	var active_id = data.get("active_objective_id", "")
	if active_id != "":
		active_objective = get_objective(active_id)
	elif objectives.size() > 0:
		active_objective = objectives[0]
