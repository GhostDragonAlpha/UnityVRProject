# Port Migration Tool - Summary

## Created Files

1. **`batch_port_update.py`** - Main migration script (executable)
2. **`BATCH_PORT_UPDATE_README.md`** - Comprehensive usage guide
3. **`QUICK_REFERENCE.txt`** - Quick command reference

## What This Tool Does

Automates the migration from deprecated port 8081 (GodotBridge) to:
- **Port 8080**: HTTP API (HttpApiServer) - for REST API calls
- **Port 8081**: WebSocket Telemetry - for streaming data

## Key Features

### 1. Intelligent Port Detection
- Analyzes context around each occurrence
- Detects HTTP API vs WebSocket usage
- Provides reasoning for each recommendation

### 2. Safety First
- **Dry-run by default** - no changes unless `--execute` specified
- **Automatic backups** - creates `.bak` files before modification
- **Confirmation prompt** - requires explicit "yes" to proceed
- **Smart exclusions** - skips `.venv`, `addons/gdUnit4`, build artifacts

### 3. Comprehensive Reporting
- Summary statistics (files scanned, matches found)
- Breakdown by recommended port (8080 vs 8081)
- Breakdown by file type (.py, .gd, .md, etc.)
- File-by-file details with context
- Line numbers for precise location
- Recommended replacements

### 4. Changelog Generation
- Lists all modified files
- Shows backup locations
- Provides rollback instructions
- Documents replacement details

## Quick Start

### Step 1: Generate Report (Safe, No Changes)

```bash
python batch_port_update.py --report migration_report.md
```

### Step 2: Review the Report

Open `migration_report.md` and review each occurrence carefully. The report shows:
- Exact line numbers
- Context (lines before and after)
- Recommended port (8080 or 8081)
- Reasoning for the recommendation

### Step 3: Execute Migration

```bash
python batch_port_update.py --execute --changelog migration_changelog.md
```

You'll be prompted to confirm with "yes".

### Step 4: Test Services

```bash
# Test new HTTP API port
curl http://127.0.0.1:8080/status

# Test WebSocket telemetry
python telemetry_client.py

# Run test suite
python tests/test_runner.py
```

## Initial Scan Results

Based on the full codebase scan:

- **Files Scanned**: ~2,155 files
- **Files with Matches**: ~350 files
- **Total Occurrences**: ~3,870 occurrences
- **Breakdown**:
  - Port 8080 (HTTP API): ~3,745 occurrences
  - Port 8081 (WebSocket): ~125 occurrences

**File Types**:
- `.md` (documentation): ~1,390 occurrences
- `.txt` (text files): ~119 occurrences
- `.py` (Python scripts): ~87 occurrences
- `.sh` (shell scripts): ~20 occurrences
- `.bat` (batch files): ~14 occurrences
- `.json` (config files): ~11 occurrences
- Others: ~11 occurrences

## Detection Logic

### HTTP API (Port 8080)
Detected when context contains:
- `http://`, `https://`
- `curl`, `request`
- `api`, `endpoint`, `rest`
- `get`, `post`, `put`, `delete`

### WebSocket Telemetry (Port 8081)
Detected when context contains:
- `websocket`, `ws://`, `wss://`
- `telemetry`, `streaming`
- `real-time`, `realtime`
- `socket`, `broadcast`

### Default Behavior
If no clear indicators are found, defaults to **Port 8080** (HTTP API).

## Excluded Directories

The script automatically skips:
- `.venv/`, `venv/` - Virtual environments
- `addons/gdUnit4/` - Testing framework
- `__pycache__/`, `*.pyc` - Python bytecode
- `.git/` - Git repository
- `node_modules/` - Node dependencies
- `build/`, `dist/` - Build artifacts
- Binary and media files

## File Types Scanned

- **Python**: `.py`
- **GDScript**: `.gd`
- **Documentation**: `.md`, `.txt`
- **Configuration**: `.json`, `.cfg`, `.toml`, `.yaml`, `.yml`
- **Scripts**: `.sh`, `.bat`
- **Godot**: `.tscn`, `.tres`, `.godot`
- **C#**: `.cs`

## Usage Examples

### Example 1: Dry-Run

```bash
python batch_port_update.py
```

Prints detailed report to console without making changes.

### Example 2: Scan Specific Directory

```bash
python batch_port_update.py --root C:/godot/scripts --report scripts_report.md
```

Only scans the `scripts/` directory.

### Example 3: More Context

```bash
python batch_port_update.py --context 5 --report detailed.md
```

Shows 5 lines of context instead of 3.

### Example 4: Full Migration

```bash
# Step 1: Review
python batch_port_update.py --report review.md
cat review.md

# Step 2: Execute
python batch_port_update.py --execute --changelog changes.md

# Step 3: Test
curl http://127.0.0.1:8080/status
python tests/test_runner.py
```

## Rollback Procedure

If you need to undo changes:

### Option 1: Restore from Backups

```bash
# Backups are created with .bak extension
cp path/to/file.py.bak path/to/file.py
```

### Option 2: Use Changelog

The changelog includes ready-to-run restore commands.

### Option 3: Git Revert

```bash
git diff HEAD
git checkout -- .
```

## Safety Considerations

### What's Safe to Update

✅ **Active Code**: Definitely update
```python
response = requests.get('http://127.0.0.1:8080/status')
# Should be: http://127.0.0.1:8080/status
```

✅ **Configuration Files**: Update to new ports
```json
{"api_port": 8080}
// Should be: {"api_port": 8080}
```

✅ **Documentation**: Update for accuracy
```markdown
Access API at http://localhost:8080
<!-- Should be: http://localhost:8080 -->
```

### What May Need Review

⚠️ **Historical References**: Decide case-by-case
```markdown
# Port 8080 was deprecated in version 2.0
# This reference may be intentionally historical
```

⚠️ **Comments**: May need manual adjustment
```python
# TODO: Migrate from port 8080 to new API
# Comment itself discusses the migration
```

⚠️ **Port Lists**: Verify entire list
```python
FALLBACK_PORTS = [8080, 8083, 8084, 8085]
# Should probably be: [8080, 8083, 8084, 8085]
```

## Common Issues

### Issue 1: Unicode Encoding Errors
**Status**: Fixed in version 1.0.0
**Fallback**: Set `PYTHONIOENCODING=utf-8` if needed

### Issue 2: Permission Errors
**Cause**: Files open in editor or insufficient permissions
**Solution**: Close files, run as administrator (Windows)

### Issue 3: False Positives
**Cause**: Context-based detection isn't perfect
**Solution**: Review report carefully, make manual adjustments

## Best Practices

1. ✅ **Always start with dry-run** - Review before executing
2. ✅ **Use git** - Ensure clean state before migration
3. ✅ **Read the report** - Don't blindly trust automation
4. ✅ **Test after migration** - Verify services work
5. ✅ **Keep backups** - `.bak` files are your safety net
6. ✅ **Commit thoughtfully** - Include changelog in commit message

## Recommended Workflow

```bash
# 1. Ensure clean git state
git status
git commit -am "Save work before port migration"

# 2. Generate and review report
python batch_port_update.py --report migration_plan.md
code migration_plan.md  # Review carefully

# 3. Execute migration
python batch_port_update.py --execute --changelog migration_log.md

# 4. Review changes
git diff

# 5. Test critical services
curl http://127.0.0.1:8080/status
python telemetry_client.py
python tests/test_runner.py

# 6. Make manual adjustments if needed

# 7. Commit
git add .
git commit -m "Migrate from port 8080 to ports 8080/8081

Automated migration using batch_port_update.py:
- HTTP API: 8081 → 8080
- WebSocket: 8081 → 8081

Files modified: ~350
Total replacements: ~3,870

See migration_log.md for details.
Backups created with .bak extension."
```

## Documentation

- **Full Guide**: `BATCH_PORT_UPDATE_README.md`
- **Quick Reference**: `QUICK_REFERENCE.txt`
- **Help**: `python batch_port_update.py --help`

## Version Information

- **Version**: 1.0.0
- **Date**: 2025-12-04
- **Python**: 3.8+
- **Platform**: Cross-platform (Windows, Linux, Mac)

## Port Migration Reference

| Old (Deprecated) | New (Active) | Purpose | Protocol |
|-----------------|--------------|---------|----------|
| 8081 | 8080 | HTTP API | HTTP/REST |
| 8081 | 8081 | Telemetry | WebSocket |

**Note**: GodotBridge (port 8081) is disabled in `project.godot` autoload configuration. The new HttpApiServer (port 8080) is the active HTTP API.

## Support

If you encounter issues:
1. Check the detailed README: `BATCH_PORT_UPDATE_README.md`
2. Review the report context carefully
3. Test on a subset first: `--root C:/godot/examples`
4. Keep backups until verified
5. Use git for version control

## Next Steps

1. **Review this summary**
2. **Read the full README**: `BATCH_PORT_UPDATE_README.md`
3. **Generate initial report**: `python batch_port_update.py --report review.md`
4. **Review the report carefully**
5. **Execute when ready**: `python batch_port_update.py --execute`
6. **Test thoroughly**
7. **Commit changes**

---

**Remember**: The script is safe by default. Nothing changes unless you use `--execute` and confirm with "yes".
