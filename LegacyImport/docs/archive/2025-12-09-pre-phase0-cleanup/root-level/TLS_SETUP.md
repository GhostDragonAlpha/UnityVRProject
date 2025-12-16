# TLS/HTTPS Setup Guide for SpaceTime

This guide covers setting up HTTPS/TLS support for the SpaceTime HTTP API server.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Development Setup](#development-setup)
- [Production Setup](#production-setup)
- [Docker Deployment](#docker-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Certificate Management](#certificate-management)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Security Assessment](#security-assessment)

## Overview

SpaceTime HTTP API now supports HTTPS/TLS through two approaches:

1. **NGINX Reverse Proxy (Recommended)** - Industry-standard TLS termination
2. **Native Godot TLS (Fallback)** - Built-in StreamPeerTLS support

### Why NGINX?

- Battle-tested and widely deployed
- Excellent performance and scalability
- Easy Let's Encrypt integration
- Advanced features (rate limiting, caching, etc.)
- Comprehensive documentation and community support

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Internet                    │
└───────────────────┬─────────────────────────┘
                    │
                    │ HTTPS (443 or 8443)
                    ▼
┌─────────────────────────────────────────────┐
│           NGINX TLS Termination              │
│  • TLS 1.3/1.2                              │
│  • Strong Ciphers                           │
│  • HSTS, CSP Headers                        │
│  • Rate Limiting                            │
└───────────────────┬─────────────────────────┘
                    │
                    │ HTTP (8080)
                    ▼
┌─────────────────────────────────────────────┐
│         Godot HTTP API Server                │
│  • Scene Management                          │
│  • Authentication                            │
│  • Business Logic                           │
└─────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Godot 4.5+ with SpaceTime project
- Python 3.8+
- OpenSSL (for certificate generation)
- NGINX (optional, for production)
- Docker (optional, for containerized deployment)

### 1. Generate Development Certificate

```bash
# Generate self-signed certificate for development
python scripts/certificate_manager.py --generate-dev

# Output:
# ✅ Certificate generated successfully!
#    Certificate: certs/dev/server.crt
#    Private Key: certs/dev/server.key
#    Validity: 365 days
```

### 2. Verify Certificate

```bash
# Check certificate details
python scripts/certificate_manager.py --check

# Verify certificate and key match
python scripts/certificate_manager.py --verify \
    certs/dev/server.crt \
    certs/dev/server.key
```

### 3. Configure NGINX

```bash
# Copy NGINX configuration
sudo cp nginx/tls.conf /etc/nginx/sites-available/spacetime
sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/

# Create certificate directory
sudo mkdir -p /etc/nginx/certs

# Copy certificates
sudo cp certs/dev/server.crt /etc/nginx/certs/
sudo cp certs/dev/server.key /etc/nginx/certs/

# Test configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx
```

### 4. Start Godot Server

```bash
# Start Godot with debug servers (HTTP API on port 8080)
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### 5. Test HTTPS Connection

```bash
# Test with curl (accept self-signed cert)
curl -k https://localhost:8443/health

# Test with Python client
python scripts/http_api/https_client.py --https --no-verify

# View certificate information
python scripts/http_api/https_client.py --https --no-verify --cert-info
```

## Development Setup

### Local Development (Self-Signed Certificate)

For local development, use self-signed certificates:

```bash
# 1. Generate certificate
python scripts/certificate_manager.py --generate-dev

# 2. Use with Python client (disable verification)
python scripts/http_api/https_client.py --https --no-verify --host 127.0.0.1 --port 8443

# 3. Or specify CA certificate
python scripts/http_api/https_client.py --https --ca-cert certs/dev/server.crt
```

### Using Native Godot TLS (Without NGINX)

If you cannot use NGINX, use the native Godot TLS wrapper:

```gdscript
# Create TLS server in your Godot script
var tls_server = TLSServerWrapper.new()
add_child(tls_server)

# Start TLS server
if tls_server.start():
    print("TLS server started on https://127.0.0.1:8443")
else:
    print("Failed to start TLS server")
```

**Note:** This is experimental. NGINX is strongly recommended.

## Production Setup

### Let's Encrypt (Free SSL Certificates)

#### Prerequisites

- Domain name pointing to your server
- Port 80 and 443 accessible
- Certbot installed

#### Setup Process

```bash
# 1. Install certbot
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# CentOS/RHEL:
sudo yum install certbot python3-certbot-nginx

# 2. Obtain certificate
sudo certbot certonly --standalone \
    -d spacetime.example.com \
    --email admin@example.com \
    --agree-tos

# Or use DNS challenge (for wildcard certs)
sudo certbot certonly --manual \
    --preferred-challenges dns \
    -d *.spacetime.example.com \
    --email admin@example.com \
    --agree-tos

# 3. Certificates will be in /etc/letsencrypt/live/spacetime.example.com/
#    - fullchain.pem (certificate)
#    - privkey.pem (private key)

# 4. Update NGINX configuration
sudo cp nginx/production.conf /etc/nginx/sites-available/spacetime
sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/

# Edit production.conf to use your domain name
sudo nano /etc/nginx/sites-available/spacetime
# Change: server_name spacetime.example.com;

# 5. Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

#### Automatic Renewal

Certbot automatically sets up renewal. Verify it's working:

```bash
# Test renewal (dry run)
sudo certbot renew --dry-run

# Check renewal timer
sudo systemctl status certbot.timer

# Or set up custom renewal script
python scripts/certificate_manager.py --setup-renewal
```

### Production Configuration

Edit `scripts/http_api/tls_config.json`:

```json
{
  "tls": {
    "enabled": true,
    "mode": "nginx",
    "certificates": {
      "production": {
        "cert_path": "/etc/letsencrypt/live/spacetime/fullchain.pem",
        "key_path": "/etc/letsencrypt/live/spacetime/privkey.pem",
        "use_letsencrypt": true,
        "domains": ["spacetime.example.com"],
        "email": "admin@example.com"
      }
    },
    "tls_settings": {
      "min_version": "1.3",
      "protocols": ["TLSv1.3", "TLSv1.2"]
    }
  }
}
```

## Docker Deployment

### Development with Docker Compose

```bash
# 1. Generate certificate
python scripts/certificate_manager.py --generate-dev

# 2. Start services
cd docker
docker-compose -f docker-compose.tls.yml up -d

# 3. Check status
docker-compose -f docker-compose.tls.yml ps

# 4. View logs
docker-compose -f docker-compose.tls.yml logs -f nginx-tls

# 5. Test connection
curl -k https://localhost:8443/health
```

### Production with Docker Compose

```bash
# 1. Set environment variable
export SPACETIME_ENV=production

# 2. Start services (with Let's Encrypt)
cd docker
docker-compose -f docker-compose.production.yml --profile production up -d

# 3. Initial Let's Encrypt setup
docker-compose -f docker-compose.production.yml exec certbot \
    certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    -d spacetime.example.com \
    --email admin@example.com \
    --agree-tos

# 4. Reload NGINX
docker-compose -f docker-compose.production.yml restart nginx-tls
```

### Building Custom Image

```bash
# Build image with TLS support
docker build -t spacetime/godot-api:latest -f docker/Dockerfile.tls .

# Run container
docker run -d \
    --name spacetime-api \
    -p 8080:8080 \
    -p 8081:8081 \
    -e SPACETIME_ENV=production \
    spacetime/godot-api:latest
```

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (1.25+)
- kubectl configured
- cert-manager installed

### Deploy to Kubernetes

```bash
# 1. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 2. Update configuration
# Edit k8s/cert-manager.yaml with your domain and email

# 3. Deploy SpaceTime
kubectl apply -f k8s/deployment.tls.yaml

# 4. Configure cert-manager
kubectl apply -f k8s/cert-manager.yaml

# 5. Check deployment
kubectl get pods -n spacetime
kubectl get certificate -n spacetime
kubectl get ingress -n spacetime

# 6. View logs
kubectl logs -f deployment/godot-api -n spacetime
kubectl logs -f deployment/nginx-tls -n spacetime
```

See [k8s/README.md](k8s/README.md) for detailed Kubernetes documentation.

## Certificate Management

### Check Certificate Expiration

```bash
# Check all certificates
python scripts/certificate_manager.py --check

# Output:
# ✅ Development Certificate:
#    Path: certs/dev/server.crt
#    Expires: 2025-12-02 10:00:00
#    Days remaining: 365
```

### Renew Certificates

```bash
# Let's Encrypt (automatic)
sudo certbot renew

# Manual renewal
python scripts/certificate_manager.py --letsencrypt \
    --domains spacetime.example.com \
    --email admin@example.com
```

### Certificate Monitoring

Set up monitoring for certificate expiration:

```bash
# Create cron job for daily checks
cat <<EOF | crontab -
0 8 * * * python /path/to/scripts/certificate_manager.py --check
EOF
```

## Testing

### Run TLS Test Suite

```bash
# Run all TLS tests
cd tests
python http_api/test_tls.py

# Run specific test class
pytest http_api/test_tls.py::TestHTTPSConnection -v

# Run with custom host/port
TEST_HOST=spacetime.example.com HTTPS_PORT=443 pytest http_api/test_tls.py
```

### Test Categories

The test suite includes 20+ tests in these categories:

1. **Certificate Generation** (4 tests)
   - Self-signed certificate generation
   - Certificate validity
   - Certificate/key matching
   - Expiry checking

2. **HTTPS Connection** (6 tests)
   - Basic HTTPS connection
   - TLS version verification
   - Cipher strength testing
   - Certificate subject validation
   - Subject Alternative Names (SAN)

3. **Certificate Validation** (3 tests)
   - Invalid certificate rejection
   - Custom CA acceptance
   - Hostname verification

4. **Security Headers** (5 tests)
   - HSTS header
   - X-Content-Type-Options
   - X-Frame-Options
   - X-XSS-Protection
   - Referrer-Policy

5. **API Functionality** (3 tests)
   - Health endpoint over HTTPS
   - Authenticated requests
   - POST requests

6. **Performance** (2 tests)
   - HTTPS response time
   - TLS handshake speed

7. **Configuration** (3 tests)
   - Config file validation
   - JSON structure
   - Security settings

### Manual Testing

```bash
# Test with curl
curl -k https://localhost:8443/health

# Test TLS version
curl -k https://localhost:8443/health --tlsv1.3

# Test with specific cipher
curl -k https://localhost:8443/health --ciphers 'TLS_AES_256_GCM_SHA384'

# View full TLS handshake
openssl s_client -connect localhost:8443 -tls1_3

# Test SSL configuration strength
testssl.sh https://localhost:8443
```

## Troubleshooting

### Certificate Errors

**Problem:** "Certificate verify failed"

```bash
# Solution 1: Disable verification (development only)
curl -k https://localhost:8443/health

# Solution 2: Use custom CA certificate
curl --cacert certs/dev/server.crt https://localhost:8443/health

# Solution 3: Add cert to system trust store (Linux)
sudo cp certs/dev/server.crt /usr/local/share/ca-certificates/spacetime.crt
sudo update-ca-certificates
```

**Problem:** "Certificate and key don't match"

```bash
# Verify they match
python scripts/certificate_manager.py --verify \
    certs/dev/server.crt \
    certs/dev/server.key

# Regenerate if needed
python scripts/certificate_manager.py --generate-dev
```

### Connection Errors

**Problem:** "Connection refused"

```bash
# Check if NGINX is running
sudo systemctl status nginx

# Check if port is open
sudo netstat -tulpn | grep :8443

# Check NGINX logs
sudo tail -f /var/log/nginx/spacetime_error.log
```

**Problem:** "Upstream connection failed"

```bash
# Check if Godot API is running
curl http://localhost:8080/health

# Check NGINX can reach Godot
docker-compose exec nginx-tls curl http://godot-api:8080/health
```

### NGINX Errors

**Problem:** "NGINX configuration test failed"

```bash
# Test configuration
sudo nginx -t

# Check syntax
sudo nginx -T | less

# Validate paths
ls -la /etc/nginx/certs/server.crt
ls -la /etc/nginx/certs/server.key
```

**Problem:** "Permission denied" for certificates

```bash
# Fix permissions
sudo chmod 644 /etc/nginx/certs/server.crt
sudo chmod 600 /etc/nginx/certs/server.key
sudo chown root:root /etc/nginx/certs/*
```

### Let's Encrypt Errors

**Problem:** "Failed to obtain certificate"

```bash
# Check domain DNS
dig spacetime.example.com

# Check port 80 is accessible
curl http://spacetime.example.com/.well-known/acme-challenge/test

# Check certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Try staging first
sudo certbot certonly --staging -d spacetime.example.com
```

### Docker Errors

**Problem:** "Container fails to start"

```bash
# Check logs
docker-compose logs nginx-tls

# Check certificate mount
docker-compose exec nginx-tls ls -la /etc/nginx/certs/

# Rebuild container
docker-compose build --no-cache nginx-tls
docker-compose up -d nginx-tls
```

## Security Assessment

### SSL Labs Test

Test your production deployment:

1. Go to https://www.ssllabs.com/ssltest/
2. Enter your domain: `spacetime.example.com`
3. Wait for analysis (5-10 minutes)

**Expected Grade: A+**

Criteria for A+ rating:
- ✅ TLS 1.3 and 1.2 support
- ✅ Strong cipher suites only
- ✅ Perfect Forward Secrecy (PFS)
- ✅ HSTS with preload
- ✅ No weak protocols (SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1)
- ✅ No weak ciphers (RC4, DES, 3DES, MD5)
- ✅ Certificate chain valid
- ✅ OCSP stapling enabled

### Security Checklist

Production deployment checklist:

- [ ] Valid SSL certificate (Let's Encrypt or commercial)
- [ ] TLS 1.3 enabled (with TLS 1.2 fallback)
- [ ] Strong cipher suites configured
- [ ] HSTS enabled with max-age ≥ 31536000
- [ ] HSTS preload submitted to browsers
- [ ] OCSP stapling enabled
- [ ] Security headers configured (CSP, X-Frame-Options, etc.)
- [ ] HTTP to HTTPS redirect enabled
- [ ] Certificate renewal automated
- [ ] Certificate expiry monitoring
- [ ] Rate limiting enabled
- [ ] Firewall configured (ports 80, 443 only)
- [ ] DH parameters generated (2048-bit minimum)
- [ ] Server tokens disabled
- [ ] Access logs reviewed regularly
- [ ] Intrusion detection system (IDS) enabled
- [ ] Regular security updates applied

### Security Best Practices

1. **Use Let's Encrypt in Production**
   - Free, automated, and trusted by all browsers
   - 90-day validity forces regular renewal

2. **Enable TLS 1.3**
   - Faster handshake
   - Improved security
   - Remove deprecated ciphers

3. **Implement HSTS Preload**
   - Submit to https://hstspreload.org/
   - Prevents downgrade attacks
   - Forces HTTPS for all visitors

4. **Monitor Certificate Expiry**
   - Set up alerts 30 days before expiry
   - Test renewal process regularly
   - Have backup certificate ready

5. **Regular Security Audits**
   - Run SSL Labs test monthly
   - Use `testssl.sh` for detailed analysis
   - Review access logs for suspicious activity

6. **Keep Software Updated**
   - Update NGINX regularly
   - Update OpenSSL/BoringSSL
   - Update cert-manager (K8s)

## Additional Resources

- [SSL Labs Best Practices](https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [NGINX TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Godot StreamPeerTLS](https://docs.godotengine.org/en/stable/classes/class_streampeertls.html)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review NGINX error logs: `/var/log/nginx/spacetime_error.log`
- Run test suite: `pytest tests/http_api/test_tls.py -v`
- Check certificate: `python scripts/certificate_manager.py --check`

---

**Last Updated:** 2025-12-02
**Version:** 2.0
**Minimum Requirements:** Godot 4.5+, Python 3.8+, NGINX 1.18+
