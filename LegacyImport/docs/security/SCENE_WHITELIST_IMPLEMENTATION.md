# Scene Whitelist Implementation

**Vulnerability ID:** VULN-004
**CVSS Score:** 9.1 (CRITICAL)
**Status:** FIXED
**Date:** 2025-12-02

## Executive Summary

This document describes the implementation of strict scene whitelist validation to fix VULN-004: Path traversal in scene loading. The vulnerability allowed arbitrary scene loading via the HTTP API, potentially enabling attackers to load system scenes, addon scenes, or traverse the filesystem.

The fix implements a comprehensive whitelist system with:
- Environment-specific whitelists (production/development/test)
- Exact path matching, directory wildcards, and glob patterns
- Blacklist for system/addon scenes
- Path canonicalization to prevent traversal
- Multiple bypass attempt protections

## Vulnerability Details

### Original Issue
The scene loading endpoint (`POST /scene`) accepted arbitrary scene paths without validation:
```gdscript
var scene_path = body.get("scene_path", "res://vr_main.tscn")
# VULNERABLE: No validation of scene_path
tree.call_deferred("change_scene_to_file", scene_path)
```

### Attack Vectors
1. **Path Traversal:** `res://scenes/../addons/malicious.tscn`
2. **System Scene Access:** `res://addons/gdUnit4/src/ui/GdUnitConsole.tscn`
3. **Arbitrary Scene Loading:** `res://.godot/imported/scene.tscn`

## Implementation

### 1. Configuration File

**Location:** `C:/godot/config/scene_whitelist.json`

**Structure:**
```json
{
  "environments": {
    "production": {
      "scenes": ["res://vr_main.tscn"],
      "directories": [],
      "wildcards": []
    },
    "development": {
      "scenes": [
        "res://vr_main.tscn",
        "res://node_3d.tscn",
        "res://scenes/celestial/solar_system.tscn"
      ],
      "directories": [
        "res://tests/",
        "res://tests/integration/"
      ],
      "wildcards": [
        "res://tests/**/*.tscn"
      ]
    },
    "test": {
      "scenes": ["res://vr_main.tscn", "res://node_3d.tscn"],
      "directories": ["res://tests/"],
      "wildcards": ["res://tests/**/*.tscn"]
    }
  },
  "blacklist": {
    "patterns": [
      "res://addons/**/*.tscn",
      "**/.godot/**/*.tscn",
      "**/gdUnit4/**/*.tscn"
    ],
    "exact": []
  },
  "validation_rules": {
    "max_path_length": 256,
    "allow_path_traversal": false,
    "require_res_prefix": true,
    "require_tscn_extension": true
  }
}
```

### 2. Security Configuration Enhancements

**File:** `C:/godot/scripts/http_api/security_config.gd`

**Key Functions:**

#### `load_whitelist_config(environment: String) -> bool`
Loads whitelist configuration from JSON file for specified environment.

```gdscript
static func load_whitelist_config(environment: String = "") -> bool:
    if environment.is_empty():
        environment = _current_environment

    var config_path = "res://config/scene_whitelist.json"
    # Load and parse JSON...
    # Populate _scene_whitelist, _scene_whitelist_directories, etc.
```

#### `validate_scene_path_enhanced(scene_path: String) -> Dictionary`
Enhanced validation with multiple security checks:

```gdscript
static func validate_scene_path_enhanced(scene_path: String) -> Dictionary:
    # 1. Format validation (res://, .tscn, length)
    # 2. Path traversal check (..)
    # 3. Canonicalization
    # 4. Blacklist check
    # 5. Whitelist check (exact, directory, wildcard)
```

**Validation Steps:**
1. **Format Validation**
   - Must start with `res://`
   - Must end with `.tscn`
   - Length ≤ 256 characters

2. **Path Traversal Prevention**
   - Reject any path containing `..`
   - Check before canonicalization

3. **Canonicalization**
   - Remove `.` segments
   - Remove empty segments (`//`)
   - Resolve `..` segments (for display only, already rejected)

4. **Blacklist Check**
   - Check exact blacklist matches
   - Check wildcard pattern matches
   - **Blacklist takes precedence over whitelist**

5. **Whitelist Check**
   - Exact path match
   - Directory prefix match
   - Wildcard pattern match

#### `_matches_wildcard(path: String, pattern: String) -> bool`
Wildcard pattern matching with support for:
- `*` - Matches any characters in a single path segment (no `/`)
- `**` - Matches zero or more path segments

```gdscript
# Examples:
_matches_wildcard("res://tests/test.tscn", "res://tests/*.tscn")  # true
_matches_wildcard("res://tests/unit/test.tscn", "res://tests/**/*.tscn")  # true
_matches_wildcard("res://tests/unit/sub/test.tscn", "res://tests/**/*.tscn")  # true
```

#### `_canonicalize_path(path: String) -> String`
Path normalization:
```gdscript
_canonicalize_path("res://scenes//test.tscn")  # → "res://scenes/test.tscn"
_canonicalize_path("res://scenes/./test.tscn")  # → "res://scenes/test.tscn"
_canonicalize_path("res://scenes/sub/../test.tscn")  # → "res://scenes/test.tscn"
```

#### `_is_blacklisted(scene_path: String) -> bool`
Checks if path is in blacklist (exact or pattern match).

### 3. Scene Router Updates

**File:** `C:/godot/scripts/http_api/scene_router.gd`

Updated to use enhanced validation:
```gdscript
# OLD (VULNERABLE):
var scene_validation = SecurityConfig.validate_scene_path(scene_path)

# NEW (SECURE):
var scene_validation = SecurityConfig.validate_scene_path_enhanced(scene_path)
```

### 4. Whitelist Management API

**File:** `C:/godot/scripts/http_api/whitelist_router.gd`

New HTTP API endpoints for whitelist management:

#### `GET /whitelist`
Query current whitelist configuration.

**Response:**
```json
{
  "success": true,
  "whitelist": {
    "environment": "development",
    "exact_scenes": ["res://vr_main.tscn", "res://node_3d.tscn"],
    "directories": ["res://tests/"],
    "wildcards": ["res://tests/**/*.tscn"],
    "blacklist_patterns": ["res://addons/**/*.tscn"],
    "blacklist_exact": []
  }
}
```

#### `POST /whitelist` (Admin Operations)

**Actions:**

**Add Scene:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "add_scene", "scene_path": "res://new_scene.tscn"}'
```

**Add Directory:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "add_directory", "dir_path": "res://new_scenes/"}'
```

**Add Wildcard:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "add_wildcard", "pattern": "res://custom/**/*.tscn"}'
```

**Set Environment:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "set_environment", "environment": "production"}'
```

**Reload Config:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "reload"}'
```

**Validate Scene:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "validate", "scene_path": "res://test.tscn"}'
```

### 5. Comprehensive Tests

**File:** `C:/godot/tests/security/test_scene_whitelist.gd`

Test suite covers:
- ✅ Exact scene matching (allowed/rejected)
- ✅ Wildcard pattern matching (`*`, `**`)
- ✅ Blacklist override
- ✅ Path traversal attempts (`..`, encoded)
- ✅ Invalid formats (no `res://`, wrong extension)
- ✅ Canonicalization
- ✅ Directory whitelisting
- ✅ Environment switching
- ✅ Bypass attempts (null bytes, unicode, backslashes, absolute paths)
- ✅ Case sensitivity
- ✅ Special characters
- ✅ Performance with large whitelists
- ✅ Config reload

**Run Tests:**
```bash
# From Godot editor (GdUnit4 panel)
# OR command line:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --test-suite tests/security/test_scene_whitelist.gd
```

## Security Guarantees

### ✅ Path Traversal Protection
- All `..` sequences rejected before validation
- Paths canonicalized to prevent `./` and `//` tricks
- No filesystem access outside `res://`

### ✅ Blacklist Enforcement
- System scenes (`res://addons/**`) always blocked
- Godot internal scenes (`**/.godot/**`) always blocked
- GdUnit4 scenes never loadable via API

### ✅ Environment Isolation
- **Production:** Only essential scenes (e.g., `vr_main.tscn`)
- **Development:** Test scenes and debugging scenes allowed
- **Test:** Test scenes allowed, no production restrictions

### ✅ Defense in Depth
1. Format validation (prefix, extension, length)
2. Path traversal check
3. Canonicalization
4. Blacklist check
5. Whitelist verification

### ✅ Performance
- O(n) complexity for exact matches
- O(n*m) for wildcard matches (n=paths, m=patterns)
- Optimized with early returns
- Tested with 1000+ whitelist entries

## Usage Examples

### Development Workflow

**1. Start Godot with development environment:**
```bash
# Environment is loaded from config automatically
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**2. Load a test scene:**
```bash
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://tests/test_scene.tscn"}'
```

**3. Query whitelist:**
```bash
curl http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN"
```

### Production Deployment

**1. Set environment to production:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "set_environment", "environment": "production"}'
```

**2. Only whitelisted scenes loadable:**
```bash
# SUCCESS:
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'

# REJECTED:
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://tests/test_scene.tscn"}'
# → 403 Forbidden: Scene not in whitelist for environment: production
```

## Configuration Management

### Adding Scenes to Whitelist

**Option 1: Update config file (persistent)**
Edit `config/scene_whitelist.json` and reload:
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "reload"}'
```

**Option 2: Runtime addition (temporary)**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "add_scene", "scene_path": "res://new_scene.tscn"}'
```

### Environment Setup

**Development:**
```json
{
  "scenes": ["res://vr_main.tscn", "res://node_3d.tscn"],
  "directories": ["res://tests/"],
  "wildcards": ["res://tests/**/*.tscn", "res://scenes/**/*.tscn"]
}
```

**Production:**
```json
{
  "scenes": ["res://vr_main.tscn"],
  "directories": [],
  "wildcards": []
}
```

## Attack Surface Reduction

| Attack Vector | Before (Vulnerable) | After (Fixed) |
|---------------|---------------------|---------------|
| Path Traversal | ❌ Possible | ✅ Blocked |
| Addon Scene Loading | ❌ Possible | ✅ Blacklisted |
| System Scene Access | ❌ Possible | ✅ Blacklisted |
| Arbitrary Scene Loading | ❌ Possible | ✅ Whitelist Only |
| Encoding Bypasses | ❌ Possible | ✅ Canonicalized |
| Case Sensitivity | ⚠️ Inconsistent | ✅ Consistent |

## Migration Guide

### For Developers

**1. Update scene loading code:**
```gdscript
# OLD:
SecurityConfig.validate_scene_path(scene_path)

# NEW:
SecurityConfig.validate_scene_path_enhanced(scene_path)
```

**2. Add your scenes to whitelist:**
Edit `config/scene_whitelist.json` and add to appropriate environment.

**3. Test in development environment:**
```bash
godot --path "C:/godot"
# Verify scenes load correctly
```

### For Production

**1. Review whitelist:**
Ensure only necessary scenes are in production whitelist.

**2. Set environment:**
```bash
curl -X POST http://127.0.0.1:8080/whitelist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "set_environment", "environment": "production"}'
```

**3. Monitor logs:**
```bash
# Check for rejected scene loads
grep "not in whitelist" godot.log
```

## Performance Considerations

- **Config Loading:** O(n) where n = number of whitelist entries
- **Validation:** O(n+m+p) where n=exact, m=directories, p=wildcards
- **Canonicalization:** O(k) where k = path length
- **Wildcard Matching:** O(p*k) where p=pattern length, k=path length

**Optimization Tips:**
1. Use exact matches when possible (fastest)
2. Use directory prefixes instead of wildcards
3. Minimize number of wildcard patterns
4. Keep blacklist small (checked first)

## Monitoring and Auditing

All whitelist validation failures are logged:
```
[Security] Scene not in whitelist: res://malicious.tscn
[Security] Environment: development
[Security] Attempted by: 127.0.0.1
```

**Audit Logs:**
- All scene loading attempts logged
- Failed validations logged with reason
- Environment changes logged
- Whitelist modifications logged

## Future Enhancements

Potential improvements:
1. **Content Security Policy** for scenes
2. **Scene signing/verification**
3. **Rate limiting per scene**
4. **Scene dependency validation**
5. **Automated whitelist generation from project**

## References

- **VULN-004 Report:** `docs/security/VULN-004_SCENE_LOADING_PATH_TRAVERSAL.md`
- **Security Audit:** `docs/security/SECURITY_AUDIT_2025-12-02.md`
- **HTTP API Docs:** `addons/godot_debug_connection/HTTP_API.md`
- **Configuration:** `config/scene_whitelist.json`
- **Tests:** `tests/security/test_scene_whitelist.gd`

## Support

For questions or issues:
1. Check test suite for examples
2. Review configuration file
3. Check audit logs
4. Consult HTTP API documentation

---

**Implementation Date:** 2025-12-02
**Status:** ✅ COMPLETE
**Severity:** CRITICAL (CVSS 9.1) → **FIXED**
