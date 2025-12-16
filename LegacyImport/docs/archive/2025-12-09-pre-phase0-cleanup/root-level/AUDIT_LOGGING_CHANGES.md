# Audit Logging Implementation for HTTP API Routers

## Overview

This document describes the audit logging changes required for VULN-SEC-002 mitigation.

## Files Modified

1. `C:/godot/scripts/http_api/scene_router.gd`
2. `C:/godot/scripts/http_api/scene_reload_router.gd`
3. `C:/godot/scripts/http_api/scene_history_router.gd`
4. `C:/godot/scripts/http_api/scenes_list_router.gd`
5. `C:/godot/scripts/http_api/http_api_server.gd`

## Changes Required

### 1. Add Helper Function to All Routers

Add this function to each router file (at the end, before the final closing brace):

```gdscript
## Extract client IP from request headers
## Checks X-Forwarded-For header first, falls back to localhost
func _extract_client_ip(request: HttpRequest) -> String:
	# Try X-Forwarded-For header first (for proxied requests)
	if request.headers:
		for header in request.headers:
			if header.begins_with("X-Forwarded-For:"):
				var ip = header.split(":", 1)[1].strip_edges()
				return ip.split(",")[0].strip_edges()  # First IP in chain
	# Fallback to localhost (godottpd limitation)
	return "127.0.0.1"
```

### 2. Audit Logging Points

For **each HTTP handler** in each router, add these audit logging calls:

#### A. Extract Client IP (at start of each handler)
```gdscript
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
	# Extract client IP for audit logging
	var client_ip = _extract_client_ip(request)

	# ... rest of handler
```

#### B. Failed Authentication
```gdscript
# Auth check
if not SecurityConfig.validate_auth(request):
	HttpApiAuditLogger.log_auth_attempt(client_ip, ENDPOINT, false, "Invalid or missing token")
	_security_headers.apply_headers(response)
	response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
	return true
```

Replace `ENDPOINT` with:
- `/scene` for scene_router.gd
- `/scene/reload` for scene_reload_router.gd
- `/scene/history` for scene_history_router.gd
- `/scenes` for scenes_list_router.gd

#### C. Successful Authentication
```gdscript
# Log successful auth
HttpApiAuditLogger.log_auth_attempt(client_ip, ENDPOINT, true)
```

#### D. Rate Limiting (if applicable)
```gdscript
var rate_check = SecurityConfig.check_rate_limit(client_ip, ENDPOINT)
if not rate_check.allowed:
	HttpApiAuditLogger.log_rate_limit(client_ip, ENDPOINT, SecurityConfig.RATE_LIMIT_REQUESTS_PER_MINUTE, rate_check.retry_after)
	var error_response = SecurityConfig.create_rate_limit_error_response(rate_check.retry_after)
	_security_headers.apply_headers(response)
	response.send(429, JSON.stringify(error_response))
	return true
```

#### E. Whitelist Violations (scene_router.gd only)
```gdscript
var scene_validation = SecurityConfig.validate_scene_path_enhanced(scene_path)
if not scene_validation.valid:
	HttpApiAuditLogger.log_whitelist_violation(client_ip, "/scene", scene_path, scene_validation.error)
	_security_headers.apply_headers(response)
	response.send(403, JSON.stringify(SecurityConfig.create_forbidden_response(scene_validation.error)))
	return true
```

#### F. Scene Operations (scene_router.gd only)
```gdscript
# On failure
if not ResourceLoader.exists(scene_path):
	HttpApiAuditLogger.log_scene_operation(client_ip, "LOAD", scene_path, false, "Scene file not found")
	# ... send 404 response

# On success
# Load scene...
HttpApiAuditLogger.log_scene_operation(client_ip, "LOAD", scene_path, true)
# ... send 200 response
```

### 3. Initialize Audit Logger in http_api_server.gd

In the `_ready()` function, add as the FIRST line:

```gdscript
func _ready():
	# Initialize audit logging
	HttpApiAuditLogger.initialize()

	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)
	# ... rest of initialization
```

## Summary of Audit Events Logged

| Event Type | When Logged | Information Captured |
|------------|-------------|---------------------|
| AUTH_FAILURE | Invalid/missing token | Client IP, Endpoint, Reason |
| AUTH_SUCCESS | Valid token provided | Client IP, Endpoint |
| RATE_LIMIT | Rate limit exceeded | Client IP, Endpoint, Limit, Retry-After |
| WHITELIST_VIOLATION | Scene not in whitelist | Client IP, Endpoint, Scene Path, Reason |
| SCENE_OPERATION | Scene load success/failure | Client IP, Operation Type, Scene Path, Success/Failure, Details |

## Audit Log Location

Logs are written to: `user://logs/http_api_audit.log`

On Windows, this typically resolves to:
`C:/Users/<USERNAME>/AppData/Roaming/Godot/app_userdata/SpaceTime/logs/http_api_audit.log`

## Log Format

```
[TIMESTAMP] [LEVEL] [CLIENT_IP] [ENDPOINT] [RESULT] DETAILS
```

Example:
```
[2025-12-02 18:30:45] [WARN] [127.0.0.1] [/scene] [AUTH_FAILURE] Invalid or missing token
[2025-12-02 18:31:12] [INFO] [127.0.0.1] [/scene] [AUTH_SUCCESS] Valid token
[2025-12-02 18:31:13] [INFO] [127.0.0.1] [/scene] [SUCCESS] LOAD: res://vr_main.tscn
```

## Log Rotation

- Max log size: 10 MB
- Max log files: 5 (rotated)
- Old logs renamed with .1, .2, .3, .4, .5 suffix

## Testing Audit Logging

After implementation, verify with:

```bash
# Failed auth
curl -X POST http://127.0.0.1:8080/scene -H "Content-Type: application/json" -d '{"scene_path":"res://vr_main.tscn"}'

# Successful auth
curl -X POST http://127.0.0.1:8080/scene -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN>" -d '{"scene_path":"res://vr_main.tscn"}'

# Check logs
cat "C:/Users/<YOUR_USERNAME>/AppData/Roaming/Godot/app_userdata/SpaceTime/logs/http_api_audit.log"
```

## Status

- [ ] scene_router.gd - Audit logging added
- [ ] scene_reload_router.gd - Audit logging added
- [ ] scene_history_router.gd - Audit logging added
- [ ] scenes_list_router.gd - Audit logging added
- [ ] http_api_server.gd - Audit logger initialized
- [ ] Tested and verified

## Notes

- The HttpApiAuditLogger is already implemented in `scripts/http_api/audit_logger.gd`
- All routers already have the import: `const HttpApiAuditLogger = preload("res://scripts/http_api/audit_logger.gd")`
- The audit logger uses file rotation and GZIP compression for efficiency
- Audit logging is enabled by default but can be disabled with `HttpApiAuditLogger.disable()`
