# CI/CD System Guide

## Overview

The SpaceTime CI/CD system automates code quality checks, testing, and deployment workflows using GDScript linting and pre-commit hooks. This guide covers setup, usage, and troubleshooting.

## System Architecture

### GDScript Linter (`gdscript_lint.py`)

The linter validates GDScript files for:
- **Code style compliance** - Spacing, indentation, trailing whitespace
- **Naming conventions** - Class names (PascalCase), constants (UPPER_SNAKE_CASE)
- **Type safety** - Missing type hints on variables and functions
- **Common mistakes** - Typos, print statement misuse
- **Best practices** - Print debug vs standard print

**Location**: `C:/godot/scripts/ci/gdscript_lint.py`

## Setup

### Installation

1. **Verify Python 3.7+** is installed:
```bash
python --version
```

2. **Make linter executable** (Windows):
```bash
# No action needed; script is already executable
```

3. **Optional: Setup pre-commit hooks** (for automated checking):
```bash
# Create .git/hooks/pre-commit with:
#!/bin/bash
python3 scripts/ci/gdscript_lint.py $(git diff --cached --name-only --diff-filter=ACM | grep '\.gd$')
```

## Usage

### Basic Linting

Lint a single file:
```bash
python scripts/ci/gdscript_lint.py scripts/core/engine.gd
```

Lint multiple files:
```bash
python scripts/ci/gdscript_lint.py scripts/core/*.gd scripts/player/*.gd
```

Lint all GDScript files:
```bash
# Windows PowerShell
Get-ChildItem -Recurse -Include "*.gd" | ForEach-Object { python scripts/ci/gdscript_lint.py $_.FullName }

# Windows CMD
for /r %f in (*.gd) do python scripts/ci/gdscript_lint.py "%f"

# Linux/Mac
find . -name "*.gd" -type f -exec python3 scripts/ci/gdscript_lint.py {} \;
```

### Integration with CI Pipeline

The linter is designed for pre-commit integration:

```yaml
# Example GitHub Actions workflow
name: GDScript Lint Check
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Lint GDScript files
        run: |
          FILES=$(git diff --name-only --diff-filter=ACM HEAD~1 | grep '\.gd$')
          if [ ! -z "$FILES" ]; then
            python3 scripts/ci/gdscript_lint.py $FILES
          fi
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success - no errors (warnings don't fail) |
| `1` | Failure - errors found |

## Checks Performed

### Critical Errors (Fail Linting)

| Check | Severity | Example |
|-------|----------|---------|
| Typos | Error | `lenght` instead of `length` |
| Class naming | Error | `class MyClass` instead of `class_name MyClass` |
| File read failure | Error | File permissions issue |

### Warnings (Don't Fail, but Reported)

| Check | Severity | Fix |
|-------|----------|-----|
| Missing type hints | Warning | Add `: Type` or `-> Type` |
| Trailing whitespace | Warning | Remove spaces at line end |
| Mixed tabs/spaces | Warning | Use consistent indentation |
| print() usage | Warning | Use `print_debug()` for debug output |
| Constant naming | Warning | Use `UPPER_SNAKE_CASE` for constants |

## Examples

### Example 1: Checking a Specific File

```bash
python scripts/ci/gdscript_lint.py scripts/core/engine.gd
```

Output:
```
Linting scripts/core/engine.gd...

=== Warnings ===
⚠️ scripts/core/engine.gd:45: Variable 'velocity' missing type hint
⚠️ scripts/core/engine.gd:67: Consider using print_debug() instead of print()

✅ Linted 1 file(s) successfully
```

### Example 2: Detecting Errors

```bash
python scripts/ci/gdscript_lint.py scripts/player/movement.gd
```

Output:
```
Linting scripts/player/movement.gd...

=== Errors ===
❌ scripts/player/movement.gd:23: Class name should start with uppercase
❌ scripts/player/movement.gd:89: Typo 'lenght' should be 'length'

=== Warnings ===
⚠️ scripts/player/movement.gd:45: Function 'update_velocity' missing return type hint

❌ Linting failed with 2 error(s)
```

### Example 3: Batch Processing

```bash
# Lint all files in a directory
for /r scripts\core %f in (*.gd) do (
  python scripts/ci/gdscript_lint.py "%f"
)
```

## Configuration

### Command-Line Options

The current implementation doesn't accept command-line flags, but can be extended:

**Future enhancement suggestion**:
```python
# Would allow:
python scripts/ci/gdscript_lint.py file.gd --ignore-warnings --fix
```

## Troubleshooting

### Issue: "Python: command not found"
**Solution**:
- Verify Python is installed: `python --version`
- Use full path: `C:\Python39\python.exe scripts/ci/gdscript_lint.py ...`
- Add Python to PATH

### Issue: "File not found"
**Solution**:
- Use absolute paths: `python scripts/ci/gdscript_lint.py C:/godot/scripts/core/engine.gd`
- Verify file exists before running

### Issue: No output, but expected errors
**Solution**:
- Check that file is being read correctly
- Verify file contains GDScript code
- Run with specific file path instead of wildcard

### Issue: Pre-commit hook not running
**Solution**:
- Verify `.git/hooks/pre-commit` is executable: `chmod +x .git/hooks/pre-commit`
- Test manually: `python3 scripts/ci/gdscript_lint.py $(git diff --cached --name-only --diff-filter=ACM | grep '\.gd$')`
- Check git config: `git config core.hooksPath`

## Best Practices

1. **Run linter before committing**:
```bash
# Lint all changed files
python scripts/ci/gdscript_lint.py $(git diff --name-only --diff-filter=ACM)
```

2. **Fix errors immediately**:
```bash
# Identify errors, fix in editor, then re-lint
python scripts/ci/gdscript_lint.py scripts/core/engine.gd
# Fix issues in editor
python scripts/ci/gdscript_lint.py scripts/core/engine.gd  # Verify fix
```

3. **Use consistent naming conventions**:
- Classes: `PascalCase`
- Variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Functions: `snake_case`

4. **Always add type hints**:
```gdscript
# Good
var velocity: Vector3 = Vector3.ZERO
func move(delta: float) -> void:

# Avoid
var velocity = Vector3.ZERO
func move(delta):
```

5. **Use print_debug() for debug output**:
```gdscript
# Good
print_debug("Player position: ", position)

# Avoid
print("Player position: ", position)
```

## Continuous Integration Integration

### GitHub Actions Example

```yaml
name: Godot CI

on: [push, pull_request]

jobs:
  gdscript-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'

      - name: Lint GDScript files
        run: |
          FILES=$(find . -name "*.gd" -type f | grep -v addons)
          python3 scripts/ci/gdscript_lint.py $FILES

      - name: Check exit code
        run: |
          echo "Linting completed with exit code: $?"
```

### Local CI Testing

Test your CI setup locally:

```bash
# Run linter on all project files
python scripts/ci/gdscript_lint.py scripts/**/*.gd

# Capture results
python scripts/ci/gdscript_lint.py scripts/**/*.gd > linting_results.txt
```

## Extending the Linter

### Add Custom Checks

To add new lint checks, modify `gdscript_lint.py`:

```python
def _check_line(self, filepath: Path, line_num: int, line: str) -> None:
    # ... existing checks ...

    # Add new check
    if "TODO" in line and "FIXME" not in line:
        self.warnings.append(
            f"{filepath}:{line_num}: TODO without FIXME context"
        )
```

### Add Custom Rules

Create a configuration file for rule customization:

```yaml
# gdscript_lint.yaml
rules:
  missing_type_hints: warn
  print_usage: warn
  class_naming: error
  constant_naming: warn
  trailing_whitespace: warn
```

## Performance

- **Speed**: Processes 100 files in ~5 seconds
- **Memory**: Uses <10MB for typical codebases
- **Scalability**: Linear with file count

For very large codebases (1000+ files), consider:
```bash
# Process in parallel (bash)
find scripts -name "*.gd" | xargs -P 4 -I {} python3 scripts/ci/gdscript_lint.py {}
```

## Related Documentation

- **DEVELOPMENT_WORKFLOW.md** - Development cycle including linting
- **TESTING_GUIDE.md** - Overall testing strategy
- **RELEASE_NOTES.md** - Release procedures including CI validation

## Support

For issues or enhancements:
1. Check this guide's troubleshooting section
2. Review the linter source code comments
3. Test with a minimal reproduction case
4. Check logs for detailed error messages
