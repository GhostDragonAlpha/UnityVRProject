# Player Monitor Flow Diagram

## Initialization Sequence

```
┌─────────────────────────────────────────────────────────────────┐
│ python godot_editor_server.py --auto-load-scene                │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │ 1. Start Godot Process          │
        │    - Launch Godot editor        │
        │    - Flags: --dap-port 6006     │
        │    - Flags: --lsp-port 6005     │
        │    - Wait 5s for init           │
        └─────────────┬───────────────────┘
                      │ (~5 seconds)
                      ▼
        ┌─────────────────────────────────┐
        │ 2. Wait for API Ready           │
        │    - Poll GET /status           │
        │    - Retry every 1s             │
        │    - Timeout: 30s               │
        └─────────────┬───────────────────┘
                      │ (~5-10 seconds)
                      ▼
        ┌─────────────────────────────────┐
        │ 3. SceneLoader.load_scene()     │
        │    - Check if scene loaded      │
        │    - Execute change_scene_to()  │
        │    - Verify scene loaded        │
        │    - Retry up to 3 times        │
        └─────────────┬───────────────────┘
                      │ (~2-5 seconds)
                      ▼
        ┌─────────────────────────────────┐
        │ 4. Scene Loads: vr_main.tscn    │
        │    - VR scene tree created      │
        │    - vr_setup.gd:_ready() runs  │
        │    - _setup_planetary()         │
        └─────────────┬───────────────────┘
                      │ (async)
                      ▼
        ┌─────────────────────────────────┐
        │ 5. PlayerMonitor.wait_for_player│
        │    - Poll GET /state/player     │
        │    - Every 1 second             │
        │    - Timeout: 30s (configurable)│
        └─────────────┬───────────────────┘
                      │
                      │ (parallel)
                      │
        ┌─────────────▼───────────────────┐
        │ Player Spawn Process            │
        │ ┌─────────────────────────────┐ │
        │ │ vr_setup.gd spawns player:  │ │
        │ │ 1. Create PlayerSpawnSystem │ │
        │ │ 2. Generate voxel terrain   │ │
        │ │    (50 chunks, 5×5×2)       │ │
        │ │ 3. Create test planet       │ │
        │ │ 4. spawn_player() at (0,2,0)│ │
        │ │ 5. Player node added        │ │
        │ └─────────────────────────────┘ │
        └─────────────┬───────────────────┘
                      │ (~5-10 seconds)
                      ▼
        ┌─────────────────────────────────┐
        │ 6. Player Detected              │
        │    - GET /state/player          │
        │      returns {"exists": true}   │
        │    - PlayerMonitor returns True │
        │    - Log success message        │
        └─────────────┬───────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────┐
        │ 7. Start HTTP Server            │
        │    - Listen on port 8090        │
        │    - Start health monitor       │
        │    - Server ready for requests  │
        └─────────────┬───────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────┐
        │ 8. Ready for Testing            │
        │    - Scene loaded ✓             │
        │    - Player spawned ✓           │
        │    - Health: overall_healthy ✓  │
        └─────────────────────────────────┘
```

**Total Time:** ~15-25 seconds from cold start to fully ready

---

## Player Monitor Polling Loop

```
wait_for_player(timeout=30):
    │
    ├─ Start timer
    │
    └─┬─ LOOP (every 1 second):
      │
      ├─ Poll: GET /state/player
      │
      ├─ Response: {"exists": true/false}
      │
      ├─ If exists == true:
      │   └─> Log success, return True
      │
      ├─ If exists == false:
      │   └─> Continue polling
      │
      └─ If timeout reached:
          └─> Log error, return False
```

---

## Scene Loader Retry Logic

```
load_scene(max_retries=3):
    │
    └─┬─ FOR attempt in 1..3:
      │
      ├─ Check: GET /state/scene
      │
      ├─ If already loaded:
      │   └─> Return True
      │
      ├─ Execute: POST /execute/script
      │   └─> Code: get_tree().change_scene_to_file(...)
      │
      ├─ Wait 2 seconds
      │
      ├─ Verify: GET /state/scene
      │
      ├─ If loaded:
      │   └─> Return True
      │
      └─ If not loaded:
          └─> Retry (wait 2s before next attempt)
```

---

## Health Endpoint Flow

```
GET /health
    │
    ├─ Check: Godot process running?
    │
    ├─ Check: Godot API reachable?
    │
    ├─ Check: GET /state/scene
    │   └─> Scene loaded?
    │
    ├─ Check: GET /state/player
    │   └─> Player spawned?
    │
    ├─ Calculate: overall_healthy
    │   └─> All checks must pass
    │
    └─> Return JSON with status
```

---

## API Endpoints Used

```
Server                          Godot API
  │                                │
  ├─ GET /health ─────────────────>├─ GET /status
  │                                ├─ GET /state/scene
  │                                └─ GET /state/player
  │                                │
  ├─ POST /godot/execute/script ──>├─ Execute GDScript
  │                                │   (scene loading)
  │                                │
  └─ GET /godot/state/* ──────────>└─ Query game state
```

---

## Error Handling

```
Initialization Flow:
    │
    ├─ Godot process fails?
    │   └─> Log error, exit(1)
    │
    ├─ API not ready after 30s?
    │   └─> Log warning, continue
    │
    ├─ Scene load fails (3 retries)?
    │   └─> Log error, skip player spawn
    │
    ├─ Player spawn timeout?
    │   └─> Log warning, continue
    │       (server starts but tests may fail)
    │
    └─ Health monitor detects failure?
        └─> Auto-restart Godot (up to 3 attempts)
```

---

## Class Interactions

```
┌───────────────────────┐
│ GodotProcessManager   │  Manages Godot editor process
│ ─────────────────────│
│ + start()             │  Start Godot
│ + stop()              │  Stop Godot
│ + is_running()        │  Check if running
└───────────────────────┘
           │
           │ uses
           ▼
┌───────────────────────┐
│ GodotAPIClient        │  HTTP client for Godot API
│ ─────────────────────│
│ + request()           │  Make HTTP request
│ + health_check()      │  Check API ready
└───────────────────────┘
           │
           │ used by
           ▼
┌───────────────────────┐
│ SceneLoader           │  Loads and verifies scene
│ ─────────────────────│
│ + check_scene_loaded()│  Check via API
│ + load_scene()        │  Load with retries
└───────────────────────┘
           │
           │ then
           ▼
┌───────────────────────┐
│ PlayerMonitor         │  Waits for player spawn
│ ─────────────────────│
│ + check_player_exists()│ Poll API
│ + wait_for_player()   │  Poll with timeout
└───────────────────────┘
           │
           │ reports to
           ▼
┌───────────────────────┐
│ HealthMonitor         │  Monitors system health
│ ─────────────────────│
│ + start()             │  Start monitoring thread
│ + _monitor_loop()     │  Continuous health checks
└───────────────────────┘
```

---

## State Transitions

```
Server State Machine:

STARTING ──> API_WAITING ──> SCENE_LOADING ──> PLAYER_WAITING ──> READY
   │              │               │                  │               │
   │              │               │                  │               └─> Tests can run
   │              │               │                  │
   │              │               │                  └─> Player spawn detected
   │              │               │
   │              │               └─> Scene loaded successfully
   │              │
   │              └─> Godot API responsive
   │
   └─> Godot process started

Error States:

STARTING ──X──> FAILED (Godot won't start)
   │
   └──> API_WAITING ──timeout──> DEGRADED (API not ready)
                  │
                  └──> SCENE_LOADING ──X──> DEGRADED (Scene load failed)
                                    │
                                    └──> PLAYER_WAITING ──timeout──> DEGRADED (Player timeout)
```

---

## Timing Breakdown

| Phase | Time | What Happens |
|-------|------|--------------|
| Godot Start | 5s | Process launches, initializes |
| API Ready | 5-10s | HTTP server starts responding |
| Scene Load | 2-5s | vr_main.tscn loads |
| Player Spawn | 5-10s | vr_setup.gd creates player |
| **Total** | **17-30s** | **Full initialization** |

**Bottlenecks:**
- Godot process startup (platform-dependent)
- Voxel terrain generation (50 chunks)
- OpenXR initialization (if VR available)

**Optimization Opportunities:**
- Pre-load common scenes in project settings
- Reduce initial terrain generation area
- Lazy-load non-critical systems

---

## Success Indicators

**Logs to watch for:**

✓ `Godot process started with PID: XXXXX`
✓ `Godot API is ready`
✓ `Scene res://vr_main.tscn loaded successfully`
✓ `Player spawned successfully after X.Xs (N polls)`
✓ `Player spawn verification complete - system ready for testing`
✓ `Server listening on http://127.0.0.1:8090`

**Health endpoint:**

✓ `"overall_healthy": true`
✓ `"scene": {"loaded": true, "name": "vr_main"}`
✓ `"player": {"spawned": true}`
✓ `"blocking_issues": []`

---

**Ready to Test?** Run `example_server_start_with_player.bat`
