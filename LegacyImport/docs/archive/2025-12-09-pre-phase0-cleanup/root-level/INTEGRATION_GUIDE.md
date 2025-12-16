# Token Management Integration Guide

This guide explains how to integrate the token management system into the existing GodotBridge HTTP API server.

## Integration Steps

### Step 1: Initialize TokenManager in SecurityConfig

The TokenManager is automatically initialized when SecurityConfig is loaded. Add this to your startup code:

```gdscript
# In your main scene or autoload _ready()
HttpApiSecurityConfig.initialize_token_manager()
HttpApiSecurityConfig.print_config()
```

### Step 2: Add Auth Router to GodotBridge

In `addons/godot_debug_connection/godot_bridge.gd`, add the auth router:

```gdscript
## Auth router for token management
var auth_router: HttpApiAuthRouter

## Initialize the bridge
func _ready() -> void:
    print("=== GODOT BRIDGE INITIALIZATION ===")

    # Initialize SecurityConfig and TokenManager
    HttpApiSecurityConfig.initialize_token_manager()

    # Create auth router
    auth_router = HttpApiAuthRouter.new(HttpApiSecurityConfig.get_token_manager())

    # ... rest of initialization
```

### Step 3: Add Auth Routes

In the `_route_request()` function, add auth endpoints before other routes:

```gdscript
func _route_request(client: StreamPeerTCP, method: String, path: String, headers: Dictionary, body: String) -> void:
    # Authentication endpoints (no auth required for these)
    if path.begins_with("/auth/"):
        _handle_auth_endpoint(client, method, path, headers, body)
        return

    # Validate authentication for all other endpoints
    if not HttpApiSecurityConfig.validate_auth(headers):
        _send_json_response(client, 401, HttpApiSecurityConfig.create_auth_error_response())
        return

    # ... rest of routing
```

### Step 4: Implement Auth Handler

Add the auth endpoint handler:

```gdscript
## Handle authentication endpoints
func _handle_auth_endpoint(client: StreamPeerTCP, method: String, path: String, headers: Dictionary, body: String) -> void:
    # For /auth/rotate, /auth/refresh, /auth/revoke - require authentication
    var requires_auth = path != "/auth/metrics" and path != "/auth/audit"

    if requires_auth and not HttpApiSecurityConfig.validate_auth(headers):
        _send_json_response(client, 401, HttpApiSecurityConfig.create_auth_error_response())
        return

    # Route to auth router
    var result = auth_router.route_request(method, path, headers, body)
    _send_json_response(client, result.status, result.body)
```

### Step 5: Update Process for Token Maintenance

Add token maintenance to `_process()`:

```gdscript
func _process(delta: float) -> void:
    # Token management maintenance
    HttpApiSecurityConfig.process(delta)

    # ... rest of process logic
```

### Step 6: Update Endpoint Documentation

Update the startup message to include auth endpoints:

```gdscript
print("Available endpoints:")
print("  POST /connect - Connect to GDA services")
print("  POST /disconnect - Disconnect from GDA services")
print("  GET  /status - Get connection status")
print("  POST /auth/rotate - Rotate API token")
print("  POST /auth/refresh - Refresh API token")
print("  POST /auth/revoke - Revoke API token")
print("  GET  /auth/status - Get token status")
print("  GET  /auth/metrics - Get token metrics")
print("  GET  /auth/audit - Get token audit log")
print("  POST /debug/* - Debug adapter commands")
# ... rest of endpoints
```

## Complete Integration Example

Here's a complete example of the integration:

```gdscript
# In godot_bridge.gd

## Auth router for token management
var auth_router: HttpApiAuthRouter

func _ready() -> void:
    print("=== GODOT BRIDGE INITIALIZATION ===")

    # Initialize security and token management
    HttpApiSecurityConfig.initialize_token_manager()
    HttpApiSecurityConfig.print_config()

    # Create auth router
    auth_router = HttpApiAuthRouter.new(HttpApiSecurityConfig.get_token_manager())
    print("AuthRouter initialized")

    # Create connection manager
    connection_manager = ConnectionManager.new()
    add_child(connection_manager)

    # Start HTTP server
    _start_server_with_fallback()

    print("=== GODOT BRIDGE INITIALIZATION COMPLETE ===")

func _process(delta: float) -> void:
    # Token management maintenance (auto-rotation, cleanup)
    HttpApiSecurityConfig.process(delta)

    # Service discovery broadcasting
    if udp_broadcaster:
        broadcast_timer += delta
        if broadcast_timer >= BROADCAST_INTERVAL:
            broadcast_timer = 0.0
            _broadcast_discovery()

    # ... rest of process logic

func _route_request(client: StreamPeerTCP, method: String, path: String, headers: Dictionary, body: String) -> void:
    # Serve dashboard (no auth)
    if (path == "/" or path == "/dashboard.html") and method == "GET":
        _handle_static_file_request(client, "res://addons/godot_debug_connection/dashboard.html", "text/html")
        return

    # Auth endpoints (special handling - some require auth, some don't)
    if path.begins_with("/auth/"):
        _handle_auth_endpoint(client, method, path, headers, body)
        return

    # Validate authentication for all other endpoints
    if not HttpApiSecurityConfig.validate_auth(headers):
        _send_json_response(client, 401, HttpApiSecurityConfig.create_auth_error_response())
        return

    # Connection management endpoints (authenticated)
    if path == "/connect" and method == "POST":
        _handle_connect(client, body)
    elif path == "/disconnect" and method == "POST":
        _handle_disconnect(client, body)
    elif path == "/status" and method == "GET":
        _handle_status(client)

    # ... rest of routing

    else:
        _send_error_response(client, 404, "Not Found", "Endpoint not found: " + path)

## Handle authentication endpoints
func _handle_auth_endpoint(client: StreamPeerTCP, method: String, path: String, headers: Dictionary, body: String) -> void:
    # Metrics and audit log don't require auth (public endpoints)
    var public_endpoints = ["/auth/metrics", "/auth/audit"]
    var requires_auth = true

    for endpoint in public_endpoints:
        if path == endpoint:
            requires_auth = false
            break

    # Validate auth for protected endpoints
    if requires_auth and not HttpApiSecurityConfig.validate_auth(headers):
        _send_json_response(client, 401, HttpApiSecurityConfig.create_auth_error_response())
        return

    # Route to auth router
    var result = auth_router.route_request(method, path, headers, body)
    _send_json_response(client, result.status, result.body)
```

## Testing the Integration

### 1. Start Godot with Debug Services

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### 2. Check Console Output

You should see:
```
[Security] TokenManager initialized
[Security] Active token: 1a2b3c4d5e6f...
[Security] Token ID: 550e8400-e29b-41d4-a716-446655440000
[Security] Expires: 2024-12-03 14:30:00
[Security] Include in requests: Authorization: Bearer 1a2b3c4d5e6f...
AuthRouter initialized
```

### 3. Test Auth Endpoints

```bash
# Get token from console output
TOKEN="1a2b3c4d5e6f..."

# Test token status
curl http://127.0.0.1:8080/auth/status \
  -H "Authorization: Bearer $TOKEN"

# Test token refresh
curl -X POST http://127.0.0.1:8080/auth/refresh \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"extension_hours": 24.0}'

# Test token rotation
curl -X POST http://127.0.0.1:8080/auth/rotate \
  -H "Authorization: Bearer $TOKEN"

# Test metrics (no auth required)
curl http://127.0.0.1:8080/auth/metrics
```

### 4. Test Python Client

```python
from godot_api_client import GodotAPIClient

# Create client (loads token from storage or prompts for input)
client = GodotAPIClient(auto_refresh=True)

# Test token operations
status = client.get_token_status()
print(f"Token expires in {status['expires_in_hours']:.1f} hours")

# Make authenticated requests
api_status = client.get_status()
print(api_status)
```

## Configuration Options

### Disable Token Manager (Legacy Mode)

If you want to use the old single-token system:

```gdscript
# In security_config.gd or at startup
HttpApiSecurityConfig.use_token_manager = false
```

### Configure Token Lifetime

```gdscript
# In token_manager.gd
const DEFAULT_TOKEN_LIFETIME_HOURS = 24  # Change to desired lifetime
```

### Configure Auto-Rotation

```gdscript
# In token_manager.gd
const AUTO_ROTATION_ENABLED = true  # Set to false to disable
```

### Configure Grace Period

```gdscript
# In token_manager.gd
const ROTATION_OVERLAP_HOURS = 1  # Change grace period duration
```

## Troubleshooting

### Issue: AuthRouter not found

**Solution**: Ensure `auth_router.gd` is in the correct location:
```
C:/godot/scripts/http_api/auth_router.gd
```

### Issue: TokenManager not found

**Solution**: Ensure `token_manager.gd` is in the correct location:
```
C:/godot/scripts/http_api/token_manager.gd
```

### Issue: Tokens not persisting

**Solution**: Check that `user://tokens/` directory exists and is writable:
```gdscript
# In Godot console
print(OS.get_user_data_dir() + "/tokens/")
```

### Issue: All requests getting 401

**Solution**: Check that token manager is initialized:
```gdscript
# Add debug output
print("Token manager: ", HttpApiSecurityConfig.get_token_manager())
print("Use token manager: ", HttpApiSecurityConfig.use_token_manager)
```

## Migration from Legacy System

The system automatically migrates legacy tokens on first startup. No manual action needed!

If you want to force migration:

```gdscript
# At startup, after initializing token manager
var legacy_token = HttpApiSecurityConfig.generate_token()
print("Legacy token will be auto-migrated: ", legacy_token)
```

## Security Considerations

1. **Always use HTTPS in production** (current implementation is HTTP for local dev)
2. **Rotate tokens regularly** (automatic rotation handles this)
3. **Monitor metrics** for suspicious activity
4. **Review audit logs** periodically
5. **Revoke tokens immediately** on security incidents

## Next Steps

1. Integrate into `godot_bridge.gd` following this guide
2. Test all auth endpoints
3. Update client applications to use new token system
4. Enable auto-refresh in all clients
5. Set up monitoring for token metrics
6. Schedule regular audit log reviews

## Reference Files

- TokenManager: `C:/godot/scripts/http_api/token_manager.gd`
- AuthRouter: `C:/godot/scripts/http_api/auth_router.gd`
- SecurityConfig: `C:/godot/scripts/http_api/security_config.gd`
- Python Client: `C:/godot/examples/godot_api_client.py`
- Test Suite: `C:/godot/tests/http_api/test_token_rotation.py`
- User Guide: `C:/godot/TOKEN_MANAGEMENT.md`
- Implementation Report: `C:/godot/TOKEN_ROTATION_IMPLEMENTATION_REPORT.md`
