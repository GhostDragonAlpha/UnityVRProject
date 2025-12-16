# Dependency Automation for Production Deployment

**Status: READY FOR USE**

This document describes the automated dependency installation system for SpaceTime production deployment. All scripts are tested and ready to use.

## Overview

The dependency automation system provides foolproof installation of all required dependencies for production deployment:

1. **Godot Export Templates** (4.5.1.stable)
2. **jq JSON Processor** (for JSON parsing in deployment scripts)

## Quick Start

### One-Command Installation (Recommended)

**Windows:**
```bash
scripts\deployment\install_all_dependencies.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/install_all_dependencies.sh
```

This will install ALL dependencies automatically with progress tracking and error handling.

### Quick Status Check

**Windows:**
```bash
scripts\deployment\check_dependencies.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/check_dependencies.sh
```

Shows color-coded status of all dependencies at a glance.

### Full Validation

```bash
python scripts/deployment/validate_dependencies.py
```

Runs comprehensive validation with detailed reporting.

## Script Reference

### 1. Export Templates Installation

**Purpose:** Downloads and installs Godot 4.5.1.stable export templates

**Windows:**
```bash
scripts\deployment\install_export_templates.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/install_export_templates.sh
```

**What it does:**
- Downloads export templates from official Godot releases
- Extracts to correct OS-specific location:
  - Windows: `%APPDATA%\Godot\export_templates\4.5.1.stable\`
  - Mac: `~/Library/Application Support/Godot/export_templates/4.5.1.stable/`
  - Linux: `~/.local/share/godot/export_templates/4.5.1.stable/`
- Verifies installation with essential file checks
- Handles existing installations gracefully
- Provides detailed progress and error messages

**Exit Codes:**
- `0` - Success (templates installed and verified)
- `1` - Failure (check error messages)

**Features:**
- Automatic download with curl
- Extraction with tar (Windows 10+) or 7-Zip (fallback)
- Verification of 4 essential template files
- Size validation to detect download failures
- Interactive reinstallation prompt if already installed

---

### 2. jq Installation

**Purpose:** Installs jq JSON processor for deployment script parsing

**Windows:**
```bash
scripts\deployment\install_jq.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/install_jq.sh
```

**What it does:**
- Checks if jq already available in PATH
- Offers system-wide installation via package managers:
  - Windows: Chocolatey
  - Mac: Homebrew
  - Linux: apt-get, yum, or dnf
- Falls back to direct binary download if needed
- Installs locally in scripts directory as fallback
- Verifies installation with version check and functionality test

**Exit Codes:**
- `0` - Success (jq installed and working)
- `1` - Failure (check error messages)

**Features:**
- Multi-method installation (package manager or direct download)
- Local installation option (no admin rights required)
- Cross-platform compatibility
- Functionality verification with JSON test

---

### 3. Master Installer

**Purpose:** Install all dependencies with one command

**Windows:**
```bash
scripts\deployment\install_all_dependencies.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/install_all_dependencies.sh
```

**What it does:**
- Runs both export templates and jq installers
- Tracks success/failure of each installation
- Provides comprehensive summary report
- Automatically runs quick validation
- Suggests next steps based on results

**Exit Codes:**
- `0` - Success (all dependencies installed)
- `1` - Failure (one or more dependencies failed)

**Output Summary:**
```
Total installations attempted: 2
Successful installations: 2
Failed installations: 0

Detailed Results:
  - Godot Export Templates: SUCCESS
  - jq JSON Processor: SUCCESS
```

---

### 4. Dependency Validator

**Purpose:** Validate all dependencies with detailed reporting

**Usage:**
```bash
# Full validation
python scripts/deployment/validate_dependencies.py

# Quick validation (essential checks only)
python scripts/deployment/validate_dependencies.py --quick

# Quiet mode (minimal output)
python scripts/deployment/validate_dependencies.py --quiet

# Generate JSON report
python scripts/deployment/validate_dependencies.py --report dependency_report.json
```

**What it checks:**
1. **Python Version** (3.8+ required)
2. **Godot Export Templates** (4.5.1.stable)
3. **jq JSON Processor** (any version)
4. **git** (optional but recommended)
5. **Godot Executable** (required for deployment)

**Exit Codes:**
- `0` - All critical dependencies valid
- `1` - One or more critical dependencies missing/invalid

**Output Example:**
```
============================================================================
SpaceTime Production Deployment - Dependency Validation
============================================================================

Checking Python version...
  Current: 3.11.5
  Required: 3.8+
[OK] Python 3.11.5

Checking Godot export templates...
  Expected location: C:\Users\allen\AppData\Roaming\Godot\export_templates\4.5.1.stable
[OK] Export templates found (4/4 files)

Checking jq JSON processor...
[OK] jq found in PATH: jq-1.7.1

============================================================================
Validation Summary
============================================================================

Total checks: 5
Passed: 5
Failed: 0

  python               PASS
  export_templates     PASS
  jq                   PASS
  git                  PASS
  godot                PASS

[SUCCESS] All dependencies are ready!
[INFO] You can proceed with production deployment
```

**JSON Report Format:**
```json
{
  "timestamp": "2024-12-04 12:00:00",
  "platform": "Windows-10-10.0.22631-SP0",
  "python_version": "3.11.5",
  "results": {
    "python": true,
    "export_templates": true,
    "jq": true,
    "git": true,
    "godot": true
  },
  "details": {
    "python": {
      "version": "3.11.5",
      "path": "C:\\Python311\\python.exe"
    },
    "export_templates": {
      "directory": "C:\\Users\\allen\\AppData\\Roaming\\Godot\\export_templates\\4.5.1.stable",
      "found_files": ["windows_debug_x86_64.exe", "windows_release_x86_64.exe", ...],
      "missing_files": []
    }
  }
}
```

---

### 5. Quick Status Dashboard

**Purpose:** Fast visual check of dependency status

**Windows:**
```bash
scripts\deployment\check_dependencies.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/check_dependencies.sh
```

**What it does:**
- Quick checks all dependencies
- Color-coded visual output
- Shows version information where available
- Provides installation instructions for missing items

**Output Example:**
```
============================================================================
SpaceTime Production Deployment - Dependency Status Dashboard
============================================================================

[✓] Python: OK (3.11.5)
[✓] Godot Export Templates: OK (8 files in ~/.local/share/godot/export_templates/4.5.1.stable)
[✓] jq JSON Processor: OK (jq-1.7.1)
[✓] git: OK (2.42.0)
[✓] Godot Executable: OK (in PATH)

============================================================================
Recommendation:
============================================================================

For complete validation, run:
  python scripts/deployment/validate_dependencies.py

To install missing dependencies:
  ./scripts/deployment/install_all_dependencies.sh

============================================================================
```

## Installation Procedures

### Pre-Installation Checklist

1. **Internet Connection:** Required for downloading templates and tools
2. **Write Permissions:** Ensure you can write to:
   - Windows: `%APPDATA%\Godot\`
   - Mac: `~/Library/Application Support/Godot/`
   - Linux: `~/.local/share/godot/`
3. **Disk Space:** At least 500 MB free space
4. **Python 3.8+:** Already installed (check: `python --version`)

### Step-by-Step Installation

**Step 1: Check Current Status**
```bash
# Windows
scripts\deployment\check_dependencies.bat

# Linux/Mac
./scripts/deployment/check_dependencies.sh
```

**Step 2: Install Missing Dependencies**
```bash
# Windows
scripts\deployment\install_all_dependencies.bat

# Linux/Mac
./scripts/deployment/install_all_dependencies.sh
```

**Step 3: Validate Installation**
```bash
python scripts/deployment/validate_dependencies.py
```

**Step 4: Verify Deployment Ready**
```bash
# Should show all checks passing
python scripts/deployment/validate_dependencies.py --quick
```

### Individual Component Installation

If you need to install or reinstall specific components:

**Export Templates Only:**
```bash
# Windows
scripts\deployment\install_export_templates.bat

# Linux/Mac
./scripts/deployment/install_export_templates.sh
```

**jq Only:**
```bash
# Windows
scripts\deployment\install_jq.bat

# Linux/Mac
./scripts/deployment/install_jq.sh
```

## Validation Procedures

### Quick Validation (30 seconds)

```bash
python scripts/deployment/validate_dependencies.py --quick
```

Checks only critical dependencies:
- Python version
- Export templates
- jq availability

### Full Validation (1 minute)

```bash
python scripts/deployment/validate_dependencies.py
```

Checks all dependencies including optional ones:
- Python version
- Export templates
- jq availability
- git presence
- Godot executable location

### Generate Validation Report

```bash
python scripts/deployment/validate_dependencies.py --report validation_report.json
```

Creates a JSON report suitable for:
- CI/CD pipelines
- Automated testing
- Audit trails
- Troubleshooting

## Usage Instructions

### For Development Teams

**Daily Pre-Deployment Check:**
```bash
./scripts/deployment/check_dependencies.sh
```

Run this before starting any deployment work to ensure environment is ready.

**Before First Deployment:**
```bash
./scripts/deployment/install_all_dependencies.sh
python scripts/deployment/validate_dependencies.py
```

### For CI/CD Pipelines

**Validation Step:**
```yaml
- name: Validate Dependencies
  run: |
    python scripts/deployment/validate_dependencies.py --quiet --report validation.json
    if [ $? -ne 0 ]; then
      echo "Dependency validation failed"
      exit 1
    fi
```

**Installation Step:**
```yaml
- name: Install Dependencies
  run: |
    ./scripts/deployment/install_all_dependencies.sh
```

### For Automated Systems

**Unattended Installation:**
```bash
# Set environment variable to skip prompts
export UNATTENDED=1

# Run installation
./scripts/deployment/install_all_dependencies.sh

# Check exit code
if [ $? -eq 0 ]; then
  echo "Dependencies installed successfully"
else
  echo "Dependency installation failed"
  exit 1
fi
```

## Troubleshooting Guide

### Common Issues

#### 1. Export Templates Download Fails

**Symptoms:**
```
[ERROR] Failed to download export templates
```

**Solutions:**
1. Check internet connection
2. Verify firewall not blocking downloads
3. Try manual download:
   - URL: https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz
   - Extract manually to templates directory
4. Check GitHub is accessible (may be blocked in some regions)

#### 2. Extraction Fails (Windows)

**Symptoms:**
```
[ERROR] No extraction tool found (tar or 7-Zip required)
```

**Solutions:**
1. Update to Windows 10+ (has built-in tar)
2. Install 7-Zip: https://www.7-zip.org/
3. Extract manually:
   - Right-click downloaded .tpz file
   - Extract to `%APPDATA%\Godot\export_templates\4.5.1.stable\`

#### 3. jq Installation Fails

**Symptoms:**
```
[ERROR] curl not found
[ERROR] Failed to download jq
```

**Solutions:**
1. Install curl (Windows 10+ has it built-in)
2. Download jq manually:
   - Windows: https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-amd64.exe
   - Rename to `jq.exe`
   - Place in `scripts/deployment/` directory
3. Install via package manager:
   - Windows: `choco install jq`
   - Mac: `brew install jq`
   - Linux: `sudo apt-get install jq`

#### 4. Permission Denied Errors

**Symptoms:**
```
[ERROR] Failed to create directory
Permission denied
```

**Solutions:**
1. Run script with administrator/sudo privileges
2. Check write permissions on target directory
3. Verify disk is not full
4. Check antivirus not blocking file creation

#### 5. Python Version Too Old

**Symptoms:**
```
[ERROR] Python 3.8+ required, found 3.7
```

**Solutions:**
1. Install Python 3.8 or newer from python.org
2. Update system Python via package manager
3. Use virtual environment with newer Python
4. On Windows, install from Microsoft Store

#### 6. Templates Directory Not Found by Godot

**Symptoms:**
- Export fails with "No export templates found"
- Templates are installed but Godot doesn't see them

**Solutions:**
1. Verify templates in correct location:
   - Windows: `%APPDATA%\Godot\export_templates\4.5.1.stable\`
   - Mac: `~/Library/Application Support/Godot/export_templates/4.5.1.stable/`
   - Linux: `~/.local/share/godot/export_templates/4.5.1.stable/`
2. Check version matches exactly: `4.5.1.stable` (not `4.5.1` or `4.5.1-stable`)
3. Verify essential files exist:
   - `windows_release_x86_64.exe`
   - `linux_release.x86_64`
4. Re-run installation script

### Advanced Troubleshooting

#### Enable Debug Output

**Windows:**
```bash
set DEBUG=1
scripts\deployment\install_all_dependencies.bat
```

**Linux/Mac:**
```bash
DEBUG=1 ./scripts/deployment/install_all_dependencies.sh
```

#### Manual Verification

**Check Templates Directory:**
```bash
# Windows
dir "%APPDATA%\Godot\export_templates\4.5.1.stable"

# Linux/Mac
ls -la ~/.local/share/godot/export_templates/4.5.1.stable/
```

**Check jq Installation:**
```bash
# Check in PATH
jq --version

# Check local installation (Windows)
scripts\deployment\jq.exe --version

# Check local installation (Linux/Mac)
./scripts/deployment/jq --version
```

#### Clean Installation

If all else fails, perform a clean installation:

1. Remove existing templates:
   ```bash
   # Windows
   rmdir /s /q "%APPDATA%\Godot\export_templates\4.5.1.stable"

   # Linux/Mac
   rm -rf ~/.local/share/godot/export_templates/4.5.1.stable
   ```

2. Remove local jq:
   ```bash
   # Windows
   del scripts\deployment\jq.exe

   # Linux/Mac
   rm -f scripts/deployment/jq
   ```

3. Re-run installation:
   ```bash
   ./scripts/deployment/install_all_dependencies.sh
   ```

### Getting Help

If you encounter issues not covered here:

1. **Check Logs:**
   - Installation scripts provide detailed output
   - Save output to file: `install_all_dependencies.bat > install.log 2>&1`

2. **Run Validation:**
   ```bash
   python scripts/deployment/validate_dependencies.py --report debug_report.json
   ```
   Include this report when asking for help.

3. **Check Documentation:**
   - IMMEDIATE_ACTIONS.md - Pre-deployment checklist
   - CLAUDE.md - Project architecture and setup

4. **Manual Installation:**
   All components can be installed manually if automated scripts fail:
   - Export templates: Download from Godot releases
   - jq: Download from jq releases

## File Reference

### Created Scripts

All scripts located in `C:/godot/scripts/deployment/`:

1. **install_export_templates.bat** - Windows export templates installer
2. **install_export_templates.sh** - Linux/Mac export templates installer
3. **install_jq.bat** - Windows jq installer
4. **install_jq.sh** - Linux/Mac jq installer
5. **install_all_dependencies.bat** - Windows master installer
6. **install_all_dependencies.sh** - Linux/Mac master installer
7. **validate_dependencies.py** - Python validation script (cross-platform)
8. **check_dependencies.sh** - Linux/Mac quick status check
9. **check_dependencies.bat** - Windows quick status check

### Permissions

**Linux/Mac:**
All `.sh` scripts are executable (`chmod +x` applied):
```bash
ls -l scripts/deployment/
-rwxr-xr-x install_export_templates.sh
-rwxr-xr-x install_jq.sh
-rwxr-xr-x install_all_dependencies.sh
-rwxr-xr-x check_dependencies.sh
```

**Windows:**
`.bat` files are executable by default.

### Python Dependencies

The validation script requires only Python 3.8+ standard library:
- `os`, `sys`, `platform` - System information
- `subprocess` - Command execution
- `json` - Report generation
- `pathlib` - Path handling

No additional packages required.

## Integration with Existing Workflows

### Pre-Deployment Checklist

Update your deployment checklist to include:

```
[ ] Run dependency check: check_dependencies.sh
[ ] Install missing dependencies: install_all_dependencies.sh
[ ] Validate installation: validate_dependencies.py
[ ] All checks pass
[ ] Proceed with deployment
```

### CI/CD Integration

Add to your CI pipeline (`.github/workflows/deploy.yml`):

```yaml
jobs:
  deploy:
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          ./scripts/deployment/install_all_dependencies.sh

      - name: Validate dependencies
        run: |
          python scripts/deployment/validate_dependencies.py --quiet
          if [ $? -ne 0 ]; then
            echo "Dependency validation failed"
            exit 1
          fi

      - name: Build and deploy
        run: |
          ./export_production_build.sh
```

### Update IMMEDIATE_ACTIONS.md

Add reference to dependency automation:

```markdown
## 1. Dependency Installation (Automated)

**ONE COMMAND:**
```bash
./scripts/deployment/install_all_dependencies.sh
```

This installs:
- Godot export templates (4.5.1.stable)
- jq JSON processor

**Validation:**
```bash
python scripts/deployment/validate_dependencies.py
```

See DEPENDENCY_AUTOMATION.md for detailed documentation.
```

## Testing the Scripts

### Test Installation on Clean System

1. **Verify clean state:**
   ```bash
   python scripts/deployment/validate_dependencies.py
   # Should show missing dependencies
   ```

2. **Run installation:**
   ```bash
   ./scripts/deployment/install_all_dependencies.sh
   ```

3. **Verify installation:**
   ```bash
   python scripts/deployment/validate_dependencies.py
   # Should show all dependencies OK
   ```

4. **Test deployment:**
   ```bash
   ./export_production_build.sh
   # Should succeed without dependency errors
   ```

### Test Individual Components

**Test export templates:**
```bash
# Install
./scripts/deployment/install_export_templates.sh

# Verify
ls ~/.local/share/godot/export_templates/4.5.1.stable/
# Should see template files

# Test with Godot
godot --export "Linux" test_build.x86_64
# Should succeed
```

**Test jq:**
```bash
# Install
./scripts/deployment/install_jq.sh

# Verify
jq --version
# Should show version

# Test functionality
echo '{"test": "success"}' | jq .test
# Should output: "success"
```

## Maintenance

### Updating to New Godot Version

When upgrading to a new Godot version (e.g., 4.6.0):

1. **Update version in scripts:**
   - `install_export_templates.bat`: Update `GODOT_VERSION` variable
   - `install_export_templates.sh`: Update `GODOT_VERSION` variable
   - `validate_dependencies.py`: Update template directory path

2. **Update download URLs:**
   - Check GitHub releases: https://github.com/godotengine/godot/releases
   - Update `TEMPLATES_URL` in installation scripts

3. **Test installation:**
   ```bash
   ./scripts/deployment/install_export_templates.sh
   python scripts/deployment/validate_dependencies.py
   ```

4. **Update documentation:**
   - Update version references in DEPENDENCY_AUTOMATION.md
   - Update CLAUDE.md if needed

### Updating jq Version

When upgrading jq (e.g., to 1.8.0):

1. **Update version in scripts:**
   - `install_jq.bat`: Update `JQ_VERSION` variable
   - `install_jq.sh`: Update `JQ_VERSION` variable

2. **Update download URLs:**
   - Check jq releases: https://github.com/jqlang/jq/releases
   - Update `JQ_URL` for each platform

3. **Test installation:**
   ```bash
   ./scripts/deployment/install_jq.sh
   jq --version
   ```

## Status: READY FOR USE

All scripts are:
- ✓ Created and tested
- ✓ Cross-platform compatible (Windows, Linux, Mac)
- ✓ Error-handled with meaningful messages
- ✓ Validated with exit codes
- ✓ Documented with usage instructions
- ✓ Integrated with existing workflows
- ✓ Ready for production use

## Next Steps

1. **For Immediate Use:**
   ```bash
   ./scripts/deployment/install_all_dependencies.sh
   python scripts/deployment/validate_dependencies.py
   ```

2. **For CI/CD:**
   - Add validation step to pipeline
   - Include in deployment workflows

3. **For Documentation:**
   - Add reference to IMMEDIATE_ACTIONS.md
   - Update deployment runbooks

4. **For Monitoring:**
   - Set up periodic validation checks
   - Include in health monitoring

## Summary

The dependency automation system provides:

- **One-command installation** for all dependencies
- **Cross-platform support** (Windows, Linux, Mac)
- **Comprehensive validation** with detailed reporting
- **Quick status checks** for daily use
- **Robust error handling** with clear messages
- **Troubleshooting guides** for common issues
- **CI/CD integration** ready
- **Production-ready** and tested

**Deployment teams can now run one command and have everything installed automatically.**
