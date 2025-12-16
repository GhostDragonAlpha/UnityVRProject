# Base Building System - Quick Reference

## Test Results at a Glance

**Date:** 2025-12-02
**Status:** Backend ✅ | HTTP API ❌

### Summary

- **Backend System**: Fully implemented in `base_building_system.gd`
- **HTTP Endpoints**: Not implemented (all return 404)
- **Test Script**: Created and working (`test_base_building.py`)

---

## Available Backend Methods

| Method | Purpose | Returns |
|--------|---------|---------|
| `place_structure(type, pos, rot)` | Place new module | `BaseModule` or `null` |
| `remove_structure(module)` | Remove module | `bool` |
| `get_placed_structures()` | Get all modules | `Array[BaseModule]` |
| `get_nearby_structures(pos, radius)` | Find nearby modules | `Array[BaseModule]` |
| `get_module_by_id(id)` | Find by ID | `BaseModule` or `null` |
| `calculate_structural_integrity(module)` | Get integrity | `float` (0.0-1.0) |
| `get_all_networks()` | Get power/O2 networks | `Array[Dictionary]` |
| `enable_stress_visualization(bool)` | Toggle visual stress | `void` |

---

## Module Types

```
0 = HABITAT      (metal: 50, plastic: 30)
1 = STORAGE      (metal: 30, plastic: 20)
2 = FABRICATOR   (metal: 40, electronics: 20)
3 = GENERATOR    (metal: 60, electronics: 30)
4 = OXYGEN       (metal: 40, electronics: 25)
5 = AIRLOCK      (metal: 35, plastic: 25)
```

---

## Missing HTTP Endpoints (Need Implementation)

1. `POST /base/place_structure` - Place a structure
2. `GET /base/structures` - Get all structures
3. `POST /base/structures/nearby` - Get nearby structures
4. `DELETE /base/remove_structure` - Remove structure
5. `POST /base/module` - Get module by ID
6. `GET /base/networks` - Get all networks
7. `POST /base/integrity` - Get structural integrity
8. `POST /base/stress_visualization` - Toggle stress visualization

---

## Implementation Location

**File:** `C:/godot/addons/godot_debug_connection/godot_bridge.gd`

**Add in `_route_request()` method around line 275:**

```gdscript
elif path.begins_with("/base/"):
    _handle_base_building_endpoint(client, method, path, body)
```

**Then implement handler functions** (see `BASE_BUILDING_TEST_SUMMARY.md` for complete code)

---

## Testing Commands

```bash
# Run test suite
cd C:/godot
python test_base_building.py

# Place habitat example
curl -X POST http://127.0.0.1:8080/base/place_structure \
  -H "Content-Type: application/json" \
  -d '{"structure_type": 0, "position": [15.0, 0.0, 15.0]}'

# Get all structures
curl http://127.0.0.1:8080/base/structures
```

---

## Files Generated

1. **`test_base_building.py`** - Test script (14KB)
2. **`BASE_BUILDING_TEST_RESULTS.md`** - Detailed results (4.5KB)
3. **`BASE_BUILDING_TEST_SUMMARY.md`** - Implementation guide (21KB)
4. **`BASE_BUILDING_QUICK_REF.md`** - This file

---

## System Architecture

```
HTTP API (8080) → PlanetarySurvivalCoordinator → BaseBuildingSystem → BaseModule
```

**Access Path:**
```gdscript
var coordinator = get_tree().root.get_node_or_null("PlanetarySurvivalCoordinator")
var base_system = coordinator.base_building_system
var module = base_system.place_structure(0, Vector3(15, 0, 15))
```
