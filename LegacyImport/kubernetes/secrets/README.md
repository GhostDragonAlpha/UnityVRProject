# Kubernetes Secrets - Quick Reference

## Files in This Directory

| File | Purpose | Git Status |
|------|---------|-----------|
| `production-secrets.yaml` | Actual production secrets with real values | ❌ NOT committed (excluded by .gitignore) |
| `production-secrets-template.yaml` | Template with placeholders for reference | ✅ Safe to commit |
| `README.md` | This file | ✅ Safe to commit |

## Quick Deploy

### Deploy All Secrets
```bash
# Create namespaces first
kubectl create namespace spacetime --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace planetary-survival --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

# Deploy secrets
kubectl apply -f production-secrets.yaml

# Verify
kubectl get secrets -n spacetime
kubectl get secrets -n planetary-survival
kubectl get secrets -n staging
```

### Deploy Individual Secret
```bash
# Deploy only spacetime-secrets
kubectl apply -f - <<EOF
$(kubectl create secret generic spacetime-secrets \
  --from-literal=API_TOKEN="$(cat ../../certs/api_token.txt | tr -d '\n')" \
  --from-literal=JWT_SECRET="$(cat ../../certs/jwt_secret.txt | tr -d '\n')" \
  --from-literal=REDIS_PASSWORD="$(cat ../../certs/redis_password.txt | tr -d '\n')" \
  --from-literal=GRAFANA_ADMIN_PASSWORD="$(cat ../../certs/grafana_password.txt | tr -d '\n')" \
  --from-literal=POSTGRES_PASSWORD="$(cat ../../certs/postgres_password.txt | tr -d '\n')" \
  -n spacetime --dry-run=client -o yaml)
EOF
```

### Deploy TLS Certificate
```bash
# From certificate files
kubectl create secret tls spacetime-tls \
  --cert=../../certs/spacetime.crt \
  --key=../../certs/spacetime.key \
  -n spacetime

# Or apply from production-secrets.yaml (TLS secret is included)
kubectl apply -f production-secrets.yaml
```

## Verify Deployment

```bash
# Check secrets exist
kubectl get secrets -A | grep -E "spacetime|planetary-survival|staging"

# Describe a secret (values are hidden)
kubectl describe secret spacetime-secrets -n spacetime

# Verify TLS certificate
kubectl get secret spacetime-tls -n spacetime -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -text

# Check certificate expiry
kubectl get secret spacetime-tls -n spacetime -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -enddate
```

## Troubleshooting

### Secret Not Found
```bash
# List all secrets in namespace
kubectl get secrets -n spacetime

# Check if secret was applied
kubectl get events -n spacetime | grep secret
```

### Wrong Values
```bash
# Delete and recreate
kubectl delete secret spacetime-secrets -n spacetime
kubectl apply -f production-secrets.yaml
```

### Pod Can't Access Secret
```bash
# Check pod logs
kubectl logs <pod-name> -n spacetime

# Verify secret is mounted
kubectl describe pod <pod-name> -n spacetime | grep -A 10 "Mounts:"

# Check RBAC permissions
kubectl auth can-i get secrets --as=system:serviceaccount:spacetime:default -n spacetime
```

## Security Notes

- **NEVER** commit `production-secrets.yaml` to Git
- **ALWAYS** use the template file for version control
- **RESTRICT** access to secrets using Kubernetes RBAC
- **ROTATE** secrets every 90 days
- **MONITOR** secret access in audit logs

## Additional Resources

- Full documentation: `../../PRODUCTION_SECRETS_READY.md`
- Project setup: `../../CLAUDE.md`
- Certificate generation: See "Production Certificate Upgrade Path" in PRODUCTION_SECRETS_READY.md
