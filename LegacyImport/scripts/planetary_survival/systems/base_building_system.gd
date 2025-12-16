## BaseBuildingSystem - Handles modular structure placement and connections
## Requirements: 5.1-5.5, 6.1-6.5, 47.1-47.5

class_name BaseBuildingSystem
extends Node

signal module_placed(module: BaseModule)
signal module_removed(module: BaseModule)
signal placement_invalid(reason: String)
signal network_updated()

## System references
var voxel_terrain: StubVoxelTerrain = null
var power_grid_system: PowerGridSystem = null
var life_support_system: LifeSupportSystem = null
var inventory_manager = null  # TODO: Type as InventoryManager when implemented

## State
var placed_structures: Array[BaseModule] = []
var structure_networks: Array[Dictionary] = []  # Power, oxygen, data networks
var next_module_id: int = 0

## Preview state
var preview_module: BaseModule = null
var is_placing: bool = false

## Placement settings
@export var placement_snap_distance: float = 0.5  # Snap to grid
@export var connection_distance: float = 5.0     # Max distance for auto-connection
@export var min_placement_distance: float = 1.0  # Min distance from other modules

## Module costs (resource_id -> quantity)
var module_costs: Dictionary = {
	BaseModule.ModuleType.HABITAT: {"metal": 50, "plastic": 30},
	BaseModule.ModuleType.STORAGE: {"metal": 30, "plastic": 20},
	BaseModule.ModuleType.FABRICATOR: {"metal": 40, "electronics": 20},
	BaseModule.ModuleType.GENERATOR: {"metal": 60, "electronics": 30},
	BaseModule.ModuleType.OXYGEN: {"metal": 40, "electronics": 25},
	BaseModule.ModuleType.AIRLOCK: {"metal": 35, "plastic": 25}
}


func _ready() -> void:
	pass


## PLACEMENT SYSTEM

func start_placement(module_type: BaseModule.ModuleType) -> BaseModule:
	"""Start placing a module with holographic preview"""
	if is_placing and preview_module:
		cancel_placement()
	
	# Create preview module
	preview_module = BaseModule.new()
	preview_module.module_type = module_type
	preview_module.module_id = -1  # Preview has no ID
	preview_module.set_preview_mode(true)
	add_child(preview_module)
	
	is_placing = true
	return preview_module


func update_placement_preview(position: Vector3, rotation: Quaternion) -> bool:
	"""Update preview position and validate placement"""
	if not is_placing or not preview_module:
		return false
	
	# Snap to grid
	var snapped_pos := _snap_to_grid(position)
	preview_module.global_position = snapped_pos
	preview_module.quaternion = rotation
	
	# Validate placement
	var valid := validate_placement(preview_module, snapped_pos)
	preview_module.set_placement_valid(valid)
	
	return valid


func confirm_placement() -> BaseModule:
	"""Confirm placement and create actual module"""
	if not is_placing or not preview_module:
		return null
	
	var position := preview_module.global_position
	var rotation := preview_module.quaternion
	var module_type := preview_module.module_type
	
	# Validate one more time
	if not validate_placement(preview_module, position):
		placement_invalid.emit("Invalid placement location")
		return null
	
	# Check resource costs
	if not _check_and_consume_resources(module_type):
		placement_invalid.emit("Insufficient resources")
		return null
	
	# Remove preview
	preview_module.queue_free()
	preview_module = null
	is_placing = false
	
	# Create actual module
	var module := _create_module(module_type, position, rotation)
	return module


func cancel_placement() -> void:
	"""Cancel current placement"""
	if preview_module:
		preview_module.queue_free()
		preview_module = null
	is_placing = false


func validate_placement(module: BaseModule, position: Vector3) -> bool:
	"""Validate if a module can be placed at the given position
	Requirements: 6.2, 6.3"""
	
	# Check if position is inside terrain (invalid)
	if voxel_terrain:
		var density := voxel_terrain.get_voxel_density(position)
		if density > 0.5:  # Inside solid terrain
			return false
	
	# Check minimum distance from other modules
	for existing_module in placed_structures:
		var distance := position.distance_to(existing_module.global_position)
		if distance < min_placement_distance:
			return false
	
	# Check if module would intersect with other modules
	var module_bounds := module.get_bounds()
	module_bounds.position += position
	
	for existing_module in placed_structures:
		var existing_bounds := existing_module.get_bounds()
		existing_bounds.position += existing_module.global_position
		
		if module_bounds.intersects(existing_bounds):
			return false
	
	# Check structural integrity (basic check)
	if not _check_structural_support(position):
		return false
	
	return true


func place_module(module_type: BaseModule.ModuleType, position: Vector3, rotation: Quaternion = Quaternion.IDENTITY) -> BaseModule:
	"""Place a module directly without preview
	Requirements: 6.1, 6.4"""
	
	# Create temporary module for validation
	var temp_module := BaseModule.new()
	temp_module.module_type = module_type
	
	if not validate_placement(temp_module, position):
		temp_module.free()
		placement_invalid.emit("Invalid placement location")
		return null
	
	temp_module.free()
	
	# Check and consume resources
	if not _check_and_consume_resources(module_type):
		placement_invalid.emit("Insufficient resources")
		return null
	
	# Create actual module
	return _create_module(module_type, position, rotation)


func remove_module(module: BaseModule) -> bool:
	"""Remove a placed module"""
	if not module in placed_structures:
		return false
	
	placed_structures.erase(module)
	module_removed.emit(module)
	
	# Disconnect from networks
	_disconnect_module_from_networks(module)
	
	# Destroy module
	module.destroy()
	
	return true


## MODULE CONNECTION SYSTEM

func connect_adjacent_modules(new_module: BaseModule) -> void:
	"""Auto-connect adjacent modules
	Requirements: 6.5"""
	
	for existing_module in placed_structures:
		if existing_module == new_module:
			continue
		
		var distance := new_module.global_position.distance_to(existing_module.global_position)
		
		if distance <= connection_distance:
			# Connect modules
			new_module.connect_to_module(existing_module)
			
			# Update networks
			_update_networks_for_connection(new_module, existing_module)


func disconnect_module(module: BaseModule) -> void:
	"""Disconnect a module from all connections"""
	for connected in module.connected_modules.duplicate():
		module.disconnect_from_module(connected)
		_update_networks_for_disconnection(module, connected)


## NETWORK MANAGEMENT

func _update_networks_for_connection(module_a: BaseModule, module_b: BaseModule) -> void:
	"""Update power, oxygen, and data networks when modules connect
	Requirements: 6.5"""
	
	# Find or create networks for both modules
	var network_a := _find_network_for_module(module_a)
	var network_b := _find_network_for_module(module_b)
	
	if network_a and network_b and network_a != network_b:
		# Merge networks
		_merge_networks(network_a, network_b)
	elif network_a:
		# Add module_b to network_a
		network_a["modules"].append(module_b)
	elif network_b:
		# Add module_a to network_b
		network_b["modules"].append(module_a)
	else:
		# Create new network
		var new_network := {
			"modules": [module_a, module_b],
			"has_power": false,
			"has_oxygen": false
		}
		structure_networks.append(new_network)
	
	_recalculate_networks()
	network_updated.emit()


func _update_networks_for_disconnection(module_a: BaseModule, module_b: BaseModule) -> void:
	"""Update networks when modules disconnect"""
	var network := _find_network_for_module(module_a)
	if not network:
		return
	
	# Check if network should split
	if not _are_modules_connected_through_network(module_a, module_b):
		_split_network(network)
	
	_recalculate_networks()
	network_updated.emit()


func _find_network_for_module(module: BaseModule) -> Dictionary:
	"""Find the network containing a module"""
	for network in structure_networks:
		if module in network["modules"]:
			return network
	return {}


func _merge_networks(network_a: Dictionary, network_b: Dictionary) -> void:
	"""Merge two networks"""
	for module in network_b["modules"]:
		if not module in network_a["modules"]:
			network_a["modules"].append(module)
	
	structure_networks.erase(network_b)


func _split_network(network: Dictionary) -> void:
	"""Split a network into separate connected components"""
	var modules: Array = network["modules"]
	if modules.is_empty():
		return
	
	# Use BFS to find connected components
	var visited: Array[BaseModule] = []
	var new_networks: Array[Dictionary] = []
	
	for module in modules:
		if module in visited:
			continue
		
		# BFS from this module
		var component: Array[BaseModule] = []
		var queue: Array[BaseModule] = [module]
		
		while not queue.is_empty():
			var current: BaseModule = queue.pop_front()
			if current in visited:
				continue
			
			visited.append(current)
			component.append(current)
			
			# Add connected modules that are in the network
			for connected in current.connected_modules:
				if connected in modules and not connected in visited:
					queue.append(connected)
		
		# Create new network for this component
		if not component.is_empty():
			new_networks.append({
				"modules": component,
				"has_power": false,
				"has_oxygen": false
			})
	
	# Remove old network and add new ones
	structure_networks.erase(network)
	structure_networks.append_array(new_networks)


func _are_modules_connected_through_network(module_a: BaseModule, module_b: BaseModule) -> bool:
	"""Check if two modules are still connected through other modules"""
	var visited: Array[BaseModule] = []
	var queue: Array[BaseModule] = [module_a]
	
	while not queue.is_empty():
		var current: BaseModule = queue.pop_front()
		if current in visited:
			continue
		
		if current == module_b:
			return true
		
		visited.append(current)
		
		for connected in current.connected_modules:
			if not connected in visited:
				queue.append(connected)
	
	return false


func _recalculate_networks() -> void:
	"""Recalculate network properties (power, oxygen)"""
	for network in structure_networks:
		var has_power := false
		var has_oxygen := false
		
		for module in network["modules"]:
			if module.power_production > 0.0:
				has_power = true
			if module.oxygen_production > 0.0:
				has_oxygen = true
		
		network["has_power"] = has_power
		network["has_oxygen"] = has_oxygen
		
		# Update module states
		for module in network["modules"]:
			module.set_powered(has_power)
			module.set_pressurized(has_oxygen)


func _disconnect_module_from_networks(module: BaseModule) -> void:
	"""Remove a module from all networks"""
	for network in structure_networks:
		if module in network["modules"]:
			network["modules"].erase(module)
			
			# Remove empty networks
			if network["modules"].is_empty():
				structure_networks.erase(network)
			else:
				# Check if network needs to split
				_split_network(network)


## STRUCTURAL INTEGRITY

signal structural_collapse(modules: Array[BaseModule])
signal structural_warning(module: BaseModule, integrity: float)

## Structural settings
@export var integrity_check_interval: float = 1.0  # Check every second
@export var collapse_threshold: float = 0.3        # Collapse below 30% integrity
@export var warning_threshold: float = 0.5         # Warn below 50% integrity
@export var max_unsupported_distance: float = 10.0 # Max distance from ground support

var integrity_check_timer: float = 0.0
var module_integrity_cache: Dictionary = {}  # module_id -> integrity value


func _process(delta: float) -> void:
	"""Update structural integrity checks"""
	integrity_check_timer += delta
	
	if integrity_check_timer >= integrity_check_interval:
		integrity_check_timer = 0.0
		_check_all_structural_integrity()


func _check_all_structural_integrity() -> void:
	"""Check structural integrity for all modules
	Requirements: 47.1, 47.2, 47.3"""
	
	var modules_to_collapse: Array[BaseModule] = []
	
	for module in placed_structures:
		var integrity := calculate_structural_integrity(module)
		module_integrity_cache[module.module_id] = integrity
		
		# Check for collapse
		if integrity < collapse_threshold:
			modules_to_collapse.append(module)
		elif integrity < warning_threshold:
			structural_warning.emit(module, integrity)
	
	# Trigger collapse for unstable modules
	if not modules_to_collapse.is_empty():
		_trigger_collapse(modules_to_collapse)


func _check_structural_support(position: Vector3) -> bool:
	"""Check if position has adequate structural support
	Requirements: 5.2, 47.1"""
	
	# For now, simple check: must be on or near terrain
	if not voxel_terrain:
		return true
	
	# Check if there's terrain below (within max distance)
	var step := 0.5
	var checks := int(max_unsupported_distance / step)
	
	for i in range(checks):
		var check_pos := position - Vector3(0, i * step, 0)
		var density := voxel_terrain.get_voxel_density(check_pos)
		if density > 0.5:  # Found solid terrain
			return true
	
	return false


func calculate_structural_integrity(module: BaseModule) -> float:
	"""Calculate structural integrity for a module
	Requirements: 5.2, 47.1, 47.2"""
	
	var integrity := 1.0
	
	# Factor 1: Ground support (40% weight)
	var has_ground_support := _has_ground_support_path(module)
	if not has_ground_support:
		integrity *= 0.4  # Severe penalty for no ground support
	
	# Factor 2: Connection count (20% weight)
	var connection_factor: float = min(1.0, module.get_connection_count() / 4.0)
	integrity *= (0.8 + connection_factor * 0.2)
	
	# Factor 3: Module health (20% weight)
	var health_factor := module.health / module.max_health
	integrity *= (0.8 + health_factor * 0.2)
	
	# Factor 4: Load bearing (20% weight)
	var load_factor := _calculate_load_factor(module)
	integrity *= (0.8 + load_factor * 0.2)
	
	return clamp(integrity, 0.0, 1.0)


func _has_ground_support_path(module: BaseModule) -> bool:
	"""Check if module has a path to ground-supported module
	Requirements: 47.1"""
	
	# Direct ground support
	if _check_structural_support(module.global_position):
		return true
	
	# Check if connected to a ground-supported module (BFS)
	var visited: Array[BaseModule] = []
	var queue: Array[BaseModule] = [module]
	var max_depth := 10  # Limit search depth
	var depth_map: Dictionary = {module: 0}
	
	while not queue.is_empty():
		var current: BaseModule = queue.pop_front()
		if current in visited:
			continue
		
		visited.append(current)
		var current_depth: int = depth_map.get(current, 0)
		
		if current_depth > max_depth:
			continue
		
		# Check if this module has ground support
		if current != module and _check_structural_support(current.global_position):
			return true
		
		# Add connected modules to queue
		for connected in current.connected_modules:
			if not connected in visited:
				queue.append(connected)
				depth_map[connected] = current_depth + 1
	
	return false


func _calculate_load_factor(module: BaseModule) -> float:
	"""Calculate load factor based on modules supported above
	Requirements: 47.1, 47.4"""
	
	# Count modules that depend on this module for support
	var supported_count := _count_supported_modules(module)
	
	# Calculate load factor (more supported modules = lower factor)
	var max_supported := 5.0  # Assume max 5 modules can be supported
	var load_factor := 1.0 - (supported_count / max_supported)
	
	return clamp(load_factor, 0.0, 1.0)


func _count_supported_modules(module: BaseModule) -> int:
	"""Count how many modules depend on this module for support"""
	
	var count := 0
	var visited: Array[BaseModule] = [module]
	var queue: Array[BaseModule] = []
	queue.assign(module.connected_modules)
	
	while not queue.is_empty():
		var current: BaseModule = queue.pop_front()
		if current in visited:
			continue
		
		visited.append(current)
		
		# Check if this module is above the original module
		if current.global_position.y > module.global_position.y:
			count += 1
			
			# Add its connections
			for connected in current.connected_modules:
				if not connected in visited:
					queue.append(connected)
	
	return count


func _trigger_collapse(modules: Array[BaseModule]) -> void:
	"""Trigger collapse for unstable modules
	Requirements: 47.2, 47.3"""
	
	# Find all modules that will collapse (including connected unsupported ones)
	var collapse_set: Array[BaseModule] = []
	
	for module in modules:
		if not module in collapse_set:
			collapse_set.append(module)
			
			# Find all modules that depend on this one
			var dependent := _find_dependent_modules(module)
			for dep in dependent:
				if not dep in collapse_set:
					collapse_set.append(dep)
	
	# Emit signal
	structural_collapse.emit(collapse_set)
	
	# Destroy collapsed modules
	for module in collapse_set:
		# Drop some resources
		_drop_module_resources(module)
		
		# Remove module
		remove_module(module)


func _find_dependent_modules(module: BaseModule) -> Array[BaseModule]:
	"""Find all modules that depend on this module for support"""
	
	var dependent: Array[BaseModule] = []
	var visited: Array[BaseModule] = [module]
	var queue: Array[BaseModule] = []
	queue.assign(module.connected_modules)
	
	while not queue.is_empty():
		var current: BaseModule = queue.pop_front()
		if current in visited:
			continue
		
		visited.append(current)
		
		# Check if this module would lose support without the original
		if not _would_have_support_without(current, module):
			dependent.append(current)
			
			# Add its connections
			for connected in current.connected_modules:
				if not connected in visited and connected != module:
					queue.append(connected)
	
	return dependent


func _would_have_support_without(module: BaseModule, excluded: BaseModule) -> bool:
	"""Check if module would have ground support without a specific module"""
	
	# Direct ground support
	if _check_structural_support(module.global_position):
		return true
	
	# Check path to ground support excluding the specified module
	var visited: Array[BaseModule] = [excluded]
	var queue: Array[BaseModule] = [module]
	var max_depth := 10
	var depth_map: Dictionary = {module: 0}
	
	while not queue.is_empty():
		var current: BaseModule = queue.pop_front()
		if current in visited:
			continue
		
		visited.append(current)
		var current_depth: int = depth_map.get(current, 0)
		
		if current_depth > max_depth:
			continue
		
		if current != module and _check_structural_support(current.global_position):
			return true
		
		for connected in current.connected_modules:
			if not connected in visited and connected != excluded:
				queue.append(connected)
				depth_map[connected] = current_depth + 1
	
	return false


func _drop_module_resources(module: BaseModule) -> void:
	"""Drop partial resources when module is destroyed"""
	
	# Get module costs
	var costs: Dictionary = module_costs.get(module.module_type, {})
	
	# Drop 50% of resources
	for resource_id in costs:
		var amount: int = costs[resource_id] / 2
		if amount > 0 and inventory_manager:
			# In a real implementation, this would spawn item pickups
			# For now, just add back to inventory
			inventory_manager.add_item(resource_id, amount)


## STRESS VISUALIZATION

func get_module_integrity(module: BaseModule) -> float:
	"""Get cached integrity value for a module
	Requirements: 47.5"""
	return module_integrity_cache.get(module.module_id, 1.0)


func get_stress_visualization_data() -> Array[Dictionary]:
	"""Get stress data for all modules for visualization
	Requirements: 47.5"""
	
	var data: Array[Dictionary] = []
	
	for module in placed_structures:
		var integrity := get_module_integrity(module)
		var stress_level := 1.0 - integrity
		
		data.append({
			"module": module,
			"integrity": integrity,
			"stress_level": stress_level,
			"position": module.global_position,
			"is_critical": integrity < warning_threshold
		})
	
	return data


func enable_stress_visualization(enabled: bool) -> void:
	"""Enable or disable stress visualization overlay
	Requirements: 47.5"""
	
	# This would be implemented with visual overlays in a real system
	# For now, just update module materials based on stress
	if enabled:
		for module in placed_structures:
			var integrity := get_module_integrity(module)
			_apply_stress_visual(module, integrity)
	else:
		for module in placed_structures:
			_clear_stress_visual(module)


func _apply_stress_visual(module: BaseModule, integrity: float) -> void:
	"""Apply visual indicator of stress level"""
	
	if not module.mesh_instance:
		return
	
	var stress_material := StandardMaterial3D.new()
	
	# Color based on integrity: green (good) -> yellow (warning) -> red (critical)
	if integrity >= warning_threshold:
		var t := (integrity - warning_threshold) / (1.0 - warning_threshold)
		stress_material.albedo_color = Color(1.0 - t * 0.5, 1.0, 0.0)  # Green to yellow
	else:
		var t := integrity / warning_threshold
		stress_material.albedo_color = Color(1.0, t, 0.0)  # Yellow to red
	
	stress_material.emission_enabled = true
	stress_material.emission = stress_material.albedo_color * 0.3
	
	module.mesh_instance.material_override = stress_material


func _clear_stress_visual(module: BaseModule) -> void:
	"""Clear stress visualization"""
	if module.mesh_instance:
		module._create_standard_material()


## HELPER FUNCTIONS

func _create_module(module_type: BaseModule.ModuleType, position: Vector3, rotation: Quaternion) -> BaseModule:
	"""Create and initialize a new module"""
	var module := BaseModule.new()
	module.module_type = module_type
	module.module_id = next_module_id
	next_module_id += 1
	
	add_child(module)
	module.global_position = position
	module.quaternion = rotation
	
	# Set module properties based on type
	match module_type:
		BaseModule.ModuleType.GENERATOR:
			module.power_production = 100.0
		BaseModule.ModuleType.OXYGEN:
			module.oxygen_production = 10.0
	
	placed_structures.append(module)
	
	# Connect to adjacent modules
	connect_adjacent_modules(module)
	
	module_placed.emit(module)
	
	return module


func _snap_to_grid(position: Vector3) -> Vector3:
	"""Snap position to placement grid"""
	return Vector3(
		round(position.x / placement_snap_distance) * placement_snap_distance,
		round(position.y / placement_snap_distance) * placement_snap_distance,
		round(position.z / placement_snap_distance) * placement_snap_distance
	)


func _check_and_consume_resources(module_type: BaseModule.ModuleType) -> bool:
	"""Check if player has resources and consume them
	Requirements: 6.4"""
	
	if not inventory_manager:
		return true  # No inventory system, allow placement
	
	var costs: Dictionary = module_costs.get(module_type, {})
	
	# Check if player has all required resources
	for resource_id in costs:
		var required: int = costs[resource_id]
		var available: int = inventory_manager.get_item_count(resource_id)
		
		if available < required:
			return false
	
	# Consume resources
	for resource_id in costs:
		var required: int = costs[resource_id]
		inventory_manager.remove_item(resource_id, required)
	
	return true


## PUBLIC API

func place_structure(structure_type: BaseModule.ModuleType, position: Vector3, rotation: Quaternion = Quaternion.IDENTITY) -> BaseModule:
	"""Place a structure at the specified position

	This is the main placement API that:
	- Validates the placement position (terrain check, no overlaps)
	- Checks and deducts required resources from inventory
	- Instantiates the structure node
	- Adds it to the scene tree
	- Auto-connects to adjacent structures

	Args:
		structure_type: The type of structure to place (from BaseModule.ModuleType enum)
		position: World position where the structure should be placed
		rotation: Rotation of the structure (defaults to identity/no rotation)

	Returns:
		The placed BaseModule instance, or null if placement failed

	Requirements: 6.1, 6.2, 6.3, 6.4"""

	# Create temporary module for validation
	var temp_module := BaseModule.new()
	temp_module.module_type = structure_type

	# Validate placement position (checks terrain and overlaps)
	if not validate_placement(temp_module, position):
		temp_module.free()
		placement_invalid.emit("Invalid placement location - position on terrain or overlapping existing structure")
		return null

	temp_module.free()

	# Check and consume resources
	if not _check_and_consume_resources(structure_type):
		placement_invalid.emit("Insufficient resources to build structure")
		return null

	# Create and place the actual structure
	var structure := _create_module(structure_type, position, rotation)

	return structure


func remove_structure(structure: BaseModule) -> bool:
	"""Remove a placed structure from the base

	This method:
	- Removes the structure from the placed structures list
	- Disconnects it from all connected structures
	- Updates the network connections
	- Destroys the structure node

	Args:
		structure: The BaseModule instance to remove

	Returns:
		true if removal was successful, false if structure was not found

	Requirements: 6.1"""

	if not structure in placed_structures:
		return false

	placed_structures.erase(structure)
	module_removed.emit(structure)

	# Disconnect from networks
	_disconnect_module_from_networks(structure)

	# Destroy structure
	structure.destroy()

	return true


func get_nearby_structures(position: Vector3, radius: float) -> Array[BaseModule]:
	"""Get all structures within a specified radius of a position

	This is useful for:
	- Collision checking before placement
	- Finding structures to connect to
	- Area-of-effect operations
	- Proximity-based gameplay mechanics

	Args:
		position: The center point to search from
		radius: The search radius in world units

	Returns:
		Array of BaseModule instances within the radius

	Requirements: 6.2, 6.3"""

	var nearby: Array[BaseModule] = []

	for structure in placed_structures:
		var distance := position.distance_to(structure.global_position)
		if distance <= radius:
			nearby.append(structure)

	return nearby


func get_placed_modules() -> Array[BaseModule]:
	"""Get all placed modules"""
	return placed_structures.duplicate()


func get_placed_structures() -> Array[BaseModule]:
	"""Get all placed structures (alias for get_placed_modules)"""
	return placed_structures.duplicate()


func get_module_by_id(module_id: int) -> BaseModule:
	"""Find a module by its ID"""
	for module in placed_structures:
		if module.module_id == module_id:
			return module
	return null


func get_modules_in_radius(position: Vector3, radius: float) -> Array[BaseModule]:
	"""Get all modules within a radius"""
	var result: Array[BaseModule] = []
	for module in placed_structures:
		if module.global_position.distance_to(position) <= radius:
			result.append(module)
	return result


func get_network_for_module(module: BaseModule) -> Dictionary:
	"""Get the network containing a module"""
	return _find_network_for_module(module)


func get_all_networks() -> Array[Dictionary]:
	"""Get all structure networks"""
	return structure_networks.duplicate()


## PERSISTENCE

func save_state() -> Dictionary:
	"""Save system state"""
	var modules_data: Array = []
	for module in placed_structures:
		modules_data.append(module.save_state())
	
	return {
		"modules": modules_data,
		"next_module_id": next_module_id
	}


func load_state(data: Dictionary) -> void:
	"""Load system state"""
	# Clear existing structures
	for module in placed_structures.duplicate():
		remove_module(module)
	
	next_module_id = data.get("next_module_id", 0)
	
	# Load modules
	var modules_data: Array = data.get("modules", [])
	var module_id_map: Dictionary = {}  # old_id -> module
	
	for module_data in modules_data:
		var module := BaseModule.new()
		module.load_state(module_data)
		add_child(module)
		placed_structures.append(module)
		module_id_map[module.module_id] = module
	
	# Restore connections
	for module_data in modules_data:
		var module_id: int = module_data.get("module_id", -1)
		var module: BaseModule = module_id_map.get(module_id)
		if not module:
			continue
		
		var connected_ids: Array = module_data.get("connected_module_ids", [])
		for connected_id in connected_ids:
			var connected_module: BaseModule = module_id_map.get(connected_id)
			if connected_module:
				module.connect_to_module(connected_module)
	
	# Rebuild networks
	structure_networks.clear()
	for module in placed_structures:
		if module.get_connection_count() > 0:
			var network := _find_network_for_module(module)
			if network.is_empty():
				# Create new network for this connected component
				var new_network := {
					"modules": [module],
					"has_power": false,
					"has_oxygen": false
				}
				structure_networks.append(new_network)
				
				# Add all connected modules
				var visited: Array[BaseModule] = [module]
				var queue: Array[BaseModule] = []
				queue.assign(module.connected_modules)
				
				while not queue.is_empty():
					var current: BaseModule = queue.pop_front()
					if current in visited:
						continue
					
					visited.append(current)
					new_network["modules"].append(current)
					
					for connected in current.connected_modules:
						if not connected in visited:
							queue.append(connected)
	
	_recalculate_networks()
