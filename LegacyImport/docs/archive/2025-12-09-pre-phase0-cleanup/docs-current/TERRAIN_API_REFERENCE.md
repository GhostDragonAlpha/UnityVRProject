# Terrain Deformation API Reference

**Version:** 1.0
**Last Updated:** 2025-12-02
**Base URL:** `http://127.0.0.1:8080`

## Overview

The Terrain API provides endpoints for dynamic voxel-based terrain modification in SpaceTime VR. The API supports two primary operations: excavating (removing) and elevating (adding) terrain in spherical volumes.

**Key Features:**
- Real-time voxel terrain modification
- Sphere-based excavation and elevation
- Soil volume tracking and resource management
- Integration with PlanetarySurvivalCoordinator system

---

## Implementation Status

| Endpoint | Status | Implementation |
|----------|--------|----------------|
| `POST /terrain/excavate` | ✅ **IMPLEMENTED** | Fully functional |
| `POST /terrain/elevate` | ✅ **IMPLEMENTED** | Fully functional |
| `POST /terrain/deform` | ❌ Not implemented | See TERRAIN_MISSING_ENDPOINTS.md |
| `GET /terrain/chunk_info` | ❌ Not implemented | See TERRAIN_MISSING_ENDPOINTS.md |
| `POST /terrain/reset_chunk` | ❌ Not implemented | See TERRAIN_MISSING_ENDPOINTS.md |

---

## Prerequisites

### Required Components

1. **Godot running with debug flags:**
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. **PlanetarySurvivalCoordinator node:**
   - Must be present in scene tree at root level
   - Must have `voxel_terrain` property initialized
   - VoxelTerrain must be ready and loaded

3. **VoxelTerrain system:**
   - Voxel terrain mesh must be initialized
   - Terrain modification functions must be available

### Error Responses

If prerequisites are not met, you will receive:

```json
{
  "error": "Internal Server Error",
  "message": "PlanetarySurvivalCoordinator not found",
  "status_code": 500
}
```

or

```json
{
  "error": "Internal Server Error",
  "message": "VoxelTerrain not initialized",
  "status_code": 500
}
```

---

## Endpoints

### 1. POST /terrain/excavate

Removes terrain in a spherical volume, creating a crater or tunnel. Returns the amount of soil removed.

#### Request

**Method:** `POST`
**URL:** `/terrain/excavate`
**Content-Type:** `application/json`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `center` | Array[float, float, float] | ✅ Yes | Center position of excavation sphere `[x, y, z]` |
| `radius` | Number (int or float) | ✅ Yes | Radius of the excavation sphere in meters |

**Example Request:**

```bash
curl -X POST http://127.0.0.1:8080/terrain/excavate \
  -H "Content-Type: application/json" \
  -d '{
    "center": [10.0, 5.0, 10.0],
    "radius": 3.0
  }'
```

**Python Example:**

```python
import requests

response = requests.post(
    "http://127.0.0.1:8080/terrain/excavate",
    json={
        "center": [10.0, 5.0, 10.0],
        "radius": 3.0
    }
)

data = response.json()
print(f"Excavated {data['soil_removed']} cubic units of soil")
```

#### Response

**Success (200 OK):**

```json
{
  "status": "success",
  "command": "excavate",
  "center": [10.0, 5.0, 10.0],
  "radius": 3.0,
  "soil_removed": 113.097
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Always "success" for successful excavation |
| `command` | String | Echo of command type ("excavate") |
| `center` | Array[float] | Echo of center position |
| `radius` | Number | Echo of radius used |
| `soil_removed` | Number | Volume of soil removed in cubic units |

**Error Responses:**

**400 Bad Request - Missing parameter:**
```json
{
  "error": "Bad Request",
  "message": "Missing required parameter: center",
  "status_code": 400
}
```

**400 Bad Request - Invalid center format:**
```json
{
  "error": "Bad Request",
  "message": "center must be an array of 3 numbers [x, y, z]",
  "status_code": 400
}
```

**400 Bad Request - Invalid radius:**
```json
{
  "error": "Bad Request",
  "message": "radius must be a number",
  "status_code": 400
}
```

**500 Internal Server Error - System not ready:**
```json
{
  "error": "Internal Server Error",
  "message": "PlanetarySurvivalCoordinator not found",
  "status_code": 500
}
```

#### Implementation Details

**Source:** `C:/godot/addons/godot_debug_connection/godot_bridge.gd` (lines 547-596)

**Backend Call:** `voxel_terrain.excavate_sphere(center: Vector3, radius: float) -> float`

**Validation Steps:**
1. Parse JSON body
2. Validate `center` is array of 3 numbers
3. Validate `radius` is a number
4. Check PlanetarySurvivalCoordinator exists
5. Check VoxelTerrain is initialized
6. Call VoxelTerrain.excavate_sphere()
7. Return soil volume removed

---

### 2. POST /terrain/elevate

Adds terrain in a spherical volume, creating a mound or hill. Requires available soil resources.

#### Request

**Method:** `POST`
**URL:** `/terrain/elevate`
**Content-Type:** `application/json`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `center` | Array[float, float, float] | ✅ Yes | Center position of elevation sphere `[x, y, z]` |
| `radius` | Number (int or float) | ✅ Yes | Radius of the elevation sphere in meters |
| `soil_available` | Number (int or float) | ✅ Yes | Amount of soil available to use (cubic units) |

**Example Request:**

```bash
curl -X POST http://127.0.0.1:8080/terrain/elevate \
  -H "Content-Type: application/json" \
  -d '{
    "center": [10.0, 5.0, 10.0],
    "radius": 3.0,
    "soil_available": 150
  }'
```

**Python Example:**

```python
import requests

response = requests.post(
    "http://127.0.0.1:8080/terrain/elevate",
    json={
        "center": [10.0, 5.0, 10.0],
        "radius": 3.0,
        "soil_available": 150
    }
)

data = response.json()
if data["success"]:
    print("Terrain elevated successfully")
else:
    print("Insufficient soil resources")
```

#### Response

**Success (200 OK) - Sufficient resources:**

```json
{
  "status": "success",
  "command": "elevate",
  "center": [10.0, 5.0, 10.0],
  "radius": 3.0,
  "soil_available": 150,
  "success": true
}
```

**Success (200 OK) - Insufficient resources:**

```json
{
  "status": "insufficient_resources",
  "command": "elevate",
  "center": [10.0, 5.0, 10.0],
  "radius": 3.0,
  "soil_available": 50,
  "success": false
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | "success" or "insufficient_resources" |
| `command` | String | Echo of command type ("elevate") |
| `center` | Array[float] | Echo of center position |
| `radius` | Number | Echo of radius used |
| `soil_available` | Number | Echo of soil available |
| `success` | Boolean | `true` if elevation succeeded, `false` if insufficient resources |

**Error Responses:**

**400 Bad Request - Missing parameter:**
```json
{
  "error": "Bad Request",
  "message": "Missing required parameter: soil_available",
  "status_code": 400
}
```

**400 Bad Request - Invalid parameter types:**
```json
{
  "error": "Bad Request",
  "message": "center must be an array of 3 numbers [x, y, z]",
  "status_code": 400
}
```

**500 Internal Server Error - System not ready:**
```json
{
  "error": "Internal Server Error",
  "message": "VoxelTerrain not initialized",
  "status_code": 500
}
```

#### Implementation Details

**Source:** `C:/godot/addons/godot_debug_connection/godot_bridge.gd` (lines 598-656)

**Backend Call:** `voxel_terrain.elevate_sphere(center: Vector3, radius: float, soil_available: int) -> bool`

**Validation Steps:**
1. Parse JSON body
2. Validate `center` is array of 3 numbers
3. Validate `radius` is a number
4. Validate `soil_available` is a number
5. Check PlanetarySurvivalCoordinator exists
6. Check VoxelTerrain is initialized
7. Call VoxelTerrain.elevate_sphere()
8. Return success/failure based on resource availability

**Resource Logic:**
- If `soil_available` < required volume: `success = false`, no terrain modification
- If `soil_available` >= required volume: `success = true`, terrain is elevated

---

## Common Workflows

### Excavate and Reuse Soil

```python
import requests

BASE_URL = "http://127.0.0.1:8080"

# 1. Excavate terrain
excavate_response = requests.post(
    f"{BASE_URL}/terrain/excavate",
    json={"center": [10, 5, 10], "radius": 2.5}
)
soil_removed = excavate_response.json()["soil_removed"]

# 2. Use excavated soil to build elsewhere
elevate_response = requests.post(
    f"{BASE_URL}/terrain/elevate",
    json={
        "center": [20, 5, 20],
        "radius": 2.5,
        "soil_available": soil_removed
    }
)

if elevate_response.json()["success"]:
    print("Successfully relocated terrain!")
```

### Dig Tunnel

```python
import requests

BASE_URL = "http://127.0.0.1:8080"

# Create tunnel by excavating multiple overlapping spheres
tunnel_points = [
    [10, 5, 10],
    [12, 5, 12],
    [14, 5, 14],
    [16, 5, 16],
]

for point in tunnel_points:
    response = requests.post(
        f"{BASE_URL}/terrain/excavate",
        json={"center": point, "radius": 1.5}
    )
    print(f"Excavated at {point}: {response.json()['soil_removed']} units")
```

### Build Defensive Wall

```python
import requests

BASE_URL = "http://127.0.0.1:8080"

# Build a wall by elevating a line of spheres
# Assume we have 1000 units of soil available
wall_points = [
    [0, 0, 10],
    [0, 0, 12],
    [0, 0, 14],
    [0, 0, 16],
]

soil_per_section = 250
for point in wall_points:
    response = requests.post(
        f"{BASE_URL}/terrain/elevate",
        json={
            "center": point,
            "radius": 2.0,
            "soil_available": soil_per_section
        }
    )
    if not response.json()["success"]:
        print(f"Failed to build at {point} - insufficient soil")
```

---

## Testing

### Manual Testing with cURL

**Test excavate:**
```bash
# Valid excavation
curl -X POST http://127.0.0.1:8080/terrain/excavate \
  -H "Content-Type: application/json" \
  -d '{"center": [10, 5, 10], "radius": 2.0}'

# Missing parameter
curl -X POST http://127.0.0.1:8080/terrain/excavate \
  -H "Content-Type: application/json" \
  -d '{"center": [10, 5, 10]}'

# Invalid center format
curl -X POST http://127.0.0.1:8080/terrain/excavate \
  -H "Content-Type: application/json" \
  -d '{"center": [10, 5], "radius": 2.0}'
```

**Test elevate:**
```bash
# Valid elevation
curl -X POST http://127.0.0.1:8080/terrain/elevate \
  -H "Content-Type: application/json" \
  -d '{"center": [10, 5, 10], "radius": 2.0, "soil_available": 100}'

# Insufficient resources
curl -X POST http://127.0.0.1:8080/terrain/elevate \
  -H "Content-Type: application/json" \
  -d '{"center": [10, 5, 10], "radius": 10.0, "soil_available": 1}'
```

### Automated Testing

See `C:/godot/test_terrain_working.py` for automated test suite.

```bash
python test_terrain_working.py
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Cause |
|------|---------|-------|
| 200 | OK | Request successful (check `success` field for elevate) |
| 400 | Bad Request | Invalid parameters or malformed JSON |
| 404 | Not Found | Unknown terrain command |
| 500 | Internal Server Error | System not ready (coordinator or terrain missing) |

### Common Error Scenarios

**Scenario 1: VoxelTerrain not loaded**
- **Error:** `PlanetarySurvivalCoordinator not found` or `VoxelTerrain not initialized`
- **Solution:** Ensure the survival scene is loaded, not just the VR main scene

**Scenario 2: Invalid JSON**
- **Error:** `Invalid JSON in request body`
- **Solution:** Validate JSON syntax, ensure proper Content-Type header

**Scenario 3: Wrong endpoint name**
- **Error:** `Unknown terrain command: deform`
- **Solution:** Use correct endpoint names (`excavate` or `elevate`)

**Scenario 4: Insufficient resources**
- **Status:** 200 OK
- **Response:** `{"success": false, "status": "insufficient_resources"}`
- **Solution:** This is not an error, but indicates resource constraint

---

## Architecture Notes

### System Dependencies

```
HTTP Request
    ↓
GodotBridge._handle_terrain_endpoint()
    ↓
    ├─→ _handle_terrain_excavate()
    │       ↓
    │   PlanetarySurvivalCoordinator
    │       ↓
    │   VoxelTerrain.excavate_sphere()
    │
    └─→ _handle_terrain_elevate()
            ↓
        PlanetarySurvivalCoordinator
            ↓
        VoxelTerrain.elevate_sphere()
```

### VoxelTerrain Backend

The terrain endpoints call GDScript functions on the VoxelTerrain node:

**excavate_sphere(center: Vector3, radius: float) -> float**
- Removes voxels within spherical radius
- Returns volume of voxels removed (for resource tracking)

**elevate_sphere(center: Vector3, radius: float, soil_available: int) -> bool**
- Adds voxels within spherical radius
- Consumes soil resources
- Returns `true` if sufficient resources, `false` otherwise

### Coordinate System

- Coordinates are in Godot's world space
- Origin depends on scene setup (typically player spawn point)
- Y-axis is vertical (up/down)
- Units are in meters

---

## Performance Considerations

### Request Latency

Typical response times:
- Small radius (1-3m): 10-50ms
- Medium radius (3-5m): 50-150ms
- Large radius (5-10m): 150-500ms

Latency depends on:
- Voxel mesh complexity
- Number of voxels affected
- Current system load

### Rate Limiting

No built-in rate limiting. For high-frequency modifications:
- Batch operations where possible
- Add client-side throttling (100-500ms between requests)
- Monitor system performance via telemetry

### Optimization Tips

1. **Use smaller radii for frequent operations**
   - Better performance
   - More precise control

2. **Batch distant modifications**
   - Group excavations/elevations in same area
   - Reduces mesh recalculation overhead

3. **Check coordinator availability once**
   - Cache coordinator reference if making multiple calls
   - Reduces tree traversal overhead

---

## Related Documentation

- **HTTP API Overview:** `C:/godot/addons/godot_debug_connection/HTTP_API.md`
- **Complete API Reference:** `C:/godot/addons/godot_debug_connection/API_REFERENCE.md`
- **Missing Terrain Endpoints:** `C:/godot/TERRAIN_MISSING_ENDPOINTS.md`
- **Test Results:** `C:/godot/TERRAIN_TEST_RESULTS.md`
- **Working Test Suite:** `C:/godot/test_terrain_working.py`

---

## Support

For issues or questions:
1. Check Godot console for error messages
2. Verify prerequisites are met
3. Test with `/status` endpoint to check system health
4. Review telemetry stream for real-time diagnostics

**Telemetry Connection:**
```bash
python telemetry_client.py
```

**Server Status:**
```bash
curl http://127.0.0.1:8080/status
```
