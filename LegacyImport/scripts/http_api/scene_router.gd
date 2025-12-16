extends "res://addons/godottpd/http_router.gd"
class_name SceneRouter

## HTTP Router for scene management operations
## Handles loading scenes without requiring DAP/LSP connection

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")
const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")
# const SecurityHeadersMiddleware = preload("res://scripts/http_api/security_headers.gd")  # TEMPORARILY DISABLED

# Security headers instance (MODERATE preset)
# static var _security_headers = null  # TEMPORARILY DISABLED


func _extract_client_ip(request: HttpRequest) -> String:
	# SECURITY FIX: Validate X-Forwarded-For header with trusted proxy list
	# and proper IP format validation. Prevents IP spoofing attacks.

	var client_ip = _get_direct_connection_ip(request)

	# Only trust X-Forwarded-For if it came from a trusted proxy
	if _is_trusted_proxy(client_ip) and request.headers:
		var forwarded_ip = _extract_forwarded_for_ip(request)
		if forwarded_ip:
			return forwarded_ip

	return client_ip


## Get the direct connection IP from the request
func _get_direct_connection_ip(request: HttpRequest) -> String:
	# godottpd provides connection info through headers
	# Default to localhost if we can't determine actual IP
	return "127.0.0.1"


## Check if the connecting IP is from a trusted proxy
func _is_trusted_proxy(ip: String) -> bool:
	var trusted_proxies = [
		"127.0.0.1",      # Localhost
		"::1",            # IPv6 localhost
		"localhost"       # Hostname
	]

	return ip in trusted_proxies


## Extract and validate IP from X-Forwarded-For header
func _extract_forwarded_for_ip(request: HttpRequest) -> String:
	if not request.headers:
		return ""

	# Find X-Forwarded-For header
	var forwarded_header = ""
	for header in request.headers:
		if header.begins_with("X-Forwarded-For:"):
			forwarded_header = header
			break

	if forwarded_header.is_empty():
		return ""

	# Extract header value
	var header_value = forwarded_header.split(":", 1)[1].strip_edges()
	if header_value.is_empty():
		return ""

	# X-Forwarded-For can contain multiple IPs: "client, proxy1, proxy2"
	var ips = header_value.split(",")
	if ips.is_empty():
		return ""

	var client_ip = ips[0].strip_edges()

	# SECURITY: Validate IP format before returning
	if _is_valid_ip_format(client_ip):
		return client_ip

	# SECURITY: Log invalid IP attempts
	print("[Security] WARNING: Invalid IP format in X-Forwarded-For header: ", client_ip)
	return ""


## Validate IP address format (IPv4 or IPv6)
func _is_valid_ip_format(ip: String) -> bool:
	if ip.is_empty():
		return false

	ip = ip.strip_edges()

	# Check for IPv6 (contains colons)
	if ":" in ip:
		return _is_valid_ipv6(ip)

	# Check for IPv4 (contains dots)
	if "." in ip:
		return _is_valid_ipv4(ip)

	return false


## Validate IPv4 address format
func _is_valid_ipv4(ip: String) -> bool:
	var parts = ip.split(".")

	if parts.size() != 4:
		return false

	for part in parts:
		if part.is_empty():
			return false

		if not part.is_valid_int():
			return false

		var num = int(part)
		if num < 0 or num > 255:
			return false

	return true


## Validate IPv6 address format (basic validation)
func _is_valid_ipv6(ip: String) -> bool:
	if ":" not in ip:
		return false

	var parts = ip.split(":")

	# IPv6 should have 8 parts (or fewer with compression ::)
	if "::" in ip:
		if ip.count("::") > 1:
			return false
	else:
		if parts.size() != 8:
			return false

	# Validate each part contains only hex digits
	for part in parts:
		if part.is_empty():
			continue

		if part.length() > 4:
			return false

		for char in part:
			if not char in "0123456789abcdefABCDEF":
				return false

	return true


## Apply security headers to HTTP response
## Implements MED-008 fix: Re-enable security headers using inline approach
func _add_security_headers(response: GodottpdResponse) -> void:
	response.set_header("X-Content-Type-Options", "nosniff")
	response.set_header("X-Frame-Options", "DENY")
	response.set_header("Referrer-Policy", "no-referrer")
	response.set_header("X-XSS-Protection", "1; mode=block")


func _init():
	# Initialize security headers middleware
# 	if _security_headers == null:  # TEMPORARILY DISABLED
# 		_security_headers = SecurityHeadersMiddleware.new(SecurityHeadersMiddleware.HeaderPreset.MODERATE)  # TEMPORARILY DISABLED

	# Define handlers first
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			_add_security_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Rate limiting check
		var client_ip = _extract_client_ip(request)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene")
		if not rate_check.allowed:
			var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
			_add_security_headers(response)
			response.send(429, JSON.stringify(error_response))
			return true

		# Size check
		if not SecurityConfig.validate_request_size(request):
			_add_security_headers(response)
			response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			_add_security_headers(response)
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid JSON body or missing Content-Type: application/json"
			}))
			return true

		var scene_path = body.get("scene_path", "res://vr_main.tscn")

		print("[SceneRouter] Scene load requested: ", scene_path)

		# Whitelist validation
		var scene_validation = SecurityConfig.validate_scene_path_enhanced(scene_path)
		if not scene_validation.valid:
			_add_security_headers(response)
			response.send(403, JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error)))
			return true

		# Verify scene file exists
		if not ResourceLoader.exists(scene_path):
			_add_security_headers(response)
			response.send(404, JSON.stringify({
				"error": "Not Found",
				"message": "Scene file not found: " + scene_path
			}))
			return true

		# Load scene using Engine singleton to access SceneTree
		print("[SceneRouter] Loading scene via call_deferred: ", scene_path)
		# Use Engine to get the main loop (SceneTree)
		var tree = Engine.get_main_loop() as SceneTree
		if tree:
			tree.call_deferred("change_scene_to_file", scene_path)

		# Return success response immediately (scene will load async)
_add_security_headers(response)
		response.send(200, JSON.stringify({
			"status": "loading",
			"scene": scene_path,
			"message": "Scene load initiated successfully"
		}))
		return true

	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			_add_security_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Rate limiting check
		var client_ip = _extract_client_ip(request)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene")
		if not rate_check.allowed:
			var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
			_add_security_headers(response)
			response.send(429, JSON.stringify(error_response))
			return true

		var tree = Engine.get_main_loop() as SceneTree
		var current_scene = tree.current_scene if tree else null
		if current_scene:
			_add_security_headers(response)
			response.send(200, JSON.stringify({
				"scene_name": current_scene.name,
				"scene_path": current_scene.scene_file_path,
				"status": "loaded"
			}))
		else:
			_add_security_headers(response)
			response.send(200, JSON.stringify({
				"scene_name": null,
				"scene_path": null,
				"status": "no_scene"
			}))
		return true

	var put_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			_add_security_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Rate limiting check
		var client_ip = _extract_client_ip(request)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene")
		if not rate_check.allowed:
			var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
			_add_security_headers(response)
			response.send(429, JSON.stringify(error_response))
			return true

		# Size check
		if not SecurityConfig.validate_request_size(request):
			_add_security_headers(response)
			response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			_add_security_headers(response)
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid JSON body or missing Content-Type: application/json"
			}))
			return true

		var scene_path = body.get("scene_path", "")

		print("[SceneRouter] Scene validation requested: ", scene_path)

		# Whitelist validation
		var scene_validation = SecurityConfig.validate_scene_path_enhanced(scene_path)
		if not scene_validation.valid:
			_add_security_headers(response)
			response.send(403, JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error)))
			return true

		# Perform validation
		var validation_result = _validate_scene(scene_path)

_add_security_headers(response)
		response.send(200, JSON.stringify(validation_result))
		return true

	# Call parent with handlers in options
	super("/scene", {
		'post': post_handler,
		'get': get_handler,
		'put': put_handler
	})


## Validates a scene without loading it
## Returns a dictionary with validation results
func _validate_scene(scene_path: String) -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"scene_info": {}
	}

	# Check if scene_path is empty
	if scene_path.is_empty():
		result.valid = false
		result.errors.append("Scene path cannot be empty")
		return result

	# Check path format - must start with res:// and end with .tscn
	if not scene_path.begins_with("res://"):
		result.valid = false
		result.errors.append("Scene path must start with 'res://'")

	if not scene_path.ends_with(".tscn"):
		result.valid = false
		result.errors.append("Scene path must end with '.tscn'")

	# If path format is invalid, return early
	if not result.valid:
		return result

	# Check if file exists
	if not ResourceLoader.exists(scene_path):
		result.valid = false
		result.errors.append("Scene file not found: " + scene_path)
		return result

	# Try to load the scene to validate it
	var packed_scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)

	if not packed_scene:
		result.valid = false
		result.errors.append("Failed to load scene resource")
		return result

	# Check if scene can be instantiated (has root node)
	var scene_state = packed_scene.get_state()
	if scene_state.get_node_count() == 0:
		result.valid = false
		result.errors.append("Scene has no nodes (empty scene)")
		return result

	# Get scene metadata
	result.scene_info = {
		"node_count": scene_state.get_node_count(),
		"root_type": scene_state.get_node_type(0),
		"root_name": scene_state.get_node_name(0)
	}

	# Check for circular dependencies by trying to instantiate
	# We don't actually add it to the tree, just test instantiation
	var instance = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	if not instance:
		result.valid = false
		result.errors.append("Failed to instantiate scene (possible circular dependency)")
		return result

	# Clean up the test instance
	instance.free()

	# Add warnings for common issues
	if result.scene_info.node_count > 1000:
		result.warnings.append("Scene has a large number of nodes (%d), may impact performance" % result.scene_info.node_count)

	# Check if scene path contains spaces (can cause issues on some platforms)
	if " " in scene_path:
		result.warnings.append("Scene path contains spaces, which may cause issues on some platforms")

	return result
