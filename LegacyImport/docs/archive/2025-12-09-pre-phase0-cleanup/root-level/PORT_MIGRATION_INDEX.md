# Port Migration Tool - Complete Documentation Index

## Quick Links

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[MIGRATION_SUMMARY.md](MIGRATION_SUMMARY.md)** | Overview and quick start | Start here first |
| **[BATCH_PORT_UPDATE_README.md](BATCH_PORT_UPDATE_README.md)** | Comprehensive guide | Deep dive and reference |
| **[QUICK_REFERENCE.txt](QUICK_REFERENCE.txt)** | Command cheat sheet | Quick command lookup |
| **[batch_port_update.py](batch_port_update.py)** | Main script | Execute the tool |
| **[example_migration_workflow.sh](example_migration_workflow.sh)** | Bash workflow example | Linux/Mac guided migration |
| **[example_migration_workflow.bat](example_migration_workflow.bat)** | Windows workflow example | Windows guided migration |

## What This Tool Does

Automates migration from deprecated **port 8081** (GodotBridge) to active ports:
- **8080**: HTTP API (HttpApiServer)
- **8081**: WebSocket Telemetry

## Getting Started in 3 Steps

### 1. Read the Summary (5 minutes)

```bash
# Open the summary document
cat MIGRATION_SUMMARY.md
# or
code MIGRATION_SUMMARY.md
```

**What you'll learn:**
- What the tool does
- Initial scan results
- Safety features
- Quick start guide

### 2. Generate Your First Report (1 minute)

```bash
# Safe dry-run - no changes made
python batch_port_update.py --report my_migration_report.md
```

**What you'll get:**
- Files with port 8080 references
- Recommended replacements (8080 or 8081)
- Context around each occurrence
- Summary statistics

### 3. Review and Execute (When Ready)

```bash
# Review the report first
cat my_migration_report.md

# Execute when confident
python batch_port_update.py --execute --changelog my_changelog.md
```

**What happens:**
- Automatic `.bak` backups created
- Files updated with new ports
- Changelog generated
- You can rollback if needed

## Document Descriptions

### MIGRATION_SUMMARY.md
**Summary document for quick orientation**

Contents:
- What the tool does
- Key features
- Quick start guide
- Initial scan results (~3,870 occurrences)
- Detection logic explanation
- Usage examples
- Rollback procedures
- Best practices
- Recommended workflow

**Start here** if you're new to the tool.

### BATCH_PORT_UPDATE_README.md
**Comprehensive usage guide with all details**

Contents:
- Complete feature list
- All command-line options
- Detailed examples
- Report structure explanation
- Understanding detection logic
- Troubleshooting guide
- Edge cases and special handling
- Post-migration testing
- Version history

**Use this** for detailed reference and troubleshooting.

### QUICK_REFERENCE.txt
**One-page command cheat sheet**

Contents:
- Basic commands
- Port migration guide
- Safety features
- Typical workflow
- Context indicators
- Troubleshooting tips
- Post-migration testing

**Use this** for quick command lookup.

### batch_port_update.py
**The main executable script**

Features:
- Intelligent port detection (HTTP vs WebSocket)
- Context-aware analysis
- Safe dry-run default
- Automatic backups
- Comprehensive reporting
- Changelog generation
- Unicode support (Windows)
- Cross-platform (Windows, Linux, Mac)

**Run this** to perform the migration.

### example_migration_workflow.sh (Bash/Linux/Mac)
**Interactive guided workflow script**

Features:
- Step-by-step guidance
- Git status checks
- Report generation
- Review prompts
- Service testing
- Automated commit

**Run this** for guided migration on Linux/Mac.

### example_migration_workflow.bat (Windows)
**Interactive guided workflow script for Windows**

Features:
- Same as bash version
- Windows-specific commands
- Handles paths correctly
- Opens editors automatically

**Run this** for guided migration on Windows.

## File Organization

```
C:/godot/
├── batch_port_update.py              # Main script
├── PORT_MIGRATION_INDEX.md           # This file
├── MIGRATION_SUMMARY.md              # Quick overview
├── BATCH_PORT_UPDATE_README.md       # Complete guide
├── QUICK_REFERENCE.txt               # Command cheat sheet
├── example_migration_workflow.sh     # Bash workflow
└── example_migration_workflow.bat    # Windows workflow

Generated files (after running):
├── port_migration_report.md          # Detailed analysis
├── migration_changelog.md            # Change log
└── **/*.bak                           # Backup files
```

## Usage Paths

### Path 1: Quick and Simple
For users who want to get started quickly:

```bash
1. cat MIGRATION_SUMMARY.md           # Read overview
2. python batch_port_update.py --report report.md
3. cat report.md                       # Review
4. python batch_port_update.py --execute
```

### Path 2: Guided Workflow
For users who want step-by-step guidance:

```bash
# Windows
example_migration_workflow.bat

# Linux/Mac
bash example_migration_workflow.sh
```

### Path 3: Comprehensive Study
For users who want to understand everything:

```bash
1. cat MIGRATION_SUMMARY.md           # Overview
2. cat BATCH_PORT_UPDATE_README.md    # Deep dive
3. cat QUICK_REFERENCE.txt             # Commands
4. python batch_port_update.py --help  # Options
5. python batch_port_update.py --report report.md
6. # Review report carefully
7. python batch_port_update.py --execute --changelog log.md
```

## Common Workflows

### Workflow 1: First-Time User

```bash
# 1. Understand the tool
cat PORT_MIGRATION_INDEX.md          # This file
cat MIGRATION_SUMMARY.md             # Overview

# 2. Test on a subset first
python batch_port_update.py --root C:/godot/examples --report test.md
cat test.md

# 3. If comfortable, run on full codebase
python batch_port_update.py --report full_report.md
cat full_report.md

# 4. Execute when ready
python batch_port_update.py --execute --changelog changes.md
```

### Workflow 2: Experienced User

```bash
# Quick reference
cat QUICK_REFERENCE.txt

# Generate report
python batch_port_update.py --report report.md

# Review and execute
python batch_port_update.py --execute --changelog log.md

# Test
curl http://127.0.0.1:8080/status
```

### Workflow 3: Using Guided Script

```bash
# Windows
example_migration_workflow.bat

# Linux/Mac
bash example_migration_workflow.sh

# The script handles everything:
# - Git checks
# - Report generation
# - Review prompts
# - Execution
# - Testing
# - Commit
```

## Key Concepts

### Port Migration Map

| Old | New | When to Use | Indicators |
|-----|-----|-------------|------------|
| 8081 | 8080 | HTTP API calls | `http://`, `curl`, `api`, `endpoint` |
| 8081 | 8081 | WebSocket streaming | `ws://`, `websocket`, `telemetry`, `streaming` |

### Safety Model

1. **Dry-run by default** - Nothing changes without `--execute`
2. **Automatic backups** - `.bak` files created before modification
3. **Confirmation required** - Must type "yes" to proceed
4. **Reversible** - Can restore from backups or git
5. **Smart exclusions** - Skips `.venv`, build artifacts

### Detection Algorithm

```
For each occurrence of "8081":
  1. Extract context (lines before/after)
  2. Score for HTTP indicators (http://, curl, api, etc.)
  3. Score for WebSocket indicators (ws://, websocket, telemetry)
  4. If WebSocket score > HTTP score: recommend 8081
  5. Else: recommend 8080 (default)
  6. Include reasoning in report
```

## Troubleshooting Quick Ref

| Issue | Solution |
|-------|----------|
| No occurrences found | Check `--root` path, may be already migrated |
| Unicode errors | Fixed in v1.0.0, set `PYTHONIOENCODING=utf-8` |
| Permission errors | Close files in editor, run as admin |
| False positives | Review context, make manual adjustments |
| Can't undo | Restore from `.bak` files or use `git checkout` |

## Success Criteria

After migration, verify:

✅ HTTP API responds on port 8080:
```bash
curl http://127.0.0.1:8080/status
```

✅ WebSocket telemetry works on port 8081:
```bash
python telemetry_client.py
```

✅ Tests pass:
```bash
python tests/test_runner.py
```

✅ No references to 8080 in active code:
```bash
python batch_port_update.py --report verify.md
# Should show 0 occurrences (or only historical references)
```

## Next Steps

1. **Choose your path** (see "Usage Paths" above)
2. **Read the appropriate docs** for your experience level
3. **Generate a report** to see what will change
4. **Review carefully** - automation is smart but not perfect
5. **Execute when ready** - backups are automatic
6. **Test thoroughly** - verify services still work
7. **Commit** - save your migration

## Support

If you need help:

1. Check **QUICK_REFERENCE.txt** for commands
2. Read **BATCH_PORT_UPDATE_README.md** for details
3. Review the generated **report.md** for context
4. Check **MIGRATION_SUMMARY.md** for examples

## Version

- **Tool Version**: 1.0.0
- **Date**: 2025-12-04
- **Python**: 3.8+
- **Platform**: Cross-platform

## Migration Context

This tool is part of migrating the Godot SpaceTime project from:
- **Old**: GodotBridge (port 8081, deprecated, disabled in autoload)
- **New**: HttpApiServer (port 8080, active, production)
- **New**: Telemetry WebSocket (port 8081, active)

The legacy addon (`addons/godot_debug_connection/`) is retained for reference but no longer used in active development.

---

**Remember**: Start with the summary, generate a report, review carefully, then execute. The tool is safe by default.
