# Continuous Deployment (CD) Guide

This project now includes comprehensive Continuous Deployment capabilities with multiple deployment options.

## 🚀 Deployment Options

### 1. Kubernetes Deployment (Recommended for Production)

**Prerequisites:**
- Kubernetes cluster (local or cloud)
- `kubectl` configured
- Docker Hub credentials

**Deploy:**
```bash
# Deploy to production
./scripts/deploy-k8s.sh production latest

# Deploy specific version
./scripts/deploy-k8s.sh production 1.0.0-123
```

**Features:**
- Auto-scaling with HPA
- Rolling updates
- Health checks
- Load balancing
- Service discovery

### 2. Docker Compose Deployment (Good for Development/Staging)

**Prerequisites:**
- Docker and Docker Compose
- Docker Hub access

**Deploy:**
```bash
# Deploy with Docker Compose
./scripts/deploy-docker-compose.sh staging latest

# Deploy specific version
./scripts/deploy-docker-compose.sh production 1.0.0-123
```

**Features:**
- Simple setup
- Includes monitoring (Prometheus + Grafana)
- Nginx reverse proxy
- Health checks

## 📁 Project Structure

```
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml            # Namespace definition
│   ├── configmap.yaml           # Configuration
│   ├── deployment.yaml          # Application deployment
│   ├── service.yaml             # Service definition
│   ├── ingress.yaml             # Ingress configuration
│   ├── hpa.yaml                 # Horizontal Pod Autoscaler
│   └── dockerhub-secret.yaml    # Docker Hub credentials
├── scripts/                      # Deployment scripts
│   ├── deploy-k8s.sh            # Kubernetes deployment
│   ├── deploy-docker-compose.sh # Docker Compose deployment
│   ├── rollback-k8s.sh          # Kubernetes rollback
│   └── health-check.sh          # Health check utility
├── docker-compose.yml           # Docker Compose configuration
├── nginx.conf                   # Nginx configuration
├── prometheus.yml               # Prometheus configuration
└── Jenkinsfile                  # Extended CI/CD pipeline
```

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your settings
```

### Kubernetes Setup

1. **Create Docker Hub Secret:**
```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=prayag8tiwari \
  --docker-password=YOUR_DOCKERHUB_PASSWORD \
  --docker-email=YOUR_EMAIL \
  --namespace=prayag-app
```

2. **Apply all manifests:**
```bash
kubectl apply -f k8s/
```

### Docker Compose Setup

1. **Update image tag in docker-compose.yml**
2. **Start services:**
```bash
docker-compose up -d
```

## 🔄 CI/CD Pipeline

The Jenkins pipeline now includes:

1. **Build & Test** - Maven build and testing
2. **Docker Build** - Create and push Docker images
3. **Deploy to Staging** - Automatic deployment to staging
4. **Health Check** - Verify staging deployment
5. **Deploy to Production** - Manual approval required
6. **Post-Deployment Health Check** - Verify production deployment

## 📊 Monitoring

### Prometheus Metrics
- Available at: `http://localhost:9090`
- Monitors application health and performance

### Grafana Dashboards
- Available at: `http://localhost:3000`
- Default credentials: `admin/admin`
- Pre-configured dashboards for application monitoring

## 🚨 Health Checks

### Application Health
```bash
# Check application health
./scripts/health-check.sh http://localhost:8080

# Check with custom timeout
./scripts/health-check.sh http://localhost:8080 60
```

### Kubernetes Health
```bash
# Check pod status
kubectl get pods -n prayag-app

# Check service status
kubectl get services -n prayag-app

# Check deployment status
kubectl rollout status deployment/prayag-app-deployment -n prayag-app
```

## 🔄 Rollback

### Kubernetes Rollback
```bash
# Rollback to previous version
./scripts/rollback-k8s.sh

# Manual rollback
kubectl rollout undo deployment/prayag-app-deployment -n prayag-app
```

### Docker Compose Rollback
```bash
# Stop current version
docker-compose down

# Start previous version (update docker-compose.yml first)
docker-compose up -d
```

## 🌐 Access Points

### Kubernetes
- **LoadBalancer IP**: Check with `kubectl get services -n prayag-app`
- **Ingress**: `http://prayag-app.example.com` (configure your domain)

### Docker Compose
- **Direct**: `http://localhost:8080`
- **Nginx**: `http://localhost:80`
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3000`

## 🔧 Troubleshooting

### Common Issues

1. **Image Pull Errors**
   - Check Docker Hub credentials
   - Verify image exists and is public

2. **Health Check Failures**
   - Check application logs
   - Verify port configuration
   - Check resource limits

3. **Kubernetes Deployment Issues**
   - Check pod logs: `kubectl logs -n prayag-app -l app=prayag-app`
   - Check events: `kubectl get events -n prayag-app`
   - Verify resource availability

### Logs

```bash
# Kubernetes logs
kubectl logs -n prayag-app -l app=prayag-app

# Docker Compose logs
docker-compose logs prayag-app

# All services logs
docker-compose logs
```

## 📈 Scaling

### Kubernetes Auto-scaling
- Configured in `k8s/hpa.yaml`
- Scales based on CPU and memory usage
- Min: 2 replicas, Max: 10 replicas

### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment prayag-app-deployment --replicas=5 -n prayag-app

# Scale Docker Compose (update replicas in docker-compose.yml)
docker-compose up -d --scale prayag-app=3
```

## 🔒 Security Considerations

1. **Secrets Management**
   - Use Kubernetes secrets for sensitive data
   - Never commit passwords to version control

2. **Network Security**
   - Configure proper ingress rules
   - Use HTTPS in production
   - Implement proper authentication

3. **Image Security**
   - Scan images for vulnerabilities
   - Use specific image tags, not `latest`
   - Regular security updates

## 📝 Next Steps

1. **Configure your domain** in `k8s/ingress.yaml`
2. **Set up monitoring alerts** in Grafana
3. **Configure SSL certificates** for HTTPS
4. **Set up backup strategies** for persistent data
5. **Implement blue-green deployments** for zero-downtime updates