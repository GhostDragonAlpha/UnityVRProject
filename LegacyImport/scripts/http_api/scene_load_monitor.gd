extends Node

## Scene Load Monitor
## Tracks scene changes and reports to SceneHistoryRouter
## This is an autoload singleton that monitors SceneTree changes

# CRITICAL FIX: Preload SceneHistoryRouter at compile time to avoid runtime load() calls
# This prevents performance issues from loading the class every time a scene changes
const SceneHistoryRouter = preload("res://scripts/http_api/scene_history_router.gd")

# CRITICAL FIX: Use queue to handle multiple overlapping scene loads
# This prevents race conditions when multiple scene loads happen in quick succession
var _pending_scene_loads: Array[Dictionary] = []
var _is_loading: bool = false
var _pending_load_timeout_sec: float = 30.0  # Timeout for pending loads

func _ready():
	# Connect to scene tree signals
	var tree = get_tree()
	if tree:
		tree.tree_changed.connect(_on_tree_changed)
		print("[SceneLoadMonitor] Initialized and monitoring scene changes")


## Called when initiating a scene load from SceneRouter
func start_tracking(scene_path: String) -> void:
	# CRITICAL FIX: Queue scene loads to prevent race conditions
	var load_info = {
		"scene_path": scene_path,
		"start_time": Time.get_ticks_msec()
	}
	_pending_scene_loads.append(load_info)
	_is_loading = true
	print("[SceneLoadMonitor] Started tracking load for: ", scene_path, " (queue size: ", _pending_scene_loads.size(), ")")


## Called when scene tree changes
func _on_tree_changed() -> void:
	# CRITICAL FIX: Process scene loads from queue to handle overlapping loads
	if _pending_scene_loads.is_empty():
		return

	# Check if the scene has actually changed
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var current_scene = tree.current_scene
	var current_path = current_scene.scene_file_path

	# Find matching pending load in the queue (search from oldest to newest)
	for i in range(_pending_scene_loads.size() - 1, -1, -1):
		var load_info = _pending_scene_loads[i]
		if current_path == load_info.scene_path:
			var duration_ms = Time.get_ticks_msec() - load_info.start_time
			var scene_name = current_scene.name

			# Add to history (using preloaded class - no runtime load() call)
			SceneHistoryRouter.add_to_history(current_path, scene_name, duration_ms)

			print("[SceneLoadMonitor] Scene loaded: ", scene_name, " in ", duration_ms, "ms")

			# Remove this load from the queue
			_pending_scene_loads.remove_at(i)

			# Update loading state
			if _pending_scene_loads.is_empty():
				_is_loading = false

			break


## Process function to handle timeouts for stale scene loads
func _process(_delta: float) -> void:
	if _pending_scene_loads.is_empty():
		return

	var current_time = Time.get_ticks_msec()
	var timeout_ms = _pending_load_timeout_sec * 1000.0

	# Check for timed out loads and remove them
	for i in range(_pending_scene_loads.size() - 1, -1, -1):
		var load_info = _pending_scene_loads[i]
		if current_time - load_info.start_time > timeout_ms:
			push_warning("[SceneLoadMonitor] Scene load timed out after %.1f seconds: %s" % [_pending_load_timeout_sec, load_info.scene_path])
			_pending_scene_loads.remove_at(i)

	# Update loading state
	if _pending_scene_loads.is_empty():
		_is_loading = false
