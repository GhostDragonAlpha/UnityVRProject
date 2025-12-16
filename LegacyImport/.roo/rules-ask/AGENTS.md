# Ask Mode Rules (Non-Obvious Only)

**MANDATORY DEBUG SYSTEM** - The Godot Debug Connection addon is core infrastructure, not optional. All development sessions must run with debug services enabled. Headless mode breaks debug servers.

**7-PHASE INITIALIZATION** - [`ResonanceEngine`](scripts/core/engine.gd:76) has strict dependency order. Phase 3 (Physics) depends on Phase 2 (Floating Origin). Reordering causes silent failures.

**PORT FALLBACK CHAIN** - HTTP API requires fallback through 8080→8083→8084→8085. Hardcoding port 8080 breaks auto-recovery.

**BINARY TELEMETRY** - Custom protocol (type 0x01) for FPS data. GZIP compression for JSON >1KB. Implementation in [`telemetry_server.gd`](addons/godot_debug_connection/telemetry_server.gd).

**CIRCUIT BREAKER PATTERN** - ConnectionManager uses circuit breakers for DAP/LSP connections. Direct connection attempts bypass failure recovery mechanisms.

**MULTI-CLIENT SUPPORT** - Telemetry broadcasts to all connected clients simultaneously. ConnectionManager handles multi-client events.

**SERVICE DISCOVERY** - UDP broadcast on port 8087 announces available services for auto-discovery.

**REQUIREMENTS TRACEABILITY** - Every script header must reference `.kiro/specs/` requirements. Missing references break validation.

**FLOATING ORIGIN REGISTRATION** - All spatial objects must register with [`FloatingOriginSystem`](scripts/core/engine.gd:761) via `register_object()` before physics processing begins. Failure causes coordinate drift at astronomical distances.

**ZERO GRAVITY OVERRIDE** - [`project.godot`](project.godot:42) sets `3d/default_gravity=0.0`. Manual gravity changes in scripts must respect this base configuration.

**PHYSICS TICK RATE COUPLING** - 90 FPS physics rate (matching VR) is hardcoded in [`project.godot`](project.godot:41). Changing without updating VR refresh rate causes motion sickness.

**GDUNIT4 MANUAL INSTALLATION** - Cannot use `package.json` or automated installation. Must clone from https://github.com/MikeSchulze/gdUnit4 into `addons/gdUnit4/` manually or via AssetLib.

**PYTHON PROPERTY TESTS** - Require `hypothesis`, `pytest`, `pytest-timeout` from [`tests/property/requirements.txt`](tests/property/requirements.txt).