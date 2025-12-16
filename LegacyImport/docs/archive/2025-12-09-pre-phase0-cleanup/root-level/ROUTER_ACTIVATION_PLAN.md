# HTTP API Router Activation Plan

**Document Version**: 1.0
**Last Updated**: 2025-12-04
**Status**: Actionable Implementation Guide
**Target Completion**: Phased rollout over 4 phases

---

## Executive Summary

This document provides a **prioritized, phased activation plan** for enabling 8 disabled HTTP API routers in the SpaceTime project. Currently, only 4 of 12 routers are active. This plan identifies quick wins, sequences dependencies, and provides step-by-step instructions with time estimates.

**Current State:**
- ✅ **4 Active Routers**: Scene management endpoints operational
- ⚠️ **8 Disabled Routers**: Advanced features (webhooks, jobs, admin, auth) not available
- 🔒 **Security Issue**: Authentication validation bug affects ALL routers (19 files)

**Plan Overview:**
- **Phase 1 (Quick Wins)**: Enable performance monitoring (1-2 hours)
- **Phase 2 (Medium Effort)**: Enable webhooks and jobs (3-4 hours)
- **Phase 3 (Complex)**: Enable batch operations (2-3 hours)
- **Phase 4 (Future)**: Enable admin and auth systems (6-8 hours)

**Total Estimated Effort**: 12-17 hours of development time

---

## Table of Contents

1. [Priority Analysis](#priority-analysis)
2. [Security Fix (CRITICAL)](#security-fix-critical)
3. [Phase 1: Quick Wins](#phase-1-quick-wins)
4. [Phase 2: Medium Effort](#phase-2-medium-effort)
5. [Phase 3: Complex Features](#phase-3-complex-features)
6. [Phase 4: Future Enhancements](#phase-4-future-enhancements)
7. [Testing Strategy](#testing-strategy)
8. [Rollback Procedures](#rollback-procedures)
9. [Resource Requirements](#resource-requirements)
10. [Success Metrics](#success-metrics)

---

## Priority Analysis

### Value vs. Effort Matrix

| Router | Value | Effort | Dependencies | Priority | Phase |
|--------|-------|--------|--------------|----------|-------|
| **PerformanceRouter** | High | Low | CacheManager | **P0 - Critical** | 1 |
| **WebhookRouter** | High | Medium | WebhookManager | **P1 - High** | 2 |
| **JobRouter** | High | Medium | JobQueue | **P1 - High** | 2 |
| **BatchOperationsRouter** | Medium | Medium | WebhookManager | **P2 - Medium** | 3 |
| **WebhookDetailRouter** | Medium | Low | WebhookManager | **P2 - Medium** | 2 |
| **JobDetailRouter** | Medium | Low | JobQueue | **P2 - Medium** | 2 |
| **AdminRouter** | High | High | Conversion needed | **P3 - Low** | 4 |
| **AuthRouter** | High | High | TokenManager + Conversion | **P3 - Low** | 4 |

### Justification

**Priority 0 (Critical):**
- **PerformanceRouter**: Essential for production monitoring, minimal dependencies, quick activation

**Priority 1 (High):**
- **WebhookRouter**: Enables event-driven architecture, critical for external integrations
- **JobRouter**: Background processing essential for scalability and user experience

**Priority 2 (Medium):**
- **BatchOperationsRouter**: Nice-to-have for bulk operations, depends on webhooks
- **Detail Routers**: Complement main routers, low effort once dependencies are active

**Priority 3 (Low):**
- **AdminRouter/AuthRouter**: High value but complex refactoring needed, can wait

---

## Security Fix (CRITICAL)

### Authentication Validation Bug

**CVSS Score**: Not actually a bug - `SecurityConfig.validate_auth()` is **correctly implemented** (lines 177-276)

**Status**: ✅ **NO BUG FOUND** - Validation is comprehensive and secure

**Current Implementation Analysis:**
```gdscript
# security_config.gd lines 177-276
static func validate_auth(headers: Variant) -> bool:
    # ✅ Strict null checks
    # ✅ Type validation (Dictionary or Object with headers property)
    # ✅ Bearer token extraction with format validation
    # ✅ Token length validation (minimum 16 characters)
    # ✅ JWT support with expiry checking
    # ✅ Token manager support with rotation
    # ✅ Constant-time comparison for legacy tokens
```

**Security Features:**
- Null safety at every step
- Type confusion prevention
- Bearer format enforcement
- Minimum token length (16 chars)
- JWT expiry validation
- Token manager integration
- Extensive debug logging

**Recommendation**:
- ⚠️ **No fix needed** - the authentication system is **already secure**
- 📋 Keep using current `validate_auth()` pattern in all routers
- 🔍 Monitor logs for authentication failures to detect attacks

**Action Items:**
- [ ] Document authentication pattern as best practice
- [ ] Add unit tests for edge cases (null, empty, malformed tokens)
- [ ] No code changes required

---

## Phase 1: Quick Wins (1-2 hours)

### Objective
Enable performance monitoring with minimal risk and maximum operational visibility.

### Target Routers
1. **PerformanceRouter** (GET /performance)

### Prerequisites
- ✅ SecurityConfig already active
- ⚠️ CacheManager needs to be added as autoload

### Step-by-Step Activation

#### Step 1.1: Add CacheManager Autoload
**Estimated Time**: 15 minutes

**File**: `C:/godot/project.godot`

```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"

# Phase 1: Performance monitoring
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

**Verification:**
```bash
# Check autoload exists
grep "CacheManager" C:/godot/project.godot
```

**Expected Output:**
```
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

#### Step 1.2: Verify CacheManager Implementation
**Estimated Time**: 10 minutes

```bash
# Check if file exists
ls C:/godot/scripts/http_api/cache_manager.gd
```

**If file doesn't exist**, create minimal implementation:
```gdscript
# File: scripts/http_api/cache_manager.gd
extends Node
class_name HttpApiCacheManager

var _cache: Dictionary = {}
var _cache_stats: Dictionary = {
    "hits": 0,
    "misses": 0,
    "evictions": 0,
    "size": 0
}

func _ready():
    print("[CacheManager] Initialized HTTP API cache")

func get_stats() -> Dictionary:
    return _cache_stats.duplicate()

func clear_cache() -> void:
    _cache.clear()
    _cache_stats.evictions += _cache_stats.size
    _cache_stats.size = 0
    print("[CacheManager] Cache cleared")
```

#### Step 1.3: Register PerformanceRouter
**Estimated Time**: 10 minutes

**File**: `C:/godot/scripts/http_api/http_api_server.gd`

Find the `_register_routers()` function (around line 180) and add:

```gdscript
func _register_routers():
    # ... existing routers ...

    # Scenes list router
    var scenes_list_router = load("res://scripts/http_api/scenes_list_router.gd").new()
    server.register_router(scenes_list_router)
    print("[HttpApiServer] Registered /scenes router")

    # === PHASE 1: PERFORMANCE MONITORING ===

    # Performance monitoring router
    var performance_router = load("res://scripts/http_api/performance_router.gd").new()
    server.register_router(performance_router)
    print("[HttpApiServer] Registered /performance router")
```

#### Step 1.4: Restart Godot and Test
**Estimated Time**: 15 minutes

```bash
# Start Godot via Python server
python godot_editor_server.py --port 8090 --auto-load-scene
```

Wait for:
```
[HttpApiServer] Registered /performance router
[CacheManager] Initialized HTTP API cache
```

**Test the endpoint:**
```bash
# Get API token from server output
TOKEN="<your-token-from-output>"

# Test performance endpoint
curl -X GET http://localhost:8080/performance \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "cache": {
    "hits": 0,
    "misses": 0,
    "evictions": 0,
    "size": 0,
    "hit_rate": 0.0
  },
  "security": {
    "auth_checks": 1,
    "rate_limits_triggered": 0
  },
  "memory": {
    "static": 50123456,
    "dynamic": 12345678
  },
  "engine": {
    "fps": 60,
    "frame_time_ms": 16.67,
    "process_time_ms": 5.23,
    "physics_time_ms": 2.11,
    "objects": 234
  }
}
```

#### Step 1.5: Acceptance Criteria
- [ ] CacheManager autoload appears in Godot editor (Project → Project Settings → Autoload)
- [ ] No errors in Godot console on startup
- [ ] GET /performance returns 200 with valid JSON
- [ ] Performance metrics update in real-time
- [ ] Authentication is enforced (401 without token)
- [ ] Rate limiting works (429 after excessive requests)

#### Step 1.6: Rollback Plan
If issues occur:
1. Comment out CacheManager autoload line in project.godot
2. Comment out performance_router registration in http_api_server.gd
3. Restart Godot
4. Verify existing routers still work

**Time Required**: 5 minutes

---

## Phase 2: Medium Effort (3-4 hours)

### Objective
Enable webhooks and background job processing for event-driven architecture.

### Target Routers
1. **WebhookRouter** (POST /webhooks, GET /webhooks)
2. **WebhookDetailRouter** (GET/PUT/DELETE /webhooks/{id})
3. **JobRouter** (POST /jobs, GET /jobs)
4. **JobDetailRouter** (GET/DELETE /jobs/{id})

### Prerequisites
- ✅ Phase 1 completed successfully
- ⚠️ WebhookManager needs to be added as autoload
- ⚠️ JobQueue needs to be added as autoload

### Step-by-Step Activation

#### Step 2.1: Add WebhookManager and JobQueue Autoloads
**Estimated Time**: 20 minutes

**File**: `C:/godot/project.godot`

```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"

# Phase 1: Performance monitoring
CacheManager="*res://scripts/http_api/cache_manager.gd"

# Phase 2: Webhooks and job queue
WebhookManager="*res://scripts/http_api/webhook_manager.gd"
JobQueue="*res://scripts/http_api/job_queue.gd"
```

**Verification:**
```bash
# Verify files exist
ls C:/godot/scripts/http_api/webhook_manager.gd
ls C:/godot/scripts/http_api/job_queue.gd

# Verify autoload configuration
grep -E "(WebhookManager|JobQueue)" C:/godot/project.godot
```

#### Step 2.2: Test Autoload Dependencies
**Estimated Time**: 30 minutes

Create test script to verify autoloads work:

**File**: `C:/godot/test_autoloads.gd`
```gdscript
extends Node

func _ready():
    # Test WebhookManager
    var webhook_mgr = get_node_or_null("/root/WebhookManager")
    if webhook_mgr:
        print("[Test] ✓ WebhookManager loaded successfully")
        var result = webhook_mgr.register_webhook(
            "https://webhook.site/test",
            ["scene.loaded"],
            "test_secret"
        )
        print("[Test] Webhook registration: ", result)
    else:
        print("[Test] ✗ WebhookManager NOT loaded")

    # Test JobQueue
    var job_queue = get_node_or_null("/root/JobQueue")
    if job_queue:
        print("[Test] ✓ JobQueue loaded successfully")
        var job = job_queue.submit_job(
            job_queue.JobType.CACHE_WARMING,
            {}
        )
        print("[Test] Job submission: ", job)
    else:
        print("[Test] ✗ JobQueue NOT loaded")

    # Exit after tests
    get_tree().create_timer(2.0).timeout.connect(func():
        print("[Test] Tests complete")
        get_tree().quit()
    )
```

**Run test:**
```bash
godot --path C:/godot --headless --script test_autoloads.gd
```

**Expected Output:**
```
[WebhookManager] Initialized webhook system
[JobQueue] Initialized job queue system
[Test] ✓ WebhookManager loaded successfully
[Test] Webhook registration: {success:true, webhook_id:1, webhook:{...}}
[Test] ✓ JobQueue loaded successfully
[Test] Job submission: {success:true, job_id:1, status:queued}
[Test] Tests complete
```

#### Step 2.3: Register Webhook Routers
**Estimated Time**: 20 minutes

**File**: `C:/godot/scripts/http_api/http_api_server.gd`

```gdscript
func _register_routers():
    # ... existing routers ...

    # === PHASE 2: WEBHOOKS ===

    # Webhook management (must come BEFORE webhook detail router)
    var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
    server.register_router(webhook_router)
    print("[HttpApiServer] Registered /webhooks router")

    # Webhook detail management (specific /webhooks/{id} routes)
    var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
    server.register_router(webhook_detail_router)
    print("[HttpApiServer] Registered /webhooks/{id} router")
```

**Important**: Router order matters! Register specific routes (`/webhooks/{id}`) BEFORE generic routes (`/webhooks`).

#### Step 2.4: Register Job Queue Routers
**Estimated Time**: 20 minutes

**File**: `C:/godot/scripts/http_api/http_api_server.gd`

```gdscript
func _register_routers():
    # ... existing routers ...

    # === PHASE 2: JOB QUEUE ===

    # Job queue management
    var job_router = load("res://scripts/http_api/job_router.gd").new()
    server.register_router(job_router)
    print("[HttpApiServer] Registered /jobs router")

    # Job detail management (specific /jobs/{id} routes)
    var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
    server.register_router(job_detail_router)
    print("[HttpApiServer] Registered /jobs/{id} router")
```

#### Step 2.5: Restart and Test Webhooks
**Estimated Time**: 30 minutes

**Start Godot:**
```bash
python godot_editor_server.py --port 8090 --auto-load-scene
```

**Test webhook registration:**
```bash
TOKEN="<your-token-from-output>"

# Register a webhook
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://webhook.site/your-unique-id",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "my_webhook_secret_123"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "webhook_id": "1",
  "webhook": {
    "id": "1",
    "url": "https://webhook.site/your-unique-id",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "***",
    "enabled": true,
    "created_at": 1733356800,
    "delivery_count": 0,
    "failure_count": 0
  }
}
```

**Test webhook listing:**
```bash
curl -X GET http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN"
```

**Trigger a webhook event:**
```bash
# Load a scene (should trigger webhook)
curl -X POST http://localhost:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://minimal_test.tscn"}'

# Check webhook.site for delivery
```

#### Step 2.6: Test Job Queue
**Estimated Time**: 30 minutes

**Submit a scene preload job:**
```bash
TOKEN="<your-token-from-output>"

# Submit job
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
```

**Expected Response:**
```json
{
  "success": true,
  "job_id": "1",
  "status": "queued"
}
```

**Check job status:**
```bash
# Poll job status
curl -X GET http://localhost:8080/jobs/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response (completed):**
```json
{
  "success": true,
  "job": {
    "id": "1",
    "type": "scene_preload",
    "status": "completed",
    "progress": 1.0,
    "created_at": 1733356800,
    "started_at": 1733356801,
    "completed_at": 1733356803,
    "result": {
      "scenes_loaded": 2,
      "total_scenes": 2,
      "scenes": [...]
    },
    "error": null
  }
}
```

**Test job cancellation:**
```bash
# Submit a long job
curl -X POST http://localhost:8080/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "cache_warming", "parameters": {}}'

# Cancel immediately
curl -X DELETE http://localhost:8080/jobs/2 \
  -H "Authorization: Bearer $TOKEN"
```

#### Step 2.7: Acceptance Criteria
- [ ] WebhookManager and JobQueue appear in autoloads
- [ ] No errors on Godot startup
- [ ] POST /webhooks creates webhook successfully
- [ ] GET /webhooks lists all webhooks
- [ ] Webhook events are delivered with HMAC signatures
- [ ] POST /jobs submits job successfully
- [ ] GET /jobs lists jobs with status filter
- [ ] Jobs process in background (max 3 concurrent)
- [ ] Job cancellation works for queued jobs
- [ ] Webhook retry logic works (test with invalid URL)

#### Step 2.8: Rollback Plan
If issues occur:
1. Comment out WebhookManager and JobQueue autoload lines
2. Comment out webhook and job router registrations
3. Restart Godot
4. Verify Phase 1 routers still work

**Time Required**: 10 minutes

---

## Phase 3: Complex Features (2-3 hours)

### Objective
Enable batch operations for multi-scene management.

### Target Routers
1. **BatchOperationsRouter** (POST /batch)

### Prerequisites
- ✅ Phase 2 completed successfully
- ✅ WebhookManager already active (for event notifications)

### Step-by-Step Activation

#### Step 3.1: Register Batch Operations Router
**Estimated Time**: 15 minutes

**File**: `C:/godot/scripts/http_api/http_api_server.gd`

```gdscript
func _register_routers():
    # ... existing routers ...

    # === PHASE 3: BATCH OPERATIONS ===

    # Batch operations router
    var batch_router = load("res://scripts/http_api/batch_operations_router.gd").new()
    server.register_router(batch_router)
    print("[HttpApiServer] Registered /batch router")
```

#### Step 3.2: Test Batch Operations - Continue Mode
**Estimated Time**: 30 minutes

**Test Case**: Batch load multiple scenes, continue on failure

```bash
TOKEN="<your-token-from-output>"

# Submit batch operation
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "continue",
    "operations": [
      {
        "action": "load",
        "scene_path": "res://vr_main.tscn"
      },
      {
        "action": "load",
        "scene_path": "res://minimal_test.tscn"
      },
      {
        "action": "load",
        "scene_path": "res://nonexistent.tscn"
      },
      {
        "action": "validate",
        "scene_path": "res://vr_main.tscn"
      }
    ]
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Batch operation completed",
  "total": 4,
  "succeeded": 3,
  "failed": 1,
  "results": [
    {"success": true, "scene_path": "res://vr_main.tscn"},
    {"success": true, "scene_path": "res://minimal_test.tscn"},
    {"success": false, "scene_path": "res://nonexistent.tscn", "error": "Scene not found"},
    {"success": true, "scene_path": "res://vr_main.tscn"}
  ]
}
```

#### Step 3.3: Test Batch Operations - Transactional Mode
**Estimated Time**: 30 minutes

**Test Case**: Batch operations with rollback on any failure

```bash
# This should fail and rollback
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "transactional",
    "operations": [
      {
        "action": "load",
        "scene_path": "res://vr_main.tscn"
      },
      {
        "action": "load",
        "scene_path": "res://nonexistent.tscn"
      }
    ]
  }'
```

**Expected Response:**
```json
{
  "success": false,
  "error": "Batch operation failed",
  "message": "Operation failed, rolling back",
  "failed_operation": {
    "action": "load",
    "scene_path": "res://nonexistent.tscn"
  },
  "rollback": "completed"
}
```

#### Step 3.4: Test Rate Limiting
**Estimated Time**: 20 minutes

**Test Case**: Exceed batch operation limits

```bash
# Test max operations limit (50 operations max)
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "continue",
    "operations": [
      ... (generate 51 operations)
    ]
  }'
```

**Expected Response:**
```json
{
  "success": false,
  "error": "Bad Request",
  "message": "Too many operations (max 50)"
}
```

**Test requests per minute limit:**
```bash
# Send 11 batch requests rapidly (limit is 10/min)
for i in {1..11}; do
  curl -X POST http://localhost:8080/batch \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"mode":"continue","operations":[{"action":"validate","scene_path":"res://vr_main.tscn"}]}'
  sleep 0.1
done
```

**Expected**: 11th request returns 429 Too Many Requests

#### Step 3.5: Test Webhook Integration
**Estimated Time**: 30 minutes

**Setup webhook for batch events:**
```bash
# Register webhook for batch events
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://webhook.site/your-unique-id",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "batch_webhook_secret"
  }'
```

**Run batch operation:**
```bash
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "continue",
    "operations": [
      {"action": "load", "scene_path": "res://vr_main.tscn"},
      {"action": "load", "scene_path": "res://minimal_test.tscn"}
    ]
  }'
```

**Verify on webhook.site:**
- 2 webhook deliveries (one per scene.loaded event)
- Each has X-Webhook-Signature header
- Payload contains scene_path and operation details

#### Step 3.6: Acceptance Criteria
- [ ] POST /batch processes operations successfully
- [ ] Continue mode executes all operations even if some fail
- [ ] Transactional mode rolls back on any failure
- [ ] Rate limiting enforces max 50 operations per request
- [ ] Rate limiting enforces 10 requests per minute
- [ ] Webhooks are triggered for batch operations
- [ ] Batch operation results are detailed and accurate
- [ ] Progress tracking works for long batches

#### Step 3.7: Rollback Plan
If issues occur:
1. Comment out batch_router registration in http_api_server.gd
2. Restart Godot
3. Verify Phase 2 routers still work

**Time Required**: 5 minutes

---

## Phase 4: Future Enhancements (6-8 hours)

### Objective
Enable advanced admin and authentication systems (requires significant refactoring).

### Target Routers
1. **AdminRouter** (/admin/*)
2. **AuthRouter** (/auth/*)

### Prerequisites
- ✅ Phases 1-3 completed successfully
- ⚠️ AdminRouter needs conversion from RefCounted to HttpRouter
- ⚠️ AuthRouter needs conversion from RefCounted to HttpRouter
- ⚠️ TokenManager needs to be added as autoload

### Why Phase 4 is Complex

**Current Issues:**
1. **Pattern Mismatch**: AdminRouter and AuthRouter extend `RefCounted` instead of `HttpRouter`
2. **Missing Autoload**: TokenManager not yet added to project
3. **Refactoring Required**: Need to rewrite route handling logic
4. **Testing Complexity**: Admin endpoints need comprehensive security testing

**Estimated Complexity:**
- AdminRouter conversion: 3-4 hours
- AuthRouter conversion: 2-3 hours
- TokenManager integration: 1 hour
- Testing and validation: 2 hours

### Step-by-Step Activation (Summary)

#### Step 4.1: Add TokenManager Autoload
**Estimated Time**: 30 minutes

**Create TokenManager if it doesn't exist:**
```gdscript
# File: scripts/http_api/token_manager.gd
extends Node
class_name HttpApiTokenManager

var _tokens: Dictionary = {}
var _next_token_id: int = 1

func _ready():
    print("[TokenManager] Initialized token lifecycle management")
    _generate_initial_token()

func _generate_initial_token() -> String:
    # Generate secure token
    var bytes = PackedByteArray()
    for i in range(32):
        bytes.append(randi() % 256)

    var token_secret = bytes.hex_encode()
    var token_id = str(_next_token_id)
    _next_token_id += 1

    var token = {
        "token_id": token_id,
        "token_secret": token_secret,
        "created_at": Time.get_unix_time_from_system(),
        "expires_at": Time.get_unix_time_from_system() + 86400,  # 24 hours
        "active": true
    }

    _tokens[token_id] = token
    print("[TokenManager] Initial token: ", token_secret)
    return token_secret

func validate_token(token_secret: String) -> Dictionary:
    for token_id in _tokens.keys():
        var token = _tokens[token_id]
        if token.token_secret == token_secret and token.active:
            if Time.get_unix_time_from_system() < token.expires_at:
                return {"valid": true, "token_id": token_id}
            else:
                return {"valid": false, "error": "Token expired"}
    return {"valid": false, "error": "Invalid token"}

func get_active_tokens() -> Array:
    var active = []
    for token_id in _tokens.keys():
        var token = _tokens[token_id]
        if token.active and Time.get_unix_time_from_system() < token.expires_at:
            active.append(token)
    return active

func rotate_token(old_token_secret: String, new_token_secret: String = "") -> Dictionary:
    # Token rotation logic
    var validation = validate_token(old_token_secret)
    if not validation.valid:
        return {"success": false, "error": "Invalid old token"}

    # Invalidate old token
    var old_token_id = validation.token_id
    _tokens[old_token_id].active = false

    # Generate new token
    if new_token_secret.is_empty():
        return {"success": false, "error": "New token not provided"}

    var new_token_id = str(_next_token_id)
    _next_token_id += 1

    var token = {
        "token_id": new_token_id,
        "token_secret": new_token_secret,
        "created_at": Time.get_unix_time_from_system(),
        "expires_at": Time.get_unix_time_from_system() + 86400,
        "active": true
    }

    _tokens[new_token_id] = token
    print("[TokenManager] Token rotated: ", old_token_id, " → ", new_token_id)

    return {"success": true, "token_id": new_token_id, "token_secret": new_token_secret}
```

**Add to project.godot:**
```ini
[autoload]
# ... existing autoloads ...

# Phase 4: Advanced auth
TokenManager="*res://scripts/http_api/token_manager.gd"
```

#### Step 4.2: Convert AdminRouter to HttpRouter Pattern
**Estimated Time**: 3-4 hours

**Current Pattern (RefCounted):**
```gdscript
# OLD: admin_router.gd
extends RefCounted

func route_request(request, response):
    if request.path.begins_with("/admin/metrics"):
        return _handle_metrics(request, response)
    # ... more routing logic
```

**New Pattern (HttpRouter):**
```gdscript
# NEW: admin_router.gd
extends "res://addons/godottpd/http_router.gd"
class_name AdminRouter

func _init():
    # Define routes and handlers
    super("/admin", {
        'get': _handle_admin_get,
        'post': _handle_admin_post,
        'delete': _handle_admin_delete
    })

func _handle_admin_get(request: HttpRequest, response: GodottpdResponse) -> bool:
    # Extract subpath
    var subpath = request.path.replace("/admin", "")

    match subpath:
        "/metrics":
            return _handle_metrics(request, response)
        "/audit":
            return _handle_audit(request, response)
        "/health":
            return _handle_health(request, response)
        _:
            response.send(404, JSON.stringify({
                "error": "Not Found",
                "message": "Admin endpoint not found"
            }))
            return true

func _handle_metrics(request: HttpRequest, response: GodottpdResponse) -> bool:
    # Admin token validation
    if not _validate_admin_token(request):
        response.send(401, JSON.stringify({
            "error": "Unauthorized",
            "message": "Invalid admin token"
        }))
        return true

    # Return metrics
    var metrics = {
        "uptime_seconds": (Time.get_ticks_msec() - _start_time) / 1000.0,
        "request_count": _request_count,
        "success_count": _success_count,
        "error_count": _error_count
    }

    response.send(200, JSON.stringify(metrics))
    return true

func _validate_admin_token(request: HttpRequest) -> bool:
    var admin_token = request.headers.get("X-Admin-Token", "")
    return admin_token == AdminRouter.get_admin_token()
```

**Complexity**: This requires rewriting all route handling logic. Each admin endpoint needs individual handler functions.

#### Step 4.3: Convert AuthRouter to HttpRouter Pattern
**Estimated Time**: 2-3 hours

Similar conversion as AdminRouter, but also needs TokenManager integration.

#### Step 4.4: Register Admin and Auth Routers
**Estimated Time**: 30 minutes

**File**: `C:/godot/scripts/http_api/http_api_server.gd`

```gdscript
func _register_routers():
    # ... existing routers ...

    # === PHASE 4: ADMIN AND AUTH ===

    # Admin router (requires admin token)
    var admin_router = load("res://scripts/http_api/admin_router.gd").new()
    server.register_router(admin_router)
    print("[HttpApiServer] Registered /admin router")

    # Auth router (token lifecycle management)
    var auth_router = load("res://scripts/http_api/auth_router.gd").new()
    server.register_router(auth_router)
    print("[HttpApiServer] Registered /auth router")
```

#### Step 4.5: Test Admin Endpoints
**Estimated Time**: 1 hour

```bash
# Get admin token from console output
ADMIN_TOKEN="<admin-token-from-output>"

# Test metrics
curl -X GET http://localhost:8080/admin/metrics \
  -H "X-Admin-Token: $ADMIN_TOKEN"

# Test audit log
curl -X GET http://localhost:8080/admin/audit \
  -H "X-Admin-Token: $ADMIN_TOKEN"

# Test cache clear
curl -X POST http://localhost:8080/admin/cache/clear \
  -H "X-Admin-Token: $ADMIN_TOKEN"
```

#### Step 4.6: Test Auth Endpoints
**Estimated Time**: 1 hour

```bash
TOKEN="<current-api-token>"

# Check token status
curl -X GET http://localhost:8080/auth/status \
  -H "Authorization: Bearer $TOKEN"

# Rotate token
curl -X POST http://localhost:8080/auth/rotate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "new_token": "new_secure_token_here_32_chars_min"
  }'

# Test with new token
NEW_TOKEN="new_secure_token_here_32_chars_min"
curl -X GET http://localhost:8080/status \
  -H "Authorization: Bearer $NEW_TOKEN"

# Old token should fail
curl -X GET http://localhost:8080/status \
  -H "Authorization: Bearer $TOKEN"
# Expected: 401 Unauthorized
```

#### Step 4.7: Acceptance Criteria
- [ ] TokenManager autoload works correctly
- [ ] AdminRouter converted to HttpRouter pattern
- [ ] AuthRouter converted to HttpRouter pattern
- [ ] Admin endpoints require separate admin token
- [ ] Token rotation works without breaking active sessions
- [ ] Token refresh extends expiry time
- [ ] Token revocation immediately invalidates token
- [ ] Audit logging captures all admin operations

#### Step 4.8: Rollback Plan
If issues occur:
1. Comment out TokenManager autoload
2. Comment out admin and auth router registrations
3. Restart Godot
4. Verify Phase 3 routers still work

**Time Required**: 10 minutes

### Recommendation: Defer Phase 4

**Rationale:**
- High complexity (6-8 hours) vs. medium immediate value
- Requires significant code refactoring
- SecurityConfig already provides adequate authentication
- Admin operations can be done via Godot console/editor
- Token rotation is a "nice-to-have" not "must-have"

**Alternative:**
- Focus on Phases 1-3 first (total 6-9 hours)
- Evaluate if admin/auth features are truly needed
- Schedule Phase 4 for future sprint if demand exists

---

## Testing Strategy

### Unit Testing

**Create test suite**: `C:/godot/tests/http_api/test_routers.gd`

```gdscript
extends GdUnitTestSuite

var http_client: HTTPRequest
var base_url: String = "http://127.0.0.1:8080"
var token: String = ""

func before():
    # Get API token from SecurityConfig
    token = SecurityConfig.get_token()
    print("[Test] Using token: ", token)

func test_performance_router_requires_auth():
    # Test without token
    var response = await _make_request("GET", "/performance", "", {})
    assert_int(response.code).is_equal(401)

func test_performance_router_returns_metrics():
    # Test with valid token
    var headers = {"Authorization": "Bearer " + token}
    var response = await _make_request("GET", "/performance", "", headers)
    assert_int(response.code).is_equal(200)
    assert_object(response.body).is_not_null()
    assert_bool(response.body.has("cache")).is_true()
    assert_bool(response.body.has("engine")).is_true()

func test_webhook_registration():
    var headers = {"Authorization": "Bearer " + token}
    var payload = {
        "url": "https://webhook.site/test",
        "events": ["scene.loaded"],
        "secret": "test_secret"
    }
    var response = await _make_request("POST", "/webhooks", JSON.stringify(payload), headers)
    assert_int(response.code).is_equal(200)
    assert_bool(response.body.success).is_true()
    assert_str(response.body.webhook_id).is_not_empty()

func test_job_submission():
    var headers = {"Authorization": "Bearer " + token}
    var payload = {
        "type": "cache_warming",
        "parameters": {}
    }
    var response = await _make_request("POST", "/jobs", JSON.stringify(payload), headers)
    assert_int(response.code).is_equal(200)
    assert_bool(response.body.success).is_true()
    assert_str(response.body.job_id).is_not_empty()

func test_batch_operations_rate_limit():
    var headers = {"Authorization": "Bearer " + token}
    var payload = {
        "mode": "continue",
        "operations": _generate_operations(51)  # Exceeds max of 50
    }
    var response = await _make_request("POST", "/batch", JSON.stringify(payload), headers)
    assert_int(response.code).is_equal(400)
    assert_str(response.body.error).contains("Too many operations")

func _make_request(method: String, path: String, body: String, headers: Dictionary):
    # Helper function to make HTTP requests
    # Implementation details...
    pass

func _generate_operations(count: int) -> Array:
    var ops = []
    for i in range(count):
        ops.append({"action": "validate", "scene_path": "res://vr_main.tscn"})
    return ops
```

**Run tests:**
```bash
# Start Godot with all routers enabled
python godot_editor_server.py --port 8090 --auto-load-scene

# In another terminal, run tests
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/http_api/
```

### Integration Testing

**Test webhook delivery flow:**
```bash
# 1. Register webhook
# 2. Load scene
# 3. Verify webhook received
# 4. Validate HMAC signature
```

**Test job queue flow:**
```bash
# 1. Submit job
# 2. Check status (queued → running → completed)
# 3. Verify result
# 4. Cleanup old jobs
```

**Test batch operations with webhooks:**
```bash
# 1. Register webhook for scene events
# 2. Submit batch operation
# 3. Verify webhook deliveries for each operation
# 4. Check delivery history
```

### Load Testing

**Use Apache Bench or similar:**
```bash
# Test rate limiting
ab -n 1000 -c 10 -H "Authorization: Bearer $TOKEN" \
   http://localhost:8080/performance

# Test concurrent job submissions
ab -n 100 -c 5 -p job_payload.json -T application/json \
   -H "Authorization: Bearer $TOKEN" \
   http://localhost:8080/jobs
```

**Monitor Godot console for:**
- Memory usage (should stay stable)
- No errors or warnings
- Rate limiting triggers correctly
- Job queue processes efficiently

### Security Testing

**Authentication bypass attempts:**
```bash
# No token
curl -X GET http://localhost:8080/performance
# Expected: 401

# Invalid token
curl -X GET http://localhost:8080/performance \
  -H "Authorization: Bearer invalid_token"
# Expected: 401

# Malformed header
curl -X GET http://localhost:8080/performance \
  -H "Authorization: invalid_format"
# Expected: 401
```

**Rate limit bypass attempts:**
```bash
# Rapid requests from single IP
for i in {1..200}; do
  curl -X GET http://localhost:8080/performance \
    -H "Authorization: Bearer $TOKEN" &
done
wait
# Expected: 429 Too Many Requests after hitting limit
```

**HMAC signature validation:**
```bash
# Capture webhook payload and signature
# Recompute HMAC locally
# Verify signatures match
```

---

## Rollback Procedures

### Quick Rollback (Emergency)

If production system becomes unstable:

```bash
# 1. Stop Godot
pkill -f "Godot"

# 2. Revert to last known good configuration
git checkout project.godot
git checkout scripts/http_api/http_api_server.gd

# 3. Restart Godot
python godot_editor_server.py --port 8090 --auto-load-scene

# 4. Verify core functionality
curl http://localhost:8080/status
```

**Time Required**: 2 minutes

### Selective Rollback (Per Phase)

**Rollback Phase 3 (Batch Operations):**
```gdscript
# Comment out in http_api_server.gd:
# var batch_router = load("res://scripts/http_api/batch_operations_router.gd").new()
# server.register_router(batch_router)
```

**Rollback Phase 2 (Webhooks + Jobs):**
```ini
# Comment out in project.godot:
# WebhookManager="*res://scripts/http_api/webhook_manager.gd"
# JobQueue="*res://scripts/http_api/job_queue.gd"
```

```gdscript
# Comment out router registrations in http_api_server.gd
```

**Rollback Phase 1 (Performance):**
```ini
# Comment out in project.godot:
# CacheManager="*res://scripts/http_api/cache_manager.gd"
```

```gdscript
# Comment out router registration in http_api_server.gd
```

### Validation After Rollback

```bash
# 1. Check autoloads loaded
curl http://localhost:8080/status

# 2. Test active routers
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/scenes

# 3. Check Godot console for errors
# Look for: "[HttpApiServer] Registered X routers"

# 4. Run health monitor
python tests/health_monitor.py
```

---

## Resource Requirements

### Developer Skills

**Required:**
- ✅ GDScript proficiency (intermediate level)
- ✅ HTTP API concepts (REST, status codes, headers)
- ✅ JSON parsing and formatting
- ✅ Basic authentication concepts

**Nice to Have:**
- Webhook delivery and retry logic
- Background job processing patterns
- HMAC signature generation
- Rate limiting algorithms

### Development Tools

**Required:**
- ✅ Godot Engine 4.5+ installed
- ✅ Python 3.8+ for server scripts
- ✅ curl or Postman for API testing
- ✅ Text editor (VS Code, Sublime, etc.)

**Nice to Have:**
- webhook.site for webhook testing
- Apache Bench for load testing
- Wireshark for network debugging
- GdUnit4 for automated testing

### Testing Resources

**Hardware:**
- Minimum: 8GB RAM, 4-core CPU
- Recommended: 16GB RAM, 8-core CPU (for load testing)

**Network:**
- Localhost testing sufficient for Phases 1-3
- External webhook URLs needed for Phase 2 testing

**Time:**
- Phase 1: 1-2 hours (one developer)
- Phase 2: 3-4 hours (one developer)
- Phase 3: 2-3 hours (one developer)
- Phase 4: 6-8 hours (one developer)
- **Total**: 12-17 hours of focused development

### Documentation Updates

**Files to Update:**
- [ ] `CLAUDE.md` - Update API endpoints list
- [ ] `HTTP_API_ROUTER_STATUS.md` - Mark routers as active
- [ ] `README.md` (if exists) - Add new API examples
- [ ] API documentation (OpenAPI/Swagger if exists)

**Estimated Time**: 1-2 hours

---

## Success Metrics

### Phase 1 Success Criteria

**Functional:**
- [ ] GET /performance returns 200 with valid metrics
- [ ] Cache statistics update in real-time
- [ ] Memory usage reported accurately
- [ ] Engine stats (FPS, process time) are correct

**Non-Functional:**
- [ ] Response time < 50ms for /performance
- [ ] No memory leaks after 1000 requests
- [ ] No errors in Godot console

### Phase 2 Success Criteria

**Functional:**
- [ ] Webhooks registered successfully
- [ ] Webhook events delivered with <5s latency
- [ ] HMAC signatures validated correctly
- [ ] Retry logic works (3 attempts with exponential backoff)
- [ ] Jobs queued and processed in background
- [ ] Max 3 concurrent jobs enforced
- [ ] Job status updates in real-time

**Non-Functional:**
- [ ] Webhook delivery success rate > 95%
- [ ] Job processing throughput > 10 jobs/minute
- [ ] No blocking on main thread

### Phase 3 Success Criteria

**Functional:**
- [ ] Batch operations execute all actions
- [ ] Continue mode handles failures gracefully
- [ ] Transactional mode rolls back on failure
- [ ] Rate limiting enforced (50 ops max, 10 req/min)
- [ ] Webhook events triggered for batch operations

**Non-Functional:**
- [ ] Batch processing time < 100ms per operation
- [ ] Memory usage stable during large batches
- [ ] No API server crashes under load

### Phase 4 Success Criteria

**Functional:**
- [ ] Admin endpoints require separate token
- [ ] Token rotation works without disruption
- [ ] Token refresh extends expiry
- [ ] Token revocation takes effect immediately
- [ ] Audit logging captures all operations

**Non-Functional:**
- [ ] Token validation time < 10ms
- [ ] Audit log doesn't impact performance
- [ ] Token storage is secure (not logged)

### Overall Project Success

**Adoption Metrics:**
- External integrations using webhooks: > 3
- API requests per day: > 1000
- Uptime: > 99.5%
- Error rate: < 1%

**Developer Experience:**
- API documentation complete
- Example code available for all endpoints
- Support requests < 5 per week

---

## Automated Activation Script

To simplify activation, create: `C:/godot/activate_routers.sh`

```bash
#!/bin/bash

# Router Activation Script
# Automates router activation based on phase

set -e  # Exit on error

PHASE=$1
if [ -z "$PHASE" ]; then
    echo "Usage: ./activate_routers.sh <phase>"
    echo "Phases: 1, 2, 3, 4"
    exit 1
fi

PROJECT_ROOT="C:/godot"
PROJECT_GODOT="$PROJECT_ROOT/project.godot"
HTTP_SERVER="$PROJECT_ROOT/scripts/http_api/http_api_server.gd"

echo "===== Activating Phase $PHASE Routers ====="

case $PHASE in
    1)
        echo "Phase 1: Enabling Performance Router"

        # Add CacheManager autoload
        if ! grep -q "CacheManager=" "$PROJECT_GODOT"; then
            echo "Adding CacheManager autoload..."
            sed -i '/VoxelPerformanceMonitor=/a CacheManager="*res://scripts/http_api/cache_manager.gd"' "$PROJECT_GODOT"
        fi

        # Register PerformanceRouter
        echo "Registering PerformanceRouter..."
        # (Add sed command to insert router registration)

        echo "✓ Phase 1 activation complete"
        ;;

    2)
        echo "Phase 2: Enabling Webhook and Job Queue Routers"

        # Add autoloads
        if ! grep -q "WebhookManager=" "$PROJECT_GODOT"; then
            echo "Adding WebhookManager autoload..."
            sed -i '/CacheManager=/a WebhookManager="*res://scripts/http_api/webhook_manager.gd"' "$PROJECT_GODOT"
        fi

        if ! grep -q "JobQueue=" "$PROJECT_GODOT"; then
            echo "Adding JobQueue autoload..."
            sed -i '/WebhookManager=/a JobQueue="*res://scripts/http_api/job_queue.gd"' "$PROJECT_GODOT"
        fi

        echo "✓ Phase 2 activation complete"
        ;;

    3)
        echo "Phase 3: Enabling Batch Operations Router"
        echo "✓ Phase 3 activation complete (no autoloads needed)"
        ;;

    4)
        echo "Phase 4: Enabling Admin and Auth Routers"

        # Add TokenManager autoload
        if ! grep -q "TokenManager=" "$PROJECT_GODOT"; then
            echo "Adding TokenManager autoload..."
            sed -i '/JobQueue=/a TokenManager="*res://scripts/http_api/token_manager.gd"' "$PROJECT_GODOT"
        fi

        echo "⚠️  WARNING: Phase 4 requires manual router conversion"
        echo "Please convert AdminRouter and AuthRouter to HttpRouter pattern"
        echo "See ROUTER_ACTIVATION_PLAN.md Phase 4 for details"
        ;;

    *)
        echo "Error: Invalid phase '$PHASE'"
        echo "Valid phases: 1, 2, 3, 4"
        exit 1
        ;;
esac

echo ""
echo "Next steps:"
echo "1. Restart Godot: python godot_editor_server.py --port 8090 --auto-load-scene"
echo "2. Check console output for router registration messages"
echo "3. Run tests: see ROUTER_ACTIVATION_PLAN.md Phase $PHASE testing section"
```

**Usage:**
```bash
# Activate Phase 1
./activate_routers.sh 1

# Activate Phase 2
./activate_routers.sh 2
```

---

## Conclusion

This activation plan provides a **structured, phased approach** to enabling all disabled HTTP API routers. By prioritizing quick wins (Phase 1), building on dependencies (Phase 2-3), and deferring complex refactoring (Phase 4), the plan minimizes risk while maximizing value delivery.

**Recommended Execution Order:**
1. **Start with Phase 1** (1-2 hours) - Get immediate operational visibility
2. **Proceed to Phase 2** (3-4 hours) - Enable event-driven architecture
3. **Add Phase 3** (2-3 hours) - Complete batch operations support
4. **Defer Phase 4** (6-8 hours) - Evaluate if admin/auth features are needed

**Total Time to Production-Ready API**: 6-9 hours (Phases 1-3)

**Key Success Factors:**
- ✅ Test each phase independently before moving forward
- ✅ Use rollback procedures if issues arise
- ✅ Monitor Godot console for errors during activation
- ✅ Document any deviations from the plan
- ✅ Update HTTP_API_ROUTER_STATUS.md after each phase

**Questions or Issues?**
- See HTTP_API_ROUTER_STATUS.md Section 8 (Troubleshooting)
- Check Godot console output for detailed error messages
- Consult CLAUDE.md for project architecture overview

---

**Document End**
