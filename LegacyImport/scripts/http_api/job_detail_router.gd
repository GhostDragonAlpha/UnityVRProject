extends "res://addons/godottpd/http_router.gd"
class_name JobDetailRouter

## Job Detail Router
## Handles individual job operations: GET /jobs/:id, DELETE /jobs/:id

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	# GET /jobs/:id - Get job status
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Extract job ID from path
		var job_id = _extract_job_id(request.path)
		if job_id.is_empty():
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid job ID"
			}))
			return true

		# Get job queue
		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Scene tree not available"
			}))
			return true
		var job_queue = tree.root.get_node_or_null("/root/JobQueue")
		if not job_queue:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Job queue not available"
			}))
			return true

		# Get job status
		var result = job_queue.get_job_status(job_id)

		if result.success:
			response.send(200, JSON.stringify(result))
		else:
			response.send(404, JSON.stringify(result))

		return true

	# DELETE /jobs/:id - Cancel job
	var delete_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Extract job ID from path
		var job_id = _extract_job_id(request.path)
		if job_id.is_empty():
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid job ID"
			}))
			return true

		# Get job queue
		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Scene tree not available"
			}))
			return true
		var job_queue = tree.root.get_node_or_null("/root/JobQueue")
		if not job_queue:
			response.send(500, JSON.stringify({
				"error": "Internal Server Error",
				"message": "Job queue not available"
			}))
			return true

		# Cancel job
		var result = job_queue.cancel_job(job_id)

		if result.success:
			response.send(200, JSON.stringify(result))
		else:
			if result.error == "Job not found":
				response.send(404, JSON.stringify(result))
			else:
				response.send(400, JSON.stringify(result))

		return true

	super("/jobs/", {
		'get': get_handler,
		'delete': delete_handler
	})


func _extract_job_id(path: String) -> String:
	# Extract ID from path like "/jobs/123"
	var parts = path.split("/")
	if parts.size() >= 3:
		return parts[2]
	return ""
