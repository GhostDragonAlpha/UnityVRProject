# Scene Loader Quick Start Guide

## Quick Start

### Start Server with Auto-Loading

```bash
python godot_editor_server.py --auto-load-scene
```

This will:
1. Start Godot editor
2. Load vr_main.tscn automatically
3. Wait for player to spawn (up to 30 seconds)
4. Report when ready for testing

### Check if Ready

```bash
curl http://127.0.0.1:8090/health
```

Look for:
- `"overall_healthy": true` - System is ready
- `"blocking_issues": []` - No issues detected

### Custom Configuration

```bash
# Load different scene
python godot_editor_server.py --auto-load-scene --scene-path res://test_scene.tscn

# Longer timeout for player spawn
python godot_editor_server.py --auto-load-scene --player-timeout 60

# Both
python godot_editor_server.py --auto-load-scene --scene-path res://test.tscn --player-timeout 60
```

## What Gets Loaded

When `--auto-load-scene` is enabled:

1. **Scene Loading**
   - Executes: `get_tree().change_scene_to_file("res://vr_main.tscn")`
   - Retries: Up to 3 times with 2-second delays
   - Verifies: Scene loaded via `/state/scene` endpoint

2. **Player Spawn**
   - Polls: `/state/player` every 1 second
   - Timeout: 30 seconds (configurable)
   - Success: When `exists=true`

## Health Check Response

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T...",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": true
  },
  "scene": {
    "loaded": true,
    "name": "vr_main"
  },
  "player": {
    "spawned": true
  },
  "overall_healthy": true,
  "blocking_issues": []
}
```

## Python Usage

```python
import requests
import time

# Wait for server to be ready
def wait_for_ready(timeout=60):
    start = time.time()
    while time.time() - start < timeout:
        try:
            health = requests.get("http://127.0.0.1:8090/health").json()
            if health["overall_healthy"]:
                return True
        except:
            pass
        time.sleep(1)
    return False

# Use in tests
if wait_for_ready():
    print("Ready for testing!")
    # Run tests...
else:
    print("Timeout waiting for server")
```

## Troubleshooting

### Scene Doesn't Load

**Check logs for:**
```
[ERROR] Failed to load scene after 3 attempts
```

**Solutions:**
1. Verify scene exists: Check `res://vr_main.tscn`
2. Check scene for errors in Godot editor
3. Restart with: `--scene-path` to specify correct path

### Player Doesn't Spawn

**Check logs for:**
```
[ERROR] Player did not spawn within 30s timeout
```

**Solutions:**
1. Increase timeout: `--player-timeout 60`
2. Check vr_setup.gd for errors
3. Verify VR system initialization

### Server Not Responding

**Check if running:**
```bash
curl http://127.0.0.1:8090/health
```

**If no response:**
1. Check if server is running
2. Check port not blocked by firewall
3. Verify Godot process started

## Command Reference

```bash
# All available flags
python godot_editor_server.py --help

# Common combinations
--auto-load-scene                    # Enable auto-loading
--scene-path PATH                    # Scene to load
--player-timeout SECONDS             # Player spawn timeout
--port PORT                          # Server port (default: 8090)
--godot-port PORT                    # Godot API port (default: 8080)
--godot-path PATH                    # Godot executable path
--project-path PATH                  # Project directory
--no-autostart                       # Don't start Godot
--no-monitor                         # Disable health monitoring
```

## Testing

Run unit tests:
```bash
python test_scene_loader.py
```

Run demo:
```bash
python demo_scene_loader.py
```

## Next Steps

1. Start server: `python godot_editor_server.py --auto-load-scene`
2. Wait for ready: Check `/health` endpoint
3. Run tests: Player is guaranteed to be spawned
4. Monitor: Check logs for issues

---

For detailed information, see: `SCENE_LOADER_IMPLEMENTATION.md`
