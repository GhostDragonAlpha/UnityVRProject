# Runtime Debug Features - Available Now

This document describes all debug and monitoring features available while the game is running (runtime mode), without needing the Godot Editor.

## ✅ Currently Working Features

### 1. HTTP REST API (Port 8080)

The GodotBridge HTTP server provides real-time control and monitoring.

**Base URL**: `http://127.0.0.1:8080`

#### Connection Management
```bash
# Check system status
curl http://127.0.0.1:8080/status

# Initiate debug connections (attempts DAP/LSP connection)
curl -X POST http://127.0.0.1:8080/connect

# Disconnect services
curl -X POST http://127.0.0.1:8080/disconnect
```

#### Resonance System Control
```bash
# Apply interference to game objects at runtime
curl -X POST http://127.0.0.1:8080/resonance/apply_interference \
  -H "Content-Type: application/json" \
  -d '{
    "object_frequency": 440.0,
    "object_amplitude": 1.0,
    "emit_frequency": 440.0,
    "interference_type": "constructive"
  }'

# Response includes:
# - frequency_match (how well frequencies align)
# - amplitude_change (calculated change)
# - final_amplitude (resulting amplitude)
# - was_cancelled (if destructive interference cancelled the object)
```

### 2. WebSocket Telemetry Server (Port 8081)

Real-time event streaming for monitoring game state.

**URL**: `ws://127.0.0.1:8081`

**Features**:
- Binary telemetry packets (FPS, performance metrics)
- Compressed JSON for large payloads
- Multi-client support (broadcast to all connected)
- Heartbeat mechanism (30s ping, 60s timeout)

**Event Types**:
- System events (startup, shutdown, errors)
- Performance metrics (FPS, frame time)
- VR events (headset tracking, controller input)
- Game state changes
- Custom game events

**Python Client Example**:
```python
import asyncio
import websockets
import json

async def monitor_telemetry():
    uri = "ws://127.0.0.1:8081"
    async with websockets.connect(uri) as websocket:
        async for message in websocket:
            data = json.loads(message)
            print(f"Event: {data['event']} at {data['timestamp']}")
            print(f"Data: {data['data']}")

asyncio.run(monitor_telemetry())
```

### 3. Service Discovery (Port 8087 UDP)

Broadcasts service availability for automatic discovery.

**Broadcast Format**:
```json
{
  "service": "GodotBridge",
  "http_port": 8081,
  "telemetry_port": 8081,
  "version": "1.0"
}
```

### 4. Real-Time Game State Monitoring

Monitor all game systems through telemetry:

- **ResonanceEngine**: All subsystems status
- **VRManager**: Headset tracking, controller state
- **PhysicsEngine**: Physics calculations, collisions
- **RenderingSystem**: FPS, render quality, MSAA settings
- **PerformanceOptimizer**: Automatic quality adjustments
- **HapticManager**: Controller vibration feedback
- **TimeManager**: Time dilation, physics timestep
- **FloatingOriginSystem**: Large-scale coordinate management

### 5. Runtime Metrics

Available through telemetry stream:

```json
{
  "event": "performance_update",
  "timestamp": 1234567890.0,
  "data": {
    "fps": 89.5,
    "frame_time_ms": 11.2,
    "render_quality": "MEDIUM",
    "msaa": 2,
    "vr_active": true,
    "headset_tracking": true,
    "controllers_connected": 2
  }
}
```

## ⚠️ Editor-Only Features (Not Available at Runtime)

These require Godot Editor to be open:

- **Debug Adapter Protocol (DAP)** - Port 6006
  - Breakpoints
  - Step debugging
  - Variable inspection
  - Call stack analysis

- **Language Server Protocol (LSP)** - Port 6005
  - Code completion
  - Symbol definitions
  - Find references
  - Code intelligence

## 🎯 Practical Use Cases

### 1. AI-Assisted Gameplay Monitoring
Monitor game state in real-time and make decisions:
```python
# Connect to telemetry and watch for low FPS
if fps < 30:
    # Request quality reduction via HTTP API
    requests.post("http://127.0.0.1:8080/resonance/...", ...)
```

### 2. Automated Testing
Drive game behavior through HTTP API:
```python
# Apply resonance interference patterns
# Monitor results through telemetry
# Verify expected behavior
```

### 3. Performance Profiling
Stream telemetry data to external analysis tools:
- Track FPS over time
- Monitor render quality adjustments
- Analyze VR tracking issues

### 4. Remote Control
Control game systems remotely:
- Trigger specific gameplay mechanics
- Adjust system parameters
- Monitor responses in real-time

## 📊 Current System Status

```bash
# Quick health check
curl -s http://127.0.0.1:8080/status | python -m json.tool
```

**Services Running**:
- ✅ HTTP API: http://127.0.0.1:8081
- ✅ Telemetry: ws://127.0.0.1:8081
- ✅ Service Discovery: UDP broadcast on 8087
- ✅ All game systems operational
- ⚠️ DAP/LSP: Editor-only (not available in runtime mode)

## 🔧 Integration Examples

### Python Integration
See `examples/python_ai_client.py` for full AI integration example.

### cURL Examples
```bash
# Monitor system health
watch -n 1 'curl -s http://127.0.0.1:8080/status'

# Test resonance system
curl -X POST http://127.0.0.1:8080/resonance/apply_interference \
  -H "Content-Type: application/json" \
  -d '{"object_frequency": 440.0, "object_amplitude": 1.0, "emit_frequency": 220.0, "interference_type": "destructive"}'
```

## 📝 Notes

- All HTTP endpoints respond with JSON
- Telemetry uses WebSocket protocol
- Service discovery broadcasts every 5 seconds
- HTTP API has automatic port fallback (8081 → 8083 → 8084 → 8085)
- Telemetry supports multiple simultaneous clients
- All services are localhost-only for security

## 🚀 Next Steps

1. **Test Telemetry**: Run `python telemetry_client.py` to see live game events
2. **Monitor Performance**: Watch FPS and quality adjustments in real-time
3. **Control Game**: Use HTTP API to trigger gameplay mechanics
4. **Build Tools**: Create custom monitoring/control applications

## 🐛 Known Limitations

- Code reloading requires debug adapter (editor-only)
- Breakpoint debugging requires editor
- Code intelligence features require editor
- Some endpoints may require game restart to pick up code changes
