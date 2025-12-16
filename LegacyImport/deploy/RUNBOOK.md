# SpaceTime VR - Production Deployment Runbook

**Version:** 1.0.0
**Date:** 2025-12-04
**Status:** Production Ready

---

## Table of Contents

1. [Pre-Deployment Checklist](#1-pre-deployment-checklist)
2. [Deployment Steps](#2-deployment-steps)
3. [Post-Deployment Verification](#3-post-deployment-verification)
4. [Rollback Procedure](#4-rollback-procedure)
5. [Monitoring](#5-monitoring)
6. [Troubleshooting](#6-troubleshooting)
7. [Contacts and Escalation](#7-contacts-and-escalation)

---

## 1. Pre-Deployment Checklist

### Critical Items (GO/NO-GO)

Work through each item sequentially. If any item fails, stop and resolve before continuing.

#### Item 1: Environment Variables Set

**Task:** Verify environment variables are configured

**Commands:**
```bash
# Check if variables are set
echo $GODOT_ENABLE_HTTP_API  # Must be "true"
echo $GODOT_ENV               # Must be "production"

# If not set, configure them
export GODOT_ENABLE_HTTP_API=true
export GODOT_ENV=production

# For systemd service
sudo systemctl edit spacetime
# Add:
# [Service]
# Environment="GODOT_ENABLE_HTTP_API=true"
# Environment="GODOT_ENV=production"
```

**Verification:**
```bash
# Variables should print:
# GODOT_ENABLE_HTTP_API=true
# GODOT_ENV=production
```

**Status:** [ ] COMPLETE

---

#### Item 2: Secrets Generated and Configured

**Task:** Replace placeholder secrets with real secure values

**Commands:**
```bash
# Generate secure tokens
API_TOKEN=$(openssl rand -base64 32)
GRAFANA_PASSWORD=$(openssl rand -base64 24)
REDIS_PASSWORD=$(openssl rand -base64 24)

# For Kubernetes
kubectl create secret generic spacetime-secrets \
  --from-literal=API_TOKEN="$API_TOKEN" \
  --from-literal=GRAFANA_ADMIN_USER="admin" \
  --from-literal=GRAFANA_ADMIN_PASSWORD="$GRAFANA_PASSWORD" \
  --from-literal=REDIS_PASSWORD="$REDIS_PASSWORD" \
  -n spacetime

# Save credentials securely (restrict to 0600 permissions)
echo "API_TOKEN=$API_TOKEN" > .credentials
echo "GRAFANA_PASSWORD=$GRAFANA_PASSWORD" >> .credentials
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .credentials
chmod 600 .credentials
```

**Verification:**
```bash
# For Kubernetes
kubectl get secret spacetime-secrets -n spacetime

# Should show the secret exists
```

**Status:** [ ] COMPLETE

---

#### Item 3: TLS Certificates Generated

**Task:** Generate TLS certificates for HTTPS

**Development (Self-Signed):**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout deploy/certs/tls.key \
  -out deploy/certs/tls.crt \
  -subj "/CN=spacetime.yourdomain.com"

# For Kubernetes
kubectl create secret tls spacetime-tls \
  --cert=deploy/certs/tls.crt \
  --key=deploy/certs/tls.key \
  -n spacetime
```

**Production (Let's Encrypt):**
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=Available --timeout=300s \
  deployment/cert-manager -n cert-manager

# Create ClusterIssuer
kubectl apply -f kubernetes/cert-manager-issuer.yaml
```

**Verification:**
```bash
# For Kubernetes
kubectl get secret spacetime-tls -n spacetime

# Should show the TLS secret exists
```

**Status:** [ ] COMPLETE

---

#### Item 4: Build Exported and Validated

**Task:** Export release build and verify it works

**Commands:**
```bash
# Export release build
godot --headless --export-release "Windows Desktop" "deploy/build/SpaceTime.exe"

# Check build exists
ls -lh deploy/build/SpaceTime.exe

# File should be 100-500 MB
```

**Verification:**
```bash
# Run build with API enabled (in background)
GODOT_ENABLE_HTTP_API=true ./deploy/build/SpaceTime.exe &
BUILD_PID=$!

# Wait for startup (30 seconds)
sleep 30

# Verify API responds
curl -f http://127.0.0.1:8080/status

# Stop build
kill $BUILD_PID
```

**Expected Output:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "http_api": "active"
}
```

**Status:** [ ] COMPLETE

---

#### Item 5: Test Suite Passing

**Task:** Run all automated tests

**Commands:**
```bash
# Run test suite
cd tests
python test_runner.py --parallel

# Run health check
python health_monitor.py --single

# Run feature validation
python feature_validator.py --ci
```

**Verification:**
- Test runner: All tests passing (green output)
- Health monitor: All checks passing
- Feature validator: All features validated

**Status:** [ ] COMPLETE

---

### High Priority Items (STRONGLY RECOMMENDED)

#### Item 6: Configuration Files Reviewed

**Task:** Review production configuration files

**Files to Review:**
- `config/scene_whitelist.json` - Production whitelist (only vr_main.tscn)
- `config/security_production.json` - Security settings
- `config/performance_production.json` - Performance tuning

**Verification:**
- Scene whitelist contains only necessary scenes
- Security settings match requirements
- Performance settings appropriate for hardware

**Status:** [ ] COMPLETE

---

#### Item 7: Team Trained

**Task:** Ensure deployment team understands procedures

**Training Completed:**
- [ ] Deployment procedures walkthrough
- [ ] Health monitoring training
- [ ] Troubleshooting session
- [ ] Rollback drill

**Status:** [ ] COMPLETE

---

#### Item 8: Monitoring Configured

**Task:** Set up monitoring and alerting

**For Kubernetes:**
```bash
# Deploy monitoring stack
kubectl apply -f kubernetes/monitoring/

# Wait for Prometheus and Grafana
kubectl wait --for=condition=Available --timeout=300s \
  deployment/spacetime-prometheus -n spacetime
kubectl wait --for=condition=Available --timeout=300s \
  deployment/spacetime-grafana -n spacetime
```

**Verification:**
```bash
# Port forward to check services
kubectl port-forward -n spacetime svc/spacetime-prometheus-service 9090:9090 &
kubectl port-forward -n spacetime svc/spacetime-grafana-service 3000:3000 &

# Check Prometheus
curl http://localhost:9090/-/healthy

# Check Grafana
curl http://localhost:3000/api/health
```

**Status:** [ ] COMPLETE (or acceptable to skip for initial deployment)

---

## 2. Deployment Steps

### Step 1: Create Namespace (Kubernetes Only)

```bash
kubectl apply -f kubernetes/namespace.yaml

# Verify
kubectl get namespace spacetime
```

**Expected:** Namespace "spacetime" created

---

### Step 2: Apply Configuration

**For Kubernetes:**
```bash
# Apply ConfigMap
kubectl apply -f kubernetes/configmap.yaml

# Verify
kubectl get configmap spacetime-config -n spacetime
```

**Expected:** ConfigMap created successfully

---

### Step 3: Create Persistent Volumes (Kubernetes Only)

```bash
# Apply PVC
kubectl apply -f kubernetes/pvc.yaml

# Verify
kubectl get pvc -n spacetime
```

**Expected:** PVCs in "Bound" state

---

### Step 4: Deploy Application

**For Kubernetes:**
```bash
# Deploy StatefulSets (Redis)
kubectl apply -f kubernetes/statefulset.yaml

# Deploy application
kubectl apply -f kubernetes/deployment.yaml

# Wait for rollout
kubectl rollout status deployment/spacetime-godot -n spacetime
kubectl rollout status deployment/spacetime-nginx -n spacetime
```

**For Bare Metal:**
```bash
# Copy build to server
scp deploy/build/SpaceTime.exe user@prod-server:/opt/spacetime/

# SSH to server
ssh user@prod-server

# Set environment variables
sudo tee /etc/systemd/system/spacetime.service <<EOF
[Unit]
Description=SpaceTime VR Application
After=network.target

[Service]
Type=simple
User=spacetime
WorkingDirectory=/opt/spacetime
Environment="GODOT_ENABLE_HTTP_API=true"
Environment="GODOT_ENV=production"
ExecStart=/opt/spacetime/SpaceTime.exe
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable spacetime
sudo systemctl start spacetime
```

**Verification:**
```bash
# For Kubernetes
kubectl get pods -n spacetime

# Expected: All pods Running

# For Bare Metal
sudo systemctl status spacetime

# Expected: Active (running)
```

---

### Step 5: Deploy Services (Kubernetes Only)

```bash
# Apply Services
kubectl apply -f kubernetes/service.yaml

# Verify
kubectl get services -n spacetime
```

**Expected:** Services created with ClusterIP or LoadBalancer

---

### Step 6: Deploy Ingress (Kubernetes Only, if using HTTPS)

```bash
# Apply Ingress
kubectl apply -f kubernetes/ingress.yaml

# Verify
kubectl get ingress -n spacetime

# Get external IP
kubectl get ingress spacetime-ingress -n spacetime -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Expected:** Ingress created with external IP

---

### Step 7: Apply Network Policies (Kubernetes Only, Optional)

```bash
# Apply NetworkPolicy (optional but recommended)
kubectl apply -f kubernetes/networkpolicy.yaml

# Verify
kubectl get networkpolicy -n spacetime
```

---

### Step 8: Configure Horizontal Pod Autoscaling (Kubernetes Only, Optional)

```bash
# Apply HPA (optional)
kubectl apply -f kubernetes/hpa.yaml

# Verify
kubectl get hpa -n spacetime
```

---

## 3. Post-Deployment Verification

Run these checks **in order**. All must pass before deployment is considered successful.

### Check 1: Pods Running (Kubernetes)

```bash
kubectl get pods -n spacetime
```

**Expected:**
```
NAME                                   READY   STATUS    RESTARTS   AGE
spacetime-godot-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
spacetime-nginx-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
spacetime-redis-0                      1/1     Running   0          2m
```

**Pass:** [ ] YES / [ ] NO

---

### Check 2: API Health Check

```bash
# For Kubernetes (port forward first)
kubectl port-forward -n spacetime deployment/spacetime-godot 8080:8080 &

# Check health
curl -f http://127.0.0.1:8080/health

# Or directly on bare metal
curl -f http://127.0.0.1:8080/health
```

**Expected:**
```json
{
  "status": "ok"
}
```

**Pass:** [ ] YES / [ ] NO

---

### Check 3: API Status Check

```bash
curl http://127.0.0.1:8080/status | jq .
```

**Expected:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 120,
  "http_api": "active",
  "telemetry": "active",
  "scene": "res://vr_main.tscn",
  "environment": "production"
}
```

**Verify:**
- `environment` is "production" ✅
- `http_api` is "active" ✅
- `status` is "healthy" ✅

**Pass:** [ ] YES / [ ] NO

---

### Check 4: Telemetry WebSocket

```bash
# Check port is listening
nc -zv 127.0.0.1 8081
```

**Expected:** "Connection to 127.0.0.1 8081 succeeded"

**Pass:** [ ] YES / [ ] NO

---

### Check 5: Scene Loaded

```bash
curl http://127.0.0.1:8080/state/scene | jq .
```

**Expected:**
```json
{
  "current_scene": "res://vr_main.tscn",
  "loaded": true
}
```

**Pass:** [ ] YES / [ ] NO

---

### Check 6: Authentication Working

```bash
# Try without token (should fail)
curl -w "%{http_code}\n" http://127.0.0.1:8080/scene

# Expected: 401 Unauthorized

# Get token from status
TOKEN=$(curl -s http://127.0.0.1:8080/status | jq -r .jwt_token)

# Try with token (should succeed)
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene | jq .

# Expected: HTTP 200, scene data returned
```

**Pass:** [ ] YES / [ ] NO

---

### Check 7: Rate Limiting Active

```bash
# Send 65 requests rapidly (rate limit is 60/minute)
for i in {1..65}; do
  curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/status >/dev/null 2>&1
done

# Last few requests should get 429 Too Many Requests
curl -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n" http://127.0.0.1:8080/status

# Expected: 429 (rate limit exceeded)
```

**Pass:** [ ] YES / [ ] NO

---

### Check 8: Scene Whitelist Enforced

```bash
# Try to load a test scene (should fail in production)
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://tests/debug.tscn"}' \
  http://127.0.0.1:8080/scene/load

# Expected: HTTP 403 Forbidden (not in production whitelist)
```

**Pass:** [ ] YES / [ ] NO

---

### Check 9: Performance Metrics Available

```bash
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/performance | jq .
```

**Expected:**
```json
{
  "cache": { ... },
  "security": { ... },
  "memory": { ... },
  "engine": { ... }
}
```

**Pass:** [ ] YES / [ ] NO

---

### Check 10: Automated Validation

```bash
# Run automated verification script
cd deploy/tests
python verify_deployment.py --endpoint http://127.0.0.1:8080
```

**Expected:** "All checks passed"

**Pass:** [ ] YES / [ ] NO

---

### Verification Summary

**Total Checks:** 10
**Passed:** _____ / 10
**Failed:** _____ / 10

**GO/NO-GO Decision:**
- If 10/10 passed: ✅ **DEPLOYMENT SUCCESSFUL**
- If 8-9/10 passed: ⚠️ **DEPLOYMENT PARTIAL** (review failures)
- If <8/10 passed: ❌ **DEPLOYMENT FAILED** (rollback recommended)

---

## 4. Rollback Procedure

If deployment fails or critical issues discovered, follow this rollback procedure.

### Quick Rollback (Kubernetes)

```bash
# View deployment history
kubectl rollout history deployment/spacetime-godot -n spacetime

# Rollback to previous version
kubectl rollout undo deployment/spacetime-godot -n spacetime

# Wait for rollback
kubectl rollout status deployment/spacetime-godot -n spacetime

# Verify
kubectl get pods -n spacetime
curl http://127.0.0.1:8080/status
```

**Estimated Time:** 2 minutes

---

### Rollback to Specific Version (Kubernetes)

```bash
# Rollback to specific revision
kubectl rollout undo deployment/spacetime-godot --to-revision=1 -n spacetime
```

---

### Rollback on Bare Metal

```bash
# Stop service
sudo systemctl stop spacetime

# Restore previous version
sudo cp /opt/spacetime/backups/SpaceTime-previous.exe /opt/spacetime/SpaceTime.exe

# Start service
sudo systemctl start spacetime

# Verify
sudo systemctl status spacetime
curl http://127.0.0.1:8080/status
```

**Estimated Time:** 5 minutes

---

### Configuration Rollback

```bash
# For Kubernetes
kubectl apply -f kubernetes/configmap-previous.yaml

# Restart pods to pick up config
kubectl rollout restart deployment/spacetime-godot -n spacetime
```

---

### Post-Rollback Verification

After rollback, re-run Post-Deployment Verification (Section 3).

**Rollback Successful:** [ ] YES / [ ] NO

---

## 5. Monitoring

### What to Monitor

**Critical Metrics (Alert Immediately):**

1. **API Health** (every 1 minute)
   - `curl -f http://127.0.0.1:8080/health`
   - Alert if: HTTP 500 or connection refused

2. **FPS** (every 5 minutes)
   - `curl http://127.0.0.1:8080/performance | jq .engine.fps`
   - Alert if: <85 FPS for >5 minutes

3. **Memory** (every 5 minutes)
   - `curl http://127.0.0.1:8080/performance | jq .memory.static_mb`
   - Alert if: >800 MB or growing >10 MB/minute

4. **Error Rate** (every 5 minutes)
   - Check logs for error count
   - Alert if: >5% error rate

**Monitoring Commands:**

```bash
# Continuous health monitoring
cd tests
python health_monitor.py --interval 60

# Telemetry streaming
python telemetry_client.py

# Log monitoring (Kubernetes)
kubectl logs -f deployment/spacetime-godot -n spacetime

# Log monitoring (Bare Metal)
sudo journalctl -u spacetime -f
```

---

## 6. Troubleshooting

### Issue 1: API Not Responding

**Symptoms:**
- `curl http://127.0.0.1:8080/health` times out or connection refused

**Diagnosis:**
```bash
# Check if Godot is running
ps aux | grep Godot  # or kubectl get pods -n spacetime

# Check environment variables
echo $GODOT_ENABLE_HTTP_API  # Should be "true"

# Check logs
kubectl logs deployment/spacetime-godot -n spacetime | grep "HTTP API"
# or
sudo journalctl -u spacetime | grep "HTTP API"
```

**Solution:**
```bash
# If GODOT_ENABLE_HTTP_API not set:
export GODOT_ENABLE_HTTP_API=true

# Restart
kubectl rollout restart deployment/spacetime-godot -n spacetime
# or
sudo systemctl restart spacetime

# Verify
curl http://127.0.0.1:8080/status
```

---

### Issue 2: Authentication Failing

**Symptoms:**
- All API requests return 401 Unauthorized

**Diagnosis:**
```bash
# Check if token is generated
curl http://127.0.0.1:8080/status | jq .jwt_token

# Check if secrets are set correctly (Kubernetes)
kubectl get secret spacetime-secrets -n spacetime -o yaml
```

**Solution:**
- Regenerate secrets (see Pre-Deployment Checklist Item 2)
- Restart deployment

---

### Issue 3: Scene Loading Fails

**Symptoms:**
- Scene load requests return 403 Forbidden

**Diagnosis:**
```bash
# Check environment
curl http://127.0.0.1:8080/status | jq .environment
# Should be "production"

# Check scene whitelist
cat config/scene_whitelist.json | jq '.environments.production.scenes'
```

**Solution:**
```bash
# Ensure GODOT_ENV=production
export GODOT_ENV=production

# Or add scene to production whitelist
# Edit config/scene_whitelist.json
# Restart deployment
```

---

### Issue 4: Port 8080 Already in Use

**Diagnosis:**
```bash
# Find process using port
sudo lsof -i :8080
# or
sudo netstat -tulpn | grep :8080
```

**Solution:**
```bash
# Kill conflicting process
sudo kill -9 <PID>

# Or change port (not recommended)
```

---

### More Troubleshooting

See `docs/DEPLOYMENT_GUIDE.md` Section 9 for complete troubleshooting guide.

---

## 7. Contacts and Escalation

### Emergency Contacts (24/7)

**Critical Production Issues:**
- On-call engineer: [Phone] / [Email]
- Escalation to tech lead: [Phone] / [Email]

**Call immediately if:**
- API down for >5 minutes
- Multiple pods crashing
- Security breach suspected
- Data loss suspected

---

### Regular Support

**Non-Critical Issues:**
- Email: support@yourdomain.com
- Slack: #spacetime-deployment
- Jira: [Project Key]

**Response Times:**
- P0 (Critical): 15 minutes
- P1 (High): 2 hours
- P2 (Medium): 1 business day
- P3 (Low): 3 business days

---

### Escalation Path

1. **Level 1:** Deployment engineer investigates
2. **Level 2:** DevOps lead reviews (after 30 minutes)
3. **Level 3:** Tech lead engages (after 1 hour)
4. **Level 4:** CTO notified (after 2 hours or data loss)

---

## Document Metadata

**Version:** 1.0.0
**Created:** 2025-12-04
**Maintained By:** SpaceTime Development Team
**Next Review:** After first production deployment

**Related Documents:**
- `README.md` - Package overview
- `CHECKLIST.md` - Deployment checklist
- `docs/DEPLOYMENT_GUIDE.md` - Comprehensive deployment guide

---

**END OF RUNBOOK**
