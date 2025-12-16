# Troubleshooting Guide

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Systematic Troubleshooting Approach](#systematic-troubleshooting-approach)
3. [Common Error Messages](#common-error-messages)
4. [Debug Information Collection](#debug-information-collection)
5. [Performance Profiling](#performance-profiling)
6. [Network Troubleshooting](#network-troubleshooting)
7. [When to Escalate](#when-to-escalate)

---

## Overview

### Troubleshooting Philosophy

1. **Don't Panic:** Take time to understand the problem
2. **Gather Data:** Collect logs, metrics, and symptoms
3. **Form Hypothesis:** Based on data, what could be wrong?
4. **Test Hypothesis:** Make one change at a time
5. **Document:** Record findings and solutions
6. **Share:** Update runbooks and team knowledge

### Tools Required

- SSH access to production servers
- Grafana dashboard access
- Log access (journalctl or log aggregation)
- Prometheus query interface
- Telemetry client
- curl/wget for API testing

---

## Systematic Troubleshooting Approach

### Step-by-Step Methodology

```
1. OBSERVE
   ↓
   What is the symptom?
   ↓
2. COLLECT DATA
   ↓
   Logs, metrics, user reports
   ↓
3. ANALYZE
   ↓
   What changed? Pattern recognition
   ↓
4. HYPOTHESIZE
   ↓
   Possible root causes
   ↓
5. TEST
   ↓
   Verify hypothesis with minimal risk
   ↓
6. RESOLVE
   ↓
   Apply fix, verify solution
   ↓
7. DOCUMENT
   ↓
   Update runbooks, create tickets
```

---

### Troubleshooting Checklist

**Phase 1: Observe and Define (5 minutes)**

```bash
# What is the problem?
- [ ] Service down
- [ ] Slow performance
- [ ] Errors occurring
- [ ] Specific feature broken
- [ ] Intermittent issue

# When did it start?
PROBLEM_START=$(date)  # Or from monitoring

# Who is affected?
- [ ] All users
- [ ] Specific users
- [ ] Specific regions
- [ ] Specific endpoints

# How severe?
- [ ] Critical (service down)
- [ ] High (major degradation)
- [ ] Medium (minor impact)
- [ ] Low (cosmetic)
```

**Phase 2: Quick Health Check (2 minutes)**

```bash
# Service running?
systemctl status godot-spacetime

# API responding?
curl -s http://localhost:8080/status | jq .

# Resource usage normal?
top -bn1 | head -20

# Disk space OK?
df -h /opt/spacetime

# Network OK?
ping -c 3 8.8.8.8
```

**Phase 3: Recent Changes (5 minutes)**

```bash
# Recent deployments?
git log --oneline --since="24 hours ago"

# Recent configuration changes?
ls -lt /opt/spacetime/production/.env | head -1

# Recent system changes?
last | head -20

# Recent alerts?
# Check PagerDuty history
```

**Phase 4: Collect Diagnostic Data (10 minutes)**

```bash
# System logs
sudo journalctl -u godot-spacetime --since "1 hour ago" > /tmp/godot-logs.txt

# Error summary
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR > /tmp/errors.txt

# System metrics
top -bn1 > /tmp/system-metrics.txt
free -h >> /tmp/system-metrics.txt
df -h >> /tmp/system-metrics.txt

# Network status
netstat -tlnp | grep -E "6005|6006|8081|8080" > /tmp/network.txt

# Process info
ps aux | grep godot > /tmp/process-info.txt
```

**Phase 5: Analyze Patterns (10 minutes)**

```bash
# Error frequency
grep -c ERROR /tmp/errors.txt

# Error types
cat /tmp/errors.txt | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | sort | uniq -c | sort -rn | head -10

# Correlation with metrics
# Check Grafana for:
# - Traffic spike?
# - Resource spike?
# - Deployment at problem start time?
```

---

## Common Error Messages

### "Connection refused"

**Full Error:**
```
ERROR: Connection refused: http://localhost:8080
```

**Meaning:** Service not listening on expected port

**Troubleshooting:**

```bash
# 1. Check if service is running
systemctl status godot-spacetime

# 2. If not running, start it
sudo systemctl start godot-spacetime

# 3. If running, check port binding
sudo netstat -tlnp | grep 8080

# 4. If port not listening, check logs for startup errors
sudo journalctl -u godot-spacetime -n 50

# 5. Common causes:
# - Port already in use by another process
# - Permission issues
# - Configuration error preventing startup
```

**Solution:**

```bash
# If port conflict:
sudo lsof -i :8080
sudo kill -9 <PID>
sudo systemctl start godot-spacetime

# If permissions:
sudo chown -R spacetime-app:spacetime-app /opt/spacetime/production
sudo systemctl start godot-spacetime

# If configuration error:
# Fix configuration and restart
```

---

### "Scene load failed: file not found"

**Full Error:**
```
ERROR: Scene load failed: File not found: res://vr_main.tscn
```

**Meaning:** Godot cannot find the requested scene file

**Troubleshooting:**

```bash
# 1. Verify file exists
ls -la /opt/spacetime/production/vr_main.tscn

# 2. Check permissions
ls -la /opt/spacetime/production/*.tscn

# 3. Check file integrity
file /opt/spacetime/production/vr_main.tscn
# Should show: "ASCII text" or "UTF-8 text"

# 4. Check for symlink issues
readlink /opt/spacetime/production

# 5. Verify file contents
head -20 /opt/spacetime/production/vr_main.tscn
# Should show Godot scene format
```

**Solution:**

```bash
# If file missing, restore from backup
cd /opt/spacetime/backups
tar -xzf production_$(date +%Y%m%d)*.tar.gz --wildcards "*/vr_main.tscn"
cp */vr_main.tscn /opt/spacetime/production/

# If permissions wrong
sudo chown spacetime-app:spacetime-app /opt/spacetime/production/*.tscn
sudo chmod 644 /opt/spacetime/production/*.tscn

# Restart service
sudo systemctl restart godot-spacetime
```

---

### "Out of memory"

**Full Error:**
```
ERROR: Out of memory allocating 1048576 bytes
```

**Meaning:** System or process has exhausted available memory

**Troubleshooting:**

```bash
# 1. Check system memory
free -h

# 2. Check process memory
ps aux | grep godot | grep -v grep

# 3. Check for memory leak pattern
# Monitor memory over time:
watch -n 60 'free -h && ps aux | grep godot | grep -v grep'

# 4. Check swap usage
vmstat 1 10

# 5. Check OOM killer logs
dmesg | grep -i "out of memory\|oom"
```

**Solution:**

```bash
# Immediate: Restart service to reclaim memory
sudo systemctl restart godot-spacetime

# Short-term: Schedule regular restarts
# Add to crontab: 0 */6 * * * systemctl restart godot-spacetime

# Long-term: Fix memory leak
# See RUNBOOK_INCIDENTS.md - Incident 6: Memory Leak
```

---

### "Authentication failed"

**Full Error:**
```
ERROR: Authentication failed: Invalid token
```

**Meaning:** API token is invalid, expired, or malformed

**Troubleshooting:**

```bash
# 1. Verify token format
echo $API_TOKEN | wc -c
# Should be expected length (e.g., 64 characters for JWT)

# 2. Decode token (if JWT)
echo $API_TOKEN | cut -d'.' -f2 | base64 -d | jq .

# 3. Check expiration
TOKEN_EXP=$(echo $API_TOKEN | cut -d'.' -f2 | base64 -d | jq -r .exp)
CURRENT_TIME=$(date +%s)
if [ $TOKEN_EXP -lt $CURRENT_TIME ]; then
  echo "Token expired"
fi

# 4. Test with known good token
curl -H "Authorization: Bearer $KNOWN_GOOD_TOKEN" http://localhost:8080/status

# 5. Check auth service logs
sudo journalctl -u godot-spacetime | grep -i "auth"
```

**Solution:**

```bash
# If token expired, request new token
# Follow token renewal procedure

# If token invalid, verify token generation process

# If auth service issue, restart auth service
```

---

### "Database connection failed"

**Full Error:**
```
ERROR: Database connection failed: Connection timeout
```

**Meaning:** Cannot connect to database (if application uses database)

**Troubleshooting:**

```bash
# 1. Check database service status
systemctl status postgresql

# 2. Verify network connectivity
ping database.internal.company.com

# 3. Test database connection
psql -U spacetime -d spacetime_db -c "SELECT 1;"

# 4. Check connection pool
# Look for connection pool exhaustion in logs

# 5. Verify credentials
# Check connection string in .env file
```

**Solution:**

```bash
# If database down
sudo systemctl start postgresql

# If network issue
# Check firewall rules, security groups

# If connection pool exhausted
# Restart application to reset pool
sudo systemctl restart godot-spacetime

# Or adjust pool size in configuration
```

---

### "Timeout waiting for response"

**Full Error:**
```
ERROR: Timeout waiting for response after 30000ms
```

**Meaning:** Operation took longer than timeout threshold

**Troubleshooting:**

```bash
# 1. Measure actual response time
time curl -X POST http://localhost:8080/some/endpoint

# 2. Check for slow operations in logs
sudo journalctl -u godot-spacetime --since "10 minutes ago" | grep "took\|duration\|elapsed"

# 3. Check resource contention
iostat -x 1 10  # Disk I/O
top -bn1  # CPU/Memory

# 4. Check for network latency
ping -c 10 external-service.com

# 5. Profile slow endpoint
# Add timing logs to identify bottleneck
```

**Solution:**

```bash
# If disk I/O bottleneck
# Optimize file access, add caching

# If CPU bottleneck
# Optimize algorithm, scale horizontally

# If network latency
# Add timeout retry logic, use caching

# Temporary: Increase timeout
# Edit configuration to allow more time
```

---

## Debug Information Collection

### Comprehensive Debug Package

When escalating or creating tickets, collect this information:

```bash
#!/bin/bash
# Collect debug information package

DEBUG_DIR="/tmp/debug-$(date +%Y%m%d_%H%M%S)"
mkdir -p $DEBUG_DIR

echo "Collecting debug information to $DEBUG_DIR"

# 1. System information
echo "=== System Info ===" > $DEBUG_DIR/system-info.txt
uname -a >> $DEBUG_DIR/system-info.txt
cat /etc/os-release >> $DEBUG_DIR/system-info.txt
uptime >> $DEBUG_DIR/system-info.txt

# 2. Service status
echo "=== Service Status ===" > $DEBUG_DIR/service-status.txt
systemctl status godot-spacetime >> $DEBUG_DIR/service-status.txt

# 3. Recent logs
echo "Collecting logs..."
sudo journalctl -u godot-spacetime --since "1 hour ago" > $DEBUG_DIR/service-logs.txt
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR > $DEBUG_DIR/errors.txt

# 4. Configuration
echo "Collecting configuration..."
cp /opt/spacetime/production/project.godot $DEBUG_DIR/
# Don't copy .env (contains secrets)
cat /opt/spacetime/production/.env | grep -v "SECRET\|PASSWORD\|TOKEN" > $DEBUG_DIR/env-sanitized.txt

# 5. Resource usage
echo "=== Resource Usage ===" > $DEBUG_DIR/resources.txt
top -bn1 >> $DEBUG_DIR/resources.txt
free -h >> $DEBUG_DIR/resources.txt
df -h >> $DEBUG_DIR/resources.txt

# 6. Network status
echo "=== Network Status ===" > $DEBUG_DIR/network.txt
netstat -tlnp | grep -E "6005|6006|8081|8080" >> $DEBUG_DIR/network.txt
ss -s >> $DEBUG_DIR/network.txt

# 7. Process information
echo "=== Process Info ===" > $DEBUG_DIR/process.txt
ps aux | grep godot >> $DEBUG_DIR/process.txt
pstree -p $(pgrep godot) >> $DEBUG_DIR/process.txt

# 8. Git status
cd /opt/spacetime/production
echo "=== Git Status ===" > $DEBUG_DIR/git-info.txt
git log --oneline -10 >> $DEBUG_DIR/git-info.txt
git status >> $DEBUG_DIR/git-info.txt
git describe --tags >> $DEBUG_DIR/git-info.txt

# 9. API health check
echo "=== API Health ===" > $DEBUG_DIR/api-health.txt
curl -s http://localhost:8080/status >> $DEBUG_DIR/api-health.txt

# 10. Metrics snapshot (from Prometheus)
echo "=== Metrics Snapshot ===" > $DEBUG_DIR/metrics.txt
curl -s "https://prometheus.company.com/api/v1/query?query=up{job='spacetime-api'}" >> $DEBUG_DIR/metrics.txt

# 11. Create tarball
cd /tmp
tar -czf debug-$(date +%Y%m%d_%H%M%S).tar.gz debug-$(date +%Y%m%d_%H%M%S)/

echo "Debug package created: /tmp/debug-$(date +%Y%m%d_%H%M%S).tar.gz"
echo "Upload to ticket or share with team"
```

---

### Effective Log Reading

**Log Structure:**
```
[Timestamp] [Level] [Component] Message
```

**Example:**
```
Dec 02 10:15:30 prod-api-01 godot[12345]: [GodotBridge] HTTP server started on port 8080
```

**Reading Logs Efficiently:**

```bash
# 1. Start with time window
sudo journalctl -u godot-spacetime --since "2025-12-02 10:00:00" --until "2025-12-02 11:00:00"

# 2. Filter by severity
sudo journalctl -u godot-spacetime -p err  # Errors only
sudo journalctl -u godot-spacetime -p warning  # Warnings only

# 3. Search for keywords
sudo journalctl -u godot-spacetime | grep -i "error\|fail\|exception"

# 4. Context around errors (show 5 lines before and after)
sudo journalctl -u godot-spacetime | grep -B 5 -A 5 ERROR

# 5. Follow logs in real-time
sudo journalctl -u godot-spacetime -f

# 6. Filter by component
sudo journalctl -u godot-spacetime | grep GodotBridge

# 7. Count occurrences
sudo journalctl -u godot-spacetime | grep ERROR | wc -l

# 8. Unique error messages
sudo journalctl -u godot-spacetime | grep ERROR | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | sort -u

# 9. Error frequency over time
sudo journalctl -u godot-spacetime --since "24 hours ago" | grep ERROR | awk '{print $1, $2, $3}' | uniq -c

# 10. Export logs
sudo journalctl -u godot-spacetime --since "1 hour ago" -o json > logs.json
```

---

## Performance Profiling

### CPU Profiling

```bash
# 1. Identify CPU-intensive process
top -o %CPU

# 2. Profile Godot process
PID=$(pgrep godot)
perf record -p $PID -g -- sleep 60
perf report

# 3. Check for CPU-bound threads
top -H -p $PID

# 4. Flame graph (if available)
# Install flamegraph tools
git clone https://github.com/brendangregg/FlameGraph
perf record -p $PID -g -- sleep 30
perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl > flamegraph.svg
```

### Memory Profiling

```bash
# 1. Current memory usage
ps aux | grep godot | awk '{print $6/1024 " MB"}'

# 2. Memory map
pmap -x $(pgrep godot)

# 3. Memory growth over time
while true; do
  echo "$(date): $(ps aux | grep godot | awk '{print $6/1024}') MB"
  sleep 60
done

# 4. Heap profiling (if Godot has profiling support)
# Use Godot profiler or custom telemetry

# 5. Check for memory leaks
# Compare memory usage over time
# Look for continuous growth
```

### Disk I/O Profiling

```bash
# 1. Real-time I/O monitoring
iostat -x 1 10

# 2. Process I/O
iotop -p $(pgrep godot)

# 3. File access patterns
lsof -p $(pgrep godot)

# 4. Disk latency
ioping /opt/spacetime
```

### Network Profiling

```bash
# 1. Network connections
netstat -anp | grep $(pgrep godot)

# 2. Network throughput
iftop -i eth0

# 3. Connection states
ss -s

# 4. Packet capture (if needed)
tcpdump -i eth0 port 8080 -w capture.pcap

# 5. Analyze capture
wireshark capture.pcap  # Or use tshark
```

---

## Network Troubleshooting

### Connection Issues

**Can't connect to API:**

```bash
# 1. Test from localhost
curl http://localhost:8080/status

# 2. Test from internal network
curl http://10.0.1.50:8080/status

# 3. Test from external
curl https://spacetime-api.company.com/status

# 4. Identify failure point
# If localhost works but external doesn't:
# - Check firewall
# - Check load balancer
# - Check DNS

# 5. Test DNS resolution
dig spacetime-api.company.com
nslookup spacetime-api.company.com

# 6. Test routing
traceroute spacetime-api.company.com

# 7. Test port availability
telnet spacetime-api.company.com 443
```

### Firewall Issues

```bash
# 1. Check iptables rules
sudo iptables -L -n -v | grep -E "6005|6006|8081|8080"

# 2. Check if port is blocked
sudo iptables -L INPUT -n -v | grep DROP

# 3. Add temporary rule (testing only)
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT

# 4. Check security groups (AWS)
aws ec2 describe-security-groups --group-ids sg-xxxxx

# 5. Verify no rate limiting
fail2ban-client status
```

### Load Balancer Issues

```bash
# 1. Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# 2. Check load balancer status
aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN

# 3. Test direct to backend (bypass load balancer)
curl http://10.0.1.50:8080/status

# 4. Check load balancer logs
aws s3 ls s3://my-lb-logs/

# 5. Verify listener configuration
aws elbv2 describe-listeners --load-balancer-arn $LB_ARN
```

---

## When to Escalate

### Escalation Criteria

**Escalate Immediately If:**

1. **Security Incident**
   - Data breach suspected
   - Unauthorized access detected
   - Active attack in progress

2. **Data Loss Risk**
   - Database corruption
   - Backup failure
   - Critical data integrity issue

3. **Complete Outage**
   - All services down
   - Cannot determine root cause within 15 minutes
   - Rollback failed

4. **Beyond Your Expertise**
   - Requires specialized knowledge (database expert, network engineer)
   - Issue in unfamiliar system
   - Complex distributed system problem

5. **Time Pressure**
   - SLA breach imminent
   - High-visibility customer affected
   - Executive escalation

---

### Escalation Procedure

**Step 1: Prepare**

```bash
# Gather information before escalating:
- [ ] Problem description (1-2 sentences)
- [ ] When it started
- [ ] User impact (who/how many affected)
- [ ] What you've tried
- [ ] Current system state
- [ ] Relevant logs/metrics
```

**Step 2: Escalate**

```bash
# Primary escalation path:
1. Senior Engineer (Slack: @senior-engineer-oncall)
2. Engineering Lead (if unavailable or unresolved)
3. Engineering Manager (for critical issues)

# Create escalation message:
"""
🚨 ESCALATION NEEDED

Issue: [Brief description]
Severity: [P0/P1/P2]
Started: [Time]
Impact: [User impact]
Tried: [What you've attempted]
Current State: [System status]
Need: [What you need help with]

Debug package: [Link to collected logs/metrics]
"""
```

**Step 3: Handoff**

```bash
# When escalating:
- [ ] Brief escalation engineer on findings
- [ ] Share access (credentials, VPN, etc.)
- [ ] Remain available for questions
- [ ] Continue monitoring
- [ ] Document outcome for learning
```

---

### Self-Service Resolution vs. Escalation

**Resolve Yourself:**
- Common issues with documented solutions
- Standard operational procedures (restart, clear cache)
- Simple configuration changes
- You have required expertise
- Time permits investigation

**Escalate:**
- Never seen this before
- Requires specialized skills
- Multiple failed resolution attempts
- Time pressure (SLA risk)
- Security concern
- Data loss risk

---

## Troubleshooting FAQs

**Q: Service is slow but not completely down. Is this an incident?**
A: Depends on severity. If response time > 1s (P95), escalate to P1. If response time 500ms-1s, treat as P2.

**Q: Should I restart the service to fix the issue?**
A: Restart is acceptable for:
- Testing if issue is transient
- Clear memory leak (temporary fix)
- After configuration change

Don't restart for:
- Investigating root cause (you'll lose valuable data)
- Without backup/rollback plan
- Without understanding impact

**Q: How long should I investigate before escalating?**
A:
- P0 (critical): 15 minutes
- P1 (high): 30 minutes
- P2 (medium): 1 hour
- P3/P4: Investigate during business hours, escalate if stuck

**Q: Can I make configuration changes during troubleshooting?**
A: Yes, but:
- Make one change at a time
- Document each change
- Have rollback plan
- For P0/P1, get approval first

**Q: Should I wake up senior engineer at 3 AM?**
A: Yes if:
- P0 (critical) incident
- P1 incident you can't resolve in 30 minutes
- Security incident
- Data loss risk

No if:
- P2 or lower
- Issue can wait until business hours
- You're still investigating and making progress

---

## Appendix

### Useful Commands Quick Reference

```bash
# Service management
systemctl status godot-spacetime
systemctl restart godot-spacetime
systemctl stop godot-spacetime
systemctl start godot-spacetime

# Logs
sudo journalctl -u godot-spacetime -f
sudo journalctl -u godot-spacetime -n 100
sudo journalctl -u godot-spacetime --since "1 hour ago"

# Resource monitoring
top -bn1 | head -20
free -h
df -h
iostat -x 1 5

# Network
netstat -tlnp | grep -E "6005|6006|8081|8080"
ss -s
ping -c 3 [host]
telnet [host] [port]

# Process information
ps aux | grep godot
pgrep godot
kill -9 [PID]

# API testing
curl http://localhost:8080/status
curl -X POST http://localhost:8080/connect

# File operations
ls -lah /opt/spacetime/production/
tail -f /var/log/spacetime.log
grep ERROR /var/log/spacetime.log
```

---

### Metrics Interpretation Guide

| Metric | Good | Warning | Critical | Action |
|--------|------|---------|----------|--------|
| CPU % | < 50% | 50-70% | > 70% | Scale/optimize |
| Memory % | < 60% | 60-80% | > 80% | Investigate leak |
| Disk % | < 70% | 70-85% | > 85% | Cleanup/expand |
| Error Rate | < 0.5% | 0.5-1% | > 1% | Investigate |
| Response Time (P95) | < 200ms | 200-500ms | > 500ms | Profile/optimize |
| FPS | 90 | 85-90 | < 85 | Investigate |

---

## Runbook Maintenance

- **Review Frequency:** After each complex troubleshooting session
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-01-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager
