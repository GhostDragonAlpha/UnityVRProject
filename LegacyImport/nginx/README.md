# NGINX Configuration for SpaceTime

This directory contains NGINX configuration files for HTTPS termination.

## Configuration Files

- **tls.conf** - Development/testing configuration with self-signed certificates
- **production.conf** - Production configuration with Let's Encrypt certificates

## Quick Setup

### Development (Self-Signed Certificate)

1. Generate development certificate:
```bash
python scripts/certificate_manager.py --generate-dev
```

2. Copy NGINX config:
```bash
# Linux/Mac
sudo cp nginx/tls.conf /etc/nginx/sites-available/spacetime
sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/
sudo mkdir -p /etc/nginx/certs
sudo cp certs/dev/server.crt /etc/nginx/certs/
sudo cp certs/dev/server.key /etc/nginx/certs/

# Or use Docker (see Docker section below)
```

3. Test and reload NGINX:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Production (Let's Encrypt)

1. Set up Let's Encrypt:
```bash
python scripts/certificate_manager.py --letsencrypt \
    --domains spacetime.example.com \
    --email admin@example.com
```

2. Copy production config:
```bash
sudo cp nginx/production.conf /etc/nginx/sites-available/spacetime
sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/
```

3. Generate DH parameters (one-time setup):
```bash
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
```

4. Test and reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Using with Docker

See `docker/nginx/` directory for Dockerized NGINX setup.

## Testing TLS Configuration

Test SSL configuration strength:
```bash
# Using SSL Labs (online)
https://www.ssllabs.com/ssltest/analyze.html?d=spacetime.example.com

# Using testssl.sh (local)
./testssl.sh https://spacetime.example.com:443
```

Test with curl:
```bash
# Development (accept self-signed cert)
curl -k https://localhost:8443/health

# Production
curl https://spacetime.example.com/health
```

## Security Features

- TLS 1.3 and 1.2 only
- Strong cipher suites (A+ rating compatible)
- HSTS with preload
- OCSP stapling
- Security headers (CSP, X-Frame-Options, etc.)
- Rate limiting
- Request size limits

## Monitoring

Check NGINX status:
```bash
curl http://localhost/nginx_status
```

View logs:
```bash
sudo tail -f /var/log/nginx/spacetime_access.log
sudo tail -f /var/log/nginx/spacetime_error.log
```

## Troubleshooting

### Certificate Errors

Check certificate:
```bash
openssl x509 -in /etc/nginx/certs/server.crt -text -noout
```

Verify certificate and key match:
```bash
python scripts/certificate_manager.py --verify \
    /etc/nginx/certs/server.crt \
    /etc/nginx/certs/server.key
```

### Connection Refused

Ensure Godot HTTP API is running:
```bash
curl http://127.0.0.1:8080/health
```

Check NGINX error logs:
```bash
sudo tail -100 /var/log/nginx/spacetime_error.log
```

### Rate Limiting

If you're being rate limited:
```bash
# Check current limits in nginx config
grep limit_req nginx/tls.conf

# Increase limits if needed (then reload NGINX)
```
