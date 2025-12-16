## Consumable - Represents a consumable item (food or water)
## Requirements: 16.5

class_name Consumable
extends Resource

enum ConsumableType {
	FOOD,   # Restores hunger
	WATER   # Restores thirst
}

## Consumable properties
@export var consumable_type: ConsumableType = ConsumableType.FOOD
@export var item_name: String = "Food"
@export var restoration_value: float = 20.0  # Amount to restore (0-100)
@export var consumption_time: float = 2.0    # Time to consume in seconds
@export var stack_size: int = 10             # Maximum stack size

## State
var current_stack: int = 1


func _init(type: ConsumableType = ConsumableType.FOOD, name: String = "Food", value: float = 20.0):
	consumable_type = type
	item_name = name
	restoration_value = value


## Consume the item
## @return Restoration value
## Requirements: 16.5
func consume() -> float:
	if current_stack > 0:
		current_stack -= 1
		return restoration_value
	return 0.0


## Check if consumable is depleted
func is_depleted() -> bool:
	return current_stack <= 0


## Add to stack
## @param amount: Amount to add
## @return Amount that couldn't be added (overflow)
func add_to_stack(amount: int) -> int:
	var space_available: int = stack_size - current_stack
	var amount_to_add: int = min(amount, space_available)
	current_stack += amount_to_add
	return amount - amount_to_add


## Get type name
func get_type_name() -> String:
	match consumable_type:
		ConsumableType.FOOD:
			return "Food"
		ConsumableType.WATER:
			return "Water"
	return "Unknown"


## Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"type": consumable_type,
		"name": item_name,
		"restoration_value": restoration_value,
		"consumption_time": consumption_time,
		"stack_size": stack_size,
		"current_stack": current_stack
	}


## Create from dictionary
static func from_dict(data: Dictionary) -> Consumable:
	var type: ConsumableType = data.get("type", ConsumableType.FOOD)
	var name: String = data.get("name", "Food")
	var value: float = data.get("restoration_value", 20.0)
	
	var consumable := Consumable.new(type, name, value)
	consumable.consumption_time = data.get("consumption_time", 2.0)
	consumable.stack_size = data.get("stack_size", 10)
	consumable.current_stack = data.get("current_stack", 1)
	
	return consumable


## Create predefined consumables
static func create_basic_food() -> Consumable:
	"""Create a basic food item."""
	return Consumable.new(ConsumableType.FOOD, "Ration", 25.0)


static func create_basic_water() -> Consumable:
	"""Create a basic water item."""
	return Consumable.new(ConsumableType.WATER, "Water Bottle", 30.0)


static func create_advanced_food() -> Consumable:
	"""Create an advanced food item."""
	var food := Consumable.new(ConsumableType.FOOD, "Nutrient Bar", 50.0)
	food.consumption_time = 1.0  # Faster consumption
	return food


static func create_advanced_water() -> Consumable:
	"""Create an advanced water item."""
	var water := Consumable.new(ConsumableType.WATER, "Purified Water", 60.0)
	water.consumption_time = 1.0  # Faster consumption
	return water
