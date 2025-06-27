# Deploying a Helm Application on Minikube (AWS EC2)

This guide demonstrates how to deploy a containerized application using Helm on a Minikube cluster running on an Amazon EC2 Ubuntu instance. The application uses images stored in AWS ECR (Elastic Container Registry).

## Overview

This project includes:
- Setting up Minikube on an EC2 instance
- Configuring AWS ECR access
- Deploying a multi-component application (`numgen-app`) using Helm
- Managing the deployment lifecycle

## Prerequisites

### AWS Requirements
- AWS account with ECR access
- EC2 instance (t3.medium or larger recommended)
- Security group configured for necessary ports
- AWS CLI credentials configured

### EC2 Instance Requirements
- **Instance Type**: t3.medium or larger (minimum 2 CPUs, 2GB RAM)
- **OS**: Ubuntu 20.04 LTS or newer
- **Storage**: 20GB+ recommended
- **Virtualization**: Support enabled

## Step 1: Initial Setup

### Connect to your EC2 instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Update the system
```bash
sudo apt update && sudo apt upgrade -y
```

## Step 2: Install Docker

```bash
# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

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

## Step 3: Install Kubernetes Tools

### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Install Minikube
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Install Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Step 4: Start Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify installation
minikube status
kubectl get nodes
```

## Step 5: Configure AWS ECR Access

### Install AWS CLI
```bash
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configure AWS credentials
```bash
aws configure
```
Enter your AWS credentials when prompted.

### Authenticate with ECR
```bash
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 475325513391.dkr.ecr.ap-southeast-2.amazonaws.com
```

## Step 6: Prepare Kubernetes Environment

### Create namespace
```bash
kubectl create ns numgen-app
```

### Create ECR secret for image pulling
```bash
kubectl create secret docker-registry ecr-secret \
  --docker-server=475325513391.dkr.ecr.ap-southeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \
  --namespace=numgen-app
```

### Verify secret creation
```bash
kubectl get secret -n numgen-app
```

## Step 7: Deploy Application with Helm

### Transfer Helm chart to EC2
From your local machine:
```bash
scp -i your-key.pem -r ./numgen-app ubuntu@your-ec2-ip:~/
```

### Navigate to chart directory
```bash
cd ~/numgen-app
```

### Validate and deploy
```bash
# Validate the Helm chart
helm lint .

# Test template rendering (optional)
helm template numgen-release . --debug

# Install the application
helm install numgen-release .
```

## Step 8: Verify Deployment

### Check Helm release
```bash
helm list
```

### Verify Kubernetes resources
```bash
# Check all resources in namespace
kubectl get all -n numgen-app

# Check pods status
kubectl get pods -n numgen-app

# Check services
kubectl get services -n numgen-app

# Check deployment status
kubectl get deployments -n numgen-app
```

## Step 9: Access Applications

### Port forwarding for external access
```bash
# Forward numgen service to port 8080
kubectl port-forward -n numgen-app --address 0.0.0.0 service/numgen 8080:3000 &

# Forward mongo-express service to port 8081
kubectl port-forward -n numgen-app --address 0.0.0.0 service/mongo-express 8081:8081 &
```

### Access applications
- **Numgen App**: http://your-ec2-ip:8080
- **Mongo Express**: http://your-ec2-ip:8081

> **Note**: Ensure your EC2 security group allows inbound traffic on ports 8080 and 8081.

## What Success Looks Like

When your deployment is successful, you should see:

### 1. Application Interface (NomCombo)
The main application will be accessible at port 8080 and should display:
- A web form titled "NomCombo"
- Input fields for Username, String Length, and Number of Combinations
- Generate and Clear Results buttons
- Success messages when combinations are generated and saved

### 2. Kubernetes Resources Running
Your `kubectl get all -n numgen-app` command should show:
- **Pods**: All pods in "Running" status (mongo, mongo-express, numgen)
- **Services**: Three services with ClusterIP and NodePort types
- **Deployments**: All deployments showing READY status (e.g., 2/2 for numgen)
- **ReplicaSets**: All with desired number of replicas ready

### 3. MongoDB Data Persistence
Access Mongo Express at port 8081 to verify:
- Database connection is working
- Collections are created when data is generated
- Generated combinations are stored in the database
- Data persists between application restarts

## Step 10: Cleanup

### Uninstall the Helm release
```bash
helm uninstall numgen-release
```

### Delete namespace (optional)
```bash
kubectl delete namespace numgen-app
```

### Stop Minikube
```bash
minikube stop
```

## Troubleshooting

### Common Issues

1. **Insufficient resources**: Ensure your EC2 instance has at least 2 CPUs and 2GB RAM
2. **Docker permission denied**: Make sure you've added your user to the docker group and reloaded the session
3. **ECR authentication**: Verify your AWS credentials and region settings
4. **Port forwarding**: Check that your security group allows the required ports

### Useful Commands

```bash
# Check Minikube logs
minikube logs

# Check pod logs
kubectl logs -n numgen-app <pod-name>

# Describe resources for debugging
kubectl describe pod -n numgen-app <pod-name>

# Check Helm chart values
helm get values numgen-release
```

## Security Considerations

- Use least-privilege IAM policies for ECR access
- Regularly rotate ECR authentication tokens
- Configure appropriate security groups
- Consider using AWS Secrets Manager for sensitive data

## Next Steps

- Explore Helm chart customization with values.yaml
- Implement CI/CD pipeline for automated deployments
- Learn about Kubernetes networking and ingress controllers
- Investigate monitoring and logging solutions

---

**Note**: This guide uses specific AWS account and region details. Adjust the ECR repository URL and region according to your setup.