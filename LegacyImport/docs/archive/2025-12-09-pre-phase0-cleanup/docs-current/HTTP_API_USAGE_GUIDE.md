# HTTP API Usage Guide

Complete guide for using the secure godottpd HTTP server for remote Godot control.

**API Version**: v2.5 (Security-Hardened)

**Security Features**: Token authentication, scene whitelist, request size limits, localhost binding

---

## Quick Start

### 1. Start Godot and Get API Token

The HTTP server starts automatically as an autoload when Godot launches. The API token is printed to the console.

```bash
# Start Godot and capture output
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log

# Or use quick restart script (Windows)
./restart_godot_with_debug.bat
```

**Look for the token in console output:**
```
[Security] API token generated: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
[Security] Include in requests: Authorization: Bearer a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

**Save the token in your environment:**

```bash
# Linux/Mac/Git Bash
export API_TOKEN="a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"

# Windows PowerShell
$env:API_TOKEN = "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"

# Windows Command Prompt
set API_TOKEN=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### 2. Verify Server is Running

```bash
# Test with authentication
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

# Should return current scene info
```

**Important**: Most endpoints require authentication. See [Authentication](#authentication) section below.

---

## Authentication

All API endpoints (except `/status`) require Bearer token authentication.

### Authentication Format

Include the `Authorization` header with Bearer token in all requests:

```
Authorization: Bearer <your_64_character_token>
```

### Getting Your Token

The token is generated when Godot starts and printed to the console. See [Quick Start](#quick-start) above.

### Example Authenticated Request

```bash
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene
```

### Authentication Errors

**401 Unauthorized** - Missing or invalid token:
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}
```

**403 Forbidden** - Scene not whitelisted or other access denied:
```json
{
  "error": "Forbidden",
  "message": "Scene not in whitelist"
}
```

**413 Payload Too Large** - Request exceeds 1MB limit:
```json
{
  "error": "Payload Too Large",
  "message": "Request body exceeds maximum size",
  "max_size_bytes": 1048576
}
```

**For complete token management guide**, see [API_TOKEN_GUIDE.md](../../../API_TOKEN_GUIDE.md).

---

## API Endpoints

### GET /scene - Query Current Scene

**Authentication**: Required

**Request:**
```bash
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene
```

**Response:**
```json
{
  "scene_name": "VRMain",
  "scene_path": "res://vr_main.tscn",
  "status": "loaded"
}
```

**Status Values:**
- `loaded` - Scene is fully loaded and active
- `no_scene` - No scene currently loaded (scene_name and scene_path will be null)

---

### POST /scene - Load New Scene

**Authentication**: Required

**Request:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}' \
  http://127.0.0.1:8080/scene
```

**Required Headers:**
- `Content-Type: application/json` - Server will reject requests without this header
- `Authorization: Bearer <token>` - Required for authentication

**Request Body:**
```json
{
  "scene_path": "res://path/to/scene.tscn"
}
```

**Success Response (200):**
```json
{
  "status": "loading",
  "scene": "res://vr_main.tscn",
  "message": "Scene load initiated successfully"
}
```

**Error Responses:**

**401 Unauthorized - Missing/Invalid Token:**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}
```

**403 Forbidden - Scene Not Whitelisted:**
```json
{
  "error": "Forbidden",
  "message": "Scene not in whitelist"
}
```

**400 Bad Request - Missing Content-Type:**
```json
{
  "error": "Bad Request",
  "message": "Invalid JSON body or missing Content-Type: application/json"
}
```

**400 Bad Request - Invalid Path Format:**
```json
{
  "error": "Bad Request",
  "message": "Invalid scene path. Must start with 'res://' and end with '.tscn'"
}
```

**404 Not Found - Scene Doesn't Exist:**
```json
{
  "error": "Not Found",
  "message": "Scene file not found: res://nonexistent.tscn"
}
```

**413 Payload Too Large - Request Exceeds 1MB:**
```json
{
  "error": "Payload Too Large",
  "message": "Request body exceeds maximum size",
  "max_size_bytes": 1048576
}
```

---

### GET /scenes - List Available Scenes

**Authentication**: Required

**Request:**
```bash
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scenes
```

**Query Parameters:**
- `dir` (optional) - Base directory to scan (default: `res://`)
- `include_addons` (optional) - Include scenes from addons/ folder (default: `false`)

**Request Examples:**
```bash
# List all scenes (excluding addons)
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scenes

# List scenes in specific directory
curl -H "Authorization: Bearer $API_TOKEN" "http://127.0.0.1:8080/scenes?dir=res://scenes"

# Include addon scenes
curl -H "Authorization: Bearer $API_TOKEN" "http://127.0.0.1:8080/scenes?include_addons=true"

# Combine filters
curl -H "Authorization: Bearer $API_TOKEN" "http://127.0.0.1:8080/scenes?dir=res://tests&include_addons=false"
```

**Success Response (200):**
```json
{
  "scenes": [
    {
      "name": "vr_main",
      "path": "res://vr_main.tscn",
      "size_bytes": 12345,
      "modified": "2025-12-02T10:30:00Z"
    },
    {
      "name": "walking_controller",
      "path": "res://scenes/player/walking_controller.tscn",
      "size_bytes": 8192,
      "modified": "2025-11-28T14:22:15Z"
    }
  ],
  "count": 2,
  "directory": "res://",
  "include_addons": false
}
```

**Scene Object Fields:**
- `name` - Scene name (filename without .tscn extension)
- `path` - Full Godot resource path
- `size_bytes` - File size in bytes
- `modified` - Last modification time in ISO 8601 format (UTC)

**Error Responses:**

**400 Bad Request - Invalid Directory Path:**
```json
{
  "error": "Bad Request",
  "message": "Directory path must start with 'res://'"
}
```

**Notes:**
- Scenes are sorted alphabetically by path
- Hidden files (starting with `.`) are excluded
- The endpoint recursively scans subdirectories
- Addon scenes (in `res://addons/`) are excluded by default
- Use `include_addons=true` to include addon scenes

---

## Python Client Library

Use the included Python client for easy integration with built-in authentication support.

### Installation

No dependencies required - uses standard library `requests`:
```bash
pip install requests
```

### Basic Usage with Authentication

```python
import os
from examples.scene_loader_client import SceneLoaderClient

# Get API token from environment
api_token = os.getenv("API_TOKEN")

# Create client with authentication
client = SceneLoaderClient(host="127.0.0.1", port=8080, token=api_token)

# Get current scene
scene = client.get_current_scene()
print(f"Current: {scene['scene_name']} at {scene['scene_path']}")

# Load new scene
result = client.load_scene("res://vr_main.tscn")
print(f"Loading: {result['scene']}")

# List available scenes
scenes = client.list_scenes()
print(f"Found {scenes['count']} scenes")
for scene in scenes['scenes']:
    print(f"  - {scene['name']}: {scene['path']}")

# List scenes in specific directory with addons
scenes = client.list_scenes(directory="res://tests", include_addons=True)
```

**Note**: The `SceneLoaderClient` class needs to be updated to support authentication. See the updated example below.

### Updated Python Client with Authentication

```python
#!/usr/bin/env python3
"""Secure Scene Loader Client with Token Authentication"""

import requests
import os
from typing import Optional, Dict, Any


class SecureSceneLoaderClient:
    """Client for managing Godot scenes via HTTP API with authentication"""

    def __init__(self, host: str = "127.0.0.1", port: int = 8080, token: Optional[str] = None):
        self.base_url = f"http://{host}:{port}"
        self.token = token or os.getenv("API_TOKEN")

        if not self.token:
            raise ValueError(
                "API token required. Set API_TOKEN environment variable or pass token parameter."
            )

    def _get_headers(self) -> Dict[str, str]:
        """Get request headers with authentication"""
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def get_current_scene(self) -> Optional[Dict[str, Any]]:
        """Get information about the currently loaded scene"""
        try:
            response = requests.get(
                f"{self.base_url}/scene",
                headers=self._get_headers(),
                timeout=5
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 401:
                print("ERROR: Authentication failed. Check API token.")
            else:
                print(f"ERROR: {e}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"ERROR: {e}")
            return None

    def load_scene(self, scene_path: str) -> Optional[Dict[str, Any]]:
        """Load a new scene"""
        try:
            response = requests.post(
                f"{self.base_url}/scene",
                headers=self._get_headers(),
                json={"scene_path": scene_path},
                timeout=5
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 401:
                print("ERROR: Authentication failed. Check API token.")
            elif e.response.status_code == 403:
                error_data = e.response.json()
                print(f"ERROR: Forbidden - {error_data.get('message', 'Access denied')}")
            elif e.response.status_code == 413:
                print("ERROR: Request payload too large (max 1MB).")
            else:
                print(f"ERROR: {e}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"ERROR: {e}")
            return None

    def list_scenes(self, directory: str = "res://", include_addons: bool = False) -> Optional[Dict[str, Any]]:
        """List available scenes in the project"""
        try:
            params = {
                "dir": directory,
                "include_addons": "true" if include_addons else "false"
            }
            response = requests.get(
                f"{self.base_url}/scenes",
                headers=self._get_headers(),
                params=params,
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 401:
                print("ERROR: Authentication failed. Check API token.")
            else:
                print(f"ERROR: {e}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"ERROR: {e}")
            return None


# Example usage
if __name__ == "__main__":
    # Create client (reads API_TOKEN from environment)
    try:
        client = SecureSceneLoaderClient()
    except ValueError as e:
        print(f"ERROR: {e}")
        exit(1)

    # Get current scene
    scene = client.get_current_scene()
    if scene:
        print(f"Current: {scene['scene_name']} ({scene['scene_path']})")

    # Load a scene
    result = client.load_scene("res://vr_main.tscn")
    if result:
        print(f"Loading: {result['scene']}")

    # List scenes
    scenes = client.list_scenes()
    if scenes:
        print(f"Found {scenes['count']} scenes")
```

### Command-Line Interface

**Before running CLI commands, set the API_TOKEN environment variable:**

```bash
# Set token
export API_TOKEN="your_token_here"

# Check current scene
python examples/scene_loader_client.py status

# Load a scene
python examples/scene_loader_client.py load "res://vr_main.tscn"

# List all scenes
python examples/scene_loader_client.py list

# List scenes in specific directory
python examples/scene_loader_client.py list --dir res://scenes

# Include addon scenes
python examples/scene_loader_client.py list --include-addons
```

**Note**: The CLI client needs to be updated to read `API_TOKEN` from environment and include it in requests.

---

## Common Use Cases

### 1. Automated Testing - Switch Between Test Scenes

```python
import time
import os

# Use the secure client with authentication
from secure_scene_loader_client import SecureSceneLoaderClient

# Create client (reads API_TOKEN from environment)
client = SecureSceneLoaderClient()

test_scenes = [
    "res://tests/test_walking_scene.tscn",
    "res://tests/test_resonance_input.tscn",
    "res://tests/test_coordinate_system.tscn"
]

for scene in test_scenes:
    print(f"Testing {scene}...")
    result = client.load_scene(scene)
    if not result:
        print(f"ERROR: Failed to load {scene}")
        continue
    time.sleep(5)  # Wait for scene to load
    # Run your tests here
    print(f"✓ {scene} complete")
```

### 2. Live Development - Hot Reload Scenes

```python
import time
from secure_scene_loader_client import SecureSceneLoaderClient

client = SecureSceneLoaderClient()

# Reload current scene to see changes
current = client.get_current_scene()
if current:
    current_path = current['scene_path']
    print(f"Reloading {current_path}...")
    client.load_scene(current_path)
else:
    print("ERROR: Could not get current scene")
```

### 3. Scene Discovery and Validation

```python
from secure_scene_loader_client import SecureSceneLoaderClient

client = SecureSceneLoaderClient()

# Get all test scenes
result = client.list_scenes(directory="res://tests")
if not result:
    print("ERROR: Failed to list scenes")
    exit(1)

print(f"Found {result['count']} test scenes:")

for scene in result['scenes']:
    print(f"\nValidating {scene['name']}...")
    print(f"  Path: {scene['path']}")
    print(f"  Size: {scene['size_bytes'] / 1024:.1f} KB")
    print(f"  Modified: {scene['modified']}")

    # Try loading each scene
    load_result = client.load_scene(scene['path'])
    if load_result:
        print(f"  ✓ Scene loads successfully")
    else:
        print(f"  ✗ Scene failed to load")
```

### 4. CI/CD Pipeline - Automated Scene Validation

```bash
#!/bin/bash
# validate_scenes.sh

# Check if API_TOKEN is set
if [ -z "$API_TOKEN" ]; then
  echo "ERROR: API_TOKEN environment variable not set"
  echo "Get token from Godot console and run: export API_TOKEN='your_token'"
  exit 1
fi

# Get list of all scenes (with authentication)
scenes=$(curl -s -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scenes | jq -r '.scenes[].path')

if [ -z "$scenes" ]; then
  echo "ERROR: Failed to get scenes list. Check authentication."
  exit 1
fi

for scene in $scenes; do
  echo "Validating $scene..."

  # Load scene with authentication
  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    -d "{\"scene_path\":\"$scene\"}" \
    http://127.0.0.1:8080/scene)

  # Check for errors in response
  if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
    error_msg=$(echo "$response" | jq -r '.message')
    echo "ERROR: Failed to load $scene - $error_msg"
    exit 1
  fi

  sleep 3

  # Verify scene loaded correctly
  current=$(curl -s -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene | jq -r '.scene_path')
  if [ "$current" != "$scene" ]; then
    echo "ERROR: Scene path mismatch. Expected $scene, got $current"
    exit 1
  fi
  echo "✓ $scene validated"
done

echo "All scenes validated successfully"
```

---

## Architecture

### How It Works

1. **HttpApiServer** autoload starts on Godot launch
2. **godottpd library** provides HTTP server infrastructure
3. **SceneRouter** handles /scene endpoint routing
4. **ScenesListRouter** handles /scenes endpoint routing
5. Scene loading uses `Engine.get_main_loop().call_deferred("change_scene_to_file", path)`
6. Async loading prevents blocking HTTP response

### Port Configuration

- **8080** - godottpd HTTP API (scene management)
- **8081** - GodotBridge (legacy DAP/LSP integration)
- **6005** - Language Server Protocol
- **6006** - Debug Adapter Protocol
- **8081** - WebSocket Telemetry

### Key Files

- `scripts/http_api/http_api_server.gd` - Main HTTP server autoload
- `scripts/http_api/scene_router.gd` - Scene endpoint handler
- `scripts/http_api/scenes_list_router.gd` - Scenes list endpoint handler
- `addons/godottpd/` - HTTP server library
- `examples/scene_loader_client.py` - Python client

---

## Troubleshooting

### Authentication Failures (401 Unauthorized)

**Symptom:** Getting `401 Unauthorized` errors on all requests

**Common Causes:**
1. Token not set in environment
2. Wrong token value
3. Missing "Bearer " prefix
4. Godot restarted (token changed)

**Solutions:**

1. **Check if token is set:**
   ```bash
   # Linux/Mac/Git Bash
   echo $API_TOKEN

   # Windows PowerShell
   echo $env:API_TOKEN
   ```

2. **Get fresh token from Godot console:**
   - Look for `[Security] API token generated: ...`
   - Copy the 64-character hex string
   - Set in environment: `export API_TOKEN="new_token"`

3. **Verify Authorization header format:**
   ```bash
   # Correct
   curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

   # Wrong - missing "Bearer"
   curl -H "Authorization: $API_TOKEN" http://127.0.0.1:8080/scene
   ```

4. **Test with explicit token:**
   ```bash
   TOKEN="a1b2c3d4..."  # paste token here
   curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene
   ```

### Scene Not Whitelisted (403 Forbidden)

**Symptom:** Getting `403 Forbidden` with "Scene not in whitelist" message

**Solution:** Add scene to whitelist in Godot console:

```gdscript
# Add single scene
HttpApiSecurityConfig.add_to_whitelist("res://my_scene.tscn")

# Add entire directory
HttpApiSecurityConfig.add_directory_to_whitelist("res://levels/")

# View current whitelist
print(HttpApiSecurityConfig.get_whitelist())
```

**Default whitelisted scenes:**
- `res://vr_main.tscn`
- `res://node_3d.tscn`
- `res://test_scene.tscn`

### Request Too Large (413 Payload Too Large)

**Symptom:** Getting `413 Payload Too Large` errors

**Cause:** Request body exceeds 1MB limit

**Solutions:**
1. Reduce request payload size
2. Check for accidental large data in request
3. Split operations into multiple smaller requests

### Server Not Responding

Check if Godot is running:
```bash
netstat -ano | grep 8080
```

Verify server started in Godot logs:
```
[HttpApiServer] ✓ HTTP API server started successfully on port 8080
[Security] API token generated: ...
```

### Scene Load Fails

**Symptom:** POST returns success but scene doesn't change

**Cause:** Scene may have errors or dependencies missing

**Solution:** Check Godot console for errors:
```bash
# Look for scene load errors in logs
grep -i error godot_final.log
```

### Port Already in Use

**Symptom:** Server fails to start

**Solution:** Kill existing process or change port in `http_api_server.gd`:
```gdscript
const PORT = 8090  # Change to available port
```

---

## Advantages Over DAP/LSP

### Before (DAP/LSP):
- ❌ Complex handshake protocol
- ❌ Connection timing issues
- ❌ Requires debug mode
- ❌ Not designed for automation

### After (HTTP API):
- ✅ Simple REST API
- ✅ Reliable connections
- ✅ Works in any mode
- ✅ Perfect for CI/CD

---

## Security Features (v2.5)

The HTTP API now includes comprehensive security features:

### Token-Based Authentication

- **Method**: Bearer token authentication
- **Token Format**: 64-character hexadecimal string
- **Generation**: Automatic on Godot startup
- **Lifetime**: Valid until Godot restarts
- **Header**: `Authorization: Bearer <token>`

### Scene Whitelist

- **Purpose**: Restrict scene loading to approved paths only
- **Default Scenes**: `vr_main.tscn`, `node_3d.tscn`, `test_scene.tscn`
- **Management**: Add scenes via `HttpApiSecurityConfig.add_to_whitelist()`
- **Response**: 403 Forbidden if scene not whitelisted

### Request Size Limits

- **Max Request Size**: 1MB (1,048,576 bytes)
- **Max Scene Path Length**: 256 characters
- **Response**: 413 Payload Too Large if limit exceeded

### Network Binding

- **Bind Address**: 127.0.0.1 (localhost only)
- **Purpose**: Prevents external network access
- **Security**: API only accepts local connections

### Error Responses

- **401 Unauthorized**: Missing or invalid token
- **403 Forbidden**: Scene not whitelisted or path traversal attempt
- **413 Payload Too Large**: Request exceeds size limit

**For detailed security information**, see:
- [QUICK_START_V2.5_SECURITY.md](../../../QUICK_START_V2.5_SECURITY.md) - Security-focused quick start
- [API_TOKEN_GUIDE.md](../../../API_TOKEN_GUIDE.md) - Comprehensive token management
- [HTTP_API_SECURITY_HARDENING_COMPLETE.md](../../../HTTP_API_SECURITY_HARDENING_COMPLETE.md) - Technical implementation details

---

## Next Steps

1. **Rate Limiting** - Add per-endpoint rate limiting (planned)
2. **Audit Logging** - Log all authentication attempts (planned)
3. **WebSocket Events** - Real-time scene change notifications
4. **Token Rotation** - Automatic token expiration and renewal (planned)

---

## Related Documentation

- **[QUICK_START.md](../../../QUICK_START.md)** - Quick start guide with authentication
- **[QUICK_START_V2.5_SECURITY.md](../../../QUICK_START_V2.5_SECURITY.md)** - Security-focused quick start
- **[API_TOKEN_GUIDE.md](../../../API_TOKEN_GUIDE.md)** - Token management guide
- **[HTTP_API_SECURITY_HARDENING_COMPLETE.md](../../../HTTP_API_SECURITY_HARDENING_COMPLETE.md)** - Security implementation details

---

**API Version**: v2.5 (Security-Hardened)

**Last Updated**: December 2, 2025
