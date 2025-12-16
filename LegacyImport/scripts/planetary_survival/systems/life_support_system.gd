class_name LifeSupportSystem
extends Node

## Life support management system
## Manages oxygen production, temperature, and atmospheric conditions

signal oxygen_level_changed(current: float, max: float)
signal temperature_changed(current: float)

var oxygen_level: float = 100.0
var max_oxygen: float = 100.0
var temperature: float = 20.0 # Celsius

func _ready():
	print("[LifeSupportSystem] Initialized")

func produce_oxygen(amount: float) -> void:
	oxygen_level = min(max_oxygen, oxygen_level + amount)
	oxygen_level_changed.emit(oxygen_level, max_oxygen)

func consume_oxygen(amount: float) -> void:
	oxygen_level = max(0.0, oxygen_level - amount)
	oxygen_level_changed.emit(oxygen_level, max_oxygen)

func has_oxygen() -> bool:
	return oxygen_level > 0.0

func set_temperature(new_temp: float) -> void:
	temperature = new_temp
	temperature_changed.emit(temperature)
