# Phase 2 Router Activation Guide

**Document Version**: 1.0
**Created**: 2025-12-04
**Target**: WebhookRouter and JobRouter activation
**Estimated Time**: 3-4 hours
**Difficulty**: Medium

---

## Quick Start

This guide provides step-by-step instructions for activating Phase 2 routers (webhooks and job queue).

**Prerequisites**:
- Phase 1 routers activated (PerformanceRouter)
- CacheManager autoload operational
- Text editor for code changes
- Terminal/command line access

**What You'll Activate**:
- WebhookRouter - Register and manage webhooks
- WebhookDetailRouter - Individual webhook operations
- JobRouter - Submit and list background jobs
- JobDetailRouter - Individual job operations

---

## Step-by-Step Activation

### Step 1: Add Autoloads to project.godot

**Time**: 5 minutes

**File**: `C:\godot\project.godot`

**Action**: Add two autoload lines after CacheManager (line 26)

**Current state** (lines 19-26):
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
CacheManager="*res://scripts/http_api/cache_manager.gd"
```

**Add these two lines after line 26**:
```ini
WebhookManager="*res://scripts/http_api/webhook_manager.gd"
JobQueue="*res://scripts/http_api/job_queue.gd"
```

**Result** (lines 19-28):
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
CacheManager="*res://scripts/http_api/cache_manager.gd"
WebhookManager="*res://scripts/http_api/webhook_manager.gd"
JobQueue="*res://scripts/http_api/job_queue.gd"
```

**Save file**: Ctrl+S (or Cmd+S on Mac)

---

### Step 2: Register Routers in http_api_server.gd

**Time**: 10 minutes

**File**: `C:\godot\scripts\http_api\http_api_server.gd`

**Action**: Add router registrations after Phase 1 section

**Current state** (around lines 215-221):
```gdscript
	# === PHASE 1: PERFORMANCE MONITORING ===

	# Performance monitoring router
	var performance_router = load("res://scripts/http_api/performance_router.gd").new()
	server.register_router(performance_router)
	print("[HttpApiServer] Registered /performance router")
```

**Add these lines after line 221** (after Phase 1 section):
```gdscript

	# === PHASE 2: WEBHOOKS ===

	# Webhook detail router (specific /webhooks/:id routes - MUST come BEFORE /webhooks)
	var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
	server.register_router(webhook_detail_router)
	print("[HttpApiServer] Registered /webhooks/:id router")

	# Webhook management router (generic /webhooks route)
	var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
	server.register_router(webhook_router)
	print("[HttpApiServer] Registered /webhooks router")


	# === PHASE 2: JOB QUEUE ===

	# Job detail router (specific /jobs/:id routes - MUST come BEFORE /jobs)
	var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
	server.register_router(job_detail_router)
	print("[HttpApiServer] Registered /jobs/:id router")

	# Job queue management router (generic /jobs route)
	var job_router = load("res://scripts/http_api/job_router.gd").new()
	server.register_router(job_router)
	print("[HttpApiServer] Registered /jobs router")
```

**IMPORTANT**: Router order matters! Register detail routers BEFORE generic routers.

**Save file**: Ctrl+S (or Cmd+S on Mac)

---

### Step 3: Restart Godot

**Time**: 5 minutes

**Action**: Restart Godot to load new autoloads and routers

**Method 1: Via Python Server (Recommended)**
```bash
# If Godot is running via Python server, stop it first
# Press Ctrl+C in the terminal running godot_editor_server.py

# Then restart
python godot_editor_server.py --port 8090 --auto-load-scene
```

**Method 2: Direct Godot Launch**
```bash
# Stop Godot (if running)
# Windows: Close console window or Ctrl+C
# Linux/Mac: Ctrl+C or pkill -f Godot

# Restart
C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe --path C:/godot
```

---

### Step 4: Verify Startup

**Time**: 5 minutes

**Action**: Check console output for successful initialization

**Expected console output**:
```
[WebhookManager] Initialized webhook system
[JobQueue] Initialized job queue system
[HttpApiServer] Registered /webhooks/:id router
[HttpApiServer] Registered /webhooks router
[HttpApiServer] Registered /jobs/:id router
[HttpApiServer] Registered /jobs router
[HttpApiServer] SECURE HTTP API server started on 127.0.0.1:8080
```

**If you see errors**:
```
[HttpApiServer] Webhook manager not available
```
- **Cause**: WebhookManager autoload not loaded
- **Fix**: Check project.godot line 27, verify file path is correct
- **Retry**: Restart Godot

```
[HttpApiServer] Job queue not available
```
- **Cause**: JobQueue autoload not loaded
- **Fix**: Check project.godot line 28, verify file path is correct
- **Retry**: Restart Godot

---

### Step 5: Get API Token

**Time**: 1 minute

**Action**: Copy API token from console output

**Look for this line in console**:
```
[HttpApiServer] API TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Copy the token** (everything after "API TOKEN: ")

**Store in environment variable** (for easy testing):
```bash
# Windows CMD
set TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Windows PowerShell
$env:TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Linux/Mac
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

### Step 6: Test Webhook Endpoints

**Time**: 30 minutes

#### Test 6.1: Register Webhook

**Command**:
```bash
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"https://webhook.site/unique-id\", \"events\": [\"scene.loaded\"], \"secret\": \"test_secret\"}"
```

**Expected Response** (201 Created):
```json
{
  "success": true,
  "webhook_id": "1",
  "webhook": {
    "id": "1",
    "url": "https://webhook.site/unique-id",
    "events": ["scene.loaded"],
    "secret": "***",
    "created_at": 1733356800,
    "enabled": true,
    "delivery_count": 0,
    "failure_count": 0
  }
}
```

**If failed**:
- Check TOKEN is set correctly
- Verify WebhookManager is loaded (check console)
- Check request body JSON is valid

---

#### Test 6.2: List Webhooks

**Command**:
```bash
curl -X GET http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "webhooks": [
    {
      "id": "1",
      "url": "https://webhook.site/unique-id",
      ...
    }
  ],
  "count": 1
}
```

---

#### Test 6.3: Get Webhook Details

**Command**:
```bash
curl -X GET http://localhost:8080/webhooks/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "webhook": {
    "id": "1",
    "url": "https://webhook.site/unique-id",
    ...
  }
}
```

---

#### Test 6.4: Update Webhook

**Command**:
```bash
curl -X PUT http://localhost:8080/webhooks/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"enabled\": false}"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "webhook": {
    "id": "1",
    "enabled": false,
    ...
  }
}
```

---

#### Test 6.5: Delete Webhook

**Command**:
```bash
curl -X DELETE http://localhost:8080/webhooks/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Webhook deleted"
}
```

---

### Step 7: Test Job Queue Endpoints

**Time**: 30 minutes

#### Test 7.1: Submit Job

**Command**:
```bash
curl -X POST http://localhost:8080/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"scene_preload\", \"parameters\": {\"scene_paths\": [\"res://vr_main.tscn\"]}}"
```

**Expected Response** (202 Accepted):
```json
{
  "success": true,
  "job_id": "1",
  "status": "queued"
}
```

---

#### Test 7.2: Get Job Status

**Command**:
```bash
curl -X GET http://localhost:8080/jobs/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "job": {
    "id": "1",
    "type": "scene_preload",
    "status": "completed",
    "progress": 1.0,
    "result": {
      "scenes_loaded": 1,
      "total_scenes": 1,
      ...
    }
  }
}
```

**Note**: Job may be "queued" or "running" initially. Poll again after a few seconds.

---

#### Test 7.3: List Jobs

**Command**:
```bash
curl -X GET http://localhost:8080/jobs \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "jobs": [
    {
      "id": "1",
      "type": "scene_preload",
      "status": "completed",
      "progress": 1.0,
      "created_at": 1733356800
    }
  ],
  "count": 1
}
```

---

#### Test 7.4: Cancel Job

**Command**:
```bash
# First, submit a long job
curl -X POST http://localhost:8080/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"cache_warming\", \"parameters\": {}}"

# Then cancel it immediately
curl -X DELETE http://localhost:8080/jobs/2 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Job cancelled"
}
```

---

### Step 8: Test Webhook Delivery

**Time**: 15 minutes

#### Test 8.1: Create Webhook for Testing

**Command**:
```bash
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"https://webhook.site/unique-id\", \"events\": [\"scene.loaded\"], \"secret\": \"webhook_secret\"}"
```

**Note**: Replace `unique-id` with your actual webhook.site ID (visit https://webhook.site to get one)

---

#### Test 8.2: Trigger Webhook Event

**Command** (load a scene to trigger scene.loaded event):
```bash
curl -X POST http://localhost:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"scene_path\": \"res://minimal_test.tscn\"}"
```

---

#### Test 8.3: Verify Webhook Delivery

**Action**:
1. Visit https://webhook.site/unique-id (use your actual ID)
2. Check for webhook delivery
3. Verify headers:
   - `X-Webhook-Signature` - HMAC signature (should be present)
   - `X-Webhook-Event` - Should be `scene.loaded`
   - `X-Webhook-ID` - Should match your webhook ID
   - `X-Webhook-Attempt` - Should be `1`
4. Verify payload:
```json
{
  "event": "scene.loaded",
  "webhook_id": "1",
  "timestamp": 1733356800,
  "data": {
    "scene_path": "res://minimal_test.tscn",
    ...
  }
}
```

**If webhook not received**:
- Check webhook URL is correct (https://webhook.site/your-unique-id)
- Check webhook is enabled (GET /webhooks/1)
- Check scene loaded successfully (POST /scene should return 200)
- Check Godot console for delivery errors

---

### Step 9: Test Error Handling

**Time**: 10 minutes

#### Test 9.1: Authentication Failure (401)

**Command** (no token):
```bash
curl -X GET http://localhost:8080/webhooks
```

**Expected Response** (401 Unauthorized):
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token"
}
```

---

#### Test 9.2: Not Found (404)

**Command** (non-existent webhook):
```bash
curl -X GET http://localhost:8080/webhooks/999 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (404 Not Found):
```json
{
  "success": false,
  "error": "Webhook not found"
}
```

---

#### Test 9.3: Bad Request (400)

**Command** (missing required field):
```bash
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"https://webhook.site/test\"}"
```

**Expected Response** (400 Bad Request):
```json
{
  "error": "Bad Request",
  "message": "Missing required field: events"
}
```

---

### Step 10: Final Verification

**Time**: 5 minutes

**Checklist**:
- [ ] WebhookManager autoload loaded (check console)
- [ ] JobQueue autoload loaded (check console)
- [ ] 4 routers registered (check console for 4 print statements)
- [ ] POST /webhooks works (201 Created)
- [ ] GET /webhooks works (200 OK)
- [ ] GET /webhooks/:id works (200 OK)
- [ ] PUT /webhooks/:id works (200 OK)
- [ ] DELETE /webhooks/:id works (200 OK)
- [ ] POST /jobs works (202 Accepted)
- [ ] GET /jobs works (200 OK)
- [ ] GET /jobs/:id works (200 OK)
- [ ] DELETE /jobs/:id works (200 OK)
- [ ] Webhook delivery works (check webhook.site)
- [ ] HMAC signature present (X-Webhook-Signature header)
- [ ] Authentication enforced (401 without token)
- [ ] No errors in Godot console

**If all checked**: ✅ **Phase 2 Activation Successful!**

---

## Troubleshooting

### Issue: Autoload not loaded

**Symptoms**:
```
[HttpApiServer] Webhook manager not available
```

**Solution**:
1. Check project.godot autoload section
2. Verify file path: `res://scripts/http_api/webhook_manager.gd`
3. Verify file exists: `ls C:/godot/scripts/http_api/webhook_manager.gd`
4. Restart Godot

---

### Issue: Router not registered

**Symptoms**:
```
404 Not Found
```

**Solution**:
1. Check http_api_server.gd `_register_routers()` function
2. Verify router registration code added
3. Check console for registration messages
4. Restart Godot

---

### Issue: Router order wrong

**Symptoms**:
- GET /webhooks/1 returns 400 instead of 200
- DELETE /jobs/1 returns 404 instead of 200

**Solution**:
1. Check router registration order
2. Ensure detail routers registered BEFORE generic routers
3. Correct order:
   ```gdscript
   var webhook_detail_router = load("...").new()  # /webhooks/:id FIRST
   server.register_router(webhook_detail_router)

   var webhook_router = load("...").new()  # /webhooks SECOND
   server.register_router(webhook_router)
   ```
4. Restart Godot

---

### Issue: Webhook not delivered

**Symptoms**:
- Webhook registered successfully
- Scene loaded successfully
- But webhook.site shows no delivery

**Solution**:
1. Check webhook URL is correct
2. Check webhook is enabled (GET /webhooks/1, check "enabled": true)
3. Check webhook events include "scene.loaded"
4. Check Godot console for delivery errors:
   ```
   [WebhookManager] Webhook delivery failed: 1 - HTTP 404
   ```
5. Try with a fresh webhook.site URL (https://webhook.site)

---

### Issue: Job stays queued

**Symptoms**:
- Job submitted successfully
- Status stays "queued" for long time
- Never becomes "running" or "completed"

**Solution**:
1. Check if 3 jobs already running (max concurrent jobs = 3)
2. List all jobs: `curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/jobs`
3. Wait for running jobs to complete
4. If still stuck, check Godot console for errors

---

### Issue: Authentication fails

**Symptoms**:
```
401 Unauthorized
```

**Solution**:
1. Check TOKEN environment variable is set
2. Verify token from console output (look for "API TOKEN:")
3. Copy entire token (very long string)
4. Test token:
   ```bash
   echo $TOKEN  # Should show long string
   ```
5. Re-set TOKEN if needed

---

## Rollback Instructions

If issues occur, follow these steps to rollback Phase 2:

### Rollback Step 1: Comment Out Autoloads

**File**: `C:\godot\project.godot`

**Change**:
```ini
# WebhookManager="*res://scripts/http_api/webhook_manager.gd"
# JobQueue="*res://scripts/http_api/job_queue.gd"
```

### Rollback Step 2: Comment Out Router Registrations

**File**: `C:\godot\scripts\http_api\http_api_server.gd`

**Comment out Phase 2 sections**:
```gdscript
	# === PHASE 2: WEBHOOKS ===
	# var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
	# server.register_router(webhook_detail_router)
	# print("[HttpApiServer] Registered /webhooks/:id router")
	# var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
	# server.register_router(webhook_router)
	# print("[HttpApiServer] Registered /webhooks router")

	# === PHASE 2: JOB QUEUE ===
	# var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
	# server.register_router(job_detail_router)
	# print("[HttpApiServer] Registered /jobs/:id router")
	# var job_router = load("res://scripts/http_api/job_router.gd").new()
	# server.register_router(job_router)
	# print("[HttpApiServer] Registered /jobs router")
```

### Rollback Step 3: Restart Godot

```bash
python godot_editor_server.py --port 8090 --auto-load-scene
```

### Rollback Step 4: Verify Phase 1 Still Works

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/performance
```

**Expected**: Phase 1 endpoints still functional

---

## Next Steps

After successful Phase 2 activation:

1. **Monitor for 24 hours**
   - Check Godot console for errors
   - Monitor webhook delivery success rate
   - Monitor job queue performance
   - Check memory usage remains stable

2. **Update Documentation**
   - Mark Phase 2 routers as ACTIVE in HTTP_API_ROUTER_STATUS.md
   - Update CLAUDE.md endpoint list
   - Document any issues encountered

3. **Plan Phase 3 Activation**
   - Review ROUTER_ACTIVATION_PLAN.md Phase 3 section
   - BatchOperationsRouter activation
   - Estimated time: 2-3 hours

---

## Success Criteria

Phase 2 activation is successful when:
- ✅ All 4 routers operational
- ✅ All 12 tests passing
- ✅ Webhook delivery working
- ✅ Job queue processing jobs
- ✅ No errors in console
- ✅ No memory leaks
- ✅ Authentication enforced
- ✅ Input validation working

---

**Activation Complete!**

Congratulations on successfully activating Phase 2 routers. The HTTP API now supports event-driven architecture via webhooks and background job processing.

**Document End**
