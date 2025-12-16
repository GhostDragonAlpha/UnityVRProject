# JWT Authentication Quick Start

## Get Your Token (3 Steps)

1. **Start Godot with debug services:**
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. **Look for in Godot console:**
   ```
   [Security] API token generated: a1b2c3d4e5f6...
   ```

3. **Copy the 64-character hex token**

## Run the Examples (1 Step)

```bash
# Set token as environment variable
export GODOT_API_TOKEN=a1b2c3d4e5f6...

# Run examples
cd examples
python jwt_authentication_example.py
```

## Use in Your Code (5 Lines)

```python
from jwt_authentication_example import AuthenticatedAPIClient, TokenExtractor

# Get token from environment/file
token = TokenExtractor.get_token()

# Create authenticated client
client = AuthenticatedAPIClient(token=token)

# Make API request
status = client.get_status()
```

## Token Locations (Automatic Search)

The script searches in this order:

1. `GODOT_API_TOKEN` environment variable
2. `api_token.txt` (current directory)
3. `~/.godot/api_token.txt` (home directory)
4. `~/.godot/config.json` (config file)

**Create token file:**

```bash
echo "a1b2c3d4e5f6..." > api_token.txt
```

## What You Get

- `TokenExtractor` - Finds your token automatically
- `AuthenticatedAPIClient` - Makes authenticated API calls
- `TokenRefreshManager` - Manages token lifecycle
- 6 working examples showing all authentication patterns

## API Examples

```python
# Get server status
status = client.get_status()

# Connect to debug services
client.connect()

# Make authenticated request (manual)
response = client.request("POST", "/endpoint", json_data={})

# Update token if it changes
client.set_token("new_token_here")

# Refresh or rotate token
manager = TokenRefreshManager(client)
manager.refresh_token()
manager.rotate_token()
```

## Error Handling

```python
try:
    status = client.get_status()
    if status is None:
        print("Token may be expired - restart Godot")
except requests.ConnectionError:
    print("Godot not running on http://127.0.0.1:8080")
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "No token found" | Copy token from Godot logs and set GODOT_API_TOKEN |
| "401 Unauthorized" | Token is invalid - restart Godot for new token |
| "Connection refused" | Godot not running - start with debug flags |
| "Invalid format" | Token must be 64 hex characters (0-9, a-f) |

## Files

- `jwt_authentication_example.py` - Main implementation (745 lines)
- `JWT_AUTHENTICATION_GUIDE.md` - Detailed guide
- `JWT_QUICK_START.md` - This file

## Documentation

For detailed information, see:
- `JWT_AUTHENTICATION_GUIDE.md` - Complete setup guide
- `jwt_authentication_example.py` - Source code with comments
- `PYTHON_CLIENT_AUTH_IMPLEMENTATION.md` - Implementation details

## API Endpoints (All Require Bearer Token)

```
GET  /status                    - Connection status
POST /connect                   - Connect to services
POST /disconnect                - Disconnect
POST /debug/*                   - Debug commands
POST /lsp/*                     - Language server
POST /edit/*                    - File editing
POST /execute/*                 - Code execution
POST /auth/*                    - Token management
```

## Security Tips

- Never commit `api_token.txt` to git
- Use `.gitignore` for token files
- Use environment variables in production
- Tokens are session-specific (new token on restart)
- File permissions: `chmod 600 api_token.txt`

## Next Steps

1. Get your token from Godot
2. Set environment variable or create file
3. Run `python jwt_authentication_example.py`
4. Copy example code to your project
5. Read `JWT_AUTHENTICATION_GUIDE.md` for details

Good luck!
