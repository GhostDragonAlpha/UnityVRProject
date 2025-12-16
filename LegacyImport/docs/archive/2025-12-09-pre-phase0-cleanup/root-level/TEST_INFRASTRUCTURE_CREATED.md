# Test Infrastructure Created

This document summarizes the three new test infrastructure files created for the SpaceTime VR project.

**Created:** 2025-12-04
**Location:** `C:/godot/tests/`

---

## 1. Test Runner (`tests/test_runner.py`)

**Purpose:** Automated test suite runner that discovers and executes all test types with parallel execution support.

### Features
- Discovers GDScript tests (GdUnit4), Python tests, and property-based tests
- Parallel test execution for faster CI/CD pipelines
- Colored output with pass/fail counts
- Exit codes for CI/CD integration (0=pass, 1=fail)
- Filter tests by name pattern
- Configurable timeouts
- Verbose debug mode

### Usage Examples

```bash
# Run all tests with default settings
python tests/test_runner.py

# Run with verbose output
python tests/test_runner.py --verbose

# Filter tests by name (e.g., only voxel tests)
python tests/test_runner.py --filter voxel

# Run with custom timeout (300 seconds)
python tests/test_runner.py --timeout 300

# Run tests in parallel with 4 workers
python tests/test_runner.py --parallel --workers 4

# Run only GDScript tests
python tests/test_runner.py --gdscript-only

# Run only Python tests
python tests/test_runner.py --python-only

# Disable colored output (for CI/CD)
python tests/test_runner.py --no-color
```

### Exit Codes
- `0` - All tests passed
- `1` - One or more tests failed
- `2` - Test runner error (setup/configuration issues)

### Test Discovery
The test runner automatically discovers:
- **GDScript tests:** `tests/unit/test_*.gd` (requires GdUnit4)
- **Python tests:** `tests/test_*.py` (excluding test_runner.py itself)
- **Property tests:** `tests/property/test_*.py` (requires pytest)

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Run test suite
  run: |
    python tests/test_runner.py --no-color --parallel
```

---

## 2. Health Monitor (`tests/health_monitor.py`)

**Purpose:** Real-time health monitoring during development with continuous refresh and alerting.

### Features
- Monitors Godot process (PID, status, uptime, CPU, memory)
- Checks API endpoints (8080, 8081, 8087)
- Tracks scene loading status
- Monitors player spawn state
- Validates autoload subsystems
- Configurable refresh interval
- Alert on failures with threshold detection
- Single-check or continuous monitoring mode

### Usage Examples

```bash
# Continuous monitoring with 5-second refresh (default)
python tests/health_monitor.py

# Custom refresh interval (10 seconds)
python tests/health_monitor.py --interval 10

# Single health check (no loop)
python tests/health_monitor.py --once

# Verbose output with detailed information
python tests/health_monitor.py --verbose

# Custom server URL
python tests/health_monitor.py --server http://localhost:8090

# Disable colored output
python tests/health_monitor.py --no-color
```

### Exit Codes (--once mode)
- `0` - All systems healthy
- `1` - One or more systems unhealthy

### Monitored Components
1. **Godot Process**
   - Process status (running, zombie, etc.)
   - CPU usage percentage
   - Memory usage (MB)
   - Uptime tracking
   - PID identification

2. **Python Server** (port 8090)
   - Health endpoint response
   - Connection status

3. **Godot HTTP API** (port 8080)
   - Status endpoint response
   - API availability

4. **Telemetry WebSocket** (port 8081)
   - Port availability
   - Connection readiness

5. **Scene Status**
   - Scene loaded state
   - Current scene path

6. **Player Status**
   - Player spawned state
   - Player node existence

### Development Workflow

```bash
# Terminal 1: Start Godot with debug services
python godot_editor_server.py --port 8090 --auto-load-scene

# Terminal 2: Monitor health continuously
python tests/health_monitor.py

# Terminal 3: Make code changes and observe health
# (Health monitor will show any issues in real-time)
```

### Quick Health Check Script

```bash
# Add to your development scripts
if python tests/health_monitor.py --once; then
    echo "System healthy - proceeding with tests"
    python tests/test_runner.py
else
    echo "System unhealthy - please check Godot"
    exit 1
fi
```

---

## 3. Feature Validator (`tests/feature_validator.py`)

**Purpose:** Feature validation and regression testing for major SpaceTime VR features.

### Features
- Validates core features work correctly
- Checks for regressions before commits
- JSON report generation for CI/CD
- Pre-commit hook mode (fast checks)
- CI/CD mode (strict validation)
- Per-feature validation
- Detailed error reporting

### Validated Features
1. **HTTP API** - REST API on port 8080
2. **Telemetry** - WebSocket on port 8081
3. **Core Engine** - ResonanceEngine autoload
4. **Autoloads** - All subsystem initialization
5. **Scene Loading** - Scene management
6. **Player Spawn** - Player node creation
7. **Physics Engine** - Physics subsystem
8. **VR Initialization** - VR system setup

### Usage Examples

```bash
# Validate all features
python tests/feature_validator.py

# Validate specific feature
python tests/feature_validator.py --feature vr
python tests/feature_validator.py --feature http_api

# Generate JSON report
python tests/feature_validator.py --json validation_report.json

# Pre-commit hook mode (fast, essential checks)
python tests/feature_validator.py --hook

# CI/CD mode (strict validation)
python tests/feature_validator.py --ci

# Verbose output with details
python tests/feature_validator.py --verbose

# Custom timeout (60 seconds)
python tests/feature_validator.py --timeout 60

# Custom server URL
python tests/feature_validator.py --server http://localhost:8090
```

### Exit Codes
- `0` - All features validated successfully
- `1` - One or more features failed validation
- `2` - Validation error (setup issues)

### Pre-Commit Hook Setup

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run feature validation before commit

echo "Running feature validation..."
python tests/feature_validator.py --hook

if [ $? -ne 0 ]; then
    echo "Feature validation failed - commit aborted"
    exit 1
fi

echo "Feature validation passed - proceeding with commit"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Validate features
  run: |
    python tests/feature_validator.py --ci --json validation_report.json

- name: Upload validation report
  uses: actions/upload-artifact@v3
  with:
    name: validation-report
    path: validation_report.json
```

### JSON Report Format

```json
{
  "timestamp": "2025-12-04T12:34:56.789",
  "passed": 7,
  "failed": 1,
  "total": 8,
  "features": [
    {
      "feature": "http_api",
      "passed": true,
      "message": "HTTP API responding correctly",
      "details": {...},
      "timestamp": "2025-12-04T12:34:56.789",
      "duration": 0.234
    },
    ...
  ]
}
```

---

## Integration with Existing Infrastructure

All three tools integrate seamlessly with the existing SpaceTime VR infrastructure:

### With Python Server (`godot_editor_server.py`)
All tools connect to the Python server on port 8090 by default, which proxies to Godot's HTTP API on port 8080. This provides a stable interface layer.

### With Telemetry (`telemetry_client.py`)
The health monitor and feature validator check telemetry WebSocket availability on port 8081.

### With Existing Tests
- Test runner discovers and executes existing tests in `tests/unit/` and `tests/`
- Compatible with existing `test_bug_fixes_runtime.py`
- Works with GdUnit4 tests (`test_voxel_terrain.gd`, etc.)

---

## Quick Reference

| Tool | Purpose | Default Behavior | Common Use Case |
|------|---------|------------------|-----------------|
| `test_runner.py` | Run all tests | Sequential execution | `python tests/test_runner.py --parallel` |
| `health_monitor.py` | Monitor system | Continuous 5s refresh | `python tests/health_monitor.py` |
| `feature_validator.py` | Validate features | Check all features | `python tests/feature_validator.py` |

---

## Dependencies

All tools require:
- **Python 3.8+** (project uses Python 3.11.9)
- **requests** library (`pip install requests`)
- **psutil** library for health monitor (`pip install psutil`)

For GDScript tests:
- **GdUnit4** addon installed in `addons/gdUnit4/`
- **Godot 4.5+** executable

For property tests:
- **pytest** and **hypothesis** (`pip install pytest hypothesis`)

---

## Common Workflows

### Development Workflow
```bash
# Terminal 1: Start services
python godot_editor_server.py --port 8090 --auto-load-scene

# Terminal 2: Monitor health
python tests/health_monitor.py

# Terminal 3: Run tests after changes
python tests/test_runner.py --filter my_feature
```

### Pre-Commit Workflow
```bash
# Before committing code
python tests/feature_validator.py --hook
python tests/test_runner.py --filter my_feature

# If all pass, commit
git commit -m "Add new feature"
```

### CI/CD Workflow
```bash
# In CI pipeline
python tests/health_monitor.py --once  # Verify setup
python tests/feature_validator.py --ci --json report.json
python tests/test_runner.py --parallel --no-color
```

---

## Troubleshooting

### Test Runner Issues
- **GdUnit4 not found:** Install with `cd addons && git clone https://github.com/MikeSchulze/gdUnit4.git`
- **Godot not found:** Ensure Godot executable is in project or PATH
- **Tests timeout:** Increase with `--timeout 300`

### Health Monitor Issues
- **Process not found:** Ensure Godot is running with `--editor` flag
- **API not responding:** Check Godot started successfully and autoloads initialized
- **High CPU warning:** Normal during scene loading, should settle down

### Feature Validator Issues
- **Connection refused:** Start Python server with `python godot_editor_server.py`
- **Autoloads missing:** Check project.godot autoload configuration
- **Scene not loaded:** Use `--auto-load-scene` flag when starting server

---

## Support and Documentation

- **CLAUDE.md:** Project overview and development commands
- **DEVELOPMENT_WORKFLOW.md:** Complete development workflow guide
- **Test files:** See individual test files for specific feature testing

For questions or issues, refer to the inline documentation in each Python file (all have comprehensive docstrings and help text).
