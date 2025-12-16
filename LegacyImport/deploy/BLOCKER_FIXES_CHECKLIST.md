# SpaceTime VR - Blocker Fixes Checklist

**Date:** 2025-12-04
**Status:** BLOCKERS IDENTIFIED
**Priority:** CRITICAL (Must fix before production)
**Estimated Total Time:** 6-8 hours

---

## Critical Blockers

### Blocker 1: GDScript API Compatibility Issues

**Priority:** CRITICAL
**Estimated Time:** 4 hours
**Status:** Not Started

**Issue:** telemetry_server.gd uses deprecated/changed Godot 4.5 APIs

**Files to Fix:**
- `C:/godot/addons/godot_debug_connection/telemetry_server.gd`

**Specific Fixes Required:**

#### Fix 1.1: accept_stream() API Change (Line ~56)
- [ ] **Current code:**
  ```gdscript
  var peer = tcp_server.take_connection()
  if peer:
      telemetry_stream.accept_stream()  # OLD API
  ```

- [ ] **New code (Godot 4.5):**
  ```gdscript
  var peer = tcp_server.take_connection()
  if peer:
      telemetry_stream.accept_stream(peer)  # NEW: Requires StreamPeer
  ```

- [ ] Test: Launch Godot, check for parse errors

#### Fix 1.2: Performance.MEMORY_DYNAMIC Deprecated (Line ~180)
- [ ] **Search for:** `Performance.MEMORY_DYNAMIC`

- [ ] **Investigate replacement:**
  ```gdscript
  # Check Godot 4.5 Performance class documentation
  # Possible replacements:
  # - Performance.MEMORY_STATIC
  # - Performance.get_monitor(Performance.MEMORY_STATIC)
  # - OS.get_static_memory_usage()
  ```

- [ ] **Replace with:** (TBD based on investigation)

- [ ] Test: Check telemetry data collection works

#### Fix 1.3: Verify TelemetryServer Loads
- [ ] Run: `godot --headless --script res://addons/godot_debug_connection/telemetry_server.gd`
- [ ] Expected: No parse errors
- [ ] Check project.godot autoload section (TelemetryServer should load)

#### Fix 1.4: Test Telemetry WebSocket Connection
- [ ] Start application: `./deploy/build/SpaceTime.exe`
- [ ] Check logs: "TelemetryServer started on port 8081"
- [ ] Test connection: `python telemetry_client.py`
- [ ] Expected: Receives telemetry packets

**Verification:**
```bash
# 1. No parse errors
godot --headless --script res://addons/godot_debug_connection/telemetry_server.gd

# 2. Application starts without errors
GODOT_ENABLE_HTTP_API=true ./deploy/build/SpaceTime.exe

# 3. Telemetry port listening
netstat -an | grep 8081

# 4. Can connect via WebSocket
python telemetry_client.py
```

---

### Blocker 2: HttpApiServer Not Starting

**Priority:** CRITICAL
**Estimated Time:** 1 hour (after Blocker 1 fixed)
**Status:** Not Started (Depends on Blocker 1)

**Issue:** Modern HTTP API server not initializing, production endpoints unavailable

**Investigation Steps:**

- [ ] **Step 1: Verify HttpApiServer Autoload**
  ```bash
  # Check project.godot for HttpApiServer autoload
  grep -A 2 "HttpApiServer" C:/godot/project.godot
  ```
  - [ ] Autoload enabled?
  - [ ] Path correct: `res://scripts/http_api/http_api_server.gd`?

- [ ] **Step 2: Check Script Dependencies**
  ```bash
  # Check if HttpApiServer depends on TelemetryServer
  grep -i "telemetry" C:/godot/scripts/http_api/http_api_server.gd
  ```
  - [ ] If yes: Fix telemetry first (Blocker 1)
  - [ ] If no: Investigate other dependencies

- [ ] **Step 3: Test HttpApiServer Standalone**
  ```bash
  godot --headless --script res://scripts/http_api/http_api_server.gd
  ```
  - [ ] Expected: No parse errors
  - [ ] Expected: Server starts on port 8080

- [ ] **Step 4: Verify Endpoints Available**
  ```bash
  curl http://127.0.0.1:8080/health
  curl http://127.0.0.1:8080/status
  curl http://127.0.0.1:8080/state/scene
  ```
  - [ ] All should return 200 OK or valid JSON

**Verification:**
```bash
# 1. Application starts with HttpApiServer
GODOT_ENABLE_HTTP_API=true ./deploy/build/SpaceTime.exe

# 2. Health endpoint available
curl http://127.0.0.1:8080/health
# Expected: {"status": "ok"}

# 3. Status shows production environment
curl -s http://127.0.0.1:8080/status | grep production

# 4. All modern endpoints respond
for endpoint in health status state/scene state/player performance; do
  echo "Testing /$endpoint"
  curl -s http://127.0.0.1:8080/$endpoint | head -3
done
```

---

### Blocker 3: Missing jq Tool

**Priority:** HIGH
**Estimated Time:** 30 minutes
**Status:** Not Started

**Issue:** deploy_local.sh uses jq for JSON parsing, tool not installed

**Option A: Install jq (Recommended)**

- [ ] **Windows (Chocolatey):**
  ```bash
  choco install jq
  ```

- [ ] **Windows (Manual):**
  1. Download from: https://jqlang.github.io/jq/download/
  2. Place jq.exe in: `C:/Program Files/jq/jq.exe`
  3. Add to PATH: `C:/Program Files/jq`

- [ ] **Verify installation:**
  ```bash
  which jq
  jq --version
  # Expected: jq-1.7 or later
  ```

**Option B: Modify Script to Use Python**

- [ ] **Edit:** `C:/godot/deploy/scripts/deploy_local.sh`

- [ ] **Find line ~95:**
  ```bash
  STATUS=$(curl -s http://127.0.0.1:8080/status | jq -r '.status')
  ```

- [ ] **Replace with:**
  ```bash
  STATUS=$(curl -s http://127.0.0.1:8080/status | python -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))")
  ```

- [ ] Test: `bash deploy_local.sh`

**Verification:**
```bash
# Test jq works
echo '{"status": "healthy"}' | jq -r '.status'
# Expected: healthy

# Test deployment script
cd C:/godot/deploy/scripts
export GODOT_ENABLE_HTTP_API=true
export GODOT_ENV=production
bash deploy_local.sh
# Expected: No "jq: command not found" errors
```

---

### Blocker 4: TLS Certificates Not Generated

**Priority:** HIGH (for production)
**Estimated Time:** 1 hour
**Status:** Not Started

**Issue:** HTTPS/TLS certificates required for production, currently missing

**Option A: Self-Signed Certificates (Development/Testing)**

- [ ] **Generate self-signed certificate:**
  ```bash
  cd C:/godot/deploy/certs

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout tls.key \
    -out tls.crt \
    -subj "/CN=spacetime-dev.local/O=SpaceTime Development/C=US"
  ```

- [ ] **Set permissions:**
  ```bash
  chmod 600 tls.key
  chmod 644 tls.crt
  ```

- [ ] **Verify certificate:**
  ```bash
  openssl x509 -in tls.crt -text -noout
  # Check: Subject, Issuer, Validity dates
  ```

- [ ] **Test with nginx:**
  ```nginx
  # nginx.conf
  server {
    listen 443 ssl;
    ssl_certificate /path/to/deploy/certs/tls.crt;
    ssl_certificate_key /path/to/deploy/certs/tls.key;
  }
  ```

**Option B: Let's Encrypt with cert-manager (Production)**

- [ ] **Prerequisites:**
  - [ ] Kubernetes cluster running
  - [ ] Domain name configured (DNS)
  - [ ] External IP assigned

- [ ] **Install cert-manager:**
  ```bash
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
  ```

- [ ] **Create ClusterIssuer:**
  ```bash
  kubectl apply -f C:/godot/deploy/kubernetes/base/cert-manager-issuer.yaml
  ```

- [ ] **Add annotation to Ingress:**
  ```yaml
  metadata:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
  ```

- [ ] **Verify certificate issued:**
  ```bash
  kubectl get certificate -n spacetime
  # Expected: READY = True
  ```

**Verification:**
```bash
# Development (self-signed)
curl -k https://127.0.0.1:443/status
# Expected: JSON response (ignore cert warning)

# Production (Let's Encrypt)
curl https://spacetime.yourdomain.com/status
# Expected: JSON response (no cert warning)
```

---

### Blocker 5: Production Secrets Not Configured

**Priority:** HIGH (for production)
**Estimated Time:** 30 minutes
**Status:** Not Started

**Issue:** API tokens and passwords use placeholder values, insecure for production

**Steps:**

- [ ] **Generate API Token:**
  ```bash
  export API_TOKEN=$(openssl rand -base64 32)
  echo "API_TOKEN=${API_TOKEN}"
  # Save this securely!
  ```

- [ ] **Generate Grafana Password:**
  ```bash
  export GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 16)
  echo "GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}"
  # Save this securely!
  ```

- [ ] **Generate Redis Password:**
  ```bash
  export REDIS_PASSWORD=$(openssl rand -base64 16)
  echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
  # Save this securely!
  ```

- [ ] **Update .env.production:**
  ```bash
  # Edit C:/godot/.env.production
  # Replace placeholders:
  API_TOKEN=<generated-token>
  GRAFANA_ADMIN_PASSWORD=<generated-password>
  REDIS_PASSWORD=<generated-password>
  ```

- [ ] **Update Kubernetes secret:**
  ```bash
  # Edit C:/godot/deploy/kubernetes/base/secret.yaml
  # Base64 encode secrets:
  echo -n "${API_TOKEN}" | base64
  echo -n "${GRAFANA_ADMIN_PASSWORD}" | base64
  echo -n "${REDIS_PASSWORD}" | base64

  # Replace in secret.yaml
  ```

- [ ] **Store secrets securely:**
  ```bash
  # Option 1: Password manager (1Password, LastPass)
  # Option 2: Encrypted vault (Vault by HashiCorp)
  # Option 3: Encrypted file with 0600 permissions

  cat > ~/.spacetime_secrets << EOF
  API_TOKEN=${API_TOKEN}
  GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
  REDIS_PASSWORD=${REDIS_PASSWORD}
  EOF

  chmod 0600 ~/.spacetime_secrets
  ```

**Verification:**
```bash
# 1. Check secrets are not placeholders
grep -i "REPLACE_WITH" C:/godot/.env.production
# Expected: No matches

grep -i "REPLACE_WITH" C:/godot/deploy/kubernetes/base/secret.yaml
# Expected: No matches

# 2. Verify secrets are base64 encoded in K8s
kubectl get secret spacetime-secrets -n spacetime -o jsonpath='{.data.API_TOKEN}' | base64 -d
# Expected: Your generated token

# 3. Test API authentication
curl -H "Authorization: Bearer ${API_TOKEN}" http://127.0.0.1:8080/status
# Expected: 200 OK
```

---

## Verification After All Fixes

**Once all blockers are resolved, run full verification:**

### Step 1: Clean Build
```bash
# Rebuild with fixes
godot --headless --export-release "Windows Desktop" "C:/godot/deploy/build/SpaceTime.exe"
```

### Step 2: Deploy Locally
```bash
cd C:/godot/deploy/scripts
export GODOT_ENABLE_HTTP_API=true
export GODOT_ENV=production
bash deploy_local.sh
```

### Step 3: Automated Verification
```bash
python verify_deployment.py --endpoint http://127.0.0.1:8080
```

**Expected Result:**
```
==========================================
SpaceTime VR - Deployment Verification
==========================================

[SUCCESS] Health Check: Health check passed
[SUCCESS] Status Check: Status healthy, environment: production
[SUCCESS] Scene Loaded: Scene loaded: res://vr_main.tscn
[SUCCESS] Authentication: Authentication working correctly
[SUCCESS] Scene Whitelist: Scene whitelist enforced (test scene rejected)
[SUCCESS] Performance Endpoint: Performance endpoint available with all metrics
[SUCCESS] Rate Limiting: Rate limiting active (limited after 60 requests)

==========================================
Verification Summary
==========================================

Passed: 7 / 7
Failed: 0 / 7

[SUCCESS] All checks passed! Deployment successful.
```

### Step 4: Manual Testing
```bash
# Test all critical endpoints
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/status
curl http://127.0.0.1:8080/state/scene
curl http://127.0.0.1:8080/state/player
curl http://127.0.0.1:8080/performance

# Test telemetry
python telemetry_client.py
# Expected: Receiving telemetry packets

# Test VR (if headset connected)
# Expected: Application runs at 90 FPS, no errors
```

### Step 5: 24-Hour Monitoring
```bash
# Start health monitoring
python C:/godot/tests/health_monitor.py

# Monitor for 24 hours, checking:
# - [ ] No crashes or restarts
# - [ ] Memory stable (<500MB)
# - [ ] FPS stable (85-95)
# - [ ] No error spikes
# - [ ] API responsive (<100ms)
```

---

## Sign-Off

Once all blockers are fixed and verification passes:

- [ ] All critical blockers resolved
- [ ] All verification tests passing
- [ ] 24-hour monitoring complete with no issues
- [ ] Production secrets configured and secured
- [ ] TLS certificates generated and tested
- [ ] Documentation updated with any changes

**Deployment Status:** READY FOR PRODUCTION

**Sign-off:**
- Developer: _________________ Date: _______
- QA: _________________ Date: _______
- DevOps: _________________ Date: _______

---

## Additional Resources

- Full Report: `C:/godot/deploy/LOCAL_DEPLOYMENT_EXECUTED.md`
- Quick Status: `C:/godot/deploy/DEPLOYMENT_STATUS.txt`
- Deployment Guide: `C:/godot/deploy/docs/DEPLOYMENT_GUIDE.md`
- Runbook: `C:/godot/deploy/RUNBOOK.md`
- Checklist: `C:/godot/deploy/CHECKLIST.md`

---

**Document Version:** 1.0.0
**Last Updated:** 2025-12-04
**Next Review:** After blocker fixes completed
