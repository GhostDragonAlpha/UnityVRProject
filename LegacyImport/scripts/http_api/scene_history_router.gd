extends "res://addons/godottpd/http_router.gd"
class_name SceneHistoryRouter

## HTTP Router for scene history tracking
## Maintains history of last 10 scene loads with timestamps and duration

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")
const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")
#const SecurityHeadersMiddleware = preload("res://scripts/http_api/security_headers.gd")
const MAX_HISTORY = 10

# Singleton instance for history persistence across requests
static var _instance: SceneHistoryRouter = null
static var _history: Array = []  # Max 10 entries

# Security headers instance (MODERATE preset)
#static var _security_headers = null

func _extract_client_ip(request: HttpRequest) -> String:
	# Try X-Forwarded-For header first (for proxied requests)
	if request.headers:
		for header in request.headers:
			if header.begins_with("X-Forwarded-For:"):
				var ip = header.split(":", 1)[1].strip_edges()
				return ip.split(",")[0].strip_edges()  # First IP in chain
	# Fallback to localhost (godottpd limitation)
	return "127.0.0.1"

func _init():
	# Initialize singleton instance
	if _instance == null:
		_instance = self

	# Initialize security headers middleware
#	if _security_headers == null:
#		_security_headers = SecurityHeadersMiddleware.new(SecurityHeadersMiddleware.HeaderPreset.MODERATE)

	# Define GET handler for fetching history
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
#			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Rate limiting check
		var client_ip = _extract_client_ip(request)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene/history")
		if not rate_check.allowed:
			var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
			response.send(429, JSON.stringify(error_response))
			return true

		var history_data = {
			"history": _history.duplicate(),
			"count": _history.size(),
			"max_size": MAX_HISTORY
		}
#		_security_headers.apply_headers(response)
		response.send(200, JSON.stringify(history_data))
		return true

	# Call parent constructor with route and handlers
	super("/scene/history", {
		'get': get_handler
	})


## Add a scene load event to history
## Called by SceneRouter after successful scene load
static func add_to_history(scene_path: String, scene_name: String, duration_ms: int) -> void:
	# Get current timestamp in ISO 8601 format
	var time_dict = Time.get_datetime_dict_from_system()
	var loaded_at = "%04d-%02d-%02dT%02d:%02d:%02d" % [
		time_dict.year,
		time_dict.month,
		time_dict.day,
		time_dict.hour,
		time_dict.minute,
		time_dict.second
	]

	# Create history entry
	var entry = {
		"scene_path": scene_path,
		"scene_name": scene_name,
		"loaded_at": loaded_at,
		"load_duration_ms": duration_ms
	}

	# Add to beginning of array (most recent first)
	_history.push_front(entry)

	# Keep only last MAX_HISTORY entries
	if _history.size() > MAX_HISTORY:
		_history.resize(MAX_HISTORY)

	print("[SceneHistoryRouter] Added to history: ", scene_name, " (", duration_ms, "ms)")


## Clear all history (useful for testing)
static func clear_history() -> void:
	_history.clear()
	print("[SceneHistoryRouter] History cleared")
