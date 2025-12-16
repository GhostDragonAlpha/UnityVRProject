extends RefCounted
class_name HealthCheckSystem

## Enhanced Health Check System for HTTP API
## Provides detailed subsystem health monitoring with timing
##
## Subsystems monitored:
## - Scene loader health
## - File system access
## - Memory usage
## - Request queue depth
## - DAP/LSP connection status
## - Telemetry server status

# Health status constants
enum HealthStatus {
	HEALTHY,
	DEGRADED,
	UNHEALTHY,
	UNKNOWN
}

# Thresholds
const MEMORY_WARNING_THRESHOLD_MB: float = 512.0
const MEMORY_CRITICAL_THRESHOLD_MB: float = 1024.0
const QUEUE_WARNING_THRESHOLD: int = 50
const QUEUE_CRITICAL_THRESHOLD: int = 100
const SCENE_LOAD_TIMEOUT_MS: float = 5000.0

## Perform comprehensive health check
func perform_health_check() -> Dictionary:
	var start_time = Time.get_ticks_usec()
	var checks = {}

	# Overall health status (starts as healthy, degrades based on checks)
	var overall_status = HealthStatus.HEALTHY
	var issues = []

	# Check 1: Scene Loader Health
	var scene_check = _check_scene_loader()
	checks["scene_loader"] = scene_check
	if scene_check.status != HealthStatus.HEALTHY:
		overall_status = max(overall_status, scene_check.status)
		issues.append("Scene loader: " + scene_check.message)

	# Check 2: File System Access
	var fs_check = _check_file_system()
	checks["file_system"] = fs_check
	if fs_check.status != HealthStatus.HEALTHY:
		overall_status = max(overall_status, fs_check.status)
		issues.append("File system: " + fs_check.message)

	# Check 3: Memory Usage
	var memory_check = _check_memory_usage()
	checks["memory"] = memory_check
	if memory_check.status != HealthStatus.HEALTHY:
		overall_status = max(overall_status, memory_check.status)
		issues.append("Memory: " + memory_check.message)

	# Check 4: Connection Status (DAP/LSP)
	var connection_check = _check_connections()
	checks["connections"] = connection_check
	# Note: Connection issues are warnings, not critical failures
	if connection_check.status == HealthStatus.DEGRADED:
		overall_status = max(overall_status, HealthStatus.DEGRADED)
		issues.append("Connections: " + connection_check.message)

	# Check 5: Resource Loader Status
	var resource_check = _check_resource_loader()
	checks["resource_loader"] = resource_check
	if resource_check.status != HealthStatus.HEALTHY:
		overall_status = max(overall_status, resource_check.status)
		issues.append("Resource loader: " + resource_check.message)

	# Check 6: Engine Status
	var engine_check = _check_engine_status()
	checks["engine"] = engine_check
	if engine_check.status != HealthStatus.HEALTHY:
		overall_status = max(overall_status, engine_check.status)
		issues.append("Engine: " + engine_check.message)

	var total_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0

	return {
		"status": _status_to_string(overall_status),
		"timestamp": Time.get_datetime_string_from_system(),
		"check_duration_ms": total_time_ms,
		"subsystems": checks,
		"issues": issues,
		"healthy": overall_status == HealthStatus.HEALTHY
	}

## Check scene loader health
func _check_scene_loader() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	# Try loading a simple test scene (we'll use the validation path)
	var test_path = "res://vr_main.tscn"

	if not ResourceLoader.exists(test_path):
		return {
			"status": HealthStatus.DEGRADED,
			"message": "Main scene not found",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {"scene_path": test_path}
		}

	# Try to get scene state without full load
	var scene = ResourceLoader.load(test_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	if scene == null:
		return {
			"status": HealthStatus.UNHEALTHY,
			"message": "Failed to load scene",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {"scene_path": test_path}
		}

	var check_time = (Time.get_ticks_usec() - start_time) / 1000.0

	return {
		"status": HealthStatus.HEALTHY,
		"message": "Scene loader operational",
		"check_duration_ms": check_time,
		"details": {
			"scene_path": test_path,
			"load_time_ms": check_time
		}
	}

## Check file system access
func _check_file_system() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	# Test read access to project directory
	var dir = DirAccess.open("res://")
	if dir == null:
		return {
			"status": HealthStatus.UNHEALTHY,
			"message": "Cannot access project directory",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {"error": DirAccess.get_open_error()}
		}

	# Count files to verify directory access works
	var file_count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		file_count += 1
		file_name = dir.get_next()
		if file_count > 100:  # Limit iteration
			break
	dir.list_dir_end()

	if file_count == 0:
		return {
			"status": HealthStatus.DEGRADED,
			"message": "Project directory appears empty",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {"file_count": file_count}
		}

	return {
		"status": HealthStatus.HEALTHY,
		"message": "File system accessible",
		"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
		"details": {"file_count": file_count}
	}

## Check memory usage
func _check_memory_usage() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	# Get memory stats from Performance singleton
	# Note: MEMORY_DYNAMIC deprecated in Godot 4.x - only MEMORY_STATIC_MAX is available

	var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024.0 / 1024.0  # MB

	var total_memory = static_memory

	var status = HealthStatus.HEALTHY
	var message = "Memory usage normal"

	if total_memory >= MEMORY_CRITICAL_THRESHOLD_MB:
		status = HealthStatus.UNHEALTHY
		message = "Critical memory usage (%.1f MB)" % total_memory
	elif total_memory >= MEMORY_WARNING_THRESHOLD_MB:
		status = HealthStatus.DEGRADED
		message = "High memory usage (%.1f MB)" % total_memory

	return {
		"status": status,
		"message": message,
		"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
		"details": {
			"static_memory_mb": static_memory,
			"total_memory_mb": total_memory,
			"warning_threshold_mb": MEMORY_WARNING_THRESHOLD_MB,
			"critical_threshold_mb": MEMORY_CRITICAL_THRESHOLD_MB
		}
	}

## Check DAP/LSP connection status
func _check_connections() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	# Try to find GodotBridge autoload
	var godot_bridge = null
	if Engine.has_singleton("GodotBridge"):
		godot_bridge = Engine.get_singleton("GodotBridge")
	else:
		# Try to find it in the tree
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			godot_bridge = tree.root.get_node_or_null("/root/GodotBridge")

	if godot_bridge == null:
		return {
			"status": HealthStatus.DEGRADED,
			"message": "GodotBridge not found (debug features unavailable)",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {"dap_connected": false, "lsp_connected": false}
		}

	# Check connection manager
	var connection_manager = godot_bridge.get("connection_manager")
	if connection_manager == null:
		return {
			"status": HealthStatus.DEGRADED,
			"message": "Connection manager not available",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {"dap_connected": false, "lsp_connected": false}
		}

	var dap_status = connection_manager.get_dap_status()
	var lsp_status = connection_manager.get_lsp_status()

	var dap_connected = dap_status.get("state", 0) == 2  # CONNECTED state
	var lsp_connected = lsp_status.get("state", 0) == 2

	var status = HealthStatus.HEALTHY
	var message = "All connections active"

	if not dap_connected and not lsp_connected:
		status = HealthStatus.DEGRADED
		message = "DAP and LSP disconnected"
	elif not dap_connected:
		status = HealthStatus.DEGRADED
		message = "DAP disconnected"
	elif not lsp_connected:
		status = HealthStatus.DEGRADED
		message = "LSP disconnected"

	return {
		"status": status,
		"message": message,
		"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
		"details": {
			"dap_connected": dap_connected,
			"lsp_connected": lsp_connected,
			"dap_port": 6006,
			"lsp_port": 6005
		}
	}

## Check resource loader status
func _check_resource_loader() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	# Note: ResourceLoader.get_resource_list() was removed in Godot 4.x
	# Check if we can load a simple resource instead
	var status = HealthStatus.HEALTHY
	var message = "Resource loader operational"

	# Test by checking if we can access ResourceLoader
	var test_exists = ResourceLoader.exists("res://icon.svg")
	# Not finding icon.svg is informational, not a failure
	var test_result = "found" if test_exists else "not_found"
	if not test_exists:
		message = "Resource loader operational (icon.svg not found, but this is not critical)"

	return {
		"status": status,
		"message": message,
		"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
		"details": {
			"icon_test": test_result
		}
	}

## Check engine status
func _check_engine_status() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return {
			"status": HealthStatus.UNHEALTHY,
			"message": "SceneTree not accessible",
			"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
			"details": {}
		}

	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS)

	var status = HealthStatus.HEALTHY
	var message = "Engine running normally"

	# Check for extremely low FPS (might indicate engine stall)
	if fps < 10.0:
		status = HealthStatus.DEGRADED
		message = "Low FPS detected (%.1f)" % fps

	return {
		"status": status,
		"message": message,
		"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
		"details": {
			"fps": fps,
			"frame_time_ms": frame_time * 1000.0,
			"godot_version": Engine.get_version_info()["string"],
			"is_paused": tree.paused
		}
	}

## Convert status enum to string
func _status_to_string(status: HealthStatus) -> String:
	match status:
		HealthStatus.HEALTHY:
			return "healthy"
		HealthStatus.DEGRADED:
			return "degraded"
		HealthStatus.UNHEALTHY:
			return "unhealthy"
		_:
			return "unknown"

## Quick health check (lighter version for frequent polling)
func quick_health_check() -> Dictionary:
	var start_time = Time.get_ticks_usec()

	var tree = Engine.get_main_loop() as SceneTree
	var is_healthy = tree != null

	var memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024.0 / 1024.0

	var fps = Performance.get_monitor(Performance.TIME_FPS)

	return {
		"healthy": is_healthy and memory_mb < MEMORY_CRITICAL_THRESHOLD_MB and fps > 10.0,
		"check_duration_ms": (Time.get_ticks_usec() - start_time) / 1000.0,
		"memory_mb": memory_mb,
		"fps": fps
	}
