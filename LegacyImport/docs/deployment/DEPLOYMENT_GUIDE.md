# SpaceTime VR - Comprehensive Deployment Guide

Complete guide for deploying SpaceTime VR to development, staging, and production environments with automated CI/CD pipelines.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Methods](#deployment-methods)
- [Environment Setup](#environment-setup)
- [Manual Deployment](#manual-deployment)
- [Automated Deployment (CI/CD)](#automated-deployment-cicd)
- [Blue-Green Deployment](#blue-green-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Infrastructure as Code (Terraform)](#infrastructure-as-code-terraform)
- [Server Configuration (Ansible)](#server-configuration-ansible)
- [Health Checks and Monitoring](#health-checks-and-monitoring)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## Overview

SpaceTime VR supports multiple deployment strategies:

1. **Local Development** - Docker Compose for local testing
2. **Staging Environment** - Automated deployment on code push
3. **Production Environment** - Blue-green deployment with manual approval
4. **Kubernetes** - Scalable production deployment on K8s clusters
5. **Cloud Infrastructure** - Terraform-managed AWS infrastructure

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Code Repository                      │
│                    (GitHub)                             │
└───────────────────┬─────────────────────────────────────┘
                    │
         ┌──────────┴──────────┐
         │  GitHub Actions     │
         │  CI/CD Pipeline     │
         └──────────┬──────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
┌───┴────┐    ┌────┴─────┐    ┌───┴────┐
│ Build  │    │  Tests   │    │Security│
│ Docker │    │ (57+)    │    │ Scan   │
│ Image  │    │          │    │        │
└───┬────┘    └────┬─────┘    └───┬────┘
    │              │              │
    └──────────────┴──────────────┘
                   │
         ┌─────────┴──────────┐
         │  Container         │
         │  Registry (GHCR)   │
         └─────────┬──────────┘
                   │
    ┌──────────────┴───────────────┐
    │                              │
┌───┴────────┐            ┌────────┴───┐
│  Staging   │            │ Production │
│  Auto      │            │  Manual    │
│  Deploy    │            │  Approval  │
└────────────┘            └────────────┘
```

## Prerequisites

### Required Tools

```bash
# Docker and Docker Compose
docker --version  # >= 24.0.0
docker-compose --version  # >= 2.20.0

# Kubernetes tools (for K8s deployment)
kubectl version  # >= 1.28.0
kustomize version  # >= 5.0.0

# Terraform (for infrastructure)
terraform version  # >= 1.5.0

# Ansible (for server configuration)
ansible --version  # >= 2.15.0

# GitHub CLI (for workflow management)
gh --version  # >= 2.30.0

# Other utilities
jq --version  # JSON processing
curl --version  # HTTP requests
```

### Access Requirements

- **GitHub Repository**: Write access for CI/CD workflows
- **Container Registry**: Push access to GHCR or Docker Hub
- **Cloud Provider**: AWS credentials (for Terraform)
- **SSH Access**: SSH keys for deployment servers
- **DNS**: Access to manage DNS records

### Environment Variables

Create `.env.production` and `.env.staging` files:

```bash
# API Configuration
API_PORT=8080
TELEMETRY_PORT=8081
DAP_PORT=6006
LSP_PORT=6005

# Security
API_TOKEN=your-secure-token-here
JWT_SECRET=your-jwt-secret-here

# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=spacetime
POSTGRES_USER=spacetime
POSTGRES_PASSWORD=secure-password-here

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis-password-here

# Monitoring
PROMETHEUS_ENABLED=true
GRAFANA_ENABLED=true

# Deployment
ENVIRONMENT=production
DEPLOYMENT_ID=$(date +%Y%m%d-%H%M%S)
```

## Deployment Methods

### 1. Local Development Deployment

Quick deployment for development and testing:

```bash
# Start all services
docker-compose -f docker-compose.v2.5.yml up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 2. Staging Deployment

Automated deployment to staging environment:

```bash
# Deploy to staging (triggered automatically on push to main/develop)
# Or trigger manually:
gh workflow run deploy.yml \
  -f environment=staging \
  -f image_tag=latest
```

### 3. Production Deployment

Manual deployment with approval:

```bash
# Trigger production deployment
gh workflow run deploy.yml \
  -f environment=production \
  -f image_tag=v2.5.0

# Approve deployment in GitHub UI
# Visit: https://github.com/your-org/your-repo/actions

# Monitor deployment
gh run watch
```

## Environment Setup

### Development Environment

```bash
cd C:/godot

# Create .env file
cp .env.example .env

# Edit configuration
nano .env

# Start services
docker-compose up -d

# Verify
curl http://localhost:8080/status
```

### Staging Environment

```bash
# Configure staging environment
export ENVIRONMENT=staging
export IMAGE_TAG=latest

# Deploy
cd deploy
bash deploy.sh
```

### Production Environment

```bash
# Configure production environment
export ENVIRONMENT=production
export IMAGE_TAG=v2.5.0
export DEPLOYMENT_ID=$(date +%Y%m%d-%H%M%S)

# Run pre-flight checks
bash deploy/health_check.sh --url https://spacetime.example.com
bash deploy/security_validation.sh --url https://spacetime.example.com

# Deploy
bash deploy/deploy.sh
```

## Manual Deployment

### Step-by-Step Manual Deployment

1. **Pre-Deployment Checks**

```bash
cd C:/godot/deploy

# Verify deployment scripts
ls -la *.sh

# Check prerequisites
docker --version
docker-compose --version
jq --version

# Verify configuration files
ls -la ../.env.production
ls -la ../docker-compose.production.yml
```

2. **Backup Current System**

```bash
# Create backup
export DEPLOYMENT_ID=$(date +%Y%m%d-%H%M%S)
mkdir -p ../backups/${DEPLOYMENT_ID}

# Backup current state
docker-compose ps > ../backups/${DEPLOYMENT_ID}/containers.txt
docker-compose config > ../backups/${DEPLOYMENT_ID}/docker-compose.yml
docker-compose logs --tail=1000 > ../backups/${DEPLOYMENT_ID}/logs.txt
```

3. **Pull New Image**

```bash
# Pull latest image
export IMAGE_TAG=v2.5.0
docker pull ghcr.io/your-org/spacetime:${IMAGE_TAG}

# Verify image
docker images | grep spacetime
```

4. **Deploy New Version**

```bash
# Run deployment script
export ENVIRONMENT=production
bash deploy.sh

# The script will:
# - Check prerequisites
# - Create backup
# - Pull new image
# - Stop old containers
# - Start new containers
# - Run health checks
# - Run smoke tests
```

5. **Verify Deployment**

```bash
# Check container status
docker-compose ps

# Run health checks
bash health_check.sh --url http://localhost:8080 --verbose

# Run security validation
bash security_validation.sh --url http://localhost:8080

# Run smoke tests
bash smoke_tests.sh
```

6. **Monitor Deployment**

```bash
# Watch logs
docker-compose logs -f

# Check metrics
curl http://localhost:9090/metrics

# Monitor Grafana
open http://localhost:3000
```

## Automated Deployment (CI/CD)

### GitHub Actions Workflows

The project includes comprehensive CI/CD workflows:

1. **test.yml** - Runs all tests on push/PR
2. **security-scan.yml** - Security scanning
3. **build.yml** - Builds and publishes Docker images
4. **deploy.yml** - Automated deployment pipeline

### Triggering Deployments

**Automatic Triggers:**

- Push to `main` → Deploy to staging
- Push to `develop` → Deploy to staging
- Tag `v*.*.*` → Deploy to production (with approval)

**Manual Triggers:**

```bash
# Deploy specific version to staging
gh workflow run deploy.yml \
  -f environment=staging \
  -f image_tag=main-abc1234

# Deploy to production
gh workflow run deploy.yml \
  -f environment=production \
  -f image_tag=v2.5.0 \
  -f skip_approval=false

# Emergency deployment (skip approval)
gh workflow run deploy.yml \
  -f environment=production \
  -f image_tag=v2.5.0 \
  -f skip_approval=true
```

### Workflow Configuration

Edit `.github/workflows/deploy.yml` to customize:

```yaml
# Example: Change approval requirement
deployment-approval:
  if: ${{ inputs.skip_approval == 'false' }}
  environment:
    name: production-approval

# Example: Add Slack notifications
- name: Notify Slack
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Deployment to ${{ inputs.environment }} completed!"
      }
```

## Blue-Green Deployment

Blue-green deployment enables zero-downtime updates with instant rollback capability.

### Architecture

```
┌─────────────────────────────────────────┐
│           Load Balancer (Nginx)         │
│              Active: BLUE               │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───┴────┐         ┌────┴───┐
│  BLUE  │ ←──┐    │ GREEN  │
│ Active │    │    │Standby │
│ v2.4.9 │    │    │ v2.5.0 │
└────────┘    │    └────────┘
              │
         Switch Traffic
```

### Using Blue-Green Deployment

1. **Initial State** (Blue active):

```bash
# Check current state
cd C:/godot/deploy
bash blue-green-switch.sh status

# Output:
# Active Environment: blue
# Blue Environment: Running, Healthy, ACTIVE
# Green Environment: Not Running
```

2. **Deploy New Version** (to Green):

```bash
# Start green environment with new version
export ENVIRONMENT=production
export IMAGE_TAG=v2.5.0
export DEPLOYMENT_COLOR=green

# Use blue-green compose file
docker-compose -f docker-compose.blue-green.yml up -d godot-green

# Wait for green to be healthy
docker-compose ps godot-green
```

3. **Validate Green Environment**:

```bash
# Run health checks on green
docker exec spacetime-godot-green curl http://localhost:8080/status

# Run smoke tests
TEST_URL=http://spacetime-godot-green:8080 bash smoke_tests.sh
```

4. **Switch Traffic** (instant cutover):

```bash
# Instant switch to green
bash blue-green-switch.sh green

# Or gradual canary deployment
bash blue-green-switch.sh canary-green
```

5. **Monitor and Rollback if Needed**:

```bash
# Monitor green environment
docker-compose logs -f godot-green

# If issues detected, instantly rollback to blue
bash blue-green-switch.sh blue
```

6. **Cleanup Old Environment**:

```bash
# After confirming green is stable, stop blue
docker-compose stop godot-blue

# Or keep blue running as backup for 24 hours
```

### Canary Deployment

Gradual traffic shift from blue to green:

```bash
# Start canary deployment
bash blue-green-switch.sh canary-green

# The script will:
# 1. Route 10% traffic to green (monitor 2 min)
# 2. Route 25% traffic to green (monitor 2 min)
# 3. Route 50% traffic to green (monitor 2 min)
# 4. Route 75% traffic to green (monitor 2 min)
# 5. Route 100% traffic to green
#
# Auto-rollback if any health check fails
```

## Kubernetes Deployment

Deploy to Kubernetes for production-scale workloads.

### Prerequisites

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Configure kubectl
export KUBECONFIG=~/.kube/config
kubectl cluster-info
```

### Deploy to Kubernetes

1. **Create Namespace**:

```bash
kubectl apply -f deploy/kubernetes/base/namespace.yaml
```

2. **Create Secrets**:

```bash
# Create secrets from .env file
kubectl create secret generic spacetime-secrets \
  --from-env-file=.env.production \
  -n spacetime

# Or create manually
kubectl create secret generic spacetime-secrets \
  --from-literal=api-token='your-token' \
  --from-literal=jwt-secret='your-secret' \
  --from-literal=db-password='db-password' \
  -n spacetime
```

3. **Deploy Application**:

```bash
# Using kustomize for production
kubectl apply -k deploy/kubernetes/production/

# Or for staging
kubectl apply -k deploy/kubernetes/staging/
```

4. **Verify Deployment**:

```bash
# Check pods
kubectl get pods -n spacetime

# Check services
kubectl get svc -n spacetime

# Check ingress
kubectl get ingress -n spacetime

# View logs
kubectl logs -f deployment/spacetime-godot -n spacetime
```

5. **Scale Deployment**:

```bash
# Manual scaling
kubectl scale deployment spacetime-godot --replicas=5 -n spacetime

# Auto-scaling is configured via HPA
kubectl get hpa -n spacetime
```

### Update Kubernetes Deployment

```bash
# Update image tag
cd deploy/kubernetes/production
kustomize edit set image spacetime=ghcr.io/your-org/spacetime:v2.5.1

# Apply changes (rolling update)
kubectl apply -k .

# Monitor rollout
kubectl rollout status deployment/spacetime-godot -n spacetime

# Rollback if needed
kubectl rollout undo deployment/spacetime-godot -n spacetime
```

### Kubernetes Troubleshooting

```bash
# Describe pod issues
kubectl describe pod <pod-name> -n spacetime

# View events
kubectl get events -n spacetime --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n spacetime
kubectl top nodes

# Debug with shell
kubectl exec -it <pod-name> -n spacetime -- /bin/bash

# View all resources
kubectl get all -n spacetime
```

## Infrastructure as Code (Terraform)

Manage cloud infrastructure with Terraform.

### Initialize Terraform

```bash
cd C:/godot/deploy/terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file="environments/production/terraform.tfvars"
```

### Deploy Infrastructure

1. **Set Required Variables**:

```bash
# Set sensitive variables via environment
export TF_VAR_db_password="secure-db-password"
export TF_VAR_redis_auth_token="secure-redis-token"
export TF_VAR_api_token="secure-api-token"
export TF_VAR_jwt_secret="secure-jwt-secret"
```

2. **Review Plan**:

```bash
# Generate execution plan
terraform plan \
  -var-file="environments/production/terraform.tfvars" \
  -out=tfplan

# Review what will be created
terraform show tfplan
```

3. **Apply Changes**:

```bash
# Apply infrastructure changes
terraform apply tfplan

# Confirm by typing 'yes'
```

4. **View Outputs**:

```bash
# Get deployment outputs
terraform output

# Get specific output
terraform output eks_cluster_endpoint
terraform output database_endpoint
```

### Update Infrastructure

```bash
# Make changes to .tf files or .tfvars

# Plan changes
terraform plan -var-file="environments/production/terraform.tfvars"

# Apply changes
terraform apply -var-file="environments/production/terraform.tfvars"
```

### Destroy Infrastructure

```bash
# ⚠️ WARNING: This will destroy all infrastructure!

# Plan destruction
terraform plan -destroy -var-file="environments/production/terraform.tfvars"

# Destroy (requires confirmation)
terraform destroy -var-file="environments/production/terraform.tfvars"
```

## Server Configuration (Ansible)

Configure servers with Ansible playbooks.

### Setup Ansible

```bash
cd C:/godot/deploy/ansible

# Install Ansible
pip install ansible

# Verify installation
ansible --version

# Test connectivity
ansible -i inventories/production.ini spacetime_servers -m ping
```

### Run Playbooks

1. **Configure All Servers**:

```bash
# Run full playbook
ansible-playbook -i inventories/production.ini playbook.yml

# Run with verbose output
ansible-playbook -i inventories/production.ini playbook.yml -vvv
```

2. **Run Specific Roles**:

```bash
# Only install Docker
ansible-playbook -i inventories/production.ini playbook.yml --tags docker

# Only configure security
ansible-playbook -i inventories/production.ini playbook.yml --tags security

# Only setup monitoring
ansible-playbook -i inventories/production.ini playbook.yml --tags monitoring
```

3. **Run on Specific Hosts**:

```bash
# Run on single host
ansible-playbook -i inventories/production.ini playbook.yml --limit prod-server-01

# Run on multiple hosts
ansible-playbook -i inventories/production.ini playbook.yml --limit "prod-server-01,prod-server-02"
```

### Manage Secrets with Ansible Vault

```bash
# Create encrypted secrets file
ansible-vault create vars/secrets.yml

# Edit encrypted file
ansible-vault edit vars/secrets.yml

# Run playbook with vault
ansible-playbook -i inventories/production.ini playbook.yml --ask-vault-pass

# Or use vault password file
ansible-playbook -i inventories/production.ini playbook.yml --vault-password-file ~/.vault_pass
```

## Health Checks and Monitoring

### Manual Health Checks

```bash
# Run comprehensive health check
cd C:/godot/deploy
bash health_check.sh --url https://spacetime.example.com --verbose

# Check specific components
curl https://spacetime.example.com/status | jq
curl https://spacetime.example.com/health | jq
curl https://spacetime.example.com/metrics

# Check Docker containers
docker-compose ps
docker stats

# Check logs
docker-compose logs --tail=100 | grep -i error
```

### Automated Monitoring

**Prometheus Metrics**:

```bash
# Access Prometheus UI
open http://spacetime.example.com:9090

# Key metrics:
# - up{job="godot"} - Service uptime
# - http_requests_total - Request count
# - http_request_duration_seconds - Response time
# - container_memory_usage_bytes - Memory usage
```

**Grafana Dashboards**:

```bash
# Access Grafana
open https://spacetime.example.com/grafana

# Default credentials (change immediately!):
# Username: admin
# Password: admin

# Import dashboards from grafana/dashboards/
```

**Alerting**:

Configure alerts in Prometheus (prometheus.yml):

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - 'alerts/*.yml'
```

## Rollback Procedures

### Automatic Rollback

Deployments automatically rollback if:

- Health checks fail
- Smoke tests fail
- Container fails to start
- High error rate detected

### Manual Rollback

1. **Quick Rollback** (to previous version):

```bash
cd C:/godot/deploy

# Rollback to latest backup
bash rollback.sh --quick

# Verify rollback
bash health_check.sh --url http://localhost:8080
```

2. **Rollback to Specific Version**:

```bash
# List available backups
bash rollback.sh --list

# Output:
#      1	20251202-153022
#      2	20251201-143010
#      3	20251130-120045

# Rollback to specific backup
bash rollback.sh 20251201-143010
```

3. **Blue-Green Rollback**:

```bash
# Instant rollback by switching to previous environment
bash blue-green-switch.sh blue

# Verify
bash blue-green-switch.sh status
```

4. **Kubernetes Rollback**:

```bash
# View rollout history
kubectl rollout history deployment/spacetime-godot -n spacetime

# Rollback to previous revision
kubectl rollout undo deployment/spacetime-godot -n spacetime

# Rollback to specific revision
kubectl rollout undo deployment/spacetime-godot --to-revision=2 -n spacetime
```

### Verify Rollback

```bash
# Check service health
curl http://localhost:8080/status | jq '.overall_ready'

# Check container status
docker-compose ps

# Check logs for errors
docker-compose logs --tail=100 | grep -i error

# Run smoke tests
bash deploy/smoke_tests.sh

# Monitor metrics
curl http://localhost:9090/api/v1/query?query=up{job="godot"}
```

## Troubleshooting

### Common Issues

**1. Deployment Script Fails**

```bash
# Check prerequisites
bash deploy/health_check.sh --url http://localhost:8080

# Check Docker
docker info
docker-compose version

# Check logs
docker-compose logs --tail=100

# Check disk space
df -h

# Check memory
free -h
```

**2. Containers Won't Start**

```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs <service-name>

# Check for port conflicts
netstat -an | grep 8080

# Restart containers
docker-compose restart

# Rebuild if needed
docker-compose up -d --build --force-recreate
```

**3. Health Checks Failing**

```bash
# Check service accessibility
curl http://localhost:8080/status

# Check all ports
curl http://localhost:8080  # HTTP API
curl http://localhost:8081  # Telemetry
curl http://localhost:9090  # Prometheus
curl http://localhost:3000  # Grafana

# Check container health
docker inspect --format='{{.State.Health.Status}}' spacetime-godot-prod

# View health check logs
docker inspect --format='{{json .State.Health}}' spacetime-godot-prod | jq
```

**4. Image Pull Failures**

```bash
# Login to registry
docker login ghcr.io

# Manually pull image
docker pull ghcr.io/your-org/spacetime:v2.5.0

# Check image exists
docker images | grep spacetime

# Check registry credentials
cat ~/.docker/config.json
```

**5. Database Connection Issues**

```bash
# Check database container
docker-compose ps postgres

# Test database connection
docker-compose exec postgres pg_isready -U spacetime

# Check database logs
docker-compose logs postgres --tail=50

# Test connection from app
docker-compose exec godot curl http://localhost:8080/status | jq '.database'
```

### Getting Help

1. **Check logs**:

```bash
# Application logs
docker-compose logs godot --tail=100

# All services
docker-compose logs --tail=100

# Follow logs
docker-compose logs -f
```

2. **Check documentation**:

```bash
# Project documentation
ls -la docs/

# Deployment scripts help
bash deploy/deploy.sh --help
bash deploy/rollback.sh --help
bash deploy/health_check.sh --help
```

3. **Create issue**:

If problems persist, create a GitHub issue with:

- Deployment environment (dev/staging/production)
- Error messages and logs
- Steps to reproduce
- System information (OS, Docker version, etc.)

## Security Considerations

### Pre-Deployment Security Checklist

- [ ] Update all dependencies to latest secure versions
- [ ] Run security scan: `gh workflow run security-scan.yml`
- [ ] Verify no secrets in code: `git grep -i "password\|secret\|key"`
- [ ] Check `.env` files are not committed
- [ ] Verify TLS certificates are valid and not expiring
- [ ] Review firewall rules (only required ports open)
- [ ] Confirm authentication is required for all endpoints
- [ ] Test rate limiting is active
- [ ] Verify CORS configuration
- [ ] Check security headers are present
- [ ] Review container security settings
- [ ] Verify database encryption at rest
- [ ] Check Redis authentication is enabled
- [ ] Review IAM roles and permissions (AWS)
- [ ] Verify backup encryption
- [ ] Test disaster recovery procedure

### Security Validation

```bash
# Run comprehensive security validation
bash deploy/security_validation.sh --url https://spacetime.example.com --verbose

# Check for vulnerabilities
docker scan ghcr.io/your-org/spacetime:v2.5.0

# Run penetration tests
cd tests/http_api
pytest test_security_penetration.py -v
```

### Security Incident Response

If a security issue is discovered:

1. **Immediate Actions**:

```bash
# Take affected systems offline
docker-compose down

# Enable maintenance mode
# (implement maintenance page)

# Preserve logs for analysis
docker-compose logs > incident-$(date +%Y%m%d-%H%M%S).log
```

2. **Assess Impact**:

```bash
# Check access logs
grep "suspicious-pattern" logs/*.log

# Review authentication attempts
grep "401\|403" logs/access.log

# Check for data exfiltration
# Review database query logs
# Review network traffic logs
```

3. **Remediate**:

```bash
# Rotate all secrets
# Update .env files with new credentials
# Redeploy with new secrets

# Apply security patches
# Update to patched versions
# Redeploy

# Review and update security configurations
```

4. **Communicate**:

- Notify stakeholders
- Document incident
- Create security advisory if needed
- Update security procedures

---

## Quick Reference

### Essential Commands

```bash
# Deploy to staging
bash deploy/deploy.sh

# Deploy to production with specific version
ENVIRONMENT=production IMAGE_TAG=v2.5.0 bash deploy/deploy.sh

# Quick rollback
bash deploy/rollback.sh --quick

# Health check
bash deploy/health_check.sh --url http://localhost:8080

# Security validation
bash deploy/security_validation.sh --url http://localhost:8080

# Blue-green switch
bash deploy/blue-green-switch.sh green

# View deployment status
bash deploy/blue-green-switch.sh status

# Kubernetes deploy
kubectl apply -k deploy/kubernetes/production/

# Terraform apply
terraform apply -var-file="environments/production/terraform.tfvars"

# Ansible playbook
ansible-playbook -i inventories/production.ini playbook.yml
```

### Useful URLs

- **Application**: https://spacetime.example.com
- **API Docs**: https://spacetime.example.com/docs
- **Prometheus**: https://spacetime.example.com:9090
- **Grafana**: https://spacetime.example.com/grafana
- **GitHub Actions**: https://github.com/your-org/your-repo/actions

### Support

- **Documentation**: `docs/`
- **GitHub Issues**: https://github.com/your-org/your-repo/issues
- **Team Chat**: [Your team chat link]

---

**Last Updated**: 2025-12-02
**Version**: 2.5.0
