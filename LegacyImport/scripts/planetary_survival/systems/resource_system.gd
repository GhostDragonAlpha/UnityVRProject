## ResourceSystem - Manages resource types, nodes, and gathering
## Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 26.1, 26.2, 26.3, 26.4, 26.5

class_name ResourceSystem
extends Node

## Reference to voxel terrain (stub implementation)
var voxel_terrain: StubVoxelTerrain = null

## Resource type definitions: String -> ResourceDefinition
var resource_types: Dictionary = {}

## All active resource nodes
var resource_nodes: Array[ResourceNode] = []

## Procedural generation seed
var world_seed: int = 0

## Chunk size for resource spawning
const CHUNK_SIZE: int = 32


func _ready() -> void:
	_register_default_resources()


## Register default resource types
## Requirements: 3.1 - Define resource types
func _register_default_resources() -> void:
	# Common ores
	register_resource_type("iron", {
		"name": "Iron Ore",
		"stack_size": 100,
		"rarity": 0.3,
		"color": Color(0.5, 0.5, 0.5),
		"fragments_per_node": 10,
		"min_depth": 0.0,
		"max_depth": 1000.0,
		"biome_weights": {"default": 1.0}
	})
	
	register_resource_type("copper", {
		"name": "Copper Ore",
		"stack_size": 100,
		"rarity": 0.4,
		"color": Color(0.8, 0.4, 0.2),
		"fragments_per_node": 10,
		"min_depth": 0.0,
		"max_depth": 800.0,
		"biome_weights": {"default": 1.0}
	})
	
	# Rare crystals
	register_resource_type("crystal", {
		"name": "Energy Crystal",
		"stack_size": 50,
		"rarity": 0.1,
		"color": Color(0.2, 0.6, 1.0),
		"fragments_per_node": 5,
		"min_depth": 100.0,
		"max_depth": 2000.0,
		"biome_weights": {"cave": 2.0, "default": 0.5}
	})
	
	# Organic resources
	register_resource_type("organic", {
		"name": "Organic Matter",
		"stack_size": 200,
		"rarity": 0.5,
		"color": Color(0.3, 0.6, 0.2),
		"fragments_per_node": 15,
		"min_depth": 0.0,
		"max_depth": 50.0,
		"biome_weights": {"forest": 3.0, "default": 0.2}
	})
	
	# Rare resources
	register_resource_type("titanium", {
		"name": "Titanium Ore",
		"stack_size": 50,
		"rarity": 0.15,
		"color": Color(0.7, 0.7, 0.8),
		"fragments_per_node": 8,
		"min_depth": 200.0,
		"max_depth": 1500.0,
		"biome_weights": {"default": 1.0}
	})
	
	register_resource_type("uranium", {
		"name": "Uranium Ore",
		"stack_size": 25,
		"rarity": 0.05,
		"color": Color(0.2, 1.0, 0.2),
		"fragments_per_node": 5,
		"min_depth": 500.0,
		"max_depth": 3000.0,
		"biome_weights": {"radioactive": 5.0, "default": 0.1}
	})


## Register a new resource type
## Requirements: 3.1 - Define resource types
func register_resource_type(id: String, definition: Dictionary) -> void:
	resource_types[id] = definition
	print("ResourceSystem: Registered resource type '%s'" % id)


## Spawn a resource node at position
## Requirements: 3.2 - Implement procedural resource node spawning
func spawn_resource_node(position: Vector3, type: String, quantity: int) -> ResourceNode:
	if not resource_types.has(type):
		push_error("ResourceSystem: Unknown resource type '%s'" % type)
		return null
	
	var node: ResourceNode = ResourceNode.new(type, position, quantity)
	resource_nodes.append(node)
	
	# Embed in voxel terrain if available
	if voxel_terrain:
		_embed_resource_in_terrain(node)
	
	return node


## Procedurally generate resource nodes for a chunk
## Requirements: 3.2 - Implement procedural resource node spawning
func generate_resources_for_chunk(chunk_pos: Vector3i, biome: String = "default") -> Array[ResourceNode]:
	var generated_nodes: Array[ResourceNode] = []
	
	# Use chunk position and world seed for deterministic generation
	var chunk_seed: int = _get_chunk_seed(chunk_pos)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed
	
	# Calculate world position of chunk
	var world_pos: Vector3 = Vector3(chunk_pos) * CHUNK_SIZE
	var depth: float = abs(world_pos.y)  # Depth below surface
	
	# Try to spawn each resource type
	for resource_id in resource_types.keys():
		var def: Dictionary = resource_types[resource_id]
		
		# Check depth constraints
		if depth < def.get("min_depth", 0.0) or depth > def.get("max_depth", 10000.0):
			continue
		
		# Apply biome weight
		var biome_weights: Dictionary = def.get("biome_weights", {"default": 1.0})
		var biome_weight: float = biome_weights.get(biome, biome_weights.get("default", 1.0))
		
		# Calculate spawn probability
		var base_rarity: float = def.get("rarity", 0.1)
		var spawn_chance: float = base_rarity * biome_weight
		
		# Roll for spawn (1-3 nodes per chunk per resource type)
		var max_nodes: int = 3
		for i in range(max_nodes):
			if rng.randf() < spawn_chance:
				# Random position within chunk
				var local_x: float = rng.randf_range(2.0, CHUNK_SIZE - 2.0)
				var local_y: float = rng.randf_range(2.0, CHUNK_SIZE - 2.0)
				var local_z: float = rng.randf_range(2.0, CHUNK_SIZE - 2.0)
				var node_pos: Vector3 = world_pos + Vector3(local_x, local_y, local_z)
				
				# Random quantity (50-150% of base)
				var base_quantity: int = def.get("fragments_per_node", 10) * 10
				var quantity: int = int(rng.randf_range(base_quantity * 0.5, base_quantity * 1.5))
				
				# Spawn the node
				var node: ResourceNode = spawn_resource_node(node_pos, resource_id, quantity)
				if node:
					generated_nodes.append(node)
	
	return generated_nodes


## Embed a resource node in voxel terrain
## Requirements: 3.3 - Create resource node embedding in terrain
func _embed_resource_in_terrain(node: ResourceNode) -> void:
	if not voxel_terrain:
		return
	
	# Get resource definition
	var def: Dictionary = resource_types.get(node.resource_type, {})
	var color: Color = def.get("color", Color.WHITE)
	
	# Create a small sphere of higher-density voxels with resource marker
	var radius: float = 1.5
	var center: Vector3 = node.position
	
	# Mark voxels in a sphere around the node position
	for x in range(-2, 3):
		for y in range(-2, 3):
			for z in range(-2, 3):
				var offset: Vector3 = Vector3(x, y, z) * 0.5
				var pos: Vector3 = center + offset
				var dist: float = offset.length()
				
				if dist <= radius:
					# Set voxel density slightly higher to indicate resource
					var current_density: float = voxel_terrain.get_voxel_density(pos)
					if current_density > 0.3:  # Only embed in solid terrain
						voxel_terrain.set_voxel_density(pos, min(current_density + 0.2, 1.0))


## Get deterministic seed for chunk
func _get_chunk_seed(chunk_pos: Vector3i) -> int:
	# Combine world seed with chunk coordinates
	var hash_val: int = world_seed
	hash_val = (hash_val * 73856093) ^ chunk_pos.x
	hash_val = (hash_val * 19349663) ^ chunk_pos.y
	hash_val = (hash_val * 83492791) ^ chunk_pos.z
	return abs(hash_val)


## Gather resources from a node
func gather_resource(node: ResourceNode, amount: int) -> Dictionary:
	if node.is_depleted:
		return {}
	
	var extracted: int = node.extract(amount)
	return {"type": node.resource_type, "amount": extracted}


## Scan for resources in radius
func scan_for_resources(center: Vector3, radius: float) -> Array:
	var signatures: Array = []
	
	for node in resource_nodes:
		if node.is_depleted:
			continue
		
		var distance: float = node.position.distance_to(center)
		if distance <= radius:
			signatures.append({
				"type": node.resource_type,
				"position": node.position,
				"quantity": node.quantity,
				"distance": distance
			})
	
	return signatures


## INVENTORY MANAGEMENT
## TODO: Engineers implement full inventory system

func add_to_inventory(inventory: Dictionary, resource: String, amount: int) -> bool:
	if not inventory.has(resource):
		inventory[resource] = 0
	inventory[resource] += amount
	return true


func remove_from_inventory(inventory: Dictionary, resource: String, amount: int) -> bool:
	if not inventory.has(resource) or inventory[resource] < amount:
		return false
	inventory[resource] -= amount
	return true


func get_inventory_count(inventory: Dictionary, resource: String) -> int:
	return inventory.get(resource, 0)


## Save/Load
func save_state() -> Dictionary:
	var nodes_data: Array = []
	for node in resource_nodes:
		if not node.is_depleted:
			nodes_data.append(node.serialize())
	return {"resource_nodes": nodes_data}


func load_state(data: Dictionary) -> void:
	resource_nodes.clear()
	for node_data in data.get("resource_nodes", []):
		var node: ResourceNode = ResourceNode.deserialize(node_data)
		resource_nodes.append(node)
