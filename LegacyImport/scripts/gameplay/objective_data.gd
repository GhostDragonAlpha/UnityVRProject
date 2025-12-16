## ObjectiveData - Resource class for mission objective definitions
## Defines a single objective within a mission.
##
## Requirements: 37.1, 37.2, 37.3, 37.4, 37.5
extends Resource
class_name ObjectiveData

## Objective types (mirrors MissionSystem.ObjectiveType)
enum Type {
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

## Objective identifier
@export var id: String = ""
## Short description displayed in HUD
@export var description: String = ""
## Detailed description for objective panel
@export var detailed_description: String = ""
## Objective type
@export var objective_type: Type = Type.CUSTOM

## Completion state
var is_completed: bool = false
var is_optional: bool = false
var completion_time: float = 0.0

## Location-based objectives
@export var target_position: Vector3 = Vector3.ZERO
@export var completion_radius: float = 100.0  ## Distance to target for completion

## Item-based objectives
@export var target_item_id: String = ""
@export var required_quantity: int = 1
var current_quantity: int = 0

## Time-based objectives
@export var required_duration: float = 0.0  ## Seconds to survive
var start_time: float = 0.0

## Target-based objectives (scan, destroy)
@export var target_object_id: String = ""
@export var target_object_name: String = ""

## Progress tracking
var progress: float = 0.0  ## 0.0 to 1.0

## Custom objective callback name
@export var custom_callback: String = ""

## Visual hints
@export var show_marker: bool = true
@export var marker_color: Color = Color.CYAN
@export var hint_text: String = ""


func _init() -> void:
	pass


## Factory Methods

static func create_location(obj_id: String, desc: String, position: Vector3, radius: float = 100.0) -> ObjectiveData:
	"""Create a location-based objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.REACH_LOCATION
	objective.target_position = position
	objective.completion_radius = radius
	objective.show_marker = true
	return objective


static func create_collect(obj_id: String, desc: String, item_id: String, quantity: int = 1) -> ObjectiveData:
	"""Create a collection objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.COLLECT_ITEM
	objective.target_item_id = item_id
	objective.required_quantity = quantity
	objective.current_quantity = 0
	return objective


static func create_scan(obj_id: String, desc: String, target_id: String = "", target_name: String = "") -> ObjectiveData:
	"""Create a scan objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.SCAN_OBJECT
	objective.target_object_id = target_id
	objective.target_object_name = target_name
	return objective


static func create_survival(obj_id: String, desc: String, duration: float) -> ObjectiveData:
	"""Create a survival time objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.SURVIVE_TIME
	objective.required_duration = duration
	return objective


static func create_destroy(obj_id: String, desc: String, target_id: String, target_name: String = "") -> ObjectiveData:
	"""Create a destroy target objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.DESTROY_TARGET
	objective.target_object_id = target_id
	objective.target_object_name = target_name
	return objective


static func create_discover(obj_id: String, desc: String, system_name: String) -> ObjectiveData:
	"""Create a discovery objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.DISCOVER_SYSTEM
	objective.target_object_name = system_name
	return objective


static func create_custom(obj_id: String, desc: String, callback: String = "") -> ObjectiveData:
	"""Create a custom objective."""
	var objective := ObjectiveData.new()
	objective.id = obj_id
	objective.description = desc
	objective.objective_type = Type.CUSTOM
	objective.custom_callback = callback
	return objective


## Progress Tracking

func update_progress(amount: float) -> void:
	"""Update objective progress (0.0 to 1.0)."""
	progress = clamp(amount, 0.0, 1.0)
	
	if progress >= 1.0 and not is_completed:
		complete()


func add_progress(amount: float) -> void:
	"""Add to objective progress."""
	update_progress(progress + amount)


func add_item(quantity: int = 1) -> void:
	"""Add collected items for collection objectives."""
	if objective_type != Type.COLLECT_ITEM:
		return
	
	current_quantity = min(current_quantity + quantity, required_quantity)
	progress = float(current_quantity) / float(required_quantity)
	
	if current_quantity >= required_quantity and not is_completed:
		complete()


func complete() -> void:
	"""Mark objective as completed."""
	is_completed = true
	progress = 1.0
	completion_time = Time.get_unix_time_from_system()


func reset() -> void:
	"""Reset objective to incomplete state."""
	is_completed = false
	progress = 0.0
	completion_time = 0.0
	current_quantity = 0
	start_time = 0.0


## State Queries

func get_progress_percentage() -> int:
	"""Get progress as integer percentage (0-100)."""
	return int(progress * 100)


func get_remaining_quantity() -> int:
	"""Get remaining items needed for collection objectives."""
	if objective_type != Type.COLLECT_ITEM:
		return 0
	return max(0, required_quantity - current_quantity)


func get_remaining_time() -> float:
	"""Get remaining time for survival objectives."""
	if objective_type != Type.SURVIVE_TIME or start_time <= 0:
		return required_duration
	
	var elapsed := Time.get_unix_time_from_system() - start_time
	return max(0.0, required_duration - elapsed)


func get_elapsed_time() -> float:
	"""Get elapsed time for survival objectives."""
	if objective_type != Type.SURVIVE_TIME or start_time <= 0:
		return 0.0
	return Time.get_unix_time_from_system() - start_time


func has_target_position() -> bool:
	"""Check if objective has a target position for navigation."""
	return target_position != Vector3.ZERO


func get_type_name() -> String:
	"""Get human-readable type name."""
	match objective_type:
		Type.REACH_LOCATION:
			return "Navigate"
		Type.COLLECT_ITEM:
			return "Collect"
		Type.SCAN_OBJECT:
			return "Scan"
		Type.SURVIVE_TIME:
			return "Survive"
		Type.DESTROY_TARGET:
			return "Destroy"
		Type.DISCOVER_SYSTEM:
			return "Discover"
		Type.CUSTOM:
			return "Objective"
		_:
			return "Unknown"


## Display Formatting

func get_status_text() -> String:
	"""Get formatted status text for HUD display."""
	if is_completed:
		return "[COMPLETE] %s" % description
	
	match objective_type:
		Type.COLLECT_ITEM:
			return "%s (%d/%d)" % [description, current_quantity, required_quantity]
		Type.SURVIVE_TIME:
			var remaining := get_remaining_time()
			return "%s (%.0fs remaining)" % [description, remaining]
		_:
			if progress > 0 and progress < 1:
				return "%s (%d%%)" % [description, get_progress_percentage()]
			return description


func get_marker_label() -> String:
	"""Get label text for navigation marker."""
	if target_object_name != "":
		return target_object_name
	return description


## Serialization

func serialize() -> Dictionary:
	"""Serialize objective data for saving."""
	return {
		"id": id,
		"description": description,
		"detailed_description": detailed_description,
		"objective_type": objective_type,
		"is_completed": is_completed,
		"is_optional": is_optional,
		"completion_time": completion_time,
		"target_position": {
			"x": target_position.x,
			"y": target_position.y,
			"z": target_position.z
		},
		"completion_radius": completion_radius,
		"target_item_id": target_item_id,
		"required_quantity": required_quantity,
		"current_quantity": current_quantity,
		"required_duration": required_duration,
		"start_time": start_time,
		"target_object_id": target_object_id,
		"target_object_name": target_object_name,
		"progress": progress,
		"custom_callback": custom_callback,
		"show_marker": show_marker,
		"marker_color": marker_color.to_html(),
		"hint_text": hint_text
	}


func deserialize(data: Dictionary) -> void:
	"""Deserialize objective data from save."""
	id = data.get("id", "")
	description = data.get("description", "")
	detailed_description = data.get("detailed_description", "")
	objective_type = data.get("objective_type", Type.CUSTOM)
	is_completed = data.get("is_completed", false)
	is_optional = data.get("is_optional", false)
	completion_time = data.get("completion_time", 0.0)
	completion_radius = data.get("completion_radius", 100.0)
	target_item_id = data.get("target_item_id", "")
	required_quantity = data.get("required_quantity", 1)
	current_quantity = data.get("current_quantity", 0)
	required_duration = data.get("required_duration", 0.0)
	start_time = data.get("start_time", 0.0)
	target_object_id = data.get("target_object_id", "")
	target_object_name = data.get("target_object_name", "")
	progress = data.get("progress", 0.0)
	custom_callback = data.get("custom_callback", "")
	show_marker = data.get("show_marker", true)
	hint_text = data.get("hint_text", "")
	
	if data.has("target_position"):
		var pos = data["target_position"]
		target_position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
	
	if data.has("marker_color"):
		marker_color = Color.html(data["marker_color"])
