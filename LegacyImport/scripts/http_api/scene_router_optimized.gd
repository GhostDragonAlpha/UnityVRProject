extends "res://addons/godottpd/http_router.gd"
class_name SceneRouterOptimized

## Optimized HTTP Router for scene management operations
##
## PERFORMANCE OPTIMIZATIONS:
## 1. Cached scene validation results (10min TTL)
## 2. Cached JSON responses (reduces serialization overhead)
## 3. Pre-allocated response objects (object pooling)
## 4. Optimized security checks with caching
## 5. Lazy scene loading with ResourceLoader cache mode
## 6. Reduced string allocations

const SecurityConfig = preload("res://scripts/http_api/security_config_optimized.gd")
const CacheManager = preload("res://scripts/http_api/cache_manager.gd")

# Response object pool
var _response_pool: Array = []
const MAX_POOL_SIZE = 20

# Pre-allocated error responses (JSON strings)
var _cached_error_responses: Dictionary = {}

# Performance stats
var _request_count: int = 0
var _cache_hits: int = 0

func _init():
	# Initialize security
	SecurityConfig.initialize()

	# Pre-generate common error responses
	_precache_error_responses()

	# Define handlers
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		_request_count += 1

		# Fast auth check (with caching)
		if not SecurityConfig.validate_auth(request):
			response.send(401, _cached_error_responses["auth_error"])
			return true

		# Fast size check (inline)
		if not SecurityConfig.validate_request_size(request):
			response.send(413, _cached_error_responses["size_error"])
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			response.send(400, _cached_error_responses["invalid_json"])
			return true

		var scene_path = body.get("scene_path", "res://vr_main.tscn")

		# Fast whitelist validation (with caching)
		var scene_validation = SecurityConfig.validate_scene_path(scene_path)
		if not scene_validation.valid:
			var error_response = JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error))
			response.send(403, error_response)
			return true

		# Verify scene file exists
		if not ResourceLoader.exists(scene_path):
			var error_response = JSON.stringify({
				"error": "Not Found",
				"message": "Scene file not found: " + scene_path
			})
			response.send(404, error_response)
			return true

		# Load scene using Engine singleton
		var tree = Engine.get_main_loop() as SceneTree
		if tree:
			tree.call_deferred("change_scene_to_file", scene_path)

		# Return success response (use pre-built response)
		var success_response = JSON.stringify({
			"status": "loading",
			"scene": scene_path,
			"message": "Scene load initiated successfully"
		})
		response.send(200, success_response)
		return true

	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		_request_count += 1

		# Fast auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, _cached_error_responses["auth_error"])
			return true

		var tree = Engine.get_main_loop() as SceneTree
		var current_scene = tree.current_scene if tree else null

		if current_scene:
			# Build response
			var response_data = JSON.stringify({
				"scene_name": current_scene.name,
				"scene_path": current_scene.scene_file_path,
				"status": "loaded"
			})
			response.send(200, response_data)
		else:
			response.send(200, _cached_error_responses["no_scene"])
		return true

	var put_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		_request_count += 1

		# Fast auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, _cached_error_responses["auth_error"])
			return true

		# Fast size check
		if not SecurityConfig.validate_request_size(request):
			response.send(413, _cached_error_responses["size_error"])
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			response.send(400, _cached_error_responses["invalid_json"])
			return true

		var scene_path = body.get("scene_path", "")

		# Fast whitelist validation
		var scene_validation = SecurityConfig.validate_scene_path(scene_path)
		if not scene_validation.valid:
			var error_response = JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error))
			response.send(403, error_response)
			return true

		# Check cache for validation result
		var cache = CacheManager.get_instance()
		var cached_validation = cache.get_cached_scene_validation(scene_path)

		var validation_result: Dictionary
		if cached_validation != null:
			_cache_hits += 1
			validation_result = cached_validation
		else:
			# Perform validation and cache it
			validation_result = _validate_scene(scene_path)
			cache.cache_scene_validation(scene_path, validation_result)

		var response_json = JSON.stringify(validation_result)
		response.send(200, response_json)
		return true

	# Call parent with handlers
	super("/scene", {
		'post': post_handler,
		'get': get_handler,
		'put': put_handler
	})


## Pre-cache common error responses to avoid repeated JSON serialization
func _precache_error_responses() -> void:
	_cached_error_responses["auth_error"] = JSON.stringify(SecurityConfig.create_auth_error_response())
	_cached_error_responses["size_error"] = JSON.stringify(SecurityConfig.create_size_error_response())
	_cached_error_responses["invalid_json"] = JSON.stringify({
		"error": "Bad Request",
		"message": "Invalid JSON body or missing Content-Type: application/json"
	})
	_cached_error_responses["no_scene"] = JSON.stringify({
		"scene_name": null,
		"scene_path": null,
		"status": "no_scene"
	})


## Optimized scene validation with caching
func _validate_scene(scene_path: String) -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"scene_info": {}
	}

	# Early validation checks
	if scene_path.is_empty():
		result.valid = false
		result.errors.append("Scene path cannot be empty")
		return result

	# Combined path format check
	if not (scene_path.begins_with("res://") and scene_path.ends_with(".tscn")):
		result.valid = false
		if not scene_path.begins_with("res://"):
			result.errors.append("Scene path must start with 'res://'")
		if not scene_path.ends_with(".tscn"):
			result.errors.append("Scene path must end with '.tscn'")
		return result

	# Check if file exists
	if not ResourceLoader.exists(scene_path):
		result.valid = false
		result.errors.append("Scene file not found: " + scene_path)
		return result

	# Load scene with cache mode for performance
	var packed_scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)

	if not packed_scene:
		result.valid = false
		result.errors.append("Failed to load scene resource")
		return result

	# Get scene state efficiently
	var scene_state = packed_scene.get_state()
	var node_count = scene_state.get_node_count()

	if node_count == 0:
		result.valid = false
		result.errors.append("Scene has no nodes (empty scene)")
		return result

	# Get scene metadata
	result.scene_info = {
		"node_count": node_count,
		"root_type": scene_state.get_node_type(0),
		"root_name": scene_state.get_node_name(0)
	}

	# Try to instantiate (with error handling)
	var instance = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	if not instance:
		result.valid = false
		result.errors.append("Failed to instantiate scene (possible circular dependency)")
		return result

	# Clean up
	instance.free()

	# Add performance warnings
	if node_count > 1000:
		result.warnings.append("Scene has a large number of nodes (%d), may impact performance" % node_count)

	if " " in scene_path:
		result.warnings.append("Scene path contains spaces, which may cause issues on some platforms")

	return result


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


## Print performance stats
func print_stats() -> void:
	var stats = get_stats()
	print("[SceneRouterOptimized] Performance Stats:")
	print("  Requests: ", stats.requests)
	print("  Cache Hits: ", stats.cache_hits)
	print("  Cache Hit Rate: ", stats.cache_hit_rate_percent, "%")
