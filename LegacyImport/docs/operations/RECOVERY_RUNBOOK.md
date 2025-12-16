# Recovery Runbook - SpaceTime VR

Quick-reference guide for all failure scenarios and recovery procedures.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Failure Scenario Index](#failure-scenario-index)
- [Recovery Procedures](#recovery-procedures)
  - [Application Server Failure](#application-server-failure)
  - [Database Failure](#database-failure)
  - [Cache Failure](#cache-failure-redis)
  - [Network Partition](#network-partition)
  - [Security Breach](#security-breach)
  - [Data Corruption](#data-corruption)
  - [Configuration Error](#configuration-error)
  - [Cascading Failures](#cascading-failures)
  - [Resource Exhaustion](#resource-exhaustion)
  - [Backup Failure](#backup-failure)
- [Recovery Testing](#recovery-testing)
- [Runbook Maintenance](#runbook-maintenance)

## Quick Reference

### Emergency Commands

```bash
# Quick status check
curl -s http://localhost:8080/status | jq

# Quick rollback to last known good
bash deploy/rollback/rollback.sh --quick

# View recent logs
docker-compose logs --tail=100

# Stop everything immediately
docker-compose down

# Full system restore
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>
```

### Severity Levels

| Level | Description | Response Time | Action |
|-------|-------------|---------------|--------|
| **P1 - Critical** | Complete outage, data loss | Immediate | Page on-call, rollback immediately |
| **P2 - High** | Significant degradation | < 5 min | Alert on-call, prepare rollback |
| **P3 - Medium** | Minor degradation | < 15 min | Alert team, monitor closely |
| **P4 - Low** | Isolated issues | < 1 hour | Log issue, fix in next deploy |

### Rollback Decision Matrix

| Condition | Severity | Action | Level |
|-----------|----------|--------|-------|
| Service down completely | P1 | Rollback immediately | 1 or 3 |
| Error rate > 50% | P1 | Rollback immediately | 1 or 2 |
| Data corruption detected | P1 | Rollback immediately | 3 |
| Error rate 10-50% | P2 | Rollback if not resolved in 5 min | 1 or 2 |
| Response time > 5s | P2 | Rollback if not resolved in 5 min | 1 |
| Error rate 5-10% | P3 | Monitor, consider rollback if worsens | 1 |
| Minor degradation | P3-P4 | Monitor, fix forward | N/A |

## Failure Scenario Index

Each scenario includes:
- **Detection:** How to identify the issue
- **Impact:** What is affected
- **Recovery:** Step-by-step recovery procedure
- **Prevention:** How to prevent recurrence
- **RTO:** Recovery Time Objective
- **Validation:** How to verify recovery

### Scenarios

1. [Application Server Failure](#application-server-failure) - RTO: 5 min
2. [Database Failure](#database-failure) - RTO: 15 min
3. [Cache Failure](#cache-failure-redis) - RTO: 5 min
4. [Network Partition](#network-partition) - RTO: 10 min
5. [Security Breach](#security-breach) - RTO: Varies
6. [Data Corruption](#data-corruption) - RTO: 30 min
7. [Configuration Error](#configuration-error) - RTO: 10 min
8. [Cascading Failures](#cascading-failures) - RTO: 30 min
9. [Resource Exhaustion](#resource-exhaustion) - RTO: 10 min
10. [Backup Failure](#backup-failure) - RTO: N/A

---

## Recovery Procedures

## Application Server Failure

**Scenario:** Godot application container crashes, won't start, or becomes unresponsive

### Detection

**Symptoms:**
- HTTP API returns 502/503 errors
- Container status shows "Exited" or "Restarting"
- Health checks failing
- Monitoring alerts: "Application container down"

**Detection commands:**
```bash
# Check container status
docker-compose ps godot
# Expected: Status should be "Up" and "healthy"

# Check HTTP API
curl http://localhost:8080/health
# Expected: 200 OK

# Check logs for crashes
docker-compose logs --tail=50 godot | grep -i "error\|crash\|segfault"
```

### Impact

- **Severity:** P1 (Critical)
- **User Impact:** Complete service outage
- **Data Impact:** No data loss (in-memory data lost)
- **SLA Impact:** Full downtime

### Recovery Procedure

**RTO: 5 minutes**

#### Step 1: Immediate Assessment (30 seconds)

```bash
# Check if container is running
docker-compose ps godot

# If exited, check exit code
docker inspect spacetime-godot --format='{{.State.ExitCode}}'

# Check recent logs
docker-compose logs --tail=100 godot
```

#### Step 2: Quick Restart Attempt (1 minute)

```bash
# Try simple restart
docker-compose restart godot

# Wait 30 seconds
sleep 30

# Check if healthy
curl http://localhost:8080/status
```

**Decision Point:** If restart successful and healthy, skip to validation. Otherwise, continue to Step 3.

#### Step 3: Level 1 Rollback (3 minutes)

```bash
# Execute quick rollback
bash deploy/rollback/rollback.sh --quick

# This will:
# - Switch traffic to blue environment
# - Verify health
# - Stop failed green environment
```

#### Step 4: Validation (30 seconds)

```bash
# Verify service is responding
curl http://localhost:8080/status | jq '.overall_ready'
# Expected: true

# Run quick smoke tests
bash deploy/smoke_tests.sh --quick

# Monitor for 2 minutes
watch -n 5 'curl -s http://localhost:8080/health'
```

### Root Cause Investigation

```bash
# After recovery, investigate:

# 1. Check logs from failed container
docker logs spacetime-godot-failed > /tmp/crash_logs.txt

# 2. Check for OOM kills
dmesg | grep -i "killed process"

# 3. Check resource usage before crash
# Review Grafana metrics around crash time

# 4. Check for segfaults
docker-compose logs godot | grep -i segfault

# 5. Review recent code changes
git log --oneline -10
```

### Prevention

- **Add health checks:** Ensure health checks cover all critical paths
- **Memory limits:** Set appropriate memory limits in docker-compose.yml
- **Restart policy:** Configure restart policies for automatic recovery
- **Better error handling:** Add try-catch blocks for crash-prone code
- **Resource monitoring:** Set up alerts for high memory/CPU usage
- **Load testing:** Regular load testing to identify breaking points

### Related Procedures

- [Rollback Procedures - Level 1](ROLLBACK_PROCEDURES.md#level-1-quick-rollback)
- [Container debugging](../development/DEBUGGING.md#container-debugging)

---

## Database Failure

**Scenario:** PostgreSQL database is down, unresponsive, or corrupted

### Detection

**Symptoms:**
- Application errors: "Connection refused" or "Database unavailable"
- Container status shows postgres as "Exited"
- Database queries timing out
- Monitoring alerts: "Database connection failed"

**Detection commands:**
```bash
# Check database container
docker-compose ps postgres

# Test database connection
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "SELECT 1"

# Check database logs
docker-compose logs --tail=50 postgres
```

### Impact

- **Severity:** P1 (Critical)
- **User Impact:** Complete service outage (if data-dependent)
- **Data Impact:** Possible data loss depending on failure type
- **SLA Impact:** Full downtime

### Recovery Procedure

**RTO: 15 minutes**

#### Step 1: Immediate Assessment (1 minute)

```bash
# Check database status
docker-compose ps postgres

# Check if database is accessible
docker-compose exec postgres pg_isready -U spacetime

# Check for corruption
docker-compose exec postgres psql -U spacetime -d spacetime_db \
  -c "SELECT datname, pg_database_size(datname) FROM pg_database"
```

#### Step 2: Attempt Database Restart (2 minutes)

```bash
# Stop application to prevent connection spam
docker-compose stop godot nginx

# Restart database
docker-compose restart postgres

# Wait for startup
sleep 30

# Verify database
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "SELECT 1"
```

**Decision Point:** If database starts cleanly, restart application and skip to validation. Otherwise, continue to Step 3.

#### Step 3: Level 2 Rollback (10 minutes)

```bash
# Database not starting cleanly - need full rollback
bash deploy/rollback/rollback.sh --level 2 --target <last-good-backup>

# This will:
# - Stop all services
# - Rollback database migrations
# - Restore configuration
# - Start previous version
```

#### Step 4: If Corruption Detected - Level 3 Recovery (20 minutes)

```bash
# If database corruption detected
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>

# This will:
# - Complete shutdown
# - Restore database from backup dump
# - Replay transaction logs if available
# - Verify data integrity
```

#### Step 5: Validation (2 minutes)

```bash
# Verify database health
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT
    (SELECT COUNT(*) FROM pg_stat_activity) as connections,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public') as tables,
    pg_size_pretty(pg_database_size('spacetime_db')) as size
"

# Verify application connectivity
curl http://localhost:8080/status | jq

# Run database integrity checks
bash tests/database/integrity_check.sh
```

### Root Cause Investigation

```bash
# After recovery:

# 1. Check database logs
docker-compose logs postgres > /tmp/db_failure_logs.txt

# 2. Check for disk space issues
df -h
docker exec spacetime-postgres df -h

# 3. Check for connection exhaustion
# Review Grafana: Database connections metric

# 4. Check for long-running queries
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT pid, age(clock_timestamp(), query_start), usename, query
  FROM pg_stat_activity
  WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%'
  ORDER BY query_start desc
"

# 5. Check PostgreSQL error log
docker-compose exec postgres cat /var/log/postgresql/postgresql-*.log
```

### Prevention

- **Connection pooling:** Implement proper connection pooling
- **Query timeout:** Set statement_timeout to prevent long-running queries
- **Regular backups:** Ensure backup schedule is working (every 6 hours)
- **Monitoring:** Alert on connection count, query duration, disk space
- **Replication:** Set up read replicas for high availability
- **Regular VACUUM:** Schedule regular VACUUM and ANALYZE operations

### Related Procedures

- [Database Rollback](ROLLBACK_PROCEDURES.md#database-migration-rollback)
- [Backup Restoration](BACKUP_DEPLOYMENT_GUIDE.md#restore-from-backup)

---

## Cache Failure (Redis)

**Scenario:** Redis cache is down or unresponsive

### Detection

**Symptoms:**
- Slower response times (cache misses)
- Redis container not running
- Application logs: "Redis connection failed"
- Increased database load

**Detection commands:**
```bash
# Check Redis container
docker-compose ps redis

# Test Redis connection
docker-compose exec redis redis-cli ping
# Expected: PONG

# Check Redis stats
docker-compose exec redis redis-cli INFO stats
```

### Impact

- **Severity:** P2 (High) or P3 (Medium) depending on cache dependency
- **User Impact:** Degraded performance, slower responses
- **Data Impact:** No data loss (cache is ephemeral)
- **SLA Impact:** Degraded performance but service available

### Recovery Procedure

**RTO: 5 minutes**

#### Step 1: Immediate Assessment (30 seconds)

```bash
# Check Redis status
docker-compose ps redis

# Check logs
docker-compose logs --tail=50 redis
```

#### Step 2: Restart Redis (2 minutes)

```bash
# Restart Redis container
docker-compose restart redis

# Wait for startup
sleep 10

# Verify
docker-compose exec redis redis-cli ping
```

**Decision Point:** If Redis starts successfully, skip to validation. Otherwise, continue to Step 3.

#### Step 3: Recreate Redis Container (2 minutes)

```bash
# Stop and remove container
docker-compose stop redis
docker-compose rm -f redis

# Start fresh
docker-compose up -d redis

# Wait for startup
sleep 10

# Verify
docker-compose exec redis redis-cli ping
```

#### Step 4: Validation (30 seconds)

```bash
# Test Redis operations
docker-compose exec redis redis-cli SET test "recovery" EX 60
docker-compose exec redis redis-cli GET test
# Expected: "recovery"

# Check application using cache
curl http://localhost:8080/status | jq

# Monitor response times
# Should improve as cache warms up
```

### Root Cause Investigation

```bash
# After recovery:

# 1. Check Redis logs
docker-compose logs redis > /tmp/redis_failure_logs.txt

# 2. Check memory usage
docker stats redis --no-stream

# 3. Check for evictions
docker-compose exec redis redis-cli INFO stats | grep evicted

# 4. Check maxmemory policy
docker-compose exec redis redis-cli CONFIG GET maxmemory-policy
```

### Prevention

- **Memory limits:** Set appropriate maxmemory and eviction policy
- **Monitoring:** Alert on Redis memory usage, hit rate, evictions
- **Persistence:** Consider RDB/AOF persistence for critical cached data
- **Graceful degradation:** Application should work without cache (slower)
- **Connection retry:** Implement retry logic with exponential backoff

### Related Procedures

- [Cache warming procedures](../development/CACHE_MANAGEMENT.md)
- [Performance optimization](../performance/OPTIMIZATION.md)

---

## Network Partition

**Scenario:** Network connectivity lost between containers or to external services

### Detection

**Symptoms:**
- Containers can't communicate with each other
- DNS resolution failures
- Connection timeouts
- Monitoring alerts: "Container unreachable"

**Detection commands:**
```bash
# Test container networking
docker-compose exec godot ping -c 3 postgres

# Check network connectivity
docker network inspect spacetime_default

# Test DNS resolution
docker-compose exec godot nslookup postgres

# Check routes
docker-compose exec godot ip route
```

### Impact

- **Severity:** P1 (Critical) if internal network partition
- **User Impact:** Service unavailable
- **Data Impact:** No data loss (unless transaction in progress)
- **SLA Impact:** Full downtime

### Recovery Procedure

**RTO: 10 minutes**

#### Step 1: Immediate Assessment (1 minute)

```bash
# Check Docker network
docker network ls
docker network inspect spacetime_default

# Check container connectivity
docker-compose exec godot ping -c 3 postgres
docker-compose exec godot ping -c 3 redis

# Check host networking
ping -c 3 8.8.8.8
```

#### Step 2: Restart Affected Container (2 minutes)

```bash
# If specific container disconnected, restart it
docker-compose restart godot

# Wait for startup
sleep 30

# Test connectivity
docker-compose exec godot ping -c 3 postgres
```

**Decision Point:** If connectivity restored, skip to validation. Otherwise, continue to Step 3.

#### Step 3: Recreate Docker Network (5 minutes)

```bash
# Stop all containers
docker-compose down

# Remove network
docker network rm spacetime_default

# Recreate everything
docker-compose up -d

# Wait for startup
sleep 60
```

#### Step 4: Validation (2 minutes)

```bash
# Test internal connectivity
docker-compose exec godot ping -c 3 postgres
docker-compose exec godot ping -c 3 redis

# Test service availability
curl http://localhost:8080/status | jq

# Test database connectivity
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "SELECT 1"

# Run smoke tests
bash deploy/smoke_tests.sh --quick
```

### Root Cause Investigation

```bash
# After recovery:

# 1. Check Docker daemon logs
journalctl -u docker -n 100

# 2. Check network settings
docker network inspect spacetime_default

# 3. Check firewall rules
sudo iptables -L -n
sudo ip6tables -L -n

# 4. Check for network conflicts
docker network ls
# Look for overlapping IP ranges

# 5. Check host networking
netstat -tulpn
```

### Prevention

- **Network isolation:** Use dedicated networks for different services
- **Health checks:** Implement network health checks
- **Monitoring:** Alert on network connectivity issues
- **Retry logic:** Implement connection retry with backoff
- **Network redundancy:** Use overlay networks for multi-host deployments

### Related Procedures

- [Docker networking guide](https://docs.docker.com/network/)
- [Troubleshooting connectivity](../development/NETWORKING.md)

---

## Security Breach

**Scenario:** Unauthorized access, security vulnerability exploited, or suspicious activity detected

### Detection

**Symptoms:**
- Security alerts from monitoring systems
- Unusual access patterns in logs
- Unexpected privilege escalations
- Data exfiltration detected
- Malware/rootkit detection

**Detection commands:**
```bash
# Check for suspicious processes
docker-compose exec godot ps aux

# Check active connections
docker-compose exec godot netstat -tupln

# Check for unauthorized access
docker-compose logs --since 1h | grep -i "unauthorized\|forbidden\|authentication failed"

# Check file integrity
docker-compose exec godot find /app -mtime -1 -ls
```

### Impact

- **Severity:** P1 (Critical)
- **User Impact:** Immediate service shutdown (security isolation)
- **Data Impact:** Potential data breach, data loss, or corruption
- **SLA Impact:** Extended downtime during investigation

### Recovery Procedure

**RTO: Varies (security-driven, not time-driven)**

#### Step 1: IMMEDIATE ISOLATION (1 minute)

```bash
# STOP ALL SERVICES IMMEDIATELY
docker-compose down

# BLOCK EXTERNAL ACCESS
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -j DROP
sudo iptables -A INPUT -p tcp --dport 8080 -j DROP

# DISCONNECT FROM NETWORK (if needed)
# docker network disconnect spacetime_default spacetime-godot
```

**⚠️ CRITICAL: DO NOT RESTART SERVICES WITHOUT SECURITY TEAM APPROVAL**

#### Step 2: PRESERVE EVIDENCE (5 minutes)

```bash
# Collect logs
docker-compose logs > /tmp/incident-logs-$(date +%Y%m%d-%H%M%S).log

# Create forensic snapshot
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker commit spacetime-godot spacetime-forensic-$TIMESTAMP
docker commit spacetime-postgres spacetime-postgres-forensic-$TIMESTAMP

# Preserve container state
docker inspect spacetime-godot > /tmp/container-state-$TIMESTAMP.json

# Preserve file system
docker cp spacetime-godot:/app /tmp/forensic-app-$TIMESTAMP/
docker cp spacetime-godot:/data /tmp/forensic-data-$TIMESTAMP/

# Create evidence archive
tar czf /tmp/security-incident-evidence-$TIMESTAMP.tar.gz \
  /tmp/incident-logs-*.log \
  /tmp/container-state-*.json \
  /tmp/forensic-*
```

#### Step 3: NOTIFY SECURITY TEAM (Immediately)

```bash
# Send alert
# Contact: security@company.com
# Phone: [Security team phone]
# Slack: #security-incidents

# Include:
# - Incident timestamp
# - Services affected
# - Evidence location
# - Current system state
```

#### Step 4: SECURITY INVESTIGATION (Time varies)

**Led by Security Team:**
- Forensic analysis of evidence
- Identify breach vector
- Assess data exposure
- Determine scope of compromise
- Review access logs

**Do NOT proceed to recovery until security team approves.**

#### Step 5: CLEAN RECOVERY (After security clearance)

```bash
# Option 1: Clean deployment from verified source
# Pull clean images from verified registry
docker pull registry.company.com/spacetime:verified-clean

# Deploy clean version
docker-compose -f docker-compose.clean.yml up -d

# Option 2: Full Level 3 recovery from pre-breach backup
# Identify last known good backup BEFORE breach
CLEAN_BACKUP="20251201-120000"  # BEFORE breach timestamp

bash deploy/rollback/rollback.sh --level 3 --target $CLEAN_BACKUP
```

#### Step 6: SECURITY HARDENING (Before production)

```bash
# Rotate all credentials
# - Database passwords
# - API keys
# - SSL certificates
# - SSH keys
# - Service tokens

# Update to patched versions
docker-compose pull

# Apply security patches
# ...

# Security scan
docker scan spacetime:latest

# Vulnerability assessment
# Run security audit tools
```

#### Step 7: GRADUAL RESTORATION

```bash
# Start in isolated environment
# Deploy to staging first
# Run security scans
# Monitor for 24+ hours
# Gradual rollout to production

# Enable monitoring and auditing
# - Increased logging
# - File integrity monitoring
# - Network traffic analysis
# - Access auditing
```

### Post-Incident Actions

```bash
# 1. Security post-mortem
# 2. Update security procedures
# 3. Implement additional safeguards
# 4. User notification (if required by law)
# 5. Regulatory reporting (if applicable)
# 6. Insurance claim (if applicable)
```

### Prevention

- **Security scanning:** Regular vulnerability scans
- **Dependency updates:** Keep all dependencies up to date
- **Access control:** Principle of least privilege
- **Monitoring:** Real-time security monitoring and alerting
- **Penetration testing:** Regular security assessments
- **Security training:** Team security awareness training
- **Incident response plan:** Regular drills and updates
- **Network segmentation:** Isolate services
- **Encryption:** Encrypt data at rest and in transit
- **Audit logging:** Comprehensive audit trails

### Related Procedures

- [Security Incident Response Plan](../security/INCIDENT_RESPONSE.md)
- [Forensic Analysis Guide](../security/FORENSICS.md)
- [Security Hardening Checklist](../security/HARDENING.md)

---

## Data Corruption

**Scenario:** Data integrity issues, corrupted files, or inconsistent database state

### Detection

**Symptoms:**
- Database constraint violations
- Application errors: "Data integrity error"
- Corrupted files detected
- Inconsistent query results
- Monitoring alerts: "Data corruption detected"

**Detection commands:**
```bash
# Check for corruption markers
docker-compose exec godot test -f /data/corruption_detected
echo "Exit code: $?"  # 0 means file exists (corruption detected)

# Database integrity check
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
  FROM pg_tables WHERE schemaname = 'public'
"

# Check database for corruption
docker-compose exec postgres pg_checksums --check

# Application data validation
curl http://localhost:8080/admin/data-integrity-check
```

### Impact

- **Severity:** P1 (Critical)
- **User Impact:** Service must be stopped immediately
- **Data Impact:** Data loss back to last clean backup
- **SLA Impact:** Extended downtime

### Recovery Procedure

**RTO: 30 minutes**

#### Step 1: IMMEDIATE SHUTDOWN (1 minute)

```bash
# STOP ALL SERVICES TO PREVENT FURTHER CORRUPTION
docker-compose down

# DO NOT RESTART UNTIL RECOVERY COMPLETE
```

#### Step 2: Assess Corruption Extent (5 minutes)

```bash
# Create snapshot of corrupted state for analysis
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker run --rm \
  -v spacetime_godot-data:/data \
  -v /tmp:/backup \
  alpine tar czf /backup/corrupted-state-$TIMESTAMP.tar.gz /data

# Start database in single-user mode for inspection
docker-compose up -d postgres

# Check database corruption
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT datname, pg_database_size(datname),
    (SELECT COUNT(*) FROM pg_stat_activity WHERE datname = pg_database.datname) as connections
  FROM pg_database
"

# Identify corrupted tables
docker-compose exec postgres pg_checksums --check 2>&1 | grep -i corrupt

# Stop database again
docker-compose stop postgres
```

#### Step 3: Level 3 Point-in-Time Recovery (20 minutes)

```bash
# Identify last known good backup
ls -lt /opt/spacetime/backups/
# Choose backup from BEFORE corruption

CLEAN_BACKUP="20251202-060000"

# Execute Level 3 recovery
bash deploy/rollback/rollback.sh --level 3 --target $CLEAN_BACKUP

# This performs:
# - Complete data volume restore
# - Database restore from dump
# - Transaction log replay (if available)
# - Data integrity verification
```

#### Step 4: Data Integrity Verification (4 minutes)

```bash
# Comprehensive data validation
bash deploy/rollback/validate_rollback.sh --thorough

# Additional database checks
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  -- Check for NULL values in NOT NULL columns
  SELECT * FROM information_schema.columns
  WHERE is_nullable = 'NO' AND table_schema = 'public';

  -- Verify foreign key constraints
  SELECT conname, conrelid::regclass, confrelid::regclass
  FROM pg_constraint WHERE contype = 'f';
"

# Verify critical data
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT
    (SELECT COUNT(*) FROM users) as users,
    (SELECT COUNT(*) FROM game_state) as game_states,
    (SELECT COUNT(*) FROM sessions) as sessions
"

# Check for corruption markers
docker-compose exec godot test ! -f /data/corruption_detected
echo "Clean: $?"  # Should be 0
```

### Root Cause Investigation

```bash
# After recovery:

# 1. Analyze corrupted state snapshot
tar xzf /tmp/corrupted-state-$TIMESTAMP.tar.gz -C /tmp/analysis/

# 2. Check for hardware issues
docker-compose exec postgres dmesg | grep -i "error\|hardware"

# 3. Review application logs before corruption
docker-compose logs --since 24h > /tmp/logs-before-corruption.txt

# 4. Check for concurrent access issues
# Review application connection pooling settings

# 5. Check disk health
sudo smartctl -a /dev/sda
df -h
```

### Prevention

- **Regular backups:** Automated backups every 6 hours minimum
- **Checksums:** Enable PostgreSQL checksums
- **Transactions:** Use database transactions properly
- **Validation:** Add data validation at application level
- **Monitoring:** Alert on data integrity issues immediately
- **Testing:** Regular recovery testing
- **RAID:** Use RAID for data redundancy
- **Replication:** PostgreSQL streaming replication

### Related Procedures

- [Point-in-Time Recovery](ROLLBACK_PROCEDURES.md#level-3-point-in-time-recovery)
- [Backup Procedures](BACKUP_DEPLOYMENT_GUIDE.md)
- [Data Integrity Monitoring](MONITORING_DEPLOYMENT.md#data-integrity)

---

## Configuration Error

**Scenario:** Invalid configuration causing service failures

### Detection

**Symptoms:**
- Services fail to start
- Configuration validation errors
- Application behaving incorrectly
- Environment variable issues

**Detection commands:**
```bash
# Validate docker-compose configuration
docker-compose config

# Check environment variables
docker-compose exec godot env | grep GODOT

# Verify configuration files
docker-compose exec godot cat /app/config.json | jq
```

### Impact

- **Severity:** P2 (High) to P3 (Medium)
- **User Impact:** Service unavailable or degraded
- **Data Impact:** No data loss
- **SLA Impact:** Downtime until fixed

### Recovery Procedure

**RTO: 10 minutes**

#### Step 1: Identify Configuration Issue (2 minutes)

```bash
# Check docker-compose validation
docker-compose config 2>&1 | grep -i error

# Check container logs for config errors
docker-compose logs --tail=100 | grep -i "config\|configuration\|invalid"

# Check environment file
cat .env | grep -v "^#" | grep -v "^$"
```

#### Step 2: Level 2 Rollback (8 minutes)

```bash
# Rollback to previous configuration
bash deploy/rollback/rollback.sh --level 2 --target <last-good-backup>

# This restores:
# - docker-compose.yml
# - .env file
# - All configuration files
```

#### Alternative: Manual Configuration Fix

```bash
# If configuration error is known and simple

# 1. Stop services
docker-compose down

# 2. Fix configuration
vim .env
# or
vim docker-compose.yml

# 3. Validate
docker-compose config

# 4. Restart
docker-compose up -d

# 5. Verify
curl http://localhost:8080/status | jq
```

### Prevention

- **Validation:** Validate configuration before deployment
- **Version control:** Track all configuration in git
- **Testing:** Test configuration changes in staging first
- **Separation:** Use separate configs for different environments
- **Templates:** Use templating for configuration generation
- **Documentation:** Document all configuration options

### Related Procedures

- [Configuration Management](../development/CONFIGURATION.md)
- [Environment Variables](../development/ENVIRONMENT_VARIABLES.md)

---

## Cascading Failures

**Scenario:** Multiple service failures causing system-wide outage

### Detection

**Symptoms:**
- Multiple containers failing simultaneously
- Services timing out waiting for dependencies
- Increasing error rates across all services
- Monitoring alerts from multiple systems

**Detection commands:**
```bash
# Check all service status
docker-compose ps

# Check logs from all services
docker-compose logs --tail=50

# Check resource usage
docker stats --no-stream

# Check system resources
df -h
free -h
```

### Impact

- **Severity:** P1 (Critical)
- **User Impact:** Complete system failure
- **Data Impact:** Potential data loss
- **SLA Impact:** Extended downtime

### Recovery Procedure

**RTO: 30 minutes**

#### Step 1: Stop the Cascade (2 minutes)

```bash
# Immediately stop all services
docker-compose down --timeout 60

# Prevent automatic restarts
docker update --restart=no $(docker ps -aq)

# Check system resources
df -h
free -h
docker system df
```

#### Step 2: Identify Root Cause (5 minutes)

```bash
# Common cascading failure causes:

# 1. Resource exhaustion
df -h  # Disk full?
free -h  # Out of memory?
docker stats --no-stream  # Container resource issues?

# 2. Network issues
docker network inspect spacetime_default

# 3. Database overload
docker-compose logs postgres | grep -i "too many connections"

# 4. Circular dependencies
# Review service startup order
```

#### Step 3: Resolve Resource Issues (if applicable) (5 minutes)

```bash
# If disk full:
docker system prune -af --volumes
# Free up space: remove old logs, backups, etc.

# If memory exhausted:
# Identify memory hog
docker stats --no-stream | sort -k 4 -h

# Kill memory-intensive processes if needed
```

#### Step 4: Level 3 Recovery (15 minutes)

```bash
# Full system restore from last known good state
bash deploy/rollback/rollback.sh --level 3 --target <clean-backup>

# This performs complete system recovery:
# - Data restore
# - Database restore
# - Configuration restore
# - Service restart in correct order
```

#### Step 5: Staged Service Startup (if manual recovery needed)

```bash
# Start services in dependency order:

# 1. Database
docker-compose up -d postgres
sleep 20

# 2. Cache
docker-compose up -d redis
sleep 10

# 3. Application
docker-compose up -d godot
sleep 30

# 4. Reverse proxy
docker-compose up -d nginx
sleep 10

# 5. Monitoring
docker-compose up -d prometheus grafana
```

#### Step 6: Validation (3 minutes)

```bash
# Check all services
docker-compose ps

# Verify health
bash deploy/rollback/validate_rollback.sh --thorough

# Monitor for stability
watch -n 5 'docker-compose ps'
```

### Prevention

- **Resource limits:** Set container resource limits
- **Health checks:** Implement comprehensive health checks
- **Circuit breakers:** Implement circuit breaker pattern
- **Graceful degradation:** Services should degrade gracefully
- **Dependency management:** Minimize tight coupling
- **Monitoring:** Multi-level monitoring and alerting
- **Capacity planning:** Regular capacity reviews

### Related Procedures

- [System Architecture](../architecture/SYSTEM_DESIGN.md)
- [Dependency Management](../development/DEPENDENCIES.md)

---

## Resource Exhaustion

**Scenario:** CPU, memory, disk, or network resources exhausted

### Detection

**Symptoms:**
- Slow performance
- OOM (Out of Memory) kills
- Disk full errors
- High CPU usage

**Detection commands:**
```bash
# System resources
free -h
df -h
top -bn1 | head -20

# Container resources
docker stats --no-stream

# Disk usage by container
docker system df -v
```

### Impact

- **Severity:** P2 (High)
- **User Impact:** Degraded performance or service unavailable
- **Data Impact:** Minimal unless disk full
- **SLA Impact:** Performance degradation

### Recovery Procedure

**RTO: 10 minutes**

#### Memory Exhaustion

```bash
# Identify memory hog
docker stats --no-stream | sort -k 4 -h

# Restart heavy container
docker-compose restart godot

# If OOM kills happening:
# Increase memory limit in docker-compose.yml
# or reduce application memory footprint
```

#### Disk Exhaustion

```bash
# Free up space immediately
docker system prune -af

# Remove old logs
find /var/log -name "*.log" -mtime +7 -delete

# Remove old backups
find /opt/spacetime/backups -mtime +30 -delete

# Check large files
du -sh /* | sort -h | tail -10

# Verify space freed
df -h
```

#### CPU Exhaustion

```bash
# Identify CPU hog
docker stats --no-stream | sort -k 3 -h

# Check processes
docker-compose exec godot top -bn1

# Restart if runaway process
docker-compose restart godot

# Scale down if load spike
# Reduce concurrent connections
```

### Prevention

- **Resource limits:** Set CPU and memory limits
- **Monitoring:** Alert on high resource usage
- **Log rotation:** Implement log rotation
- **Disk quotas:** Set volume size limits
- **Auto-scaling:** Implement horizontal scaling
- **Optimization:** Regular performance optimization

---

## Backup Failure

**Scenario:** Backup system failing to create backups

### Detection

**Symptoms:**
- Backup alerts
- Missing recent backups
- Backup validation failures

**Detection commands:**
```bash
# Check recent backups
ls -lt /opt/spacetime/backups/ | head -10

# Check backup logs
cat /var/log/spacetime-backup.log

# Validate latest backup
bash deploy/backup_validate.sh
```

### Recovery Procedure

```bash
# 1. Immediate manual backup
bash deploy/backup_current_state.sh

# 2. Check backup script logs
cat /var/log/backup.log

# 3. Verify backup storage
df -h /opt/spacetime/backups

# 4. Fix backup schedule (cron)
crontab -e

# 5. Test backup process
bash deploy/backup.sh --test

# 6. Verify backup restoration
bash deploy/restore_test.sh
```

### Prevention

- **Backup monitoring:** Alert if backup fails
- **Multiple backup locations:** Off-site backups
- **Regular testing:** Test restore procedures monthly
- **Automation:** Automated backup validation
- **Documentation:** Clear backup procedures

---

## Recovery Testing

Regular testing ensures recovery procedures work when needed.

### Testing Schedule

- **Weekly:** Quick recovery test (Level 1)
- **Monthly:** Full rollback test (Level 2)
- **Quarterly:** Disaster recovery drill (Level 3)
- **Annually:** Full chaos engineering tests

### Test Procedures

```bash
# Weekly Level 1 test
bash tests/recovery/test_failure_scenarios.py --scenario "Application Crash Recovery" --dry-run

# Monthly Level 2 test
bash tests/recovery/test_failure_scenarios.py --tag "database" --dry-run

# Quarterly Level 3 drill
# Scheduled maintenance window
bash tests/recovery/test_disaster_recovery.sh --environment staging

# Annual chaos engineering
bash tests/recovery/test_failure_scenarios.py --dry-run
```

### Testing Best Practices

1. **Use staging environment** for destructive tests
2. **Document test results**
3. **Update procedures** based on test findings
4. **Time all recovery procedures**
5. **Verify RTO/RPO** targets are met
6. **Train team members** on procedures

---

## Runbook Maintenance

This runbook must be kept up-to-date.

### Review Schedule

- **Weekly:** Review recent incidents
- **Monthly:** Update based on new learnings
- **Quarterly:** Full runbook review
- **After incidents:** Update within 24 hours

### Update Process

1. Identify gaps or outdated information
2. Test updated procedures
3. Update documentation
4. Review with team
5. Commit changes to version control

### Version Control

```bash
# Track runbook in git
git add docs/operations/RECOVERY_RUNBOOK.md
git commit -m "Update recovery procedures for [scenario]"
git push

# Tag significant updates
git tag -a runbook-v2.0 -m "Major runbook update"
git push --tags
```

---

**Document Version:** 2.0
**Last Updated:** 2025-12-02
**Next Review:** 2025-03-02
**Maintained By:** Operations Team
**Emergency Contact:** [On-call rotation]
