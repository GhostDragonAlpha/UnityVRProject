# SpaceTime Health Monitoring Dashboard

A comprehensive real-time monitoring dashboard for debugging and production monitoring of SpaceTime game systems.

## Overview

The Health Dashboard provides a professional terminal-based UI for monitoring all aspects of the SpaceTime game in real-time. It connects to both the WebSocket telemetry server and HTTP API to provide complete visibility into system health, performance, and player state.

## Features

### 1. Real-Time Telemetry Display
- **FPS Metrics**: Current FPS, frame time, physics time, render time
- **Performance Monitoring**: Continuous updates at 10Hz (configurable)
- **Binary Protocol Support**: Efficient telemetry streaming with GZIP compression
- **Color-Coded Status**: Visual indicators for performance levels (green/yellow/red)

### 2. System Status Panel
- **Subsystem Monitoring**: Tracks all major game systems
  - ResonanceEngine
  - VRManager
  - TelemetryServer
  - PhysicsEngine
  - FloatingOriginSystem
  - AudioManager
- **Status Indicators**: Online/Offline/Degraded/Unknown states
- **Heartbeat Detection**: Automatic timeout detection for stale systems

### 3. Player Vitals
- **Oxygen Level**: Percentage with warning thresholds
- **Health**: Current player health percentage
- **Fuel**: Remaining fuel percentage
- **Position**: 3D coordinates in world space
- **Velocity**: Current speed in m/s

### 4. Network Statistics
- **WebSocket Metrics**: Messages received, messages/second
- **HTTP API**: Request latency tracking
- **Protocol Status**: DAP/LSP connection states
- **Latency**: Average round-trip time in milliseconds

### 5. Resource Monitoring
- **Memory Usage**: Current memory consumption (MB and %)
- **CPU Utilization**: Process CPU usage percentage
- **Entity Counts**: Total objects, nodes, chunks loaded
- **Real-Time Updates**: Pulled from Godot performance monitors

### 6. Alert System
- **Configurable Thresholds**: Customizable warning/critical levels
- **Alert Levels**: Critical (red), Warning (yellow), Info (blue)
- **Deduplication**: Prevents alert spam (5-second window)
- **History**: Maintains last 50 alerts with timestamps
- **Visual Priority**: Panel border color reflects highest alert level

### 7. Historical Graphs
- **FPS Graph**: ASCII graph showing FPS over last 60 seconds
- **Frame Time Trends**: Visual representation of performance
- **Sparkline Display**: Compact visualization in terminal
- **Configurable History**: Up to 5 minutes of data retention

## Installation

### Requirements

Python 3.8+ with the following packages:

```bash
pip install rich websockets requests psutil
```

### Quick Start (Windows)

Use the included launcher script:

```bash
start_dashboard.bat
```

This will automatically:
1. Check for Python installation
2. Install missing dependencies
3. Launch the dashboard

### Manual Start

```bash
python health_dashboard.py
```

## Usage

### Starting the Dashboard

1. **Start Godot with debug services** (required):
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

   Or use the quick restart script:
   ```bash
   ./restart_godot_with_debug.bat
   ```

2. **Launch the dashboard**:
   ```bash
   python health_dashboard.py
   # or
   start_dashboard.bat
   ```

3. **Wait for connection**: The dashboard will automatically connect to:
   - WebSocket telemetry server: `ws://127.0.0.1:8081`
   - HTTP API server: `http://127.0.0.1:8081`

### Keyboard Commands

| Key | Action |
|-----|--------|
| `q` | Quit the dashboard |
| `r` | Reset statistics (clear history and alerts) |
| `p` | Pause/unpause updates |
| `s` | Request snapshot from Godot |
| `a` | Toggle alerts panel visibility |
| `g` | Toggle graphs panel visibility |

## Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ SpaceTime Health Monitor - ● Connected to localhost:8080       │
│ Uptime: 5m 23s                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│ ┌─ Performance ──────┐  ┌─ System Status ────────────────────┐ │
│ │ FPS:         89.2   │  │ ResonanceEngine:      ● ONLINE     │ │
│ │ Frame Time:  11.2ms │  │ VRManager:            ● ONLINE     │ │
│ │ Physics Time: 2.1ms │  │ TelemetryServer:      ● ONLINE     │ │
│ │ Render Time:  8.1ms │  │ PhysicsEngine:        ● ONLINE     │ │
│ └────────────────────┘  │ FloatingOriginSystem: ● ONLINE     │ │
│                          │ AudioManager:         ● ONLINE     │ │
│ ┌─ Player Vitals ────┐  └────────────────────────────────────┘ │
│ │ Oxygen:      100%   │                                         │
│ │ Health:      100%   │  ┌─ Network ──────────────────────────┐ │
│ │ Fuel:        100%   │  │ WS Messages:     1250 (12.5/s)     │ │
│ │ Position: (10,0,10) │  │ Avg Latency:     2ms               │ │
│ │ Velocity:    0.0 m/s│  │ DAP:             ✓                 │ │
│ └────────────────────┘  │ LSP:             ✓                 │ │
│                          └────────────────────────────────────┘ │
│ ┌─ Resources ────────┐                                         │
│ │ Memory:    512MB    │  ┌─ FPS History (60s) ───────────────┐ │
│ │            (6.4%)   │  │ Current: 89.2                      │ │
│ │ CPU:       12.5%    │  │ █▇▇▆▆▅▅▄▄▃▃▃▄▄▅▅▆▇█               │ │
│ │ Chunks:    45       │  │                                    │ │
│ │ Entities:  128      │  └────────────────────────────────────┘ │
│ │ Nodes:     1024     │                                         │
│ └────────────────────┘                                         │
│                                                                   │
├─ Alerts (2 total) ──────────────────────────────────────────────┤
│ 5s ago   ⚠ Frame time elevated: 13.2ms                          │
│ 12s ago  ℹ Connected to telemetry server                        │
└─────────────────────────────────────────────────────────────────┘
```

## Health Thresholds

The dashboard uses configurable thresholds to generate alerts:

### FPS Thresholds
- **Warning**: FPS < 70 (yellow alert)
- **Critical**: FPS < 60 (red alert)

### Frame Time Thresholds
- **Warning**: Frame time > 13.0ms (< 75 FPS)
- **Critical**: Frame time > 16.6ms (< 60 FPS)

### Oxygen Thresholds
- **Warning**: Oxygen < 30%
- **Critical**: Oxygen < 20%

### Memory Thresholds
- **Warning**: Memory > 70% of system RAM
- **Critical**: Memory > 85% of system RAM

### System Heartbeat
- **Timeout**: 5 seconds without heartbeat = system offline

## Customization

### Modifying Thresholds

Edit the `HealthThresholds` class in `health_dashboard.py`:

```python
class HealthThresholds:
    """Configurable health thresholds for alerts."""
    FPS_WARNING = 70.0
    FPS_CRITICAL = 60.0
    OXYGEN_WARNING = 30.0
    OXYGEN_CRITICAL = 20.0
    MEMORY_WARNING = 70.0  # percent
    MEMORY_CRITICAL = 85.0  # percent
    FRAME_TIME_WARNING = 13.0  # ms
    FRAME_TIME_CRITICAL = 16.6  # ms
    SYSTEM_HEARTBEAT_TIMEOUT = 5.0  # seconds
```

### Adding Custom Systems

To monitor additional systems, add them to the `default_systems` list in `render_systems()`:

```python
default_systems = [
    "ResonanceEngine",
    "VRManager",
    "YourCustomSystem",  # Add here
    # ...
]
```

### Adjusting History Length

Modify the deque maxlen in `DashboardState`:

```python
fps_history: deque = field(default_factory=lambda: deque(maxlen=300))  # 5 min at 1Hz
frame_time_history: deque = field(default_factory=lambda: deque(maxlen=300))
```

## Technical Details

### Communication Protocols

#### WebSocket Telemetry (Port 8081)

The dashboard connects to Godot's telemetry server via WebSocket and handles:

1. **Binary Telemetry Packets** (Type 0x01):
   - 17-byte packets with FPS, frame time, physics time
   - High-frequency updates (10Hz default)
   - Efficient binary encoding

2. **Compressed JSON** (Type 0x02):
   - GZIP-compressed JSON for large payloads
   - Automatic decompression
   - Used for snapshots and complex events

3. **Heartbeat Protocol**:
   - Ping (0x03) / Pong (0x04) packets
   - 30-second ping interval
   - 60-second timeout

#### HTTP API (Port 8080)

Polls the HTTP API every 1 second for:
- Connection status (`/status`)
- DAP/LSP connection states
- System health information

### Data Structures

The dashboard uses strongly-typed dataclasses for all state:

- `FPSMetrics`: Performance metrics
- `PlayerVitals`: Player state
- `SystemStatus`: Subsystem health
- `NetworkStats`: Network telemetry
- `ResourceStats`: Resource usage
- `Alert`: Alert messages
- `DashboardState`: Complete dashboard state

### Performance

- **Update Rate**: 4 FPS (reduces CPU usage while maintaining responsiveness)
- **History**: 5 minutes of FPS/frame time data (300 samples)
- **Alerts**: Last 50 alerts retained
- **Memory**: ~20MB typical, scales with history length

## Troubleshooting

### Connection Failed

**Symptom**: "Failed to connect to telemetry server"

**Solutions**:
1. Ensure Godot is running with debug services:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. Check that ports 8081 (WebSocket) and 8081 (HTTP) are not blocked

3. Verify Godot is fully started (wait 5-10 seconds after launch)

### Missing Dependencies

**Symptom**: "Missing required package: ..."

**Solution**:
```bash
pip install rich websockets requests psutil
```

Or use the launcher script which auto-installs dependencies:
```bash
start_dashboard.bat
```

### No Data Displayed

**Symptom**: Dashboard connects but shows no data

**Solutions**:
1. Request a snapshot manually: Press `s`
2. Check that telemetry is enabled in Godot
3. Verify VR nodes are connected (for VR tracking data)
4. Check Godot console for telemetry server errors

### High CPU Usage

**Symptom**: Dashboard uses excessive CPU

**Solutions**:
1. Reduce update rate in `render_loop()`:
   ```python
   refresh_per_second=4  # Lower this value
   ```

2. Disable graphs: Press `g`

3. Increase history polling interval

### Alerts Not Showing

**Symptom**: No alerts despite performance issues

**Solutions**:
1. Check if alerts are enabled: Press `a` to toggle
2. Verify thresholds are appropriate for your system
3. Check that telemetry data is being received

## Integration with CI/CD

The dashboard can be used for automated testing and monitoring:

### Headless Monitoring

Run the dashboard in a CI environment to detect performance regressions:

```python
# ci_monitor.py
import asyncio
from health_dashboard import TelemetryClient, HealthThresholds

async def monitor_test():
    client = TelemetryClient()
    await client.connect()

    # Monitor for 60 seconds
    await asyncio.sleep(60)

    # Check for critical alerts
    critical_alerts = [a for a in client.state.alerts if a.level == "critical"]
    if critical_alerts:
        print(f"FAIL: {len(critical_alerts)} critical alerts detected")
        return 1

    # Check average FPS
    avg_fps = sum(client.state.fps_history) / len(client.state.fps_history)
    if avg_fps < HealthThresholds.FPS_CRITICAL:
        print(f"FAIL: Average FPS {avg_fps:.1f} below threshold")
        return 1

    print("PASS: All health checks passed")
    return 0

if __name__ == "__main__":
    exit(asyncio.run(monitor_test()))
```

### Performance Benchmarking

Use the dashboard to capture performance metrics during automated tests:

```bash
# Start Godot with automated test scene
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 test_scene.tscn &

# Run dashboard in monitoring mode
python ci_monitor.py

# Kill Godot
pkill godot
```

## Future Enhancements

Potential improvements for future versions:

- [ ] Web-based dashboard (HTML/JavaScript)
- [ ] Export metrics to Prometheus/Grafana
- [ ] Audio alerts for critical events
- [ ] Remote monitoring over network
- [ ] Historical data persistence (SQLite)
- [ ] Custom metric plugins
- [ ] Screenshot capture on critical events
- [ ] Email/Slack notifications
- [ ] Performance comparison (baseline vs current)
- [ ] Automated test report generation

## Related Documentation

- [CLAUDE.md](CLAUDE.md) - Project overview and development commands
- [HTTP_API.md](addons/godot_debug_connection/HTTP_API.md) - Complete HTTP API reference
- [TELEMETRY_GUIDE.md](TELEMETRY_GUIDE.md) - Telemetry system documentation
- [telemetry_client.py](telemetry_client.py) - Simple telemetry client example

## Support

For issues or questions:
1. Check Godot console for error messages
2. Review this documentation
3. Inspect telemetry server logs in Godot
4. Verify network connectivity to ports 8081/8081

## License

Part of the SpaceTime project. See main project for license information.
