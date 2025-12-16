class_name CraftingSystem
extends Node

## Crafting system manager
## Manages crafting recipes and fabrication operations

var recipes: Dictionary = {} # {recipe_id: CraftingRecipe}

func register_recipe(recipe: CraftingRecipe) -> void:
	recipes[recipe.recipe_id] = recipe

func get_recipe(recipe_id: String) -> CraftingRecipe:
	return recipes.get(recipe_id, null)

func can_craft(recipe_id: String, available_resources: Dictionary) -> bool:
	var recipe = get_recipe(recipe_id)
	if not recipe:
		return false
	return recipe.can_craft(available_resources)

func craft(recipe_id: String, available_resources: Dictionary) -> Dictionary:
	var recipe = get_recipe(recipe_id)
	if not recipe or not recipe.can_craft(available_resources):
		return {"success": false, "error": "Cannot craft - missing resources"}

	# Consume resources (stub - actual implementation would modify inventory)
	return {"success": true, "output_item": recipe.output_item, "output_quantity": recipe.output_quantity}
