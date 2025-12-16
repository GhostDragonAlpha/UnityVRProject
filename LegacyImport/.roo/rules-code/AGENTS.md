# Code Mode Rules (Non-Obvious Only)

**HOT-RELOAD ENDPOINT** - Use `/execute/reload` HTTP endpoint instead of application restart. Direct restart causes debug servers to stop responding.

**FLOATING ORIGIN REGISTRATION** - All spatial objects must register with [`FloatingOriginSystem`](scripts/core/engine.gd:761) via `register_object()` before physics processing begins. Failure causes coordinate drift at astronomical distances.

**BINARY TELEMETRY PROTOCOL** - Custom binary format (type 0x01) for FPS data. Use [`telemetry_server.gd`](addons/godot_debug_connection/telemetry_server.gd) methods, not standard Godot telemetry.

**SUBSYSTEM INITIALIZATION ORDER** - [`ResonanceEngine`](scripts/core/engine.gd:76) 7-phase initialization is mandatory. Phase 3 (Physics) depends on Phase 2 (Floating Origin) completion. Reordering causes silent initialization failures.

**PORT FALLBACK CHAIN** - HTTP API requires fallback implementation through ports 8080→8083→8084→8085. Hardcoding port 8080 breaks auto-recovery.

**GDUNIT4 MANUAL INSTALLATION** - Cannot use `package.json` or automated installation. Must clone from https://github.com/MikeSchulze/gdUnit4 into `addons/gdUnit4/` manually or via AssetLib.

**SCRIPT HEADER REQUIREMENTS** - Every script must include requirement references from `.kiro/specs/` in header comments. Missing references break traceability validation.

**ZERO GRAVITY OVERRIDE** - [`project.godot`](project.godot:42) sets `3d/default_gravity=0.0`. Manual gravity changes in scripts must respect this base configuration.

**PHYSICS TICK RATE COUPLING** - 90 FPS physics rate (matching VR) is hardcoded in [`project.godot`](project.godot:41). Changing without updating VR refresh rate causes motion sickness.

**DICTIONARY VALIDATORS** - Use [`dictionary_validators.gd`](scripts/core/dictionary_validators.gd) for type-safe data structures. Direct dictionary access bypasses validation.

**HUD DEPENDENCY COUPLING** - Cockpit HUD systems depend on VR controller state. Initialize VR controllers before HUD to prevent null reference errors.