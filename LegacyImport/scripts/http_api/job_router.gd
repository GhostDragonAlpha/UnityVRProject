extends "res://addons/godottpd/http_router.gd"
class_name JobRouter

## Job Queue Router
## Handles job submission and listing: POST /jobs, GET /jobs

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	# POST /jobs - Submit new job
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
		if not body.has("type"):
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Missing required field: type"
			}))
			return true

		if not body.has("parameters"):
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Missing required field: parameters"
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

		# Parse job type
		var job_type_str = body.get("type")
		var job_type = _parse_job_type(job_type_str)
		if job_type == -1:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid job type. Must be: batch_operations, scene_preload, or cache_warming"
			}))
			return true

		var parameters = body.get("parameters", {})

		# Submit job
		var result = job_queue.submit_job(job_type, parameters)
		response.send(202, JSON.stringify(result))  # 202 Accepted
		return true

	# GET /jobs - List all jobs
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
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

		# Get status filter from query parameters
		var status_filter = request.query.get("status", "")

		# List jobs
		var result = job_queue.list_jobs(status_filter)
		response.send(200, JSON.stringify(result))
		return true

	super("/jobs", {
		'post': post_handler,
		'get': get_handler
	})


func _parse_job_type(type_str: String) -> int:
	match type_str:
		"batch_operations":
			return 0  # JobQueue.JobType.BATCH_OPERATIONS
		"scene_preload":
			return 1  # JobQueue.JobType.SCENE_PRELOAD
		"cache_warming":
			return 2  # JobQueue.JobType.CACHE_WARMING
		_:
			return -1
