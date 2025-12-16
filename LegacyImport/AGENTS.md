# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## 🚨 MANDATORY: Development Workflow 🚨

**ALL CHANGES MUST BE VERIFIED BEFORE COMMIT - NO EXCEPTIONS**

```bash
# After ANY code/scene changes, run:
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**Acceptance Criteria:**
- ✅ **Exit code 0** → All checks passed → Commit approved
- ❌ **Exit code 1** → Failures detected → Fix issues and re-verify
- ⚠️ **Exit code 2** → Auto-fixes applied → Re-verify

## Critical Non-Obvious Patterns

**7-PHASE INITIALIZATION** - [`ResonanceEngine`](scripts/core/engine.gd:76) has strict dependency order. Phase 3 (Physics) depends on Phase 2 (Floating Origin). Reordering causes silent failures.

**PORT FALLBACK CHAIN** - HTTP API requires fallback through 8080→8083→8084→8085. Hardcoding port 8080 breaks auto-recovery.

**BINARY TELEMETRY** - Custom protocol (type 0x01) for FPS data. GZIP compression for JSON >1KB. Implementation in [`telemetry_server.gd`](addons/godot_debug_connection/telemetry_server.gd).

**CIRCUIT BREAKER PATTERN** - ConnectionManager uses circuit breakers for DAP/LSP connections. Direct connection attempts bypass failure recovery mechanisms.

**MULTI-CLIENT SUPPORT** - Telemetry broadcasts to all connected clients simultaneously. ConnectionManager handles multi-client events.

**SERVICE DISCOVERY** - UDP broadcast on port 8087 announces available services for auto-discovery.

**FLOATING ORIGIN REGISTRATION** - All spatial objects must register with [`FloatingOriginSystem`](scripts/core/engine.gd:761) via `register_object()` before physics processing begins. Failure causes coordinate drift at astronomical distances.

**ZERO GRAVITY OVERRIDE** - [`project.godot`](project.godot:42) sets `3d/default_gravity=0.0`. Manual gravity changes in scripts must respect this base configuration.

**PHYSICS TICK RATE COUPLING** - 90 FPS physics rate (matching VR) is hardcoded in [`project.godot`](project.godot:41). Changing without updating VR refresh rate causes motion sickness.

**GDUNIT4 MANUAL INSTALLATION** - Cannot use `package.json` or automated installation. Must clone from https://github.com/MikeSchulze/gdUnit4 into `addons/gdUnit4/` manually or via AssetLib.

**REQUIREMENTS TRACEABILITY** - Every script header must reference `.kiro/specs/` requirements. Missing references break validation.

**HOT-RELOAD ONLY** - Use `/execute/reload` HTTP endpoint, not application restart. Direct restart causes debug servers to stop responding.

**DICTIONARY VALIDATORS** - Use [`dictionary_validators.gd`](scripts/core/dictionary_validators.gd) for type-safe data structures. Direct dictionary access bypasses validation.

**HUD DEPENDENCY COUPLING** - Cockpit HUD systems depend on VR controller state. Initialize VR controllers before HUD to prevent null reference errors.

**QUICK RESTART** - Use `restart_godot_with_debug.bat` (Windows) or:
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005