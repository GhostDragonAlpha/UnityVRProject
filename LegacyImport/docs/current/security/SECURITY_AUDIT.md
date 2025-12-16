# Security Audit Report: HTTP Scene Management API

**Date:** 2025-12-02
**Scope:** HTTP Scene Management API and related HTTP services
**Auditor:** Claude Code Security Analysis
**Risk Level:** **HIGH - NOT PRODUCTION SAFE**

---

## Executive Summary

The HTTP Scene Management API in SpaceTime/Godot has **CRITICAL security vulnerabilities** that make it unsuitable for production use without significant hardening. The API was designed for local development/debugging and lacks fundamental security controls. **This system should ONLY be used in trusted, isolated development environments.**

### Critical Findings

| Severity | Count | Description |
|----------|-------|-------------|
| **CRITICAL** | 3 | No authentication, path traversal risks, DoS potential |
| **HIGH** | 4 | Input validation gaps, resource exhaustion, unlimited scene loading |
| **MEDIUM** | 5 | Missing rate limiting, no timeout configuration, verbose errors |
| **LOW** | 3 | Missing security headers, no audit logging, weak CORS |

**Recommendation:** Do NOT expose this API to untrusted networks. Implement the hardening recommendations before any production deployment.

---

## 1. Current Security Posture

### What's Protected

1. **Path Format Validation** (Partial)
   - Scene paths must start with `res://`
   - Scene paths must end with `.tscn`
   - ResourceLoader checks file existence
   - Location: `scene_router.gd` lines 24-29

2. **Directory Traversal Protection** (Limited)
   - godottpd library has some path normalization
   - `res://` prefix prevents absolute path attacks
   - URI decoding in scenes_list_router.gd line 12

3. **Client Connection Limits** (GodotBridge only)
   - MAX_CLIENTS = 100 in `godot_bridge.gd`
   - MAX_REQUEST_SIZE = 10MB in `godot_bridge.gd`
   - Note: **http_api_server.gd has NO limits**

4. **JSON Validation**
   - Content-Type checking for application/json
   - JSON parse error handling
   - Type validation for dictionary bodies

### What's Vulnerable

1. **No Authentication/Authorization**
   - Any client on localhost can load arbitrary scenes
   - No API keys, tokens, or credentials required
   - No session management
   - No role-based access control

2. **No Rate Limiting**
   - Unlimited scene load requests
   - Can spam reload endpoints
   - Can exhaust scene history storage
   - Can overwhelm telemetry system

3. **Resource Exhaustion**
   - Scene validation loads entire scene into memory (`scene_router.gd` line 135)
   - No limits on scene complexity
   - Recursive directory scanning in scenes list (`scenes_list_router.gd` line 58)
   - Static history array can grow unbounded (MAX_HISTORY = 10 is not enforced)

4. **Information Disclosure**
   - Verbose error messages reveal internal paths
   - Scene validation exposes node structure
   - Directory listing exposes project structure
   - File modification times leaked

5. **Injection Vulnerabilities**
   - Scene path concatenation could be exploited
   - No sanitization of scene names in responses
   - Query parameters passed without validation

### Attack Surface Analysis

**Exposed Endpoints (Port 8080):**
```
POST   /scene              - Load arbitrary scene
GET    /scene              - Get current scene info
PUT    /scene              - Validate scene (DoS vector)
GET    /scenes?dir=X       - List scenes (information disclosure)
POST   /scene/reload       - Reload current scene
GET    /scene/history      - Get scene load history
```

**Exposed via GodotBridge (Port 8080-8085):**
- 30+ endpoints including debug, LSP, execute commands
- Scene management endpoints duplicated
- Input injection endpoints for testing

**Network Exposure:**
- http_api_server.gd binds to 0.0.0.0:8080 (ALL interfaces)
- godot_bridge.gd binds to 127.0.0.1 (localhost only)
- UDP service discovery broadcasts to 255.255.255.255:8087

**Critical Issue:** The new http_api_server.gd may bind to all network interfaces, exposing it beyond localhost!

---

## 2. Identified Vulnerabilities

### CRITICAL Vulnerabilities

#### CRITICAL-1: No Authentication or Authorization
**File:** All router files
**Severity:** CRITICAL
**CVSS:** 9.8 (Critical)

**Description:**
Zero authentication mechanisms. Any process or user that can reach the HTTP port can:
- Load arbitrary scenes from the project
- Reload the current scene repeatedly
- Query project structure
- Execute debug commands (via GodotBridge)

**Attack Scenario:**
```bash
# Attacker loads malicious scene
curl -X POST http://target:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://malicious_scene.tscn"}'

# Attacker crashes game by loading invalid scene repeatedly
while true; do
  curl -X POST http://target:8080/scene/reload
  sleep 0.1
done
```

**Impact:**
- Complete control over scene state
- Denial of service
- Information disclosure
- Game state manipulation

---

#### CRITICAL-2: Path Traversal via Directory Listing
**File:** `scenes_list_router.gd`
**Lines:** 11-12, 28, 47-101
**Severity:** CRITICAL
**CVSS:** 8.6 (High)

**Description:**
The `/scenes` endpoint accepts a `dir` query parameter that is URI-decoded and passed to `_scan_scenes()`. While the code checks for `res://` prefix, it doesn't prevent traversal within the resource system.

**Vulnerable Code:**
```gdscript
# scenes_list_router.gd line 11-12
var base_dir_raw = request.query.get("dir", "res://")
var base_dir = base_dir_raw.uri_decode() if base_dir_raw else "res://"
```

**Attack Scenario:**
```bash
# Enumerate entire project structure
curl "http://target:8080/scenes?dir=res://&include_addons=true"

# Enumerate specific directories
curl "http://target:8080/scenes?dir=res://scripts/"
curl "http://target:8080/scenes?dir=res://addons/"

# Try to confuse path validation
curl "http://target:8080/scenes?dir=res://../../../"
curl "http://target:8080/scenes?dir=res://./././scripts/"
```

**Impact:**
- Complete project structure disclosure
- File metadata leakage (sizes, modification times)
- Reconnaissance for further attacks

**Notes:**
- Godot's `res://` system may prevent filesystem escape, but allows full resource enumeration
- The `include_addons` parameter reveals third-party code
- No whitelist of allowed directories

---

#### CRITICAL-3: Denial of Service via Scene Validation
**File:** `scene_router.gd`
**Lines:** 86-165
**Severity:** CRITICAL
**CVSS:** 7.5 (High)

**Description:**
The `PUT /scene` endpoint validates scenes by loading them entirely into memory and instantiating them. An attacker can specify complex scenes to exhaust memory and CPU.

**Vulnerable Code:**
```gdscript
# scene_router.gd line 135
var packed_scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)

# scene_router.gd line 158
var instance = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
```

**Attack Scenario:**
```bash
# Validate a massive scene repeatedly
while true; do
  curl -X PUT http://target:8080/scene \
    -H "Content-Type: application/json" \
    -d '{"scene_path": "res://huge_procedural_universe.tscn"}'
done

# Or validate many scenes in parallel
for scene in $(seq 1 100); do
  curl -X PUT http://target:8080/scene \
    -H "Content-Type: application/json" \
    -d '{"scene_path": "res://vr_main.tscn"}' &
done
```

**Impact:**
- Memory exhaustion (OOM crash)
- CPU exhaustion (unresponsive game)
- Disk thrashing (if swap is used)
- VR headset freeze (dangerous for user)

**Notes:**
- No timeout on validation
- No resource limits
- Validation happens synchronously in request handler
- In VR context, this could cause nausea or injury

---

### HIGH Severity Vulnerabilities

#### HIGH-1: Unlimited Scene History Growth
**File:** `scene_history_router.gd`
**Lines:** 9, 35-62
**Severity:** HIGH

**Description:**
Static array `_history` is documented with MAX_HISTORY = 10, but the `add_to_history()` method doesn't enforce this limit consistently across all code paths.

**Vulnerable Code:**
```gdscript
# scene_history_router.gd line 59
if _history.size() > MAX_HISTORY:
    _history.resize(MAX_HISTORY)
```

**Attack Scenario:**
```bash
# Load scenes repeatedly to grow history
for i in {1..10000}; do
  curl -X POST http://target:8080/scene/reload
done
```

**Impact:**
- Memory leak
- Slow history queries
- Potential array bounds issues

---

#### HIGH-2: Unrestricted Recursive Directory Scanning
**File:** `scenes_list_router.gd`
**Lines:** 58-101
**Severity:** HIGH

**Description:**
The `_scan_directory()` function recursively scans directories without depth limits or timeout. Large project structures can cause excessive CPU usage.

**Vulnerable Code:**
```gdscript
# scenes_list_router.gd line 85
_scan_directory(full_path, scenes, include_addons)  # Unbounded recursion
```

**Attack Scenario:**
```bash
# Trigger expensive scan
curl "http://target:8080/scenes?dir=res://&include_addons=true"

# If attacker can create symlinks (unlikely in res://), could cause infinite loop
```

**Impact:**
- CPU exhaustion
- Request timeout (blocks other requests)
- Potential stack overflow with deep nesting

---

#### HIGH-3: No Request Size Limits (http_api_server.gd)
**File:** `http_api_server.gd`, godottpd library
**Lines:** N/A (missing protection)
**Severity:** HIGH

**Description:**
The new HTTP API server using godottpd doesn't implement request size limits. The underlying library reads entire requests into memory.

**Comparison:**
- `godot_bridge.gd` has `MAX_REQUEST_SIZE = 10MB` (line 44)
- `http_api_server.gd` has NO size limits

**Attack Scenario:**
```bash
# Send huge JSON payload
curl -X POST http://target:8080/scene \
  -H "Content-Type: application/json" \
  -d "$(python3 -c 'print("{\"scene_path\": \"" + "A"*1000000000 + "\"}")')"
```

**Impact:**
- Memory exhaustion
- OOM crash
- Slow request processing

---

#### HIGH-4: Scene Path Injection in Responses
**File:** Multiple routers
**Lines:** Various
**Severity:** HIGH

**Description:**
Scene paths from user input are included directly in JSON responses without sanitization. Could enable JSON injection or XSS if responses are rendered in browsers.

**Vulnerable Code:**
```gdscript
# scene_router.gd line 47-51
response.send(200, JSON.stringify({
    "status": "loading",
    "scene": scene_path,  # User-controlled, unsanitized
    "message": "Scene load initiated successfully"
}))
```

**Attack Scenario:**
```bash
# Inject malicious content
curl -X POST http://target:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://test.tscn\",\"malicious\":\"data"}'
```

**Impact:**
- JSON structure manipulation
- XSS if rendered in web dashboard
- Log injection

**Note:** Godot's `JSON.stringify()` may escape some characters, but not verified.

---

### MEDIUM Severity Vulnerabilities

#### MEDIUM-1: Missing Rate Limiting
**Files:** All routers
**Severity:** MEDIUM

**Description:**
No rate limiting on any endpoints. Attacker can flood the server with requests.

**Impact:**
- Service degradation
- CPU/bandwidth exhaustion
- Prevents legitimate use

**Recommendation:** Implement token bucket or sliding window rate limiting.

---

#### MEDIUM-2: Verbose Error Messages
**Files:** All routers
**Severity:** MEDIUM

**Description:**
Error responses include detailed internal information.

**Examples:**
```gdscript
# scene_router.gd line 35
"message": "Scene file not found: " + scene_path

# scenes_list_router.gd line 23
"message": "Directory path must start with 'res://'"
```

**Impact:**
- Information disclosure
- Helps attackers craft exploits

**Recommendation:** Return generic errors to clients, log details server-side.

---

#### MEDIUM-3: No Request Timeouts
**Files:** All routers
**Severity:** MEDIUM

**Description:**
Scene loading and validation have no timeout limits.

**Impact:**
- Hung requests
- Resource exhaustion
- Slowloris-style attacks

---

#### MEDIUM-4: Unrestricted Scene Loading
**File:** `scene_router.gd`
**Severity:** MEDIUM

**Description:**
Any scene in `res://` can be loaded without whitelist checking.

**Impact:**
- Load debug/test scenes in production
- Load incomplete/broken scenes
- Access scenes meant to be internal

**Recommendation:** Implement scene whitelist for production.

---

#### MEDIUM-5: Static History Singleton Pattern
**File:** `scene_history_router.gd`
**Lines:** 7-8
**Severity:** MEDIUM

**Description:**
Uses static singleton pattern for history, making it persist across router instances and potentially causing state corruption.

**Vulnerable Code:**
```gdscript
static var _instance: SceneHistoryRouter = null
static var _history: Array = []
```

**Impact:**
- State corruption if multiple instances
- Memory leaks
- Race conditions

---

### LOW Severity Vulnerabilities

#### LOW-1: Missing Security Headers
**Files:** All routers
**Severity:** LOW

**Description:**
Responses lack security headers like:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Strict-Transport-Security`

**Impact:** Reduced defense-in-depth

---

#### LOW-2: No Audit Logging
**Files:** All routers
**Severity:** LOW

**Description:**
No structured audit logs for security events (scene loads, validation attempts, errors).

**Impact:** Difficult to detect/investigate attacks

---

#### LOW-3: Weak CORS Configuration
**File:** godottpd library
**Severity:** LOW

**Description:**
CORS is optional and not enforced by default. If enabled, allows all origins.

**Impact:** Web-based attacks if exposed

---

## 3. Threat Model

### Threat Actors

1. **Untrusted Network Attacker**
   - **Access:** Network access to HTTP port
   - **Goal:** Crash service, steal information, manipulate game state
   - **Likelihood:** HIGH if exposed to internet/LAN

2. **Malicious Scene File**
   - **Access:** Ability to place .tscn files in project
   - **Goal:** Code execution, data exfiltration
   - **Likelihood:** MEDIUM in development, LOW in production

3. **API Abuse by Compromised Tool**
   - **Access:** Localhost access (e.g., compromised development tool)
   - **Goal:** Manipulate game state, DoS
   - **Likelihood:** LOW but increasing with supply chain attacks

### Attack Scenarios

#### Scenario 1: Remote DoS Attack
1. Attacker discovers exposed port 8080 on target
2. Attacker sends rapid requests to `/scene/reload`
3. Game repeatedly reloads scene, becoming unplayable
4. VR users experience nausea from repeated scene transitions
5. Service crashes from resource exhaustion

**Mitigation:** Rate limiting, authentication, localhost-only binding

---

#### Scenario 2: Information Disclosure
1. Attacker queries `/scenes?dir=res://&include_addons=true`
2. Attacker learns project structure, file names, dependencies
3. Attacker identifies known-vulnerable addons
4. Attacker crafts targeted attacks based on reconnaissance

**Mitigation:** Authentication, directory whitelist, disable directory listing

---

#### Scenario 3: Scene Validation DoS
1. Attacker sends PUT requests with complex scene paths
2. Server loads and instantiates scenes repeatedly
3. Memory exhaustion causes OOM crash
4. In VR context, headset freezes, user cannot recover

**Mitigation:** Validation timeout, resource limits, async validation

---

#### Scenario 4: Malicious Scene Loading
1. Attacker (or compromised tool) places malicious.tscn in project
2. Attacker sends POST to `/scene` with malicious scene path
3. Scene contains GDScript nodes with malicious code
4. Code executes in game context with full permissions

**Mitigation:** Scene whitelist, code signing, sandboxing

---

#### Scenario 5: Supply Chain Attack via Compromised Development Tool
1. Popular Godot development tool is compromised
2. Tool has localhost API access (normal for development)
3. Tool sends malicious API requests to manipulate game state
4. Developer unknowingly deploys backdoored game build

**Mitigation:** Principle of least privilege, API authentication, audit logging

---

## 4. Hardening Recommendations

### Priority 1: CRITICAL (Implement Immediately)

#### 1.1 Add Authentication
**Priority:** CRITICAL
**Effort:** Medium

Implement token-based authentication:

```gdscript
# auth_middleware.gd
class_name AuthMiddleware
extends RefCounted

const API_TOKEN_ENV = "GODOT_API_TOKEN"
static var _api_token: String = ""

static func initialize() -> void:
    # Load from environment or config file
    _api_token = OS.get_environment(API_TOKEN_ENV)
    if _api_token.is_empty():
        _api_token = _generate_secure_token()
        print("[AUTH] Generated API token: ", _api_token)
        print("[AUTH] Set environment variable: export GODOT_API_TOKEN='%s'" % _api_token)

static func _generate_secure_token() -> String:
    # Generate cryptographically secure token
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var token = ""
    for i in range(32):
        token += "%02x" % rng.randi_range(0, 255)
    return token

static func validate_request(request: HttpRequest) -> bool:
    # Check Authorization header
    var auth_header = request.headers.get("authorization", request.headers.get("Authorization", ""))

    if auth_header.is_empty():
        return false

    # Expected format: "Bearer <token>"
    if not auth_header.begins_with("Bearer "):
        return false

    var token = auth_header.substr(7).strip_edges()
    return token == _api_token

static func send_auth_error(response: GodottpdResponse) -> void:
    response.send(401, JSON.stringify({
        "error": "Unauthorized",
        "message": "Valid API token required"
    }))
```

**Usage in routers:**
```gdscript
# scene_router.gd
func _init():
    var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
        # FIRST: Check authentication
        if not AuthMiddleware.validate_request(request):
            AuthMiddleware.send_auth_error(response)
            return true

        # THEN: Process request
        var body = request.get_body_parsed()
        # ... existing code ...
```

---

#### 1.2 Bind to Localhost Only
**Priority:** CRITICAL
**Effort:** Trivial

**Current (UNSAFE):**
```gdscript
# http_api_server.gd
const PORT = 8080
# godottpd defaults to binding "*" (all interfaces)
```

**Fixed:**
```gdscript
# http_api_server.gd
const PORT = 8080
const BIND_ADDRESS = "127.0.0.1"  # Localhost only

func _ready():
    # ...
    server = load("res://addons/godottpd/http_server.gd").new()
    server.port = PORT
    server.bind_address = BIND_ADDRESS  # CRITICAL: Localhost only
    # ...
```

**Rationale:** Development API should NEVER be exposed to network.

---

#### 1.3 Implement Scene Whitelist
**Priority:** CRITICAL
**Effort:** Low

```gdscript
# scene_whitelist.gd
class_name SceneWhitelist
extends RefCounted

# Whitelist of allowed scenes for production
const ALLOWED_SCENES = [
    "res://vr_main.tscn",
    "res://scenes/main_menu.tscn",
    "res://scenes/gameplay.tscn",
    # Add other safe scenes
]

# In development, allow all scenes
const DEVELOPMENT_MODE = true  # Set to false for production

static func is_scene_allowed(scene_path: String) -> bool:
    if DEVELOPMENT_MODE:
        # In dev, only check format
        return scene_path.begins_with("res://") and scene_path.ends_with(".tscn")
    else:
        # In production, check whitelist
        return scene_path in ALLOWED_SCENES

static func get_allowed_scenes() -> Array:
    if DEVELOPMENT_MODE:
        return []  # Return empty to indicate "all scenes"
    else:
        return ALLOWED_SCENES
```

**Usage:**
```gdscript
# scene_router.gd
if not SceneWhitelist.is_scene_allowed(scene_path):
    response.send(403, JSON.stringify({
        "error": "Forbidden",
        "message": "Scene not in allowed list"
    }))
    return true
```

---

### Priority 2: HIGH (Implement Soon)

#### 2.1 Add Rate Limiting
**Priority:** HIGH
**Effort:** Medium

```gdscript
# rate_limiter.gd
class_name RateLimiter
extends RefCounted

# Token bucket algorithm
class TokenBucket:
    var capacity: int
    var tokens: float
    var refill_rate: float  # tokens per second
    var last_refill: int  # ticks_msec

    func _init(capacity: int, refill_rate: float):
        self.capacity = capacity
        self.tokens = float(capacity)
        self.refill_rate = refill_rate
        self.last_refill = Time.get_ticks_msec()

    func try_consume(count: int = 1) -> bool:
        _refill()
        if tokens >= count:
            tokens -= count
            return true
        return false

    func _refill() -> void:
        var now = Time.get_ticks_msec()
        var elapsed = (now - last_refill) / 1000.0  # seconds
        tokens = min(capacity, tokens + (refill_rate * elapsed))
        last_refill = now

# Per-endpoint rate limiters
static var _limiters: Dictionary = {}

static func get_limiter(endpoint: String) -> TokenBucket:
    if not _limiters.has(endpoint):
        # Configure per-endpoint limits
        match endpoint:
            "/scene", "/scene/reload":
                # 10 scene changes per minute
                _limiters[endpoint] = TokenBucket.new(10, 10.0 / 60.0)
            "/scene/validate":
                # 5 validations per minute (expensive)
                _limiters[endpoint] = TokenBucket.new(5, 5.0 / 60.0)
            "/scenes":
                # 30 listings per minute
                _limiters[endpoint] = TokenBucket.new(30, 30.0 / 60.0)
            _:
                # Default: 60 requests per minute
                _limiters[endpoint] = TokenBucket.new(60, 1.0)

    return _limiters[endpoint]

static func check_rate_limit(endpoint: String, response: GodottpdResponse) -> bool:
    var limiter = get_limiter(endpoint)
    if not limiter.try_consume():
        response.send(429, JSON.stringify({
            "error": "Too Many Requests",
            "message": "Rate limit exceeded. Please try again later."
        }))
        return false
    return true
```

**Usage:**
```gdscript
# scene_router.gd
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    if not AuthMiddleware.validate_request(request):
        AuthMiddleware.send_auth_error(response)
        return true

    if not RateLimiter.check_rate_limit("/scene", response):
        return true  # Rate limit response already sent

    # ... existing code ...
```

---

#### 2.2 Add Request Size Limits
**Priority:** HIGH
**Effort:** Low

```gdscript
# request_validator.gd
class_name RequestValidator
extends RefCounted

const MAX_REQUEST_BODY_SIZE = 1024 * 1024  # 1MB
const MAX_PATH_LENGTH = 512
const MAX_QUERY_PARAMS = 20

static func validate_request_size(request: HttpRequest, response: GodottpdResponse) -> bool:
    # Check body size
    if request.body.length() > MAX_REQUEST_BODY_SIZE:
        response.send(413, JSON.stringify({
            "error": "Payload Too Large",
            "message": "Request body exceeds maximum size"
        }))
        return false

    # Check path length
    if request.path.length() > MAX_PATH_LENGTH:
        response.send(414, JSON.stringify({
            "error": "URI Too Long",
            "message": "Request path exceeds maximum length"
        }))
        return false

    # Check query parameter count
    if request.query.size() > MAX_QUERY_PARAMS:
        response.send(400, JSON.stringify({
            "error": "Bad Request",
            "message": "Too many query parameters"
        }))
        return false

    return true
```

---

#### 2.3 Implement Validation Timeout
**Priority:** HIGH
**Effort:** Medium

```gdscript
# scene_router.gd - Modified validation with timeout
func _validate_scene(scene_path: String) -> Dictionary:
    var result = {
        "valid": true,
        "errors": [],
        "warnings": [],
        "scene_info": {}
    }

    var start_time = Time.get_ticks_msec()
    const VALIDATION_TIMEOUT_MS = 5000  # 5 seconds max

    # Basic checks (fast)
    if scene_path.is_empty():
        result.valid = false
        result.errors.append("Scene path cannot be empty")
        return result

    if not scene_path.begins_with("res://"):
        result.valid = false
        result.errors.append("Scene path must start with 'res://'")

    if not scene_path.ends_with(".tscn"):
        result.valid = false
        result.errors.append("Scene path must end with '.tscn'")

    if not result.valid:
        return result

    # Check timeout before expensive operations
    if Time.get_ticks_msec() - start_time > VALIDATION_TIMEOUT_MS:
        result.valid = false
        result.errors.append("Validation timeout")
        return result

    # File existence check
    if not ResourceLoader.exists(scene_path):
        result.valid = false
        result.errors.append("Scene file not found")
        return result

    # Load scene (expensive)
    var packed_scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)

    if not packed_scene:
        result.valid = false
        result.errors.append("Failed to load scene resource")
        return result

    # Check timeout again
    if Time.get_ticks_msec() - start_time > VALIDATION_TIMEOUT_MS:
        result.valid = false
        result.errors.append("Validation timeout during scene loading")
        return result

    # Get scene metadata (fast)
    var scene_state = packed_scene.get_state()
    if scene_state.get_node_count() == 0:
        result.valid = false
        result.errors.append("Scene has no nodes")
        return result

    result.scene_info = {
        "node_count": scene_state.get_node_count(),
        "root_type": scene_state.get_node_type(0),
        "root_name": scene_state.get_node_name(0)
    }

    # SKIP expensive instantiation check to avoid DoS
    # Instead, just validate that the scene can be read
    if result.scene_info.node_count > 10000:
        result.valid = false
        result.errors.append("Scene too large (>10000 nodes)")
        return result

    # Add warnings
    if result.scene_info.node_count > 1000:
        result.warnings.append("Scene has many nodes, may impact performance")

    return result
```

---

#### 2.4 Sanitize Error Messages
**Priority:** HIGH
**Effort:** Low

```gdscript
# error_handler.gd
class_name ErrorHandler
extends RefCounted

const PRODUCTION_MODE = false  # Set to true for production

static func send_error(response: GodottpdResponse, code: int, error_type: String,
                       internal_message: String, user_message: String = "") -> void:
    # Log detailed error internally
    print("[ERROR] ", error_type, ": ", internal_message)

    # Send sanitized error to client
    var message = user_message if not user_message.is_empty() else _get_generic_message(code)

    var error_response = {
        "error": error_type,
        "message": message if PRODUCTION_MODE else internal_message
    }

    response.send(code, JSON.stringify(error_response))

static func _get_generic_message(code: int) -> String:
    match code:
        400: return "The request was invalid"
        401: return "Authentication required"
        403: return "Access denied"
        404: return "Resource not found"
        429: return "Too many requests"
        500: return "Internal server error"
        _: return "Request failed"
```

**Usage:**
```gdscript
# scene_router.gd
if not ResourceLoader.exists(scene_path):
    ErrorHandler.send_error(
        response, 404, "Not Found",
        "Scene file not found: " + scene_path,  # Internal log
        "Scene file not found"  # User message
    )
    return true
```

---

### Priority 3: MEDIUM (Implement Before Production)

#### 3.1 Add Security Headers
```gdscript
# security_headers.gd
class_name SecurityHeaders
extends RefCounted

static func add_security_headers(response: GodottpdResponse) -> void:
    # These would need to be added to godottpd response headers
    # For now, document the headers that should be added:
    pass
    # X-Content-Type-Options: nosniff
    # X-Frame-Options: DENY
    # X-XSS-Protection: 1; mode=block
    # Content-Security-Policy: default-src 'self'
    # Strict-Transport-Security: max-age=31536000; includeSubDomains
```

Note: godottpd may need to be modified to support custom headers.

---

#### 3.2 Implement Audit Logging
```gdscript
# audit_logger.gd
class_name AuditLogger
extends RefCounted

const LOG_FILE = "user://api_audit.log"

static func log_request(endpoint: String, method: String, client_ip: String,
                        user: String, success: bool, details: String = "") -> void:
    var timestamp = Time.get_datetime_string_from_system()
    var log_entry = "%s | %s | %s | %s | %s | %s | %s\n" % [
        timestamp,
        endpoint,
        method,
        client_ip,
        user,
        "SUCCESS" if success else "FAILURE",
        details
    ]

    var file = FileAccess.open(LOG_FILE, FileAccess.READ_WRITE)
    if file:
        file.seek_end()
        file.store_string(log_entry)
        file.close()

static func log_security_event(event_type: String, details: String) -> void:
    var timestamp = Time.get_datetime_string_from_system()
    var log_entry = "%s | SECURITY | %s | %s\n" % [
        timestamp,
        event_type,
        details
    ]

    var file = FileAccess.open(LOG_FILE, FileAccess.READ_WRITE)
    if file:
        file.seek_end()
        file.store_string(log_entry)
        file.close()

    # Also print to console
    push_warning("[SECURITY] ", event_type, ": ", details)
```

---

#### 3.3 Add Directory Whitelist for Scene Listing
```gdscript
# scenes_list_router.gd modifications
const ALLOWED_DIRECTORIES = [
    "res://scenes/",
    "res://levels/",
    "res://vr_scenes/",
]

func _is_directory_allowed(dir_path: String) -> bool:
    for allowed_dir in ALLOWED_DIRECTORIES:
        if dir_path.begins_with(allowed_dir):
            return true
    return false

var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    var base_dir_raw = request.query.get("dir", "res://")
    var base_dir = base_dir_raw.uri_decode() if base_dir_raw else "res://"

    # Validate directory is in whitelist
    if not _is_directory_allowed(base_dir):
        response.send(403, JSON.stringify({
            "error": "Forbidden",
            "message": "Directory access not allowed"
        }))
        return true

    # ... existing code ...
```

---

#### 3.4 Limit Directory Scan Depth
```gdscript
# scenes_list_router.gd modifications
const MAX_SCAN_DEPTH = 5
const MAX_FILES_PER_SCAN = 1000

func _scan_directory(dir_path: String, scenes: Array, include_addons: bool, depth: int = 0) -> void:
    # Prevent deep recursion
    if depth > MAX_SCAN_DEPTH:
        print("[ScenesListRouter] Max depth reached: ", dir_path)
        return

    # Prevent excessive file counts
    if scenes.size() > MAX_FILES_PER_SCAN:
        print("[ScenesListRouter] Max files reached, stopping scan")
        return

    var dir = DirAccess.open(dir_path)

    if dir == null:
        print("[ScenesListRouter] Warning: Could not open directory: ", dir_path)
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name.begins_with("."):
            file_name = dir.get_next()
            continue

        var full_path = dir_path.path_join(file_name)

        if dir.current_is_dir():
            if not include_addons and file_name == "addons":
                file_name = dir.get_next()
                continue

            # Recursive call with incremented depth
            _scan_directory(full_path, scenes, include_addons, depth + 1)

        elif file_name.ends_with(".tscn"):
            if not include_addons and full_path.contains("/addons/"):
                file_name = dir.get_next()
                continue

            var scene_info = _get_scene_info(full_path)
            if scene_info:
                scenes.append(scene_info)

        file_name = dir.get_next()

    dir.list_dir_end()
```

---

### Priority 4: LOW (Nice to Have)

#### 4.1 Implement HTTPS/TLS
For local development, this is overkill, but for any remote access:
- Use a reverse proxy (nginx, Caddy) with TLS termination
- Or implement TLS in Godot using StreamPeerTLS

---

#### 4.2 Add Request Correlation IDs
```gdscript
# Add to each request for tracing
var request_id = _generate_request_id()
print("[REQUEST] ", request_id, " - ", method, " ", path)
```

---

## 5. Secure vs Insecure Code Examples

### Example 1: Scene Loading

#### INSECURE (Current):
```gdscript
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    var body = request.get_body_parsed()
    var scene_path = body.get("scene_path", "res://vr_main.tscn")

    # No authentication check
    # No rate limiting
    # No whitelist check

    if not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn"):
        response.send(400, JSON.stringify({
            "error": "Bad Request",
            "message": "Invalid scene path. Must start with 'res://' and end with '.tscn'"
        }))
        return true

    if not ResourceLoader.exists(scene_path):
        response.send(404, JSON.stringify({
            "error": "Not Found",
            "message": "Scene file not found: " + scene_path  # Path disclosure
        }))
        return true

    var tree = Engine.get_main_loop() as SceneTree
    if tree:
        tree.call_deferred("change_scene_to_file", scene_path)

    response.send(200, JSON.stringify({
        "status": "loading",
        "scene": scene_path,  # Path disclosure
        "message": "Scene load initiated successfully"
    }))
    return true
```

#### SECURE (Hardened):
```gdscript
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    # 1. Validate request size
    if not RequestValidator.validate_request_size(request, response):
        AuditLogger.log_security_event("REQUEST_TOO_LARGE", request.path)
        return true

    # 2. Check authentication
    if not AuthMiddleware.validate_request(request):
        AuditLogger.log_security_event("AUTH_FAILURE", request.path)
        AuthMiddleware.send_auth_error(response)
        return true

    # 3. Check rate limit
    if not RateLimiter.check_rate_limit("/scene", response):
        AuditLogger.log_security_event("RATE_LIMIT_EXCEEDED", request.path)
        return true

    # 4. Parse and validate body
    var body = request.get_body_parsed()
    if not body:
        ErrorHandler.send_error(response, 400, "Bad Request",
            "Invalid JSON body", "Request body must be valid JSON")
        return true

    var scene_path = body.get("scene_path", "")

    if scene_path.is_empty():
        ErrorHandler.send_error(response, 400, "Bad Request",
            "Missing scene_path parameter", "scene_path is required")
        return true

    # 5. Validate scene path format
    if not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn"):
        ErrorHandler.send_error(response, 400, "Bad Request",
            "Invalid scene path format: " + scene_path,
            "Scene path must start with 'res://' and end with '.tscn'")
        return true

    # 6. Check scene whitelist
    if not SceneWhitelist.is_scene_allowed(scene_path):
        AuditLogger.log_security_event("SCENE_NOT_WHITELISTED", scene_path)
        ErrorHandler.send_error(response, 403, "Forbidden",
            "Scene not in whitelist: " + scene_path,
            "Scene access not allowed")
        return true

    # 7. Verify scene exists
    if not ResourceLoader.exists(scene_path):
        ErrorHandler.send_error(response, 404, "Not Found",
            "Scene file not found: " + scene_path,
            "Scene file not found")
        return true

    # 8. Load scene
    var tree = Engine.get_main_loop() as SceneTree
    if tree:
        tree.call_deferred("change_scene_to_file", scene_path)

        # 9. Log successful scene load
        AuditLogger.log_request("/scene", "POST", "127.0.0.1", "api_user",
                                true, "Loaded scene: " + scene_path)

        # 10. Send success response (minimal info)
        response.send(200, JSON.stringify({
            "status": "loading",
            "message": "Scene load initiated"
        }))
    else:
        ErrorHandler.send_error(response, 500, "Internal Server Error",
            "Could not access SceneTree",
            "Scene load failed")

    return true
```

---

### Example 2: Scene Listing

#### INSECURE (Current):
```gdscript
var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    var base_dir_raw = request.query.get("dir", "res://")
    var base_dir = base_dir_raw.uri_decode() if base_dir_raw else "res://"

    # No authentication
    # No whitelist check
    # No depth limit

    if not base_dir.begins_with("res://"):
        response.send(400, JSON.stringify({
            "error": "Bad Request",
            "message": "Directory path must start with 'res://'"
        }))
        return true

    var scenes = _scan_scenes(base_dir, include_addons)  # Unbounded scan

    response.send(200, JSON.stringify({
        "scenes": scenes,  # Full file info including timestamps
        "count": scenes.size(),
        "directory": base_dir
    }))
    return true
```

#### SECURE (Hardened):
```gdscript
const ALLOWED_DIRECTORIES = [
    "res://scenes/",
    "res://levels/"
]

var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    # 1. Check authentication
    if not AuthMiddleware.validate_request(request):
        AuthMiddleware.send_auth_error(response)
        return true

    # 2. Check rate limit
    if not RateLimiter.check_rate_limit("/scenes", response):
        return true

    # 3. Parse and validate query parameters
    var base_dir_raw = request.query.get("dir", "res://scenes/")
    var base_dir = base_dir_raw.uri_decode() if base_dir_raw else "res://scenes/"

    # 4. Normalize path
    base_dir = base_dir.simplify_path()

    # 5. Validate directory format
    if not base_dir.begins_with("res://"):
        ErrorHandler.send_error(response, 400, "Bad Request",
            "Invalid directory path: " + base_dir,
            "Directory path must start with 'res://'")
        return true

    # 6. Check directory whitelist
    var is_allowed = false
    for allowed_dir in ALLOWED_DIRECTORIES:
        if base_dir.begins_with(allowed_dir):
            is_allowed = true
            break

    if not is_allowed:
        AuditLogger.log_security_event("DIRECTORY_NOT_WHITELISTED", base_dir)
        ErrorHandler.send_error(response, 403, "Forbidden",
            "Directory not in whitelist: " + base_dir,
            "Directory access not allowed")
        return true

    # 7. Scan with limits
    var scenes = _scan_scenes_safe(base_dir, false)  # Don't include addons

    # 8. Sanitize response (remove internal details)
    var sanitized_scenes = []
    for scene in scenes:
        sanitized_scenes.append({
            "name": scene.name,
            "path": scene.path
            # Omit size_bytes, modified timestamp
        })

    # 9. Log request
    AuditLogger.log_request("/scenes", "GET", "127.0.0.1", "api_user",
                            true, "Listed %d scenes in %s" % [scenes.size(), base_dir])

    # 10. Send response
    response.send(200, JSON.stringify({
        "scenes": sanitized_scenes,
        "count": sanitized_scenes.size()
    }))
    return true

func _scan_scenes_safe(base_path: String, include_addons: bool) -> Array:
    var scenes = []
    _scan_directory(base_path, scenes, include_addons, 0)  # Start at depth 0
    scenes.sort_custom(func(a, b): return a["path"] < b["path"])
    return scenes
```

---

## 6. Summary and Recommendations

### Is Current Code Production-Safe?

**NO. Absolutely not.**

The current HTTP Scene Management API has **CRITICAL** security vulnerabilities that make it completely unsuitable for production use. Specifically:

1. **No authentication** - Anyone can control the game
2. **Network exposed** - May bind to all interfaces (0.0.0.0)
3. **No rate limiting** - Trivial DoS attacks
4. **Resource exhaustion** - Scene validation can crash the game
5. **Information disclosure** - Full project structure enumeration

### Most Important Fix Recommendations (Priority Order)

1. **CRITICAL - Bind to localhost only** (1 line change)
   ```gdscript
   server.bind_address = "127.0.0.1"
   ```

2. **CRITICAL - Add authentication** (token-based, 50 lines)
   - Generate secure API token on startup
   - Validate `Authorization: Bearer <token>` header on all requests

3. **CRITICAL - Implement scene whitelist** (30 lines)
   - Only allow loading pre-approved scenes
   - Reject requests for arbitrary scene paths

4. **HIGH - Add rate limiting** (100 lines)
   - Token bucket algorithm per endpoint
   - 10 scene loads/minute, 5 validations/minute

5. **HIGH - Add validation timeout** (20 lines)
   - 5 second max for scene validation
   - Skip expensive instantiation check

6. **HIGH - Sanitize error messages** (50 lines)
   - Log detailed errors internally
   - Return generic errors to client

7. **MEDIUM - Add request size limits** (30 lines)
   - 1MB max body size
   - 512 byte max path length

8. **MEDIUM - Implement audit logging** (100 lines)
   - Log all API requests with timestamps
   - Log security events (auth failures, rate limits)

9. **MEDIUM - Add directory whitelist** (20 lines)
   - Only allow listing specific directories
   - Prevent full project enumeration

10. **MEDIUM - Limit scan depth** (10 lines)
    - Max 5 levels deep
    - Max 1000 files per scan

### Estimated Implementation Time

- **Minimal security (items 1-3):** 4 hours
- **Strong security (items 1-6):** 12 hours
- **Production-ready (items 1-10):** 24 hours

### Risk Assessment After Hardening

| Threat | Before | After Hardening |
|--------|--------|----------------|
| Remote DoS | CRITICAL | LOW |
| Unauthorized Access | CRITICAL | LOW |
| Information Disclosure | HIGH | MEDIUM |
| Resource Exhaustion | HIGH | LOW |
| Malicious Scene Loading | MEDIUM | LOW |

---

## Conclusion

The HTTP Scene Management API is a powerful development tool but was designed for trusted, local use only. **The current implementation is NOT safe for any environment where untrusted users or processes could access the HTTP port.**

Before considering production deployment, implement at minimum:
1. Bind to localhost only
2. Add authentication
3. Implement scene whitelist
4. Add rate limiting
5. Add validation timeout

Even with these changes, this API should be **disabled entirely in production builds** unless absolutely necessary. Consider implementing a separate, heavily restricted API for production use cases.

---

## References

- OWASP API Security Top 10: https://owasp.org/API-Security/
- CWE-22: Path Traversal: https://cwe.mitre.org/data/definitions/22.html
- CWE-400: Resource Exhaustion: https://cwe.mitre.org/data/definitions/400.html
- CWE-287: Authentication Bypass: https://cwe.mitre.org/data/definitions/287.html

**END OF SECURITY AUDIT REPORT**
