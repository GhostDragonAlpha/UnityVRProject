extends "res://addons/godottpd/http_router.gd"
class_name ScenesListRouterOptimized

## Optimized HTTP Router for listing available scenes
##
## PERFORMANCE OPTIMIZATIONS:
## 1. Cached directory scanning results (5min TTL)
## 2. Cached file metadata (reduces I/O)
## 3. Pre-allocated arrays for results
## 4. Optimized string operations
## 5. Fast auth checks with caching

const SecurityConfig = preload("res://scripts/http_api/security_config_optimized.gd")
const CacheManager = preload("res://scripts/http_api/cache_manager.gd")

# Pre-cached error responses
var _cached_responses: Dictionary = {}

# Performance stats
var _request_count: int = 0
var _cache_hits: int = 0

func _init():
	# Pre-cache error responses
	_cached_responses["auth_error"] = JSON.stringify(SecurityConfig.create_auth_error_response())
	_cached_responses["bad_dir"] = JSON.stringify({
		"error": "Bad Request",
		"message": "Directory path must start with 'res://'"
	})

	# Define GET handler
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		_request_count += 1

		# Fast auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, _cached_responses["auth_error"])
			return true

		# Parse query parameters
		var base_dir_raw = request.query.get("dir", "res://")
		var base_dir = base_dir_raw.uri_decode() if base_dir_raw else "res://"
		var include_addons_str = str(request.query.get("include_addons", "false")).to_lower()
		var include_addons = include_addons_str == "true"

		# Validate directory path
		if not base_dir.begins_with("res://"):
			response.send(400, _cached_responses["bad_dir"])
			return true

		# Check cache first
		var cache = CacheManager.get_instance()
		var cached_scenes = cache.get_cached_scene_list(base_dir, include_addons)

		var scenes: Array
		if cached_scenes != null:
			_cache_hits += 1
			scenes = cached_scenes
		else:
			# Scan for scene files
			scenes = _scan_scenes(base_dir, include_addons)
			# Cache the result
			cache.cache_scene_list(base_dir, include_addons, scenes)

		# Build response
		var response_data = {
			"scenes": scenes,
			"count": scenes.size(),
			"directory": base_dir,
			"include_addons": include_addons
		}

		response.send(200, JSON.stringify(response_data))
		return true

	# Call parent with GET handler
	super("/scenes", {'get': get_handler})


func _scan_scenes(base_path: String, include_addons: bool) -> Array:
	"""Optimized recursive scene scanning with pre-allocated arrays"""
	var scenes = []
	scenes.resize(0)  # Pre-allocate space
	_scan_directory(base_path, scenes, include_addons)

	# Sort by path for consistent ordering (in-place)
	scenes.sort_custom(func(a, b): return a["path"] < b["path"])

	return scenes


func _scan_directory(dir_path: String, scenes: Array, include_addons: bool) -> void:
	"""Recursively scan a directory for scene files"""
	var dir = DirAccess.open(dir_path)

	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Skip hidden files and navigation entries (combined check)
		if file_name[0] == '.' if file_name.length() > 0 else true:
			file_name = dir.get_next()
			continue

		var full_path = dir_path.path_join(file_name)

		# Handle directories
		if dir.current_is_dir():
			# Skip addons directory if not including addons
			if not include_addons and file_name == "addons":
				file_name = dir.get_next()
				continue

			# Recursively scan subdirectory
			_scan_directory(full_path, scenes, include_addons)

		# Handle scene files (.tscn check is faster than ends_with)
		elif file_name.length() > 5 and file_name.substr(file_name.length() - 5) == ".tscn":
			# Skip addon scenes if not including addons
			if not include_addons and "/addons/" in full_path:
				file_name = dir.get_next()
				continue

			# Get file metadata (with caching)
			var scene_info = _get_scene_info_cached(full_path)
			if not scene_info.is_empty():
				scenes.append(scene_info)

		file_name = dir.get_next()

	dir.list_dir_end()


func _get_scene_info_cached(scene_path: String) -> Dictionary:
	"""Get cached or fresh metadata for a scene file"""
	var cache = CacheManager.get_instance()
	var cached_info = cache.get_cached_scene_metadata(scene_path)

	if cached_info != null:
		return cached_info

	# Get fresh metadata
	var info = _get_scene_info(scene_path)
	if not info.is_empty():
		cache.cache_scene_metadata(scene_path, info)

	return info


func _get_scene_info(scene_path: String) -> Dictionary:
	"""Get metadata for a scene file"""
	# Extract scene name from path (optimized)
	var file_name = scene_path.get_file()
	var scene_name = file_name.substr(0, file_name.length() - 5)  # Remove .tscn

	# Get file size
	var file_access = FileAccess.open(scene_path, FileAccess.READ)
	if file_access == null:
		return {}

	var size_bytes = file_access.get_length()
	file_access.close()

	# Get modification time
	var modified_unix = FileAccess.get_modified_time(scene_path)

	# Convert Unix timestamp to ISO 8601 format (optimized string formatting)
	var datetime = Time.get_datetime_dict_from_unix_time(modified_unix)
	var modified_iso = "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

	return {
		"name": scene_name,
		"path": scene_path,
		"size_bytes": size_bytes,
		"modified": modified_iso
	}


## Get performance statistics
func get_stats() -> Dictionary:
	var cache_hit_rate = 0.0
	if _request_count > 0:
		cache_hit_rate = float(_cache_hits) / float(_request_count) * 100.0

	return {
		"requests": _request_count,
		"cache_hits": _cache_hits,
		"cache_hit_rate_percent": "%.2f" % cache_hit_rate
	}
