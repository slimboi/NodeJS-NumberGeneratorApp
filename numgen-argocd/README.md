# Numgen App ArgoCD  🚀

A production-ready GitOps DevOps pipeline demonstrating end-to-end automation with Flask microservices, Kubernetes orchestration, Argo CD GitOps, and Infrastructure as Code using modern DevOps practices.

[![flask-kubernetes-pipeline](https://github.com/slimboi/flask-kubernetes-pipeline/actions/workflows/ci.yaml/badge.svg)](https://github.com/slimboi/flask-kubernetes-pipeline/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Made with Flask](https://img.shields.io/badge/made%20with-Flask-blue)](https://flask.palletsprojects.com/)
[![Python 3.13](https://img.shields.io/badge/python-3.13-blue.svg)](https://www.python.org/downloads/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/slimboi/flask-kubernetes-pipeline)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-orange.svg)](https://argoproj.github.io/cd/)

## 🎯 Project Overview

This project showcases a complete GitOps DevOps pipeline that includes:
- **Application Development**: Python Flask web application
- **Containerization**: Security-hardened Docker containers with non-root users
- **Infrastructure as Code**: Terraform for automated infrastructure provisioning
- **Container Orchestration**: Kubernetes deployment on Minikube
- **GitOps Deployment**: ArgoCD for declarative continuous delivery
- **Package Management**: Helm charts for Kubernetes applications
- **CI/CD Pipeline**: GitHub Actions with automated GitOps workflows

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flask App     │───▶│   Docker        │───▶│   Kubernetes    │
│   (Python)      │    │   Container     │    │   (Minikube)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ▲                       ▲
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Terraform     │    │   ArgoCD        │
                       │   (IaC)         │    │   (GitOps)      │
                       └─────────────────┘    └─────────────────┘
                                                       ▲
                                              ┌─────────────────┐
                                              │   Helm Charts   │
                                              │   (Packaging)   │
                                              └─────────────────┘
```

## 🛠️ Technology Stack

| Category | Technology |
|----------|------------|
| **Application** | Python 3.13, Flask |
| **Containerization** | Docker, Alpine Linux |
| **Infrastructure** | Terraform, Minikube |
| **Orchestration** | Kubernetes |
| **GitOps** | ArgoCD |
| **Package Management** | Helm Charts |
| **CI/CD** | GitHub Actions |
| **Registry** | Docker Hub |
| **Version Control** | Git, GitHub |

## 📋 Prerequisites

Before running this project, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) (v1.25+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (v1.25+)
- [Git](https://git-scm.com/downloads)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd numgen-argocd
```

### 2. Infrastructure Provisioning
```bash
# Navigate to Terraform configurations
cd terraform-configs/

# Initialize Terraform
terraform init

# Format Terraform files
terraform fmt

# Plan infrastructure changes
terraform plan

# Apply infrastructure
terraform apply
```

### 3. Deploy ArgoCD and Setup GitOps
```bash
# Apply ArgoCD installation
terraform apply

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

### 4. Configure ArgoCD Repository Access

**GitHub Setup Requirements:**
1. **Create Personal Access Token (PAT)**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Name: `numgen-app-token`
   - Scopes: Select `repo` (full repository access)

2. **Configure GitHub Actions Permissions**:
   - Go to Repository Settings → Actions → General
   - Under "Workflow permissions" choose "Read and write permissions"

```bash
# Login to ArgoCD CLI
argocd login localhost:8443 --username admin --password <admin-password> --insecure

# Add GitHub repository to ArgoCD
argocd repo add https://github.com/slimboi/flask-kubernetes-pipeline.git \
  --username <your-github-username> \
  --password <github-personal-access-token> \
  --server localhost:8443 --insecure
```

### 5. Deploy Application via ArgoCD
```bash
# Go back to root directory of project
cd ..

# Apply ArgoCD application configuration
kubectl apply -f argocd-app.yaml

# Verify application deployment
kubectl get applications -n argocd
```

### 6. Access the Application
```bash
# Get service details
kubectl get svc -n default

# Port forward to access application (avoid port 8080 if ArgoCD is using it)
kubectl port-forward svc/<service-name> -n default 8085:8080

# Alternative: Access via pod directly
kubectl get pods -n default
kubectl port-forward pod/<pod-name> -n default 8085:8080

# Access your application at: http://localhost:8085
```

### 7. Testing the GitOps Pipeline
```bash
# Make a simple change to app.py
# Example: Change "The current time of the day:" to "The current time of the day is:"

# Commit and push changes
git add app.py
git commit -m "Update time message format"
git push origin main

# Monitor the pipeline:
# 1. Check GitHub Actions for CI pipeline
# 2. Check ArgoCD UI for automatic deployment
# 3. Verify application update in Kubernetes
```

### 8. Verify Deployment Status
```bash
# Check cluster nodes
kubectl get nodes

# Verify ArgoCD installation
kubectl get pods -n argocd

# Check ArgoCD applications
kubectl get applications -n argocd

# Check application deployment
kubectl get pods,svc -n default

# View ArgoCD applications in UI
# Navigate to Applications tab in ArgoCD dashboard
```

### 9. Manual Testing (Optional)
```bash
# Build Docker image
docker build -t flask-time-app .

# Run container locally
docker run -p 8080:8080 flask-time-app
```

## 📁 Project Structure

```
flask-kubernetes-pipeline/
├── app.py                 # Flask application
├── Dockerfile            # Container configuration
├── argocd-app.yaml       # ArgoCD application configuration
├── terraform-configs/
│   ├── main.tf          # Main Terraform configuration
│   ├── provider.tf      # Provider configurations
│   └── argocd.tf        # ArgoCD Helm deployment
├── helm-chart/
│   ├── values.yaml      # Helm chart values
│   └── templates/
│       └── deployment.yaml  # Kubernetes deployment template
├── .github/workflows/
│   └── ci.yml           # GitHub Actions CI/CD pipeline
└── README.md           # Project documentation
```

## 🔧 Application Details

### Flask Application (`app.py`)
- **Endpoint**: `/` - Returns current timestamp
- **Port**: 8080
- **Features**: 
  - Lightweight Python web server
  - Real-time timestamp display
  - Health check ready

### Docker Configuration (`Dockerfile`)
- **Base Image**: `python:3.13-alpine` (lightweight)
- **Security**: Non-root user implementation (appuser)
- **Optimization**: Requirements caching for faster builds
- **Working Directory**: `/app`
- **Exposed Port**: 8080
- **Best Practices**: Layer optimization and proper ownership

### ArgoCD Application Configuration (`argocd-app.yaml`)
- **Application Name**: `flask-kubernetes-pipeline`
- **Source Repository**: GitHub repository with Helm charts
- **Target Path**: `helm-chart` (Helm chart directory)
- **Destination**: Default namespace in local Kubernetes cluster
- **Sync Policy**: 
  - **Automated**: Enables automatic synchronization
  - **Prune**: Removes resources not defined in Git
  - **Self-Heal**: Automatically corrects configuration drift

### Terraform Infrastructure
- **Minikube Cluster**: Automated cluster provisioning
- **ArgoCD Installation**: Helm-based ArgoCD deployment
- **Kubernetes Provider**: Integrated cluster management

## 📊 Key DevOps Practices Demonstrated

### Infrastructure as Code (IaC)
- Terraform for reproducible infrastructure
- Version-controlled infrastructure definitions
- Automated cluster provisioning

### Containerization Best Practices
- **Security-focused Docker builds** with non-root user
- **Lightweight Alpine Linux base** for minimal attack surface
- **Optimized layer caching** with requirements separation
- **Proper file permissions** and ownership management

### Kubernetes Orchestration
- Automated cluster setup
- Scalable container deployment
- Service discovery and load balancing

### GitOps with ArgoCD
- Declarative continuous deployment
- Automated application synchronization
- Git-based configuration management
- Self-healing deployments

### Helm Package Management
- Templated Kubernetes manifests
- Values-based configuration
- Version-controlled deployments
- Reusable application packaging

### CI/CD Pipeline
- GitHub Actions for automated builds
- Docker Hub integration for image registry
- Git SHA-based image tagging
- Secure credential management

### Configuration Management
- Structured project organization
- Environment-specific configurations
- Secrets management ready

## 🔍 Monitoring and Health Checks

The application includes basic health monitoring:
- **Health Endpoint**: `/` returns HTTP 200 with timestamp
- **Container Health**: Docker health checks can be added
- **Kubernetes Readiness**: Ready for liveness and readiness probes

## 🚦 GitOps CI/CD Pipeline

The project implements a complete GitOps workflow using GitHub Actions and ArgoCD:

### CI Pipeline (GitHub Actions)
- **Automated Builds**: Triggers on every push to main branch
- **Docker Image Building**: Creates containerized application images
- **Image Tagging**: Uses Git SHA for unique versioning
- **Registry Integration**: Pushes images to Docker Hub
- **GitOps Integration**: Updates Helm values with new image tags
- **Automated Git Operations**: Commits and pushes changes back to repository

### CD Pipeline (ArgoCD GitOps)
- **Declarative Deployment**: ArgoCD monitors Git repository for changes
- **Automated Sync**: Automatically deploys new versions to Kubernetes
- **Rollback Capability**: Easy rollback to previous versions
- **Health Monitoring**: Continuous application health checks
- **Self-Healing**: Automatic drift detection and correction

### Complete GitOps Workflow
```yaml
Code Push → GitHub Actions → Build Image → Push to Registry → 
Update Helm Values → Git Commit → ArgoCD Sync → Deploy to K8s
```

### Setup Instructions
1. **Configure GitHub Secrets**:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token

2. **Setup Git Credentials** for automated commits:
   ```bash
   git config --global user.email "your-email@example.com"
   git config --global user.name "Your Name"
   ```

3. **Deploy ArgoCD** using Terraform:
   ```bash
   terraform apply
   ```

4. **Create ArgoCD Application** (manual step):
   - Access ArgoCD UI at `https://localhost:8443`
   - Create new application pointing to your Git repository
   - Set sync policy to automatic

### Pipeline Benefits
- **True GitOps**: Single source of truth in Git
- **Automated Deployments**: Zero-touch deployments
- **Version Control**: Full audit trail of deployments
- **Rollback Capability**: Quick rollback to any previous version
- **Security**: Secure credential management
- **Monitoring**: Built-in deployment monitoring and alerting

## 📈 Scaling and Production Considerations

For production deployment, consider:
- **Security**: Implement proper authentication and authorization
- **Monitoring**: Add comprehensive logging and monitoring
- **High Availability**: Multi-node cluster configuration
- **Backup**: Database and configuration backup strategies
- **SSL/TLS**: HTTPS termination and certificate management

## 🐛 Troubleshooting

### Common Issues

**Port forwarding errors:**
```bash
# Get the correct service name first
kubectl get svc -n default
kubectl port-forward svc/<service-name> -n default 8085:8080

# Alternative: Access via pod directly
kubectl get pods -n default
kubectl port-forward pod/<pod-name> -n default 8085:8080
```

**ArgoCD sync issues:**
```bash
# Force sync ArgoCD application
argocd app sync <app-name> --server localhost:8443

# Check application status
argocd app get <app-name> --server localhost:8443
```

**Minikube won't start:**
```bash
minikube delete
minikube start --driver=docker
```

**GitHub Actions permission issues:**
```bash
# Ensure repository has "Read and write permissions" enabled
# Repository Settings → Actions → General → Workflow permissions
```

**Terraform errors:**
```bash
terraform destroy
terraform apply
```

**Docker permission issues:**
```bash
sudo usermod -aG docker $USER
# Log out and log back in
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flask team for the lightweight web framework
- Terraform team for excellent IaC tooling
- Kubernetes community for container orchestration
- Docker team for containerization technology

## 📞 Contact

**Contact** - [ola.fagbule@gmail.com](mailto:your.email@example.com)

Project Link: [https://github.com/slimboi/flask-kubernetes-pipeline](https://github.com/slimboi/flask-kubernetes-pipeline)

---

⭐ **Star this repository if you found it helpful!** ⭐