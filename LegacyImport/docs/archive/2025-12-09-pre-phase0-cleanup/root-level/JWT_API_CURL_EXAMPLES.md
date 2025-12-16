# HTTP API Curl Examples with JWT Authentication

## Setup

Set your JWT token as an environment variable:

```bash
# Windows CMD
set JWT_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjQ3MzE1MzEsImlhdCI6MTc2NDcyNzkzMSwidHlwZSI6ImFwaV9hY2Nlc3MifQ=.16dKPEqZemKe_9ozNZsmkPJuICA1m5uTu4bBEKiP5ag

# Windows PowerShell
$env:JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjQ3MzE1MzEsImlhdCI6MTc2NDcyNzkzMSwidHlwZSI6ImFwaV9hY2Nlc3MifQ=.16dKPEqZemKe_9ozNZsmkPJuICA1m5uTu4bBEKiP5ag"

# Linux/Mac
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjQ3MzE1MzEsImlhdCI6MTc2NDcyNzkzMSwidHlwZSI6ImFwaV9hY2Nlc3MifQ=.16dKPEqZemKe_9ozNZsmkPJuICA1m5uTu4bBEKiP5ag"
```

## Working Endpoints (Tested & Verified)

### 1. GET /scene - Get Current Scene
```bash
curl -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scene | python -m json.tool
```

**Expected Response:**
```json
{
  "scene_name": "VRMain",
  "scene_path": "res://vr_main.tscn",
  "status": "loaded"
}
```

---

### 2. GET /scenes - List Available Scenes
```bash
# List all scenes
curl -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scenes | python -m json.tool

# List scenes in specific directory
curl -H "Authorization: Bearer $JWT_TOKEN" \
  "http://127.0.0.1:8080/scenes?dir=res://scenes" | python -m json.tool

# Include addon scenes
curl -H "Authorization: Bearer $JWT_TOKEN" \
  "http://127.0.0.1:8080/scenes?include_addons=true" | python -m json.tool
```

**Expected Response:**
```json
{
  "count": 33,
  "directory": "res://",
  "include_addons": false,
  "scenes": [
    {
      "modified": "2025-11-30T06:59:51Z",
      "name": "node_3d",
      "path": "res://node_3d.tscn",
      "size_bytes": 82
    }
  ]
}
```

---

### 3. GET /scene/history - Get Scene Load History
```bash
curl -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scene/history | python -m json.tool
```

**Expected Response:**
```json
{
  "count": 0,
  "history": [],
  "max_size": 10
}
```

---

### 4. POST /scene/reload - Reload Current Scene
```bash
curl -X POST \
  -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scene/reload | python -m json.tool
```

**Expected Response:**
```json
{
  "message": "Scene reload initiated successfully",
  "scene": "res://vr_main.tscn",
  "scene_name": "vr_main",
  "status": "reloading"
}
```

---

## Endpoints with Known Issues

### PUT /scene - Validate Scene (⚠️ HAS BUG)
```bash
# Currently returns 413 due to size validation bug
curl -X PUT \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path":"res://vr_main.tscn"}' \
  http://127.0.0.1:8080/scene | python -m json.tool
```

**Current Response (Bug):**
```json
{
  "error": "Payload Too Large",
  "max_size_bytes": 1048576,
  "message": "Request body exceeds maximum size"
}
```

**Expected Response (After Fix):**
```json
{
  "valid": true,
  "errors": [],
  "warnings": [],
  "scene_info": {
    "node_count": 123,
    "root_type": "Node3D",
    "root_name": "VRMain"
  }
}
```

---

### POST /scene - Load Scene (⚠️ HAS BUG)
```bash
# Currently returns 413 due to size validation bug
curl -X POST \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path":"res://node_3d.tscn"}' \
  http://127.0.0.1:8080/scene | python -m json.tool
```

**Current Response (Bug):**
```json
{
  "error": "Payload Too Large",
  "max_size_bytes": 1048576,
  "message": "Request body exceeds maximum size"
}
```

**Expected Response (After Fix):**
```json
{
  "status": "loading",
  "scene": "res://node_3d.tscn",
  "message": "Scene load initiated successfully"
}
```

---

## Authentication Tests

### Test Without Auth (Should Return 401)
```bash
curl http://127.0.0.1:8080/scene | python -m json.tool
```

**Expected Response:**
```json
{
  "details": "Include 'Authorization: Bearer <token>' header",
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token"
}
```

---

### Test With Invalid Token (Should Return 401)
```bash
curl -H "Authorization: Bearer invalid_token_here" \
  http://127.0.0.1:8080/scene | python -m json.tool
```

**Expected Response:**
```json
{
  "details": "Include 'Authorization: Bearer <token>' header",
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token"
}
```

---

## Advanced Examples

### Pretty Print JSON with jq (if installed)
```bash
curl -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scenes | jq .
```

### Get Only Scene Count
```bash
curl -s -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scenes | jq '.count'
```

### Get Scene Paths Only
```bash
curl -s -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scenes | jq '.scenes[].path'
```

### Filter Scenes by Name Pattern
```bash
curl -s -H "Authorization: Bearer $JWT_TOKEN" \
  http://127.0.0.1:8080/scenes | jq '.scenes[] | select(.name | contains("test"))'
```

---

## Testing Rate Limits

### Rapid Fire Requests (Testing Rate Limiting)
```bash
# Send 10 requests rapidly
for i in {1..10}; do
  echo "Request $i:"
  curl -s -H "Authorization: Bearer $JWT_TOKEN" \
    http://127.0.0.1:8080/scene | python -m json.tool
  echo ""
done
```

**Note:** Rate limits:
- `/scene`: 30 requests/minute
- `/scene/reload`: 20 requests/minute
- `/scenes`: 60 requests/minute
- `/scene/history`: 100 requests/minute

If you exceed the limit, you'll get a 429 response:
```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded",
  "retry_after_seconds": 5.2
}
```

---

## Troubleshooting

### Check if Godot is Running
```bash
# Windows
tasklist | findstr Godot

# Linux
ps aux | grep godot

# Mac
ps aux | grep -i godot
```

### Check if API Server is Responding
```bash
curl -I http://127.0.0.1:8080/scene
# Should return: HTTP/1.1 401 Unauthorized
```

### Get JWT Token from Godot Logs
```bash
# Windows
findstr "JWT token" C:\godot\*.log

# Linux/Mac
grep "JWT token" /path/to/godot/*.log
```

The token appears in logs as:
```
[Security] JWT token generated (expires in 3600s)
[Security] Include in requests: Authorization: Bearer <token>
```

---

## Security Notes

1. **Token Expiration:** JWT tokens expire after 1 hour (3600 seconds)
2. **Token Storage:** Never commit JWT tokens to version control
3. **HTTPS:** In production, always use HTTPS for API requests
4. **Token Rotation:** Implement token refresh mechanism for long-running clients
5. **Rate Limiting:** Respect rate limits to avoid 429 errors

---

## Quick Test Script

Save this as `test_api.sh`:

```bash
#!/bin/bash

TOKEN="${JWT_TOKEN:-YOUR_TOKEN_HERE}"

echo "Testing HTTP API with JWT Authentication"
echo "=========================================="

echo -e "\n1. Current Scene:"
curl -s -H "Authorization: Bearer $TOKEN" \
  http://127.0.0.1:8080/scene | python -m json.tool

echo -e "\n2. Scene Count:"
curl -s -H "Authorization: Bearer $TOKEN" \
  http://127.0.0.1:8080/scenes | python -c "import sys,json; print('Total scenes:', json.load(sys.stdin)['count'])"

echo -e "\n3. Scene History:"
curl -s -H "Authorization: Bearer $TOKEN" \
  http://127.0.0.1:8080/scene/history | python -m json.tool

echo -e "\n4. Test Auth (should fail):"
curl -s http://127.0.0.1:8080/scene | python -m json.tool

echo -e "\nDone!"
```

Make it executable and run:
```bash
chmod +x test_api.sh
./test_api.sh
```

---

## Related Files

- **Test Suite:** `test_jwt_endpoints.py` - Comprehensive Python test suite
- **Results:** `JWT_ENDPOINT_TEST_RESULTS.md` - Detailed test results and analysis
- **API Server:** `scripts/http_api/http_api_server.gd` - Main HTTP API server
- **Security Config:** `scripts/http_api/security_config.gd` - JWT validation and security
- **JWT Implementation:** `scripts/http_api/jwt.gd` - JWT encoding/decoding

---

## Getting a Fresh Token

If your token expires, restart Godot with debug flags:

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

Check the console output or log files for:
```
[Security] JWT token generated (expires in 3600s)
[Security] Include in requests: Authorization: Bearer <NEW_TOKEN>
```

Or check the most recent log file:
```bash
# Windows
type C:\godot\godot_startup.log | findstr "JWT token"

# Linux/Mac
cat /path/to/godot/godot_startup.log | grep "JWT token"
```
