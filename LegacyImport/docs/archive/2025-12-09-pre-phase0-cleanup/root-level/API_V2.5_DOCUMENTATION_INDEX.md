# API v2.5 Documentation Index

**SpaceTime HTTP API - Security-Hardened Edition**

**Version**: v2.5

**Release Date**: December 2, 2025

**Security Status**: Production-Ready

---

## What's New in v2.5

The HTTP Scene Management API has been significantly enhanced with production-grade security features:

- **Token-Based Authentication**: All endpoints require Bearer token authentication
- **Scene Whitelist**: Restricted scene loading to approved paths only
- **Request Size Limits**: Protection against large payload attacks (1MB max)
- **Localhost Binding**: Server only accepts connections from 127.0.0.1
- **Comprehensive Error Handling**: Clear 401, 403, and 413 responses

**Migration Required**: All clients must be updated to include authentication headers.

---

## Quick Start Guides

### For New Users

**Start Here**: [QUICK_START.md](QUICK_START.md)
- 5-minute setup guide
- Get your API token
- Make your first authenticated API call
- Monitor telemetry
- Run in VR

**Time to Complete**: 5-10 minutes

### For Security-Focused Users

**Start Here**: [QUICK_START_V2.5_SECURITY.md](QUICK_START_V2.5_SECURITY.md)
- Security-first approach
- Token acquisition and management
- Authentication testing
- Scene whitelist understanding
- Python client with security
- Security best practices

**Time to Complete**: 10-15 minutes

---

## Core Documentation

### API Token Management

**File**: [API_TOKEN_GUIDE.md](API_TOKEN_GUIDE.md)

**Comprehensive guide covering**:
- How to get your token (4 methods)
- Token storage methods (environment, .env files, config files, keyring)
- Using tokens in requests (curl, Python, JavaScript, C#)
- Token security best practices
- Token lifecycle (generation, validation, rotation)
- Scene whitelist management
- Multi-user scenarios (future)
- Troubleshooting

**When to Use**:
- Setting up authentication for the first time
- Implementing token management in your application
- Troubleshooting authentication issues
- Understanding security best practices

### HTTP API Usage

**File**: [docs/current/api/HTTP_API_USAGE_GUIDE.md](docs/current/api/HTTP_API_USAGE_GUIDE.md)

**Complete API reference with**:
- Authentication section
- All endpoints with auth examples
- Python client library (with auth)
- Common use cases (all updated for auth)
- Troubleshooting (auth-specific issues)
- Security features summary

**When to Use**:
- Complete API reference
- Learning all available endpoints
- Implementing Python clients
- CI/CD pipeline integration
- Advanced use cases

---

## Technical Documentation

### Security Implementation

**File**: [HTTP_API_SECURITY_HARDENING_COMPLETE.md](HTTP_API_SECURITY_HARDENING_COMPLETE.md)

**Technical deep-dive on**:
- Security implementation details
- Files modified and security features added
- API usage examples with authentication
- Python client examples
- Testing the security
- Configuration options

**When to Use**:
- Understanding the security implementation
- Contributing to the codebase
- Extending security features
- Security auditing

---

## Common Tasks

### Task: Get Started with the API

1. **Read**: [QUICK_START.md](QUICK_START.md)
2. **Get Token**: Start Godot and copy token from console
3. **Set Token**: `export API_TOKEN="your_token"`
4. **Test**: `curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene`

**Time**: 5 minutes

### Task: Implement Python Client

1. **Read**: [docs/current/api/HTTP_API_USAGE_GUIDE.md#python-client-library](docs/current/api/HTTP_API_USAGE_GUIDE.md#python-client-library)
2. **Copy**: `SecureSceneLoaderClient` class from guide
3. **Set Token**: `export API_TOKEN="your_token"`
4. **Run**: `python your_client.py`

**Time**: 10 minutes

### Task: Add Scene to Whitelist

1. **Read**: [API_TOKEN_GUIDE.md#scene-whitelist-management](API_TOKEN_GUIDE.md#scene-whitelist-management)
2. **In Godot Console**: `HttpApiSecurityConfig.add_to_whitelist("res://my_scene.tscn")`
3. **Test**: Load scene via API

**Time**: 2 minutes

### Task: Troubleshoot Authentication

1. **Read**: [API_TOKEN_GUIDE.md#troubleshooting](API_TOKEN_GUIDE.md#troubleshooting)
2. **Check Token**: `echo $API_TOKEN`
3. **Get Fresh Token**: Look for `[Security] API token generated:` in Godot console
4. **Update**: `export API_TOKEN="new_token"`

**Time**: 5 minutes

### Task: Set Up CI/CD Pipeline

1. **Read**: [docs/current/api/HTTP_API_USAGE_GUIDE.md#4-cicd-pipeline---automated-scene-validation](docs/current/api/HTTP_API_USAGE_GUIDE.md#4-cicd-pipeline---automated-scene-validation)
2. **Copy**: Bash script from guide
3. **Set Token**: `export API_TOKEN="your_token"`
4. **Run**: `./validate_scenes.sh`

**Time**: 15 minutes

---

## Authentication Quick Reference

### Get Token

```bash
# Start Godot
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Look for this in console:
# [Security] API token generated: a1b2c3d4e5f6...
```

### Set Token

```bash
# Linux/Mac/Git Bash
export API_TOKEN="a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"

# Windows PowerShell
$env:API_TOKEN = "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"

# Windows Command Prompt
set API_TOKEN=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### Use Token

```bash
# curl
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

# Python
import os
token = os.getenv("API_TOKEN")
headers = {"Authorization": f"Bearer {token}"}
```

---

## Error Reference

### 401 Unauthorized

**Cause**: Missing or invalid authentication token

**Solution**:
1. Check token is set: `echo $API_TOKEN`
2. Get fresh token from Godot console
3. Verify header format: `Authorization: Bearer <token>`

**Details**: [API_TOKEN_GUIDE.md#issue-missing-or-invalid-authentication-token](API_TOKEN_GUIDE.md#issue-missing-or-invalid-authentication-token)

### 403 Forbidden

**Cause**: Scene not in whitelist

**Solution**:
1. Check whitelist: `HttpApiSecurityConfig.get_whitelist()`
2. Add scene: `HttpApiSecurityConfig.add_to_whitelist("res://scene.tscn")`

**Details**: [API_TOKEN_GUIDE.md#issue-scene-not-in-whitelist](API_TOKEN_GUIDE.md#issue-scene-not-in-whitelist)

### 413 Payload Too Large

**Cause**: Request body exceeds 1MB limit

**Solution**:
1. Reduce payload size
2. Split into multiple requests

**Details**: [API_TOKEN_GUIDE.md#issue-request-size-limit-exceeded](API_TOKEN_GUIDE.md#issue-request-size-limit-exceeded)

---

## Example Workflows

### Workflow 1: Development Setup

```bash
# 1. Start Godot and capture token
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 2>&1 | tee godot.log

# 2. Extract and set token
export API_TOKEN=$(grep "API token generated:" godot.log | awk '{print $5}')

# 3. Verify token
echo $API_TOKEN

# 4. Test API
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

# 5. Load a scene
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}'
```

### Workflow 2: Python Client

```python
#!/usr/bin/env python3
import os
import requests

# Get token from environment
API_TOKEN = os.getenv("API_TOKEN")

# Set up headers
headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# Get current scene
response = requests.get("http://127.0.0.1:8080/scene", headers=headers)
print(response.json())

# Load scene
response = requests.post(
    "http://127.0.0.1:8080/scene",
    headers=headers,
    json={"scene_path": "res://vr_main.tscn"}
)
print(response.json())
```

### Workflow 3: Scene Whitelist Management

```gdscript
# In Godot console or autoload script

# View current whitelist
var whitelist = HttpApiSecurityConfig.get_whitelist()
print("Current whitelist:")
for scene in whitelist:
    print("  - ", scene)

# Add single scene
HttpApiSecurityConfig.add_to_whitelist("res://level_01.tscn")

# Add directory (all scenes in directory allowed)
HttpApiSecurityConfig.add_directory_to_whitelist("res://levels/")

# Verify
print("Updated whitelist:")
print(HttpApiSecurityConfig.get_whitelist())
```

---

## Security Checklist

Use this checklist when implementing the API:

### Development
- [ ] Token is stored in environment variable
- [ ] `.env` file is in `.gitignore`
- [ ] Token is not hardcoded in source
- [ ] Authorization header uses correct format
- [ ] Authentication errors are handled

### Testing
- [ ] Test with missing token (expect 401)
- [ ] Test with invalid token (expect 401)
- [ ] Test with valid token (expect 200)
- [ ] Test with non-whitelisted scene (expect 403)

### Production
- [ ] Whitelist is minimal (only required scenes)
- [ ] Token rotation process is documented
- [ ] Error handling is comprehensive
- [ ] Logging is enabled

---

## Migration from v2.4 to v2.5

### Breaking Changes

1. **All endpoints now require authentication** (except `/status`)
2. **Scene loading restricted to whitelist**
3. **Request size limited to 1MB**

### Migration Steps

**Step 1: Update clients to get token**

```bash
# Get token from Godot console
export API_TOKEN="token_from_console"
```

**Step 2: Add Authorization header to all requests**

```bash
# Before (v2.4)
curl http://127.0.0.1:8080/scene

# After (v2.5)
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene
```

**Step 3: Update Python clients**

```python
# Before (v2.4)
client = SceneLoaderClient()

# After (v2.5)
import os
client = SecureSceneLoaderClient(token=os.getenv("API_TOKEN"))
```

**Step 4: Add scenes to whitelist**

```gdscript
# In Godot console or autoload
HttpApiSecurityConfig.add_to_whitelist("res://your_scene.tscn")
```

**Step 5: Test thoroughly**

```bash
# Test authentication works
curl -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8080/scene

# Test scene loading works
curl -X POST http://127.0.0.1:8080/scene \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"scene_path":"res://vr_main.tscn"}'
```

---

## Additional Resources

### Project Documentation
- **[CLAUDE.md](CLAUDE.md)** - Project overview and development workflow
- **[README.md](README.md)** - Main project README
- **[DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md)** - Complete development cycle

### API Documentation
- **[addons/godot_debug_connection/HTTP_API.md](addons/godot_debug_connection/HTTP_API.md)** - GodotBridge API (DAP/LSP)
- **[addons/godot_debug_connection/API_REFERENCE.md](addons/godot_debug_connection/API_REFERENCE.md)** - Complete API reference

### Examples
- **[examples/](examples/)** - Python client examples (need auth updates)
- **[examples/README.md](examples/README.md)** - Example usage guide

---

## Getting Help

### Authentication Issues
→ [API_TOKEN_GUIDE.md#troubleshooting](API_TOKEN_GUIDE.md#troubleshooting)

### Scene Whitelist Issues
→ [API_TOKEN_GUIDE.md#scene-whitelist-management](API_TOKEN_GUIDE.md#scene-whitelist-management)

### General API Issues
→ [docs/current/api/HTTP_API_USAGE_GUIDE.md#troubleshooting](docs/current/api/HTTP_API_USAGE_GUIDE.md#troubleshooting)

### Security Questions
→ [QUICK_START_V2.5_SECURITY.md](QUICK_START_V2.5_SECURITY.md)

---

## Document Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-02 | Initial release with v2.5 security documentation |

---

**API Version**: v2.5 (Security-Hardened)

**Documentation Status**: Complete

**Last Updated**: December 2, 2025
