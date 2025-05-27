# Building a NodeJS Number Generator with Docker Networking: Multi-Container Architecture and Data Persistence

## Application Overview

This project demonstrates Docker networking fundamentals by connecting multiple containers in a unified environment. The application stack includes:
- NodeJS Number Generator Application
- MongoDB Database
- Mongo Express (Database Management UI)
- Custom Docker Network
- Persistent Volume Storage

## Step-by-Step Implementation Guide

### 1. Project Setup and Repository Configuration

#### 1.1 Clone the Repository
1. Open your terminal or command prompt
2. Execute the following commands:
   ```bash
   git clone https://github.com/slimboi/NodeJS-NumberGeneratorApp.git
   cd NodeJS-NumberGeneratorApp
   ```

#### 1.2 Reinitialize Git (Optional - for personal use)
1. Remove existing git configuration:
   ```bash
   rm -rf .git
   git init
   git add .
   git commit -m "Initial commit"
   ```
2. Link to your personal repository:
   ```bash
   git remote add origin <your personal github repo>
   git push -u origin main
   ```
3. Navigate to the Docker application directory:
   ```bash
   cd NodeJS-NumberGeneratorApp/app-docker
   ```

### 2. Docker Image Creation

#### 2.1 Build the Application Image
1. Ensure you're in the correct directory containing the Dockerfile
2. Build the Docker image:
   ```bash
   docker build -t numgen .
   ```
3. Verify the image was created successfully:
   ```bash
   docker images | grep numgen
   ```

### 3. Docker Network Configuration

#### 3.1 Create Custom Bridge Network
1. Create a dedicated network for container communication:
   ```bash
   docker network create mongo
   ```
2. Verify network creation:
   ```bash
   docker network ls | grep mongo
   ```

### 4. Database Container Deployment

#### 4.1 Deploy MongoDB Container
1. Start the MongoDB container with network attachment:
   ```bash
   docker run --rm -d --network mongo --name mongo mongo
   ```
2. Verify container status:
   ```bash
   docker ps | grep mongo
   ```

#### 4.2 Deploy Mongo Express Management UI
1. Start Mongo Express container with proper configuration:
   ```bash
   docker run --rm -d --network mongo \
     -e ME_CONFIG_MONGODB_SERVER=mongo \
     -p 8081:8081 \
     --name mongo-express \
     mongo-express
   ```
2. Verify Mongo Express accessibility:
   - Navigate to: `http://localhost:8081`
   - Default credentials: `admin:pass`

### 5. Application Container Deployment

#### 5.1 Deploy NodeJS Application
1. Start the Number Generator application:
   ```bash
   docker run -d --rm \
     --name numgen \
     --network mongo \
     -p 3000:3000 \
     numgen
   ```
2. Verify application accessibility:
   - Navigate to: `http://localhost:3000`

#### 5.2 Application Health Check
1. Monitor application logs:
   ```bash
   docker logs numgen
   ```
2. Expected output should include:
   ```
   Server running on port 3000
   Connected to MongoDB
   ```

### 6. Data Persistence Implementation

#### 6.1 Create Named Volume
1. Create a persistent volume for MongoDB data:
   ```bash
   docker volume create mongodb
   ```
2. Verify volume creation:
   ```bash
   docker volume ls | grep mongodb
   ```

#### 6.2 Deploy with Persistent Storage
1. Stop existing containers:
   ```bash
   docker stop $(docker ps -q)
   ```
2. Start MongoDB with volume attachment:
   ```bash
   docker run --rm -d \
     --network mongo \
     -v mongodb:/data/db \
     --name mongo \
     mongo
   ```
3. Start Mongo Express:
   ```bash
   docker run --rm -d \
     --network mongo \
     -e ME_CONFIG_MONGODB_SERVER=mongo \
     -p 8081:8081 \
     --name mongo-express \
     mongo-express
   ```
4. Start the application:
   ```bash
   docker run -d --rm \
     --name numgen \
     --network mongo \
     -p 3000:3000 \
     numgen
   ```

### 7. Testing and Verification

#### 7.1 Persistence Testing
1. **Data Creation**:
   - Navigate to `http://localhost:3000`
   - Submit test data through the application interface
2. **Data Verification**:
   - Navigate to `http://localhost:8081`
   - Verify data appears in Mongo Express interface
3. **Persistence Validation**:
   - Stop all containers: `docker stop $(docker ps -q)`
   - Restart containers using the same volume (repeat step 6.2)
   - Verify data persistence by checking both application and Mongo Express

#### 7.2 Network Connectivity Testing
1. Test inter-container communication:
   ```bash
   docker exec -it numgen ping mongo
   ```
2. Verify network configuration:
   ```bash
   docker network inspect mongo
   ```

### 8. Maintenance and Cleanup

#### 8.1 Container Management
1. View running containers:
   ```bash
   docker ps
   ```
2. Stop specific container:
   ```bash
   docker stop [container_name]
   ```
3. View container logs:
   ```bash
   docker logs [container_name]
   ```

#### 8.2 System Cleanup (Use with Caution)
1. **Stop all containers**:
   ```bash
   docker stop $(docker ps -q)
   ```
2. **Remove all containers** (⚠️ Destructive operation):
   ```bash
   docker rm $(docker ps -aq)
   ```
3. **Clean unused resources**:
   ```bash
   docker volume prune
   docker network prune
   ```

### Network Configuration
- **Custom Bridge Network**: `mongo`
- **Container Ports**:
  - NodeJS Application: `3000`
  - Mongo Express: `8081`
  - MongoDB: `27017` (internal)

### Data Persistence Strategy
- **Volume Name**: `mongodb`
- **Mount Point**: `/data/db`
- **Purpose**: Ensures data survives container restarts and removals

## Learning Objectives

This implementation demonstrates key Docker concepts:
- **Container Networking**: Custom bridge networks for service communication
- **Multi-Container Architecture**: Orchestrating related services
- **Data Persistence**: Using named volumes for stateful applications
- **Environment Configuration**: Container-specific environment variables
- **Port Mapping**: Exposing services to host system

## Troubleshooting

### Common Issues and Solutions

#### Application Won't Start
1. Check container logs: `docker logs numgen`
2. Verify network connectivity: `docker network inspect mongo`
3. Ensure MongoDB container is running: `docker ps | grep mongo`

#### Data Not Persisting
1. Verify volume attachment: `docker inspect mongo | grep -A 10 Mounts`
2. Check volume exists: `docker volume ls | grep mongodb`
3. Ensure proper mount path: `/data/db`

#### Network Communication Issues
1. Verify all containers are on same network: `docker network inspect mongo`
2. Test connectivity: `docker exec -it numgen ping mongo`
3. Check container names match network references

## Security Considerations

### Production Recommendations
- Use specific image tags instead of `latest`
- Implement proper authentication for Mongo Express
- Use Docker secrets for sensitive configuration
- Regularly update base images for security patches
- Implement network policies for container isolation

---