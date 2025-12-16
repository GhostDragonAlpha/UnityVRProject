# JWT Authentication Guide for Godot HTTP API

This guide explains how to use JWT/Bearer tokens to authenticate with the Godot HTTP API using the `jwt_authentication_example.py` script.

## Overview

The Godot HTTP API server generates a unique 64-character hexadecimal token on startup. This token must be included in all API requests via the `Authorization: Bearer <token>` header.

## Token Generation

When Godot starts with the debug connection addon enabled, the server logs:

```
[Security] API token generated: a1b2c3d4e5f6...
[Security] Include in requests: Authorization: Bearer a1b2c3d4e5f6...
```

The token is:
- 64 hexadecimal characters (0-9, a-f)
- Session-specific (new token generated on Godot restart)
- Required for all API requests

## Getting Your Token

### Option 1: From Godot Startup Logs

1. Start Godot with debug services:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. Look for console output containing:
   ```
   [Security] API token generated: <64-character-hex-string>
   ```

3. Copy the token

### Option 2: Set Environment Variable

```bash
# Linux/Mac
export GODOT_API_TOKEN=a1b2c3d4e5f6...

# Windows (Command Prompt)
set GODOT_API_TOKEN=a1b2c3d4e5f6...

# Windows (PowerShell)
$env:GODOT_API_TOKEN="a1b2c3d4e5f6..."
```

### Option 3: Create Token File

Create `api_token.txt` in the examples directory:

```bash
echo "a1b2c3d4e5f6..." > api_token.txt
```

Or in home directory:

```bash
mkdir -p ~/.godot
echo "a1b2c3d4e5f6..." > ~/.godot/api_token.txt
```

### Option 4: Create Config File

Create `~/.godot/config.json`:

```json
{
  "api_token": "a1b2c3d4e5f6..."
}
```

## Using the JWT Example Script

### Running the Examples

```bash
cd examples
python jwt_authentication_example.py
```

This will run 6 demonstrations:

1. **Basic Authentication** - Making authenticated API requests
2. **Error Handling** - Handling 401 Unauthorized responses
3. **Token Refresh** - Refreshing token to extend expiration
4. **Token Rotation** - Rotating to a new token
5. **Save and Reuse** - Storing and reusing tokens
6. **Log Extraction** - Extracting tokens from Godot logs

### Token Priority

The script searches for tokens in this order:

1. Environment variable: `GODOT_API_TOKEN`
2. Current directory: `api_token.txt`
3. Home directory: `~/.godot/api_token.txt`
4. Config file: `~/.godot/config.json`

## Using in Your Code

### Basic Authenticated Request

```python
from jwt_authentication_example import AuthenticatedAPIClient, TokenExtractor

# Get token (searches all sources)
token = TokenExtractor.get_token()

# Create client
client = AuthenticatedAPIClient(token=token)

# Make authenticated request
status = client.get_status()
print(f"Server ready: {status['overall_ready']}")
```

### With Custom Token

```python
client = AuthenticatedAPIClient(token="a1b2c3d4e5f6...")
```

### Setting New Token

```python
# Update token if it expires and you get a new one
client.set_token("new_token_here")
```

## Error Handling

### 401 Unauthorized

If you get a 401 error:

1. **Token is invalid or expired** - Restart Godot to generate new token
2. **Token is malformed** - Must be exactly 64 hex characters
3. **Token doesn't match** - Ensure you're using current token from Godot

```python
try:
    response = client.get_status()
    if response.status_code == 401:
        print("Token is invalid - get new token from Godot")
        print("Restart Godot and check logs for: [Security] API token generated")
except requests.ConnectionError:
    print("Cannot connect to Godot API")
```

### Token Validation

Check if a token is valid format:

```python
token = "a1b2c3d4e5f6..."
is_valid = (
    len(token) == 64 and
    all(c in '0123456789abcdef' for c in token)
)
```

## Token Refresh Workflow

### Manual Refresh

```python
from jwt_authentication_example import TokenRefreshManager

manager = TokenRefreshManager(client)

# Refresh to extend expiration
result = manager.refresh_token(extension_hours=48.0)

if result:
    print(f"Token refreshed. New expiration: {result['expires_at']}")
```

### Token Rotation

```python
# Rotate to new token
result = manager.rotate_token()

if result:
    new_token = result['new_token']
    grace_period = result['grace_period_seconds']

    print(f"New token: {new_token[:16]}...")
    print(f"Grace period: {grace_period}s")

    # Old token still works during grace period
    # Then use new token
    client.set_token(new_token)
```

## Secure Token Storage

### File Permissions

For `api_token.txt`, set restricted permissions:

**Linux/Mac:**
```bash
chmod 600 api_token.txt        # User read/write only
chmod 600 ~/.godot/api_token.txt
```

**Windows:**
```cmd
icacls api_token.txt /grant:r %username%:F /inheritance:r
```

### Never Commit Tokens

Add to `.gitignore`:

```
api_token.txt
.godot/api_token.txt
.env
```

### Environment Variable

Use environment variables in production:

```bash
# CI/CD systems
export GODOT_API_TOKEN="${SECRET_GODOT_TOKEN}"

# Docker
docker run -e GODOT_API_TOKEN="$TOKEN" ...

# Kubernetes
kubectl set env deployment/app GODOT_API_TOKEN="$TOKEN"
```

## Bearer Token Format

All API requests must include the Authorization header:

```
GET /status HTTP/1.1
Authorization: Bearer a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b
Content-Type: application/json
```

In Python with requests:

```python
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}
response = requests.get("http://127.0.0.1:8080/status", headers=headers)
```

## Extracting Token from Logs

Use the `TokenExtractor` class to extract tokens from various sources:

```python
from jwt_authentication_example import TokenExtractor

# From environment
token = TokenExtractor.extract_from_environment()

# From file
token = TokenExtractor.extract_from_token_file("api_token.txt")

# From config
token = TokenExtractor.extract_from_config("~/.godot/config.json")

# From Godot log file
token = TokenExtractor.extract_from_startup_logs("godot_output.log")

# From all sources (priority order)
token = TokenExtractor.get_token()
```

## Troubleshooting

### "No token available"

1. Start Godot and wait for startup logs
2. Copy token from `[Security] API token generated:` line
3. Set as environment variable: `export GODOT_API_TOKEN=<token>`
4. Or create `api_token.txt` file

### "401 Unauthorized"

1. Verify token is 64 hex characters
2. Check token is from current Godot session (restarted?)
3. Ensure header format: `Authorization: Bearer <token>` (with space)
4. Check for trailing whitespace in token file

### "Connection refused"

1. Ensure Godot is running
2. Verify debug services are enabled
3. Check HTTP API port (default 8080)
4. Look for fallback ports 8083-8085 if 8080 is in use

### "Invalid token format"

1. Token must be exactly 64 characters
2. Token must be hexadecimal (0-9, a-f only)
3. No spaces or newlines
4. Check file encoding (UTF-8)

## Complete Example

```python
#!/usr/bin/env python3
from jwt_authentication_example import (
    AuthenticatedAPIClient,
    TokenExtractor,
    TokenRefreshManager
)

def main():
    # Step 1: Get token
    print("Getting token...")
    token = TokenExtractor.get_token()

    if not token:
        print("Error: No token available")
        print("Set GODOT_API_TOKEN or create api_token.txt")
        return 1

    # Step 2: Create client
    print(f"Creating client with token: {token[:16]}...")
    client = AuthenticatedAPIClient(token=token)

    # Step 3: Make authenticated requests
    print("Getting server status...")
    status = client.get_status()

    if status:
        print(f"Server ready: {status['overall_ready']}")
        print(f"Debug adapter: {status['debug_adapter']['state']}")
        print(f"Language server: {status['language_server']['state']}")
    else:
        print("Error: Could not get status")
        return 1

    # Step 4: Handle token refresh if needed
    manager = TokenRefreshManager(client)

    # Try to refresh token
    refresh_result = manager.refresh_token()
    if refresh_result:
        print(f"Token refreshed successfully")

    return 0

if __name__ == "__main__":
    exit(main())
```

## API Endpoints Requiring Authentication

All endpoints require Bearer token authentication:

- `GET /status` - Connection status
- `POST /connect` - Connect to services
- `POST /disconnect` - Disconnect from services
- `POST /debug/*` - Debug commands
- `POST /lsp/*` - Language server commands
- `POST /edit/*` - File editing
- `POST /execute/*` - Code execution

## See Also

- `jwt_authentication_example.py` - Complete working examples
- `PYTHON_CLIENT_AUTH_IMPLEMENTATION.md` - Detailed implementation guide
- `HTTP_API.md` - HTTP API endpoint reference
- `token_management_example.py` - Token management features

## Support

For issues with authentication:

1. Check that Godot is running with debug services enabled
2. Verify token from Godot console logs
3. Ensure token is 64 hex characters
4. Check Bearer header format is correct
5. Try restarting Godot to get fresh token
