class_name PowerGridSystem
extends Node

## Power grid management system
## Manages power generation, distribution, and consumption

signal power_changed(current_power: float, max_power: float)

var total_generation: float = 0.0
var total_consumption: float = 0.0
var max_power_capacity: float = 1000.0

func _ready():
	print("[PowerGridSystem] Initialized")

func register_generator(power_output: float) -> void:
	total_generation += power_output
	power_changed.emit(get_available_power(), max_power_capacity)

func unregister_generator(power_output: float) -> void:
	total_generation -= power_output
	power_changed.emit(get_available_power(), max_power_capacity)

func register_consumer(power_draw: float) -> void:
	total_consumption += power_draw

func unregister_consumer(power_draw: float) -> void:
	total_consumption -= power_draw

func get_available_power() -> float:
	return max(0.0, total_generation - total_consumption)

func has_power() -> bool:
	return get_available_power() > 0.0
