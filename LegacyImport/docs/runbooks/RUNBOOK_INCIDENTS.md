# Incident Response Runbook

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Severity Levels](#severity-levels)
3. [Escalation Procedures](#escalation-procedures)
4. [Common Incidents](#common-incidents)
5. [Incident Response Process](#incident-response-process)
6. [Post-Incident Review](#post-incident-review)

---

## Overview

### Purpose
This runbook provides procedures for responding to incidents affecting the SpaceTime HTTP Scene Management API.

### Incident Definition
An **incident** is any event that causes or has the potential to cause:
- Service disruption or degradation
- Data loss or corruption
- Security breach
- SLO violation

### Response Time Targets

| Severity | Initial Response | Status Updates | Resolution Target |
|----------|------------------|----------------|-------------------|
| P0 - Critical | 5 minutes | Every 15 minutes | 1 hour |
| P1 - High | 15 minutes | Every 30 minutes | 4 hours |
| P2 - Medium | 1 hour | Every 2 hours | 24 hours |
| P3 - Low | 4 hours | Daily | 1 week |
| P4 - Minor | Next business day | As needed | 2 weeks |

---

## Severity Levels

### P0 - Critical (SEV-1)

**Definition:**
- Complete service outage
- Data loss or corruption affecting production
- Security breach with active threat
- Revenue-impacting outage

**Examples:**
- All API endpoints returning 500 errors
- Database corruption
- Complete network failure
- Active security intrusion

**Required Actions:**
- Immediate all-hands response
- Executive notification within 15 minutes
- War room established
- Customer communication initiated
- All non-critical work stopped

**Escalation:**
- Immediately page on-call engineer
- Escalate to manager after 15 minutes
- Escalate to director after 30 minutes
- Engage vendor support if needed

---

### P1 - High (SEV-2)

**Definition:**
- Major feature completely unavailable
- Significant performance degradation
- Security vulnerability with high risk
- Partial service outage

**Examples:**
- Scene loading completely failing
- API error rate > 5%
- Response times > 1 second
- Authentication system down

**Required Actions:**
- Immediate on-call response
- Manager notification within 30 minutes
- Regular status updates
- Customer communication if customer-facing

**Escalation:**
- Page on-call engineer
- Escalate to senior engineer after 30 minutes
- Escalate to manager after 1 hour

---

### P2 - Medium (SEV-3)

**Definition:**
- Minor feature unavailable
- Workaround available
- Performance degraded but functional
- Intermittent errors

**Examples:**
- Single endpoint failing occasionally
- Error rate 1-5%
- Response times 300-500ms
- Non-critical feature broken

**Required Actions:**
- On-call response within 1 hour
- Team notification
- Investigation during business hours
- Status updates every 2 hours

**Escalation:**
- Notify on-call engineer
- Escalate if unresolved after 4 hours

---

### P3 - Low (SEV-4)

**Definition:**
- Minor issue with minimal impact
- Cosmetic issues
- Edge case bugs
- Non-urgent improvements

**Examples:**
- Log messages incorrect
- Minor performance issue
- Documentation errors
- Rare edge case failures

**Required Actions:**
- Create ticket for investigation
- Address during business hours
- No immediate response required

---

### P4 - Minor (SEV-5)

**Definition:**
- Trivial issues
- Feature requests
- Nice-to-have improvements

**Examples:**
- Code cleanup
- Optimization opportunities
- Enhancement requests

**Required Actions:**
- Add to backlog
- Prioritize in planning
- No urgency

---

## Escalation Procedures

### Primary Escalation Path

```
Incident Detected
      ↓
On-Call Engineer (0-15 min)
      ↓
Senior Engineer (15-30 min)
      ↓
Engineering Lead (30-60 min)
      ↓
Engineering Manager (1-2 hours)
      ↓
Director of Engineering (2-4 hours)
      ↓
VP Engineering / CTO (4+ hours)
```

### When to Escalate

**Escalate Immediately If:**
- Unable to identify root cause within response time
- Issue requires expertise beyond your level
- Multiple systems affected
- Customer data at risk
- Security breach suspected
- Severity increases during investigation

**Escalate Automatically At:**
- P0: 15 minutes (manager), 30 minutes (director)
- P1: 30 minutes (senior), 1 hour (manager)
- P2: 4 hours (senior)
- P3/P4: No automatic escalation

### Vendor Escalation

**When to Engage Vendors:**
- Godot engine issues
- Cloud provider (AWS/GCP/Azure) issues
- Third-party service failures
- Infrastructure problems

**Vendor Contact Information:**
- **Godot:** GitHub issues, community forums
- **Cloud Provider:** Support portal, premium support
- **Monitoring:** Support tickets, emergency contact

---

## Common Incidents

### Incident 1: API Completely Unresponsive

**Severity:** P0 - Critical

#### Symptoms
```bash
# All requests timeout
curl -v http://spacetime-api.company.com/status
# Output: Connection timeout

# No response from load balancer
# Health checks failing
# Monitoring shows API down
```

#### Impact Assessment
- **User Impact:** Complete service outage
- **Affected Services:** All API functionality
- **Data Risk:** None (unless during writes)
- **Business Impact:** All users unable to access service

---

#### Investigation Steps

**Step 1: Verify Issue Scope (2 minutes)**
```bash
# Check from multiple locations
curl -v http://spacetime-api.company.com/status  # External
curl -v http://10.0.1.50:8080/status             # Internal
ssh prod-api-01 "curl localhost:8080/status"      # Local

# Expected: Identify where failure occurs
# - All fail: Complete outage
# - External fails: Load balancer or DNS issue
# - Internal works: Firewall or routing issue
```

**Step 2: Check Service Status (1 minute)**
```bash
# Check systemd service on all hosts
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "systemctl status godot-spacetime | grep Active"
done

# Expected output: active (running) or inactive (dead)
```

**Step 3: Check Network Connectivity (1 minute)**
```bash
# Ping hosts
for host in prod-api-01 prod-api-02 prod-api-03; do
  ping -c 3 $host
done

# Check load balancer health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN | jq '.TargetHealthDescriptions[].TargetHealth.State'

# Expected: "healthy" or "unhealthy"
```

**Step 4: Review Logs (2 minutes)**
```bash
# Check recent logs for errors
ssh prod-api-01 "sudo journalctl -u godot-spacetime -n 100 --no-pager"

# Look for:
# - Crash messages
# - Out of memory errors
# - Segmentation faults
# - Connection errors
# - Port binding failures
```

---

#### Resolution Procedures

**Scenario A: Service Crashed/Stopped**
```bash
# Restart service on affected hosts
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "Restarting $host..."
  ssh $host "sudo systemctl restart godot-spacetime"
  sleep 5
  ssh $host "systemctl status godot-spacetime | grep Active"
done

# Wait for startup (30 seconds)
sleep 30

# Verify service responds
curl http://spacetime-api.company.com/status | jq .overall_ready

# Expected output: true
```

**Scenario B: Port Conflict**
```bash
# Identify process using port
ssh prod-api-01 "sudo lsof -i :8080"

# If another process using port, kill it
ssh prod-api-01 "sudo kill -9 <PID>"

# Restart Godot service
ssh prod-api-01 "sudo systemctl restart godot-spacetime"
```

**Scenario C: Load Balancer Issue**
```bash
# Check load balancer configuration
aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN

# Verify targets registered
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# Re-register targets if needed
aws elbv2 register-targets \
  --target-group-arn $TG_ARN \
  --targets Id=i-xxxxx Id=i-yyyyy Id=i-zzzzz
```

**Scenario D: DNS Issue**
```bash
# Check DNS resolution
dig spacetime-api.company.com +short

# If incorrect, update DNS
# Use DNS management console or API

# Flush DNS cache if needed
sudo systemd-resolve --flush-caches
```

**Scenario E: Firewall/Security Group**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids $SG_ID

# Verify rules allow ports 8080, 6005, 6006, 8081
# Add rules if missing
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0
```

---

#### Verification Steps

```bash
# 1. Service responds
curl http://spacetime-api.company.com/status | jq .overall_ready
# Expected: true

# 2. All endpoints functional
for endpoint in /status /connect; do
  echo "Testing $endpoint"
  curl -X POST http://spacetime-api.company.com$endpoint
done

# 3. Load balancer healthy
aws elbv2 describe-target-health --target-group-arn $TG_ARN | \
  jq '.TargetHealthDescriptions[].TargetHealth.State'
# Expected: All "healthy"

# 4. Monitoring shows recovery
# Check Grafana dashboard for metrics flowing

# 5. Error rate back to normal
# Monitor for 5-10 minutes
```

---

#### Prevention Measures

1. **Improve Monitoring:**
   - Add pre-failure alerts (CPU > 90%, memory > 95%)
   - Implement health check retries
   - Add synthetic monitoring

2. **Increase Resilience:**
   - Implement automatic service restart on failure
   - Add circuit breakers
   - Improve error handling

3. **Process Improvements:**
   - Document root cause
   - Update runbooks
   - Schedule post-incident review

---

### Incident 2: High Error Rate

**Severity:** P1 - High (if > 5%), P2 - Medium (if 1-5%)

#### Symptoms
```bash
# High 5xx error rate
curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])/rate(http_requests_total[5m])" | jq '.data.result[0].value[1]'

# Output: 0.05 (5% error rate)

# Multiple error logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -c ERROR"

# Output: High count (> 50)
```

#### Impact Assessment
- **User Impact:** Intermittent failures, degraded experience
- **Affected Services:** Varies by error type
- **Data Risk:** Possible if write operations failing
- **Business Impact:** User frustration, potential data loss

---

#### Investigation Steps

**Step 1: Identify Failing Endpoints (3 minutes)**
```bash
# Get error distribution by endpoint
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep 'HTTP 500' | awk '{print \$(NF-1)}' | sort | uniq -c | sort -rn"

# Output:
#  125 /scene/load
#   45 /debug/evaluate
#   12 /lsp/completion

# Most common failing endpoint identified
```

**Step 2: Analyze Error Messages (5 minutes)**
```bash
# Get detailed errors for top failing endpoint
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep '/scene/load' | grep ERROR | tail -20"

# Look for patterns:
# - File not found
# - Resource exhaustion
# - Timeout errors
# - Connection failures
# - Memory errors

# Get stack traces
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep -A 10 'Traceback\|Stack trace'"
```

**Step 3: Check Resource Usage (2 minutes)**
```bash
# CPU usage
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "top -bn1 | grep 'Cpu\\|godot' | head -3"
done

# Memory usage
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "free -h && ps aux | grep godot | grep -v grep"
done

# Disk I/O
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "iostat -x 1 3 | grep -A 3 'Device'"
done
```

**Step 4: Check Dependencies (2 minutes)**
```bash
# Check DAP/LSP connections
curl http://localhost:8080/status | jq '{dap: .debug_adapter.state, lsp: .language_server.state}'

# Check telemetry server
python3 << 'EOF'
import asyncio
import websockets
async def test():
    try:
        async with websockets.connect('ws://localhost:8081') as ws:
            await asyncio.wait_for(ws.recv(), timeout=5)
            print("Telemetry: OK")
    except:
        print("Telemetry: FAILED")
asyncio.run(test())
EOF
```

---

#### Resolution Procedures

**Scenario A: Scene File Issues**
```bash
# Issue: Scene files not loading
# Error: "Scene load failed: file not found"

# Verify scene files exist
ls -la /opt/spacetime/production/scenes/

# Check file permissions
ls -la /opt/spacetime/production/vr_main.tscn

# Expected: rw-r--r-- spacetime-app spacetime-app

# Fix permissions if wrong
sudo chown spacetime-app:spacetime-app /opt/spacetime/production/*.tscn
chmod 644 /opt/spacetime/production/*.tscn

# Restart service
sudo systemctl restart godot-spacetime

# Verify
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**Scenario B: Resource Exhaustion**
```bash
# Issue: Out of memory or CPU overload

# Immediate: Restart service to clear memory
sudo systemctl restart godot-spacetime
sleep 30

# Check if error rate decreases
watch -n 5 'curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~\"5..\"}[5m])/rate(http_requests_total[5m])" | jq -r ".data.result[0].value[1]"'

# If memory leak suspected, implement temporary restart schedule
# Add to crontab: 0 */6 * * * systemctl restart godot-spacetime

# Long-term: Investigate and fix memory leak (see Memory Leak section)
```

**Scenario C: Dependency Failure**
```bash
# Issue: DAP or LSP not connecting

# Restart connection
curl -X POST http://localhost:8080/disconnect
sleep 2
curl -X POST http://localhost:8080/connect
sleep 5

# Verify connection
curl http://localhost:8080/status | jq .overall_ready

# If still failing, check ports
sudo netstat -tlnp | grep -E "6005|6006"

# Restart Godot if needed
sudo systemctl restart godot-spacetime
```

**Scenario D: Code Bug**
```bash
# Issue: Specific endpoint has code bug causing crashes

# Immediate: If possible, disable failing endpoint temporarily
# Edit godot_bridge.gd to return 503 for that endpoint
# OR add rate limiting for failing endpoint

# Review recent changes
cd /opt/spacetime/production
git log --oneline --since="1 week ago" | head -10

# If bug introduced in recent deployment, consider rollback
# Follow RUNBOOK_DEPLOYMENT.md rollback procedure

# Create hotfix ticket
# Deploy fix following deployment procedure
```

**Scenario E: External Service Failure**
```bash
# Issue: External dependency (database, API) failing

# Identify failing service from logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep 'connection refused\|timeout\|unreachable'"

# Check service status
systemctl status postgresql  # Or other service

# Restart if down
sudo systemctl restart postgresql

# Implement retry logic or circuit breaker if not present
```

---

#### Verification Steps

```bash
# 1. Error rate decreased
curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])/rate(http_requests_total[5m])" | jq '.data.result[0].value[1]'
# Expected: < 0.01 (1%)

# 2. Previously failing endpoint works
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
# Expected: 200 OK

# 3. No new errors in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -c ERROR"
# Expected: < 10

# 4. Resource usage normal
top -bn1 | grep godot
# Expected: CPU < 50%, memory stable

# 5. Monitor for 15 minutes
# Ensure error rate stays low
```

---

#### Prevention Measures

1. **Code Quality:**
   - Add tests for failing scenarios
   - Implement better error handling
   - Add input validation

2. **Resource Management:**
   - Implement resource limits
   - Add memory leak detection
   - Optimize hot paths

3. **Monitoring:**
   - Add alerts for specific error types
   - Implement error tracking (Sentry)
   - Add detailed logging

---

### Incident 3: Slow Response Times

**Severity:** P1 - High (if > 1s), P2 - Medium (if > 500ms)

#### Symptoms
```bash
# Slow response times
for i in {1..10}; do
  curl -o /dev/null -s -w "%{time_total}\n" http://spacetime-api.company.com/status
done | awk '{sum+=$1} END {print "Average:", sum/NR, "s"}'

# Output: Average: 0.75 s (750ms - slow!)

# P95 response time high
curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[5m]))" | jq '.data.result[0].value[1]'

# Output: 0.85 (850ms)
```

#### Impact Assessment
- **User Impact:** Degraded user experience, timeouts
- **Affected Services:** All endpoints potentially affected
- **Data Risk:** Low
- **Business Impact:** User frustration, possible abandonment

---

#### Investigation Steps

**Step 1: Identify Slow Endpoints (3 minutes)**
```bash
# Get response time by endpoint from logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep 'response_time' | awk '{print \$(NF-1), \$NF}' | sort -k2 -rn | head -20"

# Output:
# /debug/evaluate 1.23s
# /lsp/completion 0.95s
# /scene/load 0.78s

# Profile specific endpoint
time curl -X POST http://localhost:8080/debug/evaluate \
  -H "Content-Type: application/json" \
  -d '{"expression": "player.health", "frameId": 0}'
```

**Step 2: Check System Resources (2 minutes)**
```bash
# CPU usage
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host CPU ==="
  ssh $host "top -bn1 | head -20"
done

# Look for:
# - High CPU usage (> 80%)
# - High wait time (wa > 20%)
# - Load average > number of cores

# Memory usage
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host Memory ==="
  ssh $host "free -h && vmstat 1 5"
done

# Look for:
# - High memory usage (> 90%)
# - Swap usage (si/so columns)
# - Memory pressure

# Disk I/O
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host Disk ==="
  ssh $host "iostat -x 1 5"
done

# Look for:
# - High %util (> 80%)
# - High await time (> 10ms)
# - Queue depth (avgqu-sz > 10)
```

**Step 3: Check Network Latency (2 minutes)**
```bash
# Internal latency
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ping -c 10 $host | tail -1
done

# Expected: avg < 1ms

# External latency (to dependencies)
ping -c 10 database.internal.company.com | tail -1

# Check connection pool
ssh prod-api-01 "sudo netstat -an | grep ESTABLISHED | wc -l"

# Compare to max connections
# If near limit, may be connection exhaustion
```

**Step 4: Analyze Godot Performance (5 minutes)**
```bash
# Check frame rate via telemetry
python3 << 'EOF'
import asyncio
import websockets
import json

async def monitor():
    async with websockets.connect('ws://localhost:8081') as ws:
        await ws.recv()  # Connection message
        for _ in range(10):
            msg = await ws.recv()
            data = json.loads(msg)
            if data.get('event') == 'fps':
                print(f"FPS: {data['data']['fps']}, Frame Time: {data['data']['frame_time_ms']}ms")

asyncio.run(monitor())
EOF

# Expected FPS: 90
# If FPS < 90, Godot is struggling

# Check for heavy operations in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep -E 'processing|computation|load'"
```

---

#### Resolution Procedures

**Scenario A: High CPU Usage**
```bash
# Identify CPU-intensive process
top -o %CPU

# If Godot using > 80% CPU:

# Option 1: Restart to clear temporary issue
sudo systemctl restart godot-spacetime

# Option 2: Profile hot spots
# Enable profiling in Godot if available
# Analyze which functions consuming CPU

# Option 3: Scale horizontally
# Add more instances to distribute load
# Follow scaling procedure in RUNBOOK_OPERATIONS.md

# Option 4: Optimize code
# Identify hot paths from profiling
# Implement optimizations
# Deploy update
```

**Scenario B: Memory Pressure**
```bash
# Check for memory leak
watch -n 60 'free -h && ps aux | grep godot | grep -v grep'

# If memory growing continuously:

# Immediate: Restart service
sudo systemctl restart godot-spacetime

# Temporary: Schedule regular restarts
# Add to crontab: 0 */6 * * * systemctl restart godot-spacetime

# Long-term: Fix memory leak
# Profile memory usage
# Identify leaking resources (nodes, arrays, connections)
# Fix code and deploy update
```

**Scenario C: Disk I/O Bottleneck**
```bash
# Check disk performance
iostat -x 1 10

# If %util > 80% or await > 20ms:

# Option 1: Reduce disk writes
# Adjust log levels
# Implement log rotation
# Disable verbose logging

# Option 2: Optimize file access
# Implement caching
# Reduce scene loading frequency
# Preload commonly used scenes

# Option 3: Upgrade storage
# Move to faster SSD
# Use local NVMe instead of network storage
# Implement caching layer (Redis)
```

**Scenario D: Network Latency**
```bash
# If network latency high:

# Check network path
traceroute database.internal.company.com

# Check firewall rules
sudo iptables -L -n -v | grep DROP

# Optimize connections
# Implement connection pooling
# Use persistent connections
# Reduce connection timeout
# Implement local caching

# If external dependency slow:
# Implement timeout and retry
# Add circuit breaker
# Cache responses when possible
```

**Scenario E: Inefficient Code**
```bash
# If specific endpoint slow due to code:

# Profile the endpoint
# Add timing logs to identify bottleneck
# Example: Add logs in godot_bridge.gd

# Optimize identified bottleneck:
# - Use more efficient algorithms
# - Reduce database queries
# - Implement caching
# - Optimize loops
# - Use async operations

# Deploy optimized code
# Follow deployment procedure
```

---

#### Verification Steps

```bash
# 1. Response times improved
for i in {1..10}; do
  curl -o /dev/null -s -w "%{time_total}\n" http://spacetime-api.company.com/status
done | awk '{sum+=$1} END {print "Average:", sum/NR*1000, "ms"}'
# Expected: < 100ms

# 2. P95 back to normal
curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[5m]))" | jq '.data.result[0].value[1]'
# Expected: < 0.2 (200ms)

# 3. Resource usage normal
top -bn1 | grep godot
# Expected: CPU < 50%, memory stable

# 4. FPS stable at 90
# Check telemetry for 5 minutes

# 5. No timeout errors
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -c timeout"
# Expected: 0
```

---

#### Prevention Measures

1. **Performance Testing:**
   - Add load tests to CI/CD
   - Profile before deploying
   - Set performance budgets

2. **Optimization:**
   - Implement caching strategy
   - Optimize database queries
   - Use async operations

3. **Scaling:**
   - Implement auto-scaling
   - Add performance monitoring
   - Set scaling thresholds

---

### Incident 4: Authentication Failures

**Severity:** P1 - High (if all auth failing), P2 - Medium (if intermittent)

#### Symptoms
```bash
# Authentication errors in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep -i 'authentication failed' | wc -l"

# Output: High count (> 10)

# API returns 401 errors
curl -H "Authorization: Bearer $API_TOKEN" http://spacetime-api.company.com/status
# Output: 401 Unauthorized
```

#### Investigation Steps

**Step 1: Verify Token Validity (2 minutes)**
```bash
# Check token expiration
# Decode JWT token (if using JWT)
echo $API_TOKEN | cut -d'.' -f2 | base64 -d | jq .exp

# Compare to current time
date +%s

# If exp < current time, token expired

# Test with known good token
curl -H "Authorization: Bearer $KNOWN_GOOD_TOKEN" http://localhost:8080/status

# If works, token issue
# If fails, service issue
```

**Step 2: Check Authentication Service (2 minutes)**
```bash
# If using external auth service
curl http://auth-service.internal.company.com/health

# Check auth service logs
ssh auth-server "sudo journalctl -u auth-service --since '10 minutes ago' | tail -50"

# Verify network connectivity
ping auth-service.internal.company.com
```

**Step 3: Review API Logs (3 minutes)**
```bash
# Get detailed auth errors
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep -i 'auth' | tail -50"

# Look for:
# - Token validation failures
# - Connection to auth service failures
# - Certificate errors
# - Timeout errors
```

---

#### Resolution Procedures

**Scenario A: Expired Tokens**
```bash
# Issue: API tokens expired

# Immediate: Rotate tokens
# Use token management system
./scripts/rotate_api_tokens.sh

# Update clients with new tokens
# Notify users via email/Slack

# Verify new tokens work
curl -H "Authorization: Bearer $NEW_TOKEN" http://localhost:8080/status
# Expected: 200 OK
```

**Scenario B: Auth Service Down**
```bash
# Issue: External auth service unavailable

# Check auth service status
systemctl status auth-service

# Restart if down
sudo systemctl restart auth-service

# Verify connectivity
curl http://auth-service.internal.company.com/health

# If auth service has persistent issues:
# Consider implementing local token cache
# Add fallback authentication method
```

**Scenario C: Certificate Issues**
```bash
# Issue: TLS certificate validation failing

# Check certificate validity
openssl s_client -connect auth-service.internal.company.com:443 -servername auth-service.internal.company.com

# If expired, renew certificate
sudo certbot renew --force-renewal

# Restart services
sudo systemctl restart godot-spacetime
```

---

#### Verification Steps

```bash
# 1. Authentication succeeds
curl -H "Authorization: Bearer $API_TOKEN" http://spacetime-api.company.com/status | jq .overall_ready
# Expected: true

# 2. No auth errors in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -c 'authentication failed'"
# Expected: 0

# 3. All clients can authenticate
# Test from multiple clients/locations

# 4. Monitor for 15 minutes
# Ensure no recurring auth failures
```

---

#### Prevention Measures

1. **Token Management:**
   - Implement automatic token rotation
   - Add token expiration monitoring
   - Alert before tokens expire (7 days)

2. **Resilience:**
   - Implement token caching
   - Add fallback authentication
   - Use longer-lived tokens

3. **Monitoring:**
   - Add auth failure rate alerts
   - Monitor auth service health
   - Track token usage

---

### Incident 5: Scene Loading Failures

**Severity:** P1 - High (if all scenes fail), P2 - Medium (if specific scenes)

#### Symptoms
```bash
# Scene load endpoint failing
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'

# Output: 500 Internal Server Error
# {"error": "Scene load failed", "message": "File not found"}

# Errors in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep 'scene.*failed'"
```

#### Investigation Steps

**Step 1: Verify Scene Files (2 minutes)**
```bash
# Check if scene files exist
ls -la /opt/spacetime/production/*.tscn

# Expected: vr_main.tscn and other scene files

# Check file permissions
ls -la /opt/spacetime/production/vr_main.tscn

# Expected: rw-r--r-- spacetime-app spacetime-app

# Check file integrity
file /opt/spacetime/production/vr_main.tscn

# Expected: ASCII text or UTF-8 text
```

**Step 2: Test Scene Loading Manually (3 minutes)**
```bash
# Try loading scene directly in Godot
ssh prod-api-01 "cd /opt/spacetime/production && godot --headless --script test_scene_load.gd"

# Create test script if needed:
cat > /opt/spacetime/production/test_scene_load.gd << 'EOF'
extends Node
func _ready():
    var scene = load("res://vr_main.tscn")
    if scene:
        print("Scene loaded successfully")
    else:
        print("Scene load failed")
    get_tree().quit()
EOF

# Run test
godot --headless --script /opt/spacetime/production/test_scene_load.gd
```

**Step 3: Check Dependencies (2 minutes)**
```bash
# Check if scene dependencies exist
grep -r "ext_resource" /opt/spacetime/production/vr_main.tscn

# Verify each referenced resource exists
# Example:
# [ext_resource type="Script" path="res://scripts/vr_setup.gd"]

ls -la /opt/spacetime/production/scripts/vr_setup.gd
```

---

#### Resolution Procedures

**Scenario A: Missing Scene Files**
```bash
# Issue: Scene files missing after deployment

# Restore from backup
cd /opt/spacetime
tar -xzf backups/production_$(date +%Y%m%d)*.tar.gz -C /tmp/restore/

# Copy missing files
cp /tmp/restore/production/*.tscn production/

# Set correct permissions
chown spacetime-app:spacetime-app production/*.tscn
chmod 644 production/*.tscn

# Restart service
sudo systemctl restart godot-spacetime

# Verify
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

**Scenario B: Corrupted Scene Files**
```bash
# Issue: Scene files corrupted

# Verify corruption
file /opt/spacetime/production/vr_main.tscn

# If corrupted, restore from Git
cd /opt/spacetime/production
git checkout vr_main.tscn

# Or restore from backup
cp backups/vr_main.tscn.$(ls -t backups/vr_main.tscn.* | head -1) vr_main.tscn

# Restart service
sudo systemctl restart godot-spacetime
```

**Scenario C: Missing Dependencies**
```bash
# Issue: Scene references missing resources

# Identify missing resources from error logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep 'not found\|missing'"

# Restore missing resources from backup or Git
cd /opt/spacetime/production
git checkout scripts/vr_setup.gd  # Example

# Or re-sync from staging
rsync -av staging/scripts/ production/scripts/

# Restart service
sudo systemctl restart godot-spacetime
```

**Scenario D: Permission Issues**
```bash
# Issue: Godot can't read scene files

# Fix permissions recursively
sudo chown -R spacetime-app:spacetime-app /opt/spacetime/production
find /opt/spacetime/production -type f -name "*.tscn" -exec chmod 644 {} \;
find /opt/spacetime/production -type f -name "*.gd" -exec chmod 644 {} \;

# Restart service
sudo systemctl restart godot-spacetime
```

---

#### Verification Steps

```bash
# 1. Scene loads successfully
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
# Expected: 200 OK

# 2. No errors in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -c 'scene.*failed'"
# Expected: 0

# 3. Test multiple scenes
for scene in vr_main.tscn other_scene.tscn; do
  curl -X POST http://localhost:8080/scene/load \
    -H "Content-Type: application/json" \
    -d "{\"scene_path\": \"res://$scene\"}"
done

# 4. Verify via telemetry
# Check scene_loaded events in telemetry stream
```

---

#### Prevention Measures

1. **Deployment:**
   - Add scene file validation to deployment
   - Test scene loading in staging
   - Verify all dependencies before deploy

2. **File Integrity:**
   - Implement file checksums
   - Add automated file integrity checks
   - Monitor for file system corruption

3. **Testing:**
   - Add automated scene loading tests
   - Test all scenes in CI/CD
   - Validate dependencies

---

### Incident 6: Memory Leak

**Severity:** P2 - Medium (gradually degrading), escalate to P1 if OOM imminent

#### Symptoms
```bash
# Memory usage continuously growing
watch -n 60 'free -h && ps aux | grep godot | grep -v grep'

# Output shows memory increasing over time:
# Time 0: 2.5 GB
# Time 1h: 3.2 GB
# Time 2h: 4.1 GB
# Growth rate: ~0.7 GB/hour

# Eventually OOM killer triggered
dmesg | grep -i "out of memory\|oom"

# Service crashes
systemctl status godot-spacetime
# Output: failed (Result: signal)
```

#### Investigation Steps

**Step 1: Confirm Memory Leak (10 minutes)**
```bash
# Monitor memory over time
for i in {1..10}; do
  ps aux | grep godot | grep -v grep | awk '{print $6}'
  sleep 60
done

# Output should show increasing values
# Example:
# 2621440  # 2.5 GB
# 2654208  # 2.6 GB
# 2686976  # 2.6 GB
# 2719744  # 2.7 GB
# ...

# Calculate growth rate
# If consistently growing, memory leak confirmed
```

**Step 2: Identify Leak Source (15 minutes)**
```bash
# Check Godot memory usage if profiling enabled
curl http://localhost:8080/debug/memory_profile > memory_profile.txt

# Analyze profile for growing allocations
# Look for:
# - Growing arrays/dictionaries
# - Unreleased nodes
# - Unclosed file handles
# - Growing connection pools

# Check for leaked resources in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '1 hour ago' | grep -E 'new|alloc|instantiate' | wc -l"

# Compare to deallocation
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '1 hour ago' | grep -E 'free|queue_free|delete' | wc -l"

# If allocations >> deallocations, resources not being freed
```

**Step 3: Review Recent Changes (5 minutes)**
```bash
# Check recent code changes
cd /opt/spacetime/production
git log --oneline --since="1 week ago" --grep="memory\|leak\|free\|allocation"

# Review commits for potential leak introduction
git show <commit_hash>

# Common leak patterns:
# - Nodes created but not freed
# - Signals connected but not disconnected
# - Arrays/dicts growing without bounds
# - File handles not closed
# - HTTP connections not released
```

---

#### Resolution Procedures

**Scenario A: Immediate Mitigation - Restart Service**
```bash
# Temporary fix: Restart to reclaim memory
sudo systemctl restart godot-spacetime

# Verify memory usage after restart
ps aux | grep godot | grep -v grep | awk '{print $6/1024/1024 " GB"}'

# Expected: Back to baseline (~2.5 GB)

# Implement automatic restart until fix deployed
# Create systemd timer for scheduled restarts

# Create timer unit
sudo tee /etc/systemd/system/godot-restart.timer << EOF
[Unit]
Description=Restart Godot SpaceTime every 6 hours

[Timer]
OnBootSec=6h
OnUnitActiveSec=6h
Unit=godot-restart.service

[Install]
WantedBy=timers.target
EOF

# Create service unit
sudo tee /etc/systemd/system/godot-restart.service << EOF
[Unit]
Description=Restart Godot SpaceTime Service

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart godot-spacetime
EOF

# Enable and start timer
sudo systemctl daemon-reload
sudo systemctl enable godot-restart.timer
sudo systemctl start godot-restart.timer

# Verify timer
systemctl list-timers | grep godot-restart
```

**Scenario B: Fix Code Leak**
```bash
# Identify and fix common leak patterns

# Pattern 1: Nodes not freed
# Bad:
# func create_node():
#     var node = Node.new()
#     add_child(node)
#     # node never freed

# Good:
# func create_node():
#     var node = Node.new()
#     add_child(node)
#     node.queue_free()  # Free when done

# Pattern 2: Signals not disconnected
# Bad:
# func connect_signal():
#     some_object.signal_name.connect(handler)
#     # never disconnected

# Good:
# func connect_signal():
#     some_object.signal_name.connect(handler)
#
# func _exit_tree():
#     some_object.signal_name.disconnect(handler)

# Pattern 3: Growing collections
# Bad:
# var cache = {}
# func cache_data(key, value):
#     cache[key] = value  # grows indefinitely

# Good:
# var cache = {}
# const MAX_CACHE_SIZE = 1000
# func cache_data(key, value):
#     if cache.size() >= MAX_CACHE_SIZE:
#         # Remove oldest entries
#         var keys = cache.keys()
#         cache.erase(keys[0])
#     cache[key] = value

# Apply fixes and deploy following deployment procedure
```

**Scenario C: Optimize Memory Usage**
```bash
# Reduce memory footprint

# 1. Implement object pooling for frequently created objects
# 2. Use weak references where appropriate
# 3. Reduce scene complexity
# 4. Optimize textures and models
# 5. Implement aggressive garbage collection

# Example: Object pool pattern
# var node_pool = []
# const POOL_SIZE = 100
#
# func get_node():
#     if node_pool.is_empty():
#         return Node.new()
#     return node_pool.pop_back()
#
# func return_node(node):
#     if node_pool.size() < POOL_SIZE:
#         node_pool.append(node)
#     else:
#         node.queue_free()
```

---

#### Verification Steps

```bash
# 1. Monitor memory over 2 hours
for i in {1..24}; do
  echo "$(date) - Memory: $(ps aux | grep godot | grep -v grep | awk '{print $6/1024/1024}') GB"
  sleep 300  # 5 minutes
done > memory_monitoring.log

# Check log for trend
# Memory should be stable, not continuously growing

# 2. Check for OOM errors
dmesg | grep -i "out of memory" --since "1 hour ago"
# Expected: No output

# 3. Verify service stability
uptime
# Expected: Uptime should be increasing (no crashes)

# 4. Monitor for 24-48 hours
# Ensure memory usage stays within acceptable range
```

---

#### Prevention Measures

1. **Code Reviews:**
   - Check for proper resource cleanup
   - Review node lifecycle management
   - Verify signal disconnection

2. **Testing:**
   - Add memory leak tests
   - Run long-duration tests
   - Profile memory usage

3. **Monitoring:**
   - Add memory growth alerts
   - Track memory usage trends
   - Implement memory profiling

4. **Best Practices:**
   - Document resource management patterns
   - Create coding guidelines
   - Use static analysis tools

---

### Incident 7: Disk Space Exhaustion

**Severity:** P1 - High (if > 95%), P2 - Medium (if > 85%)

#### Symptoms
```bash
# Disk space critical
df -h /opt/spacetime

# Output:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1       100G   96G   4G  96% /opt/spacetime

# Disk full errors in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -i 'no space left\|disk full'"

# Service degraded or failing
# Write operations failing
```

#### Investigation Steps

**Step 1: Identify Space Usage (5 minutes)**
```bash
# Find largest directories
du -h /opt/spacetime --max-depth=2 | sort -rh | head -20

# Output shows space consumers:
# 45G  /opt/spacetime/logs
# 20G  /opt/spacetime/backups
# 10G  /opt/spacetime/production
# ...

# Find largest files
find /opt/spacetime -type f -size +100M -exec du -h {} \; | sort -rh | head -20

# Check log files specifically
du -h /opt/spacetime/logs/*.log | sort -rh | head -10
```

**Step 2: Check for Runaway Processes (2 minutes)**
```bash
# Check if logs growing rapidly
watch -n 1 'du -h /opt/spacetime/logs/godot.log'

# Check for core dumps
ls -lh /opt/spacetime/core.*

# Check temp files
du -h /tmp | sort -rh | head -10
```

---

#### Resolution Procedures

**Scenario A: Log Files Too Large**
```bash
# Immediate: Compress and archive old logs
cd /opt/spacetime/logs

# Archive logs older than 7 days
find . -name "*.log" -mtime +7 -exec gzip {} \;

# Move archives to backup location
mv *.log.gz /opt/spacetime/backups/logs/

# Or delete old archived logs if backups not needed
find /opt/spacetime/backups/logs -name "*.log.gz" -mtime +30 -delete

# Truncate current log if extremely large
if [ $(du -m godot.log | cut -f1) -gt 1000 ]; then
  # Backup last 1000 lines
  tail -1000 godot.log > godot.log.tmp
  mv godot.log.tmp godot.log
fi

# Verify space freed
df -h /opt/spacetime
```

**Scenario B: Backup Files Accumulation**
```bash
# Remove old backups beyond retention policy
cd /opt/spacetime/backups

# Keep: 7 daily, 4 weekly, 3 monthly
# Delete daily backups older than 7 days
find . -name "production_*" -mtime +7 -type f ! -name "*weekly*" ! -name "*monthly*" -delete

# Delete weekly backups older than 28 days
find . -name "*weekly*" -mtime +28 -type f ! -name "*monthly*" -delete

# Delete monthly backups older than 90 days
find . -name "*monthly*" -mtime +90 -type f -delete

# Verify space freed
df -h /opt/spacetime
```

**Scenario C: Core Dumps**
```bash
# Remove core dumps
find /opt/spacetime -name "core.*" -delete
find /tmp -name "core.*" -delete

# Disable core dumps if not needed
echo "* soft core 0" >> /etc/security/limits.conf
echo "* hard core 0" >> /etc/security/limits.conf
ulimit -c 0

# Or limit core dump size
echo "* soft core 102400" >> /etc/security/limits.conf  # 100MB limit
```

**Scenario D: Temp Files**
```bash
# Clean temp files
rm -rf /tmp/godot-*
rm -rf /tmp/spacetime-*

# Clean old temp files system-wide
find /tmp -type f -mtime +7 -delete

# Set up tmpfiles cleanup
cat > /etc/tmpfiles.d/spacetime.conf << EOF
# Clean SpaceTime temp files daily
d /tmp/godot-* - - - 1d
d /tmp/spacetime-* - - - 1d
EOF

systemd-tmpfiles --create
```

**Scenario E: Emergency - Expand Disk**
```bash
# If cleanup insufficient, expand disk

# For AWS EBS volume:
# 1. Modify volume size in AWS console
aws ec2 modify-volume --volume-id vol-xxxxx --size 200

# 2. Wait for modification to complete
aws ec2 describe-volumes-modifications --volume-id vol-xxxxx

# 3. Extend partition
sudo growpart /dev/sda 1

# 4. Resize filesystem
sudo resize2fs /dev/sda1

# 5. Verify
df -h /opt/spacetime
```

---

#### Verification Steps

```bash
# 1. Disk space recovered
df -h /opt/spacetime
# Expected: < 80% used

# 2. No disk full errors
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -i 'no space left'"
# Expected: No output

# 3. Write operations work
echo "test" > /opt/spacetime/test_write.txt && rm /opt/spacetime/test_write.txt
# Expected: Success

# 4. Service operational
curl http://localhost:8080/status | jq .overall_ready
# Expected: true

# 5. Monitor for 1 hour
# Ensure space not rapidly consumed again
```

---

#### Prevention Measures

1. **Log Management:**
   - Implement log rotation
   - Set log retention policies
   - Use centralized logging (Splunk, ELK)

2. **Backup Management:**
   - Automate backup cleanup
   - Store backups externally (S3, GCS)
   - Implement backup retention policy

3. **Monitoring:**
   - Add disk space alerts (at 80%, 85%, 90%)
   - Monitor disk growth rate
   - Predict when disk will fill

4. **Automation:**
   - Scheduled cleanup jobs
   - Automated log archival
   - Automatic disk expansion (if cloud)

**Log Rotation Configuration:**
```bash
# Create logrotate config
sudo tee /etc/logrotate.d/spacetime << EOF
/opt/spacetime/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0644 spacetime-app spacetime-app
    sharedscripts
    postrotate
        systemctl reload godot-spacetime > /dev/null 2>&1 || true
    endscript
}
EOF

# Test logrotate
sudo logrotate -d /etc/logrotate.d/spacetime
```

---

## Incident Response Process

### Phase 1: Detection and Triage (0-5 minutes)

**Step 1: Acknowledge Alert**
```bash
# Acknowledge in PagerDuty
# Set status to "Acknowledged"
# Add initial note with time and responder

# Create incident channel in Slack
# /incident create "API Unresponsive - [Your Name] investigating"
```

**Step 2: Assess Severity**
- Review symptoms
- Determine user impact
- Assign severity level (P0-P4)
- Escalate if needed

**Step 3: Initial Communication**
```bash
# Post in #incidents channel
# Template:
# 🚨 INCIDENT: [Title]
# Severity: [P0/P1/P2/P3/P4]
# Impact: [Description]
# Investigating: [Your Name]
# Status: Investigating
```

---

### Phase 2: Investigation (5-30 minutes)

**Step 4: Gather Information**
- Follow investigation steps for incident type
- Document findings
- Collect logs and metrics

**Step 5: Identify Root Cause**
- Analyze data
- Form hypothesis
- Test hypothesis
- Confirm root cause

---

### Phase 3: Mitigation (10-60 minutes)

**Step 6: Implement Fix**
- Follow resolution procedures
- Document actions taken
- Monitor impact

**Step 7: Verify Resolution**
- Run verification steps
- Confirm symptoms resolved
- Monitor for recurrence

---

### Phase 4: Recovery (30-120 minutes)

**Step 8: Full Recovery**
- Ensure system fully operational
- Clear any maintenance modes
- Verify all dependencies

**Step 9: Communication**
```bash
# Update incident status
# Post in #incidents:
# ✅ RESOLVED: [Title]
# Duration: [time]
# Root Cause: [brief description]
# Resolution: [brief description]
# Post-Mortem: [link when available]
```

---

### Phase 5: Post-Incident (1-3 days)

**Step 10: Post-Incident Review**
- Schedule post-mortem meeting (within 48 hours)
- Document timeline
- Identify contributing factors
- Create action items

**Step 11: Follow-Up**
- Track action items
- Update runbooks
- Implement preventive measures
- Share lessons learned

---

## Post-Incident Review

### Post-Mortem Template

```markdown
# Incident Post-Mortem

**Incident:** [Title]
**Date:** [Date]
**Duration:** [Total time from detection to resolution]
**Severity:** [P0/P1/P2/P3/P4]
**Responders:** [List of people involved]

## Summary
[Brief 2-3 sentence summary of what happened]

## Timeline
| Time | Event |
|------|-------|
| 10:00 | Alert triggered: API unresponsive |
| 10:05 | On-call engineer acknowledged |
| 10:10 | Root cause identified: Service crashed |
| 10:15 | Service restarted |
| 10:20 | Verified resolution |
| 10:30 | Monitoring confirmed stable |

## Root Cause
[Detailed explanation of what caused the incident]

## Impact
- **User Impact:** [Description]
- **Duration:** [Time]
- **Affected Users:** [Number or percentage]
- **Data Loss:** [Yes/No, details]
- **Revenue Impact:** [If applicable]

## What Went Well
- [Things that worked well during response]
- [Effective tools or processes]
- [Good decisions made]

## What Went Wrong
- [Issues encountered during response]
- [Delays or inefficiencies]
- [Gaps in monitoring or documentation]

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Add pre-failure alerts | DevOps | 2025-12-10 | Open |
| Update runbook | SRE | 2025-12-08 | In Progress |
| Implement circuit breaker | Engineering | 2025-12-20 | Open |

## Lessons Learned
- [Key takeaways]
- [Process improvements]
- [Technical improvements]

## Prevention
[Steps taken to prevent recurrence]
```

---

### Post-Mortem Meeting Agenda

1. **Introduction (5 min)**
   - Review purpose of post-mortem
   - Establish blameless culture
   - Set expectations

2. **Timeline Review (15 min)**
   - Walk through incident timeline
   - Identify key decision points
   - Note delays or confusion

3. **Root Cause Analysis (15 min)**
   - Present findings
   - Discuss contributing factors
   - Validate root cause

4. **Discussion (20 min)**
   - What went well?
   - What could be improved?
   - What surprised us?

5. **Action Items (15 min)**
   - Brainstorm preventive measures
   - Assign owners and due dates
   - Prioritize actions

6. **Follow-Up (5 min)**
   - Schedule action item review
   - Document lessons learned
   - Share with wider team

---

## Appendix

### Incident Communication Templates

**Initial Alert Template:**
```
🚨 INCIDENT: [Brief Title]

Severity: [P0/P1/P2/P3/P4]
Impact: [Who is affected and how]
Status: Investigating
Investigating: @[name]
Started: [time]

Current Status:
- [What we know]
- [What we're checking]

Next Update: [time]
```

**Progress Update Template:**
```
📊 UPDATE: [Incident Title]

Time: [current time] (Duration: [elapsed time])
Status: [Investigating/Identified/Fixing/Monitoring]

Progress:
- [What we've found]
- [What we've done]
- [Current action]

Impact: [Current impact status]
Next Update: [time]
```

**Resolution Template:**
```
✅ RESOLVED: [Incident Title]

Total Duration: [time]
Severity: [P0/P1/P2/P3/P4]

Summary:
[2-3 sentences about what happened and how it was fixed]

Root Cause: [Brief explanation]
Resolution: [Brief explanation]

Next Steps:
- Post-mortem scheduled: [date/time]
- Action items: [high-level list]

Thanks to @[names] for rapid response.
```

---

### Useful Commands Reference

```bash
# Check service status
systemctl status godot-spacetime

# View recent logs
sudo journalctl -u godot-spacetime -n 100 --no-pager

# Follow logs real-time
sudo journalctl -u godot-spacetime -f

# Restart service
sudo systemctl restart godot-spacetime

# Check API health
curl http://localhost:8080/status | jq .

# Check error rate
curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])/rate(http_requests_total[5m])" | jq '.data.result[0].value[1]'

# Monitor resource usage
top -p $(pgrep -f godot)

# Check disk space
df -h /opt/spacetime

# Network connectivity
ping -c 3 [host]
telnet [host] [port]

# Process information
ps aux | grep godot
lsof -p [PID]
```

---

## Runbook Maintenance

- **Review Frequency:** After each major incident, monthly review
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-01-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager

**Change Log:**
- 2025-12-02: Initial version for v2.5.0
- Future changes to be documented here
