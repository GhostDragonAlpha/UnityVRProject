# TLS Certificates Directory

Place TLS certificates here for HTTPS deployment.

## Development (Self-Signed)

Generate self-signed certificates:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=spacetime.yourdomain.com"
```

Files created:
- `tls.key` - Private key
- `tls.crt` - Certificate

## Production (Let's Encrypt)

Use cert-manager with Kubernetes:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer (edit email)
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

Cert-manager will automatically generate and manage certificates.

## Create Kubernetes Secret

```bash
kubectl create secret tls spacetime-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n spacetime
```

## Verify

```bash
kubectl get secret spacetime-tls -n spacetime
```
