# Router Integration Examples for InputValidator

This document provides code examples for integrating InputValidator into all HTTP API routers.

---

## WebhookRouter Integration

### File: `scripts/http_api/webhook_router.gd`

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

# In POST handler
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
	# ... existing auth and size checks ...

	var body = request.get_body_parsed()
	if not body:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Invalid JSON body"
		}))
		return true

	# VALIDATE URL
	if not body.has("url"):
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Missing required field: url"
		}))
		return true

	var url = body.get("url")

	# Validate URL string
	var url_validation = InputValidator.validate_string(url, 256, "", "url")
	if not url_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": url_validation.error,
			"field": "url"
		}))
		return true

	# Validate URL format (basic check)
	if not url.begins_with("http://") and not url.begins_with("https://"):
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "URL must start with http:// or https://",
			"field": "url"
		}))
		return true

	# VALIDATE EVENTS ARRAY
	if not body.has("events"):
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Missing required field: events"
		}))
		return true

	var events = body.get("events")

	# Validate events is an array
	var events_validation = InputValidator.validate_array(events, 50, "events")
	if not events_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": events_validation.error,
			"field": "events"
		}))
		return true

	# Validate each event name
	for event in events:
		var event_validation = InputValidator.validate_string(event, 64, "", "event")
		if not event_validation.valid:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": event_validation.error,
				"field": "events[]"
			}))
			return true

	# VALIDATE SECRET (optional)
	var secret = body.get("secret", "")
	if not secret.is_empty():
		var secret_validation = InputValidator.validate_string(secret, 128, "", "secret")
		if not secret_validation.valid:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": secret_validation.error,
				"field": "secret"
			}))
			return true

	# Continue with webhook registration...
	var webhook_manager = get_node_or_null("/root/WebhookManager")
	# ... rest of handler ...
```

---

## AdminRouter Integration

### File: `scripts/http_api/admin_router.gd`

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

# In _handle_logs
func _handle_logs(request, response) -> bool:
	# Validate query parameters
	var level_filter = request.params.get("level", "")
	if not level_filter.is_empty():
		var level_validation = InputValidator.validate_string(level_filter, 32, "", "level")
		if not level_validation.valid:
			response.code = 400
			response.body = JSON.stringify({
				"error": "Bad Request",
				"message": level_validation.error
			})
			response.headers["Content-Type"] = "application/json"
			return true

		# Validate against allowed log levels
		var allowed_levels = ["debug", "info", "warning", "error", "critical"]
		if not level_filter in allowed_levels:
			response.code = 400
			response.body = JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid log level. Allowed: " + ", ".join(allowed_levels)
			})
			response.headers["Content-Type"] = "application/json"
			return true

	var search = request.params.get("search", "")
	if not search.is_empty():
		# Sanitize search input
		search = InputValidator.sanitize_user_input(search)

		# Validate search length
		var search_validation = InputValidator.validate_string(search, 256, "", "search")
		if not search_validation.valid:
			response.code = 400
			response.body = JSON.stringify({
				"error": "Bad Request",
				"message": search_validation.error
			})
			response.headers["Content-Type"] = "application/json"
			return true

	var limit_str = request.params.get("limit", "100")
	var limit_validation = InputValidator.validate_integer(limit_str, 1, 1000, "limit")
	if not limit_validation.valid:
		response.code = 400
		response.body = JSON.stringify({
			"error": "Bad Request",
			"message": limit_validation.error
		})
		response.headers["Content-Type"] = "application/json"
		return true

	var limit = limit_validation.value

	# Continue with filtered logs...
	# ... rest of handler ...
```

---

## PerformanceRouter Integration

### File: `scripts/http_api/performance_router.gd`

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

# In GET handler
var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
	# Auth check
	if not SecurityConfig.validate_auth(request):
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	# Validate query parameters if any
	var include_memory = request.params.get("include_memory", "true")
	if include_memory != "true" and include_memory != "false":
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "include_memory must be 'true' or 'false'"
		}))
		return true

	var include_engine = request.params.get("include_engine", "true")
	if include_engine != "true" and include_engine != "false":
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "include_engine must be 'true' or 'false'"
		}))
		return true

	# Gather performance statistics
	var cache = CacheManager.get_instance()
	var perf_data = {
		"timestamp": Time.get_unix_time_from_system(),
		"cache": cache.get_stats(),
		"security": SecurityConfig.get_stats()
	}

	if include_memory == "true":
		perf_data["memory"] = _get_memory_stats()

	if include_engine == "true":
		perf_data["engine"] = _get_engine_stats()

	response.send(200, JSON.stringify(perf_data))
	return true
```

---

## Creature Spawner Integration

### File: `scripts/planetary_survival/multiplayer/creature_spawner.gd` (if it exists)

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

func spawn_creature(creature_type: String, position: Vector3, health: float = 100.0) -> Dictionary:
	# Validate creature type
	var type_validation = InputValidator.validate_creature_type(creature_type)
	if not type_validation.valid:
		return {
			"success": false,
			"error": type_validation.error
		}

	# Validate position
	var pos_array = [position.x, position.y, position.z]
	var pos_validation = InputValidator.validate_position(pos_array)
	if not pos_validation.valid:
		return {
			"success": false,
			"error": pos_validation.error
		}

	# Validate health
	var health_validation = InputValidator.validate_health(health)
	if not health_validation.valid:
		return {
			"success": false,
			"error": health_validation.error
		}

	# Spawn creature with validated values
	var creature = _create_creature(type_validation.creature_type)
	creature.global_position = pos_validation.vector
	creature.health = health_validation.value

	return {
		"success": true,
		"creature_id": creature.get_instance_id()
	}
```

---

## Damage/Attack Endpoint Integration

### Example: Damage router (if exists)

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

func handle_damage_request(request: HttpRequest, response: GodottpdResponse) -> bool:
	# ... auth checks ...

	var body = request.get_body_parsed()
	if not body:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Invalid JSON body"
		}))
		return true

	# VALIDATE POSITION
	if not body.has("position"):
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Missing required field: position"
		}))
		return true

	var pos_validation = InputValidator.validate_position(body["position"])
	if not pos_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": pos_validation.error,
			"field": "position"
		}))
		return true

	# VALIDATE DAMAGE
	if not body.has("damage"):
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Missing required field: damage"
		}))
		return true

	var damage_validation = InputValidator.validate_damage(body["damage"])
	if not damage_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": damage_validation.error,
			"field": "damage"
		}))
		return true

	# VALIDATE RADIUS
	if not body.has("radius"):
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Missing required field: radius"
		}))
		return true

	var radius_validation = InputValidator.validate_radius(body["radius"])
	if not radius_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": radius_validation.error,
			"field": "radius"
		}))
		return true

	# Apply damage with validated values
	apply_area_damage(
		pos_validation.vector,
		damage_validation.value,
		radius_validation.value
	)

	response.send(200, JSON.stringify({
		"success": true,
		"position": {
			"x": pos_validation.vector.x,
			"y": pos_validation.vector.y,
			"z": pos_validation.vector.z
		},
		"damage": damage_validation.value,
		"radius": radius_validation.value
	}))
	return true
```

---

## BatchOperationsRouter Additional Validation

### File: `scripts/http_api/batch_operations_router.gd`

Already has some validation. Add more:

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

func _validate_batch_request(body: Dictionary) -> Dictionary:
	var result = {"valid": true, "error": ""}

	# ... existing checks ...

	# Validate mode parameter
	var mode = body.get("mode", "continue")
	var mode_validation = InputValidator.validate_string(mode, 32, "", "mode")
	if not mode_validation.valid:
		result.valid = false
		result.error = mode_validation.error
		return result

	# Validate against allowed modes
	var allowed_modes = ["transactional", "continue"]
	if not mode in allowed_modes:
		result.valid = false
		result.error = "Invalid mode. Must be 'transactional' or 'continue'"
		return result

	# Validate operations is array
	var operations = body.get("operations", [])
	var ops_validation = InputValidator.validate_array(operations, 50, "operations")
	if not ops_validation.valid:
		result.valid = false
		result.error = ops_validation.error
		return result

	# Validate each operation
	for i in range(operations.size()):
		var op = operations[i]

		# Validate action
		if not op.has("action"):
			result.valid = false
			result.error = "Operation %d missing 'action' field" % i
			return result

		var action = op.get("action")
		var action_validation = InputValidator.validate_string(action, 32, "", "action")
		if not action_validation.valid:
			result.valid = false
			result.error = "Operation %d: %s" % [i, action_validation.error]
			return result

		# Validate scene_path if present
		if op.has("scene_path"):
			var scene_path = op.get("scene_path")
			var scene_validation = InputValidator.validate_scene_path(scene_path)
			if not scene_validation.valid:
				result.valid = false
				result.error = "Operation %d: %s" % [i, scene_validation.error]
				return result

	return result
```

---

## General Pattern

For any new router endpoint:

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

func handle_endpoint(request: HttpRequest, response: GodottpdResponse) -> bool:
	# 1. AUTH CHECK (always first)
	if not SecurityConfig.validate_auth(request):
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	# 2. SIZE CHECK
	if not SecurityConfig.validate_request_size(request):
		response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
		return true

	# 3. PARSE BODY
	var body = request.get_body_parsed()
	if not body:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": "Invalid JSON body"
		}))
		return true

	# 4. VALIDATE EACH FIELD
	# String field
	if body.has("name"):
		var name_validation = InputValidator.validate_string(body["name"], 128, "", "name")
		if not name_validation.valid:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": name_validation.error,
				"field": "name"
			}))
			return true
		var name = name_validation.value

	# Numeric field
	if body.has("count"):
		var count_validation = InputValidator.validate_count(body["count"])
		if not count_validation.valid:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": count_validation.error,
				"field": "count"
			}))
			return true
		var count = count_validation.value

	# Vector field
	if body.has("position"):
		var pos_validation = InputValidator.validate_position(body["position"])
		if not pos_validation.valid:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": pos_validation.error,
				"field": "position"
			}))
			return true
		var position = pos_validation.vector

	# 5. PROCESS WITH VALIDATED DATA
	# ... business logic ...

	# 6. RETURN SUCCESS
	response.send(200, JSON.stringify({
		"success": true,
		# ... response data ...
	}))
	return true
```

---

## Validation Error Response Format

Always use this consistent format:

```json
{
	"error": "Bad Request",
	"message": "Detailed error message from validator",
	"field": "field_name",
	"timestamp": 1234567890
}
```

Example implementation:

```gdscript
func send_validation_error(response: GodottpdResponse, validation_result: Dictionary, field_name: String) -> void:
	response.send(400, JSON.stringify({
		"error": "Bad Request",
		"message": validation_result.error,
		"field": field_name,
		"timestamp": Time.get_unix_time_from_system()
	}))
```

---

## Checklist for Router Integration

- [ ] Import InputValidator at top of file
- [ ] Validate all string inputs (length, sanitization)
- [ ] Validate all numeric inputs (range, NaN/Inf)
- [ ] Validate all array inputs (size, element validation)
- [ ] Validate all path inputs (traversal, whitelist)
- [ ] Validate all enum inputs (whitelist)
- [ ] Return 400 Bad Request with detailed error
- [ ] Include field name in error response
- [ ] Log security events for injection attempts
- [ ] Add tests for new validation logic

---

## Testing Your Integration

```gdscript
# Test script example
extends GdUnitTestSuite

const YourRouter = preload("res://scripts/http_api/your_router.gd")

func test_validates_input():
	var router = YourRouter.new()
	var request = create_mock_request({
		"invalid_field": "'; DROP TABLE users; --"
	})
	var response = create_mock_response()

	router.handle(request, response)

	assert_that(response.code).is_equal(400)
	assert_that(response.body).contains("injection")
```

---

## Performance Tips

1. **Validate in order of likelihood to fail** - Check required fields first
2. **Fail fast** - Return error immediately on first validation failure
3. **Cache validation results** - If same value used multiple times
4. **Use appropriate validators** - Don't over-validate (e.g., don't validate SQL if not using DB)
5. **Log only security events** - Don't log every validation failure

---

## Common Mistakes to Avoid

1. ❌ **Using raw input without validation**
   ```gdscript
   var position = Vector3(body["x"], body["y"], body["z"])  # WRONG
   ```

2. ❌ **Partial validation**
   ```gdscript
   if body["count"] < 0:  # Only checking lower bound
       return_error()
   ```

3. ❌ **Ignoring validation result**
   ```gdscript
   var result = InputValidator.validate_position(pos)
   # Forgot to check result.valid!
   use_position(pos)  # WRONG
   ```

4. ❌ **Not returning detailed errors**
   ```gdscript
   return {"error": "Invalid input"}  # Too vague
   ```

5. ❌ **Validating after using**
   ```gdscript
   process_data(body["value"])
   InputValidator.validate_string(body["value"], 100)  # Too late!
   ```

---

**Remember:** Every input from HTTP requests is UNTRUSTED. Always validate BEFORE using.
