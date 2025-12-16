extends "res://addons/godottpd/http_router.gd"
class_name WhitelistRouter

## HTTP Router for scene whitelist management operations
## VULN-004 FIX: Provides API endpoints to query and manage scene whitelist
## Requires authentication for all operations

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	# Define handlers
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Get whitelist configuration
		var whitelist = SecurityConfig.get_whitelist_enhanced()
		whitelist["whitelist_enabled"] = SecurityConfig.whitelist_enabled
		whitelist["config_loaded"] = SecurityConfig._whitelist_config_loaded

		response.send(200, JSON.stringify({
			"success": true,
			"whitelist": whitelist
		}))
		return true

	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Size check
		if not SecurityConfig.validate_request_size(request):
			response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid JSON body or missing Content-Type: application/json"
			}))
			return true

		var action = body.get("action", "")

		match action:
			"add_scene":
				var scene_path = body.get("scene_path", "")
				if scene_path.is_empty():
					response.send(400, JSON.stringify({
						"error": "Bad Request",
						"message": "scene_path is required"
					}))
					return true
				SecurityConfig.add_to_whitelist(scene_path)
				response.send(200, JSON.stringify({
					"success": true,
					"message": "Scene added to whitelist",
					"scene_path": scene_path
				}))
				return true

			"add_directory":
				var dir_path = body.get("dir_path", "")
				if dir_path.is_empty():
					response.send(400, JSON.stringify({
						"error": "Bad Request",
						"message": "dir_path is required"
					}))
					return true
				SecurityConfig.add_directory_to_whitelist(dir_path)
				response.send(200, JSON.stringify({
					"success": true,
					"message": "Directory added to whitelist",
					"dir_path": dir_path
				}))
				return true

			"add_wildcard":
				var pattern = body.get("pattern", "")
				if pattern.is_empty():
					response.send(400, JSON.stringify({
						"error": "Bad Request",
						"message": "pattern is required"
					}))
					return true
				SecurityConfig.add_wildcard_to_whitelist(pattern)
				response.send(200, JSON.stringify({
					"success": true,
					"message": "Wildcard pattern added to whitelist",
					"pattern": pattern
				}))
				return true

			"set_environment":
				var environment = body.get("environment", "")
				if environment.is_empty():
					response.send(400, JSON.stringify({
						"error": "Bad Request",
						"message": "environment is required (production, development, test)"
					}))
					return true
				SecurityConfig.set_environment(environment)
				response.send(200, JSON.stringify({
					"success": true,
					"message": "Environment changed and whitelist reloaded",
					"environment": environment
				}))
				return true

			"reload":
				var success = SecurityConfig.load_whitelist_config()
				response.send(200, JSON.stringify({
					"success": success,
					"message": "Whitelist configuration reloaded" if success else "Failed to reload config",
					"environment": SecurityConfig.get_environment()
				}))
				return true

			"validate":
				var scene_path = body.get("scene_path", "")
				if scene_path.is_empty():
					response.send(400, JSON.stringify({
						"error": "Bad Request",
						"message": "scene_path is required"
					}))
					return true
				var validation = SecurityConfig.validate_scene_path_enhanced(scene_path)
				response.send(200, JSON.stringify({
					"success": true,
					"validation": validation,
					"scene_path": scene_path
				}))
				return true

			_:
				response.send(400, JSON.stringify({
					"error": "Bad Request",
					"message": "Invalid action. Supported: add_scene, add_directory, add_wildcard, set_environment, reload, validate"
				}))
				return true

	# Call parent with handlers
	super("/whitelist", {
		'get': get_handler,
		'post': post_handler
	})
