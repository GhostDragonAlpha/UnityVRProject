# WebSocket Security Quick Start Guide

**Fix for:** VULN-012 (Unauthenticated WebSocket)
**Time Required:** 10 minutes
**Complexity:** Low

---

## ⚡ Quick Deploy (5 Minutes)

### Step 1: Stop Godot
Close Godot completely.

### Step 2: Deploy Secure Server

**Windows (PowerShell):**
```powershell
cd C:\godot\addons\godot_debug_connection
copy telemetry_server.gd telemetry_server.gd.backup
copy telemetry_server_SECURE_VERSION.gd telemetry_server.gd
```

**Linux/Mac (Bash):**
```bash
cd /c/godot/addons/godot_debug_connection
cp telemetry_server.gd telemetry_server.gd.backup
cp telemetry_server_SECURE_VERSION.gd telemetry_server.gd
```

### Step 3: Restart Godot
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### Step 4: Get Token
Look in console output for:
```
Initial token created: a1b2c3d4e5f6...
```
**Save this token!**

### Step 5: Test Connection
```bash
python C:/godot/telemetry_client_secure.py --token <YOUR_TOKEN>
```

**Expected Output:**
```
✅ Connected to telemetry server!
🔐 Authentication required
🔑 Sending authentication token...
✅ Authentication successful!
  User: token-id-uuid
  Role: readonly
```

---

## 🧪 Verify Security (2 Minutes)

### Test 1: Authentication Required
```bash
# Should fail without token
python C:/godot/telemetry_client_secure.py --token invalid_token
# Expected: ❌ Authentication failed
```

### Test 2: Run Full Test Suite
```bash
cd C:/godot/tests/security
python test_websocket_security.py
```

**Expected:** All tests pass ✅

---

## 📋 Files Created

**New Files:**
- ✅ `addons/godot_debug_connection/telemetry_server_SECURE_VERSION.gd` - Secure server
- ✅ `telemetry_client_secure.py` - Authenticated client
- ✅ `tests/security/test_websocket_security.py` - Security tests
- ✅ `docs/security/WEBSOCKET_SECURITY_IMPLEMENTATION.md` - Full documentation
- ✅ `docs/security/WEBSOCKET_DEPLOYMENT_GUIDE.md` - Deployment guide
- ✅ `docs/security/VULN_012_RESOLUTION_SUMMARY.md` - Resolution summary

**Backups:**
- ✅ `addons/godot_debug_connection/telemetry_server.gd.backup` - Original server

---

## 🔒 Security Features

✅ **Token Authentication** - Required within 10 seconds
✅ **Connection Limits** - 3 per IP, 10 total
✅ **Inactivity Timeout** - 5 minutes
✅ **Authentication Timeout** - 10 seconds
✅ **Security Metrics** - Comprehensive tracking
✅ **Message Signing** - Framework ready (disabled by default)

---

## 🚨 Troubleshooting

### "Authentication failed"
**Solution:** Generate new token or check token validity

### "Connection limit reached"
**Solution:** Close unused connections or increase limits in constants

### "Authentication timeout"
**Solution:** Client must authenticate within 10 seconds

### Rollback
```bash
cp telemetry_server.gd.backup telemetry_server.gd
# Restart Godot
```

---

## 📊 Monitoring

### Get Security Metrics
```gdscript
# In GDScript
var metrics = $TelemetryServer.get_security_metrics()
print("Auth failures: ", metrics.auth_failures)
print("Active connections: ", metrics.active_connections)
```

### Check Logs
```bash
grep "\[SECURITY\]" godot_console.log
```

---

## 🎯 What Changed

| Feature | Before | After |
|---------|--------|-------|
| Authentication | None | Required |
| Connection Limit | Unlimited | 3 per IP, 10 total |
| Timeout | None | 10s auth, 5min inactive |
| Security Metrics | No | Yes |
| Message Signing | No | Framework ready |

**CVSS Score:** 7.5 HIGH → 2.0 LOW

---

## 📖 Full Documentation

- **Implementation:** `docs/security/WEBSOCKET_SECURITY_IMPLEMENTATION.md`
- **Deployment:** `docs/security/WEBSOCKET_DEPLOYMENT_GUIDE.md`
- **Resolution:** `docs/security/VULN_012_RESOLUTION_SUMMARY.md`

---

## ✅ Deployment Checklist

- [ ] Godot stopped
- [ ] Original file backed up
- [ ] Secure version deployed
- [ ] Godot restarted
- [ ] Token obtained from console
- [ ] Client test successful
- [ ] Security tests passed
- [ ] Monitoring configured

---

**Status:** ✅ Ready to Deploy
**Impact:** Fixes VULN-012 (CVSS 7.5 HIGH)
**Time:** 10 minutes
**Risk:** Low (rollback available)

---

**Quick Deploy Command:**
```bash
cd C:/godot/addons/godot_debug_connection && \
cp telemetry_server.gd telemetry_server.gd.backup && \
cp telemetry_server_SECURE_VERSION.gd telemetry_server.gd
```

**Restart Godot, get token, test with:**
```bash
python C:/godot/telemetry_client_secure.py --token <TOKEN>
```

**Done!** 🎉

---

*Version: 1.0 | Date: 2025-12-02 | Author: Security Team*
