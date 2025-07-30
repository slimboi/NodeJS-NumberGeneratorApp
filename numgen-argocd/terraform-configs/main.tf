terraform {
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "0.5.2"
    }
  }
}

provider "minikube" {
  kubernetes_version = "v1.33.0"
}

resource "minikube_cluster" "minikube_numgen" {
  driver       = "docker"
  cluster_name = "numgen-app-project"
  addons = [
    "default-storageclass",
    "storage-provisioner"
  ]
}