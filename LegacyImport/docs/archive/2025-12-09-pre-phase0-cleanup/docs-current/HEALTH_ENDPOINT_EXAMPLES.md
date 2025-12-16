# Enhanced /health Endpoint Examples

## Overview

The enhanced `/health` endpoint provides comprehensive readiness information including:
- Godot process status
- API reachability
- Scene loading status
- Player spawn status
- Overall health indicator
- List of blocking issues

## Response Format

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
  "godot_process": {
    "running": true/false,
    "pid": 12345 or null
  },
  "godot_api": {
    "reachable": true/false
  },
  "scene": {
    "loaded": true/false,
    "name": "vr_main" or null
  },
  "player": {
    "spawned": true/false
  },
  "overall_healthy": true/false,
  "blocking_issues": []
}
```

## HTTP Status Codes

- **200 OK**: System fully healthy (all components ready)
- **503 Service Unavailable**: System not ready (one or more issues)

## Example States

### 1. Fully Healthy (200)

All systems operational - ready for testing/development.

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
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

**When**: Godot editor running, scene loaded, player spawned
**Action**: Ready to run tests and development tasks

### 2. Godot Not Running (503)

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
  "godot_process": {
    "running": false,
    "pid": null
  },
  "godot_api": {
    "reachable": false
  },
  "scene": {
    "loaded": false,
    "name": null
  },
  "player": {
    "spawned": false
  },
  "overall_healthy": false,
  "blocking_issues": [
    "Godot process not running",
    "Godot API not reachable"
  ]
}
```

**When**: Godot editor not started
**Action**: Start Godot with `POST /start` or manually

### 3. Scene Not Loaded (503)

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": true
  },
  "scene": {
    "loaded": false,
    "name": null
  },
  "player": {
    "spawned": false
  },
  "overall_healthy": false,
  "blocking_issues": [
    "Main scene (vr_main) not loaded"
  ]
}
```

**When**: Godot running but vr_main.tscn not loaded
**Action**: Load scene via editor or use scene loading endpoint

### 4. Player Not Spawned (503)

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
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
    "spawned": false
  },
  "overall_healthy": false,
  "blocking_issues": [
    "Player node not spawned"
  ]
}
```

**When**: Scene loaded but player node not yet created
**Action**: Wait for vr_setup.gd to execute, or trigger player spawn

### 5. API Unreachable (503)

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": false
  },
  "scene": {
    "loaded": false,
    "name": null
  },
  "player": {
    "spawned": false
  },
  "overall_healthy": false,
  "blocking_issues": [
    "Godot API not reachable"
  ]
}
```

**When**: Godot process exists but HTTP API not responding
**Action**: Restart Godot, check if GodotBridge autoload is enabled

## Usage Examples

### Python

```python
import requests

response = requests.get("http://127.0.0.1:8090/health")
health = response.json()

if health["overall_healthy"]:
    print("✓ System ready")
    # Proceed with tests
else:
    print("✗ System not ready:")
    for issue in health["blocking_issues"]:
        print(f"  - {issue}")
    # Wait or fix issues
```

### Bash/curl

```bash
# Basic check
curl http://127.0.0.1:8090/health

# Check with status code
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8090/health

# Wait for readiness
while [ "$(curl -s http://127.0.0.1:8090/health | jq -r '.overall_healthy')" != "true" ]; do
  echo "Waiting for system to be ready..."
  sleep 2
done
echo "System ready!"
```

### Test Scripts

```python
def wait_for_ready(timeout=60):
    """Wait for system to be fully ready."""
    import time
    start = time.time()

    while time.time() - start < timeout:
        response = requests.get("http://127.0.0.1:8090/health")
        if response.status_code == 200:
            return True

        health = response.json()
        print(f"Waiting... Issues: {health['blocking_issues']}")
        time.sleep(5)

    return False

if wait_for_ready():
    # Run tests
    run_integration_tests()
else:
    print("System failed to become ready")
```

## Integration with CI/CD

```yaml
# .github/workflows/test.yml
- name: Wait for Godot to be ready
  run: |
    timeout 300 bash -c 'while [ "$(curl -s http://127.0.0.1:8090/health | jq -r .overall_healthy)" != "true" ]; do sleep 5; done'

- name: Run tests
  run: python tests/test_runner.py
```

## Blocking Issues Reference

| Issue | Cause | Resolution |
|-------|-------|------------|
| Godot process not running | Editor not started | `POST /start` or manual start |
| Godot API not reachable | GodotBridge disabled or crashed | Check autoloads, restart Godot |
| Main scene (vr_main) not loaded | Scene not opened | Open vr_main.tscn in editor |
| Player node not spawned | vr_setup.gd not executed | Wait or check scene setup |

## Comparison with Old /health

### Old (Basic)

```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T09:00:00.000000",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": true
  },
  "overall_healthy": true
}
```

### New (Enhanced)

Adds:
- `scene` object with load status and name
- `player` object with spawn status
- `blocking_issues` array with specific problems
- More accurate `overall_healthy` that requires ALL systems ready

## Notes

- The endpoint uses `retry_count=1` for scene/player checks to fail fast
- Scene check looks for `vr_main: "found"` in `/state/scene` response
- Player check looks for `exists: true` in `/state/player` response
- Overall health requires ALL of: process running, API reachable, scene loaded, player spawned
- Status code is 503 if any issue exists, 200 only when fully ready
