extends "res://addons/godottpd/http_router.gd"
class_name SceneReloadRouter

## HTTP Router for scene reload operations
## Reloads the current scene without requiring a path

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")
const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")
#const SecurityHeadersMiddleware = preload("res://scripts/http_api/security_headers.gd")

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
	# Initialize security headers middleware
#	if _security_headers == null:
#		_security_headers = SecurityHeadersMiddleware.new(SecurityHeadersMiddleware.HeaderPreset.MODERATE)

	# Define POST handler for reloading current scene
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
#			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Rate limiting check
		var client_ip = _extract_client_ip(request)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene/reload")
		if not rate_check.allowed:
			var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
#			_security_headers.apply_headers(response)
			response.send(429, JSON.stringify(error_response))
			return true

		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
#			_security_headers.apply_headers(response)
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Could not access SceneTree"
			}))
			return true

		var current_scene = tree.current_scene
		if not current_scene:
#			_security_headers.apply_headers(response)
			response.send(404, JSON.stringify({
				"error": "Not Found",
				"message": "No scene currently loaded"
			}))
			return true

		var scene_path = current_scene.scene_file_path
		if not scene_path or scene_path.is_empty():
#			_security_headers.apply_headers(response)
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Current scene has no file path"
			}))
			return true

		print("[SceneReloadRouter] Reloading current scene: ", scene_path)

		# Reload the scene
		tree.call_deferred("change_scene_to_file", scene_path)

		var scene_name = scene_path.get_file().get_basename()
#		_security_headers.apply_headers(response)
		response.send(200, JSON.stringify({
			"status": "reloading",
			"scene": scene_path,
			"scene_name": scene_name,
			"message": "Scene reload initiated successfully"
		}))
		return true

	# Call parent with POST handler
	super("/scene/reload", {'post': post_handler})
