# Debug Mode Rules (Non-Obvious Only)

**MANDATORY DEBUG ENFORCEMENT** - Debug system is core infrastructure, not optional. All development sessions must run with debug services enabled. Headless mode breaks debug servers.

**AUTHORIZED RESTARTS ONLY** - Restarts prohibited except for core plugin initialization changes. See [`DEBUGGING_EXCEPTIONS.md`](DEBUGGING_EXCEPTIONS.md:9) for mandatory procedure.

**7-PHASE INITIALIZATION** - [`ResonanceEngine`](scripts/core/engine.gd:76) has strict dependency order. Phase 3 (Physics) depends on Phase 2 (Floating Origin). Reordering causes silent failures.

**PORT FALLBACK CHAIN** - HTTP API requires fallback through 8080→8083→8084→8085. Hardcoding port 8080 breaks auto-recovery.

**BINARY TELEMETRY** - Custom protocol (type 0x01) for FPS data. GZIP compression for JSON >1KB. Implementation in [`telemetry_server.gd`](addons/godot_debug_connection/telemetry_server.gd).

**CIRCUIT BREAKER PATTERN** - ConnectionManager uses circuit breakers for DAP/LSP connections. Direct connection attempts bypass failure recovery mechanisms.

**REQUIREMENTS TRACEABILITY** - Every script header must reference `.kiro/specs/` requirements. Missing references break validation.

**QUICK RESTART** - Use `restart_godot_with_debug.bat` (Windows) or:
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**HOT-RELOAD ONLY** - Use `/execute/reload` HTTP endpoint, not application restart. Direct restart causes debug servers to stop responding.

**MULTI-CLIENT SUPPORT** - Telemetry broadcasts to all connected clients simultaneously. ConnectionManager handles multi-client events.

**SERVICE DISCOVERY** - UDP broadcast on port 8087 announces available services for auto-discovery.