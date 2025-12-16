## AirlockModule - Entry/exit with pressure management
## Requirements: 5.4, 5.5, 6.4

class_name AirlockModule
extends BaseModule

enum AirlockState {
	CLOSED,           # Both doors closed
	PRESSURIZING,     # Filling with air
	DEPRESSURIZING,   # Venting air
	INNER_OPEN,       # Inner door open (base side)
	OUTER_OPEN        # Outer door open (exterior side)
}

signal state_changed(new_state: AirlockState)
signal cycle_started()
signal cycle_completed()
signal player_entered_chamber()
signal player_exited_chamber()

## Airlock-specific properties
@export var cycle_duration: float = 5.0  # Seconds to pressurize/depressurize
@export var max_occupants: int = 2

var current_state: AirlockState = AirlockState.CLOSED
var cycle_progress: float = 0.0
var is_cycling: bool = false
var occupants_in_chamber: int = 0


func _ready() -> void:
	module_type = ModuleType.AIRLOCK
	max_health = 140.0
	health = max_health
	power_consumption = 10.0
	structural_strength = 110.0
	
	super._ready()


func _process(delta: float) -> void:
	if is_cycling:
		_update_cycle(delta)


func _update_cycle(delta: float) -> void:
	"""Update airlock cycle progress"""
	cycle_progress += delta / cycle_duration
	
	if cycle_progress >= 1.0:
		_complete_cycle()


func _complete_cycle() -> void:
	"""Complete the current cycle"""
	is_cycling = false
	cycle_progress = 0.0
	
	match current_state:
		AirlockState.PRESSURIZING:
			_set_state(AirlockState.INNER_OPEN)
		AirlockState.DEPRESSURIZING:
			_set_state(AirlockState.OUTER_OPEN)
	
	cycle_completed.emit()


func request_entry_from_outside() -> bool:
	"""Request to enter from outside (depressurize then open outer door)"""
	if current_state != AirlockState.CLOSED:
		return false
	
	if not is_powered:
		return false
	
	_start_cycle(AirlockState.DEPRESSURIZING)
	return true


func request_entry_from_inside() -> bool:
	"""Request to enter from inside (pressurize then open inner door)"""
	if current_state != AirlockState.CLOSED:
		return false
	
	if not is_powered:
		return false
	
	_start_cycle(AirlockState.PRESSURIZING)
	return true


func request_exit_to_outside() -> bool:
	"""Request to exit to outside (depressurize then open outer door)"""
	if current_state != AirlockState.CLOSED:
		return false
	
	if not is_powered:
		return false
	
	_start_cycle(AirlockState.DEPRESSURIZING)
	return true


func request_exit_to_inside() -> bool:
	"""Request to exit to inside (pressurize then open inner door)"""
	if current_state != AirlockState.CLOSED:
		return false
	
	if not is_powered:
		return false
	
	_start_cycle(AirlockState.PRESSURIZING)
	return true


func close_doors() -> bool:
	"""Close all doors and return to closed state"""
	if current_state == AirlockState.CLOSED or is_cycling:
		return false
	
	if occupants_in_chamber > 0:
		return false  # Can't close with people inside
	
	_set_state(AirlockState.CLOSED)
	return true


func enter_chamber(player_id: int) -> bool:
	"""Player enters the airlock chamber"""
	if occupants_in_chamber >= max_occupants:
		return false
	
	if current_state != AirlockState.INNER_OPEN and current_state != AirlockState.OUTER_OPEN:
		return false
	
	occupants_in_chamber += 1
	player_entered_chamber.emit()
	return true


func exit_chamber(player_id: int) -> bool:
	"""Player exits the airlock chamber"""
	if occupants_in_chamber <= 0:
		return false
	
	if current_state != AirlockState.INNER_OPEN and current_state != AirlockState.OUTER_OPEN:
		return false
	
	occupants_in_chamber -= 1
	player_exited_chamber.emit()
	return true


func _start_cycle(target_state: AirlockState) -> void:
	"""Start a pressurization/depressurization cycle"""
	_set_state(target_state)
	is_cycling = true
	cycle_progress = 0.0
	cycle_started.emit()


func _set_state(new_state: AirlockState) -> void:
	"""Set airlock state"""
	if current_state == new_state:
		return
	
	current_state = new_state
	state_changed.emit(new_state)


func get_state_name() -> String:
	"""Get human-readable state name"""
	match current_state:
		AirlockState.CLOSED:
			return "Closed"
		AirlockState.PRESSURIZING:
			return "Pressurizing"
		AirlockState.DEPRESSURIZING:
			return "Depressurizing"
		AirlockState.INNER_OPEN:
			return "Inner Door Open"
		AirlockState.OUTER_OPEN:
			return "Outer Door Open"
	return "Unknown"


func get_cycle_progress_percentage() -> float:
	"""Get cycle progress as percentage"""
	return cycle_progress * 100.0


func is_safe_to_enter() -> bool:
	"""Check if it's safe to enter the chamber"""
	return current_state == AirlockState.INNER_OPEN or current_state == AirlockState.OUTER_OPEN


func save_state() -> Dictionary:
	var data := super.save_state()
	data["current_state"] = current_state
	data["is_cycling"] = is_cycling
	data["cycle_progress"] = cycle_progress
	data["occupants_in_chamber"] = occupants_in_chamber
	return data


func load_state(data: Dictionary) -> void:
	super.load_state(data)
	current_state = data.get("current_state", AirlockState.CLOSED)
	is_cycling = data.get("is_cycling", false)
	cycle_progress = data.get("cycle_progress", 0.0)
	occupants_in_chamber = data.get("occupants_in_chamber", 0)
