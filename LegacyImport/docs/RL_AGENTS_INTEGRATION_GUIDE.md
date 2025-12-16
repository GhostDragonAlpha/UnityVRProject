# Godot RL Agents Integration Guide for SpaceTime VR

**Last Updated:** 2025-12-09
**Status:** Integration Blueprint
**Target:** Automated playtesting and runtime testing for VR environments

---

## Table of Contents

1. [Overview & Benefits](#1-overview--benefits)
2. [Installation & Setup](#2-installation--setup)
3. [Architecture](#3-architecture)
4. [VR Testing Scenarios](#4-vr-testing-scenarios)
5. [First Agent Implementation](#5-first-agent-implementation)
6. [Integration with Existing Infrastructure](#6-integration-with-existing-infrastructure)
7. [CI/CD Integration](#7-cicd-integration)
8. [Advanced Use Cases](#8-advanced-use-cases)
9. [Troubleshooting](#9-troubleshooting)
10. [Performance Optimization](#10-performance-optimization)

---

## 1. Overview & Benefits

### What is Godot RL Agents?

Godot RL Agents is a framework that bridges Godot Engine and Python-based reinforcement learning (RL) libraries. It enables AI agents to learn complex behaviors through trial and error, making it ideal for automated testing and playtesting of game mechanics.

**GitHub:** https://github.com/edbeeching/godot_rl_agents
**Plugin:** https://github.com/edbeeching/godot_rl_agents_plugin
**Course:** https://huggingface.co/learn/deep-rl-course/en/unitbonus3/godotrl

### Why Use RL Agents for SpaceTime VR?

**Automated Playtesting:**
- Train AI agents to navigate VR environments and test locomotion systems
- Detect physics bugs, collision issues, and navigation dead-ends
- Stress-test performance under realistic player behavior patterns
- Validate VR comfort features (vignette, snap turns, teleportation)

**Regression Testing:**
- Ensure VR tracking remains stable across builds
- Verify spacecraft controls and walking transitions
- Test voxel terrain generation under various conditions
- Monitor performance degradation (90 FPS VR target)

**Runtime Validation:**
- Complement existing HTTP API testing (port 8080)
- Integrate with VoxelPerformanceMonitor for metrics collection
- Validate scene loading and hot-reload functionality
- Test edge cases difficult to manually reproduce

**Cost Efficiency:**
- Run 24/7 without human testers
- Parallelize testing across multiple environments
- Catch regressions before VR headset testing
- Reduce reliance on expensive manual QA

### Supported RL Frameworks

- **StableBaselines3** (recommended for beginners)
- **CleanRL** (lightweight, educational)
- **Sample Factory** (high-performance, scalable)
- **Ray RLLib** (distributed training)

---

## 2. Installation & Setup

### Prerequisites

**Python Environment:**
```bash
# Activate SpaceTime virtual environment
cd C:/Ignotus
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# Verify Python 3.8+
python --version
```

**Godot Version:**
- Godot 4.5.1+ (SpaceTime currently uses Godot 4.5.1)
- For ONNX model inference: Godot Mono/.NET build required

### Step 1: Install Godot RL Agents Python Package

```bash
# Install core package
pip install godot-rl

# Install with StableBaselines3 support (recommended)
pip install godot-rl[sb3]

# OR install with Sample Factory support (high-performance)
pip install godot-rl[sf]

# Verify installation
gdrl --help
```

**Add to SpaceTime dependencies:**
```bash
# Update requirements.txt
echo "godot-rl[sb3]" >> requirements.txt
```

### Step 2: Install Godot RL Agents Plugin

**Method 1: Via Godot AssetLib (Recommended)**

1. Open Godot editor for SpaceTime project
2. Click **AssetLib** tab (top of editor)
3. Search for "Godot RL Agents"
4. Click **Download** → **Install**
5. **Important:** Deselect `LICENSE` and `README.md` during installation
6. Click **Install**

**Method 2: Manual Installation**

```bash
cd C:/Ignotus/addons
git clone https://github.com/edbeeching/godot_rl_agents_plugin.git godot_rl

# Verify structure
ls godot_rl/
# Should contain: plugin.cfg, sync.gd, controller/, sensors/, etc.
```

### Step 3: Enable Plugin

1. In Godot editor: **Project → Project Settings → Plugins**
2. Find "Godot RL Agents"
3. Check **Enable** checkbox
4. Click **Close**

**Verify plugin is active:**
- Look for new node types in "Create New Node" dialog: `Sync`, `AIController2D`, `AIController3D`
- Check console for: `[Godot RL Agents] Plugin loaded`

### Step 4: Test Installation

**Download and test example environment:**
```bash
# Download example project (optional - for learning)
gdrl.env_from_hub -r edbeeching/godot_rl_JumperHard

# Run test training
cd godot_rl_JumperHard
python -m godot_rl.wrappers.stable_baselines_3.test_sb3 \
  --env_path=JumperHard.x86_64 \
  --timesteps=10000 \
  --viz
```

If example runs successfully, installation is complete.

---

## 3. Architecture

### Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Python Training Process                   │
│  ┌─────────────┐      ┌──────────────┐      ┌────────────┐ │
│  │ RL Algorithm│ ───→ │ Godot RL Env │ ───→ │ TCP Socket │ │
│  │  (SB3/etc)  │ ←─── │   Wrapper    │ ←─── │   Client   │ │
│  └─────────────┘      └──────────────┘      └────────────┘ │
└──────────────────────────────────────│──────────────────────┘
                                       │ TCP (Port 11008)
                                       │ Observations & Actions
┌──────────────────────────────────────│──────────────────────┐
│                    Godot Engine (C:/Ignotus)                 │
│  ┌────────────┐      ┌──────────────┐      ┌────────────┐  │
│  │ TCP Socket │ ───→ │  Sync Node   │ ───→ │ AI         │  │
│  │   Server   │ ←─── │ (Autoload)   │ ←─── │ Controllers│  │
│  └────────────┘      └──────────────┘      └────────────┘  │
│                             │                     │          │
│                             │                     │          │
│  ┌─────────────────────────┴─────────────────────┴───────┐ │
│  │              VR Scene (vr_locomotion_test.tscn)        │ │
│  │  ┌──────────────┐  ┌────────────┐  ┌──────────────┐  │ │
│  │  │ XROrigin3D   │  │ XRCamera3D │  │ Controllers  │  │ │
│  │  │ (Tracking)   │  │  (Player)  │  │ (L/R Hands)  │  │ │
│  │  └──────────────┘  └────────────┘  └──────────────┘  │ │
│  └───────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### Key Components

**1. Sync Node (Godot Side)**
- **Location:** Autoload singleton (added to project.godot)
- **Purpose:** Manages TCP server, coordinates AI controllers, synchronizes timesteps
- **Modes:**
  - `Training`: Connects to Python for RL training
  - `Onnx Inference`: Uses trained .onnx model for in-game AI
  - `Human`: Disables AI, allows manual control

**2. AIController3D/2D (Godot Side)**
- **Location:** Child node of agent/player in scene tree
- **Purpose:** Defines agent's observation space, action space, reward function
- **Script Interface:**
  ```gdscript
  func get_obs() -> Dictionary          # What agent sees
  func get_reward() -> float             # Performance metric
  func get_action_space() -> Dictionary  # Available actions
  func set_action(action) -> void        # Execute action
  ```

**3. Environment Wrapper (Python Side)**
- **Location:** Python training script
- **Purpose:** Bridges Godot environment to RL framework (SB3, etc.)
- **Interface:** OpenAI Gym-compatible API

**4. RL Algorithm (Python Side)**
- **Location:** Training script (e.g., `train_vr_locomotion.py`)
- **Purpose:** Learns optimal policy through reinforcement learning
- **Algorithms:** PPO, SAC, TD3, DQN, etc.

### Observation, Action, Reward (OAR) Cycle

```
1. Godot: AIController.get_obs() → Observation (e.g., player position, VR tracking)
2. TCP → Python: Send observation
3. Python: RL algorithm processes observation → Action (e.g., joystick input)
4. TCP → Godot: Send action
5. Godot: AIController.set_action() → Execute in physics step
6. Godot: Environment updates (player moves, physics simulates)
7. Godot: AIController.get_reward() → Reward signal (e.g., distance traveled)
8. TCP → Python: Send reward + done flag
9. Python: RL algorithm updates policy
10. Repeat
```

**Timestep Synchronization:**
- Each physics frame in Godot = 1 RL timestep
- Training: Python controls simulation speed (can run faster than real-time)
- Inference: Godot runs at normal speed (90 FPS for VR)

---

## 4. VR Testing Scenarios

### Scenario 1: VR Locomotion Validation

**Goal:** Train agent to navigate vr_locomotion_test.tscn without triggering comfort warnings

**Observations:**
- XRCamera3D position/rotation (local to XROrigin3D)
- XRController3D positions (left/right hands)
- Linear velocity (CharacterBody3D)
- Distance to nearest obstacle (raycast sensors)
- Vignette intensity (comfort system state)

**Actions:**
- Left joystick X/Y (continuous: -1.0 to 1.0) - locomotion direction
- Right joystick X (continuous: -1.0 to 1.0) - snap turn
- Trigger button (discrete: 0/1) - teleport activation

**Rewards:**
- +0.1 per timestep (survival bonus)
- +1.0 for reaching waypoint
- -0.5 for triggering comfort vignette (nausea risk)
- -1.0 for collision with obstacle
- -5.0 for episode timeout (failed navigation)

**Success Criteria:**
- Agent completes navigation course in < 60 seconds
- Zero comfort system activations (smooth movement)
- Zero collisions

**Test Coverage:**
- VR tracking stability
- Locomotion physics (CharacterBody3D integration)
- Comfort system responsiveness
- Input handling (godot-xr-tools)

---

### Scenario 2: VR Physics Stress Test

**Goal:** Detect physics instabilities and frame rate drops

**Observations:**
- Physics frame time (from VoxelPerformanceMonitor)
- Render frame time
- Object count in scene
- Collision layer states

**Actions:**
- Spawn voxel chunks (discrete: 0-10 chunks/frame)
- Grab/throw rigidbodies (continuous: force vector)
- Trigger particle effects

**Rewards:**
- +1.0 for maintaining 90 FPS
- -10.0 for frame time > 11.11ms (VR budget exceeded)
- -5.0 for physics jitter detected

**Success Criteria:**
- 90 FPS maintained for 1000 frames
- No physics warnings in console
- Memory usage < 2GB (voxel system budget)

**Test Coverage:**
- VoxelPerformanceMonitor accuracy
- Physics tick rate stability (90 Hz)
- Memory leak detection
- Performance degradation over time

---

### Scenario 3: Spacecraft Landing Automation

**Goal:** Train agent to land spacecraft on planetary surface

**Observations:**
- Spacecraft altitude, velocity, rotation (from Spacecraft RigidBody3D)
- Terrain height below (raycast)
- Fuel remaining
- Landing pad distance/orientation

**Actions:**
- Thrust vector (continuous: 3D direction + magnitude)
- RCS rotation (continuous: pitch/yaw/roll)

**Rewards:**
- -0.01 * fuel_consumption (efficiency)
- +10.0 for soft landing (< 2 m/s touchdown)
- -50.0 for crash (> 5 m/s or wrong orientation)
- +5.0 for landing on pad (vs. off-target)

**Success Criteria:**
- 90% success rate for landings
- Average fuel efficiency > 80%
- Landing precision within 2m of target

**Test Coverage:**
- Spacecraft physics (thrust, torque, gravity)
- Terrain collision detection
- Transition system (spacecraft → walking mode)
- FloatingOriginSystem handling large coordinates

---

### Scenario 4: Voxel Terrain Stress Testing

**Goal:** Generate worst-case voxel chunk loading patterns

**Observations:**
- Active chunk count (from VoxelPerformanceMonitor)
- Chunk generation queue length
- Frame time metrics
- Memory usage

**Actions:**
- Player movement direction (continuous: XZ plane)
- Movement speed (continuous: 0-20 m/s)

**Rewards:**
- +1.0 for triggering chunk generation
- +5.0 for causing performance warning (finds edge cases)
- +10.0 for reproducing known bugs

**Success Criteria:**
- Discover chunk generation patterns that exceed 5ms budget
- Trigger memory warnings (> 2GB usage)
- Find LOD transition artifacts

**Test Coverage:**
- VoxelTerrainGenerator performance
- Chunk loading/unloading logic
- Memory management
- godot_voxel addon integration

---

### Scenario 5: UI Interaction Automation

**Goal:** Test VR UI menus and HUD interactions

**Observations:**
- Controller raycast hit positions
- UI element states (visible, enabled, focused)
- Menu hierarchy depth

**Actions:**
- Controller pointing direction
- Trigger press (UI selection)
- Grip press (UI drag)

**Rewards:**
- +1.0 for successful menu navigation
- +5.0 for completing interaction sequence (e.g., settings change)
- -2.0 for UI element not responding

**Success Criteria:**
- Navigate full menu tree
- Test all buttons/sliders
- Verify VR pointer accuracy

**Test Coverage:**
- VR UI raycasting
- godot-xr-tools UI integration
- Settings manager persistence
- HUD visibility in different lighting

---

## 5. First Agent Implementation

### Step-by-Step: VR Locomotion Test Agent

This section walks through creating your first RL agent for SpaceTime VR.

#### Step 1: Prepare the Scene

**1. Open vr_locomotion_test.tscn**

Scene already exists at: `C:/Ignotus/scenes/features/vr_locomotion_test.tscn`

**2. Add Sync Node (Autoload)**

Instead of adding to scene, we'll add as autoload for global access:

Edit `project.godot`:
```ini
[autoload]

# ... existing autoloads ...
GodotRLAgentsSync="*res://addons/godot_rl/sync.gd"
```

**OR** add via editor:
- Project → Project Settings → Autoload
- Path: `res://addons/godot_rl/sync.gd`
- Name: `GodotRLAgentsSync`
- Check "Enable"

**3. Configure Sync Node**

Create `res://rl_training/sync_config.gd`:
```gdscript
extends Node

func _ready():
	var sync = get_node("/root/GodotRLAgentsSync")
	if sync:
		sync.control_mode = sync.ControlModes.TRAINING
		sync.action_repeat = 8  # Speed up training
		sync.speed_up = 8  # 8x faster than real-time
		print("[RL] Sync node configured for training")
```

#### Step 2: Create AI Controller

**1. Create AIController script**

Create `res://rl_training/vr_locomotion_controller.gd`:

```gdscript
extends AIController3D
class_name VRLocomotionAIController

## AI Controller for VR locomotion testing
## Tests: movement, rotation, comfort system, collision avoidance

# References (set in _ready)
@onready var player_body: CharacterBody3D = get_parent()
@onready var xr_origin: XROrigin3D = player_body.get_node("XROrigin3D")
@onready var xr_camera: XRCamera3D = xr_origin.get_node("XRCamera3D")
@onready var left_controller: XRController3D = xr_origin.get_node("LeftController")
@onready var right_controller: XRController3D = xr_origin.get_node("RightController")

# Action space
var move_x: float = 0.0
var move_z: float = 0.0
var rotate: float = 0.0
var teleport: float = 0.0

# Sensors
var raycast_forward: RayCast3D
var raycast_left: RayCast3D
var raycast_right: RayCast3D

# Goal/waypoint system
var current_waypoint: Vector3 = Vector3(5, 0, 5)  # Example waypoint
var waypoint_reached: bool = false
var waypoint_radius: float = 1.0

# Performance tracking
var start_time: float = 0.0
var episode_steps: int = 0
var max_episode_steps: int = 5400  # 60 seconds at 90 fps

func _ready():
	# Initialize raycasts for obstacle detection
	_setup_raycasts()

	# Reset on start
	reset()

func _setup_raycasts():
	"""Create raycasts for obstacle detection."""
	raycast_forward = RayCast3D.new()
	raycast_forward.target_position = Vector3(0, 0, -2)  # 2m forward
	raycast_forward.enabled = true
	raycast_forward.collide_with_areas = false
	raycast_forward.collide_with_bodies = true
	add_child(raycast_forward)

	raycast_left = RayCast3D.new()
	raycast_left.target_position = Vector3(-1.5, 0, -1.5)  # Diagonal left
	raycast_left.enabled = true
	add_child(raycast_left)

	raycast_right = RayCast3D.new()
	raycast_right.target_position = Vector3(1.5, 0, -1.5)  # Diagonal right
	raycast_right.enabled = true
	add_child(raycast_right)

## RL Interface Methods

func get_obs() -> Dictionary:
	"""Return agent observations."""

	# Player state (in local coordinates)
	var player_pos = player_body.global_position
	var player_vel = player_body.velocity
	var player_rot = player_body.global_rotation.y

	# Waypoint direction (normalized)
	var to_waypoint = current_waypoint - player_pos
	var waypoint_distance = to_waypoint.length()
	var waypoint_direction = to_waypoint.normalized()

	# Obstacle detection (0.0 = far, 1.0 = close)
	var obs_forward = 1.0 if raycast_forward.is_colliding() else 0.0
	var obs_left = 1.0 if raycast_left.is_colliding() else 0.0
	var obs_right = 1.0 if raycast_right.is_colliding() else 0.0

	# VR tracking state
	var camera_rot_x = xr_camera.rotation.x  # Pitch
	var camera_rot_y = xr_camera.rotation.y  # Yaw

	# Velocity normalization (max ~5 m/s expected)
	var vel_x = clamp(player_vel.x / 5.0, -1.0, 1.0)
	var vel_z = clamp(player_vel.z / 5.0, -1.0, 1.0)

	# Build observation vector
	var obs = [
		# Waypoint info (3)
		waypoint_direction.x,
		waypoint_direction.z,
		clamp(waypoint_distance / 20.0, 0.0, 1.0),  # Normalized to ~20m max

		# Player state (4)
		sin(player_rot),  # Rotation as sin/cos for continuity
		cos(player_rot),
		vel_x,
		vel_z,

		# Obstacle sensors (3)
		obs_forward,
		obs_left,
		obs_right,

		# VR camera orientation (2)
		camera_rot_x / PI,  # Normalize to [-1, 1]
		camera_rot_y / PI,
	]
	# Total: 12 observations

	return {"obs": obs}

func get_reward() -> float:
	"""Calculate reward signal."""
	var reward = 0.0

	# 1. Survival bonus (encourage staying alive)
	reward += 0.01

	# 2. Progress toward waypoint
	var distance_to_waypoint = player_body.global_position.distance_to(current_waypoint)
	if distance_to_waypoint < waypoint_radius:
		if not waypoint_reached:
			reward += 10.0  # Big bonus for reaching waypoint
			waypoint_reached = true
			done = true  # Episode complete
	else:
		# Reward for getting closer (inverse distance)
		reward += (1.0 / max(distance_to_waypoint, 1.0)) * 0.1

	# 3. Penalty for collision
	if raycast_forward.is_colliding():
		var collision_distance = raycast_forward.get_collision_point().distance_to(global_position)
		if collision_distance < 0.5:  # Very close
			reward -= 1.0

	# 4. Comfort system penalty (if implemented)
	# Check if vignette is active (would need reference to VRComfortSystem)
	# For now, penalize excessive rotation speed
	if abs(rotate) > 0.8:  # Harsh rotation
		reward -= 0.1

	# 5. Timeout penalty
	if episode_steps >= max_episode_steps:
		reward -= 5.0
		done = true

	return reward

func get_action_space() -> Dictionary:
	"""Define available actions."""
	return {
		"move_x": {
			"size": 1,
			"action_type": "continuous"  # -1.0 (left) to 1.0 (right)
		},
		"move_z": {
			"size": 1,
			"action_type": "continuous"  # -1.0 (back) to 1.0 (forward)
		},
		"rotate": {
			"size": 1,
			"action_type": "continuous"  # -1.0 (left) to 1.0 (right)
		},
		"teleport": {
			"size": 1,
			"action_type": "continuous"  # > 0.5 = activate teleport
		}
	}

func set_action(action) -> void:
	"""Apply action from RL algorithm."""
	move_x = clamp(action["move_x"][0], -1.0, 1.0)
	move_z = clamp(action["move_z"][0], -1.0, 1.0)
	rotate = clamp(action["rotate"][0], -1.0, 1.0)
	teleport = clamp(action["teleport"][0], 0.0, 1.0)

func reset() -> void:
	"""Reset environment for new episode."""
	# Reset player position
	player_body.global_position = Vector3.ZERO
	player_body.velocity = Vector3.ZERO
	player_body.global_rotation = Vector3.ZERO

	# Reset waypoint
	current_waypoint = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	waypoint_reached = false

	# Reset episode tracking
	start_time = Time.get_ticks_msec()
	episode_steps = 0

	# Reset AI controller state
	done = false
	needs_reset = false
	reward = 0.0

func _physics_process(delta):
	"""Called every physics step (90 fps)."""
	episode_steps += 1

	# Check if reset needed
	if needs_reset:
		reset()
		return

	# Apply AI actions to player movement (if not in human mode)
	if heuristic != "human":
		_apply_ai_movement(delta)

func _apply_ai_movement(delta: float):
	"""Apply AI-controlled movement to player."""
	# Calculate movement direction (in player's local space)
	var move_dir = Vector3(move_x, 0, -move_z)  # Note: -Z is forward in Godot
	move_dir = move_dir.rotated(Vector3.UP, player_body.global_rotation.y)

	# Apply movement (integrate with existing CharacterBody3D physics)
	var speed = 3.0  # m/s
	player_body.velocity.x = move_dir.x * speed
	player_body.velocity.z = move_dir.z * speed

	# Apply rotation (snap turn style)
	if abs(rotate) > 0.5:  # Threshold for snap turn
		var snap_angle = sign(rotate) * deg_to_rad(30)  # 30 degree snap
		player_body.rotate_y(snap_angle)

	# Apply teleport (if triggered)
	if teleport > 0.5:
		var teleport_distance = 3.0  # 3m forward
		var teleport_dir = Vector3(0, 0, -teleport_distance).rotated(Vector3.UP, player_body.global_rotation.y)
		player_body.global_position += teleport_dir
```

**2. Attach controller to player**

Modify `scenes/features/vr_locomotion_test.tscn`:
1. Open scene in Godot editor
2. Find the player/character node (likely CharacterBody3D)
3. Right-click → Add Child Node → Search "AIController3D"
4. Attach the script: `res://rl_training/vr_locomotion_controller.gd`

#### Step 3: Create Python Training Script

Create `C:/Ignotus/rl_training/train_vr_locomotion.py`:

```python
#!/usr/bin/env python3
"""
VR Locomotion RL Training Script for SpaceTime

Trains AI agent to navigate vr_locomotion_test.tscn using StableBaselines3 PPO.

Usage:
    python rl_training/train_vr_locomotion.py --timesteps 100000 --viz
"""

import argparse
from pathlib import Path
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import SubprocVecEnv
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

# SpaceTime project paths
PROJECT_ROOT = Path(__file__).parent.parent
GODOT_EXECUTABLE = Path("C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe")
SCENE_PATH = "res://scenes/features/vr_locomotion_test.tscn"
MODEL_SAVE_DIR = PROJECT_ROOT / "rl_training" / "models"
LOGS_DIR = PROJECT_ROOT / "rl_training" / "logs"

def create_env(env_id: int, show_window: bool = False):
    """Factory function to create Godot environment."""
    def _init():
        env = StableBaselinesGodotEnv(
            env_path=str(GODOT_EXECUTABLE),
            show_window=show_window,
            scene_path=SCENE_PATH,
            port=11008 + env_id,  # Unique port per environment
            seed=42 + env_id,
        )
        return env
    return _init

def train(
    timesteps: int = 100_000,
    num_envs: int = 4,
    save_frequency: int = 10_000,
    experiment_name: str = "vr_locomotion_v1",
    visualize: bool = False,
):
    """Train VR locomotion agent using PPO."""

    # Create output directories
    MODEL_SAVE_DIR.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    print(f"[RL Training] Starting training for {experiment_name}")
    print(f"  Timesteps: {timesteps:,}")
    print(f"  Parallel Envs: {num_envs}")
    print(f"  Visualization: {visualize}")
    print(f"  Godot: {GODOT_EXECUTABLE}")
    print(f"  Scene: {SCENE_PATH}")

    # Create vectorized environment (parallel training)
    if num_envs > 1:
        env = SubprocVecEnv([
            create_env(i, show_window=visualize and i == 0)  # Only show first env
            for i in range(num_envs)
        ])
    else:
        env = create_env(0, show_window=visualize)()

    # Create PPO agent
    # Hyperparameters tuned for VR locomotion
    model = PPO(
        "MlpPolicy",  # Multi-layer perceptron
        env,
        verbose=1,
        tensorboard_log=str(LOGS_DIR / experiment_name),
        learning_rate=3e-4,
        n_steps=2048,  # Steps per update
        batch_size=64,
        n_epochs=10,
        gamma=0.99,  # Discount factor
        gae_lambda=0.95,  # GAE parameter
        clip_range=0.2,  # PPO clip range
        ent_coef=0.01,  # Entropy coefficient (exploration)
        vf_coef=0.5,  # Value function coefficient
    )

    print(f"\n[RL Training] Model created. Starting training loop...")

    # Training loop with checkpointing
    checkpoint_interval = save_frequency
    for checkpoint in range(0, timesteps, checkpoint_interval):
        remaining_steps = min(checkpoint_interval, timesteps - checkpoint)

        print(f"\n[Checkpoint {checkpoint // checkpoint_interval + 1}] Training {remaining_steps:,} steps...")
        model.learn(total_timesteps=remaining_steps, reset_num_timesteps=False)

        # Save checkpoint
        checkpoint_path = MODEL_SAVE_DIR / f"{experiment_name}_step_{checkpoint + remaining_steps}.zip"
        model.save(str(checkpoint_path))
        print(f"[Checkpoint] Saved: {checkpoint_path}")

    # Final save
    final_path = MODEL_SAVE_DIR / f"{experiment_name}_final.zip"
    model.save(str(final_path))
    print(f"\n[Training Complete] Final model saved: {final_path}")

    # Export to ONNX for in-game inference
    onnx_path = MODEL_SAVE_DIR / f"{experiment_name}_final.onnx"
    print(f"[Export] Exporting to ONNX: {onnx_path}")
    # Note: ONNX export requires additional setup (see ONNX Export section)

    env.close()
    print("[Training Complete] Environment closed.")

def main():
    parser = argparse.ArgumentParser(description="Train VR locomotion agent")
    parser.add_argument("--timesteps", type=int, default=100_000, help="Total training timesteps")
    parser.add_argument("--num_envs", type=int, default=4, help="Number of parallel environments")
    parser.add_argument("--save_frequency", type=int, default=10_000, help="Save checkpoint every N steps")
    parser.add_argument("--experiment_name", type=str, default="vr_locomotion_v1", help="Experiment name")
    parser.add_argument("--viz", action="store_true", help="Show Godot window during training")

    args = parser.parse_args()

    train(
        timesteps=args.timesteps,
        num_envs=args.num_envs,
        save_frequency=args.save_frequency,
        experiment_name=args.experiment_name,
        visualize=args.viz,
    )

if __name__ == "__main__":
    main()
```

#### Step 4: Run Training

**1. Activate environment and run:**

```bash
cd C:/Ignotus
.venv\Scripts\activate

# Quick test (1000 timesteps, show window)
python rl_training/train_vr_locomotion.py --timesteps 1000 --num_envs 1 --viz

# Full training (100k timesteps, 4 parallel envs, headless)
python rl_training/train_vr_locomotion.py --timesteps 100000 --num_envs 4
```

**2. Monitor training progress:**

```bash
# Install tensorboard (if not already)
pip install tensorboard

# Launch tensorboard
tensorboard --logdir=rl_training/logs

# Open browser to: http://localhost:6006
```

**3. Training output:**

```
[RL Training] Starting training for vr_locomotion_v1
  Timesteps: 100,000
  Parallel Envs: 4
  Visualization: False
  Godot: C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe
  Scene: res://scenes/features/vr_locomotion_test.tscn

[RL Training] Model created. Starting training loop...

[Checkpoint 1] Training 10,000 steps...
| rollout/           |          |
|    ep_len_mean     | 245      |
|    ep_rew_mean     | 3.42     |
| time/              |          |
|    fps             | 856      |
|    total_timesteps | 10000    |
[Checkpoint] Saved: rl_training/models/vr_locomotion_v1_step_10000.zip

...

[Training Complete] Final model saved: rl_training/models/vr_locomotion_v1_final.zip
```

#### Step 5: Test Trained Agent

**1. Load and evaluate model:**

Create `rl_training/test_vr_locomotion.py`:

```python
#!/usr/bin/env python3
"""Test trained VR locomotion agent."""

from pathlib import Path
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

PROJECT_ROOT = Path(__file__).parent.parent
GODOT_EXECUTABLE = Path("C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe")
SCENE_PATH = "res://scenes/features/vr_locomotion_test.tscn"
MODEL_PATH = PROJECT_ROOT / "rl_training" / "models" / "vr_locomotion_v1_final.zip"

def test_agent(episodes: int = 10):
    """Test trained agent for multiple episodes."""

    # Load trained model
    print(f"[Test] Loading model: {MODEL_PATH}")
    model = PPO.load(str(MODEL_PATH))

    # Create test environment (with visualization)
    env = StableBaselinesGodotEnv(
        env_path=str(GODOT_EXECUTABLE),
        show_window=True,  # Show Godot window
        scene_path=SCENE_PATH,
        port=11008,
    )

    # Run episodes
    for episode in range(episodes):
        obs = env.reset()
        done = False
        episode_reward = 0
        steps = 0

        print(f"\n[Episode {episode + 1}/{episodes}] Starting...")

        while not done:
            # Get action from trained agent
            action, _states = model.predict(obs, deterministic=True)

            # Execute action
            obs, reward, done, info = env.step(action)
            episode_reward += reward
            steps += 1

        print(f"[Episode {episode + 1}] Finished: Reward={episode_reward:.2f}, Steps={steps}")

    env.close()
    print("\n[Test] Complete.")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Test trained VR locomotion agent")
    parser.add_argument("--episodes", type=int, default=10, help="Number of test episodes")
    args = parser.parse_args()

    test_agent(episodes=args.episodes)
```

**2. Run test:**

```bash
python rl_training/test_vr_locomotion.py --episodes 5
```

You should see Godot window open with the agent navigating autonomously.

---

## 6. Integration with Existing Infrastructure

### VoxelPerformanceMonitor Integration

**Goal:** Collect performance metrics during RL training to detect regressions

**Implementation:**

1. **Expose metrics via AIController:**

Modify `vr_locomotion_controller.gd`:

```gdscript
# Add to VRLocomotionAIController

@onready var perf_monitor = get_node("/root/VoxelPerformanceMonitor")

func get_obs() -> Dictionary:
	var obs = # ... existing observations ...

	# Add performance metrics to observations
	if perf_monitor:
		var stats = perf_monitor.get_statistics()
		obs["performance"] = [
			stats.physics_frame_time_ms / 11.11,  # Normalized to budget
			stats.render_frame_time_ms / 11.11,
			float(stats.active_chunk_count) / 512.0,  # Normalized to max
		]

	return obs

func get_reward() -> float:
	var reward = # ... existing reward ...

	# Penalty for performance degradation
	if perf_monitor:
		var stats = perf_monitor.get_statistics()

		# Major penalty for exceeding VR frame budget
		if stats.physics_frame_time_ms > 11.11:
			reward -= 5.0
			print("[RL] PERFORMANCE WARNING: Physics frame time exceeded VR budget!")

		# Penalty for excessive chunk loading
		if stats.active_chunk_count > 512:
			reward -= 2.0

	return reward
```

2. **Log metrics to TensorBoard:**

Modify `train_vr_locomotion.py`:

```python
from stable_baselines3.common.callbacks import BaseCallback

class PerformanceMetricsCallback(BaseCallback):
	"""Log SpaceTime performance metrics during training."""

	def __init__(self, verbose=0):
		super().__init__(verbose)

	def _on_step(self) -> bool:
		# Get performance info from environment
		if "performance" in self.locals.get("infos", [{}])[0]:
			perf = self.locals["infos"][0]["performance"]

			# Log to TensorBoard
			self.logger.record("performance/physics_frame_time_ratio", perf[0])
			self.logger.record("performance/render_frame_time_ratio", perf[1])
			self.logger.record("performance/chunk_count_ratio", perf[2])

		return True

# Add to training loop
model.learn(
	total_timesteps=remaining_steps,
	callback=PerformanceMetricsCallback(),
	reset_num_timesteps=False
)
```

### HTTP API Integration

**Goal:** Control RL training via HTTP API (scene reloading, health checks)

**Implementation:**

1. **API-triggered training:**

Create `rl_training/api_controlled_training.py`:

```python
#!/usr/bin/env python3
"""RL training controlled via SpaceTime HTTP API."""

import requests
import time
from train_vr_locomotion import train

API_BASE = "http://127.0.0.1:8080"
AUTH_TOKEN = None  # Get from Godot console on startup

def check_api_health():
	"""Verify HTTP API is running."""
	try:
		response = requests.get(f"{API_BASE}/status", timeout=5)
		return response.status_code == 200
	except:
		return False

def load_training_scene():
	"""Load VR locomotion test scene via API."""
	headers = {"Content-Type": "application/json"}
	if AUTH_TOKEN:
		headers["Authorization"] = f"Bearer {AUTH_TOKEN}"

	payload = {"scene_path": "res://scenes/features/vr_locomotion_test.tscn"}
	response = requests.post(f"{API_BASE}/scene", json=payload, headers=headers)

	if response.status_code == 200:
		print("[API] Training scene loaded successfully")
		return True
	else:
		print(f"[API] Failed to load scene: {response.text}")
		return False

def get_performance_metrics():
	"""Get current performance metrics via API."""
	try:
		response = requests.get(f"{API_BASE}/performance/metrics", timeout=5)
		if response.status_code == 200:
			return response.json()
	except:
		pass
	return None

def main():
	# 1. Verify API is running
	print("[API] Checking HTTP API health...")
	if not check_api_health():
		print("[API] ERROR: HTTP API not responding. Start Godot first.")
		return

	# 2. Load training scene
	print("[API] Loading training scene...")
	if not load_training_scene():
		print("[API] ERROR: Failed to load training scene")
		return

	time.sleep(2)  # Wait for scene to initialize

	# 3. Check initial performance
	metrics = get_performance_metrics()
	if metrics:
		print(f"[API] Initial performance: {metrics}")

	# 4. Start training
	print("[API] Starting RL training...")
	train(
		timesteps=100_000,
		num_envs=4,
		experiment_name="api_controlled_vr_locomotion",
		visualize=False,
	)

if __name__ == "__main__":
	main()
```

2. **Scene hot-reloading during training:**

```python
# Add to training callback
class SceneReloadCallback(BaseCallback):
	"""Reload scene every N steps to test hot-reload stability."""

	def __init__(self, reload_interval=10000, verbose=0):
		super().__init__(verbose)
		self.reload_interval = reload_interval

	def _on_step(self) -> bool:
		if self.num_timesteps % self.reload_interval == 0:
			print(f"[Callback] Triggering scene reload at step {self.num_timesteps}")
			requests.post("http://127.0.0.1:8080/scene/reload")
			time.sleep(2)  # Wait for reload
		return True
```

### CI/CD Integration (Preview)

See Section 7 for full CI/CD integration details.

**Quick test in CI:**

```yaml
# .github/workflows/rl_smoke_test.yml
name: RL Smoke Test

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install godot-rl[sb3]

      - name: Run RL smoke test
        run: |
          python rl_training/train_vr_locomotion.py --timesteps 100 --num_envs 1
```

---

## 7. CI/CD Integration

### Automated RL Testing Pipeline

**Goal:** Integrate RL agents into CI/CD for regression detection

### Step 1: Headless Training Infrastructure

**1. Export headless Godot build:**

```bash
# Export headless server build (no rendering)
godot --headless --export-release "Linux/X11" "build/SpaceTime_headless.x86_64"
```

**Note:** Headless mode may have limitations with VR scenes. Consider:
- Using mock VR input for headless testing
- Running full VR tests only on dedicated test machines
- Hybrid approach: Headless for basic tests, full VR for nightly builds

**2. Configure CI environment:**

```yaml
# .github/workflows/rl_regression_test.yml
name: RL Regression Testing

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Nightly at 2 AM

jobs:
  rl-locomotion-test:
    runs-on: ubuntu-latest
    timeout-minutes: 60

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install godot-rl[sb3] tensorboard
          pip install -r requirements.txt

      - name: Download Godot headless
        run: |
          wget https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_linux.x86_64.zip
          unzip Godot_v4.5.1-stable_linux.x86_64.zip
          chmod +x Godot_v4.5.1-stable_linux.x86_64

      - name: Run RL smoke test (1k timesteps)
        run: |
          python rl_training/train_vr_locomotion.py \
            --timesteps 1000 \
            --num_envs 2 \
            --experiment_name "ci_smoke_test_${{ github.sha }}"

      - name: Validate training metrics
        run: |
          python rl_training/validate_training_metrics.py \
            --experiment "ci_smoke_test_${{ github.sha }}" \
            --min_reward -10.0 \
            --max_physics_time 15.0

      - name: Upload training logs
        uses: actions/upload-artifact@v3
        with:
          name: rl-training-logs
          path: rl_training/logs/

      - name: Upload trained model
        uses: actions/upload-artifact@v3
        with:
          name: rl-model
          path: rl_training/models/ci_smoke_test_*.zip

  rl-performance-test:
    runs-on: ubuntu-latest
    needs: rl-locomotion-test

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install godot-rl[sb3] pandas matplotlib

      - name: Download trained model
        uses: actions/download-artifact@v3
        with:
          name: rl-model
          path: rl_training/models/

      - name: Evaluate model performance
        run: |
          python rl_training/evaluate_model.py \
            --model "rl_training/models/ci_smoke_test_${{ github.sha }}_final.zip" \
            --episodes 10 \
            --output "performance_report.json"

      - name: Check performance regression
        run: |
          python rl_training/check_regression.py \
            --current "performance_report.json" \
            --baseline "rl_training/baselines/vr_locomotion_baseline.json" \
            --tolerance 0.1

      - name: Upload performance report
        uses: actions/upload-artifact@v3
        with:
          name: performance-report
          path: performance_report.json
```

### Step 2: Validation Scripts

**1. Metrics validator:**

Create `rl_training/validate_training_metrics.py`:

```python
#!/usr/bin/env python3
"""Validate RL training metrics against thresholds."""

import argparse
import json
import sys
from pathlib import Path
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

def validate_training(experiment_name: str, min_reward: float, max_physics_time: float):
	"""Validate training metrics from TensorBoard logs."""

	log_dir = Path("rl_training/logs") / experiment_name
	if not log_dir.exists():
		print(f"[ERROR] Log directory not found: {log_dir}")
		return False

	# Find latest event file
	event_files = list(log_dir.glob("events.out.tfevents.*"))
	if not event_files:
		print(f"[ERROR] No TensorBoard event files found in {log_dir}")
		return False

	latest_event = max(event_files, key=lambda p: p.stat().st_mtime)
	print(f"[Validation] Reading: {latest_event}")

	# Load events
	ea = EventAccumulator(str(latest_event))
	ea.Reload()

	# Extract metrics
	try:
		reward_values = [s.value for s in ea.Scalars('rollout/ep_rew_mean')]

		# Check minimum reward threshold
		final_reward = reward_values[-1] if reward_values else float('-inf')
		print(f"[Validation] Final reward: {final_reward:.2f} (threshold: {min_reward:.2f})")

		if final_reward < min_reward:
			print(f"[FAIL] Reward below threshold!")
			return False

		# Check physics time (if available)
		if 'performance/physics_frame_time_ratio' in ea.Tags()['scalars']:
			physics_times = [s.value for s in ea.Scalars('performance/physics_frame_time_ratio')]
			max_observed = max(physics_times) * 11.11  # Convert ratio to ms
			print(f"[Validation] Max physics time: {max_observed:.2f} ms (threshold: {max_physics_time:.2f} ms)")

			if max_observed > max_physics_time:
				print(f"[FAIL] Physics time exceeded threshold!")
				return False

		print("[PASS] All validation checks passed")
		return True

	except Exception as e:
		print(f"[ERROR] Validation failed: {e}")
		return False

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Validate RL training metrics")
	parser.add_argument("--experiment", required=True, help="Experiment name")
	parser.add_argument("--min_reward", type=float, default=-10.0, help="Minimum acceptable reward")
	parser.add_argument("--max_physics_time", type=float, default=15.0, help="Max physics frame time (ms)")

	args = parser.parse_args()

	success = validate_training(args.experiment, args.min_reward, args.max_physics_time)
	sys.exit(0 if success else 1)
```

**2. Regression checker:**

Create `rl_training/check_regression.py`:

```python
#!/usr/bin/env python3
"""Check for performance regression vs baseline."""

import argparse
import json
import sys
from pathlib import Path

def check_regression(current_file: str, baseline_file: str, tolerance: float):
	"""Compare current performance to baseline."""

	# Load reports
	with open(current_file, 'r') as f:
		current = json.load(f)

	with open(baseline_file, 'r') as f:
		baseline = json.load(f)

	# Compare key metrics
	metrics_to_check = [
		"mean_reward",
		"mean_episode_length",
		"success_rate",
	]

	regressions = []
	for metric in metrics_to_check:
		current_val = current.get(metric, 0)
		baseline_val = baseline.get(metric, 0)

		# Calculate relative change
		if baseline_val != 0:
			change = (current_val - baseline_val) / baseline_val
		else:
			change = 0

		print(f"[Regression Check] {metric}:")
		print(f"  Baseline: {baseline_val:.4f}")
		print(f"  Current:  {current_val:.4f}")
		print(f"  Change:   {change:+.2%}")

		# Check if regression (tolerance = 10% by default)
		if change < -tolerance:
			print(f"  [REGRESSION DETECTED] Performance dropped by {-change:.2%}")
			regressions.append(metric)
		else:
			print(f"  [OK]")

	if regressions:
		print(f"\n[FAIL] Regressions detected in: {', '.join(regressions)}")
		return False
	else:
		print("\n[PASS] No regressions detected")
		return True

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Check performance regression")
	parser.add_argument("--current", required=True, help="Current performance report JSON")
	parser.add_argument("--baseline", required=True, help="Baseline performance report JSON")
	parser.add_argument("--tolerance", type=float, default=0.1, help="Regression tolerance (0.1 = 10%)")

	args = parser.parse_args()

	success = check_regression(args.current, args.baseline, args.tolerance)
	sys.exit(0 if success else 1)
```

### Step 3: Baseline Management

**1. Create baseline:**

```bash
# Train baseline model
python rl_training/train_vr_locomotion.py \
  --timesteps 100000 \
  --experiment_name "vr_locomotion_baseline"

# Evaluate baseline
python rl_training/evaluate_model.py \
  --model "rl_training/models/vr_locomotion_baseline_final.zip" \
  --episodes 100 \
  --output "rl_training/baselines/vr_locomotion_baseline.json"

# Commit baseline to repo
git add rl_training/baselines/vr_locomotion_baseline.json
git commit -m "Add RL baseline for VR locomotion"
```

**2. Update baseline (after improvements):**

```bash
# After making improvements to VR locomotion system
python rl_training/train_vr_locomotion.py --timesteps 100000 --experiment_name "new_baseline"
python rl_training/evaluate_model.py --model "rl_training/models/new_baseline_final.zip" --episodes 100 --output "new_baseline.json"

# Compare to old baseline
python rl_training/check_regression.py --current new_baseline.json --baseline rl_training/baselines/vr_locomotion_baseline.json

# If improved, update baseline
cp new_baseline.json rl_training/baselines/vr_locomotion_baseline.json
git add rl_training/baselines/vr_locomotion_baseline.json
git commit -m "Update RL baseline (improved locomotion physics)"
```

### Step 4: Nightly Training Runs

**Long-duration training for comprehensive testing:**

```yaml
# .github/workflows/rl_nightly.yml
name: RL Nightly Training

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  full-training:
    runs-on: ubuntu-latest
    timeout-minutes: 480  # 8 hours

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install godot-rl[sb3]

      - name: Run full training (1M timesteps)
        run: |
          python rl_training/train_vr_locomotion.py \
            --timesteps 1000000 \
            --num_envs 8 \
            --experiment_name "nightly_$(date +%Y%m%d)"

      - name: Evaluate trained model
        run: |
          python rl_training/evaluate_model.py \
            --model "rl_training/models/nightly_$(date +%Y%m%d)_final.zip" \
            --episodes 100 \
            --output "nightly_report.json"

      - name: Generate report
        run: |
          python rl_training/generate_report.py \
            --metrics "nightly_report.json" \
            --output "RL_NIGHTLY_REPORT.md"

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: nightly-rl-results
          path: |
            rl_training/models/nightly_*
            rl_training/logs/nightly_*
            RL_NIGHTLY_REPORT.md
```

---

## 8. Advanced Use Cases

### 8.1 Voxel Terrain Stress Testing

**Scenario:** Find edge cases in voxel chunk generation

**Implementation:**

```gdscript
# rl_training/voxel_stress_test_controller.gd
extends AIController3D
class_name VoxelStressTestController

@onready var perf_monitor = get_node("/root/VoxelPerformanceMonitor")
var chaos_mode: bool = true  # Intentionally trigger worst-case scenarios

func get_obs() -> Dictionary:
	var stats = perf_monitor.get_statistics()

	return {"obs": [
		stats.physics_frame_time_ms / 11.11,
		stats.chunk_generation_avg_ms / 5.0,
		float(stats.active_chunk_count) / 512.0,
		stats.voxel_memory_mb / 2048.0,
	]}

func get_reward() -> float:
	var reward = 0.0
	var stats = perf_monitor.get_statistics()

	# REWARD edge cases (we WANT to find problems)
	if stats.physics_frame_time_ms > 11.11:
		reward += 10.0  # Found a performance issue!

	if stats.chunk_generation_max_ms > 5.0:
		reward += 5.0  # Found slow chunk generation!

	if stats.active_chunk_count > 400:
		reward += 2.0  # Stress testing chunk count

	# Encourage exploring different areas
	reward += player_body.velocity.length() * 0.1

	return reward

func get_action_space() -> Dictionary:
	return {
		"move_direction": {"size": 2, "action_type": "continuous"},  # XZ movement
		"move_speed": {"size": 1, "action_type": "continuous"},  # 0-20 m/s
		"teleport_distance": {"size": 1, "action_type": "continuous"},  # Jump to new area
	}
```

**Training:**

```python
# rl_training/train_voxel_stress.py
# ... similar to train_vr_locomotion.py but with:

model = PPO(
	"MlpPolicy",
	env,
	ent_coef=0.1,  # High entropy = more exploration
	# ... other params
)
```

**Usage:**
- Run nightly to find performance regressions
- Identify worst-case voxel generation patterns
- Test memory leaks over long runs

---

### 8.2 Spacecraft Landing Automation

**Scenario:** Train agent to land spacecraft safely

**Implementation:**

```gdscript
# rl_training/spacecraft_landing_controller.gd
extends AIController3D
class_name SpacecraftLandingController

@onready var spacecraft: RigidBody3D = get_parent()
@onready var landing_pad: Node3D = get_node("../LandingPad")

# Raycasts for terrain sensing
var terrain_raycast: RayCast3D

func _ready():
	terrain_raycast = RayCast3D.new()
	terrain_raycast.target_position = Vector3(0, -100, 0)
	terrain_raycast.enabled = true
	add_child(terrain_raycast)
	reset()

func get_obs() -> Dictionary:
	# Spacecraft state
	var altitude = spacecraft.global_position.y
	var velocity = spacecraft.linear_velocity
	var rotation = spacecraft.global_rotation
	var angular_vel = spacecraft.angular_velocity

	# Landing pad direction
	var to_pad = landing_pad.global_position - spacecraft.global_position
	var pad_distance = to_pad.length()
	var pad_direction = to_pad.normalized()

	# Terrain sensing
	var terrain_distance = 1000.0
	if terrain_raycast.is_colliding():
		terrain_distance = terrain_raycast.get_collision_point().distance_to(spacecraft.global_position)

	return {"obs": [
		# Position/velocity (9)
		altitude / 1000.0,  # Normalize to ~1km
		velocity.x / 50.0,  # Normalize to ~50 m/s max
		velocity.y / 50.0,
		velocity.z / 50.0,
		angular_vel.x,
		angular_vel.y,
		angular_vel.z,
		rotation.x / PI,
		rotation.z / PI,  # Roll/pitch (yaw doesn't matter for landing)

		# Target info (4)
		pad_direction.x,
		pad_direction.y,
		pad_direction.z,
		pad_distance / 1000.0,

		# Terrain (1)
		terrain_distance / 100.0,  # Normalize to ~100m
	]}
	# Total: 14 observations

func get_action_space() -> Dictionary:
	return {
		"thrust_x": {"size": 1, "action_type": "continuous"},  # -1 to 1
		"thrust_y": {"size": 1, "action_type": "continuous"},  # Main engine (0 to 1)
		"thrust_z": {"size": 1, "action_type": "continuous"},
		"rcs_pitch": {"size": 1, "action_type": "continuous"},
		"rcs_roll": {"size": 1, "action_type": "continuous"},
	}

func set_action(action) -> void:
	# Apply thrust
	var thrust_dir = Vector3(
		action["thrust_x"][0],
		clamp(action["thrust_y"][0], 0, 1),  # Only upward thrust
		action["thrust_z"][0]
	)
	thrust_dir = thrust_dir.limit_length(1.0)

	var thrust_force = thrust_dir * 10000.0  # Newtons
	spacecraft.apply_central_force(spacecraft.global_transform.basis * thrust_force)

	# Apply RCS rotation
	var torque = Vector3(
		action["rcs_pitch"][0] * 500.0,
		0,
		action["rcs_roll"][0] * 500.0
	)
	spacecraft.apply_torque(spacecraft.global_transform.basis * torque)

func get_reward() -> float:
	var reward = 0.0

	# Shaping: Reward for getting closer to pad
	var distance = spacecraft.global_position.distance_to(landing_pad.global_position)
	reward += (1.0 / max(distance, 1.0)) * 0.1

	# Shaping: Reward for low descent rate near ground
	if spacecraft.global_position.y < 50:
		var descent_rate = abs(spacecraft.linear_velocity.y)
		if descent_rate < 5.0:
			reward += 0.5

	# Terminal rewards
	if _check_landed():
		var touchdown_velocity = spacecraft.linear_velocity.length()

		if touchdown_velocity < 2.0:  # Soft landing
			reward += 50.0
			print("[RL] SOFT LANDING SUCCESS!")
		elif touchdown_velocity < 5.0:  # Hard landing (survived)
			reward += 10.0
			print("[RL] Hard landing (survived)")
		else:  # Crash
			reward -= 50.0
			print("[RL] CRASH")

		# Bonus for landing on pad (vs. anywhere)
		var landing_offset = spacecraft.global_position.distance_to(landing_pad.global_position)
		if landing_offset < 2.0:
			reward += 20.0  # Precision bonus

		done = true

	# Timeout penalty
	if episode_steps > 9000:  # 100 seconds at 90 fps
		reward -= 20.0
		done = true

	return reward

func _check_landed() -> bool:
	# Check if spacecraft is on ground and nearly stationary
	return (
		terrain_raycast.is_colliding() and
		terrain_raycast.get_collision_point().y > spacecraft.global_position.y - 5.0
	)

func reset() -> void:
	# Randomize start conditions
	var start_altitude = randf_range(500, 1000)
	var start_offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))

	spacecraft.global_position = Vector3(
		landing_pad.global_position.x + start_offset.x,
		start_altitude,
		landing_pad.global_position.z + start_offset.y
	)

	spacecraft.linear_velocity = Vector3(
		randf_range(-10, 10),
		randf_range(-20, 0),  # Falling
		randf_range(-10, 10)
	)
	spacecraft.angular_velocity = Vector3.ZERO
	spacecraft.global_rotation = Vector3.ZERO

	episode_steps = 0
	done = false
```

**Training:**

```bash
python rl_training/train_spacecraft_landing.py --timesteps 500000 --num_envs 8
```

**Result:** Trained agent can land spacecraft autonomously, useful for:
- Testing spacecraft physics under various conditions
- Validating thrust/torque calculations
- Stress-testing collision detection
- Automated regression testing after physics changes

---

### 8.3 Multi-Agent VR Interactions

**Scenario:** Test multi-player VR interactions (future feature)

**Implementation:**

```gdscript
# rl_training/multi_agent_controller.gd
extends AIController3D
class_name MultiAgentVRController

var other_agents: Array[Node3D] = []

func get_obs() -> Dictionary:
	var obs_vector = []

	# Self state
	obs_vector.append_array([
		player_body.global_position.x / 10.0,
		player_body.global_position.z / 10.0,
		player_body.velocity.length() / 5.0,
	])

	# Other agents (up to 3 nearest)
	var nearest = _get_nearest_agents(3)
	for agent in nearest:
		var to_agent = agent.global_position - player_body.global_position
		obs_vector.append_array([
			to_agent.x / 20.0,
			to_agent.z / 20.0,
			to_agent.length() / 20.0,
		])

	# Pad observations if fewer than 3 agents
	while len(obs_vector) < 3 + 3*3:
		obs_vector.append(0.0)

	return {"obs": obs_vector}

func get_reward() -> float:
	# Reward for proximity to other agents (cooperation)
	# OR penalty for collisions (adversarial)
	# Depends on training objective
	pass
```

**Training:**

```python
# Use multi-agent RL library (e.g., Ray RLLib)
from ray.rllib.agents.ppo import PPOTrainer

config = {
	"multiagent": {
		"policies": {
			"agent_policy": (None, obs_space, action_space, {}),
		},
		"policy_mapping_fn": lambda agent_id: "agent_policy",
	},
	# ... other config
}

trainer = PPOTrainer(config=config, env=MultiAgentGodotEnv)
```

---

### 8.4 Automated Bug Reproduction

**Scenario:** Train agent to reproduce specific bugs

**Example: Reproduce voxel chunk loading race condition**

```gdscript
# rl_training/bug_reproduction_controller.gd
extends AIController3D
class_name BugReproductionController

var target_bug: String = "voxel_chunk_race_condition"
var bug_reproduced: bool = false

func get_reward() -> float:
	var reward = 0.0

	# Detect specific bug signature
	match target_bug:
		"voxel_chunk_race_condition":
			# Check for error in console logs
			if _check_console_for_error("chunk generation race condition"):
				reward += 100.0  # Big reward for reproducing bug!
				bug_reproduced = true
				done = true

			# Shaping: Reward for rapid direction changes (likely to trigger)
			var angular_velocity = player_body.angular_velocity.length()
			if angular_velocity > 2.0:
				reward += 1.0

	return reward

func _check_console_for_error(error_substring: String) -> bool:
	# Would need integration with Godot logging system
	# Or check VoxelPerformanceMonitor warnings
	pass
```

**Usage:**
- CI runs this agent nightly
- If bug reproduced, capture full state
- Generate detailed reproduction steps
- Attach to bug report

---

## 9. Troubleshooting

### Common Issues and Solutions

#### Issue: TCP Connection Failed

**Symptoms:**
```
[godot_rl] ERROR: Could not connect to Godot instance on port 11008
Connection refused
```

**Solutions:**

1. **Verify Godot is running:**
   ```bash
   # Check if Godot process is active
   ps aux | grep -i godot  # Linux/Mac
   tasklist | findstr -i godot  # Windows
   ```

2. **Check Sync node is enabled:**
   - In Godot editor: Verify `GodotRLAgentsSync` is in autoload list
   - Check console for: `[Godot RL Agents] Sync node initialized`

3. **Port conflict:**
   - Default port: 11008
   - Change in Python: `StableBaselinesGodotEnv(..., port=11009)`
   - Change in Godot: `sync.port = 11009`
   - Check port usage: `netstat -an | grep 11008`  # Linux/Mac
   - Windows: `netstat -an | findstr 11008`

4. **Firewall blocking:**
   ```bash
   # Windows: Allow Python through firewall
   # Control Panel → Windows Defender Firewall → Allow an app
   # Add python.exe from .venv/Scripts/

   # Linux: Open port
   sudo ufw allow 11008/tcp
   ```

---

#### Issue: Training Not Starting

**Symptoms:**
```
[RL Training] Model created. Starting training loop...
[Waiting for environment...]
(hangs indefinitely)
```

**Solutions:**

1. **Check Godot scene:**
   - Ensure scene loads without errors in Godot editor
   - Press F5 to test scene manually first
   - Check console for errors

2. **Verify AIController is attached:**
   ```gdscript
   # In scene tree, ensure AIController3D is child of player node
   # Script should extend AIController3D
   ```

3. **Test with visualization:**
   ```bash
   # Add --viz flag to see what's happening
   python rl_training/train_vr_locomotion.py --timesteps 100 --num_envs 1 --viz
   ```

4. **Check action/observation space mismatch:**
   ```gdscript
   # Ensure get_obs() returns correct number of values
   func get_obs() -> Dictionary:
	   var obs = [1.0, 2.0, 3.0]  # Length must be consistent!
	   return {"obs": obs}
   ```

---

#### Issue: Slow Training Performance

**Symptoms:**
- Training FPS < 100
- Episodes take very long
- High CPU usage

**Solutions:**

1. **Increase simulation speed:**
   ```gdscript
   # In Sync node configuration
   sync.speed_up = 16  # Run 16x faster than real-time
   sync.action_repeat = 8  # Execute each action for 8 frames
   ```

2. **Reduce rendering overhead:**
   - Train without visualization (`--viz` flag off)
   - Use headless Godot build (if VR not required)
   - Reduce scene complexity (disable post-processing, particles)

3. **Optimize observation space:**
   ```gdscript
   # SLOW: Raycasting many times per frame
   # FAST: Cache raycast results, update less frequently

   var raycast_cache: Array = []
   var cache_refresh_counter: int = 0

   func get_obs() -> Dictionary:
	   cache_refresh_counter += 1
	   if cache_refresh_counter >= 10:  # Refresh every 10 frames
		   raycast_cache = _do_expensive_raycasts()
		   cache_refresh_counter = 0

	   return {"obs": raycast_cache}
   ```

4. **Use parallel environments:**
   ```bash
   # Train with more parallel environments to utilize CPU cores
   python rl_training/train_vr_locomotion.py --num_envs 8
   ```

---

#### Issue: Agent Not Learning (Reward Not Increasing)

**Symptoms:**
- `ep_rew_mean` stays flat or decreases
- Agent behavior is random after many timesteps

**Solutions:**

1. **Check reward function:**
   ```gdscript
   # COMMON MISTAKE: Reward too sparse
   func get_reward() -> float:
	   if waypoint_reached:
		   return 100.0  # Only reward on success
	   return 0.0  # Agent gets no feedback until success (bad!)

   # BETTER: Reward shaping
   func get_reward() -> float:
	   var reward = 0.0
	   reward += 0.01  # Survival bonus
	   reward += (1.0 / distance_to_goal) * 0.1  # Progress bonus
	   if waypoint_reached:
		   reward += 100.0  # Terminal reward
	   return reward
   ```

2. **Verify observations are meaningful:**
   ```gdscript
   # Print observations during training to verify values
   func get_obs() -> Dictionary:
	   var obs = [player_pos.x, player_pos.z, velocity.x, velocity.z]
	   print("[RL OBS] ", obs)  # Check values are in reasonable range
	   return {"obs": obs}
   ```

3. **Tune hyperparameters:**
   ```python
   # Try different learning rates
   model = PPO("MlpPolicy", env, learning_rate=1e-3)  # Default: 3e-4

   # Increase exploration
   model = PPO("MlpPolicy", env, ent_coef=0.05)  # Default: 0.01

   # Adjust network size
   model = PPO("MlpPolicy", env, policy_kwargs=dict(net_arch=[128, 128]))
   ```

4. **Check for NaN/Inf in observations:**
   ```gdscript
   func get_obs() -> Dictionary:
	   var obs = [...]

	   # Clamp all values to safe range
	   for i in range(len(obs)):
		   if is_nan(obs[i]) or is_inf(obs[i]):
			   push_error("[RL] NaN/Inf in observation index %d" % i)
			   obs[i] = 0.0
		   obs[i] = clamp(obs[i], -10.0, 10.0)

	   return {"obs": obs}
   ```

---

#### Issue: ONNX Export/Inference Not Working

**Symptoms:**
```
[ERROR] ONNX model not found
[ERROR] ONNXInference requires Godot Mono build
```

**Solutions:**

1. **Use Godot Mono build:**
   - Download Godot Mono/.NET version from godotengine.org
   - Install .NET SDK: https://dotnet.microsoft.com/en-us/download

2. **Export model to ONNX:**
   ```python
   # After training
   from godot_rl.core.utils import export_to_onnx

   export_to_onnx(
	   model,
	   output_path="rl_training/models/vr_locomotion_v1.onnx",
	   input_size=12,  # Match observation space size
   )
   ```

3. **Configure Sync node for inference:**
   ```gdscript
   # In Godot scene
   sync.control_mode = sync.ControlModes.ONNX_INFERENCE
   sync.onnx_model_path = "res://rl_training/models/vr_locomotion_v1.onnx"
   ```

4. **Verify ONNX runtime installed:**
   ```bash
   # Install ONNX runtime for .NET
   dotnet add package Microsoft.ML.OnnxRuntime
   ```

---

#### Issue: VR Headset Required for Training

**Symptoms:**
- Training fails without VR headset connected
- XR initialization errors

**Solutions:**

1. **Mock VR input for headless training:**
   ```gdscript
   # In AIController
   func _ready():
	   # Disable VR if running in training mode
	   if get_node_or_null("/root/GodotRLAgentsSync"):
		   _disable_xr_requirement()

   func _disable_xr_requirement():
	   # Use mock camera instead of XR camera
	   var mock_camera = Camera3D.new()
	   mock_camera.global_position = Vector3(0, 1.6, 0)  # Head height
	   add_child(mock_camera)

	   # Disable XR initialization
	   var xr_interface = XRServer.find_interface("OpenXR")
	   if xr_interface:
		   xr_interface.uninitialize()
   ```

2. **Use dedicated VR test machine:**
   - Set up a separate machine with VR headset for RL training
   - Use GitHub Actions self-hosted runner with VR hardware

3. **Hybrid approach:**
   - Basic training: Headless (no VR)
   - Final validation: VR hardware

---

## 10. Performance Optimization

### Training Performance

**Goal:** Maximize training speed (timesteps/second)

#### Optimization 1: Parallel Environments

```bash
# Scale from 1 to N parallel environments
python rl_training/train_vr_locomotion.py --num_envs 1   # ~500 steps/sec
python rl_training/train_vr_locomotion.py --num_envs 4   # ~1800 steps/sec
python rl_training/train_vr_locomotion.py --num_envs 8   # ~3200 steps/sec
```

**Diminishing returns:** Beyond 8-16 environments, gains plateau due to Python GIL and CPU contention.

#### Optimization 2: Simulation Speed-Up

```gdscript
# In Sync node configuration
sync.speed_up = 8  # 8x faster than real-time (default)
sync.speed_up = 16  # 16x faster (if stable)
sync.speed_up = 32  # 32x faster (may cause physics instabilities)
```

**Trade-off:** Higher speed-up may cause physics to behave differently than production (e.g., tunneling, jitter).

**Recommendation:** Test at 1x speed periodically to verify learned behavior transfers.

#### Optimization 3: Action Repeat

```gdscript
sync.action_repeat = 1  # Execute each action for 1 frame (default)
sync.action_repeat = 4  # Execute each action for 4 frames (4x faster training)
sync.action_repeat = 8  # 8x faster (coarser control)
```

**Trade-off:** Higher action repeat reduces control frequency, may not learn fine-grained behaviors.

**Use case:** Use high action repeat (8) for initial training, then fine-tune with lower repeat (1-2).

#### Optimization 4: Observation Space Reduction

```gdscript
# SLOW: 100+ observations
func get_obs() -> Dictionary:
	var obs = []
	for i in range(100):
		obs.append(raycast_sensors[i].get_collision_distance())
	return {"obs": obs}

# FAST: 10-20 observations
func get_obs() -> Dictionary:
	# Use only most informative observations
	var obs = [
		player_pos.x,
		player_pos.z,
		velocity.length(),
		heading_to_goal,
		distance_to_goal,
	]
	return {"obs": obs}
```

**Guideline:** Keep observation space < 50 dimensions for faster training.

#### Optimization 5: Vectorized Environments

```python
# Use SubprocVecEnv (multi-process) for CPU-bound tasks
from stable_baselines3.common.vec_env import SubprocVecEnv

env = SubprocVecEnv([create_env(i) for i in range(8)])

# OR use DummyVecEnv (single-process) if Godot is the bottleneck
from stable_baselines3.common.vec_env import DummyVecEnv

env = DummyVecEnv([create_env(i) for i in range(8)])
```

**Recommendation:** SubprocVecEnv for CPU-intensive tasks, DummyVecEnv for I/O-bound or debugging.

---

### Memory Optimization

**Goal:** Reduce memory usage during training

#### Optimization 1: Limit Replay Buffer Size

```python
# PPO doesn't use replay buffer, but off-policy algorithms do:
from stable_baselines3 import SAC

model = SAC(
	"MlpPolicy",
	env,
	buffer_size=10_000,  # Small buffer (default: 1M)
)
```

#### Optimization 2: Reduce Network Size

```python
# Smaller neural network = less memory
model = PPO(
	"MlpPolicy",
	env,
	policy_kwargs=dict(
		net_arch=[64, 64]  # Small network (default: [256, 256])
	)
)
```

**Trade-off:** Smaller network may have less capacity to learn complex policies.

#### Optimization 3: Godot Scene Optimization

```gdscript
# Remove unnecessary nodes during training
func _ready():
	if OS.has_feature("training"):  # Custom feature flag
		# Disable rendering-heavy nodes
		$ParticleEffects.queue_free()
		$DetailMeshes.queue_free()

		# Reduce physics collision layers
		$ComplexCollider.collision_layer = 0
		$ComplexCollider.collision_mask = 0
```

---

### Inference Performance

**Goal:** Run trained agent at 90 FPS in VR production build

#### Optimization 1: ONNX Quantization

```python
# Quantize ONNX model (8-bit vs. 32-bit floating point)
import onnx
from onnxruntime.quantization import quantize_dynamic

model_fp32 = "vr_locomotion_v1.onnx"
model_int8 = "vr_locomotion_v1_quantized.onnx"

quantize_dynamic(
	model_fp32,
	model_int8,
	weight_type="int8"
)

# Result: ~4x smaller, ~2x faster inference
```

#### Optimization 2: Reduce Inference Frequency

```gdscript
# Don't run inference every frame (90 fps)
var inference_counter: int = 0
var action_cache: Dictionary = {}

func _physics_process(delta):
	inference_counter += 1

	if inference_counter >= 3:  # Run inference every 3 frames (30 Hz)
		action_cache = ai_controller.get_action()
		inference_counter = 0

	_apply_action(action_cache)
```

**Result:** 3x reduction in inference calls, minimal impact on behavior quality.

#### Optimization 3: Use Simpler Policy for Deployment

```python
# Train with large network for best performance
model = PPO("MlpPolicy", env, policy_kwargs=dict(net_arch=[256, 256]))

# Distill into smaller network for deployment
small_model = PPO("MlpPolicy", env, policy_kwargs=dict(net_arch=[64, 64]))

# Train small model to mimic large model (knowledge distillation)
# ... (implementation left as exercise)
```

---

### Profiling Tools

**1. Godot Profiler:**
- Editor → Debug → Profiler
- Check "Physics" and "Scripts" to see AIController overhead

**2. Python Profiler:**
```python
import cProfile

cProfile.run('train(timesteps=1000)', 'training_profile.prof')

# Analyze with snakeviz
pip install snakeviz
snakeviz training_profile.prof
```

**3. TensorBoard:**
```bash
tensorboard --logdir=rl_training/logs

# Monitor:
# - time/fps (training speed)
# - rollout/ep_len_mean (episode efficiency)
```

---

## Conclusion

You now have a comprehensive blueprint for integrating Godot RL Agents into SpaceTime VR. Key takeaways:

**Benefits:**
- Automated playtesting and regression detection
- 24/7 testing without human testers
- Discover edge cases and performance issues
- Validate VR comfort and physics systems

**Next Steps:**
1. Install Godot RL Agents plugin and Python package
2. Implement first agent (VR locomotion test)
3. Train baseline model (100k timesteps)
4. Integrate with CI/CD pipeline
5. Expand to additional test scenarios (voxel stress, spacecraft landing)

**Resources:**
- GitHub: https://github.com/edbeeching/godot_rl_agents
- Course: https://huggingface.co/learn/deep-rl-course/en/unitbonus3/godotrl
- Discord: Join Godot RL Agents community for support

**SpaceTime-Specific Integration:**
- VoxelPerformanceMonitor: Track performance during training
- HTTP API (port 8080): Control training remotely
- Existing test infrastructure: Combine RL with GdUnit4 and Python runtime tests
- VR scenes: vr_locomotion_test.tscn, vr_tracking_test.tscn ready for RL integration

**Questions or Issues?**
- Check Troubleshooting section (Section 9)
- Review existing SpaceTime docs: `docs/INDEX.md`
- Consult VR Testing Workflow: `docs/VR_TESTING_WORKFLOW.md`

---

**Document Version:** 1.0
**Compatibility:** Godot 4.5.1+, Python 3.8+, godot-rl 0.6+
**Tested On:** Windows 10/11, Ubuntu 22.04

**Maintainers:** SpaceTime VR Development Team
**Last Review:** 2025-12-09
