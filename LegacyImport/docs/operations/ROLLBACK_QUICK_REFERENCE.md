# Rollback Quick Reference

One-page reference for emergency rollback procedures.

## Emergency? Start Here

### Is Service DOWN?
```bash
bash deploy/rollback/rollback.sh --quick
```
**Recovery time:** < 5 minutes

### Is Data CORRUPTED?
```bash
docker-compose down
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>
```
**Recovery time:** < 30 minutes

### Is Database FAILING?
```bash
bash deploy/rollback/rollback.sh --level 2 --target <backup-id>
```
**Recovery time:** < 15 minutes

### Is it a SECURITY BREACH?
```bash
docker-compose down
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
# STOP - Call security team - DO NOT rollback yet
```

---

## Decision in 30 Seconds

| Symptom | Action |
|---------|--------|
| Service returns 502/503 | `--quick` |
| Error rate > 10% | `--quick` |
| Response time > 5s | `--quick` |
| Database won't start | `--level 2` |
| Data corruption detected | `--level 3` |
| Security breach | ISOLATE + Security team |

---

## Three Rollback Levels

| Level | Time | Use When | Command |
|-------|------|----------|---------|
| **1** | < 5 min | App crash, high errors | `--quick` or `--level 1` |
| **2** | < 15 min | DB issues, config errors | `--level 2 --target <id>` |
| **3** | < 30 min | Data corruption, security | `--level 3 --target <id>` |

---

## Commands

### Check Status
```bash
curl http://localhost:8080/status | jq
docker-compose ps
docker-compose logs --tail=100
```

### Quick Rollback (Level 1)
```bash
bash deploy/rollback/rollback.sh --quick
```

### List Backups
```bash
bash deploy/rollback/rollback.sh --list
```

### Level 2 Rollback
```bash
bash deploy/rollback/rollback.sh --level 2 --target 20251202-143022
```

### Level 3 Recovery
```bash
bash deploy/rollback/rollback.sh --level 3 --target 20251201-120000
```

### Validate
```bash
bash deploy/rollback/validate_rollback.sh
bash deploy/smoke_tests.sh
```

---

## Time Rules

- **2 minutes down?** → Rollback now
- **5 minutes high errors?** → Rollback now
- **15 minutes slow?** → Consider rollback
- **Data corruption?** → Stop immediately, then rollback

---

## Communication Template

```
SUBJECT: [P1] Production Issue - Rollback Initiated

Status: [Service DOWN / High Errors / Data Issue]
Action: Rollback Level [1/2/3] at [TIME]
ETA: [X] minutes to recovery
Impact: [Brief description]

Next update in [X] minutes.
```

---

## Checklist

### Before Rollback
- [ ] Severity assessed
- [ ] Team notified (P1/P2)
- [ ] Backup target identified

### After Rollback
- [ ] Services healthy
- [ ] Validation passed
- [ ] Team notified
- [ ] Incident report created

---

## When in Doubt

**ROLLBACK FIRST, INVESTIGATE LATER**

It's better to rollback and be safe than to wait and hope it fixes itself.

---

## Help

**Full Docs:**
- [ROLLBACK_PROCEDURES.md](ROLLBACK_PROCEDURES.md) - Complete procedures
- [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) - Failure scenarios
- [ROLLBACK_DECISION_TREE.md](ROLLBACK_DECISION_TREE.md) - Decision guide

**Emergency Contact:** [On-call phone/pager]

**Slack:** #incidents

---

**Keep this page bookmarked for emergencies!**
