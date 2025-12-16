# SpaceTime VR - Game Systems Architecture

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Audience:** Engineers, Technical Designers, System Architects

This document provides comprehensive documentation of all game systems in SpaceTime VR, including voxel terrain, server meshing, authority transfer, persistence, creature AI, and base building.

## Table of Contents

1. [Voxel Terrain System](#voxel-terrain-system)
2. [Server Meshing](#server-meshing)
3. [Authority Transfer Protocol](#authority-transfer-protocol)
4. [Persistence and Save System](#persistence-and-save-system)
5. [Creature AI](#creature-ai)
6. [Taming and Breeding Mechanics](#taming-and-breeding-mechanics)
7. [Base Building System](#base-building-system)
8. [Power Grid System](#power-grid-system)
9. [Resource Management](#resource-management)
10. [Crafting System](#crafting-system)

---

## Voxel Terrain System

### Overview

The voxel terrain system provides fully deformable 3D terrain using a chunk-based approach with marching cubes mesh generation.

### Key Features

- **Fully Deformable:** Add, remove, or smooth terrain in real-time
- **Infinite World:** Procedurally generated chunks loaded on-demand
- **Material System:** Multiple material types with properties
- **LOD Support:** Level-of-detail rendering for performance
- **Multiplayer Sync:** Real-time synchronization across players

### Architecture

```
VoxelTerrain (Node3D)
├── ChunkManager
│   ├── Chunk Generation
│   ├── Chunk Loading/Unloading
│   └── LOD Management
├── MeshGenerator
│   ├── Marching Cubes
│   ├── Material Blending
│   └── Collision Generation
├── DeformationSystem
│   ├── Sphere Brush
│   ├── Smooth Brush
│   └── Material Painter
└── NetworkSync
    ├── Change Tracking
    ├── Compression
    └── Delta Updates
```

### Data Structures

#### Chunk

```gdscript
class_name VoxelChunk
extends Node3D

# Chunk size: 32x32x32 voxels
const CHUNK_SIZE = 32

# Voxel data (density + material)
var voxels: PackedByteArray  # Size: CHUNK_SIZE^3 * 2 bytes
var chunk_coords: Vector3i
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var dirty: bool = false
var lod_level: int = 0

# Generation state
var generated: bool = false
var meshed: bool = false
var loaded: bool = false
```

#### Voxel Data Format

Each voxel stored as 2 bytes:
- **Byte 0:** Density (0-255)
  - 0 = Empty
  - 127 = Surface
  - 255 = Solid
- **Byte 1:** Material ID + Properties
  - Bits 0-3: Material type (16 types)
  - Bits 4-7: Material properties (hardness, etc.)

**Materials:**
```gdscript
enum VoxelMaterial {
    AIR = 0,
    DIRT = 1,
    STONE = 2,
    SAND = 3,
    GRASS = 4,
    ROCK = 5,
    METAL_ORE = 6,
    ICE = 7,
    SNOW = 8,
    LAVA = 9,
    WATER = 10,
    # ... more materials
}
```

### Terrain Generation

#### Procedural Generation

```gdscript
func generate_chunk(chunk_coords: Vector3i) -> VoxelChunk:
    var chunk = VoxelChunk.new()
    chunk.chunk_coords = chunk_coords

    # Calculate world position
    var world_pos = chunk_coords * CHUNK_SIZE

    # Generate voxel data using noise
    for x in range(CHUNK_SIZE):
        for y in range(CHUNK_SIZE):
            for z in range(CHUNK_SIZE):
                var voxel_pos = world_pos + Vector3i(x, y, z)

                # Multi-octave Perlin noise
                var density = calculate_density(voxel_pos)
                var material = determine_material(voxel_pos, density)

                chunk.set_voxel(x, y, z, density, material)

    chunk.generated = true
    return chunk

func calculate_density(pos: Vector3i) -> int:
    # Base terrain height using Perlin noise
    var height = noise.get_noise_2d(pos.x * 0.01, pos.z * 0.01) * 50.0

    # Add caves using 3D noise
    var cave_noise = noise.get_noise_3d(pos.x * 0.05, pos.y * 0.05, pos.z * 0.05)

    # Combine noises
    var surface_distance = pos.y - height
    var density_value = 127 - surface_distance * 5

    # Apply caves
    if cave_noise > 0.3:
        density_value -= 100

    return clamp(int(density_value), 0, 255)
```

#### Biome System

```gdscript
enum Biome {
    PLAINS,
    DESERT,
    TUNDRA,
    MOUNTAINS,
    OCEAN,
    VOLCANIC
}

func determine_biome(pos: Vector2) -> Biome:
    # Use temperature and humidity noise
    var temperature = noise_temperature.get_noise_2d(pos.x * 0.001, pos.y * 0.001)
    var humidity = noise_humidity.get_noise_2d(pos.x * 0.001, pos.y * 0.001)

    # Biome selection based on temperature/humidity
    if temperature < -0.5:
        return Biome.TUNDRA
    elif temperature > 0.5:
        if humidity < 0:
            return Biome.DESERT
        else:
            return Biome.VOLCANIC
    else:
        if humidity < 0:
            return Biome.PLAINS
        else:
            return Biome.MOUNTAINS
```

### Mesh Generation

#### Marching Cubes

```gdscript
func generate_mesh(chunk: VoxelChunk) -> ArrayMesh:
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Iterate through voxels
    for x in range(CHUNK_SIZE - 1):
        for y in range(CHUNK_SIZE - 1):
            for z in range(CHUNK_SIZE - 1):
                # Get 8 corner densities
                var cube = get_cube_densities(chunk, x, y, z)

                # Calculate marching cubes index
                var cube_index = calculate_cube_index(cube)

                if cube_index == 0 or cube_index == 255:
                    continue  # Fully inside or outside

                # Generate triangles for this cube
                generate_cube_triangles(surface_tool, cube, cube_index, x, y, z)

    surface_tool.generate_normals()
    surface_tool.generate_tangents()

    chunk.meshed = true
    return surface_tool.commit()

func calculate_cube_index(densities: Array) -> int:
    var cube_index = 0
    for i in range(8):
        if densities[i] > 127:  # Above surface threshold
            cube_index |= (1 << i)
    return cube_index
```

### Terrain Deformation

#### Sphere Brush

```gdscript
func deform_terrain(position: Vector3, radius: float, strength: float, operation: String):
    # Find affected chunks
    var affected_chunks = get_chunks_in_sphere(position, radius)

    for chunk in affected_chunks:
        # Calculate voxels in sphere
        var voxels_modified = 0

        for x in range(CHUNK_SIZE):
            for y in range(CHUNK_SIZE):
                for z in range(CHUNK_SIZE):
                    var voxel_world_pos = chunk.get_voxel_world_pos(x, y, z)
                    var distance = voxel_world_pos.distance_to(position)

                    if distance <= radius:
                        # Apply falloff
                        var falloff = 1.0 - (distance / radius)
                        var delta = strength * falloff

                        match operation:
                            "add":
                                chunk.add_density(x, y, z, delta)
                            "remove":
                                chunk.add_density(x, y, z, -delta)
                            "smooth":
                                smooth_voxel(chunk, x, y, z)

                        voxels_modified += 1

        # Mark chunk as dirty for remeshing
        chunk.dirty = true

        # Network sync
        if multiplayer.is_server():
            sync_chunk_deformation.rpc(chunk.chunk_coords, position, radius, strength, operation)

    # Remesh dirty chunks
    remesh_dirty_chunks()
```

### Level of Detail (LOD)

```gdscript
const LOD_DISTANCES = [64, 128, 256, 512]  # Meters

func update_chunk_lod(chunk: VoxelChunk, camera_pos: Vector3):
    var chunk_center = chunk.get_center_position()
    var distance = chunk_center.distance_to(camera_pos)

    # Determine LOD level
    var new_lod = 0
    for i in range(LOD_DISTANCES.size()):
        if distance > LOD_DISTANCES[i]:
            new_lod = i + 1

    # Update if changed
    if new_lod != chunk.lod_level:
        chunk.lod_level = new_lod
        remesh_chunk_with_lod(chunk, new_lod)

func remesh_chunk_with_lod(chunk: VoxelChunk, lod: int):
    # LOD 0: Full detail (1 voxel = 1 unit)
    # LOD 1: Half detail (2 voxels = 1 unit)
    # LOD 2: Quarter detail (4 voxels = 1 unit)
    # etc.

    var skip = pow(2, lod)
    # Generate mesh with reduced resolution
```

### Network Synchronization

#### Change Tracking

```gdscript
# Track modified voxels for network sync
var modified_voxels: Dictionary = {}  # {chunk_coords: [voxel_changes]}

func track_voxel_change(chunk_coords: Vector3i, voxel_pos: Vector3i, old_value: int, new_value: int):
    if not modified_voxels.has(chunk_coords):
        modified_voxels[chunk_coords] = []

    modified_voxels[chunk_coords].append({
        "pos": voxel_pos,
        "old": old_value,
        "new": new_value,
        "timestamp": Time.get_ticks_msec()
    })
```

#### Delta Compression

```gdscript
func compress_chunk_changes(changes: Array) -> PackedByteArray:
    var buffer = StreamPeerBuffer.new()

    # Write number of changes
    buffer.put_u16(changes.size())

    for change in changes:
        # Pack position (3 bytes: 5 bits each for x,y,z within 32x32x32)
        var packed_pos = (change.pos.x << 10) | (change.pos.y << 5) | change.pos.z
        buffer.put_u16(packed_pos)

        # Pack old/new values (2 bytes)
        buffer.put_u8(change.old)
        buffer.put_u8(change.new)

    # Compress with zlib
    var compressed = buffer.data_array.compress(FileAccess.COMPRESSION_GZIP)
    return compressed
```

### Persistence

#### Chunk Saving

```gdscript
func save_chunk(chunk: VoxelChunk) -> Dictionary:
    return {
        "coords": chunk.chunk_coords,
        "voxels": Marshalls.variant_to_base64(chunk.voxels),
        "checksum": calculate_checksum(chunk.voxels),
        "modified_at": Time.get_unix_time_from_system()
    }

func load_chunk(chunk_data: Dictionary) -> VoxelChunk:
    var chunk = VoxelChunk.new()
    chunk.chunk_coords = chunk_data.coords
    chunk.voxels = Marshalls.base64_to_variant(chunk_data.voxels)

    # Verify checksum
    if calculate_checksum(chunk.voxels) != chunk_data.checksum:
        push_error("Chunk data corrupted!")
        return null

    chunk.generated = true
    chunk.loaded = true
    return chunk
```

---

## Server Meshing

### Overview

Server meshing divides the game world into zones, with each zone managed by a dedicated server instance. This enables horizontal scaling to support thousands of concurrent players.

### Architecture

```
Coordinator Server
├── Zone Assignment
├── Load Balancing
├── Player Routing
└── Health Monitoring
    │
    ├─── Zone Server 1 (0,0)
    │    ├── Authority over zone (0,0)
    │    ├── Players: 45
    │    └── Entities: 2,341
    │
    ├─── Zone Server 2 (0,1)
    │    ├── Authority over zone (0,1)
    │    ├── Players: 38
    │    └── Entities: 1,892
    │
    └─── Zone Server 3 (1,0)
         ├── Authority over zone (1,0)
         ├── Players: 52
         └── Entities: 3,105
```

### Zone Management

#### Zone Definition

```gdscript
class_name Zone
extends RefCounted

const ZONE_SIZE = 1000  # 1000m x 1000m

var zone_coords: Vector2i
var bounds: AABB
var server_id: String
var player_count: int = 0
var entity_count: int = 0
var load: float = 0.0  # 0.0 to 1.0

func _init(coords: Vector2i):
    zone_coords = coords
    bounds = AABB(
        Vector3(coords.x * ZONE_SIZE, -500, coords.y * ZONE_SIZE),
        Vector3(ZONE_SIZE, 1000, ZONE_SIZE)
    )

func contains_position(pos: Vector3) -> bool:
    return bounds.has_point(pos)

func calculate_load() -> float:
    # Load based on player count and entity count
    var player_load = player_count / 100.0  # Max 100 players per zone
    var entity_load = entity_count / 5000.0  # Max 5000 entities per zone
    load = (player_load + entity_load) / 2.0
    return load
```

#### Coordinator Server

```gdscript
class_name CoordinatorServer
extends Node

var zones: Dictionary = {}  # {zone_coords: Zone}
var zone_servers: Dictionary = {}  # {server_id: ZoneServer}
var players: Dictionary = {}  # {player_id: PlayerInfo}

func _ready():
    # Start coordinator services
    start_zone_assignment_service()
    start_load_balancing_service()
    start_health_monitoring_service()

func assign_zone_to_server(zone_coords: Vector2i) -> String:
    # Find least loaded server
    var least_loaded_server = null
    var min_load = 1.0

    for server_id in zone_servers:
        var server = zone_servers[server_id]
        if server.is_healthy() and server.get_load() < min_load:
            min_load = server.get_load()
            least_loaded_server = server

    if least_loaded_server:
        var zone = Zone.new(zone_coords)
        zone.server_id = least_loaded_server.server_id
        zones[zone_coords] = zone
        least_loaded_server.add_zone(zone)
        return least_loaded_server.server_id

    # No available server - provision new one
    return provision_new_zone_server()

func route_player_to_zone(player_id: String, position: Vector3) -> String:
    var zone_coords = world_pos_to_zone_coords(position)

    if not zones.has(zone_coords):
        assign_zone_to_server(zone_coords)

    var zone = zones[zone_coords]
    return zone.server_id

func world_pos_to_zone_coords(pos: Vector3) -> Vector2i:
    return Vector2i(
        int(floor(pos.x / Zone.ZONE_SIZE)),
        int(floor(pos.z / Zone.ZONE_SIZE))
    )
```

#### Zone Server

```gdscript
class_name ZoneServer
extends Node

var server_id: String
var managed_zones: Array[Zone] = []
var coordinator_connection: StreamPeerTCP
var entities: Dictionary = {}  # {entity_id: Entity}

func _ready():
    server_id = generate_server_id()
    connect_to_coordinator()
    start_entity_simulation()

func _physics_process(delta):
    # Simulate all entities in managed zones
    for entity_id in entities:
        var entity = entities[entity_id]
        if entity.has_authority:
            entity.simulate(delta)

            # Check if entity left zone
            if not is_entity_in_managed_zone(entity):
                transfer_entity_to_correct_zone(entity)

func add_zone(zone: Zone):
    managed_zones.append(zone)
    load_zone_state(zone)

func is_entity_in_managed_zone(entity: Entity) -> bool:
    for zone in managed_zones:
        if zone.contains_position(entity.position):
            return true
    return false

func transfer_entity_to_correct_zone(entity: Entity):
    var zone_coords = world_pos_to_zone_coords(entity.position)
    var target_zone = get_zone_at_coords(zone_coords)

    if target_zone and target_zone.server_id != server_id:
        # Transfer entity to another server
        request_entity_transfer.rpc_id(
            get_server_peer_id(target_zone.server_id),
            entity.serialize()
        )

        # Remove from local simulation
        entities.erase(entity.entity_id)
```

### Load Balancing

```gdscript
class_name LoadBalancer
extends Node

func _ready():
    # Check load every 10 seconds
    $Timer.timeout.connect(_on_load_check_timeout)
    $Timer.start(10.0)

func _on_load_check_timeout():
    # Find overloaded zones
    var overloaded_zones = []
    for zone_coords in coordinator.zones:
        var zone = coordinator.zones[zone_coords]
        if zone.calculate_load() > 0.8:  # 80% capacity
            overloaded_zones.append(zone)

    # Rebalance if needed
    for zone in overloaded_zones:
        attempt_zone_split(zone)

func attempt_zone_split(zone: Zone):
    # Check if zone can be split
    if zone.player_count < 20:
        return  # Too few players to benefit from split

    # Find player clustering
    var clusters = find_player_clusters(zone)

    if clusters.size() >= 2:
        # Split zone into sub-zones
        split_zone_into_subzones(zone, clusters)

func find_player_clusters(zone: Zone) -> Array:
    # Use k-means clustering to find player groups
    var player_positions = []
    for player_id in coordinator.players:
        var player = coordinator.players[player_id]
        if zone.contains_position(player.position):
            player_positions.append(player.position)

    return kmeans_clustering(player_positions, 2)  # 2 clusters
```

---

## Authority Transfer Protocol

### Overview

The authority transfer protocol manages which server has authoritative control over each entity as it moves through the world.

### Authority States

```gdscript
enum AuthorityState {
    NONE,           # No authority
    REQUESTING,     # Requesting authority transfer
    TRANSFERRING,   # Authority transfer in progress
    AUTHORITATIVE   # Has authority
}
```

### Transfer Process

```
Player enters new zone boundary
            │
            ▼
Request authority transfer
            │
            ▼
    Target server accepts?
            │
      ┌─────┴─────┐
      │           │
     Yes          No
      │           │
      ▼           ▼
Transfer state   Retry
      │
      ▼
Grant authority
      │
      ▼
Revoke local authority
      │
      ▼
  Complete
```

### Implementation

#### Authority Request

```gdscript
@rpc("any_peer", "reliable")
func request_authority_transfer(entity_id: String, target_zone_coords: Vector2i):
    if not multiplayer.is_server():
        return

    var entity = entities.get(entity_id)
    if not entity:
        return

    # Find target zone server
    var target_zone = coordinator.zones.get(target_zone_coords)
    if not target_zone:
        return

    var target_server_id = target_zone.server_id

    # Send transfer request
    var transfer_data = {
        "entity_id": entity_id,
        "entity_state": entity.serialize(),
        "source_server": server_id,
        "target_server": target_server_id,
        "timestamp": Time.get_ticks_msec()
    }

    entity.authority_state = AuthorityState.TRANSFERRING

    grant_authority.rpc_id(
        get_server_peer_id(target_server_id),
        transfer_data
    )

@rpc("authority", "reliable")
func grant_authority(transfer_data: Dictionary):
    var entity_id = transfer_data.entity_id
    var entity_state = transfer_data.entity_state

    # Create entity locally
    var entity = Entity.deserialize(entity_state)
    entity.authority_state = AuthorityState.AUTHORITATIVE
    entities[entity_id] = entity

    # Acknowledge transfer
    acknowledge_transfer.rpc_id(
        get_server_peer_id(transfer_data.source_server),
        entity_id
    )

@rpc("authority", "reliable")
func acknowledge_transfer(entity_id: String):
    # Remove entity from local simulation
    var entity = entities.get(entity_id)
    if entity:
        entity.authority_state = AuthorityState.NONE
        entities.erase(entity_id)
```

#### State Synchronization

```gdscript
class_name Entity
extends Node3D

var entity_id: String
var authority_state: AuthorityState = AuthorityState.NONE
var last_sync_time: int = 0

const SYNC_INTERVAL_MS = 100  # Sync every 100ms

func _physics_process(delta):
    if authority_state == AuthorityState.AUTHORITATIVE:
        # Simulate entity
        simulate(delta)

        # Sync state to clients
        var current_time = Time.get_ticks_msec()
        if current_time - last_sync_time >= SYNC_INTERVAL_MS:
            sync_state_to_clients()
            last_sync_time = current_time

func sync_state_to_clients():
    var state = {
        "entity_id": entity_id,
        "position": position,
        "velocity": velocity,
        "rotation": rotation,
        "health": health,
        "timestamp": Time.get_ticks_msec()
    }

    # Broadcast to all clients in zone
    sync_entity_state.rpc(state)

@rpc("authority", "unreliable")
func sync_entity_state(state: Dictionary):
    # Clients receive state updates
    if authority_state != AuthorityState.AUTHORITATIVE:
        # Apply state with interpolation
        position = lerp(position, state.position, 0.3)
        velocity = state.velocity
        rotation = lerp(rotation, state.rotation, 0.3)
        health = state.health
```

---

## Persistence and Save System

### Overview

The persistence system handles saving and loading of world state, including terrain modifications, player progress, structures, and entities.

### Save File Structure

```
save_file.json
├── metadata
│   ├── version
│   ├── timestamp
│   ├── playtime
│   └── world_seed
├── world_state
│   ├── terrain_chunks: []
│   ├── structures: []
│   └── entities: []
├── players: []
└── statistics
    ├── resources_gathered
    ├── creatures_tamed
    └── distance_traveled
```

### Save System Implementation

```gdscript
class_name SaveSystem
extends Node

const SAVE_DIR = "user://saves/"
const AUTOSAVE_INTERVAL = 300.0  # 5 minutes

func save_world(save_name: String) -> bool:
    var save_data = {
        "metadata": get_metadata(),
        "world_state": get_world_state(),
        "players": get_player_data(),
        "statistics": get_statistics()
    }

    # Convert to JSON
    var json = JSON.stringify(save_data, "\t")

    # Write to file
    var file = FileAccess.open(SAVE_DIR + save_name + ".json", FileAccess.WRITE)
    if not file:
        push_error("Failed to create save file")
        return false

    file.store_string(json)
    file.close()

    # Save binary data (terrain chunks)
    save_terrain_chunks(save_name)

    print("World saved: ", save_name)
    return true

func get_metadata() -> Dictionary:
    return {
        "version": ProjectSettings.get_setting("application/config/version"),
        "timestamp": Time.get_unix_time_from_system(),
        "playtime": GameState.total_playtime_seconds,
        "world_seed": WorldGenerator.world_seed,
        "godot_version": Engine.get_version_info()
    }

func get_world_state() -> Dictionary:
    return {
        "terrain_modified_chunks": get_modified_terrain_chunks(),
        "structures": get_all_structures(),
        "entities": get_all_entities(),
        "time_of_day": DayNightCycle.time_of_day,
        "weather": WeatherSystem.current_weather
    }

func get_modified_terrain_chunks() -> Array:
    var chunks = []
    for chunk_coords in TerrainSystem.modified_chunks:
        chunks.append({
            "coords": chunk_coords,
            "checksum": TerrainSystem.get_chunk_checksum(chunk_coords)
        })
    return chunks

func get_all_structures() -> Array:
    var structures = []
    for structure in StructureManager.get_all_structures():
        structures.append(structure.serialize())
    return structures

func get_all_entities() -> Array:
    var entities = []
    for entity in EntityManager.get_all_entities():
        if entity.should_persist:
            entities.append(entity.serialize())
    return entities

func get_player_data() -> Array:
    var players = []
    for player_id in GameState.players:
        var player = GameState.players[player_id]
        players.append({
            "player_id": player_id,
            "position": player.position,
            "rotation": player.rotation,
            "health": player.health,
            "oxygen": player.oxygen,
            "inventory": player.inventory.serialize(),
            "stats": player.stats.serialize()
        })
    return players

func get_statistics() -> Dictionary:
    return {
        "resources_gathered": GameState.statistics.resources_gathered,
        "creatures_tamed": GameState.statistics.creatures_tamed,
        "distance_traveled": GameState.statistics.distance_traveled,
        "structures_built": GameState.statistics.structures_built,
        "time_in_spacecraft": GameState.statistics.time_in_spacecraft,
        "time_walking": GameState.statistics.time_walking
    }

func save_terrain_chunks(save_name: String):
    var terrain_dir = SAVE_DIR + save_name + "_terrain/"
    DirAccess.make_dir_recursive_absolute(terrain_dir)

    for chunk_coords in TerrainSystem.modified_chunks:
        var chunk = TerrainSystem.get_chunk(chunk_coords)
        if chunk:
            var chunk_file = terrain_dir + "chunk_%d_%d_%d.dat" % [
                chunk_coords.x, chunk_coords.y, chunk_coords.z
            ]

            # Compress and save chunk data
            var compressed = chunk.voxels.compress(FileAccess.COMPRESSION_GZIP)
            var file = FileAccess.open(chunk_file, FileAccess.WRITE)
            file.store_buffer(compressed)
            file.close()
```

### Load System

```gdscript
func load_world(save_name: String) -> bool:
    var save_file_path = SAVE_DIR + save_name + ".json"

    if not FileAccess.file_exists(save_file_path):
        push_error("Save file not found: ", save_name)
        return false

    # Read JSON file
    var file = FileAccess.open(save_file_path, FileAccess.READ)
    var json_string = file.get_as_text()
    file.close()

    # Parse JSON
    var json = JSON.new()
    var error = json.parse(json_string)
    if error != OK:
        push_error("Failed to parse save file JSON")
        return false

    var save_data = json.data

    # Validate version compatibility
    if not is_save_compatible(save_data.metadata):
        push_error("Save file version incompatible")
        return false

    # Load world state
    load_world_state(save_data.world_state, save_name)

    # Load players
    load_player_data(save_data.players)

    # Load statistics
    GameState.statistics = save_data.statistics

    print("World loaded: ", save_name)
    return true

func is_save_compatible(metadata: Dictionary) -> bool:
    var save_version = metadata.get("version", "0.0.0")
    var current_version = ProjectSettings.get_setting("application/config/version")

    # Major version must match
    var save_major = int(save_version.split(".")[0])
    var current_major = int(current_version.split(".")[0])

    return save_major == current_major

func load_world_state(world_state: Dictionary, save_name: String):
    # Set world seed
    WorldGenerator.world_seed = world_state.metadata.world_seed

    # Load terrain chunks
    load_terrain_chunks(save_name, world_state.terrain_modified_chunks)

    # Load structures
    for structure_data in world_state.structures:
        StructureManager.deserialize_structure(structure_data)

    # Load entities
    for entity_data in world_state.entities:
        EntityManager.deserialize_entity(entity_data)

    # Load time/weather
    DayNightCycle.time_of_day = world_state.time_of_day
    WeatherSystem.set_weather(world_state.weather)

func load_terrain_chunks(save_name: String, chunk_list: Array):
    var terrain_dir = SAVE_DIR + save_name + "_terrain/"

    for chunk_info in chunk_list:
        var chunk_coords = Vector3i(
            chunk_info.coords.x,
            chunk_info.coords.y,
            chunk_info.coords.z
        )

        var chunk_file = terrain_dir + "chunk_%d_%d_%d.dat" % [
            chunk_coords.x, chunk_coords.y, chunk_coords.z
        ]

        if FileAccess.file_exists(chunk_file):
            var file = FileAccess.open(chunk_file, FileAccess.READ)
            var compressed_data = file.get_buffer(file.get_length())
            file.close()

            # Decompress
            var voxels = compressed_data.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)

            # Verify checksum
            var checksum = hash(voxels)
            if checksum == chunk_info.checksum:
                # Create and load chunk
                var chunk = VoxelChunk.new()
                chunk.chunk_coords = chunk_coords
                chunk.voxels = voxels
                chunk.generated = true
                chunk.loaded = true

                TerrainSystem.add_chunk(chunk)
            else:
                push_warning("Chunk checksum mismatch: ", chunk_coords)
```

### Autosave

```gdscript
func _ready():
    # Start autosave timer
    var timer = Timer.new()
    timer.timeout.connect(_on_autosave_timeout)
    timer.wait_time = AUTOSAVE_INTERVAL
    timer.autostart = true
    add_child(timer)

func _on_autosave_timeout():
    # Create autosave
    var autosave_name = "autosave_" + str(Time.get_unix_time_from_system())
    save_world(autosave_name)

    # Keep only last 3 autosaves
    cleanup_old_autosaves()

func cleanup_old_autosaves():
    var autosaves = []
    var dir = DirAccess.open(SAVE_DIR)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.begins_with("autosave_"):
                autosaves.append(file_name)
            file_name = dir.get_next()
        dir.list_dir_end()

    # Sort by timestamp (newest first)
    autosaves.sort()
    autosaves.reverse()

    # Delete old autosaves
    for i in range(3, autosaves.size()):
        DirAccess.remove_absolute(SAVE_DIR + autosaves[i])
```

---

## Creature AI

### Overview

The creature AI system uses behavior trees to create complex, dynamic creature behaviors including wandering, hunting, fleeing, and social interactions.

### Behavior Tree Structure

```
RootNode
├── Sequence (Priority: Survival)
│   ├── Condition: Health Low?
│   └── Action: Flee
│
├── Sequence (Priority: Combat)
│   ├── Condition: Enemy Nearby?
│   └── Selector
│       ├── Sequence (If Aggressive)
│       │   ├── Action: Approach Enemy
│       │   └── Action: Attack
│       └── Action: Flee (If Passive)
│
├── Sequence (Priority: Hunger)
│   ├── Condition: Hungry?
│   └── Selector
│       ├── Sequence (Food Nearby)
│       │   ├── Action: Move To Food
│       │   └── Action: Eat
│       └── Action: Search For Food
│
└── Selector (Priority: Idle)
    ├── Action: Wander
    ├── Action: Rest
    └── Action: Socialize
```

### Behavior Tree Implementation

```gdscript
class_name BehaviorTree
extends Node

var root_node: BTNode
var blackboard: Dictionary = {}  # Shared data between nodes

func _init():
    root_node = create_behavior_tree()

func create_behavior_tree() -> BTNode:
    var root = BTSelector.new("Root")

    # Priority 1: Survival (flee when low health)
    var survival = BTSequence.new("Survival")
    survival.add_child(BTCondition.new("Health Low", is_health_low))
    survival.add_child(BTAction.new("Flee", flee_action))
    root.add_child(survival)

    # Priority 2: Combat
    var combat = BTSequence.new("Combat")
    combat.add_child(BTCondition.new("Enemy Nearby", is_enemy_nearby))

    var combat_selector = BTSelector.new("Combat Choice")

    # Aggressive: attack
    var attack_sequence = BTSequence.new("Attack")
    attack_sequence.add_child(BTCondition.new("Is Aggressive", is_aggressive))
    attack_sequence.add_child(BTAction.new("Approach", approach_enemy))
    attack_sequence.add_child(BTAction.new("Attack", attack_enemy))
    combat_selector.add_child(attack_sequence)

    # Passive: flee
    combat_selector.add_child(BTAction.new("Flee", flee_action))

    combat.add_child(combat_selector)
    root.add_child(combat)

    # Priority 3: Hunger
    var hunger = BTSequence.new("Hunger")
    hunger.add_child(BTCondition.new("Hungry", is_hungry))

    var food_selector = BTSelector.new("Find Food")

    # Food nearby: go eat
    var eat_sequence = BTSequence.new("Eat")
    eat_sequence.add_child(BTCondition.new("Food Nearby", is_food_nearby))
    eat_sequence.add_child(BTAction.new("Move To Food", move_to_food))
    eat_sequence.add_child(BTAction.new("Eat", eat_food))
    food_selector.add_child(eat_sequence)

    # No food: search
    food_selector.add_child(BTAction.new("Search For Food", search_for_food))

    hunger.add_child(food_selector)
    root.add_child(hunger)

    # Priority 4: Idle behaviors
    var idle = BTSelector.new("Idle")
    idle.add_child(BTAction.new("Wander", wander))
    idle.add_child(BTAction.new("Rest", rest))
    idle.add_child(BTAction.new("Socialize", socialize))
    root.add_child(idle)

    return root

func execute(creature: Creature, delta: float) -> int:
    blackboard["creature"] = creature
    blackboard["delta"] = delta
    return root_node.execute(blackboard)
```

### Behavior Node Types

```gdscript
# Base behavior tree node
class BTNode:
    enum Status { SUCCESS, FAILURE, RUNNING }

    var node_name: String
    var children: Array = []

    func _init(name: String):
        node_name = name

    func add_child(child: BTNode):
        children.append(child)

    func execute(blackboard: Dictionary) -> int:
        return Status.FAILURE

# Selector: runs children until one succeeds
class BTSelector extends BTNode:
    func execute(blackboard: Dictionary) -> int:
        for child in children:
            var result = child.execute(blackboard)
            if result != Status.FAILURE:
                return result
        return Status.FAILURE

# Sequence: runs children until one fails
class BTSequence extends BTNode:
    func execute(blackboard: Dictionary) -> int:
        for child in children:
            var result = child.execute(blackboard)
            if result != Status.SUCCESS:
                return result
        return Status.SUCCESS

# Condition: checks a condition
class BTCondition extends BTNode:
    var condition_func: Callable

    func _init(name: String, func_ref: Callable):
        super(name)
        condition_func = func_ref

    func execute(blackboard: Dictionary) -> int:
        if condition_func.call(blackboard):
            return Status.SUCCESS
        return Status.FAILURE

# Action: performs an action
class BTAction extends BTNode:
    var action_func: Callable

    func _init(name: String, func_ref: Callable):
        super(name)
        action_func = func_ref

    func execute(blackboard: Dictionary) -> int:
        return action_func.call(blackboard)
```

### Creature AI State

```gdscript
class_name CreatureAI
extends Node

var creature: Creature
var behavior_tree: BehaviorTree
var target: Node3D = null
var current_action: String = "idle"

# AI parameters
var detection_range: float = 20.0
var attack_range: float = 2.0
var flee_distance: float = 15.0

# State
var is_fleeing: bool = false
var is_attacking: bool = false
var hunger_level: float = 0.0  # 0-100
var aggression_level: float = 0.5  # 0-1

func _ready():
    creature = get_parent()
    behavior_tree = BehaviorTree.new()

func _physics_process(delta):
    # Execute behavior tree
    behavior_tree.execute(creature, delta)

    # Update hunger
    hunger_level += delta * 0.5  # Hunger increases over time
    hunger_level = clamp(hunger_level, 0, 100)

# Condition checks
func is_health_low(blackboard: Dictionary) -> bool:
    var creature = blackboard.creature
    return creature.health < creature.max_health * 0.3

func is_enemy_nearby(blackboard: Dictionary) -> bool:
    var creature = blackboard.creature
    var enemies = get_tree().get_nodes_in_group("players")

    for enemy in enemies:
        if creature.position.distance_to(enemy.position) < detection_range:
            target = enemy
            return true

    return false

func is_aggressive(blackboard: Dictionary) -> bool:
    return aggression_level > 0.6

func is_hungry(blackboard: Dictionary) -> bool:
    return hunger_level > 70.0

func is_food_nearby(blackboard: Dictionary) -> bool:
    var food_sources = get_tree().get_nodes_in_group("food")

    for food in food_sources:
        if creature.position.distance_to(food.position) < detection_range:
            target = food
            return true

    return false

# Actions
func flee_action(blackboard: Dictionary) -> int:
    var creature = blackboard.creature
    var delta = blackboard.delta

    if target:
        # Move away from target
        var flee_direction = (creature.position - target.position).normalized()
        creature.velocity = flee_direction * creature.speed * 1.5
        current_action = "fleeing"
        return BTNode.Status.RUNNING

    return BTNode.Status.SUCCESS

func approach_enemy(blackboard: Dictionary) -> int:
    var creature = blackboard.creature
    var delta = blackboard.delta

    if target:
        var distance = creature.position.distance_to(target.position)

        if distance > attack_range:
            # Move towards target
            var direction = (target.position - creature.position).normalized()
            creature.velocity = direction * creature.speed
            current_action = "approaching"
            return BTNode.Status.RUNNING
        else:
            current_action = "ready_to_attack"
            return BTNode.Status.SUCCESS

    return BTNode.Status.FAILURE

func attack_enemy(blackboard: Dictionary) -> int:
    var creature = blackboard.creature
    var delta = blackboard.delta

    if target and creature.position.distance_to(target.position) <= attack_range:
        # Perform attack
        if creature.attack_cooldown <= 0:
            creature.perform_attack(target)
            current_action = "attacking"
            return BTNode.Status.SUCCESS
        return BTNode.Status.RUNNING

    return BTNode.Status.FAILURE

func move_to_food(blackboard: Dictionary) -> int:
    var creature = blackboard.creature

    if target:
        var distance = creature.position.distance_to(target.position)

        if distance > 1.0:
            var direction = (target.position - creature.position).normalized()
            creature.velocity = direction * creature.speed
            current_action = "moving_to_food"
            return BTNode.Status.RUNNING
        else:
            return BTNode.Status.SUCCESS

    return BTNode.Status.FAILURE

func eat_food(blackboard: Dictionary) -> int:
    var creature = blackboard.creature

    if target:
        # Consume food
        hunger_level -= 50.0
        hunger_level = max(0, hunger_level)

        if target.has_method("consume"):
            target.consume()

        current_action = "eating"
        target = null
        return BTNode.Status.SUCCESS

    return BTNode.Status.FAILURE

func search_for_food(blackboard: Dictionary) -> int:
    var creature = blackboard.creature

    # Wander while searching
    if not creature.has_wander_target():
        creature.set_random_wander_target()

    current_action = "searching_for_food"
    return BTNode.Status.RUNNING

func wander(blackboard: Dictionary) -> int:
    var creature = blackboard.creature

    if not creature.has_wander_target():
        creature.set_random_wander_target()

    creature.move_to_wander_target()
    current_action = "wandering"
    return BTNode.Status.RUNNING

func rest(blackboard: Dictionary) -> int:
    var creature = blackboard.creature

    creature.velocity = Vector3.ZERO
    current_action = "resting"
    return BTNode.Status.SUCCESS

func socialize(blackboard: Dictionary) -> int:
    var creature = blackboard.creature

    # Find nearby creatures of same species
    var nearby_creatures = []
    for other in get_tree().get_nodes_in_group("creatures"):
        if other.species == creature.species:
            var distance = creature.position.distance_to(other.position)
            if distance < detection_range:
                nearby_creatures.append(other)

    if nearby_creatures.size() > 0:
        # Move towards nearest
        var nearest = nearby_creatures[0]
        var direction = (nearest.position - creature.position).normalized()
        creature.velocity = direction * creature.speed * 0.5
        current_action = "socializing"
        return BTNode.Status.RUNNING

    return BTNode.Status.FAILURE
```

---

## Taming and Breeding Mechanics

### Overview

Players can tame creatures and breed them to create stronger variants.

### Taming System

```gdscript
class_name TamingSystem
extends Node

const TAMING_DURATION = 30.0  # 30 seconds
const TAMING_FOOD_REQUIRED = 10

func attempt_tame_creature(player: Player, creature: Creature) -> bool:
    if creature.is_tamed:
        return false

    if creature.is_aggressive_to(player):
        return false

    # Check if player has required food
    if not player.inventory.has_item("creature_food", TAMING_FOOD_REQUIRED):
        return false

    # Start taming process
    start_taming(player, creature)
    return true

func start_taming(player: Player, creature: Creature):
    creature.taming_progress = 0.0
    creature.taming_player = player
    creature.is_being_tamed = true

    # Feed creature
    player.inventory.remove_item("creature_food", TAMING_FOOD_REQUIRED)

    # Start taming timer
    var timer = Timer.new()
    timer.timeout.connect(_on_taming_complete.bind(player, creature))
    timer.wait_time = TAMING_DURATION
    timer.one_shot = true
    add_child(timer)
    timer.start()

func _physics_process(delta):
    # Update taming progress for all creatures being tamed
    for creature in get_tree().get_nodes_in_group("creatures"):
        if creature.is_being_tamed:
            update_taming_progress(creature, delta)

func update_taming_progress(creature: Creature, delta: float):
    creature.taming_progress += delta / TAMING_DURATION

    # Check if player moved too far away
    if creature.taming_player:
        var distance = creature.position.distance_to(creature.taming_player.position)
        if distance > 10.0:
            cancel_taming(creature)

    # Update UI
    if creature.taming_player:
        creature.taming_player.ui.update_taming_progress(creature.taming_progress)

func _on_taming_complete(player: Player, creature: Creature):
    if not creature.is_being_tamed:
        return

    # Successfully tamed
    creature.is_tamed = true
    creature.owner_id = player.player_id
    creature.is_being_tamed = false
    creature.taming_player = null

    # Set creature to follow player
    creature.ai.set_follow_target(player)

    # Grant experience
    player.stats.add_experience("taming", 50)

    # Notification
    player.show_notification("Creature tamed!")

func cancel_taming(creature: Creature):
    creature.is_being_tamed = false
    creature.taming_progress = 0.0

    if creature.taming_player:
        creature.taming_player.show_notification("Taming cancelled")
        creature.taming_player = null
```

### Breeding System

```gdscript
class_name BreedingSystem
extends Node

const BREEDING_DURATION = 600.0  # 10 minutes
const GESTATION_DURATION = 1800.0  # 30 minutes

func attempt_breed_creatures(creature1: Creature, creature2: Creature) -> bool:
    # Validation checks
    if not can_breed(creature1, creature2):
        return false

    # Start breeding
    creature1.is_breeding = true
    creature2.is_breeding = true
    creature1.breeding_partner = creature2
    creature2.breeding_partner = creature1

    # Start breeding timer
    var timer = Timer.new()
    timer.timeout.connect(_on_breeding_complete.bind(creature1, creature2))
    timer.wait_time = BREEDING_DURATION
    timer.one_shot = true
    add_child(timer)
    timer.start()

    return true

func can_breed(creature1: Creature, creature2: Creature) -> bool:
    # Same species
    if creature1.species != creature2.species:
        return false

    # Both tamed
    if not creature1.is_tamed or not creature2.is_tamed:
        return false

    # Same owner
    if creature1.owner_id != creature2.owner_id:
        return false

    # Not currently breeding
    if creature1.is_breeding or creature2.is_breeding:
        return false

    # Not pregnant
    if creature1.is_pregnant or creature2.is_pregnant:
        return false

    # Breeding cooldown passed
    if not creature1.can_breed_again() or not creature2.can_breed_again():
        return false

    return true

func _on_breeding_complete(creature1: Creature, creature2: Creature):
    creature1.is_breeding = false
    creature2.is_breeding = false

    # Determine which creature becomes pregnant
    # (assuming creature2 is female for simplicity)
    creature2.is_pregnant = true
    creature2.pregnancy_progress = 0.0

    # Calculate offspring stats
    creature2.offspring_stats = calculate_offspring_stats(creature1, creature2)

    # Start gestation timer
    var timer = Timer.new()
    timer.timeout.connect(_on_gestation_complete.bind(creature2))
    timer.wait_time = GESTATION_DURATION
    timer.one_shot = true
    add_child(timer)
    timer.start()

    # Set breeding cooldowns
    creature1.last_breed_time = Time.get_ticks_msec()
    creature2.last_breed_time = Time.get_ticks_msec()

    # Notify owner
    notify_owner(creature1.owner_id, "Breeding successful! Baby will arrive in 30 minutes.")

func calculate_offspring_stats(parent1: Creature, parent2: Creature) -> Dictionary:
    var stats = {}

    # Inherit stats from parents with some randomness
    stats["health"] = (parent1.max_health + parent2.max_health) / 2.0 + randf_range(-10, 10)
    stats["damage"] = (parent1.damage + parent2.damage) / 2.0 + randf_range(-2, 2)
    stats["speed"] = (parent1.speed + parent2.speed) / 2.0 + randf_range(-1, 1)
    stats["level"] = max(parent1.level, parent2.level)

    # Chance for stat mutation (5% chance)
    if randf() < 0.05:
        var mutation_stat = ["health", "damage", "speed"].pick_random()
        stats[mutation_stat] *= 1.2  # 20% boost
        stats["is_mutant"] = true

    return stats

func _on_gestation_complete(creature: Creature):
    creature.is_pregnant = false

    # Spawn offspring
    var baby = spawn_offspring(creature)

    # Notify owner
    notify_owner(creature.owner_id, "A baby creature has been born!")

func spawn_offspring(mother: Creature) -> Creature:
    var baby_scene = load("res://creatures/" + mother.species + ".tscn")
    var baby = baby_scene.instantiate()

    # Apply offspring stats
    baby.max_health = mother.offspring_stats.health
    baby.health = baby.max_health
    baby.damage = mother.offspring_stats.damage
    baby.speed = mother.offspring_stats.speed
    baby.level = mother.offspring_stats.level

    # Set as baby
    baby.is_baby = true
    baby.growth_progress = 0.0
    baby.scale = Vector3.ONE * 0.5  # Babies are smaller

    # Tamed by same owner
    baby.is_tamed = true
    baby.owner_id = mother.owner_id

    # Spawn near mother
    baby.position = mother.position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))

    get_tree().current_scene.add_child(baby)

    return baby
```

---

## Base Building System

### Overview

Players can construct bases using modular building pieces including foundations, walls, roofs, and functional structures.

### Building Piece System

```gdscript
class_name BuildingPiece
extends StaticBody3D

enum PieceType {
    FOUNDATION,
    WALL,
    DOOR,
    WINDOW,
    ROOF,
    STAIRS,
    RAMP
}

var piece_type: PieceType
var piece_id: String
var owner_id: String
var health: float = 100.0
var max_health: float = 100.0
var snap_points: Array[SnapPoint] = []

func _ready():
    piece_id = generate_piece_id()
    add_to_group("structures")
    setup_snap_points()

func setup_snap_points():
    # Define snap points for this piece type
    match piece_type:
        PieceType.FOUNDATION:
            # Foundation has snap points on all 4 edges
            snap_points.append(SnapPoint.new(Vector3(2.5, 0, 0), Vector3.RIGHT))
            snap_points.append(SnapPoint.new(Vector3(-2.5, 0, 0), Vector3.LEFT))
            snap_points.append(SnapPoint.new(Vector3(0, 0, 2.5), Vector3.FORWARD))
            snap_points.append(SnapPoint.new(Vector3(0, 0, -2.5), Vector3.BACK))
            snap_points.append(SnapPoint.new(Vector3(0, 1, 0), Vector3.UP))

        PieceType.WALL:
            # Wall has snap points on sides and top
            snap_points.append(SnapPoint.new(Vector3(1.25, 0, 0), Vector3.RIGHT))
            snap_points.append(SnapPoint.new(Vector3(-1.25, 0, 0), Vector3.LEFT))
            snap_points.append(SnapPoint.new(Vector3(0, 1.5, 0), Vector3.UP))
            snap_points.append(SnapPoint.new(Vector3(0, -1.5, 0), Vector3.DOWN))
```

### Building System

```gdscript
class_name BuildingSystem
extends Node

var preview_piece: BuildingPiece = null
var can_place: bool = false
var snap_target: SnapPoint = null

const PLACEMENT_RANGE = 10.0
const SNAP_DISTANCE = 0.5

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    if preview_piece:
        update_preview_placement()

func start_building(piece_type: BuildingPiece.PieceType):
    # Load piece scene
    var piece_scene = load_piece_scene(piece_type)
    preview_piece = piece_scene.instantiate()
    preview_piece.modulate = Color(0, 1, 0, 0.5)  # Green transparent
    get_tree().current_scene.add_child(preview_piece)

func update_preview_placement():
    var player = get_player()
    var camera = player.get_camera()

    # Raycast from camera
    var from = camera.global_position
    var to = from + camera.global_transform.basis.z * -PLACEMENT_RANGE

    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player]
    var result = space_state.intersect_ray(query)

    if result:
        var hit_point = result.position
        var hit_normal = result.normal

        # Check for snap points
        snap_target = find_nearest_snap_point(hit_point)

        if snap_target:
            # Snap to target
            preview_piece.global_position = snap_target.global_position
            preview_piece.global_rotation = snap_target.global_rotation
            can_place = check_can_place_at_snap(snap_target)
        else:
            # Free placement
            preview_piece.global_position = hit_point
            align_to_surface(preview_piece, hit_normal)
            can_place = check_can_place_free(hit_point)

        # Update preview color
        if can_place:
            preview_piece.modulate = Color(0, 1, 0, 0.5)  # Green
        else:
            preview_piece.modulate = Color(1, 0, 0, 0.5)  # Red
    else:
        can_place = false
        preview_piece.modulate = Color(1, 0, 0, 0.5)  # Red

func find_nearest_snap_point(position: Vector3) -> SnapPoint:
    var nearest: SnapPoint = null
    var nearest_distance = SNAP_DISTANCE

    # Check all nearby structures
    for structure in get_tree().get_nodes_in_group("structures"):
        if structure is BuildingPiece:
            for snap_point in structure.snap_points:
                var snap_pos = structure.global_transform * snap_point.position
                var distance = position.distance_to(snap_pos)

                if distance < nearest_distance:
                    nearest = snap_point
                    nearest_distance = distance

    return nearest

func check_can_place_at_snap(snap: SnapPoint) -> bool:
    # Check if snap point is already occupied
    if snap.is_occupied:
        return false

    # Check if player has resources
    if not has_required_resources(preview_piece.piece_type):
        return false

    return true

func check_can_place_free(position: Vector3) -> bool:
    # Check if area is clear
    var space_state = get_world_3d().direct_space_state
    var shape = BoxShape3D.new()
    shape.size = Vector3(5, 3, 5)  # Foundation size

    var query = PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = preview_piece.global_transform
    query.collision_mask = 1  # Only check terrain/structures

    var result = space_state.intersect_shape(query)

    if result.size() > 0:
        return false  # Collision detected

    # Check if player has resources
    if not has_required_resources(preview_piece.piece_type):
        return false

    return true

func place_building_piece():
    if not can_place:
        return

    # Consume resources
    consume_resources(preview_piece.piece_type)

    # Convert preview to real structure
    var final_piece = preview_piece.duplicate()
    final_piece.modulate = Color.WHITE  # Remove transparency
    final_piece.owner_id = get_player().player_id
    get_tree().current_scene.add_child(final_piece)

    # Mark snap point as occupied
    if snap_target:
        snap_target.is_occupied = true

    # Network sync
    if multiplayer.is_server():
        sync_structure_placement.rpc(
            final_piece.piece_id,
            final_piece.piece_type,
            final_piece.global_position,
            final_piece.global_rotation,
            get_player().player_id
        )

    # Continue building (don't end placement mode)
    preview_piece.queue_free()
    preview_piece = null
    start_building(preview_piece.piece_type)  # Restart with same type

func has_required_resources(piece_type: BuildingPiece.PieceType) -> bool:
    var player = get_player()
    var required = get_required_resources(piece_type)

    for resource_id in required:
        if not player.inventory.has_item(resource_id, required[resource_id]):
            return false

    return true

func get_required_resources(piece_type: BuildingPiece.PieceType) -> Dictionary:
    match piece_type:
        BuildingPiece.PieceType.FOUNDATION:
            return {"stone": 20, "metal": 5}
        BuildingPiece.PieceType.WALL:
            return {"wood": 10, "stone": 5}
        BuildingPiece.PieceType.DOOR:
            return {"wood": 15, "metal": 3}
        _:
            return {}
```

---

## Power Grid System

See [Power Grid Documentation](../current/guides/POWER_GRID_HUD.md) for complete details.

### Overview

The power grid system manages electricity generation, distribution, and consumption across base structures.

### Architecture

```
PowerGrid
├── Generators (Solar, Wind, Fuel)
├── Batteries (Storage)
├── Consumers (Machines, Lights)
└── Distribution Network
```

---

## Resource Management

### Resource Types

```gdscript
enum ResourceType {
    # Raw Materials
    IRON_ORE,
    COPPER_ORE,
    SILICON,
    CARBON,
    ICE,

    # Processed Materials
    IRON_INGOT,
    COPPER_INGOT,
    GLASS,
    PLASTIC,

    # Energy
    ENERGY_CELL,
    FUEL,

    # Organic
    FOOD,
    WATER,
    OXYGEN_CANISTER
}
```

### Resource Collection

```gdscript
func collect_resource(player: Player, resource_node: ResourceNode):
    if not resource_node.can_harvest():
        return

    # Check tool requirement
    if resource_node.requires_tool and not player.has_required_tool(resource_node):
        player.show_message("Requires: " + resource_node.required_tool)
        return

    # Start harvesting
    var harvest_time = resource_node.harvest_time
    player.start_harvest_action(resource_node, harvest_time)

    await get_tree().create_timer(harvest_time).timeout

    # Grant resources
    var resource_id = resource_node.resource_type
    var amount = resource_node.yield_amount

    player.inventory.add_item(resource_id, amount)

    # Deplete node
    resource_node.harvest()

    # Stats
    player.stats.resources_gathered[resource_id] += amount
```

---

## Crafting System

### Crafting Recipe

```gdscript
class_name CraftingRecipe
extends Resource

@export var recipe_id: String
@export var result_item: String
@export var result_quantity: int = 1
@export var ingredients: Dictionary = {}  # {item_id: quantity}
@export var crafting_time: float = 1.0
@export var required_station: String = ""  # e.g., "fabricator", "workbench"

func can_craft(inventory: Inventory) -> bool:
    for item_id in ingredients:
        var required_qty = ingredients[item_id]
        if not inventory.has_item(item_id, required_qty):
            return false
    return true
```

### Crafting System

```gdscript
func craft_item(player: Player, recipe: CraftingRecipe):
    # Validate
    if not recipe.can_craft(player.inventory):
        player.show_message("Missing ingredients")
        return

    if recipe.required_station:
        if not player.is_at_crafting_station(recipe.required_station):
            player.show_message("Requires: " + recipe.required_station)
            return

    # Start crafting
    player.start_crafting_action(recipe)

    await get_tree().create_timer(recipe.crafting_time).timeout

    # Consume ingredients
    for item_id in recipe.ingredients:
        var qty = recipe.ingredients[item_id]
        player.inventory.remove_item(item_id, qty)

    # Grant result
    player.inventory.add_item(recipe.result_item, recipe.result_quantity)

    player.show_message("Crafted: " + recipe.result_item)
```

---

## Additional Resources

- [API Reference](../api/API_REFERENCE.md)
- [Operational Runbooks](../operations/RUNBOOKS.md)
- [Developer Guides](../development/)
- [Quick Reference](../QUICK_REFERENCE.md)

---

**Last Updated:** 2025-12-02
**Version:** 2.5.0
**Status:** Production-Ready
