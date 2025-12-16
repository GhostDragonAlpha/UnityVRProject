class_name Refinery
extends ProductionMachine

## Refinery machine for advanced processing
## Produces refined materials and fuels

var refining_rate: float = 0.6 # units per second

func _ready():
	super._ready()
	machine_name = "Refinery"
	machine_type = MachineType.REFINERY
	power_consumption = 35.0
