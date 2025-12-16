# Scene Reload Endpoint

## Overview

The `/scene/reload` endpoint provides a quick way to reload the currently loaded scene without specifying a path. This is useful for testing scene changes and rapid iteration.

## Implementation

### Files Created/Modified

1. **`scripts/http_api/scene_reload_router.gd`** (NEW)
   - Implements `SceneReloadRouter` class
   - Handles POST requests to `/scene/reload`
   - Gets current scene path from SceneTree
   - Reloads scene using `call_deferred("change_scene_to_file", scene_path)`

2. **`scripts/http_api/http_api_server.gd`** (MODIFIED)
   - Registered `SceneReloadRouter` in `_register_routers()`
   - Added endpoint to printed list of available endpoints

## API Endpoint

### POST /scene/reload

Reloads the currently loaded scene.

**Method:** POST

**URL:** `http://127.0.0.1:8080/scene/reload`

**Request Body:** None required

**Success Response (200 OK):**
```json
{
  "status": "reloading",
  "scene": "res://node_3d.tscn",
  "scene_name": "node_3d",
  "message": "Scene reload initiated successfully"
}
```

**Error Responses:**

- **404 Not Found** - No scene currently loaded
  ```json
  {
    "error": "Not Found",
    "message": "No scene currently loaded"
  }
  ```

- **500 Internal Server Error** - Could not access SceneTree or scene has no file path
  ```json
  {
    "error": "Internal Server Error",
    "message": "Could not access SceneTree"
  }
  ```

## Usage Examples

### Using curl

```bash
# Reload the current scene
curl -X POST http://127.0.0.1:8080/scene/reload

# Pretty print with jq
curl -s -X POST http://127.0.0.1:8080/scene/reload | jq .

# Pretty print with python
curl -s -X POST http://127.0.0.1:8080/scene/reload | python -m json.tool
```

### Using the test script

```bash
# Run the automated test script
./test_reload_endpoint.sh
```

The test script will:
1. Get the current scene
2. Reload the current scene
3. Wait 2 seconds
4. Verify the scene is still loaded

### Using Python

```python
import requests

# Reload current scene
response = requests.post('http://127.0.0.1:8080/scene/reload')
result = response.json()

print(f"Reloading: {result['scene_name']}")
print(f"Path: {result['scene']}")
print(f"Status: {result['status']}")
```

## Testing

**IMPORTANT:** After creating or modifying the router, you must restart Godot for the changes to take effect, as the `HttpApiServer` autoload only initializes routers once at startup.

### To test after Godot restart:

1. **Start Godot** (or restart if already running)

2. **Verify the server is running:**
   ```bash
   curl http://127.0.0.1:8080/scene
   ```

3. **Test the reload endpoint:**
   ```bash
   curl -X POST http://127.0.0.1:8080/scene/reload
   ```

4. **Check console output** in Godot for:
   ```
   [HttpApiServer] Registered /scene/reload router
   [SceneReloadRouter] Reloading current scene: res://node_3d.tscn
   ```

### Using the automated test script:

```bash
./test_reload_endpoint.sh
```

Expected output:
```
Testing POST /scene/reload endpoint...
========================================

1. Get current scene:
{
    "scene_name": "node_3d",
    "scene_path": "res://node_3d.tscn",
    "status": "loaded"
}


2. Reload current scene:
{
    "message": "Scene reload initiated successfully",
    "scene": "res://node_3d.tscn",
    "scene_name": "node_3d",
    "status": "reloading"
}


3. Wait 2 seconds and check scene again:
{
    "scene_name": "node_3d",
    "scene_path": "res://node_3d.tscn",
    "status": "loaded"
}


Test complete!
```

## Implementation Details

### Router Architecture

The `SceneReloadRouter` follows the established pattern used by other routers:
- Extends `res://addons/godottpd/http_router.gd`
- Defines handlers as lambda functions in `_init()`
- Calls parent constructor with route path and handler dictionary

### Scene Reload Process

1. **Get SceneTree** from `Engine.get_main_loop()`
2. **Get current scene** from `tree.current_scene`
3. **Extract scene path** from `current_scene.scene_file_path`
4. **Reload deferred** using `tree.call_deferred("change_scene_to_file", scene_path)`
5. **Return immediately** with success response (reload happens async)

### Error Handling

The endpoint handles three error cases:
1. Cannot access SceneTree (500 error)
2. No scene currently loaded (404 error)
3. Current scene has no file path (500 error)

## Benefits Over POST /scene

While you can reload a scene using `POST /scene` with the current scene path, the `/scene/reload` endpoint:
- **Simpler:** No need to know or specify the current scene path
- **Faster:** No JSON body to construct
- **Convenient:** One-line curl command
- **Self-documenting:** Intent is clear from the endpoint name

## Related Endpoints

- `GET /scene` - Get information about current scene
- `POST /scene` - Load a specific scene by path
- `GET /scenes` - List all available scenes

## Notes

- Scene reloading is asynchronous - the response is sent before the reload completes
- The reload uses `call_deferred` to avoid conflicts with the current frame
- All scene state is reset during reload (same as manually reloading in Godot)
- VR state, autoloads, and singletons persist across scene reloads
