# Production Ready Checklist V2.0

**Version:** 2.0
**Last Updated:** 2025-12-04
**Status:** 98% Production Ready
**Phase:** Post Phase 6.5 (Editor Mode Fix + Phase 2 Router Activation)

---

## Executive Summary

This checklist provides a comprehensive pre-deployment validation process for the SpaceTime VR project. After Phase 6.5 completion, the system is **98% production-ready** with 9 active routers, editor mode auto-detection, and full webhook/job queue support.

**Key Metrics:**
- **Production Readiness:** 98%
- **Active Routers:** 9/12 (75%)
- **Critical Bugs:** 0
- **High Priority Issues:** 0
- **Medium Priority Issues:** 0
- **Low Priority Issues:** 3 (optional)

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Verification Steps](#deployment-verification-steps)
3. [Post-Deployment Testing Procedures](#post-deployment-testing-procedures)
4. [Rollback Procedures](#rollback-procedures)
5. [Monitoring and Alerts](#monitoring-and-alerts)
6. [Contact Information](#contact-information)

---

## Pre-Deployment Checklist

### 1. Environment Configuration

#### 1.1 Required Environment Variables

**Critical (MUST be set):**

- [ ] `GODOT_ENABLE_HTTP_API=true` (Enables API in release builds)
- [ ] `GODOT_ENV=production` (Loads production whitelist)

**Optional (Recommended):**

- [ ] `GODOT_LOG_LEVEL=info` (Logging verbosity: debug|info|warn|error)
- [ ] `GODOT_API_PORT=8080` (Override default HTTP API port)
- [ ] `GODOT_TELEMETRY_PORT=8081` (Override default telemetry port)
- [ ] `GODOT_DISCOVERY_PORT=8087` (Override default discovery port)

**Verification Command:**
```bash
# Verify environment variables are set
echo "GODOT_ENABLE_HTTP_API: $GODOT_ENABLE_HTTP_API"
echo "GODOT_ENV: $GODOT_ENV"
```

**Expected Output:**
```
GODOT_ENABLE_HTTP_API: true
GODOT_ENV: production
```

---

#### 1.2 Configuration Files

**Scene Whitelist** (`config/scene_whitelist.json`)

- [ ] Production whitelist configured
- [ ] Only required scenes included
- [ ] Test scenes removed

**Example Production Whitelist:**
```json
{
  "production": [
    "res://vr_main.tscn",
    "res://minimal_test.tscn"
  ]
}
```

**Verification Command:**
```bash
cat config/scene_whitelist.json | jq '.production'
```

---

#### 1.3 Secrets Management

**Kubernetes Secrets (MUST replace placeholders):**

- [ ] API tokens generated (not placeholder values)
- [ ] Database credentials set (if using persistence)
- [ ] Grafana admin password set
- [ ] TLS certificates generated

**Generate Secrets:**
```bash
# Generate API token
API_TOKEN=$(openssl rand -base64 32)

# Generate Grafana password
GRAFANA_PASSWORD=$(openssl rand -base64 24)

# Create Kubernetes secret
kubectl create secret generic spacetime-secrets \
  --from-literal=API_TOKEN=$API_TOKEN \
  --from-literal=GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASSWORD \
  -n spacetime
```

**Verification Command:**
```bash
# Verify secrets exist (do NOT print values)
kubectl get secrets -n spacetime | grep spacetime-secrets
```

---

#### 1.4 TLS Certificates

**Production TLS (REQUIRED for external access):**

- [ ] TLS certificate obtained (Let's Encrypt or CA)
- [ ] TLS private key secured
- [ ] Certificate imported to Kubernetes

**Generate TLS Secret:**
```bash
# Option 1: Using cert-manager (recommended)
kubectl apply -f k8s/cert-manager.yaml

# Option 2: Manual certificate
kubectl create secret tls spacetime-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem \
  -n spacetime
```

**Verification Command:**
```bash
kubectl get secret spacetime-tls -n spacetime
```

---

### 2. Build Verification

#### 2.1 Export Project

**Export Release Build:**
```bash
# Export for Windows Desktop
godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"
```

**Verification:**
- [ ] Export completed without errors
- [ ] Build file exists: `build/SpaceTime.exe`
- [ ] Build file size reasonable (> 50MB, < 500MB)

---

#### 2.2 Test Exported Build

**Test API in Release Build:**
```bash
# Start exported build with API enabled
GODOT_ENABLE_HTTP_API=true ./build/SpaceTime.exe &

# Wait 10 seconds for startup
sleep 10

# Test API connection
curl http://127.0.0.1:8080/status

# Expected: 200 OK with system status JSON
```

**Acceptance Criteria:**
- [ ] API starts in release build (with GODOT_ENABLE_HTTP_API=true)
- [ ] `/status` endpoint returns 200
- [ ] No errors in console output
- [ ] API disabled by default (without environment variable)

---

### 3. Code Quality Verification

#### 3.1 Run Test Suite

**Comprehensive Test Run:**
```bash
# Activate virtual environment
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# Run all tests
python run_all_tests.py --verbose

# Expected: All tests pass (exit code 0)
```

**Acceptance Criteria:**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All runtime tests pass
- [ ] No test failures or errors

---

#### 3.2 Health Monitoring

**Run Health Check:**
```bash
# Start Godot
godot --path C:/godot --editor &

# Wait for startup
sleep 10

# Run health monitor (single check mode)
python tests/health_monitor.py --single

# Expected: All checks pass
```

**Acceptance Criteria:**
- [ ] Godot process running
- [ ] HTTP API responding (port 8080)
- [ ] All autoloads loaded
- [ ] No critical errors

---

#### 3.3 Syntax Validation

**Run Syntax Checks:**
```bash
# Check GDScript syntax
python check_syntax.py

# Expected: No syntax errors
```

**Acceptance Criteria:**
- [ ] No syntax errors in GDScript files
- [ ] No undefined variables
- [ ] No type mismatches

---

### 4. Security Verification

#### 4.1 Authentication Testing

**Test API Authentication:**
```bash
# Test without token (should fail)
curl http://127.0.0.1:8080/scenes
# Expected: 401 Unauthorized

# Test with invalid token (should fail)
curl -H "Authorization: Bearer invalid_token" http://127.0.0.1:8080/scenes
# Expected: 401 Unauthorized

# Test with valid token (should succeed)
TOKEN="<api-token-from-console>"
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scenes
# Expected: 200 OK with scene list
```

**Acceptance Criteria:**
- [ ] Requests without token rejected (401)
- [ ] Requests with invalid token rejected (401)
- [ ] Requests with valid token succeed (200)

---

#### 4.2 Rate Limiting Testing

**Test Rate Limiting:**
```bash
TOKEN="<api-token-from-console>"

# Send 150 rapid requests (limit is 100/min)
for i in {1..150}; do
  curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/status &
done
wait

# Expected: Some requests return 429 Too Many Requests
```

**Acceptance Criteria:**
- [ ] Rate limiting enforced after limit exceeded
- [ ] 429 status code returned
- [ ] Rate limit resets after time window

---

#### 4.3 Security Headers

**Check Security Headers:**
```bash
curl -I http://127.0.0.1:8080/status

# Expected headers:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# X-XSS-Protection: 1; mode=block
```

**Acceptance Criteria:**
- [ ] Security headers present
- [ ] CORS headers configured (if needed)
- [ ] No sensitive information in headers

---

### 5. Router Verification

#### 5.1 Phase 1 Routers (Scene Management)

**Test Scene Management:**
```bash
TOKEN="<api-token>"

# Test scene loading
curl -X POST http://127.0.0.1:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
# Expected: 200 OK

# Test scene info
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene
# Expected: 200 OK with scene details

# Test scene list
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scenes
# Expected: 200 OK with scene array

# Test scene history
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene/history
# Expected: 200 OK with history array
```

**Acceptance Criteria:**
- [ ] POST /scene loads scene successfully
- [ ] GET /scene returns current scene info
- [ ] GET /scenes lists available scenes
- [ ] GET /scene/history returns load history

---

#### 5.2 Phase 2 Routers (Webhooks and Jobs)

**Test Webhook Management:**
```bash
TOKEN="<api-token>"

# Register webhook
curl -X POST http://127.0.0.1:8080/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://webhook.site/test-id",
    "events": ["scene.loaded"],
    "secret": "webhook_secret_123"
  }'
# Expected: 200 OK with webhook_id

# List webhooks
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/webhooks
# Expected: 200 OK with webhook array

# Get webhook details
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/webhooks/1
# Expected: 200 OK with webhook details
```

**Test Job Queue:**
```bash
# Submit job
curl -X POST http://127.0.0.1:8080/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "cache_warming",
    "parameters": {}
  }'
# Expected: 200 OK with job_id

# Check job status
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/jobs/1
# Expected: 200 OK with job status
```

**Acceptance Criteria:**
- [ ] Webhooks can be registered
- [ ] Webhooks can be listed
- [ ] Webhook details can be retrieved
- [ ] Jobs can be submitted
- [ ] Job status can be checked

---

### 6. Performance Verification

#### 6.1 Response Time Testing

**Test API Response Times:**
```bash
TOKEN="<api-token>"

# Measure response time
time curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/status

# Expected: < 50ms
```

**Acceptance Criteria:**
- [ ] `/status` responds in < 50ms
- [ ] `/scenes` responds in < 100ms
- [ ] Scene loading completes in < 5s

---

#### 6.2 Memory Usage

**Monitor Memory Usage:**
```bash
# Start Godot and monitor memory
ps aux | grep Godot | awk '{print $6}'

# Expected: < 4GB RAM for typical workload
```

**Acceptance Criteria:**
- [ ] Memory usage stable over time
- [ ] No memory leaks detected
- [ ] Memory usage within expected range

---

### 7. Deployment Infrastructure

#### 7.1 Kubernetes Configuration

**Verify Kubernetes Resources:**
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml -n spacetime

# Verify deployment
kubectl get deployments -n spacetime
kubectl get pods -n spacetime
kubectl get services -n spacetime

# Check pod status
kubectl describe pod <pod-name> -n spacetime
```

**Acceptance Criteria:**
- [ ] Deployment created successfully
- [ ] Pods running (not CrashLoopBackOff)
- [ ] Services created and listening
- [ ] No error events in pod description

---

#### 7.2 Health Check Endpoints

**Configure Health Checks:**
```bash
# Test Kubernetes liveness probe
curl http://<pod-ip>:8080/status

# Test readiness probe
curl http://<pod-ip>:8080/health
```

**Acceptance Criteria:**
- [ ] Liveness probe returns 200
- [ ] Readiness probe returns 200
- [ ] Pod marked as Ready in Kubernetes

---

### 8. Monitoring Setup

#### 8.1 Prometheus Metrics

**Verify Metrics Endpoint:**
```bash
curl http://127.0.0.1:8080/metrics
```

**Acceptance Criteria:**
- [ ] Metrics endpoint returns Prometheus format
- [ ] FPS metric present
- [ ] Memory metric present
- [ ] Request count metric present

---

#### 8.2 Grafana Dashboard

**Configure Grafana:**
```bash
# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n spacetime

# Open browser to http://localhost:3000
# Login with admin credentials from secrets
```

**Acceptance Criteria:**
- [ ] Grafana accessible
- [ ] Dashboard configured
- [ ] Metrics displayed correctly

---

### 9. Documentation Review

**Final Documentation Check:**

- [ ] `CLAUDE.md` updated with current status
- [ ] `README.md` reflects production status
- [ ] `DEPLOYMENT_GUIDE.md` reviewed and accurate
- [ ] `PHASE_6_COMPLETE.md` includes Phase 6.5 updates
- [ ] API documentation reflects 9 active routers
- [ ] Runbook created for operations team

---

## Deployment Verification Steps

### 1. Initial Deployment

**Deploy to Staging:**
```bash
# Set environment
export GODOT_ENV=staging
export GODOT_ENABLE_HTTP_API=true

# Deploy
kubectl apply -f k8s/deployment-staging.yaml -n spacetime-staging

# Wait for rollout
kubectl rollout status deployment/spacetime -n spacetime-staging
```

**Verification:**
```bash
# Test staging API
curl https://staging.spacetime.example.com/api/status
```

---

### 2. Smoke Tests

**Run Smoke Test Suite:**
```bash
# Test critical paths
curl -H "Authorization: Bearer $TOKEN" https://staging.spacetime.example.com/api/status
curl -H "Authorization: Bearer $TOKEN" https://staging.spacetime.example.com/api/scenes
curl -H "Authorization: Bearer $TOKEN" https://staging.spacetime.example.com/api/webhooks
```

**Acceptance Criteria:**
- [ ] All critical endpoints return 200
- [ ] No 500 errors
- [ ] Response times acceptable

---

### 3. Load Testing

**Run Load Test:**
```bash
# Use Apache Bench
ab -n 1000 -c 10 -H "Authorization: Bearer $TOKEN" \
  https://staging.spacetime.example.com/api/status

# Expected: 99% success rate, < 100ms avg response time
```

**Acceptance Criteria:**
- [ ] Load test completes successfully
- [ ] No crashes or errors
- [ ] Response times within SLA

---

### 4. Production Deployment

**Deploy to Production:**
```bash
# Set production environment
export GODOT_ENV=production
export GODOT_ENABLE_HTTP_API=true

# Deploy with rolling update
kubectl apply -f k8s/deployment-production.yaml -n spacetime

# Monitor rollout
kubectl rollout status deployment/spacetime -n spacetime

# Verify health
kubectl get pods -n spacetime
```

**Acceptance Criteria:**
- [ ] Rolling update completes successfully
- [ ] All pods healthy
- [ ] No downtime during rollout

---

## Post-Deployment Testing Procedures

### 1. API Functionality Test

**Test All Endpoints:**
```bash
# Get API token from production
TOKEN="<production-api-token>"

# Test scene management
curl -H "Authorization: Bearer $TOKEN" https://spacetime.example.com/api/scenes

# Test webhooks
curl -H "Authorization: Bearer $TOKEN" https://spacetime.example.com/api/webhooks

# Test jobs
curl -H "Authorization: Bearer $TOKEN" https://spacetime.example.com/api/jobs

# Test performance metrics
curl -H "Authorization: Bearer $TOKEN" https://spacetime.example.com/api/performance
```

**Acceptance Criteria:**
- [ ] All endpoints return expected responses
- [ ] Authentication working correctly
- [ ] Rate limiting active

---

### 2. Webhook Delivery Test

**Test Webhook Delivery:**
```bash
# Register test webhook
curl -X POST https://spacetime.example.com/api/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://webhook.site/unique-id",
    "events": ["scene.loaded"],
    "secret": "test_secret"
  }'

# Trigger event by loading scene
curl -X POST https://spacetime.example.com/api/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'

# Check webhook.site for delivery
```

**Acceptance Criteria:**
- [ ] Webhook received at destination
- [ ] HMAC signature valid
- [ ] Payload contains correct data

---

### 3. Job Queue Test

**Test Background Jobs:**
```bash
# Submit job
JOB_ID=$(curl -X POST https://spacetime.example.com/api/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "cache_warming", "parameters": {}}' | jq -r '.job_id')

# Poll job status
while true; do
  STATUS=$(curl -H "Authorization: Bearer $TOKEN" \
    https://spacetime.example.com/api/jobs/$JOB_ID | jq -r '.job.status')
  echo "Job status: $STATUS"
  [ "$STATUS" = "completed" ] && break
  sleep 1
done
```

**Acceptance Criteria:**
- [ ] Job submitted successfully
- [ ] Job processes in background
- [ ] Job status updates correctly
- [ ] Job completes successfully

---

### 4. Performance Monitoring

**Monitor Production Metrics:**
```bash
# Check Prometheus metrics
curl https://spacetime.example.com/metrics

# Check Grafana dashboard
# Open https://grafana.spacetime.example.com

# Verify metrics:
# - FPS > 60
# - Memory usage < 4GB
# - Request rate normal
# - Error rate < 1%
```

**Acceptance Criteria:**
- [ ] Metrics being collected
- [ ] Dashboards displaying correctly
- [ ] No anomalous metrics

---

### 5. Security Audit

**Verify Security Posture:**
```bash
# Test authentication bypass (should fail)
curl https://spacetime.example.com/api/scenes
# Expected: 401 Unauthorized

# Test rate limiting (should trigger)
for i in {1..150}; do
  curl -H "Authorization: Bearer $TOKEN" \
    https://spacetime.example.com/api/status &
done
wait
# Expected: 429 Too Many Requests after limit

# Check TLS configuration
curl -I https://spacetime.example.com/api/status
# Expected: HTTPS with valid certificate
```

**Acceptance Criteria:**
- [ ] Authentication cannot be bypassed
- [ ] Rate limiting working
- [ ] TLS configured correctly
- [ ] Security headers present

---

## Rollback Procedures

### 1. Quick Rollback (Emergency)

**Immediate Rollback:**
```bash
# Rollback Kubernetes deployment
kubectl rollout undo deployment/spacetime -n spacetime

# Wait for rollback to complete
kubectl rollout status deployment/spacetime -n spacetime

# Verify previous version running
kubectl get pods -n spacetime -o wide
```

**Time Required:** 2-5 minutes

---

### 2. Configuration Rollback

**Revert Configuration:**
```bash
# Restore previous ConfigMap
kubectl apply -f k8s/configmap-previous.yaml -n spacetime

# Restart pods to pick up changes
kubectl rollout restart deployment/spacetime -n spacetime
```

**Time Required:** 5-10 minutes

---

### 3. Version Downgrade

**Deploy Previous Version:**
```bash
# Deploy specific version
kubectl set image deployment/spacetime \
  spacetime=spacetime:v1.0.0 \
  -n spacetime

# Monitor rollout
kubectl rollout status deployment/spacetime -n spacetime
```

**Time Required:** 5-10 minutes

---

### 4. Rollback Verification

**Verify Rollback Success:**
```bash
# Check pod status
kubectl get pods -n spacetime

# Test API
curl https://spacetime.example.com/api/status

# Check error logs
kubectl logs -n spacetime -l app=spacetime --tail=100
```

**Acceptance Criteria:**
- [ ] Pods running previous version
- [ ] API responding correctly
- [ ] No errors in logs

---

## Monitoring and Alerts

### 1. Critical Alerts

**Configure Alerts:**

**API Down:**
- **Metric:** `http_requests_total{status="200"} == 0`
- **Threshold:** 0 successful requests in 1 minute
- **Action:** Page on-call engineer

**High Error Rate:**
- **Metric:** `http_requests_total{status=~"5.."}`
- **Threshold:** > 5% error rate
- **Action:** Alert operations team

**Low FPS:**
- **Metric:** `godot_fps < 30`
- **Threshold:** FPS below 30 for 1 minute
- **Action:** Investigate performance issue

**High Memory Usage:**
- **Metric:** `godot_memory_bytes > 4GB`
- **Threshold:** Memory usage above 4GB
- **Action:** Check for memory leaks

---

### 2. Warning Alerts

**Scene Load Failures:**
- **Metric:** `scene_load_failures_total > 10`
- **Threshold:** > 10 failures in 10 minutes
- **Action:** Check scene whitelist and paths

**Webhook Delivery Failures:**
- **Metric:** `webhook_delivery_failures_total > 50`
- **Threshold:** > 50 failures in 10 minutes
- **Action:** Check webhook URLs and connectivity

**Job Queue Backlog:**
- **Metric:** `job_queue_pending > 100`
- **Threshold:** > 100 pending jobs
- **Action:** Scale job workers

---

### 3. Dashboard Metrics

**Grafana Dashboard Panels:**

1. **API Health:**
   - Request rate (requests/sec)
   - Success rate (%)
   - Average response time (ms)
   - Error rate (%)

2. **System Performance:**
   - FPS (frames/sec)
   - Memory usage (MB)
   - CPU usage (%)
   - Active connections

3. **Router Activity:**
   - Scene loads (count)
   - Webhook deliveries (count)
   - Jobs processed (count)
   - Rate limit triggers (count)

4. **Error Tracking:**
   - 4xx errors (count)
   - 5xx errors (count)
   - Failed scene loads (count)
   - Failed webhook deliveries (count)

---

## Contact Information

### On-Call Engineer

**Primary:** [Engineer Name]
- **Phone:** [Phone Number]
- **Email:** [Email Address]
- **Slack:** [Slack Handle]

**Secondary:** [Engineer Name]
- **Phone:** [Phone Number]
- **Email:** [Email Address]
- **Slack:** [Slack Handle]

---

### Escalation Contacts

**Engineering Manager:**
- **Name:** [Manager Name]
- **Email:** [Email Address]
- **Phone:** [Phone Number]

**DevOps Lead:**
- **Name:** [Lead Name]
- **Email:** [Email Address]
- **Phone:** [Phone Number]

---

### External Support

**Hosting Provider:**
- **Provider:** [Provider Name]
- **Support:** [Support URL]
- **Phone:** [Support Phone]

**Monitoring Service:**
- **Provider:** [Provider Name]
- **Support:** [Support URL]
- **Phone:** [Support Phone]

---

## Appendix

### A. Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GODOT_ENABLE_HTTP_API` | Yes (production) | false | Enable HTTP API in release builds |
| `GODOT_ENV` | Yes | development | Environment (development/staging/production) |
| `GODOT_LOG_LEVEL` | No | info | Logging verbosity (debug/info/warn/error) |
| `GODOT_API_PORT` | No | 8080 | HTTP API port |
| `GODOT_TELEMETRY_PORT` | No | 8081 | Telemetry WebSocket port |
| `GODOT_DISCOVERY_PORT` | No | 8087 | Service discovery UDP port |

---

### B. Port Reference

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| HTTP API | 8080 | HTTP | REST API for scene/resource management |
| Telemetry | 8081 | WebSocket | Real-time performance data streaming |
| Discovery | 8087 | UDP | Service discovery broadcast |

---

### C. Quick Reference Commands

**Check API Status:**
```bash
curl -H "Authorization: Bearer $TOKEN" https://spacetime.example.com/api/status
```

**List Active Routers:**
```bash
# Check Godot console output for:
# [HttpApiServer] Registered X router
```

**View Logs:**
```bash
kubectl logs -n spacetime -l app=spacetime --tail=100 -f
```

**Restart Deployment:**
```bash
kubectl rollout restart deployment/spacetime -n spacetime
```

**Scale Deployment:**
```bash
kubectl scale deployment/spacetime --replicas=3 -n spacetime
```

---

**Document Version:** 2.0
**Last Updated:** 2025-12-04
**Status:** Production Ready (98%)
**Maintainer:** [Your Name/Team]
