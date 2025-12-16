# Quick Reference: Autonomous Testing & Development

## Daily Workflow

```bash
# 1. Start Godot
python vr_game_controller.py start

# 2. Wait for initialization
sleep 10

# 3. Check scene state
python quick_diagnostic.py

# 4. Make changes, then restart
python vr_game_controller.py stop
python vr_game_controller.py start

# 5. Verify fixes
python quick_diagnostic.py
```

---

## HTTP API Endpoints

```bash
# Server status
curl http://127.0.0.1:8080/status

# Full scene inspection
curl http://127.0.0.1:8080/state/scene

# Formatted output
curl -s http://127.0.0.1:8080/state/scene | python -m json.tool

# Game state
curl http://127.0.0.1:8080/state/game
```

---

## Quick Checks

### Is Godot Running?
```bash
curl -s --max-time 2 http://127.0.0.1:8080/status && echo "Running" || echo "Not running"
```

### Is Player Spawned?
```bash
curl -s http://127.0.0.1:8080/state/scene | python -c "import sys,json; print('YES' if json.load(sys.stdin)['player']['found'] else 'NO')"
```

### Is Player On Ground?
```bash
curl -s http://127.0.0.1:8080/state/scene | python -c "import sys,json; print('YES' if json.load(sys.stdin)['player']['on_floor'] else 'NO')"
```

### Current Gravity?
```bash
curl -s http://127.0.0.1:8080/state/scene | python -c "import sys,json; print(f\"{json.load(sys.stdin)['player']['gravity']:.2f} m/s²\")"
```

---

## Common Issues

### Timeout on /state/scene
**Cause**: Using `find_child()` or collision methods
**Fix**: Use direct paths with `get_node_or_null()`

### Player Not Found
**Cause**: Not spawned yet or async bug
**Fix**: Wait 10s or add `await` to spawn function

### Gravity Too Weak/Strong
**Cause**: Wrong planet mass
**Fix**: Calculate mass = (gravity × radius²) / G

### Player Falling
**Cause**: No ground collision or gravity too strong
**Fix**: Check ground exists and collision layers match

---

## Critical Rules

1. ✓ All tests auto-terminate within 15 seconds
2. ✓ Use direct node paths (never `find_child()` in endpoints)
3. ✓ Check property/method existence before accessing
4. ✓ Add timeouts to all HTTP requests (3s recommended)
5. ✓ Wait 8-10 seconds after Godot start before testing

---

## Expected Values

| Property | Good Value | Bad Value |
|----------|------------|-----------|
| FPS | 90.0 | <60.0 |
| Gravity | 9.8 | <1.0 or >50.0 |
| On Floor | True (when standing) | False (falling) |
| Velocity | [0,0,0] (stable) | Nonzero Y (falling) |
| Jetpack Fuel | 100.0 | <0.0 |

---

## File Locations

| File | Purpose |
|------|---------|
| `quick_diagnostic.py` | Fast scene check |
| `vr_game_controller.py` | Game control |
| `godot_bridge.gd:1038` | Scene inspector |
| `vr_setup.gd:48` | Player spawn |

---

## Documentation

- **Complete Methodology**: `AUTOMATED_TESTING_METHODOLOGY.md`
- **API Reference**: `SCENE_INSPECTION_API.md`
- **Session Summary**: `SESSION_2025-12-01_SCENE_INSPECTION.md`
- **Main Guide**: `CLAUDE.md`

---

## Emergency Commands

```bash
# Force kill Godot
taskkill /F /IM Godot_v4.5.1-stable_win64.exe

# Check if port is in use
netstat -an | grep 8080

# Test HTTP server directly
curl -v http://127.0.0.1:8080/status
```

---

## Sample Good Output

```
[OK] PLAYER FOUND: Player
  Position: [0.0, 2.0, 0.0]
  Velocity: [0.0, 0.0, 0.0]
  On Floor: True
  Gravity: 9.798
  Jetpack Fuel: 100.0
```

## Sample Bad Output

```
[X] PLAYER NOT FOUND
  → Wait longer or check spawn system

[OK] PLAYER FOUND: Player
  On Floor: False
  Velocity: [0.0, -2.5, 0.0]
  → Player is falling! Check ground collision
```

---

**Last Updated**: 2025-12-01
