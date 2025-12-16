# Documentation Archive - December 9, 2025
**Reason:** Pre-Phase 0 cleanup - Removed documentation conflicting with new architecture plan
**Date:** 2025-12-09
**Archived by:** Claude (automated cleanup)

## Summary

**Total files archived:** 274
- Root-level MD files: 255
- docs/current files: 19

## Reason for Archive

The project underwent a complete architecture redesign. The previous documentation described:
- **Old Project:** "Project Resonance + Planetary Survival" (space flight + Astroneer/Satisfactory/Ark-style survival/automation/creature taming)
- **New Project:** Galaxy-scale VR space simulator (walk, fly, land, multiplayer - NO survival mechanics)

These are fundamentally incompatible architectures, so all old documentation was archived.

## What Was Archived

### Root-Level Files (255 files)

**Categories:**
- HTTP API implementation docs (70+ files)
- Planetary Survival features (40+ files) - creatures, base building, life support
- Old phase/task/wave reports (40+ files)
- Security/JWT/audit docs (25+ files)
- Production/deployment docs (30+ files)
- Testing infrastructure (20+ files)
- Migration/fix reports (30+ files)

**Notable archived files:**
- ARCHITECTURE.md (old architecture)
- CODE_QUALITY_REPORT.md (old codebase analysis)
- PRODUCTION_READINESS_CHECKLIST.md (old system)
- HTTP_API_ROUTER_STATUS.md
- ROUTER_ACTIVATION_PLAN.md
- All PHASE_*.md, WAVE_*.md, TASK_*.md files
- All JWT_*, AUDIT_*, TOKEN_* files
- All DEPLOYMENT_*, PRODUCTION_* files
- All survival feature docs (AUDIO_*, MOON_*, PLANETARY_*, etc.)

### docs/current Files (19 files)

**Survival features NOT in new plan:**
- BASE_BUILDING_QUICK_REF.md
- CREATURE_AI_QUICKSTART.md
- CREATURE_AI_SYSTEM.md
- INVENTORY_QUICKSTART.md
- INVENTORY_UI_SYSTEM.md
- JETPACK_VFX.md
- LIFE_SUPPORT_SYSTEM.md
- HEALTH_DASHBOARD.md
- POWER_GRID_HUD.md

**Old architecture docs:**
- DEVELOPMENT_WORKFLOW.md (superseded by DEVELOPMENT_PHASES.md)
- FULL_PROJECT_OVERVIEW.md (superseded by ARCHITECTURE_BLUEPRINT.md)

**API documentation:**
- Various HTTP API guides referencing old features

## What Remains (Active Documentation)

### Root-Level (7 files - THE NEW PLAN):
1. PROJECT_START.md - Project overview and orientation
2. PHASE_0_FOUNDATION.md - Week 1 foundation tasks
3. DEVELOPMENT_PHASES.md - Phase 0-9 roadmap
4. ARCHITECTURE_BLUEPRINT.md - Technical architecture
5. TDD_WORKFLOW.md - Test-driven development guide
6. README.md - Project readme (updated)
7. CLAUDE.md - AI development guide (updated)

### scripts/ Embedded Docs (51 files - KEPT):
All implementation guides embedded in code directories were kept as they don't conflict with the architecture:
- scripts/core/ - Core system guides
- scripts/http_api/ - API implementation guides (security-critical)
- scripts/player/ - Player control guides
- scripts/rendering/ - Rendering system guides
- scripts/ui/ - UI system guides
- etc.

## Archive Location

All archived files are in:
```
docs/archive/2025-12-09-pre-phase0-cleanup/
├── root-level/          (255 files)
└── docs-current/        (19 files)
```

## Recovery

If you need to reference old documentation:
1. Check this archive directory
2. Files are preserved exactly as they were
3. Git history also contains all previous versions

## Next Steps

Following PHASE_0_FOUNDATION.md:
- Day 2: Documentation cleanup (COMPLETE)
- Day 3: Install missing tools
- Day 4: Create test infrastructure
- Day 5: Baseline commit

---

**This cleanup enables a fresh start for attempt #11 - the final attempt.**
