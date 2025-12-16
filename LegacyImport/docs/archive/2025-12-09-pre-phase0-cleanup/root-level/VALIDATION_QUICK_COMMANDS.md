# Validation Quick Reference Commands
**Project:** SpaceTime VR
**Purpose:** Quick commands to validate all fixes applied

---

## 1. Verify Null Guards Applied

```bash
# Count null guards in celestial_body.gd
grep -c "NULL GUARD" scripts/celestial/celestial_body.gd
# Expected: 14

# Verify is_instance_valid usage
grep -c "is_instance_valid" scripts/celestial/celestial_body.gd
# Expected: 14+

# Check for unsafe patterns (should return 0 or minimal results)
grep "model != null" scripts/celestial/celestial_body.gd
grep "parent_body != null" scripts/celestial/celestial_body.gd
```

---

## 2. Verify Performance Optimization

```bash
# Check spatial partitioning implementation
grep -c "use_spatial_partitioning" scripts/core/physics_engine.gd
# Expected: 3+

# Verify grid implementation
grep -c "_spatial_grid" scripts/core/physics_engine.gd
# Expected: 5+
```

---

## 3. Verify Compilation Status

```bash
# Parse check all files (from project root)
godot --headless --check-only --path "C:/godot"

# Check specific files
godot --headless --script scripts/celestial/celestial_body.gd --check-only
godot --headless --script scripts/core/physics_engine.gd --check-only
```

---

## 4. Run Test Suites

```bash
# GDScript unit tests
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/

# Python integration tests
cd tests
python test_runner.py

# Health monitoring
python health_monitor.py
```

---

## 5. Verify Security Framework

```bash
# Check if Godot is running with debug services
curl http://127.0.0.1:8080/status

# Test TokenManager
curl -X POST http://127.0.0.1:8080/auth/token/generate
```

---

## 6. Performance Benchmarks

```bash
# Monitor real-time telemetry
python telemetry_client.py

# Check physics statistics
curl http://127.0.0.1:8080/physics/statistics
```

---

## 7. Start Godot with Debug Services

```bash
# Windows (recommended)
./restart_godot_with_debug.bat

# Manual start
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

---

## 8. Execute Production Validation

```bash
# Run automated checks (240 checks)
cd tests/production_readiness
python automated_validation.py --verbose
```

---

## Report Locations

- **Full Report:** C:/godot/FIXES_APPLIED_REPORT.md (32KB, 1006 lines)
- **Executive Summary:** C:/godot/VALIDATION_EXECUTIVE_SUMMARY.md (10KB)
- **Quick Commands:** C:/godot/VALIDATION_QUICK_COMMANDS.md
- **System Health:** C:/godot/docs/COMPREHENSIVE_SYSTEM_HEALTH_REPORT.md

---

**Last Updated:** 2025-12-03
