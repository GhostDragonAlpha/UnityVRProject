# Quick Start - Player Monitor

**Goal:** Start Godot editor server with automatic scene loading and player spawn verification.

## 1. Start Server

```bash
# Windows - Use batch script
example_server_start_with_player.bat

# OR manually
python godot_editor_server.py --auto-load-scene
```

## 2. Verify Success

```bash
# Check health endpoint
curl http://127.0.0.1:8090/health

# Expected output:
# {
#   "overall_healthy": true,
#   "scene": {"loaded": true, "name": "vr_main"},
#   "player": {"spawned": true},
#   "blocking_issues": []
# }
```

## 3. Run Tests

```bash
python test_player_monitor.py
```

## 4. Expected Server Output

```
============================================================
Godot Editor Interface Server
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
Server listening on http://127.0.0.1:8090
```

## Troubleshooting

### Player Timeout
**Symptom:** "Player did not spawn within 30s timeout"

**Fix:**
```bash
# Increase timeout to 60s
python godot_editor_server.py --auto-load-scene --player-timeout 60
```

### Scene Not Found
**Symptom:** "Failed to load scene after 3 attempts"

**Fix:** Check scene path exists: `C:\godot\vr_main.tscn`

### API Not Responding
**Symptom:** "Godot API not responding, continuing anyway..."

**Fix:**
1. Wait longer (sometimes takes >30s on first start)
2. Check Godot console for errors
3. Restart server

## Command Reference

```bash
# Basic (defaults)
python godot_editor_server.py --auto-load-scene

# Custom scene
python godot_editor_server.py --auto-load-scene --scene-path "res://test_scene.tscn"

# Longer timeout
python godot_editor_server.py --auto-load-scene --player-timeout 60

# Full options
python godot_editor_server.py \
    --port 8090 \
    --godot-port 8080 \
    --auto-load-scene \
    --scene-path "res://vr_main.tscn" \
    --player-timeout 30
```

## Files Reference

| File | Purpose |
|------|---------|
| `godot_editor_server.py` | Main server implementation |
| `test_player_monitor.py` | Test suite |
| `PLAYER_MONITOR_USAGE.md` | Detailed usage guide |
| `PLAYER_MONITOR_IMPLEMENTATION_REPORT.md` | Technical implementation details |
| `example_server_start_with_player.bat` | Quick start script (Windows) |

---

**Need More Help?** See `PLAYER_MONITOR_USAGE.md` for complete documentation.
