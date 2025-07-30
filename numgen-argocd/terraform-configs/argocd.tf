resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argocd"
  create_namespace = "true"

  # Explicitly depend on the cluster being ready
  depends_on = [minikube_cluster.minikube_numgen]

  values = [
    <<EOF
        server:
          service:
            type: ClusterIP
        EOF
  ]
}