class_name Constructor
extends ProductionMachine

## Construction machine for basic components
## Builds simple parts from raw materials

var construction_rate: float = 0.5 # units per second

func _ready():
	super._ready()
	machine_name = "Constructor"
	machine_type = MachineType.CONSTRUCTOR
	power_consumption = 20.0
