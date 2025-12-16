# SpaceTime VR - Deployment Checklist

**Version:** 1.0.0
**Date:** 2025-12-04
**Deployment Date:** _______________
**Deployment Engineer:** _______________

---

## Pre-Deployment Checklist

### Critical Items (MUST complete before deployment)

- [ ] **Environment Variables Configured**
  - [ ] `GODOT_ENABLE_HTTP_API=true` set
  - [ ] `GODOT_ENV=production` set
  - [ ] Variables verified with `echo` command
  - [ ] Variables persist across restarts (systemd/K8s config)

- [ ] **Secrets Generated and Deployed**
  - [ ] API_TOKEN generated (`openssl rand -base64 32`)
  - [ ] GRAFANA_ADMIN_PASSWORD generated (strong password)
  - [ ] REDIS_PASSWORD generated (strong password)
  - [ ] Kubernetes secret created (if using K8s)
  - [ ] No "REPLACE_WITH_SECURE_TOKEN" placeholders remain
  - [ ] Credentials saved securely (0600 permissions)

- [ ] **TLS Certificates Generated**
  - [ ] Self-signed cert generated (development) OR
  - [ ] Let's Encrypt configured with cert-manager (production)
  - [ ] Kubernetes TLS secret created (if using K8s)
  - [ ] Certificate expiration date noted: _______________

- [ ] **Build Exported and Validated**
  - [ ] Release build exported: `deploy/build/SpaceTime.exe` exists
  - [ ] Build size reasonable (100-500 MB)
  - [ ] Build tested with `GODOT_ENABLE_HTTP_API=true`
  - [ ] API responds on port 8080
  - [ ] Status endpoint returns expected JSON

- [ ] **Tests Passing**
  - [ ] Test runner: All tests passing
  - [ ] Health monitor: All checks passing
  - [ ] Feature validator: All features validated
  - [ ] No critical failures in any test suite

---

### High Priority (SHOULD complete before deployment)

- [ ] **Scene Whitelist Reviewed**
  - [ ] Production whitelist contains only necessary scenes
  - [ ] `res://vr_main.tscn` included
  - [ ] No test/debug scenes in production list
  - [ ] Blacklist includes addons, .godot, gdUnit4

- [ ] **Log Files Cleaned**
  - [ ] Reviewed .log files in repository root
  - [ ] Deleted sensitive or unnecessary logs
  - [ ] Verified .gitignore excludes .log files

- [ ] **Audit Logging Status Confirmed**
  - [ ] Understand audit logging is temporarily disabled
  - [ ] Acceptable for deployment: YES / NO
  - [ ] Alternative logging configured (if needed)

- [ ] **Monitoring Configured**
  - [ ] Prometheus deployed (if using monitoring)
  - [ ] Grafana deployed (if using monitoring)
  - [ ] Health check alerts configured (every 5 minutes)
  - [ ] Error alerting configured
  - [ ] Dashboard created or imported

- [ ] **Team Training Complete**
  - [ ] Deployment procedures reviewed
  - [ ] Health monitoring training completed
  - [ ] Troubleshooting session conducted
  - [ ] Rollback procedure practiced

---

### Medium Priority (CONSIDER before deployment)

- [ ] **Export Metadata Added**
  - [ ] Version number set in export_presets.cfg
  - [ ] Company name set
  - [ ] Product name set
  - [ ] File description set

- [ ] **VR Fallback Tested**
  - [ ] Tested without VR headset
  - [ ] Desktop fallback works correctly
  - [ ] Warning message appears in logs
  - [ ] Acceptable for production environment: YES / NO

- [ ] **Rate Limits Reviewed**
  - [ ] Global limit: 300 req/min (appropriate)
  - [ ] Scene endpoints: 10-30 req/min (appropriate)
  - [ ] Status endpoint: 100 req/min (appropriate)
  - [ ] Plan to adjust based on usage data

---

## Deployment Checklist

### Pre-Deployment (Day Before)

- [ ] **Infrastructure Ready**
  - [ ] Kubernetes cluster available and healthy OR
  - [ ] Bare metal servers provisioned
  - [ ] Network connectivity verified
  - [ ] DNS configured (if applicable)
  - [ ] Firewall rules applied (ports 8080, 8081, 8087)

- [ ] **Backups Created**
  - [ ] Previous deployment backed up (if applicable)
  - [ ] Configuration files backed up
  - [ ] Database backed up (if applicable)

- [ ] **Communication Sent**
  - [ ] Deployment window announced to stakeholders
  - [ ] On-call rotation updated
  - [ ] Status page updated (if applicable)

---

### Deployment Day (T-2 hours)

- [ ] **Final Verification**
  - [ ] All pre-deployment items checked
  - [ ] No outstanding blockers
  - [ ] Team ready and available
  - [ ] Rollback plan reviewed

- [ ] **Staging Deployment**
  - [ ] Deployed to staging environment
  - [ ] Staging tests passing
  - [ ] No issues discovered

---

### Deployment Execution (T-0)

- [ ] **Start Deployment**
  - [ ] Deployment start time logged: _______________
  - [ ] Runbook RUNBOOK.md opened
  - [ ] Following steps sequentially

- [ ] **Step 1: Create Namespace (K8s)**
  - [ ] Namespace created
  - [ ] Verified with `kubectl get namespace spacetime`

- [ ] **Step 2: Apply Configuration**
  - [ ] ConfigMap applied
  - [ ] Verified with `kubectl get configmap -n spacetime`

- [ ] **Step 3: Create Persistent Volumes (K8s)**
  - [ ] PVCs created
  - [ ] All PVCs in "Bound" state

- [ ] **Step 4: Deploy Application**
  - [ ] StatefulSets deployed (Redis)
  - [ ] Deployments applied (Godot, Nginx)
  - [ ] Rollout completed successfully
  - [ ] All pods in "Running" state

- [ ] **Step 5: Deploy Services (K8s)**
  - [ ] Services created
  - [ ] ClusterIP or LoadBalancer assigned

- [ ] **Step 6: Deploy Ingress (K8s)**
  - [ ] Ingress created
  - [ ] External IP assigned
  - [ ] DNS updated (if applicable)

- [ ] **Step 7: Network Policies (K8s, Optional)**
  - [ ] NetworkPolicy applied OR
  - [ ] Skipped (acceptable)

- [ ] **Step 8: HPA (K8s, Optional)**
  - [ ] HPA configured OR
  - [ ] Skipped (acceptable)

---

### Post-Deployment Verification (T+30 minutes)

- [ ] **Check 1: Pods Running**
  - [ ] All pods in "Running" state
  - [ ] No restarts or crashes

- [ ] **Check 2: API Health Check**
  - [ ] `/health` endpoint returns 200 OK
  - [ ] Response: `{"status": "ok"}`

- [ ] **Check 3: API Status Check**
  - [ ] `/status` endpoint returns healthy status
  - [ ] `environment` is "production"
  - [ ] `http_api` is "active"

- [ ] **Check 4: Telemetry WebSocket**
  - [ ] Port 8081 listening
  - [ ] Connection successful

- [ ] **Check 5: Scene Loaded**
  - [ ] Current scene is `res://vr_main.tscn`
  - [ ] Scene loaded successfully

- [ ] **Check 6: Authentication Working**
  - [ ] Requests without token fail (401)
  - [ ] Requests with token succeed (200)

- [ ] **Check 7: Rate Limiting Active**
  - [ ] Rate limit violations trigger 429 response
  - [ ] Rate limiting working as expected

- [ ] **Check 8: Scene Whitelist Enforced**
  - [ ] Test scene load fails (403)
  - [ ] Whitelist enforced correctly

- [ ] **Check 9: Performance Metrics Available**
  - [ ] `/performance` endpoint returns data
  - [ ] All metrics populated

- [ ] **Check 10: Automated Validation**
  - [ ] `verify_deployment.py` passes
  - [ ] All checks successful

---

### Post-Deployment Summary

**Deployment Completion Time:** _______________
**Total Duration:** _______________ hours
**Verification Results:** _____ / 10 checks passed

**Status:**
- [ ] ✅ DEPLOYMENT SUCCESSFUL (10/10 passed)
- [ ] ⚠️ DEPLOYMENT PARTIAL (8-9/10 passed)
- [ ] ❌ DEPLOYMENT FAILED (<8/10 passed)

**Issues Encountered:**
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

**Rollback Performed:**
- [ ] YES - Reason: _______________________________________________
- [ ] NO

---

## Post-Deployment Monitoring (First 24 Hours)

### Hour 1

- [ ] **Health Checks (every 5 minutes)**
  - [ ] API responsive
  - [ ] No error spikes
  - [ ] FPS stable (85-95)
  - [ ] Memory usage stable (<400 MB)

- [ ] **Log Review**
  - [ ] No critical errors
  - [ ] No unexpected warnings
  - [ ] VR initialization logged (or desktop fallback)

### Hour 4

- [ ] **Performance Review**
  - [ ] FPS trend: _______________
  - [ ] Memory trend: _______________
  - [ ] Request latency: _______________
  - [ ] Error rate: _______________

- [ ] **Security Check**
  - [ ] No failed authentication attacks
  - [ ] Rate limiting working
  - [ ] No suspicious activity

### Hour 24

- [ ] **Daily Review**
  - [ ] Uptime: _______________
  - [ ] Total requests: _______________
  - [ ] Errors: _______________
  - [ ] Restarts: _______________

- [ ] **User Feedback**
  - [ ] Collected initial feedback
  - [ ] No critical issues reported
  - [ ] Performance acceptable

---

## Week 1 Follow-Up

- [ ] **Complete Tier 2 Tasks**
  - [ ] Monitoring dashboards created
  - [ ] Phase 2 routers enabled (WebhookRouter, JobRouter)
  - [ ] Load testing completed
  - [ ] Security audit completed

- [ ] **Documentation Updates**
  - [ ] Production runbook updated with lessons learned
  - [ ] Troubleshooting guide updated
  - [ ] Team training materials updated

- [ ] **Performance Optimization**
  - [ ] Identified bottlenecks (if any)
  - [ ] Optimizations applied (if needed)
  - [ ] Rate limits adjusted based on usage

---

## Sign-Off

**Deployment Engineer:** _______________  **Signature:** _______________  **Date:** _______________

**Tech Lead:** _______________  **Signature:** _______________  **Date:** _______________

**DevOps Lead:** _______________  **Signature:** _______________  **Date:** _______________

**Product Owner:** _______________  **Signature:** _______________  **Date:** _______________

---

## Notes

Use this space for additional notes, observations, or recommendations:

_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

---

**Document Version:** 1.0.0
**Last Updated:** 2025-12-04
**Next Review:** After deployment completion
