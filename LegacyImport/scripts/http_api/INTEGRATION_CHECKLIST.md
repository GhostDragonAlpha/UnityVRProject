# Input Validation Integration Checklist

This checklist ensures proper integration of the InputValidator into your HTTP API.

---

## Initial Setup

### 1. Initialize InputValidator on Startup

Add to your HTTP server initialization (likely in `GodotBridge._ready()` or similar):

```gdscript
# In godot_bridge.gd or http_server startup
const InputValidator = preload("res://scripts/http_api/input_validator.gd")
const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _ready():
	# ... existing code ...

	# Initialize InputValidator with scene whitelist
	var scene_whitelist = SecurityConfig.get_whitelist()
	InputValidator.initialize(scene_whitelist)

	print("[Security] InputValidator initialized with %d whitelisted scenes" % scene_whitelist.size())
```

### 2. Verify Whitelist Configuration

Check `scripts/http_api/security_config.gd` and ensure your scene whitelist is correct:

```gdscript
static var _scene_whitelist: Array[String] = [
	"res://vr_main.tscn",
	"res://node_3d.tscn",
	"res://test_scene.tscn",
	"res://scenes/",  # Directory whitelist (all scenes in dir)
	# Add your allowed scenes here
]
```

---

## Router Integration

For each router that accepts user input:

### ☐ Step 1: Import InputValidator

At the top of your router file:

```gdscript
const InputValidator = preload("res://scripts/http_api/input_validator.gd")
```

### ☐ Step 2: Identify All Input Points

List all fields from request body and query parameters:
- [ ] String fields (names, descriptions, etc.)
- [ ] Numeric fields (counts, values, etc.)
- [ ] Array fields (positions, lists, etc.)
- [ ] Path fields (scene paths, file paths, etc.)
- [ ] Enum fields (types, modes, etc.)

### ☐ Step 3: Add Validation for Each Field

For each field, add appropriate validation BEFORE using the value:

```gdscript
# Required field validation
if not body.has("field_name"):
	response.send(400, JSON.stringify({
		"error": "Bad Request",
		"message": "Missing required field: field_name"
	}))
	return true

# Type-specific validation
var validation = InputValidator.validate_<type>(body["field_name"], ...)
if not validation.valid:
	response.send(400, JSON.stringify({
		"error": "Bad Request",
		"message": validation.error,
		"field": "field_name"
	}))
	return true

# Use validated value
var field_value = validation.value  # or .vector, .creature_type, etc.
```

### ☐ Step 4: Test Each Validation

For each field, test with:
- [ ] Valid input (should succeed)
- [ ] Missing input (should fail if required)
- [ ] Out of range input (should fail)
- [ ] Invalid type input (should fail)
- [ ] Malicious input (should fail and log)

---

## Validation Type Reference

### Scene Paths
```gdscript
var result = InputValidator.validate_scene_path(scene_path)
# Returns: {valid: bool, error: String, sanitized_path: String}
# Use: result.sanitized_path
```

### Integers (counts, IDs, etc.)
```gdscript
var result = InputValidator.validate_integer(value, min, max, "field_name")
# Returns: {valid: bool, error: String, value: int}
# Use: result.value
```

### Floats (damage, radius, etc.)
```gdscript
var result = InputValidator.validate_float(value, min, max, "field_name")
# Returns: {valid: bool, error: String, value: float}
# Use: result.value
```

### Positions
```gdscript
var result = InputValidator.validate_position([x, y, z])
# Returns: {valid: bool, error: String, vector: Vector3}
# Use: result.vector
```

### Rotations
```gdscript
var result = InputValidator.validate_rotation([x, y, z])
# Returns: {valid: bool, error: String, vector: Vector3}
# Use: result.vector
```

### Scales
```gdscript
var result = InputValidator.validate_scale([x, y, z])
# Returns: {valid: bool, error: String, vector: Vector3}
# Use: result.vector
```

### Strings (names, descriptions, etc.)
```gdscript
var result = InputValidator.validate_string(value, max_length, "", "field_name")
# Returns: {valid: bool, error: String, value: String}
# Use: result.value
```

### Creature Types
```gdscript
var result = InputValidator.validate_creature_type(type)
# Returns: {valid: bool, error: String, creature_type: String}
# Use: result.creature_type
```

### Damage
```gdscript
var result = InputValidator.validate_damage(value)
# Returns: {valid: bool, error: String, value: float}
# Use: result.value
```

### Radius
```gdscript
var result = InputValidator.validate_radius(value)
# Returns: {valid: bool, error: String, value: float}
# Use: result.value
```

### Health
```gdscript
var result = InputValidator.validate_health(value)
# Returns: {valid: bool, error: String, value: float}
# Use: result.value
```

### Counts/Quantities
```gdscript
var result = InputValidator.validate_count(value)
# Returns: {valid: bool, error: String, value: int}
# Use: result.value
```

### Arrays
```gdscript
var result = InputValidator.validate_array(array, max_size, "field_name")
# Returns: {valid: bool, error: String, array: Array}
# Use: result.array
```

### JSON Payloads
```gdscript
var result = InputValidator.validate_json_payload(json_string)
# Returns: {valid: bool, error: String, data: Variant}
# Use: result.data
```

---

## Common Patterns

### Pattern 1: Required Field with Validation
```gdscript
# Check field exists
if not body.has("position"):
	response.send(400, JSON.stringify({
		"error": "Bad Request",
		"message": "Missing required field: position"
	}))
	return true

# Validate field
var pos_validation = InputValidator.validate_position(body["position"])
if not pos_validation.valid:
	response.send(400, JSON.stringify({
		"error": "Bad Request",
		"message": pos_validation.error,
		"field": "position"
	}))
	return true

# Use validated value
var position = pos_validation.vector
```

### Pattern 2: Optional Field with Validation
```gdscript
var health = 100.0  # Default value

if body.has("health"):
	var health_validation = InputValidator.validate_health(body["health"])
	if not health_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": health_validation.error,
			"field": "health"
		}))
		return true
	health = health_validation.value
```

### Pattern 3: Sanitizing User Content
```gdscript
var description = body.get("description", "")
if not description.is_empty():
	# Sanitize before storing
	description = InputValidator.sanitize_user_input(description)

	# Then validate length
	var desc_validation = InputValidator.validate_string(description, 1024, "", "description")
	if not desc_validation.valid:
		response.send(400, JSON.stringify({
			"error": "Bad Request",
			"message": desc_validation.error,
			"field": "description"
		}))
		return true
```

### Pattern 4: Validating Multiple Related Fields
```gdscript
# Validate all fields first, then use values
var validations = []

# Position
var pos_validation = InputValidator.validate_position(body.get("position"))
if not pos_validation.valid:
	return_error(pos_validation.error, "position")

# Damage
var damage_validation = InputValidator.validate_damage(body.get("damage"))
if not damage_validation.valid:
	return_error(damage_validation.error, "damage")

# Radius
var radius_validation = InputValidator.validate_radius(body.get("radius"))
if not radius_validation.valid:
	return_error(radius_validation.error, "radius")

# All valid - use values
apply_damage(
	pos_validation.vector,
	damage_validation.value,
	radius_validation.value
)
```

---

## Testing Checklist

For each endpoint with validation:

### Unit Tests
- [ ] Test with valid input (should succeed)
- [ ] Test with missing required field (should return 400)
- [ ] Test with null value (should return 400)
- [ ] Test with wrong type (should return 400)
- [ ] Test with out of range value (should return 400)
- [ ] Test with boundary min value (should succeed)
- [ ] Test with boundary max value (should succeed)
- [ ] Test with NaN (numeric fields, should return 400)
- [ ] Test with Infinity (numeric fields, should return 400)
- [ ] Test with path traversal (path fields, should return 400)
- [ ] Test with null byte (string fields, should return 400)
- [ ] Test with SQL injection pattern (should return 400)
- [ ] Test with command injection pattern (should return 400)

### Integration Tests
- [ ] Test full request/response cycle
- [ ] Verify error messages are clear
- [ ] Verify field names in error responses
- [ ] Check security event logging
- [ ] Verify validated values are used correctly

### Manual Tests
- [ ] Test via curl/Postman
- [ ] Test from client application
- [ ] Test with production-like data
- [ ] Performance test (validation should be < 5ms per request)

---

## Error Response Format

Always use this consistent format:

```json
{
	"error": "Bad Request",
	"message": "Specific error from validator",
	"field": "field_name",
	"timestamp": 1234567890
}
```

Implementation:

```gdscript
func send_validation_error(response, validation_result: Dictionary, field_name: String):
	response.send(400, JSON.stringify({
		"error": "Bad Request",
		"message": validation_result.error,
		"field": field_name,
		"timestamp": Time.get_unix_time_from_system()
	}))
```

---

## Security Event Logging

Validation failures that indicate attacks will be automatically logged:

```gdscript
# Logged automatically by InputValidator
[SECURITY] path_traversal_attempt: {"path": "res://../../../etc/passwd"}
[SECURITY] sql_injection_attempt: {"field": "search", "pattern": "' OR "}
[SECURITY] command_injection_attempt: {"field": "command", "char": ";"}
[SECURITY] null_byte_injection: {"path": "file\x00.txt"}
[SECURITY] nan_detected: {"field": "damage"}
```

No additional code required - logging happens inside validators.

---

## Common Mistakes to Avoid

### ❌ Don't: Use input before validating
```gdscript
var position = Vector3(body["x"], body["y"], body["z"])  # WRONG!
process_position(position)
```

### ✅ Do: Validate first, then use
```gdscript
var pos_validation = InputValidator.validate_position(body["position"])
if not pos_validation.valid:
	return_error(pos_validation.error, "position")
var position = pos_validation.vector  # Safe to use
process_position(position)
```

### ❌ Don't: Ignore validation result
```gdscript
InputValidator.validate_position(body["position"])  # Result ignored!
var position = body["position"]  # Using unvalidated value
```

### ✅ Do: Check validation result
```gdscript
var validation = InputValidator.validate_position(body["position"])
if validation.valid:
	use_position(validation.vector)
else:
	return_error(validation.error)
```

### ❌ Don't: Partial validation
```gdscript
if body["count"] < 0:  # Only checking lower bound
	return_error("Count must be positive")
# Missing upper bound check, type check, NaN check
```

### ✅ Do: Comprehensive validation
```gdscript
var validation = InputValidator.validate_count(body["count"])
# Checks: type, range (0-1000), NaN, Infinity
if not validation.valid:
	return_error(validation.error)
```

---

## Performance Optimization

### Tips
1. **Validate in order of failure likelihood** - Check required fields first
2. **Fail fast** - Return error on first validation failure
3. **Don't over-validate** - Only use validators needed for your use case
4. **Cache validation results** - If same value validated multiple times

### Example: Fail Fast
```gdscript
# Good - returns immediately on first error
if not body.has("position"):
	return_error("Missing position")

var pos_validation = InputValidator.validate_position(body["position"])
if not pos_validation.valid:
	return_error(pos_validation.error)

if not body.has("damage"):
	return_error("Missing damage")

var damage_validation = InputValidator.validate_damage(body["damage"])
if not damage_validation.valid:
	return_error(damage_validation.error)

# Only reaches here if all validations passed
```

---

## Maintenance

### Adding New Validators
1. Add validation method to `input_validator.gd`
2. Add tests to `test_input_validation.gd`
3. Update documentation
4. Integrate into relevant routers

### Updating Constraints
1. Modify constants in `input_validator.gd`
2. Update tests with new ranges
3. Document changes in CHANGELOG

### Adding to Whitelists
```gdscript
# Scene whitelist - in security_config.gd
static var _scene_whitelist: Array[String] = [
	"res://new_scene.tscn",  # Add here
]

# Creature type whitelist - via code
InputValidator.add_creature_type("new_type")
```

---

## Completion Checklist

### Initial Setup
- [ ] InputValidator initialized on server startup
- [ ] Scene whitelist configured
- [ ] Creature type whitelist configured

### Router Integration
- [ ] scene_router.gd ✅ (completed)
- [ ] batch_operations_router.gd ✅ (completed)
- [ ] webhook_router.gd (see examples)
- [ ] admin_router.gd (see examples)
- [ ] performance_router.gd (see examples)
- [ ] Any creature/spawning endpoints
- [ ] Any custom endpoints

### Testing
- [ ] Unit tests pass (73+ tests)
- [ ] Integration tests pass
- [ ] Manual tests completed
- [ ] Performance verified (< 5ms overhead)

### Documentation
- [ ] Code comments added
- [ ] API documentation updated
- [ ] Integration examples reviewed

### Deployment
- [ ] Run full test suite before deploy
- [ ] Monitor security logs after deploy
- [ ] Verify error responses in production

---

## Quick Reference Card

```gdscript
# Import
const InputValidator = preload("res://scripts/http_api/input_validator.gd")

# Scene Path
InputValidator.validate_scene_path(path) -> {valid, error, sanitized_path}

# Numbers
InputValidator.validate_integer(val, min, max, name) -> {valid, error, value}
InputValidator.validate_float(val, min, max, name) -> {valid, error, value}

# Vectors
InputValidator.validate_position(array) -> {valid, error, vector}
InputValidator.validate_rotation(array) -> {valid, error, vector}
InputValidator.validate_scale(array) -> {valid, error, vector}

# Strings
InputValidator.validate_string(str, max_len, pattern, name) -> {valid, error, value}
InputValidator.sanitize_user_input(str) -> String

# Specialized
InputValidator.validate_creature_type(type) -> {valid, error, creature_type}
InputValidator.validate_damage(val) -> {valid, error, value}
InputValidator.validate_radius(val) -> {valid, error, value}
InputValidator.validate_health(val) -> {valid, error, value}
InputValidator.validate_count(val) -> {valid, error, value}

# Collections
InputValidator.validate_array(arr, max_size, name) -> {valid, error, array}
InputValidator.validate_json_payload(json_str) -> {valid, error, data}

# Security
InputValidator.validate_sql_parameter(val, name) -> {valid, error, value}
InputValidator.validate_command_parameter(val, name) -> {valid, error, value}

# Error Response
response.send(400, JSON.stringify({
	"error": "Bad Request",
	"message": validation.error,
	"field": "field_name"
}))
```

---

**Remember:** EVERY input from HTTP requests is UNTRUSTED. ALWAYS validate BEFORE using!

---

**Questions?** See documentation in `docs/security/INPUT_VALIDATION_IMPLEMENTATION.md`
