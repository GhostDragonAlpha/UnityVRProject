# Staging Environment Documentation

## Overview

The staging environment is a complete replica of the production environment, designed for pre-production testing, validation, and quality assurance. It mirrors production infrastructure, configuration, security settings, and performance characteristics while being completely isolated.

**Purpose:**
- Pre-production testing and validation
- Integration testing with production-like infrastructure
- Performance testing and load testing
- Security testing and penetration testing
- Training and demonstration
- Disaster recovery testing

**Environment:** `staging`
**Namespace (Kubernetes):** `staging`
**Network:** Isolated from production

---

## Architecture

### Infrastructure Components

The staging environment includes all production components:

#### Databases

**CockroachDB Cluster**
- **Nodes:** 3 (mirroring production topology)
- **Storage:** 50GB per node (50% of production)
- **Resources:** 1-2 CPU, 4-8GB RAM per node
- **Configuration:** Identical to production
  - Serializable isolation level
  - Query execution logging enabled
  - Performance statistics enabled
  - Slow query logging (100ms threshold)

**Redis Cluster**
- **Nodes:** 3 (1 master, 2 replicas)
- **Storage:** 10GB per node
- **Resources:** 250-500m CPU, 1-2GB RAM per node
- **Sentinel:** High availability with automatic failover
- **Configuration:**
  - AOF persistence with `appendfsync always`
  - Debug logging enabled
  - Lower latency monitoring thresholds (50ms)

#### Monitoring Stack

**Prometheus**
- **Storage:** 50GB (15 days retention)
- **Resources:** 500m-1 CPU, 2-4GB RAM
- **Scrape Interval:** 15s
- **Configuration:** Enhanced logging, staging-specific rules

**Grafana**
- **Storage:** 5GB
- **Resources:** 250-500m CPU, 512MB-1GB RAM
- **Datasources:**
  - Prometheus (metrics)
  - Jaeger (traces)
  - Elasticsearch (logs)

**ELK Stack (Logging)**
- **Elasticsearch:** Single-node cluster, 8.11.1
- **Logstash:** Log processing pipeline
- **Kibana:** Log visualization and analysis

**Jaeger (Tracing)**
- **All-in-one deployment**
- **OTLP collector enabled**
- **Zipkin compatibility**

---

## Deployment

### Prerequisites

**Required Tools:**
- `kubectl` (for Kubernetes deployment)
- `docker` and `docker-compose` (for local deployment)
- `python3` (for seed data and validation)
- `curl` or `wget` (for health checks)

**Python Dependencies:**
```bash
pip install psycopg2-binary redis requests
```

### Kubernetes Deployment

**Deploy to Kubernetes cluster:**

```bash
# Deploy entire staging environment
cd deploy/staging
./deploy_staging.sh kubernetes

# Dry run to preview changes
DRY_RUN=true ./deploy_staging.sh kubernetes

# Skip smoke tests
SKIP_TESTS=true ./deploy_staging.sh kubernetes

# Skip seed data loading
LOAD_SEED_DATA=false ./deploy_staging.sh kubernetes
```

**Manual deployment steps:**

```bash
# 1. Create namespace and apply resource limits
kubectl apply -f kubernetes/namespace.yaml

# 2. Apply secrets (use sealed-secrets in production)
kubectl apply -f kubernetes/secrets.yaml

# 3. Deploy CockroachDB
kubectl apply -f kubernetes/cockroachdb.yaml
kubectl wait --for=condition=ready pod -l app=cockroachdb -n staging --timeout=300s

# 4. Deploy Redis
kubectl apply -f kubernetes/redis.yaml
kubectl wait --for=condition=ready pod -l app=redis -n staging --timeout=300s

# 5. Deploy monitoring
kubectl apply -f kubernetes/monitoring.yaml
kubectl wait --for=condition=available deployment/prometheus -n staging --timeout=300s
kubectl wait --for=condition=available deployment/grafana -n staging --timeout=300s

# 6. Verify deployment
kubectl get all -n staging
```

### Local Docker Compose Deployment

**Deploy locally with Docker Compose:**

```bash
cd deploy/staging

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

**Quick health check:**

```bash
# CockroachDB
curl http://localhost:8080/health

# Redis
redis-cli -a staging-redis-password ping

# Prometheus
curl http://localhost:9090/-/healthy

# Grafana
curl http://localhost:3000/api/health

# Elasticsearch
curl http://localhost:9200/_cluster/health
```

---

## Configuration

### Environment Variables

Staging-specific configuration is managed via ConfigMap and secrets:

**Key Configuration (from `staging-config` ConfigMap):**

```yaml
ENVIRONMENT: "staging"
DEBUG_MODE: "true"
VERBOSE_LOGGING: "true"
PERFORMANCE_PROFILING: "true"
ENABLE_METRICS: "true"
LOG_LEVEL: "debug"

# Feature flags
ENABLE_EXPERIMENTAL_FEATURES: "true"
MOCK_EXTERNAL_SERVICES: "true"

# Performance
MAX_PLAYERS_PER_SERVER: "50"
PHYSICS_TICK_RATE: "90"

# Security
RATE_LIMIT_ENABLED: "true"
RATE_LIMIT_REQUESTS_PER_MINUTE: "1000"
SESSION_TIMEOUT_MINUTES: "60"

# Testing
ENABLE_TEST_ENDPOINTS: "true"
ALLOW_TEST_ACCOUNTS: "true"
SKIP_EXTERNAL_VALIDATIONS: "true"
```

### Secrets Management

**Staging secrets should be:**
- Different from production credentials
- Managed via sealed-secrets or external secret manager
- Never committed to version control

**Required secrets:**
- `database-credentials`: CockroachDB and Redis passwords
- `game-server-config`: JWT secrets, API keys, encryption keys
- `monitoring-credentials`: Prometheus, Grafana credentials

---

## Seed Data

### Loading Test Data

Staging environment includes realistic test data for comprehensive testing:

```bash
# Load default seed data (100 players, 500 sessions)
python3 deploy/staging/seed_data.py --environment staging

# Custom data generation
python3 deploy/staging/seed_data.py \
  --environment staging \
  --num-players 500 \
  --num-sessions 2000 \
  --num-security-events 100

# For Kubernetes deployment
python3 deploy/staging/seed_data.py \
  --environment staging \
  --db-host cockroachdb-public.staging.svc.cluster.local \
  --redis-host redis-master.staging.svc.cluster.local \
  --redis-password <REDIS_PASSWORD>
```

### Generated Data

**Players:**
- Randomized usernames, emails, VR headsets
- Varying levels (1-50) and credits
- Realistic play time and preferences
- Test accounts for various scenarios

**Game Sessions:**
- Sessions spanning 5 minutes to 4 hours
- FPS metrics (70-95 avg, with variation)
- Multiple star systems and locations
- Achievement tracking

**Security Events:**
- Login attempts (success/failure)
- Suspicious activity patterns
- Rate limiting events
- API abuse scenarios

**Performance Metrics:**
- CPU and memory usage over 24 hours
- Active player counts
- FPS statistics
- Network latency data

**Redis Cache:**
- Active session data
- Leaderboards with sample scores
- Rate limiting counters
- Player online status

---

## Validation

### Running Validation Suite

Comprehensive validation ensures staging mirrors production:

```bash
# Run full validation suite
python3 tests/staging/validate_staging.py

# Export results
python3 tests/staging/validate_staging.py --export validation_results.json

# For Kubernetes
python3 tests/staging/validate_staging.py \
  --db-host cockroachdb-public.staging.svc.cluster.local \
  --redis-host redis-master.staging.svc.cluster.local \
  --prometheus-url http://prometheus.staging.svc.cluster.local:9090 \
  --grafana-url http://grafana.staging.svc.cluster.local:3000
```

### Validation Tests

**1. Database Connectivity**
- CockroachDB cluster health
- All 3 nodes alive and responsive
- Version verification

**2. Redis Connectivity**
- Redis master and replicas operational
- Sentinel failover configured
- Read/write operations functional

**3. Monitoring Stack**
- Prometheus healthy and scraping metrics
- Grafana accessible with configured datasources
- Alert rules loaded

**4. Performance SLAs**
- Database latency < 100ms
- Redis latency < 10ms
- Network throughput adequate

**5. Data Integrity**
- Referential integrity maintained
- No orphaned records
- Consistent data across replicas

**6. Security Configuration**
- Transaction isolation level: serializable
- Redis protected mode enabled
- Authentication configured

**7. Backup Configuration**
- Backup tools accessible
- Proper permissions configured
- Backup schedules active

**8. Monitoring Alerts**
- Alert rules configured and active
- Notification channels set up
- Test alerts firing correctly

### Expected Results

All validations should pass:
```
========================================================================
VALIDATION SUMMARY
========================================================================

Total Tests: 8
Passed: 8
Failed: 0
Success Rate: 100.0%
```

---

## Access Points

### Kubernetes Deployment

Access services via `kubectl port-forward` or LoadBalancer IPs:

```bash
# Port forward Grafana
kubectl port-forward -n staging svc/grafana 3000:3000

# Port forward Prometheus
kubectl port-forward -n staging svc/prometheus 9090:9090

# Port forward CockroachDB
kubectl port-forward -n staging svc/cockroachdb-public 26257:26257 8080:8080

# Access via browser
open http://localhost:3000  # Grafana
open http://localhost:9090  # Prometheus
open http://localhost:8080  # CockroachDB UI
```

### Docker Compose Deployment

Direct access on localhost:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / staging-admin |
| **Prometheus** | http://localhost:9090 | - |
| **CockroachDB UI** | http://localhost:8080 | - |
| **Kibana** | http://localhost:5601 | - |
| **Jaeger UI** | http://localhost:16686 | - |
| **CockroachDB SQL** | localhost:26257 | staging_user |
| **Redis** | localhost:6379 | staging-redis-password |

---

## Testing Procedures

### Integration Testing

**1. Database Operations**
```bash
# Connect to CockroachDB
cockroach sql --insecure --host=localhost:26257 --database=spacetime_staging

# Run test queries
SELECT COUNT(*) FROM players;
SELECT COUNT(*) FROM game_sessions;
SELECT * FROM players LIMIT 10;
```

**2. Cache Operations**
```bash
# Connect to Redis
redis-cli -h localhost -p 6379 -a staging-redis-password

# Test commands
PING
GET player:session:test
KEYS *
INFO
```

**3. Monitoring Queries**
```bash
# Query Prometheus
curl -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up'

# Check metrics
curl http://localhost:8080/_status/vars  # CockroachDB metrics
```

### Load Testing

Generate load to test performance:

```python
# Example load test script
import concurrent.futures
import psycopg2
import redis
import time

def db_load_test():
    conn = psycopg2.connect(
        host="localhost",
        port=26257,
        database="spacetime_staging",
        user="staging_user"
    )
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM players LIMIT 100")
    cursor.fetchall()
    conn.close()

def redis_load_test():
    client = redis.Redis(
        host="localhost",
        password="staging-redis-password"
    )
    client.ping()
    client.get("test_key")

# Run concurrent load
with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
    futures = [executor.submit(db_load_test) for _ in range(100)]
    concurrent.futures.wait(futures)
```

### Disaster Recovery Testing

**Test database failover:**

```bash
# Kill CockroachDB node
docker-compose stop cockroachdb-1

# Verify cluster still operational
curl http://localhost:8080/health

# Verify automatic recovery
docker-compose start cockroachdb-1
```

**Test Redis failover:**

```bash
# Kill Redis master
docker-compose stop redis-0

# Check sentinel promotion
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

---

## Monitoring and Alerting

### Grafana Dashboards

**Pre-configured dashboards:**
- **Staging Overview**: Environment health at a glance
- **Database Performance**: CockroachDB metrics
- **Redis Performance**: Cache hit rates, memory usage
- **Application Metrics**: Game server performance
- **System Resources**: CPU, memory, disk, network

### Prometheus Alerts

**Configured alerts:**
- Database node down (critical)
- Redis instance down (critical)
- High CPU usage > 80% for 5 minutes (warning)
- High memory usage > 90% for 5 minutes (warning)
- Low FPS < 60 for 2 minutes (warning)
- Disk space < 10% (warning)

**View active alerts:**
```bash
curl http://localhost:9090/api/v1/alerts
```

### Log Analysis

**View logs in Kibana:**
1. Open http://localhost:5601
2. Navigate to Discover
3. Create index pattern: `logs-staging-*`
4. Query logs with KQL or Lucene syntax

**Example queries:**
```
level: ERROR
service: game-server AND level: WARNING
message: "connection refused"
```

---

## Differences from Production

While staging mirrors production, there are intentional differences:

### Resource Allocation

| Component | Production | Staging | Ratio |
|-----------|-----------|---------|-------|
| **CockroachDB Storage** | 100GB/node | 50GB/node | 50% |
| **CockroachDB CPU** | 2-4 cores | 1-2 cores | 50% |
| **Redis Storage** | 20GB/node | 10GB/node | 50% |
| **Prometheus Retention** | 30 days | 15 days | 50% |

### Configuration Differences

**Debug and Logging:**
- More verbose logging (DEBUG level)
- Performance profiling enabled
- Query execution tracing enabled
- Slow query threshold lower (100ms vs 500ms)

**Security:**
- Test accounts allowed
- External validation skipped
- Mock external services enabled
- More permissive rate limits

**Features:**
- Experimental features enabled
- Test endpoints exposed
- Debug tools accessible

### Data Isolation

**Complete isolation from production:**
- Separate database cluster
- Separate Redis cluster
- Separate network namespace
- Different credentials
- Different domain names

---

## Troubleshooting

### Common Issues

**1. Services Not Starting**

```bash
# Check logs
docker-compose logs <service-name>
kubectl logs -n staging <pod-name>

# Check resource availability
docker stats
kubectl top nodes
kubectl top pods -n staging
```

**2. Database Connection Issues**

```bash
# Verify CockroachDB is ready
curl http://localhost:8080/health?ready=1

# Check cluster status
cockroach sql --insecure --host=localhost --execute="SHOW DATABASES"

# Check for network issues
kubectl exec -it -n staging cockroachdb-0 -- /cockroach/cockroach node status --insecure
```

**3. Redis Connection Issues**

```bash
# Test Redis connectivity
redis-cli -h localhost -p 6379 -a staging-redis-password ping

# Check sentinel status
redis-cli -p 26379 SENTINEL masters

# View Redis logs
docker-compose logs redis-0
```

**4. Monitoring Stack Issues**

```bash
# Verify Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Grafana datasources
curl -u admin:staging-admin http://localhost:3000/api/datasources

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload
```

**5. Performance Issues**

```bash
# Check resource usage
docker stats
kubectl top pods -n staging

# Verify database performance
cockroach sql --insecure --execute="SHOW STATISTICS FOR TABLE players"

# Check Redis memory
redis-cli -a staging-redis-password INFO memory
```

### Getting Help

**Diagnostic commands:**

```bash
# Full system status
./deploy/staging/deploy_staging.sh kubernetes 2>&1 | tee deployment.log

# Run validation with detailed output
python3 tests/staging/validate_staging.py --export diagnostics.json

# Export metrics
curl http://localhost:9090/api/v1/query?query=up > metrics.json
```

**Support channels:**
- Engineering team: engineering@example.com
- DevOps team: devops@example.com
- On-call: Use incident management system

---

## Maintenance

### Regular Tasks

**Daily:**
- Monitor resource usage
- Review error logs
- Check alert status

**Weekly:**
- Run validation suite
- Review performance metrics
- Update test data

**Monthly:**
- Update Docker images
- Review and update seed data
- Perform disaster recovery drill
- Review resource allocation

### Updating Staging

**Update application:**

```bash
# Kubernetes
kubectl set image deployment/<deployment-name> \
  <container-name>=<new-image>:<tag> \
  -n staging

# Docker Compose
docker-compose pull
docker-compose up -d
```

**Database migrations:**

```bash
# Run migrations
python3 migrations/migrate.py --environment staging

# Verify migration
cockroach sql --insecure --execute="SHOW TABLES"
```

**Configuration updates:**

```bash
# Update ConfigMap
kubectl edit configmap staging-config -n staging

# Restart pods to pick up changes
kubectl rollout restart deployment -n staging
```

### Cleanup

**Remove old data:**

```bash
# Clean up old test data (older than 30 days)
cockroach sql --insecure --execute="
  DELETE FROM game_sessions WHERE started_at < NOW() - INTERVAL '30 days';
  DELETE FROM security_events WHERE created_at < NOW() - INTERVAL '30 days';
"

# Clean Redis cache
redis-cli -a staging-redis-password FLUSHDB
```

**Reset environment:**

```bash
# Kubernetes
kubectl delete namespace staging
./deploy/staging/deploy_staging.sh kubernetes

# Docker Compose
docker-compose down -v
docker-compose up -d
python3 deploy/staging/seed_data.py
```

---

## Best Practices

### Testing in Staging

**DO:**
- Test all changes before production deployment
- Run full validation suite after deployments
- Monitor performance during load tests
- Test disaster recovery procedures regularly
- Keep staging synchronized with production config

**DON'T:**
- Use production credentials or secrets
- Deploy untested changes to production
- Allow direct access from public internet
- Mix staging and production data
- Skip validation steps

### Data Management

**DO:**
- Refresh seed data regularly (weekly)
- Use realistic test data volumes
- Test with various user scenarios
- Include edge cases in test data

**DON'T:**
- Use real user data (PII concerns)
- Let data grow unbounded
- Ignore data cleanup procedures
- Test with empty databases

### Security

**DO:**
- Use separate credentials for staging
- Apply same security policies as production
- Test security features and vulnerabilities
- Keep staging isolated from production network

**DON'T:**
- Expose staging publicly without authentication
- Use production secrets in staging
- Skip security testing in staging
- Allow unrestricted access

---

## CI/CD Integration

### Automated Deployment

**Trigger on `develop` branch merge:**

```yaml
# .github/workflows/staging-deploy.yml
name: Deploy to Staging
on:
  push:
    branches: [develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to staging
        run: |
          ./deploy/staging/deploy_staging.sh kubernetes

      - name: Run validation
        run: |
          python3 tests/staging/validate_staging.py

      - name: Notify team
        if: failure()
        run: |
          # Send notification to Slack/email
```

### Smoke Tests

Automated smoke tests run after each deployment:

```bash
# Included in deploy_staging.sh
python3 tests/staging/validate_staging.py

# Exit code 0 = success, 1 = failure
```

---

## Appendix

### Service Ports Reference

**CockroachDB:**
- 26257: SQL interface
- 8080: Admin UI and metrics

**Redis:**
- 6379: Redis server
- 26379: Sentinel
- 9121: Metrics (exporter)

**Monitoring:**
- 9090: Prometheus
- 3000: Grafana
- 9200: Elasticsearch
- 5601: Kibana
- 16686: Jaeger UI
- 5000: Logstash

### Resource Requirements

**Minimum (Docker Compose):**
- CPU: 8 cores
- RAM: 32GB
- Disk: 200GB SSD

**Recommended (Kubernetes):**
- Nodes: 3-5 worker nodes
- CPU: 32 cores total
- RAM: 128GB total
- Disk: 500GB SSD per node

### Related Documentation

- [Production Environment](./PRODUCTION_ENVIRONMENT.md)
- [Deployment Guide](../operations/DEPLOYMENT.md)
- [Monitoring Guide](../operations/MONITORING.md)
- [Disaster Recovery](../operations/DISASTER_RECOVERY.md)
- [Security Policies](../security/SECURITY_POLICIES.md)

---

**Last Updated:** 2024-12-02
**Version:** 1.0.0
**Maintained By:** DevOps Team
