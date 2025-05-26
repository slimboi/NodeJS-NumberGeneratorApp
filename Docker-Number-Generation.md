🧪 NodeJS Number Generator – Docker Networking Practice

This project is part of my learning journey into Docker networking, demonstrating how to bridge multiple containers (Node.js app, MongoDB, and Mongo Express) using a custom Docker network.

⸻

📥 Clone the Repository

git clone https://github.com/seunayolu/NodeJS-NumberGeneratorApp.git
cd NodeJS-NumberGeneratorApp

⸻

🔁 Reinitialize Git (for personal use)

rm -rf .git
git init
git add .
git commit -m "Initial commit"

Link it to your own GitHub repository:

git remote add origin git@github-personal:slimboi/NodeJS-NumberGeneratorApp.git
git push -u origin main

cd NodeJS-NumberGeneratorApp/app-docker

⸻

🐳 Docker Workflow

1️⃣ Build the Docker Image

docker build -t numgen .

2️⃣ Create a Custom Docker Network

docker network create mongo

3️⃣ Run MongoDB Container

docker run --rm -d --network mongo --name mongo mongo

4️⃣ Run Mongo Express (UI for MongoDB)

docker run --rm -d --network mongo \
  -e ME_CONFIG_MONGODB_SERVER=mongo \
  -p 8081:8081 \
  --name mongo-express \
  mongo-express

Verify Mongo Express:
Navigate to http://localhost:8081
Use credentials: admin:pass

5️⃣ Run the Number Generator App

docker run -d --rm \
  --name numgen \
  --network mongo \
  -p 3000:3000 \
  numgen

Verify App:
Navigate to http://localhost:3000

⸻

🧾 Logs & Status

To check if the app is working properly:

docker logs numgen

Expected output:

Server running on port 3000
Connected to MongoDB

⸻

🧹 Cleanup Docker Containers (Optional)

To stop all running containers, run:

docker stop $(docker ps -q)

💡 docker ps -q lists all running container IDs, and docker stop stops them.

If you also want to remove all containers (use with caution):

docker rm $(docker ps -aq)

⚠️ This will delete all containers, including stopped ones.

To remove all volumes and networks, if needed:

docker volume prune
docker network prune

⚠️ Be careful — this will delete unused Docker resources system-wide.

⸻
🎯 Learning Goal
	•	Understand Docker bridge networking
	•	Practice inter-container communication using a shared network
	•	Connect a backend Node.js app to MongoDB and expose a management UI via Mongo Express

⸻

💾 Docker Volumes: Essential for Data Persistence

By default, containers are ephemeral — once stopped or removed, their data is lost. Docker volumes allow persistent storage by mapping data directories to named volumes.

⸻

🔨 Step-by-Step: Add Persistent Storage to MongoDB

1️⃣ Create a Named Volume

docker volume create mongodb

2️⃣ Start MongoDB with the Volume Attached

docker run --rm -d \
  --network mongo \
  -v mongodb:/data/db \
  --name mongo \
  mongo

This command mounts the named volume mongodb to the internal MongoDB data directory /data/db.

3️⃣ Start Mongo Express (MongoDB UI)

docker run --rm -d \
  --network mongo \
  -e ME_CONFIG_MONGODB_SERVER=mongo \
  -p 8081:8081 \
  --name mongo-express \
  mongo-express

4️⃣ Start the Node.js Number Generator App

docker run -d --rm \
  --name numgen \
  --network mongo \
  -p 3000:3000 \
  numgen


⸻

✅ Test Persistence
	1.	Navigate to http://localhost:3000 and submit some data.
	2.	Navigate to http://localhost:8081 to inspect the data via Mongo Express.
	3.	Stop and remove the running containers:

docker stop $(docker ps -q)

	4.	Restart the containers using the same volume:

docker run --rm -d \
  --network mongo \
  -v mongodb:/data/db \
  --name mongo \
  mongo

docker run --rm -d \
  --network mongo \
  -e ME_CONFIG_MONGODB_SERVER=mongo \
  -p 8081:8081 \
  --name mongo-express \
  mongo-express

docker run -d --rm \
  --name numgen \
  --network mongo \
  -p 3000:3000 \
  numgen

	5.	Go back to the app or Mongo Express — your data should still be there 🎉

⸻