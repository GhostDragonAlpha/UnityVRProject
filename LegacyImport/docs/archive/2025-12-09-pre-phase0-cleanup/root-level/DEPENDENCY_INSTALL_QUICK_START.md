# Dependency Installation - Quick Start Guide

**Status: READY FOR USE**

## Automated Installation (Recommended)

### One Command to Install Everything

**Windows:**
```bash
cd C:/godot
scripts\deployment\install_all_dependencies.bat
```

**Linux/Mac:**
```bash
cd /path/to/godot
./scripts/deployment/install_all_dependencies.sh
```

This will automatically install:
1. Godot 4.5.1 Export Templates
2. jq JSON Processor

### Quick Status Check

**Windows:**
```bash
scripts\deployment\check_dependencies.bat
```

**Linux/Mac:**
```bash
./scripts/deployment/check_dependencies.sh
```

### Full Validation

```bash
python scripts/deployment/validate_dependencies.py
```

## What Gets Installed

### 1. Godot Export Templates (4.5.1.stable)

**Install Location:**
- Windows: `C:\Users\[USER]\AppData\Roaming\Godot\export_templates\4.5.1.stable\`
- Mac: `~/Library/Application Support/Godot/export_templates/4.5.1.stable/`
- Linux: `~/.local/share/godot/export_templates/4.5.1.stable/`

**Required Files:**
- `windows_debug_x86_64.exe`
- `windows_release_x86_64.exe`
- `linux_debug.x86_64`
- `linux_release.x86_64`

### 2. jq JSON Processor

**Install Location:**
- System-wide (via package manager), OR
- Local: `scripts/deployment/jq.exe` (Windows) or `scripts/deployment/jq` (Linux/Mac)

**Purpose:** JSON parsing in deployment and packaging scripts

## Time Estimates

| Task | Time |
|------|------|
| Download export templates | 3-5 min |
| Extract and install | 1-2 min |
| Install jq | 1-2 min |
| Validation | 1 min |
| **Total** | **6-10 min** |

## Success Indicators

After installation, you should see:

```
[OK] Python: OK (3.11.5)
[OK] Godot Export Templates: OK (8 files)
[OK] jq JSON Processor: OK (jq-1.7.1)
[OK] git: OK (2.42.0)
[OK] Godot Executable: OK (in PATH)
```

## Troubleshooting

### Installation Failed?

**Check:**
1. Internet connection active
2. Sufficient disk space (500 MB)
3. Write permissions to install directories
4. Firewall not blocking downloads

**Solutions:**
1. Review error messages in output
2. Run individual installers:
   - `scripts\deployment\install_export_templates.bat`
   - `scripts\deployment\install_jq.bat`
3. Check **DEPENDENCY_AUTOMATION.md** troubleshooting section
4. Try manual installation methods in **IMMEDIATE_ACTIONS.md**

### How to Verify Installation?

```bash
# Check export templates exist
ls "C:/Users/allen/AppData/Roaming/Godot/export_templates/4.5.1.stable/"*.exe

# Check jq works
jq --version

# Run full validation
python scripts/deployment/validate_dependencies.py
```

## Next Steps After Installation

1. **Verify dependencies:**
   ```bash
   python scripts/deployment/validate_dependencies.py
   ```

2. **Proceed with build export:**
   ```bash
   ./export_production_build.bat
   ```

3. **Validate build:**
   ```bash
   python validate_build.py
   ```

## Documentation

- **Complete Guide:** DEPENDENCY_AUTOMATION.md
- **Deployment Steps:** IMMEDIATE_ACTIONS.md
- **Script Reference:** scripts/deployment/README.md

## Quick Commands Reference

```bash
# Install all dependencies
scripts\deployment\install_all_dependencies.bat

# Check status
scripts\deployment\check_dependencies.bat

# Validate
python scripts\deployment\validate_dependencies.py

# Individual installs (if needed)
scripts\deployment\install_export_templates.bat
scripts\deployment\install_jq.bat
```

---

**For CI/CD Integration:**

```yaml
- name: Install Dependencies
  run: ./scripts/deployment/install_all_dependencies.sh

- name: Validate Dependencies
  run: python scripts/deployment/validate_dependencies.py --quiet
```

---

**Support:**
- Detailed documentation: DEPENDENCY_AUTOMATION.md
- Troubleshooting: See DEPENDENCY_AUTOMATION.md section "Troubleshooting Guide"
- Script details: scripts/deployment/README.md
