# SpaceTime VR - Deployment Troubleshooting Flowchart

**Version:** 1.0.0
**Date:** 2025-12-04

## Quick Reference Decision Tree

This document provides visual decision trees for rapid troubleshooting of common deployment issues.

---

## Decision Tree 1: API Not Responding

```
API NOT RESPONDING (Cannot connect to port 8080)
│
├─> Check if Godot process is running
│   │
│   ├─> NO → START
│   │   │
│   │   ├─> Check environment variables
│   │   │   ├─> GODOT_ENABLE_HTTP_API=1 ?
│   │   │   │   ├─> NO → Set GODOT_ENABLE_HTTP_API=1
│   │   │   │   └─> YES → Continue
│   │   │
│   │   ├─> Start Godot process
│   │   │   └─> ./deploy.sh or python godot_editor_server.py
│   │   │
│   │   └─> Wait 30 seconds, retry connection
│   │       ├─> SUCCESS → Problem solved
│   │       └─> FAIL → Check logs
│   │
│   └─> YES → Continue to port check
│
├─> Check if port 8080 is listening
│   │
│   ├─> Linux/Mac: netstat -an | grep 8080
│   ├─> Windows: netstat -an | findstr 8080
│   │
│   ├─> NOT LISTENING → INVESTIGATE
│   │   │
│   │   ├─> Check HttpApiServer autoload enabled
│   │   │   └─> project.godot line 24-25
│   │   │       ├─> Commented out? → Uncomment
│   │   │       └─> Enabled? → Continue
│   │   │
│   │   ├─> Check for port conflicts
│   │   │   └─> Another process using port 8080?
│   │   │       ├─> YES → Kill other process or change port
│   │   │       └─> NO → Continue
│   │   │
│   │   └─> Check Godot logs for errors
│   │       └─> Look for "HttpApiServer failed to start"
│   │           └─> See logs section below
│   │
│   └─> LISTENING → Continue to firewall check
│
├─> Check firewall
│   │
│   ├─> Test local connection: curl http://127.0.0.1:8080/health
│   │   ├─> SUCCESS → Firewall not blocking localhost
│   │   └─> FAIL → Continue
│   │
│   ├─> Check firewall rules
│   │   ├─> Linux: sudo iptables -L
│   │   ├─> Windows: Get-NetFirewallRule
│   │   └─> Mac: /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
│   │
│   └─> Add firewall exception for port 8080
│       └─> Retry connection
│
└─> Check bind address
    │
    ├─> HttpApiServer binds to 127.0.0.1 (localhost only)
    │   └─> Cannot access from other machines
    │       └─> EXPECTED BEHAVIOR (security feature)
    │
    └─> If remote access needed:
        ├─> Use reverse proxy (nginx, Apache)
        ├─> Set up SSH tunnel
        └─> DO NOT bind to 0.0.0.0 (security risk)

RESOLUTION: API should now be responding
VERIFY: curl http://127.0.0.1:8080/status
```

---

## Decision Tree 2: Authentication Failing

```
AUTHENTICATION FAILING (401 Unauthorized)
│
├─> JWT token present?
│   │
│   ├─> NO → GET TOKEN
│   │   │
│   │   ├─> Query /status endpoint (no auth required)
│   │   │   └─> curl http://127.0.0.1:8080/status
│   │   │
│   │   ├─> Extract jwt_token from response
│   │   │   └─> TOKEN=$(curl -s http://127.0.0.1:8080/status | jq -r '.jwt_token')
│   │   │
│   │   └─> Use token in Authorization header
│   │       └─> curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene
│   │
│   └─> YES → Validate token format
│
├─> Token format correct?
│   │
│   ├─> Format: "Authorization: Bearer <token>"
│   │   ├─> Missing "Bearer "? → Add "Bearer " prefix
│   │   ├─> Extra spaces? → Remove extra spaces
│   │   └─> Correct format? → Continue
│   │
│   └─> Token expired?
│       │
│       ├─> Tokens regenerated on server restart
│       │   └─> Get fresh token from /status
│       │
│       └─> Using old token? → Get new token
│
├─> Check security configuration
│   │
│   ├─> Query /status for security settings
│   │   └─> curl http://127.0.0.1:8080/status | jq '.security'
│   │
│   ├─> authentication_enabled: false?
│   │   └─> ISSUE: Authentication disabled
│   │       └─> Check environment configuration
│   │           └─> Production should have auth enabled
│   │
│   └─> authentication_enabled: true?
│       └─> Continue to endpoint check
│
└─> Check endpoint requirements
    │
    ├─> Some endpoints don't require auth:
    │   ├─> /health (public)
    │   ├─> /status (public)
    │   └─> /service-discovery (public)
    │
    ├─> Protected endpoints require auth:
    │   ├─> /scene/* (requires Bearer token)
    │   ├─> /performance (requires Bearer token)
    │   ├─> /admin/* (requires Bearer token + admin role)
    │   └─> /webhooks/* (requires Bearer token)
    │
    └─> Using correct endpoint?
        ├─> YES → Check logs for auth errors
        └─> NO → Use correct endpoint

RESOLUTION: Authentication should now work
VERIFY: curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene
```

---

## Decision Tree 3: Performance Issues (Low FPS)

```
LOW FPS (< 30 FPS)
│
├─> Check current FPS
│   │
│   ├─> Get JWT token from /status
│   ├─> Query /performance endpoint
│   │   └─> curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance
│   │
│   └─> Current FPS: _____ (from response.engine.fps)
│
├─> Check system resources
│   │
│   ├─> CPU usage high?
│   │   │
│   │   ├─> YES → INVESTIGATE CPU
│   │   │   │
│   │   │   ├─> Check CPU % in /performance
│   │   │   │   └─> cpu_usage > 80%?
│   │   │   │       ├─> YES → CPU bottleneck
│   │   │   │       └─> NO → Continue
│   │   │   │
│   │   │   ├─> Check for runaway processes
│   │   │   │   └─> top (Linux/Mac) or Task Manager (Windows)
│   │   │   │
│   │   │   ├─> Reduce physics complexity
│   │   │   │   └─> Lower physics tick rate
│   │   │   │   └─> Reduce active physics objects
│   │   │   │
│   │   │   └─> Optimize GDScript code
│   │   │       └─> Profile with Godot profiler
│   │   │
│   │   └─> NO → Continue to memory check
│   │
│   ├─> Memory usage high?
│   │   │
│   │   ├─> YES → INVESTIGATE MEMORY
│   │   │   │
│   │   │   ├─> Check memory in /performance
│   │   │   │   └─> memory.usage_mb > 1500?
│   │   │   │       ├─> YES → Memory pressure
│   │   │   │       └─> NO → Continue
│   │   │   │
│   │   │   ├─> Check for memory leaks
│   │   │   │   └─> Monitor memory over 15 minutes
│   │   │   │       └─> Increasing > 10%? → Memory leak
│   │   │   │
│   │   │   ├─> Reduce texture sizes
│   │   │   ├─> Unload unused scenes/resources
│   │   │   └─> Check for orphan nodes
│   │   │
│   │   └─> NO → Continue to rendering check
│   │
│   └─> GPU/rendering issues?
│       │
│       ├─> Check render stats in /performance
│       │   └─> response.engine.render_*
│       │
│       ├─> High draw calls?
│       │   └─> Batch meshes, reduce draw calls
│       │
│       ├─> High vertex count?
│       │   └─> LOD (level of detail) optimization
│       │
│       └─> Complex shaders?
│           └─> Simplify shader code
│
├─> Check scene complexity
│   │
│   ├─> Too many nodes in scene?
│   │   └─> Query /state/scene for node count
│   │       └─> > 1000 nodes? → Optimize scene structure
│   │
│   ├─> Too many physics objects?
│   │   └─> Reduce active RigidBody3D count
│   │   └─> Use static bodies where possible
│   │
│   └─> Complex procedural generation?
│       └─> Spread generation over multiple frames
│       └─> Use background threads
│
├─> Check VR overhead
│   │
│   ├─> VR enabled?
│   │   └─> Check vr_initialized in /status
│   │
│   ├─> VR requires higher FPS (90 FPS target)
│   │   └─> Reduce MSAA (currently 2x)
│   │   └─> Lower render resolution
│   │   └─> Disable post-processing effects
│   │
│   └─> Test without VR (desktop mode)
│       └─> FPS better? → VR overhead issue
│
└─> Check Godot settings
    │
    ├─> Debug vs Release build?
    │   └─> Debug build slower
    │       └─> Use release build for production
    │
    ├─> Physics tick rate too high?
    │   └─> Currently 90 FPS (for VR)
    │       └─> Can reduce to 60 FPS if not VR
    │
    └─> Profiler enabled?
        └─> Profiling adds overhead
            └─> Disable profiler in production

RESOLUTION: FPS should improve
VERIFY: Query /performance again, check engine.fps
TARGET: >= 60 FPS (desktop), >= 90 FPS (VR)
```

---

## Decision Tree 4: Scene Not Loading

```
SCENE NOT LOADING (vr_main.tscn not loaded)
│
├─> Check scene status
│   │
│   ├─> Query /state/scene
│   │   └─> curl http://127.0.0.1:8080/state/scene
│   │
│   └─> Response shows current scene?
│       ├─> NO → API not responding (see Decision Tree 1)
│       └─> YES → Check scene path
│
├─> Scene path correct?
│   │
│   ├─> Expected: "res://vr_main.tscn"
│   ├─> Actual: ___________
│   │
│   ├─> Wrong scene loaded?
│   │   │
│   │   ├─> Load correct scene via API
│   │   │   └─> POST /scene/load with {"scene_path": "res://vr_main.tscn"}
│   │   │
│   │   ├─> Get JWT token first
│   │   │   └─> TOKEN=$(curl -s http://127.0.0.1:8080/status | jq -r '.jwt_token')
│   │   │
│   │   └─> Execute load
│   │       └─> curl -X POST -H "Authorization: Bearer $TOKEN" \
│   │           -H "Content-Type: application/json" \
│   │           -d '{"scene_path": "res://vr_main.tscn"}' \
│   │           http://127.0.0.1:8080/scene/load
│   │
│   └─> No scene loaded (empty)?
│       └─> Continue to whitelist check
│
├─> Check scene whitelist (production/staging)
│   │
│   ├─> Environment: production or staging?
│   │   └─> Check /status response for "environment"
│   │
│   ├─> YES → Whitelist enforced
│   │   │
│   │   ├─> Check whitelist configuration
│   │   │   └─> config/production_whitelist.json
│   │   │   └─> config/staging_whitelist.json
│   │   │
│   │   ├─> Is vr_main.tscn in whitelist?
│   │   │   ├─> NO → ADD TO WHITELIST
│   │   │   │   └─> Edit whitelist JSON file
│   │   │   │   └─> Restart HttpApiServer
│   │   │   │
│   │   │   └─> YES → Whitelist correct
│   │   │
│   │   └─> Try loading scene again
│   │
│   └─> NO → Whitelist not enforced (development)
│       └─> Continue to file check
│
├─> Check scene file exists
│   │
│   ├─> Verify file on disk
│   │   └─> ls C:/godot/vr_main.tscn
│   │
│   ├─> File missing?
│   │   └─> CRITICAL ERROR
│   │       └─> Scene file not deployed
│   │           └─> Redeploy with correct files
│   │
│   └─> File exists?
│       └─> Continue to scene errors
│
├─> Check for scene loading errors
│   │
│   ├─> Check logs
│   │   └─> Look for "Failed to load scene"
│   │   └─> Look for "Cannot instantiate"
│   │   └─> Look for missing dependencies
│   │
│   ├─> Missing dependencies?
│   │   └─> Scene references missing resources
│   │       └─> Check .import files
│   │       └─> Verify all assets deployed
│   │
│   ├─> Scene parse errors?
│   │   └─> Scene file corrupted
│   │       └─> Validate .tscn file syntax
│   │       └─> Redeploy from source
│   │
│   └─> Script errors in scene?
│       └─> Scene has attached scripts with errors
│           └─> Check script compilation
│           └─> Fix script errors
│
└─> Check SceneLoadMonitor autoload
    │
    ├─> SceneLoadMonitor enabled?
    │   └─> Check project.godot autoload configuration
    │       └─> Line 26 should be enabled
    │
    ├─> Monitor reporting correct state?
    │   └─> Query /state/scene should return current scene
    │
    └─> Restart if autoload disabled
        └─> Enable autoload, restart Godot

RESOLUTION: Scene should now load
VERIFY: curl http://127.0.0.1:8080/state/scene
EXPECTED: current_scene contains "vr_main.tscn"
```

---

## Decision Tree 5: VR Not Initializing

```
VR NOT INITIALIZING (vr_initialized: false)
│
├─> Is VR headset required?
│   │
│   ├─> NO → Desktop mode acceptable
│   │   └─> System working as designed
│   │       └─> vr_initialized: false is EXPECTED
│   │       └─> NO ACTION REQUIRED
│   │
│   └─> YES → Continue troubleshooting
│
├─> Check VR hardware
│   │
│   ├─> Headset connected?
│   │   ├─> NO → Connect VR headset
│   │   └─> YES → Continue
│   │
│   ├─> Headset powered on?
│   │   ├─> NO → Power on headset
│   │   └─> YES → Continue
│   │
│   ├─> Headset detected by OS?
│   │   ├─> Windows: Check SteamVR or Oculus app
│   │   ├─> Linux: Check xr-runtime status
│   │   └─> Not detected? → Fix hardware connection
│   │
│   └─> Controllers connected?
│       └─> Check controller batteries/pairing
│
├─> Check OpenXR runtime
│   │
│   ├─> OpenXR runtime installed?
│   │   ├─> SteamVR (recommended)
│   │   ├─> Oculus Runtime
│   │   ├─> Windows Mixed Reality
│   │   └─> Not installed? → Install OpenXR runtime
│   │
│   ├─> Runtime running?
│   │   └─> Start SteamVR or Oculus app
│   │
│   └─> Runtime set as active?
│       └─> Windows: Check OpenXR runtime registry
│       └─> Set SteamVR as active OpenXR runtime
│
├─> Check Godot VR configuration
│   │
│   ├─> XR plugins enabled?
│   │   └─> Check project.godot for XR settings
│   │       └─> xr_mode should be enabled
│   │
│   ├─> OpenXR plugin enabled?
│   │   └─> Project Settings > XR > OpenXR
│   │       └─> Enable OpenXR plugin
│   │
│   └─> VR scene structure correct?
│       └─> Scene has XROrigin3D node?
│       └─> Scene has XRCamera3D node?
│       └─> Scene has controller nodes?
│
├─> Check VR initialization in logs
│   │
│   ├─> Look for OpenXR initialization messages
│   │   └─> "OpenXR initialized"
│   │   └─> "XR interface found"
│   │
│   ├─> Look for VR errors
│   │   └─> "Failed to initialize XR"
│   │   └─> "No XR runtime available"
│   │   └─> "OpenXR session failed"
│   │
│   └─> Errors found?
│       └─> See error-specific troubleshooting below
│
└─> VR-specific errors
    │
    ├─> "No XR runtime available"
    │   └─> Install and start OpenXR runtime
    │
    ├─> "XR session failed to start"
    │   └─> Restart VR headset and runtime
    │   └─> Check for runtime conflicts (multiple runtimes)
    │
    ├─> "OpenXR not supported"
    │   └─> Update Godot to version 4.5+ (OpenXR support)
    │
    └─> "XR interface not found"
        └─> Enable OpenXR plugin in project settings
        └─> Rebuild and redeploy

RESOLUTION: VR should initialize if hardware available
VERIFY: curl http://127.0.0.1:8080/status | jq '.vr_initialized'
EXPECTED: true (if headset connected) or false (desktop mode)
NOTE: false is acceptable if VR not required
```

---

## Decision Tree 6: Rollback Decision

```
SHOULD WE ROLLBACK?
│
├─> Critical acceptance criteria failing?
│   │
│   ├─> Check acceptance criteria status
│   │   └─> Run: python tests/post_deployment_validation.py
│   │
│   ├─> Any CRITICAL criterion failed?
│   │   │
│   │   ├─> YES → ROLLBACK IMMEDIATELY
│   │   │   │
│   │   │   └─> Execute: ./deploy/scripts/rollback.sh
│   │   │       └─> Restores previous version
│   │   │       └─> Verify rollback success
│   │   │
│   │   └─> NO → Continue evaluation
│   │
│   └─> Multiple IMPORTANT criteria failing?
│       ├─> > 50% failing? → ROLLBACK RECOMMENDED
│       └─> < 50% failing? → Continue evaluation
│
├─> System stability issues?
│   │
│   ├─> System crashing?
│   │   ├─> YES → ROLLBACK IMMEDIATELY
│   │   └─> NO → Continue
│   │
│   ├─> System unresponsive?
│   │   ├─> YES → ROLLBACK IMMEDIATELY
│   │   └─> NO → Continue
│   │
│   ├─> Memory leaks detected?
│   │   ├─> Severe? → ROLLBACK
│   │   └─> Minor? → Monitor, may continue
│   │
│   └─> Performance severely degraded?
│       ├─> FPS < 15? → ROLLBACK
│       └─> FPS 15-30? → Monitor, investigate
│
├─> Security issues?
│   │
│   ├─> Authentication broken?
│   │   └─> YES → ROLLBACK IMMEDIATELY (security risk)
│   │
│   ├─> Whitelist not enforced?
│   │   └─> YES → ROLLBACK IMMEDIATELY (security risk)
│   │
│   ├─> Rate limiting disabled?
│   │   └─> YES → ROLLBACK or fix immediately
│   │
│   └─> Security vulnerability discovered?
│       └─> YES → ROLLBACK, patch, redeploy
│
├─> Business impact assessment
│   │
│   ├─> System unusable for primary use case?
│   │   ├─> YES → ROLLBACK
│   │   └─> NO → Continue
│   │
│   ├─> Workaround available?
│   │   ├─> YES → May continue with workaround
│   │   └─> NO → Consider rollback
│   │
│   └─> Fix available quickly (< 30 minutes)?
│       ├─> YES → Attempt fix before rollback
│       └─> NO → ROLLBACK, fix properly, redeploy
│
└─> DECISION MATRIX
    │
    ├─> ROLLBACK IMMEDIATELY if:
    │   ├─> Any CRITICAL criterion fails
    │   ├─> System crashes/unresponsive
    │   ├─> Security broken
    │   └─> System unusable
    │
    ├─> ROLLBACK RECOMMENDED if:
    │   ├─> > 50% IMPORTANT criteria fail
    │   ├─> Severe performance degradation
    │   ├─> Multiple stability issues
    │   └─> No quick fix available
    │
    ├─> MONITOR AND FIX if:
    │   ├─> Minor issues only
    │   ├─> Workaround available
    │   ├─> Quick fix possible
    │   └─> Non-critical functionality affected
    │
    └─> CONTINUE if:
        ├─> All CRITICAL criteria pass
        ├─> > 80% IMPORTANT criteria pass
        ├─> System stable
        └─> Security intact

ROLLBACK EXECUTION:
1. Get approval from Technical Lead + DevOps Lead
2. Execute: ./deploy/scripts/rollback.sh
3. Verify rollback: python deploy/scripts/verify_deployment.py
4. Notify stakeholders
5. Document incident
6. Fix issues offline
7. Schedule redeployment

ROLLBACK TIME: Target < 5 minutes
ROLLBACK VERIFICATION: All smoke tests must pass
```

---

## Quick Command Reference

### Health Checks
```bash
# Basic health
curl http://127.0.0.1:8080/health

# Detailed status
curl http://127.0.0.1:8080/status

# Full validation
python tests/smoke_tests.py
python tests/post_deployment_validation.py
```

### Get JWT Token
```bash
# Extract token
TOKEN=$(curl -s http://127.0.0.1:8080/status | jq -r '.jwt_token')

# Use token
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene
```

### Scene Operations
```bash
# Check current scene
curl http://127.0.0.1:8080/state/scene

# Load scene (with auth)
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}' \
  http://127.0.0.1:8080/scene/load
```

### Performance Check
```bash
# Get performance metrics
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance
```

### Process Management
```bash
# Check if Godot running
ps aux | grep -i godot

# Check ports listening
netstat -an | grep 8080  # Linux/Mac
netstat -an | findstr 8080  # Windows
```

### Rollback
```bash
# Execute rollback
./deploy/scripts/rollback.sh

# Verify rollback
python deploy/scripts/verify_deployment.py
```

---

## Contact Information

### On-Call Escalation

1. **On-Call Engineer** (First contact)
   - Phone: _______________
   - Email: _______________

2. **Technical Lead** (Escalation)
   - Phone: _______________
   - Email: _______________

3. **DevOps Lead** (Infrastructure issues)
   - Phone: _______________
   - Email: _______________

4. **Product Owner** (Business decisions)
   - Phone: _______________
   - Email: _______________

---

## Document Version

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-12-04 | Initial troubleshooting flowchart | Claude Code |

**Document Location:** `C:/godot/deploy/TROUBLESHOOTING_FLOWCHART.md`

**Related Documents:**
- [Acceptance Criteria](ACCEPTANCE_CRITERIA.md)
- [Deployment Sign-Off](DEPLOYMENT_SIGNOFF.md)
- [Deployment Runbook](RUNBOOK.md)
