# NumGen ArgoCD GitOps Implementation

[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-blue?logo=argo)](https://argoproj.github.io/cd/)
[![ApplicationSet](https://img.shields.io/badge/ApplicationSet-Multi--Environment-green?logo=argo)](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Container%20Orchestration-blue?logo=kubernetes)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-Package%20Manager-blue?logo=helm)](https://helm.sh/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-purple?logo=terraform)](https://terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud%20Platform-orange?logo=amazon-aws)](https://aws.amazon.com/)

A complete GitOps implementation of the NumGen application stack using ArgoCD and ApplicationSet, demonstrating modern multi-environment Kubernetes deployment practices with Infrastructure as Code.

## 🏗️ Architecture Overview

This project showcases a production-ready GitOps workflow featuring:

- **🚀 NumGen Application**: Node.js web application for generating number combinations
- **🗄️ MongoDB**: Database backend using Bitnami Helm chart
- **🖥️ Mongo Express**: Web-based MongoDB administration interface
- **🔄 ArgoCD**: GitOps continuous deployment
- **🌐 ApplicationSet**: Multi-environment application management
- **🏗️ Terraform**: Infrastructure as Code for AWS EC2 and Minikube
- **⚓ Helm**: Kubernetes package management with environment-specific values

## 📁 Repository Structure

```
├── terraform-configs/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── numgen-stack/              # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml           # Base values file
│   ├── values-dev.yaml       # Development overrides
│   ├── values-staging.yaml   # Staging overrides
│   ├── values-prod.yaml      # Production overrides
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       └── hpa.yaml
├── applicationset/            # ApplicationSet Configuration
│   └── numgen-applicationset.yaml
├── argocd-application.yaml    # Single Application Manifest (Legacy)
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
# Clone the repository and switch to ApplicationSet branch
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp/
git checkout feature/appSet

# Navigate to Terraform configurations
cd numgen-argocd/terraform-configs/

# Initialize and apply infrastructure
terraform init
terraform fmt
terraform plan
terraform apply
```

### 2. ArgoCD Setup Verification

```bash
# Verify ArgoCD installation
kubectl get all -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI (run in background)
kubectl port-forward svc/argocd-server -n argocd 8443:443 --address 0.0.0.0 &
```

**🌐 Access ArgoCD**: `https://<ec2-instance-ip>:8443`
- **Username**: `admin`
- **Password**: (from command above)

## 🌐 Multi-Environment Deployment with ApplicationSet

### ApplicationSet Configuration

The ApplicationSet automatically creates three environments with different configurations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: numgen-multi-env
  namespace: argocd
  labels:
    app: numgen
    component: applicationset
spec:
  generators:
  - list:
      elements:
      # Development Environment
      - environment: dev
        namespace: numgen-dev
        valuesFile: values-dev.yaml
        syncPolicy: automated
        
      # Staging Environment  
      - environment: staging
        namespace: numgen-staging
        valuesFile: values-staging.yaml
        syncPolicy: manual
        
      # Production Environment
      - environment: prod
        namespace: numgen-prod
        valuesFile: values-prod.yaml
        syncPolicy: manual

  template:
    metadata:
      name: 'numgen-{{environment}}'
      labels:
        app: numgen
        environment: '{{environment}}'
    spec:
      project: default
      
      source:
        repoURL: https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
        targetRevision: feature/appSet
        path: numgen-stack
        helm:
          valueFiles:
          - values.yaml
          - '{{valuesFile}}'
      
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      
      syncPolicy:
        syncOptions:
        - CreateNamespace=true
```

### Deploy ApplicationSet

```bash
# Navigate back to root directory
cd ../..

# Apply ApplicationSet configuration
kubectl apply -f applicationset/numgen-applicationset.yaml
```

### Environment-Specific Synchronization

After applying the ApplicationSet, you'll see three applications in ArgoCD UI:
- `numgen-dev` - **Automated sync** enabled
- `numgen-staging` - **Manual sync** required
- `numgen-prod` - **Manual sync** required

#### Sync Development Environment
```bash
# Development syncs automatically, or manually trigger:
# In ArgoCD UI: Select numgen-dev → Sync → Synchronize
```

#### Verify Development Deployment
```bash
# Check all resources in dev environment
kubectl get all -n numgen-dev

# Port forward development services
kubectl port-forward -n numgen-dev --address 0.0.0.0 service/numgen 3000:3000 &
kubectl port-forward -n numgen-dev --address 0.0.0.0 service/mongo-express 8081:8081 &
```

#### Sync Additional Environments
For staging and production environments, manual sync is required:

**Staging Environment:**
```bash
# In ArgoCD UI: Select numgen-staging → Sync → Synchronize
# Verify deployment
kubectl get all -n numgen-staging

# Port forward staging services (different ports)
kubectl port-forward -n numgen-staging --address 0.0.0.0 service/numgen 3001:3000 &
kubectl port-forward -n numgen-staging --address 0.0.0.0 service/mongo-express 8082:8081 &
```

**Production Environment:**
```bash
# In ArgoCD UI: Select numgen-prod → Sync → Synchronize  
# Verify deployment
kubectl get all -n numgen-prod

# Port forward production services (different ports)
kubectl port-forward -n numgen-prod --address 0.0.0.0 service/numgen 3002:3000 &
kubectl port-forward -n numgen-prod --address 0.0.0.0 service/mongo-express 8083:8081 &
```

## 🎛️ Environment-Specific Access URLs

**🎯 Development Environment:**
- **NumGen Application**: `http://<ec2-instance-ip>:3000`
- **Mongo Express**: `http://<ec2-instance-ip>:8081`

**🎯 Staging Environment:**
- **NumGen Application**: `http://<ec2-instance-ip>:3001`
- **Mongo Express**: `http://<ec2-instance-ip>:8082`

**🎯 Production Environment:**
- **NumGen Application**: `http://<ec2-instance-ip>:3002`
- **Mongo Express**: `http://<ec2-instance-ip>:8083`

**🌐 ArgoCD Dashboard**: `https://<ec2-instance-ip>:8443`

## 🔧 Environment-Specific Configuration

### Development (values-dev.yaml)
- **Replicas**: 1 (resource efficient)
- **Image**: Latest/development tags
- **Resources**: Minimal limits
- **Sync Policy**: Automated
- **Storage**: Smaller PVC sizes

### Staging (values-staging.yaml)
- **Replicas**: 2 (load testing)
- **Image**: Release candidate tags
- **Resources**: Moderate limits
- **Sync Policy**: Manual (controlled releases)
- **Storage**: Production-like sizes

### Production (values-prod.yaml)
- **Replicas**: 3+ (high availability)
- **Image**: Stable/versioned tags
- **Resources**: Full production limits
- **Sync Policy**: Manual (strict control)
- **Storage**: Full production sizes
- **Monitoring**: Enhanced health checks

## 🔄 GitOps Workflow Testing

### 1. Environment-Specific Changes
```bash
# Clone and modify environment-specific values
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp/numgen-stack

# Edit values-dev.yaml - increase dev replicas
numgen:
  deployment:
    replicas: 2  # Changed from 1

# Commit and push changes
git add values-dev.yaml
git commit -m "Scale dev environment NumGen to 2 replicas"
git push origin feature/appSet
```

### 2. Observe Sync Behavior
- **Development**: Changes sync automatically
- **Staging/Production**: Remain OutOfSync until manually triggered

### 3. Promote Changes Through Environments
```bash
# 1. Test in development (auto-synced)
kubectl get pods -n numgen-dev -l app=numgen

# 2. Manually sync staging after verification
# ArgoCD UI: numgen-staging → Sync → Synchronize

# 3. Manually sync production after staging validation
# ArgoCD UI: numgen-prod → Sync → Synchronize
```

## 🚀 Legacy Single-Application Support

For backwards compatibility, the original single-application deployment is still supported:

```bash
# Deploy single application instead of ApplicationSet
kubectl apply -f argocd-application.yaml
```

This creates a single `numgen-app` in the `numgen-app` namespace with manual sync policy.

## 🎯 Key Features Demonstrated

### ✅ Advanced GitOps Principles
- **📝 Declarative Multi-Environment**: Infrastructure and applications across environments
- **🔄 Environment-Specific Automation**: Dev auto-sync, Staging/Prod manual control
- **🔍 Centralized Observability**: Single ArgoCD instance managing multiple environments
- **🛡️ Environment Isolation**: Separate namespaces and configurations

### ✅ ApplicationSet Capabilities
- **🌐 Multi-Environment Management**: Single ApplicationSet creates multiple applications
- **🔧 Template-Based Configuration**: Parameterized application definitions
- **📊 Environment-Specific Values**: Tailored configurations per environment
- **🚀 Scalable Deployment**: Easy addition of new environments

### ✅ Production-Ready Practices
- **🏗️ Infrastructure as Code**: Terraform-managed AWS resources
- **📦 Helm Charts**: Environment-specific value overrides
- **🔐 Security**: ECR integration and Kubernetes secrets
- **📊 Monitoring**: Per-environment health checks and metrics
- **🔄 Controlled Promotions**: Manual approval for production deployments

## 🛠️ Troubleshooting

### ApplicationSet-Specific Issues

#### ApplicationSet Not Creating Applications
```bash
# Check ApplicationSet status
kubectl get applicationset -n argocd
kubectl describe applicationset numgen-multi-env -n argocd

# Check ArgoCD ApplicationSet controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller
```

#### Applications Stuck in OutOfSync
```bash
# Check individual application status
kubectl describe application numgen-dev -n argocd
kubectl describe application numgen-staging -n argocd
kubectl describe application numgen-prod -n argocd

# Force refresh all applications
kubectl patch application numgen-dev -n argocd --type='merge' -p='{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

#### Environment-Specific Failures
```bash
# Check namespace-specific events
kubectl get events -n numgen-dev --sort-by=.metadata.creationTimestamp
kubectl get events -n numgen-staging --sort-by=.metadata.creationTimestamp
kubectl get events -n numgen-prod --sort-by=.metadata.creationTimestamp

# Validate environment-specific values
helm template numgen-dev ./numgen-stack -f ./numgen-stack/values.yaml -f ./numgen-stack/values-dev.yaml
helm template numgen-staging ./numgen-stack -f ./numgen-stack/values.yaml -f ./numgen-stack/values-staging.yaml
helm template numgen-prod ./numgen-stack -f ./numgen-stack/values.yaml -f ./numgen-stack/values-prod.yaml
```

## 📊 Multi-Environment Monitoring

### Environment Health Overview
```bash
# Check all environments at once
kubectl get pods -A | grep numgen

# Environment-specific resource monitoring
kubectl top pods -n numgen-dev
kubectl top pods -n numgen-staging  
kubectl top pods -n numgen-prod
```

### ApplicationSet Monitoring
```bash
# Monitor ApplicationSet and generated applications
kubectl get applications -n argocd -l app=numgen
kubectl get applicationset numgen-multi-env -n argocd -o yaml
```

## 🚀 Advanced ApplicationSet Features

### Adding New Environments
Add new environments by extending the ApplicationSet generator:

```yaml
# Add QA environment
- environment: qa
  namespace: numgen-qa
  valuesFile: values-qa.yaml
  syncPolicy: manual
```

### Branch-Based Environments
Target different branches per environment:

```yaml
# Development tracks feature branch
- environment: dev
  namespace: numgen-dev
  valuesFile: values-dev.yaml
  targetRevision: develop
  
# Production tracks stable branch  
- environment: prod
  namespace: numgen-prod
  valuesFile: values-prod.yaml
  targetRevision: main
```

### Cluster-Based Multi-Environment
Deploy to different clusters:

```yaml
- environment: dev
  cluster: https://dev-cluster.example.com
  namespace: numgen
  
- environment: prod
  cluster: https://prod-cluster.example.com
  namespace: numgen
```

## 🎯 Learning Outcomes

This enhanced implementation demonstrates mastery of:

- **🔄 Advanced GitOps**: Multi-environment GitOps with ApplicationSet
- **🌐 Environment Management**: Development, staging, production workflows
- **⚓ Kubernetes Orchestration**: Complex multi-service, multi-environment applications
- **🏗️ Infrastructure as Code**: Terraform cloud resource management
- **📦 Advanced Helm**: Environment-specific value overrides and templating
- **🔐 Security Practices**: Environment isolation and controlled promotions
- **📊 Observability**: Multi-environment monitoring and health checks
- **🛠️ Troubleshooting**: Complex multi-environment debugging

## 🌟 Migration Guide

### From Single Application to ApplicationSet

If you have an existing single application deployment:

1. **Backup Current State**:
   ```bash
   kubectl get application numgen-app -n argocd -o yaml > backup-single-app.yaml
   ```

2. **Delete Single Application**:
   ```bash
   kubectl delete application numgen-app -n argocd
   ```

3. **Deploy ApplicationSet**:
   ```bash
   kubectl apply -f applicationset/numgen-applicationset.yaml
   ```

4. **Sync New Applications** as described in the deployment section.

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
- [ApplicationSet Controller](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) for multi-environment management
- [Bitnami](https://bitnami.com/) for production-ready Helm charts
- [Kubernetes Community](https://kubernetes.io/) for container orchestration
- [Terraform](https://terraform.io/) for infrastructure automation

---

⭐ **Star this repository** if you found this GitOps ApplicationSet implementation helpful!

🔄 **Fork and adapt** for your own multi-environment projects and learning journey!