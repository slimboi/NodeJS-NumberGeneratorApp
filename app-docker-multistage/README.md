# 🚀 Node.js Number Generator App with CI/CD Pipeline

![CI/CD Pipeline](https://github.com/slimboi/NodeJS-NumberGeneratorApp/workflows/Node.js%20CI%20with%20Docker%20+%20ECR/badge.svg)
![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A simple Node.js application that generates random numbers, demonstrating a complete CI/CD pipeline using GitHub Actions. The pipeline includes automated linting, testing, Docker containerization, and deployment to AWS ECR.

## 🌟 Features

- **Random Number Generation**: Core Node.js application functionality
- **Automated CI/CD**: Complete pipeline with GitHub Actions
- **Code Quality**: ESLint linting and automated testing
- **Containerization**: Multi-stage Docker build for optimized images
- **Cloud Deployment**: Automated push to private AWS ECR repository

## 🏗️ Project Structure

```
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions CI/CD pipeline
├── app-docker-multistage/
│   ├── app.js              # Main application file
│   ├── test.js             # Unit tests
│   ├── package.json        # Node.js dependencies
│   ├── package-lock.json   # Dependency lock file (required for npm ci)
│   ├── Dockerfile          # Multi-stage Docker build
│   └── eslint.config.mjs   # ESLint configuration
├── .gitignore              # Git ignore rules (ensure package-lock.json is NOT listed)
└── README.md
```

## 🔧 Prerequisites

### 🖥️ Local Development
- [Node.js](https://nodejs.org/) version 18 or later
- [npm](https://www.npmjs.com/) (comes with Node.js)
- Docker installed and running ([Docker Desktop](https://www.docker.com/products/docker-desktop))

### ☁️ AWS Requirements
- An **AWS account** with ECR permissions
- A **private ECR repository** created in your AWS account
  - Example: `123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/my-node-app`
- IAM user with ECR push/pull permissions

### 🔐 GitHub Secrets Setup

Navigate to your repository → Settings → Secrets and variables → Actions, then add:

| Secret Name              | Description                                    | Example Value                                           |
|--------------------------|------------------------------------------------|---------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`      | Your AWS IAM user access key                  | `AKIAIOSFODNN7EXAMPLE`                                  |
| `AWS_SECRET_ACCESS_KEY`  | Your AWS IAM user secret key                  | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`              |
| `AWS_REGION`             | AWS region where ECR is located               | `ap-southeast-2`                                        |
| `ECR_REPOSITORY`         | Full ECR repository URI                        | `123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/my-node-app` |

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp/app-docker-multistage

# Install dependencies
npm install
```

### 2. Local Development

```bash
# Run the application
node app.js

# Run tests
npm test

# Run linting
npm run lint
```

### 3. Docker Development

```bash
# Build Docker image
docker build -t my-node-app .

# Run container locally
docker run -p 3000:3000 my-node-app
```

## 📦 Project Setup from Scratch

If you want to recreate this setup in your own project:

### 1. Initialize Node.js Project

```bash
mkdir my-node-app && cd my-node-app
npm init -y
```

### 2. Install and Configure ESLint

```bash
npm install eslint -D
npm init @eslint/config@latest
```

### 3. Update package.json Scripts

```json
{
  "scripts": {
    "start": "node app.js",
    "test": "node test.js",
    "lint": "eslint ."
  }
}
```

### 4. Create GitHub Actions Workflow

Create `.github/workflows/ci.yml` with the provided configuration below.

## ⚙️ CI/CD Pipeline Configuration

Create `.github/workflows/ci.yml`:

```yaml
name: Node.js CI with Docker + ECR

on:
  push:
    branches:
      - main
      - 'feature/**'
    paths:
      - 'README.md'
      - '*.md'
  pull_request:
    branches:
      - main
      - 'feature/**'
    paths:
      - 'README.md'
      - '*.md'

jobs:
  checkout:
    name: Checkout Code
    runs-on: ubuntu-latest

    outputs:
      short_sha: ${{ steps.set-sha.outputs.short_sha }}

    steps:
      - name: Checkout Repo
        uses: actions/checkout@v3

      - name: Set Short SHA
        id: set-sha
        run: echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"

  lint:
    name: ESLint Check
    runs-on: ubuntu-latest
    needs: checkout

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci
        working-directory: app-docker-multistage

      - run: npm run lint
        working-directory: app-docker-multistage

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci
        working-directory: app-docker-multistage

      - run: npm test
        working-directory: app-docker-multistage

  docker:
    name: Build & Push Docker Image
    runs-on: ubuntu-latest
    needs: test

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region ${{ secrets.AWS_REGION }} \
            | docker login --username AWS --password-stdin ${{ secrets.ECR_REPOSITORY }}

      - name: Build and Push Docker Image
        working-directory: app-docker-multistage
        run: |
          SHORT_SHA=${GITHUB_SHA::7}
          IMAGE=${{ secrets.ECR_REPOSITORY }}:$SHORT_SHA
          docker build -t $IMAGE .
          docker push $IMAGE
```

## 🔄 Deployment Process

### Testing the Pipeline

**Best Practice**: Test your pipeline on a feature branch first:

```bash
# Create and switch to feature branch
git checkout -b feature/ci-pipeline

# Make your changes
git add .
git commit -m "feat: add CI/CD pipeline with Docker and ECR"
git push origin feature/ci-pipeline
```

This triggers the pipeline on your feature branch, allowing you to:
- ✅ Verify all jobs pass (lint, test, docker build/push)
- ✅ Check ECR repository receives the Docker image
- ✅ Debug any issues before affecting main branch
- ✅ Review pipeline logs and timing

### Merging to Main

Once your feature branch pipeline passes successfully:

```bash
# Create Pull Request via GitHub UI, or use GitHub CLI
gh pr create --title "Add CI/CD Pipeline" --body "Implements automated pipeline with ESLint, tests, and ECR deployment"

# After review and approval, merge to main
# This will trigger the pipeline again on main branch
```

### Pipeline Triggers

The pipeline runs on:
- **Push to main**: Production deployments
- **Push to feature/** branches: Testing and validation  
- **Pull requests**: Code review validation

### What Happens During Pipeline Execution

1. **Code Checkout** 📥: Pipeline retrieves the code and generates a short SHA (`abc1234`)
2. **ESLint Check** 🧹: Code is linted for style and potential issues
3. **Testing** 🧪: Unit tests are executed to ensure functionality
4. **Docker Build** 🐳: Multi-stage Docker image is built and optimized
5. **ECR Push** ☁️: Image is tagged with commit SHA and pushed to AWS ECR

**Example ECR Image Tags:**
- Feature branch: `your-ecr-repo:6cc5dc5` (from commit SHA)
- Main branch: `your-ecr-repo:a1b2c3d` (from commit SHA)

## 🚧 Challenges Faced & Solutions

### 1. **Package Lock File Missing from Git**

**🔴 Problem**: Pipeline was failing during `npm ci` step with this exact error:
```
npm error The `npm ci` command can only install with an existing package-lock.json or
npm error npm-shrinkwrap.json with lockfileVersion >= 1. Run an install with npm@5 or
npm error later to generate a package-lock.json file, then try again.
```

**🕵️ Root Cause**: `package-lock.json` was listed in `.gitignore` and wasn't being committed to the repository.

**✅ Solution**: 
1. Remove `package-lock.json` from `.gitignore`:
```bash
# Edit .gitignore and remove this line:
# package-lock.json
```

2. Generate and commit the lock file:
```bash
# Generate package-lock.json locally
npm install

# Add and commit the lock file
git add package-lock.json
git commit -m "add package-lock.json for npm ci compatibility"
git push
```

**📝 Key Lesson**: 
- **Never ignore `package-lock.json`** in projects using `npm ci`
- `npm ci` is designed for CI/CD and requires the exact lock file for reproducible builds
- Many developers mistakenly add lock files to `.gitignore` - this breaks CI/CD pipelines

### 2. **Docker Image Not Found Between Jobs**

**🔴 Problem**: Initially split Docker build and push into separate jobs, but push job failed with:
```
Run SHORT_SHA=${GITHUB_SHA::7}
Error response from daemon: No such image: nomcombo-app:6cc5dc5
Error: Process completed with exit code 1.
```

**🕵️ Root Cause**: GitHub Actions jobs run on isolated virtual machines - Docker images built in one job aren't available in subsequent jobs.

**✅ Solution**: 
Combined build and push operations into a single job so they share the same Docker daemon:

```yaml
# ❌ Original approach (didn't work)
docker-build:
  steps:
    - name: Build Docker Image
      run: |
        SHORT_SHA=${GITHUB_SHA::7}
        IMAGE=${{ secrets.ECR_REPOSITORY }}:$SHORT_SHA
        docker build -t $IMAGE .

docker-push:
  needs: docker-build
  steps:
    - name: Push Docker Image  # ❌ Image not available here!
      run: |
        SHORT_SHA=${GITHUB_SHA::7}
        IMAGE=${{ secrets.ECR_REPOSITORY }}:$SHORT_SHA
        docker push $IMAGE

# ✅ Fixed approach (works)
docker:
  name: 🐳 Build & Push Docker Image
  steps:
    - name: 🛠️ Build and Push Docker Image
      run: |
        SHORT_SHA=${GITHUB_SHA::7}
        IMAGE=${{ secrets.ECR_REPOSITORY }}:$SHORT_SHA
        docker build -t $IMAGE .
        docker push $IMAGE
```

**📝 Key Lesson**: 
- Each GitHub Actions job runs on a fresh virtual machine
- Docker images, files, and environment variables don't persist between jobs
- Either combine related operations in one job, or use artifacts/registries to share data

## 🐛 Additional Troubleshooting

### Common Issues and Solutions

**ESLint Configuration Issues**
```bash
# If eslint.config.mjs is missing
npm init @eslint/config@latest

# Fix auto-fixable issues
npm run lint -- --fix
```

**Node.js Version Mismatches**
```bash
# Check your local Node version matches CI
node --version

# Update package.json engines field
"engines": {
  "node": ">=18.0.0"
}
```

**Docker Build Failures**
```bash
# Check Docker is running
docker --version

# Clear Docker cache if builds are slow/failing
docker system prune -a

# Test build locally first
docker build -t test-app .
```

**AWS ECR Authentication Issues**
```bash
# Test AWS credentials locally
aws ecr describe-repositories --region your-region

# Verify ECR repository exists
aws ecr describe-repositories --repository-names your-repo-name

# Test ECR login manually
aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-ecr-uri
```

**GitHub Actions Secrets Problems**
- Double-check secret names match exactly (case-sensitive)
- Verify ECR repository URI format: `account-id.dkr.ecr.region.amazonaws.com/repo-name`
- Ensure IAM user has `AmazonEC2ContainerRegistryPowerUser` policy
- Test AWS credentials work locally before adding to GitHub

**Working Directory Issues**
```yaml
# If your app is in a subdirectory, specify working-directory
- run: npm ci
  working-directory: app-docker-multistage
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow existing code style (enforced by ESLint)
- Write tests for new features
- Update documentation as needed
- Use conventional commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub Actions for CI/CD automation
- AWS ECR for container registry
- Docker for containerization
- ESLint for code quality

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Search existing [Issues](https://github.com/slimboi/NodeJS-NumberGeneratorApp/issues)
3. Create a new issue with detailed information

---

⭐ **Star this repository if you found it helpful!**