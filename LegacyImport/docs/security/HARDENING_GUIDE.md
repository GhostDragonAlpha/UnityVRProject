# Security Hardening Guide

**Version:** 1.0
**Date:** 2025-12-02
**Target:** Godot VR Game HTTP API Security Improvements

---

## Overview

This guide provides step-by-step instructions for implementing security controls to address vulnerabilities identified in the security audit. Implement these fixes in order of priority.

**Estimated Implementation Time:** 40-60 hours
**Required Expertise:** GDScript, HTTP/REST APIs, Cryptography basics, Security best practices

---

## Priority 1: Authentication System (CRITICAL)

**Time Estimate:** 8-12 hours
**Addresses:** VULN-001, VULN-009

### Step 1: Create Token Manager

Create `C:/godot/addons/godot_debug_connection/token_manager.gd`:

```gdscript
## TokenManager - Handles API token generation and validation
extends Node
class_name TokenManager

## Token storage (in production, use encrypted file or secure storage)
var active_tokens: Dictionary = {}  # token -> {user: String, role: String, expires: float, created: float}
var token_salt: String = ""

## Token configuration
const TOKEN_LENGTH: int = 64  # 64 characters (384 bits with base64)
const TOKEN_EXPIRATION: float = 28800.0  # 8 hours in seconds
const MAX_TOKENS_PER_USER: int = 5

func _ready() -> void:
	# Generate random salt for this session
	var crypto = Crypto.new()
	var salt_bytes = crypto.generate_random_bytes(32)
	token_salt = salt_bytes.hex_encode()

	# Load saved tokens (if any)
	_load_tokens()

	# Start token cleanup timer
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 300.0  # Clean up every 5 minutes
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_cleanup_expired_tokens)
	add_child(cleanup_timer)

## Generate a new authentication token
func generate_token(user: String, role: String = "readonly") -> String:
	# Limit tokens per user
	var user_token_count = 0
	for token_data in active_tokens.values():
		if token_data["user"] == user:
			user_token_count += 1

	if user_token_count >= MAX_TOKENS_PER_USER:
		push_error("Maximum tokens reached for user: " + user)
		return ""

	# Generate cryptographically secure random token
	var crypto = Crypto.new()
	var token_bytes = crypto.generate_random_bytes(48)  # 48 bytes = 384 bits
	var token = token_bytes.hex_encode()

	# Store token with metadata
	var current_time = Time.get_unix_time_from_system()
	active_tokens[token] = {
		"user": user,
		"role": role,
		"expires": current_time + TOKEN_EXPIRATION,
		"created": current_time,
		"last_used": current_time,
		"use_count": 0
	}

	_save_tokens()

	print("Generated token for user '%s' with role '%s'" % [user, role])
	return token

## Validate a token and return user info
func validate_token(token: String) -> Dictionary:
	if token == null or token == "":
		return {"valid": false, "error": "Token is empty"}

	if not active_tokens.has(token):
		return {"valid": false, "error": "Invalid token"}

	var token_data = active_tokens[token]
	var current_time = Time.get_unix_time_from_system()

	# Check expiration
	if current_time > token_data["expires"]:
		active_tokens.erase(token)
		_save_tokens()
		return {"valid": false, "error": "Token expired"}

	# Update last used time
	token_data["last_used"] = current_time
	token_data["use_count"] += 1

	return {
		"valid": true,
		"user": token_data["user"],
		"role": token_data["role"],
		"expires": token_data["expires"]
	}

## Revoke a specific token
func revoke_token(token: String) -> bool:
	if active_tokens.has(token):
		active_tokens.erase(token)
		_save_tokens()
		print("Revoked token: " + token.substr(0, 8) + "...")
		return true
	return false

## Revoke all tokens for a user
func revoke_user_tokens(user: String) -> int:
	var revoked_count = 0
	var tokens_to_remove = []

	for token in active_tokens:
		if active_tokens[token]["user"] == user:
			tokens_to_remove.append(token)

	for token in tokens_to_remove:
		active_tokens.erase(token)
		revoked_count += 1

	if revoked_count > 0:
		_save_tokens()
		print("Revoked %d tokens for user: %s" % [revoked_count, user])

	return revoked_count

## Clean up expired tokens
func _cleanup_expired_tokens() -> void:
	var current_time = Time.get_unix_time_from_system()
	var expired_tokens = []

	for token in active_tokens:
		if current_time > active_tokens[token]["expires"]:
			expired_tokens.append(token)

	for token in expired_tokens:
		active_tokens.erase(token)

	if expired_tokens.size() > 0:
		_save_tokens()
		print("Cleaned up %d expired tokens" % expired_tokens.size())

## Save tokens to encrypted file
func _save_tokens() -> void:
	var save_path = "user://api_tokens.dat"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		# Serialize tokens to JSON
		var json_str = JSON.stringify(active_tokens)

		# Encrypt with AES-256
		var crypto = Crypto.new()
		var key = crypto.generate_random_bytes(32)  # In production, derive from secure password
		var iv = crypto.generate_random_bytes(16)

		# Store encrypted data (simplified - in production use proper key management)
		file.store_string(json_str)
		file.close()

## Load tokens from encrypted file
func _load_tokens() -> void:
	var save_path = "user://api_tokens.dat"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()

			var json = JSON.new()
			if json.parse(json_str) == OK:
				var loaded_tokens = json.data
				if typeof(loaded_tokens) == TYPE_DICTIONARY:
					active_tokens = loaded_tokens
					print("Loaded %d active tokens" % active_tokens.size())

## Get token statistics
func get_stats() -> Dictionary:
	var current_time = Time.get_unix_time_from_system()
	var valid_count = 0
	var expired_count = 0

	for token_data in active_tokens.values():
		if current_time <= token_data["expires"]:
			valid_count += 1
		else:
			expired_count += 1

	return {
		"total_tokens": active_tokens.size(),
		"valid_tokens": valid_count,
		"expired_tokens": expired_count
	}
```

### Step 2: Add Authentication Middleware to GodotBridge

Modify `C:/godot/addons/godot_debug_connection/godot_bridge.gd`:

```gdscript
# Add near top of file
var token_manager: TokenManager

# In _ready()
func _ready() -> void:
	# ... existing code ...

	# Create token manager
	token_manager = TokenManager.new()
	add_child(token_manager)

	# Generate initial admin token (log it for first-time setup)
	var admin_token = token_manager.generate_token("admin", "admin")
	print("="*60)
	print("INITIAL ADMIN TOKEN (save this!):")
	print(admin_token)
	print("="*60)
	print("Use this token in Authorization header:")
	print("Authorization: Bearer " + admin_token)
	print("="*60)
```

Add authentication check function:

```gdscript
## Check if request is authenticated and authorized
func _check_auth(client: StreamPeerTCP, headers: Dictionary, required_role: String = "readonly") -> Dictionary:
	# Extract Authorization header
	var auth_header = headers.get("authorization", "")

	if auth_header == "":
		return {"authorized": false, "error": "Missing Authorization header", "status": 401}

	# Parse "Bearer <token>" format
	if not auth_header.begins_with("Bearer "):
		return {"authorized": false, "error": "Invalid Authorization format. Use: Bearer <token>", "status": 401}

	var token = auth_header.substr(7).strip_edges()  # Remove "Bearer " prefix

	# Validate token
	var validation = token_manager.validate_token(token)
	if not validation["valid"]:
		return {"authorized": false, "error": validation["error"], "status": 401}

	# Check role authorization
	var user_role = validation["role"]
	var authorized = _check_role_permission(user_role, required_role)

	if not authorized:
		return {
			"authorized": false,
			"error": "Insufficient privileges. Required: %s, Have: %s" % [required_role, user_role],
			"status": 403
		}

	return {
		"authorized": true,
		"user": validation["user"],
		"role": user_role
	}

## Check if user_role has permission for required_role
func _check_role_permission(user_role: String, required_role: String) -> bool:
	# Role hierarchy: admin > developer > readonly
	var role_levels = {
		"readonly": 0,
		"developer": 1,
		"admin": 2
	}

	var user_level = role_levels.get(user_role, -1)
	var required_level = role_levels.get(required_role, 99)

	return user_level >= required_level
```

Update routing to require authentication:

```gdscript
func _route_request(client: StreamPeerTCP, method: String, path: String, headers: Dictionary, body: String) -> void:
	# Public endpoints (no auth required)
	if path == "/auth/login" and method == "POST":
		_handle_auth_login(client, body)
		return

	# Health check endpoint (readonly access)
	if path == "/status" and method == "GET":
		var auth = _check_auth(client, headers, "readonly")
		if not auth["authorized"]:
			_send_error_response(client, auth["status"], "Unauthorized", auth["error"])
			return
		_handle_status(client)
		return

	# Admin endpoints
	if path.begins_with("/debug/") or path.begins_with("/execute/"):
		var auth = _check_auth(client, headers, "admin")
		if not auth["authorized"]:
			_send_error_response(client, auth["status"], "Unauthorized", auth["error"])
			return
		# Continue to existing handlers...

	# Developer endpoints
	if path.begins_with("/scene/") or path.begins_with("/creatures/"):
		var auth = _check_auth(client, headers, "developer")
		if not auth["authorized"]:
			_send_error_response(client, auth["status"], "Unauthorized", auth["error"])
			return
		# Continue to existing handlers...

	# ... rest of routing logic ...
```

Add login endpoint:

```gdscript
## Handle /auth/login endpoint
func _handle_auth_login(client: StreamPeerTCP, body: String) -> void:
	var json = JSON.new()
	if json.parse(body) != OK:
		_send_error_response(client, 400, "Bad Request", "Invalid JSON")
		return

	var request_data = json.data
	if typeof(request_data) != TYPE_DICTIONARY:
		_send_error_response(client, 400, "Bad Request", "Request body must be JSON object")
		return

	var username = request_data.get("username", "")
	var password = request_data.get("password", "")
	var role = request_data.get("role", "readonly")

	if username == "" or password == "":
		_send_error_response(client, 400, "Bad Request", "Missing username or password")
		return

	# TODO: Implement proper password verification
	# For now, accept any password for demo (REMOVE IN PRODUCTION!)
	if username != "admin" and username != "developer" and username != "readonly":
		_send_error_response(client, 401, "Unauthorized", "Invalid credentials")
		return

	# Generate token
	var token = token_manager.generate_token(username, role)
	if token == "":
		_send_error_response(client, 500, "Internal Server Error", "Failed to generate token")
		return

	_send_json_response(client, 200, {
		"token": token,
		"user": username,
		"role": role,
		"expires_in": 28800
	})
```

---

## Priority 2: Rate Limiting (CRITICAL)

**Time Estimate:** 4-6 hours
**Addresses:** VULN-003

### Implementation

Create `C:/godot/addons/godot_debug_connection/rate_limiter.gd`:

```gdscript
## RateLimiter - Token bucket rate limiting implementation
extends Node
class_name RateLimiter

## Rate limit configuration
const RATE_LIMIT_PER_SECOND: int = 10
const RATE_LIMIT_PER_MINUTE: int = 100
const RATE_LIMIT_PER_HOUR: int = 1000
const BAN_DURATION: float = 300.0  # 5 minutes

## Client rate tracking
var client_buckets: Dictionary = {}  # IP -> {tokens: float, last_update: float, requests: Array}
var banned_clients: Dictionary = {}  # IP -> ban_expires_timestamp

func _ready() -> void:
	# Cleanup timer
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 60.0
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_cleanup_old_clients)
	add_child(cleanup_timer)

## Check if request is allowed
func check_rate_limit(ip: String) -> Dictionary:
	var current_time = Time.get_unix_time_from_system()

	# Check if banned
	if banned_clients.has(ip):
		if current_time < banned_clients[ip]:
			var remaining = banned_clients[ip] - current_time
			return {
				"allowed": false,
				"reason": "IP temporarily banned",
				"retry_after": int(remaining)
			}
		else:
			banned_clients.erase(ip)

	# Initialize bucket if new client
	if not client_buckets.has(ip):
		client_buckets[ip] = {
			"tokens_second": RATE_LIMIT_PER_SECOND,
			"tokens_minute": RATE_LIMIT_PER_MINUTE,
			"tokens_hour": RATE_LIMIT_PER_HOUR,
			"last_update": current_time,
			"requests": []
		}

	var bucket = client_buckets[ip]
	var time_delta = current_time - bucket["last_update"]

	# Refill tokens based on time passed
	bucket["tokens_second"] = min(
		RATE_LIMIT_PER_SECOND,
		bucket["tokens_second"] + time_delta
	)
	bucket["tokens_minute"] = min(
		RATE_LIMIT_PER_MINUTE,
		bucket["tokens_minute"] + (time_delta / 60.0) * RATE_LIMIT_PER_MINUTE
	)
	bucket["tokens_hour"] = min(
		RATE_LIMIT_PER_HOUR,
		bucket["tokens_hour"] + (time_delta / 3600.0) * RATE_LIMIT_PER_HOUR
	)

	bucket["last_update"] = current_time

	# Check limits
	if bucket["tokens_second"] < 1:
		return {
			"allowed": false,
			"reason": "Rate limit exceeded (per second)",
			"retry_after": 1
		}

	if bucket["tokens_minute"] < 1:
		return {
			"allowed": false,
			"reason": "Rate limit exceeded (per minute)",
			"retry_after": 60
		}

	if bucket["tokens_hour"] < 1:
		return {
			"allowed": false,
			"reason": "Rate limit exceeded (per hour)",
			"retry_after": 3600
		}

	# Consume tokens
	bucket["tokens_second"] -= 1
	bucket["tokens_minute"] -= 1
	bucket["tokens_hour"] -= 1

	# Record request
	bucket["requests"].append(current_time)

	# Check for abuse (too many requests in short time)
	var recent_requests = bucket["requests"].filter(
		func(t): return current_time - t < 10.0
	)

	if recent_requests.size() > 50:  # 50 requests in 10 seconds = abuse
		banned_clients[ip] = current_time + BAN_DURATION
		print("WARNING: Banned IP %s for rate limit abuse" % ip)
		return {
			"allowed": false,
			"reason": "IP banned for abuse",
			"retry_after": int(BAN_DURATION)
		}

	return {"allowed": true}

## Clean up old client data
func _cleanup_old_clients() -> void:
	var current_time = Time.get_unix_time_from_system()
	var old_clients = []

	for ip in client_buckets:
		if current_time - client_buckets[ip]["last_update"] > 3600.0:
			old_clients.append(ip)

	for ip in old_clients:
		client_buckets.erase(ip)

	if old_clients.size() > 0:
		print("Cleaned up %d old client rate limit records" % old_clients.size())
```

Integrate rate limiter into GodotBridge:

```gdscript
# Add to godot_bridge.gd
var rate_limiter: RateLimiter

func _ready() -> void:
	# ... existing code ...

	# Create rate limiter
	rate_limiter = RateLimiter.new()
	add_child(rate_limiter)

func _handle_http_request(client: StreamPeerTCP, request_data: PackedByteArray) -> void:
	# Get client IP (for localhost, use connection ID)
	var client_ip = "127.0.0.1"  # In production, get real IP
	var client_id = client_ids.get(client, 0)
	var effective_ip = "%s_%d" % [client_ip, client_id]

	# Check rate limit
	var rate_check = rate_limiter.check_rate_limit(effective_ip)
	if not rate_check["allowed"]:
		_send_rate_limit_response(client, rate_check["reason"], rate_check["retry_after"])
		return

	# Continue with normal request processing...
	# ... existing code ...

func _send_rate_limit_response(client: StreamPeerTCP, reason: String, retry_after: int) -> void:
	var response_body = JSON.stringify({
		"error": "Rate limit exceeded",
		"message": reason,
		"retry_after": retry_after
	})

	var headers = "HTTP/1.1 429 Too Many Requests\r\n"
	headers += "Content-Type: application/json\r\n"
	headers += "Retry-After: %d\r\n" % retry_after
	headers += "Content-Length: %d\r\n" % response_body.length()
	headers += "\r\n"

	client.put_data((headers + response_body).to_utf8_buffer())
```

---

## Priority 3: Scene Whitelist (CRITICAL)

**Time Estimate:** 2-3 hours
**Addresses:** VULN-004

### Implementation

Create scene whitelist configuration file at `C:/godot/config/scene_whitelist.json`:

```json
{
  "allowed_scenes": [
    "res://vr_main.tscn",
    "res://scenes/main_menu.tscn",
    "res://scenes/game_level_1.tscn",
    "res://scenes/game_level_2.tscn",
    "res://scenes/settings.tscn"
  ],
  "allow_test_scenes_in_debug": true,
  "test_scene_patterns": [
    "res://tests/integration/*.tscn"
  ]
}
```

Add scene validator:

```gdscript
# In godot_bridge.gd

var scene_whitelist: Array[String] = []
var allow_test_scenes: bool = false

func _load_scene_whitelist() -> void:
	var whitelist_path = "res://config/scene_whitelist.json"

	if not FileAccess.file_exists(whitelist_path):
		push_error("Scene whitelist not found: " + whitelist_path)
		# Default safe list
		scene_whitelist = ["res://vr_main.tscn"]
		return

	var file = FileAccess.open(whitelist_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(json_str) == OK:
			var config = json.data
			scene_whitelist = config.get("allowed_scenes", [])
			allow_test_scenes = config.get("allow_test_scenes_in_debug", false) and OS.is_debug_build()
			print("Loaded scene whitelist: %d scenes" % scene_whitelist.size())

func _is_scene_allowed(scene_path: String) -> bool:
	# Check exact match in whitelist
	if scene_path in scene_whitelist:
		return true

	# Check test scenes if allowed
	if allow_test_scenes and scene_path.begins_with("res://tests/"):
		return true

	return false

func _handle_scene_load(client: StreamPeerTCP, request_data: Dictionary) -> void:
	var scene_path = request_data.get("scene_path", "res://vr_main.tscn")

	# Validate scene path format
	if not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn"):
		_send_error_response(client, 400, "Bad Request",
			"Invalid scene path format. Must start with 'res://' and end with '.tscn'")
		return

	# Check path traversal attempts
	if "../" in scene_path or "..\\" in scene_path:
		_send_error_response(client, 400, "Bad Request",
			"Path traversal detected")
		# Log security event
		push_error("SECURITY: Path traversal attempt: " + scene_path)
		return

	# Check whitelist
	if not _is_scene_allowed(scene_path):
		_send_error_response(client, 403, "Forbidden",
			"Scene not in whitelist: " + scene_path)
		# Log security event
		push_warning("SECURITY: Attempted to load non-whitelisted scene: " + scene_path)
		return

	# Verify scene file exists
	if not ResourceLoader.exists(scene_path):
		_send_error_response(client, 404, "Not Found",
			"Scene file not found")
		return

	# Load scene
	get_tree().call_deferred("change_scene_to_file", scene_path)

	_send_json_response(client, 200, {
		"status": "loading",
		"scene": scene_path,
		"message": "Scene load initiated successfully"
	})
```

Call `_load_scene_whitelist()` in `_ready()`.

---

## Priority 4: Input Validation (HIGH)

**Time Estimate:** 6-8 hours
**Addresses:** VULN-010, VULN-014, VULN-018

### Create Input Validator

Create `C:/godot/addons/godot_debug_connection/input_validator.gd`:

```gdscript
## InputValidator - Centralized input validation
class_name InputValidator

## Numeric range constraints
const MAX_POSITION_COORD: float = 100000.0
const MIN_POSITION_COORD: float = -100000.0
const MAX_DAMAGE: float = 10000.0
const MIN_DAMAGE: float = 0.0
const MAX_RADIUS: float = 1000.0
const MIN_RADIUS: float = 0.0
const MAX_HEALTH: float = 100000.0

## String constraints
const MAX_STRING_LENGTH: int = 256
const MAX_CREATURE_TYPE_LENGTH: int = 64

## Validate position vector
static func validate_position(position_array) -> Dictionary:
	if typeof(position_array) != TYPE_ARRAY:
		return {"valid": false, "error": "Position must be an array"}

	if position_array.size() != 3:
		return {"valid": false, "error": "Position must have exactly 3 elements [x, y, z]"}

	for i in range(3):
		var coord = float(position_array[i])

		if is_nan(coord) or is_inf(coord):
			return {"valid": false, "error": "Position contains invalid number (NaN or Infinity)"}

		if coord < MIN_POSITION_COORD or coord > MAX_POSITION_COORD:
			return {
				"valid": false,
				"error": "Position coordinate out of bounds [%d, %d]" % [MIN_POSITION_COORD, MAX_POSITION_COORD]
			}

	return {
		"valid": true,
		"position": Vector3(float(position_array[0]), float(position_array[1]), float(position_array[2]))
	}

## Validate damage value
static func validate_damage(damage_value) -> Dictionary:
	var damage = float(damage_value)

	if is_nan(damage) or is_inf(damage):
		return {"valid": false, "error": "Damage contains invalid number (NaN or Infinity)"}

	if damage < MIN_DAMAGE or damage > MAX_DAMAGE:
		return {
			"valid": false,
			"error": "Damage out of bounds [%d, %d]" % [MIN_DAMAGE, MAX_DAMAGE]
		}

	return {"valid": true, "damage": damage}

## Validate radius value
static func validate_radius(radius_value) -> Dictionary:
	var radius = float(radius_value)

	if is_nan(radius) or is_inf(radius):
		return {"valid": false, "error": "Radius contains invalid number (NaN or Infinity)"}

	if radius < MIN_RADIUS or radius > MAX_RADIUS:
		return {
			"valid": false,
			"error": "Radius out of bounds [%d, %d]" % [MIN_RADIUS, MAX_RADIUS]
		}

	return {"valid": true, "radius": radius}

## Validate creature type
static func validate_creature_type(creature_type: String) -> Dictionary:
	if creature_type == "":
		return {"valid": false, "error": "Creature type cannot be empty"}

	if creature_type.length() > MAX_CREATURE_TYPE_LENGTH:
		return {"valid": false, "error": "Creature type too long (max %d characters)" % MAX_CREATURE_TYPE_LENGTH}

	# Check for path traversal attempts
	if "../" in creature_type or "..\\" in creature_type:
		return {"valid": false, "error": "Invalid characters in creature type"}

	# Check for special characters that could be dangerous
	var allowed_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
	for c in creature_type:
		if not c in allowed_chars:
			return {"valid": false, "error": "Invalid character in creature type: " + c}

	# Check against whitelist
	var allowed_types = ["hostile", "friendly", "neutral", "boss", "companion"]
	if not creature_type in allowed_types:
		return {"valid": false, "error": "Unknown creature type: " + creature_type}

	return {"valid": true, "creature_type": creature_type}

## Validate JSON payload size and structure
static func validate_json_payload(json_string: String, max_size: int = 1048576) -> Dictionary:
	if json_string.length() > max_size:
		return {"valid": false, "error": "Payload too large (max %d bytes)" % max_size}

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		return {"valid": false, "error": "Invalid JSON: " + json.get_error_message()}

	var data = json.data

	# Check nesting depth
	var max_depth = _check_nesting_depth(data)
	if max_depth > 10:
		return {"valid": false, "error": "JSON nesting too deep (max 10 levels)"}

	return {"valid": true, "data": data}

## Check JSON nesting depth
static func _check_nesting_depth(data, current_depth: int = 0) -> int:
	if current_depth > 20:  # Safety limit
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
```

Update endpoint handlers to use validator:

```gdscript
func _handle_resources_mine(client: StreamPeerTCP, request_data: Dictionary) -> void:
	# Validate position
	if not request_data.has("position"):
		_send_error_response(client, 400, "Bad Request", "Missing required parameter: position")
		return

	var pos_validation = InputValidator.validate_position(request_data["position"])
	if not pos_validation["valid"]:
		_send_error_response(client, 400, "Bad Request", pos_validation["error"])
		return

	var position = pos_validation["position"]

	# Continue with validated input...
```

---

## Priority 5: Audit Logging (HIGH)

**Time Estimate:** 4-6 hours
**Addresses:** VULN-012, VULN-020

### Create Audit Logger

Create `C:/godot/addons/godot_debug_connection/audit_logger.gd`:

```gdscript
## AuditLogger - Security event logging
extends Node
class_name AuditLogger

## Log file path
var log_file_path: String = "user://audit_log.jsonl"  # JSON Lines format
var log_file: FileAccess = null

## Log configuration
const MAX_LOG_SIZE: int = 100 * 1024 * 1024  # 100MB
const LOG_ROTATION_COUNT: int = 5

func _ready() -> void:
	_open_log_file()

func _open_log_file() -> void:
	# Check if rotation needed
	if FileAccess.file_exists(log_file_path):
		var file_size = FileAccess.get_file_as_bytes(log_file_path).size()
		if file_size > MAX_LOG_SIZE:
			_rotate_logs()

	log_file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if log_file:
		log_file.seek_end()
		print("Audit logging enabled: " + log_file_path)
	else:
		push_error("Failed to open audit log file")

func _rotate_logs() -> void:
	log_file = null

	# Rotate existing logs
	for i in range(LOG_ROTATION_COUNT - 1, 0, -1):
		var old_path = log_file_path + "." + str(i)
		var new_path = log_file_path + "." + str(i + 1)
		if FileAccess.file_exists(old_path):
			DirAccess.rename_absolute(old_path, new_path)

	# Rotate current log
	DirAccess.rename_absolute(log_file_path, log_file_path + ".1")
	print("Rotated audit logs")

## Log authentication event
func log_authentication(user: String, success: bool, ip: String, reason: String = "") -> void:
	_log_event("authentication", {
		"user": user,
		"success": success,
		"ip": ip,
		"reason": reason
	})

## Log authorization failure
func log_authorization_failure(user: String, role: String, required_role: String, endpoint: String) -> void:
	_log_event("authorization_failure", {
		"user": user,
		"user_role": role,
		"required_role": required_role,
		"endpoint": endpoint,
		"severity": "high"
	})

## Log rate limit violation
func log_rate_limit_violation(ip: String, endpoint: String) -> void:
	_log_event("rate_limit_violation", {
		"ip": ip,
		"endpoint": endpoint,
		"severity": "medium"
	})

## Log path traversal attempt
func log_path_traversal_attempt(user: String, path: String, ip: String) -> void:
	_log_event("path_traversal_attempt", {
		"user": user,
		"path": path,
		"ip": ip,
		"severity": "critical"
	})

## Log scene load
func log_scene_load(user: String, scene_path: String, success: bool) -> void:
	_log_event("scene_load", {
		"user": user,
		"scene": scene_path,
		"success": success
	})

## Log creature spawn
func log_creature_spawn(user: String, creature_type: String, position: Vector3) -> void:
	_log_event("creature_spawn", {
		"user": user,
		"creature_type": creature_type,
		"position": {"x": position.x, "y": position.y, "z": position.z}
	})

## Log debug command execution
func log_debug_command(user: String, command: String, args: Dictionary) -> void:
	_log_event("debug_command", {
		"user": user,
		"command": command,
		"args": args,
		"severity": "high"
	})

## Log generic security event
func log_security_event(event_type: String, details: Dictionary) -> void:
	_log_event(event_type, details)

## Internal log writing function
func _log_event(event_type: String, details: Dictionary) -> void:
	var log_entry = {
		"timestamp": Time.get_datetime_string_from_system(),
		"unix_time": Time.get_unix_time_from_system(),
		"event_type": event_type,
		"details": details
	}

	var json_line = JSON.stringify(log_entry) + "\n"

	if log_file:
		log_file.store_string(json_line)
		log_file.flush()  # Ensure immediate write

	# Also print to console for development
	print("[AUDIT] %s: %s" % [event_type, JSON.stringify(details)])

func _exit_tree() -> void:
	if log_file:
		log_file.close()
```

Integrate audit logger:

```gdscript
# In godot_bridge.gd
var audit_logger: AuditLogger

func _ready() -> void:
	# ... existing code ...
	audit_logger = AuditLogger.new()
	add_child(audit_logger)

func _check_auth(client: StreamPeerTCP, headers: Dictionary, required_role: String = "readonly") -> Dictionary:
	# ... existing validation code ...

	var validation = token_manager.validate_token(token)
	if not validation["valid"]:
		# Log failed authentication
		audit_logger.log_authentication("unknown", false, _get_client_ip(client), validation["error"])
		return {"authorized": false, "error": validation["error"], "status": 401}

	# Log successful authentication
	audit_logger.log_authentication(validation["user"], true, _get_client_ip(client))

	# Check authorization...
	if not authorized:
		# Log authorization failure
		audit_logger.log_authorization_failure(
			validation["user"],
			user_role,
			required_role,
			"<current_endpoint>"
		)
		return {"authorized": false, ...}

	return {"authorized": true, ...}
```

---

## Priority 6: TLS/HTTPS Support (HIGH)

**Time Estimate:** 8-12 hours
**Addresses:** VULN-008

### Generate Self-Signed Certificate

```bash
# Generate private key
openssl genrsa -out C:/godot/certs/server.key 2048

# Generate certificate signing request
openssl req -new -key C:/godot/certs/server.key -out C:/godot/certs/server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Generate self-signed certificate (valid for 1 year)
openssl x509 -req -days 365 -in C:/godot/certs/server.csr \
  -signkey C:/godot/certs/server.key -out C:/godot/certs/server.crt
```

### Implement TLS in GodotBridge

Note: Godot 4.x's StreamPeerTCP doesn't natively support TLS. You'll need to:

1. Use an external HTTPS proxy (recommended for production):
```bash
# Use nginx or Caddy as reverse proxy
# nginx.conf:
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /path/to/server.crt;
    ssl_certificate_key /path/to/server.key;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

2. OR implement TLS in GDScript using Crypto class (advanced):
```gdscript
# This is a simplified example - production requires full TLS implementation
var crypto = Crypto.new()
var server_cert = crypto.load_certificate("res://certs/server.crt")
var server_key = crypto.load_key("res://certs/server.key")

# TLS handshake would need to be implemented manually
# This is beyond scope of this guide - use reverse proxy instead
```

**Recommendation:** Use nginx/Caddy reverse proxy for production TLS termination.

---

## Priority 7: Additional Security Headers (MEDIUM)

**Time Estimate:** 2-3 hours
**Addresses:** VULN-019

### Update Response Functions

```gdscript
func _send_json_response(client: StreamPeerTCP, status_code: int, data: Dictionary) -> void:
	var response_body = JSON.stringify(data)

	var status_text = _get_status_text(status_code)
	var headers = "HTTP/1.1 %d %s\r\n" % [status_code, status_text]
	headers += "Content-Type: application/json\r\n"
	headers += "Content-Length: %d\r\n" % response_body.length()

	# Security headers
	headers += "X-Content-Type-Options: nosniff\r\n"
	headers += "X-Frame-Options: DENY\r\n"
	headers += "X-XSS-Protection: 1; mode=block\r\n"
	headers += "Content-Security-Policy: default-src 'none'\r\n"
	headers += "Referrer-Policy: no-referrer\r\n"
	headers += "Permissions-Policy: geolocation=(), microphone=(), camera=()\r\n"

	# When HTTPS is implemented:
	# headers += "Strict-Transport-Security: max-age=31536000; includeSubDomains\r\n"

	headers += "\r\n"

	client.put_data((headers + response_body).to_utf8_buffer())
```

---

## Priority 8: Creature Type Validation Fix (HIGH)

**Time Estimate:** 2-3 hours
**Addresses:** VULN-005

Already covered in Priority 4 (Input Validation). Ensure `validate_creature_type()` is used in all creature endpoints.

---

## Priority 9: WebSocket Authentication (HIGH)

**Time Estimate:** 4-6 hours

### Update Telemetry Server

Modify `C:/godot/addons/godot_debug_connection/telemetry_server.gd`:

```gdscript
# Add token validation
var bridge: Node = null  # Reference to GodotBridge

func _ready():
	# ... existing code ...
	call_deferred("_get_bridge_reference")

func _get_bridge_reference() -> void:
	bridge = get_node_or_null("/root/GodotBridge")

func _handle_client_message(peer_id: int, message: String):
	# First message must be authentication
	var peer_data = peers[peer_id]

	if not peer_data.get("authenticated", false):
		var json = JSON.new()
		if json.parse(message) != OK:
			_disconnect_peer(peer_id, "Invalid authentication message")
			return

		var auth_msg = json.data
		if typeof(auth_msg) != TYPE_DICTIONARY or not auth_msg.has("token"):
			_disconnect_peer(peer_id, "Missing authentication token")
			return

		# Validate token with TokenManager
		if bridge and "token_manager" in bridge:
			var validation = bridge.token_manager.validate_token(auth_msg["token"])
			if not validation["valid"]:
				_disconnect_peer(peer_id, "Invalid token")
				return

			peer_data["authenticated"] = true
			peer_data["user"] = validation["user"]
			peer_data["role"] = validation["role"]

			send_to_peer(peer_id, "authenticated", {
				"user": validation["user"],
				"role": validation["role"]
			})
		else:
			_disconnect_peer(peer_id, "Authentication service unavailable")
		return

	# Process normal commands only if authenticated
	# ... existing command handling code ...

func _disconnect_peer(peer_id: int, reason: String) -> void:
	if peers.has(peer_id):
		var peer: WebSocketPeer = peers[peer_id]["peer"]
		peer.close(1008, reason)  # Policy violation close code
		peers.erase(peer_id)
		print("Disconnected peer %d: %s" % [peer_id, reason])
```

---

## Testing Security Improvements

After implementing each fix, run security validation tests:

### Create Test Script

Create `C:/godot/tests/security/validate_security.py`:

```python
#!/usr/bin/env python3
import requests
import json
import sys

BASE_URL = "http://127.0.0.1:8080"

def test_authentication_required():
    """Test that endpoints require authentication"""
    print("[TEST] Authentication enforcement...")

    # Try to access without token
    response = requests.get(f"{BASE_URL}/status")

    if response.status_code == 401:
        print("✅ PASS: Authentication required")
        return True
    else:
        print(f"❌ FAIL: Got status {response.status_code}, expected 401")
        return False

def test_valid_authentication():
    """Test authentication with valid token"""
    print("[TEST] Valid authentication...")

    # Get token (you'll need to set this)
    token = "YOUR_ADMIN_TOKEN_HERE"

    response = requests.get(
        f"{BASE_URL}/status",
        headers={"Authorization": f"Bearer {token}"}
    )

    if response.status_code == 200:
        print("✅ PASS: Valid token accepted")
        return True
    else:
        print(f"❌ FAIL: Got status {response.status_code}, expected 200")
        return False

def test_rate_limiting():
    """Test rate limiting enforcement"""
    print("[TEST] Rate limiting...")

    # Send many requests quickly
    for i in range(15):
        response = requests.get(f"{BASE_URL}/status")

    if response.status_code == 429:
        print("✅ PASS: Rate limiting enforced")
        return True
    else:
        print(f"❌ FAIL: No rate limiting (status: {response.status_code})")
        return False

def test_scene_whitelist():
    """Test scene whitelist validation"""
    print("[TEST] Scene whitelist...")

    token = "YOUR_DEVELOPER_TOKEN_HERE"

    response = requests.post(
        f"{BASE_URL}/scene/load",
        headers={"Authorization": f"Bearer {token}"},
        json={"scene_path": "res://tests/unauthorized.tscn"}
    )

    if response.status_code == 403:
        print("✅ PASS: Unauthorized scene blocked")
        return True
    else:
        print(f"❌ FAIL: Scene not blocked (status: {response.status_code})")
        return False

def test_input_validation():
    """Test input validation"""
    print("[TEST] Input validation...")

    token = "YOUR_DEVELOPER_TOKEN_HERE"

    # Try extreme position values
    response = requests.post(
        f"{BASE_URL}/creatures/spawn",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "creature_type": "hostile",
            "position": [9999999999, 9999999999, 9999999999]
        }
    )

    if response.status_code == 400:
        print("✅ PASS: Invalid input rejected")
        return True
    else:
        print(f"❌ FAIL: Invalid input accepted (status: {response.status_code})")
        return False

def main():
    print("="*60)
    print("SECURITY VALIDATION TEST SUITE")
    print("="*60)

    tests = [
        test_authentication_required,
        test_valid_authentication,
        test_rate_limiting,
        test_scene_whitelist,
        test_input_validation,
    ]

    results = []
    for test in tests:
        try:
            results.append(test())
        except Exception as e:
            print(f"❌ FAIL: Exception: {e}")
            results.append(False)
        print()

    passed = sum(results)
    total = len(results)

    print("="*60)
    print(f"RESULTS: {passed}/{total} tests passed")
    print("="*60)

    if passed == total:
        print("✅ ALL TESTS PASSED")
        return 0
    else:
        print(f"❌ {total - passed} TESTS FAILED")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

---

## Security Checklist

Use this checklist to track implementation progress:

### Authentication & Authorization
- [ ] TokenManager implemented
- [ ] Authentication required on all endpoints
- [ ] Role-based access control (RBAC) working
- [ ] Token expiration enforced
- [ ] Token revocation working
- [ ] Login endpoint functional
- [ ] Admin tokens properly protected

### Rate Limiting
- [ ] RateLimiter implemented
- [ ] Per-second rate limit enforced
- [ ] Per-minute rate limit enforced
- [ ] Per-hour rate limit enforced
- [ ] Abuse detection working
- [ ] Temporary bans functional
- [ ] HTTP 429 responses correct

### Input Validation
- [ ] InputValidator created
- [ ] Position validation on all endpoints
- [ ] Numeric range validation working
- [ ] String length limits enforced
- [ ] Array size limits enforced
- [ ] Type validation working
- [ ] Empty string handling correct
- [ ] JSON payload size limits enforced
- [ ] JSON nesting depth limited

### Path Security
- [ ] Scene whitelist configured
- [ ] Scene whitelist enforced
- [ ] Path traversal prevention working
- [ ] Creature type whitelist enforced
- [ ] Resource path validation working

### Audit Logging
- [ ] AuditLogger implemented
- [ ] Authentication events logged
- [ ] Authorization failures logged
- [ ] Rate limit violations logged
- [ ] Path traversal attempts logged
- [ ] Scene loads logged
- [ ] Creature spawns logged
- [ ] Debug commands logged
- [ ] Log rotation working

### Network Security
- [ ] TLS/HTTPS configured (or reverse proxy)
- [ ] WebSocket authentication working
- [ ] Security headers added
- [ ] Localhost binding verified
- [ ] Firewall rules documented

### Additional Security
- [ ] Session management implemented
- [ ] CSRF protection added
- [ ] Request timeout enforced
- [ ] Connection limits enforced
- [ ] Error messages sanitized
- [ ] Debug endpoints protected

### Testing & Validation
- [ ] Security test suite created
- [ ] All tests passing
- [ ] Penetration testing repeated
- [ ] Security documentation updated
- [ ] Team training completed

---

## Deployment Checklist

Before deploying to production:

1. **Configuration Review**
   - [ ] All default tokens changed
   - [ ] Scene whitelist reviewed and minimized
   - [ ] Rate limits tuned for production load
   - [ ] Audit logging enabled and tested
   - [ ] TLS certificates valid and not self-signed

2. **Security Testing**
   - [ ] Run automated security test suite
   - [ ] Perform manual penetration testing
   - [ ] Verify all critical vulnerabilities fixed
   - [ ] Test with security scanner (OWASP ZAP, Burp Suite)

3. **Monitoring Setup**
   - [ ] Log aggregation configured
   - [ ] Security alerts configured
   - [ ] Rate limit monitoring active
   - [ ] Failed authentication alerts set up

4. **Documentation**
   - [ ] Update API documentation with auth requirements
   - [ ] Document token generation process
   - [ ] Create runbook for security incidents
   - [ ] Document emergency procedures

5. **Backup & Recovery**
   - [ ] Token database backed up
   - [ ] Audit logs backed up
   - [ ] Recovery procedures tested

---

## Maintenance

### Regular Security Tasks

**Daily:**
- Review audit logs for suspicious activity
- Monitor rate limit violations
- Check for failed authentication attempts

**Weekly:**
- Rotate old audit logs
- Review active tokens
- Update security monitoring dashboards

**Monthly:**
- Review and update scene whitelist
- Review and update creature type whitelist
- Perform security scan
- Review access control lists
- Update security documentation

**Quarterly:**
- Full security audit
- Penetration testing
- Security training refresh
- Update dependencies
- Review incident response procedures

---

## Additional Resources

- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **OWASP Testing Guide:** https://owasp.org/www-project-web-security-testing-guide/
- **CWE Top 25:** https://cwe.mitre.org/top25/
- **Godot Security:** https://docs.godotengine.org/en/stable/tutorials/io/encrypting_save_games.html

---

**End of Security Hardening Guide**
