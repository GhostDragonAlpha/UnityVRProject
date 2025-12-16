# SpaceTime VR - Getting Started Guide

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Audience:** New Developers

Welcome to SpaceTime VR development! This guide will help you get up and running quickly.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [First Run](#first-run)
4. [Development Workflow](#development-workflow)
5. [Project Structure](#project-structure)
6. [Common Tasks](#common-tasks)
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

---

## Prerequisites

### Required Software

- **Godot Engine 4.5.1+**
  - [Download Godot 4.5.1](https://godotengine.org/download/)
  - Get the standard (non-Mono) version
  - Ensure it's added to your PATH

- **Python 3.8+**
  - [Download Python](https://www.python.org/downloads/)
  - Make sure to check "Add Python to PATH" during installation
  - Verify: `python --version`

- **Git**
  - [Download Git](https://git-scm.com/downloads/)
  - Verify: `git --version`

### Optional but Recommended

- **Visual Studio Code** (or your preferred IDE)
  - [Download VS Code](https://code.visualstudio.com/)
  - Install extensions:
    - `godot-tools` - GDScript language support
    - `Python` - Python support

- **GitHub CLI** (for PR management)
  - [Download gh](https://cli.github.com/)
  - Verify: `gh --version`

- **VR Headset** (for VR testing)
  - OpenXR-compatible headset (Quest 2/3, Valve Index, etc.)
  - SteamVR or Oculus software installed

### System Requirements

**Minimum:**
- OS: Windows 10, Linux, macOS
- CPU: Quad-core processor
- RAM: 8 GB
- GPU: DirectX 11 compatible
- Storage: 5 GB free space

**Recommended:**
- OS: Windows 11
- CPU: 8-core processor
- RAM: 16 GB
- GPU: NVIDIA RTX 2060 or AMD equivalent
- Storage: 10 GB free space (SSD)

---

## Installation

### 1. Clone the Repository

```bash
# Clone the repo
git clone https://github.com/your-org/spacetime-vr.git
cd spacetime-vr
```

### 2. Set Up Python Environment

```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install test dependencies
pip install -r tests/property/requirements.txt
```

**Dependencies installed:**
- `requests` - HTTP client
- `websockets` - WebSocket client
- `pytest` - Testing framework
- `hypothesis` - Property-based testing

### 3. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your settings
# For local development, defaults are usually fine
```

**Key environment variables:**
```bash
# API Configuration
HTTP_API_PORT=8080
TELEMETRY_PORT=8081
DAP_PORT=6006
LSP_PORT=6005

# Database (for production)
DATABASE_URL=postgresql://localhost/spacetime

# Redis (for production)
REDIS_URL=redis://localhost:6379
```

### 4. Install GDUnit4 (Testing Framework)

**Option A: Via Git**
```bash
cd addons
git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4
cd ..
```

**Option B: Via Godot AssetLib**
1. Open Godot Editor
2. Go to AssetLib tab
3. Search "GdUnit4"
4. Download and Install
5. Enable in Project → Project Settings → Plugins

### 5. Verify Installation

```bash
# Check Python environment
python --version
pip list

# Check Godot
godot --version

# Run quick diagnostic
python check_status.py
```

---

## First Run

### Starting the Development Server

**IMPORTANT:** Always use the Python server to start Godot. Do NOT start Godot directly.

```bash
# Start the development server
python godot_editor_server.py --port 8090
```

**What this does:**
- Starts Godot with proper debug flags
- Initializes DAP/LSP connections
- Starts HTTP API and telemetry servers
- Provides simple control interface on port 8090

**Expected output:**
```
╔════════════════════════════════════════════════════════════╗
║         Godot Editor Server - Starting Up                 ║
╚════════════════════════════════════════════════════════════╝

[INFO] Starting Godot with debug services...
[INFO] Godot PID: 12345
[INFO] HTTP API starting on port 8080...
[INFO] Telemetry server starting on port 8081...
[INFO] DAP listening on port 6006...
[INFO] LSP listening on port 6005...
[SUCCESS] All services ready!
[INFO] Server control API available at http://localhost:8090
```

### Verify Everything Works

**1. Check Status:**
```bash
# In a new terminal
curl http://localhost:8080/status | jq
```

**Expected response:**
```json
{
  "overall_ready": true,
  "debug_adapter": {
    "state": 2,
    "healthy": true
  },
  "language_server": {
    "state": 2,
    "healthy": true
  }
}
```

**2. Run Smoke Tests:**
```bash
cd tests
python test_runner.py --quick
```

**3. Monitor Telemetry:**
```bash
python telemetry_client.py
```

You should see real-time FPS and performance metrics streaming.

### Open the Project in VR

If you have a VR headset:

1. Put on your headset
2. Ensure SteamVR or Oculus software is running
3. In the Godot editor, press F5 (or click Play)
4. The VR scene should launch
5. You should see the spawn point and be able to look around

---

## Development Workflow

### Daily Workflow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Activate Python environment
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# 3. Start development server
python godot_editor_server.py --port 8090

# 4. Make changes in Godot Editor
# Edit GDScript files, scenes, etc.

# 5. Test changes
python tests/test_runner.py

# 6. Commit and push
git add .
git commit -m "Description of changes"
git push origin your-branch
```

### Making Code Changes

**1. Hot-Reload:**
Changes to GDScript are automatically reloaded when you save. Just press F6 in the editor to reload the current scene.

**2. Testing Changes:**
```bash
# Run specific test
python tests/test_spacecraft_controls.py

# Run all tests
python tests/test_runner.py

# Run GDScript unit tests
# Use GdUnit4 panel at bottom of Godot editor
```

**3. Debugging:**
```bash
# Monitor telemetry
python telemetry_client.py

# Use Python debugger
python examples/debug_session_example.py
```

### Creating a Feature Branch

```bash
# Create new branch
git checkout -b feature/my-new-feature

# Make changes
# ... edit files ...

# Commit changes
git add .
git commit -m "Add my new feature"

# Push to remote
git push origin feature/my-new-feature

# Create pull request
gh pr create --title "My New Feature" --body "Description..."
```

---

## Project Structure

```
spacetime-vr/
├── scripts/                # GDScript source code
│   ├── core/              # Core systems (engine, physics, VR)
│   ├── player/            # Player controls and states
│   ├── celestial/         # Space physics and orbital mechanics
│   ├── gameplay/          # Game mechanics (missions, creatures, etc.)
│   ├── ui/                # User interface
│   └── audio/             # Audio systems
│
├── scenes/                # Godot scene files
│   ├── vr_main.tscn       # Main VR scene
│   └── ...
│
├── addons/                # Third-party addons
│   ├── godot_debug_connection/  # Debug/telemetry system
│   └── gdUnit4/           # Testing framework
│
├── tests/                 # Test suites
│   ├── unit/              # GDScript unit tests
│   ├── integration/       # Integration tests
│   └── property/          # Python property-based tests
│
├── docs/                  # Documentation
│   ├── api/               # API reference
│   ├── architecture/      # System architecture docs
│   ├── development/       # Developer guides
│   ├── operations/        # Operational runbooks
│   └── current/           # Current feature docs
│
├── examples/              # Example scripts and usage
│   └── *.py               # Python client examples
│
├── deploy/                # Deployment scripts
├── monitoring/            # Monitoring configuration
└── docker/                # Docker configuration
```

### Key Files

- `project.godot` - Godot project configuration
- `vr_main.tscn` - Main entry scene
- `vr_setup.gd` - VR initialization script
- `CLAUDE.md` - Project instructions for AI
- `README.md` - Project overview
- `.env` - Environment configuration

---

## Common Tasks

### Running Tests

**Python Tests:**
```bash
# All tests
python tests/test_runner.py

# Specific test
python tests/test_spacecraft_controls.py

# With coverage
python tests/test_runner.py --coverage
```

**GDScript Tests:**
```bash
# Via Godot editor (recommended)
# 1. Open Godot editor
# 2. Click GdUnit4 panel at bottom
# 3. Click "Run All Tests"

# Via command line
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/
```

### Adding a New Feature

**1. Create the script:**
```bash
# Create new GDScript file
touch scripts/gameplay/my_feature.gd
```

**2. Add class_name:**
```gdscript
# my_feature.gd
class_name MyFeature
extends Node

# Your code here
```

**3. Create a scene:**
- Right-click in Godot FileSystem
- New Scene
- Add your script as root node
- Save scene

**4. Add to autoload (if needed):**
- Project → Project Settings → Autoload
- Add your script/scene

**5. Write tests:**
```bash
# Create test file
touch tests/unit/test_my_feature.gd
```

```gdscript
# test_my_feature.gd
extends GdUnitTestSuite

func test_my_feature_does_something():
    var feature = MyFeature.new()
    add_child(feature)

    feature.do_something()

    assert_that(feature.result).is_equal(expected_value)
```

**6. Test and iterate:**
```bash
# Run tests
python tests/test_runner.py

# Or use GdUnit4 panel in editor
```

### Adding an API Endpoint

**1. Edit GodotBridge:**
```gdscript
# addons/godot_debug_connection/godot_bridge.gd

func _handle_request(request: Dictionary) -> Dictionary:
    match request.path:
        # ... existing endpoints ...

        "/my_endpoint":
            return handle_my_endpoint(request)

func handle_my_endpoint(request: Dictionary) -> Dictionary:
    # Parse parameters
    var param = request.params.get("param", "default")

    # Do something
    var result = do_something(param)

    # Return response
    return {
        "status": "success",
        "data": result
    }
```

**2. Test the endpoint:**
```bash
# Test with curl
curl http://localhost:8080/my_endpoint?param=value

# Or with Python
python examples/test_endpoint.py
```

**3. Document the endpoint:**
Add to `docs/api/API_REFERENCE.md`

### Debugging

**Print Debugging:**
```gdscript
print("Debug message")
print("Variable value: ", my_var)
push_warning("Warning message")
push_error("Error message")
```

**Debugger:**
```gdscript
# Add breakpoint in code
breakpoint

# Or use editor debugger:
# Click line number gutter to add breakpoint
# Press F5 to run with debugger
```

**Telemetry:**
```bash
# Monitor real-time metrics
python telemetry_client.py

# Check specific metrics
curl http://localhost:8080/metrics
```

**Logs:**
```bash
# Check Godot console output
# In editor: Output panel at bottom

# Or check log file
tail -f ~/.local/share/godot/app_userdata/SpaceTime/logs/godot.log
```

---

## Troubleshooting

### Godot Won't Start

**Problem:** Server fails to start Godot

**Solutions:**
```bash
# 1. Check if Godot is in PATH
godot --version

# 2. Try manual start
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# 3. Check if ports are blocked
python check_ports.py

# 4. Kill existing Godot processes
# Windows:
taskkill /F /IM godot.exe
# Linux/Mac:
killall godot
```

### HTTP API Not Responding

**Problem:** `curl http://localhost:8080/status` fails

**Solutions:**
```bash
# 1. Check if service is running
curl http://localhost:8080/health

# 2. Try fallback ports
curl http://localhost:8083/status  # Fallback port

# 3. Check Godot logs
docker-compose logs godot-server

# 4. Restart services
python godot_editor_server.py --port 8090
```

### VR Not Working

**Problem:** VR headset not detected

**Solutions:**
1. Ensure SteamVR/Oculus software is running
2. Check headset is connected and turned on
3. Verify OpenXR runtime is configured:
   - SteamVR: Settings → OpenXR → Set as active runtime
4. Restart Godot
5. Check VR logs:
   ```bash
   # In Godot console
   # Look for "XR interface initialized" message
   ```

### Tests Failing

**Problem:** Test suite returns errors

**Solutions:**
```bash
# 1. Update dependencies
pip install -r requirements.txt --upgrade

# 2. Check Python environment
which python  # Should point to .venv

# 3. Clear test cache
rm -rf .pytest_cache __pycache__

# 4. Run specific failing test with verbose output
python -m pytest tests/test_name.py -v

# 5. Check GDScript syntax
# Open file in Godot editor, look for syntax errors
```

### Import Errors

**Problem:** Python scripts can't import modules

**Solutions:**
```bash
# 1. Activate virtual environment
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/Mac

# 2. Verify environment
pip list

# 3. Reinstall dependencies
pip install -r requirements.txt --force-reinstall

# 4. Add project to Python path
export PYTHONPATH="${PYTHONPATH}:$(pwd)"  # Linux/Mac
set PYTHONPATH=%PYTHONPATH%;%CD%  # Windows
```

---

## Next Steps

### Learn More

**Documentation:**
- [API Reference](../api/API_REFERENCE.md) - Complete API documentation
- [Game Systems](../architecture/GAME_SYSTEMS.md) - System architecture
- [Development Workflow](../current/guides/DEVELOPMENT_WORKFLOW.md) - Detailed workflow
- [Testing Guide](../TESTING_GUIDE.md) - Comprehensive testing guide

**Tutorials:**
- [Video Tutorial](../current/guides/VIDEO_TUTORIAL_SCRIPT.md)
- [Quick Start Guide](../current/guides/QUICK_START.md)
- [VR Setup](../current/guides/VR_SETUP_GUIDE.md)

**Examples:**
- `examples/` directory - Python client examples
- `scenes/` directory - Example scenes

### Join the Community

- **Discord:** [Join our Discord](https://discord.gg/spacetime)
- **GitHub Discussions:** [Ask questions](https://github.com/your-org/spacetime-vr/discussions)
- **Issue Tracker:** [Report bugs](https://github.com/your-org/spacetime-vr/issues)

### Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for:
- Code style guidelines
- Pull request process
- Review guidelines
- Community standards

---

## Quick Reference

### Essential Commands

```bash
# Start development server
python godot_editor_server.py --port 8090

# Check status
curl http://localhost:8080/status

# Run tests
python tests/test_runner.py

# Monitor telemetry
python telemetry_client.py

# Activate Python environment
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/Mac
```

### Essential Godot Shortcuts

- **F5:** Run project
- **F6:** Run current scene
- **F7:** Step into (debugger)
- **F8:** Toggle breakpoint
- **Ctrl+S:** Save
- **Ctrl+D:** Duplicate node/line
- **Ctrl+Shift+F:** Search in files

### Getting Help

**In-Project Help:**
```bash
# Check project status
python check_status.py

# Run diagnostic
python tests/health_monitor.py

# View documentation
# Open docs/README.md in browser
```

**External Resources:**
- [Godot Documentation](https://docs.godotengine.org/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [OpenXR Documentation](https://www.khronos.org/openxr/)

---

**Last Updated:** 2025-12-02
**Version:** 2.5.0

**Welcome to SpaceTime VR development! Happy coding!**
