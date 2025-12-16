# Staging Environment Quick Start Guide

## 5-Minute Setup (Docker Compose)

### Prerequisites Check
```bash
# Verify you have required tools
docker --version        # Should be 20.10+
docker-compose --version  # Should be 1.29+
python3 --version       # Should be 3.8+
```

### Start Environment
```bash
cd deploy/staging

# Start all services (takes 2-3 minutes)
docker-compose up -d

# Wait for services to be healthy
sleep 30

# Load test data (takes 1-2 minutes)
pip install psycopg2-binary redis requests
python3 seed_data.py --environment staging

# Run validation
python3 ../../tests/staging/validate_staging.py
```

### Access Services
- **Grafana**: http://localhost:3000 (admin / staging-admin)
- **Prometheus**: http://localhost:9090
- **CockroachDB UI**: http://localhost:8080
- **Kibana**: http://localhost:5601
- **Jaeger**: http://localhost:16686

### Verify Everything Works
```bash
# Test database
cockroach sql --insecure --host=localhost:26257 --database=spacetime_staging \
  --execute="SELECT COUNT(*) FROM players"

# Test Redis
redis-cli -h localhost -p 6379 -a staging-redis-password ping

# Test metrics
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

---

## Kubernetes Quick Start

### Prerequisites
```bash
# Verify kubectl configured
kubectl cluster-info
kubectl get nodes
```

### Deploy
```bash
cd deploy/staging

# Deploy (takes 5-10 minutes)
./deploy_staging.sh kubernetes

# Wait for all pods ready
kubectl wait --for=condition=ready pod --all -n staging --timeout=600s

# Check status
kubectl get all -n staging
```

### Access Services
```bash
# Port forward to access locally
kubectl port-forward -n staging svc/grafana 3000:3000 &
kubectl port-forward -n staging svc/prometheus 9090:9090 &
kubectl port-forward -n staging svc/cockroachdb-public 8080:8080 26257:26257 &

# Or get LoadBalancer IPs
kubectl get svc -n staging
```

### Load Test Data
```bash
# Get database host
DB_HOST=$(kubectl get svc cockroachdb-public -n staging -o jsonpath='{.spec.clusterIP}')

# Load data
python3 seed_data.py \
  --db-host $DB_HOST \
  --redis-host redis-master.staging.svc.cluster.local \
  --redis-password <YOUR_REDIS_PASSWORD>
```

---

## Common Tasks

### View Logs
```bash
# Docker Compose
docker-compose logs -f <service-name>
docker-compose logs -f cockroachdb-0
docker-compose logs -f redis-0

# Kubernetes
kubectl logs -n staging <pod-name> -f
kubectl logs -n staging -l app=cockroachdb -f
```

### Restart Services
```bash
# Docker Compose
docker-compose restart <service-name>

# Kubernetes
kubectl rollout restart deployment/<deployment-name> -n staging
```

### Clean Up
```bash
# Docker Compose (keep data)
docker-compose down

# Docker Compose (remove all data)
docker-compose down -v

# Kubernetes
kubectl delete namespace staging
```

### Run Tests
```bash
# Validation suite
python3 tests/staging/validate_staging.py

# With custom hosts
python3 tests/staging/validate_staging.py \
  --db-host cockroachdb-public.staging.svc.cluster.local \
  --redis-host redis-master.staging.svc.cluster.local
```

---

## Troubleshooting

### Services Won't Start
```bash
# Check logs for errors
docker-compose logs

# Check resource usage
docker stats

# Ensure ports aren't in use
netstat -tlnp | grep -E '(6379|26257|9090|3000)'
```

### Database Connection Failed
```bash
# Verify CockroachDB is running
curl http://localhost:8080/health

# Check initialization completed
docker-compose logs cockroachdb-init

# Try connecting manually
cockroach sql --insecure --host=localhost:26257
```

### Redis Connection Failed
```bash
# Check Redis is running
redis-cli -h localhost -p 6379 -a staging-redis-password ping

# Check Sentinel status
redis-cli -h localhost -p 26379 SENTINEL masters
```

### Metrics Not Showing
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job, health}'

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload
```

---

## Next Steps

1. **Review Documentation**: Read full documentation at `docs/environments/STAGING_ENVIRONMENT.md`
2. **Configure Monitoring**: Set up custom Grafana dashboards
3. **Load Realistic Data**: Adjust seed data parameters for your testing needs
4. **Run Load Tests**: Test performance under realistic load
5. **Integrate with CI/CD**: Set up automated deployments

---

## Support

**Issues?**
- Check full documentation: `docs/environments/STAGING_ENVIRONMENT.md`
- Run diagnostics: `python3 tests/staging/validate_staging.py --export diagnostics.json`
- Contact DevOps: devops@example.com
