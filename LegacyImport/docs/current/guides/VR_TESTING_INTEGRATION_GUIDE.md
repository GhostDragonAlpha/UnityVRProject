# VR Testing Integration Guide

**Last Updated:** 2025-12-09
**Status:** Production Ready
**Related:** `VR_TESTING_INFRASTRUCTURE.md`, `tests/vr/README.md`

## Overview

This guide provides step-by-step instructions for integrating the VR testing infrastructure into development workflows and CI/CD pipelines.

## Quick Start

### Local Development

```bash
# Run all VR tests
run_vr_tests.bat

# Or with Python
python tests/test_vr_suite.py --verbose
```

### CI/CD Pipeline

Add to your CI/CD configuration:

```yaml
# GitHub Actions example
- name: Run VR Tests
  run: python tests/test_vr_suite.py --timeout 300
```

## Integration Checklist

### ✅ Local Development Setup

- [x] GdUnit4 installed in `addons/gdUnit4/`
- [x] Python 3.8+ installed
- [x] Godot 4.5+ available
- [x] Test files created in `tests/vr/`
- [x] Python wrapper created: `tests/test_vr_suite.py`
- [x] Batch launcher created: `run_vr_tests.bat`

### ✅ Test Implementation

- [x] 12 comprehensive test functions
- [x] All 5 VR scenes covered
- [x] Proper cleanup (memory leak prevention)
- [x] Async support for scene loading
- [x] Graceful OpenXR fallback handling

### ⏳ CI/CD Integration (Next Steps)

- [ ] Add VR tests to GitHub Actions workflow
- [ ] Add VR tests to GitLab CI pipeline
- [ ] Configure test result artifacts
- [ ] Set up test failure notifications
- [ ] Add performance benchmarks

### ⏳ Monitoring and Reporting

- [ ] Integrate with `system_health_check.py`
- [ ] Add to `run_all_tests.py`
- [ ] Set up test result dashboard
- [ ] Configure alerts for test failures

## CI/CD Integration Examples

### GitHub Actions

Create `.github/workflows/vr-tests.yml`:

```yaml
name: VR Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  vr-tests:
    runs-on: windows-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Cache Godot
      uses: actions/cache@v3
      with:
        path: ~/godot
        key: godot-4.5.1-${{ runner.os }}

    - name: Download Godot
      run: |
        if (-not (Test-Path "~/godot/Godot.exe")) {
          New-Item -Path ~/godot -ItemType Directory -Force
          Invoke-WebRequest -Uri "https://downloads.tuxfamily.org/godotengine/4.5.1/Godot_v4.5.1-stable_win64.exe.zip" -OutFile godot.zip
          Expand-Archive godot.zip -DestinationPath ~/godot
        }

    - name: Run VR Tests
      run: |
        python tests/test_vr_suite.py --godot-path "$HOME/godot/Godot_v4.5.1-stable_win64_console.exe" --timeout 300 --verbose

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: vr-test-results
        path: test-results/
```

### GitLab CI

Add to `.gitlab-ci.yml`:

```yaml
stages:
  - test

vr-tests:
  stage: test
  image: python:3.11

  before_script:
    - apt-get update && apt-get install -y wget unzip xvfb
    - wget https://downloads.tuxfamily.org/godotengine/4.5.1/Godot_v4.5.1-stable_linux_headless.64.zip
    - unzip Godot_v4.5.1-stable_linux_headless.64.zip -d /opt/godot
    - chmod +x /opt/godot/Godot_v4.5.1-stable_linux_headless.64

  script:
    - python tests/test_vr_suite.py --godot-path "/opt/godot/Godot_v4.5.1-stable_linux_headless.64" --timeout 300 --verbose

  artifacts:
    when: always
    paths:
      - test-results/
    reports:
      junit: test-results/junit.xml

  tags:
    - linux
```

### Jenkins

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                script {
                    // Install Python dependencies
                    bat 'python --version'
                }
            }
        }

        stage('Run VR Tests') {
            steps {
                script {
                    def exitCode = bat(
                        script: 'python tests\\test_vr_suite.py --timeout 300 --verbose',
                        returnStatus: true
                    )

                    if (exitCode != 0) {
                        error("VR tests failed with exit code ${exitCode}")
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'test-results/**', allowEmptyArchive: true
        }
    }
}
```

## Integration with Existing Test Infrastructure

### Add to `run_all_tests.py`

Edit `run_all_tests.py` to include VR tests:

```python
def run_vr_tests(verbose: bool = False) -> bool:
    """Run VR initialization tests."""
    print("\n" + "=" * 70)
    print("VR INITIALIZATION TESTS")
    print("=" * 70 + "\n")

    cmd = [
        sys.executable,
        "tests/test_vr_suite.py"
    ]

    if verbose:
        cmd.append("--verbose")

    result = subprocess.run(cmd, cwd=PROJECT_ROOT)
    return result.returncode == 0

# Add to main test runner
def main():
    # ... existing code ...

    # Run VR tests
    vr_tests_passed = run_vr_tests(args.verbose)
    all_passed = all_passed and vr_tests_passed

    # ... existing code ...
```

### Add to `system_health_check.py`

Edit `system_health_check.py` to include VR test status:

```python
def check_vr_test_status() -> dict:
    """Check VR test infrastructure status."""
    status = {
        'vr_tests_available': False,
        'gdunit4_installed': False,
        'test_file_exists': False,
        'issues': []
    }

    # Check GdUnit4
    gdunit_path = PROJECT_ROOT / "addons" / "gdUnit4"
    if gdunit_path.exists():
        status['gdunit4_installed'] = True
    else:
        status['issues'].append("GdUnit4 addon not installed")

    # Check test file
    test_file = PROJECT_ROOT / "tests" / "vr" / "test_vr_initialization.gd"
    if test_file.exists():
        status['test_file_exists'] = True
    else:
        status['issues'].append("VR test file not found")

    status['vr_tests_available'] = (
        status['gdunit4_installed'] and
        status['test_file_exists']
    )

    return status
```

## Pre-Commit Hook Integration

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook to run VR tests

echo "Running VR tests..."

python tests/test_vr_suite.py --timeout 120

if [ $? -ne 0 ]; then
    echo "VR tests failed. Commit aborted."
    exit 1
fi

echo "VR tests passed!"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Continuous Monitoring

### Test Metrics to Track

1. **Test Count:** 12 tests (current)
2. **Pass Rate:** Target 100%
3. **Execution Time:** Target < 60 seconds
4. **Coverage:** All 5 VR scenes tested

### Alerting

Set up alerts for:
- Test failures (any test fails)
- Execution time > 120 seconds
- New VR scene added without tests
- GdUnit4 version updates

## Best Practices

### 1. Run Tests Before Every Commit

```bash
# Add to development workflow
git add .
run_vr_tests.bat
git commit -m "Your commit message"
```

### 2. Run Tests After Scene Changes

When modifying VR scenes:
1. Make changes to scene
2. Run VR tests: `run_vr_tests.bat`
3. Fix any failures
4. Commit changes

### 3. Add New Scenes to Test Suite

When creating new VR scenes:
1. Create scene following VR initialization pattern
2. Add scene path to `VR_SCENES` constant in `test_vr_initialization.gd`
3. Run tests to verify
4. Commit scene and updated tests together

### 4. Monitor Test Performance

Track test execution time:
```bash
python tests/test_vr_suite.py --verbose 2>&1 | grep "completed in"
```

## Troubleshooting Integration Issues

### Issue: Tests Fail in CI but Pass Locally

**Possible Causes:**
- Different Godot versions
- Missing dependencies
- Timeout too short
- Headless mode issues

**Solutions:**
1. Use same Godot version in CI as local
2. Verify all dependencies installed
3. Increase timeout: `--timeout 600`
4. Check CI logs for specific errors

### Issue: Tests Take Too Long in CI

**Solutions:**
1. Use cached Godot installation
2. Run tests in parallel (if multiple test files)
3. Optimize scene loading
4. Use faster CI runners

### Issue: OpenXR Not Available in CI

**Expected Behavior:**
- Tests should still pass
- Structure validation continues
- VR-specific tests gracefully skipped

**Verify:**
```bash
python tests/test_vr_suite.py --verbose 2>&1 | grep "OpenXR"
```

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Total Execution Time | < 60s | ~30s |
| Individual Test Time | < 5s | ~2s |
| Scene Load Time | < 2s | ~1s |
| Memory Usage | < 500MB | ~200MB |

## Next Steps

### Short Term (1-2 weeks)
- [ ] Integrate with GitHub Actions
- [ ] Add to pre-commit hooks
- [ ] Set up test result dashboard

### Medium Term (1 month)
- [ ] Add performance benchmarks
- [ ] Implement test result history
- [ ] Create test coverage reports

### Long Term (3 months)
- [ ] Automated regression testing
- [ ] Performance trend analysis
- [ ] Integration with monitoring tools

## Resources

- **Test Suite:** `tests/vr/test_vr_initialization.gd`
- **Python Wrapper:** `tests/test_vr_suite.py`
- **Documentation:** `tests/vr/README.md`
- **Implementation Summary:** `VR_TESTING_INFRASTRUCTURE.md`
- **Batch Launcher:** `run_vr_tests.bat`

## Support

For issues or questions:
1. Check `tests/vr/README.md` troubleshooting section
2. Review `VR_TESTING_INFRASTRUCTURE.md`
3. Run tests with `--verbose` flag
4. Check Godot console output

## Validation

To verify integration is complete:

```bash
# 1. Run tests locally
run_vr_tests.bat

# 2. Verify all tests pass
# Expected: 12/12 tests passed

# 3. Check exit code
echo $?  # Should be 0

# 4. Run with verbose mode
python tests/test_vr_suite.py --verbose

# 5. Verify prerequisites
python tests/test_vr_suite.py --help
```

---

**Status:** Integration guide complete
**Next Step:** Implement CI/CD pipeline integration
**Owner:** Development Team
**Priority:** High (for production readiness)
