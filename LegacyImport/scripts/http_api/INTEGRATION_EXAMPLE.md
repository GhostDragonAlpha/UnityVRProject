# Security Headers Integration Example

**Quick start guide for implementing security headers in your HTTP API**

---

## Option 1: Quick Integration (Recommended)

### Step 1: Add initialization to http_api_server.gd

```gdscript
# In http_api_server.gd

func _ready():
    print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)

    # Initialize security
    SecurityConfig.generate_token()
    SecurityConfig.print_config()

    # ⬇️ ADD THIS: Initialize security headers middleware
    _initialize_security_headers()

    # Create HTTP server
    server = load("res://addons/godottpd/http_server.gd").new()
    # ... rest of initialization ...


# ⬇️ ADD THIS FUNCTION at the end of the file
func _initialize_security_headers() -> void:
    # Load SecurityHeadersMiddleware
    var SecurityHeadersMiddleware = load("res://scripts/http_api/security_headers.gd")
    if SecurityHeadersMiddleware == null:
        push_error("[HttpApiServer] Failed to load SecurityHeadersMiddleware")
        return

    # Create middleware instance (MODERATE preset)
    var middleware = SecurityHeadersMiddleware.new(1)

    # Store globally for routers to access
    set_meta("security_middleware", middleware)

    print("[HttpApiServer] ✓ Security headers initialized (VULN-011 fix)")
    middleware.print_config()
```

### Step 2: Update your routers to apply headers

**Example: Update scene_router.gd**

```gdscript
# At the top of your router file
extends HttpRouter

var security_middleware: RefCounted = null

func _init():
    path = "/scene"

func _ready():
    # Get security middleware from server
    var server = get_node("/root/HttpApiServer")
    if server:
        security_middleware = server.get_meta("security_middleware", null)

# Then in your handle methods:
func handle_get(request: HttpRequest, response: GodottpdResponse) -> bool:
    # ⬇️ ADD THIS: Apply security headers
    if security_middleware:
        security_middleware.apply_headers(response)

    # Your existing response code
    response.json(200, {
        "current_scene": get_tree().current_scene.scene_file_path
    })
    return true

func handle_post(request: HttpRequest, response: GodottpdResponse) -> bool:
    # ⬇️ ADD THIS: Apply security headers
    if security_middleware:
        security_middleware.apply_headers(response)

    # Your existing code...
    var data = JSON.parse_string(request.body)
    # ... load scene logic ...

    response.json(200, {"status": "loaded"})
    return true
```

### Step 3: Test it works

```bash
# Run the test script
cd C:/godot/tests/security
python test_security_headers.py

# Or test manually with curl
curl -I http://127.0.0.1:8080/scene

# You should see headers like:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# X-XSS-Protection: 1; mode=block
# Content-Security-Policy: default-src 'self'; frame-ancestors 'none'
```

---

## Option 2: Using Helper Base Class

If you're creating new routers, extend `SecureRouterBase`:

### Step 1: Initialize once at startup

```gdscript
# In http_api_server.gd _ready():

# Initialize security headers for all SecureRouterBase subclasses
var SecureRouterBase = load("res://scripts/http_api/secure_router_base.gd")
if SecureRouterBase:
    SecureRouterBase.initialize_security_headers(1)  # MODERATE preset
```

### Step 2: Extend SecureRouterBase in your routers

```gdscript
# NEW router: my_secure_router.gd
extends SecureRouterBase

func _init():
    path = "/api/myendpoint"

func handle_get(request: HttpRequest, response: GodottpdResponse) -> bool:
    # Use helper method (headers automatically included!)
    send_json_response(response, 200, {
        "message": "Hello, security headers are automatic!"
    })
    return true

func handle_post(request: HttpRequest, response: GodottpdResponse) -> bool:
    var data = JSON.parse_string(request.body)

    # Headers automatically included
    send_json_response(response, 201, {
        "status": "created",
        "data": data
    })
    return true
```

---

## Option 3: Global Autoload (Easiest)

### Step 1: Add SecurityHeadersPatch as autoload

1. Open Project Settings → Autoload
2. Add new entry:
   - **Name**: `SecurityHeadersPatch`
   - **Path**: `res://scripts/http_api/security_headers_patch.gd`
   - **Enable**: ✓

### Step 2: Use in any router

```gdscript
func handle_get(request: HttpRequest, response: GodottpdResponse) -> bool:
    # Get global patch instance
    var patch = get_node("/root/SecurityHeadersPatch")
    if patch:
        patch.apply_to_response(response)

    # Your response code
    response.json(200, {"status": "ok"})
    return true
```

---

## Testing Checklist

After integration, verify:

- [ ] Run `python tests/security/test_security_headers.py`
- [ ] All tests pass
- [ ] Test with `curl -I http://127.0.0.1:8080/scene`
- [ ] Headers appear in response
- [ ] Browser developer tools show headers
- [ ] No console errors or warnings

---

## Configuration Options

### Change Security Preset

```gdscript
# PERMISSIVE (development only)
var middleware = SecurityHeadersMiddleware.new(2)

# MODERATE (recommended)
var middleware = SecurityHeadersMiddleware.new(1)

# STRICT (maximum security)
var middleware = SecurityHeadersMiddleware.new(0)
```

### Custom CSP Policy

```gdscript
# Allow specific domains
middleware.set_csp("default-src 'self'; img-src 'self' https://cdn.example.com")

# Allow inline scripts (use with caution!)
middleware.set_csp("default-src 'self'; script-src 'self' 'unsafe-inline'")
```

### Enable HSTS (HTTPS only!)

```gdscript
# Only when serving over HTTPS
if not OS.is_debug_build():
    middleware.enable_hsts()
```

---

## Common Errors and Fixes

### Error: "SecurityHeadersMiddleware not found"

**Fix**: Verify file exists at `res://scripts/http_api/security_headers.gd`

### Error: Headers still missing after integration

**Fix**: Make sure you're calling `apply_headers()` BEFORE sending response:

```gdscript
# ✅ CORRECT
middleware.apply_headers(response)
response.json(200, {})

# ❌ WRONG
response.json(200, {})
middleware.apply_headers(response)  # Too late!
```

### Error: CSP blocks resources

**Fix**: Adjust CSP policy to allow necessary resources:

```gdscript
middleware.set_csp("default-src 'self'; img-src 'self' data: https:")
```

---

## Next Steps

1. ✅ Choose integration method (Option 1 recommended)
2. ✅ Update http_api_server.gd
3. ✅ Update all routers
4. ✅ Run test suite
5. ✅ Deploy and verify in production
6. 📅 Schedule quarterly security review

---

## Support

- **Documentation**: `C:/godot/docs/security/SECURITY_HEADERS_IMPLEMENTATION.md`
- **Test Script**: `C:/godot/tests/security/test_security_headers.py`
- **Middleware Code**: `C:/godot/scripts/http_api/security_headers.gd`

**Questions?** Review the full implementation documentation for detailed examples.
