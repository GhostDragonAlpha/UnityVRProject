# Common Commands - Quick Reference

**SpaceTime HTTP Scene Management API**
**Version:** 2.5.0

---

## Service Management

```bash
# Check service status
systemctl status godot-spacetime

# Start service
sudo systemctl start godot-spacetime

# Stop service
sudo systemctl stop godot-spacetime

# Restart service
sudo systemctl restart godot-spacetime

# Reload service configuration
sudo systemctl reload godot-spacetime

# Enable on boot
sudo systemctl enable godot-spacetime

# Disable on boot
sudo systemctl disable godot-spacetime

# View service dependencies
systemctl list-dependencies godot-spacetime
```

---

## Health Checks

```bash
# Quick health check
curl http://localhost:8080/status

# Detailed health check with formatting
curl -s http://localhost:8080/status | jq .

# Check if overall system ready
curl -s http://localhost:8080/status | jq -r .overall_ready

# Test all services
curl -s http://localhost:8080/status | jq '{
  overall: .overall_ready,
  dap: .debug_adapter.state,
  lsp: .language_server.state
}'

# External health check
curl -s https://spacetime-api.company.com/status | jq .

# Health check with timing
time curl -s http://localhost:8080/status > /dev/null
```

---

## Log Management

```bash
# View recent logs (last 100 lines)
sudo journalctl -u godot-spacetime -n 100

# Follow logs in real-time
sudo journalctl -u godot-spacetime -f

# Logs since specific time
sudo journalctl -u godot-spacetime --since "2025-12-02 10:00:00"

# Logs between times
sudo journalctl -u godot-spacetime \
  --since "10:00:00" --until "11:00:00"

# Logs from last hour
sudo journalctl -u godot-spacetime --since "1 hour ago"

# Logs from last N minutes
sudo journalctl -u godot-spacetime --since "30 minutes ago"

# Filter by priority (errors only)
sudo journalctl -u godot-spacetime -p err

# Search for keyword
sudo journalctl -u godot-spacetime | grep -i "error"

# Search with context (5 lines before/after)
sudo journalctl -u godot-spacetime | grep -B 5 -A 5 "ERROR"

# Count errors
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep -c ERROR

# Export logs to file
sudo journalctl -u godot-spacetime --since "1 hour ago" > /tmp/logs.txt

# View logs in JSON format
sudo journalctl -u godot-spacetime -o json --since "1 hour ago"
```

---

## Resource Monitoring

```bash
# CPU and memory snapshot
top -bn1 | head -20

# Continuous resource monitoring
top

# Monitor specific process
top -p $(pgrep godot)

# Memory usage
free -h

# Detailed memory info
cat /proc/meminfo

# Disk usage
df -h

# Disk usage for specific directory
du -h /opt/spacetime --max-depth=1

# Disk I/O statistics
iostat -x 1 5

# Network statistics
netstat -s

# Network connections
netstat -tlnp

# Active connections
ss -s

# Process resource usage
ps aux | grep godot

# Detailed process information
ps -fp $(pgrep godot)

# Process tree
pstree -p $(pgrep godot)

# System load average
uptime

# System resource summary
vmstat 1 5
```

---

## Network Debugging

```bash
# Check ports listening
sudo netstat -tlnp | grep -E "6005|6006|8081|8080"

# Alternative using ss
sudo ss -tlnp | grep -E "6005|6006|8081|8080"

# Check specific port
sudo lsof -i :8080

# Test connectivity
ping -c 3 spacetime-api.company.com

# Test port connectivity
telnet spacetime-api.company.com 443

# Alternative using nc
nc -zv spacetime-api.company.com 443

# DNS lookup
dig spacetime-api.company.com

# Alternative DNS lookup
nslookup spacetime-api.company.com

# Trace route
traceroute spacetime-api.company.com

# Alternative traceroute
mtr spacetime-api.company.com

# Check firewall rules
sudo iptables -L -n -v

# Network interface statistics
ip -s link

# View routing table
ip route show
```

---

## API Testing

```bash
# Test status endpoint
curl http://localhost:8080/status

# Test connect endpoint
curl -X POST http://localhost:8080/connect

# Test with authentication header
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/status

# POST with JSON data
curl -X POST http://localhost:8080/scene/load \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'

# Measure response time
curl -o /dev/null -s -w "%{time_total}\n" \
  http://localhost:8080/status

# Detailed timing
curl -o /dev/null -s -w "\
  DNS: %{time_namelookup}s\n\
  Connect: %{time_connect}s\n\
  Start Transfer: %{time_starttransfer}s\n\
  Total: %{time_total}s\n" \
  http://localhost:8080/status

# Show response headers
curl -I http://localhost:8080/status

# Verbose output
curl -v http://localhost:8080/status

# Save response to file
curl -o response.json http://localhost:8080/status

# Follow redirects
curl -L http://spacetime-api.company.com/status
```

---

## File Operations

```bash
# List files in production directory
ls -la /opt/spacetime/production/

# Find large files
find /opt/spacetime -type f -size +100M

# Find files modified recently
find /opt/spacetime/production -type f -mtime -1

# Check file permissions
ls -l /opt/spacetime/production/.env

# Change file ownership
sudo chown spacetime-app:spacetime-app /opt/spacetime/production/file

# Change file permissions
sudo chmod 644 /opt/spacetime/production/file

# View file size
du -h /opt/spacetime/production/vr_main.tscn

# Count lines in file
wc -l /opt/spacetime/logs/godot.log

# View first/last N lines
head -n 20 /opt/spacetime/logs/godot.log
tail -n 20 /opt/spacetime/logs/godot.log

# Follow file changes
tail -f /opt/spacetime/logs/godot.log

# Search in files
grep -r "error" /opt/spacetime/logs/

# Search with line numbers
grep -rn "error" /opt/spacetime/logs/

# Case-insensitive search
grep -ri "error" /opt/spacetime/logs/

# Count occurrences
grep -rc "error" /opt/spacetime/logs/

# Compress file
gzip /opt/spacetime/logs/old.log

# Decompress file
gunzip /opt/spacetime/logs/old.log.gz

# Create tar archive
tar -czf backup.tar.gz /opt/spacetime/production/

# Extract tar archive
tar -xzf backup.tar.gz

# List tar contents
tar -tzf backup.tar.gz
```

---

## Process Management

```bash
# Find process by name
pgrep godot

# Find process with details
ps aux | grep godot

# Kill process (graceful)
kill $(pgrep godot)

# Kill process (force)
kill -9 $(pgrep godot)

# Kill by name
pkill godot

# Check if process is running
pgrep godot && echo "Running" || echo "Not running"

# Get process environment
cat /proc/$(pgrep godot)/environ | tr '\0' '\n'

# Get process working directory
ls -la /proc/$(pgrep godot)/cwd

# Get process open files
lsof -p $(pgrep godot)

# Get process threads
ps -T -p $(pgrep godot)

# Process CPU affinity
taskset -cp $(pgrep godot)

# Process priority
ps -o pid,pri,ni,comm -p $(pgrep godot)

# Change process priority
sudo renice -n 10 -p $(pgrep godot)
```

---

## Git Operations

```bash
# Check current version
cd /opt/spacetime/production && git describe --tags

# View recent commits
git log --oneline -10

# Check for uncommitted changes
git status

# View changed files
git diff --name-only

# View specific commit
git show <commit-hash>

# View file at specific commit
git show <commit-hash>:path/to/file

# Find when file was changed
git log --follow -- path/to/file

# Search commits for keyword
git log --grep="keyword"

# View current branch
git branch

# View all branches
git branch -a

# Check remote URL
git remote -v

# Fetch latest changes (don't merge)
git fetch origin

# Pull latest changes
git pull origin main
```

---

## Backup Operations

```bash
# Create full backup
sudo /opt/spacetime/scripts/backup_full.sh

# Create incremental backup
sudo /opt/spacetime/scripts/backup_incremental.sh

# List available backups
ls -lt /opt/spacetime/backups/*.tar.gz | head -10

# Check backup size
du -h /opt/spacetime/backups/production_*.tar.gz

# Verify backup integrity
sha256sum -c /opt/spacetime/backups/backup.tar.gz.sha256

# List backup contents
tar -tzf /opt/spacetime/backups/backup.tar.gz | less

# Extract specific file from backup
tar -xzf /opt/spacetime/backups/backup.tar.gz \
  --wildcards "*/vr_main.tscn"

# Restore full backup
sudo /opt/spacetime/scripts/restore_backup.sh backup.tar.gz

# Upload backup to S3
aws s3 cp /opt/spacetime/backups/backup.tar.gz \
  s3://company-backups/spacetime/

# Download backup from S3
aws s3 cp s3://company-backups/spacetime/backup.tar.gz \
  /opt/spacetime/backups/
```

---

## Performance Analysis

```bash
# Response time test (average of 10 requests)
for i in {1..10}; do
  curl -o /dev/null -s -w "%{time_total}\n" \
    http://localhost:8080/status
done | awk '{sum+=$1} END {print "Average:", sum/NR*1000, "ms"}'

# Check request rate
# (requires metrics endpoint)
curl -s http://localhost:8080/metrics | grep request_count

# Monitor FPS via telemetry
python3 /opt/spacetime/scripts/monitor_fps.py

# Profile CPU usage over time
sar -u 1 60

# Profile memory usage over time
sar -r 1 60

# Profile disk I/O over time
sar -d 1 60

# Network bandwidth usage
sar -n DEV 1 60

# System performance report
sar -A

# Generate flame graph
sudo perf record -p $(pgrep godot) -g -- sleep 30
sudo perf script | flamegraph.pl > perf.svg
```

---

## Quick Troubleshooting

```bash
# One-liner health check
curl -s http://localhost:8080/status | jq -r \
  'if .overall_ready then "✓ HEALTHY" else "✗ UNHEALTHY" end'

# Check all critical components
echo "=== SpaceTime Health Check ===" && \
systemctl is-active godot-spacetime && \
curl -s http://localhost:8080/status | jq .overall_ready && \
df -h /opt/spacetime | tail -1 && \
free -h | grep Mem

# Quick resource check
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')" && \
echo "Memory: $(free | grep Mem | awk '{print $3/$2 * 100.0 "%"}')" && \
echo "Disk: $(df -h /opt/spacetime | tail -1 | awk '{print $5}')"

# Find and kill zombie processes
ps aux | grep 'Z' | grep godot | awk '{print $2}' | xargs -r sudo kill -9

# Clear old logs
find /opt/spacetime/logs -name "*.log" -mtime +7 -delete

# Emergency restart
sudo systemctl stop godot-spacetime && sleep 5 && \
sudo systemctl start godot-spacetime && sleep 10 && \
curl http://localhost:8080/status

# Collect debug package
mkdir -p /tmp/debug && \
systemctl status godot-spacetime > /tmp/debug/service.txt && \
sudo journalctl -u godot-spacetime -n 100 > /tmp/debug/logs.txt && \
curl -s http://localhost:8080/status > /tmp/debug/health.json && \
top -bn1 > /tmp/debug/resources.txt && \
tar -czf /tmp/spacetime-debug-$(date +%Y%m%d_%H%M%S).tar.gz -C /tmp debug/
```

---

## Emergency Procedures

```bash
# Force stop service
sudo systemctl kill -s SIGKILL godot-spacetime

# Remove stale PID file
sudo rm -f /var/run/godot-spacetime.pid

# Clear port 8080 if blocked
sudo lsof -ti:8080 | xargs -r sudo kill -9

# Restart with fresh state
sudo systemctl stop godot-spacetime && \
sudo rm -rf /tmp/godot-* && \
sudo systemctl start godot-spacetime

# Rollback to previous version
cd /opt/spacetime && \
sudo systemctl stop godot-spacetime && \
sudo ln -sfn production.backup production && \
sudo systemctl start godot-spacetime

# Emergency log cleanup
sudo truncate -s 0 /opt/spacetime/logs/godot.log

# Free memory cache
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

---

## Useful Aliases

Add to `~/.bashrc`:

```bash
# SpaceTime aliases
alias st-status='systemctl status godot-spacetime'
alias st-logs='sudo journalctl -u godot-spacetime -f'
alias st-restart='sudo systemctl restart godot-spacetime'
alias st-health='curl -s http://localhost:8080/status | jq .'
alias st-errors='sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR'
alias st-top='top -p $(pgrep godot)'
```

---

## Quick Reference Card

**Print and keep near your desk!**

```
╔═══════════════════════════════════════════════════════════╗
║         SPACETIME API - QUICK REFERENCE                   ║
╠═══════════════════════════════════════════════════════════╣
║ Health Check:                                             ║
║   curl http://localhost:8080/status | jq .overall_ready   ║
║                                                           ║
║ Restart Service:                                          ║
║   sudo systemctl restart godot-spacetime                  ║
║                                                           ║
║ View Logs:                                                ║
║   sudo journalctl -u godot-spacetime -f                   ║
║                                                           ║
║ Check Resources:                                          ║
║   top -p $(pgrep godot)                                   ║
║                                                           ║
║ Emergency Contact:                                        ║
║   PagerDuty: spacetime-oncall                             ║
║   Slack: #spacetime-incidents                             ║
║                                                           ║
║ Runbooks:                                                 ║
║   /opt/spacetime/docs/runbooks/                           ║
╚═══════════════════════════════════════════════════════════╝
```
