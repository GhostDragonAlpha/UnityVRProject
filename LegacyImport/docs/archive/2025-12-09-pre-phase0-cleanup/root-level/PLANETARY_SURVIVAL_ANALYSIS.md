# Planetary Survival Subsystem Analysis

## Overview
The planetary_survival subsystem contains 564 compilation errors across 38 files. This document categorizes features for selective re-enabling.

## Feature Categories

### 1. Base Building & Construction (High Priority)
**Core Files (11):**
- `core/base_module.gd` - Base building module foundation
- `core/airlock_module.gd` - Airlock/entry system
- `core/fabricator_module.gd` - Manufacturing module
- `core/greenhouse_module.gd` - Farming module
- `core/habitat_module.gd` - Living quarters
- `core/lab_module.gd` - Research facility
- `core/storage_container.gd` - Storage system (FIXED)
- `core/elevator.gd` - Vertical transport
- `core/conveyor_belt.gd` - Item transport
- `core/conveyor_network.gd` - Transport network
- `core/cargo_train.gd` - Cargo transport

**System Files (3):**
- `systems/base_building_system.gd` - Main building coordinator
- `systems/base_customization_system.gd` - Module customization
- `systems/automation_system.gd` - Automation logic

**UI Files:** None directly (menu system redesign pending)

**Dependencies:** None
**Estimated Complexity:** Medium-High

---

### 2. Power & Energy Systems (High Priority)
**Core Files (1):**
- `core/battery.gd` - Energy storage (FIXED)

**System Files (1):**
- `systems/power_system.gd` - Power distribution & management

**UI Files (2):**
- `ui/power_grid_hud.gd` - Power monitoring UI (WILL REDESIGN)
- `ui/power_grid_hud_enhanced.gd` - Enhanced power UI

**Dependencies:** Base Building (batteries attach to modules)
**Estimated Complexity:** Medium

---

### 3. Crafting & Manufacturing (Medium Priority)
**Core Files (3):**
- `core/crafting_recipe.gd` - Recipe definitions
- `core/fabricator.gd` - Manufacturing machine
- `core/blueprint.gd` - Blueprint system (FIXED)

**System Files (2):**
- `systems/crafting_system.gd` - Crafting coordinator
- `systems/blueprint_system.gd` - Blueprint management

**UI Files (1):**
- `ui/vr_crafting_ui.gd` - VR crafting interface

**Dependencies:** Resource System, Inventory System
**Estimated Complexity:** Medium

---

### 4. Inventory & Storage (Medium Priority)
**Core Files (1):**
- `core/storage_container.gd` - Container logic (FIXED)

**System Files (1):**
- `systems/inventory_system.gd` - Inventory management

**UI Files (2):**
- `ui/inventory_manager.gd` - Inventory UI manager
- `ui/vr_inventory_ui.gd` - VR inventory interface

**Dependencies:** None
**Estimated Complexity:** Low-Medium

---

### 5. Resource Management (Medium Priority)
**Core Files (1):**
- `core/consumable.gd` - Consumable items (food, water, oxygen)

**System Files (1):**
- `systems/resource_system.gd` - Resource tracking & distribution

**UI Files:** None

**Dependencies:** None
**Estimated Complexity:** Low-Medium

---

### 6. Farming & Agriculture (Low Priority)
**Core Files (4):**
- `core/crop.gd` - Individual crop instances
- `core/crop_plot.gd` - Farming plot logic
- `core/crop_species.gd` - Crop type definitions
- `core/greenhouse_module.gd` - Greenhouse building

**System Files (1):**
- `systems/farming_system.gd` - Farming coordinator

**UI Files:** None

**Dependencies:** Base Building (greenhouse module), Day/Night Cycle
**Estimated Complexity:** Medium

---

### 7. Creatures & Wildlife (Low Priority - Complex)
**Core Files (6):**
- `core/creature.gd` - Creature instances
- `core/creature_ai.gd.disabled` - AI behavior (DISABLED - class name conflict)
- `core/creature_ai_optimized.gd.disabled` - Optimized AI (DISABLED)
- `core/creature_egg.gd` - Creature breeding
- `core/creature_species.gd` - Creature type definitions
- `core/tame_creature.gd` - Taming system

**System Files (1):**
- `systems/creature_system.gd` - Creature spawning & management

**UI Files:** None

**Dependencies:** None (self-contained)
**Estimated Complexity:** High (AI system disabled due to conflicts)

---

### 8. Cave & Underground Systems (Low Priority)
**Core Files (1):**
- `core/cave_network.gd` - Cave generation data

**System Files (1):**
- `systems/cave_generation_system.gd` - Procedural cave generation

**UI Files:** None

**Dependencies:** None
**Estimated Complexity:** Medium

---

### 9. Drones & Automation (Low Priority)
**Core Files (2):**
- `core/drone.gd` - Individual drone logic
- `core/drone_hub.gd` - Drone management station

**System Files (1):**
- `systems/automation_system.gd` - Drone coordination

**UI Files:** None

**Dependencies:** Base Building (drone hub module)
**Estimated Complexity:** Medium-High

---

### 10. Alien Artifacts & Discovery (Low Priority)
**Core Files (1):**
- `core/alien_artifact.gd` - Artifact instances

**System Files (1):**
- `systems/alien_artifact_system.gd` - Artifact spawning & effects

**UI Files:** None

**Dependencies:** None
**Estimated Complexity:** Low-Medium

---

### 11. Day/Night & Environmental Systems (Low Priority)
**Core Files:** None

**System Files (1):**
- `systems/day_night_cycle_system.gd` - Day/night timing & lighting

**UI Files:** None

**Dependencies:** None
**Estimated Complexity:** Low

---

### 12. Boss Encounters (Low Priority)
**Core Files:** None

**System Files (1):**
- `systems/boss_encounter_system.gd` - Boss fight coordinator

**UI Files:** None

**Dependencies:** Creature System
**Estimated Complexity:** High

---

### 13. Multiplayer/Distributed Systems (Low Priority - Advanced)
**Core Files:** None

**System Files (6):**
- `systems/authority_transfer_system.gd` - Network authority
- `systems/boundary_synchronization_system.gd` - Boundary sync
- `systems/conflict_resolver.gd` - Conflict resolution
- `systems/consistency_manager.gd` - State consistency
- `systems/distributed_database.gd` - Distributed data
- `systems/dynamic_scaler.gd` - Performance scaling
- `systems/degraded_mode_system.gd` - Fallback modes

**UI Files (1):**
- `ui/conflict_debug_ui.gd` - Conflict debugging

**Dependencies:** All other systems
**Estimated Complexity:** Very High (distributed systems are complex)

---

### 14. Save/Load UI (Medium Priority)
**Core Files:** None

**System Files:** None (uses existing SaveSystem autoload)

**UI Files (2):**
- `ui/save_load_menu.gd` - Save/load menu
- `ui/vr_save_load_menu.gd` - VR save/load interface

**Dependencies:** SaveSystem (already working)
**Estimated Complexity:** Low

---

### 15. VR Menu System (High Priority)
**Core Files:** None

**System Files:** None

**UI Files (1):**
- `ui/vr_menu_system.gd` - Main VR menu coordinator

**Dependencies:** None
**Estimated Complexity:** Medium

---

## Recommended Re-enabling Order

### Phase 2A: Core Gameplay Foundation (Essential)
1. **VR Menu System** - Main menu & UI navigation
2. **Inventory & Storage** - Item management
3. **Resource Management** - Consumables (oxygen, food, water)

### Phase 2B: Building & Power (High Value)
4. **Base Building & Construction** - Module placement & construction
5. **Power & Energy Systems** - Power generation & distribution

### Phase 2C: Crafting & Progression
6. **Crafting & Manufacturing** - Item creation
7. **Save/Load UI** - Game state persistence UI

### Phase 2D: Optional Features (Lower Priority)
8. **Farming & Agriculture** - Food production
9. **Drones & Automation** - Automated systems
10. **Day/Night & Environmental** - Time cycles
11. **Cave & Underground** - Exploration content
12. **Alien Artifacts** - Discovery mechanics

### Phase 2E: Complex Systems (Defer or Skip)
13. **Creatures & Wildlife** - High complexity, AI conflicts
14. **Boss Encounters** - Depends on creatures
15. **Multiplayer/Distributed** - Very high complexity, not needed for single-player

---

## Files Already Fixed
- `core/battery.gd` - Type inference fixes
- `core/blueprint.gd` - Type casts
- `core/storage_container.gd` - Variable shadowing fix

---

## Next Steps
1. User selects which features to re-enable from categories above
2. Move selected feature files back into project
3. Fix compilation errors for selected features only
4. Verify each feature works before moving to next
5. Leave unneeded features disabled permanently
