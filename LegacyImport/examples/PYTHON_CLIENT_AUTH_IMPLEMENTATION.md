# Python Client Authentication Implementation

This document contains the complete implementation for authentication-enabled Python clients.

## Overview

All Python clients now support Bearer token authentication via:
1. `GODOT_API_TOKEN` environment variable
2. `api_token.txt` file (local or ~/.godot/)
3. JSON config file (~/.godot/config.json)

## Token Format

The Godot HTTP API server generates 64-character hexadecimal tokens on startup.
Example: `a1b2c3d4e5f6...` (64 chars)

Look for this in the Godot console:
```
[Security] API token generated: <your-token-here>
[Security] Include in requests: Authorization: Bearer <token>
```

## File Status

### Completed
- **scene_client_config.py** (224 lines) - Configuration management

### To Update
- **scene_loader_client.py** (185 lines → ~260 lines)
- **demo_complete_workflow.py** (215 lines → ~240 lines) 
- **secure_scene_client.py** (NEW → ~280 lines)

## Implementation Guide

### 1. Updating scene_loader_client.py

Add these changes to the existing file:

```python
# Add to imports
import os

# Update class __init__
class SceneLoaderClient:
    def __init__(self, host: str = "127.0.0.1", port: int = 8080, token: Optional[str] = None):
        self.base_url = f"http://{host}:{port}"
        self.token = token or self._get_token()
        self.session = requests.Session()
        if self.token:
            self.session.headers.update({
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            })

    def _get_token(self) -> Optional[str]:
        """Auto-detect API token"""
        token = os.getenv("GODOT_API_TOKEN")
        if token:
            return token
        
        token_file = os.path.join(os.path.dirname(__file__), "api_token.txt")
        if os.path.exists(token_file):
            with open(token_file, "r") as f:
                return f.read().strip()
        
        print("[Auth] Warning: No API token found")
        return None

    def _handle_auth_error(self, response):
        """Handle 401 errors"""
        if response.status_code == 401:
            print("[Auth Error] 401 Unauthorized")
            print("[Auth Error] Set GODOT_API_TOKEN or create api_token.txt")
            return True
        return False
```

Then update all methods to use `self.session` instead of `requests` directly.

### 2. Updating demo_complete_workflow.py

Change the import and instantiation:

```python
from scene_loader_client import SceneLoaderClient

# In main()
print("[Setup] Initializing authenticated client...")
client = SceneLoaderClient()

# Add token check at start
if not client.token:
    print("[WARNING] No authentication token configured")
    print("Server may reject requests. Get token from Godot console.")
```

### 3. Creating secure_scene_client.py (Async)

Full async implementation with aiohttp:

```python
#!/usr/bin/env python3
import asyncio
import aiohttp
from scene_client_config import ClientConfig

class SecureSceneClient:
    def __init__(self, base_url="http://127.0.0.1:8080"):
        self.config = ClientConfig()
        self.base_url = base_url
        self.session = None
    
    async def __aenter__(self):
        connector = aiohttp.TCPConnector(limit=10)
        self.session = aiohttp.ClientSession(
            connector=connector,
            headers=self.config.get_auth_headers()
        )
        return self
    
    async def __aexit__(self, *args):
        await self.session.close()
    
    async def get_scene(self):
        async with self.session.get(f"{self.base_url}/scene") as resp:
            resp.raise_for_status()
            return await resp.json()

# Usage
async def main():
    async with SecureSceneClient() as client:
        scene = await client.get_scene()
        print(f"Current: {scene['scene_name']}")

if __name__ == "__main__":
    asyncio.run(main())
```

## Quick Start

### Setup Token

**Option 1: Environment Variable**
```bash
# Linux/Mac
export GODOT_API_TOKEN=<your-64-char-token>

# Windows
set GODOT_API_TOKEN=<your-64-char-token>
```

**Option 2: Token File**
```bash
# In examples/ directory
echo "<your-token>" > api_token.txt

# Or in home directory
mkdir -p ~/.godot
echo "<your-token>" > ~/.godot/api_token.txt
```

**Option 3: Using scene_client_config.py**
```bash
python scene_client_config.py save-token
# Enter token when prompted
```

### Test Connection

```bash
python scene_client_config.py test-token
```

### Use Updated Client

```bash
# Set token first
export GODOT_API_TOKEN=<token>

# Run client
python scene_loader_client.py status
python scene_loader_client.py list
python scene_loader_client.py load "res://vr_main.tscn"
```

## Error Handling

### 401 Unauthorized
- Check token is correct (64 hex characters)
- Verify token matches server's generated token
- Ensure token hasn't expired (restart Godot generates new token)

### Token Not Found
- Check environment variable is set
- Verify api_token.txt exists and contains valid token
- Use `scene_client_config.py show` to check configuration

## Dependencies

### Standard Clients (scene_loader_client.py, demo_complete_workflow.py)
```bash
pip install requests
```

### Async Client (secure_scene_client.py)
```bash
pip install aiohttp
```

## Security Notes

1. **Never commit api_token.txt to git**
   - Add to .gitignore
   - Tokens are session-specific

2. **Localhost Only**
   - Server binds to 127.0.0.1 by default
   - Not accessible from network

3. **Token Rotation**
   - New token generated on each Godot restart
   - Update clients when restarting server

4. **File Permissions**
   - Keep token files readable only by user
   - chmod 600 api_token.txt (Linux/Mac)

## Configuration Priority

Token sources checked in order:
1. Explicit `token` parameter to constructor
2. `GODOT_API_TOKEN` environment variable  
3. `./api_token.txt` (current directory)
4. `~/.godot/api_token.txt` (user home)
5. `~/.godot/config.json` (`api_token` field)

## Example Workflows

### Development Workflow
```bash
# 1. Start Godot with HTTP API
godot --headless &

# 2. Copy token from console
# [Security] API token generated: abc123...

# 3. Save token
export GODOT_API_TOKEN=abc123...

# 4. Run clients
python scene_loader_client.py list
python demo_complete_workflow.py
```

### CI/CD Workflow
```bash
# In CI environment
echo "$GODOT_API_TOKEN_SECRET" > api_token.txt
python scene_loader_client.py status
```

### Multi-Project Setup
```bash
# Global config
mkdir -p ~/.godot
echo "abc123..." > ~/.godot/api_token.txt

# All projects use same token
cd project1 && python scene_loader_client.py status
cd project2 && python scene_loader_client.py status
```

## Troubleshooting

### ImportError: No module named 'requests'
```bash
pip install requests
```

### ImportError: No module named 'aiohttp'
```bash
pip install aiohttp
```

### Connection Refused
- Ensure Godot HTTP server is running
- Check port 8080 is not blocked
- Verify base_url is correct

### Invalid Token Format
- Token must be exactly 64 hexadecimal characters
- No spaces or newlines
- Check token file encoding (UTF-8)

## API Reference

See also:
- `HTTP_API_USAGE_GUIDE.md` - Complete API documentation
- `scene_client_config.py --help` - Configuration tool
- `secure_scene_client.py` - Async implementation example

