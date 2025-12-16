extends "res://addons/godottpd/http_router.gd"
class_name PerformanceRouter

## HTTP Router for performance monitoring and statistics
## Provides cache stats, security stats, and general performance metrics

const SecurityConfig = preload("res://scripts/http_api/security_config_optimized.gd")
const CacheManager = preload("res://scripts/http_api/cache_manager.gd")

func _init():
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Gather all performance statistics
		var cache = CacheManager.get_instance()
		var perf_data = {
			"timestamp": Time.get_unix_time_from_system(),
			"cache": cache.get_stats(),
			"security": SecurityConfig.get_stats(),
			"memory": _get_memory_stats(),
			"engine": _get_engine_stats()
		}

		response.send(200, JSON.stringify(perf_data))
		return true

	super("/performance", {'get': get_handler})


func _get_memory_stats() -> Dictionary:
	"""Get memory usage statistics"""
	return {
		"static_memory_usage": Performance.get_monitor(Performance.MEMORY_STATIC),
		"static_memory_max": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"dynamic_memory_usage": Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX)
	}


func _get_engine_stats() -> Dictionary:
	"""Get engine performance statistics"""
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_time": Performance.get_monitor(Performance.TIME_PROCESS),
		"physics_process_time": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"objects_in_use": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources_in_use": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"nodes_in_use": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	}
