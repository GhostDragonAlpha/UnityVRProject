## SaveSystem - Game State Persistence
##
## Handles saving and loading game state to/from JSON files.
## Supports multiple save slots with automatic backup creation.
## Tracks discovered systems with coordinates and timestamps.
##
## Requirements: 38.1, 38.2, 38.3, 38.4, 38.5
## - 38.1: Serialize game state to JSON
## - 38.2: Store player position, velocity, SNR, entropy
## - 38.3: Restore celestial body positions to saved simulation time
## - 38.4: Display save metadata (location, time, date saved)
## - 38.5: Auto-save every 5 minutes

extends Node
class_name SaveSystem

## DiscoveredSystem data structure for tracking discovered star systems
class DiscoveredSystem:
	var system_name: String
	var coordinates: Vector3
	var timestamp: float

	func _init(name: String, coords: Vector3, time: float = 0.0) -> void:
		system_name = name
		coordinates = coords
		timestamp = time if time > 0 else Time.get_unix_time_from_system()

	## Convert to dictionary for JSON serialization
	func to_dict() -> Dictionary:
		return {
			"name": system_name,
			"coordinates": [coordinates.x, coordinates.y, coordinates.z],
			"timestamp": timestamp
		}

	## Create from dictionary (JSON deserialization)
	static func from_dict(data: Dictionary) -> DiscoveredSystem:
		var name: String = data.get("name", "Unknown")
		var coords_array: Array = data.get("coordinates", [0, 0, 0])
		var coords = Vector3(coords_array[0], coords_array[1], coords_array[2])
		var timestamp: float = data.get("timestamp", 0.0)
		return DiscoveredSystem.new(name, coords, timestamp) as DiscoveredSystem

## Signals
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal auto_save_triggered(slot: int)
signal system_discovered(system: DiscoveredSystem)

## Constants
const SAVE_VERSION: String = "1.0.0"
const MAX_SAVE_SLOTS: int = 10
const SAVE_DIR: String = "user://saves/"
const BACKUP_DIR: String = "user://saves/backups/"
const AUTO_SAVE_INTERVAL: float = 300.0  # 5 minutes

## Auto-save settings
var auto_save_enabled: bool = true
var auto_save_slot: int = 0
var auto_save_timer: float = 0.0

## Discovered systems tracking
## Dictionary mapping system names to DiscoveredSystem objects
var discovered_systems: Dictionary = {}

## References to game systems
var spacecraft: Node = null
var time_manager: Node = null
var floating_origin: Node = null
var signal_manager: Node = null
var inventory: Node = null
var mission_system: Node = null

## Initialize save system
func initialize() -> bool:
	"""Initialize the save system and create directories."""
	# Create save directories if they don't exist
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")
		if not dir.dir_exists("saves/backups"):
			dir.make_dir_recursive("saves/backups")
	
	_log_info("SaveSystem initialized")
	return true

## Set spacecraft reference
func set_spacecraft(craft: Node) -> void:
	"""Set reference to spacecraft for state saving."""
	spacecraft = craft

## Set time manager reference
func set_time_manager(manager: Node) -> void:
	"""Set reference to time manager for simulation time."""
	time_manager = manager

## Set floating origin reference
func set_floating_origin(origin: Node) -> void:
	"""Set reference to floating origin for global offset."""
	floating_origin = origin

## Set signal manager reference
func set_signal_manager(manager: Node) -> void:
	"""Set reference to signal manager for SNR/entropy."""
	signal_manager = manager

## Set inventory reference
func set_inventory(inv: Node) -> void:
	"""Set reference to inventory system."""
	inventory = inv

## Set mission system reference
func set_mission_system(missions: Node) -> void:
	"""Set reference to mission system."""
	mission_system = missions

## Add a discovered system to tracking
func add_discovered_system(system_name: String, coordinates: Vector3, timestamp: float = 0.0) -> DiscoveredSystem:
	"""
	Add a discovered system to the tracking dictionary.

	Args:
		system_name: Name of the discovered system
		coordinates: 3D coordinates of the system
		timestamp: Unix timestamp of discovery (optional, uses current time if 0)

	Returns:
		The created DiscoveredSystem object
	"""
	var system = DiscoveredSystem.new(system_name, coordinates, timestamp)
	discovered_systems[system_name] = system

	_log_info("Discovered system: %s at (%.1f, %.1f, %.1f)" % [
		system_name, coordinates.x, coordinates.y, coordinates.z
	])

	system_discovered.emit(system)
	return system

## Get all discovered systems
func get_discovered_systems() -> Array:
	"""
	Get array of all discovered systems.

	Returns:
		Array of DiscoveredSystem objects
	"""
	var systems_array: Array = []
	for system in discovered_systems.values():
		systems_array.append(system)
	return systems_array

## Check if a system has been discovered
func is_system_discovered(system_name: String) -> bool:
	"""
	Check if a system has been discovered.

	Args:
		system_name: Name of the system to check

	Returns:
		true if the system has been discovered, false otherwise
	"""
	return discovered_systems.has(system_name)

## Get a specific discovered system
func get_discovered_system(system_name: String) -> DiscoveredSystem:
	"""
	Get a specific discovered system by name.

	Args:
		system_name: Name of the system to retrieve

	Returns:
		DiscoveredSystem object or null if not found
	"""
	return discovered_systems.get(system_name, null) as DiscoveredSystem

## Get count of discovered systems
func get_discovered_system_count() -> int:
	"""
	Get the total number of discovered systems.

	Returns:
		Number of discovered systems
	"""
	return discovered_systems.size()

## Clear all discovered systems (for testing/reset)
func clear_discovered_systems() -> void:
	"""Clear all discovered systems from tracking."""
	discovered_systems.clear()
	_log_info("Cleared all discovered systems")

## Update auto-save timer
func _process(delta: float) -> void:
	"""Update auto-save timer."""
	if auto_save_enabled:
		auto_save_timer += delta
		if auto_save_timer >= AUTO_SAVE_INTERVAL:
			auto_save_timer = 0.0
			_perform_auto_save()

## Perform auto-save
func _perform_auto_save() -> void:
	"""Perform automatic save to auto-save slot."""
	if save_game(auto_save_slot):
		_log_info("Auto-save completed to slot %d" % auto_save_slot)
		auto_save_triggered.emit(auto_save_slot)
	else:
		_log_error("Auto-save failed")

## Save game to slot
## Requirement 38.1: Serialize game state to JSON
func save_game(slot: int) -> bool:
	"""Save current game state to specified slot."""
	if not _validate_slot(slot):
		return false
	
	# Create backup if save exists
	if has_save(slot):
		_create_backup(slot)
	
	# Gather game state
	var save_data = _gather_save_data()
	
	# Convert to JSON
	var json_string = JSON.stringify(save_data, "\t")
	
	# Write to file
	var save_path = _get_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file == null:
		_log_error("Failed to open save file: %s" % save_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	_log_info("Game saved to slot %d" % slot)
	game_saved.emit(slot)
	return true

## Load game from slot
## Requirement 38.3: Restore celestial body positions to saved simulation time
func load_game(slot: int) -> bool:
	"""Load game state from specified slot."""
	if not _validate_slot(slot):
		return false
	
	if not has_save(slot):
		_log_error("No save file in slot %d" % slot)
		return false
	
	# Read save file
	var save_path = _get_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	if file == null:
		_log_error("Failed to open save file: %s" % save_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		_log_error("Failed to parse save file JSON")
		return false
	
	var save_data = json.data
	
	# Validate save data
	if not _validate_save_data(save_data):
		_log_error("Invalid save data structure")
		return false
	
	# Apply save data
	_apply_save_data(save_data)
	
	_log_info("Game loaded from slot %d" % slot)
	game_loaded.emit(slot)
	return true

## Delete save file
func delete_save(slot: int) -> bool:
	"""Delete save file in specified slot."""
	if not _validate_slot(slot):
		return false
	
	var save_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(save_path):
		return true  # Already deleted
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		var err = dir.remove(save_path)
		if err == OK:
			_log_info("Deleted save in slot %d" % slot)
			return true
	
	_log_error("Failed to delete save in slot %d" % slot)
	return false

## Check if slot has save
func has_save(slot: int) -> bool:
	"""Check if specified slot has a save file."""
	if not _validate_slot(slot):
		return false
	
	return FileAccess.file_exists(_get_save_path(slot))

## Get save metadata
## Requirement 38.4: Display save metadata
func get_save_metadata(slot: int) -> Dictionary:
	"""Get metadata for save in specified slot."""
	var metadata = {
		"slot": slot,
		"exists": false,
		"version": "",
		"timestamp": 0.0,
		"date_saved": "",
		"simulation_time": 0.0,
		"player_position": Vector3.ZERO,
		"signal_strength": 0.0,
		"entropy": 0.0,
		"discovered_systems": 0
	}
	
	if not has_save(slot):
		return metadata
	
	# Read save file
	var save_path = _get_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	if file == null:
		return metadata
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return metadata
	
	var save_data = json.data
	
	# Extract metadata
	metadata["exists"] = true
	metadata["version"] = save_data.get("version", "")
	metadata["timestamp"] = save_data.get("timestamp", 0.0)
	metadata["simulation_time"] = save_data.get("simulation_time", 0.0)
	metadata["signal_strength"] = save_data.get("signal_strength", 0.0)
	metadata["entropy"] = save_data.get("entropy", 0.0)
	
	# Format date
	if metadata["timestamp"] > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(int(metadata["timestamp"]))
		metadata["date_saved"] = "%04d-%02d-%02d %02d:%02d:%02d" % [
			datetime["year"], datetime["month"], datetime["day"],
			datetime["hour"], datetime["minute"], datetime["second"]
		]
	
	# Player position
	var pos_array = save_data.get("player_position", [0, 0, 0])
	metadata["player_position"] = _array_to_vector3(pos_array)
	
	# Discovered systems count
	var systems = save_data.get("discovered_systems", [])
	metadata["discovered_systems"] = systems.size()
	
	return metadata

## Get metadata for all slots
func get_all_save_metadata() -> Array[Dictionary]:
	"""Get metadata for all save slots."""
	var all_metadata: Array[Dictionary] = []
	
	for slot in range(MAX_SAVE_SLOTS):
		all_metadata.append(get_save_metadata(slot))
	
	return all_metadata

## Enable/disable auto-save
## Requirement 38.5: Auto-save every 5 minutes
func set_auto_save_enabled(enabled: bool) -> void:
	"""Enable or disable auto-save."""
	auto_save_enabled = enabled
	auto_save_timer = 0.0
	_log_info("Auto-save %s" % ("enabled" if enabled else "disabled"))

## Set auto-save slot
func set_auto_save_slot(slot: int) -> void:
	"""Set which slot to use for auto-save."""
	if _validate_slot(slot):
		auto_save_slot = slot
		_log_info("Auto-save slot set to %d" % slot)

## Gather save data
## Requirement 38.2: Store player position, velocity, SNR, entropy
func _gather_save_data() -> Dictionary:
	"""Gather all game state data for saving."""
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"engine_version": "0.1.0"
	}
	
	# Player state (spacecraft)
	if spacecraft and spacecraft.has_method("get_state"):
		var state = spacecraft.get_state()
		save_data["player_position"] = _vector3_to_array(state.get("position", Vector3.ZERO))
		save_data["player_rotation"] = _vector3_to_array(state.get("rotation", Vector3.ZERO))
		save_data["player_velocity"] = _vector3_to_array(state.get("velocity", Vector3.ZERO))
		save_data["player_angular_velocity"] = _vector3_to_array(state.get("angular_velocity", Vector3.ZERO))
	else:
		save_data["player_position"] = [0, 0, 0]
		save_data["player_rotation"] = [0, 0, 0]
		save_data["player_velocity"] = [0, 0, 0]
		save_data["player_angular_velocity"] = [0, 0, 0]
	
	# Simulation time
	if time_manager and time_manager.has_method("get_simulation_time"):
		save_data["simulation_time"] = time_manager.get_simulation_time()
	else:
		save_data["simulation_time"] = 0.0
	
	# Floating origin offset
	if floating_origin and floating_origin.has_method("get_global_offset"):
		save_data["global_offset"] = _vector3_to_array(floating_origin.get_global_offset())
	else:
		save_data["global_offset"] = [0, 0, 0]
	
	# Signal strength and entropy
	if signal_manager:
		if signal_manager.has_method("get_signal_strength"):
			save_data["signal_strength"] = signal_manager.get_signal_strength()
		else:
			save_data["signal_strength"] = 100.0
		
		if signal_manager.has_method("get_entropy"):
			save_data["entropy"] = signal_manager.get_entropy()
		else:
			save_data["entropy"] = 0.0
	else:
		save_data["signal_strength"] = 100.0
		save_data["entropy"] = 0.0
	
	# Upgrades
	if spacecraft and spacecraft.has_method("get_all_upgrades"):
		save_data["upgrades"] = spacecraft.get_all_upgrades()
	else:
		save_data["upgrades"] = {}
	
	# Discovered systems - Serialize all discovered systems to JSON
	save_data["discovered_systems"] = _serialize_discovered_systems()
	
	# Inventory
	if inventory and inventory.has_method("get_items"):
		save_data["inventory"] = inventory.get_items()
	else:
		save_data["inventory"] = {}
	
	# Current objective
	if mission_system and mission_system.has_method("get_current_objective"):
		save_data["current_objective"] = mission_system.get_current_objective()
	else:
		save_data["current_objective"] = ""
	
	return save_data

## Apply save data
func _apply_save_data(save_data: Dictionary) -> void:
	"""Apply loaded save data to game systems."""
	# Player state
	if spacecraft and spacecraft.has_method("set_state"):
		var state = {
			"position": _array_to_vector3(save_data.get("player_position", [0, 0, 0])),
			"rotation": _array_to_vector3(save_data.get("player_rotation", [0, 0, 0])),
			"velocity": _array_to_vector3(save_data.get("player_velocity", [0, 0, 0])),
			"angular_velocity": _array_to_vector3(save_data.get("player_angular_velocity", [0, 0, 0]))
		}
		spacecraft.set_state(state)
	
	# Simulation time
	if time_manager and time_manager.has_method("set_simulation_time"):
		time_manager.set_simulation_time(save_data.get("simulation_time", 0.0))
	
	# Floating origin offset
	if floating_origin and floating_origin.has_method("set_global_offset"):
		var offset = _array_to_vector3(save_data.get("global_offset", [0, 0, 0]))
		floating_origin.set_global_offset(offset)
	
	# Signal strength and entropy
	if signal_manager:
		if signal_manager.has_method("set_signal_strength"):
			signal_manager.set_signal_strength(save_data.get("signal_strength", 100.0))
		if signal_manager.has_method("set_entropy"):
			signal_manager.set_entropy(save_data.get("entropy", 0.0))
	
	# Upgrades
	if spacecraft and spacecraft.has_method("set_all_upgrades"):
		spacecraft.set_all_upgrades(save_data.get("upgrades", {}))
	
	# Discovered systems - Deserialize discovered systems from JSON
	_deserialize_discovered_systems(save_data.get("discovered_systems", []))
	# Inventory
	if inventory and inventory.has_method("set_items"):
		inventory.set_items(save_data.get("inventory", {}))
	
	# Current objective
	if mission_system and mission_system.has_method("set_current_objective"):
		mission_system.set_current_objective(save_data.get("current_objective", ""))

## Validate save data structure
func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate that save data has required fields and perform migration if needed."""
	# Check version first
	if not save_data.has("version"):
		_log_error("Save data missing version field")
		return false

	# Check version compatibility and perform migration if needed
	var save_version = save_data.get("version", "")
	if save_version != SAVE_VERSION:
		_log_info("Save version mismatch: %s (current: %s)" % [save_version, SAVE_VERSION])

		# Attempt migration
		var migrated_data = _migrate_save_data(save_data, save_version, SAVE_VERSION)
		if migrated_data.is_empty():
			_log_error("Failed to migrate save data from version %s to %s" % [save_version, SAVE_VERSION])
			return false

		# Replace save_data with migrated version
		save_data.clear()
		save_data.merge(migrated_data)
		_log_info("Successfully migrated save data to version %s" % SAVE_VERSION)

	# Validate required fields for current version
	var required_fields = [
		"version", "timestamp", "player_position", "player_velocity",
		"simulation_time", "signal_strength", "entropy"
	]

	for field in required_fields:
		if not save_data.has(field):
			_log_error("Save data missing required field: %s" % field)
			return false

	return true
## Migrate save data between versions
func _migrate_save_data(data: Dictionary, from_version: String, to_version: String) -> Dictionary:
	"""
	Migrate save data from one version to another.
	Returns migrated data or empty Dictionary on failure.
	"""
	_log_info("Starting migration from %s to %s" % [from_version, to_version])

	# Clone data to avoid modifying original during migration
	var migrated_data = data.duplicate(true)

	# Parse version strings (format: "major.minor.patch")
	var from_parts = _parse_version(from_version)
	var to_parts = _parse_version(to_version)

	if from_parts.is_empty() or to_parts.is_empty():
		_log_error("Invalid version format: from=%s, to=%s" % [from_version, to_version])
		return {}

	# Check if migration is needed
	if from_parts == to_parts:
		_log_info("No migration needed - versions match")
		return migrated_data

	# Check if downgrade is attempted
	if _compare_versions(from_parts, to_parts) > 0:
		_log_error("Cannot downgrade save data from %s to %s" % [from_version, to_version])
		return {}

	# Chain migrations step by step
	var current_version = from_version
	var migration_chain = _get_migration_chain(from_version, to_version)

	if migration_chain.is_empty():
		_log_error("No migration path found from %s to %s" % [from_version, to_version])
		return {}

	# Apply each migration in sequence
	for migration_step in migration_chain:
		var from_v = migration_step["from"]
		var to_v = migration_step["to"]
		_log_info("Applying migration: %s -> %s" % [from_v, to_v])

		var migration_result = _apply_migration_step(migrated_data, from_v, to_v)
		if migration_result.is_empty():
			_log_error("Migration failed at step %s -> %s" % [from_v, to_v])
			return {}

		migrated_data = migration_result
		current_version = to_v

	_log_info("Migration completed successfully")
	return migrated_data

## Get migration chain from one version to another
func _get_migration_chain(from_version: String, to_version: String) -> Array[Dictionary]:
	"""
	Get the chain of migration steps needed to go from one version to another.
	Returns array of {from: String, to: String} dictionaries.
	"""
	var chain: Array[Dictionary] = []

	# Define all available migration paths
	var migrations = [
		{"from": "1.0.0", "to": "1.1.0"},
		{"from": "1.1.0", "to": "1.2.0"},
		# Add more migration paths here as versions evolve
	]

	# Build chain by finding path through migration graph
	var current = from_version

	# Simple linear chain builder (assumes sequential versions)
	# Can be enhanced with graph traversal for complex version trees
	for migration in migrations:
		if current == migration["from"]:
			chain.append(migration)
			current = migration["to"]
			if current == to_version:
				break

	# Verify chain reaches target
	if not chain.is_empty() and chain[-1]["to"] != to_version:
		_log_error("Migration chain incomplete: reached %s, target %s" % [chain[-1]["to"], to_version])
		return []

	return chain

## Apply single migration step
func _apply_migration_step(data: Dictionary, from_version: String, to_version: String) -> Dictionary:
	"""
	Apply a single migration step between adjacent versions.
	Returns migrated data or empty Dictionary on failure.
	"""
	var migration_func_name = "_migrate_%s_to_%s" % [
		from_version.replace(".", "_"),
		to_version.replace(".", "_")
	]

	# Check if migration function exists
	if has_method(migration_func_name):
		var result = call(migration_func_name, data)
		if result is Dictionary:
			return result
		else:
			_log_error("Migration function %s returned invalid type" % migration_func_name)
			return {}
	else:
		_log_error("Migration function %s not found" % migration_func_name)
		return {}

## Migration: 1.0.0 -> 1.1.0
func _migrate_1_0_0_to_1_1_0(data: Dictionary) -> Dictionary:
	"""
	Migrate save data from version 1.0.0 to 1.1.0.
	Changes:
	- Added 'engine_version' field
	- Added 'player_rotation' field (defaults to [0, 0, 0])
	- Added 'upgrades' field (defaults to {})
	"""
	_log_info("Migrating 1.0.0 -> 1.1.0: Adding new fields")

	var migrated = data.duplicate(true)

	# Add engine_version if missing
	if not migrated.has("engine_version"):
		migrated["engine_version"] = "0.1.0"
		_log_info("  Added engine_version: 0.1.0")

	# Add player_rotation if missing
	if not migrated.has("player_rotation"):
		migrated["player_rotation"] = [0.0, 0.0, 0.0]
		_log_info("  Added player_rotation: [0, 0, 0]")

	# Add upgrades if missing
	if not migrated.has("upgrades"):
		migrated["upgrades"] = {}
		_log_info("  Added upgrades: {}")

	# Update version
	migrated["version"] = "1.1.0"

	return migrated

## Migration: 1.1.0 -> 1.2.0
func _migrate_1_1_0_to_1_2_0(data: Dictionary) -> Dictionary:
	"""
	Migrate save data from version 1.1.0 to 1.2.0.
	Changes:
	- Added 'player_angular_velocity' field (defaults to [0, 0, 0])
	- Added 'global_offset' field (defaults to [0, 0, 0])
	- Added 'inventory' field (defaults to {})
	- Added 'current_objective' field (defaults to "")
	- Added 'discovered_systems' field (defaults to [])
	"""
	_log_info("Migrating 1.1.0 -> 1.2.0: Adding physics and gameplay fields")

	var migrated = data.duplicate(true)

	# Add player_angular_velocity if missing
	if not migrated.has("player_angular_velocity"):
		migrated["player_angular_velocity"] = [0.0, 0.0, 0.0]
		_log_info("  Added player_angular_velocity: [0, 0, 0]")

	# Add global_offset if missing
	if not migrated.has("global_offset"):
		migrated["global_offset"] = [0.0, 0.0, 0.0]
		_log_info("  Added global_offset: [0, 0, 0]")

	# Add inventory if missing
	if not migrated.has("inventory"):
		migrated["inventory"] = {}
		_log_info("  Added inventory: {}")

	# Add current_objective if missing
	if not migrated.has("current_objective"):
		migrated["current_objective"] = ""
		_log_info("  Added current_objective: ''")

	# Add discovered_systems if missing
	if not migrated.has("discovered_systems"):
		migrated["discovered_systems"] = []
		_log_info("  Added discovered_systems: []")

	# Update version
	migrated["version"] = "1.2.0"

	return migrated

## Parse version string into components
func _parse_version(version: String) -> Array:
	"""
	Parse version string into [major, minor, patch] array.
	Returns empty array on invalid format.
	"""
	var parts = version.split(".")
	if parts.size() != 3:
		return []

	var result = []
	for part in parts:
		if part.is_valid_int():
			result.append(int(part))
		else:
			return []

	return result

## Compare two parsed version arrays
func _compare_versions(v1: Array, v2: Array) -> int:
	"""
	Compare two version arrays.
	Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
	"""
	for i in range(3):
		if v1[i] < v2[i]:
			return -1
		elif v1[i] > v2[i]:
			return 1
	return 0



## Serialize discovered systems to JSON-compatible format
func _serialize_discovered_systems() -> Array:
	"""
	Serialize all discovered systems to array of dictionaries for JSON.

	Returns:
		Array of dictionaries representing discovered systems
	"""
	var systems_array: Array = []
	for system in discovered_systems.values():
		systems_array.append(system.to_dict())
	return systems_array

## Deserialize discovered systems from JSON format
func _deserialize_discovered_systems(systems_data: Array) -> void:
	"""
	Deserialize discovered systems from JSON data and restore to discovered_systems dictionary.

	Args:
		systems_data: Array of dictionaries from JSON
	"""
	discovered_systems.clear()

	for system_data in systems_data:
		if system_data is Dictionary:
			var system = DiscoveredSystem.from_dict(system_data)
			discovered_systems[system.system_name] = system

	_log_info("Loaded %d discovered systems from save" % discovered_systems.size())

## Create backup of existing save
func _create_backup(slot: int) -> void:
	"""Create backup of existing save file."""
	var save_path = _get_save_path(slot)
	var backup_path = BACKUP_DIR + "save_%d_backup.json" % slot
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.copy(save_path, backup_path)
		_log_info("Created backup for slot %d" % slot)

## Validate slot number
func _validate_slot(slot: int) -> bool:
	"""Validate that slot number is within valid range."""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		_log_error("Invalid save slot: %d (must be 0-%d)" % [slot, MAX_SAVE_SLOTS - 1])
		return false
	return true

## Get save file path
func _get_save_path(slot: int) -> String:
	"""Get file path for save slot."""
	return SAVE_DIR + "save_%d.json" % slot

## Convert Vector3 to array
func _vector3_to_array(vec: Vector3) -> Array:
	"""Convert Vector3 to array for JSON serialization."""
	return [vec.x, vec.y, vec.z]

## Convert array to Vector3
func _array_to_vector3(arr: Array) -> Vector3:
	"""Convert array to Vector3 from JSON deserialization."""
	if arr.size() >= 3:
		return Vector3(arr[0], arr[1], arr[2])
	return Vector3.ZERO

## Logging helpers
func _log_info(message: String) -> void:
	"""Log info message."""
	if has_node("/root/ResonanceEngine"):
		get_node("/root/ResonanceEngine").log_info("SaveSystem: " + message)
	else:
		print("SaveSystem: ", message)

func _log_error(message: String) -> void:
	"""Log error message."""
	if has_node("/root/ResonanceEngine"):
		get_node("/root/ResonanceEngine").log_error("SaveSystem: " + message)
	else:
		push_error("SaveSystem: " + message)

## Shutdown
func shutdown() -> void:
	"""Clean up save system."""
	_log_info("SaveSystem shutdown")