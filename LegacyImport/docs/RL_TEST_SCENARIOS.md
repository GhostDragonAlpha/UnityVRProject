# RL Test Scenarios for SpaceTime VR Automated Playtesting

**Version:** 1.0
**Last Updated:** 2025-12-09
**Status:** Design Complete - Ready for Implementation
**Purpose:** Define reinforcement learning agent test scenarios for automated VR playtesting

---

## Executive Summary

This document defines 10+ specific reinforcement learning test scenarios for automated playtesting of the SpaceTime VR project. Each scenario specifies observations, actions, reward functions, success criteria, and integration points with existing systems.

**Target Use Cases:**
- Automated VR locomotion validation
- Physics accuracy testing
- VR comfort monitoring (motion sickness prevention)
- Performance stress testing (90 FPS maintenance)
- Edge case discovery (physics exploits, VR bugs)

**Integration Points:**
- HTTP API (port 8080) for scene loading and control
- Telemetry WebSocket (port 8081) for real-time metrics
- VoxelPerformanceMonitor for terrain performance data
- VRComfortSystem for motion sickness metrics
- PhysicsEngine for N-body gravity validation

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Scenario 1: VR Flight Navigation (Obstacle Course)](#scenario-1-vr-flight-navigation-obstacle-course)
3. [Scenario 2: Voxel Terrain Exploration (Coverage Testing)](#scenario-2-voxel-terrain-exploration-coverage-testing)
4. [Scenario 3: Spacecraft Landing (Physics Accuracy)](#scenario-3-spacecraft-landing-physics-accuracy)
5. [Scenario 4: VR Comfort Validation (Motion Sickness Prevention)](#scenario-4-vr-comfort-validation-motion-sickness-prevention)
6. [Scenario 5: Performance Stress Test (90 FPS Maintenance)](#scenario-5-performance-stress-test-90-fps-maintenance)
7. [Scenario 6: UI Interaction Testing (Cockpit Buttons)](#scenario-6-ui-interaction-testing-cockpit-buttons)
8. [Scenario 7: Collision Detection (Asteroids, Planets)](#scenario-7-collision-detection-asteroids-planets)
9. [Scenario 8: Floating Origin Validation (10km+ Travel)](#scenario-8-floating-origin-validation-10km-travel)
10. [Scenario 9: Multi-Scene Testing (Scene Transitions)](#scenario-9-multi-scene-testing-scene-transitions)
11. [Scenario 10: Edge Case Discovery (Physics Exploits)](#scenario-10-edge-case-discovery-physics-exploits)
12. [Bonus Scenarios](#bonus-scenarios)
13. [Implementation Guide](#implementation-guide)
14. [Hardware Requirements](#hardware-requirements)

---

## Architecture Overview

### RL Agent Integration Points

```
┌─────────────────────────────────────────────────────────────┐
│                    RL Agent (Python)                         │
│  - Observation Processing (WebSocket/HTTP)                   │
│  - Action Selection (Policy Network)                         │
│  - Reward Calculation (Multi-metric)                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              SpaceTime VR Runtime (Godot)                    │
│                                                               │
│  HTTP API (8080)        WebSocket (8081)      Autoloads     │
│  ┌──────────────┐      ┌──────────────┐    ┌──────────────┐│
│  │ Scene Load   │      │ Telemetry    │    │VoxelPerfMon  ││
│  │ State Query  │      │ Frame Times  │    │VRComfort     ││
│  │ Controller   │      │ Physics Data │    │PhysicsEngine ││
│  │ Input        │      │ VR Metrics   │    │FloatingOrigin││
│  └──────────────┘      └──────────────┘    └──────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Observations (Godot → RL Agent):**
- VR HMD position/rotation (XRCamera3D global_transform)
- Controller positions/rotations (XRController3D transforms)
- Frame time metrics (VoxelPerformanceMonitor)
- Physics state (PhysicsEngine gravity, velocities)
- Scene graph state (via HTTP API `/state/scene`)
- Vignetting intensity (VRComfortSystem)
- Acceleration data (VRComfortSystem)

**Actions (RL Agent → Godot):**
- Controller thumbstick input (Vector2)
- Controller button presses (trigger, grip, buttons A/B/X/Y)
- Scene transitions (via HTTP API `/scene`)
- Configuration changes (via HTTP API)

**Rewards (Calculated by RL Agent):**
- Multi-objective optimization (navigation, comfort, performance)
- Sparse rewards (goal completion, checkpoints)
- Dense rewards (distance to target, smooth motion)
- Penalty signals (collisions, frame drops, excessive vignetting)

---

## Scenario 1: VR Flight Navigation (Obstacle Course)

### Goal/Objective
Train an RL agent to navigate a 3D obstacle course in zero-G using VR flight controls while maintaining 90 FPS and minimizing motion sickness.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_flight_obstacle_course.tscn`

**Course Components:**
- 50 checkpoint rings (CollisionShape3D spheres, 5m diameter)
- Asteroid field (20 static obstacles, 2-10m diameter)
- Start platform (XROrigin3D spawn point)
- Goal platform (Area3D with completion trigger)
- Distance: 500m total course length

### Observations (State Space)

**VR Pose Data (13 values):**
```python
observation_space = {
    # HMD Transform
    'hmd_position': gym.spaces.Box(-1000, 1000, shape=(3,)),  # x, y, z
    'hmd_rotation': gym.spaces.Box(-np.pi, np.pi, shape=(3,)),  # euler angles

    # Velocity
    'velocity': gym.spaces.Box(-50, 50, shape=(3,)),  # m/s

    # Navigation
    'distance_to_checkpoint': gym.spaces.Box(0, 1000, shape=(1,)),  # meters
    'direction_to_checkpoint': gym.spaces.Box(-1, 1, shape=(3,)),  # normalized vector

    # Comfort Metrics
    'vignette_intensity': gym.spaces.Box(0, 1, shape=(1,)),  # 0-1 range
    'acceleration_magnitude': gym.spaces.Box(0, 100, shape=(1,)),  # m/s²
}
```

**Data Source:**
- Query via HTTP: `GET http://localhost:8080/state/scene` (HMD transform, checkpoint positions)
- WebSocket telemetry: Frame times, acceleration
- VRComfortSystem autoload: Vignetting intensity

### Actions (Action Space)

**Continuous Control (5 DOF):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0, -1.0, 0.0]),
    high=np.array([1.0, 1.0, 1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0]: Left thumbstick X (strafe left/right)
# [1]: Left thumbstick Y (forward/backward)
# [2]: Right thumbstick X (yaw rotation)
# [3]: Right thumbstick Y (pitch rotation)
# [4]: Trigger (throttle 0-1)
```

**Action Injection:**
- Send controller input via HTTP API custom endpoint: `POST /input/controller`
- Payload: `{"left_stick": [x, y], "right_stick": [x, y], "trigger": value}`

### Reward Function

**Multi-objective reward with shaped components:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Progress Reward (sparse + shaped)
    checkpoint_reached = check_checkpoint_trigger()
    if checkpoint_reached:
        reward += 100.0  # Sparse reward

    # Distance-based shaping (dense)
    dist_delta = obs['distance_to_checkpoint'] - next_obs['distance_to_checkpoint']
    reward += dist_delta * 1.0  # Reward for getting closer

    # Comfort Penalty (VR sickness prevention)
    vignette_penalty = -next_obs['vignette_intensity'] * 5.0
    reward += vignette_penalty

    # Performance Penalty (frame drops)
    frame_time_ms = get_telemetry('render_frame_time_ms')
    if frame_time_ms > 11.11:  # 90 FPS budget exceeded
        reward += -10.0

    # Collision Penalty
    if collision_detected():
        reward += -50.0
        done = True

    # Action Smoothness (prevent jerky movements)
    action_delta = np.linalg.norm(action - previous_action)
    reward += -action_delta * 0.5

    # Goal Completion (episode success)
    if goal_reached():
        reward += 500.0
        done = True

    return reward, done
```

### Success Criteria

**Episode Success:** Agent completes full obstacle course (50 checkpoints + goal)

**Performance Metrics:**
- **Completion Rate:** ≥80% of episodes reach goal within 1000 timesteps
- **Average Reward:** ≥300 over 100 evaluation episodes
- **Frame Rate:** ≥90% of frames meet 11.11ms budget (90 FPS)
- **Comfort Score:** Vignette intensity <0.3 for ≥95% of episode
- **Collision Rate:** <10% of episodes result in collision

**Evaluation Protocol:**
- 100 test episodes with fixed random seed
- Record metrics: completion time, checkpoints reached, frame drops, vignetting events
- Compare to baseline (random policy, hand-coded policy)

### Integration Points

**Existing Systems Used:**
- **VRManager:** Controller input simulation, HMD tracking state
- **VRComfortSystem:** Vignetting intensity monitoring, acceleration tracking
- **VoxelPerformanceMonitor:** Frame time metrics (render + physics)
- **HTTP API:** Scene loading (`POST /scene`), state queries (`GET /state/scene`)
- **Telemetry WebSocket:** Real-time performance data (port 8081)

**New Components Required:**
- **RL Agent HTTP Endpoint:** `POST /input/controller` for injecting controller input
- **Checkpoint System:** Track checkpoint progression, emit events on trigger
- **Collision Detection:** Area3D overlaps for obstacle collisions
- **Test Scene:** Obstacle course with checkpoints and goal

### Expected Training Time

**Environment:** PPO algorithm (Stable-Baselines3)

**Training Phases:**
1. **Exploration Phase (10M steps):** Random actions, learn basic navigation
2. **Optimization Phase (20M steps):** Policy improvement, checkpoint discovery
3. **Fine-tuning Phase (10M steps):** Smooth trajectories, comfort optimization

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 20-30 hours
- 8-core CPU (no GPU): 60-80 hours
- Parallelized training (4 environments): 10-15 hours (GPU)

**Convergence Metrics:**
- Episode reward plateaus at ≥300
- Checkpoint completion rate ≥80%
- Policy entropy decreases (exploitation over exploration)

### Hardware Requirements

**Minimum:**
- CPU: Intel i5-10600K or AMD Ryzen 5 5600X (6 cores)
- GPU: NVIDIA GTX 1660 Ti (6GB VRAM) or equivalent
- RAM: 16GB system memory
- Storage: 50GB for training logs and checkpoints
- VR Headset: Not required (simulation mode sufficient)

**Recommended:**
- CPU: Intel i7-12700K or AMD Ryzen 7 5800X (8+ cores)
- GPU: NVIDIA RTX 3080 (10GB VRAM) or RTX 4070
- RAM: 32GB system memory
- Storage: 100GB NVMe SSD for fast checkpointing
- VR Headset: Meta Quest 3, Valve Index (for validation testing)

---

## Scenario 2: Voxel Terrain Exploration (Coverage Testing)

### Goal/Objective
Discover maximum terrain area while maintaining performance (90 FPS) and validating chunk generation/loading systems.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_voxel_exploration.tscn`

**Terrain Configuration:**
- **Generator:** VoxelTerrainGenerator (procedural noise-based)
- **Chunk Size:** 16x16x16 voxels
- **View Distance:** 256m (16 chunk radius)
- **Terrain Type:** Hills, valleys, caves (FastNoiseLite)
- **Test Area:** 1km x 1km exploration zone

### Observations (State Space)

**Terrain + Performance Data (18 values):**
```python
observation_space = {
    # Position
    'player_position': gym.spaces.Box(-1000, 1000, shape=(3,)),

    # Terrain Coverage
    'chunks_explored': gym.spaces.Box(0, 4096, shape=(1,)),  # Total unique chunks visited
    'current_biome': gym.spaces.Discrete(5),  # Plains, hills, mountains, caves, water

    # Performance Metrics (from VoxelPerformanceMonitor)
    'active_chunk_count': gym.spaces.Box(0, 512, shape=(1,)),
    'chunk_generation_time_ms': gym.spaces.Box(0, 50, shape=(1,)),
    'collision_generation_time_ms': gym.spaces.Box(0, 50, shape=(1,)),
    'voxel_memory_mb': gym.spaces.Box(0, 2048, shape=(1,)),
    'render_frame_time_ms': gym.spaces.Box(0, 50, shape=(1,)),
    'physics_frame_time_ms': gym.spaces.Box(0, 50, shape=(1,)),

    # Terrain Gradient (movement hints)
    'terrain_slope': gym.spaces.Box(0, 90, shape=(1,)),  # degrees
    'height_above_ground': gym.spaces.Box(0, 1000, shape=(1,)),  # meters
}
```

**Data Source:**
- VoxelPerformanceMonitor autoload: `get_statistics()` method
- HTTP API: `GET /state/scene` for player position
- Custom exploration tracker: Track visited chunk coordinates (3D grid hash set)

### Actions (Action Space)

**3D Movement Control (4 DOF):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0, 0.0]),
    high=np.array([1.0, 1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0]: Move X (strafe left/right)
# [1]: Move Y (vertical up/down)
# [2]: Move Z (forward/backward)
# [3]: Movement speed multiplier (0-1)
```

**Action Injection:**
- HTTP API: `POST /input/controller` (same as Scenario 1)
- Alternative: Direct XROrigin3D position updates via custom HTTP endpoint

### Reward Function

**Coverage-optimized reward with performance constraints:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Exploration Reward (primary objective)
    new_chunk_discovered = (next_obs['chunks_explored'] > obs['chunks_explored'])
    if new_chunk_discovered:
        reward += 10.0  # Sparse reward for new chunks

    # Diversity Bonus (biome exploration)
    if next_obs['current_biome'] != obs['current_biome']:
        reward += 5.0

    # Performance Penalties
    chunk_gen_time = next_obs['chunk_generation_time_ms']
    if chunk_gen_time > 5.0:  # MAX_CHUNK_GENERATION_MS threshold
        reward += -(chunk_gen_time - 5.0) * 2.0

    collision_gen_time = next_obs['collision_generation_time_ms']
    if collision_gen_time > 3.0:  # MAX_COLLISION_GENERATION_MS threshold
        reward += -(collision_gen_time - 3.0) * 2.0

    frame_time = next_obs['render_frame_time_ms']
    if frame_time > 11.11:  # 90 FPS budget
        reward += -5.0

    # Memory Management
    memory_usage = next_obs['voxel_memory_mb']
    if memory_usage > 2048:  # MAX_MEMORY_MB threshold
        reward += -20.0
        done = True  # Episode failure

    # Active Chunk Penalty (too many chunks loaded)
    if next_obs['active_chunk_count'] > 512:  # MAX_ACTIVE_CHUNKS
        reward += -10.0

    # Efficiency Bonus (maximize exploration per timestep)
    exploration_rate = new_chunk_discovered / (1.0 + action[3])  # Penalize high speed
    reward += exploration_rate * 2.0

    # Episode Completion (coverage target)
    if next_obs['chunks_explored'] >= 1024:  # 32x32 chunk grid explored
        reward += 200.0
        done = True

    return reward, done
```

### Success Criteria

**Episode Success:** Explore ≥1024 unique chunks within 5000 timesteps

**Performance Metrics:**
- **Coverage Rate:** ≥70% of target area explored (1024/1444 chunks for 1km²)
- **Average Reward:** ≥500 over 100 evaluation episodes
- **Frame Rate:** ≥95% of frames meet 11.11ms budget (stricter than Scenario 1)
- **Chunk Gen Time:** <5ms for 99% of chunk generations
- **Collision Gen Time:** <3ms for 99% of collision mesh generations
- **Memory Usage:** Peak usage <1500MB (below 2GB limit)

**Evaluation Protocol:**
- 100 test episodes with procedurally generated terrain (different seeds)
- Record: unique chunks explored, performance warnings, memory peaks
- Heatmap visualization of explored areas

### Integration Points

**Existing Systems Used:**
- **VoxelPerformanceMonitor:** All chunk generation and performance metrics
- **VoxelTerrainGenerator:** Procedural terrain generation
- **FloatingOriginSystem:** Coordinate rebasing for large-scale exploration (10km threshold)
- **HTTP API:** Scene loading, state queries
- **Telemetry WebSocket:** Real-time performance streaming

**New Components Required:**
- **Exploration Tracker:** 3D grid hash set to track visited chunks
- **Biome Classifier:** Detect terrain type (slope, height, voxel density)
- **Performance Logger:** Record all VoxelPerformanceMonitor warnings
- **Heatmap Generator:** Visualize explored areas (post-episode analysis)

### Expected Training Time

**Environment:** PPO or SAC (Soft Actor-Critic for exploration)

**Training Phases:**
1. **Random Exploration (5M steps):** Learn basic movement, discover coverage reward
2. **Greedy Exploration (15M steps):** Optimize for new chunk discovery
3. **Efficiency Tuning (10M steps):** Balance speed vs. performance constraints

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 15-25 hours
- 8-core CPU (no GPU): 40-60 hours
- Parallelized training (8 environments): 8-12 hours (GPU)

**Convergence Metrics:**
- Chunks explored plateaus at ≥1000
- Performance penalty rate <5% (rare frame drops)
- Exploration efficiency (chunks/timestep) ≥0.2

### Hardware Requirements

**Minimum:**
- CPU: Intel i5-12600K or AMD Ryzen 5 5600X (6 cores)
- GPU: NVIDIA RTX 3060 (8GB VRAM) for voxel rendering
- RAM: 16GB system memory
- Storage: 100GB for terrain cache and training logs
- VR Headset: Not required

**Recommended:**
- CPU: Intel i9-12900K or AMD Ryzen 9 5900X (12+ cores)
- GPU: NVIDIA RTX 4070 Ti (12GB VRAM) for high-resolution voxel rendering
- RAM: 32GB system memory
- Storage: 250GB NVMe SSD for fast chunk streaming
- VR Headset: Optional (for visual validation)

---

## Scenario 3: Spacecraft Landing (Physics Accuracy)

### Goal/Objective
Land spacecraft on planetary surface using realistic physics (N-body gravity, thrust vectoring) while minimizing fuel consumption and avoiding crashes.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_spacecraft_landing.tscn`

**Landing Environment:**
- **Planet:** Earth-like (radius 6371km, mass 5.972e24 kg)
- **Starting Altitude:** 100km (orbital velocity ~7.8 km/s)
- **Landing Pad:** 100m x 100m flat area (target zone)
- **Gravity:** PhysicsEngine N-body simulation (G = 6.674e-23 game units)
- **Atmosphere:** Simplified drag model (optional)

### Observations (State Space)

**Spacecraft Dynamics (22 values):**
```python
observation_space = {
    # Position (relative to planet center)
    'position': gym.spaces.Box(-1e7, 1e7, shape=(3,)),  # meters
    'altitude': gym.spaces.Box(0, 200000, shape=(1,)),  # meters above surface

    # Velocity
    'velocity': gym.spaces.Box(-10000, 10000, shape=(3,)),  # m/s
    'vertical_speed': gym.spaces.Box(-500, 500, shape=(1,)),  # m/s

    # Orientation (spacecraft attitude)
    'rotation': gym.spaces.Box(-np.pi, np.pi, shape=(3,)),  # euler angles
    'angular_velocity': gym.spaces.Box(-2*np.pi, 2*np.pi, shape=(3,)),  # rad/s

    # Landing Target
    'distance_to_pad': gym.spaces.Box(0, 200000, shape=(1,)),  # meters
    'bearing_to_pad': gym.spaces.Box(-np.pi, np.pi, shape=(1,)),  # radians

    # Physics State
    'gravity_acceleration': gym.spaces.Box(0, 100, shape=(3,)),  # m/s² (from PhysicsEngine)
    'atmospheric_drag': gym.spaces.Box(0, 50, shape=(3,)),  # N

    # Fuel
    'fuel_remaining': gym.spaces.Box(0, 100, shape=(1,)),  # percentage

    # Collision Risk
    'terrain_clearance': gym.spaces.Box(0, 10000, shape=(1,)),  # meters to nearest surface
}
```

**Data Source:**
- Spacecraft RigidBody3D: `global_position`, `linear_velocity`, `angular_velocity`
- PhysicsEngine autoload: `calculate_gravity()` method for N-body forces
- HTTP API: `GET /state/scene` for spacecraft state
- Custom landing pad Area3D: Distance and bearing calculations

### Actions (Action Space)

**6 DOF Thrust Control (6 values):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0, -1.0, -1.0, -1.0]),
    high=np.array([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0-2]: Thrust vector (X, Y, Z) in spacecraft local frame
# [3-5]: Torque vector (roll, pitch, yaw) for rotation
```

**Action Injection:**
- HTTP API: `POST /spacecraft/control` (custom endpoint)
- Payload: `{"thrust": [x, y, z], "torque": [roll, pitch, yaw]}`
- Maps to Spacecraft.gd `apply_thrust()` and `apply_torque()` methods

### Reward Function

**Physics-accurate landing reward with fuel efficiency:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Distance Shaping (dense reward)
    dist_delta = obs['distance_to_pad'] - next_obs['distance_to_pad']
    reward += dist_delta * 0.01  # Small reward for getting closer

    # Altitude Management (penalize crashing)
    if next_obs['altitude'] < 10 and next_obs['vertical_speed'] < -5:
        # Too fast vertical descent near ground
        reward += -100.0
        done = True

    # Fuel Efficiency (penalize excessive thrust)
    thrust_magnitude = np.linalg.norm(action[0:3])
    reward += -thrust_magnitude * 0.1

    # Orientation Penalty (should point upward for landing)
    # Spacecraft Z-axis should align with gravity vector
    gravity_dir = normalize(next_obs['gravity_acceleration'])
    spacecraft_up = get_spacecraft_up_vector(next_obs['rotation'])
    alignment = np.dot(spacecraft_up, -gravity_dir)  # -1 to 1
    reward += alignment * 2.0

    # Velocity Penalty (should be slow near landing)
    if next_obs['altitude'] < 1000:
        velocity_magnitude = np.linalg.norm(next_obs['velocity'])
        reward += -velocity_magnitude * 0.05

    # Successful Landing (sparse reward)
    if landed_successfully(next_obs):
        reward += 500.0
        # Bonus for precision landing (within 10m of center)
        if next_obs['distance_to_pad'] < 10:
            reward += 200.0
        # Bonus for fuel efficiency
        fuel_bonus = next_obs['fuel_remaining'] * 5.0
        reward += fuel_bonus
        done = True

    # Crash Penalty
    if crashed(next_obs):
        reward += -200.0
        done = True

    # Fuel Depletion
    if next_obs['fuel_remaining'] <= 0:
        reward += -150.0
        done = True

    return reward, done

def landed_successfully(obs):
    """Landing conditions: altitude < 1m, vertical speed < 2 m/s, on pad"""
    return (obs['altitude'] < 1.0 and
            abs(obs['vertical_speed']) < 2.0 and
            obs['distance_to_pad'] < 50.0)  # Within landing pad radius

def crashed(obs):
    """Crash conditions: high vertical speed or terrain collision"""
    return (obs['altitude'] < 1.0 and abs(obs['vertical_speed']) > 5.0) or \
           (obs['terrain_clearance'] < 0.1)
```

### Success Criteria

**Episode Success:** Land within 50m of pad center with vertical speed <2 m/s

**Performance Metrics:**
- **Landing Success Rate:** ≥75% of episodes land successfully
- **Average Reward:** ≥400 over 100 evaluation episodes
- **Fuel Efficiency:** Average fuel remaining ≥30% on successful landings
- **Precision:** ≥50% of landings within 10m of pad center
- **Physics Accuracy:** Gravity calculations match PhysicsEngine (validated with test suite)

**Evaluation Protocol:**
- 100 test episodes with varying initial conditions (altitude 50-150km, random orbital velocity)
- Record: landing success, fuel remaining, distance from pad, crash rate
- Compare to baseline: PID controller, optimal control (MPC)

### Integration Points

**Existing Systems Used:**
- **PhysicsEngine:** N-body gravity calculations (`calculate_gravity()`)
- **Spacecraft:** RigidBody3D with thrust/torque application
- **FloatingOriginSystem:** Coordinate rebasing for large distances (planet-scale)
- **TimeManager:** Time dilation for physics accuracy (if needed)
- **HTTP API:** Scene loading, spacecraft control endpoint

**New Components Required:**
- **Landing Pad Area3D:** Collision detection for successful landing
- **Fuel System:** Track fuel consumption based on thrust magnitude
- **Terrain Heightmap:** Raycast-based terrain clearance calculation
- **Spacecraft Control Endpoint:** `POST /spacecraft/control` for thrust/torque injection
- **Physics Validator:** Compare RL agent's observed gravity with PhysicsEngine ground truth

### Expected Training Time

**Environment:** TD3 (Twin Delayed DDPG) or SAC for continuous control

**Training Phases:**
1. **Hover Training (10M steps):** Learn to counteract gravity, maintain altitude
2. **Descent Training (20M steps):** Learn controlled descent from orbit
3. **Precision Landing (15M steps):** Optimize for pad center, fuel efficiency

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 25-40 hours
- 8-core CPU (no GPU): 70-100 hours
- Parallelized training (4 environments): 15-20 hours (GPU)

**Convergence Metrics:**
- Landing success rate ≥75%
- Average fuel remaining ≥30%
- Policy no longer improves (reward plateau)

### Hardware Requirements

**Minimum:**
- CPU: Intel i7-10700K or AMD Ryzen 7 3700X (8 cores)
- GPU: NVIDIA RTX 3060 Ti (8GB VRAM)
- RAM: 16GB system memory
- Storage: 100GB for training checkpoints and physics logs
- VR Headset: Not required

**Recommended:**
- CPU: Intel i9-13900K or AMD Ryzen 9 7900X (16+ cores)
- GPU: NVIDIA RTX 4080 (12GB VRAM)
- RAM: 64GB system memory (for large replay buffer)
- Storage: 500GB NVMe SSD for fast physics simulation replay
- VR Headset: Optional (for manual validation)

---

## Scenario 4: VR Comfort Validation (Motion Sickness Prevention)

### Goal/Objective
Quantitatively validate VR comfort systems (vignetting, snap-turns, acceleration limits) by measuring agent's ability to navigate while minimizing discomfort signals.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_comfort_validation.tscn`

**Environment:**
- **Motion Challenges:** Rapid acceleration, rotation, vertical movement
- **Test Course:** Figure-8 flight path with elevation changes (100m vertical span)
- **Duration:** 120 second episodes
- **Comfort Systems Active:** Vignetting, snap-turn, stationary mode (configurable)

### Observations (State Space)

**VR Comfort Metrics (16 values):**
```python
observation_space = {
    # Motion State
    'velocity': gym.spaces.Box(-50, 50, shape=(3,)),  # m/s
    'acceleration': gym.spaces.Box(-100, 100, shape=(3,)),  # m/s²
    'angular_velocity': gym.spaces.Box(-4*np.pi, 4*np.pi, shape=(3,)),  # rad/s

    # Comfort System State (from VRComfortSystem)
    'vignette_intensity': gym.spaces.Box(0, 1, shape=(1,)),  # Current vignetting
    'vignette_target': gym.spaces.Box(0, 1, shape=(1,)),  # Target vignetting
    'snap_turn_cooldown': gym.spaces.Box(0, 1, shape=(1,)),  # 0-1 (cooldown timer)
    'stationary_mode_active': gym.spaces.Discrete(2),  # Boolean

    # Acceleration-Based Comfort Metrics
    'linear_acceleration_magnitude': gym.spaces.Box(0, 100, shape=(1,)),  # m/s²
    'jerk': gym.spaces.Box(0, 500, shape=(1,)),  # m/s³ (rate of acceleration change)

    # Navigation Progress
    'waypoint_distance': gym.spaces.Box(0, 500, shape=(1,)),
    'course_progress': gym.spaces.Box(0, 1, shape=(1,)),  # 0-1 percentage
}
```

**Data Source:**
- VRComfortSystem autoload: `_current_vignette_intensity`, `_current_acceleration`
- XROrigin3D: Velocity, acceleration (computed from position deltas)
- Custom waypoint tracker: Course progress calculation
- HTTP API: `GET /state/scene` for motion state

### Actions (Action Space)

**Comfort-Aware Movement (5 DOF):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0, -1.0, 0.0]),
    high=np.array([1.0, 1.0, 1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0-2]: Movement vector (X, Y, Z)
# [3]: Rotation (snap-turn trigger: -1 = left 45°, 1 = right 45°)
# [4]: Acceleration limiter (0 = smooth, 1 = aggressive)
```

**Action Injection:**
- HTTP API: `POST /input/controller` for movement
- VRComfortSystem: Monitor action effects on vignetting

### Reward Function

**Comfort-optimized reward (multi-objective):**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Navigation Progress (primary objective)
    progress_delta = next_obs['course_progress'] - obs['course_progress']
    reward += progress_delta * 100.0  # High weight for course completion

    # Vignetting Penalty (minimize discomfort)
    vignette_penalty = -next_obs['vignette_intensity'] * 10.0
    reward += vignette_penalty

    # Acceleration Penalty (VR comfort thresholds)
    accel = next_obs['linear_acceleration_magnitude']
    if accel > VIGNETTE_ACCEL_THRESHOLD:  # 5.0 m/s² (from VRComfortSystem)
        reward += -(accel - VIGNETTE_ACCEL_THRESHOLD) * 2.0

    # Jerk Penalty (smooth motion preferred)
    jerk = next_obs['jerk']
    reward += -jerk * 0.1

    # Snap-Turn Usage (preferred over smooth rotation)
    if action[3] > 0.8 or action[3] < -0.8:  # Snap-turn triggered
        # Small bonus for using comfort feature
        reward += 1.0

    # Stationary Mode Bonus (if enabled during high acceleration)
    if next_obs['stationary_mode_active'] and accel > 10.0:
        reward += 5.0  # Reward for using stationary mode appropriately

    # Course Completion Bonus
    if next_obs['course_progress'] >= 1.0:
        reward += 200.0
        # Comfort bonus (low average vignetting)
        avg_vignette = episode_avg_vignette()  # Track over episode
        if avg_vignette < 0.2:
            reward += 100.0  # "Comfortable completion" bonus
        done = True

    # Time Penalty (encourage efficient navigation)
    reward += -0.1  # Small penalty per timestep

    return reward, done
```

### Success Criteria

**Episode Success:** Complete figure-8 course with average vignetting <0.3

**Performance Metrics:**
- **Completion Rate:** ≥90% of episodes complete course
- **Average Vignetting:** <0.25 over full episode
- **Peak Vignetting:** <0.7 (below max intensity threshold)
- **Acceleration Spikes:** <5% of frames exceed 20 m/s²
- **Jerk Events:** <2% of frames exceed 100 m/s³
- **Snap-Turn Usage:** ≥60% of rotations use snap-turn (vs. smooth rotation)

**Evaluation Protocol:**
- 100 test episodes with all comfort systems enabled
- A/B testing: Compare comfort metrics with systems disabled
- Human validation: 5 test subjects rate comfort (1-10 scale) after watching replay
- Correlation analysis: RL-predicted comfort vs. human comfort ratings

### Integration Points

**Existing Systems Used:**
- **VRComfortSystem:** Vignetting intensity, snap-turn, stationary mode
- **VRManager:** Controller input handling
- **HTTP API:** Scene loading, state queries
- **Telemetry WebSocket:** Real-time vignetting streaming

**New Components Required:**
- **Jerk Calculator:** Track acceleration derivative (d³x/dt³)
- **Waypoint System:** Define figure-8 course with elevation changes
- **Comfort Metrics Logger:** Record vignetting, acceleration, jerk over episode
- **Human Rating Interface:** Post-episode comfort survey (for validation)

### Expected Training Time

**Environment:** PPO with custom comfort-aware value function

**Training Phases:**
1. **Baseline Navigation (5M steps):** Learn to complete course (ignore comfort)
2. **Comfort Optimization (15M steps):** Minimize vignetting while maintaining progress
3. **Human Validation (5M steps):** Fine-tune based on human comfort ratings

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 12-20 hours
- 8-core CPU (no GPU): 30-50 hours
- Parallelized training (4 environments): 8-12 hours (GPU)

**Convergence Metrics:**
- Average vignetting <0.25
- Course completion rate ≥90%
- Human comfort rating ≥7/10 (correlates with RL metrics)

### Hardware Requirements

**Minimum:**
- CPU: Intel i5-12600K or AMD Ryzen 5 5600X (6 cores)
- GPU: NVIDIA RTX 3060 (8GB VRAM)
- RAM: 16GB system memory
- Storage: 50GB for training logs
- VR Headset: Meta Quest 2 (for human validation)

**Recommended:**
- CPU: Intel i7-13700K or AMD Ryzen 7 7700X (8 cores)
- GPU: NVIDIA RTX 4070 (12GB VRAM)
- RAM: 32GB system memory
- Storage: 100GB NVMe SSD
- VR Headset: Meta Quest 3, Valve Index (for high-quality validation)

---

## Scenario 5: Performance Stress Test (90 FPS Maintenance)

### Goal/Objective
Maximize game complexity (entities, voxel chunks, physics bodies) while maintaining 90 FPS (11.11ms frame budget) by discovering performance bottlenecks.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_performance_stress.tscn`

**Stress Test Environment:**
- **Base Load:** VR scene with voxel terrain (512 chunks)
- **Dynamic Entities:** RL agent spawns objects to increase load
- **Physics Bodies:** Up to 100 RigidBody3D objects
- **Particle Systems:** 10 particle emitters (configurable intensity)
- **Lighting:** 20 OmniLight3D sources (dynamic shadows)

### Observations (State Space)

**Performance Profiling (25 values):**
```python
observation_space = {
    # Frame Timing (from VoxelPerformanceMonitor)
    'render_frame_time_ms': gym.spaces.Box(0, 100, shape=(1,)),
    'physics_frame_time_ms': gym.spaces.Box(0, 100, shape=(1,)),
    'avg_frame_time_ms': gym.spaces.Box(0, 100, shape=(1,)),  # Rolling average (90 frames)
    'frame_time_variance': gym.spaces.Box(0, 50, shape=(1,)),  # Std deviation

    # Voxel System (from VoxelPerformanceMonitor)
    'active_chunk_count': gym.spaces.Box(0, 1024, shape=(1,)),
    'chunk_generation_time_ms': gym.spaces.Box(0, 100, shape=(1,)),
    'collision_generation_time_ms': gym.spaces.Box(0, 100, shape=(1,)),
    'voxel_memory_mb': gym.spaces.Box(0, 4096, shape=(1,)),

    # Physics Load
    'rigidbody_count': gym.spaces.Box(0, 500, shape=(1,)),
    'collision_pairs': gym.spaces.Box(0, 10000, shape=(1,)),
    'physics_step_time_ms': gym.spaces.Box(0, 50, shape=(1,)),

    # Rendering Load
    'draw_calls': gym.spaces.Box(0, 10000, shape=(1,)),
    'vertices_drawn': gym.spaces.Box(0, 10000000, shape=(1,)),
    'shadow_updates': gym.spaces.Box(0, 100, shape=(1,)),
    'particles_active': gym.spaces.Box(0, 100000, shape=(1,)),

    # Resource Usage
    'gpu_memory_mb': gym.spaces.Box(0, 16384, shape=(1,)),
    'cpu_usage_percent': gym.spaces.Box(0, 100, shape=(1,)),

    # Warning Flags (from VoxelPerformanceMonitor)
    'performance_warnings_count': gym.spaces.Box(0, 1000, shape=(1,)),
}
```

**Data Source:**
- VoxelPerformanceMonitor: All frame timing and voxel metrics
- Performance.get_monitor(): Draw calls, vertices, memory
- Custom profiler: Track entity spawns and physics load
- Telemetry WebSocket: Real-time performance streaming

### Actions (Action Space)

**Load Control (7 discrete actions):**
```python
action_space = gym.spaces.MultiDiscrete([3, 3, 3, 3, 3, 3, 3])

# Action mapping (each action 0-2: decrease/maintain/increase):
# [0]: Spawn/despawn RigidBody3D objects
# [1]: Adjust particle emitter intensity
# [2]: Toggle dynamic lights (on/off/shadow quality)
# [3]: Change voxel view distance (LOD)
# [4]: Spawn/despawn static meshes (MeshInstance3D)
# [5]: Adjust shadow quality (0-3)
# [6]: Toggle post-processing effects (glow, SSAO)
```

**Action Injection:**
- HTTP API: Custom endpoint `POST /stress_test/control`
- Payload: `{"action": [0, 1, 2, 0, 1, 2, 0]}` (discrete values)
- Scene script applies changes (spawn entities, adjust settings)

### Reward Function

**Performance optimization with complexity maximization:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Frame Time Objective (PRIMARY CONSTRAINT)
    avg_frame_time = next_obs['avg_frame_time_ms']
    if avg_frame_time < 11.11:  # Meeting 90 FPS budget
        reward += 10.0
        # Bonus for headroom (smoother performance)
        headroom = 11.11 - avg_frame_time
        reward += headroom * 0.5
    else:
        # Penalty for exceeding budget (scales with severity)
        penalty = (avg_frame_time - 11.11) * 5.0
        reward += -penalty

    # Complexity Reward (maximize game content)
    complexity_score = (
        next_obs['rigidbody_count'] * 0.5 +
        next_obs['active_chunk_count'] * 0.1 +
        next_obs['particles_active'] / 1000.0 +
        next_obs['draw_calls'] / 100.0
    )
    reward += complexity_score

    # Frame Time Stability (penalize variance)
    variance = next_obs['frame_time_variance']
    if variance > 2.0:  # High frame time jitter
        reward += -variance * 2.0

    # Performance Warnings (critical issues)
    if next_obs['performance_warnings_count'] > obs['performance_warnings_count']:
        reward += -10.0  # New warning triggered

    # Resource Limits
    if next_obs['voxel_memory_mb'] > 2048:  # MAX_MEMORY_MB
        reward += -50.0
    if next_obs['gpu_memory_mb'] > 8192:  # GPU OOM risk
        reward += -100.0
        done = True

    # Episode Success (sustained high complexity)
    if episode_timesteps > 1000 and avg_frame_time < 11.11:
        reward += 200.0  # Bonus for long stable run

    return reward, done
```

### Success Criteria

**Episode Success:** Maintain 90 FPS for 1000 timesteps with ≥50% max complexity

**Performance Metrics:**
- **Frame Rate:** ≥95% of frames meet 11.11ms budget
- **Complexity Score:** ≥500 (balanced load across systems)
- **Frame Time Variance:** <2ms standard deviation
- **Warning Rate:** <1 warning per 100 frames
- **Memory Usage:** Peak <1800MB voxel memory, <6GB GPU memory

**Evaluation Protocol:**
- 100 test episodes with random initial loads
- Record: max complexity achieved, frame time distribution, bottleneck identification
- Compare to manual optimization (developer-tuned settings)
- Generate performance profiles: identify which actions correlate with frame drops

### Integration Points

**Existing Systems Used:**
- **VoxelPerformanceMonitor:** Frame timing, chunk generation metrics
- **PerformanceOptimizer:** Dynamic quality adjustment (compare RL vs. existing system)
- **RenderingSystem:** Shadow quality, post-processing toggles
- **HTTP API:** Scene loading, stress test control endpoint
- **Telemetry WebSocket:** Real-time performance monitoring

**New Components Required:**
- **Stress Test Controller:** Spawn/despawn entities based on RL actions
- **Profiler Integration:** Track draw calls, vertices, GPU memory
- **Complexity Scorer:** Calculate aggregate complexity metric
- **Bottleneck Analyzer:** Identify which action caused frame drops (post-episode)

### Expected Training Time

**Environment:** PPO with constrained optimization (stay under 11.11ms budget)

**Training Phases:**
1. **Exploration (10M steps):** Discover performance limits, trigger warnings
2. **Optimization (20M steps):** Learn which settings maximize complexity safely
3. **Stress Testing (10M steps):** Push boundaries, find edge cases

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 20-35 hours
- 8-core CPU (no GPU): 60-90 hours
- Parallelized training (4 environments): 12-18 hours (GPU)

**Convergence Metrics:**
- Complexity score ≥500
- Frame time variance <2ms
- Policy learns to avoid performance warnings

### Hardware Requirements

**Minimum:**
- CPU: Intel i7-12700K or AMD Ryzen 7 5800X (8 cores)
- GPU: NVIDIA RTX 3070 (8GB VRAM)
- RAM: 16GB system memory
- Storage: 100GB for profiling logs
- VR Headset: Not required

**Recommended:**
- CPU: Intel i9-13900K or AMD Ryzen 9 7950X (16+ cores)
- GPU: NVIDIA RTX 4090 (24GB VRAM) for extreme stress testing
- RAM: 64GB system memory
- Storage: 500GB NVMe SSD
- VR Headset: Optional (for final validation)

---

## Scenario 6: UI Interaction Testing (Cockpit Buttons)

### Goal/Objective
Validate VR UI interaction by training agent to press cockpit buttons in correct sequence while handling input deadbands and haptic feedback.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_cockpit_interaction.tscn`

**Cockpit Environment:**
- **Spacecraft Cockpit:** 20 interactive buttons (Area3D + collision shapes)
- **Button Types:** Toggle, momentary, slider
- **Button Layout:** Realistic cockpit panel (2D grid, 5x4 layout)
- **Interaction:** Raycast from controller, trigger button to press
- **Haptic Feedback:** Vibration on successful press

### Observations (State Space)

**VR Controller + UI State (18 values):**
```python
observation_space = {
    # Right Controller Pose (primary hand for interaction)
    'controller_position': gym.spaces.Box(-10, 10, shape=(3,)),
    'controller_rotation': gym.spaces.Box(-np.pi, np.pi, shape=(3,)),
    'controller_velocity': gym.spaces.Box(-50, 50, shape=(3,)),

    # Raycast Information
    'raycast_hit': gym.spaces.Discrete(2),  # Boolean (hitting UI element)
    'raycast_distance': gym.spaces.Box(0, 10, shape=(1,)),
    'raycast_target_id': gym.spaces.Discrete(21),  # 0 = no hit, 1-20 = button IDs

    # Button States (from cockpit system)
    'button_states': gym.spaces.MultiBinary(20),  # Each button on/off
    'target_button_id': gym.spaces.Discrete(20),  # Next button to press in sequence

    # Task Progress
    'sequence_progress': gym.spaces.Box(0, 1, shape=(1,)),  # 0-1 percentage
    'errors_made': gym.spaces.Box(0, 100, shape=(1,)),  # Wrong button presses
}
```

**Data Source:**
- XRController3D (right hand): Global transform, velocity
- RayCast3D: Collision detection with button Area3D nodes
- Cockpit controller script: Button states, sequence progress
- HTTP API: `GET /state/scene` for UI state

### Actions (Action Space)

**Controller Movement + Trigger (7 values):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 0.0]),
    high=np.array([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0-2]: Controller position delta (X, Y, Z) - relative movement
# [3-5]: Controller rotation delta (euler angles)
# [6]: Trigger press (0-1, threshold 0.8 for button activation)
```

**Action Injection:**
- HTTP API: `POST /input/controller` for controller pose updates
- VRManager: Simulate trigger button press
- Cockpit script: Detect trigger press when raycast hits button

### Reward Function

**Sequence completion with precision:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Correct Button Press (sparse reward)
    if button_pressed_correctly(next_obs):
        reward += 50.0
        # Progress bonus
        reward += next_obs['sequence_progress'] * 100.0

    # Wrong Button Penalty
    if button_pressed_incorrectly(next_obs):
        reward += -20.0

    # Raycast Aiming (dense shaping)
    if next_obs['raycast_hit']:
        if next_obs['raycast_target_id'] == next_obs['target_button_id']:
            # Aiming at correct target
            reward += 1.0
        else:
            # Aiming at wrong target
            reward += -0.5

    # Distance to Target Button (3D Euclidean)
    target_position = get_button_position(next_obs['target_button_id'])
    controller_position = next_obs['controller_position']
    distance = np.linalg.norm(target_position - controller_position)
    reward += -distance * 0.1  # Penalize being far from target

    # Movement Efficiency (penalize excessive motion)
    movement_magnitude = np.linalg.norm(action[0:3])
    reward += -movement_magnitude * 0.05

    # Sequence Completion (episode success)
    if next_obs['sequence_progress'] >= 1.0:
        reward += 500.0
        # Speed bonus (fewer timesteps)
        time_bonus = max(0, 1000 - episode_timesteps)
        reward += time_bonus * 0.5
        done = True

    # Error Limit (episode failure)
    if next_obs['errors_made'] > 5:
        reward += -100.0
        done = True

    return reward, done

def button_pressed_correctly(obs):
    """Check if trigger pressed on correct button"""
    return (action[6] > 0.8 and
            obs['raycast_hit'] and
            obs['raycast_target_id'] == obs['target_button_id'])
```

### Success Criteria

**Episode Success:** Complete 10-button sequence with ≤2 errors

**Performance Metrics:**
- **Completion Rate:** ≥85% of episodes complete sequence
- **Average Reward:** ≥600 over 100 evaluation episodes
- **Error Rate:** Average <1.5 errors per episode
- **Completion Time:** <500 timesteps (efficient interaction)
- **Precision:** ≥95% of button presses hit target area (not edge)

**Evaluation Protocol:**
- 100 test episodes with randomized button sequences
- Record: completion time, errors, raycast accuracy
- Compare to human performance (5 test subjects)
- Generalization test: New button layouts not seen during training

### Integration Points

**Existing Systems Used:**
- **VRManager:** Controller tracking, trigger button state
- **HapticManager:** Vibration feedback on button press
- **HTTP API:** Scene loading, controller input injection
- **UI System:** Button interaction detection (Area3D collision)

**New Components Required:**
- **Cockpit Controller:** Button sequence generator, state tracking
- **Raycast System:** Visual raycast from controller to UI elements
- **Button Interaction Handler:** Detect trigger press + raycast collision
- **Sequence Generator:** Randomize button press sequences for training variety

### Expected Training Time

**Environment:** SAC (Soft Actor-Critic) for precise continuous control

**Training Phases:**
1. **Reach Training (5M steps):** Learn to move controller to target positions
2. **Press Training (10M steps):** Learn trigger timing + raycast alignment
3. **Sequence Training (10M steps):** Optimize for speed and accuracy

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 15-25 hours
- 8-core CPU (no GPU): 40-60 hours
- Parallelized training (4 environments): 10-15 hours (GPU)

**Convergence Metrics:**
- Completion rate ≥85%
- Error rate <1.5 per episode
- Average completion time <500 timesteps

### Hardware Requirements

**Minimum:**
- CPU: Intel i5-12600K or AMD Ryzen 5 5600X (6 cores)
- GPU: NVIDIA RTX 3060 (8GB VRAM)
- RAM: 16GB system memory
- Storage: 50GB for training logs
- VR Headset: Optional (simulation mode sufficient)

**Recommended:**
- CPU: Intel i7-13700K or AMD Ryzen 7 7700X (8 cores)
- GPU: NVIDIA RTX 4070 (12GB VRAM)
- RAM: 32GB system memory
- Storage: 100GB NVMe SSD
- VR Headset: Meta Quest 3 (for human baseline comparison)

---

## Scenario 7: Collision Detection (Asteroids, Planets)

### Goal/Objective
Stress test collision detection by navigating dense asteroid fields while validating physics accuracy (impulse transfer, rotation).

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_collision_stress.tscn`

**Asteroid Field:**
- **Asteroid Count:** 200 RigidBody3D asteroids
- **Size Range:** 1m - 20m diameter (random)
- **Density:** 10 asteroids per 100m³ volume
- **Physics:** Full rigid body dynamics (rotation, impulse)
- **Course:** Navigate 500m through field without collision

### Observations (State Space)

**Collision Avoidance (20 values):**
```python
observation_space = {
    # Spacecraft State
    'position': gym.spaces.Box(-1000, 1000, shape=(3,)),
    'velocity': gym.spaces.Box(-100, 100, shape=(3,)),
    'rotation': gym.spaces.Box(-np.pi, np.pi, shape=(3,)),

    # Nearest Obstacles (top 5 asteroids by distance)
    'obstacle_positions': gym.spaces.Box(-1000, 1000, shape=(5, 3)),  # 5 asteroids x XYZ
    'obstacle_velocities': gym.spaces.Box(-50, 50, shape=(5, 3)),
    'obstacle_sizes': gym.spaces.Box(0, 20, shape=(5,)),  # radii in meters

    # Collision Risk
    'time_to_collision': gym.spaces.Box(0, 100, shape=(1,)),  # seconds (999 if safe)
    'collision_normal': gym.spaces.Box(-1, 1, shape=(3,)),  # Predicted impact direction

    # Goal
    'distance_to_goal': gym.spaces.Box(0, 1000, shape=(1,)),
    'bearing_to_goal': gym.spaces.Box(-np.pi, np.pi, shape=(2,)),  # azimuth, elevation
}
```

**Data Source:**
- Spacecraft RigidBody3D: Position, velocity, rotation
- PhysicsEngine: Query nearby asteroids (spatial partitioning)
- Custom collision predictor: Raycast-based time-to-collision calculation
- HTTP API: `GET /state/scene` for all RigidBody3D states

### Actions (Action Space)

**Evasive Maneuvers (6 DOF):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0, -1.0, -1.0, -1.0]),
    high=np.array([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0-2]: Thrust vector (X, Y, Z) for translational dodging
# [3-5]: Torque vector (roll, pitch, yaw) for rotation
```

**Action Injection:**
- HTTP API: `POST /spacecraft/control` (same as Scenario 3)

### Reward Function

**Collision avoidance with navigation:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Collision Penalty (episode failure)
    if collision_occurred():
        reward += -500.0
        done = True
        return reward, done

    # Near-Miss Penalty (risky behavior)
    if next_obs['time_to_collision'] < 2.0:
        reward += -(10.0 / next_obs['time_to_collision'])  # Inverse distance penalty

    # Navigation Progress (dense reward)
    dist_delta = obs['distance_to_goal'] - next_obs['distance_to_goal']
    reward += dist_delta * 1.0

    # Safety Bonus (maintaining safe distance)
    min_obstacle_distance = np.min(np.linalg.norm(next_obs['obstacle_positions'], axis=1))
    if min_obstacle_distance > 10.0:  # Safe buffer zone
        reward += 1.0

    # Action Efficiency (minimize thrust usage)
    thrust_magnitude = np.linalg.norm(action[0:3])
    reward += -thrust_magnitude * 0.1

    # Goal Completion (episode success)
    if next_obs['distance_to_goal'] < 10.0:
        reward += 1000.0
        # Speed bonus (faster navigation)
        time_bonus = max(0, 2000 - episode_timesteps)
        reward += time_bonus * 0.2
        done = True

    return reward, done

def collision_occurred():
    """Check if spacecraft collided with asteroid"""
    # Listen to Godot body_entered signal on spacecraft
    return spacecraft.collision_flag  # Set by signal handler
```

### Success Criteria

**Episode Success:** Navigate through asteroid field without collision

**Performance Metrics:**
- **Completion Rate:** ≥70% of episodes reach goal without collision
- **Average Reward:** ≥500 over 100 evaluation episodes
- **Collision Rate:** <30% of episodes result in collision
- **Near-Miss Rate:** <10% of timesteps have time-to-collision <1 second
- **Navigation Efficiency:** Average completion time <1000 timesteps

**Evaluation Protocol:**
- 100 test episodes with randomized asteroid positions (fixed seed pool)
- Record: collisions, near-misses, time-to-collision distribution
- Physics validation: Compare impulse transfer on collision with analytical model

### Integration Points

**Existing Systems Used:**
- **PhysicsEngine:** RigidBody3D dynamics, collision detection
- **Spacecraft:** Thrust and torque application
- **HTTP API:** Scene loading, spacecraft control
- **Spatial Partitioning:** Query nearby asteroids efficiently

**New Components Required:**
- **Asteroid Spawner:** Procedurally generate asteroid field
- **Collision Predictor:** Calculate time-to-collision (raycast + velocity prediction)
- **Collision Logger:** Record impact impulse, rotation changes (for physics validation)
- **Obstacle Tracker:** Track 5 nearest asteroids, update observation space

### Expected Training Time

**Environment:** TD3 or SAC for collision avoidance

**Training Phases:**
1. **Reactive Avoidance (10M steps):** Learn to dodge immediate threats
2. **Predictive Avoidance (15M steps):** Plan ahead using time-to-collision
3. **Navigation Optimization (10M steps):** Balance avoidance with goal progress

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 20-35 hours
- 8-core CPU (no GPU): 60-90 hours
- Parallelized training (8 environments): 10-15 hours (GPU)

**Convergence Metrics:**
- Completion rate ≥70%
- Collision rate <30%
- Policy learns predictive avoidance (time-to-collision awareness)

### Hardware Requirements

**Minimum:**
- CPU: Intel i7-10700K or AMD Ryzen 7 3700X (8 cores)
- GPU: NVIDIA RTX 3060 Ti (8GB VRAM)
- RAM: 16GB system memory
- Storage: 100GB for collision logs and checkpoints
- VR Headset: Not required

**Recommended:**
- CPU: Intel i9-13900K or AMD Ryzen 9 7900X (12+ cores)
- GPU: NVIDIA RTX 4080 (12GB VRAM)
- RAM: 32GB system memory
- Storage: 250GB NVMe SSD for fast physics replay
- VR Headset: Optional (for manual validation)

---

## Scenario 8: Floating Origin Validation (10km+ Travel)

### Goal/Objective
Validate FloatingOriginSystem by traveling >10km and detecting coordinate rebasing errors, precision loss, or floating-point artifacts.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_floating_origin_test.tscn`

**Large-Scale Environment:**
- **Travel Distance:** 50km linear path
- **Checkpoints:** 10 waypoints (5km spacing)
- **Floating Origin Threshold:** 10km (triggers rebase)
- **Precision Targets:** Small objects (0.1m size) at each waypoint
- **Goal:** Reach all waypoints without precision loss

### Observations (State Space)

**Floating Origin Metrics (16 values):**
```python
observation_space = {
    # Position (local coordinates)
    'local_position': gym.spaces.Box(-10000, 10000, shape=(3,)),

    # Position (global coordinates via FloatingOriginSystem)
    'global_offset': gym.spaces.Box(-1e9, 1e9, shape=(3,)),  # Universe offset
    'absolute_position': gym.spaces.Box(-1e9, 1e9, shape=(3,)),  # local + offset

    # Rebase Tracking
    'rebase_count': gym.spaces.Box(0, 100, shape=(1,)),
    'distance_from_origin': gym.spaces.Box(0, 10000, shape=(1,)),

    # Precision Metrics
    'position_precision_bits': gym.spaces.Box(0, 64, shape=(1,)),  # Effective precision
    'target_distance': gym.spaces.Box(0, 100, shape=(1,)),  # Distance to small target

    # Navigation
    'waypoint_id': gym.spaces.Discrete(11),  # 0-9 waypoints + goal
    'distance_to_waypoint': gym.spaces.Box(0, 10000, shape=(1,)),
}
```

**Data Source:**
- FloatingOriginSystem autoload: `_universe_offset`, registered objects
- XROrigin3D: Local position (post-rebase)
- Custom precision tracker: Calculate floating-point precision loss
- HTTP API: `GET /state/scene` for position state

### Actions (Action Space)

**Long-Distance Travel (3 DOF):**
```python
action_space = gym.spaces.Box(
    low=np.array([-1.0, -1.0, -1.0]),
    high=np.array([1.0, 1.0, 1.0]),
    dtype=np.float32
)

# Action mapping:
# [0-2]: Movement direction (X, Y, Z) - high speed travel
```

**Action Injection:**
- HTTP API: `POST /input/controller` for movement
- Speed multiplier: 50 m/s for fast traversal

### Reward Function

**Precision-focused reward:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Waypoint Reached (sparse reward)
    if waypoint_reached():
        reward += 100.0
        # Precision bonus (hit small target)
        if target_hit_precision(next_obs):
            reward += 50.0  # Successfully hit 0.1m target
        else:
            # Precision failure (floating-point error detected)
            reward += -30.0

    # Progress Reward (dense)
    dist_delta = obs['distance_to_waypoint'] - next_obs['distance_to_waypoint']
    reward += dist_delta * 0.1

    # Rebase Detection (monitor FloatingOriginSystem)
    if next_obs['rebase_count'] > obs['rebase_count']:
        # Rebase occurred (expected every 10km)
        reward += 5.0  # Small bonus for triggering system
        # Validate rebase correctness
        if rebase_error_detected(next_obs):
            reward += -100.0  # Critical error: position jumped incorrectly
            done = True

    # Precision Loss Penalty
    if next_obs['position_precision_bits'] < 24:  # IEEE float32 = 24 bits mantissa
        # Floating-point precision degraded
        reward += -10.0

    # Goal Completion (all waypoints + final goal)
    if next_obs['waypoint_id'] == 10:
        reward += 500.0
        done = True

    return reward, done

def target_hit_precision(obs):
    """Check if agent can hit 0.1m target (precision test)"""
    return obs['target_distance'] < 0.1

def rebase_error_detected(obs):
    """Detect coordinate discontinuity after rebase"""
    # Check if absolute position is consistent with expected trajectory
    expected_position = calculate_expected_position()
    actual_position = obs['absolute_position']
    error = np.linalg.norm(expected_position - actual_position)
    return error > 1.0  # >1m error indicates rebase bug
```

### Success Criteria

**Episode Success:** Reach all 10 waypoints + goal with <10cm precision

**Performance Metrics:**
- **Completion Rate:** ≥95% of episodes reach all waypoints
- **Precision Success:** ≥90% of waypoints hit with <10cm error
- **Rebase Correctness:** Zero rebase errors detected
- **Precision Bits:** Maintain ≥24 bits throughout episode
- **Absolute Position Tracking:** Max error <1m between expected and actual position

**Evaluation Protocol:**
- 100 test episodes with fixed waypoint positions
- Record: rebase count, precision errors, position discontinuities
- Physics validation: Compare FloatingOriginSystem behavior with analytical model
- Edge case testing: Rapid back-and-forth across 10km threshold

### Integration Points

**Existing Systems Used:**
- **FloatingOriginSystem:** Coordinate rebasing, universe offset tracking
- **AstronomicalCoordinateSystem:** Multi-scale coordinate handling (if needed for extreme distances)
- **HTTP API:** Scene loading, position queries
- **XROrigin3D:** Local position (subject to rebasing)

**New Components Required:**
- **Precision Tracker:** Calculate effective floating-point precision (mantissa bits)
- **Rebase Validator:** Detect position discontinuities after rebase
- **Waypoint System:** 10 checkpoints with small precision targets
- **Position Logger:** Record absolute position history for error analysis

### Expected Training Time

**Environment:** PPO for exploration

**Training Phases:**
1. **Navigation Training (5M steps):** Learn to reach distant waypoints
2. **Precision Training (10M steps):** Learn to hit small targets
3. **Stress Testing (5M steps):** Rapid traversals to trigger edge cases

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 10-18 hours
- 8-core CPU (no GPU): 30-50 hours
- Parallelized training (4 environments): 6-10 hours (GPU)

**Convergence Metrics:**
- Completion rate ≥95%
- Precision success ≥90%
- Zero rebase errors

### Hardware Requirements

**Minimum:**
- CPU: Intel i5-12600K or AMD Ryzen 5 5600X (6 cores)
- GPU: NVIDIA RTX 3060 (8GB VRAM)
- RAM: 16GB system memory
- Storage: 50GB for position logs
- VR Headset: Not required

**Recommended:**
- CPU: Intel i7-13700K or AMD Ryzen 7 7700X (8 cores)
- GPU: NVIDIA RTX 4070 (12GB VRAM)
- RAM: 32GB system memory
- Storage: 100GB NVMe SSD
- VR Headset: Optional

---

## Scenario 9: Multi-Scene Testing (Scene Transitions)

### Goal/Objective
Validate scene loading/unloading via HTTP API by transitioning between scenes while maintaining performance and detecting memory leaks.

### Test Scene
**Scene Rotation:**
- **Scene 1:** `res://vr_main.tscn` (VR main scene)
- **Scene 2:** `res://scenes/test_scenarios/rl_voxel_exploration.tscn` (voxel terrain)
- **Scene 3:** `res://scenes/test_scenarios/rl_cockpit_interaction.tscn` (UI test)
- **Scene 4:** `res://minimal_test.tscn` (minimal scene)

**Transition Requirements:**
- Load each scene via HTTP API `POST /scene`
- Perform simple task in each scene (reach waypoint, press button)
- Monitor memory usage across transitions
- Detect memory leaks (increasing baseline memory)

### Observations (State Space)

**Scene Transition Metrics (12 values):**
```python
observation_space = {
    # Scene State
    'current_scene_id': gym.spaces.Discrete(4),  # 0-3 for 4 scenes
    'scene_load_time_ms': gym.spaces.Box(0, 10000, shape=(1,)),
    'scene_ready': gym.spaces.Discrete(2),  # Boolean

    # Memory Tracking
    'memory_usage_mb': gym.spaces.Box(0, 16384, shape=(1,)),
    'memory_baseline_mb': gym.spaces.Box(0, 16384, shape=(1,)),  # Memory before transition
    'memory_delta_mb': gym.spaces.Box(-1000, 1000, shape=(1,)),  # Change after transition

    # Performance
    'frame_time_ms': gym.spaces.Box(0, 100, shape=(1,)),
    'fps': gym.spaces.Box(0, 200, shape=(1,)),

    # Task Progress (scene-specific)
    'task_complete': gym.spaces.Discrete(2),  # Boolean
    'transitions_completed': gym.spaces.Box(0, 1000, shape=(1,)),
}
```

**Data Source:**
- SceneLoadMonitor autoload: Scene load state, history
- HTTP API: `GET /scene/history` for transition tracking
- Performance.get_monitor(): Memory usage
- Custom task tracker: Scene-specific completion flags

### Actions (Action Space)

**Scene Control (2 discrete actions):**
```python
action_space = gym.spaces.MultiDiscrete([4, 2])

# Action mapping:
# [0]: Scene to load (0-3)
# [1]: Task action (0 = navigate, 1 = interact)
```

**Action Injection:**
- HTTP API: `POST /scene` with `{"scene_path": "res://scene.tscn"}`
- Task actions depend on scene (use existing scenario actions)

### Reward Function

**Transition reliability with memory leak detection:**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Successful Scene Load
    if scene_load_succeeded(next_obs):
        reward += 20.0
        # Fast load bonus
        if next_obs['scene_load_time_ms'] < 1000:
            reward += 10.0
    else:
        # Load failure
        reward += -50.0
        done = True

    # Task Completion in Scene
    if next_obs['task_complete']:
        reward += 30.0

    # Memory Leak Detection
    memory_delta = next_obs['memory_delta_mb']
    if memory_delta > 50:  # More than 50MB increase
        # Potential memory leak
        reward += -memory_delta * 0.5
    elif memory_delta < -10:  # Memory freed (good)
        reward += 5.0

    # Performance Maintenance
    if next_obs['frame_time_ms'] > 11.11:
        reward += -5.0  # Frame drop during transition

    # Transition Count Milestone
    if next_obs['transitions_completed'] >= 100:
        reward += 200.0  # Successfully completed 100 transitions
        done = True

    # Memory Leak Failure (critical)
    if next_obs['memory_usage_mb'] > 12000:  # >12GB memory usage
        reward += -500.0
        done = True

    return reward, done

def scene_load_succeeded(obs):
    """Check if scene loaded successfully"""
    return obs['scene_ready'] == 1
```

### Success Criteria

**Episode Success:** Complete 100 scene transitions with <200MB memory growth

**Performance Metrics:**
- **Load Success Rate:** ≥99% of scene loads succeed
- **Average Load Time:** <2 seconds per scene
- **Memory Growth:** <200MB total over 100 transitions (<2MB per transition)
- **Frame Rate:** ≥90 FPS maintained during transitions
- **Task Completion:** ≥80% of in-scene tasks completed

**Evaluation Protocol:**
- 100 test episodes (1000 total transitions)
- Record: load times, memory deltas, failures
- Memory leak analysis: Linear regression on memory usage over time
- Compare to manual scene transitions (developer baseline)

### Integration Points

**Existing Systems Used:**
- **HttpApiServer:** Scene loading via `POST /scene`
- **SceneLoadMonitor:** Track scene history, detect failures
- **HTTP API:** `GET /scene/history` for transition tracking
- **All scene-specific systems:** VR, voxel, UI, etc.

**New Components Required:**
- **Memory Leak Detector:** Track memory baseline, calculate delta per transition
- **Scene Task Tracker:** Define completion criteria for each scene
- **Transition Logger:** Record all scene changes, timestamps, memory snapshots
- **Failure Analyzer:** Diagnose scene load failures (logs, error codes)

### Expected Training Time

**Environment:** DQN (discrete action space) for scene selection

**Training Phases:**
1. **Exploration (5M steps):** Try all scene transitions, discover tasks
2. **Optimization (10M steps):** Minimize load times, avoid memory leaks
3. **Stress Testing (5M steps):** Rapid transitions to trigger edge cases

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 10-20 hours
- 8-core CPU (no GPU): 30-50 hours
- Parallelized training (4 environments): 6-12 hours (GPU)

**Convergence Metrics:**
- Load success rate ≥99%
- Memory growth <2MB per transition
- Task completion rate ≥80%

### Hardware Requirements

**Minimum:**
- CPU: Intel i5-12600K or AMD Ryzen 5 5600X (6 cores)
- GPU: NVIDIA RTX 3060 (8GB VRAM)
- RAM: 16GB system memory
- Storage: 100GB for scene cache and logs
- VR Headset: Not required

**Recommended:**
- CPU: Intel i7-13700K or AMD Ryzen 7 7700X (8 cores)
- GPU: NVIDIA RTX 4070 (12GB VRAM)
- RAM: 32GB system memory
- Storage: 250GB NVMe SSD for fast scene streaming
- VR Headset: Optional

---

## Scenario 10: Edge Case Discovery (Physics Exploits)

### Goal/Objective
Discover physics exploits, numerical instability, and edge case bugs by training adversarial agent to break the physics engine.

### Test Scene
**Scene Path:** `res://scenes/test_scenarios/rl_physics_fuzzing.tscn`

**Fuzzing Environment:**
- **Spacecraft:** RigidBody3D with full physics
- **Celestial Bodies:** 5 planets/moons with varying masses
- **Extreme Scenarios:** High velocities, rapid rotation, dense gravity wells
- **Goal:** Find inputs that cause crashes, NaN values, or physics violations

### Observations (State Space)

**Physics State + Anomaly Detection (24 values):**
```python
observation_space = {
    # Spacecraft Dynamics
    'position': gym.spaces.Box(-1e9, 1e9, shape=(3,)),
    'velocity': gym.spaces.Box(-1e6, 1e6, shape=(3,)),  # Extreme velocities allowed
    'angular_velocity': gym.spaces.Box(-1000, 1000, shape=(3,)),  # rad/s
    'rotation': gym.spaces.Box(-np.pi, np.pi, shape=(3,)),

    # Physics Engine State
    'gravity_acceleration': gym.spaces.Box(-1000, 1000, shape=(3,)),
    'physics_step_time_ms': gym.spaces.Box(0, 1000, shape=(1,)),
    'collision_count': gym.spaces.Box(0, 1000, shape=(1,)),

    # Anomaly Indicators
    'nan_detected': gym.spaces.Discrete(2),  # Boolean (NaN in position/velocity)
    'inf_detected': gym.spaces.Discrete(2),  # Boolean (Inf values)
    'energy_conservation_error': gym.spaces.Box(0, 1e9, shape=(1,)),  # Energy drift
    'position_magnitude': gym.spaces.Box(0, 1e12, shape=(1,)),  # Distance from origin

    # Exploit Signals
    'exploit_type': gym.spaces.Discrete(10),  # Categorized exploit (0 = none)
}
```

**Data Source:**
- Spacecraft RigidBody3D: Position, velocity, angular_velocity
- PhysicsEngine: Gravity calculations, physics step timing
- Custom anomaly detector: Check for NaN, Inf, energy violations
- HTTP API: `GET /state/scene` for physics state

### Actions (Action Space)

**Extreme Physics Control (8 values):**
```python
action_space = gym.spaces.Box(
    low=np.array([-100.0, -100.0, -100.0, -100.0, -100.0, -100.0, -10.0, -10.0]),
    high=np.array([100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 10.0, 10.0]),
    dtype=np.float32
)

# Action mapping (EXTREME values allowed):
# [0-2]: Thrust force (very high magnitude)
# [3-5]: Torque (extreme rotation)
# [6]: Time scale (time dilation multiplier)
# [7]: Mass scale (modify spacecraft mass on-the-fly)
```

**Action Injection:**
- HTTP API: `POST /spacecraft/control` with extreme values
- Custom physics manipulator: Allow time scale, mass changes (for fuzzing)

### Reward Function

**Adversarial reward (maximize chaos):**

```python
def calculate_reward(obs, action, next_obs, done):
    reward = 0.0

    # Anomaly Detection Bonuses (exploit found!)
    if next_obs['nan_detected']:
        reward += 500.0  # NaN value detected (critical bug)
        log_exploit("NaN_VALUE", action, next_obs)
        done = True

    if next_obs['inf_detected']:
        reward += 400.0  # Infinity value detected
        log_exploit("INF_VALUE", action, next_obs)
        done = True

    # Energy Conservation Violation
    energy_error = next_obs['energy_conservation_error']
    if energy_error > 1e6:  # Large energy drift (physics bug)
        reward += energy_error / 1e6  # Scale reward by severity
        log_exploit("ENERGY_VIOLATION", action, next_obs)

    # Extreme Velocity Achievement
    velocity_magnitude = np.linalg.norm(next_obs['velocity'])
    if velocity_magnitude > 1e5:  # Impossibly high velocity
        reward += 100.0
        log_exploit("EXTREME_VELOCITY", action, next_obs)

    # Extreme Angular Velocity
    angular_velocity_magnitude = np.linalg.norm(next_obs['angular_velocity'])
    if angular_velocity_magnitude > 100:  # Extremely fast spin
        reward += 50.0
        log_exploit("EXTREME_ROTATION", action, next_obs)

    # Physics Step Time Explosion
    if next_obs['physics_step_time_ms'] > 100:  # Physics simulation lagging
        reward += 200.0
        log_exploit("PHYSICS_LAG", action, next_obs)

    # Floating Origin Failure (extreme distance)
    if next_obs['position_magnitude'] > 1e9:  # >1 million km from origin
        reward += 150.0
        log_exploit("FLOATING_ORIGIN_FAIL", action, next_obs)

    # Collision Spam (physics instability)
    if next_obs['collision_count'] > 100:
        reward += 100.0
        log_exploit("COLLISION_SPAM", action, next_obs)

    # Action Diversity Bonus (encourage exploration)
    action_magnitude = np.linalg.norm(action)
    reward += action_magnitude * 0.1

    return reward, done

def log_exploit(exploit_type, action, obs):
    """Log exploit details for bug reporting"""
    # Save to exploit database: action sequence, observations, repro steps
    pass
```

### Success Criteria

**Episode Success:** Discover ≥10 unique exploits in 1000 episodes

**Performance Metrics:**
- **Exploit Discovery Rate:** ≥10 unique exploits found
- **Exploit Severity:** ≥3 critical bugs (NaN, Inf, crash)
- **Reproducibility:** ≥80% of exploits can be reproduced manually
- **Coverage:** Test ≥90% of PhysicsEngine code paths (via code coverage tool)

**Evaluation Protocol:**
- 1000 test episodes with diverse initial conditions
- Record: all exploits, action sequences, crash logs
- Manual reproduction: Developer attempts to reproduce each exploit
- Bug fixing: Create GitHub issues for confirmed bugs
- Regression testing: Re-run RL agent after fixes to verify patches

### Integration Points

**Existing Systems Used:**
- **PhysicsEngine:** N-body gravity, RigidBody3D simulation
- **TimeManager:** Time dilation (if exploit involves time manipulation)
- **FloatingOriginSystem:** Coordinate rebasing under stress
- **HTTP API:** Physics state queries, extreme control injection

**New Components Required:**
- **Anomaly Detector:** Check for NaN, Inf, energy violations every frame
- **Exploit Logger:** Record action sequences, observations, crash dumps
- **Energy Tracker:** Calculate total system energy (kinetic + potential)
- **Code Coverage Integration:** Track PhysicsEngine code paths executed
- **Crash Handler:** Catch Godot crashes, log before exit

### Expected Training Time

**Environment:** Evolutionary Strategy (ES) or Random Search (exploration-heavy)

**Training Phases:**
1. **Random Fuzzing (5M steps):** Pure random actions to find obvious bugs
2. **Guided Fuzzing (15M steps):** RL-guided exploration toward anomalies
3. **Exploit Refinement (5M steps):** Simplify exploit action sequences

**Estimated Wall-Clock Time:**
- Single RTX 3080 GPU: 15-25 hours
- 8-core CPU (no GPU): 40-60 hours
- Parallelized training (16 environments): 6-10 hours (GPU)

**Convergence Metrics:**
- Exploit discovery rate plateaus (no new exploits found)
- All critical code paths tested
- Diminishing returns on training time

### Hardware Requirements

**Minimum:**
- CPU: Intel i7-12700K or AMD Ryzen 7 5800X (8 cores)
- GPU: NVIDIA RTX 3060 Ti (8GB VRAM)
- RAM: 16GB system memory
- Storage: 250GB for exploit logs and crash dumps
- VR Headset: Not required

**Recommended:**
- CPU: Intel i9-13900K or AMD Ryzen 9 7950X (16+ cores for parallel fuzzing)
- GPU: NVIDIA RTX 4080 (12GB VRAM)
- RAM: 64GB system memory (for crash dump analysis)
- Storage: 500GB NVMe SSD for fast logging
- VR Headset: Not required

---

## Bonus Scenarios

### Scenario 11: VR Hand Tracking Precision
**Goal:** Validate finger tracking accuracy by performing fine motor tasks (assembling objects, typing on virtual keyboard).

### Scenario 12: Network Latency Simulation
**Goal:** Test VR locomotion under simulated network latency (50-300ms) for multiplayer validation.

### Scenario 13: Procedural Planet Exploration
**Goal:** Explore procedurally generated planets, validate terrain generation, biome transitions, and LOD systems.

### Scenario 14: Multi-Agent Cooperation
**Goal:** Train multiple RL agents to cooperate (e.g., spacecraft docking, cargo transfer) in shared VR space.

### Scenario 15: Audio Spatialization Validation
**Goal:** Navigate to sound sources in 3D space, validate AudioManager spatial audio accuracy.

---

## Implementation Guide

### Step 1: Environment Setup

**Install Dependencies:**
```bash
# Python RL libraries
pip install stable-baselines3 gymnasium torch numpy

# Godot HTTP client
pip install requests websockets

# Monitoring
pip install tensorboard wandb
```

**Godot Configuration:**
```gdscript
# Enable HTTP API (already active on port 8080)
# Enable WebSocket telemetry (port 8081)
# Configure scene whitelist (allow test scenes)
```

### Step 2: RL Environment Wrapper

**Create Gymnasium-compatible wrapper:**
```python
import gymnasium as gym
import requests
import numpy as np

class SpaceTimeVREnv(gym.Env):
    def __init__(self, scenario: str, godot_url: str = "http://localhost:8080"):
        self.godot_url = godot_url
        self.scenario = scenario

        # Define observation/action spaces (scenario-specific)
        self.observation_space = self._get_obs_space(scenario)
        self.action_space = self._get_action_space(scenario)

        # Load scenario scene
        self._load_scene(scenario)

    def reset(self, seed=None, options=None):
        # Reset scene via HTTP API
        response = requests.post(f"{self.godot_url}/scene/reload")
        obs = self._get_observation()
        info = {}
        return obs, info

    def step(self, action):
        # Send action to Godot
        self._apply_action(action)

        # Get new observation
        obs = self._get_observation()
        reward = self._calculate_reward(obs)
        done = self._check_done(obs)
        truncated = False
        info = {}

        return obs, reward, done, truncated, info

    def _get_observation(self):
        # Query state via HTTP API
        response = requests.get(f"{self.godot_url}/state/scene")
        state = response.json()
        return self._parse_observation(state)

    def _apply_action(self, action):
        # Send controller input via HTTP
        payload = {"action": action.tolist()}
        requests.post(f"{self.godot_url}/input/controller", json=payload)
```

### Step 3: Training Script

**PPO training example:**
```python
from stable_baselines3 import PPO
from spacetime_vr_env import SpaceTimeVREnv

# Create environment
env = SpaceTimeVREnv(scenario="flight_obstacle_course")

# Create PPO agent
model = PPO(
    "MlpPolicy",
    env,
    verbose=1,
    tensorboard_log="./tensorboard_logs/",
    learning_rate=3e-4,
    n_steps=2048,
    batch_size=64,
    n_epochs=10,
)

# Train
model.learn(total_timesteps=10_000_000)

# Save model
model.save("spacetime_flight_agent")
```

### Step 4: Evaluation

**Evaluation script:**
```python
# Load trained model
model = PPO.load("spacetime_flight_agent")

# Evaluate
env = SpaceTimeVREnv(scenario="flight_obstacle_course")
obs, info = env.reset()

for _ in range(1000):
    action, _ = model.predict(obs, deterministic=True)
    obs, reward, done, truncated, info = env.step(action)

    if done:
        print(f"Episode finished. Reward: {reward}")
        obs, info = env.reset()
```

### Step 5: Metrics Collection

**Log to TensorBoard/WandB:**
```python
import wandb

wandb.init(project="spacetime-vr-rl", name="flight-scenario-1")

# During training:
wandb.log({
    "reward": episode_reward,
    "vignetting": avg_vignetting,
    "frame_time_ms": avg_frame_time,
    "checkpoints_reached": checkpoint_count,
})
```

---

## Hardware Requirements

### Minimum System (Single Environment)
- **CPU:** Intel i5-12600K or AMD Ryzen 5 5600X (6 cores, 12 threads)
- **GPU:** NVIDIA RTX 3060 (8GB VRAM)
- **RAM:** 16GB DDR4
- **Storage:** 100GB SSD (for logs, checkpoints, training data)
- **Network:** 1 Gbps Ethernet (local training)
- **VR Headset:** Optional (Meta Quest 2 for validation)

### Recommended System (Parallel Training)
- **CPU:** Intel i9-13900K or AMD Ryzen 9 7950X (16+ cores, 32+ threads)
- **GPU:** NVIDIA RTX 4080 or 4090 (12-24GB VRAM)
- **RAM:** 64GB DDR5
- **Storage:** 500GB NVMe SSD (for fast I/O)
- **Network:** 10 Gbps Ethernet (distributed training)
- **VR Headset:** Meta Quest 3, Valve Index (for human validation)

### Cloud Training (AWS/GCP)
- **Instance Type:** g5.4xlarge (1x A10G GPU, 16 vCPUs, 64GB RAM)
- **Estimated Cost:** $1.50/hour (on-demand) or $0.50/hour (spot)
- **Training Time:** ~20 hours for Scenario 1 (PPO) = $30 total

---

## Conclusion

This document defines 10+ comprehensive RL test scenarios for SpaceTime VR automated playtesting. Each scenario is ready for implementation with detailed specifications for observations, actions, rewards, and success criteria.

**Next Steps:**
1. Implement HTTP API endpoints for controller input injection (`POST /input/controller`)
2. Create Gymnasium environment wrapper (SpaceTimeVREnv)
3. Build test scenes for each scenario
4. Set up training infrastructure (TensorBoard, model checkpointing)
5. Run initial training experiments (start with Scenario 1: Flight Navigation)
6. Validate trained agents with human testers
7. Iterate based on discovered bugs and exploits

**Expected Outcomes:**
- Discover 50+ bugs across 10 scenarios
- Validate VR comfort systems quantitatively
- Achieve 90 FPS performance under stress testing
- Identify physics exploits and edge cases
- Build automated regression test suite for CI/CD

**Documentation Version:** 1.0
**Status:** Ready for Implementation
**Contact:** RL Team Lead (for questions/clarifications)
