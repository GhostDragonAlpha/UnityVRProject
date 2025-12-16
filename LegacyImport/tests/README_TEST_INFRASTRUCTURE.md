# Test Infrastructure Overview

Three comprehensive test infrastructure tools for the SpaceTime VR project.

## Quick Start

```bash
# 1. Test Runner - Run all tests
python tests/test_runner.py --parallel

# 2. Health Monitor - Check system health
python tests/health_monitor.py --once

# 3. Feature Validator - Validate features
python tests/feature_validator.py
```

## Tools Summary

| Tool | Purpose | Main Use Case |
|------|---------|---------------|
| `test_runner.py` | Run all tests (GDScript + Python) | CI/CD pipelines, pre-commit |
| `health_monitor.py` | Monitor system health in real-time | Development, debugging |
| `feature_validator.py` | Validate features work correctly | Regression testing, pre-release |

## Common Workflows

### Development Workflow
```bash
# Terminal 1: Start Godot
python godot_editor_server.py --port 8090 --auto-load-scene

# Terminal 2: Monitor health
python tests/health_monitor.py

# Terminal 3: Run tests after changes
python tests/test_runner.py --filter my_feature
```

### Pre-Commit Workflow
```bash
python tests/feature_validator.py --hook
python tests/test_runner.py
```

### CI/CD Workflow
```bash
python tests/health_monitor.py --once
python tests/feature_validator.py --ci --json report.json
python tests/test_runner.py --parallel --no-color
```

## Dependencies

All tools require:
- Python 3.8+ (project uses 3.11.9)
- `requests` library
- `psutil` library (for health_monitor)

Install dependencies:
```bash
pip install requests psutil
```

For GDScript tests, install GdUnit4:
```bash
cd addons
git clone https://github.com/MikeSchulze/gdUnit4.git
```

## Full Documentation

See **TEST_INFRASTRUCTURE_CREATED.md** in project root for complete documentation with usage examples, exit codes, and integration guides.

## Help

Each tool has built-in help:
```bash
python tests/test_runner.py --help
python tests/health_monitor.py --help
python tests/feature_validator.py --help
```
