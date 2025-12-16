# API Endpoints - Quick Reference

**SpaceTime HTTP Scene Management API**
**Version:** 2.5.0
**Base URL:** `http://localhost:8080` (production: `https://spacetime-api.company.com`)

---

## Connection Management

### GET /status
**Purpose:** Get system health status

**Request:**
```bash
curl http://localhost:8080/status
```

**Response:**
```json
{
  "debug_adapter": {
    "service_name": "Debug Adapter",
    "port": 6006,
    "state": 2,
    "retry_count": 0,
    "last_activity": 1733139610.0
  },
  "language_server": {
    "service_name": "Language Server",
    "port": 6005,
    "state": 2,
    "retry_count": 0,
    "last_activity": 1733139610.0
  },
  "overall_ready": true
}
```

**States:** 0=Disconnected, 1=Connecting, 2=Connected, 3=Error

---

### POST /connect
**Purpose:** Initialize DAP and LSP connections

**Request:**
```bash
curl -X POST http://localhost:8080/connect
```

**Response:**
```json
{
  "status": "connecting",
  "message": "Connection initiated"
}
```

---

### POST /disconnect
**Purpose:** Close DAP and LSP connections

**Request:**
```bash
curl -X POST http://localhost:8080/disconnect
```

**Response:**
```json
{
  "status": "disconnected",
  "message": "Disconnection complete"
}
```

---

## Debug Adapter Protocol (DAP)

### POST /debug/launch
**Purpose:** Start debug session

**Request:**
```bash
curl -X POST http://localhost:8080/debug/launch \
  -H "Content-Type: application/json" \
  -d '{
    "program": "res://main.gd",
    "noDebug": false
  }'
```

---

### POST /debug/setBreakpoints
**Purpose:** Set breakpoints in code

**Request:**
```bash
curl -X POST http://localhost:8080/debug/setBreakpoints \
  -H "Content-Type: application/json" \
  -d '{
    "source": {"path": "res://scripts/player.gd"},
    "breakpoints": [{"line": 10}, {"line": 25}]
  }'
```

---

### POST /debug/continue
**Purpose:** Continue execution after breakpoint

**Request:**
```bash
curl -X POST http://localhost:8080/debug/continue \
  -H "Content-Type: application/json" \
  -d '{"threadId": 1}'
```

---

### POST /debug/evaluate
**Purpose:** Evaluate expression in current context

**Request:**
```bash
curl -X POST http://localhost:8080/debug/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "expression": "player.health",
    "frameId": 0,
    "context": "watch"
  }'
```

**Response:**
```json
{
  "status": "evaluated",
  "response": {
    "result": "100",
    "type": "int"
  }
}
```

---

## Language Server Protocol (LSP)

### POST /lsp/completion
**Purpose:** Get code completions

**Request:**
```bash
curl -X POST http://localhost:8080/lsp/completion \
  -H "Content-Type: application/json" \
  -d '{
    "textDocument": {"uri": "file:///path/to/file.gd"},
    "position": {"line": 10, "character": 5}
  }'
```

---

### POST /lsp/definition
**Purpose:** Go to symbol definition

**Request:**
```bash
curl -X POST http://localhost:8080/lsp/definition \
  -H "Content-Type: application/json" \
  -d '{
    "textDocument": {"uri": "file:///path/to/file.gd"},
    "position": {"line": 10, "character": 5}
  }'
```

---

### POST /lsp/hover
**Purpose:** Get hover information

**Request:**
```bash
curl -X POST http://localhost:8080/lsp/hover \
  -H "Content-Type: application/json" \
  -d '{
    "textDocument": {"uri": "file:///path/to/file.gd"},
    "position": {"line": 10, "character": 5}
  }'
```

---

## Scene Management

### POST /scene/load
**Purpose:** Load a Godot scene

**Request:**
```bash
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**Response:**
```json
{
  "status": "success",
  "message": "Scene loaded",
  "scene_path": "res://vr_main.tscn"
}
```

---

## Resonance System

### POST /resonance/apply_interference
**Purpose:** Apply wave interference

**Request:**
```bash
curl -X POST http://localhost:8080/resonance/apply_interference \
  -H "Content-Type: application/json" \
  -d '{
    "object_frequency": 440.0,
    "object_amplitude": 1.0,
    "emit_frequency": 442.0,
    "interference_type": "destructive",
    "delta_time": 0.1
  }'
```

**Response:**
```json
{
  "status": "success",
  "object_frequency": 440.0,
  "emit_frequency": 442.0,
  "frequency_match": 0.95,
  "initial_amplitude": 1.0,
  "final_amplitude": 0.5,
  "amplitude_change": -0.5,
  "interference_type": "destructive",
  "was_cancelled": false
}
```

---

## Code Execution

### POST /execute/reload
**Purpose:** Hot-reload code changes

**Request:**
```bash
curl -X POST http://localhost:8080/execute/reload \
  -H "Content-Type: application/json" \
  -d '{"noDebug": false}'
```

**Response:**
```json
{
  "status": "reloaded",
  "message": "Hot-reload triggered successfully"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Bad Request",
  "message": "Missing required parameter: program",
  "status_code": 400
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Endpoint not found: /unknown",
  "status_code": 404
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "Launch failed",
  "status_code": 500
}
```

### 503 Service Unavailable
```json
{
  "error": "Service Unavailable",
  "message": "Debug adapter not connected",
  "status_code": 503
}
```

---

## WebSocket Telemetry

**URL:** `ws://localhost:8081`

### Connection
```javascript
const ws = new WebSocket('ws://localhost:8081');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log(data);
};
```

### Events

**FPS Event:**
```json
{
  "type": "event",
  "event": "fps",
  "data": {
    "fps": 90.0,
    "frame_time_ms": 11.1,
    "physics_time_ms": 2.5
  },
  "timestamp": 1733139610
}
```

**VR Tracking Event:**
```json
{
  "type": "event",
  "event": "vr_tracking",
  "data": {
    "headset": {"x": 0, "y": 1.5, "z": 0},
    "left_controller": {"x": -0.3, "y": 1.2, "z": -0.5},
    "right_controller": {"x": 0.3, "y": 1.2, "z": -0.5}
  },
  "timestamp": 1733139610
}
```

**Error Event:**
```json
{
  "type": "event",
  "event": "error",
  "data": {
    "message": "Scene load failed",
    "details": "File not found"
  },
  "timestamp": 1733139610
}
```

### Commands

**Get Snapshot:**
```json
{"command": "get_snapshot"}
```

**Ping:**
```json
{"command": "ping"}
```

**Configure:**
```json
{
  "command": "configure",
  "config": {
    "fps_enabled": true,
    "fps_interval": 1.0,
    "vr_tracking_enabled": true,
    "tracking_interval": 0.1
  }
}
```

---

## Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| /status | 100 req/min | Per IP |
| /connect | 10 req/min | Per IP |
| /debug/* | 50 req/min | Per IP |
| /lsp/* | 50 req/min | Per IP |
| /scene/* | 20 req/min | Per IP |

**Rate Limit Response:**
```json
{
  "error": "Rate Limit Exceeded",
  "message": "Too many requests",
  "retry_after": 60,
  "status_code": 429
}
```

---

## Quick Testing Script

```bash
#!/bin/bash
# API quick test script

BASE_URL="http://localhost:8080"

echo "=== Testing SpaceTime API ==="

# 1. Health check
echo "1. Health check..."
curl -s $BASE_URL/status | jq -r 'if .overall_ready then "✓ READY" else "✗ NOT READY" end'

# 2. Connect
echo "2. Connecting services..."
curl -s -X POST $BASE_URL/connect | jq -r '.status'

# Wait for connection
sleep 2

# 3. Verify connection
echo "3. Verifying connection..."
curl -s $BASE_URL/status | jq '{dap: .debug_adapter.state, lsp: .language_server.state}'

# 4. Test scene load
echo "4. Testing scene load..."
curl -s -X POST $BASE_URL/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}' | jq -r '.status'

echo "=== Test Complete ==="
```

---

## Common Issues

**Issue:** "Service Unavailable"
**Cause:** DAP/LSP not connected
**Solution:** Call `/connect` endpoint first

**Issue:** "Timeout"
**Cause:** Operation taking too long
**Solution:** Increase timeout or optimize operation

**Issue:** "Invalid JSON"
**Cause:** Malformed request body
**Solution:** Validate JSON with `jq` before sending

**Issue:** "404 Not Found"
**Cause:** Wrong endpoint path
**Solution:** Check endpoint spelling and method (GET vs POST)

---

## Additional Resources

- **Full API Documentation:** `addons/godot_debug_connection/HTTP_API.md`
- **DAP Commands:** `addons/godot_debug_connection/DAP_COMMANDS.md`
- **LSP Methods:** `addons/godot_debug_connection/LSP_METHODS.md`
- **Examples:** `addons/godot_debug_connection/EXAMPLES.md`
