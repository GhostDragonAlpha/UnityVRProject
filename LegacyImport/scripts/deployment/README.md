# Dependency Installation Scripts - Quick Reference

## One-Command Installation

### Install Everything (Recommended)
```bash
# Windows
scripts\deployment\install_all_dependencies.bat

# Linux/Mac
./scripts/deployment/install_all_dependencies.sh
```

## Quick Status Check

```bash
# Windows
scripts\deployment\check_dependencies.bat

# Linux/Mac
./scripts/deployment/check_dependencies.sh
```

## Full Validation

```bash
python scripts/deployment/validate_dependencies.py
```

## Individual Installers

### Export Templates Only
```bash
# Windows
scripts\deployment\install_export_templates.bat

# Linux/Mac
./scripts/deployment/install_export_templates.sh
```

### jq Only
```bash
# Windows
scripts\deployment\install_jq.bat

# Linux/Mac
./scripts/deployment/install_jq.sh
```

## Files in This Directory

| File | Description |
|------|-------------|
| `install_all_dependencies.bat/sh` | Master installer (all dependencies) |
| `install_export_templates.bat/sh` | Godot export templates installer |
| `install_jq.bat/sh` | jq JSON processor installer |
| `validate_dependencies.py` | Comprehensive validation script |
| `check_dependencies.bat/sh` | Quick status dashboard |

## Exit Codes

- `0` - Success
- `1` - Failure (check error messages)

## Documentation

See **DEPENDENCY_AUTOMATION.md** in project root for:
- Detailed usage instructions
- Troubleshooting guide
- CI/CD integration examples
- Maintenance procedures

## Support

For issues or questions:
1. Check DEPENDENCY_AUTOMATION.md troubleshooting section
2. Run validation with report: `python validate_dependencies.py --report debug.json`
3. Check IMMEDIATE_ACTIONS.md for deployment checklist
