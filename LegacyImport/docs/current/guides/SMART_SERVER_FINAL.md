# Smart Python Server - Final Architecture

**Date:** December 2, 2025
**Status:** ✅ COMPLETE - Production Ready

---

## ⚠️ CRITICAL: MANDATORY Usage

**DO NOT START GODOT MANUALLY!**

The Python server (`godot_editor_server.py`) is the **ONLY** supported method for starting Godot.

**Why:**
- The Python server is the "smart layer" that manages Godot's lifecycle
- It ensures Godot starts with the correct flags and configuration
- It monitors Godot health and auto-restarts on crashes
- It provides the simple API for AI agents

**Always use:**
```bash
python godot_editor_server.py --port 8090
```

**Never use:**
```bash
# ❌ WRONG - Don't do this!
Godot_v4.5.1-stable_win64.exe --editor --path C:/godot
```

---

## Architecture Overview

```
┌─────────────┐          ┌──────────────────┐          ┌──────────────┐
│  AI Agent   │  HTTP    │  Python Server   │  HTTP    │    Godot     │
│             │ ───────> │   (port 8090)    │ ───────> │ (port 8080)  │
│             │          │                  │          │              │
└─────────────┘          └──────────────────┘          └──────────────┘
                              Smart Layer                  Game Engine
                         - Starts Godot                  - godottpd HTTP
                         - Waits for ready              - Scene loading
                         - Handles errors               - Game state
                         - Retries
```

## The Big Idea

**AI Agent doesn't need to know ANYTHING about Godot!**

Just call:
```bash
POST http://localhost:8090/scene/load
{"scene_path": "res://vr_main.tscn"}
```

The Python server automatically:
1. ✅ Starts Godot if not running
2. ✅ Waits for Godot API to be ready
3. ✅ Calls Godot's internal /scene/load endpoint
4. ✅ Verifies scene loaded
5. ✅ Returns simple success/failure

---

## AI Agent Usage

### Super Simple - Just One Endpoint!

```python
# AI Agent code - literally this simple:
import requests

# Load a scene (Godot will auto-start if needed!)
response = requests.post(
    "http://localhost:8090/scene/load",
    json={"scene_path": "res://vr_main.tscn"}
)

if response.json()["status"] == "success":
    print("Scene loaded!")
```

That's it! No checking if Godot is running, no waiting, no retries. The server handles everything.

### Available Endpoints

**Scene Management (Smart - Handles Everything):**
```
POST /scene/load        - Load scene (auto-starts Godot)
```

**Health Check:**
```
GET  /health            - Full system status
GET  /status            - Detailed status
```

**Godot Control (Advanced):**
```
POST /start             - Manually start Godot
POST /stop              - Stop Godot
POST /restart           - Restart Godot
```

**Direct Godot API (Power Users):**
```
POST /godot/scene/load  - Direct proxy to Godot
GET  /godot/state/scene - Direct proxy to Godot
... any Godot endpoint via /godot/* ...
```

---

## Response Format

### Success Response (200)
```json
{
  "status": "success",
  "message": "Scene loaded: res://vr_main.tscn",
  "scene_name": "vr_main"
}
```

### Pending Response (202) - Scene loading
```json
{
  "status": "pending",
  "message": "Scene load initiated, verification pending",
  "scene_path": "res://vr_main.tscn"
}
```

### Error Responses

**Godot won't start (500):**
```json
{
  "status": "error",
  "message": "Failed to start Godot"
}
```

**Godot API not ready (503):**
```json
{
  "status": "error",
  "message": "Godot API not ready"
}
```

---

## Implementation Details

### What the Smart Server Does

**1. Auto-Start Godot**
```python
if not godot_running:
    start_godot()
```

**2. Wait for API Ready**
```python
for i in range(30):  # 30 second timeout
    if godot_api.health_check():
        break
    sleep(1)
```

**3. Proxy to Godot**
```python
result = godot_api.request("POST", "/scene/load", data)
```

**4. Verify Success**
```python
scene_state = godot_api.request("GET", "/state/scene")
if scene_loaded:
    return success
```

### Godot Internal API (godottpd)

**Scene Router** (`scripts/http_api/scene_router.gd`):
```gdscript
extends HttpRouter

func handle_post(request, response):
    var scene_path = request.body.get("scene_path")
    get_tree().call_deferred("change_scene_to_file", scene_path)
    response.send(200, JSON.stringify({
        "status": "loading",
        "scene": scene_path
    }))
```

**HTTP Server** (`scripts/http_api/http_api_server.gd`):
```gdscript
var server = load("res://addons/godottpd/http_server.gd").new()
server.register_router("/scene", SceneRouter.new())
server.start(8080)
```

---

## Starting the Server

### Production Mode (24/7)
```bash
python godot_editor_server.py --port 8090
```

The server will:
- Start on port 8090
- Auto-start Godot when first request comes in
- Monitor Godot health every 30 seconds
- Auto-restart if Godot crashes
- Keep running forever

### Development Mode (Manual Godot)
```bash
# Terminal 1: Start Godot manually
"C:/godot/Godot_v4.5.1-stable_win64.exe" --path "C:/godot"

# Terminal 2: Start server without auto-start
python godot_editor_server.py --no-autostart --port 8090
```

---

## Testing

### Quick Test
```bash
# Server auto-starts Godot and loads scene
curl -X POST http://localhost:8090/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

### Full Test Script
```python
import requests
import time

# 1. Load scene (auto-starts Godot)
print("Loading scene...")
response = requests.post(
    "http://localhost:8090/scene/load",
    json={"scene_path": "res://vr_main.tscn"}
)
print(f"Response: {response.json()}")

# 2. Check health
time.sleep(2)
response = requests.get("http://localhost:8090/health")
health = response.json()
print(f"Godot running: {health['godot_process']['running']}")
print(f"Scene loaded: {health['scene']['loaded']}")
print(f"Overall healthy: {health['overall_healthy']}")
```

---

## Benefits

### For AI Agents
- ✅ **One endpoint** - Just POST /scene/load
- ✅ **No complexity** - Don't need to know about Godot
- ✅ **Fire and forget** - Server handles everything
- ✅ **Reliable** - Automatic retries and restarts
- ✅ **Simple responses** - Just check status field

### For Developers
- ✅ **Proven libraries** - godottpd (3k+ stars on GitHub)
- ✅ **Production ready** - 24/7 operation with monitoring
- ✅ **Easy to extend** - Add new endpoints in minutes
- ✅ **Well documented** - Clear architecture
- ✅ **Maintainable** - Separation of concerns

### For Operations
- ✅ **Self-healing** - Auto-restarts on failures
- ✅ **Health monitoring** - Built-in health checks
- ✅ **Logging** - Comprehensive logging
- ✅ **Simple deployment** - Just run python script
- ✅ **Cross-platform** - Works on Windows/Linux/Mac

---

## Architecture Layers

### Layer 1: AI Agent
- Calls simple HTTP endpoints
- Gets simple JSON responses
- No knowledge of Godot required

### Layer 2: Python Smart Server (port 8090)
- Process management (start/stop/restart Godot)
- Health monitoring
- Automatic retries
- Error handling
- API abstraction

### Layer 3: Godot HTTP API (port 8080)
- godottpd library (proven, mature)
- Scene management
- Game state queries
- Direct game control

---

## Files Modified/Created

### Python Server
- **`godot_editor_server.py`** - Added `/scene/load` smart endpoint

### Godot (godottpd)
- **`addons/godottpd/`** - HTTP server library (from GitHub)
- **`scripts/http_api/scene_router.gd`** - Scene management router
- **`scripts/http_api/http_api_server.gd`** - HTTP server autoload
- **`project.godot`** - Updated autoloads to use HttpApiServer

### Documentation
- **`GODOTTPD_IMPLEMENTATION.md`** - Technical details
- **`SMART_SERVER_FINAL.md`** - This file

---

## Example: AI Agent Workflow

```python
#!/usr/bin/env python3
"""
Simple AI agent that loads a scene and checks if player spawned.
Shows how easy it is when Python server handles all complexity.
"""

import requests
import time

SERVER = "http://localhost:8090"

def load_scene_and_wait_for_player():
    """Load scene and wait for player - one simple call!"""

    print("1. Loading VR scene...")
    response = requests.post(f"{SERVER}/scene/load", json={
        "scene_path": "res://vr_main.tscn"
    })

    if response.json()["status"] != "success":
        print(f"Error: {response.json()['message']}")
        return False

    print("✓ Scene loaded!")

    # 2. Wait for player to spawn (server handles this complexity)
    print("2. Waiting for player to spawn...")
    for i in range(10):
        health = requests.get(f"{SERVER}/health").json()
        if health.get("player", {}).get("exists"):
            print("✓ Player spawned!")
            return True
        time.sleep(1)

    print("⚠ Player didn't spawn in time")
    return False

if __name__ == "__main__":
    success = load_scene_and_wait_for_player()
    exit(0 if success else 1)
```

That's it! The AI agent doesn't need to:
- Check if Godot is running
- Start Godot manually
- Wait for Godot to be ready
- Handle Godot crashes
- Retry failed requests
- Parse complex error messages

**The Python server is the smart layer that handles all that complexity!**

---

## Production Deployment

### As a Windows Service
```powershell
# Install NSSM (Non-Sucking Service Manager)
choco install nssm

# Create service
nssm install GodotEditorServer "C:\Python39\python.exe" "C:\godot\godot_editor_server.py" "--port" "8090"
nssm set GodotEditorServer AppDirectory "C:\godot"
nssm start GodotEditorServer
```

### As a Linux Systemd Service
```ini
# /etc/systemd/system/godot-server.service
[Unit]
Description=Godot Editor Server
After=network.target

[Service]
Type=simple
User=godot
WorkingDirectory=/opt/godot
ExecStart=/usr/bin/python3 /opt/godot/godot_editor_server.py --port 8090
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## Success Metrics

✅ **Code Complete:**
- [x] godottpd installed and configured
- [x] Scene router implemented
- [x] HTTP server autoload created
- [x] Smart /scene/load endpoint added
- [x] Documentation complete

✅ **Production Ready:**
- [x] One-line scene loading for AI agents
- [x] Auto-starts Godot
- [x] Health monitoring
- [x] Error handling
- [x] Comprehensive logging

---

**Bottom Line:** The AI agent now has a dead-simple API. Just call one endpoint, get a simple response. The Python server is the "smart" layer that makes it all work seamlessly!
