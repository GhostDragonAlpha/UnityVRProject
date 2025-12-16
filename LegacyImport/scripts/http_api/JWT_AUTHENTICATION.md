# JWT Authentication System - Complete Guide

**Version**: 2.5+
**Last Updated**: December 2, 2025
**Document Status**: Production Ready

---

## Table of Contents

- [Overview](#overview)
- [JWT Implementation](#jwt-implementation)
- [Token Format and Claims](#token-format-and-claims)
- [Token Lifecycle](#token-lifecycle)
- [Obtaining Tokens](#obtaining-tokens)
- [Using JWT Tokens](#using-jwt-tokens)
- [Token Expiration Handling](#token-expiration-handling)
- [Security Considerations](#security-considerations)
- [Migration from Legacy Tokens](#migration-from-legacy-tokens)
- [Troubleshooting Guide](#troubleshooting-guide)
- [API Examples](#api-examples)
- [Best Practices](#best-practices)

---

## Overview

The SpaceTime project uses JWT (JSON Web Tokens) as the primary authentication mechanism for the HTTP API. This provides a secure, stateless way to authenticate API requests from external clients including AI assistants, monitoring tools, and custom applications.

### Key Features

- **Stateless Authentication**: Tokens are self-contained; no session storage required
- **Bearer Token Format**: Standard HTTP `Authorization: Bearer <token>` header
- **HMAC-SHA256**: Industry-standard cryptographic signing
- **Automatic Generation**: Tokens auto-generated on Godot startup
- **Session-Based Validity**: Tokens remain valid for the entire Godot session
- **Circuit Breaker Pattern**: Failed authentications tracked and reported
- **Audit Trail**: All authentication attempts logged

### Architecture

```
┌─────────────────────┐
│  External Client    │
│  (AI, Script, etc)  │
└──────────┬──────────┘
           │
           │ HTTP Request with JWT
           │ Authorization: Bearer token
           ▼
┌─────────────────────────────────────┐
│    GodotBridge HTTP Server          │
│    (Port 8080)                      │
├─────────────────────────────────────┤
│  Token Validation Layer             │
│  - Verify HMAC signature            │
│  - Check token structure            │
│  - Validate claims (optional)       │
└──────────┬──────────────────────────┘
           │
    ✅ Valid Token
           │
           ▼
┌─────────────────────────────────────┐
│    API Endpoint Handler             │
│    (Debug, Scene, Edit, etc)        │
└─────────────────────────────────────┘
```

---

## JWT Implementation

### Token Structure

JWT tokens consist of three parts separated by dots (`.`):

```
header.payload.signature
```

#### Header

Contains metadata about the token:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

- `alg`: Algorithm used for signing (always HS256)
- `typ`: Token type (always JWT)

#### Payload

Contains the actual claims (user information):

```json
{
  "sub": "godot_session",
  "iat": 1702592400,
  "exp": null,
  "token_id": "session_token_001",
  "permissions": ["all"],
  "scope": "api:*"
}
```

**Payload fields**:
- `sub` (Subject): Token subject identifier
- `iat` (Issued At): Unix timestamp when token was created
- `exp` (Expiration): Unix timestamp when token expires (null = no expiration)
- `token_id`: Unique identifier for this token
- `permissions`: Array of granted permissions
- `scope`: OAuth2-style scope string

#### Signature

HMAC-SHA256 hash of the encoded header and payload:

```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret_key
)
```

The signature ensures the token hasn't been tampered with.

### Token Generation

Tokens are automatically generated when GodotBridge starts:

```gdscript
# In godot_bridge.gd _ready():
func _generate_token() -> String:
    var secret = _generate_secret()
    var header = {"alg": "HS256", "typ": "JWT"}
    var now = Time.get_unix_time_from_system()
    var payload = {
        "sub": "godot_session",
        "iat": now,
        "exp": null,  # No expiration
        "token_id": "session_token_001",
        "permissions": ["all"],
        "scope": "api:*"
    }

    var token = _encode_jwt(header, payload, secret)
    return token
```

---

## Token Format and Claims

### Complete Token Example

A real JWT token looks like:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJnb2RvdF9zZXNzaW9uIiwiaWF0IjoxNzAyNTkyNDAwLCJleHAiOm51bGwsInRva2VuX2lkIjoic2Vzc2lvbl90b2tlbl8wMDEiLCJwZXJtaXNzaW9ucyI6WyJhbGwiXSwic2NvcGUiOiJhcGk6KiJ9.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
```

**Decoding** (not required for use, but helpful for debugging):

```python
import json
import base64

token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJnb2RvdF9zZXNzaW9uIiwiaWF0IjoxNzAyNTkyNDAwLCJleHAiOm51bGwsInRva2VuX2lkIjoic2Vzc2lvbl90b2tlbl8wMDEiLCJwZXJtaXNzaW9ucyI6WyJhbGwiXSwic2NvcGUiOiJhcGk6KiJ9.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

# Split token
parts = token.split('.')

# Decode header
header = json.loads(base64.urlsafe_b64decode(parts[0] + '=='))
print("Header:", header)

# Decode payload
payload = json.loads(base64.urlsafe_b64decode(parts[1] + '=='))
print("Payload:", payload)

# Note: Signature cannot be decoded (it's just a hash)
```

Output:

```json
Header: {
  "alg": "HS256",
  "typ": "JWT"
}

Payload: {
  "sub": "godot_session",
  "iat": 1702592400,
  "exp": null,
  "token_id": "session_token_001",
  "permissions": ["all"],
  "scope": "api:*"
}
```

### Standard Claims Reference

| Claim | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `sub` | String | Yes | Subject (who the token represents) | `"godot_session"` |
| `iat` | Number | Yes | Issued At (Unix timestamp) | `1702592400` |
| `exp` | Number | No | Expiration time (null = no expiration) | `1702678800` |
| `token_id` | String | Yes | Unique token identifier | `"session_token_001"` |
| `permissions` | Array | Yes | Granted permissions | `["all"]` |
| `scope` | String | Yes | OAuth2-style scope | `"api:*"` |

### Custom Claims

Future versions may include:

```json
{
  "user_id": "developer_001",
  "role": "admin",
  "created_by": "godot_engine",
  "version": "2.5.0"
}
```

---

## Token Lifecycle

### Timeline

```
Godot Start → Token Generated → Active Session → Godot Shutdown → Token Invalidated
    |              |                  |                              |
    ▼              ▼                  ▼                              ▼
   t=0            t=0               t=1min                         t=end
                                     |
                              Token always valid
                              (no expiration)
```

### States

**1. Generated**
- Created when GodotBridge initializes
- Token printed to console
- Stored in environment for client use

**2. Active**
- Valid for all API requests
- No time-based expiration
- Persists for entire Godot session

**3. Invalidated**
- Automatically invalidated when Godot stops
- Manual restart required to get new token
- Cannot be reused after invalidation

### Token Lifetime Diagram

```
Timeline:
[Generated] ─────────────────────── [Expires on Shutdown]
   │                                      │
   └─ Token active for entire session     └─ Restart to get new token
```

---

## Obtaining Tokens

### Method 1: Godot Console Output (Recommended)

When GodotBridge initializes, it prints the token to the console:

```
=== GODOT BRIDGE INITIALIZATION ===
API Token Generated: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Token expires: Never (valid for session)
Token permissions: All endpoints
Copy this token and include in all API requests
=== GODOT BRIDGE INITIALIZATION COMPLETE ===
```

**Steps**:
1. Start Godot: `godot --path "C:/godot" --dap-port 6006 --lsp-port 6005`
2. Watch console output during startup
3. Copy the token from the `API Token Generated:` line
4. Use in subsequent API requests

### Method 2: Environment Variable

Store the token in your environment for easy access:

**Windows (PowerShell)**:
```powershell
$env:GODOT_API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Windows (CMD)**:
```cmd
set GODOT_API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Linux/Mac (Bash)**:
```bash
export GODOT_API_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Verify**:
```bash
echo $GODOT_API_TOKEN
# Should print the full token
```

### Method 3: Configuration File

Save token to a config file:

**.env file** (not committed to version control):
```ini
GODOT_API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Add to .gitignore**:
```
.env
*.token
```

**Load in Python**:
```python
import os
from dotenv import load_dotenv

load_dotenv()
token = os.getenv("GODOT_API_TOKEN")
```

---

## Using JWT Tokens

### Basic Usage Pattern

All HTTP API requests must include the token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

### HTTP Headers

**Complete request example**:

```
POST /debug/setBreakpoints HTTP/1.1
Host: 127.0.0.1:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Content-Length: 125

{"source": {"path": "res://player.gd"}, "breakpoints": [{"line": 10}]}
```

### cURL Examples

**Without token (fails with 401)**:
```bash
curl -X POST http://127.0.0.1:8080/status
# Response: {"error": "Unauthorized", "status_code": 401}
```

**With token (succeeds)**:
```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET http://127.0.0.1:8080/status \
  -H "Authorization: Bearer $TOKEN"
```

**Using environment variable**:
```bash
curl -X GET http://127.0.0.1:8080/status \
  -H "Authorization: Bearer $GODOT_API_TOKEN"
```

**Complete example with all options**:
```bash
#!/bin/bash
set -e

# Token from environment
TOKEN="${GODOT_API_TOKEN}"

if [ -z "$TOKEN" ]; then
    echo "ERROR: GODOT_API_TOKEN not set"
    echo "Export token: export GODOT_API_TOKEN=\"<token_from_console>\""
    exit 1
fi

# API endpoint
API="http://127.0.0.1:8080"

# Make request
curl -X POST "$API/debug/setBreakpoints" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "source": {"path": "res://player.gd"},
        "breakpoints": [{"line": 10}, {"line": 25}]
    }' \
    | jq .
```

### Python Examples

**Basic request**:
```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}

response = requests.get(
    "http://127.0.0.1:8080/status",
    headers=headers
)

print(response.json())
```

**With error handling**:
```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")

if not token:
    print("ERROR: GODOT_API_TOKEN not set")
    exit(1)

headers = {"Authorization": f"Bearer {token}"}

try:
    response = requests.post(
        "http://127.0.0.1:8080/debug/setBreakpoints",
        headers=headers,
        json={
            "source": {"path": "res://player.gd"},
            "breakpoints": [{"line": 10}]
        }
    )

    if response.status_code == 401:
        print("Authentication failed - invalid or expired token")
        print("Get new token from Godot console")
    elif response.status_code == 200:
        print("Success:", response.json())
    else:
        print(f"Error: {response.status_code}")
        print(response.json())

except requests.exceptions.ConnectionError:
    print("ERROR: Cannot connect to Godot API")
    print("Ensure Godot is running with debug flags:")
    print("godot --path \"C:/godot\" --dap-port 6006 --lsp-port 6005")
```

**With retry logic**:
```python
import requests
import time
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}

def make_request_with_retry(endpoint, json_data, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = requests.post(
                f"http://127.0.0.1:8080{endpoint}",
                headers=headers,
                json=json_data,
                timeout=5
            )

            if response.status_code == 401:
                raise Exception("Authentication failed - get new token")

            if response.status_code == 200:
                return response.json()

            if attempt < max_retries - 1:
                print(f"Attempt {attempt + 1} failed, retrying...")
                time.sleep(1)

        except requests.exceptions.Timeout:
            if attempt < max_retries - 1:
                print(f"Timeout on attempt {attempt + 1}, retrying...")
                time.sleep(1)

    raise Exception("Request failed after max retries")

# Usage
result = make_request_with_retry(
    "/debug/setBreakpoints",
    {
        "source": {"path": "res://player.gd"},
        "breakpoints": [{"line": 10}]
    }
)
print(result)
```

### JavaScript/Node.js Examples

**Basic request**:
```javascript
const fetch = require('node-fetch');

const token = process.env.GODOT_API_TOKEN;
const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
};

fetch('http://127.0.0.1:8080/status', {
    method: 'GET',
    headers: headers
})
.then(res => res.json())
.then(data => console.log(data))
.catch(err => console.error(err));
```

**With Axios**:
```javascript
const axios = require('axios');

const token = process.env.GODOT_API_TOKEN;

const client = axios.create({
    baseURL: 'http://127.0.0.1:8080',
    headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
    }
});

client.post('/debug/setBreakpoints', {
    source: { path: 'res://player.gd' },
    breakpoints: [{ line: 10 }]
})
.then(res => console.log(res.data))
.catch(err => {
    if (err.response?.status === 401) {
        console.error('Authentication failed');
    } else {
        console.error(err.message);
    }
});
```

---

## Token Expiration Handling

### Default Behavior

In v2.5:
- **Expiration**: Tokens do NOT expire during the session
- **Lifetime**: Valid for entire Godot runtime
- **Invalidation**: Token is invalidated when Godot stops

### Checking Token Status

**Via API**:
```bash
TOKEN="$GODOT_API_TOKEN"

# Try to use token
curl -H "Authorization: Bearer $TOKEN" \
     http://127.0.0.1:8080/status

# If 401: Token invalid or expired
# If 200: Token valid
```

**Python**:
```python
def is_token_valid(token):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        "http://127.0.0.1:8080/status",
        headers=headers
    )
    return response.status_code != 401
```

### Handling Expired Tokens

**If 401 Unauthorized is received**:

```python
import os
import requests
import subprocess

def request_with_auto_refresh(endpoint, json_data=None):
    token = os.getenv("GODOT_API_TOKEN")
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.post(
        f"http://127.0.0.1:8080{endpoint}",
        headers=headers,
        json=json_data
    )

    if response.status_code == 401:
        print("Token expired. Godot needs to be restarted.")
        print("Please:")
        print("1. Restart Godot: godot --path 'C:/godot' --dap-port 6006 --lsp-port 6005")
        print("2. Copy new token from console")
        print("3. Update GODOT_API_TOKEN environment variable")
        print("4. Retry your request")
        return None

    return response.json()
```

### Future Version Handling (v3.0+)

Planned for v3.0:
- Configurable token expiration per token
- Refresh tokens for long-lived sessions
- Token rotation API
- Multiple concurrent tokens

**Preparation**:

```python
def get_token_with_fallback():
    """Get valid token, handling potential rotation"""
    # Check multiple possible token locations
    token = (
        os.getenv("GODOT_API_TOKEN") or
        os.getenv("GODOT_SESSION_TOKEN") or
        read_token_from_file(".godot_token")
    )

    if not token:
        raise Exception("No valid token found")

    return token
```

---

## Security Considerations

### Critical Security Rules

**1. Never expose tokens in code**:

Bad:
```python
# NEVER do this!
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
headers = {"Authorization": f"Bearer {token}"}
```

Good:
```python
# Use environment variables
import os
token = os.getenv("GODOT_API_TOKEN")
if not token:
    raise ValueError("GODOT_API_TOKEN not set")
headers = {"Authorization": f"Bearer {token}"}
```

**2. Never commit tokens to version control**:

**.gitignore**:
```
.env
.env.local
*.token
*.secret
```

**.env.example** (safe to commit):
```
GODOT_API_TOKEN=your_token_here
```

**3. Use HTTPS in production**:

```python
# Development (HTTP)
url = "http://127.0.0.1:8080/status"

# Production (HTTPS)
url = "https://godot-api.production.com:8080/status"
```

**4. Rotate tokens regularly**:

```bash
# Daily restart for token rotation
0 0 * * * pkill -f godot && sleep 2 && godot --path "C:/godot" ...
```

**5. Restrict network access**:

GodotBridge binds to `127.0.0.1` (localhost only) by default.

For production, use a reverse proxy:

```nginx
server {
    listen 443 ssl;
    server_name godot-api.production.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Authorization $http_authorization;
        # Additional security headers...
    }
}
```

### HMAC-SHA256 Security

The token uses HMAC-SHA256 for signing:

```
Signature = HMACSHA256(header.payload, secret_key)
```

**What this prevents**:
- ✅ Token tampering - Any modification makes signature invalid
- ✅ Man-in-the-middle attacks - Attacker can't forge tokens without secret
- ✅ Token reuse across services - Each service has unique secret

**What this doesn't prevent**:
- ❌ Token interception - Use HTTPS to prevent
- ❌ Token theft - Secure token storage required
- ❌ Brute force - Use strong secrets (auto-generated)

### Bearer Token Best Practices

**1. Header Format**:
```
✅ Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
❌ Authorization: eyJhbGciOiJIUzI1NiIs...
❌ X-API-Token: eyJhbGciOiJIUzI1NiIs...
```

**2. Token Storage**:
```
✅ Environment variables
✅ Secure vaults (HashiCorp Vault, AWS Secrets Manager)
✅ Encrypted config files
❌ Plain text files
❌ Source code
❌ Browser cookies (for web clients)
```

**3. Token Transmission**:
```
✅ HTTPS (encrypted in transit)
✅ TLS 1.2+ (minimum)
✅ Certificate pinning (optional but recommended)
❌ HTTP (unencrypted)
❌ Query parameters (logged in server logs)
```

**4. Error Handling**:
```
✅ Log authentication failures securely
✅ Don't expose token in error messages
✅ Use generic error messages to clients
❌ Print tokens in logs
❌ Echo token in error responses
❌ Store tokens in plain text logs
```

### Audit Trail

All authentication events are logged:

```gdscript
# In telemetry_server.gd
signal auth_failed(peer_id: int, reason: String)

# Emitted on authentication failure
emit_signal("auth_failed", peer_id, "Invalid token")

# Check metrics
var metrics = get_security_metrics()
print("Auth failures: ", metrics["auth_failures"])
print("Auth timeouts: ", metrics["auth_timeouts"])
```

---

## Migration from Legacy Tokens

### v2.0 → v2.5 Migration

**v2.0 Behavior**:
- No authentication required
- Any request worked without headers

```bash
# v2.0: No token needed
curl http://127.0.0.1:8080/status
# Response: 200 OK
```

**v2.5 Behavior**:
- Bearer token required
- All requests must include auth header

```bash
# v2.5: Token required
curl http://127.0.0.1:8080/status
# Response: 401 Unauthorized

# With token:
curl -H "Authorization: Bearer $TOKEN" \
     http://127.0.0.1:8080/status
# Response: 200 OK
```

### Migration Steps

**Step 1: Get Token**
```bash
# Start Godot
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Copy token from console
# Look for: "API Token Generated: eyJhbGc..."
```

**Step 2: Update Client Code**

**Before (v2.0)**:
```python
import requests

response = requests.get("http://127.0.0.1:8080/status")
print(response.json())
```

**After (v2.5)**:
```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}

response = requests.get(
    "http://127.0.0.1:8080/status",
    headers=headers
)
print(response.json())
```

**Step 3: Test All Endpoints**

```bash
#!/bin/bash
TOKEN="$GODOT_API_TOKEN"

# Test each endpoint
curl -H "Authorization: Bearer $TOKEN" \
     http://127.0.0.1:8080/status

curl -H "Authorization: Bearer $TOKEN" \
     -X POST http://127.0.0.1:8080/connect

curl -H "Authorization: Bearer $TOKEN" \
     http://127.0.0.1:8080/debug/threads
```

**Step 4: Update Automation**

All scripts must include token:

```bash
# Before
python test_runner.py

# After
export GODOT_API_TOKEN="eyJhbGciOiJIUzI1NiIs..."
python test_runner.py
```

---

## Troubleshooting Guide

### Issue 1: 401 Unauthorized - Missing Token

**Symptom**:
```json
{
  "error": "Unauthorized",
  "message": "Authentication required",
  "status_code": 401
}
```

**Causes**:
- Authorization header missing
- Token not provided
- Token in wrong format

**Solution**:
```bash
# 1. Verify token is set
echo $GODOT_API_TOKEN

# 2. If empty, get token from Godot console
# Start Godot and copy token from startup message

# 3. Export token
export GODOT_API_TOKEN="<token_from_console>"

# 4. Verify header format
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8080/status
```

### Issue 2: 401 Unauthorized - Invalid Token

**Symptom**:
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token",
  "status_code": 401
}
```

**Causes**:
- Token from different Godot session
- Token corrupted
- Token secret changed
- Malformed JWT

**Solution**:
```bash
# 1. Restart Godot
pkill -f godot
sleep 2
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# 2. Get fresh token from console

# 3. Update environment
export GODOT_API_TOKEN="<new_token>"

# 4. Test
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8080/status
```

### Issue 3: Token Not Appearing in Console

**Symptom**:
- Godot starts but no "API Token Generated" message

**Causes**:
- Plugin not enabled
- Console output redirected
- Initialization error

**Solution**:
```bash
# 1. Check plugin is enabled
# Project Settings > Plugins > godot_debug_connection

# 2. Run with verbose output
godot --path "C:/godot" \
      --dap-port 6006 --lsp-port 6005 \
      --verbose 2>&1 | grep -i "token\|auth\|bridge"

# 3. Check for errors during startup
# Look for: "ERROR", "ERROR:", "Failed"

# 4. Verify GodotBridge is autoload
# Project Settings > Autoload > GodotBridge (should be checked)
```

### Issue 4: Connection Refused

**Symptom**:
```
curl: (7) Failed to connect to 127.0.0.1 port 8080: Connection refused
```

**Causes**:
- Godot not running
- GodotBridge not initialized
- Port 8080 blocked

**Solution**:
```bash
# 1. Verify Godot is running
ps aux | grep godot

# 2. Check port is listening
netstat -an | grep 8080

# 3. Verify correct host
# Must use 127.0.0.1 (localhost), not 0.0.0.0

# 4. Try fallback ports
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8083/status  # Try 8083

# 5. Check firewall
# Port 8080-8085 should be open locally
```

### Issue 5: Malformed Token

**Symptom**:
```json
{
  "error": "Unauthorized",
  "message": "Malformed JWT",
  "status_code": 401
}
```

**Causes**:
- Token incomplete (missing parts)
- Token copied incorrectly
- Token trimmed or truncated
- Token with extra spaces

**Solution**:
```bash
# 1. Check token is complete
echo -n "$GODOT_API_TOKEN" | wc -c
# Should be 200+ characters

# 2. Verify token has 3 parts
echo "$GODOT_API_TOKEN" | grep -o '\.' | wc -l
# Should output "2"

# 3. Copy fresh token from console
# Be careful not to include quotes or spaces

# 4. Test in Python
python3 -c "
token = '''$GODOT_API_TOKEN'''
parts = token.split('.')
if len(parts) == 3:
    print('Token format: Valid')
else:
    print(f'Token format: Invalid ({len(parts)} parts instead of 3)')
"
```

### Issue 6: Token Works Locally but Not from Scripts

**Symptom**:
- `curl` works but Python/Node.js fails
- Manual requests succeed, automated fail

**Causes**:
- Environment variable not set in script context
- Different shell environment
- Token not exported globally

**Solution**:
```bash
# 1. Ensure token is exported
export GODOT_API_TOKEN="<token>"

# 2. Verify in script context
python3 -c "import os; print(os.getenv('GODOT_API_TOKEN'))"

# 3. Source .env file if using separate config
source .env
python3 -c "import os; print(os.getenv('GODOT_API_TOKEN'))"

# 4. Pass token explicitly to script
python3 script.py --token "$GODOT_API_TOKEN"
```

---

## API Examples

### Complete Request Examples

**Example 1: Get Server Status**

```bash
#!/bin/bash
TOKEN="${GODOT_API_TOKEN}"

# Basic health check
curl -X GET "http://127.0.0.1:8080/status" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json"

# Output:
# {
#   "debug_adapter": {
#     "service_name": "Debug Adapter",
#     "port": 6006,
#     "state": 2,
#     "overall_ready": true
#   },
#   "language_server": {
#     "service_name": "Language Server",
#     "port": 6005,
#     "state": 2,
#     "overall_ready": true
#   }
# }
```

**Example 2: Set Breakpoint**

```python
import requests
import os

token = os.getenv("GODOT_API_TOKEN")
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

response = requests.post(
    "http://127.0.0.1:8080/debug/setBreakpoints",
    headers=headers,
    json={
        "source": {"path": "res://scripts/player.gd"},
        "breakpoints": [
            {"line": 10},
            {"line": 25},
            {"line": 50}
        ]
    }
)

if response.status_code == 200:
    print("Breakpoints set successfully")
    print(response.json())
elif response.status_code == 401:
    print("Authentication failed")
else:
    print(f"Error: {response.status_code}")
    print(response.json())
```

**Example 3: Code Completion Request**

```bash
#!/bin/bash

TOKEN="$GODOT_API_TOKEN"
API="http://127.0.0.1:8080"

# Request code completions
curl -X POST "$API/lsp/completion" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "textDocument": {
            "uri": "file:///home/user/project/res/scripts/player.gd"
        },
        "position": {
            "line": 10,
            "character": 5
        }
    }' | jq .
```

**Example 4: Batch Operations**

```python
#!/usr/bin/env python3
import requests
import os
import json

class GodotAPIClient:
    def __init__(self):
        self.token = os.getenv("GODOT_API_TOKEN")
        if not self.token:
            raise ValueError("GODOT_API_TOKEN not set")

        self.base_url = "http://127.0.0.1:8080"
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def request(self, method, endpoint, data=None):
        url = f"{self.base_url}{endpoint}"

        if method.upper() == "GET":
            response = requests.get(url, headers=self.headers)
        elif method.upper() == "POST":
            response = requests.post(url, headers=self.headers, json=data)
        else:
            raise ValueError(f"Unknown method: {method}")

        if response.status_code == 401:
            raise Exception("Authentication failed - check token")

        return response.json()

    def get_status(self):
        return self.request("GET", "/status")

    def set_breakpoints(self, file_path, line_numbers):
        return self.request("POST", "/debug/setBreakpoints", {
            "source": {"path": file_path},
            "breakpoints": [{"line": n} for n in line_numbers]
        })

    def continue_execution(self, thread_id=1):
        return self.request("POST", "/debug/continue", {
            "threadId": thread_id
        })

# Usage
client = GodotAPIClient()

# Check status
print("Status:", client.get_status())

# Set breakpoints
print("Setting breakpoints...")
client.set_breakpoints("res://scripts/player.gd", [10, 25, 50])

# Continue execution
print("Continuing execution...")
client.continue_execution()
```

---

## Best Practices

### 1. Token Management

**DO:**
- Store tokens in environment variables
- Rotate tokens regularly (restart Godot)
- Use `.env` files for development
- Keep tokens in secure vaults for production

**DON'T:**
- Hardcode tokens in source files
- Commit tokens to version control
- Send tokens in URL parameters
- Log tokens in output

### 2. Error Handling

**DO:**
```python
def make_api_request(endpoint, data=None):
    token = os.getenv("GODOT_API_TOKEN")
    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.post(
            f"http://127.0.0.1:8080{endpoint}",
            headers=headers,
            json=data,
            timeout=10
        )

        if response.status_code == 401:
            print("Authentication failed. Restart Godot and update token.")
            return None

        if response.status_code != 200:
            print(f"API Error {response.status_code}: {response.text}")
            return None

        return response.json()

    except requests.exceptions.ConnectionError:
        print("Cannot connect to Godot API.")
        return None
    except requests.exceptions.Timeout:
        print("Request timed out.")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None
```

**DON'T:**
```python
# No error handling
response = requests.get("http://127.0.0.1:8080/status")
print(response.json())
```

### 3. CI/CD Integration

**GitHub Actions**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      GODOT_API_TOKEN: ${{ secrets.GODOT_API_TOKEN }}
    steps:
      - uses: actions/checkout@v3
      - name: Run API tests
        run: python tests/test_api.py
```

**GitLab CI**:
```yaml
api_tests:
  image: python:3.9
  variables:
    GODOT_API_TOKEN: $GODOT_API_TOKEN
  script:
    - pip install -r requirements.txt
    - python tests/test_api.py
```

### 4. Documentation

**In Your README**:
```markdown
## API Authentication

This project uses JWT tokens for API authentication.

### Getting a Token

1. Start Godot:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. Copy the token from console output

3. Export as environment variable:
   ```bash
   export GODOT_API_TOKEN="<token_from_console>"
   ```

### Using the API

All requests must include the Authorization header:
```bash
curl -H "Authorization: Bearer $GODOT_API_TOKEN" \
     http://127.0.0.1:8080/status
```
```

---

## Summary

This documentation covers the complete JWT authentication system for SpaceTime's HTTP API. Key points:

1. **Tokens are automatically generated** when GodotBridge starts
2. **Include token in Authorization header** for all requests
3. **Tokens are valid for entire Godot session** (no time-based expiration)
4. **Always use environment variables** for token storage
5. **Restart Godot to get new token** (old token is invalidated)
6. **Use HTTPS in production** for token protection
7. **Follow security best practices** for token management

For detailed API reference, see:
- `/addons/godot_debug_connection/HTTP_API.md` - All endpoints
- `/addons/godot_debug_connection/EXAMPLES.md` - Usage examples
- `/addons/godot_debug_connection/MIGRATION_V2.0_TO_V2.5.md` - Upgrade guide
