# Fix Addon Structure Tool

A Python utility for detecting and fixing nested Godot addon directory structures, specifically addressing the common issue where addons are extracted with duplicate nesting (e.g., `addons/addon-name/addons/addon-name/`).

## Overview

This tool automatically:

1. **Detects nested addon structures** - Identifies addons with the pattern `addons/addon-name/addons/addon-name/`
2. **Flattens nested directories** - Moves files from nested structure to correct level
3. **Verifies addon integrity** - Checks for required `plugin.cfg` file
4. **Applies fixes automatically** - Option to fix issues or verify-only
5. **Creates backups** - Saves original structure before modifying

## Installation

The script is located at:
```
C:/Ignotus/scripts/tools/fix_addon_structure.py
```

No external dependencies required beyond Python standard library (3.7+).

## Usage

### Basic Commands

**Fix all addons:**
```bash
python scripts/tools/fix_addon_structure.py --all
```

**Fix specific addon:**
```bash
python scripts/tools/fix_addon_structure.py godot-xr-tools
```

**Verify without fixing:**
```bash
python scripts/tools/fix_addon_structure.py --verify-only
```

**Default behavior (no arguments):**
```bash
python scripts/tools/fix_addon_structure.py
```
Processes all addons by default.

### Advanced Options

**Verbose output:**
```bash
python scripts/tools/fix_addon_structure.py --all -v
```

**Specify custom Godot root:**
```bash
python scripts/tools/fix_addon_structure.py --godot-root "C:/path/to/godot/project"
```

**Help:**
```bash
python scripts/tools/fix_addon_structure.py --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - all addons valid |
| 1 | Errors detected or fixes applied |

## Output Format

The script provides structured output with status indicators:

- `[OK]` - Operation successful, addon valid
- `[WARN]` - Non-critical issue detected
- `[ERROR]` - Critical error preventing operation
- `[FIX]` - Fix successfully applied
- `[INFO]` - Informational message (verbose mode only)

## Example Output

```
======================================================================
GODOT ADDON STRUCTURE VALIDATOR
======================================================================

[OK] Found addons directory: C:\Ignotus\addons

Found 3 addon(s)
----------------------------------------------------------------------
[OK] Addon gdUnit4 structure is valid
[OK] Addon godot-xr-tools structure is valid
[WARN] Missing plugin.cfg in godot_rl_agents
----------------------------------------------------------------------

======================================================================
SUMMARY
======================================================================

Warnings (1):
  - Missing plugin.cfg in godot_rl_agents

No errors detected!
======================================================================
```

## How It Works

### Nested Structure Detection

The tool identifies nested addons by checking for:

1. Presence of `addons/` subdirectory within addon
2. Contents of nested `addons/` directory
3. Match with outer addon name or presence of `plugin.cfg`

Example of detected nested structure:
```
addons/
  godot-xr-tools/
    addons/              <-- Detected as nested
      godot-xr-tools/
        plugin.cfg
        hands/
        player/
        ...
```

### Flattening Process

When fixing nested structure:

1. Creates backup: `addon-name_backup_<id>`
2. Extracts nested content to temporary location
3. Clears addon directory
4. Moves extracted content to addon root
5. Verifies `plugin.cfg` exists in final location
6. Restores from backup if verification fails

## Addon Integrity Checks

The tool verifies:

- **Required file**: `plugin.cfg` must exist at addon root
- **Directory structure**: Addon directory must not be empty
- **Nested structure**: No nested `addons/addon-name/` pattern

## Platform Support

- **Windows**: Full support with Windows paths
- **Linux/Mac**: Full support with Unix paths
- **Console Compatibility**: Uses only ASCII characters (no Unicode emojis)

## Security Notes

- Backups are created before any modifications
- Original files are preserved during flattening
- Verification ensures modifications were successful
- Restore capability if verification fails

## Common Issues

### Addon Not Found
```
[ERROR] Addon not found: my-addon
```
**Solution**: Verify addon directory exists in `addons/` folder.

### Missing plugin.cfg
```
[WARN] Missing plugin.cfg in addon-name
```
**Solution**: Addon is incomplete or not a valid Godot addon. Add `plugin.cfg` or remove addon.

### Nested Structure Detected
```
[WARN] Addon godot-xr-tools has nested structure: addons/godot-xr-tools
```
**Solution**: Run with `--fix-all` to flatten automatically.

## Testing

Run the verification test:
```bash
python scripts/tools/fix_addon_structure.py --verify-only
```

This checks all addons without making changes.

## Development Workflow Integration

### Before Committing

```bash
# Verify addon structures
python scripts/tools/fix_addon_structure.py --verify-only

# Fix any issues found
python scripts/tools/fix_addon_structure.py --all
```

### In CI/CD Pipeline

```bash
python scripts/tools/fix_addon_structure.py --verify-only || exit 1
```

Returns exit code 1 if any issues found, suitable for CI failure.

## Technical Details

### Supported Python Versions

- Python 3.7+
- Python 3.8+ (recommended)
- Python 3.11+ (tested)

### Dependencies

Uses only Python standard library:
- `os` - File operations
- `sys` - System interface
- `argparse` - Command line parsing
- `shutil` - High-level file operations
- `pathlib` - Object-oriented filesystem paths
- `typing` - Type hints
- `json` - Future extensibility

### Performance

- Fast directory scanning
- Minimal memory usage
- File operations use `shutil` (efficient)
- Supports large addon trees

## Script Statistics

- Lines of code: 447
- Classes: 1 (AddonStructureValidator)
- Methods: 15
- Functions: 1 (main)
- Test coverage: All major code paths exercised

## Future Enhancements

Possible improvements:
- JSON output format (`--json` flag)
- Per-addon reporting
- Integration with git workflows
- Automatic cleanup of backups
- Performance metrics
- Addon validation schema support

## License

Part of the Ignotus/SpaceTime project.

## Support

For issues or enhancements:
1. Check this documentation
2. Review output messages
3. Run with `-v` flag for verbose details
4. Check exit code (0 = success, 1 = error)
