# Installation Guide for SpaceTime VR ML Training

Quick installation guide for setting up the machine learning training environment.

## Prerequisites

- Python 3.8 or higher
- Godot 4.5+ with SpaceTime project
- 8GB+ RAM (16GB recommended for multi-environment training)
- Optional: NVIDIA GPU with CUDA for faster training

## Installation Steps

### 1. Create Virtual Environment

```bash
# Navigate to project root
cd C:/Ignotus

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate

# Linux/Mac:
source .venv/bin/activate

# Verify activation (should show .venv path)
which python
```

### 2. Install Dependencies

```bash
# Install ML training dependencies
pip install -r scripts/ml/requirements.txt

# This will install:
# - gymnasium (RL environment framework)
# - stable-baselines3 (PPO algorithm)
# - torch (deep learning)
# - tensorboard (logging)
# - numpy, requests, etc.
```

### 3. Verify Installation

```bash
# Run setup test script
python scripts/ml/test_training_setup.py

# This will check:
# - Python version
# - Dependencies installed
# - Godot connection
# - Training scene availability
# - GPU availability
```

### 4. Start Godot with HTTP API

```bash
# Windows
./restart_godot_with_debug.bat

# OR manually:
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" --editor

# Verify HTTP API is running
curl http://127.0.0.1:8080/health
```

### 5. Run Quick Test

```bash
# Quick test training (10,000 timesteps)
python scripts/ml/train_vr_navigation.py --preset quick_test --verbose

# This will verify the full training pipeline works
```

## Optional: GPU Setup

### NVIDIA GPU with CUDA

If you have an NVIDIA GPU, install CUDA-enabled PyTorch:

```bash
# Uninstall CPU-only torch
pip uninstall torch

# Install CUDA version (CUDA 11.8)
pip install torch --index-url https://download.pytorch.org/whl/cu118

# Or for CUDA 12.1
pip install torch --index-url https://download.pytorch.org/whl/cu121

# Verify GPU is detected
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

## Troubleshooting

### Issue: "gymnasium not installed"

**Solution:**
```bash
pip install gymnasium
```

### Issue: "stable-baselines3 not installed"

**Solution:**
```bash
pip install stable-baselines3
```

### Issue: "Cannot connect to Godot HTTP API"

**Solutions:**
1. Check Godot is running: `curl http://127.0.0.1:8080/health`
2. Start Godot with `./restart_godot_with_debug.bat`
3. Verify port 8080 is not blocked by firewall
4. Check CLAUDE.md for HTTP API status

### Issue: Virtual environment activation fails

**Solution (Windows):**
```powershell
# PowerShell execution policy may need to be changed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then try activating again
.venv\Scripts\activate
```

### Issue: Out of memory during training

**Solutions:**
1. Reduce `num_environments` in config (try 1 or 2)
2. Reduce `batch_size` (try 32 or 16)
3. Close other applications
4. Use quick_test preset for initial testing

### Issue: Training is very slow

**Solutions:**
1. Check GPU is being used: `python -c "import torch; print(torch.cuda.is_available())"`
2. Install CUDA-enabled PyTorch (see GPU Setup above)
3. Reduce `num_ray_sensors` in config
4. Use headless Godot mode (if implemented)

## Verification Checklist

Before starting full training, verify:

- [ ] Virtual environment activated (`.venv` in prompt)
- [ ] All dependencies installed (`pip list` shows gymnasium, stable-baselines3, torch, etc.)
- [ ] Godot running with HTTP API (`curl http://127.0.0.1:8080/health` succeeds)
- [ ] Training scene exists (`res://scenes/features/vr_locomotion_test.tscn`)
- [ ] Setup test passes (`python scripts/ml/test_training_setup.py`)
- [ ] Quick test completes (`python scripts/ml/train_vr_navigation.py --preset quick_test`)

## Next Steps

After successful installation:

1. Review `scripts/ml/README.md` for training options
2. Configure training parameters in custom config file
3. Run full training session
4. Monitor with TensorBoard: `tensorboard --logdir=user://ml_training/logs`
5. Evaluate trained models

## Additional Resources

- **StableBaselines3 Installation**: https://stable-baselines3.readthedocs.io/en/master/guide/install.html
- **PyTorch Installation**: https://pytorch.org/get-started/locally/
- **Gymnasium Documentation**: https://gymnasium.farama.org/
- **CUDA Toolkit**: https://developer.nvidia.com/cuda-downloads

## Support

For installation issues:
1. Check `scripts/ml/README.md` troubleshooting section
2. Run `python scripts/ml/test_training_setup.py` for diagnostic info
3. Review error messages carefully
4. Check CLAUDE.md for project-specific setup
