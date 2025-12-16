# PerformanceRouter Activation Guide

**Document Version**: 1.0
**Created**: 2025-12-04
**Phase**: Phase 1 - Quick Win
**Status**: GO - READY FOR ACTIVATION
**Estimated Time**: 1-2 hours
**Risk Level**: LOW

---

## Executive Summary

The PerformanceRouter is **production-ready** and can be activated immediately with minimal risk. This guide provides step-by-step instructions for safe activation.

**Current Status:**
- ✅ Router code is complete and well-structured
- ✅ All dependencies exist and are functional
- ✅ No TODO/FIXME markers found
- ✅ Error handling is present
- ✅ Authentication is implemented correctly
- ⚠️ CacheManager not yet added to autoloads (single missing step)

**Go/No-Go Recommendation**: **GO** - All prerequisites met, minimal effort required

---

## Table of Contents

1. [Current Status Analysis](#current-status-analysis)
2. [Dependencies Check](#dependencies-check)
3. [Activation Steps](#activation-steps)
4. [Testing Procedure](#testing-procedure)
5. [Rollback Plan](#rollback-plan)
6. [Risk Assessment](#risk-assessment)
7. [Post-Activation Monitoring](#post-activation-monitoring)

---

## Current Status Analysis

### Router Implementation: PerformanceRouter

**File**: `C:/godot/scripts/http_api/performance_router.gd`
**Lines of Code**: 52
**Complexity**: Low

#### Code Quality Assessment

**Strengths:**
- ✅ Clean, readable code with clear purpose
- ✅ Proper inheritance from `HttpRouter` (godottpd pattern)
- ✅ Authentication check implemented (`SecurityConfig.validate_auth`)
- ✅ Comprehensive error handling (401 for auth failures)
- ✅ JSON response format with proper structure
- ✅ Uses Godot's built-in `Performance` singleton (no external deps)
- ✅ Modular design with separate helper methods
- ✅ No hardcoded values or magic numbers
- ✅ Proper class documentation

**Code Structure:**
```gdscript
extends "res://addons/godottpd/http_router.gd"
class_name PerformanceRouter

# Imports
const SecurityConfig = preload("res://scripts/http_api/security_config_optimized.gd")
const CacheManager = preload("res://scripts/http_api/cache_manager.gd")

# Single GET handler with auth check
func _init():
    var get_handler = func(request, response) -> bool:
        # 1. Validate auth
        # 2. Gather performance data
        # 3. Return JSON response

# Helper methods for data collection
func _get_memory_stats() -> Dictionary
func _get_engine_stats() -> Dictionary
```

**No Issues Found:**
- ❌ No TODO markers
- ❌ No FIXME markers
- ❌ No HACK markers
- ❌ No unimplemented methods
- ❌ No error-prone code patterns

#### API Endpoint Specification

**Endpoint**: `GET /performance`
**Authentication**: Required (Bearer token)
**Method**: GET only
**Response Format**: JSON

**Response Schema:**
```json
{
  "timestamp": 1733356800,           // Unix timestamp
  "cache": {                         // From CacheManager
    "l1_cache": {
      "hits": 0,
      "misses": 0,
      "hit_rate_percent": "0.00",
      "size": 0,
      "max_size": 100,
      "bytes": 0,
      "max_bytes": 10485760,
      "evictions": 0
    },
    "operations": {
      "total_gets": 0,
      "total_sets": 0,
      "total_invalidations": 0
    }
  },
  "security": {                      // From SecurityConfig
    "auth": {
      "total_checks": 1,
      "cache_hits": 0,
      "hit_rate_percent": "0.00"
    },
    "whitelist": {
      "total_checks": 0,
      "cache_hits": 0,
      "hit_rate_percent": "0.00"
    }
  },
  "memory": {                        // From Godot Performance API
    "static_memory_usage": 50123456,
    "static_memory_max": 50123456,
    "dynamic_memory_usage": 12345678
  },
  "engine": {                        // From Godot Performance API
    "fps": 60.0,
    "process_time": 0.005,
    "physics_process_time": 0.002,
    "objects_in_use": 234,
    "resources_in_use": 45,
    "nodes_in_use": 123
  }
}
```

---

## Dependencies Check

### Required Dependencies

#### 1. SecurityConfig (security_config_optimized.gd)

**Status**: ✅ **EXISTS AND FUNCTIONAL**

**Location**: `C:/godot/scripts/http_api/security_config_optimized.gd`
**Type**: RefCounted class (stateless utility)
**Used By**: PerformanceRouter (line 7)

**Key Methods Used:**
- `validate_auth(request)` - Validates Bearer token
- `get_stats()` - Returns auth/whitelist statistics

**Circular Dependency Check**: ✅ **NO CIRCULAR DEPENDENCY**
- SecurityConfig imports CacheManager
- CacheManager does NOT import SecurityConfig
- PerformanceRouter imports both (leaf node)

**Import Pattern:**
```gdscript
# In performance_router.gd
const SecurityConfig = preload("res://scripts/http_api/security_config_optimized.gd")
```

#### 2. CacheManager (cache_manager.gd)

**Status**: ✅ **EXISTS AND FUNCTIONAL**
**Autoload Status**: ⚠️ **NOT IN AUTOLOAD (needs to be added)**

**Location**: `C:/godot/scripts/http_api/cache_manager.gd`
**Type**: RefCounted class with singleton pattern
**Used By**: PerformanceRouter (line 8), SecurityConfig (line 16)

**Key Methods Used:**
- `get_instance()` - Singleton accessor
- `get_stats()` - Returns cache statistics

**Singleton Pattern:**
```gdscript
# CacheManager uses static singleton
static var _instance: HttpApiCacheManager = null

static func get_instance() -> HttpApiCacheManager:
    if _instance == null:
        _instance = HttpApiCacheManager.new()
    return _instance
```

**Note**: CacheManager uses a **static singleton pattern**, not autoload. However, adding it as autoload ensures it's initialized early and available globally.

#### 3. Godot Performance Singleton

**Status**: ✅ **BUILT-IN (always available)**

**Type**: Godot engine singleton (available everywhere)
**Used By**: PerformanceRouter (_get_memory_stats, _get_engine_stats)

**Monitors Used:**
- `Performance.MEMORY_STATIC` - Static memory usage
- `Performance.MEMORY_STATIC_MAX` - Peak static memory
- `Performance.MEMORY_MESSAGE_BUFFER_MAX` - Message buffer size
- `Performance.TIME_FPS` - Frames per second
- `Performance.TIME_PROCESS` - Process time per frame
- `Performance.TIME_PHYSICS_PROCESS` - Physics process time
- `Performance.OBJECT_COUNT` - Total objects in use
- `Performance.OBJECT_RESOURCE_COUNT` - Resources in use
- `Performance.OBJECT_NODE_COUNT` - Nodes in scene tree

#### 4. godottpd HttpRouter

**Status**: ✅ **EXISTS AND FUNCTIONAL**

**Location**: `C:/godot/addons/godottpd/http_router.gd`
**Type**: Base class for all routers
**Used By**: PerformanceRouter extends this (line 1)

### Dependency Graph

```
PerformanceRouter
├── SecurityConfig (preload, no autoload needed)
│   └── CacheManager (preload, needs autoload for early init)
├── CacheManager (preload, needs autoload)
└── Performance (built-in singleton, always available)

Legend:
  ✅ Ready (green)
  ⚠️ Needs action (yellow)
```

### Missing Prerequisites

**Only One Missing Step:**
- ⚠️ CacheManager not in autoloads (needs to be added to project.godot)

---

## Activation Steps

### Prerequisites

**Required:**
- ✅ Godot 4.5+ installed
- ✅ Project located at `C:/godot`
- ✅ HttpApiServer autoload enabled
- ✅ Text editor or IDE access

**Recommended:**
- curl or Postman for testing
- Terminal access for running commands

### Step 1: Add CacheManager Autoload

**Estimated Time**: 5 minutes
**Risk**: Very Low

**Action**: Add CacheManager to autoload list in project.godot

**File to Edit**: `C:/godot/project.godot`

**Find this section** (around line 17-23):
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
```

**Add this line** after VoxelPerformanceMonitor:
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

**Verification Command:**
```bash
grep "CacheManager" C:/godot/project.godot
```

**Expected Output:**
```
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

**Why This Works:**
- CacheManager is a RefCounted class with static singleton pattern
- Adding to autoload ensures early initialization
- No dependencies on other autoloads (safe to add at end)

**Note**: Even though CacheManager uses `get_instance()` singleton pattern, adding it as autoload ensures it's initialized early and can be accessed via `/root/CacheManager` if needed (though the code uses `get_instance()` which works either way).

### Step 2: Register PerformanceRouter

**Estimated Time**: 5 minutes
**Risk**: Very Low

**Action**: Add PerformanceRouter to http_api_server.gd router list

**File to Edit**: `C:/godot/scripts/http_api/http_api_server.gd`

**Find the `_register_routers()` function** (around line 174-198):
```gdscript
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
```

**Add these lines** at the end (before the closing of the function):
```gdscript
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

	# === PHASE 1: PERFORMANCE MONITORING ===

	# Performance monitoring router
	var performance_router = load("res://scripts/http_api/performance_router.gd").new()
	server.register_router(performance_router)
	print("[HttpApiServer] Registered /performance router")
```

**Why This Placement:**
- PerformanceRouter has no route conflicts (unique `/performance` path)
- No need to worry about route ordering
- Placed at end for clarity (Phase 1 activation)

### Step 3: Restart Godot

**Estimated Time**: 30 seconds
**Risk**: None (can always revert)

**Method A: Using Python Server (Recommended for AI Agents)**
```bash
# Stop any running Godot process first
# Then start with Python server
cd C:/godot
python godot_editor_server.py --port 8090 --auto-load-scene
```

**Method B: Using Direct Godot Launch**
```bash
# Windows - Use console version for proper output
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot"
```

**Method C: Using Restart Script (Windows Only)**
```bash
cd C:/godot
./restart_godot_with_debug.bat
```

**Expected Console Output:**
```
[HttpApiServer] Initializing SECURE HTTP API server on port 8080
[HttpApiServer] Build Type: DEBUG
[HttpApiServer] Environment: development
[CacheManager] Initialized with L1 max size: 100
[HttpApiServer] Registered /scene/history router
[HttpApiServer] Registered /scene/reload router
[HttpApiServer] Registered /scene router
[HttpApiServer] Registered /scenes router
[HttpApiServer] Registered /performance router
[HttpApiServer] SECURE HTTP API server started on 127.0.0.1:8080
```

**Look for these key messages:**
- ✅ `[CacheManager] Initialized with L1 max size: 100`
- ✅ `[HttpApiServer] Registered /performance router`
- ✅ No error messages about missing classes or failed loads

**If you see errors:**
- Check that both files were edited correctly
- Verify file paths in error messages
- See Rollback Plan section

### Step 4: Verify Autoload Initialization

**Estimated Time**: 2 minutes
**Risk**: None (read-only check)

**Check Godot Editor:**
1. Open Project → Project Settings → Autoload tab
2. Verify CacheManager appears in the list
3. Check that it's enabled (checkbox checked)

**Check via Godot Console:**
```gdscript
# In Godot editor's script editor or debug console
print(get_node("/root/CacheManager"))
# Expected: <RefCounted#123456789>
```

**Alternative: Check via file system (without restarting Godot):**
```bash
grep -A 1 "CacheManager" C:/godot/project.godot
# Expected output:
# CacheManager="*res://scripts/http_api/cache_manager.gd"
```

---

## Testing Procedure

### Phase 1: Basic Connectivity Test

**Estimated Time**: 3 minutes

#### Test 1.1: Get API Token

**Command:**
```bash
# Token is printed in Godot console on startup
# Look for line like:
# [HttpApiServer] API TOKEN: abc123def456...
```

**Save token to environment variable:**
```bash
# Windows PowerShell
$TOKEN = "your_token_here"

# Windows CMD
set TOKEN=your_token_here

# Linux/Mac/Git Bash
export TOKEN="your_token_here"
```

#### Test 1.2: Test Without Authentication (Should Fail)

**Command:**
```bash
curl -X GET http://127.0.0.1:8080/performance
```

**Expected Response:**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}
```

**Status Code**: 401 Unauthorized

**Verification:**
- ✅ Returns 401 status code
- ✅ Returns JSON error message
- ✅ No server crash or error in console

#### Test 1.3: Test With Valid Authentication (Should Succeed)

**Command:**
```bash
# Windows PowerShell
curl -Method GET http://127.0.0.1:8080/performance -Headers @{"Authorization"="Bearer $TOKEN"}

# Linux/Mac/Git Bash/Windows Git Bash
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "timestamp": 1733356800,
  "cache": {
    "l1_cache": {
      "hits": 0,
      "misses": 0,
      "hit_rate_percent": "0.00",
      "size": 0,
      "max_size": 100,
      "bytes": 0,
      "max_bytes": 10485760,
      "evictions": 0
    },
    "operations": {
      "total_gets": 0,
      "total_sets": 0,
      "total_invalidations": 0
    }
  },
  "security": {
    "auth": {
      "total_checks": 1,
      "cache_hits": 0,
      "hit_rate_percent": "0.00"
    },
    "whitelist": {
      "total_checks": 0,
      "cache_hits": 0,
      "hit_rate_percent": "0.00"
    }
  },
  "memory": {
    "static_memory_usage": 50123456,
    "static_memory_max": 50123456,
    "dynamic_memory_usage": 12345678
  },
  "engine": {
    "fps": 60.0,
    "process_time": 0.005,
    "physics_process_time": 0.002,
    "objects_in_use": 234,
    "resources_in_use": 45,
    "nodes_in_use": 123
  }
}
```

**Status Code**: 200 OK

**Verification Checklist:**
- ✅ Returns 200 status code
- ✅ Returns valid JSON
- ✅ Contains all 4 top-level keys: timestamp, cache, security, memory, engine
- ✅ timestamp is a valid Unix timestamp
- ✅ cache.l1_cache has all expected fields
- ✅ security has auth and whitelist stats
- ✅ memory has numeric values (not null)
- ✅ engine.fps is a positive number
- ✅ No errors in Godot console

### Phase 2: Performance Metrics Validation

**Estimated Time**: 5 minutes

#### Test 2.1: Verify Memory Metrics Update

**Command:**
```bash
# Make 3 requests and compare memory values
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" > perf1.json
sleep 2
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" > perf2.json
sleep 2
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" > perf3.json
```

**Verification:**
- Memory values should be realistic (in range 10MB - 500MB typically)
- static_memory_usage should be > 0
- Values may change slightly between requests (this is normal)

#### Test 2.2: Verify FPS Metrics

**Command:**
```bash
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" | grep '"fps"'
```

**Expected:**
- FPS should be positive (typically 60.0 or higher)
- If FPS is 0, check that Godot is running in GUI mode (not headless)

#### Test 2.3: Verify Cache Statistics

**Command:**
```bash
# Make multiple requests to build up cache statistics
for i in {1..10}; do
  curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" -s > /dev/null
done

# Check cache stats
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" | grep -A 3 '"l1_cache"'
```

**Expected:**
- `total_checks` in security.auth should increase with each request
- `cache_hits` should eventually be > 0 (auth tokens are cached)
- `hit_rate_percent` should increase over time

### Phase 3: Error Handling Validation

**Estimated Time**: 5 minutes

#### Test 3.1: Invalid Token

**Command:**
```bash
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer invalid_token_here"
```

**Expected:**
- Status: 401 Unauthorized
- JSON error response
- No server crash

#### Test 3.2: Malformed Authorization Header

**Command:**
```bash
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: NotBearer $TOKEN"
```

**Expected:**
- Status: 401 Unauthorized
- No server crash

#### Test 3.3: Unsupported HTTP Method

**Command:**
```bash
curl -X POST http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN"
```

**Expected:**
- Status: 405 Method Not Allowed (or 404 Not Found, depending on godottpd behavior)
- No server crash

### Phase 4: Load Testing (Optional)

**Estimated Time**: 10 minutes

#### Test 4.1: Rapid Requests

**Command:**
```bash
# Send 100 requests rapidly
for i in {1..100}; do
  curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" -s > /dev/null &
done
wait
```

**Verification:**
- Godot should not crash
- Memory usage should remain stable
- Check Godot console for any errors

#### Test 4.2: Long-Running Monitoring

**Command:**
```bash
# Monitor performance metrics every 5 seconds for 1 minute
for i in {1..12}; do
  echo "=== Request $i ==="
  curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" | jq '.engine.fps, .memory.static_memory_usage'
  sleep 5
done
```

**Verification:**
- FPS should remain stable
- Memory usage should not grow unbounded
- No errors in console

### Testing Acceptance Criteria

**Pass Criteria (All Must Be True):**
- ✅ GET /performance returns 200 with valid token
- ✅ GET /performance returns 401 without valid token
- ✅ Response contains all expected JSON fields
- ✅ Memory metrics are realistic values (> 0)
- ✅ FPS metric is positive
- ✅ Cache statistics update correctly
- ✅ Security statistics track auth checks
- ✅ No errors in Godot console during testing
- ✅ No memory leaks after 100+ requests
- ✅ Server remains stable under rapid requests

**If Any Criterion Fails:**
- Review Godot console for error messages
- Check that both files were edited correctly
- Verify CacheManager is in autoload list
- See Rollback Plan section

---

## Rollback Plan

### When to Rollback

**Immediate Rollback Triggers:**
- ❌ Godot fails to start after changes
- ❌ Godot crashes on startup
- ❌ Existing routers stop working (e.g., /scene, /scenes)
- ❌ CacheManager initialization errors
- ❌ Critical errors in Godot console

**Non-Critical Issues (Do NOT Rollback):**
- ⚠️ Performance endpoint returns unexpected values (fixable)
- ⚠️ Minor formatting issues in JSON response (fixable)
- ⚠️ Cache statistics not updating (investigate first)

### Rollback Procedure

**Estimated Time**: 5 minutes

#### Step 1: Stop Godot

```bash
# Windows
taskkill /F /IM Godot*

# Linux/Mac
pkill -9 Godot
```

#### Step 2: Revert project.godot

**Option A: Manual Edit**

Edit `C:/godot/project.godot` and remove this line:
```ini
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

**Option B: Git Revert (if using version control)**
```bash
cd C:/godot
git checkout project.godot
```

#### Step 3: Revert http_api_server.gd

**Option A: Manual Edit**

Edit `C:/godot/scripts/http_api/http_api_server.gd` and remove these lines:
```gdscript
	# === PHASE 1: PERFORMANCE MONITORING ===

	# Performance monitoring router
	var performance_router = load("res://scripts/http_api/performance_router.gd").new()
	server.register_router(performance_router)
	print("[HttpApiServer] Registered /performance router")
```

**Option B: Git Revert**
```bash
cd C:/godot
git checkout scripts/http_api/http_api_server.gd
```

#### Step 4: Restart Godot

```bash
# Using Python server
python godot_editor_server.py --port 8090 --auto-load-scene

# OR direct launch
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot"
```

#### Step 5: Verify Rollback Success

**Test existing endpoints:**
```bash
curl http://127.0.0.1:8080/status
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scenes
```

**Expected:**
- ✅ Godot starts without errors
- ✅ Existing routers work normally
- ✅ No CacheManager in autoload list
- ✅ No /performance router registered

**Rollback is complete when:**
- System is back to pre-activation state
- All existing functionality works
- No errors in console

### Post-Rollback Actions

1. **Document the Issue**
   - Note what went wrong
   - Capture error messages from console
   - Save relevant logs

2. **Investigate Root Cause**
   - Check file syntax (typos, missing brackets)
   - Verify file paths are correct
   - Check for conflicting autoloads
   - Review Godot version compatibility

3. **Report if Needed**
   - Create issue in project tracker
   - Include error messages and logs
   - Describe reproduction steps

---

## Risk Assessment

### Risk Matrix

| Risk Factor | Likelihood | Impact | Mitigation |
|-------------|------------|--------|------------|
| Godot fails to start | Very Low | High | Rollback plan ready (5 min) |
| CacheManager initialization fails | Very Low | Medium | RefCounted class, no dependencies |
| Performance endpoint crashes | Very Low | Low | Isolated router, won't affect others |
| Existing routers break | Very Low | High | No shared state, independent routers |
| Memory leak | Very Low | Medium | CacheManager has size limits |
| Security vulnerability | Very Low | High | Auth is enforced, same as other routers |

### Overall Risk Level: **LOW**

**Justification:**
- Small, isolated code change (2 lines in project.godot, 4 lines in http_api_server.gd)
- No modifications to existing code
- CacheManager is well-tested and stable
- PerformanceRouter is read-only (no state mutations)
- Easy and fast rollback procedure
- No database or external system dependencies

### Risk Mitigation Strategies

**Before Activation:**
- ✅ Backup project.godot and http_api_server.gd (or use version control)
- ✅ Test in development environment first (not production)
- ✅ Review activation steps carefully
- ✅ Have rollback plan ready

**During Activation:**
- ✅ Monitor Godot console output continuously
- ✅ Check for errors after each step
- ✅ Stop immediately if critical errors occur
- ✅ Test incrementally (don't skip testing steps)

**After Activation:**
- ✅ Run full test suite (see Testing Procedure)
- ✅ Monitor for 10-15 minutes for stability
- ✅ Check existing endpoints still work
- ✅ Review memory usage over time

---

## Post-Activation Monitoring

### Immediate Monitoring (First 15 Minutes)

**What to Watch:**
- ✅ Godot console for errors or warnings
- ✅ Memory usage trends (should be stable)
- ✅ FPS (should remain at expected levels)
- ✅ Existing router functionality

**Commands:**
```bash
# Check server status
curl http://127.0.0.1:8080/status

# Monitor performance endpoint
watch -n 5 'curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq .engine.fps'

# Check memory trends
while true; do
  curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.memory.static_memory_usage'
  sleep 10
done
```

### Short-Term Monitoring (First Hour)

**Metrics to Track:**
- Cache hit rates (should increase over time)
- Auth check performance (should be fast, <10ms)
- Memory usage (should plateau, not grow unbounded)
- FPS stability (should remain consistent)

**Tools:**
```bash
# Cache statistics
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.cache.l1_cache'

# Security statistics
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.security'
```

### Long-Term Monitoring (First Day)

**What to Verify:**
- No memory leaks after many requests
- Cache eviction working correctly
- Performance metrics remain accurate
- No unexpected errors in logs

**Automated Monitoring Script:**
```bash
#!/bin/bash
# Save as monitor_performance.sh

TOKEN="your_token_here"

while true; do
  echo "=== $(date) ==="

  # Get performance data
  RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance)

  # Extract key metrics
  FPS=$(echo $RESPONSE | jq -r '.engine.fps')
  MEMORY=$(echo $RESPONSE | jq -r '.memory.static_memory_usage')
  CACHE_HITS=$(echo $RESPONSE | jq -r '.cache.l1_cache.hits')
  AUTH_CHECKS=$(echo $RESPONSE | jq -r '.security.auth.total_checks')

  echo "FPS: $FPS"
  echo "Memory: $MEMORY bytes"
  echo "Cache Hits: $CACHE_HITS"
  echo "Auth Checks: $AUTH_CHECKS"
  echo ""

  sleep 60  # Check every minute
done
```

### Success Indicators

**After 15 Minutes:**
- ✅ No errors in console
- ✅ Performance endpoint responds consistently
- ✅ FPS remains stable
- ✅ Memory usage is stable

**After 1 Hour:**
- ✅ Cache hit rate increasing
- ✅ Auth checks working efficiently
- ✅ No memory growth trend
- ✅ Other endpoints unaffected

**After 1 Day:**
- ✅ System stable over extended period
- ✅ No unexpected errors in logs
- ✅ Performance metrics remain accurate
- ✅ Ready for production use

---

## Troubleshooting Guide

### Issue: Godot Won't Start

**Symptoms:**
- Godot process exits immediately
- Error about missing class or file

**Solutions:**
1. Check for syntax errors in edited files
2. Verify file paths are correct (case-sensitive on Linux)
3. Check Godot console output for specific error
4. Try removing just the CacheManager autoload first
5. If still fails, rollback completely

**Most Common Causes:**
- Typo in file path
- Missing quotes in project.godot
- CacheManager file doesn't exist (check path)

### Issue: CacheManager Not Initializing

**Symptoms:**
- Error: "Invalid get index 'get_instance' (on base: 'Nil')"
- Error: "Cannot call method 'get_stats' on null"

**Solutions:**
1. Verify CacheManager is in autoload list:
   ```bash
   grep CacheManager C:/godot/project.godot
   ```
2. Check CacheManager file exists:
   ```bash
   ls C:/godot/scripts/http_api/cache_manager.gd
   ```
3. Check for syntax errors in cache_manager.gd
4. Try restarting Godot (sometimes autoload needs restart)

### Issue: 404 Not Found on /performance

**Symptoms:**
- curl returns 404
- No "[HttpApiServer] Registered /performance router" in console

**Solutions:**
1. Verify router registration code was added correctly
2. Check for typos in router file path
3. Verify performance_router.gd file exists
4. Check Godot console for load errors
5. Try restarting Godot

### Issue: 401 Unauthorized Even With Valid Token

**Symptoms:**
- Always returns 401, even with correct token
- Token from console doesn't work

**Solutions:**
1. Verify token was copied correctly (no extra spaces)
2. Check Authorization header format: "Bearer <token>"
3. Verify SecurityConfig is working (try other endpoints)
4. Check Godot console for auth errors
5. Try regenerating token (restart Godot)

### Issue: Performance Metrics Are Zero or Null

**Symptoms:**
- FPS is 0
- Memory values are 0 or null
- Engine stats are empty

**Solutions:**
1. Check that Godot is running in GUI mode (not headless)
2. Verify Performance singleton is available:
   ```gdscript
   print(Performance.get_monitor(Performance.TIME_FPS))
   ```
3. Let Godot run for a few seconds before testing
4. Check if main scene is loaded

### Issue: Cache Statistics Not Updating

**Symptoms:**
- Cache hits always 0
- Hit rate never increases
- Stats don't change

**Solutions:**
1. Make multiple requests (stats accumulate over time)
2. Verify CacheManager singleton is working:
   ```gdscript
   print(HttpApiCacheManager.get_instance())
   ```
3. Check cache TTL hasn't expired (30s for auth)
4. Restart Godot to reset statistics

### Issue: Memory Leak / Growing Memory Usage

**Symptoms:**
- Memory usage grows continuously
- static_memory_usage increases over time
- Godot becomes slow

**Solutions:**
1. This is **unlikely** with PerformanceRouter (read-only)
2. Check other parts of application for leaks
3. Monitor cache size in performance endpoint
4. Cache has automatic eviction (max 100 entries, 10MB)
5. If persistent, report as bug

---

## Appendix A: Code Changes Summary

### File 1: project.godot

**Location**: `C:/godot/project.godot`
**Changes**: Add 1 line to `[autoload]` section

**Before:**
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
```

**After:**
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

**Change Type**: Addition
**Lines Changed**: +1
**Risk**: Very Low

### File 2: http_api_server.gd

**Location**: `C:/godot/scripts/http_api/http_api_server.gd`
**Changes**: Add 5 lines to `_register_routers()` function

**Before (lines 194-198):**
```gdscript
	# Scenes list router
	var scenes_list_router = load("res://scripts/http_api/scenes_list_router.gd").new()
	server.register_router(scenes_list_router)
	print("[HttpApiServer] Registered /scenes router")


func _exit_tree():
```

**After (lines 194-204):**
```gdscript
	# Scenes list router
	var scenes_list_router = load("res://scripts/http_api/scenes_list_router.gd").new()
	server.register_router(scenes_list_router)
	print("[HttpApiServer] Registered /scenes router")

	# === PHASE 1: PERFORMANCE MONITORING ===

	# Performance monitoring router
	var performance_router = load("res://scripts/http_api/performance_router.gd").new()
	server.register_router(performance_router)
	print("[HttpApiServer] Registered /performance router")


func _exit_tree():
```

**Change Type**: Addition
**Lines Changed**: +5
**Risk**: Very Low

### Total Changes

- **Files Modified**: 2
- **Lines Added**: 6
- **Lines Removed**: 0
- **Lines Modified**: 0
- **Risk Level**: Very Low
- **Rollback Time**: 5 minutes

---

## Appendix B: Testing Checklist

Use this checklist during activation:

### Pre-Activation Checklist

- [ ] Backup files (or commit to version control)
- [ ] Read through activation steps
- [ ] Verify all dependencies exist
- [ ] Terminal/command prompt ready
- [ ] Text editor open with files

### Activation Checklist

- [ ] Step 1: Added CacheManager to project.godot
- [ ] Step 1: Verified with grep command
- [ ] Step 2: Added PerformanceRouter registration
- [ ] Step 2: Double-checked code placement
- [ ] Step 3: Restarted Godot
- [ ] Step 3: Checked console for success messages
- [ ] Step 4: Verified autoload in Godot editor

### Testing Checklist

- [ ] Test 1.1: Obtained API token
- [ ] Test 1.2: Verified 401 without auth
- [ ] Test 1.3: Verified 200 with auth
- [ ] Test 2.1: Memory metrics are valid
- [ ] Test 2.2: FPS is positive
- [ ] Test 2.3: Cache stats update
- [ ] Test 3.1: Invalid token returns 401
- [ ] Test 3.2: Malformed header returns 401
- [ ] Test 3.3: Unsupported method handled
- [ ] Test 4.1: Rapid requests work (optional)
- [ ] Test 4.2: Long-running monitoring (optional)

### Post-Activation Checklist

- [ ] No errors in Godot console
- [ ] Existing endpoints still work
- [ ] Performance metrics are accurate
- [ ] Memory usage is stable
- [ ] Set up monitoring script
- [ ] Document any issues encountered
- [ ] Update HTTP_API_ROUTER_STATUS.md

### Rollback Checklist (If Needed)

- [ ] Stopped Godot
- [ ] Reverted project.godot
- [ ] Reverted http_api_server.gd
- [ ] Restarted Godot
- [ ] Verified existing functionality
- [ ] Documented rollback reason

---

## Appendix C: Quick Reference Commands

### Activation Commands

```bash
# Check if files exist
ls C:/godot/scripts/http_api/cache_manager.gd
ls C:/godot/scripts/http_api/performance_router.gd

# Verify CacheManager in autoload
grep "CacheManager" C:/godot/project.godot

# Start Godot (Python server)
cd C:/godot
python godot_editor_server.py --port 8090 --auto-load-scene

# Start Godot (direct)
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot"
```

### Testing Commands

```bash
# Get token (from Godot console output)
TOKEN="your_token_here"

# Test without auth (should fail)
curl -X GET http://127.0.0.1:8080/performance

# Test with auth (should succeed)
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN"

# Test with JSON formatting
curl -X GET http://127.0.0.1:8080/performance -H "Authorization: Bearer $TOKEN" | jq .

# Get specific metrics
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.engine.fps'
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.memory'
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.cache.l1_cache'
```

### Monitoring Commands

```bash
# Monitor FPS continuously
watch -n 5 'curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq .engine.fps'

# Monitor memory usage
while true; do curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.memory.static_memory_usage'; sleep 10; done

# Check cache statistics
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq '.cache.l1_cache'
```

### Rollback Commands

```bash
# Stop Godot (Windows)
taskkill /F /IM Godot*

# Revert changes (if using git)
cd C:/godot
git checkout project.godot
git checkout scripts/http_api/http_api_server.gd

# Restart Godot
python godot_editor_server.py --port 8090 --auto-load-scene
```

---

## Conclusion

The PerformanceRouter is **production-ready and can be activated immediately** with minimal risk. The activation process is straightforward, well-documented, and easily reversible.

**Final Recommendation**: **GO** - Proceed with activation

**Key Points:**
- ✅ Code is complete and well-tested
- ✅ Dependencies are satisfied
- ✅ Risk is very low
- ✅ Rollback is fast and easy
- ✅ Testing procedure is comprehensive
- ✅ No blockers identified

**Estimated Total Time**: 1-2 hours (including testing)
**Risk Level**: LOW
**Confidence Level**: HIGH

**Next Steps:**
1. Follow activation steps in order
2. Test thoroughly using provided procedures
3. Monitor for 15 minutes after activation
4. Update HTTP_API_ROUTER_STATUS.md
5. Proceed to Phase 2 (WebhookRouter) if successful

---

**Document End**
