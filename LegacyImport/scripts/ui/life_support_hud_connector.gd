extends Node
class_name LifeSupportHUDConnector

## Connects LifeSupportSystem signals to HUD displays
##
## This connector acts as a bridge between the LifeSupportSystem and future HUD components.
## It listens to life support signals and re-emits them in a format suitable for UI displays.
##
## Usage:
##   var connector = LifeSupportHUDConnector.new()
##   connector.connect_to_life_support(life_support_system)
##   connector.oxygen_display_update.connect(_on_oxygen_ui_update)
##   connector.temperature_display_update.connect(_on_temperature_ui_update)

## Emitted when oxygen levels change. Parameters: current oxygen, max oxygen capacity
signal oxygen_display_update(current: float, max: float)

## Emitted when temperature changes. Parameter: current temperature in Kelvin
signal temperature_display_update(temp: float)

## Connects this connector to a LifeSupportSystem instance
## @param life_support: The LifeSupportSystem to connect to
func connect_to_life_support(life_support: LifeSupportSystem) -> void:
	if life_support:
		life_support.oxygen_level_changed.connect(_on_oxygen_changed)
		life_support.temperature_changed.connect(_on_temperature_changed)
		print("[LifeSupportHUDConnector] Connected to LifeSupportSystem")
	else:
		push_error("[LifeSupportHUDConnector] Cannot connect to null LifeSupportSystem")

## Disconnects from a LifeSupportSystem instance
## @param life_support: The LifeSupportSystem to disconnect from
func disconnect_from_life_support(life_support: LifeSupportSystem) -> void:
	if life_support:
		if life_support.oxygen_level_changed.is_connected(_on_oxygen_changed):
			life_support.oxygen_level_changed.disconnect(_on_oxygen_changed)
		if life_support.temperature_changed.is_connected(_on_temperature_changed):
			life_support.temperature_changed.disconnect(_on_temperature_changed)
		print("[LifeSupportHUDConnector] Disconnected from LifeSupportSystem")

## Internal handler for oxygen level changes
func _on_oxygen_changed(current: float, max: float) -> void:
	oxygen_display_update.emit(current, max)

## Internal handler for temperature changes
func _on_temperature_changed(temp: float) -> void:
	temperature_display_update.emit(temp)
