# Missing Terrain API Endpoints

**Status:** Not Implemented
**Priority:** TBD (depends on requirements)
**Last Updated:** 2025-12-02

## Overview

This document describes terrain API endpoints that were tested but are **not currently implemented** in the codebase. These endpoints were expected in previous test specifications but do not exist in `C:/godot/addons/godot_debug_connection/godot_bridge.gd`.

**Currently Implemented:**
- ✅ `POST /terrain/excavate` - Remove terrain in spherical volume
- ✅ `POST /terrain/elevate` - Add terrain in spherical volume

**Not Implemented (described in this document):**
- ❌ `POST /terrain/deform` - Generic terrain deformation
- ❌ `GET /terrain/chunk_info` - Query chunk information
- ❌ `POST /terrain/reset_chunk` - Reset chunk to original state

---

## Endpoint Specifications

### 1. POST /terrain/deform

**Status:** ❌ Not Implemented

**Purpose:** Generic terrain deformation endpoint supporting multiple operation types (add, subtract, smooth, flatten).

**Design Specification:**

**Request:**
```json
POST /terrain/deform
Content-Type: application/json

{
  "position": [10.0, 5.0, 10.0],
  "radius": 2.0,
  "intensity": -5.0,
  "operation": "add"
}
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `position` | Array[float, float, float] | ✅ Yes | Center position `[x, y, z]` |
| `radius` | Number | ✅ Yes | Radius of deformation sphere |
| `intensity` | Number | ✅ Yes | Strength of deformation (positive = add, negative = remove) |
| `operation` | String | ✅ Yes | Operation type: `"add"`, `"subtract"`, `"smooth"`, `"flatten"` |

**Expected Response (200 OK):**
```json
{
  "status": "success",
  "command": "deform",
  "position": [10.0, 5.0, 10.0],
  "radius": 2.0,
  "intensity": -5.0,
  "operation": "add",
  "voxels_modified": 234
}
```

#### Implementation Plan

**Backend Requirements:**

1. **VoxelTerrain methods needed:**
   ```gdscript
   # In VoxelTerrain or equivalent
   func deform_sphere(center: Vector3, radius: float, intensity: float, operation: String) -> int:
       match operation:
           "add":
               return add_sphere(center, radius, intensity)
           "subtract":
               return subtract_sphere(center, radius, intensity)
           "smooth":
               return smooth_sphere(center, radius, intensity)
           "flatten":
               return flatten_sphere(center, radius, intensity)
           _:
               push_error("Unknown deformation operation: " + operation)
               return 0
   ```

2. **HTTP endpoint handler:**
   ```gdscript
   # In godot_bridge.gd, add to _handle_terrain_endpoint() match statement:
   func _handle_terrain_endpoint(client: StreamPeerTCP, method: String, path: String, body: String) -> void:
       # ... existing code ...
       match terrain_command:
           "excavate":
               _handle_terrain_excavate(client, request_data)
           "elevate":
               _handle_terrain_elevate(client, request_data)
           "deform":  # NEW
               _handle_terrain_deform(client, request_data)
           _:
               _send_error_response(client, 404, "Not Found", "Unknown terrain command: " + terrain_command)
   ```

3. **Handler implementation:**
   ```gdscript
   func _handle_terrain_deform(client: StreamPeerTCP, request_data: Dictionary) -> void:
       # Validate required parameters
       if not request_data.has("position"):
           _send_error_response(client, 400, "Bad Request", "Missing required parameter: position")
           return
       if not request_data.has("radius"):
           _send_error_response(client, 400, "Bad Request", "Missing required parameter: radius")
           return
       if not request_data.has("intensity"):
           _send_error_response(client, 400, "Bad Request", "Missing required parameter: intensity")
           return
       if not request_data.has("operation"):
           _send_error_response(client, 400, "Bad Request", "Missing required parameter: operation")
           return

       var position_array = request_data["position"]
       var radius = request_data["radius"]
       var intensity = request_data["intensity"]
       var operation = request_data["operation"]

       # Validate types
       if typeof(position_array) != TYPE_ARRAY or position_array.size() != 3:
           _send_error_response(client, 400, "Bad Request", "position must be an array of 3 numbers [x, y, z]")
           return
       if typeof(radius) not in [TYPE_INT, TYPE_FLOAT]:
           _send_error_response(client, 400, "Bad Request", "radius must be a number")
           return
       if typeof(intensity) not in [TYPE_INT, TYPE_FLOAT]:
           _send_error_response(client, 400, "Bad Request", "intensity must be a number")
           return
       if typeof(operation) != TYPE_STRING:
           _send_error_response(client, 400, "Bad Request", "operation must be a string")
           return

       # Validate operation type
       if operation not in ["add", "subtract", "smooth", "flatten"]:
           _send_error_response(client, 400, "Bad Request", "operation must be one of: add, subtract, smooth, flatten")
           return

       var position = Vector3(float(position_array[0]), float(position_array[1]), float(position_array[2]))

       # Get VoxelTerrain
       var coordinator = get_tree().root.get_node_or_null("PlanetarySurvivalCoordinator")
       if not coordinator:
           _send_error_response(client, 500, "Internal Server Error", "PlanetarySurvivalCoordinator not found")
           return

       if not "voxel_terrain" in coordinator or coordinator.voxel_terrain == null:
           _send_error_response(client, 500, "Internal Server Error", "VoxelTerrain not initialized")
           return

       var voxel_terrain = coordinator.voxel_terrain

       # Call deform_sphere
       var voxels_modified = voxel_terrain.deform_sphere(position, float(radius), float(intensity), operation)

       # Send response
       var response_data = {
           "status": "success",
           "command": "deform",
           "position": [position.x, position.y, position.z],
           "radius": radius,
           "intensity": intensity,
           "operation": operation,
           "voxels_modified": voxels_modified
       }

       _send_json_response(client, 200, response_data)
   ```

**Estimated Implementation Time:** 2-4 hours
- 1-2 hours for VoxelTerrain backend methods
- 1 hour for HTTP endpoint handler
- 30 minutes for testing

**Dependencies:**
- VoxelTerrain system with deformation support
- Operation-based terrain modification algorithms

---

### 2. GET /terrain/chunk_info

**Status:** ❌ Not Implemented

**Purpose:** Retrieve information about a specific terrain chunk, including voxel data, modification state, and metadata.

**Design Specification:**

**Request:**
```
GET /terrain/chunk_info?position=10,5,10
```

**Parameters (Query String):**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `position` | String | ✅ Yes | Chunk position as "x,y,z" (comma-separated) |

**Expected Response (200 OK):**
```json
{
  "status": "success",
  "command": "chunk_info",
  "chunk_position": [0, 0, 0],
  "world_position": [10.0, 5.0, 10.0],
  "chunk_size": 16,
  "voxel_count": 4096,
  "modified_voxels": 234,
  "is_loaded": true,
  "is_modified": true,
  "memory_usage_bytes": 65536,
  "last_modified": "2025-12-02T10:30:45Z"
}
```

#### Implementation Plan

**Backend Requirements:**

1. **VoxelTerrain chunk query methods:**
   ```gdscript
   # In VoxelTerrain or chunk manager
   func get_chunk_info(world_position: Vector3) -> Dictionary:
       var chunk_pos = world_to_chunk(world_position)
       var chunk = get_chunk(chunk_pos)

       if chunk == null:
           return {
               "exists": false,
               "chunk_position": [chunk_pos.x, chunk_pos.y, chunk_pos.z]
           }

       return {
           "exists": true,
           "chunk_position": [chunk_pos.x, chunk_pos.y, chunk_pos.z],
           "world_position": [world_position.x, world_position.y, world_position.z],
           "chunk_size": chunk.size,
           "voxel_count": chunk.voxel_count,
           "modified_voxels": chunk.modified_voxel_count,
           "is_loaded": chunk.is_loaded,
           "is_modified": chunk.is_modified,
           "memory_usage_bytes": chunk.memory_usage,
           "last_modified": chunk.last_modified_timestamp
       }
   ```

2. **HTTP endpoint handler:**
   ```gdscript
   # In godot_bridge.gd
   func _handle_terrain_endpoint(client: StreamPeerTCP, method: String, path: String, body: String) -> void:
       var terrain_command = path.substr(9)  # Remove "/terrain/" prefix

       # Special handling for GET requests
       if method == "GET" and terrain_command.begins_with("chunk_info"):
           _handle_terrain_chunk_info(client, terrain_command)
           return

       # ... existing POST handling ...
   ```

3. **Handler implementation:**
   ```gdscript
   func _handle_terrain_chunk_info(client: StreamPeerTCP, command: String) -> void:
       # Parse query string
       var query_start = command.find("?")
       if query_start == -1:
           _send_error_response(client, 400, "Bad Request", "Missing query parameter: position")
           return

       var query_string = command.substr(query_start + 1)
       var params = _parse_query_string(query_string)

       if not params.has("position"):
           _send_error_response(client, 400, "Bad Request", "Missing required parameter: position")
           return

       # Parse position (format: "x,y,z")
       var position_parts = params["position"].split(",")
       if position_parts.size() != 3:
           _send_error_response(client, 400, "Bad Request", "position must be in format 'x,y,z'")
           return

       var position = Vector3(
           float(position_parts[0]),
           float(position_parts[1]),
           float(position_parts[2])
       )

       # Get VoxelTerrain
       var coordinator = get_tree().root.get_node_or_null("PlanetarySurvivalCoordinator")
       if not coordinator or not coordinator.voxel_terrain:
           _send_error_response(client, 500, "Internal Server Error", "VoxelTerrain not available")
           return

       var voxel_terrain = coordinator.voxel_terrain

       # Get chunk info
       var chunk_info = voxel_terrain.get_chunk_info(position)

       # Send response
       var response_data = {
           "status": "success",
           "command": "chunk_info"
       }
       response_data.merge(chunk_info)

       _send_json_response(client, 200, response_data)

   # Helper function to parse query string
   func _parse_query_string(query: String) -> Dictionary:
       var result = {}
       var pairs = query.split("&")
       for pair in pairs:
           var kv = pair.split("=")
           if kv.size() == 2:
               result[kv[0]] = kv[1]
       return result
   ```

**Estimated Implementation Time:** 3-5 hours
- 2-3 hours for VoxelTerrain chunk metadata system
- 1 hour for HTTP GET endpoint with query parsing
- 1 hour for testing

**Dependencies:**
- Chunk management system with metadata tracking
- Query string parsing utilities

---

### 3. POST /terrain/reset_chunk

**Status:** ❌ Not Implemented

**Purpose:** Reset a terrain chunk to its original procedurally-generated state, undoing all modifications.

**Design Specification:**

**Request:**
```json
POST /terrain/reset_chunk
Content-Type: application/json

{
  "chunk_position": [0, 0, 0]
}
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `chunk_position` | Array[int, int, int] | ✅ Yes | Chunk coordinates `[x, y, z]` in chunk space |

**Alternative (world position):**
```json
{
  "world_position": [10.0, 5.0, 10.0]
}
```

**Expected Response (200 OK):**
```json
{
  "status": "success",
  "command": "reset_chunk",
  "chunk_position": [0, 0, 0],
  "voxels_reset": 4096,
  "modifications_cleared": 234
}
```

#### Implementation Plan

**Backend Requirements:**

1. **VoxelTerrain chunk reset method:**
   ```gdscript
   # In VoxelTerrain or chunk manager
   func reset_chunk(chunk_position: Vector3i) -> Dictionary:
       var chunk = get_chunk(chunk_position)
       if chunk == null:
           return {
               "success": false,
               "error": "Chunk not found"
           }

       # Get original voxel data from generator
       var original_data = generate_chunk_data(chunk_position)

       # Replace current data with original
       var modifications_cleared = chunk.modified_voxel_count
       chunk.set_voxel_data(original_data)
       chunk.is_modified = false
       chunk.modified_voxel_count = 0

       # Update mesh
       chunk.update_mesh()

       return {
           "success": true,
           "voxels_reset": chunk.voxel_count,
           "modifications_cleared": modifications_cleared
       }
   ```

2. **HTTP endpoint handler:**
   ```gdscript
   # In godot_bridge.gd, add to match statement:
   func _handle_terrain_endpoint(client: StreamPeerTCP, method: String, path: String, body: String) -> void:
       # ... existing code ...
       match terrain_command:
           "excavate":
               _handle_terrain_excavate(client, request_data)
           "elevate":
               _handle_terrain_elevate(client, request_data)
           "reset_chunk":  # NEW
               _handle_terrain_reset_chunk(client, request_data)
           _:
               _send_error_response(client, 404, "Not Found", "Unknown terrain command: " + terrain_command)
   ```

3. **Handler implementation:**
   ```gdscript
   func _handle_terrain_reset_chunk(client: StreamPeerTCP, request_data: Dictionary) -> void:
       # Support either chunk_position or world_position
       var chunk_position: Vector3i

       if request_data.has("chunk_position"):
           var chunk_array = request_data["chunk_position"]
           if typeof(chunk_array) != TYPE_ARRAY or chunk_array.size() != 3:
               _send_error_response(client, 400, "Bad Request", "chunk_position must be an array of 3 integers [x, y, z]")
               return
           chunk_position = Vector3i(int(chunk_array[0]), int(chunk_array[1]), int(chunk_array[2]))

       elif request_data.has("world_position"):
           var world_array = request_data["world_position"]
           if typeof(world_array) != TYPE_ARRAY or world_array.size() != 3:
               _send_error_response(client, 400, "Bad Request", "world_position must be an array of 3 numbers [x, y, z]")
               return
           var world_pos = Vector3(float(world_array[0]), float(world_array[1]), float(world_array[2]))

           # Get VoxelTerrain to convert world to chunk position
           var coordinator = get_tree().root.get_node_or_null("PlanetarySurvivalCoordinator")
           if not coordinator or not coordinator.voxel_terrain:
               _send_error_response(client, 500, "Internal Server Error", "VoxelTerrain not available")
               return

           chunk_position = coordinator.voxel_terrain.world_to_chunk(world_pos)
       else:
           _send_error_response(client, 400, "Bad Request", "Missing required parameter: chunk_position or world_position")
           return

       # Get VoxelTerrain
       var coordinator = get_tree().root.get_node_or_null("PlanetarySurvivalCoordinator")
       if not coordinator or not coordinator.voxel_terrain:
           _send_error_response(client, 500, "Internal Server Error", "VoxelTerrain not available")
           return

       var voxel_terrain = coordinator.voxel_terrain

       # Reset chunk
       var result = voxel_terrain.reset_chunk(chunk_position)

       if not result["success"]:
           _send_error_response(client, 404, "Not Found", result.get("error", "Chunk not found"))
           return

       # Send response
       var response_data = {
           "status": "success",
           "command": "reset_chunk",
           "chunk_position": [chunk_position.x, chunk_position.y, chunk_position.z],
           "voxels_reset": result["voxels_reset"],
           "modifications_cleared": result["modifications_cleared"]
       }

       _send_json_response(client, 200, response_data)
   ```

**Estimated Implementation Time:** 3-4 hours
- 2 hours for chunk reset and regeneration logic
- 1 hour for HTTP endpoint handler
- 1 hour for testing

**Dependencies:**
- Chunk generation system to recreate original data
- Chunk modification tracking

---

## Design Rationale

### Why These Endpoints Don't Currently Exist

**Possible Reasons:**

1. **Simplified Initial Implementation:**
   - Current implementation focuses on basic excavate/elevate operations
   - More advanced features deferred to later iterations

2. **Different Use Cases:**
   - Current endpoints (`excavate`/`elevate`) designed for resource-based gameplay
   - Missing endpoints would support more advanced terrain editing features

3. **Backend Limitations:**
   - VoxelTerrain system may not currently support all operation types
   - Chunk metadata tracking may not be fully implemented

4. **Test Specifications from Alternative Design:**
   - Tests may have been written for a planned but not-yet-implemented design
   - Or from a different branch/version of the codebase

### Design Differences

**Current Implementation (excavate/elevate):**
- Resource-focused (soil removal/addition)
- Simple sphere-based operations
- Direct voxel manipulation
- Integrated with resource management system

**Missing Endpoints (deform/chunk_info/reset):**
- Editor-focused (terrain sculpting)
- Multiple operation types
- Chunk-level metadata and management
- Terrain regeneration capabilities

---

## Implementation Priority

If implementing these endpoints, suggested priority order:

### Priority 1: POST /terrain/deform
- **Why:** Provides more flexible terrain modification
- **Value:** Enables advanced gameplay features (smoothing, flattening)
- **Complexity:** Medium (requires operation-specific algorithms)

### Priority 2: POST /terrain/reset_chunk
- **Why:** Useful for debugging and player-driven "undo" features
- **Value:** Enables terrain restoration gameplay mechanics
- **Complexity:** Medium (requires chunk regeneration system)

### Priority 3: GET /terrain/chunk_info
- **Why:** Debugging and monitoring tool
- **Value:** Enables terrain analysis and optimization
- **Complexity:** Low (mostly metadata retrieval)

---

## Testing Strategy (When Implemented)

### Test Cases for /terrain/deform

```python
# Test all operation types
operations = ["add", "subtract", "smooth", "flatten"]
for op in operations:
    test_deform(operation=op)

# Test invalid operation
test_deform(operation="invalid_op", expect_error=True)

# Test edge cases
test_deform(intensity=0)  # No change
test_deform(radius=0)     # Single voxel
```

### Test Cases for /terrain/chunk_info

```python
# Test existing chunk
test_chunk_info(position="10,5,10", expect_loaded=True)

# Test unloaded chunk
test_chunk_info(position="10000,5,10000", expect_loaded=False)

# Test invalid position format
test_chunk_info(position="invalid", expect_error=True)
```

### Test Cases for /terrain/reset_chunk

```python
# Test with modifications
modify_terrain(...)
test_reset_chunk(chunk=[0,0,0], expect_success=True)
verify_terrain_unmodified()

# Test unmodified chunk
test_reset_chunk(chunk=[0,0,0], expect_success=True)

# Test nonexistent chunk
test_reset_chunk(chunk=[9999,9999,9999], expect_error=True)
```

---

## Related Documentation

- **Implemented Endpoints:** `C:/godot/TERRAIN_API_REFERENCE.md`
- **Working Tests:** `C:/godot/test_terrain_working.py`
- **HTTP API Overview:** `C:/godot/addons/godot_debug_connection/HTTP_API.md`
- **GodotBridge Implementation:** `C:/godot/addons/godot_debug_connection/godot_bridge.gd`

---

## Decision Required

**Question:** Should these missing endpoints be implemented?

**Considerations:**

1. **Use Case:** Are these features needed for current gameplay?
2. **Priority:** Are other features more important?
3. **Backend Ready:** Does VoxelTerrain support these operations?
4. **Maintenance Cost:** Will these endpoints be actively used?

**Recommendation:**
- If **gameplay needs** terrain sculpting: Implement `/terrain/deform` first
- If **debugging/monitoring** needed: Implement `/terrain/chunk_info`
- If **player restoration** feature planned: Implement `/terrain/reset_chunk`
- Otherwise: Keep current simple implementation and revisit later

---

## Summary

Three terrain endpoints were tested but are not currently implemented:

1. **POST /terrain/deform** - Generic deformation with operation types
2. **GET /terrain/chunk_info** - Chunk metadata queries
3. **POST /terrain/reset_chunk** - Chunk restoration

**Current status:** Not required for basic terrain modification gameplay.

**If needed:** Follow implementation plans in this document (estimated 8-13 hours total).
