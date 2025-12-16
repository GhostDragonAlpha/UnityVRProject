# Contributing to SpaceTime VR

Thank you for your interest in contributing to SpaceTime VR! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Running Tests Locally](#running-tests-locally)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- Be respectful and considerate
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## Getting Started

### Prerequisites

- **Godot 4.5+**: Download from [godotengine.org](https://godotengine.org)
- **Python 3.10+**: For testing and scripts
- **Git**: Version control
- **GitHub CLI** (optional): For easier workflow management

### Initial Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/spacetime.git
   cd spacetime
   ```

2. **Set up Python virtual environment:**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   # OR
   .venv\Scripts\activate  # Windows
   ```

3. **Install dependencies:**
   ```bash
   pip install -r tests/requirements.txt
   pip install -r tests/http_api/requirements.txt
   pip install -r tests/property/requirements.txt
   ```

4. **Install pre-commit hooks:**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

5. **Install GdUnit4 (for GDScript tests):**
   ```bash
   cd addons
   git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4
   cd ..
   ```

6. **Start Godot with debug services:**
   ```bash
   # Windows
   ./restart_godot_with_debug.bat

   # Linux/Mac
   godot --path "." --dap-port 6006 --lsp-port 6005
   ```

7. **Verify setup:**
   ```bash
   curl http://127.0.0.1:8080/status
   python tests/health_monitor.py
   ```

## Development Workflow

### 1. Create a Feature Branch

Always work on a feature branch:

```bash
git checkout -b feature/my-feature-name
# OR
git checkout -b fix/bug-description
# OR
git checkout -b docs/documentation-update
```

**Branch Naming Convention:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes
- `chore/` - Maintenance tasks

### 2. Make Your Changes

- Write clean, readable code
- Follow existing code style
- Add tests for new functionality
- Update documentation as needed
- Keep commits focused and atomic

### 3. Run Tests Locally

Before committing, ensure all tests pass:

```bash
# Run all tests
python tests/test_runner.py

# Run specific test suite
cd tests/http_api
pytest test_all_endpoints.py -v

# Check coverage
pytest --cov=. --cov-report=term --cov-report=html
```

### 4. Commit Your Changes

Use conventional commit messages:

```bash
git add .
git commit -m "feat: add new scene management endpoint"
```

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(api): add scene validation endpoint"
git commit -m "fix(vr): resolve controller tracking issue"
git commit -m "docs(api): update HTTP API documentation"
git commit -m "test(security): add authentication tests"
git commit -m "chore(deps): update dependencies"
```

### 5. Push and Create Pull Request

```bash
git push origin feature/my-feature-name

# Using GitHub CLI
gh pr create --title "Add new scene management endpoint" --body "Description of changes"

# OR visit GitHub.com to create PR manually
```

### 6. Address Review Feedback

- Respond to all review comments
- Make requested changes
- Push additional commits to the same branch
- Mark conversations as resolved when addressed

### 7. Merge

Once approved:
- Maintainers will merge using squash or rebase
- Delete your feature branch after merge

## Running Tests Locally

### Full Test Suite

```bash
# Comprehensive test runner
python tests/test_runner.py

# With verbose output
python tests/test_runner.py --verbose

# Quick tests only (fast feedback)
python tests/test_runner.py --quick
```

### HTTP API Tests

```bash
cd tests/http_api

# All HTTP API tests
pytest -v

# Specific test file
pytest test_all_endpoints.py -v

# Specific test
pytest test_all_endpoints.py::TestGetCurrentScene::test_get_current_scene_returns_200 -v

# With coverage
pytest --cov=. --cov-report=html
```

### Security Tests

```bash
cd tests/http_api

# All security tests
pytest test_security.py test_security_penetration.py -v

# Only authentication tests
pytest test_security.py::TestAuthentication -v
```

### Property-Based Tests

```bash
cd tests/property

# All property tests
pytest -v

# Specific test file
pytest test_connection_properties.py -v

# With more examples
pytest --hypothesis-max-examples=1000 -v
```

### Integration Tests

```bash
cd tests/http_api

pytest test_integration_workflows.py -v
```

### GDScript Tests

```bash
# From Godot Editor
# Open GdUnit4 panel at bottom
# Click "Run All Tests"

# OR from command line (if GdUnit4 CLI installed)
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit
```

### Performance Tests

```bash
python tests/performance_benchmarks.py
```

### Test Markers

Tests use pytest markers for categorization:

```bash
# Fast tests only
pytest -m fast

# Slow tests only
pytest -m slow

# Security tests only
pytest -m security

# Integration tests only
pytest -m integration
```

## Pre-commit Hooks

Pre-commit hooks automatically run checks before each commit.

### Setup

```bash
pip install pre-commit
pre-commit install
```

### Hooks Included

1. **Black**: Python code formatting
2. **isort**: Import sorting
3. **Flake8**: Python linting
4. **mypy**: Type checking
5. **Bandit**: Security linting
6. **detect-secrets**: Secret detection
7. **yamllint**: YAML validation
8. **Trailing whitespace**: Remove trailing spaces
9. **End of file fixer**: Ensure files end with newline
10. **Quick tests**: Run fast tests

### Running Manually

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run black --all-files
pre-commit run flake8 --all-files

# Skip hooks for a commit (use sparingly)
git commit -m "message" --no-verify
```

### Updating Hooks

```bash
pre-commit autoupdate
```

## Pull Request Guidelines

### Before Creating PR

- [ ] Tests pass locally
- [ ] Pre-commit hooks pass
- [ ] Code follows style guidelines
- [ ] Documentation updated (if applicable)
- [ ] Changelog updated (if applicable)
- [ ] No merge conflicts

### PR Title

Use conventional commit format:
```
feat(api): add scene validation endpoint
```

### PR Description

Include:

1. **Summary**: What does this PR do?
2. **Motivation**: Why is this change needed?
3. **Changes**: List of changes made
4. **Testing**: How was this tested?
5. **Screenshots**: (if UI changes)
6. **Breaking Changes**: (if applicable)
7. **Related Issues**: Link to issues

**Template:**
```markdown
## Summary
Brief description of changes

## Motivation
Why is this change needed?

## Changes
- Added X feature
- Fixed Y bug
- Updated Z documentation

## Testing
- [ ] All tests pass
- [ ] Added new tests for new functionality
- [ ] Manually tested in VR headset
- [ ] Tested on Windows/Linux/Mac

## Screenshots
(if applicable)

## Breaking Changes
None

## Related Issues
Closes #123
```

### PR Review Process

1. **Automated Checks**: CI must pass
   - All tests
   - Security scans
   - Code coverage threshold

2. **Code Review**: At least 1 approval required
   - Reviewers check code quality
   - Verify tests are adequate
   - Ensure documentation is updated

3. **Testing**: Verify functionality
   - Run tests locally
   - Test in development environment
   - Verify in VR headset (if applicable)

4. **Merge**: Maintainer merges after approval

### Review Criteria

Reviewers check:

- **Functionality**: Does it work as intended?
- **Tests**: Are there adequate tests?
- **Code Quality**: Is code clean and maintainable?
- **Performance**: Any performance implications?
- **Security**: Any security concerns?
- **Documentation**: Is documentation updated?
- **Breaking Changes**: Are they necessary and documented?

## Coding Standards

### GDScript

Follow [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):

```gdscript
# Good
class_name MyClass
extends Node

const MAX_SPEED = 100
const GRAVITY = 9.8

var health: int = 100
var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
    initialize_systems()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    queue_free()
```

**Key points:**
- Use `class_name` for reusable classes
- Type hints on all variables and functions
- Constants in UPPER_SNAKE_CASE
- Variables in snake_case
- Functions in snake_case
- 4-space indentation
- Blank line between functions

### Python

Follow [PEP 8](https://pep8.org/):

```python
# Good
from typing import Dict, List, Optional

def process_data(
    data: List[Dict],
    max_items: int = 100,
    filter_empty: bool = True
) -> Optional[Dict]:
    """Process data and return summary.

    Args:
        data: List of data dictionaries
        max_items: Maximum items to process
        filter_empty: Whether to filter empty entries

    Returns:
        Summary dictionary or None if no data
    """
    if not data:
        return None

    processed = []
    for item in data[:max_items]:
        if not filter_empty or item:
            processed.append(transform(item))

    return {"count": len(processed), "items": processed}
```

**Key points:**
- Type hints everywhere
- Docstrings for all public functions
- Line length ≤ 100 characters
- Use Black for formatting
- Use isort for imports

### File Organization

```
scripts/
├── core/              # Core engine systems
│   ├── engine.gd      # Main coordinator
│   └── settings_manager.gd
├── http_api/          # HTTP API implementation
│   ├── http_api_server.gd
│   └── scene_load_monitor.gd
├── player/            # Player controls
└── ui/                # User interface

tests/
├── http_api/          # HTTP API tests
│   ├── test_all_endpoints.py
│   ├── test_security.py
│   └── conftest.py
├── property/          # Property-based tests
└── unit/              # GDScript unit tests
```

## Testing Guidelines

### Test Coverage

- **Minimum**: 80% coverage required
- **Target**: 90% coverage
- All new features must include tests
- All bug fixes must include regression tests

### Writing Tests

**HTTP API Tests:**
```python
def test_endpoint_returns_200(base_url, auth_client):
    """Test that endpoint returns 200 OK."""
    response = auth_client.get(f"{base_url}/endpoint")
    assert response.status_code == 200
    assert "expected_field" in response.json()
```

**Property-Based Tests:**
```python
from hypothesis import given, strategies as st

@given(st.integers(min_value=0, max_value=1000))
def test_property(value):
    """Test property holds for all values."""
    result = function_under_test(value)
    assert result >= 0  # Invariant
```

**GDScript Tests:**
```gdscript
extends GdUnitTestSuite

func test_function_returns_expected_value():
    var result = function_under_test(42)
    assert_that(result).is_equal(84)

func test_function_handles_edge_case():
    var result = function_under_test(0)
    assert_that(result).is_not_null()
```

### Test Organization

- One test file per module
- Group related tests in classes
- Use descriptive test names
- Include docstrings
- Use fixtures for common setup

## Documentation

### Code Documentation

**GDScript:**
```gdscript
## Brief description of class
##
## Detailed explanation of what this class does,
## how it should be used, and any important notes.
class_name MyClass
extends Node

## Brief description of function
##
## Detailed explanation of what function does.
##
## @param param1: Description of parameter
## @param param2: Description of parameter
## @return: Description of return value
func my_function(param1: int, param2: String) -> bool:
    pass
```

**Python:**
```python
def my_function(param1: int, param2: str) -> bool:
    """Brief description of function.

    Detailed explanation of what function does,
    how it should be used, and any important notes.

    Args:
        param1: Description of parameter
        param2: Description of parameter

    Returns:
        Description of return value

    Raises:
        ValueError: When and why this is raised
    """
    pass
```

### README Updates

Update README.md when adding:
- New features
- New dependencies
- New setup steps
- New commands

### API Documentation

Update HTTP API documentation when changing endpoints:
- `addons/godot_debug_connection/HTTP_API.md`
- Include examples
- Document all parameters
- Document error responses

### Changelog

Update `CHANGELOG.md` for all user-facing changes:

```markdown
## [Unreleased]

### Added
- New scene validation endpoint

### Changed
- Improved error messages

### Fixed
- Fixed memory leak in telemetry

### Security
- Updated dependencies to fix CVE-2024-XXXX
```

## Questions?

- **Documentation**: Check [CLAUDE.md](CLAUDE.md) and [CI_CD_GUIDE.md](CI_CD_GUIDE.md)
- **Issues**: Create a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Chat**: Join our Discord (if available)

Thank you for contributing to SpaceTime VR!
