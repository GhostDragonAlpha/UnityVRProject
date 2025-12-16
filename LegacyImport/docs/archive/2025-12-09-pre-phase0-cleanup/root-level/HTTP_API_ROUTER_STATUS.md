# HTTP API Router Status and Activation Guide

**Document Version**: 1.0
**Last Updated**: 2025-12-04
**Status**: Production API on port 8080 (HttpApiServer)

## Overview

The SpaceTime HTTP API system consists of **12 total routers**: 4 currently active and 8 disabled. This document provides a complete status of each router, prerequisites for enabling disabled routers, and step-by-step activation instructions.

**Key Facts:**
- **Active API Port**: 8080 (HttpApiServer - production)
- **Legacy Port**: 8080 (GodotBridge - deprecated and disabled)
- **Active Routers**: 4 scene management routers
- **Disabled Routers**: 8 advanced feature routers (admin, webhooks, jobs, performance, auth, batch)

---

## 1. Currently Active Routers (4/12)

These routers are registered in `http_api_server.gd` lines 180-197 and fully operational:

### 1.1 SceneHistoryRouter
- **Endpoint**: `GET /scene/history`
- **Purpose**: Track last 10 scene loads with timestamps and duration
- **Implementation**: `scripts/http_api/scene_history_router.gd`
- **Features**:
  - Maintains history of scene loads (max 10 entries)
  - Returns scene path, name, timestamp, load duration
  - Authentication required
  - Rate limiting enabled
- **Status**: ✅ **ACTIVE** (registered line 180-182)

### 1.2 SceneReloadRouter
- **Endpoint**: `POST /scene/reload`
- **Purpose**: Reload current scene without specifying path
- **Implementation**: `scripts/http_api/scene_reload_router.gd`
- **Features**:
  - Hot-reloads current scene
  - No path required (uses current scene's file path)
  - Preserves scene state where possible
  - Authentication required
  - Rate limiting enabled
- **Status**: ✅ **ACTIVE** (registered line 185-187)

### 1.3 SceneRouter
- **Endpoint**:
  - `POST /scene` - Load scene
  - `GET /scene` - Get current scene
  - `PUT /scene` - Validate scene
- **Purpose**: Core scene management operations
- **Implementation**: `scripts/http_api/scene_router.gd`
- **Features**:
  - Load scenes by path
  - Query current scene information
  - Validate scene files before loading
  - Whitelist validation
  - Scene file existence checks
  - Authentication required
  - Rate limiting enabled
  - Client IP extraction with X-Forwarded-For validation
- **Status**: ✅ **ACTIVE** (registered line 190-192)

### 1.4 ScenesListRouter
- **Endpoint**: `GET /scenes`
- **Purpose**: List available scenes in project
- **Implementation**: `scripts/http_api/scenes_list_router.gd`
- **Features**:
  - Recursive directory scanning for .tscn files
  - Optional addons directory inclusion
  - Query parameters: `?dir=res://path&include_addons=true`
  - Returns scene metadata (name, path, size, modified date)
  - Authentication required
  - Rate limiting enabled
- **Status**: ✅ **ACTIVE** (registered line 195-197)

---

## 2. Disabled Routers (8/12)

These routers are **implemented but NOT registered** in `http_api_server.gd`. They require prerequisites before activation.

### 2.1 AdminRouter
- **Endpoint**: `/admin/*`
- **Purpose**: Administrative endpoints for monitoring and management
- **Implementation**: `scripts/http_api/admin_router.gd`
- **Features**:
  - System metrics (uptime, request counts, response times)
  - Health monitoring (component status, error rates)
  - Logs viewing and filtering
  - Configuration management
  - Cache clearing
  - Security events tracking
  - Audit log access
  - Scene statistics
  - Webhook management
  - Job queue monitoring
  - Active connections tracking
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Uses RefCounted pattern (not HttpRouter)
  - Needs integration with HttpRouter pattern
- **Prerequisites**:
  1. Convert from RefCounted to extend HttpRouter
  2. Implement proper route handlers
  3. Add to `_register_routers()` in http_api_server.gd
- **Status**: ⚠️ **DISABLED** (implementation complete, needs integration)

### 2.2 WebhookRouter
- **Endpoint**: `/webhooks`
- **Purpose**: Webhook registration and management
- **Implementation**: `scripts/http_api/webhook_router.gd`
- **Features**:
  - POST /webhooks - Register new webhook
  - GET /webhooks - List all webhooks
  - HMAC signature validation
  - Event subscription (scene.loaded, scene.failed, etc.)
  - Delivery tracking with retry logic
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Depends on WebhookManager autoload (NOT in project.godot)
- **Prerequisites**:
  1. Add WebhookManager to autoload in project.godot:
     ```gdscript
     WebhookManager="*res://scripts/http_api/webhook_manager.gd"
     ```
  2. Register router in http_api_server.gd `_register_routers()`:
     ```gdscript
     var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
     server.register_router(webhook_router)
     ```
  3. Test webhook delivery and retry logic
- **Status**: ⚠️ **DISABLED** (needs autoload + registration)

### 2.3 JobRouter
- **Endpoint**: `/jobs`
- **Purpose**: Background job queue management
- **Implementation**: `scripts/http_api/job_router.gd`
- **Features**:
  - POST /jobs - Submit new job
  - GET /jobs - List jobs with status filter
  - Supports: batch_operations, scene_preload, cache_warming
  - Job status tracking (queued, running, completed, failed)
  - Progress monitoring
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Depends on JobQueue autoload (NOT in project.godot)
- **Prerequisites**:
  1. Add JobQueue to autoload in project.godot:
     ```gdscript
     JobQueue="*res://scripts/http_api/job_queue.gd"
     ```
  2. Register router in http_api_server.gd `_register_routers()`:
     ```gdscript
     var job_router = load("res://scripts/http_api/job_router.gd").new()
     server.register_router(job_router)
     ```
  3. Test job submission and processing
- **Status**: ⚠️ **DISABLED** (needs autoload + registration)

### 2.4 PerformanceRouter
- **Endpoint**: `GET /performance`
- **Purpose**: Performance monitoring and statistics
- **Implementation**: `scripts/http_api/performance_router.gd`
- **Features**:
  - Cache statistics
  - Security metrics
  - Memory usage (static, dynamic)
  - Engine stats (FPS, process time, object counts)
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Depends on CacheManager (NOT in autoload)
  - Uses optimized security config
- **Prerequisites**:
  1. Add CacheManager to autoload in project.godot:
     ```gdscript
     CacheManager="*res://scripts/http_api/cache_manager.gd"
     ```
  2. Register router in http_api_server.gd `_register_routers()`:
     ```gdscript
     var performance_router = load("res://scripts/http_api/performance_router.gd").new()
     server.register_router(performance_router)
     ```
  3. Test performance metrics endpoint
- **Status**: ⚠️ **DISABLED** (needs autoload + registration)

### 2.5 AuthRouter
- **Endpoint**: `/auth/*`
- **Purpose**: Token lifecycle management
- **Implementation**: `scripts/http_api/auth_router.gd`
- **Features**:
  - POST /auth/rotate - Rotate to new token
  - POST /auth/refresh - Refresh token expiry
  - POST /auth/revoke - Revoke token
  - GET /auth/status - Check token status
  - GET /auth/metrics - Token usage metrics
  - GET /auth/audit - Audit log
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Uses RefCounted pattern (not HttpRouter)
  - Depends on TokenManager (NOT in autoload)
- **Prerequisites**:
  1. Add TokenManager to autoload in project.godot:
     ```gdscript
     TokenManager="*res://scripts/http_api/token_manager.gd"
     ```
  2. Convert AuthRouter to HttpRouter pattern
  3. Register router in http_api_server.gd `_register_routers()`:
     ```gdscript
     var auth_router = load("res://scripts/http_api/auth_router.gd").new()
     server.register_router(auth_router)
     ```
  4. Test token rotation and refresh
- **Status**: ⚠️ **DISABLED** (needs autoload + conversion + registration)

### 2.6 BatchOperationsRouter
- **Endpoint**: `POST /batch`
- **Purpose**: Execute multiple scene operations in one request
- **Implementation**: `scripts/http_api/batch_operations_router.gd`
- **Features**:
  - Batch scene loading, validation, info retrieval
  - Two modes: transactional (rollback on failure) or continue (keep going)
  - Rate limiting (max 50 operations, 10 requests/minute)
  - Webhook integration for events
  - Progress tracking
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Depends on WebhookManager for event notifications
- **Prerequisites**:
  1. Add WebhookManager to autoload (see WebhookRouter prerequisites)
  2. Register router in http_api_server.gd `_register_routers()`:
     ```gdscript
     var batch_router = load("res://scripts/http_api/batch_operations_router.gd").new()
     server.register_router(batch_router)
     ```
  3. Test batch operations in both modes
- **Status**: ⚠️ **DISABLED** (needs WebhookManager autoload + registration)

### 2.7 WebhookDetailRouter
- **Endpoint**: `/webhooks/{id}`
- **Purpose**: Individual webhook management
- **Implementation**: `scripts/http_api/webhook_detail_router.gd`
- **Features**:
  - GET /webhooks/{id} - Get webhook details
  - PUT /webhooks/{id} - Update webhook
  - DELETE /webhooks/{id} - Delete webhook
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Depends on WebhookManager autoload
- **Prerequisites**:
  - Same as WebhookRouter (requires WebhookManager autoload)
- **Status**: ⚠️ **DISABLED** (needs autoload + registration)

### 2.8 JobDetailRouter
- **Endpoint**: `/jobs/{id}`
- **Purpose**: Individual job status and cancellation
- **Implementation**: `scripts/http_api/job_detail_router.gd`
- **Features**:
  - GET /jobs/{id} - Get job status
  - DELETE /jobs/{id} - Cancel job
- **Why Disabled**:
  - Not registered in `_register_routers()`
  - Depends on JobQueue autoload
- **Prerequisites**:
  - Same as JobRouter (requires JobQueue autoload)
- **Status**: ⚠️ **DISABLED** (needs autoload + registration)

---

## 3. Prerequisites Summary

### 3.1 Missing Autoloads

The following autoloads need to be added to `project.godot` to enable disabled routers:

```gdscript
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"

# NEW AUTOLOADS FOR ROUTERS:
WebhookManager="*res://scripts/http_api/webhook_manager.gd"
JobQueue="*res://scripts/http_api/job_queue.gd"
TokenManager="*res://scripts/http_api/token_manager.gd"
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

### 3.2 Router Pattern Conversion

Some routers need conversion from RefCounted to HttpRouter pattern:

**Affected Routers:**
- AdminRouter (RefCounted → HttpRouter)
- AuthRouter (RefCounted → HttpRouter)

**Conversion Steps:**
1. Change class declaration:
   ```gdscript
   # OLD:
   extends RefCounted
   class_name AdminRouter

   # NEW:
   extends "res://addons/godottpd/http_router.gd"
   class_name AdminRouter
   ```

2. Update `_init()` to use super() with route and handlers:
   ```gdscript
   func _init():
       var handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
           # Implementation here
           return true

       super("/admin", {'get': handler, 'post': handler})
   ```

3. Convert `route_request()` logic to handler functions

### 3.3 Testing Requirements

Before enabling routers in production:

1. **Unit Testing**:
   - Test each router's endpoints independently
   - Verify authentication and rate limiting
   - Test error handling (400, 401, 403, 404, 500)

2. **Integration Testing**:
   - Test router interaction with autoloads
   - Verify webhook delivery and retry logic
   - Test job queue processing
   - Verify token rotation and refresh

3. **Load Testing**:
   - Test batch operations with max payload size
   - Verify rate limiting enforcement
   - Test concurrent job processing

4. **Security Testing**:
   - Verify authentication on all endpoints
   - Test IP validation in X-Forwarded-For headers
   - Verify HMAC signature validation for webhooks
   - Test token revocation and expiry

---

## 4. Security Considerations

### 4.1 Authentication Bug (CRITICAL)

**Issue**: Many routers use `SecurityConfig.validate_auth(request)` which has been identified as having validation issues.

**Affected Routers**: All routers using `validate_auth()` - 19 files total:
- webhook_router.gd
- batch_operations_router.gd
- job_router.gd
- scene_router.gd
- scenes_list_router.gd
- scene_history_router.gd
- scene_reload_router.gd
- performance_router.gd
- And 11 more files...

**Current Code Pattern** (potentially buggy):
```gdscript
# Auth check
if not SecurityConfig.validate_auth(request):
    response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
    return true
```

**Proper Fix Pattern**:

1. **Check what validate_auth actually returns** in `security_config.gd`
2. **Verify token format**: Bearer token should be in `Authorization` header
3. **Add explicit logging** for failed auth attempts:
   ```gdscript
   # Auth check with logging
   var auth_result = SecurityConfig.validate_auth(request)
   if not auth_result:
       print("[Router] AUTH FAILED: ", request.headers.get("Authorization", "NO AUTH HEADER"))
       response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
       return true
   ```

4. **Validate SecurityConfig implementation**:
   - Check if `validate_auth()` properly extracts Bearer token
   - Verify token comparison is secure (constant-time comparison)
   - Ensure token storage is not empty

### 4.2 IP Validation

**Current Implementation** (SceneRouter):
- Validates X-Forwarded-For header format
- Only trusts localhost proxies
- Validates IPv4 and IPv6 formats
- Logs invalid IP attempts

**Best Practice**: This pattern should be standardized across all routers.

### 4.3 Rate Limiting

**Current Status**:
- Rate limiting is implemented in SecurityConfig
- All active routers check rate limits per client IP
- Batch operations have additional limits (50 ops max, 10 req/min)

**Recommendation**: Add rate limiting metrics to PerformanceRouter when enabled.

---

## 5. Activation Guide

### 5.1 Quick Start: Enable Webhooks

**Scenario**: You want to receive notifications when scenes are loaded.

**Steps**:

1. **Add WebhookManager autoload**:
   ```bash
   # Edit project.godot, add line after VoxelPerformanceMonitor:
   WebhookManager="*res://scripts/http_api/webhook_manager.gd"
   ```

2. **Register WebhookRouter**:
   ```gdscript
   # Edit scripts/http_api/http_api_server.gd
   # In _register_routers() function, add after scenes_list_router:

   # Webhook router
   var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
   server.register_router(webhook_router)
   print("[HttpApiServer] Registered /webhooks router")
   ```

3. **Restart Godot**:
   ```bash
   python godot_editor_server.py --port 8090 --auto-load-scene
   ```

4. **Test webhook registration**:
   ```bash
   # Get token from server output
   TOKEN="<your-token-here>"

   # Register a webhook
   curl -X POST http://localhost:8080/webhooks \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "url": "https://webhook.site/your-unique-id",
       "events": ["scene.loaded", "scene.failed"],
       "secret": "your-webhook-secret"
     }'
   ```

5. **Verify webhook delivery**:
   - Load a scene via API
   - Check webhook.site for received payload
   - Verify HMAC signature in headers

### 5.2 Enable Job Queue

**Scenario**: You want to batch-load multiple scenes in the background.

**Steps**:

1. **Add JobQueue autoload**:
   ```bash
   # Edit project.godot, add line:
   JobQueue="*res://scripts/http_api/job_queue.gd"
   ```

2. **Register JobRouter**:
   ```gdscript
   # Edit scripts/http_api/http_api_server.gd
   # In _register_routers() function:

   # Job queue router
   var job_router = load("res://scripts/http_api/job_router.gd").new()
   server.register_router(job_router)
   print("[HttpApiServer] Registered /jobs router")

   # Job detail router (for status checking)
   var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
   server.register_router(job_detail_router)
   print("[HttpApiServer] Registered /jobs/{id} router")
   ```

3. **Restart Godot**

4. **Test job submission**:
   ```bash
   TOKEN="<your-token-here>"

   # Submit a scene preload job
   curl -X POST http://localhost:8080/jobs \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "scene_preload",
       "parameters": {
         "scene_paths": [
           "res://vr_main.tscn",
           "res://minimal_test.tscn"
         ]
       }
     }'

   # Response: {"success": true, "job_id": "1", "status": "queued"}
   ```

5. **Check job status**:
   ```bash
   # Get job status
   curl -X GET http://localhost:8080/jobs/1 \
     -H "Authorization: Bearer $TOKEN"
   ```

### 5.3 Enable Performance Monitoring

**Scenario**: You want to monitor cache hit rates and system performance.

**Steps**:

1. **Add CacheManager autoload**:
   ```bash
   # Edit project.godot, add line:
   CacheManager="*res://scripts/http_api/cache_manager.gd"
   ```

2. **Register PerformanceRouter**:
   ```gdscript
   # Edit scripts/http_api/http_api_server.gd
   # In _register_routers() function:

   # Performance monitoring router
   var performance_router = load("res://scripts/http_api/performance_router.gd").new()
   server.register_router(performance_router)
   print("[HttpApiServer] Registered /performance router")
   ```

3. **Restart Godot**

4. **Test performance endpoint**:
   ```bash
   TOKEN="<your-token-here>"

   # Get performance metrics
   curl -X GET http://localhost:8080/performance \
     -H "Authorization: Bearer $TOKEN"
   ```

5. **Response includes**:
   - Cache statistics (hit rate, size, evictions)
   - Security metrics (auth attempts, rate limits)
   - Memory usage (static, dynamic)
   - Engine stats (FPS, process time, object counts)

### 5.4 Enable Admin Endpoints

**Scenario**: You want full administrative control and monitoring.

**Note**: AdminRouter requires pattern conversion first.

**Steps**:

1. **Convert AdminRouter to HttpRouter**:
   ```gdscript
   # Edit scripts/http_api/admin_router.gd
   # Change line 1 from:
   extends RefCounted
   # To:
   extends "res://addons/godottpd/http_router.gd"

   # Refactor _init() and handle() methods to use HttpRouter pattern
   # (See section 3.2 for conversion details)
   ```

2. **Register AdminRouter**:
   ```gdscript
   # Edit scripts/http_api/http_api_server.gd
   # In _register_routers() function:

   # Admin router (requires admin token)
   var admin_router = load("res://scripts/http_api/admin_router.gd").new()
   server.register_router(admin_router)
   print("[HttpApiServer] Registered /admin router")
   ```

3. **Restart Godot** and note the admin token in output

4. **Test admin endpoints**:
   ```bash
   ADMIN_TOKEN="<admin-token-from-output>"

   # Get system metrics
   curl -X GET http://localhost:8080/admin/metrics \
     -H "X-Admin-Token: $ADMIN_TOKEN"

   # View audit log
   curl -X GET http://localhost:8080/admin/audit \
     -H "X-Admin-Token: $ADMIN_TOKEN"

   # Clear cache
   curl -X POST http://localhost:8080/admin/cache/clear \
     -H "X-Admin-Token: $ADMIN_TOKEN"
   ```

### 5.5 Enable All Advanced Features

**Scenario**: Enable all disabled routers for full API functionality.

**Prerequisites Checklist**:
- [ ] Add all missing autoloads to project.godot
- [ ] Convert AdminRouter and AuthRouter to HttpRouter pattern
- [ ] Fix authentication validation bugs
- [ ] Write tests for each router
- [ ] Update security documentation

**Complete Registration Code**:
```gdscript
# Edit scripts/http_api/http_api_server.gd
# Replace _register_routers() function with:

func _register_routers():
    """Register all HTTP routers for different endpoints"""

    # Register specific routes BEFORE generic routes (godottpd uses prefix matching)

    # Scene history router (/scene/history must come before /scene)
    var scene_history_router = load("res://scripts/http_api/scene_history_router.gd").new()
    server.register_router(scene_history_router)
    print("[HttpApiServer] Registered /scene/history router")

    # Scene reload router (/scene/reload must come before /scene)
    var scene_reload_router = load("res://scripts/http_api/scene_reload_router.gd").new()
    server.register_router(scene_reload_router)
    print("[HttpApiServer] Registered /scene/reload router")

    # Scene management router (generic /scene route)
    var scene_router = load("res://scripts/http_api/scene_router.gd").new()
    server.register_router(scene_router)
    print("[HttpApiServer] Registered /scene router")

    # Scenes list router
    var scenes_list_router = load("res://scripts/http_api/scenes_list_router.gd").new()
    server.register_router(scenes_list_router)
    print("[HttpApiServer] Registered /scenes router")

    # === NEW ROUTERS (ADVANCED FEATURES) ===

    # Webhook management
    var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
    server.register_router(webhook_router)
    print("[HttpApiServer] Registered /webhooks router")

    var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
    server.register_router(webhook_detail_router)
    print("[HttpApiServer] Registered /webhooks/{id} router")

    # Job queue
    var job_router = load("res://scripts/http_api/job_router.gd").new()
    server.register_router(job_router)
    print("[HttpApiServer] Registered /jobs router")

    var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
    server.register_router(job_detail_router)
    print("[HttpApiServer] Registered /jobs/{id} router")

    # Performance monitoring
    var performance_router = load("res://scripts/http_api/performance_router.gd").new()
    server.register_router(performance_router)
    print("[HttpApiServer] Registered /performance router")

    # Batch operations
    var batch_router = load("res://scripts/http_api/batch_operations_router.gd").new()
    server.register_router(batch_router)
    print("[HttpApiServer] Registered /batch router")

    # Admin endpoints (REQUIRES CONVERSION TO HttpRouter FIRST)
    var admin_router = load("res://scripts/http_api/admin_router.gd").new()
    server.register_router(admin_router)
    print("[HttpApiServer] Registered /admin router")

    # Authentication (REQUIRES CONVERSION TO HttpRouter FIRST)
    var auth_router = load("res://scripts/http_api/auth_router.gd").new()
    server.register_router(auth_router)
    print("[HttpApiServer] Registered /auth router")
```

---

## 6. Testing Procedures

### 6.1 Router Testing Checklist

For each newly enabled router:

- [ ] **Authentication Testing**:
  - [ ] Valid token accepted
  - [ ] Invalid token rejected (401)
  - [ ] Missing token rejected (401)
  - [ ] Expired token rejected (401)

- [ ] **Rate Limiting Testing**:
  - [ ] Normal requests succeed
  - [ ] Excessive requests return 429
  - [ ] Rate limit resets after time window

- [ ] **Error Handling Testing**:
  - [ ] Invalid JSON returns 400
  - [ ] Missing required fields return 400
  - [ ] Invalid parameters return 400
  - [ ] Missing resources return 404
  - [ ] Server errors return 500

- [ ] **Functionality Testing**:
  - [ ] Happy path works as documented
  - [ ] Edge cases handled gracefully
  - [ ] Error messages are clear
  - [ ] Response format matches documentation

### 6.2 Integration Testing

After enabling multiple routers:

- [ ] **Webhook + Scene Router**:
  - [ ] Webhooks triggered on scene.loaded
  - [ ] Webhooks triggered on scene.failed
  - [ ] Retry logic works correctly
  - [ ] HMAC signatures validate correctly

- [ ] **Job Queue + Batch Operations**:
  - [ ] Jobs submitted successfully
  - [ ] Jobs process in background
  - [ ] Job status updates correctly
  - [ ] Batch operations execute via job queue

- [ ] **Admin + All Routers**:
  - [ ] Admin can view all metrics
  - [ ] Audit log captures all operations
  - [ ] Admin can clear cache
  - [ ] Security events are logged

### 6.3 Performance Testing

- [ ] **Load Testing**:
  - [ ] 100 concurrent requests handled
  - [ ] Rate limiting prevents overload
  - [ ] Cache reduces database queries

- [ ] **Memory Testing**:
  - [ ] No memory leaks after 1000 requests
  - [ ] Cache eviction works correctly
  - [ ] Job queue cleans up old jobs

### 6.4 Security Testing

- [ ] **Authentication Bypass Attempts**:
  - [ ] Cannot bypass with malformed headers
  - [ ] Cannot bypass with header injection
  - [ ] Token rotation works correctly

- [ ] **Injection Attacks**:
  - [ ] SQL injection not possible (no SQL used)
  - [ ] Path traversal blocked by whitelist
  - [ ] JSON injection handled by parser

- [ ] **Rate Limit Bypass**:
  - [ ] Cannot bypass with IP spoofing
  - [ ] X-Forwarded-For validation works
  - [ ] Distributed requests still rate limited

---

## 7. Router Dependencies Matrix

| Router | Depends On | Status |
|--------|------------|--------|
| SceneHistoryRouter | SecurityConfig | ✅ Active |
| SceneReloadRouter | SecurityConfig | ✅ Active |
| SceneRouter | SecurityConfig | ✅ Active |
| ScenesListRouter | SecurityConfig | ✅ Active |
| WebhookRouter | WebhookManager (autoload) | ⚠️ Needs autoload |
| WebhookDetailRouter | WebhookManager (autoload) | ⚠️ Needs autoload |
| JobRouter | JobQueue (autoload) | ⚠️ Needs autoload |
| JobDetailRouter | JobQueue (autoload) | ⚠️ Needs autoload |
| PerformanceRouter | CacheManager (autoload) | ⚠️ Needs autoload |
| BatchOperationsRouter | WebhookManager (autoload) | ⚠️ Needs autoload |
| AdminRouter | None (self-contained) | ⚠️ Needs conversion |
| AuthRouter | TokenManager (autoload) | ⚠️ Needs autoload + conversion |

---

## 8. Troubleshooting

### Issue: Router not responding after registration

**Symptoms**: 404 Not Found for newly registered endpoint

**Causes**:
1. Router not properly registered in `_register_routers()`
2. Route path conflict (more specific routes must come first)
3. Godot not restarted after code changes
4. Autoload dependency missing

**Solutions**:
1. Verify registration code and print statement
2. Check route order (specific before generic)
3. Restart Godot editor
4. Check console for autoload errors

### Issue: 500 Internal Server Error

**Symptoms**: Router registered but returns 500

**Causes**:
1. Autoload dependency missing
2. Method called on null object
3. Type mismatch in parameters

**Solutions**:
1. Check console for null object errors
2. Verify autoload exists: `/root/WebhookManager` etc.
3. Add null checks before accessing autoloads:
   ```gdscript
   var manager = tree.root.get_node_or_null("/root/WebhookManager")
   if not manager:
       response.send(500, JSON.stringify({
           "error": "Internal Server Error",
           "message": "WebhookManager not available"
       }))
       return true
   ```

### Issue: Authentication always fails

**Symptoms**: All requests return 401 even with correct token

**Causes**:
1. Token not generated (SecurityConfig issue)
2. Wrong authorization header format
3. Token comparison bug in validate_auth()

**Solutions**:
1. Check server startup output for token
2. Use exact format: `Authorization: Bearer <token>`
3. Add debug logging to SecurityConfig.validate_auth():
   ```gdscript
   print("[SecurityConfig] Validating token: ", extracted_token)
   print("[SecurityConfig] Expected token: ", get_token())
   ```

### Issue: Rate limiting not working

**Symptoms**: Can send unlimited requests without 429 response

**Causes**:
1. Client IP extraction returns same value for all
2. Rate limit window too long
3. Rate limit not checked in router

**Solutions**:
1. Verify X-Forwarded-For header is set
2. Check SecurityConfig rate limit configuration
3. Ensure router calls `SecurityConfig.check_rate_limit()`

---

## 9. Future Enhancements

### 9.1 Planned Features

- **Router Hot-Reload**: Reload routers without restarting Godot
- **Dynamic Router Registration**: Add/remove routers via API
- **Router Middleware**: Shared middleware for auth, logging, etc.
- **OpenAPI Documentation**: Auto-generate API docs from routers
- **Router Metrics**: Per-router performance tracking

### 9.2 Security Improvements

- **JWT Token Support**: Replace simple tokens with JWT
- **Role-Based Access Control**: Different permissions per endpoint
- **API Key Management**: Support multiple API keys
- **Request Signing**: HMAC signature for all requests
- **Audit Logging**: Comprehensive audit trail for all operations

### 9.3 Performance Optimizations

- **Response Caching**: Cache GET responses with ETags
- **Compression**: GZIP compression for large responses
- **Connection Pooling**: Reuse HTTP connections
- **Async Processing**: Non-blocking request handling

---

## 10. References

### Documentation Files
- `CLAUDE.md` - Project overview and architecture
- `DEVELOPMENT_WORKFLOW.md` - Development workflow guide
- `project.godot` - Autoload configuration

### Implementation Files
- `scripts/http_api/http_api_server.gd` - Main HTTP server
- `scripts/http_api/security_config.gd` - Authentication and rate limiting
- `scripts/http_api/webhook_manager.gd` - Webhook delivery system
- `scripts/http_api/job_queue.gd` - Background job processing
- `scripts/http_api/token_manager.gd` - Token lifecycle management
- `scripts/http_api/cache_manager.gd` - Multi-level caching

### Testing Files
- `tests/health_monitor.py` - System health checks
- `tests/test_runner.py` - Automated test suite

### External Documentation
- [godottpd Documentation](https://github.com/you-win/godottpd) - HTTP server library
- [Godot HTTPRequest](https://docs.godotengine.org/en/stable/classes/class_httprequest.html) - HTTP client
- [Godot Autoload](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) - Singleton pattern

---

## Appendix A: Complete Router List

| # | Router Name | Endpoint | Status | File |
|---|-------------|----------|--------|------|
| 1 | SceneHistoryRouter | GET /scene/history | ✅ Active | scene_history_router.gd |
| 2 | SceneReloadRouter | POST /scene/reload | ✅ Active | scene_reload_router.gd |
| 3 | SceneRouter | POST/GET/PUT /scene | ✅ Active | scene_router.gd |
| 4 | ScenesListRouter | GET /scenes | ✅ Active | scenes_list_router.gd |
| 5 | WebhookRouter | POST/GET /webhooks | ⚠️ Disabled | webhook_router.gd |
| 6 | WebhookDetailRouter | GET/PUT/DELETE /webhooks/{id} | ⚠️ Disabled | webhook_detail_router.gd |
| 7 | JobRouter | POST/GET /jobs | ⚠️ Disabled | job_router.gd |
| 8 | JobDetailRouter | GET/DELETE /jobs/{id} | ⚠️ Disabled | job_detail_router.gd |
| 9 | PerformanceRouter | GET /performance | ⚠️ Disabled | performance_router.gd |
| 10 | BatchOperationsRouter | POST /batch | ⚠️ Disabled | batch_operations_router.gd |
| 11 | AdminRouter | /admin/* | ⚠️ Disabled | admin_router.gd |
| 12 | AuthRouter | /auth/* | ⚠️ Disabled | auth_router.gd |

---

## Appendix B: Autoload Configuration Template

Complete autoload configuration for enabling all routers:

```ini
[autoload]

# Core systems (EXISTING)
ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"

# HTTP API advanced features (NEW - ADD THESE)
WebhookManager="*res://scripts/http_api/webhook_manager.gd"
JobQueue="*res://scripts/http_api/job_queue.gd"
TokenManager="*res://scripts/http_api/token_manager.gd"
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

---

**End of Document**

For questions or issues, see troubleshooting section or consult the CLAUDE.md project overview.
