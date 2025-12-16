extends "res://addons/godottpd/http_router.gd"
class_name ScenesListRouter

## HTTP Router for listing available scenes in the project
## Provides scene discovery and metadata retrieval

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")
const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")
#const SecurityHeadersMiddleware = preload("res://scripts/http_api/security_headers.gd")

# Security headers instance (MODERATE preset)
#static var _security_headers = null

func _init():
	# Initialize security headers middleware
	#if _security_headers == null:
		#_security_headers = SecurityHeadersMiddleware.new(SecurityHeadersMiddleware.HeaderPreset.MODERATE)

	# Define GET handler for listing scenes
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
#			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Rate limiting check
		var client_ip = _extract_client_ip(request)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scenes")
		if not rate_check.allowed:
			var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
			response.send(429, JSON.stringify(error_response))
			return true

		# Parse query parameters (godottpd doesn't URL-decode them, so we need to)
		var base_dir_raw = request.query.get("dir", "res://")
		var base_dir = base_dir_raw.uri_decode() if base_dir_raw else "res://"
		var include_addons_str = str(request.query.get("include_addons", "false")).to_lower()
		var include_addons = include_addons_str == "true"

		print("[ScenesListRouter] Scanning for scenes in: ", base_dir)
		print("[ScenesListRouter] Include addons: ", include_addons)

		# Validate directory path
		if not base_dir.begins_with("res://"):
#			_security_headers.apply_headers(response)
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Directory path must start with 'res://'"
			}))
			return true

		# Scan for scene files
		var scenes = _scan_scenes(base_dir, include_addons)

		# Build response
		var response_data = {
			"scenes": scenes,
			"count": scenes.size(),
			"directory": base_dir,
			"include_addons": include_addons
		}

#		_security_headers.apply_headers(response)
		response.send(200, JSON.stringify(response_data))
		return true

	# Call parent with GET handler
	super("/scenes", {
		'get': get_handler
	})


func _extract_client_ip(request: HttpRequest) -> String:
	# Try X-Forwarded-For header first (for proxied requests)
	if request.headers:
		for header in request.headers:
			if header.begins_with("X-Forwarded-For:"):
				var ip = header.split(":", 1)[1].strip_edges()
				return ip.split(",")[0].strip_edges()  # First IP in chain
	# Fallback to localhost (godottpd limitation)
	return "127.0.0.1"


func _scan_scenes(base_path: String, include_addons: bool) -> Array:
	"""Recursively scan directory for .tscn files"""
	var scenes = []
	_scan_directory(base_path, scenes, include_addons)

	# Sort by path for consistent ordering
	scenes.sort_custom(func(a, b): return a["path"] < b["path"])

	return scenes


func _scan_directory(dir_path: String, scenes: Array, include_addons: bool) -> void:
	"""Recursively scan a directory for scene files"""
	var dir = DirAccess.open(dir_path)

	if dir == null:
		print("[ScenesListRouter] Warning: Could not open directory: ", dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Skip hidden files and navigation entries
		if file_name.begins_with("."):
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

		# Handle scene files
		elif file_name.ends_with(".tscn"):
			# Skip addon scenes if not including addons
			if not include_addons and full_path.contains("/addons/"):
				file_name = dir.get_next()
				continue

			# Get file metadata
			var scene_info = _get_scene_info(full_path)
			if scene_info:
				scenes.append(scene_info)

		file_name = dir.get_next()

	dir.list_dir_end()


func _get_scene_info(scene_path: String) -> Dictionary:
	"""Get metadata for a scene file"""
	# Extract scene name from path
	var scene_name = scene_path.get_file().get_basename()

	# Get file size and modification time
	var file_access = FileAccess.open(scene_path, FileAccess.READ)
	if file_access == null:
		print("[ScenesListRouter] Warning: Could not read file: ", scene_path)
		return {}

	var size_bytes = file_access.get_length()
	file_access.close()

	# Get modification time using FileAccess static method
	var modified_unix = FileAccess.get_modified_time(scene_path)

	# Convert Unix timestamp to ISO 8601 format
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
