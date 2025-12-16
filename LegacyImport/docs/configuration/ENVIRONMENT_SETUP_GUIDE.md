# Environment Setup Guide

Quick start guide for setting up SpaceTime VR in different environments.

## Table of Contents

- [Quick Start](#quick-start)
- [Development Environment](#development-environment)
- [Staging Environment](#staging-environment)
- [Production Environment](#production-environment)
- [Configuration Profiles](#configuration-profiles)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### 1. Choose Your Environment

```bash
# Set environment variable
export ENVIRONMENT=development  # or staging, production
```

### 2. Copy Environment Template

```bash
# Copy template to .env
cp .env.template .env

# Edit with your values
nano .env
```

### 3. Validate Configuration

```bash
# Validate configuration file
python scripts/validate_config.py $ENVIRONMENT
```

### 4. Start SpaceTime

```bash
# Development (with debug services)
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Production (headless)
godot --headless --path "C:/godot"
```

---

## Development Environment

### Features

- Debug services enabled (DAP, LSP, Discovery)
- Relaxed security constraints
- Verbose logging
- Hot-reload enabled
- Test scenes allowed
- Local binding (127.0.0.1)

### Setup

**1. Configuration:**

Use `config/development.json` as-is or customize:

```json
{
  "environment": "development",
  "security": {
    "authentication": {
      "enabled": true
    },
    "rate_limiting": {
      "enabled": false
    }
  },
  "networking": {
    "http_api": {
      "bind_address": "127.0.0.1",
      "port": 8080
    }
  },
  "logging": {
    "level": "debug"
  },
  "feature_flags": {
    "debug_mode_enabled": true,
    "hot_reload_enabled": true
  }
}
```

**2. Environment Variables:**

```bash
export ENVIRONMENT=development
export GODOT_LOG_LEVEL=debug
export ENABLE_DEBUG_MODE=true
export ENABLE_HOT_RELOAD=true
export HTTP_API_BIND_ADDRESS=127.0.0.1
export RATE_LIMITING_ENABLED=false
```

**3. Start Services:**

```bash
# Start Godot with debug services
./restart_godot_with_debug.bat

# Or manually
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Verify connection
curl http://127.0.0.1:8080/status
```

**4. Monitor Telemetry:**

```bash
# Start telemetry client
python telemetry_client.py
```

### Development Workflow

1. **Edit Code** - Use hot-reload for instant updates
2. **Test Changes** - Use HTTP API to test endpoints
3. **Monitor Telemetry** - Watch real-time metrics
4. **Debug Issues** - Use DAP for breakpoints

---

## Staging Environment

### Features

- Production-like configuration
- Security enabled (with test tokens)
- Moderate rate limits
- Test data allowed
- Full monitoring enabled
- External binding (0.0.0.0)

### Setup

**1. Configuration:**

Use `config/staging.json`:

```json
{
  "environment": "staging",
  "security": {
    "authentication": {
      "enabled": true,
      "token_rotation_enabled": true,
      "token_rotation_interval_hours": 168
    },
    "rate_limiting": {
      "enabled": true,
      "global_requests_per_minute": 500
    },
    "intrusion_detection": {
      "enabled": true
    },
    "encryption": {
      "tls_enabled": true
    }
  },
  "networking": {
    "http_api": {
      "bind_address": "0.0.0.0",
      "port": 8080
    }
  }
}
```

**2. Prerequisites:**

```bash
# Install TLS certificates
sudo certbot certonly --standalone -d staging.spacetime.example.com

# Setup PostgreSQL
sudo apt install postgresql-14
sudo -u postgres createdb spacetime_staging

# Setup Redis
sudo apt install redis-server
sudo systemctl start redis-server
```

**3. Environment Variables:**

```bash
export ENVIRONMENT=staging
export DOMAIN=staging.spacetime.example.com

# Database (use real values)
export DB_HOST=staging-db.example.com
export DB_USER=spacetime
export DB_PASSWORD=$(vault kv get -field=password secret/spacetime/staging/database)

# Redis
export REDIS_HOST=staging-redis.example.com
export REDIS_PASSWORD=$(vault kv get -field=password secret/spacetime/staging/redis)

# API Token
export API_TOKEN=$(vault kv get -field=token secret/spacetime/staging/api)
```

**4. Start Services:**

```bash
# Start with systemd
sudo systemctl start spacetime-staging

# Or manually
godot --headless --path /opt/spacetime --config staging

# Verify
curl https://staging.spacetime.example.com/health
```

### Testing in Staging

1. **Load Testing** - Run performance tests
2. **Security Testing** - Test rate limits, auth
3. **Integration Testing** - Test with real services
4. **Monitoring Validation** - Verify alerts work

---

## Production Environment

### Features

- Maximum security hardening
- Strict rate limits
- Minimal scene whitelist
- Production monitoring
- High availability
- Automated backups

### Setup

**1. Pre-Deployment Checklist:**

- [ ] SSL/TLS certificates installed
- [ ] Secrets stored in Vault
- [ ] Database configured and backed up
- [ ] Redis configured and secured
- [ ] Firewall rules configured
- [ ] Monitoring configured
- [ ] Alerting tested
- [ ] Backups tested
- [ ] Disaster recovery plan documented

**2. Configuration:**

Use `config/production.json`:

```json
{
  "environment": "production",
  "security": {
    "authentication": {
      "enabled": true,
      "token_rotation_enabled": true,
      "token_rotation_interval_hours": 72
    },
    "rate_limiting": {
      "enabled": true,
      "global_requests_per_minute": 300
    },
    "intrusion_detection": {
      "enabled": true,
      "threat_score_threshold": 100,
      "auto_ban_enabled": true
    },
    "encryption": {
      "tls_enabled": true,
      "tls_version_min": "1.3"
    }
  },
  "networking": {
    "dap": {
      "enabled": false
    },
    "lsp": {
      "enabled": false
    }
  },
  "feature_flags": {
    "debug_mode_enabled": false,
    "profiling_enabled": false,
    "hot_reload_enabled": false
  }
}
```

**3. Optional: Use Hardened Profiles:**

For maximum security:

```bash
# Load security-hardened profile
ln -s config/security_production.json config/active_profile.json
```

For maximum performance:

```bash
# Load performance-optimized profile
ln -s config/performance_production.json config/active_profile.json
```

**4. Environment Variables:**

```bash
export ENVIRONMENT=production
export DOMAIN=spacetime.example.com

# Fetch secrets from Vault
export DB_HOST=$(vault kv get -field=host secret/spacetime/production/database)
export DB_USER=$(vault kv get -field=username secret/spacetime/production/database)
export DB_PASSWORD=$(vault kv get -field=password secret/spacetime/production/database)
export REDIS_HOST=$(vault kv get -field=host secret/spacetime/production/redis)
export REDIS_PASSWORD=$(vault kv get -field=password secret/spacetime/production/redis)
export API_TOKEN=$(vault kv get -field=token secret/spacetime/production/api)

# Alert channels
export ALERT_SLACK_WEBHOOK=$(vault kv get -field=webhook secret/spacetime/production/slack)
export ALERT_PAGERDUTY_KEY=$(vault kv get -field=key secret/spacetime/production/pagerduty)
```

**5. Deploy:**

```bash
# Validate configuration
python scripts/validate_config.py production --strict

# Deploy via Docker Compose
docker-compose -f docker-compose.production.yml up -d

# Or via Kubernetes
kubectl apply -f kubernetes/production/

# Verify deployment
curl https://spacetime.example.com/health
curl https://spacetime.example.com/status
```

**6. Post-Deployment Verification:**

```bash
# Run post-deployment checks
./scripts/post_deployment_checks.sh

# Monitor for 24 hours
watch -n 60 'curl -s https://spacetime.example.com/health | jq .'
```

---

## Configuration Profiles

### Using Multiple Profiles

Combine configurations for specific needs:

**Example: Production with Security Hardening**

```json
{
  "$schema": "./config_schema.json",
  "extends": [
    "production.json",
    "security_production.json"
  ]
}
```

**Example: Production with Performance Optimization**

```json
{
  "$schema": "./config_schema.json",
  "extends": [
    "production.json",
    "performance_production.json"
  ]
}
```

### Profile Selection at Runtime

```bash
# Set via environment variable
export CONFIG_PROFILE=security_production

# Or via command line
godot --path /opt/spacetime --config-profile security_production
```

### Custom Profiles

Create custom profiles for specific scenarios:

**config/custom_high_traffic.json:**

```json
{
  "version": "1.0.0",
  "profile": "high_traffic",
  "description": "Optimized for high traffic events",
  "extends": ["production.json"],
  "performance": {
    "worker_threads": {
      "http_workers": 32,
      "background_tasks": 16
    },
    "memory": {
      "max_heap_size_mb": 16384
    }
  },
  "cache": {
    "ttl_seconds": 7200,
    "max_size_mb": 4096
  },
  "security": {
    "rate_limiting": {
      "global_requests_per_minute": 1000
    }
  }
}
```

---

## Troubleshooting

### Configuration Not Loading

**Symptom:** SpaceTime starts with defaults, ignoring configuration.

**Solution:**

```bash
# Check environment variable
echo $ENVIRONMENT

# Verify file exists
ls -la config/$ENVIRONMENT.json

# Check JSON syntax
python -m json.tool config/$ENVIRONMENT.json

# Check logs
tail -f logs/spacetime_$ENVIRONMENT.log | grep -i config
```

### Environment Variables Not Interpolated

**Symptom:** Configuration contains `${VAR_NAME}` instead of value.

**Solution:**

```bash
# Verify variable is set
echo $VAR_NAME

# Check .env file loaded
cat .env | grep VAR_NAME

# Test interpolation manually
export VAR_NAME=test_value
python -c "import os; print(os.environ.get('VAR_NAME'))"
```

### Validation Errors

**Symptom:** Configuration validation fails.

**Solution:**

```bash
# Run validator with verbose output
python scripts/validate_config.py $ENVIRONMENT --strict

# Fix reported issues
nano config/$ENVIRONMENT.json

# Re-validate
python scripts/validate_config.py $ENVIRONMENT
```

### Port Already in Use

**Symptom:** Cannot bind to port (address already in use).

**Solution:**

```bash
# Find process using port
lsof -i :8080
# or
netstat -tulpn | grep 8080

# Kill process
kill -9 <PID>

# Or use fallback ports
export HTTP_API_FALLBACK_PORTS=8083,8084,8085
```

### TLS Certificate Errors

**Symptom:** TLS handshake fails or certificate invalid.

**Solution:**

```bash
# Verify certificate
openssl x509 -in /etc/nginx/ssl/cert.pem -text -noout

# Check expiry
openssl x509 -in /etc/nginx/ssl/cert.pem -noout -dates

# Renew certificate
sudo certbot renew

# Reload service
sudo systemctl reload nginx
```

### Performance Issues

**Symptom:** Low FPS, high latency, timeouts.

**Solution:**

```bash
# Check resource usage
top
htop
free -h
df -h

# Enable performance profile
export CONFIG_PROFILE=performance_production

# Increase workers
export HTTP_WORKERS=16
export BACKGROUND_TASKS=8

# Check database performance
psql -c "SELECT * FROM pg_stat_activity"

# Check Redis
redis-cli info stats
```

---

## Environment Comparison

| Feature | Development | Staging | Production |
|---------|-------------|---------|------------|
| **Bind Address** | 127.0.0.1 | 0.0.0.0 | 0.0.0.0 |
| **TLS Enabled** | No | Yes | Yes |
| **Authentication** | Yes (relaxed) | Yes | Yes (strict) |
| **Rate Limiting** | No | Yes (moderate) | Yes (strict) |
| **IDS Enabled** | No | Yes | Yes |
| **Debug Services** | Yes | Yes | No |
| **Log Level** | debug | info | warn |
| **Monitoring** | Basic | Full | Full |
| **Backups** | No | Yes | Yes |
| **HA Enabled** | No | No | Yes |

---

## Next Steps

1. **Development:** Read [CONFIG_REFERENCE.md](./CONFIG_REFERENCE.md)
2. **Staging:** Set up monitoring and alerts
3. **Production:** Follow [PRODUCTION_HARDENING.md](./PRODUCTION_HARDENING.md)

---

## Support

- **Documentation:** https://docs.spacetime.example.com
- **Issues:** https://github.com/spacetime/issues
- **Slack:** #spacetime-support
