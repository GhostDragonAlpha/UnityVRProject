# SpaceTime Testing Guide

**Purpose:** This guide helps developers verify that the HTTP API system is working correctly after installation or migration. It provides step-by-step testing procedures for all components.

**Last Updated:** 2025-12-04

---

## Table of Contents

1. [Pre-Launch Checks](#1-pre-launch-checks)
2. [Launch Testing](#2-launch-testing)
3. [HTTP API Testing](#3-http-api-testing)
4. [Scene Management Testing](#4-scene-management-testing)
5. [Common Issues & Solutions](#5-common-issues--solutions)
6. [Automated Testing](#6-automated-testing)
7. [Advanced Testing](#7-advanced-testing)

---

## 1. Pre-Launch Checks

These checks ensure your environment is configured correctly before starting Godot.

### 1.1 Verify Godot Installation

**Windows:**
```bash
# Check if Godot executable exists
dir "C:\godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe"
```

**Expected Output:**
```
Directory of C:\godot\Godot_v4.5.1-stable_win64.exe
...
Godot_v4.5.1-stable_win64_console.exe
```

**If not found:**
- Download Godot 4.5.1+ from https://godotengine.org/download
- Extract to a known location (e.g., `C:\godot\Godot_v4.5.1-stable_win64.exe\`)
- Update `restart_godot_with_debug.bat` with the correct path

---

### 1.2 Verify Project Configuration

Check that autoloads are enabled:

```bash
# View project.godot autoload section
grep -A 10 "\[autoload\]" C:/godot/project.godot
```

**Expected Output:**
```
[autoload]

ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
SettingsManager="*res://scripts/core/settings_manager.gd"
VoxelPerformanceMonitor="*res://scripts/core/voxel_performance_monitor.gd"
```

**Verification Checklist:**
- [ ] `HttpApiServer` is present and starts with `*` (enabled)
- [ ] `SceneLoadMonitor` is present and starts with `*` (enabled)
- [ ] `ResonanceEngine` is present (core system coordinator)
- [ ] `SettingsManager` is present (required dependency)

**If autoloads are missing or disabled:**
1. Open `project.godot` in a text editor
2. Add or uncomment the autoload lines shown above
3. Ensure each line starts with `*` to enable it
4. Save the file

---

### 1.3 Verify Port Availability

Port 8080 must be available for the HTTP API:

**Windows:**
```bash
# Check if port 8080 is in use
netstat -ano | findstr :8080
```

**Linux/Mac:**
```bash
# Check if port 8080 is in use
lsof -i :8080
```

**Expected Output:**
- If empty: Port is available (GOOD)
- If shows a process: Port is in use (BAD)

**If port is in use:**
1. Identify the process: `netstat -ano | findstr :8080` (Windows) or `lsof -i :8080` (Linux/Mac)
2. Stop the process or change the HTTP API port in `scripts/http_api/http_api_server.gd`

**Also check ports:**
- **8081** (WebSocket telemetry)
- **8087** (UDP service discovery)

---

### 1.4 Verify Required Files

Check that all HTTP API files exist:

```bash
# Check core HTTP API files
ls C:/godot/scripts/http_api/http_api_server.gd
ls C:/godot/scripts/http_api/scene_load_monitor.gd
ls C:/godot/scripts/http_api/security_config.gd
ls C:/godot/scripts/http_api/scene_router.gd
```

**Expected Output:**
- Each file should exist and show file size/date

**If files are missing:**
- Ensure you have the latest version of the repository
- Check that the migration was completed successfully
- Re-download or restore missing files from backup

---

### 1.5 Verify Test Scenes

Check that test scenes exist:

```bash
# Check test scenes
ls C:/godot/minimal_test.tscn
ls C:/godot/vr_main.tscn
```

**Expected Output:**
- Both files should exist

**Screenshot Placeholder:**
```
[Windows Explorer showing both .tscn files in C:\godot\]
```

---

## 2. Launch Testing

### 2.1 Start Godot with Debug Services

**Method 1: Quick Restart Script (Windows)**

```bash
cd C:/godot
./restart_godot_with_debug.bat
```

**Expected Output:**
```
========================================
 Godot Debug Services Restart Script
========================================

[1/3] Stopping existing Godot instances...
   Existing Godot processes terminated

[2/3] Locating Godot executable...
   Found: C:\godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe

[3/3] Starting Godot with debug services...
   Project Path: C:\godot
   HTTP API:     8080 (auto-start)
   Telemetry:    8081 (auto-start)

========================================
 Godot Started Successfully!
========================================
```

**Method 2: Manual Launch (All Platforms)**

```bash
# Windows
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot" --editor

# Linux
./Godot_v4.5.1-stable_linux.x86_64 --path "/path/to/godot" --editor

# Mac
./Godot.app/Contents/MacOS/Godot --path "/path/to/godot" --editor
```

---

### 2.2 Verify Console Output

Once Godot starts, check the console for initialization messages:

**Expected Console Output (in order):**

```
Godot Engine v4.5.1.stable.official [...]

[ResonanceEngine] Initializing core engine systems...
[ResonanceEngine] ===== INITIALIZATION PHASE 1: CORE SYSTEMS =====
[TimeManager] Initialized
[RelativityManager] Initialized
...

[HttpApiServer] Initializing SECURE HTTP API server on port 8080
[HttpApiServer] Build Type: DEBUG
[HttpApiServer] Environment: development
[HttpApiServer] Audit logging temporarily disabled due to class loading issues
[HttpApiServer] Whitelist configuration loaded for 'development' environment
[HttpApiServer] JWT Token generated successfully
[HttpApiServer] Registered /scene/history router
[HttpApiServer] Registered /scene/reload router
[HttpApiServer] Registered /scene router
[HttpApiServer] Registered /scenes router
[HttpApiServer] SECURE HTTP API server started on 127.0.0.1:8080
[HttpApiServer] Available endpoints:
[HttpApiServer]   POST /scene - Load a scene (AUTH REQUIRED)
[HttpApiServer]   GET  /scene - Get current scene (AUTH REQUIRED)
[HttpApiServer]   PUT  /scene - Validate a scene (AUTH REQUIRED)
[HttpApiServer]   GET  /scenes - List available scenes (AUTH REQUIRED)
[HttpApiServer]   POST /scene/reload - Reload current scene (AUTH REQUIRED)
[HttpApiServer]   GET  /scene/history - Get scene load history (AUTH REQUIRED)
[HttpApiServer]
[HttpApiServer] API TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnb2RvdC1odHRwLWFwaSIsInN1YiI6ImRldmVsb3BtZW50IiwiaWF0IjoxNzMzMzEyMTAwLCJleHAiOjE3MzMzMTU3MDB9.abcd1234...
[HttpApiServer] Use: curl -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' ...

[SceneLoadMonitor] Initializing scene load monitoring...
[SceneLoadMonitor] Ready to track scene changes
```

**Screenshot Placeholder:**
```
[Godot console showing successful HTTP API initialization with token]
```

---

### 2.3 Checklist: Verify Autoload Initialization

Go through this checklist using the console output:

- [ ] `[ResonanceEngine] Initializing core engine systems...` appears
- [ ] `[HttpApiServer] SECURE HTTP API server started on 127.0.0.1:8080` appears
- [ ] `[HttpApiServer] API TOKEN: eyJ...` appears (save this token!)
- [ ] `[SceneLoadMonitor] Ready to track scene changes` appears
- [ ] No error messages about missing files or failed initialization
- [ ] No port binding errors (would show "Address already in use")

**If any checks fail, see [Section 5: Common Issues & Solutions](#5-common-issues--solutions)**

---

### 2.4 Save Your Authentication Token

**IMPORTANT:** Copy the JWT token from the console output.

**Example token line:**
```
[HttpApiServer] API TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnb2RvdC1odHRwLWFwaSIsInN1YiI6ImRldmVsb3BtZW50IiwiaWF0IjoxNzMzMzEyMTAwLCJleHAiOjE3MzMzMTU3MDB9.abcd1234...
```

**Save it to an environment variable for easy testing:**

**Windows PowerShell:**
```powershell
$env:GODOT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Windows CMD:**
```cmd
set GODOT_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Linux/Mac:**
```bash
export GODOT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Note:** Tokens expire after 1 hour by default. If API calls start failing with 401 errors, restart Godot and get a new token.

---

## 3. HTTP API Testing

### 3.1 Test Basic Connectivity (No Auth)

First, verify the server responds (some endpoints may require auth):

```bash
# Simple connectivity test - this will likely return 401 Unauthorized, but proves server is responding
curl http://127.0.0.1:8080/scene
```

**Expected Output (if auth is enforced):**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token"
}
```

**This is GOOD!** It means:
- ✓ Server is running on port 8080
- ✓ Server is responding to requests
- ✓ Authentication is working

**If you get "Connection refused" or timeout:**
- See [Section 5.1: HTTP API Not Responding](#51-http-api-not-responding)

---

### 3.2 Test With Authentication

Now test with your saved token:

```bash
# Test with authentication (using saved token)
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene
```

**Expected Output:**
```json
{
  "success": true,
  "scene": {
    "path": "res://minimal_test.tscn",
    "name": "MinimalTest",
    "loaded": true
  }
}
```

**Checklist:**
- [ ] Response is JSON formatted
- [ ] `"success": true` is present
- [ ] `"scene"` object contains path and name
- [ ] No error messages

---

### 3.3 Test Scene Listing

Test the scenes list endpoint:

```bash
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scenes
```

**Expected Output:**
```json
{
  "success": true,
  "scenes": [
    {
      "path": "res://minimal_test.tscn",
      "name": "minimal_test.tscn",
      "type": "scene"
    },
    {
      "path": "res://vr_main.tscn",
      "name": "vr_main.tscn",
      "type": "scene"
    }
  ],
  "count": 2
}
```

**Checklist:**
- [ ] `"success": true` is present
- [ ] `"scenes"` array contains at least `minimal_test.tscn` and `vr_main.tscn`
- [ ] Each scene has `path`, `name`, and `type` fields
- [ ] `"count"` matches the number of scenes in the array

---

### 3.4 Test Scene History

Test the scene history endpoint:

```bash
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene/history
```

**Expected Output:**
```json
{
  "success": true,
  "history": [
    {
      "scene_path": "res://minimal_test.tscn",
      "timestamp": "2025-12-04T10:30:00Z",
      "status": "loaded"
    }
  ],
  "count": 1
}
```

**Checklist:**
- [ ] `"success": true` is present
- [ ] `"history"` array contains at least one entry
- [ ] Entry shows the current scene (minimal_test.tscn)
- [ ] Timestamp is present and reasonable

---

### 3.5 Test Rate Limiting

Rate limiting protects against abuse. Test it:

```bash
# Send 10 rapid requests
for i in {1..10}; do
  curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene
done
```

**Expected Behavior:**
- First ~5-10 requests succeed (200 OK)
- Later requests may return 429 (Too Many Requests) if rate limit exceeded

**Example rate limit response:**
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests from this IP address",
  "retry_after": 30
}
```

**This is GOOD!** Rate limiting is working to protect the server.

**Note:** Default rate limits:
- `/scene`: 30 requests/minute
- `/scene/reload`: 20 requests/minute
- `/scenes`: 60 requests/minute
- `/scene/history`: 100 requests/minute

---

### 3.6 Test Without Authentication (Security Check)

Verify that authentication is enforced:

```bash
# Try to access without token
curl http://127.0.0.1:8080/scene
```

**Expected Output:**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid authentication token"
}
```

**Checklist:**
- [ ] Returns 401 Unauthorized status
- [ ] Error message clearly states authentication is required
- [ ] No scene data is leaked in the response

**If endpoints work WITHOUT authentication:**
- This is a **SECURITY ISSUE**
- Check `scripts/http_api/security_config.gd` - ensure `auth_enabled: bool = true`
- See [Section 5.5: Authentication Not Working](#55-authentication-not-working)

---

## 4. Scene Management Testing

### 4.1 Load minimal_test.tscn

Test loading the minimal test scene:

```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://minimal_test.tscn"}'
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Scene loaded successfully",
  "scene": {
    "path": "res://minimal_test.tscn",
    "name": "MinimalTest"
  }
}
```

**Verification in Godot Editor:**
1. Look at the Scene tree panel (left side)
2. You should see "MinimalTest" as the root node
3. It contains a single Node3D

**Screenshot Placeholder:**
```
[Godot editor showing Scene tree with MinimalTest root node]
```

---

### 4.2 Load vr_main.tscn

Test loading the VR main scene:

```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Scene loaded successfully",
  "scene": {
    "path": "res://vr_main.tscn",
    "name": "VRMain"
  }
}
```

**Verification in Godot Editor:**
1. Check the Scene tree - root should now be "VRMain"
2. You should see VR-related nodes (XROrigin3D, XRCamera3D, controllers)

**Console Output to Look For:**
```
[VRMain] Initializing VR scene...
[VRMain] OpenXR interface detected
```

**Note:** If you don't have a VR headset, the scene will fall back to desktop mode automatically. This is normal.

---

### 4.3 Test Scene Reload

Test hot-reloading the current scene:

```bash
# First, verify current scene
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene

# Then reload it
curl -X POST http://127.0.0.1:8080/scene/reload \
  -H "Authorization: Bearer $GODOT_TOKEN"
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Scene reloaded successfully",
  "scene": {
    "path": "res://vr_main.tscn",
    "name": "VRMain"
  }
}
```

**Expected Console Output:**
```
[SceneLoadMonitor] Scene reload requested: res://vr_main.tscn
[SceneLoadMonitor] Scene reloaded successfully
```

**Verification:**
- Scene tree refreshes in Godot editor
- No errors appear in console
- Scene state resets (any runtime changes are lost)

---

### 4.4 Test Scene History After Operations

After loading several scenes, check the history:

```bash
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene/history
```

**Expected Output:**
```json
{
  "success": true,
  "history": [
    {
      "scene_path": "res://vr_main.tscn",
      "timestamp": "2025-12-04T10:35:00Z",
      "status": "loaded"
    },
    {
      "scene_path": "res://minimal_test.tscn",
      "timestamp": "2025-12-04T10:30:00Z",
      "status": "loaded"
    }
  ],
  "count": 2
}
```

**Checklist:**
- [ ] History shows all scenes loaded during this session
- [ ] Most recent scene is first (reverse chronological order)
- [ ] Timestamps are in correct order

---

### 4.5 Test Invalid Scene Path

Test error handling with an invalid scene:

```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://does_not_exist.tscn"}'
```

**Expected Output:**
```json
{
  "success": false,
  "error": "Scene not found",
  "message": "The requested scene does not exist: res://does_not_exist.tscn"
}
```

**Checklist:**
- [ ] Returns error response (not a crash)
- [ ] Error message is clear and helpful
- [ ] Current scene remains loaded (no change)

---

### 4.6 Test Scene Validation

Test the scene validation endpoint:

```bash
# Validate a valid scene
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**Expected Output:**
```json
{
  "success": true,
  "valid": true,
  "message": "Scene is valid",
  "scene_path": "res://vr_main.tscn"
}
```

**Test with invalid scene:**
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://invalid.tscn"}'
```

**Expected Output:**
```json
{
  "success": true,
  "valid": false,
  "message": "Scene does not exist",
  "scene_path": "res://invalid.tscn"
}
```

---

## 5. Common Issues & Solutions

### 5.1 HTTP API Not Responding

**Symptom:**
```bash
curl http://127.0.0.1:8080/scene
# curl: (7) Failed to connect to 127.0.0.1 port 8080: Connection refused
```

**Diagnosis Steps:**

1. **Check if Godot is running:**
   ```bash
   # Windows
   tasklist | findstr Godot

   # Linux/Mac
   ps aux | grep Godot
   ```

   If no Godot process, start Godot (see [Section 2.1](#21-start-godot-with-debug-services))

2. **Check Godot console for errors:**
   Look for error messages like:
   - `[HttpApiServer] ERROR: Failed to start server`
   - `[HttpApiServer] Port 8080 already in use`
   - `[HttpApiServer] Autoload not initialized`

3. **Check if port is listening:**
   ```bash
   # Windows
   netstat -ano | findstr :8080

   # Linux/Mac
   lsof -i :8080
   ```

   Should show Godot listening on 127.0.0.1:8080

4. **Verify autoload is enabled:**
   ```bash
   grep "HttpApiServer" C:/godot/project.godot
   ```

   Should show: `HttpApiServer="*res://scripts/http_api/http_api_server.gd"`

   If missing `*`, the autoload is disabled.

**Solutions:**

**A. Restart Godot properly:**
```bash
# Kill existing Godot processes
taskkill /IM Godot*.exe /F  # Windows
# killall Godot  # Linux/Mac

# Start with proper flags
./restart_godot_with_debug.bat  # Windows
```

**B. Check port conflicts:**
If another application is using port 8080:
- Stop the conflicting application, OR
- Change the port in `scripts/http_api/http_api_server.gd`:
  ```gdscript
  const PORT = 8090  # Change from 8080 to 8090
  ```

**C. Verify file exists:**
```bash
ls C:/godot/scripts/http_api/http_api_server.gd
```
If missing, restore from repository.

**D. Check Godot was started in EDITOR mode (not headless):**
Headless mode breaks autoloads. Must use `--editor` flag or start normally.

---

### 5.2 Port 8080 Already In Use

**Symptom:**
Console shows:
```
[HttpApiServer] ERROR: Port 8080 already in use
```

**Diagnosis:**
```bash
# Windows
netstat -ano | findstr :8080

# Linux/Mac
lsof -i :8080
```

**Solution A: Kill the conflicting process**

**Windows:**
```bash
# Find PID from netstat output (last column)
netstat -ano | findstr :8080
# Example output: TCP  127.0.0.1:8080  0.0.0.0:0  LISTENING  12345

# Kill the process
taskkill /PID 12345 /F
```

**Linux/Mac:**
```bash
# Find PID
lsof -i :8080

# Kill the process
kill -9 <PID>
```

**Solution B: Change the port**

Edit `C:/godot/scripts/http_api/http_api_server.gd`:
```gdscript
const PORT = 8090  # Change from 8080 to any available port
```

Then restart Godot and use the new port in all curl commands.

---

### 5.3 Autoload Initialization Failures

**Symptom:**
Console shows:
```
[SceneLoadMonitor] ERROR: Failed to initialize
```
or
```
[HttpApiServer] ERROR: Cannot find godottpd addon
```

**Diagnosis:**

1. **Check autoload order in project.godot:**
   ```bash
   grep -A 10 "\[autoload\]" C:/godot/project.godot
   ```

   Correct order:
   1. ResonanceEngine (first - core coordinator)
   2. HttpApiServer
   3. SceneLoadMonitor
   4. SettingsManager
   5. VoxelPerformanceMonitor

2. **Check if godottpd addon exists:**
   ```bash
   ls C:/godot/addons/godottpd/
   ```

   Should contain: `http_server.gd`, `plugin.cfg`, etc.

3. **Check if addon is enabled:**
   ```bash
   grep "godottpd" C:/godot/project.godot
   ```

   Should show: `enabled=PackedStringArray("res://addons/godottpd/plugin.cfg", ...)`

**Solutions:**

**A. Enable the godottpd plugin:**
1. Open Godot editor
2. Go to: Project → Project Settings → Plugins
3. Find "godottpd" in the list
4. Check the "Enable" checkbox
5. Restart Godot

**B. Install godottpd addon:**
If the addon is missing:
```bash
cd C:/godot/addons
git clone https://github.com/you-win/godottpd.git godottpd
```

Or download manually from AssetLib in Godot editor.

**C. Fix autoload order:**
Edit `project.godot` to ensure autoloads are in the correct order (see above).

---

### 5.4 Scene Not Loading

**Symptom:**
```json
{
  "success": false,
  "error": "Scene not found"
}
```

**Diagnosis:**

1. **Verify scene file exists:**
   ```bash
   ls C:/godot/vr_main.tscn
   ```

2. **Check scene path format:**
   Correct: `"res://vr_main.tscn"`
   Wrong: `"C:/godot/vr_main.tscn"` (file system paths don't work)
   Wrong: `"/vr_main.tscn"` (missing `res://` prefix)

3. **Check scene whitelist:**
   Edit `scripts/http_api/security_config.gd`:
   ```gdscript
   static var _scene_whitelist: Array[String] = [
       "res://vr_main.tscn",
       "res://minimal_test.tscn",
       # Your scene must be listed here
   ]
   ```

**Solutions:**

**A. Use correct scene path format:**
```bash
# Correct
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**B. Add scene to whitelist:**
Edit `scripts/http_api/security_config.gd`:
```gdscript
static var _scene_whitelist: Array[String] = [
    "res://vr_main.tscn",
    "res://minimal_test.tscn",
    "res://your_scene.tscn",  # Add your scene
]
```

Then restart Godot to apply changes.

**C. Verify scene file is valid:**
Open the scene in Godot editor manually:
1. File → Open Scene
2. Select your .tscn file
3. If it opens without errors, the file is valid

---

### 5.5 Authentication Not Working

**Symptom:**
All requests return 401 Unauthorized, even with token:
```json
{
  "error": "Unauthorized",
  "message": "Invalid token"
}
```

**Diagnosis:**

1. **Check if token is expired:**
   Tokens expire after 1 hour by default. If you started Godot more than 1 hour ago, get a new token:
   - Restart Godot
   - Copy the new token from console
   - Update your `$GODOT_TOKEN` environment variable

2. **Verify token format:**
   Should look like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ...`

   **Check for common issues:**
   - Leading/trailing whitespace
   - Truncated token (incomplete copy/paste)
   - Wrong token (from different Godot session)

3. **Check Authorization header format:**
   ```bash
   # Correct
   -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

   # Wrong (missing "Bearer")
   -H "Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

   # Wrong (wrong header name)
   -H "X-API-Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   ```

**Solutions:**

**A. Get a fresh token:**
```bash
# Restart Godot
./restart_godot_with_debug.bat

# Wait for initialization (10 seconds)

# Look for this line in console:
# [HttpApiServer] API TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Copy the ENTIRE token (select from eyJ to the end)

# Set environment variable
export GODOT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**B. Disable authentication for testing:**
Edit `scripts/http_api/security_config.gd`:
```gdscript
static var auth_enabled: bool = false  # Change from true to false
```

**WARNING:** Only do this in development! Re-enable authentication before production.

**C. Increase token expiration:**
Edit `scripts/http_api/security_config.gd`:
```gdscript
static var _jwt_token_duration: int = 86400  # 24 hours instead of 1 hour
```

---

### 5.6 Rate Limiting Too Strict

**Symptom:**
Getting 429 Too Many Requests frequently:
```json
{
  "error": "Rate limit exceeded",
  "retry_after": 30
}
```

**Solutions:**

**A. Wait for rate limit to reset:**
Wait the number of seconds shown in `retry_after`.

**B. Adjust rate limits for development:**
Edit `scripts/http_api/security_config.gd`:
```gdscript
const DEFAULT_RATE_LIMIT = 1000  # Increase from 100

static var _endpoint_rate_limits: Dictionary = {
    "/scene": 300,  # Increase from 30
    "/scene/reload": 200,  # Increase from 20
    "/scenes": 600,  # Increase from 60
    "/scene/history": 1000  # Increase from 100
}
```

**C. Disable rate limiting temporarily:**
```gdscript
static var rate_limiting_enabled: bool = false  # Change from true
```

**WARNING:** Only for development! Re-enable for production.

---

## 6. Automated Testing

### 6.1 Run Health Check Script

The health check script verifies all components are working:

```bash
cd C:/godot
python test_health_endpoint.py
```

**Expected Output:**
```
============================================================
Testing Enhanced /health Endpoint
============================================================

Status Code: 200

Response:
{
  "server": "godot-http-api",
  "timestamp": "2025-12-04T10:30:00Z",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": true
  },
  "scene": {
    "loaded": true,
    "name": "MinimalTest"
  },
  "player": {
    "spawned": false
  },
  "overall_healthy": true,
  "blocking_issues": []
}

============================================================
Health Check Analysis
============================================================

✓ Server: godot-http-api
  Timestamp: 2025-12-04T10:30:00Z

✓ Godot Process:
  Running: True
  PID: 12345

✓ Godot API:
  Reachable: True

✓ Scene:
  Loaded: True
  Name: MinimalTest

✗ Player:
  Spawned: False

✓ Overall Health: True

✓ No blocking issues - system fully ready!

============================================================
Test Results
============================================================
✓ Status code correct: 200
✓ All required keys present
✓ Blocking issues correctly reported
✓ overall_healthy logic correct

============================================================
✓ Health endpoint test completed
============================================================
```

**Checklist:**
- [ ] Status code is 200
- [ ] All required keys present
- [ ] No blocking issues (or expected issues only)
- [ ] overall_healthy is True

---

### 6.2 Interpret Health Check Results

**Scenario 1: Fully Healthy**
```json
{
  "overall_healthy": true,
  "blocking_issues": []
}
```
✓ All systems operational! You can proceed with development.

---

**Scenario 2: Godot Process Not Running**
```json
{
  "overall_healthy": false,
  "godot_process": {"running": false},
  "blocking_issues": ["Godot process not running"]
}
```
**Action:** Start Godot (see [Section 2.1](#21-start-godot-with-debug-services))

---

**Scenario 3: API Not Reachable**
```json
{
  "overall_healthy": false,
  "godot_process": {"running": true},
  "godot_api": {"reachable": false},
  "blocking_issues": ["Godot API not reachable"]
}
```
**Action:**
- Wait 10 seconds (API may still be initializing)
- Check console for errors
- See [Section 5.1: HTTP API Not Responding](#51-http-api-not-responding)

---

**Scenario 4: Scene Not Loaded**
```json
{
  "overall_healthy": false,
  "scene": {"loaded": false},
  "blocking_issues": ["Main scene not loaded"]
}
```
**Action:** Load a scene manually:
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://minimal_test.tscn"}'
```

---

### 6.3 Run Integration Tests

If you have Python integration tests:

```bash
# Activate virtual environment
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# Run integration tests
cd C:/godot
python test_runtime_features.py
```

**Expected Output:**
```
============================================================
Runtime Features Test Suite
============================================================

Test 1: HTTP API Connectivity................ PASS
Test 2: Scene Loading........................ PASS
Test 3: Scene Reload......................... PASS
Test 4: Authentication....................... PASS
Test 5: Rate Limiting........................ PASS

============================================================
All tests passed! (5/5)
============================================================
```

---

### 6.4 Run GDScript Unit Tests (GdUnit4)

If you have GdUnit4 installed:

**Method 1: From Godot Editor (Recommended)**
1. Open Godot editor
2. Click on the "GdUnit4" panel at the bottom
3. Click "Run All Tests"
4. Watch for green checkmarks (pass) or red X's (fail)

**Screenshot Placeholder:**
```
[Godot editor showing GdUnit4 panel with test results]
```

**Method 2: From Command Line**
```bash
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/
```

**Expected Output:**
```
============================================================
GdUnit4 Test Results
============================================================

Test Suite: HttpApiServerTest
  ✓ test_server_initialization
  ✓ test_endpoint_registration
  ✓ test_authentication

Test Suite: SceneLoadMonitorTest
  ✓ test_scene_tracking
  ✓ test_scene_history

============================================================
All tests passed! (5/5)
============================================================
```

---

## 7. Advanced Testing

### 7.1 WebSocket Telemetry Testing

The HTTP API also provides WebSocket telemetry on port 8081.

**Test with wscat (Node.js tool):**
```bash
# Install wscat
npm install -g wscat

# Connect to telemetry stream
wscat -c ws://127.0.0.1:8081
```

**Expected Output:**
```
Connected (press CTRL+C to quit)
< {"type":"heartbeat","timestamp":1733312100}
< {"type":"performance","fps":60,"frame_time":16.67,"memory_mb":245}
< {"type":"heartbeat","timestamp":1733312130}
```

**Telemetry Message Types:**
- `heartbeat` - Sent every 30 seconds
- `performance` - FPS, frame time, memory usage
- `scene_loaded` - When a scene loads
- `error` - When errors occur

---

### 7.2 Load Testing with Multiple Requests

Test how the API handles concurrent requests:

**Using Apache Bench (ab):**
```bash
# Install apache2-utils (Linux) or httpd-tools (RHEL)

# Test with 100 requests, 10 concurrent
ab -n 100 -c 10 -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scenes
```

**Expected Output:**
```
Concurrency Level:      10
Time taken for tests:   2.345 seconds
Complete requests:      100
Failed requests:        0
Requests per second:    42.64 [#/sec] (mean)
```

**Checklist:**
- [ ] Failed requests = 0 (or very low)
- [ ] Requests per second > 20
- [ ] No crashes or errors in Godot console

---

### 7.3 Security Testing

Test security features:

**Test 1: SQL Injection Attempt**
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://test.tscn\"; DROP TABLE users;--"}'
```

**Expected:** Request rejected or sanitized, no database errors (Godot doesn't use SQL, but tests input validation).

---

**Test 2: Path Traversal Attempt**
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://../../etc/passwd"}'
```

**Expected:** Request rejected with error about invalid scene path.

---

**Test 3: Oversized Request**
```bash
# Create a 2MB payload (exceeds MAX_REQUEST_SIZE of 1MB)
python3 -c "print('{\"scene_path\": \"res://test.tscn\", \"data\": \"' + 'A' * 2000000 + '\"}')}" > large_payload.json

curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d @large_payload.json
```

**Expected:** Request rejected with "Request too large" error.

---

### 7.4 Performance Profiling

Monitor API performance:

**Using curl with timing:**
```bash
curl -w "\nTime: %{time_total}s\n" \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  http://127.0.0.1:8080/scenes
```

**Expected Output:**
```json
{"success":true,"scenes":[...],"count":2}
Time: 0.045s
```

**Performance Targets:**
- `/scenes` (list): < 0.1s
- `/scene` (get current): < 0.05s
- `/scene/history`: < 0.1s
- `/scene` (load): < 2.0s (depends on scene complexity)
- `/scene/reload`: < 2.0s

**If times exceed targets:**
- Check system resources (CPU, RAM)
- Check for other heavy processes
- Review scene complexity
- See performance optimization docs

---

## 8. Quick Reference

### 8.1 Essential curl Commands

**Get current scene:**
```bash
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene
```

**Load a scene:**
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**Reload current scene:**
```bash
curl -X POST http://127.0.0.1:8080/scene/reload \
  -H "Authorization: Bearer $GODOT_TOKEN"
```

**List all scenes:**
```bash
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scenes
```

**View scene history:**
```bash
curl -H "Authorization: Bearer $GODOT_TOKEN" http://127.0.0.1:8080/scene/history
```

**Validate a scene:**
```bash
curl -X PUT http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $GODOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://test.tscn"}'
```

---

### 8.2 Environment Variables

**Set token (PowerShell):**
```powershell
$env:GODOT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Set token (Bash):**
```bash
export GODOT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Override environment:**
```bash
# Force production mode
export GODOT_ENV=production

# Force test mode
export GODOT_ENV=test

# Disable HTTP API
export GODOT_ENABLE_HTTP_API=false
```

---

### 8.3 Port Reference

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 8080 | HTTP API | HTTP | Scene management and system control |
| 8081 | Telemetry | WebSocket | Real-time performance metrics |
| 8087 | Discovery | UDP | Service discovery broadcast |

---

### 8.4 File Locations

**Core files:**
- `C:/godot/project.godot` - Project configuration
- `C:/godot/scripts/http_api/http_api_server.gd` - Main HTTP server
- `C:/godot/scripts/http_api/scene_load_monitor.gd` - Scene monitoring
- `C:/godot/scripts/http_api/security_config.gd` - Security settings

**Test files:**
- `C:/godot/test_health_endpoint.py` - Health check test
- `C:/godot/minimal_test.tscn` - Minimal test scene
- `C:/godot/vr_main.tscn` - VR main scene

**Logs:**
- Godot console output (in Godot editor)
- System logs (platform dependent)

---

## 9. Troubleshooting Checklist

When something goes wrong, work through this checklist:

### Level 1: Basic Checks
- [ ] Is Godot running? (`tasklist | findstr Godot`)
- [ ] Is Godot in editor mode (not headless)?
- [ ] Is port 8080 available? (`netstat -ano | findstr :8080`)
- [ ] Did Godot finish initializing? (wait 10 seconds after start)

### Level 2: Configuration Checks
- [ ] Are autoloads enabled in project.godot?
- [ ] Is godottpd plugin enabled?
- [ ] Do all required files exist?
- [ ] Is the token still valid? (< 1 hour old)

### Level 3: API Checks
- [ ] Does `/scene` endpoint respond (even with 401)?
- [ ] Is authorization header formatted correctly?
- [ ] Is the token the latest one from console?
- [ ] Are you using the correct port (8080)?

### Level 4: Advanced Checks
- [ ] Check Godot console for error messages
- [ ] Run health check script (`python test_health_endpoint.py`)
- [ ] Check firewall settings
- [ ] Verify scene paths use `res://` prefix
- [ ] Check scene whitelist in security_config.gd

---

## 10. Getting Help

If you're still stuck after following this guide:

1. **Check console output:** Most issues show error messages in Godot console
2. **Review CLAUDE.md:** Project-specific guidance in `C:/godot/CLAUDE.md`
3. **Check documentation:** See `docs/current/guides/` for detailed guides
4. **Search issues:** Check if others have encountered the same problem
5. **Create detailed bug report:** Include:
   - Steps to reproduce
   - Expected vs actual behavior
   - Console output (full errors)
   - System info (OS, Godot version)
   - Curl command that failed

---

## Appendix A: Success Criteria Checklist

Use this checklist to verify a complete successful test:

### Pre-Launch
- [ ] Godot executable found and working
- [ ] All autoloads enabled in project.godot
- [ ] Port 8080 available
- [ ] Test scenes exist (minimal_test.tscn, vr_main.tscn)

### Launch
- [ ] Godot started without errors
- [ ] ResonanceEngine initialized
- [ ] HttpApiServer started on 127.0.0.1:8080
- [ ] JWT token generated and displayed
- [ ] SceneLoadMonitor initialized
- [ ] All endpoints registered

### API Testing
- [ ] `/scene` endpoint responds (with auth)
- [ ] `/scenes` lists available scenes
- [ ] `/scene/history` shows scene history
- [ ] Authentication required (401 without token)
- [ ] Rate limiting works (429 after many requests)

### Scene Management
- [ ] Can load minimal_test.tscn successfully
- [ ] Can load vr_main.tscn successfully
- [ ] Can reload current scene
- [ ] Scene history tracks all loads
- [ ] Invalid scenes return proper errors
- [ ] Scene validation works

### Security
- [ ] Authentication enforced
- [ ] Rate limiting active
- [ ] Invalid tokens rejected
- [ ] Oversized requests rejected
- [ ] Scene whitelist enforced

**If all checkboxes are ticked: Your HTTP API migration is SUCCESSFUL! 🎉**

---

## Appendix B: Development vs Production

### Development Environment (DEBUG builds)

**Characteristics:**
- Auth enabled but relaxed
- Higher rate limits
- Detailed error messages
- All scenes allowed in whitelist
- HTTP API enabled by default

**Configuration:**
```gdscript
// Detected from: OS.is_debug_build() == true
current_environment = "development"
auth_enabled = true
rate_limiting_enabled = true
DEFAULT_RATE_LIMIT = 100
```

---

### Production Environment (RELEASE builds)

**Characteristics:**
- Auth strictly enforced
- Lower rate limits
- Generic error messages (no internal details)
- Strict scene whitelist
- HTTP API **DISABLED** by default (security hardening)

**Configuration:**
```gdscript
// Detected from: OS.is_debug_build() == false
current_environment = "production"
api_disabled = true  // Unless GODOT_ENABLE_HTTP_API=true
auth_enabled = true
rate_limiting_enabled = true
DEFAULT_RATE_LIMIT = 30
```

**To enable HTTP API in production:**
```bash
export GODOT_ENABLE_HTTP_API=true
./SpaceTime.exe
```

---

### Test Environment

**Characteristics:**
- Auth enabled
- No rate limiting
- Detailed error messages
- All scenes allowed

**Configuration:**
```bash
export GODOT_ENV=test
```

---

**End of Testing Guide**

Last updated: 2025-12-04
Version: 2.0
