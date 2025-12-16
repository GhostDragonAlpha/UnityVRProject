class_name ProductionMachine
extends Node3D

## Base class for all production machines
## Provides common functionality for mining, smelting, construction, etc.

enum MachineType {
	MINER,
	SMELTER,
	CONSTRUCTOR,
	ASSEMBLER,
	REFINERY,
	GENERIC
}

var machine_id: String = ""
var machine_name: String = "Production Machine"
var machine_type: MachineType = MachineType.GENERIC
var is_operating: bool = false
var is_powered: bool = false
var power_consumption: float = 10.0

func _ready():
	machine_id = str(get_instance_id())

func start_operation() -> void:
	if is_powered:
		is_operating = true

func stop_operation() -> void:
	is_operating = false

func shutdown() -> void:
	stop_operation()
	is_powered = false

func set_powered(powered: bool) -> void:
	is_powered = powered
	if not powered:
		stop_operation()

func save_state() -> Dictionary:
	return {
		"machine_id": machine_id,
		"machine_name": machine_name,
		"machine_type": machine_type,
		"is_operating": is_operating,
		"is_powered": is_powered
	}

func load_state(data: Dictionary) -> void:
	machine_id = data.get("machine_id", machine_id)
	machine_name = data.get("machine_name", machine_name)
	machine_type = data.get("machine_type", machine_type)
	is_operating = data.get("is_operating", false)
	is_powered = data.get("is_powered", false)
