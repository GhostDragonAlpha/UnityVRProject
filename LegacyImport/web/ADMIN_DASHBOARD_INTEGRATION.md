# Admin Dashboard Integration Guide

## Quick Integration

To integrate the admin dashboard into your HTTP API server, follow these steps:

### 1. Register Admin Router

Edit `C:/godot/scripts/http_api/http_api_server.gd` and add the admin router registration:

```gdscript
func _register_routers():
	"""Register all HTTP routers for different endpoints"""

	# Register specific routes BEFORE generic routes (godottpd uses prefix matching)

	# Admin router (/admin/* endpoints) - ADD THIS
	var admin_router = load("res://scripts/http_api/admin_router.gd").new()
	server.register_router(admin_router)
	print("[HttpApiServer] Registered /admin router")

	# Scene history router (/scene/history must come before /scene)
	var scene_history_router = load("res://scripts/http_api/scene_history_router.gd").new()
	server.register_router(scene_history_router)
	print("[HttpApiServer] Registered /scene/history router")

	# ... rest of routers
```

### 2. Initialize Admin WebSocket

Add WebSocket server initialization in the same file:

```gdscript
func _register_routers():
	# ... existing router registrations ...

	# Initialize admin WebSocket server - ADD THIS
	var admin_ws = load("res://scripts/http_api/admin_websocket.gd").new()
	admin_ws.name = "AdminWebSocket"
	add_child(admin_ws)
	print("[HttpApiServer] Registered admin WebSocket server")
```

### 3. Track Requests for Metrics

To enable metrics tracking, add this to your scene router's handle method:

```gdscript
# In scene_router.gd (or other routers)
const AdminRouter = preload("res://scripts/http_api/admin_router.gd")

func handle(request, response) -> bool:
	var start_time = Time.get_ticks_msec()

	# ... your existing handling code ...

	# Track request for admin metrics
	var response_time = Time.get_ticks_msec() - start_time
	var success = response.code >= 200 and response.code < 400
	AdminRouter.track_request(success, response_time)

	return true
```

### 4. Track Scene Loads

Add scene load tracking in your scene loading code:

```gdscript
# In scene_router.gd or wherever scenes are loaded
const AdminRouter = preload("res://scripts/http_api/admin_router.gd")

func _load_scene(scene_path: String):
	var start_time = Time.get_ticks_msec()

	# Load scene
	var success = # ... your loading logic ...

	# Track for admin dashboard
	var load_time = Time.get_ticks_msec() - start_time
	AdminRouter.track_scene_load(scene_path, load_time, success)
```

### 5. Add Audit Logging

Add audit log entries for important actions:

```gdscript
const AdminRouter = preload("res://scripts/http_api/admin_router.gd")

# After important action
AdminRouter.add_audit_log(
	"scene_load",
	"api_user",
	{"scene_path": scene_path, "success": true}
)
```

### 6. Test the Integration

1. Start Godot server
2. Check console for admin token:
   ```
   [AdminRouter] ADMIN TOKEN: admin_...
   ```
3. Open `web/admin_dashboard.html` in browser
4. Enter admin token when prompted
5. Verify all sections work

## File Structure

```
scripts/http_api/
├── admin_router.gd              # Admin endpoints (NEW)
├── admin_websocket.gd           # WebSocket server (NEW)
├── http_api_server.gd           # Main server (MODIFY)
├── scene_router.gd              # Scene endpoints (MODIFY for tracking)
└── ... other routers

web/
├── admin_dashboard.html         # Dashboard UI (NEW)
├── ADMIN_DASHBOARD.md           # User guide (NEW)
└── ADMIN_DASHBOARD_INTEGRATION.md  # This file (NEW)

tests/http_api/
└── test_admin_dashboard.py      # Test suite (NEW)
```

## Testing

Run the test suite:

```bash
cd C:/godot/tests/http_api
python test_admin_dashboard.py
```

Or with pytest directly:

```bash
pytest test_admin_dashboard.py -v
```

## Configuration

### Admin Token Security

The admin token is automatically generated on server startup. To manually set a token:

```gdscript
# In admin_router.gd
static func _generate_admin_token() -> String:
	# For development, use a fixed token
	_admin_token = "admin_dev_token_12345"
	return _admin_token

	# For production, use generated token (default)
	# var bytes = PackedByteArray()
	# for i in range(32):
	#     bytes.append(randi() % 256)
	# _admin_token = "admin_" + bytes.hex_encode()
	# return _admin_token
```

### WebSocket Port

The WebSocket server runs on port 8083 by default. To change:

```gdscript
# In admin_websocket.gd
const WS_PORT = 8083  # Change this
```

### Dashboard API URL

If your HTTP API runs on a different port or host:

```javascript
// In admin_dashboard.html, update apiUrl
data() {
	return {
		apiUrl: 'http://127.0.0.1:8080',  // Change this
		// ...
	}
}
```

## Troubleshooting

### Router Not Registered

If admin endpoints return 404:

1. Check console for "Registered /admin router" message
2. Verify admin_router.gd loads without errors
3. Check godottpd router registration order

### WebSocket Connection Fails

If WebSocket shows disconnected:

1. Verify admin_websocket.gd is added to scene tree
2. Check port 8083 is available
3. Check firewall settings
4. Look for WebSocket errors in browser console

### Metrics Show Zeros

If dashboard shows no metrics:

1. Verify `AdminRouter.track_request()` is being called
2. Make some API requests to generate data
3. Check admin token is valid
4. Refresh dashboard manually

## Advanced Features

### Custom Metrics

Add custom metrics to the admin dashboard:

```gdscript
# In admin_router.gd, add static variable
static var _custom_metrics: Dictionary = {}

# Add tracking method
static func track_custom_metric(key: String, value: float):
	_custom_metrics[key] = value

# Include in /admin/metrics endpoint
func _handle_metrics(request, response) -> bool:
	var metrics = {
		# ... existing metrics ...
		"custom": _custom_metrics
	}
	# ...
```

### Webhook Notifications

Send webhooks on specific events:

```gdscript
# In admin_router.gd
static func send_webhook(event: String, data: Dictionary):
	for webhook in _webhooks:
		if webhook.events.is_empty() or webhook.events.has(event):
			_http_post(webhook.url, {"event": event, "data": data})
```

### Job Queue Integration

Connect job system to admin dashboard:

```gdscript
# When job starts
AdminRouter._jobs.append({
	"id": job_id,
	"type": job_type,
	"status": "running",
	"progress": 0,
	"created": Time.get_unix_time_from_system()
})

# Broadcast update
var admin_ws = get_node("/root/HttpApiServer/AdminWebSocket")
if admin_ws:
	admin_ws.broadcast_job_update(job_data)
```

## Production Deployment

### Security Checklist

- [ ] Change default admin token generation to use crypto RNG
- [ ] Implement token expiration
- [ ] Add IP whitelist for admin endpoints
- [ ] Enable HTTPS/TLS
- [ ] Implement rate limiting on admin endpoints
- [ ] Set up audit log rotation
- [ ] Configure log retention policy
- [ ] Review and limit dashboard permissions

### Performance Optimization

- [ ] Implement metrics aggregation (reduce storage)
- [ ] Add database backend for audit logs
- [ ] Cache frequently accessed data
- [ ] Implement pagination for large datasets
- [ ] Set up metrics cleanup (delete old data)

### Monitoring

- [ ] Set up alerts for high error rates
- [ ] Monitor WebSocket connection count
- [ ] Track dashboard access frequency
- [ ] Alert on failed admin authentication
- [ ] Monitor server resource usage

## API Documentation

See `ADMIN_DASHBOARD.md` for complete API endpoint documentation.

Quick reference:

- `GET /admin/metrics` - System metrics
- `GET /admin/health` - Health check
- `GET /admin/logs` - System logs
- `POST /admin/config` - Update configuration
- `GET /admin/security/tokens` - Active tokens
- `GET /admin/scenes/whitelist` - Scene whitelist
- `GET /admin/webhooks` - Registered webhooks
- `GET /admin/jobs` - Job queue status

## Support

For issues with integration:

1. Check Godot console for error messages
2. Verify all files are in correct locations
3. Test endpoints individually with curl
4. Check browser console for JavaScript errors
5. Review test suite for examples

## Version History

- **v1.0** (2025-12-02): Initial release
  - Admin router with 15+ endpoints
  - WebSocket real-time updates
  - Vue.js 3 dashboard with 8 sections
  - 20+ test cases
  - Complete documentation

---

**Last Updated:** December 2, 2025
**Compatible with:** SpaceTime v2.5+
