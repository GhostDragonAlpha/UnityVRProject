## GeneratorModule - Power generation module
## Requirements: 5.4, 5.5, 6.4, 12.1, 39.1, 39.2, 39.3, 39.4, 39.5

class_name GeneratorModule
extends BaseModule

enum GeneratorType {
	BIOMASS,      # Burns organic matter
	COAL,         # Burns coal
	FUEL,         # Burns refined fuel
	GEOTHERMAL,   # Uses thermal vents (no fuel)
	NUCLEAR       # Uses uranium (high output)
}

enum FailureState {
	OPERATIONAL,
	OVERHEATING,
	FUEL_DEPLETED,
	DAMAGED,
	CRITICAL_FAILURE
}

signal fuel_depleted()
signal fuel_added(fuel_type: String, amount: int)
signal power_output_changed(new_output: float)
signal generator_failed(failure_type: FailureState)
signal generator_repaired()

## Generator-specific properties
@export var generator_type: GeneratorType = GeneratorType.BIOMASS
@export var base_power_output: float = 100.0
@export var fuel_consumption_rate: float = 1.0  # Units per second
@export var max_fuel_capacity: int = 100

var current_fuel: int = 0
var current_power_output: float = 0.0
var is_active: bool = false
var failure_state: FailureState = FailureState.OPERATIONAL

## Geothermal-specific properties
var thermal_energy_level: float = 1.0  # 0.0 to 1.0, affects geothermal output
var thermal_fluctuation_rate: float = 0.1  # How fast thermal energy changes
var time_accumulator: float = 0.0

## Failure mechanics
var overheat_threshold: float = 0.9  # Percentage of max output before overheating risk
var failure_chance_per_second: float = 0.001  # 0.1% chance per second when overheating
var repair_progress: float = 0.0
var requires_repair: bool = false

## Fuel types accepted by each generator
var accepted_fuels: Dictionary = {
	GeneratorType.BIOMASS: ["organic", "wood", "plant_matter"],
	GeneratorType.COAL: ["coal"],
	GeneratorType.FUEL: ["refined_fuel", "petroleum"],
	GeneratorType.GEOTHERMAL: [],  # No fuel needed
	GeneratorType.NUCLEAR: ["uranium", "plutonium"]
}


func _ready() -> void:
	module_type = ModuleType.GENERATOR
	max_health = 130.0
	health = max_health
	power_consumption = 0.0  # Generators don't consume power
	structural_strength = 100.0
	
	# Set power production based on generator type
	match generator_type:
		GeneratorType.BIOMASS:
			base_power_output = 50.0
		GeneratorType.COAL:
			base_power_output = 100.0
		GeneratorType.FUEL:
			base_power_output = 200.0
		GeneratorType.GEOTHERMAL:
			base_power_output = 150.0
		GeneratorType.NUCLEAR:
			base_power_output = 500.0
	
	power_production = base_power_output
	
	super._ready()


func _process(delta: float) -> void:
	if is_active:
		_update_power_generation(delta)
	
	# Update geothermal thermal energy fluctuations
	if generator_type == GeneratorType.GEOTHERMAL:
		_update_thermal_fluctuation(delta)
	
	# Check for failures
	if is_active and failure_state == FailureState.OPERATIONAL:
		_check_for_failures(delta)


func _update_power_generation(delta: float) -> void:
	"""Update power generation and fuel consumption
	Requirements: 12.1, 39.1, 39.2, 39.3, 39.4, 39.5"""
	
	# Check failure state
	if failure_state != FailureState.OPERATIONAL:
		current_power_output = 0.0
		power_production = 0.0
		return
	
	# Geothermal uses thermal energy level
	if generator_type == GeneratorType.GEOTHERMAL:
		current_power_output = base_power_output * thermal_energy_level
		power_production = current_power_output
		return
	
	# Check if we have fuel
	if current_fuel <= 0:
		_shutdown()
		failure_state = FailureState.FUEL_DEPLETED
		return
	
	# Consume fuel
	var fuel_consumed := fuel_consumption_rate * delta
	current_fuel -= int(fuel_consumed)
	current_fuel = max(0, current_fuel)
	
	if current_fuel <= 0:
		_shutdown()
		failure_state = FailureState.FUEL_DEPLETED
		fuel_depleted.emit()
		return
	
	# Generate power
	current_power_output = base_power_output
	power_production = current_power_output


func _update_thermal_fluctuation(delta: float) -> void:
	"""Update geothermal thermal energy levels with fluctuation
	Requirements: 39.2, 39.3, 39.4"""
	
	time_accumulator += delta
	
	# Use sine wave for smooth fluctuation
	var fluctuation := sin(time_accumulator * thermal_fluctuation_rate) * 0.15
	thermal_energy_level = 0.85 + fluctuation  # Fluctuates between 0.7 and 1.0
	
	# Clamp to valid range
	thermal_energy_level = clamp(thermal_energy_level, 0.1, 1.0)


func _check_for_failures(delta: float) -> void:
	"""Check for generator failures
	Requirements: 39.1, 39.2, 39.3, 39.4, 39.5"""
	
	# Check for overheating
	var load_percentage := current_power_output / base_power_output
	if load_percentage >= overheat_threshold:
		# Chance of failure increases with load
		var failure_roll := randf()
		var failure_threshold := failure_chance_per_second * delta * (load_percentage - overheat_threshold) * 10.0
		
		if failure_roll < failure_threshold:
			_trigger_failure(FailureState.OVERHEATING)
	
	# Check for damage-based failures
	var health_percentage := health / max_health
	if health_percentage < 0.3:
		var damage_failure_roll := randf()
		if damage_failure_roll < 0.001 * delta:  # 0.1% chance per second when damaged
			_trigger_failure(FailureState.DAMAGED)


func _trigger_failure(failure_type: FailureState) -> void:
	"""Trigger a generator failure
	Requirements: 39.1, 39.2, 39.3, 39.4, 39.5"""
	
	failure_state = failure_type
	_shutdown()
	requires_repair = true
	generator_failed.emit(failure_type)
	
	# Apply damage based on failure type
	match failure_type:
		FailureState.OVERHEATING:
			health -= 20.0
		FailureState.DAMAGED:
			health -= 10.0
		FailureState.CRITICAL_FAILURE:
			health -= 50.0
	
	health = max(0.0, health)


func start_generator() -> bool:
	"""Start the generator
	Requirements: 12.1"""
	if is_active:
		return false
	
	# Check if generator needs repair
	if requires_repair:
		return false
	
	# Check failure state
	if failure_state != FailureState.OPERATIONAL and failure_state != FailureState.FUEL_DEPLETED:
		return false
	
	# Check if we have fuel (except geothermal)
	if generator_type != GeneratorType.GEOTHERMAL and current_fuel <= 0:
		failure_state = FailureState.FUEL_DEPLETED
		return false
	
	is_active = true
	failure_state = FailureState.OPERATIONAL
	
	if generator_type == GeneratorType.GEOTHERMAL:
		current_power_output = base_power_output * thermal_energy_level
	else:
		current_power_output = base_power_output
	
	power_production = current_power_output
	power_output_changed.emit(current_power_output)
	
	return true


func stop_generator() -> void:
	"""Stop the generator"""
	_shutdown()


func _shutdown() -> void:
	"""Internal shutdown"""
	is_active = false
	current_power_output = 0.0
	power_production = 0.0
	power_output_changed.emit(0.0)


func add_fuel(fuel_type: String, amount: int) -> int:
	"""Add fuel to the generator"""
	var accepted: Array = accepted_fuels.get(generator_type, [])
	
	if not fuel_type in accepted:
		return 0  # Wrong fuel type
	
	var space_available: int = max_fuel_capacity - current_fuel
	var amount_to_add: int = min(amount, space_available)
	
	current_fuel += amount_to_add
	fuel_added.emit(fuel_type, amount_to_add)
	
	return amount_to_add


func get_fuel_percentage() -> float:
	"""Get fuel level as percentage"""
	return (float(current_fuel) / float(max_fuel_capacity)) * 100.0


func is_fuel_accepted(fuel_type: String) -> bool:
	"""Check if a fuel type is accepted"""
	var accepted: Array = accepted_fuels.get(generator_type, [])
	return fuel_type in accepted


func get_accepted_fuel_types() -> Array:
	"""Get list of accepted fuel types"""
	return accepted_fuels.get(generator_type, [])


func repair_generator(repair_amount: float) -> bool:
	"""Repair the generator
	Requirements: 39.1, 39.2, 39.3, 39.4, 39.5
	Returns true if repair is complete"""
	
	if not requires_repair:
		return true
	
	repair_progress += repair_amount
	
	# Repair complete?
	if repair_progress >= 100.0:
		requires_repair = false
		repair_progress = 0.0
		failure_state = FailureState.OPERATIONAL
		
		# Restore some health
		health = min(health + 30.0, max_health)
		
		generator_repaired.emit()
		return true
	
	return false


func get_failure_state_name() -> String:
	"""Get human-readable failure state name"""
	match failure_state:
		FailureState.OPERATIONAL:
			return "Operational"
		FailureState.OVERHEATING:
			return "Overheating"
		FailureState.FUEL_DEPLETED:
			return "Fuel Depleted"
		FailureState.DAMAGED:
			return "Damaged"
		FailureState.CRITICAL_FAILURE:
			return "Critical Failure"
	return "Unknown"


func get_generator_type_name() -> String:
	"""Get human-readable generator type name"""
	match generator_type:
		GeneratorType.BIOMASS:
			return "Biomass Generator"
		GeneratorType.COAL:
			return "Coal Generator"
		GeneratorType.FUEL:
			return "Fuel Generator"
		GeneratorType.GEOTHERMAL:
			return "Geothermal Generator"
		GeneratorType.NUCLEAR:
			return "Nuclear Generator"
	return "Unknown Generator"


func deplete_thermal_vent() -> void:
	"""Deplete the thermal vent (for geothermal generators)
	Requirements: 39.4"""
	if generator_type == GeneratorType.GEOTHERMAL:
		thermal_energy_level *= 0.5  # Reduce to 50%
		thermal_energy_level = max(0.1, thermal_energy_level)


func save_state() -> Dictionary:
	var data := super.save_state()
	data["generator_type"] = generator_type
	data["current_fuel"] = current_fuel
	data["is_active"] = is_active
	data["current_power_output"] = current_power_output
	data["failure_state"] = failure_state
	data["thermal_energy_level"] = thermal_energy_level
	data["requires_repair"] = requires_repair
	data["repair_progress"] = repair_progress
	return data


func load_state(data: Dictionary) -> void:
	super.load_state(data)
	generator_type = data.get("generator_type", GeneratorType.BIOMASS)
	current_fuel = data.get("current_fuel", 0)
	is_active = data.get("is_active", false)
	current_power_output = data.get("current_power_output", 0.0)
	failure_state = data.get("failure_state", FailureState.OPERATIONAL)
	thermal_energy_level = data.get("thermal_energy_level", 1.0)
	requires_repair = data.get("requires_repair", false)
	repair_progress = data.get("repair_progress", 0.0)
	power_production = current_power_output
