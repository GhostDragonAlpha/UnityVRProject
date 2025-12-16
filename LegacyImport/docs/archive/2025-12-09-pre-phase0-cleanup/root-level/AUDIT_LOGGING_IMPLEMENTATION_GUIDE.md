# Audit Logging Implementation Guide - Exact Code Snippets

## Quick Reference

This guide provides exact code snippets to copy-paste for implementing audit logging in all 4 HTTP API routers.

---

## File 1: http_api_server.gd

**Location:** `C:/godot/scripts/http_api/http_api_server.gd`

**Change:** Add audit logger initialization in `_ready()` function

### FIND THIS (around line 15-16):
```gdscript
func _ready():
	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)
```

### REPLACE WITH:
```gdscript
func _ready():
	# Initialize audit logging
	HttpApiAuditLogger.initialize()

	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)
```

---

## File 2: scene_reload_router.gd

**Location:** `C:/godot/scripts/http_api/scene_reload_router.gd`

### Change 1: Add client IP extraction and auth logging in POST handler

**FIND THIS (around line 20-25):**
```gdscript
	# Define POST handler for reloading current scene
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true
```

**REPLACE WITH:**
```gdscript
	# Define POST handler for reloading current scene
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Extract client IP for audit logging
		var client_ip = _extract_client_ip(request)

		# Auth check
		if not SecurityConfig.validate_auth(request):
			HttpApiAuditLogger.log_auth_attempt(client_ip, "/scene/reload", false, "Invalid or missing token")
			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Log successful auth
		HttpApiAuditLogger.log_auth_attempt(client_ip, "/scene/reload", true)
```

### Change 2: Add helper function at end of file

**ADD THIS at the end of the file (after line 70, before final newline):**
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

---

## File 3: scene_history_router.gd

**Location:** `C:/godot/scripts/http_api/scene_history_router.gd`

### Change 1: Add client IP extraction and auth logging in GET handler

**FIND THIS (around line 29-34):**
```gdscript
	# Define GET handler for fetching history
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true
```

**REPLACE WITH:**
```gdscript
	# Define GET handler for fetching history
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Extract client IP for audit logging
		var client_ip = _extract_client_ip(request)

		# Auth check
		if not SecurityConfig.validate_auth(request):
			HttpApiAuditLogger.log_auth_attempt(client_ip, "/scene/history", false, "Invalid or missing token")
			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Log successful auth
		HttpApiAuditLogger.log_auth_attempt(client_ip, "/scene/history", true)
```

### Change 2: Add helper function at end of file

**ADD THIS at the end of the file (after line 86, before final newline):**
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

---

## File 4: scenes_list_router.gd

**Location:** `C:/godot/scripts/http_api/scenes_list_router.gd`

### Change 1: Add client IP extraction and auth logging in GET handler

**FIND THIS (around line 20-25):**
```gdscript
	# Define GET handler for listing scenes
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true
```

**REPLACE WITH:**
```gdscript
	# Define GET handler for listing scenes
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Extract client IP for audit logging
		var client_ip = _extract_client_ip(request)

		# Auth check
		if not SecurityConfig.validate_auth(request):
			HttpApiAuditLogger.log_auth_attempt(client_ip, "/scenes", false, "Invalid or missing token")
			_security_headers.apply_headers(response)
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Log successful auth
		HttpApiAuditLogger.log_auth_attempt(client_ip, "/scenes", true)
```

### Change 2: Add helper function at end of file

**ADD THIS at the end of the file (after line 152, before final newline):**
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

---

## File 5: scene_router.gd (COMPLEX - HAS ISSUES)

**Location:** `C:/godot/scripts/http_api/scene_router.gd`

### STEP 1: Fix structural issues FIRST

This file currently has these problems:
1. Function declared before const (line 10 vs line 19)
2. Missing return statements
3. Duplicate return statements

**RECOMMENDATION**: Manually reorganize the file or use the Godot editor to fix syntax errors before adding audit logging.

### STEP 2: After fixing structure, add audit logging

The file already has rate limiting, so add:

#### For POST Handler:
```gdscript
# Extract client IP (add at very start of post_handler)
var client_ip = _extract_client_ip(request)

# Auth failure logging (add after auth check fails)
HttpApiAuditLogger.log_auth_attempt(client_ip, "/scene", false, "Invalid or missing token")

# Auth success logging (add after auth check passes, before rate limit check)
HttpApiAuditLogger.log_auth_attempt(client_ip, "/scene", true)

# Rate limit logging (add when rate limit fails)
HttpApiAuditLogger.log_rate_limit(client_ip, "/scene", SecurityConfig.RATE_LIMIT_REQUESTS_PER_MINUTE, rate_check.retry_after)

# Whitelist violation (add when whitelist check fails)
HttpApiAuditLogger.log_whitelist_violation(client_ip, "/scene", scene_path, scene_validation.error)

# Scene not found (add when ResourceLoader.exists fails)
HttpApiAuditLogger.log_scene_operation(client_ip, "LOAD", scene_path, false, "Scene file not found")

# Scene load success (add after tree.call_deferred, before response.send)
HttpApiAuditLogger.log_scene_operation(client_ip, "LOAD", scene_path, true)
```

#### For GET and PUT Handlers:
Similar pattern to POST, but without scene operations logging.

---

## Testing

After all changes, test with:

```bash
# 1. Start Godot with debug server
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# 2. Get the API token
# Look for this line in Godot console:
# [HttpApiServer] API TOKEN: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# 3. Test failed auth (should log AUTH_FAILURE)
curl -v -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path":"res://vr_main.tscn"}'

# 4. Test successful auth (should log AUTH_SUCCESS)
curl -v -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"scene_path":"res://vr_main.tscn"}'

# 5. Check audit log
cat "C:/Users/$USERNAME/AppData/Roaming/Godot/app_userdata/SpaceTime/logs/http_api_audit.log"
```

Expected log output:
```
[2025-12-02 18:45:23] [WARN] [127.0.0.1] [/scene] [AUTH_FAILURE] Invalid or missing token
[2025-12-02 18:45:45] [INFO] [127.0.0.1] [/scene] [AUTH_SUCCESS] Valid token
[2025-12-02 18:45:45] [INFO] [127.0.0.1] [/scene] [SUCCESS] LOAD: res://vr_main.tscn
```

---

## Summary of Changes

| File | Lines Added | Audit Points | Status |
|------|------------|--------------|---------|
| http_api_server.gd | ~2 | 1 (initialization) | Ready |
| scene_reload_router.gd | ~16 | 2 (auth success/fail) | Ready |
| scene_history_router.gd | ~16 | 2 (auth success/fail) | Ready |
| scenes_list_router.gd | ~16 | 2 (auth success/fail) | Ready |
| scene_router.gd | ~30 | 12 (auth, rate limit, whitelist, scene ops) | Needs structural fix first |

**Total**: ~80 lines added, ~19 audit logging points

---

## Checklist

- [ ] Fix scene_router.gd structural issues
- [ ] Add initialization to http_api_server.gd
- [ ] Add audit logging to scene_reload_router.gd
- [ ] Add audit logging to scene_history_router.gd
- [ ] Add audit logging to scenes_list_router.gd
- [ ] Add full audit logging to scene_router.gd
- [ ] Test failed authentication
- [ ] Test successful authentication
- [ ] Test rate limiting
- [ ] Test whitelist violations
- [ ] Verify audit log file exists and has correct format
- [ ] Update security documentation

---

**IMPORTANT**: Make these changes with Godot Editor CLOSED to avoid file conflicts.
