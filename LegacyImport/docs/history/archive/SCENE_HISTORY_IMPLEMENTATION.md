# Scene History Router Implementation

## Overview

This implementation adds scene history tracking to the SpaceTime HTTP API. It tracks the last 10 scene loads with timestamps and load duration metrics.

## Files Created

### 1. `scripts/http_api/scene_history_router.gd`
- **Purpose**: HTTP router that provides the `/scene/history` endpoint
- **Type**: RefCounted class extending HttpRouter
- **Features**:
  - Singleton pattern for history persistence across requests
  - Stores last 10 scene loads in memory
  - GET endpoint returns JSON array of history entries
  - Each entry contains: scene_path, scene_name, loaded_at (ISO 8601), load_duration_ms

**Key Implementation Details:**
```gdscript
class_name SceneHistoryRouter
extends "res://addons/godottpd/http_router.gd"

static var _instance: SceneHistoryRouter = null
static var _history: Array = []
const MAX_HISTORY = 10

static func add_to_history(scene_path: String, scene_name: String, duration_ms: int)
```

### 2. `scripts/http_api/scene_load_monitor.gd`
- **Purpose**: Autoload singleton that monitors scene changes and tracks load times
- **Type**: Node (autoload)
- **Features**:
  - Listens to SceneTree.tree_changed signal
  - Measures scene load duration from request to completion
  - Automatically updates SceneHistoryRouter when scenes finish loading

**How it works:**
1. SceneRouter calls `start_tracking(scene_path)` before loading
2. Monitor records start time
3. Monitor listens for tree_changed signal
4. When new scene matches pending path, calculates duration
5. Calls `SceneHistoryRouter.add_to_history()` with metrics

### 3. Modified `scripts/http_api/scene_router.gd`
- **Changes**: Added call to SceneLoadMonitor before scene load
- **Integration point**:
```gdscript
var tree = Engine.get_main_loop() as SceneTree
if tree and tree.root.has_node("/root/SceneLoadMonitor"):
    var monitor = tree.root.get_node("/root/SceneLoadMonitor")
    monitor.start_tracking(scene_path)
```

### 4. Modified `scripts/http_api/http_api_server.gd`
- **Changes**: Registered scene_history_router in `_register_routers()`
- **Added endpoint announcement**: `GET /scene/history - Get scene load history`

### 5. Modified `project.godot`
- **Changes**: Added SceneLoadMonitor as autoload singleton
- **Location**: After HttpApiServer, before GodotBridge

### 6. `test_scene_history.py`
- **Purpose**: Python test script to verify the implementation
- **Tests**:
  - Fetch initial history
  - Load a scene
  - Verify history updates with correct data

## API Endpoint

### GET /scene/history

**Response Format:**
```json
{
  "history": [
    {
      "scene_path": "res://vr_main.tscn",
      "scene_name": "VRMain",
      "loaded_at": "2025-12-02T14:30:45",
      "load_duration_ms": 125
    }
  ],
  "count": 1,
  "max_size": 10
}
```

**Response Fields:**
- `history`: Array of scene load entries (most recent first)
- `count`: Number of entries in history
- `max_size`: Maximum history size (always 10)

**Entry Fields:**
- `scene_path`: Full resource path (e.g., "res://vr_main.tscn")
- `scene_name`: Scene root node name
- `loaded_at`: ISO 8601 timestamp (YYYY-MM-DDTHH:MM:SS)
- `load_duration_ms`: Load time in milliseconds

## Architecture Decisions

### Why Singleton Pattern for History Storage?
- SceneHistoryRouter is RefCounted (not Node), so it doesn't persist in scene tree
- Static singleton instance ensures history persists across HTTP requests
- Simple and efficient for small data set (max 10 entries)

### Why Separate Monitor Node?
- Routers can't use signals (RefCounted, not Node)
- Autoload Node can listen to SceneTree signals reliably
- Clean separation of concerns: Router handles HTTP, Monitor handles timing

### Why Autoload for SceneLoadMonitor?
- Needs to persist across scene changes
- Must be available before any scene loads
- Autoload ensures initialization before HttpApiServer needs it

## Testing

### Manual Testing with curl

**1. Check initial history:**
```bash
curl http://127.0.0.1:8080/scene/history
```

**2. Load a scene:**
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**3. Wait 2 seconds, then check history again:**
```bash
curl http://127.0.0.1:8080/scene/history
```

### Automated Testing

**Run the Python test script:**
```bash
python test_scene_history.py
```

Expected output:
- Initial history fetch succeeds
- Scene load request returns 200
- Updated history shows new entry with:
  - Correct scene path and name
  - ISO 8601 timestamp
  - Load duration in milliseconds

## Integration Points

### Startup Sequence
1. ResonanceEngine initializes
2. HttpApiServer initializes and registers routers
3. SceneLoadMonitor initializes and connects to tree_changed signal
4. Scene loads trigger monitoring automatically

### Data Flow
```
POST /scene request
  → SceneRouter.post_handler()
  → SceneLoadMonitor.start_tracking()
  → SceneTree.change_scene_to_file()
  → [Scene loads...]
  → SceneTree.tree_changed signal
  → SceneLoadMonitor._on_tree_changed()
  → SceneHistoryRouter.add_to_history()
  → History updated

GET /scene/history request
  → SceneHistoryRouter.get_handler()
  → Returns _history array as JSON
```

## Future Enhancements

Possible improvements:
1. **Persistence**: Save history to disk for cross-session tracking
2. **Metrics**: Add more metrics (FPS after load, memory usage)
3. **Filtering**: Query parameters for filtering by scene name/path
4. **Statistics**: Aggregate stats (average load time, slowest scenes)
5. **DELETE endpoint**: Clear history via API
6. **WebSocket**: Push history updates to connected clients

## Notes

- History is stored in memory only (lost on restart)
- Maximum 10 entries enforced (oldest dropped)
- Load duration measured from request to scene tree change
- ISO 8601 timestamps without timezone (local system time)
- No authentication/authorization on endpoint

## Verification Checklist

- [x] SceneHistoryRouter created with GET handler
- [x] SceneLoadMonitor created as autoload Node
- [x] SceneRouter modified to call monitor
- [x] HttpApiServer registers history router
- [x] project.godot updated with autoload
- [x] Test script created
- [x] Documentation written

## Example Usage

```python
import requests

# Get history
response = requests.get("http://127.0.0.1:8080/scene/history")
history = response.json()

print(f"Total scenes loaded: {history['count']}")
for entry in history['history']:
    print(f"  {entry['scene_name']}: {entry['load_duration_ms']}ms at {entry['loaded_at']}")
```
