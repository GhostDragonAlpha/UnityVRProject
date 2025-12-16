# Integration Instructions for Advanced API Features

Quick guide to integrate the new batch operations, webhooks, and job queue features into your HTTP API server.

## Step 1: Add Autoloads to project.godot

Open `C:/godot/project.godot` and add these lines to the `[autoload]` section:

```ini
[autoload]
WebhookManager="*res://scripts/http_api/webhook_manager.gd"
JobQueue="*res://scripts/http_api/job_queue.gd"
```

These create singleton instances that manage webhooks and job processing globally.

## Step 2: Update http_api_server.gd

Add the following routers to the `_register_routers()` function in `C:/godot/scripts/http_api/http_api_server.gd`:

```gdscript
func _register_routers():
	"""Register all HTTP routers for different endpoints"""

	# Register specific routes BEFORE generic routes (godottpd uses prefix matching)

	# ========== EXISTING ROUTERS (Keep These) ==========
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

	# ========== NEW ADVANCED FEATURE ROUTERS ==========

	# Webhook deliveries router (/webhooks/:id/deliveries must come before /webhooks/:id)
	var webhook_deliveries_router = load("res://scripts/http_api/webhook_deliveries_router.gd").new()
	server.register_router(webhook_deliveries_router)
	print("[HttpApiServer] Registered /webhooks/:id/deliveries router")

	# Webhook detail router (/webhooks/:id must come before /webhooks)
	var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
	server.register_router(webhook_detail_router)
	print("[HttpApiServer] Registered /webhooks/:id router")

	# Webhook router (generic /webhooks route)
	var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
	server.register_router(webhook_router)
	print("[HttpApiServer] Registered /webhooks router")

	# Job detail router (/jobs/:id must come before /jobs)
	var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
	server.register_router(job_detail_router)
	print("[HttpApiServer] Registered /jobs/:id router")

	# Job router (generic /jobs route)
	var job_router = load("res://scripts/http_api/job_router.gd").new()
	server.register_router(job_router)
	print("[HttpApiServer] Registered /jobs router")

	# Batch operations router
	var batch_router = load("res://scripts/http_api/batch_operations_router.gd").new()
	server.register_router(batch_router)
	print("[HttpApiServer] Registered /batch router")
```

## Step 3: Update Startup Messages

Update the `_ready()` function to show the new endpoints:

```gdscript
func _ready():
	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)

	# Initialize security
	SecurityConfig.generate_token()
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
	print("[HttpApiServer] Available endpoints:")
	print("[HttpApiServer]   POST /scene - Load a scene (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /scene - Get current scene (AUTH REQUIRED)")
	print("[HttpApiServer]   PUT  /scene - Validate a scene (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /scenes - List available scenes (AUTH REQUIRED)")
	print("[HttpApiServer]   POST /scene/reload - Reload current scene (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /scene/history - Get scene load history (AUTH REQUIRED)")

	# NEW ENDPOINTS
	print("[HttpApiServer]   POST /batch - Execute batch operations (AUTH REQUIRED)")
	print("[HttpApiServer]   POST /webhooks - Register webhook (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /webhooks - List webhooks (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /webhooks/:id - Get webhook details (AUTH REQUIRED)")
	print("[HttpApiServer]   PUT  /webhooks/:id - Update webhook (AUTH REQUIRED)")
	print("[HttpApiServer]   DELETE /webhooks/:id - Delete webhook (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /webhooks/:id/deliveries - Get delivery history (AUTH REQUIRED)")
	print("[HttpApiServer]   POST /jobs - Submit job (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /jobs - List jobs (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /jobs/:id - Get job status (AUTH REQUIRED)")
	print("[HttpApiServer]   DELETE /jobs/:id - Cancel job (AUTH REQUIRED)")

	print("[HttpApiServer] ")
	print("[HttpApiServer] API TOKEN: ", SecurityConfig.get_token())
	print("[HttpApiServer] Use: curl -H 'Authorization: Bearer ", SecurityConfig.get_token(), "' ...")
```

## Step 4: Test the Integration

### Start Godot
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### Test Batch Operations
```bash
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"operations": [{"action": "get_info"}]}'
```

### Test Webhook Registration
```bash
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://localhost:9000/webhook",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "test_secret"
  }'
```

### Test Job Submission
```bash
curl -X POST http://localhost:8080/jobs \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "cache_warming",
    "parameters": {}
  }'
```

## Step 5: Run Tests

```bash
cd tests/http_api
pytest test_batch_operations.py test_webhooks.py test_job_queue.py -v
```

## Step 6: Start Webhook Test Server (Optional)

```bash
cd examples
python webhook_server.py --port 9000 --secret test_secret
```

Then register a webhook pointing to http://localhost:9000/webhook

## Troubleshooting

### Autoloads not found
**Error:** "Cannot load resource"
**Solution:** Verify paths in project.godot match file locations

### Routers not registering
**Error:** "Router not found"
**Solution:** Check that all router files exist and have correct class_name

### Webhooks not delivering
**Error:** Webhooks registered but not receiving events
**Solution:**
1. Check webhook URL is accessible
2. Verify webhook server is running
3. Check delivery history: `curl http://localhost:8080/webhooks/1/deliveries -H "Authorization: Bearer TOKEN"`

### Jobs not processing
**Error:** Jobs stuck in queued state
**Solution:**
1. Verify JobQueue autoload is registered
2. Check max concurrent jobs limit (default 3)
3. Cancel stuck jobs if needed

## Complete Example: http_api_server.gd

Here's the complete updated file:

```gdscript
extends Node

## HTTP API Server using godottpd
## Provides REST API for remote control and scene management
## This replaces the old godot_bridge.gd approach with a proven library
##
## SECURITY: v2.5+ includes authentication, whitelisting, and rate limiting
## ADVANCED: v3.0+ adds batch operations, webhooks, and job queue

const PORT = 8080
const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

var server: Node


func _ready():
	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)

	# Initialize security
	SecurityConfig.generate_token()
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
	print("[HttpApiServer] Available endpoints:")
	print("[HttpApiServer]   POST /scene - Load a scene")
	print("[HttpApiServer]   GET  /scene - Get current scene")
	print("[HttpApiServer]   PUT  /scene - Validate a scene")
	print("[HttpApiServer]   GET  /scenes - List available scenes")
	print("[HttpApiServer]   POST /scene/reload - Reload current scene")
	print("[HttpApiServer]   GET  /scene/history - Get scene load history")
	print("[HttpApiServer]   POST /batch - Execute batch operations")
	print("[HttpApiServer]   POST /webhooks - Register webhook")
	print("[HttpApiServer]   GET  /webhooks - List webhooks")
	print("[HttpApiServer]   POST /jobs - Submit job")
	print("[HttpApiServer]   GET  /jobs - List jobs")
	print("[HttpApiServer] ")
	print("[HttpApiServer] API TOKEN: ", SecurityConfig.get_token())
	print("[HttpApiServer] Use: curl -H 'Authorization: Bearer ", SecurityConfig.get_token(), "' ...")
	print("[HttpApiServer] ")
	print("[HttpApiServer] Documentation:")
	print("[HttpApiServer]   Batch Ops: scripts/http_api/BATCH_OPERATIONS.md")
	print("[HttpApiServer]   Webhooks:  scripts/http_api/WEBHOOKS.md")
	print("[HttpApiServer]   Job Queue: scripts/http_api/JOB_QUEUE.md")


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

	# Webhook deliveries router
	var webhook_deliveries_router = load("res://scripts/http_api/webhook_deliveries_router.gd").new()
	server.register_router(webhook_deliveries_router)
	print("[HttpApiServer] Registered /webhooks/:id/deliveries router")

	# Webhook detail router
	var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
	server.register_router(webhook_detail_router)
	print("[HttpApiServer] Registered /webhooks/:id router")

	# Webhook router
	var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
	server.register_router(webhook_router)
	print("[HttpApiServer] Registered /webhooks router")

	# Job detail router
	var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
	server.register_router(job_detail_router)
	print("[HttpApiServer] Registered /jobs/:id router")

	# Job router
	var job_router = load("res://scripts/http_api/job_router.gd").new()
	server.register_router(job_router)
	print("[HttpApiServer] Registered /jobs router")

	# Batch operations router
	var batch_router = load("res://scripts/http_api/batch_operations_router.gd").new()
	server.register_router(batch_router)
	print("[HttpApiServer] Registered /batch router")


func _exit_tree():
	if server:
		print("[HttpApiServer] Stopping HTTP server...")
		server.stop()
```

## Next Steps

1. ✅ Add autoloads to project.godot
2. ✅ Update http_api_server.gd with new routers
3. ✅ Test each endpoint
4. ✅ Run test suite
5. ✅ Start webhook server for testing
6. ✅ Read documentation guides

## Support

For questions or issues:
- See BATCH_OPERATIONS.md for batch operations
- See WEBHOOKS.md for webhook setup
- See JOB_QUEUE.md for job queue usage
- See ADVANCED_FEATURES_REPORT.md for complete overview
- Check test files for usage examples

## Documentation Links

- [C:/godot/scripts/http_api/BATCH_OPERATIONS.md](./BATCH_OPERATIONS.md)
- [C:/godot/scripts/http_api/WEBHOOKS.md](./WEBHOOKS.md)
- [C:/godot/scripts/http_api/JOB_QUEUE.md](./JOB_QUEUE.md)
- [C:/godot/scripts/http_api/ADVANCED_FEATURES_REPORT.md](./ADVANCED_FEATURES_REPORT.md)
- [C:/godot/tests/http_api/test_batch_operations.py](../../tests/http_api/test_batch_operations.py)
- [C:/godot/tests/http_api/test_webhooks.py](../../tests/http_api/test_webhooks.py)
- [C:/godot/tests/http_api/test_job_queue.py](../../tests/http_api/test_job_queue.py)
- [C:/godot/examples/webhook_server.py](../../examples/webhook_server.py)
