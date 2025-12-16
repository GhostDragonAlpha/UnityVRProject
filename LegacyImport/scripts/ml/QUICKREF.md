# Quick Reference - SpaceTime VR ML Training

Fast reference for common commands and configurations.

## Installation

```bash
# Setup (one-time)
python -m venv .venv
.venv\Scripts\activate
pip install -r scripts/ml/requirements.txt

# Verify
python scripts/ml/test_training_setup.py
```

## Training Commands

```bash
# Quick test (10k steps, ~5 min)
python scripts/ml/train_vr_navigation.py --preset quick_test --verbose

# Full training (1M steps, ~2-6 hours)
python scripts/ml/train_vr_navigation.py --preset full_training

# Curriculum learning (3M steps, progressive difficulty)
python scripts/ml/train_vr_navigation.py --preset curriculum_learning

# Comfort optimized (VR motion sickness reduction)
python scripts/ml/train_vr_navigation.py --preset comfort_optimized

# Custom config
python scripts/ml/train_vr_navigation.py --config my_config.json --timesteps 500000

# Resume from checkpoint
python scripts/ml/train_vr_navigation.py --resume user://ml_training/checkpoints/vr_nav_model_50000_steps.zip
```

## Monitoring

```bash
# TensorBoard
tensorboard --logdir=user://ml_training/logs

# Check Godot status
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/performance/metrics
```

## Evaluation

```bash
# Evaluate best model
python scripts/ml/train_vr_navigation.py --eval user://ml_training/best_models/best_model.zip --episodes 50

# Evaluate specific checkpoint
python scripts/ml/train_vr_navigation.py --eval user://ml_training/checkpoints/vr_nav_model_100000_steps.zip --episodes 20
```

## Configuration

### Create Config
```bash
# Generate example
python -c "from rl_config import RLConfig; RLConfig().save('my_config.json')"

# Edit my_config.json, then:
python scripts/ml/train_vr_navigation.py --config my_config.json
```

### Key Config Parameters

```json
{
  "ppo": {
    "learning_rate": 0.0003,     // Learning rate (lower = more stable)
    "batch_size": 64,             // Batch size (higher = smoother, slower)
    "n_epochs": 10                // Training epochs per rollout
  },
  "rewards": {
    "goal_reached": 100.0,        // Reward for reaching goal
    "collision_penalty": -10.0,   // Penalty for collision
    "comfort_bonus": 2.0          // VR comfort bonus
  },
  "training": {
    "total_timesteps": 1000000,   // Total training steps
    "save_freq": 10000,           // Checkpoint frequency
    "eval_freq": 5000             // Evaluation frequency
  },
  "environment": {
    "num_environments": 1,        // Parallel environments (1-8)
    "max_episode_steps": 1000     // Max steps per episode
  }
}
```

## Presets

| Preset | Timesteps | Duration | Use Case |
|--------|-----------|----------|----------|
| quick_test | 10,000 | 5-10 min | Testing pipeline |
| full_training | 5,000,000 | 3-6 hours | Production model |
| curriculum_learning | 3,000,000 | 2-4 hours | Complex tasks |
| comfort_optimized | 1,000,000 | 1-2 hours | VR comfort focus |

## Observation Space (48D)

- Camera: position (3), rotation (4), velocity (3), angular_vel (3)
- Rays: 16 distance sensors
- Controllers: left_pos (3), right_pos (3), left_vel (3), right_vel (3)
- Goal: position (3), distance (1), direction (3)

## Action Space (3D)

- move_horizontal: [-1, 1] (left/right)
- move_vertical: [-1, 1] (forward/back)
- rotate: [-1, 1] (turn)

## Reward Function

| Event | Reward | Notes |
|-------|--------|-------|
| Goal reached | +100 | Episode complete |
| Progress | +1/meter | Moving toward goal |
| Smooth movement | +0.1 | Low acceleration |
| VR comfort | +2 | Comfortable motion |
| Collision | -10 | Hit obstacle |
| Fall | -50 | Fell off map |
| Timeout | -20 | Episode too long |

## File Locations

```
scripts/ml/
├── train_vr_navigation.py   # Main training script
├── rl_config.py              # Configuration system
├── rl_utils.py               # Utilities
├── test_training_setup.py    # Setup verification
├── requirements.txt          # Dependencies
├── README.md                 # Full documentation
├── INSTALL.md                # Installation guide
├── OVERVIEW.md               # System overview
└── godot_rl_integration_example.gd  # Godot integration

user://ml_training/           # Training outputs
├── checkpoints/              # Model checkpoints
├── best_models/              # Best model from eval
└── logs/                     # TensorBoard logs
```

## Troubleshooting

### Can't Connect to Godot
```bash
# Start Godot
./restart_godot_with_debug.bat

# Verify
curl http://127.0.0.1:8080/health
```

### Import Error
```bash
# Activate venv
.venv\Scripts\activate

# Reinstall
pip install -r scripts/ml/requirements.txt
```

### Out of Memory
```json
{
  "environment": {"num_environments": 1},
  "ppo": {"batch_size": 32}
}
```

### Training Too Slow
```bash
# Check GPU
python -c "import torch; print(torch.cuda.is_available())"

# Install CUDA version
pip install torch --index-url https://download.pytorch.org/whl/cu118
```

### Poor Performance
- Increase total_timesteps (try 2-5M)
- Adjust learning_rate (try 1e-4 or 1e-3)
- Use curriculum_learning preset
- Check reward function is balanced

## Common Workflows

### Quick Iteration
```bash
# 1. Make config changes
nano my_config.json

# 2. Quick test
python scripts/ml/train_vr_navigation.py --config my_config.json --timesteps 10000 --verbose

# 3. Check TensorBoard
tensorboard --logdir=user://ml_training/logs

# 4. Adjust and repeat
```

### Production Training
```bash
# 1. Verify setup
python scripts/ml/test_training_setup.py

# 2. Start full training
python scripts/ml/train_vr_navigation.py --preset full_training

# 3. Monitor (in separate terminal)
tensorboard --logdir=user://ml_training/logs

# 4. Evaluate best model
python scripts/ml/train_vr_navigation.py --eval user://ml_training/best_models/best_model.zip --episodes 100
```

### Hyperparameter Tuning
```bash
# Test different learning rates
for lr in 0.0001 0.0003 0.001; do
  python -c "from rl_config import RLConfig; c = RLConfig(); c.ppo.learning_rate = $lr; c.save('config_lr_$lr.json')"
  python scripts/ml/train_vr_navigation.py --config config_lr_$lr.json --timesteps 100000
done

# Compare in TensorBoard
tensorboard --logdir=user://ml_training/logs
```

## Performance Metrics

### Training Speed
- CPU: ~200-500 steps/sec
- GPU: ~500-2000 steps/sec
- Multi-env (4): ~2000-8000 steps/sec

### Model Quality
- Random policy: ~-50 reward
- Trained (100k steps): ~20-40 reward
- Trained (1M steps): ~60-80 reward
- Expert (5M steps): ~80-95 reward

### Success Rate
- Quick test: 20-40%
- Full training: 60-80%
- Curriculum: 70-90%

## CLI Arguments

```
--config PATH           Custom config JSON file
--preset NAME           Use preset (quick_test, full_training, etc.)
--timesteps N           Override total timesteps
--resume PATH           Resume from checkpoint
--eval PATH             Evaluate model
--episodes N            Number of eval episodes
--verbose               Enable verbose output
--save-config PATH      Save config and exit
```

## Help

```bash
# Detailed help
python scripts/ml/train_vr_navigation.py --help

# Test suite
python scripts/ml/test_training_setup.py

# Documentation
cat scripts/ml/README.md
cat scripts/ml/INSTALL.md
```

## Tips

1. **Start small**: Use quick_test first
2. **Monitor early**: Open TensorBoard from start
3. **Save configs**: Save working configs for later
4. **Use GPU**: Training is 5-10x faster with GPU
5. **Checkpoint often**: Don't lose hours of training
6. **Evaluate regularly**: Check if agent is actually learning
7. **Adjust rewards**: Reward tuning is critical
8. **VR comfort**: Use comfort_optimized for end users

## Next Steps

1. Read: `scripts/ml/README.md`
2. Install: `scripts/ml/INSTALL.md`
3. Test: `python scripts/ml/test_training_setup.py`
4. Train: `python scripts/ml/train_vr_navigation.py --preset quick_test`
5. Evaluate: Check best model in `user://ml_training/best_models/`
