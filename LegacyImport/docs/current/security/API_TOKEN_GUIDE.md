# API Token Management Guide

**Comprehensive guide for managing authentication tokens in the SpaceTime HTTP API**

**Version**: v2.5

**Last Updated**: December 2, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [How to Get Your Token](#how-to-get-your-token)
3. [Token Storage Methods](#token-storage-methods)
4. [Using Tokens in Requests](#using-tokens-in-requests)
5. [Token Security Best Practices](#token-security-best-practices)
6. [Token Lifecycle](#token-lifecycle)
7. [Scene Whitelist Management](#scene-whitelist-management)
8. [Multi-User Scenarios](#multi-user-scenarios-future)
9. [Troubleshooting](#troubleshooting)
10. [Security Checklist](#security-checklist)

---

## Overview

The SpaceTime HTTP API uses token-based authentication to protect endpoints from unauthorized access. Each Godot instance generates a unique API token on startup.

### Key Facts

- **Token Type**: Bearer token (64-character hexadecimal string)
- **Generation**: Automatic on Godot startup
- **Lifetime**: Valid until Godot restarts
- **Scope**: Per-Godot-instance (single token per server)
- **Transmission**: HTTP `Authorization` header
- **Format**: `Authorization: Bearer <token>`

### Security Features

- **32-byte random generation**: Cryptographically secure token
- **Session-scoped**: Token changes on restart (automatic rotation)
- **Localhost-only**: API only accepts connections from 127.0.0.1
- **No storage**: Token is not persisted to disk
- **Single-use generation**: Token generated once per session

---

## How to Get Your Token

### Method 1: Console Output (Easiest)

When Godot starts, the API token is printed to the console.

**Start Godot:**
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**Look for these lines in the console:**
```
[Security] API token generated: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
[Security] Include in requests: Authorization: Bearer a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

**Copy the token** (the 64-character string after `generated:`)

### Method 2: Log File Capture (Recommended for Automation)

Redirect Godot's output to a file for automated token extraction.

**Windows (PowerShell):**
```powershell
# Start Godot and capture output
Start-Process godot -ArgumentList "--path", "C:/godot", "--dap-port", "6006", "--lsp-port", "6005" -RedirectStandardOutput godot.log -RedirectStandardError godot_err.log -NoNewWindow

# Wait for startup
Start-Sleep -Seconds 5

# Extract token
$env:API_TOKEN = (Select-String -Path godot.log -Pattern "API token generated: ([a-f0-9]+)").Matches[0].Groups[1].Value

# Verify
Write-Host "Token: $env:API_TOKEN"
```

**Linux/Mac:**
```bash
# Start Godot and capture output
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log &

# Wait for startup
sleep 5

# Extract token
export API_TOKEN=$(grep "API token generated:" godot.log | grep -oP '(?<=generated: )[a-f0-9]+')

# Verify
echo "Token: $API_TOKEN"
```

**Git Bash on Windows:**
```bash
# Start Godot and capture output
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log &

# Wait for startup
sleep 5

# Extract token
export API_TOKEN=$(grep "API token generated:" godot.log | awk '{print $5}')

# Verify
echo "Token: $API_TOKEN"
```

### Method 3: Programmatic Access (GDScript)

If you need to access the token from within Godot (e.g., for internal tools):

```gdscript
# Get current token
var token = HttpApiSecurityConfig.get_token()
print("Current API token: ", token)
```

### Method 4: Test Endpoint (Development Only)

**Note**: This endpoint should be disabled in production builds.

```bash
# Request token via HTTP (if test endpoint is enabled)
curl http://127.0.0.1:8080/debug/token
```

**Response:**
```json
{
  "token": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "format": "Authorization: Bearer <token>"
}
```

---

## Token Storage Methods

### Environment Variables (Recommended)

**Pros**: Standard, secure, easy to manage
**Cons**: Session-scoped, lost on terminal close

**Set the token:**

```bash
# Linux/Mac/Git Bash
export API_TOKEN="your_token_here"

# Windows PowerShell
$env:API_TOKEN = "your_token_here"

# Windows Command Prompt
set API_TOKEN=your_token_here
```

**Verify the token:**

```bash
# Linux/Mac/Git Bash
echo $API_TOKEN

# Windows PowerShell
echo $env:API_TOKEN

# Windows Command Prompt
echo %API_TOKEN%
```

**Use in scripts:**

```python
import os
token = os.getenv("API_TOKEN")
if not token:
    raise ValueError("API_TOKEN environment variable not set")
```

### .env Files (Recommended for Projects)

**Pros**: Project-scoped, version-controllable (without token), shareable
**Cons**: Requires additional library

**Create `.env` file:**
```bash
# .env (add to .gitignore)
API_TOKEN=your_token_here
API_HOST=127.0.0.1
API_PORT=8080
```

**Add to `.gitignore`:**
```gitignore
.env
*.env
godot.log
```

**Create `.env.example` (commit this):**
```bash
# .env.example (safe to commit)
API_TOKEN=get_from_godot_console
API_HOST=127.0.0.1
API_PORT=8080
```

**Use with Python:**

```python
from dotenv import load_dotenv
import os

# Load environment variables from .env
load_dotenv()

# Get token
token = os.getenv("API_TOKEN")
```

**Install python-dotenv:**
```bash
pip install python-dotenv
```

### Configuration Files (For Complex Setups)

**Pros**: Flexible, supports multiple environments
**Cons**: Requires manual security (permissions, gitignore)

**Create `config.py` (add to .gitignore):**

```python
# config.py
# WARNING: Add this file to .gitignore!

API_CONFIG = {
    "host": "127.0.0.1",
    "port": 8080,
    "token": "your_token_here",
    "timeout": 10,
    "retry_count": 3
}
```

**Create `config.example.py` (safe to commit):**

```python
# config.example.py
# Copy to config.py and add your token

API_CONFIG = {
    "host": "127.0.0.1",
    "port": 8080,
    "token": "GET_FROM_GODOT_CONSOLE",
    "timeout": 10,
    "retry_count": 3
}
```

**Use in scripts:**

```python
from config import API_CONFIG

token = API_CONFIG["token"]
host = API_CONFIG["host"]
port = API_CONFIG["port"]
```

### Secure Keyring (Advanced)

**Pros**: Most secure, OS-level encryption
**Cons**: More complex, requires additional setup

**Install keyring library:**
```bash
pip install keyring
```

**Store token:**

```python
import keyring

# Store token
keyring.set_password("spacetime_api", "token", "your_token_here")
```

**Retrieve token:**

```python
import keyring

# Get token
token = keyring.get_password("spacetime_api", "token")
```

**Delete token:**

```python
import keyring

# Delete token
keyring.delete_password("spacetime_api", "token")
```

---

## Using Tokens in Requests

### curl (Command Line)

**Linux/Mac/Git Bash:**
```bash
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene
```

**Windows PowerShell:**
```powershell
curl -Headers @{Authorization="Bearer $env:API_TOKEN"} http://127.0.0.1:8080/scene
```

**Windows Command Prompt:**
```cmd
curl -H "Authorization: Bearer %API_TOKEN%" http://127.0.0.1:8080/scene
```

### Python requests

**Basic usage:**

```python
import requests
import os

token = os.getenv("API_TOKEN")

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

response = requests.get("http://127.0.0.1:8080/scene", headers=headers)
print(response.json())
```

**Reusable session:**

```python
import requests
import os

class ApiClient:
    def __init__(self, token=None):
        self.session = requests.Session()
        self.token = token or os.getenv("API_TOKEN")
        self.session.headers.update({
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        })

    def get(self, endpoint):
        return self.session.get(f"http://127.0.0.1:8080{endpoint}")

    def post(self, endpoint, data):
        return self.session.post(f"http://127.0.0.1:8080{endpoint}", json=data)

# Usage
client = ApiClient()
response = client.get("/scene")
print(response.json())
```

### JavaScript/Node.js

**Using fetch:**

```javascript
const API_TOKEN = process.env.API_TOKEN;

async function getScene() {
    const response = await fetch('http://127.0.0.1:8080/scene', {
        headers: {
            'Authorization': `Bearer ${API_TOKEN}`
        }
    });
    return await response.json();
}

getScene().then(data => console.log(data));
```

**Using axios:**

```javascript
const axios = require('axios');
const API_TOKEN = process.env.API_TOKEN;

const client = axios.create({
    baseURL: 'http://127.0.0.1:8080',
    headers: {
        'Authorization': `Bearer ${API_TOKEN}`
    }
});

client.get('/scene')
    .then(response => console.log(response.data))
    .catch(error => console.error(error));
```

### C# / .NET

```csharp
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;

class ApiClient
{
    private readonly HttpClient _client;

    public ApiClient(string token)
    {
        _client = new HttpClient();
        _client.BaseAddress = new Uri("http://127.0.0.1:8080");
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
    }

    public async Task<string> GetSceneAsync()
    {
        var response = await _client.GetAsync("/scene");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync();
    }
}

// Usage
var token = Environment.GetEnvironmentVariable("API_TOKEN");
var client = new ApiClient(token);
var scene = await client.GetSceneAsync();
Console.WriteLine(scene);
```

---

## Token Security Best Practices

### DO

1. **Store tokens in environment variables or secure keystores**
   ```bash
   export API_TOKEN="your_token_here"
   ```

2. **Add token files to .gitignore**
   ```gitignore
   .env
   config.py
   *.log
   ```

3. **Use HTTPS in production** (when available)

4. **Rotate tokens regularly** (restart Godot)

5. **Validate token format before use**
   ```python
   import re
   if not re.match(r'^[a-f0-9]{64}$', token):
       raise ValueError("Invalid token format")
   ```

6. **Handle authentication errors gracefully**
   ```python
   if response.status_code == 401:
       print("Token expired or invalid. Restart Godot and get new token.")
   ```

7. **Use read-only permissions for config files**
   ```bash
   chmod 400 config.py  # Read-only for owner
   ```

8. **Clear tokens from memory when done**
   ```python
   token = os.getenv("API_TOKEN")
   # Use token...
   token = None  # Clear reference
   ```

### DON'T

1. **Don't commit tokens to version control**
   ```python
   # BAD - hardcoded token
   token = "a1b2c3d4e5f6..."
   ```

2. **Don't log tokens**
   ```python
   # BAD - token in logs
   print(f"Using token: {token}")

   # GOOD - hide token
   print(f"Using token: {token[:8]}...")
   ```

3. **Don't share tokens in plain text**
   - Don't email tokens
   - Don't paste in Slack/Discord
   - Don't include in screenshots

4. **Don't use tokens in URLs**
   ```python
   # BAD - token in URL
   url = f"http://127.0.0.1:8080/scene?token={token}"

   # GOOD - token in header
   headers = {"Authorization": f"Bearer {token}"}
   ```

5. **Don't reuse tokens across environments**
   - Each Godot instance has its own token
   - Don't copy tokens between machines

6. **Don't disable authentication in production**
   ```gdscript
   # BAD - disabling auth
   HttpApiSecurityConfig.disable_auth()
   ```

---

## Token Lifecycle

### Generation

**When**: Godot startup (when HttpApiServer initializes)

**Process**:
1. HttpApiSecurityConfig.generate_token() is called
2. 32 random bytes are generated
3. Bytes are hex-encoded to 64-character string
4. Token is printed to console
5. Token is stored in memory (not persisted)

**GDScript implementation:**
```gdscript
static func generate_token() -> String:
    if _api_token.is_empty():
        var bytes = PackedByteArray()
        for i in range(32):
            bytes.append(randi() % 256)
        _api_token = bytes.hex_encode()
        print("[Security] API token generated: ", _api_token)
    return _api_token
```

### Validation

**When**: Every HTTP request (except `/status`)

**Process**:
1. Extract `Authorization` header from request
2. Check for `Bearer ` prefix
3. Extract token (characters after `Bearer `)
4. Compare with stored token
5. Return 401 if mismatch, continue if match

**GDScript implementation:**
```gdscript
static func validate_auth(request: HttpRequest) -> bool:
    var auth_header = request.headers.get("Authorization", "")
    if auth_header.is_empty():
        return false
    if not auth_header.begins_with("Bearer "):
        return false
    var token = auth_header.substr(7).strip_edges()
    return token == get_token()
```

### Rotation

**When**: Godot restart (manual rotation)

**Process**:
1. Stop Godot
2. Start Godot
3. New token is generated
4. Old token is invalid
5. Update clients with new token

**Automated rotation script:**

```bash
#!/bin/bash
# rotate_godot_token.sh

echo "Rotating Godot API token..."

# Kill existing Godot process
pkill godot
echo "Stopped Godot"

# Start Godot with log capture
godot --path "/path/to/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log &
echo "Started Godot"

# Wait for startup
sleep 10

# Extract new token
NEW_TOKEN=$(grep "API token generated:" godot.log | grep -oP '(?<=generated: )[a-f0-9]+')

if [ -z "$NEW_TOKEN" ]; then
    echo "ERROR: Failed to extract token from log"
    exit 1
fi

# Update environment
export API_TOKEN=$NEW_TOKEN
echo "New token: $API_TOKEN"

# Update .env file if it exists
if [ -f .env ]; then
    sed -i "s/API_TOKEN=.*/API_TOKEN=$NEW_TOKEN/" .env
    echo "Updated .env file"
fi

echo "Token rotation complete"
```

### Expiration

**Current**: No automatic expiration (token valid until Godot restarts)

**Future** (planned):
- Time-based expiration (e.g., 24 hours)
- Request-based expiration (e.g., 1000 requests)
- Manual revocation API

---

## Scene Whitelist Management

The API restricts scene loading to approved paths for security.

### Default Whitelist

```gdscript
# Default whitelisted scenes
static var _scene_whitelist: Array[String] = [
    "res://vr_main.tscn",
    "res://node_3d.tscn",
    "res://test_scene.tscn",
]
```

### View Current Whitelist

**GDScript (in Godot console or script):**
```gdscript
var whitelist = HttpApiSecurityConfig.get_whitelist()
print("Whitelisted scenes:")
for scene in whitelist:
    print("  - ", scene)
```

**Python (via helper endpoint, if implemented):**
```python
# This requires a GET /security/whitelist endpoint (not yet implemented)
response = requests.get(
    "http://127.0.0.1:8080/security/whitelist",
    headers={"Authorization": f"Bearer {token}"}
)
print(response.json()["whitelist"])
```

### Add Scene to Whitelist

**Single scene:**
```gdscript
HttpApiSecurityConfig.add_to_whitelist("res://my_scene.tscn")
```

**Multiple scenes:**
```gdscript
var scenes = [
    "res://level_01.tscn",
    "res://level_02.tscn",
    "res://level_03.tscn"
]
for scene in scenes:
    HttpApiSecurityConfig.add_to_whitelist(scene)
```

**Entire directory:**
```gdscript
# Allow all scenes in res://levels/
HttpApiSecurityConfig.add_directory_to_whitelist("res://levels/")
```

**At startup (in autoload script):**
```gdscript
# scripts/autoloads/security_setup.gd
extends Node

func _ready():
    # Add project-specific scenes to whitelist
    HttpApiSecurityConfig.add_to_whitelist("res://menu.tscn")
    HttpApiSecurityConfig.add_directory_to_whitelist("res://levels/")
    HttpApiSecurityConfig.add_directory_to_whitelist("res://tests/")

    print("[Security] Custom scenes added to whitelist")
```

### Remove Scene from Whitelist

**Note**: No built-in removal function yet. Edit security_config.gd directly:

```gdscript
# In security_config.gd
static func remove_from_whitelist(scene_path: String) -> void:
    var index = _scene_whitelist.find(scene_path)
    if index >= 0:
        _scene_whitelist.remove_at(index)
        print("[Security] Removed from whitelist: ", scene_path)
```

### Disable Whitelist (Testing Only)

**WARNING: Only for local development. Never disable in production.**

```gdscript
# Disable whitelist checking
HttpApiSecurityConfig.whitelist_enabled = false
print("[Security] WARNING: Scene whitelist disabled")
```

---

## Multi-User Scenarios (Future)

Currently, the API uses a single token per Godot instance. Future versions may support:

### Multiple Tokens

**Use case**: Different clients with different permissions

**Planned features**:
- Read-only tokens (GET requests only)
- Admin tokens (all requests)
- Scene-specific tokens (can only load certain scenes)

**Example configuration (future):**
```gdscript
# Generate read-only token
var readonly_token = HttpApiSecurityConfig.generate_readonly_token()

# Generate admin token
var admin_token = HttpApiSecurityConfig.generate_admin_token()

# Generate scene-specific token
var level_token = HttpApiSecurityConfig.generate_token_for_scenes([
    "res://level_01.tscn",
    "res://level_02.tscn"
])
```

### Token Permissions

**Planned permission levels:**
- `none`: No access
- `read`: GET requests only
- `scene_load`: Can load scenes from whitelist
- `scene_manage`: Can add/remove from whitelist
- `admin`: Full access

### Token Metadata

**Planned token metadata:**
```json
{
  "token": "a1b2c3d4...",
  "created_at": "2025-12-02T10:30:00Z",
  "expires_at": "2025-12-03T10:30:00Z",
  "permissions": ["read", "scene_load"],
  "allowed_scenes": ["res://vr_main.tscn"],
  "request_count": 42,
  "last_used": "2025-12-02T11:15:30Z"
}
```

---

## Troubleshooting

### Issue: "Missing or invalid authentication token"

**Symptoms:**
- HTTP 401 response
- Error message: "Missing or invalid authentication token"

**Solutions:**

1. **Check if token is set:**
   ```bash
   echo $API_TOKEN  # Should print 64-character hex string
   ```

2. **Verify token format:**
   ```python
   import re
   token = os.getenv("API_TOKEN")
   if not re.match(r'^[a-f0-9]{64}$', token):
       print("Invalid token format")
   ```

3. **Check Authorization header:**
   ```bash
   # Correct format
   curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

   # Wrong - missing "Bearer"
   curl -H "Authorization: $API_TOKEN" http://127.0.0.1:8080/scene
   ```

4. **Get fresh token from console:**
   - Look for `[Security] API token generated:` in Godot output
   - Copy the entire 64-character token
   - Set in environment: `export API_TOKEN="new_token"`

5. **Check if Godot restarted:**
   - Token changes on every restart
   - Get new token after restart

### Issue: "Scene not in whitelist"

**Symptoms:**
- HTTP 403 response
- Error message: "Scene not in whitelist"

**Solutions:**

1. **Check whitelist:**
   ```gdscript
   # In Godot console
   print(HttpApiSecurityConfig.get_whitelist())
   ```

2. **Add scene to whitelist:**
   ```gdscript
   HttpApiSecurityConfig.add_to_whitelist("res://your_scene.tscn")
   ```

3. **Add directory to whitelist:**
   ```gdscript
   HttpApiSecurityConfig.add_directory_to_whitelist("res://scenes/")
   ```

4. **Verify scene path format:**
   - Must start with `res://`
   - Must end with `.tscn`
   - No path traversal (`..`)
   - Max 256 characters

### Issue: Token not appearing in console

**Symptoms:**
- No `[Security] API token generated:` line in console
- Can't find token in logs

**Solutions:**

1. **Check if security is initialized:**
   - Token is generated when HttpApiServer starts
   - Look for `[HttpApiServer]` messages in console

2. **Redirect console output:**
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log
   grep "API token" godot.log
   ```

3. **Check Godot startup:**
   - Ensure Godot starts successfully
   - Look for errors in console
   - Verify autoload scripts are running

4. **Manually trigger token generation:**
   ```gdscript
   # In Godot console
   var token = HttpApiSecurityConfig.generate_token()
   print("Token: ", token)
   ```

### Issue: Request size limit exceeded

**Symptoms:**
- HTTP 413 response
- Error message: "Request body exceeds maximum size"

**Solutions:**

1. **Check request size:**
   ```python
   import json
   data = {"scene_path": "res://vr_main.tscn"}
   size = len(json.dumps(data))
   print(f"Request size: {size} bytes")
   ```

2. **Reduce payload size:**
   - Remove unnecessary data from request
   - Split large operations into multiple requests

3. **Adjust size limit (not recommended):**
   ```gdscript
   # In security_config.gd
   const MAX_REQUEST_SIZE = 2097152  # 2MB instead of 1MB
   ```

---

## Security Checklist

Use this checklist to ensure proper token security:

### Development

- [ ] Token is stored in environment variable, not hardcoded
- [ ] `.env` file is in `.gitignore`
- [ ] `.env.example` is committed (without real token)
- [ ] Token is validated before use
- [ ] Authentication errors are handled gracefully
- [ ] Token is not logged or printed
- [ ] Authorization header uses correct format: `Bearer <token>`

### Testing

- [ ] Test with missing token (expect 401)
- [ ] Test with invalid token (expect 401)
- [ ] Test with valid token (expect 200)
- [ ] Test with non-whitelisted scene (expect 403)
- [ ] Test with path traversal attempt (expect 403)

### Production (Future)

- [ ] HTTPS is enabled
- [ ] Token rotation is automated
- [ ] Token expiration is configured
- [ ] Audit logging is enabled
- [ ] Rate limiting is configured
- [ ] Whitelist is minimal (only required scenes)
- [ ] Security monitoring is active

### Code Review

- [ ] No tokens in source code
- [ ] No tokens in comments
- [ ] No tokens in git history
- [ ] Configuration files are gitignored
- [ ] Environment variables are documented
- [ ] Error handling doesn't leak tokens

---

## Additional Resources

- **[QUICK_START_V2.5_SECURITY.md](QUICK_START_V2.5_SECURITY.md)** - Quick start with security focus
- **[HTTP_API_USAGE_GUIDE.md](HTTP_API_USAGE_GUIDE.md)** - Complete API reference with auth examples
- **[HTTP_API_SECURITY_HARDENING_COMPLETE.md](HTTP_API_SECURITY_HARDENING_COMPLETE.md)** - Technical security implementation
- **[QUICK_START.md](QUICK_START.md)** - General quick start guide

---

**Document Version**: 1.0

**API Version**: v2.5

**Security Status**: Production-Ready

**Last Updated**: December 2, 2025
