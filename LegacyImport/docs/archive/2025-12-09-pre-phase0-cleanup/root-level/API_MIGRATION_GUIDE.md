# HTTP API System Migration Guide

## Overview

The SpaceTime project has completed a migration from the legacy GodotBridge system (port 8080) to the modern HttpApiServer system (port 8080). This document clarifies the architecture, explains the migration, and guides developers on correct API usage.

## Current Architecture

### Active System: HttpApiServer (Port 8080)

**Location:** `scripts/http_api/http_api_server.gd`
**Status:** PRODUCTION - Primary API system
**Technology:** godottpd library (lightweight, proven HTTP server)

#### Key Features:
- RESTful API design for scene and resource management
- JWT token-based authentication
- Rate limiting and DDoS protection
- Role-based access control (RBAC)
- Audit logging of all operations
- Batch operations and async job queue
- Webhook management with delivery tracking
- Performance metrics and profiling
- WebSocket telemetry streaming (port 8081)
- Service discovery via UDP broadcast (port 8087)

#### Architecture:
```
HttpApiServer (Port 8080)
├── SceneRouter - /scene/* endpoints
├── ScenesListRouter - /scenes endpoint
├── SceneHistoryRouter - /scene/history endpoint
├── SceneReloadRouter - /scene/reload endpoint
├── AdminRouter - /admin/* administrative endpoints
├── JobRouter - /jobs/* background job management
├── WebhookRouter - /webhooks/* webhook management
├── PerformanceRouter - /performance/* metrics endpoint
└── Security Layer
    ├── SecurityConfig - JWT tokens, RBAC configuration
    ├── RateLimiter - DDoS protection
    ├── AuditLogger - Operation tracking
    └── InputValidator - Request validation
```

### Deprecated System: GodotBridge (Port 8080)

**Location:** `addons/godot_debug_connection/godot_bridge.gd`
**Status:** DEPRECATED - Disabled in autoload
**Ports Used:** 8080 (HTTP), 6006 (DAP), 6005 (LSP)

#### Why Deprecated:
1. **Complexity:** DAP/LSP protocols are complex and harder to integrate
2. **Security:** Lacked built-in authentication and rate limiting
3. **Performance:** No binary protocol or compression
4. **Maintenance:** Larger codebase with more dependencies
5. **AI Integration:** REST API is simpler for AI assistants to use

#### Retained For:
- Reference implementations of security patterns
- Reusable components (rate limiting, CSRF tokens, token management)
- Historical debugging and troubleshooting
- Example protocol implementations

## Configuration Status

### project.godot - Autoload Configuration

**Active (Enabled):**
```ini
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
```

**Deprecated (Disabled):**
```ini
[autoload]

#GodotBridge="*res://addons/godot_debug_connection/godot_bridge.gd"          # DISABLED - Use HttpApiServer instead
#TelemetryServer="*res://addons/godot_debug_connection/telemetry_server.gd"  # DISABLED
```

### project.godot - Plugin Configuration

**Current State:**
```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/godot_debug_connection/plugin.cfg", "res://addons/godottpd/plugin.cfg", "res://addons/gdUnit4/plugin.cfg")
```

**Explanation:**
- The `godot_debug_connection` plugin remains enabled for reference code access
- It is NOT used for runtime API operations (GodotBridge autoload is disabled)
- Only the HttpApiServer (port 8080) provides runtime API functionality
- godottpd plugin is enabled as it powers HttpApiServer

## API Port Reference

| Service | Port | Protocol | Status | Purpose |
|---------|------|----------|--------|---------|
| **Python Server** | 8090 | HTTP | Active | AI agent interface, process management |
| **HttpApiServer (Active)** | 8080 | HTTP | Active | Production REST API |
| **Telemetry Streaming** | 8081 | WebSocket | Active | Real-time performance data |
| **Service Discovery** | 8087 | UDP | Active | Network service announcement |
| **GodotBridge (Legacy)** | 8081 | HTTP | Disabled | Deprecated - DO NOT USE |
| **DAP (Legacy)** | 6006 | TCP | Disabled | Deprecated debug protocol |
| **LSP (Legacy)** | 6005 | TCP | Disabled | Deprecated language server |

## Migration Instructions

### For Existing Code

If your code references the old GodotBridge API:

**Old (Port 8080):**
```bash
# Status check
curl http://localhost:8080/status

# Debug operation
curl -X POST http://localhost:8080/debug/breakpoint

# File editing
curl -X PUT http://localhost:8080/edit/apply_changes
```

**New (Port 8080):**
```bash
# Status check (with authentication)
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8080/status

# Scene loading
curl -X POST http://localhost:8080/scene -H "Authorization: Bearer <TOKEN>" -d '{"path": "res://vr_main.tscn"}'

# Scene hot-reload
curl -X POST http://localhost:8080/scene/reload -H "Authorization: Bearer <TOKEN>"
```

### For New Development

**Always use HttpApiServer (port 8080):**
1. Use HTTP REST API endpoints instead of DAP/LSP
2. Include JWT authentication token in all requests
3. Handle rate limiting (429 status code)
4. Use batch operations for multiple requests
5. Monitor via WebSocket telemetry (port 8081) for real-time feedback

### Getting Authentication Token

The HttpApiServer prints the JWT token at startup:

```
[HttpApiServer] API TOKEN: <TOKEN_HERE>
[HttpApiServer] Use: curl -H 'Authorization: Bearer <TOKEN>' ...
```

Example usage:
```bash
TOKEN="<TOKEN_FROM_STARTUP>"
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status
```

## Endpoint Mapping

### Common Operations

#### Get System Status

**Old (Deprecated):**
```bash
curl http://localhost:8080/status
```

**New (Active):**
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status
```

#### Load a Scene

**Old (Not available with REST):**
```bash
# Handled via DAP protocol
```

**New (Active):**
```bash
curl -X POST http://localhost:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path": "res://vr_main.tscn"}'
```

#### Hot-Reload Current Scene

**Old (Not available with REST):**
```bash
# Handled via DAP protocol
```

**New (Active):**
```bash
curl -X POST http://localhost:8080/scene/reload \
  -H "Authorization: Bearer $TOKEN"
```

#### List Available Scenes

**Old (Not available):**
```bash
# Not supported
```

**New (Active):**
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/scenes
```

#### Get Scene Loading History

**Old (Not available):**
```bash
# Not supported
```

**New (Active):**
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/scene/history
```

## Troubleshooting

### Port 8080 Not Responding (Expected)

**Issue:** `curl http://localhost:8080/status` returns "Connection refused"

**Cause:** GodotBridge is disabled in autoload (intentional deprecation)

**Solution:** Use port 8080 instead
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status
```

### Port 8080 Not Responding

**Issue:** `curl http://localhost:8080/status` returns "Connection refused"

**Cause:** Godot may not be running, or not in GUI mode

**Solution:**
1. Check Godot is running: `ps aux | grep Godot`
2. Verify GUI mode (not headless): Check Godot startup logs
3. Check port isn't blocked: `lsof -i :8080`
4. Start Godot properly: `godot --path "C:/godot" --editor`

### Authentication Token Missing

**Issue:** `curl http://localhost:8080/status` returns 401 Unauthorized

**Cause:** Missing or invalid JWT token

**Solution:**
1. Get token from Godot startup logs: Look for "API TOKEN:"
2. Include in requests: `-H "Authorization: Bearer <TOKEN>"`
3. Or extract from logs programmatically

### Rate Limiting

**Issue:** Repeated requests return 429 Too Many Requests

**Cause:** Default rate limiting is 100 requests per minute

**Solution:**
1. Space out requests over time
2. Use batch operations for multiple actions
3. Implement exponential backoff retry logic

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
│  (Python Scripts, AI Agents, External Tools)                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ HTTP Requests with JWT Token
                 │
┌────────────────▼────────────────────────────────────────────┐
│                   Python Server (8090)                      │
│  - Process Management                                       │
│  - Health Monitoring                                        │
│  - Scene Loading                                            │
│  - Proxies to Godot HTTP API                               │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Proxy → HTTP
                 │
┌────────────────▼────────────────────────────────────────────┐
│              Godot Engine Instance                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │        HttpApiServer (Port 8080) - ACTIVE          │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  Router Components                            │ │  │
│  │  │  - SceneRouter (/scene/*)                     │ │  │
│  │  │  - ScenesListRouter (/scenes)                 │ │  │
│  │  │  - JobRouter (/jobs/*)                        │ │  │
│  │  │  - AdminRouter (/admin/*)                     │ │  │
│  │  │  - WebhookRouter (/webhooks/*)                │ │  │
│  │  │  - PerformanceRouter (/performance/*)         │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  Security Layer                               │ │  │
│  │  │  - JWT Authentication                         │ │  │
│  │  │  - Rate Limiting                              │ │  │
│  │  │  - Input Validation                           │ │  │
│  │  │  - Audit Logging                              │ │  │
│  │  │  - RBAC                                        │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │        ResonanceEngine (Core Coordinator)           │  │
│  │  - Manages all game subsystems                      │  │
│  │  - Initializes in strict dependency order          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Legacy: GodotBridge (Port 8080) - DEPRECATED      │  │
│  │  - Disabled in autoload                             │  │
│  │  - Retained for reference only                      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────┘
                 │
         ┌───────┼───────┐
         │       │       │
    ┌────▼───┐ ┌─▼────┐ ┌▼─────────┐
    │Telemetry │Discovery │Scenes
    │(8081)   │(8087)   │etc.
    └─────────┘ └────────┘ └──────────┘
```

## References

- **Primary:** `/scripts/http_api/http_api_server.gd` - Active HTTP API server
- **Configuration:** `/project.godot` - Lines 18-26 (autoload), 40 (plugins)
- **Documentation:** `/CLAUDE.md` - Complete architecture overview
- **Legacy Reference:** `/addons/godot_debug_connection/` - Deprecated addon (reference only)

## Summary

| Aspect | Old (GodotBridge) | New (HttpApiServer) |
|--------|------|------|
| **Port** | 8080 | 8080 |
| **Protocol** | DAP/LSP + HTTP | REST HTTP |
| **Auth** | Token (weak) | JWT tokens |
| **Rate Limit** | No | Yes (100/min default) |
| **RBAC** | No | Yes |
| **Audit Log** | No | Yes |
| **Performance** | Standard | Binary + GZIP |
| **Status** | DISABLED | ACTIVE |
| **For New Dev** | NO | YES |

**ACTION:** Use port 8080 (HttpApiServer) for all new API integrations and existing code using port 8080.
