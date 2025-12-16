# WebSocket Telemetry Guide

## Overview

The WebSocket telemetry system provides real-time streaming of VR and performance data from Godot to external clients (like AI assistants). It uses an efficient binary protocol with compression for high-frequency metrics and multi-client support.

## Quick Start

### 1. Start Godot with Python Server

```bash
python godot_editor_server.py --port 8090
```

The Python server automatically initializes the telemetry system on port 8081.

### 2. Install Dependencies

```bash
pip install websockets
```

### 3. Run the Telemetry Client

```bash
python telemetry_client.py
```

### 4. Launch Your VR App

The telemetry will automatically stream when the app is running and Godot is connected.

## What You Get

- **Real-time FPS**: Frame rate and timing data every 0.5s
- **VR Tracking**: Headset and controller positions every 0.1s
- **Events**: Scene changes, errors, warnings, custom game events
- **Snapshots**: On-demand system state
- **Performance**: Physics timings, memory usage, CPU load

## WebSocket Protocol Details

**Server**: `ws://127.0.0.1:8081`

### Binary Protocol Specification

The telemetry system uses an efficient binary protocol with two packet types:

#### Type 0x01: Binary FPS/Performance Telemetry (17 bytes)

Highly optimized for frequent FPS/performance updates:

```
Byte  0:    0x01 (packet type)
Bytes 1-4:  Frame number (uint32 BE)
Bytes 5-8:  FPS value (float32 BE)
Bytes 9-12: Frame time in ms (float32 BE)
Bytes 13-16: Physics time in ms (float32 BE)
```

Example parsing in Python:
```python
import struct
packet = recv_bytes(17)
frame_num, fps, frame_ms, phys_ms = struct.unpack(">I f f f", packet[1:])
```

#### Type 0x02: Compressed JSON Telemetry

For complex data payloads exceeding 1KB:

```
Byte  0:    0x02 (packet type)
Bytes 1-4:  Uncompressed length (uint32 BE)
Bytes 5-8:  Compressed length (uint32 BE)
Bytes 9+:   GZIP-compressed JSON payload
```

Decompression:
```python
import gzip, json
data = recv_bytes(9 + compressed_len)
json_data = json.loads(gzip.decompress(data[9:]))
```

### JSON Message Format

Standard JSON messages (for small payloads):

```json
{
  "type": "event",
  "event": "fps",
  "data": { "fps": 90, "frame_time_ms": 11.1, "physics_time_ms": 2.5 },
  "timestamp": 1234567890
}
```

### Event Types

**FPS and Performance:**
```json
{
  "type": "event",
  "event": "fps",
  "data": {
    "fps": 90.0,
    "frame_time_ms": 11.1,
    "physics_time_ms": 2.5,
    "memory_usage_mb": 256.3,
    "cpu_load": 0.45
  },
  "timestamp": 1234567890
}
```

**VR Tracking:**
```json
{
  "type": "event",
  "event": "vr_tracking",
  "data": {
    "headset": {
      "position": [0.0, 1.7, 0.0],
      "rotation": [0.0, 0.0, 0.0, 1.0]
    },
    "left_controller": {
      "position": [-0.5, 1.0, -0.5],
      "rotation": [0.0, 0.0, 0.0, 1.0],
      "buttons": {"trigger": 0.8, "grip": 0.0}
    },
    "right_controller": {
      "position": [0.5, 1.0, -0.5],
      "rotation": [0.0, 0.0, 0.0, 1.0],
      "buttons": {"trigger": 0.0, "grip": 0.0}
    }
  },
  "timestamp": 1234567890
}
```

**Custom Game Events:**
```json
{
  "type": "event",
  "event": "custom",
  "data": {
    "event_name": "player_teleported",
    "from": [0, 0, 0],
    "to": [10, 0, 0]
  },
  "timestamp": 1234567890
}
```

**System Alerts:**
```json
{
  "type": "alert",
  "level": "warning",
  "message": "FPS dropped below 80",
  "timestamp": 1234567890
}
```

### Commands You Can Send

```json
{"command": "get_snapshot"}
{"command": "ping"}
{"command": "configure", "config": {"fps_enabled": true, "vr_tracking_enabled": true}}
{"command": "set_update_interval", "interval": 0.1}
```

### Heartbeat Mechanism

- **Ping interval**: 30 seconds
- **Timeout**: 60 seconds (connection closed if no data received)
- **Keep-alive**: Server automatically sends pings

## Integration with AI

The telemetry server is perfect for AI-assisted development:

- Get instant feedback on code changes
- Monitor VR performance in real-time
- Detect physics anomalies
- Stream data for analysis and optimization

## Port Information

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Telemetry | 8081 | WebSocket | Real-time data streaming |
| HTTP API | 8081* | HTTP | Remote control and commands |
| DAP | 6006 | TCP | Debug Adapter Protocol |
| LSP | 6005 | TCP | Language Server Protocol |

*HTTP API has automatic fallback to ports 8083-8085

## Configuration

Adjust telemetry settings in your GDScript:

```gdscript
# Change update rates
TelemetryServer.fps_update_interval = 1.0  # Update FPS every second
TelemetryServer.tracking_update_interval = 0.05  # Update tracking 20x per second

# Disable specific streams
TelemetryServer.send_fps = false  # Disable FPS telemetry
TelemetryServer.send_vr_tracking = false  # Disable VR tracking

# Configure compression threshold
TelemetryServer.compression_threshold = 1024  # Compress payloads greater than 1KB
```

## Network Access

By default, telemetry is only accessible from localhost (127.0.0.1). To allow remote access:

1. Modify `addons/godot_debug_connection/telemetry_server.gd`:

   ```gdscript
   tcp_server.listen(PORT, "0.0.0.0")  # Listen on all interfaces
   ```

2. Configure your firewall to allow port 8081

3. Connect from remote machine:
   ```python
   await websockets.connect("ws://YOUR_IP:8081")
   ```

## Performance Characteristics

- **Binary FPS packets**: ~17 bytes per update
- **Compression ratio**: 3-5x for typical JSON payloads
- **Latency**: less than 50ms typically
- **Scalability**: Supports 10+ concurrent clients
- **CPU overhead**: less than 0.5% impact on Godot performance

## Custom Logging

Log custom events from your VR code:

```gdscript
# Log player actions
TelemetryServer.log_event("player_teleported", {
    "from": old_position,
    "to": new_position,
    "distance": old_position.distance_to(new_position)
})

# Log interactions
TelemetryServer.log_event("object_grabbed", {
    "object_id": object.get_instance_id(),
    "object_name": object.name,
    "controller": "left",
    "grip_strength": grip_value
})

# Log performance alerts
TelemetryServer.log_warning("Physics glitch detected", {
    "velocity": rigidbody.linear_velocity,
    "acceleration": rigidbody.linear_velocity - last_velocity
})

# Log errors
TelemetryServer.log_error("VR tracking lost", {
    "duration_ms": 150,
    "headset_position": tracking_data.headset_pos
})
```

## Troubleshooting

**No telemetry data:**
- Ensure Godot is running via Python server: `python godot_editor_server.py --port 8090`
- Check that telemetry_client.py is connected
- Verify port 8081 is not blocked

**Missing VR tracking:**
- Ensure VR is initialized in your scene
- Check that VR nodes are connected in vr_setup.gd
- Verify `send_vr_tracking` is enabled in TelemetryServer

**Compression errors:**
- Check available system memory for gzip operations
- Reduce `compression_threshold` if large payloads fail
- Monitor decompression exceptions on client side

**Connection drops:**
- Check network stability and firewall rules
- Increase timeout if network is slow
- Monitor heartbeat/ping messages (should see every 30s)

## Advanced: Real-time Analytics

Combine telemetry with Python analytics for performance monitoring and anomaly detection. See `telemetry_client.py` for complete reference implementation.
