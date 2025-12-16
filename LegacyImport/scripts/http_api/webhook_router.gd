extends "res://addons/godottpd/http_router.gd"
class_name WebhookRouter

## Webhook Management Router
## Handles webhook CRUD operations and delivery history

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	# POST /webhooks - Register new webhook
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

		# Validate required fields
		if not body.has("url"):
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Missing required field: url"
			}))
			return true

		if not body.has("events"):
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Missing required field: events"
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

		# Register webhook
		var url = body.get("url")
		var events = body.get("events", [])
		var secret = body.get("secret", "")

		var result = webhook_manager.register_webhook(url, events, secret)

		if result.success:
			response.send(201, JSON.stringify(result))
		else:
			response.send(400, JSON.stringify(result))

		return true

	# GET /webhooks - List all webhooks
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
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

		# List webhooks
		var result = webhook_manager.list_webhooks()
		response.send(200, JSON.stringify(result))
		return true

	super("/webhooks", {
		'post': post_handler,
		'get': get_handler
	})
