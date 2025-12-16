# Batch Port Update Tool - Usage Guide

## Overview

The `batch_port_update.py` script automates the migration from deprecated port 8081 (GodotBridge) to the new active ports:
- **Port 8080**: HTTP API (HttpApiServer)
- **Port 8081**: WebSocket Telemetry

## Quick Start

### 1. Dry-Run (Safe, No Changes)

Generate a report without making any changes:

```bash
python batch_port_update.py
```

This will scan the codebase and print a detailed report to the console.

### 2. Save Report to File

```bash
python batch_port_update.py --report port_migration_report.md
```

Review the report carefully before executing any changes.

### 3. Execute Replacements

```bash
python batch_port_update.py --execute
```

You will be prompted to confirm before any changes are made. Backups are created automatically.

### 4. Execute with Changelog

```bash
python batch_port_update.py --execute --changelog changelog.md
```

## Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--root DIR` | Root directory to scan | `C:/godot` |
| `--execute` | Execute replacements (dry-run by default) | `False` |
| `--report FILE` | Save report to file | Print to stdout |
| `--changelog FILE` | Save changelog (requires `--execute`) | None |
| `--context N` | Context lines before/after matches | `3` |
| `--help` | Show help message | - |
| `--version` | Show version number | - |

## Features

### Intelligent Port Detection

The script analyzes context to determine the correct replacement port:

- **Port 8080 (HTTP API)**: Detected when context contains:
  - `http://`, `https://`, `curl`, `request`
  - `api`, `endpoint`, `rest`, `post`, `get`

- **Port 8081 (WebSocket)**: Detected when context contains:
  - `websocket`, `ws://`, `wss://`, `telemetry`
  - `streaming`, `real-time`, `socket`, `broadcast`

### Safety Features

1. **Dry-Run Default**: No changes made unless `--execute` is specified
2. **Automatic Backups**: Creates `.bak` files before modification
3. **Confirmation Prompt**: Requires explicit "yes" before executing
4. **Smart Exclusions**: Skips `.venv`, `addons/gdUnit4`, build artifacts
5. **Unicode Support**: Handles files with various encodings

### Detailed Reporting

The report includes:

- **Summary Statistics**: Files scanned, matches found, breakdown by port
- **File-by-File Analysis**: Each occurrence with context
- **Line Numbers**: Precise location of each match
- **Recommendations**: Suggested replacement for each occurrence
- **Context Display**: Lines before/after for better understanding

### Changelog Generation

When executed with `--execute --changelog`, generates:

- List of modified files
- Backup file locations
- Summary of replacements per file
- Rollback instructions

## Examples

### Example 1: Quick Scan

```bash
python batch_port_update.py
```

Output:
```
Scanning directory: C:\godot
Excluding: .venv, addons/gdUnit4, ...

Scanned 2154 files, found matches in 353 files
Total occurrences: 1664

[Detailed report printed to console]
```

### Example 2: Scan Specific Directory

```bash
python batch_port_update.py --root C:/godot/scripts
```

Only scans the `scripts/` directory and subdirectories.

### Example 3: More Context

```bash
python batch_port_update.py --context 5 --report detailed_report.md
```

Shows 5 lines of context before/after each match instead of the default 3.

### Example 4: Full Execution

```bash
# Step 1: Generate and review report
python batch_port_update.py --report migration_plan.md

# Step 2: Review the report
cat migration_plan.md

# Step 3: Execute with changelog
python batch_port_update.py --execute --changelog migration_changelog.md
```

## Understanding the Report

### Report Structure

```markdown
# Port 8080 Migration Report

## Summary
- Files Scanned: 2154
- Files with Matches: 353
- Total Occurrences: 1664

### Breakdown by Recommended Port
- Port 8080: 1603 occurrences  # HTTP API
- Port 8081: 61 occurrences    # WebSocket Telemetry

### Breakdown by File Type
- `.md`: 1390 occurrences      # Documentation files
- `.py`: 87 occurrences        # Python scripts
- `.sh`: 20 occurrences        # Shell scripts
...

## Detailed Occurrences

### File: `examples/health_check.py`

#### Line 45

**Recommended Port:** 8080
**Reason:** HTTP API context (score: 4)

**Context:**
```
  42 | def check_godot_health():
  43 |     """Check if Godot HTTP API is responding."""
  44 |     try:
  45 |         response = requests.get('http://127.0.0.1:8080/status')  <-- PORT 8080 HERE
  46 |         return response.status_code == 200
  47 |     except Exception as e:
  48 |         print(f"Error: {e}")
```

**Replacement:**
```
        response = requests.get('http://127.0.0.1:8080/status')
```
```

### What to Look For

1. **Recommended Port**: Check if the suggestion makes sense
2. **Reason**: Understand why the script chose this port
3. **Context**: Review surrounding code to verify correctness
4. **Notes**: Pay attention to comments about documentation vs code

### Special Cases

#### Case 1: Port Lists

```python
# Original
for port in [8080, 8083, 8084]:
    test_connection(port)

# Recommended
for port in [8080, 8083, 8084]:  # Changed to active HTTP API port
    test_connection(port)
```

#### Case 2: Documentation

In documentation files (`.md`), the script will:
- Detect as documentation (noted in report)
- Still recommend appropriate port
- Allow you to decide if update is needed

#### Case 3: Comments

```python
# Original
# Old API was on port 8080 (deprecated)

# Recommended
# Old API was on port 8081 (deprecated)  # May need manual review
```

## Rollback Procedure

If you need to undo changes:

### Option 1: Restore from Backups

```bash
# Example from changelog
cp "scripts/http_api/client.py.bak" "scripts/http_api/client.py"
cp "examples/health_check.py.bak" "examples/health_check.py"
```

### Option 2: Use Changelog Script

The changelog includes a ready-to-run script:

```bash
# Extract rollback commands from changelog
grep "^cp " migration_changelog.md > rollback.sh
bash rollback.sh
```

### Option 3: Git Revert (if committed)

```bash
git diff HEAD
git checkout -- .
```

## Excluded Directories

The script automatically excludes:

- `.venv/`, `venv/` - Python virtual environments
- `addons/gdUnit4/` - Testing framework
- `__pycache__/`, `*.pyc` - Python bytecode
- `.git/` - Git repository
- `node_modules/` - Node.js dependencies
- `build/`, `dist/` - Build artifacts
- Binary files: `.exe`, `.dll`, `.so`, etc.
- Media files: `.png`, `.jpg`, `.mp3`, etc.

## File Types Scanned

- Python: `.py`
- GDScript: `.gd`
- Documentation: `.md`, `.txt`
- Configuration: `.json`, `.cfg`, `.toml`, `.yaml`, `.yml`
- Scripts: `.sh`, `.bat`
- Godot: `.tscn`, `.tres`, `.godot`
- C#: `.cs`

## Troubleshooting

### Issue: "No occurrences found"

**Possible causes:**
- Already migrated to new ports
- Scanning wrong directory (use `--root`)
- Files excluded by patterns

**Solution:**
```bash
# Verify you're in the right directory
python batch_port_update.py --root C:/godot
```

### Issue: Unicode encoding errors

**Fixed in version 1.0.0**, but if issues persist:

```bash
# Set UTF-8 environment variable
set PYTHONIOENCODING=utf-8
python batch_port_update.py
```

### Issue: Permission errors during execution

**Possible causes:**
- Files open in editor
- Insufficient permissions

**Solution:**
```bash
# Close all files in editor
# Run as administrator (Windows)
# Or use sudo (Linux/Mac)
```

### Issue: Script finds too many false positives

**Solution:**
Review the report carefully. The script includes context to help you identify:
- Historical references (should probably be updated)
- Comments (may need manual review)
- Documentation (update for clarity)
- Active code (definitely update)

## Best Practices

1. **Always start with dry-run**: Review the report first
2. **Check the summary**: Understand the scope before executing
3. **Review context**: Don't blindly trust automated detection
4. **Keep backups**: The `.bak` files are your safety net
5. **Commit first**: Have a clean git state before running
6. **Test after**: Verify services still work after migration

## Migration Workflow

### Recommended Step-by-Step Process

```bash
# 1. Ensure clean git state
git status
git stash  # if needed

# 2. Generate initial report
python batch_port_update.py --report migration_report.md

# 3. Review report thoroughly
code migration_report.md  # or your preferred editor

# 4. Identify any manual changes needed
# (e.g., config files, special cases)

# 5. Execute automated migration
python batch_port_update.py --execute --changelog migration_changelog.md

# 6. Review changes
git diff

# 7. Test critical services
curl http://127.0.0.1:8080/status
python telemetry_client.py

# 8. Make manual adjustments if needed

# 9. Run tests
python tests/test_runner.py

# 10. Commit changes
git add .
git commit -m "Migrate from port 8081 to ports 8080/8081

- Updated HTTP API references from 8081 to 8080
- Updated WebSocket references from 8081 to 8081
- Created backups (.bak files) for all modified files

See migration_changelog.md for details"
```

## Support and Issues

If you encounter issues:

1. Check the report for context
2. Review the excluded patterns
3. Verify file permissions
4. Check git status
5. Restore from backups if needed

## Version History

### 1.0.0 (2025-12-04)
- Initial release
- Intelligent port detection (HTTP vs WebSocket)
- Automatic backup creation
- Comprehensive reporting
- Changelog generation
- Unicode support for Windows
- Safe dry-run default

## License

This script is part of the Godot SpaceTime project and follows the same license.
