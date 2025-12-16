extends RefCounted
class_name InputValidator

const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")

## InputValidator - Centralized input validation for HTTP API
## Implements comprehensive validation to prevent injection attacks and crashes
## Addresses VULN-005, VULN-006, VULN-009 (SQL injection, input validation, path traversal)

# =============================================================================
# VALIDATION CONSTRAINTS
# =============================================================================

# Numeric range constraints
const MAX_POSITION_COORD: float = 100000.0
const MIN_POSITION_COORD: float = -100000.0
const MAX_ROTATION_DEGREES: float = 360.0
const MIN_ROTATION_DEGREES: float = -360.0
const MAX_SCALE: float = 100.0
const MIN_SCALE: float = 0.001
const MAX_DAMAGE: float = 10000.0
const MIN_DAMAGE: float = 0.0
const MAX_RADIUS: float = 1000.0
const MIN_RADIUS: float = 0.0
const MAX_HEALTH: float = 100000.0
const MIN_HEALTH: float = 0.0
const MAX_COUNT: int = 1000
const MIN_COUNT: int = 0

# String constraints
const MAX_STRING_LENGTH: int = 256
const MAX_SCENE_PATH_LENGTH: int = 256
const MAX_CREATURE_TYPE_LENGTH: int = 64
const MAX_NAME_LENGTH: int = 128
const MAX_DESCRIPTION_LENGTH: int = 1024

# Array constraints
const MAX_ARRAY_SIZE: int = 100
const MAX_VECTOR3_SIZE: int = 3

# JSON constraints
const MAX_JSON_DEPTH: int = 10
const MAX_JSON_SIZE: int = 1048576  # 1MB

# Scene path whitelist (loaded from SecurityConfig)
static var _scene_whitelist: Array[String] = []

# Allowed creature types whitelist
static var _creature_types_whitelist: Array[String] = [
	"hostile",
	"friendly",
	"neutral",
	"boss",
	"companion",
	"passive",
	"aggressive"
]

# =============================================================================
# SCENE PATH VALIDATION
# =============================================================================

## Validate scene path with comprehensive checks
## Prevents path traversal, enforces whitelist, validates format
static func validate_scene_path(path: String) -> Dictionary:
	var result = {"valid": true, "error": "", "sanitized_path": path}

	# Check for null or empty
	if path == null or path.is_empty():
		result.valid = false
		result.error = "Scene path cannot be empty"
		return result

	# Check length
	if path.length() > MAX_SCENE_PATH_LENGTH:
		result.valid = false
		result.error = "Scene path exceeds maximum length of %d characters" % MAX_SCENE_PATH_LENGTH
		return result

	# Check format - must start with res://
	if not path.begins_with("res://"):
		result.valid = false
		result.error = "Scene path must start with 'res://'"
		return result

	# Check format - must end with .tscn
	if not path.ends_with(".tscn"):
		result.valid = false
		result.error = "Scene path must end with '.tscn'"
		return result

	# Check for path traversal attempts
	if "../" in path or "..\\" in path:
		result.valid = false
		result.error = "Path traversal detected (../ or ..)"
		_log_security_event("path_traversal_attempt", {"path": path})
		return result

	# Check for null bytes (injection attempt)
	var null_byte = char(0)
	if null_byte in path:
		result.valid = false
		result.error = "Null byte detected in path"
		_log_security_event("null_byte_injection", {"path": path})
		return result

	# Check for dangerous characters
	var dangerous_chars = ["<", ">", "|", "&", ";", "`", "$", "(", ")", "{", "}"]
	for char in dangerous_chars:
		if char in path:
			result.valid = false
			result.error = "Dangerous character detected: %s" % char
			_log_security_event("dangerous_char_in_path", {"path": path, "char": char})
			return result

	# Check whitelist (if loaded)
	if _scene_whitelist.size() > 0:
		var is_whitelisted = false
		for allowed_path in _scene_whitelist:
			if path == allowed_path:
				is_whitelisted = true
				break
			# Allow scenes in whitelisted directories
			if allowed_path.ends_with("/") and path.begins_with(allowed_path):
				is_whitelisted = true
				break

		if not is_whitelisted:
			result.valid = false
			result.error = "Scene not in whitelist: %s" % path
			_log_security_event("scene_not_whitelisted", {"path": path})
			return result

	# Check if file exists
	if not ResourceLoader.exists(path):
		result.valid = false
		result.error = "Scene file not found: %s" % path
		return result

	return result


# =============================================================================
# NUMERIC VALIDATION
# =============================================================================

## Validate integer with range checking
static func validate_integer(value, min_value: int, max_value: int, field_name: String = "value") -> Dictionary:
	var result = {"valid": true, "error": "", "value": 0}

	# Check type and convert
	var int_value: int
	if typeof(value) == TYPE_INT:
		int_value = value
	elif typeof(value) == TYPE_FLOAT:
		int_value = int(value)
	elif typeof(value) == TYPE_STRING:
		if not value.is_valid_int():
			result.valid = false
			result.error = "%s must be a valid integer" % field_name
			return result
		int_value = value.to_int()
	else:
		result.valid = false
		result.error = "%s must be an integer" % field_name
		return result

	# Range check
	if int_value < min_value or int_value > max_value:
		result.valid = false
		result.error = "%s out of range [%d, %d]" % [field_name, min_value, max_value]
		return result

	result.value = int_value
	return result


## Validate float with range checking and NaN/Inf detection
static func validate_float(value, min_value: float, max_value: float, field_name: String = "value") -> Dictionary:
	var result = {"valid": true, "error": "", "value": 0.0}

	# Check type and convert
	var float_value: float
	if typeof(value) == TYPE_FLOAT:
		float_value = value
	elif typeof(value) == TYPE_INT:
		float_value = float(value)
	elif typeof(value) == TYPE_STRING:
		if not value.is_valid_float():
			result.valid = false
			result.error = "%s must be a valid float" % field_name
			return result
		float_value = value.to_float()
	else:
		result.valid = false
		result.error = "%s must be a number" % field_name
		return result

	# Check for NaN and Infinity
	if is_nan(float_value):
		result.valid = false
		result.error = "%s contains NaN (not a number)" % field_name
		_log_security_event("nan_detected", {"field": field_name})
		return result

	if is_inf(float_value):
		result.valid = false
		result.error = "%s contains Infinity" % field_name
		_log_security_event("infinity_detected", {"field": field_name})
		return result

	# Range check
	if float_value < min_value or float_value > max_value:
		result.valid = false
		result.error = "%s out of range [%f, %f]" % [field_name, min_value, max_value]
		return result

	result.value = float_value
	return result


# =============================================================================
# VECTOR VALIDATION
# =============================================================================

## Validate Vector3 from array with range checking
static func validate_vector3(value, min_coord: float = MIN_POSITION_COORD, max_coord: float = MAX_POSITION_COORD, field_name: String = "vector3") -> Dictionary:
	var result = {"valid": true, "error": "", "vector": Vector3.ZERO}

	# Check if array
	if typeof(value) != TYPE_ARRAY:
		result.valid = false
		result.error = "%s must be an array [x, y, z]" % field_name
		return result

	# Check array size
	if value.size() != 3:
		result.valid = false
		result.error = "%s must have exactly 3 elements [x, y, z]" % field_name
		return result

	# Validate each coordinate
	var coords = []
	for i in range(3):
		var coord_name = ["x", "y", "z"][i]
		var coord_validation = validate_float(
			value[i],
			min_coord,
			max_coord,
			"%s.%s" % [field_name, coord_name]
		)

		if not coord_validation.valid:
			return coord_validation

		coords.append(coord_validation.value)

	result.vector = Vector3(coords[0], coords[1], coords[2])
	return result


## Validate position vector
static func validate_position(position_array, field_name: String = "position") -> Dictionary:
	return validate_vector3(
		position_array,
		MIN_POSITION_COORD,
		MAX_POSITION_COORD,
		field_name
	)


## Validate rotation vector (degrees)
static func validate_rotation(rotation_array, field_name: String = "rotation") -> Dictionary:
	return validate_vector3(
		rotation_array,
		MIN_ROTATION_DEGREES,
		MAX_ROTATION_DEGREES,
		field_name
	)


## Validate scale vector
static func validate_scale(scale_array, field_name: String = "scale") -> Dictionary:
	return validate_vector3(
		scale_array,
		MIN_SCALE,
		MAX_SCALE,
		field_name
	)


# =============================================================================
# STRING VALIDATION
# =============================================================================

## Validate string with length and pattern checking
static func validate_string(value: String, max_length: int, pattern: String = "", field_name: String = "string") -> Dictionary:
	var result = {"valid": true, "error": "", "value": value}

	# Check for null
	if value == null:
		result.valid = false
		result.error = "%s cannot be null" % field_name
		return result

	# Check length
	if value.length() > max_length:
		result.valid = false
		result.error = "%s exceeds maximum length of %d characters" % [field_name, max_length]
		return result

	# Check for null bytes
	var null_byte = char(0)
	if null_byte in value:
		result.valid = false
		result.error = "%s contains null byte" % field_name
		_log_security_event("null_byte_in_string", {"field": field_name})
		return result

	# Pattern validation (if provided)
	if not pattern.is_empty():
		var regex = RegEx.new()
		regex.compile(pattern)
		if not regex.search(value):
			result.valid = false
			result.error = "%s does not match required pattern" % field_name
			return result

	return result


## Sanitize user input for safe storage/display
static func sanitize_user_input(input: String) -> String:
	if input == null:
		return ""

	# Remove null bytes
	var null_byte = char(0)
	input = input.replace(null_byte, "")

	# Remove control characters (except newline, tab, carriage return)
	var sanitized = ""
	for i in range(input.length()):
		var c = input[i]
		var code = c.unicode_at(0)

		# Allow printable ASCII, newline, tab, carriage return
		if (code >= 32 and code <= 126) or code == 10 or code == 9 or code == 13:
			sanitized += c

	return sanitized


## Validate creature type against whitelist
static func validate_creature_type(creature_type: String) -> Dictionary:
	var result = {"valid": true, "error": "", "creature_type": creature_type}

	# Check for null or empty
	if creature_type == null or creature_type.is_empty():
		result.valid = false
		result.error = "Creature type cannot be empty"
		return result

	# Check length
	if creature_type.length() > MAX_CREATURE_TYPE_LENGTH:
		result.valid = false
		result.error = "Creature type exceeds maximum length of %d characters" % MAX_CREATURE_TYPE_LENGTH
		return result

	# Check for path traversal
	if "../" in creature_type or "..\\" in creature_type:
		result.valid = false
		result.error = "Invalid characters in creature type (path traversal detected)"
		_log_security_event("creature_type_path_traversal", {"type": creature_type})
		return result

	# Check for dangerous characters
	var allowed_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
	for i in range(creature_type.length()):
		var c = creature_type[i]
		if not c in allowed_chars:
			result.valid = false
			result.error = "Invalid character in creature type: %s" % c
			_log_security_event("creature_type_invalid_char", {"type": creature_type, "char": c})
			return result

	# Check against whitelist
	if not creature_type in _creature_types_whitelist:
		result.valid = false
		result.error = "Unknown creature type: %s (allowed: %s)" % [creature_type, ", ".join(_creature_types_whitelist)]
		_log_security_event("creature_type_not_whitelisted", {"type": creature_type})
		return result

	return result


# =============================================================================
# SPECIALIZED VALIDATORS
# =============================================================================

## Validate damage value
static func validate_damage(damage_value, field_name: String = "damage") -> Dictionary:
	return validate_float(damage_value, MIN_DAMAGE, MAX_DAMAGE, field_name)


## Validate radius value
static func validate_radius(radius_value, field_name: String = "radius") -> Dictionary:
	return validate_float(radius_value, MIN_RADIUS, MAX_RADIUS, field_name)


## Validate health value
static func validate_health(health_value, field_name: String = "health") -> Dictionary:
	return validate_float(health_value, MIN_HEALTH, MAX_HEALTH, field_name)


## Validate count/quantity
static func validate_count(count_value, field_name: String = "count") -> Dictionary:
	return validate_integer(count_value, MIN_COUNT, MAX_COUNT, field_name)


# =============================================================================
# ARRAY VALIDATION
# =============================================================================

## Validate array size
static func validate_array(value, max_size: int, field_name: String = "array") -> Dictionary:
	var result = {"valid": true, "error": "", "array": value}

	# Check if array
	if typeof(value) != TYPE_ARRAY:
		result.valid = false
		result.error = "%s must be an array" % field_name
		return result

	# Check size
	if value.size() > max_size:
		result.valid = false
		result.error = "%s exceeds maximum size of %d elements" % [field_name, max_size]
		return result

	return result


# =============================================================================
# JSON VALIDATION
# =============================================================================

## Validate JSON payload size and structure
static func validate_json_payload(json_string: String, max_size: int = MAX_JSON_SIZE) -> Dictionary:
	var result = {"valid": true, "error": "", "data": null}

	# Check size
	if json_string.length() > max_size:
		result.valid = false
		result.error = "JSON payload too large (max %d bytes)" % max_size
		return result

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		result.valid = false
		result.error = "Invalid JSON: %s" % json.get_error_message()
		return result

	var data = json.data

	# Check nesting depth
	var max_depth = _check_nesting_depth(data)
	if max_depth > MAX_JSON_DEPTH:
		result.valid = false
		result.error = "JSON nesting too deep (max %d levels)" % MAX_JSON_DEPTH
		return result

	result.data = data
	return result


## Check JSON nesting depth recursively
static func _check_nesting_depth(data, current_depth: int = 0) -> int:
	# Safety limit to prevent stack overflow
	if current_depth > 20:
		return current_depth

	var max_depth = current_depth

	if typeof(data) == TYPE_DICTIONARY:
		for key in data:
			var child_depth = _check_nesting_depth(data[key], current_depth + 1)
			max_depth = max(max_depth, child_depth)
	elif typeof(data) == TYPE_ARRAY:
		for item in data:
			var child_depth = _check_nesting_depth(item, current_depth + 1)
			max_depth = max(max_depth, child_depth)

	return max_depth


# =============================================================================
# SQL INJECTION PREVENTION (for future database integration)
# =============================================================================

## Validate SQL parameter (basic validation - use parameterized queries in practice)
static func validate_sql_parameter(value: String, field_name: String = "parameter") -> Dictionary:
	var result = {"valid": true, "error": "", "value": value}

	# Check for SQL injection patterns
	var dangerous_patterns = [
		"';", "'--", "' OR ", "' AND ", "UNION SELECT", "DROP TABLE",
		"INSERT INTO", "DELETE FROM", "UPDATE ", "EXEC ", "EXECUTE "
	]

	var value_upper = value.to_upper()
	for pattern in dangerous_patterns:
		if pattern in value_upper:
			result.valid = false
			result.error = "Potential SQL injection detected in %s" % field_name
			_log_security_event("sql_injection_attempt", {"field": field_name, "pattern": pattern})
			return result

	return result


# =============================================================================
# COMMAND INJECTION PREVENTION
# =============================================================================

## Validate command parameter to prevent command injection
static func validate_command_parameter(value: String, field_name: String = "parameter") -> Dictionary:
	var result = {"valid": true, "error": "", "value": value}

	# Check for command injection characters
	var dangerous_chars = [";", "&", "|", "`", "$", "(", ")", "<", ">", "\n", "\r"]
	for char in dangerous_chars:
		if char in value:
			result.valid = false
			result.error = "Dangerous character detected in %s: %s" % [field_name, char]
			_log_security_event("command_injection_attempt", {"field": field_name, "char": char})
			return result

	return result


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

## Initialize whitelist from SecurityConfig
static func initialize(scene_whitelist: Array[String] = []) -> void:
	_scene_whitelist = scene_whitelist.duplicate()
	print("[InputValidator] Initialized with %d whitelisted scenes" % _scene_whitelist.size())


## Add creature type to whitelist
static func add_creature_type(creature_type: String) -> void:
	if not creature_type in _creature_types_whitelist:
		_creature_types_whitelist.append(creature_type)
		print("[InputValidator] Added creature type to whitelist: %s" % creature_type)


## Get creature type whitelist
static func get_creature_types() -> Array[String]:
	return _creature_types_whitelist.duplicate()


## Log security event
static func _log_security_event(event_type: String, details: Dictionary) -> void:
	# Log to console
	push_warning("[SECURITY] %s: %s" % [event_type, JSON.stringify(details)])

	# Log security event to audit logger
	SimpleAuditLogger.log_warn("UNKNOWN", "/", event_type, details)
