extends RefCounted
class_name MonitoringIntegrationExample

## Example Integration of Monitoring Components
##
## This file demonstrates how to integrate MetricsExporter, HttpApiProfiler,
## and HealthCheckSystem with an HTTP API server.
##
## Usage:
## 1. Create instances of monitoring components
## 2. Wrap request handlers with monitoring calls
## 3. Add monitoring endpoints (/metrics, /health, /debug/profile)

# Monitoring components
var metrics_exporter: MetricsExporter
var profiler: HttpApiProfiler
var health_check: HealthCheckSystem

func _init():
	# Initialize monitoring components
	metrics_exporter = MetricsExporter.new()
	profiler = HttpApiProfiler.new()
	health_check = HealthCheckSystem.new()

	print("[Monitoring] All monitoring components initialized")

## Example: Wrap a request handler with full monitoring
func handle_scene_load_request(request: Dictionary) -> Dictionary:
	# Extract request details
	var endpoint = "/scene"
	var method = "POST"
	var scene_path = request.get("scene_path", "")
	var request_id = "req_%d" % Time.get_ticks_usec()

	# Start profiling
	profiler.start_request(endpoint, method, request_id)
	profiler.add_metadata("scene_path", scene_path)
	profiler.add_metadata("client_ip", request.get("client_ip", "unknown"))

	var start_time = Time.get_ticks_msec()
	var request_size = JSON.stringify(request).length()
	var status_code = 200
	var response = {}

	# Phase 1: Authentication
	profiler.start_phase("auth_validation")
	var auth_result = _validate_auth(request)
	profiler.end_phase({"valid": auth_result.valid})

	if not auth_result.valid:
		status_code = 401
		response = {"error": "Unauthorized"}

		# Record failed auth
		metrics_exporter.record_auth_attempt("invalid_token")

		# Complete profiling and metrics
		_complete_request_monitoring(endpoint, method, status_code,
									  start_time, request_size, JSON.stringify(response).length())
		return response

	# Record successful auth
	metrics_exporter.record_auth_attempt("success")

	# Phase 2: Scene validation
	profiler.start_phase("scene_validation")
	var validation_result = _validate_scene_path(scene_path)
	profiler.end_phase({"valid": validation_result.valid, "scene": scene_path})

	if not validation_result.valid:
		status_code = 400
		response = {"error": "Invalid scene path", "details": validation_result.error}

		# Record scene error
		metrics_exporter.record_scene_load(scene_path, false, "invalid_path")

		_complete_request_monitoring(endpoint, method, status_code,
									  start_time, request_size, JSON.stringify(response).length())
		return response

	# Phase 3: File I/O (loading scene)
	profiler.start_phase("file_io")
	var load_result = _load_scene(scene_path)
	profiler.end_phase({"file_size": load_result.get("file_size", 0)})

	if not load_result.success:
		status_code = 500
		response = {"error": "Failed to load scene", "details": load_result.error}

		# Record scene error
		metrics_exporter.record_scene_load(scene_path, false, "load_failed")

		_complete_request_monitoring(endpoint, method, status_code,
									  start_time, request_size, JSON.stringify(response).length())
		return response

	# Phase 4: Response serialization
	profiler.start_phase("response_serialization")
	response = {
		"status": "success",
		"scene": scene_path,
		"loaded_at": Time.get_datetime_string_from_system(),
		"node_count": load_result.get("node_count", 0)
	}
	profiler.end_phase({"response_size": JSON.stringify(response).length()})

	# Record successful scene load
	metrics_exporter.record_scene_load(scene_path, true)

	# Complete monitoring
	_complete_request_monitoring(endpoint, method, status_code,
								  start_time, request_size, JSON.stringify(response).length())

	return response

## Complete request monitoring (metrics + profiling)
func _complete_request_monitoring(endpoint: String, method: String, status_code: int,
								   start_time_ms: int, request_size: int, response_size: int) -> void:
	var duration_ms = Time.get_ticks_msec() - start_time_ms

	# Record metrics
	metrics_exporter.record_request(endpoint, method, status_code,
									duration_ms, request_size, response_size)

	# Complete profiling
	profiler.end_request(status_code, response_size)

## Example: Rate limiting with monitoring
func check_rate_limit(endpoint: String, client_id: String) -> bool:
	# Your rate limiting logic here
	var limit_exceeded = false  # Implement actual check

	if limit_exceeded:
		# Record rate limit hit
		metrics_exporter.record_rate_limit_hit(endpoint)
		return false

	return true

## Example: Monitoring endpoint handlers

## GET /metrics - Prometheus metrics endpoint
func handle_metrics_request() -> String:
	# Return Prometheus-formatted metrics
	return metrics_exporter.export_metrics()

## GET /health - Health check endpoint
func handle_health_request() -> Dictionary:
	# Perform comprehensive health check
	return health_check.perform_health_check()

## GET /health/quick - Quick health check
func handle_quick_health_request() -> Dictionary:
	# Perform lightweight health check
	return health_check.quick_health_check()

## GET/POST /debug/profile - Profiling endpoint (requires auth)
func handle_profile_request(request: Dictionary) -> Dictionary:
	# Validate auth
	var auth_result = _validate_auth(request)
	if not auth_result.valid:
		return {"error": "Unauthorized", "status": 401}

	# Parse filters from query params
	var filters = {}
	if request.has("query_params"):
		var params = request.query_params
		if params.has("endpoint"):
			filters["endpoint"] = params.endpoint
		if params.has("method"):
			filters["method"] = params.method
		if params.has("slow_only"):
			filters["slow_only"] = params.slow_only == "true"
		if params.has("min_duration_ms"):
			filters["min_duration_ms"] = float(params.min_duration_ms)

	return profiler.get_profile_data(filters)

## GET/POST /debug/profile/flamegraph - Flame graph endpoint
func handle_flamegraph_request(request: Dictionary) -> Dictionary:
	# Validate auth
	var auth_result = _validate_auth(request)
	if not auth_result.valid:
		return {"error": "Unauthorized", "status": 401}

	# Get request_id from query params
	var request_id = ""
	if request.has("query_params") and request.query_params.has("request_id"):
		request_id = request.query_params.request_id

	return profiler.generate_flame_graph(request_id)

## GET /metrics/summary - Metrics summary (for debugging)
func handle_metrics_summary_request() -> Dictionary:
	return metrics_exporter.get_metrics_summary()

## GET /debug/profile/summary - Profiler summary
func handle_profile_summary_request() -> Dictionary:
	return profiler.get_summary()

## POST /debug/profile/clear - Clear stored profiles
func handle_clear_profiles_request(request: Dictionary) -> Dictionary:
	# Validate auth
	var auth_result = _validate_auth(request)
	if not auth_result.valid:
		return {"error": "Unauthorized", "status": 401}

	profiler.clear_profiles()
	return {"status": "success", "message": "Profiles cleared"}

## Example: Update active connections gauge
func update_active_connections(count: int) -> void:
	metrics_exporter.set_active_connections(count)

## Helper: Validate authentication (stub)
func _validate_auth(request: Dictionary) -> Dictionary:
	# Implement your auth validation logic
	var has_auth = request.has("auth_token") or request.has("headers") and request.headers.has("Authorization")
	return {"valid": has_auth}

## Helper: Validate scene path (stub)
func _validate_scene_path(scene_path: String) -> Dictionary:
	if scene_path.is_empty():
		return {"valid": false, "error": "Scene path is empty"}
	if not scene_path.begins_with("res://"):
		return {"valid": false, "error": "Scene path must start with res://"}
	if not scene_path.ends_with(".tscn"):
		return {"valid": false, "error": "Scene path must end with .tscn"}
	return {"valid": true}

## Helper: Load scene (stub)
func _load_scene(scene_path: String) -> Dictionary:
	if not ResourceLoader.exists(scene_path):
		return {"success": false, "error": "Scene not found"}

	var scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	if scene == null:
		return {"success": false, "error": "Failed to load scene"}

	var state = scene.get_state()
	return {
		"success": true,
		"node_count": state.get_node_count(),
		"file_size": 1024  # Would get from FileAccess in real implementation
	}

## Example: Complete HTTP server integration
## This shows how to integrate monitoring into a complete HTTP server

func setup_monitoring_endpoints(router) -> void:
	"""
	Setup monitoring endpoints in your HTTP router

	Example usage:
		var monitoring = MonitoringIntegrationExample.new()
		monitoring.setup_monitoring_endpoints(http_router)
	"""

	# Public endpoints (no auth required)
	router.add_route("GET", "/metrics", handle_metrics_request)
	router.add_route("GET", "/health", handle_health_request)
	router.add_route("GET", "/health/quick", handle_quick_health_request)

	# Debug endpoints (require auth)
	router.add_route("GET", "/debug/profile", handle_profile_request)
	router.add_route("POST", "/debug/profile", handle_profile_request)
	router.add_route("GET", "/debug/profile/flamegraph", handle_flamegraph_request)
	router.add_route("GET", "/debug/profile/summary", handle_profile_summary_request)
	router.add_route("POST", "/debug/profile/clear", handle_clear_profiles_request)
	router.add_route("GET", "/metrics/summary", handle_metrics_summary_request)

	print("[Monitoring] All monitoring endpoints registered")

## Example: Periodic metrics update (call from _process or timer)
func update_metrics(delta: float) -> void:
	# Update gauges that change over time
	# This would be called periodically from your main loop

	# Example: Update active connections from your HTTP server
	# var active_count = http_server.get_active_connection_count()
	# update_active_connections(active_count)
	pass

## Example: Export current state for debugging
func export_monitoring_state() -> Dictionary:
	return {
		"metrics": metrics_exporter.get_metrics_summary(),
		"profiler": profiler.get_summary(),
		"health": health_check.quick_health_check(),
		"timestamp": Time.get_datetime_string_from_system()
	}
