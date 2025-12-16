# SpaceTime VR - Production Build Guide

**Document Version:** 1.0
**Created:** 2025-12-04
**Godot Version:** 4.5.1-stable
**Build Target:** Windows Desktop (x86_64)

---

## Table of Contents

1. [Overview](#overview)
2. [Export Configuration](#export-configuration)
3. [Building for Production](#building-for-production)
4. [Build Validation](#build-validation)
5. [Testing Exported Build](#testing-exported-build)
6. [Deployment Package Structure](#deployment-package-structure)
7. [Expected Results](#expected-results)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Deployment Checklist](#deployment-checklist)

---

## Overview

This guide provides complete instructions for exporting, validating, and deploying the SpaceTime VR production build. All necessary scripts have been created and tested.

**Build Artifacts Location:** `C:/godot/build/`

**Created Scripts:**
- `export_production_build.bat` / `.sh` - Automated export with validation
- `validate_build.py` - Comprehensive build validation
- `test_exported_build.bat` / `.sh` - Interactive testing procedure

---

## Export Configuration

The export configuration is already set up in `export_presets.cfg`:

### Current Configuration

```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_path="build/SpaceTime.exe"
binary_format/architecture="x86_64"
debug/export_console_wrapper=1
binary_format/embed_pck=false
```

### Key Settings

| Setting | Value | Description |
|---------|-------|-------------|
| **Platform** | Windows Desktop | Target platform |
| **Architecture** | x86_64 | 64-bit Windows |
| **Export Path** | build/SpaceTime.exe | Output location |
| **PCK Mode** | Separate | PCK file separate from EXE |
| **Console Wrapper** | Enabled | Shows console output for debugging |

### Production-Ready Features

- ✓ 64-bit executable (x86_64)
- ✓ Texture compression optimized (BPTC, S3TC enabled)
- ✓ Console wrapper for debugging
- ✓ Separate PCK for easy updates
- ✓ All resources included
- ✓ Release optimization enabled

---

## Building for Production

### Prerequisites

1. **Godot Engine 4.5.1+** installed at one of:
   - `C:/godot/Godot_v4.5.1-stable_win64.exe/`
   - `C:/Program Files/Godot/`
   - `C:/Godot/`

2. **Export templates** installed:
   - Download from Godot: Editor > Manage Export Templates
   - Or download from: https://godotengine.org/download

3. **Disk space**: At least 500 MB free for build artifacts

### Export Process

#### Option 1: Windows (Batch Script)

```batch
cd C:\godot
export_production_build.bat
```

**What it does:**
1. Locates Godot executable
2. Verifies export preset configuration
3. Backs up previous build (to `build/backups/`)
4. Runs headless export with release optimization
5. Validates build artifacts
6. Generates SHA256 checksums
7. Creates build metadata file

**Expected Output:**
```
========================================
 SpaceTime VR - Production Build Export
========================================

Build Timestamp: 20251204_143022

[1/6] Locating Godot executable...
   Found: C:\godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe

[2/6] Verifying export configuration...
   Export preset 'Windows Desktop' found

[3/6] Managing build artifacts...
   Backing up previous build...
   Previous build backed up to: build\backups\SpaceTime_20251204_143022.exe

[4/6] Exporting production build...
   This may take 1-3 minutes depending on project size...
   Export completed successfully!

[5/6] Verifying build artifacts...
   Found: SpaceTime.exe (96625152 bytes)
   Found: SpaceTime.pck (149152 bytes)

[6/6] Generating checksums...
   SHA256 checksum saved to: build\SpaceTime.exe.sha256
   SHA256 checksum saved to: build\SpaceTime.pck.sha256

========================================
 BUILD EXPORT COMPLETED SUCCESSFULLY!
========================================
```

#### Option 2: Linux/Mac/Git Bash (Shell Script)

```bash
cd /c/godot
./export_production_build.sh
```

Same functionality as batch script but for Unix-like environments.

#### Option 3: Manual Export (Godot Editor)

If scripts fail, you can export manually:

1. Open Godot Editor
2. Load project: `C:/godot/project.godot`
3. Go to: **Project > Export**
4. Select: **Windows Desktop**
5. Click: **Export Project**
6. Save as: `C:/godot/build/SpaceTime.exe`
7. Ensure "Export With Debug" is **unchecked** (release mode)

---

## Build Validation

After export, validate the build to ensure deployment readiness.

### Automated Validation

```bash
cd C:\godot
python validate_build.py
```

### What Gets Validated

The validation script performs comprehensive checks:

#### 1. Executable Validation
- ✓ File exists
- ✓ Minimum size check (> 10 MB expected)
- ✓ Valid PE (Portable Executable) format
- ✓ Correct architecture (x86_64)
- ✓ GDPC signature present (PCK data)

#### 2. PCK Validation
- ✓ File exists (or embedded in EXE)
- ✓ Valid GDPC header
- ✓ Reasonable file size (> 100 KB)
- ✓ Version information readable

#### 3. Checksum Verification
- ✓ SHA256 checksums match stored values
- ✓ Creates checksums if missing
- ✓ Detects file corruption

#### 4. Dependency Check
- ✓ Lists required DLLs (if any)
- ✓ Checks for voxel plugin DLL
- ✓ Validates external dependencies

#### 5. Export Log Review
- ✓ Parses export log for errors
- ✓ Counts and displays warnings
- ✓ Highlights critical issues

### Expected Validation Output

```
============================================================
           SpaceTime VR - Build Validation
============================================================

Validating build in: C:\godot\build

============================================================
              Step 1: Validate Executable
============================================================

✓ Executable found: SpaceTime.exe (92.13 MB)
✓ Executable size is reasonable: 92.13 MB
✓ Valid PE executable (Windows)
✓ Architecture: x86_64 (64-bit)
✓ Embedded PCK data detected (GDPC signature found)

============================================================
              Step 2: Validate Data Pack (PCK)
============================================================

✓ Data Pack (PCK) found: SpaceTime.pck (0.14 MB)
✓ Valid Godot PCK file (GDPC signature)
ℹ PCK version: 2
✓ PCK size is reasonable: 0.14 MB

============================================================
                 Step 3: Verify Checksums
============================================================

ℹ Verifying checksums...
✓ Checksum verified: SpaceTime.exe
✓ Checksum verified: SpaceTime.pck

============================================================
               Step 4: Check Dependencies
============================================================

ℹ Checking for required dependencies...
✓ No external DLLs required (all dependencies embedded)
⚠ Voxel plugin DLL not found in build directory
ℹ   This is OK if voxel features are disabled or embedded

============================================================
              Step 5: Review Export Log
============================================================

ℹ Checking export logs...
ℹ Reading log: export_log_20251204_143022.txt
✓ No errors found in export log
✓ No warnings found in export log

============================================================
                  Validation Report
============================================================

============================================================
SpaceTime VR - Build Validation Report
============================================================

VALIDATION SUMMARY
------------------------------------------------------------
✓ Executable: PASS
✓ Data Pack: PASS (separate or embedded)
✓ Checksums: PASS
✓ Export Log: PASS (no errors)

OVERALL STATUS
------------------------------------------------------------
✓ BUILD IS READY FOR DEPLOYMENT

DETAILED INFORMATION
------------------------------------------------------------
Build directory: C:\godot\build
Executable size: 92.13 MB
PCK size: 0.14 MB

============================================================

✓ Validation report saved to: C:\godot\build\VALIDATION_REPORT.txt

✓ Build validation PASSED!
```

### Validation Failure Scenarios

If validation fails, you'll see specific error messages:

**Example: Missing Executable**
```
✗ Executable not found: C:\godot\build\SpaceTime.exe
✗ Executable: FAIL
✗ BUILD FAILED VALIDATION
```

**Example: Export Errors**
```
✗ Export log contains 3 error(s):
  ERROR: Failed to load resource
  ERROR: Script compilation failed
  ERROR: Missing export template
✗ Export Log: FAIL (contains errors)
```

---

## Testing Exported Build

### Interactive Testing Procedure

After validation, test the exported build in a runtime environment:

```batch
cd C:\godot
test_exported_build.bat
```

Or on Linux/Mac/Git Bash:
```bash
cd /c/godot
./test_exported_build.sh
```

### What the Test Does

1. **Pre-flight Checks**
   - Verifies build files exist
   - Checks if HTTP API port 8080 is available
   - Sets environment variables for testing

2. **Launch Configuration**
   - Sets `SPACETIME_DEBUG=1` for verbose logging
   - Sets `SPACETIME_LOG_LEVEL=INFO`
   - Configures HTTP API and telemetry ports

3. **Runtime Validation**
   - Launches the executable
   - Waits for process to start
   - Tests HTTP API connectivity
   - Provides manual validation checklist

### Environment Variables

The test script sets these environment variables:

```bash
SPACETIME_DEBUG=1                  # Enable debug output
SPACETIME_LOG_LEVEL=INFO           # Set logging verbosity
SPACETIME_HTTP_API_PORT=8080       # HTTP API port
SPACETIME_TELEMETRY_PORT=8081      # WebSocket telemetry port
```

### Manual Test Commands

Once the build is running, test the HTTP API:

```bash
# Check system status
curl http://127.0.0.1:8080/status

# Check loaded scene
curl http://127.0.0.1:8080/state/scene

# Check player state
curl http://127.0.0.1:8080/state/player

# Check autoload subsystems
curl http://127.0.0.1:8080/state/autoloads
```

### Expected HTTP API Responses

**Status Endpoint:**
```json
{
  "status": "ok",
  "timestamp": "2025-12-04T14:30:45Z",
  "uptime_seconds": 125.3,
  "godot_version": "4.5.1.stable",
  "project": "SpaceTime",
  "platform": "Windows"
}
```

**Scene State Endpoint:**
```json
{
  "current_scene": "res://minimal_test.tscn",
  "scene_loaded": true,
  "scene_tree_ready": true,
  "root_node": "Node3D"
}
```

### VR Testing (If Headset Available)

If you have a VR headset connected:

1. **Before launching:** Ensure headset is connected and runtime is active
2. **Expected behavior:**
   - OpenXR should initialize
   - VR scene should load (vr_main.tscn)
   - Headset should display the VR environment
   - Controllers should be tracked

3. **VR validation commands:**
```bash
# Check VR status
curl http://127.0.0.1:8080/vr/status

# Expected response
{
  "vr_enabled": true,
  "vr_runtime": "OpenXR",
  "headset_connected": true,
  "tracking_active": true
}
```

---

## Deployment Package Structure

### Minimal Deployment Package

For basic deployment, you need:

```
SpaceTime-Release-v1.0/
├── SpaceTime.exe          # Main executable (93 MB)
├── SpaceTime.pck          # Game data (0.15 MB)
├── README.txt             # User instructions
└── LICENSE.txt            # License information
```

### Complete Deployment Package

For production deployment with all files:

```
SpaceTime-Release-v1.0/
├── SpaceTime.exe                    # Main executable
├── SpaceTime.pck                    # Game data
├── SpaceTime.exe.sha256             # Checksum for verification
├── SpaceTime.pck.sha256             # Checksum for verification
├── BUILD_INFO.txt                   # Build metadata
├── VALIDATION_REPORT.txt            # Validation results
├── README.txt                       # User instructions
├── LICENSE.txt                      # License
├── CHANGELOG.md                     # Version history
├── docs/                            # Documentation
│   ├── USER_GUIDE.md
│   ├── VR_SETUP.md
│   └── TROUBLESHOOTING.md
└── prerequisites/                   # Optional dependencies
    └── vcredist_x64.exe            # Visual C++ Redistributable (if needed)
```

### Creating Deployment Package

**Windows (PowerShell):**
```powershell
# Create deployment directory
New-Item -ItemType Directory -Path "C:\godot\deploy\SpaceTime-Release-v1.0"

# Copy build artifacts
Copy-Item "C:\godot\build\SpaceTime.exe" -Destination "C:\godot\deploy\SpaceTime-Release-v1.0\"
Copy-Item "C:\godot\build\SpaceTime.pck" -Destination "C:\godot\deploy\SpaceTime-Release-v1.0\"
Copy-Item "C:\godot\build\*.sha256" -Destination "C:\godot\deploy\SpaceTime-Release-v1.0\"
Copy-Item "C:\godot\build\BUILD_INFO.txt" -Destination "C:\godot\deploy\SpaceTime-Release-v1.0\"

# Create archive
Compress-Archive -Path "C:\godot\deploy\SpaceTime-Release-v1.0" -DestinationPath "C:\godot\deploy\SpaceTime-Release-v1.0.zip"
```

**Linux/Mac/Bash:**
```bash
# Create deployment directory
mkdir -p "/c/godot/deploy/SpaceTime-Release-v1.0"

# Copy build artifacts
cp "/c/godot/build/SpaceTime.exe" "/c/godot/deploy/SpaceTime-Release-v1.0/"
cp "/c/godot/build/SpaceTime.pck" "/c/godot/deploy/SpaceTime-Release-v1.0/"
cp "/c/godot/build/"*.sha256 "/c/godot/deploy/SpaceTime-Release-v1.0/"
cp "/c/godot/build/BUILD_INFO.txt" "/c/godot/deploy/SpaceTime-Release-v1.0/"

# Create archive
cd "/c/godot/deploy"
zip -r "SpaceTime-Release-v1.0.zip" "SpaceTime-Release-v1.0"
```

### File Size Reference

Based on current build:

| File | Size | Required |
|------|------|----------|
| SpaceTime.exe | ~92 MB | Yes |
| SpaceTime.pck | ~0.15 MB | Yes |
| *.sha256 | ~1 KB each | Recommended |
| BUILD_INFO.txt | ~1 KB | Recommended |
| Documentation | Variable | Optional |

**Total minimal package size:** ~93 MB
**Total complete package size:** ~95 MB + documentation

---

## Expected Results

### Successful Export Indicators

✓ **Exit Code:** Export script returns 0
✓ **Log Output:** "Export completed successfully!"
✓ **Files Created:**
  - `build/SpaceTime.exe` (> 90 MB)
  - `build/SpaceTime.pck` (> 100 KB)
  - `build/SpaceTime.exe.sha256`
  - `build/SpaceTime.pck.sha256`
  - `build/BUILD_INFO.txt`
  - `build/export_log_*.txt`

✓ **Validation:** All checks pass (green ✓)
✓ **Runtime Test:** Application launches without crashes
✓ **HTTP API:** Responds on port 8080
✓ **Autoloads:** All subsystems initialize successfully

### Performance Expectations

**Startup Time:**
- Cold start: 5-10 seconds
- Scene load: 2-5 seconds
- HTTP API ready: 10-15 seconds after launch

**Runtime Performance:**
- Target FPS: 90 FPS (VR mode)
- Fallback FPS: 60 FPS (desktop mode)
- Physics tick rate: 90 Hz
- Memory usage: 500-800 MB (typical)

**HTTP API Performance:**
- Response time: < 50ms for status endpoints
- Concurrent connections: 10+ supported
- WebSocket telemetry: 30 updates/second

---

## Troubleshooting Guide

### Export Failures

#### Problem: "Godot executable not found"

**Solution:**
1. Verify Godot is installed
2. Update script with correct path:
   ```batch
   set GODOT_EXE=C:\path\to\Godot_v4.5.1-stable_win64.exe
   ```
3. Or set environment variable:
   ```bash
   export GODOT_PATH=/path/to/godot
   ```

#### Problem: "Export preset 'Windows Desktop' not found"

**Solution:**
1. Open Godot Editor
2. Go to: **Project > Export**
3. Click: **Add...** > **Windows Desktop**
4. Configure preset and save
5. Re-run export script

#### Problem: "Missing export templates"

**Solution:**
1. Open Godot Editor
2. Go to: **Editor > Manage Export Templates**
3. Click: **Download and Install**
4. Wait for download to complete
5. Re-run export script

#### Problem: "Export failed with errors"

**Check export log:**
```bash
cat C:\godot\build\export_log_*.txt
```

**Common errors:**
- **Script errors:** Fix GDScript compilation errors in editor
- **Missing resources:** Ensure all assets are in project
- **Invalid scene:** Check main scene path in project.godot
- **Permission denied:** Run as administrator or check file permissions

### Validation Failures

#### Problem: "Executable size too small"

**Possible causes:**
- Export templates not installed correctly
- PCK not embedded and missing separate file
- Export failed but didn't report error

**Solution:**
1. Re-install export templates
2. Verify `export_presets.cfg` settings
3. Re-run export with verbose logging

#### Problem: "Checksum mismatch"

**Possible causes:**
- File was modified after export
- Corruption during copy/transfer
- Antivirus interference

**Solution:**
1. Re-export the build
2. Disable antivirus temporarily
3. Regenerate checksums:
   ```bash
   certutil -hashfile SpaceTime.exe SHA256 > SpaceTime.exe.sha256
   ```

#### Problem: "PCK not found and not embedded"

**Possible causes:**
- Export failed to create PCK
- PCK file deleted or moved
- Incorrect export preset configuration

**Solution:**
1. Check `export_presets.cfg`: `binary_format/embed_pck=false`
2. Ensure export completed successfully
3. Check for PCK file: `ls build/SpaceTime.pck`

### Runtime Failures

#### Problem: "Application crashes on startup"

**Debugging steps:**
1. Check console output (use console wrapper version)
2. Look for error messages in Windows Event Viewer
3. Test with debug build:
   ```bash
   godot --path C:\godot --verbose
   ```
4. Check dependencies:
   ```bash
   dumpbin /dependents SpaceTime.exe
   ```

**Common causes:**
- Missing Visual C++ Redistributable
- Incompatible graphics drivers
- Corrupted build files
- Autoload initialization failure

#### Problem: "HTTP API not responding"

**Debugging steps:**
1. Check if port 8080 is available:
   ```bash
   netstat -ano | findstr :8080
   ```
2. Check firewall settings:
   ```bash
   netsh advfirewall firewall show rule name=all | findstr 8080
   ```
3. Check console output for HTTP API errors
4. Verify HttpApiServer autoload is enabled in project.godot

**Solution:**
1. Use different port: Set `SPACETIME_HTTP_API_PORT=8090`
2. Add firewall exception
3. Check if HTTP API is compiled into build

#### Problem: "VR not working"

**Debugging steps:**
1. Verify headset is connected: Check OpenXR runtime
2. Check VR initialization in console output
3. Test VR status endpoint:
   ```bash
   curl http://127.0.0.1:8080/vr/status
   ```

**Common causes:**
- OpenXR runtime not installed
- Headset not connected
- VR drivers outdated
- OpenXR not enabled in export preset

**Solution:**
1. Install OpenXR runtime (SteamVR, Oculus, etc.)
2. Update headset firmware and drivers
3. Verify `project.godot`: `xr/openxr/enabled=true`

### Performance Issues

#### Problem: "Low FPS / stuttering"

**Check performance metrics:**
```bash
curl http://127.0.0.1:8080/performance/metrics
```

**Possible causes:**
- Graphics settings too high for hardware
- VSync disabled (causing tearing)
- Background processes consuming resources
- Memory leak in scripts

**Solution:**
1. Lower quality settings in game
2. Update graphics drivers
3. Close background applications
4. Monitor memory usage: Task Manager > Details > SpaceTime.exe

#### Problem: "High memory usage"

**Normal memory usage:**
- Startup: 200-300 MB
- Running: 500-800 MB
- VR mode: 800-1200 MB

**If memory > 2 GB:**
1. Check for memory leaks in scripts
2. Review procedural generation (may be creating too many objects)
3. Check telemetry for node count:
   ```bash
   curl http://127.0.0.1:8080/state/tree_stats
   ```

---

## Deployment Checklist

Use this checklist before deploying to production or distribution:

### Pre-Export Checklist

- [ ] All features tested in development
- [ ] No critical bugs in issue tracker
- [ ] Code reviewed and approved
- [ ] Version number updated in project.godot
- [ ] CHANGELOG.md updated with release notes
- [ ] Export presets configured correctly
- [ ] Export templates installed (4.5.1-stable)
- [ ] Backup of previous stable build created

### Export Checklist

- [ ] Run export script: `export_production_build.bat` or `.sh`
- [ ] No errors in export log
- [ ] Build artifacts created successfully
- [ ] Checksums generated
- [ ] Build metadata created (BUILD_INFO.txt)
- [ ] Export log reviewed for warnings

### Validation Checklist

- [ ] Run validation script: `python validate_build.py`
- [ ] Executable validation: PASS
- [ ] PCK validation: PASS
- [ ] Checksum verification: PASS
- [ ] Dependency check: PASS
- [ ] Export log review: PASS
- [ ] Overall status: READY FOR DEPLOYMENT

### Testing Checklist

- [ ] Run test script: `test_exported_build.bat` or `.sh`
- [ ] Application window opens successfully
- [ ] No crash messages or errors in console
- [ ] Scene loads correctly (minimal_test.tscn or vr_main.tscn)
- [ ] HTTP API responds: `curl http://127.0.0.1:8080/status`
- [ ] All autoloads initialized successfully
- [ ] VR system initialized (if applicable)
- [ ] Application closes normally without errors
- [ ] No memory leaks observed
- [ ] Performance meets targets (60/90 FPS)

### Packaging Checklist

- [ ] Deployment directory created
- [ ] Executable copied to package
- [ ] PCK file copied to package
- [ ] Checksums included
- [ ] Build metadata included
- [ ] README/documentation included
- [ ] License information included
- [ ] Prerequisites documented (if needed)
- [ ] Archive created (.zip or installer)
- [ ] Archive integrity verified

### Distribution Checklist

- [ ] Build uploaded to distribution server
- [ ] Download link tested and working
- [ ] Checksum posted publicly for verification
- [ ] Release notes published
- [ ] Version tagged in source control
- [ ] Backup of build archived
- [ ] Support documentation available
- [ ] Known issues documented
- [ ] Update mechanism tested (if applicable)

### Post-Deployment Checklist

- [ ] Monitor for crash reports
- [ ] Monitor for support requests
- [ ] Track download/installation metrics
- [ ] Gather user feedback
- [ ] Plan hotfix process if needed
- [ ] Update internal documentation
- [ ] Archive build for historical reference
- [ ] Prepare for next release cycle

---

## Additional Resources

### Documentation Files

- **CLAUDE.md** - Project overview and development guide
- **DEVELOPMENT_WORKFLOW.md** - Player-experience-driven workflow
- **README.md** - Project readme and quick start

### Scripts Reference

| Script | Purpose | Platform |
|--------|---------|----------|
| `export_production_build.bat` | Export with validation | Windows |
| `export_production_build.sh` | Export with validation | Linux/Mac/Bash |
| `validate_build.py` | Comprehensive validation | Cross-platform |
| `test_exported_build.bat` | Interactive testing | Windows |
| `test_exported_build.sh` | Interactive testing | Linux/Mac/Bash |

### Key Files

| File | Location | Description |
|------|----------|-------------|
| `export_presets.cfg` | `C:/godot/` | Export configuration |
| `project.godot` | `C:/godot/` | Project settings |
| `SpaceTime.exe` | `C:/godot/build/` | Exported executable |
| `SpaceTime.pck` | `C:/godot/build/` | Game data package |
| `BUILD_INFO.txt` | `C:/godot/build/` | Build metadata |
| `VALIDATION_REPORT.txt` | `C:/godot/build/` | Validation results |

### API Ports

| Service | Port | Protocol | Status |
|---------|------|----------|--------|
| HTTP API | 8080 | HTTP | Active |
| Telemetry | 8081 | WebSocket | Active |
| Discovery | 8087 | UDP | Active |

### Support Contacts

- **Development Team:** [Contact Information]
- **Issue Tracker:** [URL to issue tracker]
- **Documentation:** [URL to documentation]
- **Community:** [URL to community forums/Discord]

---

## Conclusion

All export, validation, and testing infrastructure is now in place. The deployment team can proceed with confidence using the provided scripts and this documentation.

**Next Steps:**
1. Review this document
2. Run export script: `export_production_build.bat`
3. Run validation: `python validate_build.py`
4. Run tests: `test_exported_build.bat`
5. Package for distribution
6. Deploy using deployment checklist

**Questions or Issues?**
- Check the troubleshooting section above
- Review export logs in `build/export_log_*.txt`
- Review validation report in `build/VALIDATION_REPORT.txt`
- Consult development team if issues persist

---

**Document End** - Last Updated: 2025-12-04
