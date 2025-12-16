extends "res://addons/godottpd/http_router.gd"
class_name BatchOperationsRouter

## Batch Operations Router
## Handles batch scene operations with transactional and continue-on-error modes
## Supports rate limiting for batch operations

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")
const SceneRouter = preload("res://scripts/http_api/scene_router.gd")

# Rate limiting for batch operations
const MAX_BATCH_SIZE = 50
const MAX_BATCH_REQUESTS_PER_MINUTE = 10
var _batch_request_timestamps: Array = []

func _init():
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Size check
		if not SecurityConfig.validate_request_size(request):
			response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
			return true

		# Rate limiting check
		if not _check_rate_limit():
			response.send(429, JSON.stringify({
				"error": "Too Many Requests",
				"message": "Batch operation rate limit exceeded",
				"retry_after": 60
			}))
			# Trigger rate limit webhook
			_trigger_rate_limit_webhook(request)
			return true

		# Parse JSON body
		var body = request.get_body_parsed()
		if not body:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid JSON body or missing Content-Type: application/json"
			}))
			return true

		# Validate batch request
		var validation = _validate_batch_request(body)
		if not validation.valid:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": validation.error
			}))
			return true

		# Execute batch operations
		var operations = body.get("operations", [])
		var mode = body.get("mode", "continue")  # "transactional" or "continue"
		var results = _execute_batch_operations(operations, mode)

		# Return results
		response.send(200, JSON.stringify(results))
		return true

	super("/batch", {
		'post': post_handler
	})


## Validate batch request
func _validate_batch_request(body: Dictionary) -> Dictionary:
	var result = {"valid": true, "error": ""}

	# Check operations array
	if not body.has("operations"):
		result.valid = false
		result.error = "Missing 'operations' array"
		return result

	var operations = body.get("operations")
	if not operations is Array:
		result.valid = false
		result.error = "'operations' must be an array"
		return result

	if operations.is_empty():
		result.valid = false
		result.error = "Operations array cannot be empty"
		return result

	if operations.size() > MAX_BATCH_SIZE:
		result.valid = false
		result.error = "Batch size exceeds maximum of " + str(MAX_BATCH_SIZE)
		return result

	# Validate mode
	var mode = body.get("mode", "continue")
	if mode != "transactional" and mode != "continue":
		result.valid = false
		result.error = "Invalid mode. Must be 'transactional' or 'continue'"
		return result

	# Validate each operation
	for i in range(operations.size()):
		var op = operations[i]
		if not op is Dictionary:
			result.valid = false
			result.error = "Operation " + str(i) + " must be a dictionary"
			return result

		if not op.has("action"):
			result.valid = false
			result.error = "Operation " + str(i) + " missing 'action' field"
			return result

		var action = op.get("action")
		if action != "load" and action != "validate" and action != "get_info":
			result.valid = false
			result.error = "Operation " + str(i) + " has invalid action: " + str(action)
			return result

		# Validate scene_path for actions that need it
		if action == "load" or action == "validate":
			if not op.has("scene_path"):
				result.valid = false
				result.error = "Operation " + str(i) + " missing 'scene_path' field"
				return result

			# Validate scene path
			var scene_path = op.get("scene_path")
			var scene_validation = SecurityConfig.validate_scene_path(scene_path)
			if not scene_validation.valid:
				result.valid = false
				result.error = "Operation " + str(i) + ": " + scene_validation.error
				return result

	return result


## Execute batch operations
func _execute_batch_operations(operations: Array, mode: String) -> Dictionary:
	var results = {
		"mode": mode,
		"total": operations.size(),
		"successful": 0,
		"failed": 0,
		"operations": []
	}

	var rollback_needed = false
	var rollback_operations = []

	for i in range(operations.size()):
		var op = operations[i]
		var action = op.get("action")
		var scene_path = op.get("scene_path", "")

		print("[BatchOperationsRouter] Executing operation ", i + 1, "/", operations.size(), ": ", action)

		# Execute operation
		var op_result = _execute_single_operation(action, scene_path)

		# Add to results
		var operation_result = {
			"index": i,
			"action": action,
			"scene_path": scene_path,
			"success": op_result.success,
			"result": op_result.data if op_result.success else null,
			"error": op_result.error if not op_result.success else null
		}
		results.operations.append(operation_result)

		# Track rollback operations in transactional mode
		if mode == "transactional":
			if op_result.success:
				# Store rollback info for this operation
				if action == "load":
					# For load operations, store the previous scene
					var tree = Engine.get_main_loop() as SceneTree
					var current_scene = tree.current_scene if tree else null
					if current_scene:
						rollback_operations.push_front({
							"action": "load",
							"scene_path": current_scene.scene_file_path
						})
			else:
				# Operation failed in transactional mode - mark for rollback
				rollback_needed = true
				results.failed += 1
				break

		# Update counters
		if op_result.success:
			results.successful += 1
		else:
			results.failed += 1
			# In continue mode, keep going; in transactional mode, we already broke

	# Handle rollback in transactional mode
	if mode == "transactional" and rollback_needed:
		print("[BatchOperationsRouter] Rolling back ", rollback_operations.size(), " operations")
		_rollback_operations(rollback_operations)
		results.rollback = true
		results.message = "Transaction failed, rolled back " + str(rollback_operations.size()) + " operations"
	elif mode == "transactional" and not rollback_needed:
		results.rollback = false
		results.message = "Transaction completed successfully"
	else:
		results.message = "Batch completed with " + str(results.successful) + " successful and " + str(results.failed) + " failed operations"

	return results


## Execute a single operation
func _execute_single_operation(action: String, scene_path: String) -> Dictionary:
	match action:
		"load":
			return _execute_load(scene_path)
		"validate":
			return _execute_validate(scene_path)
		"get_info":
			return _execute_get_info()
		_:
			return {
				"success": false,
				"error": "Unknown action: " + action
			}


## Execute load operation
func _execute_load(scene_path: String) -> Dictionary:
	# Verify scene file exists
	if not ResourceLoader.exists(scene_path):
		return {
			"success": false,
			"error": "Scene file not found: " + scene_path
		}

	# Load scene
	print("[BatchOperationsRouter] Loading scene: ", scene_path)
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.call_deferred("change_scene_to_file", scene_path)

	# Trigger webhook for scene.loaded
	_trigger_scene_webhook("scene.loaded", scene_path)

	return {
		"success": true,
		"data": {
			"status": "loading",
			"scene": scene_path,
			"message": "Scene load initiated"
		}
	}


## Execute validate operation
func _execute_validate(scene_path: String) -> Dictionary:
	# Use SceneRouter's validation logic
	var scene_router = SceneRouter.new()
	var validation_result = scene_router._validate_scene(scene_path)

	# Trigger webhook for scene.validated
	_trigger_scene_webhook("scene.validated", scene_path, validation_result)

	return {
		"success": validation_result.valid,
		"data": validation_result,
		"error": validation_result.errors[0] if not validation_result.valid and validation_result.errors.size() > 0 else null
	}


## Execute get_info operation
func _execute_get_info() -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	var current_scene = tree.current_scene if tree else null

	if current_scene:
		return {
			"success": true,
			"data": {
				"scene_name": current_scene.name,
				"scene_path": current_scene.scene_file_path,
				"status": "loaded"
			}
		}
	else:
		return {
			"success": true,
			"data": {
				"scene_name": null,
				"scene_path": null,
				"status": "no_scene"
			}
		}


## Rollback operations in transactional mode
func _rollback_operations(rollback_ops: Array) -> void:
	for op in rollback_ops:
		var action = op.get("action")
		var scene_path = op.get("scene_path", "")

		if action == "load" and not scene_path.is_empty():
			print("[BatchOperationsRouter] Rollback: Loading scene: ", scene_path)
			var tree = Engine.get_main_loop() as SceneTree
			if tree:
				tree.call_deferred("change_scene_to_file", scene_path)


## Check rate limit for batch operations
func _check_rate_limit() -> bool:
	var current_time = Time.get_unix_time_from_system()
	var cutoff_time = current_time - 60.0  # 1 minute ago

	# Remove old timestamps
	var filtered_timestamps = []
	for timestamp in _batch_request_timestamps:
		if timestamp > cutoff_time:
			filtered_timestamps.append(timestamp)

	_batch_request_timestamps = filtered_timestamps

	# Check if we're within the limit
	if _batch_request_timestamps.size() >= MAX_BATCH_REQUESTS_PER_MINUTE:
		return false

	# Add current request
	_batch_request_timestamps.append(current_time)
	return true


## Trigger scene webhook
func _trigger_scene_webhook(event: String, scene_path: String, extra_data: Dictionary = {}) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var webhook_manager = tree.root.get_node_or_null("/root/WebhookManager")
	if webhook_manager:
		var payload = {
			"scene_path": scene_path
		}
		payload.merge(extra_data)
		webhook_manager.trigger_event(event, payload)


## Trigger rate limit webhook
func _trigger_rate_limit_webhook(request: HttpRequest) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var webhook_manager = tree.root.get_node_or_null("/root/WebhookManager")
	if webhook_manager:
		webhook_manager.trigger_event("rate_limit.exceeded", {
			"endpoint": "/batch",
			"ip": "localhost",  # Could extract from request if available
			"timestamp": Time.get_unix_time_from_system()
		})
