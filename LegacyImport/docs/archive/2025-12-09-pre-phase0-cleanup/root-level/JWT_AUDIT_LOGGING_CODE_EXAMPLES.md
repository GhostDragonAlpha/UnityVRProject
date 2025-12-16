# JWT Authentication Audit Logging - Code Examples

## Overview of Key Code Paths

This document shows the exact code paths that capture JWT authentication events in the audit log.

---

## 1. JWT Token Encoding (Token Generation)

**File:** `C:/godot/scripts/http_api/jwt.gd`

```gdscript
## Encodes a payload into a JWT token
static func encode(payload: Dictionary, secret: String, expires_in: int = 3600) -> String:
	# Add standard claims
	var now = Time.get_unix_time_from_system()
	var claims = payload.duplicate()
	claims["iat"] = int(now)  # Issued at
	claims["exp"] = int(now + expires_in)  # Expiration

	# Create header
	var header = {
		"alg": ALGORITHM,  # "HS256"
		"typ": "JWT"
	}

	# Encode header and payload
	var header_b64 = _base64url_encode(JSON.stringify(header))
	var payload_b64 = _base64url_encode(JSON.stringify(claims))

	# Create signature
	var message = header_b64 + "." + payload_b64
	var signature = _sign_hmac_sha256(message, secret)
	var signature_b64 = _base64url_encode(signature)

	# Return complete JWT
	return message + "." + signature_b64
```

**What Gets Logged:** Token created event (via TokenManager)

---

## 2. JWT Token Decoding & Validation

**File:** `C:/godot/scripts/http_api/jwt.gd`

```gdscript
## Decodes and verifies a JWT token
static func decode(token: String, secret: String) -> Dictionary:
	# Split token into parts
	var parts = token.split(".")
	if parts.size() != 3:
		return {"valid": false, "error": "Invalid token format"}

	var header_b64 = parts[0]
	var payload_b64 = parts[1]
	var signature_b64 = parts[2]

	# Verify signature
	var message = header_b64 + "." + payload_b64
	var expected_signature = _sign_hmac_sha256(message, secret)
	var expected_signature_b64 = _base64url_encode(expected_signature)

	if signature_b64 != expected_signature_b64:
		return {"valid": false, "error": "Invalid signature"}

	# Decode payload
	var payload_json = _base64url_decode(payload_b64)
	var payload = JSON.parse_string(payload_json)
	if payload == null:
		return {"valid": false, "error": "Invalid payload JSON"}

	# Check expiration
	if payload.has("exp"):
		var now = Time.get_unix_time_from_system()
		if int(payload.exp) < now:
			return {"valid": false, "error": "Token expired", "payload": payload}

	return {"valid": true, "payload": payload}
```

**What Gets Logged:** Failure reasons if token is invalid

---

## 3. Security Configuration - Authentication Validation

**File:** `C:/godot/scripts/http_api/security_config.gd`

```gdscript
## Validate authorization header with token manager support
static func validate_auth(headers_or_request) -> bool:
	if not auth_enabled:
		return true

	# Handle both Dictionary and HttpRequest object
	var headers: Dictionary
	if headers_or_request is Dictionary:
		headers = headers_or_request
	elif headers_or_request != null and "headers" in headers_or_request:
		headers = headers_or_request.headers
	else:
		print("[Security] Invalid parameter type for validate_auth: ", typeof(headers_or_request))
		return false

	# Try both capitalized and lowercase versions of Authorization header
	var auth_header = headers.get(_token_header, headers.get("authorization", ""))
	if auth_header.is_empty():
		print("[Security] Auth failed: No Authorization header")
		return false

	# Check for "Bearer <token>" format
	if not auth_header.begins_with("Bearer "):
		print("[Security] Auth failed: Invalid Authorization format (expected 'Bearer <token>')")
		return false

	var token_secret = auth_header.substr(7).strip_edges()

	# Use JWT if enabled
	if use_jwt:
		var result = verify_jwt_token(token_secret)
		if not result.valid:
			print("[Security] Auth failed: ", result.get("error", "Invalid JWT"))
		return result.valid

	# Use token manager if enabled
	if use_token_manager and _token_manager != null:
		var validation = _token_manager.validate_token(token_secret)
		if not validation.valid:
			print("[Security] Auth failed: Invalid token - ", validation.get("error", "unknown error"))
		return validation.valid

	# Fall back to legacy validation
	var is_valid = token_secret == get_token()
	if not is_valid:
		print("[Security] Auth failed: Token mismatch")
	return is_valid


## Verify and decode JWT token
static func verify_jwt_token(token: String) -> Dictionary:
	if _jwt_secret.is_empty():
		return {"valid": false, "error": "JWT not initialized"}

	return JWT.decode(token, _jwt_secret)
```

**What Gets Logged:**
- Reason for auth failure (from print statements)
- Later passed to audit logger via router

---

## 4. HTTP Router - Authentication Check with Audit Logging

**File:** `C:/godot/scripts/http_api/scene_router_with_audit.gd`

```gdscript
## Handle POST /scene - Load a scene
func _handle_scene_load(request: HttpRequest, response: GodottpdResponse) -> bool:
	# Auth check
	if not SecurityConfig.validate_auth(request.headers):
		if audit_helper:
			audit_helper.log_auth_failure(request, "Missing or invalid token", "/scene")
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	# Log successful authentication
	if audit_helper:
		audit_helper.log_auth_success(request, "/scene")

	# Rate limiting check
	var client_ip = _get_client_ip(request)
	var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene")
	if not rate_check["allowed"]:
		if audit_helper:
			audit_helper.log_rate_limit(request, rate_check["limit"], rate_check["retry_after"], "/scene")
		response.send(429, JSON.stringify(SecurityConfig.create_rate_limit_error_response(rate_check["retry_after"])))
		return true

	# ... continue with scene loading ...

	return true
```

**What Gets Logged:**
- `log_auth_success()` → authentication_success event
- `log_auth_failure()` → authentication_failure event

---

## 5. Audit Helper - Middleware Layer

**File:** `C:/godot/scripts/security/audit_helper.gd`

```gdscript
## Log authentication success
func log_auth_success(request, endpoint: String = "") -> void:
	var user_id = get_user_id_from_request(request)
	var ip = get_ip_from_request(request)
	var path = endpoint if not endpoint.is_empty() else request.path

	if audit_logger:
		audit_logger.log_authentication(user_id, ip, path, true, "Valid token")


## Log authentication failure
func log_auth_failure(request, reason: String, endpoint: String = "") -> void:
	var ip = get_ip_from_request(request)
	var path = endpoint if not endpoint.is_empty() else request.path

	if audit_logger:
		audit_logger.log_authentication("unknown", ip, path, false, reason)


## Extract user ID from request (from token or default to IP)
func get_user_id_from_request(request) -> String:
	# Try to extract from Authorization header
	var auth_header = request.headers.get("authorization", request.headers.get("Authorization", ""))
	if auth_header.begins_with("Bearer "):
		var token = auth_header.substr(7).strip_edges()
		# Get token manager from SecurityConfig
		var HttpApiSecurityConfig = preload("res://scripts/http_api/security_config.gd")
		if HttpApiSecurityConfig.use_token_manager:
			var token_manager = HttpApiSecurityConfig.get_token_manager()
			if token_manager:
				var validation = token_manager.validate_token(token)
				if validation.valid:
					return validation.token.token_id  # Use token ID as user ID

	# Fallback to IP-based identification
	return get_ip_from_request(request)
```

**What Gets Logged:**
- Extracts user ID from JWT token (token_id)
- Extracts client IP (with proxy support)
- Calls SecurityAuditLogger with complete context

---

## 6. Security Audit Logger - Core Logging

**File:** `C:/godot/scripts/security/audit_logger.gd`

```gdscript
## Log authentication event
func log_authentication(user_id: String, ip_address: String, endpoint: String, success: bool, reason: String = "") -> void:
	var event_type = "authentication_success" if success else "authentication_failure"
	var severity = "info" if success else "warning"

	_event_counters[event_type] += 1

	_write_log_entry({
		"timestamp": Time.get_unix_time_from_system(),
		"timestamp_iso": Time.get_datetime_string_from_system(),
		"event_type": event_type,
		"severity": severity,
		"user_id": user_id,
		"ip_address": ip_address,
		"endpoint": endpoint,
		"action": "authenticate",
		"result": "success" if success else "failure",
		"details": {
			"reason": reason,
			"token_validated": success
		}
	})

	log_event_recorded.emit(event_type, severity)


## Write log entry with JSON structure
func _write_log_entry(entry: Dictionary) -> void:
	if not _log_file:
		_open_log_file()
		if not _log_file:
			return

	# Check if daily rotation needed
	var date = Time.get_datetime_dict_from_system()
	var date_str = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	if _log_date != date_str:
		_rotate_log("Daily rotation")
		_open_log_file()

	# Add signature if enabled
	if USE_LOG_SIGNING:
		entry["signature"] = _sign_entry(entry)

	# Convert to JSON and write
	var json_line = JSON.stringify(entry) + "\n"
	var json_bytes = json_line.to_utf8_buffer()

	_log_file.store_buffer(json_bytes)
	_log_file.flush()

	_current_log_size += json_bytes.size()
	_total_events_logged += 1

	# Check size-based rotation
	if _current_log_size >= MAX_LOG_SIZE_MB * 1024 * 1024:
		_rotate_log("Size limit reached")
		_open_log_file()
```

**What Gets Logged:**
- Structured JSON entry with all authentication details
- HMAC-SHA256 signature for tamper detection
- Automatic daily and size-based rotation

---

## 7. Token Manager - Token Lifecycle Events

**File:** `C:/godot/scripts/http_api/token_manager.gd`

```gdscript
## Validate a token and update last used time
func validate_token(token_secret: String) -> Dictionary:
	var result = {
		"valid": false,
		"error": "",
		"token": null,
		"expires_in_seconds": 0
	}

	if not _active_tokens.has(token_secret):
		result.error = "Token not found"
		_metrics.invalid_tokens_rejected_total += 1
		return result

	var token: Token = _active_tokens[token_secret]

	if token.revoked:
		result.error = "Token has been revoked"
		_metrics.invalid_tokens_rejected_total += 1
		_audit_log_event("token_rejected", {"token_id": token.token_id, "reason": "revoked"})
		return result

	if token.is_expired():
		result.error = "Token has expired"
		_metrics.expired_tokens_rejected_total += 1
		_audit_log_event("token_rejected", {"token_id": token.token_id, "reason": "expired"})
		return result

	# Valid token - update last used
	token.update_last_used()
	result.valid = true
	result.token = token
	result.expires_in_seconds = int(token.expires_at - Time.get_unix_time_from_system())

	_save_tokens()  # Save updated last_used_at
	return result


## Generate a new token
func generate_token(lifetime_hours: float = DEFAULT_TOKEN_LIFETIME_HOURS) -> Token:
	var token_id = _generate_uuid()
	var token_secret = _generate_secret()
	var now = Time.get_unix_time_from_system()
	var expiry = now + (lifetime_hours * 3600)

	var token = Token.new(token_id, token_secret, now, expiry)
	_active_tokens[token_secret] = token

	_metrics.tokens_created_total += 1
	_audit_log_event("token_created", {"token_id": token_id, "expires_at": expiry})

	print("[TokenManager] Generated new token: ", token_id, " (expires: ", Time.get_datetime_string_from_unix_time(int(expiry)), ")")

	_save_tokens()
	return token


## Rotate tokens - create new token and mark old one for grace period
func rotate_token(current_token_secret: String = "") -> Dictionary:
	var result = {
		"success": false,
		"new_token": null,
		"old_token_id": "",
		"grace_period_seconds": ROTATION_OVERLAP_HOURS * 3600,
		"error": ""
	}

	# If current token provided, validate it
	if not current_token_secret.is_empty():
		var validation = validate_token(current_token_secret)
		if not validation.valid:
			result.error = "Current token is invalid: " + validation.error
			return result
		result.old_token_id = validation.token.token_id

	# Generate new token with full lifetime
	var new_token = generate_token(DEFAULT_TOKEN_LIFETIME_HOURS)

	# If we have an old token, adjust its expiry to grace period
	if not current_token_secret.is_empty() and _active_tokens.has(current_token_secret):
		var old_token: Token = _active_tokens[current_token_secret]
		var grace_expiry = Time.get_unix_time_from_system() + (ROTATION_OVERLAP_HOURS * 3600)
		old_token.expires_at = min(old_token.expires_at, grace_expiry)

	result.success = true
	result.new_token = new_token

	_metrics.token_rotations_total += 1
	_last_rotation_time = Time.get_unix_time_from_system()
	_audit_log_event("token_rotated", {
		"new_token_id": new_token.token_id,
		"old_token_id": result.old_token_id,
		"grace_period_hours": ROTATION_OVERLAP_HOURS
	})

	_save_tokens()
	return result


## Add audit log entry
func _audit_log_event(event_type: String, details: Dictionary = {}) -> void:
	var entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"event_type": event_type,
		"details": details
	}

	_audit_log.append(entry)

	# Trim audit log if too large
	if _audit_log.size() > MAX_AUDIT_LOG_SIZE:
		_audit_log = _audit_log.slice(_audit_log.size() - MAX_AUDIT_LOG_SIZE, _audit_log.size())
```

**What Gets Logged:**
- token_created - New token generated
- token_rotated - Token rotation performed
- token_rejected - Token validation failed (revoked/expired)

---

## 8. HTTP API Server Initialization

**File:** `C:/godot/scripts/http_api/http_api_server.gd`

```gdscript
func _ready():
	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)

	# Initialize audit logging
	HttpApiAuditLogger.initialize()
	print("[HttpApiServer] Audit logging initialized")

	# Load whitelist configuration
	SecurityConfig.load_whitelist_config("development")
	print("[HttpApiServer] Whitelist configuration loaded")

	# Generate security token
	SecurityConfig.generate_jwt_token()
	SecurityConfig.print_config()

	# Create HTTP server
	server = load("res://addons/godottpd/http_server.gd").new()

	# Set port and bind address
	server.port = PORT
	server.bind_address = SecurityConfig.BIND_ADDRESS

	# Register routers
	_register_routers()

	# Add server to scene tree
	add_child(server)

	# Start server
	server.start()
	print("[HttpApiServer] ✓ SECURE HTTP API server started on ", SecurityConfig.BIND_ADDRESS, ":", PORT)
```

**What Gets Logged:**
- System startup event (via audit logger initialization)

---

## Complete Example: Successful Authentication

```
REQUEST:
GET /scene HTTP/1.1
Host: 127.0.0.1:8080
Authorization: Bearer eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJ1c2VyX2lkIjogInRlc3RfdXNlciIsICJyb2xlIjogImFkbWluIiwgImlhdCI6IDE3MDE1MTg0MDAsICJleHAiOiAxNzAxNjA0ODAwfQ.signature...

FLOW:
1. SceneRouter._handle_scene_get()
   ├─ SecurityConfig.validate_auth(request.headers)
   │  ├─ Extract "Authorization: Bearer ..."
   │  ├─ JWT.decode(token, secret)
   │  │  ├─ Verify signature
   │  │  ├─ Check expiration
   │  │  └─ Return {valid: true, payload: {...}}
   │  └─ Return true
   │
   └─ audit_helper.log_auth_success(request, "/scene")
      ├─ Extract user_id from token (token_id)
      ├─ Extract ip from request
      │
      └─ audit_logger.log_authentication("550e8400...", "127.0.0.1", "/scene", true, "Valid token")
         ├─ Create JSON entry with event_type="authentication_success"
         ├─ Add HMAC-SHA256 signature
         ├─ Write to: user://logs/security/audit_2025-12-02.jsonl
         └─ Increment _event_counters["authentication_success"]

AUDIT LOG ENTRY:
{
  "timestamp": 1701518400,
  "timestamp_iso": "2025-12-02 12:00:00",
  "event_type": "authentication_success",
  "severity": "info",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "ip_address": "127.0.0.1",
  "endpoint": "/scene",
  "action": "authenticate",
  "result": "success",
  "details": {
    "reason": "Valid token",
    "token_validated": true
  },
  "signature": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```

---

## Complete Example: Failed Authentication - Expired Token

```
REQUEST:
GET /scene HTTP/1.1
Host: 127.0.0.1:8080
Authorization: Bearer eyJhbGciOiAiSFMyNTYi...signature_of_expired_token...

FLOW:
1. SceneRouter._handle_scene_get()
   ├─ SecurityConfig.validate_auth(request.headers)
   │  ├─ Extract "Authorization: Bearer ..."
   │  ├─ JWT.decode(token, secret)
   │  │  ├─ Verify signature ✓
   │  │  ├─ Check expiration ✗ (exp: 1701432000, now: 1701604800)
   │  │  └─ Return {valid: false, error: "Token expired", payload: {...}}
   │  │
   │  └─ Return false
   │
   └─ audit_helper.log_auth_failure(request, "Missing or invalid token", "/scene")
      ├─ Extract ip from request
      │
      └─ audit_logger.log_authentication("unknown", "127.0.0.1", "/scene", false, "Missing or invalid token")
         ├─ Create JSON entry with event_type="authentication_failure"
         ├─ Add HMAC-SHA256 signature
         ├─ Write to: user://logs/security/audit_2025-12-02.jsonl
         └─ Increment _event_counters["authentication_failure"]

RESPONSE:
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}

AUDIT LOG ENTRY:
{
  "timestamp": 1701604801,
  "timestamp_iso": "2025-12-02 13:00:01",
  "event_type": "authentication_failure",
  "severity": "warning",
  "user_id": "unknown",
  "ip_address": "127.0.0.1",
  "endpoint": "/scene",
  "action": "authenticate",
  "result": "failure",
  "details": {
    "reason": "Missing or invalid token",
    "token_validated": false
  },
  "signature": "d4c9e1b2a3f4e5c6d7b8a9c0d1e2f3a4"
}
```

---

## Log Analysis Example

```gdscript
# Read audit log entries
var log_path = "user://logs/security/audit_2025-12-02.jsonl"
var entries = audit_logger.read_log_entries(log_path, 100)

# Analyze authentication events
var auth_success = 0
var auth_failure = 0
var failure_reasons = {}

for entry in entries:
	if entry.event_type == "authentication_success":
		auth_success += 1
	elif entry.event_type == "authentication_failure":
		auth_failure += 1
		var reason = entry.details.reason
		failure_reasons[reason] = failure_reasons.get(reason, 0) + 1

# Print metrics
print("Authentication Metrics:")
print("  Success: %d" % auth_success)
print("  Failure: %d" % auth_failure)
print("  Success Rate: %.1f%%" % (100.0 * auth_success / (auth_success + auth_failure)))
print("\nFailure Reasons:")
for reason in failure_reasons:
	print("  %s: %d" % [reason, failure_reasons[reason]])

# Get Prometheus metrics
var prometheus_metrics = audit_logger.get_prometheus_metrics()
print("\n" + prometheus_metrics)
```

---

## Files to Examine for Implementation Details

1. **JWT Implementation:**
   - `C:/godot/scripts/http_api/jwt.gd` - HS256 signing and verification

2. **Security Configuration:**
   - `C:/godot/scripts/http_api/security_config.gd` - Authentication validation
   - `C:/godot/scripts/http_api/token_manager.gd` - Token lifecycle management

3. **HTTP Routers:**
   - `C:/godot/scripts/http_api/scene_router_with_audit.gd` - Example with audit
   - `C:/godot/scripts/http_api/scene_router.gd` - Current implementation

4. **Audit Logging:**
   - `C:/godot/scripts/security/audit_helper.gd` - Middleware layer
   - `C:/godot/scripts/security/audit_logger.gd` - Core logging
   - `C:/godot/scripts/http_api/audit_logger.gd` - Alternative implementation

5. **HTTP API:**
   - `C:/godot/scripts/http_api/http_api_server.gd` - Server initialization

