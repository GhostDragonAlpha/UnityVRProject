# Server Enhancement Analysis - Additional Problems to Solve

**Date:** December 2, 2025
**Status:** Analysis Complete

---

## Problems Identified During Testing

### 1. ✗ Scene Not Loading Automatically
**Current Issue:**
- `/state/scene` returns `{"vr_main": "not_found"}`
- Scene must be manually loaded after Godot starts
- Player spawning depends on scene being loaded

**Server Could Solve:**
- Automatically load vr_main.tscn after Godot starts
- Verify scene loaded successfully
- Retry if scene load fails
- Report scene status via `/health` endpoint

**Implementation:**
```python
class SceneManager:
    def load_scene(self, scene_path: str) -> bool:
        # Wait for DAP connection
        # Execute: get_tree().change_scene_to_file(scene_path)
        # Verify scene loaded
        # Return success/failure
```

**Priority:** HIGH - Blocks all player-dependent tests

---

### 2. ✗ Player Node Not Spawning
**Current Issue:**
- `/state/player` returns `{"exists": false}`
- Player spawn depends on vr_setup.gd:_ready() executing
- Movement tests blocked

**Server Could Solve:**
- Verify player spawned after scene load
- Trigger player spawn if not automatic
- Monitor player state continuously
- Report player status via `/health`

**Implementation:**
```python
def verify_player_spawned(self) -> bool:
    response = self.godot_api.request("GET", "/state/player")
    return response and response.get("exists", False)
```

**Priority:** HIGH - Blocks movement/jetpack tests

---

### 3. ✗ DAP/LSP Ports Not Listening
**Current Issue:**
- Ports 6005/6006 not opening even with `--dap-port` flags
- Debug adapter connection fails
- Cannot execute scripts via API

**Server Could Solve:**
- Monitor port status (netstat integration)
- Restart Godot with correct configuration if ports don't open
- Provide diagnostics about why ports aren't listening
- Alternative: Use HTTP API only (current mock endpoints work)

**Implementation:**
```python
def check_debug_ports(self) -> Dict[str, bool]:
    # Check netstat for ports 6005, 6006
    # Return status of each port
```

**Priority:** MEDIUM - DAP not strictly required if HTTP API works

---

### 4. ✗ Test Orchestration Gap
**Current Issue:**
- Tests must manually check if Godot is ready
- No centralized test runner that waits for readiness
- Tests fail if run too early after Godot start

**Server Could Solve:**
- `/tests/run` endpoint that:
  - Verifies Godot ready
  - Loads scene if needed
  - Spawns player if needed
  - Runs specified test suite
  - Returns aggregated results

**Implementation:**
```python
@app.route('/tests/run', methods=['POST'])
def run_tests():
    # Ensure Godot ready
    # Ensure scene loaded
    # Ensure player spawned
    # Run pytest tests/
    # Return results
```

**Priority:** MEDIUM - Nice to have for CI/CD

---

### 5. ✗ Resource Endpoints Use Mock Data
**Current Issue:**
- Resource endpoints return hardcoded data
- Not testing actual Godot systems
- Gives false confidence

**Server Could Solve:**
- Verify resource systems initialized
- Route requests to real systems instead of mocks
- Provide endpoint to check which endpoints are "real" vs "mock"

**Implementation:**
```python
def get_endpoint_status(self) -> Dict[str, str]:
    return {
        "/resources/inventory": "mock",  # Returns hardcoded data
        "/resources/mine": "mock",
        "/terrain/excavate": "real",  # Requires coordinator
        # ...
    }
```

**Priority:** LOW - Mock data sufficient for HTTP API testing

---

### 6. ✗ No Performance Monitoring Over Time
**Current Issue:**
- Can query `/state/scene` for current FPS
- No historical data
- Can't track performance degradation
- No alerts on performance issues

**Server Could Solve:**
- Continuously poll FPS metrics
- Store in memory (last 1000 samples)
- Provide `/metrics/fps` endpoint with statistics
- Alert if FPS drops below threshold

**Implementation:**
```python
class MetricsCollector:
    def __init__(self):
        self.fps_history = deque(maxlen=1000)

    def collect_metrics(self):
        scene_state = api.request("GET", "/state/scene")
        self.fps_history.append({
            "timestamp": time.time(),
            "fps": scene_state["fps"]
        })
```

**Priority:** LOW - Nice to have for monitoring

---

### 7. ✗ No Integration Between Systems
**Current Issue:**
- Mission endpoints return 500 (MissionSystem not found)
- Base building returns 500 (PlanetarySurvivalCoordinator not found)
- Terrain endpoints need coordinator
- No visibility into what's initialized

**Server Could Solve:**
- System initialization endpoint: `/systems/status`
- Shows which autoloads are present
- Shows which systems are initialized
- Provides troubleshooting guidance

**Implementation:**
```python
def check_system_status(self) -> Dict[str, Any]:
    return {
        "PlanetarySurvivalCoordinator": {
            "present": True/False,
            "systems": {
                "voxel_terrain": "initialized",
                "resource_system": "initialized",
                "base_building": "missing"
            }
        }
    }
```

**Priority:** MEDIUM - Helps debug integration issues

---

### 8. ✗ No Automated Test Result Reporting
**Current Issue:**
- Test results scattered across:
  - Python test script output
  - Godot console logs
  - HTTP API responses
  - Server logs
- Hard to get unified view

**Server Could Solve:**
- Aggregate test results
- Provide `/tests/results` endpoint
- Store last N test runs
- Generate test reports

**Priority:** LOW - Manual testing works for now

---

## Recommended Enhancements (Priority Order)

### Phase 1: Critical (Unblock Testing)

1. **Automatic Scene Loading**
   - Add `--auto-load-scene` flag
   - Wait for Godot ready, then load vr_main.tscn
   - Verify scene loaded
   - Report in `/health` endpoint

2. **Player Spawn Verification**
   - Check player exists after scene load
   - Report player status in `/health`
   - Provide `/player/spawn` endpoint if needed

### Phase 2: High Value (Improve Reliability)

3. **System Status Dashboard**
   - `/systems/status` endpoint
   - Shows all autoloads and their state
   - Helps debug initialization issues

4. **Debug Port Monitoring**
   - Check if DAP/LSP ports actually listening
   - Restart Godot if ports don't open
   - Provide diagnostics

### Phase 3: Quality of Life

5. **Test Orchestration**
   - `/tests/run` endpoint
   - Ensures environment ready before running tests
   - Aggregates results

6. **Performance Monitoring**
   - Continuous FPS tracking
   - `/metrics/fps` endpoint with statistics
   - Alerts on degradation

### Phase 4: Nice to Have

7. **Real vs Mock Endpoint Tracking**
   - Document which endpoints use mock data
   - Provide endpoint to query this

8. **Test Result Aggregation**
   - Store test run history
   - Generate reports

---

## Implementation Estimate

### Phase 1 (Critical)
- Automatic scene loading: 1-2 hours
- Player spawn verification: 30 minutes
- **Total:** ~2-3 hours

### Phase 2 (High Value)
- System status dashboard: 1 hour
- Debug port monitoring: 1 hour
- **Total:** ~2 hours

### Phase 3 (Quality of Life)
- Test orchestration: 2-3 hours
- Performance monitoring: 1-2 hours
- **Total:** ~3-5 hours

### Phase 4 (Nice to Have)
- Endpoint tracking: 1 hour
- Test result aggregation: 2 hours
- **Total:** ~3 hours

**Grand Total:** ~10-13 hours for all enhancements

---

## Quick Win: Phase 1 Implementation

Let me implement Phase 1 (Critical) enhancements right now:

### 1. Scene Loading Enhancement

```python
class SceneLoader:
    """Automatically loads and verifies main scene."""

    def __init__(self, api_client, scene_path="res://vr_main.tscn"):
        self.api = api_client
        self.scene_path = scene_path
        self.scene_loaded = False

    def ensure_scene_loaded(self) -> bool:
        # Check if scene already loaded
        scene_state = self.api.request("GET", "/state/scene")
        if scene_state and scene_state.get("vr_main") == "found":
            self.scene_loaded = True
            return True

        # Try to load scene via script execution
        logger.info(f"Attempting to load scene: {self.scene_path}")
        result = self.api.request("POST", "/execute/script", {
            "code": f'get_tree().change_scene_to_file("{self.scene_path}")'
        })

        if result and "error" not in result:
            # Wait for scene to load
            time.sleep(2)

            # Verify scene loaded
            scene_state = self.api.request("GET", "/state/scene")
            if scene_state and scene_state.get("vr_main") == "found":
                logger.info("Scene loaded successfully")
                self.scene_loaded = True
                return True

        logger.error("Failed to load scene")
        return False
```

### 2. Player Verification Enhancement

```python
class PlayerMonitor:
    """Monitors player node status."""

    def __init__(self, api_client):
        self.api = api_client
        self.player_exists = False

    def check_player_exists(self) -> bool:
        player_state = self.api.request("GET", "/state/player")
        self.player_exists = player_state and player_state.get("exists", False)
        return self.player_exists

    def wait_for_player(self, timeout=30) -> bool:
        """Wait for player to spawn, up to timeout seconds."""
        start_time = time.time()
        while time.time() - start_time < timeout:
            if self.check_player_exists():
                logger.info("Player spawned successfully")
                return True
            time.sleep(1)

        logger.error("Player did not spawn within timeout")
        return False
```

### 3. Enhanced Health Endpoint

```python
def handle_health_enhanced(self):
    """Enhanced health check with scene and player status."""
    godot_running = self.godot_manager.is_running()
    godot_api_ok = self.godot_api.health_check()

    # Check scene
    scene_state = self.godot_api.request("GET", "/state/scene")
    scene_loaded = scene_state and scene_state.get("vr_main") == "found"

    # Check player
    player_state = self.godot_api.request("GET", "/state/player")
    player_exists = player_state and player_state.get("exists", False)

    health = {
        "server": "healthy",
        "timestamp": datetime.now().isoformat(),
        "godot_process": {
            "running": godot_running,
            "pid": self.godot_manager.get_pid()
        },
        "godot_api": {
            "reachable": godot_api_ok
        },
        "scene": {
            "loaded": scene_loaded,
            "name": "vr_main" if scene_loaded else None
        },
        "player": {
            "spawned": player_exists
        },
        "overall_healthy": godot_running and godot_api_ok and scene_loaded and player_exists,
        "blocking_issues": []
    }

    # Add blocking issues
    if not godot_running:
        health["blocking_issues"].append("Godot process not running")
    if not godot_api_ok:
        health["blocking_issues"].append("Godot API not reachable")
    if not scene_loaded:
        health["blocking_issues"].append("Main scene (vr_main) not loaded")
    if not player_exists:
        health["blocking_issues"].append("Player node not spawned")

    status_code = 200 if health["overall_healthy"] else 503
    self.send_json_response(status_code, health)
```

---

## Decision Point

**Should I implement Phase 1 enhancements now?**

This would give you:
- ✅ Automatic scene loading when server starts
- ✅ Player spawn verification
- ✅ Enhanced health endpoint showing scene/player status
- ✅ Unblocks all player-dependent tests

Estimated time: ~1-2 hours

**Alternative:** Keep current server as-is for 24/7 management, implement enhancements later when needed.

---

## Summary Table

| Problem | Priority | Effort | Impact | Implement Now? |
|---------|----------|--------|--------|----------------|
| Scene not loading | HIGH | 2h | Unblocks tests | ✓ Recommended |
| Player not spawning | HIGH | 30m | Unblocks tests | ✓ Recommended |
| DAP ports not listening | MEDIUM | 1h | Medium | Later |
| No test orchestration | MEDIUM | 3h | Medium | Later |
| Mock data in endpoints | LOW | 2h | Low | Later |
| No performance monitoring | LOW | 2h | Low | Later |
| System status visibility | MEDIUM | 1h | Medium | Later |
| Test result aggregation | LOW | 2h | Low | Later |

---

**Recommendation:** Implement Phase 1 (scene loading + player spawn) now to unblock testing. Other enhancements can be added incrementally as needed.
