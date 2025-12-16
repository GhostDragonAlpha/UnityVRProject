# SpaceTime VR - Deployment Package

**Version:** 1.0.0
**Date:** 2025-12-04
**Status:** Production Ready (95%)

---

## Quick Start for Deployment Team

This deployment package contains everything needed to deploy SpaceTime VR to production successfully.

### Package Contents

```
deploy/
├── README.md (this file)           # Quick start guide
├── RUNBOOK.md                      # Step-by-step deployment procedures
├── CHECKLIST.md                    # Pre-deployment checklist
├── build/                          # Godot exported build (add after building)
├── config/                         # Production configuration files
├── kubernetes/                     # Kubernetes manifests
├── scripts/                        # Deployment and setup scripts
├── certs/                          # TLS certificates (placeholder)
├── docs/                           # Deployment guides
└── tests/                          # Validation scripts
```

### Prerequisites

**Required:**
- Godot 4.5.1+ installed
- Kubernetes 1.25+ cluster OR bare metal servers
- 8 CPU / 32GB RAM minimum per node
- 500GB SSD storage
- SSL/TLS certificates (Let's Encrypt or commercial)

**Optional:**
- VR headset (OpenXR compatible) - system falls back to desktop mode
- Monitoring stack (Prometheus + Grafana)
- Redis for caching

### Critical Configuration Items (MUST DO)

Before deployment, you MUST:

1. **Set environment variables:**
   ```bash
   export GODOT_ENABLE_HTTP_API=true
   export GODOT_ENV=production
   ```

2. **Replace Kubernetes secrets** in `kubernetes/secret.yaml`:
   - Generate: `openssl rand -base64 32` for API_TOKEN
   - Generate strong passwords for GRAFANA_ADMIN_PASSWORD, REDIS_PASSWORD
   - Replace all "REPLACE_WITH_SECURE_TOKEN" placeholders

3. **Generate TLS certificates:**
   ```bash
   # Development (self-signed)
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout certs/tls.key -out certs/tls.crt \
     -subj "/CN=spacetime.yourdomain.com"

   # Production (use cert-manager with Let's Encrypt)
   # See RUNBOOK.md for complete instructions
   ```

4. **Build the application:**
   ```bash
   godot --headless --export-release "Windows Desktop" "deploy/build/SpaceTime.exe"
   ```

5. **Test the build:**
   ```bash
   GODOT_ENABLE_HTTP_API=true ./deploy/build/SpaceTime.exe
   curl http://127.0.0.1:8080/status
   ```

### Quick Deploy (5 Minutes)

**Local/Development:**
```bash
cd deploy
./scripts/deploy_local.sh
```

**Kubernetes:**
```bash
cd deploy
./scripts/deploy_kubernetes.sh
```

**Verify Deployment:**
```bash
cd deploy
./scripts/verify_deployment.py
```

### If Something Goes Wrong

**Rollback:**
```bash
cd deploy
./scripts/rollback.sh
```

**Troubleshooting:**
- See `RUNBOOK.md` Section 6: Troubleshooting
- See `docs/DEPLOYMENT_GUIDE.md` Section 9: Troubleshooting
- Check logs: `kubectl logs -f deployment/spacetime-godot -n spacetime`
- Contact: [Your support contact info]

### Important Documents

**READ THESE FIRST:**
1. `RUNBOOK.md` - Complete deployment procedures
2. `CHECKLIST.md` - Pre-deployment verification
3. `docs/DEPLOYMENT_GUIDE.md` - Comprehensive deployment guide (1,450 lines)

**Reference Documents:**
- `docs/PRODUCTION_READINESS_CHECKLIST.md` - Production audit results
- `docs/EXECUTIVE_SUMMARY.md` - Project status and go/no-go recommendation
- `docs/PHASE_6_COMPLETE.md` - Final hardening phase summary

### Support Contacts

**Emergency Escalation:**
- On-call engineer: [Phone/email]
- Tech lead: [Phone/email]
- DevOps lead: [Phone/email]

**Regular Support:**
- Email: support@yourdomain.com
- Slack: #spacetime-deployment
- Wiki: [Your wiki URL]

### Deployment Timeline

**Estimated Time:**
- Pre-deployment tasks: 2-4 hours
- Deployment execution: 30 minutes
- Post-deployment verification: 30 minutes
- **Total: 3-5 hours**

### Next Steps

1. Read `RUNBOOK.md` completely
2. Review `CHECKLIST.md` and check off items
3. Follow deployment procedures step-by-step
4. Verify deployment with automated tests
5. Monitor for 24 hours (see `RUNBOOK.md` Section 5)

---

**Questions?** Contact the deployment team lead before proceeding.

**Ready?** Start with `RUNBOOK.md` Section 1: Pre-Deployment Checklist.

---

**Document Version:** 1.0.0
**Last Updated:** 2025-12-04
**Maintained By:** SpaceTime Development Team
