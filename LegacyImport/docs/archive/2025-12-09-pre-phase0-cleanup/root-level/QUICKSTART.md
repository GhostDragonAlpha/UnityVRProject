# SpaceTime VR - Quick Start Guide

**Get running in 5 minutes!**

---

## Prerequisites (1 minute)

Check you have these installed:

- ✅ **Godot 4.5.1+** - Download from https://godotengine.org/
- ✅ **Python 3.8+** - For testing and monitoring
- ⚠️ **VR Headset** (optional) - Falls back to desktop mode if not available

**Quick check:**
```bash
godot --version  # Should show 4.5.1 or higher
python --version  # Should show 3.8.0 or higher
```

---

## Step 1: Start Godot (2 minutes)

### Method 1: Smart Server (Recommended)

```bash
cd C:/godot
python godot_editor_server.py --port 8090
```

The smart server will:
- Auto-start Godot with correct flags
- Monitor health and auto-restart on crashes
- Provide simple HTTP API on port 8090

### Method 2: Direct Launch (Alternative)

```bash
# Windows
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Linux/Mac
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005
```

**IMPORTANT:** MUST run in GUI mode (not --headless). Headless causes debug servers to stop.

---

## Step 2: Get Your API Token (30 seconds)

When Godot starts, look for this in the console:

```
=== GODOT BRIDGE INITIALIZATION ===
API Token Generated: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Token expires: Never (valid for session)
```

**Copy the token** and save it:

```bash
# Windows (PowerShell)
$env:GODOT_API_TOKEN = "paste_your_token_here"

# Linux/Mac
export GODOT_API_TOKEN="paste_your_token_here"
```

---

## Step 3: Test the API (1 minute)

### Quick Health Check

```bash
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8080/status
```

**Expected response:**
```json
{
  "debug_adapter": {
    "overall_ready": true,
    "state": 2
  },
  "language_server": {
    "overall_ready": true,
    "state": 2
  }
}
```

### Python Test

```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}

response = requests.get("http://127.0.0.1:8080/status", headers=headers)
print(response.json())
```

---

## Step 4: Run the VR Scene (1 minute)

### From Godot Editor

1. Press **F5** or click the **Play** button
2. VR scene launches automatically
3. Put on your headset!

**No VR headset?** The scene automatically falls back to desktop mode.

### Test Runtime Features

```bash
# Install dependencies
pip install requests websockets

# Run comprehensive test suite
python test_runtime_features.py
```

**Expected output:**
```
Testing HTTP API...           ✓ PASS
Testing Authentication...     ✓ PASS
Testing Telemetry Stream...   ✓ PASS
Testing Resonance System...   ✓ PASS
All tests passed!
```

---

## Step 5: Monitor Telemetry (30 seconds)

Open a new terminal and run:

```bash
python telemetry_client.py
```

**You'll see:**
```
Connected to telemetry server at ws://127.0.0.1:8081
Receiving telemetry...

FPS: 90.2 | VR: true | Headset: Quest 2
Position: (0.5, 1.7, -2.3)
Rotation: (0.0, 45.2, 0.0)
Controllers: Left(active) Right(active)
```

---

## Common First-Time Tasks

### Task 1: Apply Resonance Interference

```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}

response = requests.post(
    "http://127.0.0.1:8080/resonance/apply_interference",
    headers=headers,
    json={
        "object_frequency": 440.0,  # A4 note
        "object_amplitude": 1.0,
        "emit_frequency": 440.0,    # Perfect match
        "interference_type": "constructive"
    }
)

print(response.json())
# Output: {"success": true, "new_amplitude": 2.0, "resonance_score": 1.0}
```

### Task 2: List Available Scenes

```bash
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8080/scenes
```

### Task 3: Set a Breakpoint (Editor Only)

```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}

response = requests.post(
    "http://127.0.0.1:8080/debug/setBreakpoints",
    headers=headers,
    json={
        "source": {"path": "res://scripts/player/spacecraft.gd"},
        "breakpoints": [{"line": 45}]
    }
)
```

---

## Troubleshooting

### Problem: 401 Unauthorized

**Cause:** Token not set or invalid

**Fix:**
```bash
# Check token is set
echo $GODOT_API_TOKEN

# If empty, copy token from Godot console and export it
export GODOT_API_TOKEN="eyJhbGciOiJIUzI1NiIs..."
```

### Problem: Connection Refused

**Cause:** Godot not running or port blocked

**Fix:**
```bash
# Check Godot is running
ps aux | grep godot

# Check port is listening
netstat -an | grep 8080

# Try fallback ports
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8083/status
```

### Problem: Telemetry Not Connecting

**Cause:** WebSocket server not started

**Fix:**
```bash
# Wait 10 seconds after Godot starts
# Check WebSocket port
netstat -an | grep 8081

# Verify in Godot console
# Should see: "WebSocket telemetry server started on ws://127.0.0.1:8081"
```

### Problem: VR Not Working

**Cause:** SteamVR or OpenXR runtime not running

**Fix:**
1. Start SteamVR
2. Ensure headset is connected and detected
3. Check OpenXR runtime is set (Settings → OpenXR)
4. Restart Godot

**Don't have VR?** The scene works in desktop mode automatically!

---

## What's Next?

### Learn More

- **API Reference:** `addons/godot_debug_connection/HTTP_API.md`
- **Security Guide:** `SECURITY.md`
- **Full Documentation:** `CLAUDE.md`
- **Troubleshooting:** `TROUBLESHOOTING.md`

### Explore Features

```bash
# Run all tests
python tests/test_runner.py

# Run health checks
python tests/health_monitor.py

# Monitor system
python telemetry_client.py
```

### Build for Production

```bash
# Export standalone executable
godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"

# Run the build
./build/SpaceTime.exe
```

---

## API Quick Reference

### Authentication
```python
headers = {"Authorization": f"Bearer {token}"}
```

### Common Endpoints
```python
# Health check
GET /status

# Resonance control
POST /resonance/apply_interference

# Scene management
GET /scenes
POST /scene
POST /scene/reload

# Debug (editor only)
POST /debug/setBreakpoints
POST /debug/continue
GET /debug/threads
```

### Telemetry Stream
```python
import asyncio
import websockets

async def monitor():
    async with websockets.connect('ws://127.0.0.1:8081') as ws:
        async for message in ws:
            print(message)

asyncio.run(monitor())
```

---

## Development Workflow

**Daily Workflow:**
1. Start Godot: `python godot_editor_server.py --port 8090`
2. Get token from console
3. Export token: `export GODOT_API_TOKEN="..."`
4. Test features: `python test_runtime_features.py`
5. Monitor telemetry: `python telemetry_client.py`
6. Make changes in Godot Editor
7. Test via HTTP API
8. Run tests before committing: `python tests/test_runner.py`

---

## Service Ports Reference

| Service | Port | Protocol | Status |
|---------|------|----------|--------|
| HTTP API | 8081* | HTTP | Runtime + Editor |
| Telemetry | 8081 | WebSocket | Runtime + Editor |
| Smart Server | 8090 | HTTP | Optional |
| DAP | 6006 | TCP | Editor only |
| LSP | 6005 | TCP | Editor only |
| Discovery | 8087 | UDP | Runtime + Editor |

*Fallback ports: 8083, 8084, 8085

---

## Success Checklist

After following this guide, you should be able to:

- [x] Start Godot with debug services
- [x] Get and use JWT authentication token
- [x] Make authenticated API requests
- [x] Run the VR scene (or desktop fallback)
- [x] Monitor real-time telemetry
- [x] Control resonance system via API
- [x] Set breakpoints and debug (if using editor)

**All checked?** Congratulations! You're ready to develop with SpaceTime VR!

---

## Quick Commands Cheat Sheet

```bash
# Start Godot (smart server)
python godot_editor_server.py --port 8090

# Start Godot (direct)
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Export token
export GODOT_API_TOKEN="paste_token_here"

# Test API
curl -H "Authorization: Bearer $GODOT_API_TOKEN" http://127.0.0.1:8080/status

# Run tests
python test_runtime_features.py

# Monitor telemetry
python telemetry_client.py

# Run health checks
python tests/health_monitor.py

# Build for production
godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"
```

---

**Need Help?**
- See `TROUBLESHOOTING.md` for common issues
- See `SECURITY.md` for security questions
- See `CLAUDE.md` for complete documentation
- Check error logs in Godot console

**Ready to go deeper?** Check out the full documentation and API reference!

---

**Quick Start Guide Version:** 1.0
**Last Updated:** 2025-12-02
**Estimated Time:** 5 minutes
