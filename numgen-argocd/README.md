# ArgoCD Manual Workflow - NumGen Application Deployment

## 🎯 Overview

### 1. Infrastructure Setup via Terraform
```bash
# Navigate to Terraform configurations
cd terraform-configs/

# Initialize and apply infrastructure
terraform init
terraform fmt
terraform plan
terraform apply
```

### 2. ArgoCD Access Setup
```bash
# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8443:443 --address 0.0.0.0 &
```

**Access URL**: `https://ec2-instance-ip:8443`
- **Username**: `admin`
- **Password**: (from command above)

### 3. Repository Connection (UI Steps)
1. **Go to Settings** → **Repositories**
2. **Click "Connect Repo"**
3. **Configure Repository:**
   - **Connection Method**: HTTPS
   - **Type**: Git
   - **Name**: `Numgen-App-Repo`
   - **Project**: `default`
   - **Repository URL**: `https://github.com/slimboi/NodeJS-NumberGeneratorApp.git`
4. **Click "Connect"** → Should show ✅ Successful connection

### 4. Application Creation (UI Steps)
1. **Go to Applications** → **Create Application**
2. **General Configuration:**
   - **Application Name**: `numgen`
   - **Project Name**: `default`
   - **Sync Policy**: `Manual`
   - **Options**: ✅ Auto-Create Namespace, ✅ Retry
3. **Source Configuration:**
   - **Repository URL**: `https://github.com/slimboi/NodeJS-NumberGeneratorApp.git`
   - **Revision**: `HEAD`
   - **Path**: `numgen-stack`
4. **Destination Configuration:**
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `numgen-app`
5. **Helm Configuration:**
   - **Values Files**: `values.yaml`
6. **Click "Create"**

### 5. Application Synchronization
1. **Initial Status**: `OutOfSync` (expected with manual sync)
2. **Click "Sync"** → **Click "Synchronize"**
3. **Monitor deployment** in ArgoCD UI

### 6. ECR Authentication Setup
```bash
# Create ECR secret for image pulls
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app
```

### 7. Application Access
```bash
# Port forward applications
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 3000:3000 &
kubectl port-forward -n numgen-app --address 0.0.0.0 service/mongo-express 8081:8081 &
```

**Access URLs:**
- **NumGen App**: `http://ec2-instance-ip:3000`
- **Mongo Express**: `http://ec2-instance-ip:8081`


### Applying the CLI Manifest:
```bash

cd ..

# Apply the application manifest
kubectl apply -f argocd-application.yaml

# Create ECR secret for image pulls
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app

# Verify application creation
kubectl get applications -n argocd

# Check application status
kubectl describe application numgen-app -n argocd
```

When deployed via cli Auto sync is enabled.

## 🔄 Testing GitOps Workflow

### 1. Make a Change in Git
```bash
# Clone your repository
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp/numgen-stack

# Make a change (e.g., update replica count)
# Edit values.yaml
numgen:
  deployment:
    replicas: 3  # Changed from 2

# Commit and push
git add values.yaml
git commit -m "Scale NumGen to 3 replicas"
git push origin main
```

### 2. Sync in ArgoCD
1. **Go to ArgoCD UI**
2. **Select numgen application**
3. **Click "Refresh"** to detect changes
4. **Click "Sync"** → **"Synchronize"**
5. **Verify** scaling in Resource Tree

### 3. Verify Changes
```bash
# Check if scaling occurred
kubectl get pods -n numgen-app -l app=numgen

# Should show 3 replicas running
```

### Issue 1: Application Stuck in "Progressing"
```bash
# Check ArgoCD application logs
kubectl logs -n argocd deployment/argocd-application-controller

# Check specific application status
kubectl describe application numgen-app -n argocd
```

### Issue 2: ECR Image Pull Failures
```bash
# Verify ECR secret exists
kubectl get secrets -n numgen-app | grep ecr

# Check pod events
kubectl get events -n numgen-app --sort-by=.metadata.creationTimestamp
```

### Issue 3: Helm Chart Issues
```bash
# Test Helm chart locally
helm template numgen-stack ./numgen-stack -f ./numgen-stack/values.yaml

# Validate with dry-run
helm install --dry-run numgen-test ./numgen-stack -f ./numgen-stack/values.yaml
```

## 📊 Monitoring & Observability

### ArgoCD Metrics
```bash
# Check ArgoCD metrics
kubectl port-forward -n argocd svc/argocd-metrics 8082:8082 &
curl http://localhost:8082/metrics
```

### Application Metrics
```bash
# Monitor application pods
kubectl top pods -n numgen-app

# Check application logs
kubectl logs -n numgen-app -l app=numgen
```

## 🎯 Next Steps & Enhancements

### 1. Multi-Environment Setup
- Create separate applications for dev/staging/prod
- Use different value files per environment
- Implement promotion workflows

### 2. Security Enhancements
- Set up RBAC for ArgoCD users
- Implement sealed-secrets for sensitive data
- Add network policies

### 3. Advanced GitOps
- Image updater for automatic image updates
- Webhook integration for faster sync
- Notifications and alerting

### 4. Backup & Disaster Recovery
- ArgoCD configuration backup
- Application state backup
- Cluster restoration procedures
