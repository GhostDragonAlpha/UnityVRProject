# Scene Validation - Quick Reference

## Endpoint
```
PUT http://127.0.0.1:8080/scene
```

## Request
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

## Response (Valid Scene)
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

## Response (Invalid Scene)
```json
{
  "valid": false,
  "errors": ["Scene file not found: res://missing.tscn"],
  "warnings": [],
  "scene_info": {}
}
```

## Common Validation Errors
- Scene path cannot be empty
- Scene path must start with 'res://'
- Scene path must end with '.tscn'
- Scene file not found
- Failed to load scene resource
- Scene has no nodes (empty scene)
- Failed to instantiate scene (circular dependency)

## Testing
```bash
# Run automated tests
python test_scene_validation.py

# Or use bash script
./test_scene_validation.sh
```

## See Also
- Full documentation: `docs/SCENE_VALIDATION_API.md`
- Implementation: `scripts/http_api/scene_router.gd`
