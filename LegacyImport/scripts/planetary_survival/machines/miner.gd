class_name Miner
extends ProductionMachine

## Mining machine for extracting resources
## Extracts raw materials from resource nodes

var mining_rate: float = 1.0 # units per second
var target_resource_node: Node = null

func _ready():
	super._ready()
	machine_name = "Miner"
	machine_type = MachineType.MINER
	power_consumption = 15.0

func set_target(node: Node) -> void:
	target_resource_node = node

func mine() -> Dictionary:
	if not is_operating or not is_powered:
		return {"success": false, "error": "Machine not operating"}
	if not target_resource_node:
		return {"success": false, "error": "No target set"}

	# Stub - actual implementation would extract from ResourceNode
	return {"success": true, "resource_type": "ore", "amount": mining_rate}
