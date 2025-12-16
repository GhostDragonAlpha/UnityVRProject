extends "res://addons/godottpd/http_router.gd"
class_name WebhookDeliveriesRouter

## Webhook Deliveries Router
## Handles GET /webhooks/:id/deliveries

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	# GET /webhooks/:id/deliveries - Get delivery history
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

		# Get limit from query parameters
		var limit = 50
		if request.query.has("limit"):
			limit = int(request.query.get("limit", "50"))
			limit = clamp(limit, 1, 100)

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

		# Get delivery history
		var result = webhook_manager.get_delivery_history(webhook_id, limit)

		if result.success:
			response.send(200, JSON.stringify(result))
		else:
			response.send(404, JSON.stringify(result))

		return true

	super("/webhooks/", {
		'get': get_handler
	})


func _extract_webhook_id(path: String) -> String:
	# Extract ID from path like "/webhooks/123/deliveries"
	var parts = path.split("/")
	if parts.size() >= 3:
		return parts[2]
	return ""
