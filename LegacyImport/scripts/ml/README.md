# SpaceTime VR Machine Learning Training

This directory contains Python scripts for training reinforcement learning agents in the SpaceTime VR environment using Godot RL integration.

## Overview

The ML training system enables AI agents to learn VR locomotion, navigation, and interaction tasks through reinforcement learning. It integrates with Godot's HTTP API for environment control and provides a complete training pipeline from observation processing to model deployment.

## Files

### Core Training Scripts

- **`train_vr_navigation.py`** - Main training script for VR navigation agents
  - Uses StableBaselines3 PPO algorithm
  - Connects to Godot via HTTP API
  - Supports training, evaluation, and checkpointing
  - TensorBoard logging integration

- **`rl_config.py`** - Configuration management system
  - Dataclass-based configuration
  - Preset configurations for common scenarios
  - JSON serialization/deserialization
  - Hyperparameter organization

- **`rl_utils.py`** - Utility functions and classes
  - Observation preprocessing
  - Action postprocessing
  - Custom reward calculations
  - Godot HTTP API client
  - Performance monitoring
  - Training metrics

## Installation

### Prerequisites

1. **Python 3.8+** with virtual environment
2. **Godot 4.5+** running with HTTP API enabled
3. **SpaceTime project** with vr_locomotion_test scene

### Install Dependencies

```bash
# Create virtual environment
python -m venv .venv

# Activate (Windows)
.venv\Scripts\activate

# Activate (Linux/Mac)
source .venv/bin/activate

# Install required packages
pip install gymnasium stable-baselines3 tensorboard numpy requests torch
```

### Optional Dependencies

```bash
# For advanced features
pip install godot-rl websockets psutil matplotlib
```

## Quick Start

### 1. Start Godot with HTTP API

```bash
# Windows
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" --editor

# Or use the restart script
./restart_godot_with_debug.bat
```

Verify HTTP API is running:
```bash
curl http://127.0.0.1:8080/health
```

### 2. Run Quick Test Training

```bash
python scripts/ml/train_vr_navigation.py --preset quick_test --verbose
```

This will:
- Connect to Godot on port 8080
- Load the vr_locomotion_test scene
- Train for 10,000 timesteps
- Save checkpoints every 2,000 steps
- Log to TensorBoard

### 3. Monitor Training

Open TensorBoard to view training progress:
```bash
tensorboard --logdir=user://ml_training/logs
```

Then navigate to http://localhost:6006

### 4. Evaluate Trained Model

```bash
python scripts/ml/train_vr_navigation.py --eval user://ml_training/best_models/best_model.zip --episodes 20
```

## Training Configurations

### Preset Configurations

The system provides several preset configurations:

#### 1. Quick Test (`--preset quick_test`)
- **Purpose**: Fast debugging and testing
- **Timesteps**: 10,000
- **Episode Length**: 200 steps
- **Use Case**: Verify training pipeline works

#### 2. Full Training (`--preset full_training`)
- **Purpose**: Production training
- **Timesteps**: 5,000,000
- **Episode Length**: 1,000 steps
- **Use Case**: Train high-quality agents

#### 3. Curriculum Learning (`--preset curriculum_learning`)
- **Purpose**: Progressive difficulty training
- **Timesteps**: 3,000,000 (across 3 stages)
- **Stages**: Easy → Medium → Hard goals
- **Use Case**: Complex navigation tasks

#### 4. Comfort Optimized (`--preset comfort_optimized`)
- **Purpose**: VR comfort-focused training
- **Timesteps**: 1,000,000
- **Features**: Higher comfort rewards, smoother actions
- **Use Case**: Motion sickness-sensitive applications

### Custom Configuration

Create a custom JSON configuration:

```bash
# Generate example config
python scripts/ml/rl_config.py

# Edit example_config.json to your needs

# Train with custom config
python scripts/ml/train_vr_navigation.py --config example_config.json
```

Example custom configuration:
```json
{
  "network": {
    "policy": "MlpPolicy",
    "net_arch": [256, 256],
    "activation_fn": "relu"
  },
  "ppo": {
    "learning_rate": 0.0003,
    "batch_size": 64,
    "n_epochs": 10,
    "gamma": 0.99
  },
  "rewards": {
    "goal_reached": 100.0,
    "collision_penalty": -10.0,
    "comfort_bonus": 2.0
  },
  "training": {
    "total_timesteps": 1000000,
    "save_freq": 10000
  }
}
```

## Architecture

### Observation Space

The agent observes:

- **VR Camera** (13D)
  - Position (x, y, z)
  - Rotation (quaternion: x, y, z, w)
  - Velocity (x, y, z)
  - Angular velocity (x, y, z)

- **Ray Sensors** (16D)
  - 16 raycasts around player
  - Distance to nearest obstacle per ray
  - Range: 0 to 5 meters

- **Controllers** (12D)
  - Left/Right positions (3D each)
  - Left/Right velocities (3D each)

- **Goal Information** (7D)
  - Goal position (relative to player)
  - Goal distance (scalar)
  - Goal direction (unit vector)

**Total Observation Space**: 48D continuous

### Action Space

The agent outputs continuous control signals:

- **Horizontal Movement** [-1, 1] - Left/Right thumbstick
- **Vertical Movement** [-1, 1] - Forward/Back thumbstick
- **Rotation** [-1, 1] - Snap turn or smooth rotation

**Total Action Space**: 3D continuous

Actions are smoothed and scaled to:
- Max movement speed: 2.0 m/s
- Max rotation speed: 90 deg/s

### Reward Function

The agent receives rewards based on:

#### Positive Rewards
- **Goal Reached**: +100 (episode complete)
- **Progress**: +1 per meter closer to goal
- **Smooth Movement**: +0.1 for low acceleration
- **Comfort Bonus**: +2 for VR-comfortable movement

#### Negative Penalties
- **Collision**: -10 per collision
- **Fall**: -50 for falling off map
- **Timeout**: -20 for episode timeout
- **Teleport**: -1 per excessive teleport

### VR Comfort Optimization

The reward function includes VR comfort considerations:

1. **Smooth acceleration** - Penalizes sudden speed changes
2. **Limited rotation speed** - Reduces motion sickness
3. **Upright orientation** - Rewards keeping player level
4. **Action smoothing** - Exponential smoothing filter

Comfort score calculation:
```python
comfort = 1.0
comfort -= 0.3 if rotation_speed > 0.7
comfort -= 0.2 if speed > max_speed * 0.8
comfort -= 0.2 if abs(roll) > 0.3
```

## Integration with Godot

### HTTP API Communication

The training system communicates with Godot via the HTTP API:

#### Scene Management
```python
# Load training scene
client.load_scene("res://scenes/features/vr_locomotion_test.tscn")

# Get scene state
state = client.get_scene_state()
```

#### Performance Monitoring
```python
# Get performance metrics
perf = client.get_performance_metrics()
fps = perf["engine"]["fps"]
memory = perf["memory"]["static_memory_usage"]
```

#### Health Checks
```python
# Verify Godot is running
if client.health_check():
    print("Connected to Godot!")
```

### Required Godot Endpoints (To Be Implemented)

For full training integration, implement these custom endpoints:

1. **`GET /rl/observation`** - Get current agent observation
2. **`POST /rl/action`** - Send action to VR controller
3. **`POST /rl/reset`** - Reset environment to initial state
4. **`GET /rl/state`** - Get episode state (done, info, etc.)

Example Godot implementation:
```gdscript
# In vr_locomotion_test.gd
func get_rl_observation() -> Dictionary:
    return {
        "camera_position": $XROrigin3D/XRCamera3D.global_position,
        "camera_rotation": $XROrigin3D/XRCamera3D.quaternion,
        "camera_velocity": _camera_velocity,
        "ray_sensors": _get_ray_distances(),
        "goal_position": _goal.global_position - $XROrigin3D.global_position,
        "goal_distance": _goal.global_position.distance_to($XROrigin3D.global_position)
    }
```

## Training Workflow

### Standard Training Pipeline

1. **Setup**
   ```bash
   # Start Godot
   ./restart_godot_with_debug.bat

   # Verify connection
   curl http://127.0.0.1:8080/health
   ```

2. **Initial Training**
   ```bash
   # Quick test to verify everything works
   python scripts/ml/train_vr_navigation.py --preset quick_test --verbose
   ```

3. **Full Training**
   ```bash
   # Train for full duration
   python scripts/ml/train_vr_navigation.py --preset full_training
   ```

4. **Monitor Progress**
   ```bash
   # Open TensorBoard
   tensorboard --logdir=user://ml_training/logs
   ```

5. **Evaluation**
   ```bash
   # Test best model
   python scripts/ml/train_vr_navigation.py --eval user://ml_training/best_models/best_model.zip --episodes 50
   ```

6. **Export Model**
   ```bash
   # Copy best model for inference
   cp user://ml_training/best_models/best_model.zip models/vr_nav_v1.zip
   ```

### Resume Training

If training is interrupted, resume from checkpoint:

```bash
python scripts/ml/train_vr_navigation.py --resume user://ml_training/checkpoints/vr_nav_model_100000_steps.zip
```

### Hyperparameter Tuning

Experiment with different hyperparameters:

```bash
# Create base config
python scripts/ml/rl_config.py

# Edit example_config.json
# - Adjust learning_rate, batch_size, etc.
# - Modify reward weights
# - Change network architecture

# Train with new config
python scripts/ml/train_vr_navigation.py --config tuned_config.json --timesteps 1000000
```

## Performance Optimization

### Multi-Environment Training

Train with multiple parallel environments:

```json
{
  "environment": {
    "num_environments": 4
  },
  "training": {
    "num_workers": 4
  }
}
```

### GPU Acceleration

Ensure PyTorch uses GPU:
```python
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"Device: {torch.cuda.get_device_name(0)}")
```

### Memory Management

Monitor memory usage during training:
```bash
# Windows
tasklist /FI "IMAGENAME eq python.exe" /FO TABLE

# Linux
htop -p $(pgrep python)
```

## Troubleshooting

### Common Issues

#### 1. Cannot Connect to Godot
**Symptom**: `ERROR: Cannot connect to Godot HTTP API`

**Solutions**:
- Verify Godot is running: `curl http://127.0.0.1:8080/health`
- Check port 8080 is not blocked
- Ensure HTTP API is enabled (should be automatic in editor mode)
- Check CLAUDE.md for API status

#### 2. Scene Not Loading
**Symptom**: `ERROR: Failed to load scene res://...`

**Solutions**:
- Verify scene path is correct
- Check scene exists in project
- Ensure scene is in whitelist (see `config/scene_whitelist.json`)
- Check Godot console for errors

#### 3. Training Crashes
**Symptom**: Training stops with exception

**Solutions**:
- Check available RAM (requires ~4GB per environment)
- Reduce `num_environments` in config
- Lower `batch_size` in PPO config
- Enable verbose mode: `--verbose`

#### 4. Poor Training Performance
**Symptom**: Agent doesn't learn / reward stays flat

**Solutions**:
- Verify reward function is balanced
- Check observation normalization is enabled
- Increase `total_timesteps`
- Adjust `learning_rate` (try 1e-4 or 1e-3)
- Enable curriculum learning
- Review TensorBoard logs

#### 5. VR Comfort Issues
**Symptom**: Agent movements cause motion sickness

**Solutions**:
- Use `--preset comfort_optimized`
- Increase `comfort_bonus` reward weight
- Increase `action_smoothing` (0.2-0.4)
- Decrease `max_rotation_speed`
- Add rotation penalty to reward function

## Advanced Topics

### Curriculum Learning

Train agent with progressively harder tasks:

```python
config.training.use_curriculum = True
config.training.curriculum_stages = [
    {"name": "easy", "max_goal_distance": 10.0, "timesteps": 500_000},
    {"name": "medium", "max_goal_distance": 20.0, "timesteps": 1_000_000},
    {"name": "hard", "max_goal_distance": 30.0, "timesteps": 1_500_000}
]
```

### Custom Reward Functions

Modify `rl_utils.py` to add custom rewards:

```python
class RewardCalculator:
    def calculate_reward(self, observation, action, next_observation, done, info):
        reward = 0.0

        # Your custom reward logic here
        if custom_condition:
            reward += custom_reward

        return reward
```

### Multi-Task Training

Train agent on multiple tasks:

1. Create task-specific reward functions
2. Randomize task at episode start
3. Use task ID in observation space
4. Train single policy on all tasks

### Model Export for Inference

Export trained model for use in Godot:

```python
# In Python
model = PPO.load("best_model.zip")
model.save("exported_model.zip")

# In Godot (requires godot-rl addon)
# Load and use model for inference
var model = GodotRLModel.new()
model.load("user://models/exported_model.zip")
var action = model.predict(observation)
```

## Directory Structure

```
scripts/ml/
├── README.md                    # This file
├── train_vr_navigation.py       # Main training script
├── rl_config.py                 # Configuration system
├── rl_utils.py                  # Utility functions
└── __init__.py                  # Package initialization (optional)

user://ml_training/              # Training outputs (in Godot user dir)
├── checkpoints/                 # Model checkpoints
│   ├── vr_nav_model_10000_steps.zip
│   ├── vr_nav_model_20000_steps.zip
│   └── ...
├── best_models/                 # Best models from evaluation
│   └── best_model.zip
└── logs/                        # TensorBoard logs
    └── PPO_1/
        └── events.out.tfevents...
```

## Next Steps

1. **Implement Godot RL Endpoints** - Add custom endpoints to vr_locomotion_test scene
2. **Test with Real VR Hardware** - Validate training with actual headset
3. **Add More Training Scenarios** - Create additional scenes (obstacle courses, mazes)
4. **Implement Multi-Task Learning** - Train on diverse tasks simultaneously
5. **Deploy Trained Models** - Integrate trained agents into gameplay

## Resources

- **StableBaselines3 Docs**: https://stable-baselines3.readthedocs.io/
- **Godot RL**: https://github.com/edbeeching/godot_rl_agents
- **SpaceTime HTTP API**: See `CLAUDE.md` section "Godot HTTP API System"
- **RL Tutorial**: https://spinningup.openai.com/

## Support

For issues or questions:

1. Check `CLAUDE.md` for project-specific information
2. Review `CODE_QUALITY_REPORT.md` for known issues
3. Check TensorBoard logs for training diagnostics
4. Enable verbose mode for detailed output: `--verbose`

## License

Part of the SpaceTime VR project. See project LICENSE file.
