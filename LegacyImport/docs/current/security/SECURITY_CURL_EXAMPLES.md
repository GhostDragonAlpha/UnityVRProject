# HTTP API Security - Quick Reference

## Get the API Token

The API token is printed when Godot starts. Look for this in the console:

```
[Security] API token generated: a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
[Security] Include in requests: Authorization: Bearer a1b2c3d4e5f6...
```

Set it as an environment variable for easy use:

```bash
export TOKEN="paste_your_token_here"
```

## Authenticated API Calls

### Load Scene
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

### Get Current Scene
```bash
curl -X GET http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $TOKEN"
```

### Validate Scene
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

### List All Scenes
```bash
curl -X GET "http://127.0.0.1:8080/scenes?dir=res://&include_addons=false" \
  -H "Authorization: Bearer $TOKEN"
```

### Reload Current Scene
```bash
curl -X POST http://127.0.0.1:8080/scene/reload \
  -H "Authorization: Bearer $TOKEN"
```

### Get Scene History
```bash
curl -X GET http://127.0.0.1:8080/scene/history \
  -H "Authorization: Bearer $TOKEN"
```

## Error Responses

### 401 Unauthorized (Missing/Invalid Token)
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}
```

### 403 Forbidden (Scene Not Whitelisted)
```json
{
  "error": "Forbidden",
  "message": "Scene not in whitelist"
}
```

### 413 Payload Too Large
```json
{
  "error": "Payload Too Large",
  "message": "Request body exceeds maximum size",
  "max_size_bytes": 1048576
}
```

## Testing Security

### Test Without Token (Should Fail)
```bash
curl -X GET http://127.0.0.1:8080/scene
# Expected: 401 Unauthorized
```

### Test With Wrong Token (Should Fail)
```bash
curl -X GET http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer wrong_token"
# Expected: 401 Unauthorized
```

### Test Non-Whitelisted Scene (Should Fail)
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"scene_path": "res://hacker_scene.tscn"}'
# Expected: 403 Forbidden
```

## Python Client Example

```python
import requests

# Set your token from Godot console
TOKEN = "your_token_here"
BASE_URL = "http://127.0.0.1:8080"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Load scene
response = requests.post(
    f"{BASE_URL}/scene",
    headers=headers,
    json={"scene_path": "res://vr_main.tscn"}
)
print(response.json())

# Get current scene
response = requests.get(f"{BASE_URL}/scene", headers=headers)
print(response.json())

# List scenes
response = requests.get(
    f"{BASE_URL}/scenes",
    headers=headers,
    params={"dir": "res://", "include_addons": "false"}
)
print(response.json())
```

## Whitelisted Scenes

By default, only these scenes can be loaded:
- `res://vr_main.tscn`
- `res://node_3d.tscn`
- `res://test_scene.tscn`

To add more scenes to the whitelist, use GDScript:
```gdscript
HttpApiSecurityConfig.add_to_whitelist("res://my_scene.tscn")
```
