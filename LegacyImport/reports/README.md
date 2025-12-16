# Reports Archive

This directory contains archived log files, test outputs, and historical reports from the SpaceTime VR project development.

## Directory Structure

### `/archive/`
Contains older log files and reports that have been moved from the project root to reduce clutter while preserving historical data.

## Types of Files Archived

### Editor Logs
- `editor_error_*.txt` - Godot editor error logs from various development sessions
- `editor_log_*.txt` - Godot editor output logs

### Godot Runtime Logs
- `godot_*.log` - Various Godot runtime logs including:
  - Game session logs
  - VR testing logs
  - Compilation checks
  - Feature-specific test logs (particles, terrain, VFX, etc.)

### Server Logs
- `server_*.log` - Python server and API logs

### Test Output Files
- `test_*.log`, `test_*.txt` - Test execution outputs
- `*_test_output.txt` - Various test result files
- `runtime_*.log` - Runtime verification logs

### Compilation Logs
- `compilation_*.log`, `compile_*.log` - Build and compilation check logs
- `wave*_compile_*.log` - Wave-specific compilation logs

### Debug and Error Files
- `debug_*.log`, `debug_*.txt` - Debug output files
- `error_*.txt`, `errors.txt` - Error summary files
- `*_errors.txt` - Specific error reports

### Development Reports
- Various `.txt` files containing detailed development reports, diagrams, and technical documentation that are primarily historical

## Files Retained in Root

The following types of files are typically kept in the project root:

- Recent log files (last few days)
- Important summary files (e.g., `FINAL_SUMMARY.txt`)
- Active workflow files
- Current status and health check files
- Files referenced by active documentation

## Usage Notes

- This archive preserves historical data for reference and debugging
- Files are organized chronologically within the archive
- Most recent files are typically more relevant for active development
- Archive files can be searched when investigating historical issues or patterns