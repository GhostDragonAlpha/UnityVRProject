extends "res://addons/godottpd/http_router.gd"
class_name WebhookDetailRouter

## Webhook Detail Router
## Handles individual webhook operations: GET, PUT, DELETE /webhooks/:id

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

var _webhook_id: String = ""

func _init(webhook_id_pattern: String = ""):
	_webhook_id = webhook_id_pattern

	# GET /webhooks/:id - Get webhook details
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Extract webhook ID from path
		var webhook_id = _extract_webhook_id(request.path)
		if webhook_id.is_empty():
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid webhook ID"
			}))
			return true

		# Get webhook manager
		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Scene tree not available"
			}))
			return true
		var webhook_manager = tree.root.get_node_or_null("/root/WebhookManager")
		if not webhook_manager:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Webhook manager not available"
			}))
			return true

		# Get webhook
		var result = webhook_manager.get_webhook(webhook_id)

		if result.success:
			response.send(200, JSON.stringify(result))
		else:
			response.send(404, JSON.stringify(result))

		return true

	# PUT /webhooks/:id - Update webhook
	var put_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Size check
		if not SecurityConfig.validate_request_size(request):
			response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
			return true

		# Extract webhook ID from path
		var webhook_id = _extract_webhook_id(request.path)
		if webhook_id.is_empty():
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid webhook ID"
			}))
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid JSON body or missing Content-Type: application/json"
			}))
			return true

		# Get webhook manager
		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Scene tree not available"
			}))
			return true
		var webhook_manager = tree.root.get_node_or_null("/root/WebhookManager")
		if not webhook_manager:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Webhook manager not available"
			}))
			return true

		# Update webhook
		var result = webhook_manager.update_webhook(webhook_id, body)

		if result.success:
			response.send(200, JSON.stringify(result))
		else:
			if result.error == "Webhook not found":
				response.send(404, JSON.stringify(result))
			else:
				response.send(400, JSON.stringify(result))

		return true

	# DELETE /webhooks/:id - Delete webhook
	var delete_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Extract webhook ID from path
		var webhook_id = _extract_webhook_id(request.path)
		if webhook_id.is_empty():
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid webhook ID"
			}))
			return true

		# Get webhook manager
		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Scene tree not available"
			}))
			return true
		var webhook_manager = tree.root.get_node_or_null("/root/WebhookManager")
		if not webhook_manager:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Webhook manager not available"
			}))
			return true

		# Delete webhook
		var result = webhook_manager.delete_webhook(webhook_id)

		if result.success:
			response.send(200, JSON.stringify(result))
		else:
			response.send(404, JSON.stringify(result))

		return true

	super("/webhooks/", {
		'get': get_handler,
		'put': put_handler,
		'delete': delete_handler
	})


func _extract_webhook_id(path: String) -> String:
	# Extract ID from path like "/webhooks/123" or "/webhooks/123/deliveries"
	var parts = path.split("/")
	if parts.size() >= 3:
		return parts[2]
	return ""
