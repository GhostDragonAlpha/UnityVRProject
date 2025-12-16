# Monitoring Deployment Guide - Planetary Survival VR

This guide provides step-by-step instructions for deploying the production monitoring stack for Planetary Survival VR. The stack includes Prometheus, Grafana, AlertManager, and VictoriaMetrics for comprehensive observability.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Production Deployment](#production-deployment)
4. [Service Discovery Configuration](#service-discovery-configuration)
5. [Alert Configuration](#alert-configuration)
6. [Grafana Setup](#grafana-setup)
7. [Long-Term Storage](#long-term-storage)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **Godot Engine**: 4.5+ with debug connection addon

### System Requirements

**Minimum:**
- CPU: 4 cores
- RAM: 8 GB
- Disk: 100 GB SSD

**Recommended:**
- CPU: 8 cores
- RAM: 16 GB
- Disk: 500 GB SSD (for long-term metrics storage)

### Network Requirements

**Required Ports:**
- 9090: Prometheus
- 3000: Grafana
- 9093: AlertManager
- 8428: VictoriaMetrics
- 9100: Node Exporter
- 8080: Godot HTTP API
- 8081: Godot Telemetry

## Quick Start

### 1. Clone and Prepare

```bash
cd C:/godot/monitoring
```

### 2. Start Monitoring Stack

```bash
# Use production configuration
docker-compose -f docker-compose.production.yml up -d

# Check services are running
docker-compose -f docker-compose.production.yml ps
```

### 3. Verify Deployment

```bash
# Check Prometheus
curl http://localhost:9090/-/healthy

# Check Grafana
curl http://localhost:3000/api/health

# Check AlertManager
curl http://localhost:9093/-/healthy

# Check VictoriaMetrics
curl http://localhost:8428/health
```

### 4. Access Dashboards

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **VictoriaMetrics**: http://localhost:8428

## Production Deployment

### Step 1: Prepare Configuration Files

```bash
# Copy production templates
cp C:/godot/monitoring/prometheus/prometheus_production.yml C:/godot/monitoring/prometheus/prometheus.yml

# Configure service discovery
cp C:/godot/monitoring/prometheus/targets/game_servers.json.example \
   C:/godot/monitoring/prometheus/targets/game_servers.json

# Edit targets file with your game server addresses
vi C:/godot/monitoring/prometheus/targets/game_servers.json
```

### Step 2: Configure AlertManager

Edit `C:/godot/monitoring/alertmanager/alertmanager.yml`:

```yaml
global:
  # SMTP Configuration for email alerts
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@planetarysurvival.com'
  smtp_auth_username: 'alerts@planetarysurvival.com'
  smtp_auth_password: 'YOUR_PASSWORD'
  smtp_require_tls: true

receivers:
  - name: 'critical-alerts'
    # Email notifications
    email_configs:
      - to: 'oncall@planetarysurvival.com'
        subject: '[CRITICAL] {{ .GroupLabels.alertname }}'

    # Slack notifications
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts-critical'
        title: '[CRITICAL] {{ .GroupLabels.alertname }}'
        text: '{{ .CommonAnnotations.description }}'

    # PagerDuty integration
    pagerduty_configs:
      - routing_key: 'YOUR_PAGERDUTY_INTEGRATION_KEY'
        description: '{{ .GroupLabels.alertname }}'
```

### Step 3: Deploy Stack

```bash
# Deploy with production configuration
docker-compose -f docker-compose.production.yml up -d

# View logs
docker-compose -f docker-compose.production.yml logs -f

# Wait for services to be healthy
watch docker-compose -f docker-compose.production.yml ps
```

### Step 4: Configure Firewall

```bash
# Allow Prometheus
sudo firewall-cmd --permanent --add-port=9090/tcp

# Allow Grafana
sudo firewall-cmd --permanent --add-port=3000/tcp

# Allow AlertManager
sudo firewall-cmd --permanent --add-port=9093/tcp

# Reload firewall
sudo firewall-cmd --reload
```

### Step 5: Set Up SSL/TLS (Recommended)

```bash
# Install Nginx reverse proxy
sudo apt-get install nginx certbot python3-certbot-nginx

# Configure SSL certificates
sudo certbot --nginx -d grafana.planetarysurvival.com
sudo certbot --nginx -d prometheus.planetarysurvival.com
sudo certbot --nginx -d alertmanager.planetarysurvival.com
```

Example Nginx configuration for Grafana:

```nginx
server {
    listen 443 ssl http2;
    server_name grafana.planetarysurvival.com;

    ssl_certificate /etc/letsencrypt/live/grafana.planetarysurvival.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/grafana.planetarysurvival.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Service Discovery Configuration

### File-Based Service Discovery

The monitoring stack uses file-based service discovery for dynamic game server registration.

**Target File Format** (`C:/godot/monitoring/prometheus/targets/game_servers.json`):

```json
[
  {
    "targets": ["game-server-1:8080", "10.0.1.10:8080"],
    "labels": {
      "server_id": "server-1",
      "region_id": "region-north-1",
      "planet": "earth",
      "environment": "production",
      "datacenter": "us-east-1"
    }
  },
  {
    "targets": ["game-server-2:8080", "10.0.1.11:8080"],
    "labels": {
      "server_id": "server-2",
      "region_id": "region-north-2",
      "planet": "earth",
      "environment": "production",
      "datacenter": "us-east-1"
    }
  }
]
```

### Dynamic Registration Script

Create a script to automatically update service discovery:

```python
#!/usr/bin/env python3
# update_targets.py - Update Prometheus service discovery targets

import json
import os
import requests
from typing import List, Dict

TARGETS_FILE = '/etc/prometheus/targets/game_servers.json'
ORCHESTRATOR_API = 'http://orchestrator:8080/api/v1/servers'

def fetch_game_servers() -> List[Dict]:
    """Fetch active game servers from orchestrator"""
    response = requests.get(ORCHESTRATOR_API)
    response.raise_for_status()
    return response.json()['servers']

def generate_targets(servers: List[Dict]) -> List[Dict]:
    """Generate Prometheus targets from server list"""
    targets = []

    for server in servers:
        target = {
            "targets": [f"{server['hostname']}:{server['metrics_port']}"],
            "labels": {
                "server_id": server['id'],
                "region_id": server['region_id'],
                "planet": server['planet'],
                "environment": server['environment'],
                "datacenter": server['datacenter']
            }
        }
        targets.append(target)

    return targets

def write_targets(targets: List[Dict]):
    """Write targets to file atomically"""
    temp_file = TARGETS_FILE + '.tmp'

    with open(temp_file, 'w') as f:
        json.dump(targets, f, indent=2)

    os.replace(temp_file, TARGETS_FILE)
    print(f"Updated {len(targets)} targets")

if __name__ == '__main__':
    servers = fetch_game_servers()
    targets = generate_targets(servers)
    write_targets(targets)
```

Run this script periodically (every 30 seconds) using cron or systemd timer.

## Alert Configuration

### Alert Thresholds

Alerts are configured with two severity levels:

**WARNING Alerts:**
- CPU usage > 80% for 5 minutes
- Memory usage > 80% for 5 minutes
- Authority transfer latency > 100ms (p95) for 5 minutes
- Region player count > 80 for 3 minutes
- FPS < 85 for 2 minutes

**CRITICAL Alerts:**
- CPU usage > 95% for 2 minutes
- Memory usage > 95% for 2 minutes
- Authority transfer latency > 250ms (p95) for 3 minutes
- Region player count > 100 for 1 minute
- Server node down for 1 minute
- High authority transfer failure rate > 0.1/sec for 2 minutes

### Alert Detection Time

The monitoring stack is optimized for <1 minute alert detection:

1. **Scrape Interval**: 15 seconds
2. **Evaluation Interval**: 15 seconds
3. **Alert Fire Time**: Typically 15-45 seconds depending on threshold duration

**Example Timeline:**
```
T+0s:  Metric value exceeds threshold
T+15s: Prometheus scrapes metric, evaluates rules
T+30s: Alert enters PENDING state (if "for" clause is met)
T+45s: Alert FIRES, sent to AlertManager
T+50s: AlertManager routes to notification channels
T+55s: Team receives notification
```

## Grafana Setup

### Initial Configuration

1. **Login**: http://localhost:3000 (admin/admin)
2. **Change Password**: Required on first login
3. **Verify Data Sources**: Configuration > Data Sources
   - Prometheus should be pre-configured
   - Test connection: Click "Test" button

### Dashboard Import

Dashboards are automatically provisioned from:
```
C:/godot/monitoring/grafana/dashboards/
```

**Available Dashboards:**
1. **Server Mesh Overview** - Server health, authority transfers, topology
2. **VR Performance** - FPS, frame time, input latency, VR metrics
3. **Database Performance** - Query rates, latency, connection pools
4. **Player Distribution** - Player counts, heatmaps, region load
5. **HTTP API Overview** - Request rates, errors, latency

### Custom Dashboard Creation

1. Navigate to **Dashboards** > **New Dashboard**
2. Add panels using PromQL queries
3. Save to folder: **Planetary Survival**
4. Export JSON to `C:/godot/monitoring/grafana/dashboards/` for persistence

### User Management

```bash
# Create read-only user for team
curl -X POST -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{"name":"viewer","login":"viewer","password":"viewerpass","role":"Viewer"}' \
  http://localhost:3000/api/admin/users

# Create editor user for ops team
curl -X POST -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{"name":"operator","login":"operator","password":"operatorpass","role":"Editor"}' \
  http://localhost:3000/api/admin/users
```

## Long-Term Storage

### VictoriaMetrics Configuration

VictoriaMetrics provides long-term storage with 12-month retention.

**Features:**
- Automatic downsampling for old data
- Efficient compression (10x better than Prometheus)
- Compatible with Prometheus query API
- Fast querying across long time ranges

**Retention Policy:**
- **Prometheus**: 15 days (high-resolution)
- **VictoriaMetrics**: 12 months (downsampled)

### Querying Historical Data

Grafana automatically queries VictoriaMetrics for data older than 15 days via the `remote_read` configuration.

**Manual Query:**
```bash
# Query VictoriaMetrics directly
curl -G http://localhost:8428/api/v1/query \
  --data-urlencode 'query=fps{server_id="server-1"}' \
  --data-urlencode 'time=2024-01-01T00:00:00Z'
```

### Backup and Restore

**Backup VictoriaMetrics:**
```bash
# Create snapshot
curl http://localhost:8428/snapshot/create

# Snapshot location
docker exec spacetime_victoriametrics ls -la /victoria-metrics-data/snapshots/

# Copy snapshot
docker cp spacetime_victoriametrics:/victoria-metrics-data/snapshots/SNAPSHOT_NAME ./backups/
```

**Restore from backup:**
```bash
# Stop VictoriaMetrics
docker-compose -f docker-compose.production.yml stop victoriametrics

# Restore snapshot
docker cp ./backups/SNAPSHOT_NAME spacetime_victoriametrics:/victoria-metrics-data/

# Start VictoriaMetrics
docker-compose -f docker-compose.production.yml start victoriametrics
```

## Verification

### Health Checks

```bash
# Run comprehensive health check
./monitoring/test_monitoring.sh

# Check individual components
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health # Grafana
curl http://localhost:9093/-/healthy  # AlertManager
curl http://localhost:8428/health     # VictoriaMetrics
```

### Metrics Verification

```bash
# Check if Prometheus is scraping targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, state: .health}'

# Verify metrics are being collected
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq '.data.result'

# Check alert rules are loaded
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].name'
```

### Alert Testing

```bash
# Trigger test alert by simulating high CPU
curl -X POST http://localhost:8080/debug/simulate_high_cpu

# Check if alert fired
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing")'

# Verify AlertManager received it
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | {labels: .labels, state: .status.state}'
```

### Dashboard Verification

1. Open Grafana: http://localhost:3000
2. Navigate to **Dashboards** > **Planetary Survival**
3. Verify all dashboards show data
4. Check time ranges are working (Last 5m, Last 1h, Last 24h)

## Troubleshooting

### Prometheus Not Scraping Targets

**Symptoms:**
- Targets show as "DOWN" in Prometheus UI
- No metrics appearing in Grafana

**Solutions:**

1. **Check network connectivity:**
   ```bash
   # From Prometheus container
   docker exec spacetime_prometheus wget -O- http://host.docker.internal:8080/metrics
   ```

2. **Verify Godot is exposing metrics:**
   ```bash
   curl http://localhost:8080/metrics
   ```

3. **Check Prometheus logs:**
   ```bash
   docker logs spacetime_prometheus | grep ERROR
   ```

4. **Verify firewall rules:**
   ```bash
   sudo iptables -L -n | grep 8080
   ```

### AlertManager Not Sending Notifications

**Symptoms:**
- Alerts fire in Prometheus but no notifications received

**Solutions:**

1. **Check AlertManager configuration:**
   ```bash
   docker exec spacetime_alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
   ```

2. **Verify alert routing:**
   ```bash
   curl -s http://localhost:9093/api/v2/alerts | jq
   ```

3. **Test SMTP configuration:**
   ```bash
   docker exec spacetime_alertmanager sh -c 'echo "test" | mail -s "Test Alert" oncall@planetarysurvival.com'
   ```

4. **Check AlertManager logs:**
   ```bash
   docker logs spacetime_alertmanager | grep ERROR
   ```

### Grafana Dashboards Not Loading

**Symptoms:**
- Dashboards show "No data" or errors

**Solutions:**

1. **Verify Prometheus data source:**
   - Grafana > Configuration > Data Sources > Prometheus
   - Click "Test" - should show "Data source is working"

2. **Check Prometheus is returning data:**
   ```bash
   curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=up'
   ```

3. **Verify time range:**
   - Check dashboard time picker (top right)
   - Try "Last 5 minutes" to see most recent data

4. **Check browser console:**
   - Open browser DevTools (F12)
   - Look for JavaScript errors

### High Memory Usage

**Symptoms:**
- Prometheus container consuming excessive memory
- OOM kills

**Solutions:**

1. **Reduce retention period:**
   ```yaml
   # In docker-compose.production.yml
   command:
     - '--storage.tsdb.retention.time=7d'  # Reduce from 15d
     - '--storage.tsdb.retention.size=25GB'  # Reduce from 50GB
   ```

2. **Check series cardinality:**
   ```promql
   # Count total time series
   count({__name__=~".+"})

   # Top metrics by cardinality
   topk(10, count by (__name__)({__name__=~".+"}))
   ```

3. **Increase scrape interval:**
   ```yaml
   # In prometheus.yml
   global:
     scrape_interval: 30s  # Increase from 15s
   ```

4. **Add memory limits:**
   ```yaml
   # In docker-compose.production.yml
   prometheus:
     deploy:
       resources:
         limits:
           memory: 4G
   ```

### VictoriaMetrics Disk Space

**Symptoms:**
- VictoriaMetrics container low on disk space

**Solutions:**

1. **Check current disk usage:**
   ```bash
   docker exec spacetime_victoriametrics du -sh /victoria-metrics-data
   ```

2. **Reduce retention:**
   ```yaml
   # In docker-compose.production.yml
   command:
     - '--retentionPeriod=6M'  # Reduce from 12M
   ```

3. **Compact old data:**
   ```bash
   curl -X POST http://localhost:8428/internal/force/merge
   ```

4. **Expand volume:**
   ```bash
   # Add more disk space to the host
   # Then resize Docker volume
   docker volume inspect spacetime_victoriametrics_data
   ```

## Maintenance

### Regular Maintenance Tasks

**Daily:**
- Monitor dashboard for anomalies
- Review active alerts

**Weekly:**
- Review alert history and adjust thresholds
- Check disk space usage
- Update service discovery targets

**Monthly:**
- Review and optimize slow queries
- Update Docker images
- Backup VictoriaMetrics snapshots
- Review and archive old dashboards

### Updating the Stack

```bash
# Pull latest images
docker-compose -f docker-compose.production.yml pull

# Restart with new images (zero-downtime)
docker-compose -f docker-compose.production.yml up -d

# Verify all services are healthy
docker-compose -f docker-compose.production.yml ps
```

### Backup Strategy

**What to backup:**
1. Prometheus configuration files
2. Grafana dashboards (auto-backed up to git)
3. AlertManager configuration
4. VictoriaMetrics snapshots (monthly)
5. Service discovery targets

**Backup script:**
```bash
#!/bin/bash
# backup_monitoring.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups/monitoring/$DATE"

mkdir -p "$BACKUP_DIR"

# Backup configurations
cp -r C:/godot/monitoring/prometheus "$BACKUP_DIR/"
cp -r C:/godot/monitoring/grafana "$BACKUP_DIR/"
cp -r C:/godot/monitoring/alertmanager "$BACKUP_DIR/"

# Create VictoriaMetrics snapshot
curl -X POST http://localhost:8428/snapshot/create
# Copy snapshot (manual step)

# Compress backup
tar czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"

echo "Backup completed: $BACKUP_DIR.tar.gz"
```

## Support

For issues or questions:

1. Check logs: `docker-compose -f docker-compose.production.yml logs`
2. Review [Alert Runbook](ALERT_RUNBOOK.md) for specific alert guidance
3. Review [Dashboard Guide](DASHBOARD_GUIDE.md) for dashboard usage
4. Consult Prometheus documentation: https://prometheus.io/docs/
5. Consult Grafana documentation: https://grafana.com/docs/

## References

- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [AlertManager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [VictoriaMetrics Documentation](https://docs.victoriametrics.com/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
