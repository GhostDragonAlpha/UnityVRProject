# SpaceTime VR - Complete API Reference

**Version:** 2.6.0
**Last Updated:** 2025-12-04
**Environment:** Production-Ready (98%)
**Active Routers:** 9/12 (Phase 1-2 Complete)

This document provides comprehensive API documentation for all public interfaces in the SpaceTime VR project, including HTTP REST APIs, WebSocket telemetry, multiplayer RPC interfaces, database schemas, and cache structures.

## Table of Contents

1. [Active Router Status](#active-router-status)
2. [HTTP REST API](#http-rest-api)
3. [WebSocket Telemetry API](#websocket-telemetry-api)
4. [Multiplayer RPC Interface](#multiplayer-rpc-interface)
5. [Database Schema](#database-schema)
6. [Redis Cache Structure](#redis-cache-structure)
7. [Authentication](#authentication)
8. [Error Handling](#error-handling)
9. [Rate Limiting](#rate-limiting)
10. [API Versioning](#api-versioning)

---

## Active Router Status

### Current Implementation (Version 2.6.0)

**Production Readiness:** 98%
**Last Updated:** 2025-12-04
**Implementation:** `scripts/http_api/http_api_server.gd`

### Phase 1: Scene Management (4 Routers) ✅ ACTIVE

| Router | Endpoint | Methods | Purpose | Status |
|--------|----------|---------|---------|--------|
| **SceneHistoryRouter** | `/scene/history` | GET | Track last 10 scene loads | ✅ Active |
| **SceneReloadRouter** | `/scene/reload` | POST | Hot-reload current scene | ✅ Active |
| **SceneRouter** | `/scene` | POST, GET, PUT | Load, query, validate scenes | ✅ Active |
| **ScenesListRouter** | `/scenes` | GET | List available scenes | ✅ Active |

### Phase 2: Advanced Features (5 Routers) ✅ ACTIVE

| Router | Endpoint | Methods | Purpose | Status |
|--------|----------|---------|---------|--------|
| **PerformanceRouter** | `/performance` | GET | System performance metrics | ✅ Active |
| **WebhookRouter** | `/webhooks` | POST, GET | Register and list webhooks | ✅ Active |
| **WebhookDetailRouter** | `/webhooks/:id` | GET, PUT, DELETE | Individual webhook management | ✅ Active |
| **JobRouter** | `/jobs` | POST, GET | Submit and list background jobs | ✅ Active |
| **JobDetailRouter** | `/jobs/:id` | GET, DELETE | Individual job status and cancellation | ✅ Active |

### Phase 3+: Future Routers (3 Routers) ⚠️ DISABLED

| Router | Endpoint | Methods | Purpose | Status |
|--------|----------|---------|---------|--------|
| **BatchOperationsRouter** | `/batch` | POST | Batch scene operations | ⚠️ Planned |
| **AdminRouter** | `/admin/*` | Various | Administrative endpoints | ⚠️ Planned |
| **AuthRouter** | `/auth/*` | Various | Token lifecycle management | ⚠️ Planned |

### Router Registration Order

**Critical:** Routers must be registered in this order (godottpd uses prefix matching):

1. Specific routes BEFORE generic routes
2. Detail routes (`:id`) BEFORE collection routes
3. Example: `/webhooks/:id` BEFORE `/webhooks`

**Implementation:** See `scripts/http_api/http_api_server.gd` lines 206-258

### Authentication

All active routers require JWT Bearer token authentication:

```bash
Authorization: Bearer <api_token>
```

**Token Generation:** Auto-generated on startup and printed to console.

**Example:**
```bash
TOKEN="eyJhbGc..."  # From console output
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/scenes
```

### Rate Limiting

All active routers enforce rate limiting:
- **General endpoints:** 100 requests per minute per IP
- **Write operations:** 10 requests per minute per IP
- **Batch operations:** 50 operations max, 10 requests per minute

**Rate Limit Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1733145060
```

---

## HTTP REST API

### Base URL

```
Production:  https://spacetime.example.com/api/v2
Staging:     https://staging.spacetime.example.com/api/v2
Development: http://localhost:8080
```

### Authentication

All API requests require Bearer token authentication:

```bash
Authorization: Bearer <api_token>
```

See [Authentication](#authentication) section for details.

### Connection Management

#### POST /connect

Initiate connections to DAP and LSP services.

**Request:**
```json
{}
```

**Response:**
```json
{
  "status": "connecting",
  "message": "Connection initiated",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Status Codes:**
- `200 OK` - Connection initiated
- `401 Unauthorized` - Invalid token
- `503 Service Unavailable` - Services not available

#### POST /disconnect

Gracefully disconnect from all services.

**Request:**
```json
{}
```

**Response:**
```json
{
  "status": "disconnected",
  "message": "Disconnection complete",
  "timestamp": "2025-12-02T10:35:00Z"
}
```

#### GET /status

Get current system status and health.

**Response:**
```json
{
  "debug_adapter": {
    "service_name": "Debug Adapter",
    "port": 6006,
    "state": 2,
    "retry_count": 0,
    "last_activity": 1733145000.0,
    "healthy": true
  },
  "language_server": {
    "service_name": "Language Server",
    "port": 6005,
    "state": 2,
    "retry_count": 0,
    "last_activity": 1733145000.0,
    "healthy": true
  },
  "godot": {
    "version": "4.5.1",
    "uptime_seconds": 3600,
    "fps": 90.0,
    "memory_mb": 2048
  },
  "overall_ready": true,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Status Codes:**
- `200 OK` - Status retrieved
- `401 Unauthorized` - Invalid token

### Health Check

#### GET /health

Health check endpoint for load balancers and monitoring.

**Response:**
```json
{
  "status": "healthy",
  "uptime": 3600,
  "checks": {
    "godot": "passing",
    "dap": "passing",
    "lsp": "passing",
    "telemetry": "passing"
  },
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Status Codes:**
- `200 OK` - System healthy
- `503 Service Unavailable` - System unhealthy

### Scene Management

#### POST /scene/load

Load a specific scene.

**Request:**
```json
{
  "scene_path": "res://scenes/vr_main.tscn"
}
```

**Response:**
```json
{
  "status": "success",
  "scene_path": "res://scenes/vr_main.tscn",
  "load_time_ms": 234,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Status Codes:**
- `200 OK` - Scene loaded
- `400 Bad Request` - Invalid scene path
- `404 Not Found` - Scene not found
- `500 Internal Server Error` - Load failed

#### GET /scene/current

Get information about the current scene.

**Response:**
```json
{
  "scene_path": "res://scenes/vr_main.tscn",
  "node_count": 156,
  "root_node": "VRMain",
  "loaded_at": "2025-12-02T10:25:00Z"
}
```

#### POST /scene/reload

Reload the current scene.

**Request:**
```json
{
  "preserve_state": true
}
```

**Response:**
```json
{
  "status": "success",
  "scene_path": "res://scenes/vr_main.tscn",
  "reload_time_ms": 189,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### GET /scene/history

Get scene navigation history.

**Response:**
```json
{
  "history": [
    {
      "scene_path": "res://scenes/vr_main.tscn",
      "loaded_at": "2025-12-02T10:25:00Z",
      "duration_seconds": 300
    },
    {
      "scene_path": "res://scenes/menu.tscn",
      "loaded_at": "2025-12-02T10:20:00Z",
      "duration_seconds": 300
    }
  ],
  "current_index": 0
}
```

#### POST /scene/validate

Validate scene integrity.

**Request:**
```json
{
  "scene_path": "res://scenes/vr_main.tscn"
}
```

**Response:**
```json
{
  "valid": true,
  "scene_path": "res://scenes/vr_main.tscn",
  "checks": {
    "file_exists": true,
    "parseable": true,
    "dependencies_met": true,
    "scripts_valid": true
  },
  "warnings": [],
  "errors": []
}
```

### Player Management

#### POST /player/spawn

Spawn a player in the world.

**Request:**
```json
{
  "position": {"x": 0, "y": 100, "z": 0},
  "rotation": {"x": 0, "y": 0, "z": 0},
  "player_id": "player_001",
  "mode": "spacecraft"
}
```

**Response:**
```json
{
  "status": "success",
  "player_id": "player_001",
  "position": {"x": 0, "y": 100, "z": 0},
  "mode": "spacecraft",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### GET /player/position

Get player position and state.

**Query Parameters:**
- `player_id` (optional) - Specific player ID

**Response:**
```json
{
  "player_id": "player_001",
  "position": {"x": 123.4, "y": 105.2, "z": 456.7},
  "rotation": {"x": 0, "y": 45, "z": 0},
  "velocity": {"x": 0, "y": 0, "z": 0},
  "mode": "spacecraft",
  "health": 100,
  "oxygen": 95.5,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /player/teleport

Teleport player to a new location.

**Request:**
```json
{
  "player_id": "player_001",
  "position": {"x": 500, "y": 100, "z": 500},
  "rotation": {"x": 0, "y": 90, "z": 0}
}
```

**Response:**
```json
{
  "status": "success",
  "player_id": "player_001",
  "new_position": {"x": 500, "y": 100, "z": 500},
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /player/mode

Change player mode (spacecraft/walking).

**Request:**
```json
{
  "player_id": "player_001",
  "mode": "walking"
}
```

**Response:**
```json
{
  "status": "success",
  "player_id": "player_001",
  "mode": "walking",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

### Terrain Manipulation

#### POST /terrain/deform

Deform terrain at a specific location.

**Request:**
```json
{
  "position": {"x": 100, "y": 50, "z": 100},
  "radius": 5.0,
  "strength": 2.0,
  "operation": "add"
}
```

**Response:**
```json
{
  "status": "success",
  "position": {"x": 100, "y": 50, "z": 100},
  "voxels_modified": 125,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Operation Types:**
- `add` - Add material
- `remove` - Remove material
- `smooth` - Smooth terrain

#### GET /terrain/info

Get terrain information at a location.

**Query Parameters:**
- `x`, `y`, `z` - Coordinates

**Response:**
```json
{
  "position": {"x": 100, "y": 50, "z": 100},
  "material": "rock",
  "density": 0.8,
  "temperature": 20.5,
  "biome": "plains"
}
```

#### POST /terrain/sync

Synchronize terrain changes across multiplayer.

**Request:**
```json
{
  "chunk_coords": {"x": 10, "y": 0, "z": 10},
  "force_sync": false
}
```

**Response:**
```json
{
  "status": "success",
  "chunk_coords": {"x": 10, "y": 0, "z": 10},
  "synced_to_clients": 5,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

### VR Tracking

#### GET /vr/tracking

Get VR headset and controller tracking data.

**Response:**
```json
{
  "headset": {
    "position": {"x": 0, "y": 1.7, "z": 0},
    "rotation": {"x": 0, "y": 0, "z": 0},
    "tracking_valid": true
  },
  "left_controller": {
    "position": {"x": -0.3, "y": 1.2, "z": -0.2},
    "rotation": {"x": 0, "y": 45, "z": 0},
    "tracking_valid": true,
    "buttons": {
      "trigger": false,
      "grip": false,
      "menu": false
    }
  },
  "right_controller": {
    "position": {"x": 0.3, "y": 1.2, "z": -0.2},
    "rotation": {"x": 0, "y": -45, "z": 0},
    "tracking_valid": true,
    "buttons": {
      "trigger": false,
      "grip": false,
      "menu": false
    }
  },
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /vr/recenter

Recenter VR tracking space.

**Request:**
```json
{}
```

**Response:**
```json
{
  "status": "success",
  "new_center": {"x": 0, "y": 0, "z": 0},
  "timestamp": "2025-12-02T10:30:00Z"
}
```

### Creature System

#### POST /creature/spawn

Spawn a creature.

**Request:**
```json
{
  "creature_type": "alien_predator",
  "position": {"x": 200, "y": 50, "z": 200},
  "level": 5
}
```

**Response:**
```json
{
  "status": "success",
  "creature_id": "creature_12345",
  "creature_type": "alien_predator",
  "position": {"x": 200, "y": 50, "z": 200},
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /creature/command

Send command to a tamed creature.

**Request:**
```json
{
  "creature_id": "creature_12345",
  "command": "follow",
  "target_player": "player_001"
}
```

**Response:**
```json
{
  "status": "success",
  "creature_id": "creature_12345",
  "command": "follow",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Commands:**
- `follow` - Follow player
- `stay` - Stay at location
- `aggressive` - Attack enemies
- `passive` - Ignore enemies
- `wander` - Wander freely

#### GET /creature/info

Get creature information.

**Query Parameters:**
- `creature_id` - Creature ID

**Response:**
```json
{
  "creature_id": "creature_12345",
  "creature_type": "alien_predator",
  "level": 5,
  "health": 100,
  "stamina": 85,
  "position": {"x": 205, "y": 50, "z": 198},
  "state": "following",
  "tamed": true,
  "owner": "player_001",
  "stats": {
    "damage": 25,
    "defense": 15,
    "speed": 8
  }
}
```

### Inventory System

#### GET /inventory/get

Get player inventory.

**Query Parameters:**
- `player_id` - Player ID

**Response:**
```json
{
  "player_id": "player_001",
  "slots": [
    {
      "slot": 0,
      "item_id": "iron_ore",
      "quantity": 50,
      "metadata": {}
    },
    {
      "slot": 1,
      "item_id": "energy_cell",
      "quantity": 10,
      "metadata": {"charge": 100}
    }
  ],
  "weight": 45.5,
  "max_weight": 100.0
}
```

#### POST /inventory/add

Add item to inventory.

**Request:**
```json
{
  "player_id": "player_001",
  "item_id": "iron_ore",
  "quantity": 10,
  "metadata": {}
}
```

**Response:**
```json
{
  "status": "success",
  "player_id": "player_001",
  "item_id": "iron_ore",
  "quantity_added": 10,
  "new_quantity": 60,
  "slot": 0
}
```

#### POST /inventory/remove

Remove item from inventory.

**Request:**
```json
{
  "player_id": "player_001",
  "item_id": "iron_ore",
  "quantity": 5
}
```

**Response:**
```json
{
  "status": "success",
  "player_id": "player_001",
  "item_id": "iron_ore",
  "quantity_removed": 5,
  "remaining_quantity": 55
}
```

### Base Building

#### POST /base/place

Place a building structure.

**Request:**
```json
{
  "player_id": "player_001",
  "structure_type": "solar_panel",
  "position": {"x": 100, "y": 50, "z": 100},
  "rotation": {"x": 0, "y": 90, "z": 0}
}
```

**Response:**
```json
{
  "status": "success",
  "structure_id": "structure_789",
  "structure_type": "solar_panel",
  "position": {"x": 100, "y": 50, "z": 100},
  "health": 100,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /base/remove

Remove a building structure.

**Request:**
```json
{
  "player_id": "player_001",
  "structure_id": "structure_789"
}
```

**Response:**
```json
{
  "status": "success",
  "structure_id": "structure_789",
  "resources_refunded": {
    "iron": 50,
    "silicon": 20
  },
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### GET /base/info

Get structure information.

**Query Parameters:**
- `structure_id` - Structure ID

**Response:**
```json
{
  "structure_id": "structure_789",
  "structure_type": "solar_panel",
  "owner": "player_001",
  "position": {"x": 100, "y": 50, "z": 100},
  "health": 100,
  "power_output": 50,
  "status": "active",
  "built_at": "2025-12-02T10:00:00Z"
}
```

### Power Grid

#### GET /power/status

Get power grid status.

**Query Parameters:**
- `player_id` - Player ID or base ID

**Response:**
```json
{
  "base_id": "base_001",
  "total_generation": 500,
  "total_consumption": 350,
  "battery_charge": 1000,
  "battery_capacity": 2000,
  "grid_healthy": true,
  "generators": [
    {
      "structure_id": "structure_789",
      "type": "solar_panel",
      "output": 50,
      "status": "active"
    }
  ],
  "consumers": [
    {
      "structure_id": "structure_790",
      "type": "fabricator",
      "consumption": 100,
      "status": "active"
    }
  ]
}
```

#### POST /power/toggle

Toggle power to a structure.

**Request:**
```json
{
  "structure_id": "structure_790",
  "enabled": false
}
```

**Response:**
```json
{
  "status": "success",
  "structure_id": "structure_790",
  "powered": false,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

### Debug Adapter (DAP)

#### POST /debug/launch

Launch a debug session.

**Request:**
```json
{
  "program": "res://vr_main.tscn",
  "noDebug": false,
  "stopOnEntry": false
}
```

**Response:**
```json
{
  "status": "launched",
  "session_id": "debug_session_001",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /debug/setBreakpoints

Set breakpoints in a file.

**Request:**
```json
{
  "source": {
    "path": "res://scripts/player/spacecraft.gd"
  },
  "breakpoints": [
    {"line": 10},
    {"line": 25}
  ]
}
```

**Response:**
```json
{
  "status": "breakpoints_set",
  "breakpoints": [
    {"id": 1, "line": 10, "verified": true},
    {"id": 2, "line": 25, "verified": true}
  ]
}
```

#### POST /debug/continue

Continue execution.

**Request:**
```json
{
  "threadId": 1
}
```

**Response:**
```json
{
  "status": "continued",
  "threadId": 1,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

#### POST /debug/evaluate

Evaluate an expression.

**Request:**
```json
{
  "expression": "player.health",
  "frameId": 0,
  "context": "watch"
}
```

**Response:**
```json
{
  "status": "evaluated",
  "result": "100",
  "type": "int",
  "variablesReference": 0
}
```

### Language Server (LSP)

#### POST /lsp/completion

Get code completions.

**Request:**
```json
{
  "textDocument": {
    "uri": "file:///C:/godot/scripts/player/spacecraft.gd"
  },
  "position": {
    "line": 10,
    "character": 5
  }
}
```

**Response:**
```json
{
  "status": "success",
  "items": [
    {
      "label": "health",
      "kind": 5,
      "detail": "int",
      "documentation": "Player health value"
    },
    {
      "label": "heal",
      "kind": 2,
      "detail": "func(amount: int) -> void",
      "documentation": "Heal player by amount"
    }
  ]
}
```

#### POST /lsp/definition

Go to definition.

**Request:**
```json
{
  "textDocument": {
    "uri": "file:///C:/godot/scripts/player/spacecraft.gd"
  },
  "position": {
    "line": 10,
    "character": 5
  }
}
```

**Response:**
```json
{
  "status": "success",
  "uri": "file:///C:/godot/scripts/player/player_base.gd",
  "range": {
    "start": {"line": 25, "character": 4},
    "end": {"line": 25, "character": 10}
  }
}
```

### Metrics and Monitoring

#### GET /metrics

Prometheus metrics endpoint.

**Response:** (Prometheus format)
```
# HELP godot_fps Current frames per second
# TYPE godot_fps gauge
godot_fps 90.0

# HELP godot_memory_bytes Memory usage in bytes
# TYPE godot_memory_bytes gauge
godot_memory_bytes 2147483648

# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/status"} 1234
```

---

## WebSocket Telemetry API

### Connection

```
ws://localhost:8081
wss://spacetime.example.com/telemetry
```

### Authentication

Send token as first message after connection:

```json
{
  "type": "auth",
  "token": "your_api_token_here"
}
```

### Message Types

#### Client → Server

**Authenticate:**
```json
{
  "type": "auth",
  "token": "your_api_token_here"
}
```

**Subscribe to Events:**
```json
{
  "type": "subscribe",
  "events": ["fps", "vr_tracking", "player_position"]
}
```

**Unsubscribe:**
```json
{
  "type": "unsubscribe",
  "events": ["fps"]
}
```

**Request Snapshot:**
```json
{
  "type": "get_snapshot"
}
```

**Configure Telemetry:**
```json
{
  "type": "configure",
  "config": {
    "fps_enabled": true,
    "fps_interval": 1.0,
    "vr_tracking_enabled": true,
    "tracking_interval": 0.1
  }
}
```

**Ping:**
```json
{
  "type": "ping"
}
```

#### Server → Client

**Authentication Success:**
```json
{
  "type": "auth_success",
  "client_id": "client_12345",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Authentication Failed:**
```json
{
  "type": "auth_failed",
  "reason": "Invalid token",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**FPS Update:**
```json
{
  "type": "event",
  "event": "fps",
  "data": {
    "fps": 90.0,
    "frame_time_ms": 11.1,
    "physics_time_ms": 2.5,
    "render_time_ms": 8.6
  },
  "timestamp": "2025-12-02T10:30:00.000Z"
}
```

**VR Tracking Update:**
```json
{
  "type": "event",
  "event": "vr_tracking",
  "data": {
    "headset": {
      "position": {"x": 0, "y": 1.7, "z": 0},
      "rotation": {"x": 0, "y": 0, "z": 0}
    },
    "left_controller": {
      "position": {"x": -0.3, "y": 1.2, "z": -0.2},
      "rotation": {"x": 0, "y": 45, "z": 0}
    },
    "right_controller": {
      "position": {"x": 0.3, "y": 1.2, "z": -0.2},
      "rotation": {"x": 0, "y": -45, "z": 0}
    }
  },
  "timestamp": "2025-12-02T10:30:00.000Z"
}
```

**Player Position Update:**
```json
{
  "type": "event",
  "event": "player_position",
  "data": {
    "player_id": "player_001",
    "position": {"x": 123.4, "y": 105.2, "z": 456.7},
    "velocity": {"x": 1.5, "y": 0, "z": 2.3},
    "rotation": {"x": 0, "y": 45, "z": 0}
  },
  "timestamp": "2025-12-02T10:30:00.000Z"
}
```

**System Snapshot:**
```json
{
  "type": "snapshot",
  "data": {
    "fps": 90.0,
    "memory_mb": 2048,
    "player_count": 5,
    "scene": "res://scenes/vr_main.tscn",
    "vr_active": true
  },
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Pong:**
```json
{
  "type": "pong",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

**Error:**
```json
{
  "type": "error",
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

### Binary Protocol

For efficiency, FPS data can be sent as binary:

**Binary Packet Format:**
```
Byte 0: Type (0x01 = FPS packet)
Bytes 1-4: FPS (float32, little-endian)
Bytes 5-8: Frame time (float32, little-endian)
Bytes 9-12: Physics time (float32, little-endian)
Bytes 13-16: Render time (float32, little-endian)
```

### Event Types

Available telemetry events:
- `fps` - Frames per second and timing
- `vr_tracking` - VR headset and controller tracking
- `player_position` - Player position and velocity
- `scene_loaded` - Scene change events
- `error` - Error events
- `warning` - Warning events
- `terrain_modified` - Terrain modification events
- `creature_spawned` - Creature spawn events
- `structure_built` - Structure placement events
- `power_grid_update` - Power grid status changes

---

## Multiplayer RPC Interface

### Connection

Multiplayer uses Godot's High-Level Multiplayer API with ENet protocol.

**Server:** `spacetime.example.com:7777`

### Authentication

After connecting, call:

```gdscript
rpc_id(1, "authenticate", token)
```

### RPCs (Remote Procedure Calls)

#### Player Synchronization

**Broadcast Position:**
```gdscript
@rpc("any_peer", "unreliable")
func sync_player_position(player_id: String, position: Vector3, rotation: Vector3):
    # Called on all clients when a player moves
    pass
```

**Change Player Mode:**
```gdscript
@rpc("any_peer", "reliable")
func sync_player_mode(player_id: String, mode: String):
    # Called when player changes mode (spacecraft/walking)
    pass
```

#### Terrain Synchronization

**Sync Terrain Deformation:**
```gdscript
@rpc("any_peer", "reliable")
func sync_terrain_deform(position: Vector3, radius: float, strength: float, operation: String):
    # Called when terrain is modified
    pass
```

**Request Chunk:**
```gdscript
@rpc("any_peer", "reliable")
func request_terrain_chunk(chunk_coords: Vector3i):
    # Request terrain chunk data from server
    pass
```

**Send Chunk Data:**
```gdscript
@rpc("authority", "reliable")
func receive_terrain_chunk(chunk_coords: Vector3i, data: PackedByteArray):
    # Receive terrain chunk data from server
    pass
```

#### Structure Synchronization

**Place Structure:**
```gdscript
@rpc("any_peer", "reliable")
func sync_structure_place(structure_id: String, structure_type: String, position: Vector3, rotation: Vector3, owner_id: String):
    # Called when structure is placed
    pass
```

**Remove Structure:**
```gdscript
@rpc("any_peer", "reliable")
func sync_structure_remove(structure_id: String):
    # Called when structure is removed
    pass
```

**Update Structure State:**
```gdscript
@rpc("any_peer", "unreliable")
func sync_structure_state(structure_id: String, state: Dictionary):
    # Called when structure state changes (power, health, etc.)
    pass
```

#### Creature Synchronization

**Spawn Creature:**
```gdscript
@rpc("authority", "reliable")
func sync_creature_spawn(creature_id: String, creature_type: String, position: Vector3, level: int):
    # Server spawns creature on all clients
    pass
```

**Sync Creature Position:**
```gdscript
@rpc("authority", "unreliable")
func sync_creature_position(creature_id: String, position: Vector3, velocity: Vector3):
    # Server updates creature position
    pass
```

**Creature Command:**
```gdscript
@rpc("any_peer", "reliable")
func sync_creature_command(creature_id: String, command: String, parameters: Dictionary):
    # Player sends command to tamed creature
    pass
```

#### Authority Transfer

**Request Authority:**
```gdscript
@rpc("any_peer", "reliable")
func request_authority(object_id: String):
    # Request authority over an object
    pass
```

**Grant Authority:**
```gdscript
@rpc("authority", "reliable")
func grant_authority(object_id: String, peer_id: int):
    # Server grants authority to client
    pass
```

**Revoke Authority:**
```gdscript
@rpc("authority", "reliable")
func revoke_authority(object_id: String):
    # Server revokes authority from client
    pass
```

### Authority Zones

The server mesh divides the world into authority zones. Each zone is managed by a specific server instance.

**Zone Size:** 1000m x 1000m x 1000m

**Authority Transfer:** When player crosses zone boundary, authority is transferred to the new zone's server.

---

## Database Schema

### Technology

**Production:** PostgreSQL 14+
**Connection:** Managed via SQLAlchemy ORM

### Tables

#### users

Stores user account information.

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    api_tokens TEXT[], -- Array of active API tokens
    INDEX idx_username (username),
    INDEX idx_email (email)
);
```

#### worlds

Stores world/save file metadata.

```sql
CREATE TABLE worlds (
    id SERIAL PRIMARY KEY,
    world_name VARCHAR(100) NOT NULL,
    owner_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    seed BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_played TIMESTAMP,
    play_time_seconds INTEGER DEFAULT 0,
    difficulty VARCHAR(20) DEFAULT 'normal',
    world_data JSONB, -- Serialized world state
    INDEX idx_owner (owner_id),
    INDEX idx_last_played (last_played)
);
```

#### players

Stores player character data.

```sql
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    world_id INTEGER REFERENCES worlds(id) ON DELETE CASCADE,
    player_name VARCHAR(50) NOT NULL,
    position_x FLOAT NOT NULL,
    position_y FLOAT NOT NULL,
    position_z FLOAT NOT NULL,
    rotation_x FLOAT DEFAULT 0,
    rotation_y FLOAT DEFAULT 0,
    rotation_z FLOAT DEFAULT 0,
    health INTEGER DEFAULT 100,
    oxygen FLOAT DEFAULT 100,
    mode VARCHAR(20) DEFAULT 'spacecraft',
    inventory JSONB, -- Serialized inventory
    stats JSONB, -- Player stats
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, world_id),
    INDEX idx_world (world_id),
    INDEX idx_position (position_x, position_y, position_z)
);
```

#### structures

Stores placed structures.

```sql
CREATE TABLE structures (
    id SERIAL PRIMARY KEY,
    structure_id VARCHAR(50) UNIQUE NOT NULL,
    world_id INTEGER REFERENCES worlds(id) ON DELETE CASCADE,
    owner_id INTEGER REFERENCES users(id),
    structure_type VARCHAR(50) NOT NULL,
    position_x FLOAT NOT NULL,
    position_y FLOAT NOT NULL,
    position_z FLOAT NOT NULL,
    rotation_x FLOAT DEFAULT 0,
    rotation_y FLOAT DEFAULT 0,
    rotation_z FLOAT DEFAULT 0,
    health INTEGER DEFAULT 100,
    state JSONB, -- Structure state data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_world (world_id),
    INDEX idx_structure_id (structure_id),
    INDEX idx_position (world_id, position_x, position_y, position_z)
);
```

#### creatures

Stores creature instances.

```sql
CREATE TABLE creatures (
    id SERIAL PRIMARY KEY,
    creature_id VARCHAR(50) UNIQUE NOT NULL,
    world_id INTEGER REFERENCES worlds(id) ON DELETE CASCADE,
    creature_type VARCHAR(50) NOT NULL,
    position_x FLOAT NOT NULL,
    position_y FLOAT NOT NULL,
    position_z FLOAT NOT NULL,
    level INTEGER DEFAULT 1,
    health INTEGER DEFAULT 100,
    tamed BOOLEAN DEFAULT FALSE,
    owner_id INTEGER REFERENCES users(id),
    state JSONB, -- Creature state data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_world (world_id),
    INDEX idx_creature_id (creature_id),
    INDEX idx_position (world_id, position_x, position_y, position_z)
);
```

#### terrain_chunks

Stores modified terrain chunks.

```sql
CREATE TABLE terrain_chunks (
    id SERIAL PRIMARY KEY,
    world_id INTEGER REFERENCES worlds(id) ON DELETE CASCADE,
    chunk_x INTEGER NOT NULL,
    chunk_y INTEGER NOT NULL,
    chunk_z INTEGER NOT NULL,
    data BYTEA NOT NULL, -- Compressed voxel data
    checksum VARCHAR(64), -- SHA-256 checksum
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (world_id, chunk_x, chunk_y, chunk_z),
    INDEX idx_chunk (world_id, chunk_x, chunk_y, chunk_z)
);
```

#### metrics

Stores metrics and analytics.

```sql
CREATE TABLE metrics (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    labels JSONB, -- Additional labels
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metric (metric_name, timestamp),
    INDEX idx_timestamp (timestamp)
);
```

#### sessions

Stores user sessions.

```sql
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    last_activity TIMESTAMP,
    INDEX idx_token (session_token),
    INDEX idx_user (user_id),
    INDEX idx_expires (expires_at)
);
```

---

## Redis Cache Structure

### Technology

**Production:** Redis 7+
**Use Cases:** Session caching, rate limiting, real-time data

### Key Patterns

#### Session Cache

```
session:{session_token} -> {user_id, expires_at, ...}
TTL: Session expiration time
```

Example:
```redis
SET session:abc123xyz {
  "user_id": 42,
  "username": "player_001",
  "expires_at": "2025-12-03T10:30:00Z"
}
EXPIRE session:abc123xyz 86400
```

#### Rate Limiting

```
ratelimit:{ip_address}:{endpoint} -> request_count
TTL: 60 seconds (sliding window)
```

Example:
```redis
INCR ratelimit:192.168.1.100:/api/v2/player/spawn
EXPIRE ratelimit:192.168.1.100:/api/v2/player/spawn 60
```

#### Real-time Player Position

```
player:position:{player_id} -> {x, y, z, timestamp}
TTL: 300 seconds (auto-expire if inactive)
```

Example:
```redis
HSET player:position:player_001 x 123.4 y 105.2 z 456.7 timestamp 1733145000
EXPIRE player:position:player_001 300
```

#### Active Players List

```
active_players:{world_id} -> SET of player_ids
TTL: 600 seconds
```

Example:
```redis
SADD active_players:world_001 player_001 player_002 player_003
EXPIRE active_players:world_001 600
```

#### Server Health

```
server:health:{server_id} -> {status, last_heartbeat, ...}
TTL: 60 seconds
```

Example:
```redis
HSET server:health:server_01 status healthy last_heartbeat 1733145000 cpu 45.2 memory 2048
EXPIRE server:health:server_01 60
```

#### World State Cache

```
world:state:{world_id} -> {player_count, structures, ...}
TTL: 300 seconds
```

Example:
```redis
HSET world:state:world_001 player_count 5 structure_count 123 last_update 1733145000
EXPIRE world:state:world_001 300
```

#### Terrain Chunk Cache

```
terrain:chunk:{world_id}:{x}:{y}:{z} -> compressed_chunk_data
TTL: 1800 seconds (30 minutes)
```

Example:
```redis
SET terrain:chunk:world_001:10:0:10 <binary_data>
EXPIRE terrain:chunk:world_001:10:0:10 1800
```

#### Leaderboards

```
leaderboard:{world_id}:{metric} -> SORTED SET
No TTL (persistent)
```

Example:
```redis
ZADD leaderboard:world_001:play_time player_001 3600 player_002 7200 player_003 5400
```

---

## Authentication

### Bearer Token Authentication

All API requests require a Bearer token in the Authorization header:

```
Authorization: Bearer <api_token>
```

### Obtaining a Token

**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "username": "player_001",
  "password": "secure_password"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-12-03T10:30:00Z",
  "refresh_token": "refresh_abc123xyz"
}
```

### Token Refresh

**Endpoint:** `POST /auth/refresh`

**Request:**
```json
{
  "refresh_token": "refresh_abc123xyz"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-12-03T11:30:00Z"
}
```

### Token Revocation

**Endpoint:** `POST /auth/revoke`

**Request:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Token revoked"
}
```

### Token Structure

Tokens are JWT (JSON Web Tokens) with the following claims:

```json
{
  "sub": "user_42",
  "username": "player_001",
  "iat": 1733145000,
  "exp": 1733231400,
  "scopes": ["read", "write", "admin"]
}
```

### Scopes

- `read` - Read-only access to all endpoints
- `write` - Read and write access
- `admin` - Full administrative access
- `debug` - Access to debug endpoints

---

## Error Handling

### Standard Error Format

All errors follow this format:

```json
{
  "error": "ErrorType",
  "message": "Human-readable error message",
  "status_code": 400,
  "timestamp": "2025-12-02T10:30:00Z",
  "request_id": "req_12345abcde"
}
```

### HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created
- `204 No Content` - Success, no response body
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Authenticated but not authorized
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict (e.g., duplicate)
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Service temporarily unavailable

### Common Error Codes

| Code | Message | Status |
|------|---------|--------|
| `INVALID_TOKEN` | Authentication token is invalid | 401 |
| `TOKEN_EXPIRED` | Authentication token has expired | 401 |
| `MISSING_PARAMETER` | Required parameter is missing | 400 |
| `INVALID_PARAMETER` | Parameter value is invalid | 400 |
| `RESOURCE_NOT_FOUND` | Requested resource not found | 404 |
| `RATE_LIMIT_EXCEEDED` | Too many requests | 429 |
| `SERVICE_UNAVAILABLE` | Service is temporarily unavailable | 503 |
| `INTERNAL_ERROR` | Internal server error | 500 |

---

## Rate Limiting

### Limits

**Per IP Address:**
- 100 requests per minute (general endpoints)
- 10 requests per minute (write operations)
- 1 request per second (expensive operations)

**Per User:**
- 1000 requests per minute
- 100 write operations per minute

### Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1733145060
```

### Rate Limit Exceeded Response

```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Rate limit exceeded. Try again in 45 seconds.",
  "status_code": 429,
  "retry_after": 45,
  "timestamp": "2025-12-02T10:30:00Z"
}
```

---

## API Versioning

### Current Version

**Latest:** v2.5.0

### Version Selection

Include version in URL:
```
/api/v2/endpoint
```

Or use Accept header:
```
Accept: application/vnd.spacetime.v2+json
```

### Version Support

- **v2.x** - Current, fully supported
- **v1.x** - Deprecated, supported until 2026-01-01

### Breaking Changes

Breaking changes require a new major version. See [RELEASE_NOTES.md](../RELEASE_NOTES.md) for changelog.

---

## Additional Resources

- [HTTP API Usage Guide](../current/api/HTTP_API_USAGE_GUIDE.md)
- [WebSocket Telemetry Guide](../current/guides/TELEMETRY_GUIDE.md)
- [Authentication Guide](../current/security/API_TOKEN_GUIDE.md)
- [Deployment Guide](../current/guides/DEPLOYMENT_GUIDE.md)
- [Monitoring Guide](../MONITORING.md)

---

**Last Updated:** 2025-12-02
**Version:** 2.5.0
**Status:** Production-Ready
