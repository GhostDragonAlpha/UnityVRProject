# Production Deployment Runbook

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Deployment Procedure](#deployment-procedure)
4. [Post-Deployment Validation](#post-deployment-validation)
5. [Rollback Procedures](#rollback-procedures)
6. [Common Deployment Issues](#common-deployment-issues)
7. [Emergency Contacts](#emergency-contacts)

---

## Overview

### Purpose
This runbook provides step-by-step procedures for deploying the SpaceTime HTTP Scene Management API and related services to production environments.

### Deployment Window
- **Standard Deployment:** Tuesday/Thursday 10:00-12:00 UTC
- **Emergency Deployment:** As needed, with manager approval
- **Blackout Periods:** Major holidays, peak usage hours (18:00-22:00 UTC)

### Expected Duration
- **Standard Deployment:** 45-60 minutes
- **Emergency Hotfix:** 15-30 minutes
- **Major Version Upgrade:** 2-3 hours

### Required Access
- Production server SSH access
- GitHub repository read access
- Monitoring dashboard access (Grafana/Prometheus)
- PagerDuty access for alerting
- DNS management console (if needed)

---

## Pre-Deployment Checklist

### 1. Environment Verification

#### 1.1 Server Resources
```bash
# Check disk space (need minimum 20GB free)
df -h /opt/spacetime

# Expected output: At least 20GB available
# /dev/sda1       100G   60G   40G   60% /opt/spacetime

# Check memory availability (need minimum 8GB free)
free -h

# Expected output: At least 8GB available
#               total        used        free      shared  buff/cache   available
# Mem:            32G         12G         8G        1.0G        12G         18G

# Check CPU load
uptime

# Expected output: Load average should be < 4.0 on 8-core system
# 10:23:45 up 30 days, 14:23,  1 user,  load average: 1.24, 1.45, 1.67
```

**Verification Steps:**
- [ ] Disk space >= 20GB free
- [ ] Memory >= 8GB available
- [ ] Load average < (cores * 0.5)
- [ ] No disk errors in dmesg
- [ ] File system is read/write

**Rollback Point:** If resources insufficient, stop deployment and investigate

---

#### 1.2 Network Configuration
```bash
# Verify firewall rules
sudo iptables -L -n | grep -E "6005|6006|8081|8080"

# Expected output: ACCEPT rules for required ports
# ACCEPT     tcp  --  0.0.0.0/0    0.0.0.0/0    tcp dpt:6005
# ACCEPT     tcp  --  0.0.0.0/0    0.0.0.0/0    tcp dpt:6006
# ACCEPT     tcp  --  0.0.0.0/0    0.0.0.0/0    tcp dpt:8081
# ACCEPT     tcp  --  0.0.0.0/0    0.0.0.0/0    tcp dpt:8080

# Check port availability
sudo netstat -tlnp | grep -E "6005|6006|8081|8080"

# Expected output: Ports should be free or show Godot processes
# If ports are occupied by other processes, deployment will fail

# Test internal DNS resolution
nslookup spacetime-api.internal.company.com

# Expected output: Valid A record
# Server:         10.0.0.1
# Address:        10.0.0.1#53
# Name:   spacetime-api.internal.company.com
# Address: 10.0.1.50
```

**Verification Steps:**
- [ ] Firewall rules allow ports 6005, 6006, 8081, 8080
- [ ] Ports 8080-8085 are free or occupied by Godot
- [ ] DNS resolution works for internal hostname
- [ ] Network latency < 10ms to monitoring servers
- [ ] Load balancer health check configured

**Rollback Point:** If network issues found, resolve before proceeding

---

#### 1.3 Security Group Setup
```bash
# Verify security groups (AWS example)
aws ec2 describe-security-groups --group-ids sg-xxxxx --query 'SecurityGroups[0].IpPermissions'

# Expected output: Rules allowing required ports from approved sources
# [
#     {
#         "FromPort": 8080,
#         "IpProtocol": "tcp",
#         "IpRanges": [
#             {
#                 "CidrIp": "10.0.0.0/8",
#                 "Description": "Internal API access"
#             }
#         ],
#         "ToPort": 8080
#     }
# ]

# Check TLS certificate validity
openssl x509 -in /etc/ssl/certs/spacetime-api.crt -noout -dates

# Expected output: Valid dates, not expiring within 30 days
# notBefore=Jan  1 00:00:00 2025 GMT
# notAfter=Dec 31 23:59:59 2025 GMT
```

**Verification Steps:**
- [ ] Security groups allow required ports
- [ ] Source IP restrictions are correct
- [ ] TLS certificates valid for >= 30 days
- [ ] API tokens are rotated and valid
- [ ] SSH key access is configured

**Rollback Point:** If security configuration is incorrect, halt deployment

---

#### 1.4 DNS Configuration
```bash
# Check current DNS records
dig spacetime-api.company.com +short

# Expected output: Current production IP
# 10.0.1.50

# Check DNS TTL (should be low before deployment for quick rollback)
dig spacetime-api.company.com +noall +answer

# Expected output: TTL should be 300 (5 minutes) or lower before deployment
# spacetime-api.company.com. 300 IN A 10.0.1.50

# Verify health check endpoint
curl -s http://10.0.1.50:8080/status | jq .overall_ready

# Expected output: true
```

**Verification Steps:**
- [ ] DNS records point to current production
- [ ] TTL reduced to 300 seconds
- [ ] Health check endpoint responds
- [ ] Load balancer is healthy
- [ ] CDN cache is cleared (if applicable)

**Rollback Point:** If DNS issues found, resolve before proceeding

---

### 2. Code and Dependencies

#### 2.1 Version Verification
```bash
# Verify Git tag/branch
cd /opt/spacetime/staging
git fetch --tags
git describe --tags

# Expected output: Version tag matching release notes
# v2.5.0

# Check commit hash matches release
git rev-parse HEAD

# Expected output: Commit hash from release notes
# abc123def456...

# Verify no uncommitted changes
git status

# Expected output: Clean working directory
# On branch main
# nothing to commit, working tree clean
```

**Verification Steps:**
- [ ] Git tag matches release version
- [ ] Commit hash verified against release notes
- [ ] No uncommitted changes in staging
- [ ] Branch is up-to-date with origin
- [ ] Release notes reviewed

**Rollback Point:** If version mismatch, halt and investigate

---

#### 2.2 Dependency Check
```bash
# Verify Godot version
godot --version

# Expected output: 4.5 or higher
# 4.5.0.stable.official

# Check Python dependencies (for testing tools)
python3 --version
pip3 list | grep -E "requests|websockets"

# Expected output: Required versions
# requests       2.31.0
# websockets     12.0

# Verify addon is present
ls -la /opt/spacetime/staging/addons/godot_debug_connection/

# Expected output: Plugin files present
# -rw-r--r-- 1 app app  32790 Dec  2 10:00 godot_bridge.gd
# -rw-r--r-- 1 app app  12068 Dec  2 10:00 HTTP_API.md
# ...
```

**Verification Steps:**
- [ ] Godot version >= 4.5.0
- [ ] Python 3.8+ installed
- [ ] Required Python packages installed
- [ ] Addon files present and readable
- [ ] No file permission issues

**Rollback Point:** If dependencies missing, install before proceeding

---

### 3. Backup Verification

#### 3.1 Current State Backup
```bash
# Backup current production code
cd /opt/spacetime
tar -czf backups/production_pre_deploy_$(date +%Y%m%d_%H%M%S).tar.gz production/

# Expected output: Successful compression
# Verify backup size is reasonable (> 100MB)
ls -lh backups/production_pre_deploy_*.tar.gz | tail -1

# Backup configuration files
cp production/project.godot backups/project.godot.$(date +%Y%m%d_%H%M%S)
cp production/.env backups/.env.$(date +%Y%m%d_%H%M%S)

# Backup database (if applicable)
# pg_dump spacetime_db > backups/db_$(date +%Y%m%d_%H%M%S).sql
```

**Verification Steps:**
- [ ] Production code backup created
- [ ] Backup size is reasonable (> 100MB)
- [ ] Configuration files backed up
- [ ] Database backed up (if applicable)
- [ ] Backups stored in separate location
- [ ] Backup integrity verified (test extract)

**Rollback Point:** DO NOT PROCEED without valid backups

---

### 4. Pre-Deployment Tests

#### 4.1 Staging Environment Tests
```bash
# Start staging environment
cd /opt/spacetime/staging
./restart_godot_with_debug.bat  # Or equivalent for Linux

# Wait 10 seconds for services to start
sleep 10

# Run health checks
cd tests
python3 health_monitor.py

# Expected output: All checks pass
# ✓ HTTP API reachable on port 8080
# ✓ Telemetry server reachable on port 8081
# ✓ DAP service available on port 6006
# ✓ LSP service available on port 6005
# ✓ Overall system status: READY

# Run automated test suite
python3 test_runner.py

# Expected output: All tests pass
# ================================================
# Test Suite Results
# ================================================
# Total Tests: 47
# Passed: 47
# Failed: 0
# Success Rate: 100.0%
```

**Verification Steps:**
- [ ] Staging environment starts successfully
- [ ] All health checks pass
- [ ] Automated test suite passes 100%
- [ ] No errors in logs
- [ ] Performance metrics acceptable

**Rollback Point:** If tests fail, fix issues before deploying to production

---

#### 4.2 Load Testing
```bash
# Run load test against staging
cd tests/load
python3 load_test.py --target http://staging-api:8080 --duration 300 --users 50

# Expected output: Performance within SLA
# ================================================
# Load Test Results
# ================================================
# Total Requests: 15,000
# Success Rate: 99.8%
# Average Response Time: 45ms
# 95th Percentile: 120ms
# 99th Percentile: 250ms
# Max Response Time: 450ms
# Errors: 30 (0.2%)

# Check resource usage during load test
ssh staging-server "top -bn1 | head -20"

# Expected output: CPU < 80%, Memory < 80%
```

**Verification Steps:**
- [ ] Load test completes successfully
- [ ] Success rate >= 99.5%
- [ ] Average response time < 100ms
- [ ] 95th percentile < 200ms
- [ ] CPU usage < 80% under load
- [ ] Memory usage < 80% under load
- [ ] No connection timeouts

**Rollback Point:** If performance issues found, optimize before deploying

---

## Deployment Procedure

### Step 1: Notification and Preparation

**Duration:** 5 minutes

```bash
# Send deployment notification
# - Post in #deployments Slack channel
# - Update status page: https://status.company.com
# - Notify on-call engineer

# Set maintenance mode (optional, for major updates)
curl -X POST http://api.company.com/maintenance/enable \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"reason": "Deployment v2.5.0", "duration": 60}'

# Expected response:
# {"status": "maintenance_enabled", "end_time": "2025-12-02T11:00:00Z"}
```

**Verification:**
- [ ] Deployment notification sent
- [ ] Status page updated
- [ ] On-call engineer acknowledged
- [ ] Maintenance mode enabled (if needed)

**Rollback Point:** Can abort deployment at this point with no impact

---

### Step 2: Stop Current Production Service

**Duration:** 2 minutes

```bash
# Stop Godot production service
sudo systemctl stop godot-spacetime

# Verify service stopped
sudo systemctl status godot-spacetime

# Expected output: inactive (dead)
# ● godot-spacetime.service - SpaceTime HTTP API
#    Loaded: loaded (/etc/systemd/system/godot-spacetime.service; enabled)
#    Active: inactive (dead)

# Verify ports are released
sudo netstat -tlnp | grep -E "6005|6006|8081|8080"

# Expected output: No processes listening
# (empty output)

# Check for lingering processes
ps aux | grep godot

# Expected output: Only grep process
# user     12345  0.0  0.0  grep godot
```

**Verification:**
- [ ] Service stopped cleanly
- [ ] Ports released
- [ ] No lingering processes
- [ ] Logs show clean shutdown

**Rollback Point:** If service won't stop, investigate before proceeding

---

### Step 3: Deploy New Version

**Duration:** 10 minutes

```bash
# Switch to deployment user
sudo su - spacetime-deploy

# Navigate to production directory
cd /opt/spacetime

# Backup current symlink
if [ -L production ]; then
  cp -P production production.backup
fi

# Deploy new version
rsync -av --delete staging/ production-v2.5.0/

# Expected output: Files synchronized
# sending incremental file list
# ...
# sent 150.2M bytes  received 12.3K bytes  4.2M bytes/sec
# total size is 450.8M  speedup is 3.0

# Update symlink
ln -sfn production-v2.5.0 production

# Verify symlink
ls -la production

# Expected output: Symlink to new version
# lrwxrwxrwx 1 app app 20 Dec  2 10:15 production -> production-v2.5.0

# Set correct permissions
chown -R spacetime-app:spacetime-app production-v2.5.0
chmod -R 755 production-v2.5.0
```

**Verification:**
- [ ] Files synchronized successfully
- [ ] Symlink updated to new version
- [ ] Permissions set correctly
- [ ] File ownership correct
- [ ] No rsync errors

**Rollback Point:** Can restore old symlink if issues found

---

### Step 4: Configuration Update

**Duration:** 5 minutes

```bash
# Update environment configuration
cd /opt/spacetime/production

# Copy environment-specific config
cp /opt/spacetime/config/production/.env .env

# Verify configuration
cat .env | grep -E "API_PORT|TELEMETRY_PORT|DAP_PORT|LSP_PORT"

# Expected output: Correct ports
# API_PORT=8080
# TELEMETRY_PORT=8081
# DAP_PORT=6006
# LSP_PORT=6005

# Update project.godot if needed (rare)
# Backup first
cp project.godot project.godot.backup

# Apply any configuration changes from deployment notes
# (Example: update autoload paths, enable/disable features)

# Verify project.godot syntax
grep -E "^\[autoload\]" project.godot -A 10

# Expected output: Autoload section with required services
# [autoload]
# ResonanceEngine="*res://scripts/core/engine.gd"
# GodotBridge="*res://addons/godot_debug_connection/godot_bridge.gd"
# TelemetryServer="*res://addons/godot_debug_connection/telemetry_server.gd"
```

**Verification:**
- [ ] Environment file updated
- [ ] Configuration values correct
- [ ] project.godot valid
- [ ] No syntax errors
- [ ] Secrets properly secured

**Rollback Point:** Can restore backed up configuration files

---

### Step 5: Start New Service

**Duration:** 5 minutes

```bash
# Start Godot service
sudo systemctl start godot-spacetime

# Check service status immediately
sudo systemctl status godot-spacetime

# Expected output: active (running)
# ● godot-spacetime.service - SpaceTime HTTP API
#    Loaded: loaded (/etc/systemd/system/godot-spacetime.service; enabled)
#    Active: active (running) since Tue 2025-12-02 10:20:00 UTC; 5s ago
#    Main PID: 12345 (godot)

# Wait for services to initialize (30 seconds)
echo "Waiting for services to start..."
sleep 30

# Monitor startup logs
sudo journalctl -u godot-spacetime -f --lines=50

# Expected output: Look for initialization messages
# Dec 02 10:20:05 godot[12345]: [GodotBridge] HTTP server started on port 8081
# Dec 02 10:20:06 godot[12345]: [TelemetryServer] WebSocket server started on port 8081
# Dec 02 10:20:07 godot[12345]: [ConnectionManager] DAP adapter connected
# Dec 02 10:20:08 godot[12345]: [ConnectionManager] LSP adapter connected
# Dec 02 10:20:10 godot[12345]: [ResonanceEngine] All subsystems initialized

# Press Ctrl+C to stop following logs
```

**Verification:**
- [ ] Service started successfully
- [ ] PID is stable (not restarting)
- [ ] Initialization logs look correct
- [ ] No error messages in logs

**Rollback Point:** If service fails to start, check logs and rollback

---

### Step 6: Service Health Checks

**Duration:** 5 minutes

```bash
# Check HTTP API
curl -s http://localhost:8080/status | jq .

# Expected output: Overall ready is true
# {
#   "debug_adapter": {
#     "service_name": "Debug Adapter",
#     "port": 6006,
#     "state": 2,
#     "retry_count": 0,
#     "last_activity": 1733139610.0
#   },
#   "language_server": {
#     "service_name": "Language Server",
#     "port": 6005,
#     "state": 2,
#     "retry_count": 0,
#     "last_activity": 1733139610.0
#   },
#   "overall_ready": true
# }

# Test connection endpoint
curl -X POST http://localhost:8080/connect

# Expected output: Connection initiated
# {"status": "connecting", "message": "Connection initiated"}

# Wait 5 seconds for connection to establish
sleep 5

# Verify connection established
curl -s http://localhost:8080/status | jq .overall_ready

# Expected output: true

# Check telemetry WebSocket
python3 << 'EOF'
import asyncio
import websockets
import json

async def test_telemetry():
    try:
        async with websockets.connect('ws://localhost:8081') as ws:
            msg = await asyncio.wait_for(ws.recv(), timeout=5)
            data = json.loads(msg)
            print(f"Telemetry connected: {data.get('event')}")
            return True
    except Exception as e:
        print(f"Telemetry failed: {e}")
        return False

result = asyncio.run(test_telemetry())
exit(0 if result else 1)
EOF

# Expected output: Telemetry connected: connected
```

**Verification:**
- [ ] HTTP API returns 200 status
- [ ] overall_ready is true
- [ ] Connection endpoint works
- [ ] Telemetry WebSocket connects
- [ ] No timeout errors

**Rollback Point:** If health checks fail, investigate or rollback

---

### Step 7: Functional Testing

**Duration:** 10 minutes

```bash
# Run post-deployment smoke tests
cd /opt/spacetime/production/tests

# Test basic API endpoints
python3 << 'EOF'
import requests
import sys

BASE_URL = "http://localhost:8080"

# Test status endpoint
r = requests.get(f"{BASE_URL}/status")
assert r.status_code == 200, "Status endpoint failed"
assert r.json()["overall_ready"] == True, "System not ready"

# Test connection endpoint
r = requests.post(f"{BASE_URL}/connect")
assert r.status_code == 200, "Connect endpoint failed"

print("✓ All smoke tests passed")
sys.exit(0)
EOF

# Expected output: All smoke tests passed

# Run health monitor
python3 health_monitor.py

# Expected output: All checks pass
# ✓ HTTP API reachable on port 8080
# ✓ Telemetry server reachable on port 8081
# ✓ DAP service available on port 6006
# ✓ LSP service available on port 6005
# ✓ Overall system status: READY

# Test scene management endpoints
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'

# Expected output: Scene loaded or already loaded
# {"status": "success", "message": "Scene loaded", "scene_path": "res://vr_main.tscn"}
```

**Verification:**
- [ ] Smoke tests pass 100%
- [ ] Health monitor shows green
- [ ] Scene management works
- [ ] No errors in logs during testing

**Rollback Point:** If functional tests fail, rollback immediately

---

### Step 8: Performance Verification

**Duration:** 5 minutes

```bash
# Check resource usage
top -bn1 | head -20

# Expected output: Reasonable CPU and memory usage
# CPU usage: < 20% idle time
# Memory: < 4GB used by Godot process

# Check response times
for i in {1..10}; do
  curl -o /dev/null -s -w "%{time_total}\n" http://localhost:8080/status
done | awk '{sum+=$1; count++} END {print "Average response time:", sum/count*1000, "ms"}'

# Expected output: Average < 100ms
# Average response time: 45 ms

# Monitor for 2 minutes
timeout 120 python3 tests/telemetry_client.py

# Expected output: Stable FPS, no errors
# FPS: 90.0, Frame Time: 11.1ms
# No error events
```

**Verification:**
- [ ] CPU usage normal (< 50%)
- [ ] Memory usage normal (< 4GB)
- [ ] Response times < 100ms
- [ ] FPS stable at 90
- [ ] No performance degradation

**Rollback Point:** If performance issues, investigate or rollback

---

### Step 9: Load Balancer Integration

**Duration:** 3 minutes

```bash
# Add server to load balancer
# (Example using AWS ALB)
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/spacetime-api/abcd1234 \
  --targets Id=i-1234567890abcdef0

# Wait for health check to pass
sleep 30

# Verify target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/spacetime-api/abcd1234

# Expected output: Health status is "healthy"
# {
#     "TargetHealthDescriptions": [
#         {
#             "Target": {"Id": "i-1234567890abcdef0", "Port": 8080},
#             "HealthCheckPort": "8080",
#             "TargetHealth": {"State": "healthy"}
#         }
#     ]
# }
```

**Verification:**
- [ ] Server registered with load balancer
- [ ] Health check passes
- [ ] Target status is "healthy"
- [ ] Traffic routing correctly

**Rollback Point:** If load balancer integration fails, deregister target

---

### Step 10: Final Validation

**Duration:** 5 minutes

```bash
# Disable maintenance mode
curl -X POST http://api.company.com/maintenance/disable \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Expected response:
# {"status": "maintenance_disabled"}

# Test from external network (use production domain)
curl -s https://spacetime-api.company.com/status | jq .overall_ready

# Expected output: true

# Check monitoring dashboards
# - Open Grafana: https://grafana.company.com/d/spacetime-api
# - Verify metrics are flowing
# - Check for any alert spikes

# Review logs for errors
sudo journalctl -u godot-spacetime --since "5 minutes ago" | grep -i error

# Expected output: No critical errors
# (Some warnings may be acceptable)

# Update deployment tracking
# - Mark deployment as complete in Jira/deployment system
# - Update version in inventory management
# - Post completion message in #deployments
```

**Verification:**
- [ ] Maintenance mode disabled
- [ ] External access works
- [ ] Monitoring shows healthy metrics
- [ ] No critical errors in logs
- [ ] Deployment tracked in systems
- [ ] Team notified of completion

**Deployment Complete!**

---

## Post-Deployment Validation

### Immediate Validation (0-30 minutes)

#### Monitor Key Metrics
```bash
# Watch metrics for 30 minutes
watch -n 30 'curl -s http://localhost:8080/status | jq .'

# Monitor error rates
# Check Grafana dashboard for:
# - HTTP 5xx error rate (should be < 0.1%)
# - Response time 95th percentile (should be < 200ms)
# - CPU usage (should be < 50%)
# - Memory usage (should be < 4GB)
```

**Validation Checklist:**
- [ ] No increase in error rates
- [ ] Response times within SLA
- [ ] CPU and memory stable
- [ ] No alerts triggered
- [ ] WebSocket connections stable

---

#### Review Logs
```bash
# Check for any errors or warnings
sudo journalctl -u godot-spacetime --since "30 minutes ago" | grep -E "ERROR|WARN" | tail -50

# Count error frequency
sudo journalctl -u godot-spacetime --since "30 minutes ago" | grep "ERROR" | wc -l

# Expected: < 10 errors in 30 minutes
```

**Validation Checklist:**
- [ ] Error count < 10 in 30 minutes
- [ ] No critical errors
- [ ] Warnings are expected/known
- [ ] No memory leak indicators

---

### Extended Validation (30 minutes - 2 hours)

#### Performance Trending
```bash
# Run automated load test against production
cd /opt/spacetime/production/tests/load
python3 production_load_test.py --duration 1800 --users 20

# Expected output: Performance within SLA
# Success Rate: >= 99.5%
# Average Response Time: < 100ms
# 95th Percentile: < 200ms
```

**Validation Checklist:**
- [ ] Load test passes
- [ ] No performance degradation
- [ ] Error rates remain low
- [ ] Resource usage stable

---

#### Database Integrity (if applicable)
```bash
# Check database connections
# psql -U spacetime -d spacetime_db -c "SELECT COUNT(*) FROM pg_stat_activity WHERE datname='spacetime_db';"

# Expected: Connection count < 100

# Verify data integrity
# python3 tests/data_integrity_check.py

# Expected: All integrity checks pass
```

**Validation Checklist:**
- [ ] Database connections normal
- [ ] Data integrity verified
- [ ] No connection pool exhaustion
- [ ] Query performance acceptable

---

### Full Validation (2-24 hours)

#### 24-Hour Observation
- Monitor dashboards every 2-4 hours
- Check for memory leaks (memory should not continuously grow)
- Review error logs at end of day
- Verify backup job runs successfully
- Check certificate expiry warnings

**Validation Checklist:**
- [ ] No memory leaks detected
- [ ] Daily backup completed
- [ ] No unexpected alerts
- [ ] User-reported issues < 3
- [ ] Monitoring shows stable trends

---

## Rollback Procedures

### When to Rollback

**Immediate Rollback Required:**
- Service fails to start after 3 attempts
- Error rate > 5%
- Response time 95th percentile > 500ms
- Critical security vulnerability discovered
- Data corruption detected
- Memory leak causing OOM

**Consider Rollback:**
- Error rate > 1%
- Response time 95th percentile > 300ms
- Multiple user-reported issues
- Unexpected behavior in critical features
- Resource usage > 80% continuously

---

### Emergency Rollback Procedure

**Duration:** 5-10 minutes

```bash
# Step 1: Stop current service
sudo systemctl stop godot-spacetime

# Step 2: Restore previous version symlink
cd /opt/spacetime
ln -sfn production.backup production
ls -la production  # Verify symlink restored

# Step 3: Restore configuration
cp backups/.env.$(ls -t backups/.env.* | head -1) production/.env
cp backups/project.godot.$(ls -t backups/project.godot.* | head -1) production/project.godot

# Step 4: Start service
sudo systemctl start godot-spacetime

# Step 5: Wait for startup
sleep 30

# Step 6: Verify health
curl -s http://localhost:8080/status | jq .overall_ready

# Expected output: true

# Step 7: Notify team
# Post in #incidents: "Rollback completed due to [REASON]"
```

**Rollback Verification:**
- [ ] Service started successfully
- [ ] Health check passes
- [ ] Previous version confirmed
- [ ] Error rate decreased
- [ ] Team notified

---

### Post-Rollback Actions

1. **Incident Report**
   - Create incident ticket with details
   - Document what went wrong
   - Identify root cause
   - Plan corrective actions

2. **Communication**
   - Update status page
   - Notify stakeholders
   - Explain rollback reason
   - Provide ETA for fix

3. **Investigation**
   - Analyze logs from failed deployment
   - Review test results
   - Identify gaps in testing
   - Update deployment procedures

---

## Common Deployment Issues

### Issue 1: Service Fails to Start

**Symptoms:**
- systemctl shows "failed" status
- Process exits immediately
- No PID assigned

**Investigation:**
```bash
# Check logs
sudo journalctl -u godot-spacetime -n 100

# Look for common errors:
# - "Port already in use"
# - "Permission denied"
# - "File not found"
# - "Segmentation fault"
```

**Solutions:**

**Port Already in Use:**
```bash
# Find process using port
sudo lsof -i :8080

# Kill process if safe
sudo kill -9 <PID>

# Or change port in config
echo "API_PORT=8083" >> production/.env
```

**Permission Denied:**
```bash
# Fix permissions
sudo chown -R spacetime-app:spacetime-app /opt/spacetime/production
chmod -R 755 /opt/spacetime/production
```

**File Not Found:**
```bash
# Verify files exist
ls -la /opt/spacetime/production/addons/godot_debug_connection/

# Re-sync from staging if needed
rsync -av staging/addons/godot_debug_connection/ production/addons/godot_debug_connection/
```

---

### Issue 2: Health Check Fails

**Symptoms:**
- /status endpoint returns 503
- overall_ready is false
- DAP or LSP not connected

**Investigation:**
```bash
# Check port availability
sudo netstat -tlnp | grep -E "6005|6006"

# Test DAP connection
telnet localhost 6006

# Test LSP connection
telnet localhost 6005

# Check Godot logs for connection errors
sudo journalctl -u godot-spacetime | grep -i "connection\|adapter"
```

**Solutions:**

**DAP/LSP Ports Blocked:**
```bash
# Check firewall
sudo iptables -L -n | grep -E "6005|6006"

# Add rules if needed
sudo iptables -I INPUT -p tcp --dport 6005 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 6006 -j ACCEPT
```

**Connection Timeout:**
```bash
# Increase timeout in config
# Edit production/addons/godot_debug_connection/connection_manager.gd
# CONNECT_TIMEOUT = 10  # Increase from default 5

# Restart service
sudo systemctl restart godot-spacetime
```

---

### Issue 3: High Error Rate

**Symptoms:**
- Multiple 500 errors in logs
- Error rate > 1%
- Specific endpoints failing

**Investigation:**
```bash
# Identify failing endpoints
sudo journalctl -u godot-spacetime | grep "HTTP 500" | awk '{print $NF}' | sort | uniq -c

# Check for pattern
# Example output:
#   45 /debug/evaluate
#    8 /scene/load
#    2 /lsp/completion

# Get stack traces
sudo journalctl -u godot-spacetime | grep -A 10 "ERROR"
```

**Solutions:**

**Resource Exhaustion:**
```bash
# Check limits
ulimit -a

# Increase file descriptors if needed
echo "spacetime-app soft nofile 65536" >> /etc/security/limits.conf
echo "spacetime-app hard nofile 65536" >> /etc/security/limits.conf
```

**Code Bug:**
```bash
# If specific endpoints failing, may need hotfix
# Rollback to previous version
# See Emergency Rollback Procedure above
```

---

### Issue 4: Slow Response Times

**Symptoms:**
- Response time > 300ms
- Timeouts occurring
- Users reporting slowness

**Investigation:**
```bash
# Profile response times by endpoint
for endpoint in /status /connect /scene/load; do
  echo "Testing $endpoint:"
  for i in {1..10}; do
    curl -o /dev/null -s -w "%{time_total}\n" http://localhost:8080$endpoint
  done | awk '{sum+=$1} END {print "Average:", sum/NR*1000, "ms"}'
done

# Check system resources
top -bn1 | head -20
iostat -x 1 10  # Check disk I/O
```

**Solutions:**

**High CPU:**
```bash
# Check for CPU-intensive processes
top -o %CPU

# If Godot using > 80% CPU, may need optimization
# Check for infinite loops or heavy computations in logs
```

**High I/O Wait:**
```bash
# Check disk performance
iostat -x 1 10

# If iowait > 20%, may need faster disks or caching
```

**Memory Swapping:**
```bash
# Check swap usage
free -h
vmstat 1 10

# If swap heavily used, increase memory or optimize code
```

---

### Issue 5: Memory Leak

**Symptoms:**
- Memory usage continuously grows
- OOM killer triggered
- Service crashes after hours/days

**Investigation:**
```bash
# Monitor memory over time
watch -n 60 'free -h && ps aux | grep godot | grep -v grep'

# Check for memory growth pattern
# Initial: 2.5GB
# After 1 hour: 3.2GB
# After 2 hours: 4.1GB
# Growth rate: ~0.7GB/hour = leak suspected

# Get memory profile
# If Godot has debugging enabled
curl http://localhost:8080/debug/memory_profile > memory_profile.txt
```

**Solutions:**

**Temporary Fix - Restart Service:**
```bash
# Set up automated restart until fix deployed
# Add to crontab:
# 0 */6 * * * systemctl restart godot-spacetime

# Create systemd timer for regular restarts
sudo systemctl enable godot-spacetime-restart.timer
```

**Permanent Fix - Code Update:**
```bash
# Identify leak in code (may need profiling)
# Common causes:
# - Not freeing nodes
# - Circular references
# - Unclosed file handles
# - Growing arrays/dictionaries

# Deploy hotfix with memory fix
# See deployment procedure above
```

---

## Emergency Contacts

### On-Call Rotation
- **Primary:** Check PagerDuty schedule
- **Secondary:** Check PagerDuty schedule
- **Escalation:** Engineering Manager

### Key Contacts

**DevOps Team:**
- Slack: #devops-oncall
- PagerDuty: spacetime-api-ops

**Engineering Team:**
- Slack: #spacetime-engineering
- Email: spacetime-team@company.com

**Management:**
- Engineering Manager: manager@company.com
- Director of Engineering: director@company.com

### Escalation Path

1. **Level 1 (0-15 min):** On-call DevOps engineer
2. **Level 2 (15-30 min):** Senior DevOps engineer + Engineering lead
3. **Level 3 (30-60 min):** Engineering Manager + Director
4. **Level 4 (60+ min):** VP Engineering + CTO

### Incident Severity

**P0 - Critical:**
- Service completely down
- Data loss occurring
- Security breach
- Response: Immediate (< 5 minutes)

**P1 - High:**
- Major feature broken
- Error rate > 5%
- Performance severely degraded
- Response: < 15 minutes

**P2 - Medium:**
- Minor feature broken
- Error rate 1-5%
- Performance degraded
- Response: < 1 hour

**P3 - Low:**
- Minor issues
- Workaround available
- No user impact
- Response: Next business day

---

## Appendix

### Useful Commands

```bash
# Check service status
sudo systemctl status godot-spacetime

# View logs (last 100 lines)
sudo journalctl -u godot-spacetime -n 100

# Follow logs in real-time
sudo journalctl -u godot-spacetime -f

# Restart service
sudo systemctl restart godot-spacetime

# Check port usage
sudo netstat -tlnp | grep -E "6005|6006|8081|8080"

# Test API health
curl http://localhost:8080/status | jq .

# Monitor resource usage
top -p $(pgrep -f godot)

# Check disk space
df -h /opt/spacetime

# View recent errors
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR
```

---

### Configuration Files

**Service File:** `/etc/systemd/system/godot-spacetime.service`
**Environment File:** `/opt/spacetime/production/.env`
**Project Config:** `/opt/spacetime/production/project.godot`
**Logs:** `/var/log/godot-spacetime/` or `journalctl -u godot-spacetime`

---

### Monitoring Dashboards

**Grafana:** https://grafana.company.com/d/spacetime-api
**Status Page:** https://status.company.com
**PagerDuty:** https://company.pagerduty.com/services/spacetime-api
**Log Aggregation:** https://kibana.company.com

---

## Runbook Maintenance

- **Review Frequency:** Monthly
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-01-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager

**Change Log:**
- 2025-12-02: Initial version for v2.5.0
- Future changes to be documented here
