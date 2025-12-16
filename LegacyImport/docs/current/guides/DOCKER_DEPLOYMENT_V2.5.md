# Docker Deployment Guide - SpaceTime v2.5

Complete production-ready Docker deployment guide for SpaceTime v2.5 with comprehensive security features, monitoring, and high availability.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Production Deployment](#production-deployment)
- [Security Features](#security-features)
- [Monitoring and Observability](#monitoring-and-observability)
- [Troubleshooting](#troubleshooting)
- [Performance Optimization](#performance-optimization)
- [Backup and Recovery](#backup-and-recovery)

## Overview

SpaceTime v2.5 Docker deployment provides:

- **Containerized Godot 4.5+** with Xvfb for GUI mode
- **Full AI Debug Stack** (DAP, LSP, HTTP API, Telemetry)
- **NGINX Reverse Proxy** with SSL/TLS termination
- **Prometheus + Grafana** for monitoring
- **Redis** for caching and session management
- **Automated backups** and health checks
- **Production-grade security** with minimal attack surface

### Architecture

```
Internet → NGINX (SSL/TLS) → Godot Container (Xvfb) → VR Engine
                            ↓
                        Telemetry → Prometheus → Grafana
                            ↓
                          Redis
```

## Prerequisites

### System Requirements

**Minimum:**
- CPU: 4 cores
- RAM: 8GB
- Disk: 50GB
- OS: Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+)

**Recommended:**
- CPU: 8+ cores
- RAM: 16GB+
- Disk: 100GB+ SSD
- OS: Ubuntu 22.04 LTS

### Software Requirements

```bash
# Docker Engine 20.10+
docker --version

# Docker Compose 2.0+
docker compose version

# OpenSSL (for SSL certificates)
openssl version
```

### Install Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Verify installation
docker run hello-world
```

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/spacetime-vr.git
cd spacetime-vr
```

### 2. Generate SSL Certificates

```bash
# Create SSL directory
mkdir -p ssl

# Generate self-signed certificate (development)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# For production, use Let's Encrypt:
# certbot certonly --standalone -d yourdomain.com
# cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
# cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem
```

### 3. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Generate secure API token
openssl rand -base64 32

# Edit .env file
nano .env
```

**Required settings:**

```env
API_TOKEN=your_generated_token_here
GRAFANA_ADMIN_PASSWORD=your_secure_grafana_password
DOMAIN=yourdomain.com  # or localhost for testing
```

### 4. Create Required Directories

```bash
# Create directories for production volumes
sudo mkdir -p /var/lib/spacetime/{logs,data,prometheus,grafana,redis}
sudo mkdir -p /var/log/spacetime/nginx
sudo mkdir -p /var/backups/spacetime

# Set permissions
sudo chown -R $USER:$USER /var/lib/spacetime
sudo chown -R $USER:$USER /var/log/spacetime
sudo chown -R $USER:$USER /var/backups/spacetime
```

### 5. Start Services (Development)

```bash
# Build and start all services
docker compose -f docker-compose.v2.5.yml up -d

# View logs
docker compose -f docker-compose.v2.5.yml logs -f

# Check status
docker compose -f docker-compose.v2.5.yml ps
```

### 6. Verify Deployment

```bash
# Check health
curl -k https://localhost/health

# Test API (replace TOKEN with your API_TOKEN)
curl -k -H "Authorization: Bearer TOKEN" https://localhost/api/status

# Check services
docker compose -f docker-compose.v2.5.yml ps
```

Expected output:
```
NAME                    STATUS              PORTS
spacetime-godot         running (healthy)
spacetime-nginx         running (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
spacetime-prometheus    running (healthy)
spacetime-grafana       running (healthy)
```

## Configuration

### Environment Variables

Complete reference of environment variables in `.env`:

```env
# API Authentication
API_TOKEN=your_secure_token_here

# Godot Configuration
GODOT_VERSION=4.5
GODOT_LOG_LEVEL=info

# Security Settings
MAX_REQUEST_SIZE=1048576
SCENE_WHITELIST=res://vr_main.tscn,res://node_3d.tscn

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure_password

# Domain
DOMAIN=localhost

# Redis
REDIS_PASSWORD=secure_redis_password

# Backup
BACKUP_RETENTION_DAYS=30
```

### Prometheus Configuration

Create `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'spacetime'
    static_configs:
      - targets: ['godot:8080']
    metrics_path: '/metrics'
    bearer_token: 'your_api_token_here'

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
```

### Grafana Datasources

Create `grafana/datasources/prometheus.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

### Grafana Dashboards

Create `grafana/dashboards/spacetime.json` with monitoring panels for:
- FPS and performance metrics
- API request rates
- Memory and CPU usage
- WebSocket connections
- VR session statistics

## Production Deployment

### 1. Production Environment File

Create `.env.production`:

```env
# Production settings
API_TOKEN=super_secure_production_token
GODOT_LOG_LEVEL=warn
ENABLE_DEBUG_MODE=false

# Domain and SSL
DOMAIN=spacetime.example.com

# Passwords
GRAFANA_ADMIN_PASSWORD=complex_grafana_password
REDIS_PASSWORD=complex_redis_password

# Resource limits
CPU_LIMIT=8
MEMORY_LIMIT=16G
CPU_RESERVATION=4
MEMORY_RESERVATION=8G
```

### 2. Get Production SSL Certificates

```bash
# Install Certbot
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d spacetime.example.com

# Copy to SSL directory
sudo cp /etc/letsencrypt/live/spacetime.example.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/spacetime.example.com/privkey.pem ssl/key.pem

# Set up auto-renewal
sudo crontab -e
# Add: 0 0 1 * * certbot renew --quiet && systemctl restart docker-compose@spacetime
```

### 3. Deploy Production Stack

```bash
# Build production image
docker compose -f docker-compose.production.yml build

# Start services
docker compose -f docker-compose.production.yml up -d

# Verify health
docker compose -f docker-compose.production.yml ps

# Monitor logs
docker compose -f docker-compose.production.yml logs -f godot
```

### 4. Systemd Service (Auto-start on Boot)

Create `/etc/systemd/system/spacetime.service`:

```ini
[Unit]
Description=SpaceTime VR v2.5 Docker Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/spacetime
ExecStart=/usr/bin/docker compose -f docker-compose.production.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

Enable service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable spacetime.service
sudo systemctl start spacetime.service
sudo systemctl status spacetime.service
```

## Security Features

### Container Security

1. **Non-root User**: All containers run as non-root users
2. **Read-only Filesystem**: Where possible, filesystems are read-only
3. **Dropped Capabilities**: ALL capabilities dropped, only necessary ones added
4. **No New Privileges**: `no-new-privileges` security option enabled
5. **Network Isolation**: Internal networks isolated from external

### NGINX Security Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'; ...
```

### Rate Limiting

- **API endpoints**: 10 requests/second, burst 20
- **Auth endpoints**: 5 requests/minute, burst 5
- **Connection limit**: 10 concurrent connections per IP

### SSL/TLS Configuration

- **Protocols**: TLSv1.2, TLSv1.3 only
- **Ciphers**: Modern, secure cipher suites
- **OCSP Stapling**: Enabled
- **Session Cache**: 10 minutes

### Firewall Configuration

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Restrict SSH to specific IPs
sudo ufw allow from YOUR_IP to any port 22
```

## Monitoring and Observability

### Access Monitoring Tools

- **Grafana**: https://yourdomain.com/grafana
- **Prometheus**: http://localhost:9090 (internal only)

### Default Credentials

- **Grafana**: admin / (password from .env)

### Key Metrics

Monitor these metrics in Grafana:

1. **Performance**:
   - FPS (target: 90)
   - Frame time
   - Physics tick rate

2. **API Health**:
   - Request rate
   - Response time
   - Error rate

3. **Resources**:
   - CPU usage
   - Memory usage
   - Disk I/O

4. **Network**:
   - WebSocket connections
   - Bandwidth usage

### Log Aggregation

```bash
# View all logs
docker compose -f docker-compose.production.yml logs -f

# View specific service
docker compose -f docker-compose.production.yml logs -f godot

# Export logs
docker compose -f docker-compose.production.yml logs --no-color > spacetime.log
```

### Health Checks

All services have automated health checks:

```bash
# Check health status
docker ps --filter "name=spacetime" --format "table {{.Names}}\t{{.Status}}"

# Manual health check
curl -k -H "Authorization: Bearer TOKEN" https://localhost/api/status
```

## Troubleshooting

### Common Issues

#### 1. Godot Process Fails to Start

**Symptoms**: Container exits immediately, logs show Xvfb errors

**Solution**:
```bash
# Check Xvfb logs
docker compose -f docker-compose.v2.5.yml logs godot

# Verify display is available
docker exec spacetime-godot-prod xdpyinfo -display :99

# Restart with fresh X server
docker compose -f docker-compose.v2.5.yml restart godot
```

#### 2. API Returns 401 Unauthorized

**Symptoms**: All API requests return 401

**Solution**:
```bash
# Verify token in .env
grep API_TOKEN .env

# Check token in logs
docker compose -f docker-compose.v2.5.yml logs godot | grep "API TOKEN"

# Test with correct token
curl -k -H "Authorization: Bearer YOUR_TOKEN" https://localhost/api/status
```

#### 3. NGINX 502 Bad Gateway

**Symptoms**: NGINX returns 502 errors

**Solution**:
```bash
# Check if Godot is healthy
docker ps --filter "name=godot"

# Check NGINX logs
docker compose -f docker-compose.v2.5.yml logs nginx

# Verify upstream connection
docker exec spacetime-nginx-prod wget -O- http://godot:8080/status
```

#### 4. High Memory Usage

**Symptoms**: Container OOM killed

**Solution**:
```bash
# Check memory stats
docker stats spacetime-godot-prod

# Adjust limits in docker-compose.production.yml
# Increase memory limit or reduce scene complexity
```

#### 5. WebSocket Connection Fails

**Symptoms**: Telemetry client can't connect

**Solution**:
```bash
# Check telemetry port
netstat -an | grep 8081

# Test WebSocket directly
wscat -c ws://localhost:8081

# Check NGINX WebSocket proxy
docker compose -f docker-compose.v2.5.yml logs nginx | grep ws
```

### Debug Mode

Enable debug mode temporarily:

```bash
# Set debug environment
export GODOT_LOG_LEVEL=debug
export ENABLE_DEBUG_MODE=true

# Restart with debug
docker compose -f docker-compose.v2.5.yml up -d godot

# View verbose logs
docker compose -f docker-compose.v2.5.yml logs -f godot
```

### Performance Profiling

```bash
# Get container stats
docker stats spacetime-godot-prod

# Get detailed metrics
docker exec spacetime-godot-prod ps aux

# Check disk usage
docker system df
docker system df -v
```

## Performance Optimization

### Resource Tuning

#### CPU Optimization

```yaml
# In docker-compose.production.yml
deploy:
  resources:
    limits:
      cpus: '8'  # Increase for more headroom
    reservations:
      cpus: '4'  # Guaranteed CPUs
```

#### Memory Optimization

```yaml
deploy:
  resources:
    limits:
      memory: 16G  # Increase if needed
    reservations:
      memory: 8G
```

### Network Performance

```bash
# Enable TCP BBR congestion control (Linux 4.9+)
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Increase network buffers
echo "net.core.rmem_max=16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max=16777216" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Disk I/O

```bash
# Use SSD for Docker volumes
# Mount volumes on dedicated SSD partition

# Enable writeback caching
sudo blockdev --setra 8192 /dev/sdX
```

### NGINX Tuning

```nginx
# Add to nginx.conf
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
```

## Backup and Recovery

### Automated Backups

```bash
# Manual backup
docker compose -f docker-compose.production.yml run --rm backup

# Scheduled backup (cron)
# Add to crontab:
0 2 * * * cd /opt/spacetime && docker compose -f docker-compose.production.yml run --rm backup
```

### Manual Backup

```bash
# Backup all data
docker run --rm \
  -v spacetime_godot-data:/data \
  -v /var/backups/spacetime:/backup \
  alpine tar -czf /backup/godot-data-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .

# Backup Prometheus data
docker run --rm \
  -v spacetime_prometheus-data:/data \
  -v /var/backups/spacetime:/backup \
  alpine tar -czf /backup/prometheus-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

### Restore from Backup

```bash
# Stop services
docker compose -f docker-compose.production.yml down

# Restore data
docker run --rm \
  -v spacetime_godot-data:/data \
  -v /var/backups/spacetime:/backup \
  alpine sh -c "rm -rf /data/* && tar -xzf /backup/godot-data-YYYYMMDD-HHMMSS.tar.gz -C /data"

# Start services
docker compose -f docker-compose.production.yml up -d
```

### Disaster Recovery Plan

1. **Daily backups** to local storage
2. **Weekly backups** to offsite storage (S3, etc.)
3. **Monthly full system snapshots**
4. **Quarterly DR drills**

## Kubernetes Deployment

For Kubernetes deployment, see the `kubernetes/` directory with manifests for:
- Deployment and StatefulSet
- Services and Ingress
- ConfigMaps and Secrets
- PersistentVolumeClaims
- HorizontalPodAutoscaler

## Additional Resources

- [HTTP API Documentation](addons/godot_debug_connection/HTTP_API.md)
- [DAP Commands Reference](addons/godot_debug_connection/DAP_COMMANDS.md)
- [LSP Methods Reference](addons/godot_debug_connection/LSP_METHODS.md)
- [Development Workflow](DEVELOPMENT_WORKFLOW.md)

## Support

For issues and questions:
- GitHub Issues: https://github.com/yourusername/spacetime-vr/issues
- Documentation: https://spacetime-vr.readthedocs.io

## License

See LICENSE file for details.
