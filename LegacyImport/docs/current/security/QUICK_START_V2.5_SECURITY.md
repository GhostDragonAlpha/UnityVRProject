# Quick Start - v2.5 Security-Hardened API

**Goal**: Get started with the secure HTTP API in 10 minutes

**Version**: v2.5 (Security-Hardened)

**Prerequisites**: Godot 4.5+ installed, Python 3.8+ (for examples)

---

## What's New in v2.5

The HTTP Scene Management API now includes comprehensive security features:

- **Token-Based Authentication**: All endpoints require Bearer token authentication
- **Scene Whitelist**: Only approved scenes can be loaded
- **Request Size Limits**: Protection against large payload attacks (1MB max)
- **Localhost Binding**: Server only accepts connections from 127.0.0.1
- **Proper Error Handling**: Clear 401, 403, and 413 responses

---

## Security Quick Start

### Step 1: Start Godot and Capture the Token (3 minutes)

The API token is generated when Godot starts and printed to the console.

**Option A: Visual Method (Easiest)**

1. Start Godot with debug flags:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. Look in the Godot console for these lines:
   ```
   [Security] API token generated: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
   [Security] Include in requests: Authorization: Bearer a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
   ```

3. Copy the 64-character token and save it

**Option B: Automated Method (Recommended for Scripts)**

```bash
# Windows (PowerShell)
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 2>&1 | Tee-Object -FilePath godot.log

# Linux/Mac
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log
```

Then extract the token from the log file:

```bash
# Linux/Mac/Git Bash
export API_TOKEN=$(grep "API token generated:" godot.log | grep -oP '(?<=generated: )[a-f0-9]+')

# Windows PowerShell
$env:API_TOKEN = (Select-String -Path godot.log -Pattern "API token generated: ([a-f0-9]+)").Matches[0].Groups[1].Value

# Windows Command Prompt (manual)
findstr "API token generated" godot.log
set API_TOKEN=<paste_token_here>
```

**Verify the token is set:**

```bash
# Linux/Mac/Git Bash
echo $API_TOKEN

# Windows PowerShell
echo $env:API_TOKEN

# Windows Command Prompt
echo %API_TOKEN%
```

---

### Step 2: Test Authentication (2 minutes)

**Test 1: Unauthenticated Request (Should Fail)**

```bash
curl http://127.0.0.1:8080/scene
```

**Expected Response (401 Unauthorized):**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token",
  "details": "Include 'Authorization: Bearer <token>' header"
}
```

**Test 2: Authenticated Request (Should Succeed)**

```bash
# Linux/Mac/Git Bash
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

# Windows PowerShell
curl -H "Authorization: Bearer $env:API_TOKEN" http://127.0.0.1:8080/scene

# Windows Command Prompt
curl -H "Authorization: Bearer %API_TOKEN%" http://127.0.0.1:8080/scene
```

**Expected Response (200 OK):**
```json
{
  "scene_name": "VRMain",
  "scene_path": "res://vr_main.tscn",
  "status": "loaded"
}
```

---

### Step 3: Understand the Scene Whitelist (2 minutes)

The API restricts scene loading to approved paths only.

**Default Whitelisted Scenes:**
- `res://vr_main.tscn`
- `res://node_3d.tscn`
- `res://test_scene.tscn`

**Test Loading a Whitelisted Scene:**

```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}'
```

**Expected Response (200 OK):**
```json
{
  "status": "loading",
  "scene": "res://vr_main.tscn",
  "message": "Scene load initiated successfully"
}
```

**Test Loading a Non-Whitelisted Scene:**

```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://unauthorized_scene.tscn"}'
```

**Expected Response (403 Forbidden):**
```json
{
  "error": "Forbidden",
  "message": "Scene not in whitelist"
}
```

---

### Step 4: Python Client Setup (3 minutes)

Create a Python client with proper authentication handling.

**File: `secure_client.py`**

```python
#!/usr/bin/env python3
"""Secure HTTP API Client with Token Authentication"""

import requests
import os
import sys
from typing import Optional, Dict, Any


class SecureApiClient:
    """Client for SpaceTime HTTP API with security"""

    def __init__(self, host: str = "127.0.0.1", port: int = 8080, token: Optional[str] = None):
        self.base_url = f"http://{host}:{port}"
        self.token = token or os.getenv("API_TOKEN")

        if not self.token:
            raise ValueError(
                "API token not provided. Set API_TOKEN environment variable or pass token parameter."
            )

    def _get_headers(self, **extra_headers) -> Dict[str, str]:
        """Get request headers with authentication"""
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }
        headers.update(extra_headers)
        return headers

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
                print("Authentication failed. Check your API token.")
            elif e.response.status_code == 403:
                print("Access forbidden.")
            else:
                print(f"HTTP error: {e}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"Request error: {e}")
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
                print("Authentication failed. Check your API token.")
            elif e.response.status_code == 403:
                error_data = e.response.json()
                print(f"Access forbidden: {error_data.get('message', 'Unknown reason')}")
            elif e.response.status_code == 413:
                print("Request too large.")
            else:
                print(f"HTTP error: {e}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"Request error: {e}")
            return None

    def list_scenes(self, directory: str = "res://", include_addons: bool = False) -> Optional[Dict[str, Any]]:
        """List available scenes"""
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
                print("Authentication failed. Check your API token.")
            else:
                print(f"HTTP error: {e}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"Request error: {e}")
            return None


def main():
    """Example usage"""
    # Create client (reads API_TOKEN from environment)
    try:
        client = SecureApiClient()
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

    # Get current scene
    print("Getting current scene...")
    scene = client.get_current_scene()
    if scene:
        print(f"  Current: {scene['scene_name']} ({scene['scene_path']})")
    else:
        print("  Failed to get current scene")

    # List scenes
    print("\nListing available scenes...")
    scenes = client.list_scenes()
    if scenes:
        print(f"  Found {scenes['count']} scenes:")
        for s in scenes['scenes']:
            print(f"    - {s['name']}: {s['path']}")
    else:
        print("  Failed to list scenes")

    # Try loading a whitelisted scene
    print("\nLoading whitelisted scene...")
    result = client.load_scene("res://vr_main.tscn")
    if result:
        print(f"  Success: {result['message']}")
    else:
        print("  Failed to load scene")


if __name__ == "__main__":
    main()
```

**Run the example:**

```bash
# Set API token first
export API_TOKEN="your_token_here"

# Run client
python secure_client.py
```

---

## Security Best Practices

### 1. Token Storage

**DO:**
- Store token in environment variables
- Use `.env` files (add to `.gitignore`)
- Rotate tokens on Godot restart
- Keep tokens out of source code

**DON'T:**
- Commit tokens to version control
- Share tokens in plain text
- Hardcode tokens in scripts
- Log tokens to files

### 2. Token Management

**Environment Variables (Recommended):**

```bash
# .env file (add to .gitignore)
API_TOKEN=your_token_here

# Load with python-dotenv
pip install python-dotenv

# In your script:
from dotenv import load_dotenv
load_dotenv()
token = os.getenv("API_TOKEN")
```

**Configuration Files:**

```python
# config.py (add to .gitignore)
API_CONFIG = {
    "host": "127.0.0.1",
    "port": 8080,
    "token": "your_token_here"
}

# In your script:
from config import API_CONFIG
client = SecureApiClient(**API_CONFIG)
```

### 3. Error Handling

Always handle authentication errors gracefully:

```python
def safe_api_call(func, *args, **kwargs):
    """Wrapper for API calls with error handling"""
    try:
        return func(*args, **kwargs)
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 401:
            print("ERROR: Authentication failed. Token may be expired or invalid.")
            print("SOLUTION: Restart Godot and get new token from console.")
        elif e.response.status_code == 403:
            print("ERROR: Access forbidden. Scene may not be whitelisted.")
            print("SOLUTION: Add scene to whitelist or use a whitelisted scene.")
        elif e.response.status_code == 413:
            print("ERROR: Request payload too large (max 1MB).")
        else:
            print(f"ERROR: HTTP {e.response.status_code}: {e}")
        return None
    except Exception as e:
        print(f"ERROR: {e}")
        return None
```

### 4. Scene Whitelist Management

**Check Current Whitelist (GDScript):**

```gdscript
# In Godot console or script
var whitelist = HttpApiSecurityConfig.get_whitelist()
print("Whitelisted scenes:")
for scene in whitelist:
    print("  - ", scene)
```

**Add Scene to Whitelist (GDScript):**

```gdscript
# Add single scene
HttpApiSecurityConfig.add_to_whitelist("res://my_scene.tscn")

# Add entire directory
HttpApiSecurityConfig.add_directory_to_whitelist("res://levels/")
```

---

## Common Security Errors

### Error 401: Unauthorized

**Cause**: Missing or invalid authentication token

**Solutions**:
1. Check token is set in environment
2. Verify token format: `Authorization: Bearer <token>`
3. Ensure token matches current Godot session (restart = new token)
4. Check for extra spaces or newlines in token

### Error 403: Forbidden

**Cause**: Scene not in whitelist or path traversal attempt

**Solutions**:
1. Verify scene is in whitelist
2. Add scene to whitelist via `HttpApiSecurityConfig.add_to_whitelist()`
3. Check scene path format: must be `res://path/to/scene.tscn`
4. Avoid path traversal (`..` not allowed)

### Error 413: Payload Too Large

**Cause**: Request body exceeds 1MB limit

**Solutions**:
1. Reduce request payload size
2. Check for accidental large data in request
3. Split large operations into smaller requests

---

## Testing the Security

### Test Suite for Security Features

```bash
# Test 1: Missing token (should fail with 401)
curl http://127.0.0.1:8080/scene
# Expected: {"error": "Unauthorized", ...}

# Test 2: Invalid token (should fail with 401)
curl -H "Authorization: Bearer invalid_token_12345" http://127.0.0.1:8080/scene
# Expected: {"error": "Unauthorized", ...}

# Test 3: Valid token (should succeed with 200)
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene
# Expected: {"scene_name": "VRMain", ...}

# Test 4: Non-whitelisted scene (should fail with 403)
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://not_whitelisted.tscn"}'
# Expected: {"error": "Forbidden", "message": "Scene not in whitelist"}

# Test 5: Path traversal (should fail with 403)
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://../../../etc/passwd.tscn"}'
# Expected: {"error": "Forbidden", "message": "Path traversal not allowed"}

# Test 6: Whitelisted scene (should succeed with 200)
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}'
# Expected: {"status": "loading", ...}
```

---

## Advanced Topics

### Multi-User Scenarios (Future)

Currently, the API uses a single token per Godot instance. Future versions may support:
- Multiple tokens with different permissions
- Token rotation without restart
- Token expiration
- User-specific tokens

### Token Rotation

The token is regenerated on each Godot restart. To rotate the token:

1. Restart Godot
2. Get new token from console
3. Update environment variable
4. Restart client scripts

**Automated rotation script:**

```bash
#!/bin/bash
# rotate_token.sh

# Kill Godot
pkill godot

# Start Godot and capture token
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log &

# Wait for startup
sleep 5

# Extract new token
export API_TOKEN=$(grep "API token generated:" godot.log | grep -oP '(?<=generated: )[a-f0-9]+')

echo "New token: $API_TOKEN"
```

### Disabling Security (Testing Only)

**WARNING: Only for local testing. Never disable security in production.**

```gdscript
# In Godot console or autoload script
HttpApiSecurityConfig.disable_auth()
```

This disables authentication but keeps other security features (whitelist, size limits).

---

## Next Steps

- **[API_TOKEN_GUIDE.md](API_TOKEN_GUIDE.md)** - Comprehensive token management guide
- **[HTTP_API_USAGE_GUIDE.md](HTTP_API_USAGE_GUIDE.md)** - Complete API reference with auth examples
- **[HTTP_API_SECURITY_HARDENING_COMPLETE.md](HTTP_API_SECURITY_HARDENING_COMPLETE.md)** - Technical security implementation details

---

**Security Level**: Production-Ready

**API Version**: v2.5

**Last Updated**: December 2, 2025
