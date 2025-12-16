class_name Smelter
extends ProductionMachine

## Smelting machine for processing raw materials
## Converts ore into refined metals

var smelting_rate: float = 0.8 # units per second

func _ready():
	super._ready()
	machine_name = "Smelter"
	machine_type = MachineType.SMELTER
	power_consumption = 25.0
