resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version
  namespace  = var.metrics_server_namespace

  values = [yamlencode({
    image = {
      tag = var.metrics_server_image_tag
    }

    serviceAccount = {
      create = true
      name   = var.metrics_server_service_account_name
    }

    defaultArgs = [
      "--cert-dir=/tmp",
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s",
    ]

    tolerations = [
      {
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }

    resources = {
      requests = {
        cpu    = "100m"
        memory = "200Mi"
      }
    }
  })]

  depends_on = [module.eks]
}
