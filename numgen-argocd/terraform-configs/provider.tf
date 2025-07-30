provider "kubernetes" {
  host                   = minikube_cluster.minikube_numgen.host
  client_certificate     = minikube_cluster.minikube_numgen.client_certificate
  client_key             = minikube_cluster.minikube_numgen.client_key
  cluster_ca_certificate = minikube_cluster.minikube_numgen.cluster_ca_certificate
}

provider "helm" {
  kubernetes = {
    host                   = minikube_cluster.minikube_numgen.host
    client_certificate     = minikube_cluster.minikube_numgen.client_certificate
    client_key             = minikube_cluster.minikube_numgen.client_key
    cluster_ca_certificate = minikube_cluster.minikube_numgen.cluster_ca_certificate
  }
}