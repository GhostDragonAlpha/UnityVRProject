extends RefCounted

## Admin Router for HTTP API
## Provides admin-only endpoints for monitoring and management
## Requires admin token (separate from API token)

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

# Admin token (different from API token)
static var _admin_token: String = ""

# Metrics tracking
static var _request_count: int = 0
static var _success_count: int = 0
static var _error_count: int = 0
static var _requests_per_second: Array = []
static var _response_times: Array = []
static var _start_time: int = 0

# Active connections tracking
static var _active_connections: Dictionary = {}

# Audit log
static var _audit_log: Array = []
const MAX_AUDIT_LOG_SIZE = 1000

# Job queue (placeholder for future job system)
static var _jobs: Array = []
static var _job_id_counter: int = 0

# Webhooks
static var _webhooks: Array = []
static var _webhook_history: Array = []

# System logs
static var _logs: Array = []
const MAX_LOG_SIZE = 500

# Rate limiting data
static var _rate_limit_hits: Dictionary = {}

# Security events
static var _security_events: Array = []

# Scene cache statistics
static var _scene_loads: Dictionary = {}


func _init():
	if _start_time == 0:
		_start_time = Time.get_ticks_msec()

	# Generate admin token if not exists
	if _admin_token.is_empty():
		_generate_admin_token()


## Generate admin token
static func _generate_admin_token() -> String:
	var bytes = PackedByteArray()
	for i in range(32):
		bytes.append(randi() % 256)
	_admin_token = "admin_" + bytes.hex_encode()
	_log("Admin token generated", "info")
	print("[AdminRouter] ADMIN TOKEN: ", _admin_token)
	print("[AdminRouter] Use: curl -H 'X-Admin-Token: ", _admin_token, "' ...")
	return _admin_token


## Get admin token
static func get_admin_token() -> String:
	if _admin_token.is_empty():
		return _generate_admin_token()
	return _admin_token


## Validate admin token
static func validate_admin_token(request) -> bool:
	var token = request.headers.get("X-Admin-Token", "")
	if token.is_empty():
		token = request.headers.get("x-admin-token", "")

	var is_valid = token == get_admin_token()
	if not is_valid:
		_log_security_event("Failed admin authentication attempt", request)
	return is_valid


## Log security event
static func _log_security_event(event: String, request) -> void:
	_security_events.append({
		"timestamp": Time.get_unix_time_from_system(),
		"event": event,
		"ip": request.headers.get("X-Forwarded-For", "127.0.0.1"),
		"path": request.path
	})
	if _security_events.size() > 100:
		_security_events.pop_front()


## Log message
static func _log(message: String, level: String = "info") -> void:
	var log_entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"level": level,
		"message": message
	}
	_logs.append(log_entry)
	if _logs.size() > MAX_LOG_SIZE:
		_logs.pop_front()


## Track request
static func track_request(success: bool, response_time_ms: float) -> void:
	_request_count += 1
	if success:
		_success_count += 1
	else:
		_error_count += 1

	_response_times.append(response_time_ms)
	if _response_times.size() > 1000:
		_response_times.pop_front()

	# Track requests per second (in 1-second buckets)
	var current_second = int(Time.get_ticks_msec() / 1000.0)
	if _requests_per_second.is_empty() or _requests_per_second[-1].second != current_second:
		_requests_per_second.append({"second": current_second, "count": 1})
	else:
		_requests_per_second[-1].count += 1

	# Keep only last 60 seconds
	while _requests_per_second.size() > 60:
		_requests_per_second.pop_front()


## Track scene load
static func track_scene_load(scene_path: String, load_time_ms: float, success: bool) -> void:
	if not _scene_loads.has(scene_path):
		_scene_loads[scene_path] = {
			"path": scene_path,
			"load_count": 0,
			"success_count": 0,
			"failure_count": 0,
			"total_load_time": 0.0,
			"average_load_time": 0.0
		}

	var stats = _scene_loads[scene_path]
	stats.load_count += 1
	if success:
		stats.success_count += 1
	else:
		stats.failure_count += 1

	stats.total_load_time += load_time_ms
	stats.average_load_time = stats.total_load_time / stats.load_count


## Add audit log entry
static func add_audit_log(action: String, user: String, details: Dictionary) -> void:
	_audit_log.append({
		"timestamp": Time.get_unix_time_from_system(),
		"action": action,
		"user": user,
		"details": details
	})
	if _audit_log.size() > MAX_AUDIT_LOG_SIZE:
		_audit_log.pop_front()


## Get router prefix
func get_prefix() -> String:
	return "/admin"


## Handle HTTP request
func handle(request, response) -> bool:
	# Validate admin token
	if not validate_admin_token(request):
		response.code = 401
		response.body = JSON.stringify({
			"error": "Unauthorized",
			"message": "Invalid or missing admin token"
		})
		response.headers["Content-Type"] = "application/json"
		return true

	var path = request.path.substr(get_prefix().length())

	# Route to appropriate handler
	if path == "/metrics":
		return _handle_metrics(request, response)
	elif path == "/health":
		return _handle_health(request, response)
	elif path == "/logs":
		return _handle_logs(request, response)
	elif path == "/config":
		return _handle_config(request, response)
	elif path == "/cache/clear":
		return _handle_cache_clear(request, response)
	elif path == "/restart":
		return _handle_restart(request, response)
	elif path == "/security/events":
		return _handle_security_events(request, response)
	elif path == "/security/tokens":
		return _handle_security_tokens(request, response)
	elif path == "/security/revoke":
		return _handle_security_revoke(request, response)
	elif path == "/audit":
		return _handle_audit_log(request, response)
	elif path == "/scenes/whitelist":
		return _handle_scenes_whitelist(request, response)
	elif path == "/scenes/stats":
		return _handle_scenes_stats(request, response)
	elif path == "/webhooks":
		return _handle_webhooks(request, response)
	elif path == "/jobs":
		return _handle_jobs(request, response)
	elif path == "/connections":
		return _handle_connections(request, response)

	return false


## Handle /admin/metrics
func _handle_metrics(request, response) -> bool:
	var uptime_ms = Time.get_ticks_msec() - _start_time

	# Calculate requests per second (last minute average)
	var total_requests_last_minute = 0
	for bucket in _requests_per_second:
		total_requests_last_minute += bucket.count
	var requests_per_second = total_requests_last_minute / 60.0 if _requests_per_second.size() > 0 else 0.0

	# Calculate success rate
	var success_rate = (_success_count / float(_request_count)) * 100.0 if _request_count > 0 else 100.0

	# Calculate response time percentiles
	var sorted_times = _response_times.duplicate()
	sorted_times.sort()
	var p50 = _get_percentile(sorted_times, 50)
	var p95 = _get_percentile(sorted_times, 95)
	var p99 = _get_percentile(sorted_times, 99)
	var avg_response_time = _calculate_average(_response_times)

	var metrics = {
		"uptime_ms": uptime_ms,
		"uptime_seconds": uptime_ms / 1000.0,
		"requests": {
			"total": _request_count,
			"success": _success_count,
			"errors": _error_count,
			"success_rate": success_rate
		},
		"performance": {
			"requests_per_second": requests_per_second,
			"avg_response_time_ms": avg_response_time,
			"p50_response_time_ms": p50,
			"p95_response_time_ms": p95,
			"p99_response_time_ms": p99
		},
		"connections": {
			"active": _active_connections.size()
		},
		"scenes": {
			"total_loaded": _scene_loads.size(),
			"cache_size": 0  # Placeholder
		},
		"timestamp": Time.get_unix_time_from_system()
	}

	response.code = 200
	response.body = JSON.stringify(metrics)
	response.headers["Content-Type"] = "application/json"
	return true


## Calculate percentile
static func _get_percentile(sorted_array: Array, percentile: float) -> float:
	if sorted_array.is_empty():
		return 0.0
	var index = int((percentile / 100.0) * sorted_array.size())
	if index >= sorted_array.size():
		index = sorted_array.size() - 1
	return sorted_array[index]


## Calculate average
static func _calculate_average(array: Array) -> float:
	if array.is_empty():
		return 0.0
	var sum = 0.0
	for value in array:
		sum += value
	return sum / array.size()


## Handle /admin/health
func _handle_health(request, response) -> bool:
	var health = {
		"status": "healthy",
		"timestamp": Time.get_unix_time_from_system(),
		"components": {
			"http_server": {"status": "up"},
			"security": {"status": "up", "auth_enabled": SecurityConfig.auth_enabled},
			"scene_manager": {"status": "up"}
		},
		"metrics": {
			"error_rate": (_error_count / float(_request_count)) * 100.0 if _request_count > 0 else 0.0,
			"uptime_seconds": (Time.get_ticks_msec() - _start_time) / 1000.0
		}
	}

	# Determine overall health status
	var error_rate = health.metrics.error_rate
	if error_rate > 50:
		health.status = "critical"
	elif error_rate > 20:
		health.status = "degraded"

	response.code = 200
	response.body = JSON.stringify(health)
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/logs
func _handle_logs(request, response) -> bool:
	var level_filter = request.params.get("level", "")
	var search = request.params.get("search", "")
	var limit = int(request.params.get("limit", "100"))

	var filtered_logs = _logs.duplicate()

	# Apply filters
	if not level_filter.is_empty():
		filtered_logs = filtered_logs.filter(func(log): return log.level == level_filter)

	if not search.is_empty():
		filtered_logs = filtered_logs.filter(func(log): return log.message.contains(search))

	# Apply limit
	if filtered_logs.size() > limit:
		filtered_logs = filtered_logs.slice(filtered_logs.size() - limit, filtered_logs.size())

	response.code = 200
	response.body = JSON.stringify({"logs": filtered_logs})
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/config
func _handle_config(request, response) -> bool:
	if request.method == "GET":
		var config = {
			"security": {
				"auth_enabled": SecurityConfig.auth_enabled,
				"whitelist_enabled": SecurityConfig.whitelist_enabled,
				"size_limits_enabled": SecurityConfig.size_limits_enabled,
				"bind_address": SecurityConfig.BIND_ADDRESS,
				"max_request_size": SecurityConfig.MAX_REQUEST_SIZE
			},
			"whitelist": SecurityConfig.get_whitelist()
		}
		response.code = 200
		response.body = JSON.stringify(config)
		response.headers["Content-Type"] = "application/json"
		return true

	elif request.method == "POST":
		var data = JSON.parse_string(request.body)
		if data == null:
			response.code = 400
			response.body = JSON.stringify({"error": "Invalid JSON"})
			response.headers["Content-Type"] = "application/json"
			return true

		# Update configuration
		if data.has("auth_enabled"):
			if data.auth_enabled:
				SecurityConfig.enable_auth()
			else:
				SecurityConfig.disable_auth()
			add_audit_log("config_change", "admin", {"auth_enabled": data.auth_enabled})

		if data.has("whitelist_enabled"):
			SecurityConfig.whitelist_enabled = data.whitelist_enabled
			add_audit_log("config_change", "admin", {"whitelist_enabled": data.whitelist_enabled})

		response.code = 200
		response.body = JSON.stringify({"success": true, "message": "Configuration updated"})
		response.headers["Content-Type"] = "application/json"
		return true

	return false


## Handle /admin/cache/clear
func _handle_cache_clear(request, response) -> bool:
	if request.method == "POST":
		# Clear internal caches
		_scene_loads.clear()
		_log("Cache cleared by admin", "info")
		add_audit_log("cache_clear", "admin", {})

		response.code = 200
		response.body = JSON.stringify({"success": true, "message": "Cache cleared"})
		response.headers["Content-Type"] = "application/json"
		return true

	return false


## Handle /admin/restart
func _handle_restart(request, response) -> bool:
	if request.method == "POST":
		_log("Server restart requested by admin", "warning")
		add_audit_log("restart_requested", "admin", {})

		response.code = 200
		response.body = JSON.stringify({
			"success": true,
			"message": "Server restart requested - not implemented yet"
		})
		response.headers["Content-Type"] = "application/json"
		return true

	return false


## Handle /admin/security/events
func _handle_security_events(request, response) -> bool:
	response.code = 200
	response.body = JSON.stringify({"events": _security_events})
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/security/tokens
func _handle_security_tokens(request, response) -> bool:
	var tokens = {
		"api_token": SecurityConfig.get_token(),
		"admin_token": get_admin_token(),
		"active_tokens": [
			{
				"type": "api",
				"token_prefix": SecurityConfig.get_token().substr(0, 8) + "...",
				"created": _start_time
			},
			{
				"type": "admin",
				"token_prefix": get_admin_token().substr(0, 8) + "...",
				"created": _start_time
			}
		]
	}

	response.code = 200
	response.body = JSON.stringify(tokens)
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/security/revoke
func _handle_security_revoke(request, response) -> bool:
	if request.method == "POST":
		var data = JSON.parse_string(request.body)
		if data == null or not data.has("token_type"):
			response.code = 400
			response.body = JSON.stringify({"error": "Invalid request"})
			response.headers["Content-Type"] = "application/json"
			return true

		# Regenerate token
		if data.token_type == "api":
			SecurityConfig.generate_token()
		elif data.token_type == "admin":
			_generate_admin_token()

		add_audit_log("token_revoked", "admin", {"token_type": data.token_type})

		response.code = 200
		response.body = JSON.stringify({"success": true, "message": "Token revoked and regenerated"})
		response.headers["Content-Type"] = "application/json"
		return true

	return false


## Handle /admin/audit
func _handle_audit_log(request, response) -> bool:
	var limit = int(request.params.get("limit", "100"))

	var logs = _audit_log.duplicate()
	if logs.size() > limit:
		logs = logs.slice(logs.size() - limit, logs.size())

	response.code = 200
	response.body = JSON.stringify({"audit_log": logs})
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/scenes/whitelist
func _handle_scenes_whitelist(request, response) -> bool:
	if request.method == "GET":
		response.code = 200
		response.body = JSON.stringify({"whitelist": SecurityConfig.get_whitelist()})
		response.headers["Content-Type"] = "application/json"
		return true

	elif request.method == "POST":
		var data = JSON.parse_string(request.body)
		if data == null or not data.has("scene_path"):
			response.code = 400
			response.body = JSON.stringify({"error": "Invalid request"})
			response.headers["Content-Type"] = "application/json"
			return true

		SecurityConfig.add_to_whitelist(data.scene_path)
		add_audit_log("whitelist_add", "admin", {"scene_path": data.scene_path})

		response.code = 200
		response.body = JSON.stringify({"success": true, "message": "Scene added to whitelist"})
		response.headers["Content-Type"] = "application/json"
		return true

	return false


## Handle /admin/scenes/stats
func _handle_scenes_stats(request, response) -> bool:
	var stats = _scene_loads.values()
	stats.sort_custom(func(a, b): return a.load_count > b.load_count)

	response.code = 200
	response.body = JSON.stringify({"stats": stats})
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/webhooks
func _handle_webhooks(request, response) -> bool:
	if request.method == "GET":
		response.code = 200
		response.body = JSON.stringify({"webhooks": _webhooks, "history": _webhook_history})
		response.headers["Content-Type"] = "application/json"
		return true

	elif request.method == "POST":
		var data = JSON.parse_string(request.body)
		if data == null or not data.has("url"):
			response.code = 400
			response.body = JSON.stringify({"error": "Invalid request"})
			response.headers["Content-Type"] = "application/json"
			return true

		var webhook = {
			"id": _webhooks.size() + 1,
			"url": data.url,
			"events": data.get("events", []),
			"created": Time.get_unix_time_from_system()
		}
		_webhooks.append(webhook)
		add_audit_log("webhook_add", "admin", {"url": data.url})

		response.code = 200
		response.body = JSON.stringify({"success": true, "webhook": webhook})
		response.headers["Content-Type"] = "application/json"
		return true

	return false


## Handle /admin/jobs
func _handle_jobs(request, response) -> bool:
	response.code = 200
	response.body = JSON.stringify({"jobs": _jobs})
	response.headers["Content-Type"] = "application/json"
	return true


## Handle /admin/connections
func _handle_connections(request, response) -> bool:
	var connections = []
	for conn_id in _active_connections.keys():
		connections.append(_active_connections[conn_id])

	response.code = 200
	response.body = JSON.stringify({"connections": connections})
	response.headers["Content-Type"] = "application/json"
	return true
