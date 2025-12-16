# Log Locations - Quick Reference

**SpaceTime HTTP Scene Management API**
**Version:** 2.5.0

---

## Primary Log Locations

### Service Logs (systemd/journald)
```bash
# Real-time logs
sudo journalctl -u godot-spacetime -f

# Last 100 lines
sudo journalctl -u godot-spacetime -n 100

# Since specific time
sudo journalctl -u godot-spacetime --since "2025-12-02 10:00:00"

# Export to file
sudo journalctl -u godot-spacetime > /tmp/service-logs.txt
```

**Location:** Managed by systemd (not file-based)
**Retention:** System default (usually 1-2 weeks)
**Format:** Structured logging with timestamps

---

### Application Logs
```bash
# Main application log
/var/log/spacetime/godot.log

# HTTP API log
/var/log/spacetime/http-api.log

# Telemetry server log
/var/log/spacetime/telemetry.log

# Error log
/var/log/spacetime/error.log
```

**Retention:** 7 days (rotated daily)
**Format:** Plain text, timestamped
**Rotation:** Managed by logrotate

---

### Deployment Logs
```bash
# Deployment script logs
/var/log/spacetime-deployment.log

# Backup logs
/var/log/spacetime-backup.log

# Maintenance logs
/var/log/spacetime-maintenance.log
```

---

## Log Categories

### Error Logs
**What:** Critical errors, exceptions, failures
**Location:** `journalctl -u godot-spacetime -p err`
**Filter:**
```bash
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR
```

### Warning Logs
**What:** Warnings, potential issues
**Location:** `journalctl -u godot-spacetime -p warning`
**Filter:**
```bash
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep WARN
```

### Info Logs
**What:** General information, startup messages
**Location:** `journalctl -u godot-spacetime -p info`
**Filter:**
```bash
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep INFO
```

### Debug Logs
**What:** Detailed debugging information
**Location:** `journalctl -u godot-spacetime -p debug`
**Enable:** Set `LOG_LEVEL=DEBUG` in `/opt/spacetime/production/.env`

---

## Component-Specific Logs

### GodotBridge (HTTP API)
**Filter:**
```bash
sudo journalctl -u godot-spacetime | grep "\[GodotBridge\]"
```

**Common Messages:**
- `HTTP server started on port 8080`
- `Request: POST /connect`
- `Response: 200 OK`

### TelemetryServer
**Filter:**
```bash
sudo journalctl -u godot-spacetime | grep "\[TelemetryServer\]"
```

**Common Messages:**
- `WebSocket server started on port 8081`
- `Client connected from 127.0.0.1`
- `Telemetry event: fps`

### ConnectionManager
**Filter:**
```bash
sudo journalctl -u godot-spacetime | grep "\[ConnectionManager\]"
```

**Common Messages:**
- `DAP adapter connected`
- `LSP adapter connected`
- `Connection retry attempt 1/5`

### ResonanceEngine
**Filter:**
```bash
sudo journalctl -u godot-spacetime | grep "\[ResonanceEngine\]"
```

**Common Messages:**
- `Subsystem initialized: TimeManager`
- `All subsystems initialized`
- `Frame rate: 90.0 FPS`

---

## System Logs

### System Log
```bash
/var/log/syslog  # Debian/Ubuntu
/var/log/messages  # RHEL/CentOS
```

**View:**
```bash
tail -f /var/log/syslog | grep spacetime
```

### Authentication Log
```bash
/var/log/auth.log  # Debian/Ubuntu
/var/log/secure  # RHEL/CentOS
```

**View:**
```bash
sudo tail -f /var/log/auth.log
```

### Kernel Log
```bash
# View kernel ring buffer
dmesg | tail -50

# Follow kernel messages
dmesg -w

# Filter for OOM killer
dmesg | grep -i "out of memory\|oom"
```

---

## Access Logs

### Nginx Access Log (if using reverse proxy)
```bash
/var/log/nginx/spacetime-api-access.log
```

**Format:**
```
127.0.0.1 - - [02/Dec/2025:10:15:30 +0000] "GET /status HTTP/1.1" 200 1234
```

**View:**
```bash
tail -f /var/log/nginx/spacetime-api-access.log
```

### Nginx Error Log
```bash
/var/log/nginx/spacetime-api-error.log
```

**View:**
```bash
tail -f /var/log/nginx/spacetime-api-error.log
```

---

## Audit Logs

### Security Audit Log
```bash
/var/log/spacetime/audit.log
```

**Contains:**
- Authentication attempts
- Authorization failures
- Administrative actions
- Configuration changes
- API token usage

**View:**
```bash
tail -f /var/log/spacetime/audit.log
```

### Backup Audit Log
```bash
/var/log/spacetime/backup-audit.log
```

**Contains:**
- Backup creation timestamps
- Backup verification results
- Backup deletion records
- Restoration attempts

---

## Temporary Logs

### Debug Output
```bash
/tmp/spacetime-debug-*.txt
/tmp/godot-*.log
```

**Cleanup:**
```bash
find /tmp -name "spacetime-debug-*" -mtime +1 -delete
find /tmp -name "godot-*" -mtime +1 -delete
```

### Crash Dumps
```bash
/tmp/godot-crash-*.dmp
/var/crash/godot-*.crash
```

**View:**
```bash
ls -lh /var/crash/
```

---

## Log Rotation

### Logrotate Configuration
```bash
/etc/logrotate.d/spacetime
```

**View Configuration:**
```bash
cat /etc/logrotate.d/spacetime
```

**Force Rotation:**
```bash
sudo logrotate -f /etc/logrotate.d/spacetime
```

**Test Configuration:**
```bash
sudo logrotate -d /etc/logrotate.d/spacetime
```

### Rotation Schedule
- **Daily Logs:** Kept for 7 days
- **Weekly Logs:** Kept for 4 weeks
- **Monthly Logs:** Kept for 3 months

---

## Log Analysis

### Common Searches

**Find all errors in last hour:**
```bash
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR > /tmp/errors.txt
```

**Count errors by type:**
```bash
sudo journalctl -u godot-spacetime --since "1 hour ago" | \
  grep ERROR | \
  awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | \
  sort | uniq -c | sort -rn
```

**Find slow requests:**
```bash
sudo journalctl -u godot-spacetime --since "1 hour ago" | \
  grep "response_time" | \
  awk '$NF > 1000 {print}'
```

**Authentication failures:**
```bash
sudo journalctl -u godot-spacetime --since "1 day ago" | \
  grep -i "authentication failed"
```

**Service restarts:**
```bash
sudo journalctl -u godot-spacetime --since "1 week ago" | \
  grep -E "Started|Stopped"
```

---

## Log Formats

### Structured Logging Format
```
[TIMESTAMP] [LEVEL] [COMPONENT] Message
```

**Example:**
```
[2025-12-02 10:15:30.123] [INFO] [GodotBridge] HTTP server started on port 8080
```

### JSON Logging Format
**Export:**
```bash
sudo journalctl -u godot-spacetime -o json --since "1 hour ago" > logs.json
```

**Example:**
```json
{
  "__REALTIME_TIMESTAMP": "1733139330123456",
  "MESSAGE": "HTTP server started on port 8081",
  "_SYSTEMD_UNIT": "godot-spacetime.service",
  "PRIORITY": "6",
  "SYSLOG_IDENTIFIER": "godot"
}
```

---

## Monitoring Logs

### Real-Time Monitoring

**All logs:**
```bash
sudo journalctl -u godot-spacetime -f
```

**Errors only:**
```bash
sudo journalctl -u godot-spacetime -f -p err
```

**Multiple units:**
```bash
sudo journalctl -u godot-spacetime -u nginx -f
```

**Colored output:**
```bash
sudo journalctl -u godot-spacetime -f | ccze -A
```

---

## Log Shipping (if configured)

### Rsyslog Remote
```bash
# Remote syslog server
/var/log/spacetime/*.log → rsyslog → log-server.company.com:514
```

### Logstash/ELK Stack
```bash
# Filebeat configuration
/etc/filebeat/filebeat.yml

# Shipping to ELK
/var/log/spacetime/*.log → Filebeat → Logstash → Elasticsearch → Kibana
```

**View in Kibana:**
```
https://kibana.company.com/app/kibana#/discover?index=spacetime-*
```

### CloudWatch Logs (AWS)
```bash
# CloudWatch agent config
/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Log group
/aws/ec2/spacetime/godot-spacetime
```

**View in CloudWatch:**
```bash
aws logs tail /aws/ec2/spacetime/godot-spacetime --follow
```

---

## Log Backup

### Backup Locations
```bash
# Local backup
/opt/spacetime/backups/logs/

# S3 backup
s3://company-backups/spacetime/logs/

# Long-term archive
s3://company-archive/spacetime/logs/
```

### Backup Scripts
```bash
# Daily log backup
/opt/spacetime/scripts/backup_logs.sh

# Archive old logs
/opt/spacetime/scripts/archive_logs.sh
```

---

## Troubleshooting

### No Logs Appearing
```bash
# Check service is running
systemctl status godot-spacetime

# Check journald is running
systemctl status systemd-journald

# Check log level
grep LOG_LEVEL /opt/spacetime/production/.env
```

### Logs Too Large
```bash
# Check log size
journalctl --disk-usage

# Vacuum old logs
sudo journalctl --vacuum-time=7d

# Vacuum by size
sudo journalctl --vacuum-size=500M
```

### Permission Denied
```bash
# Add user to systemd-journal group
sudo usermod -a -G systemd-journal $USER

# Or use sudo
sudo journalctl -u godot-spacetime
```

---

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║         LOG LOCATIONS - QUICK REFERENCE                   ║
╠═══════════════════════════════════════════════════════════╣
║ Service Logs:                                             ║
║   sudo journalctl -u godot-spacetime -f                   ║
║                                                           ║
║ Error Logs:                                               ║
║   sudo journalctl -u godot-spacetime -p err               ║
║                                                           ║
║ Application Logs:                                         ║
║   /var/log/spacetime/godot.log                            ║
║                                                           ║
║ Nginx Logs:                                               ║
║   /var/log/nginx/spacetime-api-access.log                 ║
║                                                           ║
║ Search Logs:                                              ║
║   sudo journalctl -u godot-spacetime | grep ERROR         ║
║                                                           ║
║ Export Logs:                                              ║
║   sudo journalctl -u godot-spacetime > logs.txt           ║
╚═══════════════════════════════════════════════════════════╝
```
