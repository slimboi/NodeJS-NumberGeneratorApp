# NumGen Application Helm Chart

A flexible, reusable Helm chart for deploying the NumGen application stack, including MongoDB database and Mongo Express admin interface.

## Overview

This chart uses a **single set of templates** with **multiple values files** approach, allowing you to deploy different applications using the same template structure but with different configurations.

## Architecture

- **NumGen**: Node.js application for number generation
- **MongoDB**: Database backend with persistent storage
- **Mongo Express**: Web-based MongoDB admin interface

## Directory Structure

```
numgen-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default values (for linting/fallback)
├── values-numgen.yaml        # NumGen app configuration
├── values-mongodb.yaml       # MongoDB configuration
├── values-mongoexpress.yaml  # Mongo Express configuration
└── templates/
    ├── deployment.yaml       # Single deployment template
    ├── service.yaml         # Single service template
    └── pvc.yaml            # Persistent volume claim template
```

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl configured to access your cluster
- For AWS ECR images: AWS CLI configured with appropriate permissions

## Deployment Environments

This chart has been tested on:
- **Local Development**: minikube on Ubuntu EC2 instance (t3.medium)
- **Cloud**: Various Kubernetes distributions

## AWS EC2 + Minikube Deployment Guide

### Complete Setup for Ubuntu EC2 Instance

If you're deploying on an Amazon EC2 Ubuntu instance with minikube, follow these steps:

#### 1. Initial System Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common unzip
```

#### 2. Install Docker
```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### 3. Install Kubernetes Tools
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 4. Install and Configure AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
# Enter your Access Key ID, Secret Access Key, region (ap-southeast-2), and output format (json)
```

#### 5. Setup Kubernetes Cluster
```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify installation
minikube status
kubectl get nodes
```

#### 6. Login to ECR
```bash
# Login to Amazon ECR
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 475325513391.dkr.ecr.ap-southeast-2.amazonaws.com
```

#### 7. Deploy Applications
```bash
# Clone your repository (adjust URL as needed)
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp
git checkout feature/helm-refactor
cd helm-numgen-app/

# Validate chart
helm lint .

# Deploy MongoDB
helm install mongodb . -f values-mongodb.yaml --create-namespace --namespace numgen-app

# Deploy Mongo Express
helm install mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app

# Create ECR secret for NumGen app
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app

# Deploy NumGen application
helm install numgen . -f values-numgen.yaml --namespace numgen-app

# Verify deployment
kubectl get all -n numgen-app
```

#### 8. Access Applications via Port Forwarding
```bash
# Forward NumGen app (port 8080 on EC2 maps to port 3000 in cluster)
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 8080:3000 &

# Forward Mongo Express (port 8081 on EC2 maps to port 8081 in cluster)
kubectl port-forward -n numgen-app --address 0.0.0.0 service/mongo-express 8081:8081 &
```

#### 9. Access Your Applications
- **NumGen Application**: `http://<EC2-PUBLIC-IP>:8080`
- **Mongo Express**: `http://<EC2-PUBLIC-IP>:8081`
  - Username: `admin`
  - Password: `pass`

### Important Security Notes for EC2 Deployment

⚠️ **Security Group Configuration**: Ensure your EC2 security group allows inbound traffic on ports 8080 and 8081 from your IP address.

⚠️ **Production Considerations**: 
- Port forwarding is suitable for development/testing only
- For production, consider using Ingress controllers or LoadBalancer services
- Secure your MongoDB with authentication
- Use HTTPS for web interfaces

### Troubleshooting EC2/Minikube Specific Issues

**1. Port forwarding not accessible:**
```bash
# Check if ports are listening
netstat -tulpn | grep :8080
netstat -tulpn | grep :8081

# Restart port forwarding if needed
pkill kubectl
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 8080:3000 &
kubectl port-forward -n numgen-app --address 0.0.0.0 service/mongo-express 8081:8081 &
```

**2. ECR authentication issues:**
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 475325513391.dkr.ecr.ap-southeast-2.amazonaws.com

# Recreate the secret
kubectl delete secret ecr-secret -n numgen-app
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app
```

**3. Minikube resource issues:**
```bash
# Check minikube status
minikube status

# Restart if needed
minikube stop
minikube start --driver=docker

# Check resources
kubectl top nodes
kubectl top pods -n numgen-app
```

## Quick Start

### Standard Deployment

1. **Clone/Download the chart**
2. **Navigate to the chart directory**
   ```bash
   cd numgen-chart
   ```

3. **Deploy the complete stack**
   ```bash
   # Deploy MongoDB first (required by other apps)
   helm install mongodb . -f values-mongodb.yaml --create-namespace --namespace numgen-app
   
   # Deploy Mongo Express
   helm install mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app
   
   # Create ECR secret (if using AWS ECR images)
   kubectl create secret docker-registry ecr-secret \
     --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
     --namespace=numgen-app
   
   # Deploy NumGen application
   helm install numgen . -f values-numgen.yaml --namespace numgen-app
   ```

## Individual Application Deployment

### 1. MongoDB Database

MongoDB provides the database backend with persistent storage.

```bash
# Deploy MongoDB
helm install mongodb . -f values-mongodb.yaml --create-namespace --namespace numgen-app

# Verify deployment
kubectl get pods -n numgen-app -l app=mongo
kubectl get pvc -n numgen-app
```

**Key Configuration Options (values-mongodb.yaml):**
- **Image**: `mongo:8.0.10`
- **Storage**: 1Gi persistent volume
- **Resources**: 256Mi-512Mi memory, 250m-500m CPU
- **Health Checks**: MongoDB ping commands
- **Service**: ClusterIP on port 27017

### 2. Mongo Express (Admin Interface)

Web-based MongoDB administration tool.

```bash
# Deploy Mongo Express (requires MongoDB to be running)
helm install mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app

# Get access URL
kubectl get svc mongo-express -n numgen-app
```

**Key Configuration Options (values-mongoexpress.yaml):**
- **Image**: `mongo-express:1-20-alpine3.19`
- **Service**: NodePort on port 8081
- **Environment**: Configured to connect to `mongo` service
- **Resources**: 128Mi-256Mi memory, 100m-200m CPU

### 3. NumGen Application

The main Node.js application.

```bash
# Deploy NumGen application
helm install numgen . -f values-numgen.yaml --namespace numgen-app

# Get access URL
kubectl get svc numgen -n numgen-app
```

**Key Configuration Options (values-numgen.yaml):**
- **Image**: Custom ECR image
- **Replicas**: 2 for high availability
- **Service**: NodePort on port 3000
- **Health Checks**: HTTP probes on `/` endpoint
- **Security**: ECR image pull secrets

## Management Commands

### Viewing Deployments
```bash
# List all Helm releases
helm list -n numgen-app

# Check all resources
kubectl get all -n numgen-app

# View specific app status
helm status mongodb -n numgen-app
helm status mongoexpress -n numgen-app
helm status numgen -n numgen-app
```

### Upgrading Applications
```bash
# Scale NumGen application
helm upgrade numgen . -f values-numgen.yaml --set deployment.replicas=3 --namespace numgen-app

# Update MongoDB image version
helm upgrade mongodb . -f values-mongodb.yaml --set image.tag=8.0.11 --namespace numgen-app

# Update with modified values file
helm upgrade mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app
```

### Accessing Applications
```bash
# Get NodePort services
kubectl get svc -n numgen-app

# Port forward for local access
kubectl port-forward svc/numgen 3000:3000 -n numgen-app
kubectl port-forward svc/mongo-express 8081:8081 -n numgen-app
```

### Rollback
```bash
# Rollback to previous version
helm rollback numgen 1 -n numgen-app
helm rollback mongodb 1 -n numgen-app
helm rollback mongoexpress 1 -n numgen-app
```

### Cleanup
```bash
# Remove individual applications
helm uninstall numgen -n numgen-app
helm uninstall mongoexpress -n numgen-app
helm uninstall mongodb -n numgen-app

# Remove namespace (optional)
kubectl delete namespace numgen-app
```

## Chart Validation

### Linting
```bash
# Lint with default values
helm lint .

# Lint specific configurations
helm lint . -f values-mongodb.yaml
helm lint . -f values-mongoexpress.yaml
helm lint . -f values-numgen.yaml
```

### Template Testing
```bash
# Generate templates without installing
helm template test . -f values-mongodb.yaml
helm template test . -f values-mongoexpress.yaml
helm template test . -f values-numgen.yaml
```

### Dry Run
```bash
# Test installation without applying
helm install --dry-run --debug mongodb . -f values-mongodb.yaml --namespace numgen-app
```

## Customization

### Common Customizations

**Scaling Applications:**
```bash
# Scale NumGen to 5 replicas
helm upgrade numgen . -f values-numgen.yaml --set deployment.replicas=5 --namespace numgen-app
```

**Resource Adjustments:**
```bash
# Increase MongoDB memory
helm upgrade mongodb . -f values-mongodb.yaml \
  --set resources.limits.memory=1Gi \
  --set resources.requests.memory=512Mi \
  --namespace numgen-app
```

**Service Type Changes:**
```bash
# Change NumGen to LoadBalancer
helm upgrade numgen . -f values-numgen.yaml --set service.type=LoadBalancer --namespace numgen-app
```

### Creating Custom Values Files

You can create environment-specific values files:

```bash
# Create production values
cp values-numgen.yaml values-numgen-prod.yaml
# Edit values-numgen-prod.yaml with production settings

# Deploy with custom values
helm install numgen-prod . -f values-numgen-prod.yaml --namespace numgen-prod
```

## Troubleshooting

### Common Issues

**1. Pods not starting:**
```bash
kubectl describe pod <pod-name> -n numgen-app
kubectl logs <pod-name> -n numgen-app
```

**2. Service connectivity:**
```bash
kubectl get endpoints -n numgen-app
kubectl exec -it <pod-name> -n numgen-app -- nslookup mongo
```

**3. Persistent Volume issues:**
```bash
kubectl get pv
kubectl describe pvc mongodb-pvc -n numgen-app
```

**4. Image pull issues:**
```bash
kubectl describe pod <pod-name> -n numgen-app
# Check imagePullSecrets configuration
```

### Health Checks

**Check application health:**
```bash
# NumGen health
kubectl exec -it $(kubectl get pod -l app=numgen -n numgen-app -o jsonpath='{.items[0].metadata.name}') -n numgen-app -- wget -qO- http://localhost:3000/

# MongoDB health
kubectl exec -it $(kubectl get pod -l app=mongo -n numgen-app -o jsonpath='{.items[0].metadata.name}') -n numgen-app -- mongosh --eval "db.adminCommand('ping')"
```

## Chart Features

- ✅ **Single Template Set**: Reusable templates for all applications
- ✅ **Multiple Values Files**: App-specific configuration
- ✅ **No Hardcoded Values**: Everything configurable via values
- ✅ **Flexible Probes**: Support for HTTP and exec health checks
- ✅ **Optional Persistence**: Configurable storage for stateful apps
- ✅ **Resource Management**: Customizable CPU/memory limits
- ✅ **Security**: Image pull secrets support
- ✅ **High Availability**: Multi-replica support

## Advanced Configuration Examples

### Environment Variables Examples

#### Basic Environment Variables
```yaml
# Simple key-value environment variables
env:
  - name: NODE_ENV
    value: "production"
  - name: PORT
    value: "3000"
  - name: DEBUG
    value: "false"
  - name: LOG_LEVEL
    value: "info"
```

#### Environment Variables from Secrets
```yaml
# Reference values from Kubernetes secrets
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: api-secrets
        key: api-key
  - name: JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: auth-secrets
        key: jwt-secret
```

#### Environment Variables from ConfigMaps
```yaml
# Reference values from ConfigMaps
env:
  - name: APP_CONFIG
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: config.json
  - name: FEATURE_FLAGS
    valueFrom:
      configMapKeyRef:
        name: feature-config
        key: flags
```

#### Mixed Environment Variables (Production Example)
```yaml
# Real-world production environment configuration
env:
  # Direct values
  - name: NODE_ENV
    value: "production"
  - name: PORT
    value: "3000"
  - name: REDIS_HOST
    value: "redis.cache.svc.cluster.local"
  - name: REDIS_PORT
    value: "6379"
  
  # From secrets
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: database-credentials
        key: connection-string
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: redis-auth
        key: password
  
  # From configmaps
  - name: LOG_LEVEL
    valueFrom:
      configMapKeyRef:
        name: logging-config
        key: level
  - name: MONITORING_ENDPOINT
    valueFrom:
      configMapKeyRef:
        name: monitoring-config
        key: endpoint
```

### Health Probes Examples

#### HTTP Health Probes (Web Applications)
```yaml
# Typical web application health checks
probes:
  readiness:
    enabled: true
    type: httpGet
    httpGet:
      path: /health/ready
      port: 3000
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
  liveness:
    enabled: true
    type: httpGet
    httpGet:
      path: /health/live
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
```

#### Exec Health Probes (Database Applications)
```yaml
# Database health checks using command execution
probes:
  readiness:
    enabled: true
    type: exec
    exec:
      command:
        - mongosh
        - --eval
        - "db.adminCommand('ping')"
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 10
    failureThreshold: 3
  liveness:
    enabled: true
    type: exec
    exec:
      command:
        - mongosh
        - --eval
        - "db.adminCommand('ping')"
    initialDelaySeconds: 60
    periodSeconds: 30
    timeoutSeconds: 10
    failureThreshold: 3
```

#### TCP Socket Probes (Network Services)
```yaml
# Simple port connectivity checks
probes:
  readiness:
    enabled: true
    type: tcpSocket
    tcpSocket:
      port: 5432
    initialDelaySeconds: 15
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
  liveness:
    enabled: true
    type: tcpSocket
    tcpSocket:
      port: 5432
    initialDelaySeconds: 45
    periodSeconds: 20
    timeoutSeconds: 5
    failureThreshold: 3
```

#### Disabled Probes (Applications without health endpoints)
```yaml
# For applications like Mongo Express that don't have reliable health endpoints
probes:
  readiness:
    enabled: false
  liveness:
    enabled: false
```

### Volume Configuration Examples

#### Basic Persistent Volume (Database Storage)
```yaml
# Simple persistent storage for databases
persistence:
  enabled: true
  storageClass: "gp2"
  accessMode: ReadWriteOnce
  size: 10Gi
  mountPath: /data/db

volumes: []
volumeMounts: []
```

#### ConfigMap Volume (Application Configuration)
```yaml
# Mount configuration files from ConfigMaps
persistence:
  enabled: false

volumes:
  - name: app-config
    configMap:
      name: application-config
      items:
        - key: app.conf
          path: application.conf
        - key: logging.conf
          path: logging.conf

volumeMounts:
  - name: app-config
    mountPath: /etc/app/config
    readOnly: true
```

#### Secret Volume (Certificates and Keys)
```yaml
# Mount certificates and secrets
persistence:
  enabled: false

volumes:
  - name: tls-certs
    secret:
      secretName: app-tls-certificates
      items:
        - key: tls.crt
          path: server.crt
        - key: tls.key
          path: server.key
  - name: api-keys
    secret:
      secretName: external-api-keys

volumeMounts:
  - name: tls-certs
    mountPath: /etc/ssl/certs
    readOnly: true
  - name: api-keys
    mountPath: /etc/secrets/api
    readOnly: true
```

#### EmptyDir Volume (Temporary Storage)
```yaml
# Temporary storage shared between containers
persistence:
  enabled: false

volumes:
  - name: temp-storage
    emptyDir: {}
  - name: cache-storage
    emptyDir:
      sizeLimit: 1Gi

volumeMounts:
  - name: temp-storage
    mountPath: /tmp/shared
  - name: cache-storage
    mountPath: /var/cache/app
```

### Complete Application Examples

#### Stateless Web Application
```yaml
# Complete configuration for a stateless web app
app:
  name: web-app
  namespace: production
  labels:
    app: web-app
    component: frontend
    version: v2.1.0

env:
  - name: NODE_ENV
    value: "production"
  - name: PORT
    value: "3000"
  - name: API_ENDPOINT
    valueFrom:
      configMapKeyRef:
        name: api-config
        key: endpoint
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: connection-string

probes:
  readiness:
    enabled: true
    type: httpGet
    httpGet:
      path: /health
      port: 3000
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
  liveness:
    enabled: true
    type: httpGet
    httpGet:
      path: /health
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3

persistence:
  enabled: false

volumes:
  - name: app-config
    configMap:
      name: web-app-config

volumeMounts:
  - name: app-config
    mountPath: /etc/app/config
    readOnly: true
```

### Best Practices

#### Environment Variables
- ✅ Use secrets for sensitive data (passwords, API keys)
- ✅ Use ConfigMaps for non-sensitive configuration
- ✅ Quote all string values to avoid YAML parsing issues
- ✅ Use descriptive names for environment variables
- ❌ Never hardcode sensitive values in values files

#### Health Probes
- ✅ Always use readiness probes for load balancer integration
- ✅ Set appropriate timeouts and failure thresholds
- ✅ Use liveness probes sparingly (only when restart helps)
- ✅ Test probe endpoints independently
- ❌ Don't use probes for applications without health endpoints

#### Volumes
- ✅ Use persistent volumes for data that must survive pod restarts
- ✅ Use ConfigMaps and Secrets for configuration files
- ✅ Set appropriate access modes and storage classes
- ✅ Use readOnly mounts when data shouldn't be modified
- ❌ Avoid HostPath volumes in production (security risk)

### Template Functions Reference
- `{{ .Values.* }}` - Access values from values files
- `{{- if condition }}` - Conditional rendering
- `{{- range array }}` - Loop through arrays
- `{{- end }}` - Close conditional/loop blocks
- `{{ quote }}` - Add quotes around values
- `{{ default "value" }}` - Provide default values
- `{{- toYaml | nindent }}` - Format YAML with proper indentation
- `{{- and condition1 condition2 }}` - Logical AND
- `{{- or condition1 condition2 }}` - Logical OR
- `{{- eq value1 value2 }}` - Equality comparison

## Contributing

To modify this chart:

1. Update the appropriate values file for configuration changes
2. Modify templates for structural changes
3. Test with `helm lint` and `helm template`
4. Validate with `--dry-run` before deployment

## Support

For issues or questions:
- Check the troubleshooting section above
- Validate your values files with `helm lint`
- Review Kubernetes events: `kubectl get events -n numgen-app`