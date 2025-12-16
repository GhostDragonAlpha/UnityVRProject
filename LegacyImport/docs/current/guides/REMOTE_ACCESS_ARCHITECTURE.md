# Remote Access System Architecture

## Overview

The Remote Access System provides comprehensive external control and monitoring capabilities for Godot applications through multiple protocols and endpoints. This system enables AI assistants, development tools, and monitoring systems to interact with running Godot instances in real-time.

## System Components

### 1. HTTP Bridge (Port 8080)
**File**: [`addons/godot_debug_connection/godot_bridge.gd`](addons/godot_debug_connection/godot_bridge.gd)

The HTTP Bridge serves as the primary REST API gateway, exposing endpoints for remote control and interaction.

#### Architecture
- **Server Type**: TCP-based HTTP server with automatic port fallback
- **Primary Port**: 8080
- **Fallback Ports**: 8083, 8084, 8085

- **Protocol**: HTTP/1.1 with JSON payloads
- **Authentication**: None (localhost only by default)

#### Core Responsibilities
- HTTP request parsing and routing
- Connection management endpoint orchestration
- Debug adapter command proxying
- Language server request proxying
- File editing operation handling
- Code execution and hot-reload triggering

#### Endpoint Structure
```
POST /connect              # Initialize connections to DAP/LSP
POST /disconnect           # Gracefully disconnect all services
GET  /status               # Get current connection status

POST /debug/*              # Debug adapter protocol commands
POST /lsp/*                # Language server protocol requests
POST /edit/*               # File editing operations
POST /execute/*            # Code execution operations
POST /resonance/*          # Resonance system operations
```

#### Request Flow
1. Client sends HTTP request to bridge server
2. Bridge parses HTTP headers and body
3. Request routed to appropriate handler based on path
4. Handler validates request and checks service availability
5. Request forwarded to DAP/LSP adapter via ConnectionManager
6. Async response handling with request sequencing
7. JSON response sent back to client

#### Port Fallback Mechanism
```gdscript
# Primary port attempt
if _is_port_available(8080):
    tcp_server.listen(8080, "127.0.0.1")
    
# Fallback sequence if primary fails
fallback_ports = [8083, 8084, 8085]

for port in fallback_ports:
    if _is_port_available(port):
        tcp_server.listen(port, "127.0.0.1")
        break
```

---

### 2. DAP Adapter (Port 6006)
**File**: [`addons/godot_debug_connection/dap_adapter.gd`](addons/godot_debug_connection/dap_adapter.gd)

Implements the Debug Adapter Protocol for IDE-style debugging capabilities.

#### Architecture
- **Protocol**: Debug Adapter Protocol (DAP)
- **Transport**: TCP with JSON message format
- **Primary Port**: 6006
- **Fallback Ports**: 6007, 6008, 6009
- **Message Format**: Content-Length header + JSON body

#### Core Responsibilities
- TCP connection management with exponential backoff retry
- DAP message parsing and validation
- Request sequencing and correlation
- Event handling and propagation
- Debug session lifecycle management

#### DAP Message Flow
```
Client → DAPAdapter → Godot Debug Server → DAPAdapter → Client
```

#### Supported DAP Commands
- **Session Management**: `initialize`, `launch`, `attach`, `disconnect`
- **Breakpoints**: `setBreakpoints`, `setFunctionBreakpoints`, `setExceptionBreakpoints`
- **Execution Control**: `continue`, `pause`, `next`, `stepIn`, `stepOut`
- **Inspection**: `stackTrace`, `scopes`, `variables`, `evaluate`
- **Threads**: `threads`, `pause`, `continue`

#### Connection State Management
```gdscript
enum State {
    DISCONNECTED,    # Not connected
    CONNECTING,      # Connection attempt in progress
    INITIALIZING,    # Handshake in progress
    CONNECTED,       # Successfully connected
    ERROR,           # Connection failed
    RECONNECTING     # Attempting reconnection
}
```

#### Retry Logic
- Maximum retry attempts: 5
- Exponential backoff: 1s, 2s, 4s, 8s, 16s
- Connection timeout: 3 seconds
- Request timeout: 10 seconds

---

### 3. LSP Adapter (Port 6005)
**File**: [`addons/godot_debug_connection/lsp_adapter.gd`](addons/godot_debug_connection/lsp_adapter.gd)

Implements the Language Server Protocol for code intelligence features.

#### Architecture
- **Protocol**: Language Server Protocol (LSP)
- **Transport**: TCP with JSON-RPC 2.0 message format
- **Primary Port**: 6005
- **Fallback Ports**: 6006, 6007, 6008
- **Message Format**: Content-Length header + JSON-RPC body

#### Core Responsibilities
- TCP connection management with exponential backoff retry
- LSP message parsing and validation
- JSON-RPC 2.0 compliance
- Request/response correlation
- Notification handling
- Code intelligence operation processing

#### LSP Message Flow
```
Client → LSPAdapter → Godot Language Server → LSPAdapter → Client
```

#### Supported LSP Methods
- **Text Synchronization**: `textDocument/didOpen`, `didChange`, `didSave`, `didClose`
- **Code Intelligence**: `textDocument/completion`, `hover`, `signatureHelp`
- **Navigation**: `textDocument/definition`, `references`, `documentSymbol`
- **Workspace**: `workspace/applyEdit`, `workspace/symbol`

#### Initialization Sequence
```gdscript
# 1. Send initialize request
send_initialize(root_uri, callback)

# 2. Wait for initialize response
# 3. Send initialized notification
send_initialized()

# 4. Server is ready for operations
```

#### Connection Management
- Same retry logic as DAP adapter
- Automatic reconnection on unexpected disconnect
- Health monitoring with periodic checks

---

### 4. Resonance System (Port 8080)
**File**: [`addons/godot_debug_connection/godot_bridge.gd`](addons/godot_debug_connection/godot_bridge.gd)

Exposes endpoints for the game's core resonance mechanics, allowing external agents to interact with the wave simulation.

#### Endpoints

**POST /resonance/apply_interference**
Apply constructive or destructive interference to a target frequency.

**Parameters:**
- `object_frequency` (float): The frequency of the target object
- `object_amplitude` (float): The current amplitude of the target object
- `emit_frequency` (float): The frequency being emitted by the agent
- `interference_type` (string): "constructive" or "destructive"
- `delta_time` (float, optional): Simulation time step (default: 0.1)

**Response:**
```json
{
    "status": "success",
    "frequency_match": 0.95,       # 0.0 to 1.0
    "initial_amplitude": 1.0,
    "final_amplitude": 1.5,
    "amplitude_change": 0.5,
    "was_cancelled": false
}
```

---

### 4. Connection Manager
**File**: [`addons/godot_debug_connection/connection_manager.gd`](addons/godot_debug_connection/connection_manager.gd)

Orchestrates all debug connections and provides unified management interface.

#### Architecture
- **Type**: Godot Node with process loop
- **Responsibilities**: 
  - Coordinates DAP and LSP adapters
  - Manages connection lifecycle
  - Health monitoring and recovery
  - Event routing and propagation
  - State synchronization

#### Core Components
```gdscript
var dap_adapter: DAPAdapter    # Debug adapter handler
var lsp_adapter: LSPAdapter    # Language server handler
var is_ready: bool             # Both services connected
```

#### Connection Lifecycle
1. **Initialization**: Adapters created and signals connected
2. **Connection**: `connect_services()` initiates both connections
3. **Monitoring**: Process loop polls adapters and checks health
4. **Recovery**: Automatic retry on connection failures
5. **Shutdown**: Graceful disconnection with timeout handling

#### Health Monitoring
- **Interval**: 5 seconds
- **Checks**: TCP connection status, response timeouts
- **Actions**: State transition, retry scheduling, warning emission

#### Event System
```gdscript
signal connection_state_changed(service: String, state: ConnectionState.State)
signal all_services_ready()
signal dap_event_received(event: Dictionary)
signal lsp_notification_received(notification: Dictionary)
```

---

### 5. Telemetry Server (Port 8081)
**File**: [`addons/godot_debug_connection/telemetry_server.gd`](addons/godot_debug_connection/telemetry_server.gd)

Provides real-time telemetry streaming via WebSocket for monitoring and analytics.

#### Architecture
- **Protocol**: WebSocket (RFC 6455)
- **Transport**: TCP with frame-based messaging
- **Port**: 8081
- **Message Format**: JSON with event-based structure

#### Core Responsibilities
- WebSocket server management
- Client connection handling
- Real-time data streaming
- Event broadcasting
- VR tracking data collection
- Performance metrics aggregation

#### Telemetry Types
1. **Performance Metrics**
   - FPS (frames per second)
   - Frame time (processing duration)
   - Physics time (physics processing)
   - Memory usage (static allocation)
   - Object counts (total objects and nodes)

2. **VR Tracking Data**
   - Headset position and rotation
   - Controller positions and rotations
   - Controller activation states
   - Tracking update rates

3. **System Events**
   - Error events with context
   - Warning events with details
   - Custom application events
   - State change notifications

#### Client Communication
```javascript
// Client connects
const ws = new WebSocket('ws://127.0.0.1:8081');

// Receive telemetry
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log(data.event, data.data);
};

// Configure telemetry
ws.send(JSON.stringify({
    command: 'configure',
    config: {
        fps_enabled: true,
        vr_tracking_enabled: true,
        fps_interval: 0.5
    }
}));
```

#### Configuration Options
```gdscript
var telemetry_enabled: bool = true
var send_fps: bool = true
var send_vr_tracking: bool = true
var send_scene_info: bool = true
var fps_update_interval: float = 0.5  # seconds
var tracking_update_interval: float = 0.1  # seconds
```

---

## 2. Network Layer

### ⚠️ CRITICAL REQUIREMENT: NON-HEADLESS MODE
**The Godot Editor MUST be running in NON-HEADLESS (GUI) mode for the network layer to function correctly.**
- **Headless Mode (`--headless`)**: Unstable for DAP/LSP connections. Use ONLY for log capture and automated tests.
- **GUI Mode (`-e`)**: Required for stable DAP (port 6006) and LSP (port 6005) connections.

### Port Configuration
The system uses the following ports:

### Default Port Assignments
| Service | Primary Port | Fallback Ports | Protocol | Purpose |
|---------|-------------|----------------|----------|---------|
| HTTP Bridge | 8080 | 8083, 8084, 8085 | HTTP | REST API gateway |

| DAP Adapter | 6006 | 6007, 6008, 6009 | TCP | Debug adapter |
| LSP Adapter | 6005 | 6006, 6007, 6008 | TCP | Language server |
| Telemetry | 8081 | - | WebSocket | Real-time streaming |

### Port Availability Checking
```gdscript
func _is_port_available(port: int) -> bool:
    var test_server = TCPServer.new()
    var err = test_server.listen(port, "127.0.0.1")
    if err == OK:
        test_server.stop()
        return true
    else:
        test_server.stop()
        return false
```

### Dynamic Port Selection
1. Attempt primary port first
2. If unavailable, iterate through fallback ports
3. Log successful binding and port used
4. Provide clear error if all ports unavailable

---

## Authentication and Security

### Current Security Model
- **Network Binding**: localhost (127.0.0.1) only by default
- **Authentication**: None implemented
- **Encryption**: None (plaintext HTTP/WebSocket)
- **Access Control**: Assumes trusted local environment

### Security Considerations
1. **Localhost Binding**: Prevents remote network access
2. **No Authentication**: Any local process can connect
3. **Debug Access**: Exposes internal application state
4. **Code Execution**: Enables remote code modification

### Recommended Security Measures
```gdscript
# For development only - localhost binding
const HOST = "127.0.0.1"

# For trusted networks only
const HOST = "0.0.0.0"  # Listen on all interfaces

# Add API key validation
func _validate_request(headers: Dictionary) -> bool:
    return headers.get("Authorization") == "Bearer YOUR_API_KEY"
```

---

## Example Usage Patterns

### 1. Complete Connection Flow
```python
import requests
import json

BASE_URL = "http://127.0.0.1:8080"

# 1. Connect to services
response = requests.post(f"{BASE_URL}/connect")
print(f"Connect: {response.json()}")

# 2. Check status
status = requests.get(f"{BASE_URL}/status").json()
print(f"DAP State: {status['debug_adapter']['state']}")
print(f"LSP State: {status['language_server']['state']}")

# 3. Set breakpoint
breakpoint_data = {
    "source": {"path": "res://player.gd"},
    "breakpoints": [{"line": 42}]
}
response = requests.post(
    f"{BASE_URL}/debug/setBreakpoints",
    json=breakpoint_data
)
print(f"Breakpoint: {response.json()}")

# 4. Get code completion
completion_data = {
    "textDocument": {"uri": "file:///project/player.gd"},
    "position": {"line": 10, "character": 5}
}
response = requests.post(
    f"{BASE_URL}/lsp/completion",
    json=completion_data
)
print(f"Completion: {response.json()}")

# 5. Disconnect
response = requests.post(f"{BASE_URL}/disconnect")
print(f"Disconnect: {response.json()}")
```

### 2. Real-time Telemetry Monitoring
```python
import asyncio
import websockets
import json

async def monitor_telemetry():
    uri = "ws://127.0.0.1:8081"
    async with websockets.connect(uri) as websocket:
        # Configure telemetry
        await websocket.send(json.dumps({
            "command": "configure",
            "config": {
                "fps_enabled": True,
                "vr_tracking_enabled": True,
                "fps_interval": 0.5
            }
        }))
        
        # Monitor events
        async for message in websocket:
            data = json.loads(message)
            if data["event"] == "fps":
                print(f"FPS: {data['data']['fps']}")
            elif data["event"] == "vr_tracking":
                print(f"Headset: {data['data']['headset']['position']}")

asyncio.run(monitor_telemetry())
```

### 3. Error Handling and Recovery
```python
import requests
import time

def connect_with_retry(max_attempts=5):
    for attempt in range(max_attempts):
        try:
            response = requests.post(
                "http://127.0.0.1:8080/connect",
                timeout=5
            )
            if response.status_code == 200:
                return True
        except requests.exceptions.RequestException:
            pass
        
        print(f"Connection attempt {attempt + 1} failed, retrying...")
        time.sleep(2 ** attempt)  # Exponential backoff
    
    return False

# Use the connection
if connect_with_retry():
    # Execute commands
    pass
else:
    print("Failed to connect after all retries")
```

---

## Troubleshooting Guide

### Connection Issues

#### Symptom: HTTP Server Won't Start
**Diagnosis**: Port already in use or permission denied
```bash
# Check port usage
netstat -an | grep 8080

# Try alternative port
# Modify godot_bridge.gd: const PRIMARY_PORT = 8083
```

#### Symptom: DAP/LSP Connection Failed
**Diagnosis**: Godot services not running or wrong port
```bash
# Verify services are listening
netstat -an | grep 6005  # LSP
netstat -an | grep 6006  # DAP

# Check Godot console for GDA startup messages
```

#### Symptom: Commands Timeout
**Diagnosis**: Godot unresponsive or network issues
```bash
# Test basic connectivity
curl http://127.0.0.1:8080/status

# Check Godot CPU usage
# Increase timeout in connection_manager.gd
```

### Message Format Issues

#### Symptom: Invalid JSON Errors
**Solution**: Validate JSON format
```python
import json

# Validate before sending
data = {"key": "value"}
json_str = json.dumps(data)  # Properly formatted JSON
```

#### Symptom: Missing Required Parameters
**Solution**: Check API documentation
```python
# Required parameters for setBreakpoints
{
    "source": {"path": "res://file.gd"},  # Required
    "breakpoints": [{"line": 10}]         # Required
}
```

### Performance Issues

#### Symptom: High CPU Usage
**Solutions**:
- Increase telemetry update intervals
- Reduce number of connected clients
- Disable unused telemetry streams
- Check for excessive polling

#### Symptom: Memory Leaks
**Solutions**:
- Monitor pending request dictionaries
- Ensure proper cleanup on disconnect
- Check for unhandled message buffers

---

## Integration Patterns

### AI Assistant Integration
```python
class GodotAIClient:
    def __init__(self, base_url="http://127.0.0.1:8080"):
        self.base_url = base_url
        self.connected = False
    
    def connect(self):
        """Establish connection to Godot services"""
        response = requests.post(f"{self.base_url}/connect")
        self.connected = response.status_code == 200
        return self.connected
    
    def get_code_completions(self, file_path, line, character):
        """Get code completions at specific position"""
        response = requests.post(
            f"{self.base_url}/lsp/completion",
            json={
                "textDocument": {"uri": f"file://{file_path}"},
                "position": {"line": line, "character": character}
            }
        )
        return response.json()
    
    def set_breakpoint(self, file_path, line):
        """Set breakpoint in file"""
        response = requests.post(
            f"{self.base_url}/debug/setBreakpoints",
            json={
                "source": {"path": file_path},
                "breakpoints": [{"line": line}]
            }
        )
        return response.json()
```

### Monitoring Dashboard Integration
```javascript
class TelemetryDashboard {
    constructor(url = 'ws://127.0.0.1:8081') {
        this.url = url;
        this.connected = false;
        this.metrics = {};
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        
        this.ws.onopen = () => {
            this.connected = true;
            this.configureTelemetry();
        };
        
        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleTelemetry(data);
        };
    }
    
    configureTelemetry() {
        this.ws.send(JSON.stringify({
            command: 'configure',
            config: {
                fps_enabled: true,
                vr_tracking_enabled: true,
                scene_info_enabled: true
            }
        }));
    }
    
    handleTelemetry(data) {
        switch(data.event) {
            case 'fps':
                this.metrics.fps = data.data.fps;
                this.updateFPSDisplay();
                break;
            case 'vr_tracking':
                this.metrics.vr = data.data;
                this.updateVRDisplay();
                break;
        }
    }
}
```

---

## Performance Characteristics

### HTTP Bridge
- **Request Processing**: ~1-5ms per request
- **Concurrent Clients**: 10-20 (development use)
- **Memory Usage**: ~5-10MB base + 1MB per active client
- **CPU Usage**: <1% typical, spikes during high request volume

### DAP/LSP Adapters
- **Connection Time**: 100-500ms typical
- **Command Latency**: 10-100ms depending on operation
- **Message Throughput**: 100+ messages/second
- **Memory Usage**: ~2-5MB per adapter

### Telemetry Server
- **Connection Overhead**: ~50ms per client
- **Update Frequency**: Configurable (0.1-10 seconds)
- **Bandwidth**: ~1-10 KB/s per client depending on enabled streams
- **CPU Impact**: <0.5% typical with default settings

---

## Future Enhancements

### Planned Features
1. **Authentication System**: API key and token-based auth
2. **HTTPS Support**: TLS/SSL encryption for secure communication
3. **Rate Limiting**: Prevent abuse and ensure fair usage
4. **Request Batching**: Combine multiple operations for efficiency
5. **Plugin Extensions**: Allow custom endpoint registration
6. **Advanced Telemetry**: GPU metrics, network stats, custom events

### Scalability Improvements
1. **Connection Pooling**: Reuse connections for better performance
2. **Async Processing**: Non-blocking I/O for all operations
3. **Message Queuing**: Buffer and prioritize messages
4. **Load Balancing**: Distribute across multiple Godot instances

---

## References

- [Debug Adapter Protocol Specification](https://microsoft.github.io/debug-adapter-protocol/)
- [Language Server Protocol Specification](https://microsoft.github.io/language-server-protocol/)
- [WebSocket Protocol RFC 6455](https://tools.ietf.org/html/rfc6455)
- [Godot Debug Adapter Documentation](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html)
- [GDScript Language Server](https://docs.godotengine.org/en/stable/tutorials/editor/language_server.html)