class_name CraftingRecipe
extends Resource

## Crafting recipe definition for fabrication
## Defines required resources and output items

var recipe_id: String = ""
var required_resources: Dictionary = {} # {resource_type: quantity}
var output_item: String = ""
var output_quantity: int = 1
var crafting_time: float = 1.0

func _init(id: String = "", resources: Dictionary = {}, output: String = "", qty: int = 1, time: float = 1.0):
	recipe_id = id
	required_resources = resources
	output_item = output
	output_quantity = qty
	crafting_time = time

func can_craft(available_resources: Dictionary) -> bool:
	for resource_type in required_resources:
		if not available_resources.has(resource_type):
			return false
		if available_resources[resource_type] < required_resources[resource_type]:
			return false
	return true
