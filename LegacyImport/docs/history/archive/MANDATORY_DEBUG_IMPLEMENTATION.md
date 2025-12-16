# MANDATORY DEBUG IMPLEMENTATION GUIDE

## Overview

This guide provides practical implementation instructions for the Godot Debug Connection system with mandatory debug enforcement. **Debug connection is REQUIRED, not optional.**

## Quick Start

### 1. Configuration Setup

```bash
# Copy the configuration file to your project
cp debugger_config.json /path/to/your/godot/project/

# Make the setup script executable
chmod +x debugger_setup.sh

# Run the validation script to check your system
python debugger_validation.py --project-path /path/to/your/godot/project
```

### 2. Start Godot with Mandatory Debug Services

```bash
# Using the automated setup script (RECOMMENDED)
./debugger_setup.sh --project-path /path/to/your/godot/project --verbose

# Or manually start Godot with required parameters
godot --path "/path/to/your/project" \
      --debug-server tcp://127.0.0.1:6006 \
      --lsp-server tcp://127.0.0.1:6005
```

### 3. Verify Debug Connection

```bash
# Check status endpoint
curl http://127.0.0.1:8080/status

# Expected response:
{
  "debug_adapter": {
    "service_name": "Debug Adapter",
    "port": 6006,
    "state": 2,           # ⚠️ MUST be 2 (CONNECTED)
    "retry_count": 0
  },
  "language_server": {
    "service_name": "Language Server",
    "port": 6005,
    "state": 2,           # ⚠️ MUST be 2 (CONNECTED)
    "retry_count": 0
  },
  "overall_ready": true   # ⚠️ MUST be true
}
```

## Configuration File Structure

### debugger_config.json

The configuration file enforces all mandatory settings:

```json
{
  "debug_enforcement": {
    "mandatory": true,
    "version": "1.0.0"
  },
  "port_configurations": {
    "http_bridge": {
      "primary_port": 8080,
      "fallback_ports": [8083, 8084, 8085, 8080],
      "protocol": "HTTP/1.1",
      "binding": "127.0.0.1",
      "timeout_seconds": 10,
      "max_retries": 5
    },
    "dap_adapter": {
      "primary_port": 6006,
      "fallback_ports": [6007, 6008, 6009],
      "protocol": "TCP",
      "binding": "127.0.0.1",
      "timeout_seconds": 3,
      "request_timeout_seconds": 10,
      "max_retries": 5,
      "retry_delays": [1, 2, 4, 8, 16]
    },
    "lsp_adapter": {
      "primary_port": 6005,
      "fallback_ports": [6006, 6007, 6008],
      "protocol": "TCP",
      "binding": "127.0.0.1",
      "timeout_seconds": 3,
      "request_timeout_seconds": 10,
      "max_retries": 5,
      "retry_delays": [1, 2, 4, 8, 16]
    },
    "telemetry_server": {
      "primary_port": 8081,
      "protocol": "WebSocket",
      "binding": "127.0.0.1",
      "timeout_seconds": 5,
      "max_connections": 10
    }
  },
  "security_settings": {
    "localhost_only": true,
    "authentication": {
      "enabled": false,
      "api_key": null,
      "bearer_token": null
    },
    "resource_limits": {
      "max_memory_mb": 512,
      "max_cpu_percent": 80,
      "max_connections_per_service": 20
    }
  }
}
```

## Implementation Examples

### Example 1: Basic HTTP API Client (Python)

```python
import requests
import json
import time
from typing import Dict, Any

class GodotDebugClient:
    """Client for Godot Debug Connection HTTP API"""
    
    def __init__(self, base_url: str = "http://127.0.0.1:8080"):
        self.base_url = base_url
        self.connected = False
    
    def connect(self, max_retries: int = 5) -> bool:
        """Connect to Godot debug services with exponential backoff"""
        for attempt in range(max_retries):
            try:
                # Check if services are ready
                status = self.get_status()
                if status.get("overall_ready", False):
                    self.connected = True
                    print("✓ Successfully connected to Godot debug services")
                    return True
                
                # Wait with exponential backoff
                delay = 2 ** attempt
                print(f"Services not ready, waiting {delay} seconds...")
                time.sleep(delay)
                
            except Exception as e:
                print(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    delay = 2 ** attempt
                    time.sleep(delay)
                else:
                    print("✗ Failed to connect after all retries")
                    return False
        
        return False
    
    def get_status(self) -> Dict[str, Any]:
        """Get debug connection status"""
        response = requests.get(f"{self.base_url}/status", timeout=5)
        response.raise_for_status()
        return response.json()
    
    def set_breakpoint(self, file_path: str, line: int) -> Dict[str, Any]:
        """Set a breakpoint in a Godot script"""
        if not self.connected:
            raise RuntimeError("Not connected to debug services")
        
        payload = {
            "source": {"path": file_path},
            "breakpoints": [{"line": line}]
        }
        
        response = requests.post(
            f"{self.base_url}/debug/setBreakpoints",
            json=payload,
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    
    def get_completions(self, file_path: str, line: int, character: int) -> Dict[str, Any]:
        """Get code completions at a specific position"""
        if not self.connected:
            raise RuntimeError("Not connected to debug services")
        
        payload = {
            "textDocument": {"uri": f"file://{file_path}"},
            "position": {"line": line, "character": character}
        }
        
        response = requests.post(
            f"{self.base_url}/lsp/completion",
            json=payload,
            timeout=10
        )
        response.raise_for_status()
        return response.json()

# Usage example
if __name__ == "__main__":
    client = GodotDebugClient()
    
    # Connect with automatic retry
    if not client.connect():
        print("❌ Failed to establish debug connection")
        print("This is a MANDATORY DEBUG ERROR - system cannot function without debug connection")
        sys.exit(1)
    
    # Check status
    status = client.get_status()
    print(f"DAP State: {status['debug_adapter']['state']}")
    print(f"LSP State: {status['language_server']['state']}")
    
    # Set a breakpoint
    try:
        result = client.set_breakpoint("res://player.gd", 42)
        print(f"Breakpoint set: {result}")
    except Exception as e:
        print(f"Failed to set breakpoint: {e}")
    
    # Get code completions
    try:
        completions = client.get_completions("res://player.gd", 10, 5)
        print(f"Completions: {completions}")
    except Exception as e:
        print(f"Failed to get completions: {e}")
```

### Example 2: Telemetry Monitoring Client (Python)

```python
import asyncio
import websockets
import json
from typing import Dict, Any, Callable

class TelemetryMonitor:
    """Monitor Godot telemetry data in real-time"""
    
    def __init__(self, uri: str = "ws://127.0.0.1:8081"):
        self.uri = uri
        self.websocket = None
        self.running = False
        self.callbacks: Dict[str, Callable] = {}
    
    def on(self, event: str, callback: Callable):
        """Register callback for telemetry event"""
        self.callbacks[event] = callback
    
    async def connect(self):
        """Connect to telemetry server"""
        try:
            self.websocket = await websockets.connect(self.uri)
            print("✓ Connected to telemetry server")
            
            # Configure telemetry
            config = {
                "command": "configure",
                "config": {
                    "fps_enabled": True,
                    "vr_tracking_enabled": True,
                    "scene_info_enabled": True,
                    "fps_interval": 0.5,
                    "tracking_update_interval": 0.1
                }
            }
            await self.websocket.send(json.dumps(config))
            
        except Exception as e:
            print(f"✗ Failed to connect to telemetry: {e}")
            raise
    
    async def monitor(self):
        """Monitor telemetry stream"""
        self.running = True
        
        try:
            async for message in self.websocket:
                data = json.loads(message)
                event = data.get("event")
                
                if event in self.callbacks:
                    self.callbacks[event](data.get("data", {}))
                
        except websockets.exceptions.ConnectionClosed:
            print("Telemetry connection closed")
        except Exception as e:
            print(f"Telemetry error: {e}")
        finally:
            self.running = False
    
    async def disconnect(self):
        """Disconnect from telemetry server"""
        self.running = False
        if self.websocket:
            await self.websocket.close()
    
    async def run(self):
        """Run telemetry monitor"""
        await self.connect()
        await self.monitor()

# Usage example
async def main():
    monitor = TelemetryMonitor()
    
    # Register callbacks
    def on_fps(data: Dict[str, Any]):
        print(f"FPS: {data.get('fps', 0):.1f}")
    
    def on_vr_tracking(data: Dict[str, Any]):
        headset = data.get("headset", {})
        pos = headset.get("position", {})
        print(f"Headset position: ({pos.get('x', 0):.2f}, {pos.get('y', 0):.2f}, {pos.get('z', 0):.2f})")
    
    def on_error(data: Dict[str, Any]):
        print(f"❌ Error: {data.get('message', 'Unknown error')}")
    
    monitor.on("fps", on_fps)
    monitor.on("vr_tracking", on_vr_tracking)
    monitor.on("error", on_error)
    
    # Run monitor
    try:
        await monitor.run()
    except KeyboardInterrupt:
        print("\nShutting down telemetry monitor...")
    finally:
        await monitor.disconnect()

if __name__ == "__main__":
    asyncio.run(main())
```

### Example 3: GDScript Integration

```gdscript
# In your main game script or autoload
extends Node

var connection_manager = null

func _ready():
    # Initialize debug connection
    initialize_debug_connection()
    
    # Set up error handling
    setup_error_handling()

func initialize_debug_connection():
    # Get connection manager from autoload
    connection_manager = get_node("/root/GodotBridge")
    
    if connection_manager == null:
        push_error("MANDATORY DEBUG ERROR: GodotBridge not found")
        push_error("MANDATORY DEBUG ERROR: Debug connection is REQUIRED")
        return
    
    # Wait for connection to be ready
    await wait_for_debug_connection()

func wait_for_debug_connection(timeout: float = 30.0) -> bool:
    var elapsed = 0.0
    
    while elapsed < timeout:
        if connection_manager.is_ready:
            print("✓ Debug connection established")
            return true
        
        # Wait a bit and check again
        await get_tree().create_timer(0.5).timeout
        elapsed += 0.5
    
    push_error("MANDATORY DEBUG ERROR: Debug connection timeout")
    push_error("MANDATORY DEBUG ERROR: System cannot function without debug connection")
    return false

func setup_error_handling():
    # Connect to error signals
    if connection_manager:
        connection_manager.connection_state_changed.connect(_on_connection_state_changed)

func _on_connection_state_changed(service: String, state: int):
    match state:
        0:  # DISCONNECTED
            push_warning("Debug service disconnected: %s" % service)
        2:  # CONNECTED
            print("Debug service connected: %s" % service)
        3:  # ERROR
            push_error("MANDATORY DEBUG ERROR: Debug service error: %s" % service)

# Example function that requires debug connection
func perform_ai_operation():
    # Check debug connection before operation
    if not connection_manager.require_debug_connection():
        push_error("Cannot perform AI operation: Debug connection required")
        return
    
    # Proceed with operation
    var result = connection_manager.send_dap_command("evaluate", {
        "expression": "get_current_scene().name"
    })
    
    return result
```

### Example 4: Health Check Monitoring

```python
import requests
import time
import threading
from typing import Dict, Any, Callable

class HealthMonitor:
    """Monitor debug connection health and alert on failures"""
    
    def __init__(self, base_url: str = "http://127.0.0.1:8080"):
        self.base_url = base_url
        self.running = False
        self.check_interval = 5  # seconds
        self.on_failure_callback = None
    
    def on_failure(self, callback: Callable[[str], None]):
        """Set callback for health check failures"""
        self.on_failure_callback = callback
    
    def check_health(self) -> bool:
        """Perform health check"""
        try:
            status = self.get_status()
            
            # Check DAP state
            dap_state = status.get("debug_adapter", {}).get("state")
            if dap_state != 2:
                if self.on_failure_callback:
                    self.on_failure_callback(f"DAP adapter state is {dap_state}, expected 2")
                return False
            
            # Check LSP state
            lsp_state = status.get("language_server", {}).get("state")
            if lsp_state != 2:
                if self.on_failure_callback:
                    self.on_failure_callback(f"LSP adapter state is {lsp_state}, expected 2")
                return False
            
            # Check overall ready
            if not status.get("overall_ready", False):
                if self.on_failure_callback:
                    self.on_failure_callback("System is not ready")
                return False
            
            return True
            
        except Exception as e:
            if self.on_failure_callback:
                self.on_failure_callback(f"Health check failed: {e}")
            return False
    
    def get_status(self) -> Dict[str, Any]:
        """Get current status"""
        response = requests.get(f"{self.base_url}/status", timeout=5)
        response.raise_for_status()
        return response.json()
    
    def start_monitoring(self):
        """Start health check monitoring in background"""
        self.running = True
        
        def monitor():
            while self.running:
                if not self.check_health():
                    print("❌ Health check failed!")
                else:
                    print("✓ Health check passed")
                
                time.sleep(self.check_interval)
        
        thread = threading.Thread(target=monitor, daemon=True)
        thread.start()
    
    def stop_monitoring(self):
        """Stop health check monitoring"""
        self.running = False

# Usage example
def main():
    monitor = HealthMonitor()
    
    def on_failure(message: str):
        print(f"🚨 MANDATORY DEBUG ERROR: {message}")
        print("Debug connection health check failed!")
    
    monitor.on_failure(on_failure)
    
    # Start monitoring
    monitor.start_monitoring()
    
    # Keep running
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping health monitor...")
        monitor.stop_monitoring()

if __name__ == "__main__":
    main()
```

## Error Handling Patterns

### Pattern 1: Mandatory Error Logging

```python
import logging

# Set up logging
logging.basicConfig(
    level=logging.ERROR,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('godot_debug.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('GodotDebug')

def log_mandatory_error(message: str):
    """Log mandatory debug error"""
    error_msg = f"MANDATORY DEBUG ERROR: {message}"
    logger.error(error_msg)
    print(error_msg)
    print("This error indicates a critical failure in the debug system.")
    print("The application cannot proceed without a proper debug connection.")

# Usage
try:
    # Some operation that requires debug connection
    if not debug_client.is_connected():
        log_mandatory_error("Debug connection is not established")
        raise RuntimeError("Debug connection required")
except Exception as e:
    log_mandatory_error(f"Operation failed: {e}")
    raise
```

### Pattern 2: Connection Validation Before Operations

```python
def require_debug_connection(func):
    """Decorator to require debug connection before function execution"""
    def wrapper(self, *args, **kwargs):
        if not self.debug_client or not self.debug_client.is_connected():
            raise RuntimeError(
                "MANDATORY DEBUG ERROR: Debug connection required for this operation"
            )
        return func(self, *args, **kwargs)
    return wrapper

class GodotOperations:
    def __init__(self, debug_client):
        self.debug_client = debug_client
    
    @require_debug_connection
    def set_breakpoint(self, file_path: str, line: int):
        """Set breakpoint (requires debug connection)"""
        return self.debug_client.set_breakpoint(file_path, line)
    
    @require_debug_connection
    def get_completions(self, file_path: str, line: int, character: int):
        """Get code completions (requires debug connection)"""
        return self.debug_client.get_completions(file_path, line, character)
```

## Testing and Validation

### Automated Validation Script

```bash
#!/bin/bash
# test_debug_setup.sh - Test debug connection setup

set -e

echo "Testing Godot Debug Connection setup..."

# Test configuration file
if [ ! -f "debugger_config.json" ]; then
    echo "❌ debugger_config.json not found"
    exit 1
fi
echo "✓ Configuration file exists"

# Test validation script
if [ ! -f "debugger_validation.py" ]; then
    echo "❌ debugger_validation.py not found"
    exit 1
fi
echo "✓ Validation script exists"

# Test Python validation
echo "Running Python validation..."
python debugger_validation.py --verbose
if [ $? -ne 0 ]; then
    echo "❌ Python validation failed"
    exit 1
fi
echo "✓ Python validation passed"

# Test setup script
if [ ! -f "debugger_setup.sh" ]; then
    echo "❌ debugger_setup.sh not found"
    exit 1
fi

# Make executable
chmod +x debugger_setup.sh
echo "✓ Setup script exists and is executable"

echo ""
echo "🎉 All tests passed! Debug connection system is properly configured."
```

## Troubleshooting Guide

### Issue: "MANDATORY DEBUG ERROR" Messages

**Symptoms:**
- Console shows errors starting with "MANDATORY DEBUG ERROR"
- System functionality limited or non-functional
- HTTP API returns 503 errors

**Solutions:**
```bash
# 1. Verify plugin is enabled
# Check Project → Project Settings → Plugins → Godot Debug Connection = Enabled

# 2. Verify Godot command line
ps aux | grep godot  # Should show --debug-server and --lsp-server

# 3. Check port availability
netstat -an | grep 6005  # LSP port
netstat -an | grep 6006  # DAP port
netstat -an | grep 8080  # HTTP port

# 4. Test connectivity
curl http://127.0.0.1:8080/status

# 5. Run validation script
python debugger_validation.py --project-path /path/to/project --verbose
```

### Issue: Connection Timeouts

**Symptoms:**
- Connection attempts timeout
- Services not becoming ready
- Health check failures

**Solutions:**
```bash
# Increase timeout values in debugger_config.json
{
  "port_configurations": {
    "dap_adapter": {
      "timeout_seconds": 5,           # Increase from 3
      "request_timeout_seconds": 15   # Increase from 10
    },
    "lsp_adapter": {
      "timeout_seconds": 5,           # Increase from 3
      "request_timeout_seconds": 15   # Increase from 10
    }
  },
  "connection_validation": {
    "connection_timeout_seconds": 60  # Increase from 30
  }
}
```

## Summary

### Key Points

1. **Debug connection is mandatory** - not optional
2. **Always validate before operations** - use `require_debug_connection()`
3. **Monitor health continuously** - implement health checks
4. **Log mandatory errors** - use "MANDATORY DEBUG ERROR" prefix
5. **Use exponential backoff** - for connection retries
6. **Enforce localhost binding** - for security
7. **Validate configuration** - before starting services

### Required Files

- ✅ `debugger_config.json` - Configuration with all mandatory settings
- ✅ `debugger_setup.sh` - Automated startup script
- ✅ `debugger_validation.py` - Validation script
- ✅ `MANDATORY_DEBUG_IMPLEMENTATION.md` - This implementation guide

### Next Steps

1. Copy all files to your Godot project
2. Run validation: `python debugger_validation.py --project-path /path/to/project`
3. Start services: `./debugger_setup.sh --project-path /path/to/project`
4. Implement client code using the examples above
5. Set up monitoring and health checks

**Remember: Debug connection is not optional. It is a core requirement for system functionality.**