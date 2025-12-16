# Configuration Quick Start

Get SpaceTime VR running in any environment in 5 minutes or less.

---

## Development (Local Testing)

```bash
# 1. Copy template
cp .env.template .env

# 2. Set environment
export ENVIRONMENT=development

# 3. Start with debug services
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# 4. Verify
curl http://127.0.0.1:8080/status
```

**Configuration:** `config/development.json`
**Features:** Debug enabled, relaxed security, verbose logging

---

## Staging (Pre-Production)

```bash
# 1. Install prerequisites
sudo apt install postgresql-14 redis-server
sudo certbot certonly --standalone -d staging.spacetime.example.com

# 2. Set environment
export ENVIRONMENT=staging
export DB_HOST=staging-db.example.com
export REDIS_HOST=staging-redis.example.com
export API_TOKEN=$(openssl rand -base64 32)

# 3. Validate config
python scripts/validate_config.py staging --strict

# 4. Deploy
docker-compose -f docker-compose.staging.yml up -d

# 5. Verify
curl https://staging.spacetime.example.com/health
```

**Configuration:** `config/staging.json`
**Features:** Production-like, security enabled, full monitoring

---

## Production (Live)

```bash
# 1. Pre-deployment checklist
# ✓ SSL certificates installed
# ✓ Secrets in Vault
# ✓ Database configured
# ✓ Firewall configured
# ✓ Monitoring configured
# ✓ Backups tested

# 2. Fetch secrets from Vault
export DB_HOST=$(vault kv get -field=host secret/spacetime/production/database)
export DB_PASSWORD=$(vault kv get -field=password secret/spacetime/production/database)
export API_TOKEN=$(vault kv get -field=token secret/spacetime/production/api)

# 3. Validate config
python scripts/validate_config.py production --strict

# 4. Deploy
docker-compose -f docker-compose.production.yml up -d

# 5. Post-deployment checks
curl https://spacetime.example.com/health
curl https://spacetime.example.com/status
./scripts/post_deployment_checks.sh
```

**Configuration:** `config/production.json`
**Features:** Maximum security, strict limits, audit logging

---

## Using Security-Hardened Profile

For maximum security in production:

```bash
# Use security-hardened configuration
export CONFIG_PROFILE=security_production
python scripts/validate_config.py production --strict
```

**Configuration:** `config/security_production.json`
**Features:** 24h token rotation, aggressive rate limits, full IDS

---

## Using Performance-Optimized Profile

For high-traffic scenarios:

```bash
# Use performance-optimized configuration
export CONFIG_PROFILE=performance_production
python scripts/validate_config.py production --strict
```

**Configuration:** `config/performance_production.json`
**Features:** 16 workers, aggressive caching, VR optimizations

---

## Validation

Always validate before deployment:

```bash
# Basic validation
python scripts/validate_config.py development

# Strict validation (production)
python scripts/validate_config.py production --strict
```

**Validation checks:**
- JSON syntax
- Required fields
- Type correctness
- Security best practices
- Production readiness

---

## Common Tasks

### View Current Configuration

```bash
# Check environment
echo $ENVIRONMENT

# View config file
cat config/$ENVIRONMENT.json | jq .

# Check loaded values
curl http://127.0.0.1:8080/admin/config
```

### Change Log Level

```bash
# Edit .env
echo "LOG_LEVEL=debug" >> .env

# Or set environment variable
export LOG_LEVEL=debug

# Restart service
systemctl restart spacetime
```

### Rotate API Token

```bash
# Generate new token
openssl rand -base64 32

# Update in Vault
vault kv put secret/spacetime/production/api token="NEW_TOKEN_HERE"

# Or update .env
echo "API_TOKEN=NEW_TOKEN_HERE" >> .env

# Restart service
systemctl restart spacetime
```

### Enable/Disable Features

```bash
# Edit .env
echo "ENABLE_DEBUG_MODE=false" >> .env
echo "ENABLE_VR=true" >> .env

# Restart service
systemctl restart spacetime
```

---

## Troubleshooting

### Configuration Not Loading

```bash
# Check environment variable
echo $ENVIRONMENT

# Verify file exists
ls -la config/$ENVIRONMENT.json

# Validate JSON syntax
python -m json.tool config/$ENVIRONMENT.json
```

### Port Already in Use

```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>

# Or use fallback ports
export HTTP_API_FALLBACK_PORTS=8083,8084,8085
```

### TLS Certificate Errors

```bash
# Check certificate
openssl x509 -in /etc/nginx/ssl/cert.pem -text -noout

# Renew certificate
sudo certbot renew

# Reload service
sudo systemctl reload nginx
```

---

## Next Steps

- **Full Reference:** [CONFIG_REFERENCE.md](./CONFIG_REFERENCE.md)
- **Production Guide:** [PRODUCTION_HARDENING.md](./PRODUCTION_HARDENING.md)
- **Detailed Setup:** [ENVIRONMENT_SETUP_GUIDE.md](./ENVIRONMENT_SETUP_GUIDE.md)

---

## Configuration Files Reference

| File | Purpose |
|------|---------|
| `config/development.json` | Development environment |
| `config/staging.json` | Staging environment |
| `config/production.json` | Production environment |
| `config/security_production.json` | Security-hardened profile |
| `config/performance_production.json` | Performance-optimized profile |
| `.env.template` | Environment variable template |
| `.env` | Local environment variables (not committed) |

---

## Key Environment Variables

```bash
# Environment selection
ENVIRONMENT=development|staging|production

# Security
API_TOKEN=your_secure_token_here
TLS_ENABLED=true|false

# Database
DB_HOST=localhost
DB_USER=spacetime
DB_PASSWORD=secure_password

# Cache
REDIS_HOST=localhost
REDIS_PASSWORD=secure_password

# Monitoring
PROMETHEUS_ENABLED=true|false
TELEMETRY_ENABLED=true|false

# Logging
LOG_LEVEL=debug|info|warn|error
LOG_FORMAT=text|json

# Features
ENABLE_VR=true|false
ENABLE_DEBUG_MODE=true|false
```

See `.env.template` for complete list (150+ variables).

---

## Support

- **Documentation:** `docs/configuration/`
- **Validation:** `python scripts/validate_config.py ENV`
- **Issues:** Check troubleshooting sections
