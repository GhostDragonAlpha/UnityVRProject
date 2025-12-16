# Documentation Structure

This document describes the organization of all project documentation to improve discoverability and maintainability.

## Overview

The documentation has been reorganized into two main categories:
- **Current Documentation** (`docs/current/`) - Active, up-to-date documentation for the current version
- **Historical Documentation** (`docs/history/`) - Archived development history, checkpoints, and legacy documents

## Directory Structure

```
docs/
├── current/              # Active v2.5+ documentation
│   ├── api/             # API references and examples
│   ├── guides/          # How-to guides and tutorials
│   ├── security/        # Security documentation
│   └── testing/         # Testing guides and procedures
│
├── history/             # Historical documents (archived)
│   ├── checkpoints/     # Development checkpoint files (30 files)
│   ├── tasks/           # Task tracking documents (87 files)
│   ├── summaries/       # Completion reports and summaries (52 files)
│   ├── archive/         # Implementation notes, bug fixes, investigations
│   └── v1.0/            # Version 1.0 specific documentation
│
└── README.md            # Documentation navigation guide
```

## Root-Level Documentation

Key files that remain in the project root for easy access:

- **CLAUDE.md** - Claude Code project instructions (must stay in root)
- **README.md** - Project overview and quick start
- **AGENTS.md** - AI agent configurations
- **GEMINI.md** - Gemini AI integration guide
- **DOCUMENTATION_STRUCTURE.md** - This file

## Current Documentation (`docs/current/`)

### API Documentation (`docs/current/api/`)

Complete API references for the HTTP API, endpoints, and integrations:

- `HTTP_API_MASTER_INDEX.md` - Master index of all HTTP API endpoints
- `HTTP_API_USAGE_GUIDE.md` - Usage guide with examples
- `TERRAIN_API_REFERENCE.md` - Terrain manipulation API
- `VR_TELEPORTATION_HTTP_API.md` - VR teleportation endpoints
- `HEALTH_ENDPOINT_EXAMPLES.md` - Health monitoring examples
- `SCENE_RELOAD_ENDPOINT.md` - Scene management API
- `SCENE_VALIDATION_API.md` - Scene validation endpoints

### Guides (`docs/current/guides/`)

How-to guides, tutorials, and system documentation:

**Setup and Configuration:**
- `QUICK_START.md` - Quick start guide for new users
- `SETUP_INSTRUCTIONS.md` - Detailed setup instructions
- `DEPLOYMENT_GUIDE.md` - Production deployment guide
- `GDUNIT4_SETUP.md` - GDUnit4 testing framework setup
- `GODOT_SERVER_SETUP.md` - Godot server configuration
- `VR_SETUP_GUIDE.md` - VR headset setup

**Development:**
- `DEVELOPMENT_WORKFLOW.md` - Development workflow and best practices
- `REMOTE_ACCESS_ARCHITECTURE.md` - Remote access system design
- `HEADLESS_MODE_GUIDE.md` - Running Godot in headless mode

**System Documentation:**
- `FULL_PROJECT_OVERVIEW.md` - Complete project architecture overview
- `HEALTH_DASHBOARD.md` - Health monitoring dashboard
- `SMART_SERVER_FINAL.md` - Smart server implementation

**Feature-Specific Guides:**
- `BASE_BUILDING_QUICK_REF.md` - Base building quick reference
- `CREATURE_AI_QUICKSTART.md` - Creature AI quick start
- `CREATURE_AI_SYSTEM.md` - Complete creature AI system
- `INVENTORY_QUICKSTART.md` - Inventory system quick start
- `INVENTORY_UI_SYSTEM.md` - Inventory UI documentation
- `QUICK_START_PLANETARY_SURVIVAL.md` - Planetary survival mode
- `QUICK_START_PLAYER_MONITOR.md` - Player monitoring system
- `PLAYER_MONITOR_FLOW.md` - Player monitor flow diagrams
- `PLAYER_MONITOR_USAGE.md` - Player monitor usage guide
- `LIFE_SUPPORT_SYSTEM.md` - Life support mechanics
- `POWER_GRID_HUD.md` - Power grid HUD system
- `JETPACK_VFX.md` - Jetpack visual effects
- `VR_TELEPORTATION.md` - VR teleportation system
- `VR_TRACKING_QUICK_REFERENCE.md` - VR tracking reference
- `SPACECRAFT_QUICK_REFERENCE.md` - Spacecraft controls
- `SCENE_LOADER_QUICK_START.md` - Scene loading system
- `TELEMETRY_GUIDE.md` - Telemetry system usage

**Tutorials:**
- `TUTORIAL_ASSETS.md` - Tutorial asset guide
- `VIDEO_TUTORIAL_SCRIPT.md` - Video tutorial scripts

### Security (`docs/current/security/`)

Security documentation and guidelines:

- `SECURITY_AUDIT.md` - Complete security audit results
- `SECURITY_CURL_EXAMPLES.md` - Secure API usage examples
- `QUICK_START_V2.5_SECURITY.md` - V2.5 security quick start

### Testing (`docs/current/testing/`)

Testing guides, procedures, and test documentation:

- `TESTING_GUIDE.md` - Complete testing guide
- `TEST_COMMANDS.md` - Test command reference
- `USER_TESTING_GUIDE.md` - User acceptance testing guide
- `USER_TESTING_READY.md` - Test readiness checklist
- `QUICK_REFERENCE_TESTING.md` - Testing quick reference
- `PERFORMANCE_BENCHMARKS.md` - Performance testing results
- `MOVEMENT_TEST_FEATURES.md` - Movement system test features
- `MOVEMENT_TEST_README.md` - Movement test suite documentation
- `SPACECRAFT_TEST_INDEX.md` - Spacecraft test index

## Historical Documentation (`docs/history/`)

### Checkpoints (`docs/history/checkpoints/`)

Development checkpoint documents tracking major milestones (30 files):
- `CHECKPOINT_4_TERRAIN_DEFORMATION.md` through `CHECKPOINT_66_VALIDATION.md`
- These provide historical snapshots of feature completion and validation

### Tasks (`docs/history/tasks/`)

Task tracking documents for completed work (87 files):
- `TASK_1_COMPLETION.md` through `TASK_69_PERFORMANCE_TESTING_GUIDE.md`
- Detailed completion reports for each development task

### Summaries (`docs/history/summaries/`)

Completion reports, session summaries, and implementation status (52 files):
- Implementation summaries (e.g., `AUDIO_ASSETS_IMPLEMENTATION_SUMMARY.md`)
- Session summaries (e.g., `SESSION_SUMMARY_2025-12-01.md`)
- Test results (e.g., `BASE_BUILDING_TEST_SUMMARY.md`)
- Status reports (e.g., `HTTP_API_PRODUCTION_READY_REPORT.md`)

### Archive (`docs/history/archive/`)

Historical implementation notes, bug fixes, and investigations:

**Investigation Reports:**
- DAP/LSP investigation reports
- Network diagnosis documents
- Root cause analysis reports

**Implementation Documents:**
- Feature implementation notes
- Integration progress documents
- Automated testing methodology

**Bug Fixes and Patches:**
- Bug fix documentation
- Quick fix guides
- Speed and performance fixes

**Status Documents:**
- Historical status snapshots
- Session handoff notes
- Development progress tracking

### Version 1.0 (`docs/history/v1.0/`)

Documentation specific to version 1.0 (reserved for future use)

## Finding Documentation

### For Current Features

1. **API Reference**: Check `docs/current/api/` for endpoint documentation
2. **Setup/Deployment**: Check `docs/current/guides/` for setup and deployment
3. **Security**: Check `docs/current/security/` for security guidelines
4. **Testing**: Check `docs/current/testing/` for testing procedures

### For Historical Information

1. **Development History**: Check `docs/history/checkpoints/` for milestone history
2. **Task Details**: Check `docs/history/tasks/` for detailed task completion info
3. **Session Notes**: Check `docs/history/summaries/` for session summaries
4. **Old Investigations**: Check `docs/history/archive/` for bug investigations

## Naming Conventions

### Current Documentation
- Use descriptive names that indicate purpose
- Include system/feature name in filename
- Examples: `QUICK_START_PLANETARY_SURVIVAL.md`, `HTTP_API_MASTER_INDEX.md`

### Historical Documentation
- Preserve original filenames for traceability
- Checkpoints: `CHECKPOINT_N_DESCRIPTION.md`
- Tasks: `TASK_N_DESCRIPTION.md`
- Summaries: `*_SUMMARY.md`, `*_REPORT.md`, `*_COMPLETE.md`

## Document Lifecycle

### New Documents
1. Create in appropriate `docs/current/` subdirectory
2. Follow naming conventions
3. Add link to `docs/README.md`

### Deprecated Documents
1. Move to appropriate `docs/history/` subdirectory
2. Add note in `docs/README.md` about archival
3. Update any references in current docs

### Major Version Changes
1. Archive previous version docs to `docs/history/vX.Y/`
2. Update current docs with new version info
3. Maintain version compatibility notes

## Maintenance

- Review and update `docs/README.md` when adding new documents
- Archive outdated documents to `docs/history/` subdirectories
- Keep root directory minimal (only essential project files)
- Update this structure document when reorganizing

## See Also

- `docs/README.md` - Navigation guide for documentation
- `CLAUDE.md` - Claude Code project instructions
- `README.md` - Project overview
