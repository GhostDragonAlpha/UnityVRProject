# HTTPS Quick Start Guide for SpaceTime

**Get HTTPS running in 5 minutes!**

## Prerequisites

- ✅ Godot 4.5+ with SpaceTime project
- ✅ Python 3.8+
- ✅ OpenSSL (for certificates)
- ⬜ NGINX (optional, but recommended)
- ⬜ Docker (optional, for containerized setup)

## Option 1: Quick Development Setup (Self-Signed)

### Step 1: Generate Certificate (30 seconds)

```bash
cd C:/godot
python scripts/certificate_manager.py --generate-dev
```

**Output:**
```
🔐 Generating self-signed certificate for development...
✅ Certificate generated successfully!
   Certificate: certs/dev/server.crt
   Private Key: certs/dev/server.key
   Validity: 365 days
```

### Step 2: Start NGINX (1 minute)

```bash
# Install NGINX first if needed:
# Ubuntu: sudo apt install nginx
# macOS: brew install nginx
# Windows: Download from https://nginx.org/

# Copy configuration
sudo cp nginx/tls.conf /etc/nginx/sites-available/spacetime
sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/

# Copy certificates
sudo mkdir -p /etc/nginx/certs
sudo cp certs/dev/server.crt /etc/nginx/certs/
sudo cp certs/dev/server.key /etc/nginx/certs/

# Test and start
sudo nginx -t
sudo systemctl reload nginx
```

### Step 3: Start Godot Server (30 seconds)

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### Step 4: Test HTTPS Connection (1 minute)

```bash
# Test with curl
curl -k https://localhost:8443/health

# Test with Python client
python scripts/http_api/https_client.py --https --no-verify

# View certificate info
python scripts/http_api/https_client.py --https --no-verify --cert-info
```

**Expected Output:**
```
Connecting to https://127.0.0.1:8443...
✅ API is healthy!

📜 Certificate Information:
   Subject: {'commonName': 'localhost'}
   Issuer: {'commonName': 'localhost'}
   Valid from: Dec  2 10:00:00 2025 GMT
   Valid until: Dec  2 10:00:00 2026 GMT
   TLS Version: TLSv1.3
   Cipher: ('TLS_AES_256_GCM_SHA384', 'TLSv1.3', 256)
```

**🎉 Done! Your HTTPS server is running!**

---

## Option 2: Docker Setup (Even Faster!)

### Step 1: Generate Certificate

```bash
python scripts/certificate_manager.py --generate-dev
```

### Step 2: Start Docker Services

```bash
cd docker
docker-compose -f docker-compose.tls.yml up -d
```

### Step 3: Test

```bash
curl -k https://localhost:8443/health
```

**🎉 Done! HTTPS running in Docker!**

---

## Option 3: Production Setup (Let's Encrypt)

### Prerequisites
- Domain name (e.g., spacetime.example.com)
- DNS pointing to your server
- Port 80 and 443 accessible

### Step 1: Install Certbot

```bash
# Ubuntu/Debian
sudo apt install certbot

# CentOS/RHEL
sudo yum install certbot

# macOS
brew install certbot
```

### Step 2: Obtain Certificate

```bash
sudo certbot certonly --standalone \
    -d spacetime.example.com \
    --email admin@example.com \
    --agree-tos
```

### Step 3: Configure NGINX

```bash
# Update production.conf with your domain
sudo cp nginx/production.conf /etc/nginx/sites-available/spacetime
sudo nano /etc/nginx/sites-available/spacetime
# Change: server_name spacetime.example.com;

sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 4: Test Production HTTPS

```bash
# From anywhere in the world
curl https://spacetime.example.com/health

# Check SSL grade
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=spacetime.example.com
```

**🎉 Production HTTPS with A+ security grade!**

---

## Troubleshooting

### Problem: "Connection refused"

**Solution:**
```bash
# Check if NGINX is running
sudo systemctl status nginx

# Check if port is open
sudo netstat -tulpn | grep :8443

# Check if Godot is running
curl http://localhost:8080/health
```

### Problem: "Certificate verify failed"

**Solution:**
```bash
# For development, disable verification
curl -k https://localhost:8443/health

# Or use custom CA
curl --cacert certs/dev/server.crt https://localhost:8443/health
```

### Problem: "Permission denied" for certificates

**Solution:**
```bash
# Fix permissions
sudo chmod 644 /etc/nginx/certs/server.crt
sudo chmod 600 /etc/nginx/certs/server.key
sudo chown root:root /etc/nginx/certs/*
```

---

## Next Steps

### 1. Update Your Applications

**Python:**
```python
from scripts.http_api.https_client import create_client

# Development (self-signed)
client = create_client(use_https=True, verify_ssl=False)

# Production (Let's Encrypt)
client = create_client(
    use_https=True,
    port=443,
    host='spacetime.example.com',
    verify_ssl=True
)

response = client.get('/health')
```

**curl:**
```bash
# Development
curl -k https://localhost:8443/api/endpoint

# Production
curl https://spacetime.example.com/api/endpoint
```

### 2. Set Up Certificate Monitoring

```bash
# Check certificate expiry
python scripts/certificate_manager.py --check

# Set up automatic renewal (production)
python scripts/certificate_manager.py --setup-renewal
```

### 3. Run Tests

```bash
# Run TLS test suite
pytest tests/http_api/test_tls.py -v
```

### 4. Review Security

```bash
# Check security headers
curl -I -k https://localhost:8443/health

# Test SSL configuration
testssl.sh https://localhost:8443
```

---

## Common Use Cases

### Use Case 1: Local Development

**Goal:** Test HTTPS features locally

**Setup:**
```bash
python scripts/certificate_manager.py --generate-dev
docker-compose -f docker/docker-compose.tls.yml up -d
```

**Access:** https://localhost:8443

### Use Case 2: Staging Environment

**Goal:** Test with Let's Encrypt staging

**Setup:**
```bash
python scripts/certificate_manager.py --letsencrypt \
    --domains staging.spacetime.example.com \
    --email admin@example.com \
    --staging
```

### Use Case 3: Production Deployment

**Goal:** Production-ready HTTPS

**Setup:**
```bash
# Kubernetes with cert-manager
kubectl apply -f k8s/deployment.tls.yaml
kubectl apply -f k8s/cert-manager.yaml

# Or Docker Compose
docker-compose -f docker/docker-compose.production.yml --profile production up -d
```

---

## Learning Path

### New to HTTPS/TLS?

1. **Start here:** Read `TLS_SETUP.md` overview section
2. **Try this:** Option 1 (Development Setup) above
3. **Test it:** Run `pytest tests/http_api/test_tls.py -v`
4. **Learn more:** Review `nginx/tls.conf` with comments

### Experienced with HTTPS?

1. **Jump to:** Option 3 (Production Setup) above
2. **Optimize:** Review `nginx/production.conf` for tuning
3. **Scale:** Check `k8s/` for Kubernetes deployment
4. **Monitor:** Set up Prometheus/Grafana with `docker/docker-compose.production.yml`

### Security Professional?

1. **Audit:** Review `TLS_IMPLEMENTATION_REPORT.md`
2. **Test:** Run SSL Labs test on your deployment
3. **Harden:** Review security checklist in `TLS_SETUP.md`
4. **Contribute:** Suggest improvements for A+ rating

---

## Documentation Index

- **This file:** Quick start (you are here)
- **TLS_SETUP.md:** Comprehensive setup guide (850 lines)
- **TLS_IMPLEMENTATION_REPORT.md:** Technical implementation details
- **nginx/README.md:** NGINX-specific documentation
- **k8s/README.md:** Kubernetes deployment guide
- **tests/http_api/test_tls.py:** Test suite (see examples)
- **examples/https_example.py:** Python client examples

---

## Getting Help

### Documentation
```bash
# Certificate manager help
python scripts/certificate_manager.py --help

# HTTPS client help
python scripts/http_api/https_client.py --help

# Test suite help
pytest tests/http_api/test_tls.py --help
```

### Validation
```bash
# Check certificate
python scripts/certificate_manager.py --check

# Test connection
python scripts/http_api/https_client.py --https --no-verify

# Run tests
pytest tests/http_api/test_tls.py -v
```

### Logs
```bash
# NGINX logs
sudo tail -f /var/log/nginx/spacetime_error.log
sudo tail -f /var/log/nginx/spacetime_access.log

# Docker logs
docker-compose logs -f nginx-tls

# Kubernetes logs
kubectl logs -f deployment/nginx-tls -n spacetime
```

---

## Quick Reference Commands

```bash
# Certificate Management
python scripts/certificate_manager.py --generate-dev        # Generate dev cert
python scripts/certificate_manager.py --check               # Check expiry
python scripts/certificate_manager.py --verify CERT KEY     # Verify cert/key match

# NGINX
sudo nginx -t                                               # Test config
sudo systemctl reload nginx                                 # Reload config
sudo systemctl status nginx                                 # Check status

# Testing
curl -k https://localhost:8443/health                       # Test endpoint
python scripts/http_api/https_client.py --https --no-verify # Test with client
pytest tests/http_api/test_tls.py -v                        # Run tests

# Docker
docker-compose -f docker/docker-compose.tls.yml up -d       # Start services
docker-compose -f docker/docker-compose.tls.yml logs -f     # View logs
docker-compose -f docker/docker-compose.tls.yml down        # Stop services

# Kubernetes
kubectl apply -f k8s/deployment.tls.yaml                    # Deploy
kubectl get all -n spacetime                                # Check status
kubectl logs -f deployment/godot-api -n spacetime           # View logs
```

---

## Success Checklist

After setup, verify:

- [ ] Certificate generated and valid
- [ ] NGINX running and accessible
- [ ] Godot HTTP API running
- [ ] HTTPS endpoint responding
- [ ] Certificate information retrievable
- [ ] Security headers present
- [ ] HTTP redirects to HTTPS (production)
- [ ] Tests passing (at least config tests)
- [ ] Documentation reviewed
- [ ] Monitoring configured (optional)

---

**Ready to go? Pick an option above and start in 5 minutes!**

**Questions?** Check `TLS_SETUP.md` for detailed documentation.

**Issues?** Review troubleshooting section above or check error logs.

**Last Updated:** 2025-12-02
