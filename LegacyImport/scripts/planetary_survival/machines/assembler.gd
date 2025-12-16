class_name Assembler
extends ProductionMachine

## Assembly machine for complex components
## Combines multiple parts into finished products

var assembly_rate: float = 0.3 # units per second

func _ready():
	super._ready()
	machine_name = "Assembler"
	machine_type = MachineType.ASSEMBLER
	power_consumption = 30.0
