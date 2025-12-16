# SpaceTime (Project Resonance) - GEMINI Context

## 1. Project Overview
**SpaceTime** is a **VR Space Simulation** built with **Godot Engine 4.5.1** (C# Mono supported but primarily GDScript). It models the universe as a fractal harmonic lattice with relativistic physics.

*   **Core Tech:**
    *   **Engine & Language:** Godot 4.5+ (GDScript primary, Python for testing/tooling).
    *   **VR:** OpenXR via Godot's XRInterface (90 FPS target).
    *   **Physics:** Godot Physics 3D (built-in), custom PhysicsEngine.
    *   **Rendering:** Forward+ with PBR materials, custom shaders (lattice, atmosphere).
    *   **Autoloads:** `ResonanceEngine`, `GodotBridge`, `TelemetryServer`.
    *   **Debug Tools:** Custom DAP/LSP adapters, GDScript unit tests, Python property-based tests (Hypothesis).
*   **Key Features:** Seamless space-to-planet transitions, procedural generation, floating origin system, relativistic physics, and an AI-controlled debug infrastructure.
*   **Current Status:** ~95% Complete. Phases 1-13 finished. **Next: Phase 14 (Testing and Bug Fixing).**

## 1.1. Product Vision
SpaceTime models the universe as a fractal harmonic lattice of standing waves, where players navigate as AI consciousness entities. The simulation combines relativistic physics, information theory, and procedural generation for an immersive VR experience. Key features include VR-First Design, Relativistic Physics, Fractal Universe, Procedural Generation, Lattice Visualization, and unique Resonance-based Mechanics. The game emphasizes exploration, navigation challenges, and understanding the harmonic structure of spacetime.

## 2. ⚠️ CRITICAL MANDATES (READ FIRST)

### A. Mandatory Debugging
The "Godot Debug Connection" is **NOT OPTIONAL**. It is a core infrastructure component.
*   **Rule:** You must ensure the Godot instance is running with debug services enabled.
*   **Enforcement:** The system will log `MANDATORY DEBUG ERROR` if connections fail.
*   **Launch Command (GUI Mode REQUIRED):**
    ```bash
    godot -e --path . --debug-server tcp://127.0.0.1:6006 --lsp-port 6005
    ```
*   **⚠️ CRITICAL RULE:**
    *   **Network/Debug**: MUST use **GUI mode** (`-e`). Headless mode causes connection instability.
    *   **Logs/Tests**: Use **Headless mode** (`--headless`) ONLY for capturing logs or running automated tests.
    ```

### B. Restart Policy
*   **General Rule:** **DO NOT RESTART** the application to fix runtime bugs. Use hot-reload.
*   **Exception:** Restarts are **only** permitted for changes to initialization code (plugins, autoloads, server startup) that cannot be hot-reloaded. See `DEBUGGING_EXCEPTIONS.md`.

## 3. Architecture & AI Bridge

The project uses a specialized bridge to allow AI agents (like you) to inspect and control the engine.

### Communication Ports
| Service | Port | Protocol | Usage |
| :--- | :--- | :--- | :--- |
| **HTTP API** | **8081** | HTTP | Remote control, state inspection (`/status`, `/debug/*`). |
| **Telemetry** | **8081** | WebSocket | Real-time streams (FPS, VR coords). |
| **DAP** | **6006** | TCP | Debug Adapter Protocol (Breakpoints, Stack trace). |
| **LSP** | **6005** | TCP | Language Server Protocol (Autocomplete, Go-to-def). |

### Key Components
*   **`addons/godot_debug_connection/`**: The heart of the AI bridge.
    *   `godot_bridge.gd`: HTTP Server implementation.
    *   `connection_manager.gd`: Manages DAP/LSP/HTTP state.
*   **`scripts/core/`**: The engine core.
    *   `engine.gd`: Main coordinator (Autoload: `ResonanceEngine`).
    *   `vr_manager.gd`: OpenXR handling.
    *   `floating_origin.gd`: Handling vast distances.

## 4. Coding Standards & Conventions

### Naming Conventions
*   **Classes:** PascalCase (`class_name` declaration).
*   **Files:** snake_case (matching class name).
*   **Functions:** snake_case.
*   **Constants:** UPPER_SNAKE_CASE.
*   **Private members:** Prefix with underscore `_private_var`.
*   **Signals:** snake_case, past tense for events (`capture_detected`).

### Documentation
*   Every script must include a header with `ClassName`, brief description, detailed explanation, and `Requirements: X.Y, Z.W`.
*   Functions should have docstrings.

### Type Hints
*   Always use type hints for parameters and return values.

### Error Handling
*   Use `push_error()` for critical failures, `push_warning()` for non-critical issues.
*   Check null/validity with `if obj != null and is_instance_valid(obj):`.

### File Organization
*   Script Headers include requirement traceability.
*   Scene structure: `vr_main.tscn` is main VR scene.
*   Prefer scene composition over inheritance.

## 4.1. Requirements Traceability
Each implementation file references requirements from `.kiro/specs/project-resonance/requirements.md`. Requirement numbers are included in file headers, and critical sections are commented with requirement references. Property tests validate correctness from `design.md`.

## 5. Development & workflows

### Running the Project
**VR Mode (Default):**
```bash
godot --path .
```
**Headless (for testing):**
```bash
godot --headless --path .
```

### Testing
*   **Unit Tests (GDUnit4):** `godot --headless --script tests/unit/test_coordinate_system.gd` (example command, specific test files are in `tests/unit/`).
*   **Property Tests (Python):** `python -m pytest tests/property/` (using Hypothesis).
*   **Integration Tests:** `python tests/integration/test_mandatory_debug.py`.
*   **Telemetry Monitor:** `python telemetry_client.py`.

### Validation
Check `CHECKPOINT_XX_STATUS.md` files for phase-specific validation steps. The latest is `CHECKPOINT_44_VALIDATION.md` (Planetary Systems).

## 6. Directory Map

*   `addons/` - Plugins. **Crucial:** `godot_debug_connection`.
*   `scripts/`
    *   `core/` - Physics, Time, VR, Engine loops.
    *   `celestial/` - Orbital mechanics, Solar system, Day/Night cycle.
    *   `procedural/` - Terrain generation, Universe generation.
    *   `player/` - Controller logic, Interaction, Transition system.
    *   `rendering/` - Shaders, Atmosphere, LOD.
*   `scenes/` - `.tscn` files. `vr_main.tscn` is the entry point.
*   `shaders/` - `.gdshader` files (Atmosphere, Lattice, etc.).
*   `tests/` - Automated tests.

## 7. Current Known Issues
*   **UI Validation Tests:** Mismatch between test expectations and actual method names in Phase 7.
*   **Type Declarations:** Some scripts missing `class_name`, causing potential load issues.
*   **Assets:** Missing audio/models (Phase 13/9).

## 8. Useful Commands
*   **Check Status:** `curl http://127.0.0.1:8080/status`
*   **Hot Reload:** Trigger via DAP or HTTP `/execute/reload`.
