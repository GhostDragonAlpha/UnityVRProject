# Setup Instructions for Godot Debug Connection

## ⚠️ MANDATORY DEBUG CONNECTION SETUP (STEP 1 - REQUIRED) ⚠️

5. **Check the "Enable" checkbox** (REQUIRED - not optional)
6. The plugin will automatically configure the GodotBridge autoload

#### 1.2 Start Godot with GDA Services (MANDATORY)

**This step is REQUIRED. The system will not function without GDA services running.**

```bash
# Windows (REQUIRED)
godot.exe --path "C:\path\to\your\project" --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005

# macOS (REQUIRED)
/Applications/Godot.app/Contents/MacOS/Godot --path "/path/to/your/project" --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005

# Linux (REQUIRED)
godot --path "/path/to/your/project" --debug-server tcp://127.0.0.1:6006 --lsp-server tcp://127.0.0.1:6005
```

#### 1.3 Verify Debug Connection (MANDATORY)

After starting Godot, **immediately verify** that the debug connection is active:

```bash
# Check HTTP server is running (REQUIRED)
curl http://127.0.0.1:8080/status

# Expected response MUST show:
# - debug_adapter.state = 2 (CONNECTED) ⚠️ REQUIRED
# - language_server.state = 2 (CONNECTED) ⚠️ REQUIRED
# - overall_ready = true ⚠️ REQUIRED
```

If you do not see `state: 2` for both services and `overall_ready: true`, **STOP and troubleshoot** before proceeding.

### Consequences of Skipping Debug Setup

If you skip or incorrectly configure the debug connection:

- ❌ HTTP API will return 503 Service Unavailable errors
- ❌ DAP commands will fail with connection errors
- ❌ LSP requests will fail with service unavailable errors
- ❌ Telemetry streaming will not function
- ❌ AI assistant integration will be completely non-functional
- ❌ Code editing and hot-reload capabilities will be disabled
- ❌ Development tools will not work

**See [MANDATORY_DEBUG_ENFORCEMENT.md](MANDATORY_DEBUG_ENFORCEMENT.md) for detailed requirements and troubleshooting.**

## Task 1 Completion Status

✅ **Directory structure created** - All component files are in place under `addons/godot_debug_connection/`
✅ **ConnectionState enum defined** - Enum with all 5 required states (DISCONNECTED, CONNECTING, CONNECTED, ERROR, RECONNECTING)
✅ **Testing framework setup** - GdUnit4 setup instructions and test structure created

## Project Structure

```
SpaceTime/
├── addons/
│   └── godot_debug_connection/
│       ├── connection_state.gd       # ✅ ConnectionState enum
│       ├── dap_adapter.gd            # ✅ Placeholder for DAP adapter
│       ├── lsp_adapter.gd            # ✅ Placeholder for LSP adapter
│       ├── connection_manager.gd     # ✅ Placeholder for connection manager
│       ├── godot_bridge.gd           # ✅ Placeholder for HTTP bridge
│       ├── plugin.gd                 # ✅ Plugin entry point
│       ├── plugin.cfg                # ✅ Plugin configuration
│       └── README.md                 # ✅ Component documentation
└── tests/
    ├── README.md                     # ✅ Testing setup guide
    ├── simple_test_runner.gd         # ✅ Basic test runner
    └── unit/
        └── test_connection_state.gd  # ✅ Unit tests for ConnectionState
```

## Next Steps (After Debug Connection is Verified)

### 2. Install GdUnit4 Testing Framework

**Option A: Via Godot Editor (Recommended)**

1. Open the Godot Editor with this project
2. Go to the AssetLib tab
3. Search for "GdUnit4"
4. Click Download and Install
5. Enable the plugin in Project Settings > Plugins

**Option B: Manual Installation**

1. Download from: https://github.com/MikeSchulze/gdUnit4
2. Extract to `addons/gdUnit4/`
3. Enable in Project Settings > Plugins

### 3. Verify Installation

**Using Simple Test Runner:**

```bash
# Navigate to project directory
cd SpaceTime

# Run with Godot (adjust path to your Godot executable)
godot --headless --script tests/simple_test_runner.gd

# Or on Windows:
"C:\Program Files\Godot\godot.exe" --headless --script tests/simple_test_runner.gd
```

**Using GdUnit4 (after installation):**

1. Open Godot Editor
2. Open the GdUnit4 panel (bottom of editor)
3. Click "Run All Tests"

Or via command line:

```bash
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/
```

### 3.1 Custom SceneTree Test Runner
Some tests (like `test_walking_controller.gd`) use a custom `SceneTree`-based runner for better compatibility with headless mode physics. To run these:

```bash
godot --headless --script tests/unit/test_walking_controller.gd
```

### 4. Enable the Plugin

1. Open Project Settings > Plugins
2. Enable "Godot Debug Connection"
3. The plugin is now ready for implementation

## Verification Checklist

### Debug Connection Verification (MANDATORY - Must be completed first)

- [ ] Plugin is enabled in Project Settings > Plugins
- [ ] Godot started with `--debug-server` and `--lsp-server` arguments
- [ ] HTTP server responding on port 8080
- [ ] `curl http://127.0.0.1:8080/status` shows `overall_ready: true`
- [ ] Both `debug_adapter.state` and `language_server.state` show `2` (CONNECTED)
- [ ] No "MANDATORY DEBUG ERROR" messages in console

### General Verification (After debug connection is verified)

- [ ] GdUnit4 installed and enabled
- [ ] Simple test runner executes successfully
- [ ] ConnectionState enum accessible in editor
- [ ] Plugin appears in Project Settings > Plugins
- [ ] All 5 connection states defined correctly

## ConnectionState Enum Details

The enum is defined in `addons/godot_debug_connection/connection_state.gd`:

```gdscript
enum State {
    DISCONNECTED,   # Value: 0 - Not connected to the service
    CONNECTING,     # Value: 1 - Connection attempt in progress
    INITIALIZING,   # Value: 2 - Handshake in progress
    CONNECTED,      # Value: 3 - Successfully connected and ready
    ERROR,          # Value: 4 - Connection failed after retries
    RECONNECTING    # Value: 5 - Attempting to reconnect after unexpected disconnect
}
```

## Troubleshooting

### Debug Connection Issues (MANDATORY)

**Issue: "MANDATORY DEBUG ERROR" messages in console**

- **Solution**: Ensure plugin is enabled and Godot was started with GDA services
- **Verify**: Run `curl http://127.0.0.1:8080/status` and check for `overall_ready: true`

**Issue: HTTP server not responding**

- **Solution**: Check port availability: `netstat -an | grep 8080`
- **Solution**: Try alternative ports (8083, 8084, 8085)


**Issue: DAP/LSP services not connecting**

- **Solution**: Verify Godot was started with `--debug-server` and `--lsp-server`
- **Solution**: Check service ports: `netstat -an | grep 6005` and `netstat -an | grep 6006`

### General Issues

**Issue: Godot command not found**

- Add Godot to your system PATH, or use the full path to the executable

**Issue: Plugin not appearing**

- Ensure the `addons/godot_debug_connection/` directory is in the correct location
- Check that `plugin.cfg` exists and is properly formatted
- Restart the Godot Editor

**Issue: Tests not running**

- Verify GdUnit4 is installed and enabled
- Check that test files are in the `tests/` directory
- Ensure test files extend `GdUnitTestSuite`

## Task 1 Summary

Task 1 has been completed successfully:

1. ✅ **Directory structure created**: All component files are organized under `addons/godot_debug_connection/`
2. ✅ **ConnectionState enum defined**: Complete enum with all 5 required states (DISCONNECTED, CONNECTING, CONNECTED, ERROR, RECONNECTING)
3. ✅ **Testing framework setup**: GdUnit4 setup instructions provided, test directory structure created, and basic tests written

The project is now ready for Task 2 implementation (DAPAdapter).

**⚠️ REMEMBER: Debug connection setup (Step 1) is MANDATORY and must be completed before any other development work.**
