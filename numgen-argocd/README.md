# NumGen ArgoCD GitOps Implementation

[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-blue?logo=argo)](https://argoproj.github.io/cd/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Container%20Orchestration-blue?logo=kubernetes)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-Package%20Manager-blue?logo=helm)](https://helm.sh/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-purple?logo=terraform)](https://terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud%20Platform-orange?logo=amazon-aws)](https://aws.amazon.com/)

A complete GitOps implementation of the NumGen application stack using ArgoCD, demonstrating modern Kubernetes deployment practices with Infrastructure as Code.

## 🏗️ Architecture Overview

This project showcases a production-ready GitOps workflow featuring:

- **🚀 NumGen Application**: Node.js web application for generating number combinations
- **🗄️ MongoDB**: Database backend using Bitnami Helm chart
- **🖥️ Mongo Express**: Web-based MongoDB administration interface
- **🔄 ArgoCD**: GitOps continuous deployment
- **🏗️ Terraform**: Infrastructure as Code for AWS EC2 and Minikube
- **⚓ Helm**: Kubernetes package management with single-template architecture

## 📁 Repository Structure

```
├── terraform-configs/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── numgen-stack/              # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml           # Single values file for all components
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       └── hpa.yaml
├── argocd-application.yaml    # ArgoCD Application Manifest
└── README.md
```

## 🚀 Quick Start Guide

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- kubectl installed
- Git repository access

### 1. Infrastructure Provisioning

```bash
# Clone the repository
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp/numgen-argocd/

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

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI (run in background)
kubectl port-forward svc/argocd-server -n argocd 8443:443 --address 0.0.0.0 &
```

**🌐 Access ArgoCD**: `https://<ec2-instance-ip>:8443`
- **Username**: `admin`
- **Password**: (from command above)

## 🎛️ Deployment Options

Choose your preferred deployment method:

### Option A: ArgoCD UI Deployment (Recommended for Learning)

#### 1. Repository Connection
1. **Settings** → **Repositories** → **Connect Repo**
2. **Configure Repository:**
   - **Connection Method**: HTTPS
   - **Type**: Git
   - **Name**: `Numgen-App-Repo`
   - **Project**: `default`
   - **Repository URL**: `https://github.com/slimboi/NodeJS-NumberGeneratorApp.git`
3. **Connect** → ✅ Successful connection

#### 2. Application Creation
1. **Applications** → **Create Application**
2. **Configuration:**
   - **Application Name**: `numgen`
   - **Project Name**: `default`
   - **Sync Policy**: `Manual`
   - **Options**: ✅ Auto-Create Namespace, ✅ Retry
3. **Source:**
   - **Repository URL**: `https://github.com/slimboi/NodeJS-NumberGeneratorApp.git`
   - **Revision**: `HEAD` (or specific branch like `feature/argocd`)
   - **Path**: `numgen-stack`
4. **Destination:**
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `numgen-app`
5. **Helm:**
   - **Values Files**: `values.yaml`
6. **Create** → **Sync** → **Synchronize**

### Option B: CLI Deployment (Automated)

```bash
# Navigate back to root directory
cd ..

# Apply ArgoCD application manifest (auto-sync enabled)
kubectl apply -f argocd-application.yaml

# Verify application creation
kubectl get applications -n argocd
kubectl describe application numgen-app -n argocd
```

## 🔐 Container Registry Authentication

```bash
# Create ECR secret for private image pulls
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app
```

## 🌐 Application Access

```bash
# Port forward applications
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 3000:3000 &
kubectl port-forward -n numgen-app --address 0.0.0.0 service/mongo-express 8081:8081 &
```

**🎯 Access URLs:**
- **NumGen Application**: `http://<ec2-instance-ip>:3000`
- **Mongo Express**: `http://<ec2-instance-ip>:8081`
- **ArgoCD Dashboard**: `https://<ec2-instance-ip>:8443`

## 🔄 GitOps Workflow Testing

Demonstrate the GitOps workflow by making changes:

### 1. Make Changes in Git
```bash
# Clone and modify
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp/numgen-stack

# Edit values.yaml - increase replicas
numgen:
  deployment:
    replicas: 3  # Changed from 2

# Commit and push changes
git add values.yaml
git commit -m "Scale NumGen to 3 replicas"
git push origin main
```

### 2. Sync Changes in ArgoCD
- **UI Method**: ArgoCD Dashboard → numgen → Refresh → Sync
- **Auto-Sync**: Changes applied automatically (if enabled)

### 3. Verify Deployment
```bash
# Verify scaling occurred
kubectl get pods -n numgen-app -l app=numgen
# Should show 3 pods running
```

## 🎯 Key Features Demonstrated

### ✅ GitOps Principles
- **📝 Declarative**: Infrastructure and applications defined as code
- **🔄 Automated**: Continuous synchronization from Git
- **🔍 Observable**: Real-time application health monitoring
- **🛡️ Secure**: RBAC and secret management

### ✅ Production-Ready Practices
- **🏗️ Infrastructure as Code**: Terraform-managed AWS resources
- **📦 Helm Charts**: Reusable, templated Kubernetes deployments
- **🔐 Security**: ECR integration and Kubernetes secrets
- **📊 Monitoring**: ArgoCD health checks and metrics
- **🔄 Self-Healing**: Automatic drift detection and correction

### ✅ Multi-Component Orchestration
- **Frontend**: NumGen Node.js application
- **Database**: MongoDB with persistent storage
- **Admin UI**: Mongo Express for database management
- **Dependencies**: Bitnami chart integration

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### Application Stuck in "Progressing"
```bash
# Check ArgoCD controller logs
kubectl logs -n argocd deployment/argocd-application-controller

# Check application status
kubectl describe application numgen-app -n argocd
```

#### ECR Image Pull Failures
```bash
# Verify ECR secret exists
kubectl get secrets -n numgen-app | grep ecr

# Check pod events for image pull errors
kubectl get events -n numgen-app --sort-by=.metadata.creationTimestamp
```

#### Helm Chart Validation
```bash
# Test chart locally
helm template numgen-stack ./numgen-stack -f ./numgen-stack/values.yaml

# Dry-run validation
helm install --dry-run numgen-test ./numgen-stack -f ./numgen-stack/values.yaml
```

## 📊 Monitoring and Observability

### ArgoCD Metrics
```bash
# Access ArgoCD metrics
kubectl port-forward -n argocd svc/argocd-metrics 8082:8082 &
curl http://localhost:8082/metrics
```

### Application Health
```bash
# Monitor resource usage
kubectl top pods -n numgen-app

# Check application logs
kubectl logs -n numgen-app -l app=numgen

# View ArgoCD application health
kubectl get application numgen-app -n argocd -o jsonpath='{.status.health.status}'
```

## 🚀 Advanced Features

### Branch Targeting
Switch ArgoCD to track specific branches:

```bash
# Target feature branch instead of main
kubectl patch application numgen-app -n argocd --type='merge' \
  -p='{"spec":{"source":{"targetRevision":"feature/argocd"}}}'
```

### Multi-Environment Support
- **Development**: Auto-sync enabled, latest images
- **Staging**: Manual sync, release candidates  
- **Production**: Manual sync, pinned stable versions

### Security Enhancements
- RBAC configuration for team access
- Sealed-secrets for sensitive data
- Network policies for pod communication

## 🎯 Learning Outcomes

This implementation demonstrates mastery of:

- **🔄 GitOps Methodologies**: Declarative, Git-driven deployments
- **⚓ Kubernetes Orchestration**: Complex multi-service applications
- **🏗️ Infrastructure as Code**: Terraform cloud resource management
- **📦 Helm Templating**: Flexible, reusable chart architecture
- **🔐 Security Practices**: Container registry authentication
- **📊 Observability**: Application health monitoring
- **🛠️ Troubleshooting**: Systematic debugging approaches

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

**GitHub**: [@slimboi](https://github.com/slimboi)  
**LinkedIn**: [Your LinkedIn Profile](https://linkedin.com/in/yourprofile)

## 🙏 Acknowledgments

- [ArgoCD Project](https://argoproj.github.io/cd/) for the GitOps platform
- [Bitnami](https://bitnami.com/) for production-ready Helm charts
- [Kubernetes Community](https://kubernetes.io/) for container orchestration
- [Terraform](https://terraform.io/) for infrastructure automation

---

⭐ **Star this repository** if you found this GitOps implementation helpful!

🔄 **Fork and adapt** for your own projects and learning journey!