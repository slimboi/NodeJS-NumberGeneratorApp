# NumGen Application Helm Chart

A flexible, reusable Helm chart for deploying the NumGen application stack, including MongoDB database and Mongo Express admin interface.

## Overview

This chart uses a **single set of templates** with **multiple values files** approach, allowing you to deploy different applications using the same template structure but with different configurations.

## Architecture

- **NumGen**: Node.js application for number generation
- **MongoDB**: Database backend with persistent storage (via Bitnami chart dependency)
- **Mongo Express**: Web-based MongoDB admin interface

## Directory Structure

```
numgen-chart/
├── Chart.yaml                 # Chart metadata with Bitnami MongoDB dependency
├── values-numgen.yaml        # NumGen app + MongoDB configuration
├── values-mongoexpress.yaml  # Mongo Express configuration
└── templates/
    ├── deployment.yaml       # Single deployment template
    ├── service.yaml         # Single service template
    ├── pvc.yaml            # Persistent volume claim template
    └── hpa.yaml            # Horizontal Pod Autoscaler template
```

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl configured to access your cluster
- For AWS ECR images: AWS CLI configured with appropriate permissions
- AWS region: ap-southeast-2 (Sydney) - adjust commands if using different region

## Important: Service Discovery in Multiple Release Deployment

When using multiple Helm releases, service discovery requires careful configuration:

- **NumGen release** (`numgen`) creates: `numgen-mongodb` service
- **Mongo Express release** (`mongoexpress`) needs to connect to: `numgen-mongodb` 

Therefore, Mongo Express uses a **configurable service name** to ensure proper connectivity across releases:

```yaml
# In values-mongoexpress.yaml
mongodb:
  enabled: false  # Disable MongoDB for this release
  serviceName: "numgen-mongodb"  # Configurable service name

env:
  - name: ME_CONFIG_MONGODB_SERVER
    value: "{{ .Values.mongodb.serviceName }}"  # Dynamic reference
```

**Design Benefits:**
- **Flexibility**: Can easily change which MongoDB service to connect to
- **No Hardcoding**: Service name is configurable via values
- **Cross-Release Connectivity**: Mongo Express can connect to MongoDB from any release

**Note**: If you change the NumGen release name, update the `mongodb.serviceName` value in `values-mongoexpress.yaml` to match.

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

# Verify AWS access
aws s3 ls
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
git checkout feature/helm-bitnami
cd helm-numgen-app-bitnami/

# Validate chart
helm lint .

# Add bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update dependencies
helm dependency update

# Deploy NumGen+MongoDB application (Helm creates namespace)
helm install numgen . -f values-numgen.yaml --create-namespace --namespace numgen-app

# Create ECR secret after namespace exists
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app

# Restart NumGen deployment to pick up the ECR secret
kubectl rollout restart deployment/numgen -n numgen-app

# Check NumGen deployment status
kubectl get pods -n numgen-app
kubectl logs -l app=numgen -n numgen-app

# Deploy Mongo Express (connects to existing MongoDB)
helm install mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app

# Verify complete deployment
kubectl get all -n numgen-app
```

#### 8. Access Applications via Port Forwarding
```bash
# Forward NumGen app
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 3000:3000 &

# Forward Mongo Express
kubectl port-forward -n numgen-app --address 0.0.0.0 service/mongo-express 8081:8081 &
```

#### 9. Access Your Applications
- **NumGen Application**: `http://<EC2-PUBLIC-IP>:3000`
- **Mongo Express**: `http://<EC2-PUBLIC-IP>:8081`
  - No authentication required (as configured in values)

### Important Security Notes for EC2 Deployment

⚠️ **Security Group Configuration**: Ensure your EC2 security group allows inbound traffic on ports 3000 and 8081 from your IP address.

⚠️ **Production Considerations**: 
- Port forwarding is suitable for development/testing only
- For production, consider using Ingress controllers or LoadBalancer services
- MongoDB is currently configured without authentication - enable for production
- Use HTTPS for web interfaces

### Troubleshooting EC2/Minikube Specific Issues

**1. Port forwarding not accessible:**
```bash
# Check if ports are listening
netstat -tulpn | grep :3000
netstat -tulpn | grep :8081

# Restart port forwarding if needed
pkill kubectl
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 3000:3000 &
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

# Restart deployment
kubectl rollout restart deployment/numgen -n numgen-app
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

**4. Mongo Express connection issues:**
```bash
# Check if MongoDB service exists
kubectl get svc numgen-mongodb -n numgen-app

# Check Mongo Express logs
kubectl logs -l app=mongo-express -n numgen-app

# Verify service name configuration
kubectl describe deployment mongo-express -n numgen-app | grep ME_CONFIG_MONGODB_SERVER
```

## Management Commands

### Viewing Deployments
```bash
# List all Helm releases
helm list -n numgen-app

# Check all resources
kubectl get all -n numgen-app

# View specific app status
helm status numgen -n numgen-app
helm status mongoexpress -n numgen-app

# Check specific components
kubectl get pods -l app=numgen -n numgen-app
kubectl get pods -l app=mongo-express -n numgen-app
kubectl get pods -l app.kubernetes.io/name=mongodb -n numgen-app
```

### Upgrading Applications
```bash
# Scale NumGen application
helm upgrade numgen . -f values-numgen.yaml --set deployment.replicas=3 --namespace numgen-app

# Update Mongo Express configuration
helm upgrade mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app

# Change MongoDB service name in Mongo Express
helm upgrade mongoexpress . -f values-mongoexpress.yaml --set mongodb.serviceName=new-mongodb-service --namespace numgen-app
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
# View release history
helm history numgen -n numgen-app
helm history mongoexpress -n numgen-app

# Rollback to previous version
helm rollback numgen 1 -n numgen-app
helm rollback mongoexpress 1 -n numgen-app
```

### Cleanup
```bash
# Remove individual applications
helm uninstall numgen -n numgen-app
helm uninstall mongoexpress -n numgen-app

# Remove namespace (optional)
kubectl delete namespace numgen-app
```

## Chart Validation

### Linting
```bash
# Lint with default values
helm lint .

# Lint specific configurations
helm lint . -f values-mongoexpress.yaml
helm lint . -f values-numgen.yaml
```

### Template Testing
```bash
# Generate templates without installing
helm template test . -f values-mongoexpress.yaml
helm template test . -f values-numgen.yaml

# Check specific template
helm template test . -f values-numgen.yaml -s templates/deployment.yaml
```

### Dry Run
```bash
# Test installation without applying
helm install --dry-run --debug mongoexpress . -f values-mongoexpress.yaml --namespace numgen-app
helm install --dry-run --debug numgen . -f values-numgen.yaml --namespace numgen-app
```

## Customization

### Common Customizations

**Scaling Applications:**
```bash
# Scale NumGen to 5 replicas
helm upgrade numgen . -f values-numgen.yaml --set deployment.replicas=5 --namespace numgen-app

# Enable horizontal pod autoscaling
helm upgrade numgen . -f values-numgen.yaml --set autoscaling.enabled=true --namespace numgen-app
```

**Resource Adjustments:**
```bash
# Increase MongoDB memory (via NumGen release)
helm upgrade numgen . -f values-numgen.yaml \
  --set mongodb.resources.limits.memory=1Gi \
  --set mongodb.resources.requests.memory=512Mi \
  --namespace numgen-app
```

**Service Type Changes:**
```bash
# Change NumGen to LoadBalancer
helm upgrade numgen . -f values-numgen.yaml --set service.type=LoadBalancer --namespace numgen-app
```

**MongoDB Service Name Changes:**
```bash
# Update Mongo Express to connect to different MongoDB
helm upgrade mongoexpress . -f values-mongoexpress.yaml --set mongodb.serviceName=different-mongodb --namespace numgen-app
```

### Creating Custom Values Files

You can create environment-specific values files:

```bash
# Create production values
cp values-numgen.yaml values-numgen-prod.yaml
# Edit values-numgen-prod.yaml with production settings

# Deploy with custom values
helm install numgen-prod . -f values-numgen-prod.yaml --namespace numgen-prod --create-namespace
```

## Troubleshooting

### Common Issues

**1. Pods not starting:**
```bash
kubectl describe pod <pod-name> -n numgen-app
kubectl logs <pod-name> -n numgen-app

# Check for image pull issues
kubectl get events -n numgen-app --sort-by=.metadata.creationTimestamp
```

**2. Service connectivity:**
```bash
kubectl get endpoints -n numgen-app
kubectl exec -it <numgen-pod-name> -n numgen-app -- nslookup numgen-mongodb
```

**3. Persistent Volume issues:**
```bash
kubectl get pv
kubectl describe pvc -n numgen-app
```

**4. Image pull issues:**
```bash
kubectl describe pod <pod-name> -n numgen-app
# Check imagePullSecrets configuration in pod spec
```

**5. Cross-release connectivity:**
```bash
# Test Mongo Express -> MongoDB connectivity
kubectl exec -it <mongo-express-pod> -n numgen-app -- nc -zv numgen-mongodb 27017

# Check Mongo Express environment variables
kubectl exec -it <mongo-express-pod> -n numgen-app -- env | grep MONGO
```

### Health Checks

**Check application health:**
```bash
# NumGen health
kubectl exec -it $(kubectl get pod -l app=numgen -n numgen-app -o jsonpath='{.items[0].metadata.name}') -n numgen-app -- wget -qO- http://localhost:3000/

# MongoDB health (using Bitnami service selector)
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/name=mongodb -n numgen-app -o jsonpath='{.items[0].metadata.name}') -n numgen-app -- mongosh --eval "db.adminCommand('ping')"

# Check MongoDB connection from NumGen app
kubectl exec -it $(kubectl get pod -l app=numgen -n numgen-app -o jsonpath='{.items[0].metadata.name}') -n numgen-app -- nc -zv numgen-mongodb 27017
```

## Chart Features

### Multiple Release Architecture
- **Independent Lifecycle**: Each component (NumGen, Mongo Express) can be deployed, upgraded, and scaled independently
- **Flexible Configuration**: Different values files allow customization per component
- **Cross-Release Connectivity**: Configurable service names enable communication between releases

### Template Flexibility
- **Reusable Templates**: Single set of templates handles multiple application types
- **Configuration-Driven**: All customization through values files, no template changes needed
- **Multi-Environment Support**: Same templates work across development, staging, and production

### Production-Ready Features
- **Health Checks**: Comprehensive readiness and liveness probes
- **Resource Management**: CPU and memory limits/requests for all components
- **Horizontal Pod Autoscaling**: Automatic scaling based on CPU/memory usage
- **Persistent Storage**: MongoDB data persistence with configurable storage classes
- **Security**: Image pull secrets, configurable service accounts

### Bitnami MongoDB Integration
- **Production-Ready**: Uses well-maintained Bitnami MongoDB chart as dependency
- **Configurable Authentication**: Can enable/disable MongoDB authentication
- **High Availability**: Support for standalone and replica set architectures
- **Monitoring**: Built-in health checks and metrics endpoints
- **Backup Support**: Compatible with standard MongoDB backup tools

### Development Features
- **Port Forwarding Support**: Easy local access for development and testing
- **Independent Scaling**: Scale individual components without affecting others
- **Debug-Friendly**: Comprehensive logging and troubleshooting tools
- **Quick Updates**: Fast deployment updates with Helm upgrades
- **Configurable Service Discovery**: Flexible MongoDB service name configuration

### Service Discovery Design
- **Cross-Release Communication**: Configurable service names enable connectivity between different Helm releases
- **Template Flexibility**: Environment variables support both static and dynamic values
- **Easy Reconfiguration**: Change target services without template modifications

## Contributing

To modify this chart:

1. Update the appropriate values file for configuration changes
2. Modify templates for structural changes  
3. Test with `helm lint` and `helm template`
4. Validate with `--dry-run` before deployment
5. When changing service names, ensure dependent services are updated accordingly

## Support

For issues or questions:
- Check the troubleshooting section above
- Validate your values files with `helm lint`
- Review Kubernetes events: `kubectl get events -n numgen-app`
- Verify service connectivity between releases
- Check that MongoDB service names match between NumGen and Mongo Express configurations