## BaseModule - Represents a modular base structure component
## Requirements: 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5

class_name BaseModule
extends Node3D

enum ModuleType {
	HABITAT,      # Living quarters with life support
	STORAGE,      # Resource storage container
	FABRICATOR,   # Crafting station
	GENERATOR,    # Power generation
	OXYGEN,       # Oxygen generation and distribution
	AIRLOCK       # Entry/exit with pressure management
}

signal module_damaged(damage_amount: float)
signal module_destroyed()
signal module_connected(other_module: BaseModule)
signal module_disconnected(other_module: BaseModule)

enum PowerPriority {
	CRITICAL = 0,   # Life support, oxygen
	HIGH = 1,       # Fabricators, important machines
	MEDIUM = 2,     # Conveyors, automation
	LOW = 3         # Lighting, decorative
}

## Module properties
@export var module_type: ModuleType = ModuleType.HABITAT
@export var max_health: float = 100.0
@export var power_consumption: float = 10.0  # Watts
@export var power_production: float = 0.0    # Watts (for generators)
@export var power_priority: PowerPriority = PowerPriority.MEDIUM  # Power distribution priority
@export var oxygen_production: float = 0.0   # Units per second (for oxygen generators)
@export var storage_capacity: int = 0        # Number of item slots (for storage)
@export var structural_strength: float = 100.0  # Load-bearing capacity

## State
var health: float = 100.0
var is_powered: bool = false
var is_pressurized: bool = false
var connected_modules: Array[BaseModule] = []
var module_id: int = -1  # Unique identifier

## Visual components
var hologram_material: StandardMaterial3D = null
var valid_placement_color: Color = Color(0.0, 1.0, 0.0, 0.5)  # Green
var invalid_placement_color: Color = Color(1.0, 0.0, 0.0, 0.5)  # Red
var is_preview: bool = false

## Collision and mesh
var collision_shape: CollisionShape3D = null
var mesh_instance: MeshInstance3D = null


func _ready() -> void:
	health = max_health
	_setup_visuals()


func _setup_visuals() -> void:
	# Create mesh instance if not already present
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
		_create_module_mesh()
	
	# Create collision shape if not already present
	if not collision_shape:
		var static_body := StaticBody3D.new()
		collision_shape = CollisionShape3D.new()
		static_body.add_child(collision_shape)
		add_child(static_body)
		_create_collision_shape()


func _create_module_mesh() -> void:
	# Create a basic box mesh for the module
	# In a real implementation, this would load proper 3D models
	var box_mesh := BoxMesh.new()
	
	match module_type:
		ModuleType.HABITAT:
			box_mesh.size = Vector3(4.0, 3.0, 4.0)
		ModuleType.STORAGE:
			box_mesh.size = Vector3(3.0, 3.0, 3.0)
		ModuleType.FABRICATOR:
			box_mesh.size = Vector3(2.0, 2.5, 2.0)
		ModuleType.GENERATOR:
			box_mesh.size = Vector3(2.5, 2.0, 2.5)
		ModuleType.OXYGEN:
			box_mesh.size = Vector3(2.0, 3.0, 2.0)
		ModuleType.AIRLOCK:
			box_mesh.size = Vector3(2.0, 3.0, 3.0)
	
	mesh_instance.mesh = box_mesh
	
	# Set material
	if is_preview:
		_create_hologram_material()
		mesh_instance.material_override = hologram_material
	else:
		_create_standard_material()


func _create_collision_shape() -> void:
	var box_shape := BoxShape3D.new()
	
	match module_type:
		ModuleType.HABITAT:
			box_shape.size = Vector3(4.0, 3.0, 4.0)
		ModuleType.STORAGE:
			box_shape.size = Vector3(3.0, 3.0, 3.0)
		ModuleType.FABRICATOR:
			box_shape.size = Vector3(2.0, 2.5, 2.0)
		ModuleType.GENERATOR:
			box_shape.size = Vector3(2.5, 2.0, 2.5)
		ModuleType.OXYGEN:
			box_shape.size = Vector3(2.0, 3.0, 2.0)
		ModuleType.AIRLOCK:
			box_shape.size = Vector3(2.0, 3.0, 3.0)
	
	collision_shape.shape = box_shape


func _create_hologram_material() -> void:
	hologram_material = StandardMaterial3D.new()
	hologram_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hologram_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hologram_material.albedo_color = valid_placement_color


func _create_standard_material() -> void:
	var material := StandardMaterial3D.new()
	
	# Set color based on module type
	match module_type:
		ModuleType.HABITAT:
			material.albedo_color = Color(0.7, 0.7, 0.8)
		ModuleType.STORAGE:
			material.albedo_color = Color(0.6, 0.6, 0.6)
		ModuleType.FABRICATOR:
			material.albedo_color = Color(0.8, 0.6, 0.4)
		ModuleType.GENERATOR:
			material.albedo_color = Color(0.9, 0.7, 0.2)
		ModuleType.OXYGEN:
			material.albedo_color = Color(0.4, 0.7, 0.9)
		ModuleType.AIRLOCK:
			material.albedo_color = Color(0.5, 0.5, 0.5)
	
	mesh_instance.material_override = material


## PUBLIC API

func set_preview_mode(enabled: bool) -> void:
	"""Enable or disable holographic preview mode"""
	is_preview = enabled
	if mesh_instance:
		if enabled:
			_create_hologram_material()
			mesh_instance.material_override = hologram_material
		else:
			_create_standard_material()


func set_placement_valid(valid: bool) -> void:
	"""Update preview color based on placement validity"""
	if not is_preview or not hologram_material:
		return
	
	if valid:
		hologram_material.albedo_color = valid_placement_color
	else:
		hologram_material.albedo_color = invalid_placement_color


func take_damage(amount: float) -> void:
	"""Apply damage to the module
	
	Requirements: 20.2"""
	health -= amount
	health = max(0.0, health)
	
	module_damaged.emit(amount)
	
	if health <= 0.0:
		destroy()


func repair(amount: float) -> void:
	"""Repair the module"""
	health += amount
	health = min(max_health, health)


func is_destroyed() -> bool:
	"""Check if the module is destroyed
	
	Requirements: 20.3"""
	return health <= 0.0


func destroy() -> void:
	"""Destroy the module
	
	Requirements: 20.3"""
	# Disconnect from all connected modules
	for module in connected_modules.duplicate():
		disconnect_from_module(module)
	
	module_destroyed.emit()
	queue_free()


func connect_to_module(other: BaseModule) -> bool:
	"""Connect this module to another module"""
	if other in connected_modules:
		return false  # Already connected
	
	connected_modules.append(other)
	
	# Ensure bidirectional connection
	if not self in other.connected_modules:
		other.connected_modules.append(self)
		other.module_connected.emit(self)
	
	module_connected.emit(other)
	return true


func disconnect_from_module(other: BaseModule) -> bool:
	"""Disconnect this module from another module"""
	if not other in connected_modules:
		return false  # Not connected
	
	connected_modules.erase(other)
	
	# Ensure bidirectional disconnection
	if self in other.connected_modules:
		other.connected_modules.erase(self)
		other.module_disconnected.emit(self)
	
	module_disconnected.emit(other)
	return true


func is_connected_to(other: BaseModule) -> bool:
	"""Check if this module is connected to another"""
	return other in connected_modules


func get_connection_count() -> int:
	"""Get the number of connected modules"""
	return connected_modules.size()


func set_powered(powered: bool) -> void:
	"""Set the powered state of the module"""
	is_powered = powered


func set_pressurized(pressurized: bool) -> void:
	"""Set the pressurized state of the module"""
	is_pressurized = pressurized


func get_bounds() -> AABB:
	"""Get the bounding box of the module"""
	if mesh_instance and mesh_instance.mesh:
		return mesh_instance.get_aabb()
	return AABB()


func get_module_type_name() -> String:
	"""Get the human-readable name of the module type"""
	match module_type:
		ModuleType.HABITAT:
			return "Habitat"
		ModuleType.STORAGE:
			return "Storage"
		ModuleType.FABRICATOR:
			return "Fabricator"
		ModuleType.GENERATOR:
			return "Generator"
		ModuleType.OXYGEN:
			return "Oxygen Generator"
		ModuleType.AIRLOCK:
			return "Airlock"
	return "Unknown"


func save_state() -> Dictionary:
	"""Save the module state"""
	return {
		"module_type": module_type,
		"position": global_position,
		"rotation": global_rotation,
		"health": health,
		"is_powered": is_powered,
		"is_pressurized": is_pressurized,
		"module_id": module_id,
		"connected_module_ids": connected_modules.map(func(m): return m.module_id)
	}


func load_state(data: Dictionary) -> void:
	"""Load the module state"""
	module_type = data.get("module_type", ModuleType.HABITAT)
	global_position = data.get("position", Vector3.ZERO)
	global_rotation = data.get("rotation", Vector3.ZERO)
	health = data.get("health", max_health)
	is_powered = data.get("is_powered", false)
	is_pressurized = data.get("is_pressurized", false)
	module_id = data.get("module_id", -1)
	# Note: connected_module_ids will be restored by BaseBuildingSystem
