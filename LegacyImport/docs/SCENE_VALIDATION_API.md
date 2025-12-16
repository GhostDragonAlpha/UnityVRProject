# Scene Validation API

## Overview

The Scene Validation endpoint allows you to validate a Godot scene file without actually loading it into the scene tree. This is useful for:

- Pre-flight checks before loading scenes
- Validating user-provided scene paths
- Detecting common scene issues (circular dependencies, missing files, etc.)
- Getting scene metadata without side effects

## Endpoint

**PUT /scene**

Validates a scene file and returns validation results.

## Request

### Headers
```
Content-Type: application/json
```

### Body
```json
{
  "scene_path": "res://path/to/scene.tscn"
}
```

#### Parameters

- `scene_path` (string, required): Path to the scene file to validate
  - Must start with `res://`
  - Must end with `.tscn`

## Response

### Success (200 OK)

```json
{
  "valid": true,
  "errors": [],
  "warnings": [],
  "scene_info": {
    "node_count": 42,
    "root_type": "Node3D",
    "root_name": "VRMain"
  }
}
```

### Validation Failed (200 OK)

```json
{
  "valid": false,
  "errors": [
    "Scene file not found: res://missing.tscn"
  ],
  "warnings": [],
  "scene_info": {}
}
```

### Bad Request (400)

```json
{
  "error": "Bad Request",
  "message": "Invalid JSON body or missing Content-Type: application/json"
}
```

## Response Fields

### valid (boolean)
- `true`: Scene is valid and can be loaded
- `false`: Scene has validation errors

### errors (array of strings)
List of validation errors. Common errors:
- `"Scene path cannot be empty"`
- `"Scene path must start with 'res://'"`
- `"Scene path must end with '.tscn'"`
- `"Scene file not found: <path>"`
- `"Failed to load scene resource"`
- `"Scene has no nodes (empty scene)"`
- `"Failed to instantiate scene (possible circular dependency)"`

### warnings (array of strings)
List of non-critical warnings. Common warnings:
- `"Scene has a large number of nodes (X), may impact performance"`
- `"Scene path contains spaces, which may cause issues on some platforms"`

### scene_info (object)
Metadata about the scene (only present when validation succeeds):
- `node_count` (number): Total number of nodes in the scene
- `root_type` (string): Type of the root node (e.g., "Node3D", "Control")
- `root_name` (string): Name of the root node

## Validation Checks

The endpoint performs the following validations:

1. **Path Format**: Verifies path starts with `res://` and ends with `.tscn`
2. **File Exists**: Checks if the file exists in the resource system
3. **Resource Loading**: Attempts to load the scene as a PackedScene
4. **Node Structure**: Verifies the scene has at least one node
5. **Instantiation**: Tests if the scene can be instantiated (detects circular dependencies)
6. **Performance**: Warns about scenes with >1000 nodes
7. **Path Safety**: Warns about spaces in paths

## Examples

### cURL Examples

#### Validate an existing scene
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

#### Validate a non-existent scene
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://nonexistent.tscn"}'
```

### Python Example

```python
import requests
import json

def validate_scene(scene_path):
    response = requests.put(
        "http://127.0.0.1:8080/scene",
        headers={"Content-Type": "application/json"},
        json={"scene_path": scene_path}
    )
    
    result = response.json()
    
    if result["valid"]:
        print(f"✓ Scene is valid")
        print(f"  Nodes: {result['scene_info']['node_count']}")
        print(f"  Root: {result['scene_info']['root_name']} ({result['scene_info']['root_type']})")
    else:
        print(f"✗ Scene validation failed:")
        for error in result["errors"]:
            print(f"  - {error}")
    
    if result["warnings"]:
        print(f"⚠ Warnings:")
        for warning in result["warnings"]:
            print(f"  - {warning}")
    
    return result["valid"]

# Usage
validate_scene("res://vr_main.tscn")
```

### GDScript Example

```gdscript
func validate_scene_async(scene_path: String) -> void:
    var http = HTTPRequest.new()
    add_child(http)
    
    http.request_completed.connect(func(result, response_code, headers, body):
        var json = JSON.new()
        json.parse(body.get_string_from_utf8())
        var response = json.data
        
        if response.valid:
            print("✓ Scene is valid: ", scene_path)
            print("  Nodes: ", response.scene_info.node_count)
        else:
            print("✗ Scene validation failed: ", scene_path)
            for error in response.errors:
                print("  - ", error)
        
        http.queue_free()
    )
    
    var body = JSON.stringify({"scene_path": scene_path})
    var headers = ["Content-Type: application/json"]
    
    http.request(
        "http://127.0.0.1:8080/scene",
        headers,
        HTTPClient.METHOD_PUT,
        body
    )
```

## Comparison with POST /scene

| Feature | PUT /scene (Validate) | POST /scene (Load) |
|---------|----------------------|-------------------|
| Purpose | Validate without loading | Load into scene tree |
| Side Effects | None | Changes current scene |
| Speed | Fast | Slower (requires scene tree update) |
| Use Case | Pre-flight checks | Actual scene changes |
| Returns scene info | Yes | No |

## Testing

Run the provided test scripts to verify the endpoint:

### Bash
```bash
./test_scene_validation.sh
```

### Python
```bash
python test_scene_validation.py
```

## Implementation Details

The validation is performed in `scripts/http_api/scene_router.gd`:

1. **Handler**: `put_handler` function processes PUT requests
2. **Validation**: `_validate_scene()` function performs all checks
3. **Resource Loading**: Uses `ResourceLoader.load()` with `CACHE_MODE_IGNORE` to avoid caching
4. **Instantiation Test**: Creates a temporary instance to detect circular dependencies, then immediately frees it

## Performance Considerations

- Validation is fast but not instantaneous (requires loading scene metadata)
- Uses `CACHE_MODE_IGNORE` to prevent polluting resource cache
- Test instance is freed immediately after validation
- For large scenes (>1000 nodes), validation may take longer

## Error Handling

All errors return HTTP 200 with `valid: false` and error details, except:
- Missing/invalid JSON body returns HTTP 400

This design allows clients to always parse the JSON response and check the `valid` field.

## Future Enhancements

Potential future additions:
- Dependency graph analysis
- Scene size estimation
- Custom validation rules
- Batch validation of multiple scenes
- Scene diff/comparison
