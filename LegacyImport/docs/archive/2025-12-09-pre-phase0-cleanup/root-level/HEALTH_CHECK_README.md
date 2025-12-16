# SpaceTime System Health Check

**Location:** `C:/godot/system_health_check.py`

A comprehensive automated health check script for the SpaceTime VR project that validates system configuration, HTTP API functionality, file integrity, and port configurations.

## Overview

This production-ready health check script performs 12+ automated checks across 5 categories:

1. **Port Configuration** - Validates active and legacy port usage
2. **HTTP API (Port 8080)** - Tests HTTP API endpoints and responses
3. **Autoload Configuration** - Verifies Godot autoload definitions
4. **File Integrity** - Checks critical files and basic GDScript syntax
5. **Legacy System Migration** - Validates migration from port 8082 to 8080

## Features

- ✅ Comprehensive validation of HTTP API on port 8080
- ✅ Autoload configuration verification (all 5 autoloads)
- ✅ Critical file existence and integrity checks
- ✅ Port migration validation (8082 → 8080)
- ✅ GDScript basic syntax checking
- ✅ Color-coded console output with clear status indicators
- ✅ JSON report generation for CI/CD integration
- ✅ HTML report generation for web viewing
- ✅ Proper error handling and timeouts
- ✅ Windows console compatibility (no Unicode issues)

## Quick Start

### Basic Usage

```bash
# Run all checks (requires Godot running)
python system_health_check.py

# Run offline checks only (skip HTTP API tests)
python system_health_check.py --skip-http

# Verbose output with detailed information
python system_health_check.py --verbose
```

### Generate Reports

```bash
# Generate JSON report for CI/CD
python system_health_check.py --json-report health.json

# Generate HTML report for web viewing
python system_health_check.py --html-report health.html

# Generate both reports
python system_health_check.py --json-report health.json --html-report health.html
```

### Advanced Options

```bash
# Disable colored output (for log files)
python system_health_check.py --no-color

# Custom timeout for HTTP requests
python system_health_check.py --timeout 30

# Specify custom project root
python system_health_check.py --project-root /path/to/project

# Combine options
python system_health_check.py --skip-http --no-color --json-report ci_health.json
```

## Exit Codes

- **0** - All checks passed
- **1** - One or more checks failed

Perfect for CI/CD integration:

```bash
python system_health_check.py --skip-http --json-report health.json
if [ $? -eq 0 ]; then
    echo "Health check passed!"
else
    echo "Health check failed!"
    exit 1
fi
```

## Checks Performed

### 1. Port Configuration

| Check | Description | Expected Result |
|-------|-------------|-----------------|
| Port 8080 Listening | Verifies HTTP API server is active | Port is listening |
| Port 8082 References | Scans for legacy port references | No active file references |
| Port 8081 WebSocket | Validates WebSocket telemetry port | Properly referenced |

### 2. HTTP API (Port 8080)

| Endpoint | Method | Check |
|----------|--------|-------|
| `/status` | GET | Response validation and JSON format |
| `/scene` | GET | Endpoint accessibility (200 or 404) |
| `/scenes` | GET | Scene list availability (200 or 401) |

**Note:** HTTP checks require Godot running with HTTP API enabled. Use `--skip-http` for offline validation.

### 3. Autoload Configuration

| Check | Description |
|-------|-------------|
| Autoloads Defined | All 5 autoloads present in project.godot |
| Script Files Exist | All autoload scripts exist on filesystem |
| Circular Dependencies | No obvious circular dependency patterns |

**Expected Autoloads:**
- `ResonanceEngine` → `scripts/core/engine.gd`
- `HttpApiServer` → `scripts/http_api/http_api_server.gd`
- `SceneLoadMonitor` → `scripts/http_api/scene_load_monitor.gd`
- `SettingsManager` → `scripts/core/settings_manager.gd`
- `VoxelPerformanceMonitor` → `scripts/core/voxel_performance_monitor.gd`

### 4. File Integrity

| Check | Description |
|-------|-------------|
| Critical Files Exist | 8 critical project files verified |
| GDScript Syntax | Basic syntax validation (braces, brackets, parens) |
| Main Scene Configuration | Main scene defined and file exists |

**Critical Files Checked:**
- `project.godot`
- `vr_main.tscn`
- `minimal_test.tscn`
- `scripts/core/engine.gd`
- `scripts/http_api/http_api_server.gd`
- `scripts/http_api/scene_load_monitor.gd`
- `CLAUDE.md`
- `README.md`

### 5. Legacy System Migration

| Check | Description |
|-------|-------------|
| GodotBridge Disabled | Legacy GodotBridge autoload is commented out |
| Active vs Legacy Ports | Port 8080 is primary, 8082 is minimal |

## Output Examples

### Console Output (Success)

```
================================================================================
SpaceTime System Health Check
================================================================================

Project Root: C:\godot
Timestamp: 2025-12-04 00:56:35

...

================================================================================
Health Check Summary
================================================================================

Total Checks: 12
[OK] Passed: 12

Duration: 2.92s

================================================================================
Detailed Results
================================================================================

[OK] Port 8080 Listening: PASSED
   Port 8080 is listening (HTTP API server active)
[OK] Port 8082 References (Legacy): PASSED
   No port 8082 references found in active files (migration complete)
...

[OK] All checks passed!
```

### Console Output (Failure)

```
[FAIL] Port 8080 Listening: FAILED
   Port 8080 is NOT listening. Is Godot running with HTTP API enabled?
[WARN] Port 8082 References (Legacy): WARNING
   Found 4 active files with port 8082 references

...

[FAIL] Health check failed with 1 error(s)
```

### JSON Report Structure

```json
{
  "timestamp": "2025-12-04T00:56:35.566196",
  "total_checks": 12,
  "passed": 9,
  "failed": 1,
  "warnings": 1,
  "skipped": 1,
  "duration_seconds": 2.92,
  "checks": [
    {
      "name": "Port 8080 Listening",
      "status": "failed",
      "message": "Port 8080 is NOT listening...",
      "details": {
        "port": 8080,
        "host": "127.0.0.1",
        "error_code": 10035
      },
      "timestamp": "2025-12-04T00:56:34.645352"
    }
  ]
}
```

### HTML Report

The HTML report provides a beautiful, web-based dashboard with:
- Color-coded summary statistics
- Expandable check details
- Professional styling with gradients
- Responsive layout
- Embedded JSON details for debugging

Open `health_report.html` in any modern browser to view.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Health Check
on: [push, pull_request]

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Health Check
        run: |
          python system_health_check.py --skip-http --json-report health.json
      - name: Upload Report
        uses: actions/upload-artifact@v3
        with:
          name: health-report
          path: health.json
```

### Jenkins Pipeline Example

```groovy
stage('Health Check') {
    steps {
        sh 'python system_health_check.py --skip-http --json-report health.json'
        archiveArtifacts artifacts: 'health.json', fingerprint: true
    }
}
```

## Troubleshooting

### Port 8080 Not Listening

**Problem:** "Port 8080 is NOT listening"

**Solutions:**
1. Start Godot with HTTP API enabled:
   ```bash
   python godot_editor_server.py --port 8090
   ```
2. Verify HttpApiServer autoload is enabled in `project.godot`
3. Check if another process is using port 8080:
   ```bash
   netstat -ano | findstr :8080
   ```

### Port 8082 Legacy References

**Problem:** "Found N active files with port 8082 references"

**Solutions:**
1. Review the files listed in the warning details
2. Most references should be in `.bak` or documentation files
3. Update any active code files to use port 8080
4. References in `CLAUDE.md` or migration docs are acceptable

### Autoload Missing

**Problem:** "Missing N autoload(s) in project.godot"

**Solutions:**
1. Check `project.godot` has the `[autoload]` section
2. Verify autoload definitions are not commented out
3. Ensure autoload definitions use correct format:
   ```ini
   AutoloadName="*res://path/to/script.gd"
   ```

### Script File Not Found

**Problem:** "Missing N autoload script file(s)"

**Solutions:**
1. Verify the file exists at the specified path
2. Check for typos in the path
3. Ensure file permissions are correct
4. Check if file was accidentally deleted or moved

## Configuration

The health check script has sensible defaults but can be customized:

```python
# In system_health_check.py

# Default timeout for HTTP requests (seconds)
DEFAULT_TIMEOUT = 10

# Expected autoloads
EXPECTED_AUTOLOADS = {
    "ResonanceEngine": "res://scripts/core/engine.gd",
    "HttpApiServer": "res://scripts/http_api/http_api_server.gd",
    # ...
}

# Critical files to check
CRITICAL_FILES = [
    "project.godot",
    "vr_main.tscn",
    # ...
]
```

## Development

### Adding New Checks

To add a new health check:

1. Create a new method in `SystemHealthChecker` class:
   ```python
   def check_my_new_feature(self):
       """Check description"""
       check_name = "My New Feature"

       try:
           # Perform check logic
           if success:
               self.results.append(CheckResult(
                   name=check_name,
                   status=CheckStatus.PASSED,
                   message="Check passed",
                   details={"key": "value"}
               ))
           else:
               self.results.append(CheckResult(
                   name=check_name,
                   status=CheckStatus.FAILED,
                   message="Check failed",
                   details={"error": "reason"}
               ))
       except Exception as e:
           self.results.append(CheckResult(
               name=check_name,
               status=CheckStatus.FAILED,
               message=f"Unexpected error: {str(e)}",
               details={"error": str(e)}
           ))
   ```

2. Add the check to `run_all_checks()` method:
   ```python
   def run_all_checks(self, skip_http: bool = False):
       # ...
       print_header("6. My New Category")
       self.check_my_new_feature()
       # ...
   ```

### Testing

Test the health check script:

```bash
# Test basic functionality
python system_health_check.py --skip-http

# Test with verbose output
python system_health_check.py --skip-http --verbose

# Test report generation
python system_health_check.py --skip-http --json-report test.json --html-report test.html

# Test with no colors (for CI/CD)
python system_health_check.py --skip-http --no-color
```

## Support

For issues or questions:

1. Check this README for troubleshooting tips
2. Review `CLAUDE.md` for project architecture
3. Check the generated reports for detailed diagnostics
4. Review the health check script source code for implementation details

## Version History

- **v1.0.0** (2025-12-04)
  - Initial release
  - 12 comprehensive checks across 5 categories
  - JSON and HTML report generation
  - Windows console compatibility
  - CI/CD ready with exit codes
  - Production error handling and timeouts

## License

Part of the SpaceTime VR project. See project LICENSE file.
