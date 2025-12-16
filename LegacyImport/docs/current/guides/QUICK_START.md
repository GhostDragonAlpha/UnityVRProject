# Quick Start Guide - SpaceTime VR Development

**Goal**: Get your development environment running in 5 minutes

**Prerequisites**: Godot 4.5+ installed, Python 3.8+, VR headset (optional)

---

## Step 1: Start the Development Server (2 minutes)

### Windows

```bash
# Quick restart (recommended)
restart_godot_with_debug.bat

# OR manual start
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### Linux/Mac

```bash
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005
```

**Important**: Must run in GUI mode (not headless). Wait 5-10 seconds for services to start.

---

## Step 2: Get Your API Token (1 minute)

The HTTP API uses token-based authentication. When Godot starts, it prints the API token to the console.

### Find the Token in Console Output

Look for these lines in the Godot console:

```
[Security] API token generated: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
[Security] Include in requests: Authorization: Bearer a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### Save the Token

**Windows (PowerShell):**
```powershell
$env:API_TOKEN="your_token_here"
```

**Windows (Command Prompt):**
```cmd
set API_TOKEN=your_token_here
```

**Linux/Mac:**
```bash
export API_TOKEN="your_token_here"
```

**Tip**: You can also redirect Godot's output to capture the token automatically:

```bash
# Windows
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log

# Linux/Mac
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log

# Extract token
export API_TOKEN=$(grep "API TOKEN:" godot.log | awk '{print $4}')
```

---

## Step 3: Verify Connection (1 minute)

```bash
# Check HTTP API is running (port 8080 - GodotBridge)
curl http://127.0.0.1:8080/status

# Expected output:
# {
#   "overall_ready": true,
#   "debug_adapter": {"state": 2, "port": 6006},
#   "language_server": {"state": 2, "port": 6005}
# }
```

**Note**: The `/status` endpoint does not require authentication. All other endpoints do.

**Troubleshooting**: If curl fails, wait 10 more seconds and retry.

---

## Step 4: Make Your First API Call (1 minute)

### Get Current Scene

**With Authentication (port 8080 - requires token):**
```bash
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene
```

**Expected Output**:
```json
{
  "scene_name": "VRMain",
  "scene_path": "res://vr_main.tscn",
  "status": "loaded"
}
```

**Authentication Error (if token is missing or invalid):**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}
```

### Load a Different Scene

```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}'
```

**Expected Output**:
```json
{
  "status": "loading",
  "scene": "res://vr_main.tscn",
  "message": "Scene load initiated successfully"
}
```

**Forbidden Error (if scene is not whitelisted):**
```json
{
  "error": "Forbidden",
  "message": "Scene not in whitelist"
}
```

---

## Step 5: Monitor Telemetry (1 minute)

### Install Python Dependencies

```bash
pip install websockets requests
```

### Start Telemetry Monitor

```bash
python telemetry_client.py
```

**Expected Output**:
```
Connected to telemetry server
FPS: 90.0, Frame Time: 11.1ms
VR Tracking: Headset at (0.0, 1.7, 0.0)
```

---

## Step 6: Run in VR (Optional)

1. **Connect your VR headset** (Quest, Index, Vive, WMR)
2. **Start SteamVR or OpenXR runtime**
3. **Press F5 in Godot** or click Play button
4. **Put on headset** - VR scene should appear
5. **Use controllers** - Trigger to excavate, grip to interact

**Desktop Fallback**: If no headset detected, game runs in desktop mode automatically.

---

## Quick Reference

### Available Ports

| Service | Port | Purpose |
|---------|------|---------|
| HTTP API (GodotBridge) | 8081 | Remote control, DAP/LSP access |
| HTTP API (godottpd) | 8080 | Scene management |
| WebSocket Telemetry | 8081 | Real-time monitoring |
| DAP (Debug Adapter) | 6006 | Breakpoints, stepping |
| LSP (Language Server) | 6005 | Code intelligence |

### Common Commands

**Note**: Most commands require the `Authorization: Bearer $API_TOKEN` header. Set `$API_TOKEN` first.

```bash
# Check server status (no auth required)
curl http://127.0.0.1:8080/status

# List all scenes (requires auth)
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scenes

# Get current scene (requires auth)
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

# Load a scene (requires auth)
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}'

# Connect to debug services (no auth required)
curl -X POST http://127.0.0.1:8080/connect

# Set a breakpoint (requires auth)
curl -X POST http://127.0.0.1:8080/debug/setBreakpoints \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"source":{"path":"res://player.gd"},"breakpoints":[{"line":10}]}'

# Get code completion (requires auth)
curl -X POST http://127.0.0.1:8080/lsp/completion \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"textDocument":{"uri":"file:///path/to/file.gd"},"position":{"line":10,"character":5}}'
```

### Python Client Example

```python
import requests
import os

# Get API token from environment
API_TOKEN = os.getenv("API_TOKEN")

# Set up headers with authentication
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {API_TOKEN}"
}

# Connect to services (no auth required for this endpoint)
requests.post("http://127.0.0.1:8080/connect")

# Check status (no auth required for this endpoint)
status = requests.get("http://127.0.0.1:8080/status").json()
print(f"Ready: {status['overall_ready']}")

# Load a scene (requires authentication)
response = requests.post(
    "http://127.0.0.1:8080/scene",
    headers=headers,
    json={"scene_path": "res://vr_main.tscn"}
)
print(response.json())
```

---

## Troubleshooting

### Authentication Failures?

**Problem**: Getting 401 Unauthorized errors

**Solutions**:
1. **Check if token is set correctly**:
   ```bash
   # Windows PowerShell
   echo $env:API_TOKEN

   # Linux/Mac/Git Bash
   echo $API_TOKEN
   ```

2. **Find the token in Godot console**:
   - Look for `[Security] API token generated: ...`
   - Copy the entire token (64 characters)
   - Set it in your environment

3. **Verify the Authorization header format**:
   ```bash
   # Correct format
   curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

   # Wrong - missing "Bearer"
   curl -H "Authorization: $API_TOKEN" http://127.0.0.1:8080/scene
   ```

4. **Check if Godot is actually running**:
   - Token is regenerated every time Godot restarts
   - Get the new token from console after restart

### Scene Not Whitelisted?

**Problem**: Getting 403 Forbidden with "Scene not in whitelist" message

**Solution**: The API restricts scene loading to a whitelist for security. Default whitelisted scenes:
- `res://vr_main.tscn`
- `res://node_3d.tscn`
- `res://test_scene.tscn`

To add a scene to the whitelist, see [API_TOKEN_GUIDE.md](API_TOKEN_GUIDE.md#scene-whitelist-management).

### Server not responding?

```bash
# Check if Godot is running
tasklist | findstr godot  # Windows
ps aux | grep godot       # Linux/Mac

# Check if port is in use
netstat -ano | findstr 8080  # Windows
lsof -i :8080                # Linux/Mac

# Restart server
restart_godot_with_debug.bat  # Windows
```

### VR not working?

1. Verify SteamVR is running
2. Check headset is connected and detected
3. Ensure OpenXR runtime is set correctly
4. Game will fallback to desktop mode if VR unavailable

### Telemetry not connecting?

1. Ensure Godot is fully started (wait 10 seconds)
2. Check port 8081 is not blocked
3. Verify `websockets` is installed: `pip install websockets`

---

## Next Steps

### Learn More

- **[README.md](README.md)** - Project overview and features
- **[HTTP_API_USAGE_GUIDE.md](HTTP_API_USAGE_GUIDE.md)** - Complete HTTP API reference
- **[TELEMETRY_GUIDE.md](TELEMETRY_GUIDE.md)** - Real-time monitoring guide
- **[VR_SETUP_GUIDE.md](VR_SETUP_GUIDE.md)** - Detailed VR configuration
- **[CLAUDE.md](CLAUDE.md)** - AI assistant development instructions

### Try Examples

```bash
# Python examples
cd examples
python python_ai_client.py        # AI client library
python debug_session_example.py   # Debug session workflow
python code_editing_example.py    # Code editing workflow

# Scene management
python scene_loader_client.py status
python scene_loader_client.py list
python scene_loader_client.py load "res://vr_main.tscn"
```

### Run Tests

```bash
# HTTP API tests
cd tests/http_api
python -m pytest test_scene_endpoints.py -v

# GDScript unit tests (requires GdUnit4)
cd tests
# Use GdUnit4 panel in Godot editor

# Property-based tests
cd tests/property
python -m pytest test_*.py
```

### Development Workflow

1. **Start server** with debug flags
2. **Connect to services** via `/connect` endpoint
3. **Monitor telemetry** with `telemetry_client.py`
4. **Make changes** in Godot Editor
5. **Test via HTTP API** with Python scripts
6. **Debug with DAP** through remote connection
7. **Run tests** before committing

See [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) for complete workflow.

---

## Quick Architecture Overview

```
┌─────────────────────────────────────────────┐
│           Godot Engine 4.5                  │
│  ┌─────────────────────────────────────┐   │
│  │     ResonanceEngine (Autoload)      │   │
│  │  - Manages all subsystems           │   │
│  │  - VR, Physics, Audio, etc.         │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ GodotBridge│ │TelemetryServer│ │HttpApiServer││
│  │  :8080   │  │  :8081   │  │  :8080   │ │
│  └──────────┘  └──────────┘  └──────────┘ │
└─────────────────────────────────────────────┘
         ↓              ↓              ↓
   ┌──────────┐  ┌──────────┐  ┌──────────┐
   │ HTTP API │  │WebSocket │  │ REST API │
   │ DAP/LSP  │  │Telemetry │  │  Scenes  │
   └──────────┘  └──────────┘  └──────────┘
         ↓              ↓              ↓
   ┌────────────────────────────────────────┐
   │       AI Clients / Monitoring Tools    │
   └────────────────────────────────────────┘
```

---

## Development Services at a Glance

### GodotBridge (Port 8080)
- Remote control via HTTP REST API
- DAP integration (breakpoints, stepping, evaluation)
- LSP integration (completion, definitions, references)
- Connection management with circuit breaker
- **Use for**: Remote debugging, code intelligence

### TelemetryServer (Port 8081)
- WebSocket streaming of real-time data
- Binary protocol + GZIP compression
- FPS, VR tracking, events, snapshots
- Multi-client support
- **Use for**: Performance monitoring, VR tracking

### HttpApiServer (Port 8080)
- Scene loading and management
- Scene discovery and listing
- Scene validation before loading
- Load history tracking
- **Use for**: Automated testing, scene switching

### DAP (Port 6006)
- Debug Adapter Protocol
- Breakpoint management
- Program execution control
- Variable inspection
- **Use for**: Interactive debugging

### LSP (Port 6005)
- Language Server Protocol
- Code completion
- Go to definition
- Find references
- **Use for**: Code editing assistance

---

## Success Checklist

After completing this guide, you should be able to:

- ✅ Start Godot with debug services
- ✅ Verify HTTP API is responding
- ✅ Make API calls to query and control scenes
- ✅ Monitor real-time telemetry data
- ✅ Connect to debug services (DAP/LSP)
- ✅ Load and run the VR scene
- ✅ Understand available ports and services
- ✅ Know where to find detailed documentation

---

## Getting Help

### Documentation

- **Quick Start** (this file) - 5-minute setup
- **[HTTP_API_USAGE_GUIDE.md](HTTP_API_USAGE_GUIDE.md)** - HTTP API details
- **[DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md)** - Complete development cycle
- **[addons/godot_debug_connection/README.md](addons/godot_debug_connection/README.md)** - Debug system overview

### Examples

- **[examples/](examples/)** - Python client examples
- **[examples/README.md](examples/README.md)** - Example usage guide

### Testing

- **[tests/README.md](tests/README.md)** - Testing framework setup
- **[tests/http_api/README.md](tests/http_api/README.md)** - HTTP API tests

### Feature Guides

- **[scripts/gameplay/RESONANCE_SYSTEM_GUIDE.md](scripts/gameplay/RESONANCE_SYSTEM_GUIDE.md)** - Resonance mechanics
- **[scripts/player/WALKING_SYSTEM_GUIDE.md](scripts/player/WALKING_SYSTEM_GUIDE.md)** - Walking controls
- **[scripts/core/VR_COMFORT_GUIDE.md](scripts/core/VR_COMFORT_GUIDE.md)** - VR comfort features

---

**Time to Complete**: 5-10 minutes
**Difficulty**: Beginner
**Last Updated**: December 2, 2025

**Ready to build?** Start with [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) for the complete development cycle!
