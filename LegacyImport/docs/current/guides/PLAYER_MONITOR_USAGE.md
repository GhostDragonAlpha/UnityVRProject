# Player Monitor Implementation

**Date:** December 2, 2025
**Status:** Implemented and ready for testing

## Overview

The Godot Editor Server now includes automatic scene loading and player spawn verification via the `--auto-load-scene` flag. This enhancement ensures the game environment is fully initialized before running tests.

## Components Added

### 1. SceneLoader Class

Located in `godot_editor_server.py`, the `SceneLoader` class handles automatic scene loading:

```python
class SceneLoader:
    """Automatically loads and verifies main scene."""

    def __init__(self, api_client: GodotAPIClient, scene_path: str = "res://vr_main.tscn")

    def check_scene_loaded(self) -> bool
        """Check if scene is already loaded."""

    def load_scene(self, max_retries: int = 3, retry_delay: int = 2) -> bool
        """Load the scene if not already loaded, with retries."""
```

**Features:**
- Checks if scene already loaded before attempting to load
- Retries scene loading up to 3 times with 2-second delays
- Verifies scene loaded successfully via `/state/scene` endpoint
- Logs all operations for debugging

### 2. PlayerMonitor Class

Located in `godot_editor_server.py`, the `PlayerMonitor` class verifies player spawn:

```python
class PlayerMonitor:
    """Monitors player node status after scene loading."""

    def __init__(self, api_client: GodotAPIClient)

    def check_player_exists(self) -> bool
        """Check if player node exists via API."""

    def wait_for_player(self, timeout: int = 30) -> bool
        """Wait for player to spawn, up to timeout seconds."""
```

**Features:**
- Polls `/state/player` endpoint every 1 second
- Configurable timeout (default 30 seconds)
- Logs poll count and elapsed time
- Returns `True` if player spawns, `False` on timeout

## Usage

### Starting the Server with Auto-Load

```bash
# Basic usage - auto-load default scene (vr_main.tscn)
python godot_editor_server.py --auto-load-scene

# Custom scene path
python godot_editor_server.py --auto-load-scene --scene-path "res://test_scene.tscn"

# Custom player spawn timeout
python godot_editor_server.py --auto-load-scene --player-timeout 60

# Full example with all options
python godot_editor_server.py \
    --port 8090 \
    --godot-port 8080 \
    --auto-load-scene \
    --scene-path "res://vr_main.tscn" \
    --player-timeout 30
```

### Command-Line Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `--auto-load-scene` | flag | False | Enable automatic scene loading and player verification |
| `--scene-path` | string | `res://vr_main.tscn` | Path to scene to auto-load |
| `--player-timeout` | int | 30 | Timeout for player spawn in seconds |

### Initialization Sequence

When `--auto-load-scene` is enabled, the server follows this sequence:

1. **Start Godot** - Launch Godot editor process
2. **Wait for API** - Wait up to 30s for HTTP API to respond
3. **Load Scene** - Use SceneLoader to load specified scene
   - Checks if already loaded
   - Attempts load via `/execute/script` endpoint
   - Retries up to 3 times on failure
   - Waits 2s between retries
4. **Verify Player** - Use PlayerMonitor to wait for player spawn
   - Polls `/state/player` every 1s
   - Times out after configured timeout
   - Logs progress

## Enhanced Health Endpoint

The `/health` endpoint now includes scene and player status:

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T10:30:00",
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

**Blocking Issues Examples:**
- "Godot process not running"
- "Godot API not reachable"
- "Main scene (vr_main) not loaded"
- "Player node not spawned"

## Testing

### Manual Testing

1. **Start server with auto-load:**
   ```bash
   python godot_editor_server.py --auto-load-scene
   ```

2. **Check health endpoint:**
   ```bash
   curl http://127.0.0.1:8090/health
   ```

3. **Verify scene loaded:**
   ```bash
   curl http://127.0.0.1:8090/godot/state/scene
   ```

4. **Verify player spawned:**
   ```bash
   curl http://127.0.0.1:8090/godot/state/player
   ```

### Automated Testing

Run the test suite:

```bash
# Start server in one terminal
python godot_editor_server.py --auto-load-scene

# Run tests in another terminal
python test_player_monitor.py
```

The test script verifies:
- ✓ Server health check passes
- ✓ Scene loaded successfully
- ✓ Player spawned successfully
- ✓ Player movement works

## Expected Output

When starting with `--auto-load-scene`, you should see:

```
============================================================
Godot Editor Interface Server
============================================================
Server Port: 8090
Godot API Port: 8080
Godot Path: C:/godot/Godot_v4.5.1-stable_win64.exe
Project Path: C:/godot
============================================================
Starting Godot editor...
Godot process started with PID: 12345
Waiting for Godot API to be ready...
Godot API is ready
============================================================
Auto-loading scene and verifying player spawn
============================================================
Scene res://vr_main.tscn already loaded
Waiting for player to spawn (timeout: 30s)...
Player spawned successfully after 5.2s (6 polls)
Player spawn verification complete - system ready for testing
============================================================
Health monitor started
Server listening on http://127.0.0.1:8090
Endpoints:
  GET  /health          - Health check
  GET  /status          - Detailed status
  POST /restart         - Restart Godot
  POST /start           - Start Godot
  POST /stop            - Stop Godot
  *    /godot/*         - Proxy to Godot API
============================================================
Press Ctrl+C to stop
```

## Integration with vr_setup.gd

The player spawns via `vr_setup.gd:_ready()`:

1. `_ready()` is called when vr_main scene loads
2. `_setup_planetary_survival()` creates PlayerSpawnSystem
3. `spawn_system.spawn_player()` creates player node
4. Player node becomes visible to `/state/player` endpoint
5. PlayerMonitor detects player and returns success

**Timing:** Player spawn typically completes in 3-10 seconds after scene load, depending on:
- Voxel terrain generation (50 chunks)
- Test planet initialization
- PlayerSpawnSystem initialization

## Error Handling

### Scene Load Failures

If scene fails to load after 3 retries:
```
ERROR: Failed to load scene after 3 attempts
```

**Common causes:**
- Scene file doesn't exist at specified path
- Godot API not responding
- Scene has errors preventing load

**Solution:** Check Godot console for errors, verify scene path

### Player Spawn Timeout

If player doesn't spawn within timeout:
```
ERROR: Player did not spawn within 30s timeout (30 polls)
WARNING: Player did not spawn within 30s - tests may fail
```

**Common causes:**
- vr_setup.gd:_ready() not executing
- PlayerSpawnSystem failed to initialize
- Spawn position invalid

**Solution:** Check Godot console, increase timeout, verify vr_setup.gd

## API Endpoints Used

The implementation uses these Godot HTTP API endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/status` | GET | Check if Godot API responsive |
| `/state/scene` | GET | Check if vr_main scene loaded |
| `/state/player` | GET | Check if player node exists |
| `/execute/script` | POST | Execute GDScript to load scene |

## Future Enhancements

Potential improvements:
- [ ] Add `/player/spawn` endpoint to force player spawn
- [ ] Support multiple scene types (not just vr_main)
- [ ] Add scene unload functionality
- [ ] Monitor player health/state during testing
- [ ] Add player respawn on death detection

## Troubleshooting

### Player Monitor Never Completes

**Symptom:** `wait_for_player()` times out after 30s

**Check:**
1. Is vr_main scene loaded? `curl http://127.0.0.1:8090/godot/state/scene`
2. Check Godot console for vr_setup.gd errors
3. Verify PlayerSpawnSystem exists in scene tree
4. Check if player spawn position is valid

**Solution:** Increase timeout or check vr_setup.gd

### Scene Loader Retries Infinitely

**Symptom:** Scene load attempts keep retrying

**Check:**
1. Is scene path correct? `res://vr_main.tscn`
2. Does scene file exist in project?
3. Check Godot console for scene errors

**Solution:** Fix scene errors or update scene path

## Performance Impact

**Startup Time:**
- Without auto-load: ~10-15 seconds (Godot start + API ready)
- With auto-load: ~20-30 seconds (+ scene load + player spawn)

**Resource Usage:**
- Minimal additional memory (SceneLoader/PlayerMonitor are lightweight)
- No ongoing CPU usage (monitoring happens once at startup)

## Conclusion

The PlayerMonitor implementation provides a robust, automated way to ensure the game environment is fully initialized before running tests. This eliminates the "scene not loaded" and "player not spawned" errors that previously blocked automated testing.

**Key Benefits:**
- ✓ Tests can run immediately after server starts
- ✓ No manual scene loading required
- ✓ Reliable player spawn verification
- ✓ Enhanced health reporting
- ✓ Configurable timeouts for different environments
