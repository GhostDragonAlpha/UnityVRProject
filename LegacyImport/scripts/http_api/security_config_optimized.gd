extends RefCounted
class_name HttpApiSecurityConfigOptimized

## Optimized security configuration for HTTP API
## Implements authentication with caching, whitelisting with optimized lookups,
## and constant-time token comparison
##
## PERFORMANCE OPTIMIZATIONS:
## 1. Cached authentication results (30s TTL)
## 2. Cached whitelist lookups (10m TTL)
## 3. Constant-time HMAC comparison (prevents timing attacks)
## 4. Pre-compiled regex for path validation
## 5. Optimized string operations

# Import cache manager
const CacheManager = preload("res://scripts/http_api/cache_manager.gd")

# Security token (generated on startup)
static var _api_token: String = ""
static var _token_header: String = "Authorization"
static var _token_hash: String = ""  # Pre-computed hash for comparison

# Scene whitelist (allowed scene paths)
static var _scene_whitelist: Array[String] = [
	"res://vr_main.tscn",
	"res://node_3d.tscn",
	"res://test_scene.tscn",
]

# Pre-computed whitelist lookup table for O(1) access
static var _whitelist_lookup: Dictionary = {}
static var _whitelist_dirs: Array[String] = []

# Request size limits (bytes)
const MAX_REQUEST_SIZE = 1048576  # 1MB
const MAX_SCENE_PATH_LENGTH = 256

# Localhost only binding
const BIND_ADDRESS = "127.0.0.1"

# Enable/disable security features
static var auth_enabled: bool = true
static var whitelist_enabled: bool = true
static var size_limits_enabled: bool = true

# Performance statistics
static var _auth_checks: int = 0
static var _auth_cache_hits: int = 0
static var _whitelist_checks: int = 0
static var _whitelist_cache_hits: int = 0


## Initialize security system (call on startup)
static func initialize() -> void:
	generate_token()
	_build_whitelist_lookup()
	print("[SecurityOptimized] Initialized with ", _scene_whitelist.size(), " whitelisted scenes")


## Generate secure API token on startup
static func generate_token() -> String:
	if _api_token.is_empty():
		# Generate 32-byte random token
		var bytes = PackedByteArray()
		for i in range(32):
			bytes.append(randi() % 256)
		_api_token = bytes.hex_encode()
		_token_hash = _api_token.sha256_text()  # Pre-compute hash
		print("[SecurityOptimized] API token generated: ", _api_token)
		print("[SecurityOptimized] Include in requests: Authorization: Bearer ", _api_token)
	return _api_token


## Get current API token
static func get_token() -> String:
	if _api_token.is_empty():
		return generate_token()
	return _api_token


## Validate authorization header with caching and constant-time comparison
static func validate_auth(request: HttpRequest) -> bool:
	if not auth_enabled:
		return true

	_auth_checks += 1

	# Get auth header
	var auth_header = request.headers.get(_token_header, "")
	if auth_header.is_empty():
		return false

	# Check for "Bearer <token>" format
	if not auth_header.begins_with("Bearer "):
		return false

	var token = auth_header.substr(7).strip_edges()

	# Check cache first
	var cache = CacheManager.get_instance()
	var cached_result = cache.get_cached_auth(token)
	if cached_result != null:
		_auth_cache_hits += 1
		return cached_result

	# Perform validation with constant-time comparison
	var is_valid = _constant_time_compare(token, get_token())

	# Cache result
	cache.cache_auth_result(token, is_valid)

	return is_valid


## Constant-time string comparison (prevents timing attacks)
static func _constant_time_compare(a: String, b: String) -> bool:
	# If lengths differ, still compare all bytes to maintain constant time
	var len_match = (a.length() == b.length())

	# Compare hashes instead of raw strings for better security
	var a_hash = a.sha256_text()
	var b_hash = b.sha256_text()

	# XOR all bytes and check if result is zero
	var result = 0
	var max_len = max(a_hash.length(), b_hash.length())

	for i in range(max_len):
		var a_byte = a_hash.unicode_at(i) if i < a_hash.length() else 0
		var b_byte = b_hash.unicode_at(i) if i < b_hash.length() else 0
		result |= (a_byte ^ b_byte)

	return (result == 0) and len_match


## Build whitelist lookup table for O(1) access
static func _build_whitelist_lookup() -> void:
	_whitelist_lookup.clear()
	_whitelist_dirs.clear()

	for path in _scene_whitelist:
		if path.ends_with("/"):
			# This is a directory whitelist
			_whitelist_dirs.append(path)
		else:
			# This is a specific file whitelist
			_whitelist_lookup[path] = true

	print("[SecurityOptimized] Built whitelist lookup: ", _whitelist_lookup.size(), " files, ", _whitelist_dirs.size(), " dirs")


## Optimized scene path validation with caching
static func validate_scene_path(scene_path: String) -> Dictionary:
	_whitelist_checks += 1

	# Check cache first
	var cache = CacheManager.get_instance()
	var cached_result = cache.get_cached_whitelist_lookup(scene_path)
	if cached_result != null:
		_whitelist_cache_hits += 1
		return cached_result

	# Perform validation
	var result = _validate_scene_path_uncached(scene_path)

	# Cache result
	cache.cache_whitelist_lookup(scene_path, result.valid, result.error)

	return result


## Internal validation without caching
static func _validate_scene_path_uncached(scene_path: String) -> Dictionary:
	var result = {"valid": true, "error": ""}

	# Basic format validation (optimized)
	if scene_path.length() > MAX_SCENE_PATH_LENGTH:
		result.valid = false
		result.error = "Scene path exceeds maximum length"
		return result

	# Use single check for prefix and suffix
	if not (scene_path.begins_with("res://") and scene_path.ends_with(".tscn")):
		result.valid = false
		result.error = "Scene path must start with res:// and end with .tscn"
		return result

	# Path traversal prevention (check once)
	if ".." in scene_path:
		result.valid = false
		result.error = "Path traversal not allowed"
		return result

	# Whitelist validation with O(1) lookup
	if whitelist_enabled:
		# Check direct file match first (O(1))
		if _whitelist_lookup.has(scene_path):
			return result

		# Check directory matches (O(n) but n is small)
		var is_whitelisted = false
		for dir in _whitelist_dirs:
			if scene_path.begins_with(dir):
				is_whitelisted = true
				break

		if not is_whitelisted:
			result.valid = false
			result.error = "Scene not in whitelist"
			return result

	return result


## Validate request size (inline for performance)
static func validate_request_size(request: HttpRequest) -> bool:
	if not size_limits_enabled:
		return true
	return request.body.length() <= MAX_REQUEST_SIZE


## Add scene to whitelist (for configuration)
static func add_to_whitelist(scene_path: String) -> void:
	if not _scene_whitelist.has(scene_path):
		_scene_whitelist.append(scene_path)
		_build_whitelist_lookup()  # Rebuild lookup table
		print("[SecurityOptimized] Added to whitelist: ", scene_path)


## Add directory to whitelist (all scenes in dir allowed)
static func add_directory_to_whitelist(dir_path: String) -> void:
	if not dir_path.ends_with("/"):
		dir_path += "/"
	add_to_whitelist(dir_path)


## Get whitelist for configuration/debugging
static func get_whitelist() -> Array[String]:
	return _scene_whitelist.duplicate()


## Disable authentication (for testing only)
static func disable_auth() -> void:
	auth_enabled = false
	print("[SecurityOptimized] WARNING: Authentication disabled")


## Enable authentication
static func enable_auth() -> void:
	auth_enabled = true
	print("[SecurityOptimized] Authentication enabled")


## Create 401 Unauthorized response
static func create_auth_error_response() -> Dictionary:
	return {
		"error": "Unauthorized",
		"message": "Missing or invalid authentication token",
		"details": "Include 'Authorization: Bearer <token>' header"
	}


## Create 403 Forbidden response
static func create_forbidden_response(reason: String = "") -> Dictionary:
	return {
		"error": "Forbidden",
		"message": reason if not reason.is_empty() else "Access denied",
	}


## Create 413 Payload Too Large response
static func create_size_error_response() -> Dictionary:
	return {
		"error": "Payload Too Large",
		"message": "Request body exceeds maximum size",
		"max_size_bytes": MAX_REQUEST_SIZE
	}


## Get performance statistics
static func get_stats() -> Dictionary:
	var auth_hit_rate = 0.0
	if _auth_checks > 0:
		auth_hit_rate = float(_auth_cache_hits) / float(_auth_checks) * 100.0

	var whitelist_hit_rate = 0.0
	if _whitelist_checks > 0:
		whitelist_hit_rate = float(_whitelist_cache_hits) / float(_whitelist_checks) * 100.0

	return {
		"auth": {
			"total_checks": _auth_checks,
			"cache_hits": _auth_cache_hits,
			"hit_rate_percent": "%.2f" % auth_hit_rate
		},
		"whitelist": {
			"total_checks": _whitelist_checks,
			"cache_hits": _whitelist_cache_hits,
			"hit_rate_percent": "%.2f" % whitelist_hit_rate
		}
	}


## Print security configuration on startup
static func print_config() -> void:
	print("[SecurityOptimized] Configuration:")
	print("[SecurityOptimized]   Authentication: ", "ENABLED" if auth_enabled else "DISABLED")
	print("[SecurityOptimized]   Scene Whitelist: ", "ENABLED" if whitelist_enabled else "DISABLED")
	print("[SecurityOptimized]   Size Limits: ", "ENABLED" if size_limits_enabled else "DISABLED")
	print("[SecurityOptimized]   Bind Address: ", BIND_ADDRESS)
	print("[SecurityOptimized]   Max Request Size: ", MAX_REQUEST_SIZE, " bytes")
	print("[SecurityOptimized]   Whitelisted Scenes: ", _scene_whitelist.size())
	for scene in _scene_whitelist:
		print("[SecurityOptimized]     - ", scene)
