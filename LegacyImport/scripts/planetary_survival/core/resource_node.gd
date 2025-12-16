class_name ResourceNode
extends Resource

## Resource node for planetary resource extraction
## Represents a mineable/harvestable resource location

var resource_type: String = ""
var position: Vector3 = Vector3.ZERO
var quantity: int = 0
var is_depleted: bool = false

func _init(type: String = "", pos: Vector3 = Vector3.ZERO, qty: int = 0):
	resource_type = type
	position = pos
	quantity = qty

## Extract resources from this node
func extract(amount: int) -> int:
	var extracted = min(amount, quantity)
	quantity -= extracted
	if quantity <= 0:
		is_depleted = true
	return extracted

## Serialize to dictionary for saving
func serialize() -> Dictionary:
	return {
		"resource_type": resource_type,
		"position": position,
		"quantity": quantity,
		"is_depleted": is_depleted
	}

## Deserialize from dictionary for loading
static func deserialize(data: Dictionary) -> ResourceNode:
	var node = ResourceNode.new(
		data.get("resource_type", ""),
		data.get("position", Vector3.ZERO),
		data.get("quantity", 0)
	)
	node.is_depleted = data.get("is_depleted", false)
	return node
