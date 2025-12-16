# Dual HTTP API System Resolution

## Issue

The SpaceTime project had two conflicting HTTP API systems creating confusion:

1. **GodotBridge** (Legacy) - Port 8080, disabled in autoload but plugin still enabled
2. **HttpApiServer** (Modern) - Port 8080, the actual active system

This dual system caused confusion about which API to use and where to direct requests.

## Resolution Implemented

The project has been clarified to establish a single, clear API hierarchy:

### Current Architecture

```
Developer/AI Agent
       │
       ├─→ Port 8090 (Python Server)     [OPTIONAL: Process management layer]
       │         │
       │    Proxies to ↓
       │
       └─→ Port 8080 (HttpApiServer)     [PRIMARY: Active REST API]
                   │
                   ├─→ Port 8081 (Telemetry WebSocket)
                   ├─→ Port 8087 (Service Discovery UDP)
                   │
       ╳ Port 8081 (GodotBridge)         [DEPRECATED: Disabled - DO NOT USE]
```

## Changes Made

### 1. Configuration Cleanup (project.godot)

**Status:** Already correct, clarified with comments

**Current state (correct):**
```ini
[autoload]
ResonanceEngine="*res://scripts/core/engine.gd"
HttpApiServer="*res://scripts/http_api/http_api_server.gd"
SceneLoadMonitor="*res://scripts/http_api/scene_load_monitor.gd"
#GodotBridge="*res://addons/godot_debug_connection/godot_bridge.gd"  # DISABLED - Deprecated
#TelemetryServer="*res://addons/godot_debug_connection/telemetry_server.gd"  # DISABLED
SettingsManager="*res://scripts/core/settings_manager.gd"
```

**Plugin status (kept for reference):**
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_debug_connection/plugin.cfg", "res://addons/godottpd/plugin.cfg", "res://addons/gdUnit4/plugin.cfg")
```

**Decision:** Plugin remains enabled because it contains valuable reference code for security patterns.

### 2. Documentation Updates

#### CLAUDE.md
- Updated "Godot HTTP API System" section to clarify HttpApiServer is active
- Changed port references from 8080 to 8080
- Added clear "Legacy Debug Connection Addon" section explaining deprecation
- Updated port table with status column
- Updated troubleshooting section with correct port numbers

#### GodotBridge Header Comment
- Added clear DEPRECATION NOTICE at top of file
- Explained status: disabled in autoload, retained for reference
- Listed reasons for deprecation
- Added migration guidance

#### HttpApiServer Header Comment
- Added prominent "ACTIVE Production HTTP API" designation
- Explained it replaces deprecated GodotBridge
- Listed all features clearly
- Added migration note

### 3. New Documentation

#### API_MIGRATION_GUIDE.md
Comprehensive guide covering:
- Current active system (HttpApiServer on 8080)
- Deprecated system (GodotBridge on 8080)
- Complete configuration status
- Port reference table
- Step-by-step migration instructions
- Endpoint mapping (old vs. new)
- Troubleshooting guide
- Architecture diagram
- Summary comparison table

#### API_QUICK_REFERENCE.md
Developer quick reference covering:
- At-a-glance port and usage information
- Common commands with examples
- Files to remember
- Troubleshooting
- Migration checklist
- Key endpoints table

#### DUAL_API_SYSTEM_RESOLUTION.md (this file)
Meta-documentation explaining the resolution process.

## Decision Rationale

### Why HttpApiServer (8080) is Active

1. **REST API Simplicity:** No DAP/LSP protocol complexity
2. **Security:** JWT authentication, rate limiting, RBAC built-in
3. **Performance:** Binary telemetry protocol, GZIP compression
4. **Maintainability:** Cleaner codebase, easier to extend
5. **AI Integration:** REST is simpler for AI assistants
6. **Proven Technology:** Uses godottpd library

### Why GodotBridge (8080) is Deprecated

1. **Protocol Overhead:** DAP/LSP are complex for simple REST needs
2. **Weak Security:** Manual token implementation, no rate limiting
3. **No Audit Logging:** Couldn't track API operations
4. **Performance Overhead:** Standard protocol without compression
5. **Maintenance Burden:** Dual system creates confusion

### Why the Plugin is Retained

The addon contains valuable reference implementations:
- **Security Patterns:** Rate limiting, CSRF token management
- **Telemetry Server:** WebSocket streaming implementation
- **Token Management:** JWT token handling examples
- **Historical Context:** Useful for debugging integration issues
- **Reusable Components:** Some code can be adapted for future use

## Port Assignment Summary

| Port | Service | Protocol | Active | Use For |
|------|---------|----------|--------|---------|
| 8080 | HttpApiServer | HTTP REST | YES | All new API calls |
| 8081 | Telemetry | WebSocket | YES | Real-time monitoring |
| 8087 | Discovery | UDP | YES | Service announcement |
| 8090 | Python Server | HTTP | YES | Process management |
| **8081** | **GodotBridge** | **HTTP** | **NO** | **DO NOT USE** |
| 6006 | DAP | TCP | NO | (Deprecated) |
| 6005 | LSP | TCP | NO | (Deprecated) |

## Migration Path for Users

### Quick Migration (Code using 8080)

1. Update port: `8080` → `8080`
2. Add authentication: Include `-H "Authorization: Bearer $TOKEN"`
3. Replace endpoint paths: Use REST operations instead of DAP commands
4. Test with curl, then integrate

Example:
```bash
# OLD (don't use)
curl http://localhost:8080/status

# NEW (use this)
TOKEN=$(grep "API TOKEN:" godot.log | sed 's/.*API TOKEN: //')
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status
```

### Testing the Change

```bash
# 1. Start Godot with debug output
godot --path "C:/godot" --editor

# 2. Wait for startup and find token in output
# Look for: "[HttpApiServer] API TOKEN: xxx"

# 3. Test new API (8080)
TOKEN="<from_logs>"
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status

# 4. Verify old API is disabled (should fail)
curl http://localhost:8080/status
# Expected: Connection refused (port not listening)
```

## Verification Checklist

- [x] GodotBridge disabled in autoload (project.godot line 23 commented)
- [x] HttpApiServer enabled as autoload (project.godot line 21)
- [x] godot_debug_connection plugin remains enabled for reference
- [x] CLAUDE.md updated with correct port references
- [x] HttpApiServer header comment explains it's active
- [x] GodotBridge header comment explains it's deprecated
- [x] API_MIGRATION_GUIDE.md created with comprehensive details
- [x] API_QUICK_REFERENCE.md created for developers
- [x] Port table updated with status information
- [x] Troubleshooting section updated with correct ports

## Impact Assessment

### No Breaking Changes
- GodotBridge was already disabled, so existing code must already be updated
- Python server (8090) continues to work unchanged
- Telemetry (8081) continues to work unchanged
- All new code should use 8080

### Documentation Clarity
- Developers now have clear guidance on which API to use
- Migration path is well-documented
- Common mistakes are addressed in troubleshooting

### Code Quality
- No code changes required in functional systems
- Only comments and documentation updated
- Preserved valuable reference implementations in legacy addon

## Files Modified

1. **C:/godot/CLAUDE.md** - Architecture documentation updated
2. **C:/godot/addons/godot_debug_connection/godot_bridge.gd** - Deprecation comment added
3. **C:/godot/scripts/http_api/http_api_server.gd** - Active system comment added

## Files Created

1. **C:/godot/API_MIGRATION_GUIDE.md** - Comprehensive migration guide
2. **C:/godot/API_QUICK_REFERENCE.md** - Developer quick reference
3. **C:/godot/DUAL_API_SYSTEM_RESOLUTION.md** - This resolution document

## Conclusion

The dual API system conflict has been resolved by:
1. Establishing HttpApiServer (8080) as the single active API
2. Clearly marking GodotBridge (8080) as deprecated and disabled
3. Providing comprehensive migration guidance
4. Retaining the legacy addon for reference implementations only
5. Updating all documentation to prevent future confusion

**Current Status: RESOLVED**

All developers should now:
- Use port 8080 for new API calls
- Include JWT authentication tokens
- Refer to API_MIGRATION_GUIDE.md for details
- Use API_QUICK_REFERENCE.md for command examples
