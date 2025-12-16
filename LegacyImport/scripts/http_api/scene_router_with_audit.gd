extends "res://addons/godottpd/http_router.gd"
class_name SceneRouterWithAudit

## HTTP Router for scene management operations with comprehensive audit logging
## Logs all authentication, authorization, validation, and scene operations

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

# Get AuditHelper singleton (must be registered as autoload)
var audit_helper: Node = null

func _init():
	# Get audit helper
	call_deferred("_get_audit_helper")

	# Define handlers
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		return _handle_scene_load(request, response)

	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		return _handle_scene_get(request, response)

	var put_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		return _handle_scene_validate(request, response)

	# Call parent with handlers in options
	super("/scene", {
		'post': post_handler,
		'get': get_handler,
		'put': put_handler
	})


func _get_audit_helper() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		push_warning("[SceneRouterWithAudit] Scene tree not available - audit logging disabled")
		return
	audit_helper = tree.root.get_node_or_null("/root/AuditHelper")
	if not audit_helper:
		push_warning("[SceneRouterWithAudit] AuditHelper not found - audit logging disabled")


## Handle POST /scene - Load a scene
func _handle_scene_load(request: HttpRequest, response: GodottpdResponse) -> bool:
	# Auth check
	if not SecurityConfig.validate_auth(request.headers):
		if audit_helper:
			audit_helper.log_auth_failure(request, "Missing or invalid token", "/scene")
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	# Log successful authentication
	if audit_helper:
		audit_helper.log_auth_success(request, "/scene")

	# Rate limit check
	var client_ip = _get_client_ip(request)
	var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene")
	if not rate_check["allowed"]:
		if audit_helper:
			audit_helper.log_rate_limit(request, rate_check["limit"], rate_check["retry_after"], "/scene")
		response.send(429, JSON.stringify(SecurityConfig.create_rate_limit_error_response(rate_check["retry_after"])))
		return true

	# Size check
	var body_size = request.body.length()
	if not SecurityConfig.validate_request_size(body_size):
		if audit_helper:
			audit_helper.log_validation_failure(request, "body_size", "Request too large", str(body_size), "/scene")
		response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
		return true

	# Parse JSON body
	var body = request.get_body_parsed()
	if not body:
		if audit_helper:
			audit_helper.log_validation_failure(request, "body", "Invalid JSON or missing Content-Type", "", "/scene")
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Invalid JSON body or missing Content-Type: application/json"
		}))
		return true

	var scene_path = body.get("scene_path", "res://vr_main.tscn")

	# Whitelist validation
	var scene_validation = SecurityConfig.validate_scene_path(scene_path)
	if not scene_validation.valid:
		# Check for path traversal attempts
		if "../" in scene_path or "..\\" in scene_path:
			if audit_helper:
				audit_helper.log_security_violation(request, "path_traversal", {
					"scene_path": scene_path,
					"reason": "Path traversal attempt detected"
				}, "/scene")
		else:
			if audit_helper:
				audit_helper.log_validation_failure(request, "scene_path", scene_validation.error, scene_path, "/scene")

		response.send(403, JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error)))
		return true

	# Verify scene file exists
	if not ResourceLoader.exists(scene_path):
		if audit_helper:
			audit_helper.log_scene_load(request, scene_path, false, "Scene file not found")
		response.send(404, JSON.stringify({
			"error": "Not Found",
			"message": "Scene file not found: " + scene_path
		}))
		return true

	# Load scene
	print("[SceneRouterWithAudit] Loading scene: ", scene_path)
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.call_deferred("change_scene_to_file", scene_path)

	# Log successful scene load
	if audit_helper:
		audit_helper.log_scene_load(request, scene_path, true, "Scene load initiated")

	# Return success response
	response.send(200, JSON.stringify({
		"status": "loading",
		"scene": scene_path,
		"message": "Scene load initiated successfully"
	}))
	return true


## Handle GET /scene - Get current scene info
func _handle_scene_get(request: HttpRequest, response: GodottpdResponse) -> bool:
	# Auth check
	if not SecurityConfig.validate_auth(request.headers):
		if audit_helper:
			audit_helper.log_auth_failure(request, "Missing or invalid token", "/scene")
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	# Log successful authentication
	if audit_helper:
		audit_helper.log_auth_success(request, "/scene")

	var tree = Engine.get_main_loop() as SceneTree
	var current_scene = tree.current_scene if tree else null

	if current_scene:
		response.send(200, JSON.stringify({
			"scene_name": current_scene.name,
			"scene_path": current_scene.scene_file_path,
			"status": "loaded"
		}))
	else:
		response.send(200, JSON.stringify({
			"scene_name": null,
			"scene_path": null,
			"status": "no_scene"
		}))

	return true


## Handle PUT /scene - Validate scene without loading
func _handle_scene_validate(request: HttpRequest, response: GodottpdResponse) -> bool:
	# Auth check
	if not SecurityConfig.validate_auth(request.headers):
		if audit_helper:
			audit_helper.log_auth_failure(request, "Missing or invalid token", "/scene")
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	# Log successful authentication
	if audit_helper:
		audit_helper.log_auth_success(request, "/scene")

	# Size check
	var body_size = request.body.length()
	if not SecurityConfig.validate_request_size(body_size):
		if audit_helper:
			audit_helper.log_validation_failure(request, "body_size", "Request too large", str(body_size), "/scene")
		response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
		return true

	# Parse JSON body
	var body = request.get_body_parsed()
	if not body:
		if audit_helper:
			audit_helper.log_validation_failure(request, "body", "Invalid JSON or missing Content-Type", "", "/scene")
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Invalid JSON body or missing Content-Type: application/json"
		}))
		return true

	var scene_path = body.get("scene_path", "")

	# Whitelist validation
	var scene_validation = SecurityConfig.validate_scene_path(scene_path)
	if not scene_validation.valid:
		if audit_helper:
			audit_helper.log_validation_failure(request, "scene_path", scene_validation.error, scene_path, "/scene")
		response.send(403, JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error)))
		return true

	# Perform validation
	var validation_result = _validate_scene(scene_path)

	response.send(200, JSON.stringify(validation_result))
	return true


## Validates a scene without loading it
func _validate_scene(scene_path: String) -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"scene_info": {}
	}

	if scene_path.is_empty():
		result.valid = false
		result.errors.append("Scene path cannot be empty")
		return result

	if not scene_path.begins_with("res://"):
		result.valid = false
		result.errors.append("Scene path must start with 'res://'")

	if not scene_path.ends_with(".tscn"):
		result.valid = false
		result.errors.append("Scene path must end with '.tscn'")

	if not result.valid:
		return result

	if not ResourceLoader.exists(scene_path):
		result.valid = false
		result.errors.append("Scene file not found: " + scene_path)
		return result

	var packed_scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	if not packed_scene:
		result.valid = false
		result.errors.append("Failed to load scene resource")
		return result

	var scene_state = packed_scene.get_state()
	if scene_state.get_node_count() == 0:
		result.valid = false
		result.errors.append("Scene has no nodes (empty scene)")
		return result

	result.scene_info = {
		"node_count": scene_state.get_node_count(),
		"root_type": scene_state.get_node_type(0),
		"root_name": scene_state.get_node_name(0)
	}

	var instance = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	if not instance:
		result.valid = false
		result.errors.append("Failed to instantiate scene (possible circular dependency)")
		return result

	instance.free()

	if result.scene_info.node_count > 1000:
		result.warnings.append("Scene has a large number of nodes (%d), may impact performance" % result.scene_info.node_count)

	if " " in scene_path:
		result.warnings.append("Scene path contains spaces, which may cause issues on some platforms")

	return result


## Get client IP from request
func _get_client_ip(request: HttpRequest) -> String:
	var forwarded = request.headers.get("x-forwarded-for", request.headers.get("X-Forwarded-For", ""))
	if not forwarded.is_empty():
		var ips = forwarded.split(",")
		if ips.size() > 0:
			return ips[0].strip_edges()

	var real_ip = request.headers.get("x-real-ip", request.headers.get("X-Real-IP", ""))
	if not real_ip.is_empty():
		return real_ip

	return "127.0.0.1"
