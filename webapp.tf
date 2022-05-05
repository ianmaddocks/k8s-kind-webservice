#microservice2.tf

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
  alias = "alias"
}

variable "cloudflare_zone_id" {
    type = string
    sensitive = true
}

resource "kubernetes_deployment" "microservice2_deployment" {
  depends_on = [helm_release.traefik]
  
  metadata {
    name = "microservice2-deploy"
    labels = {
      app = "microservice2"
    }
    namespace = "default"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "microservice2"
      }
    }
    min_ready_seconds   = "5"
    strategy {
        type            = "RollingUpdate"
        rolling_update {
          max_surge        = "1"
          max_unavailable  = "0"
        }
    }
    template {
      metadata {
        labels = {
           app = "microservice2"
        }
      }
      spec {
        container {
          image = "ianmaddocks/microservice2:v0.0.2"
          name  = "microservice2"
          port {
            container_port = 80
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "microservice2_ingress" {
  depends_on = [kubernetes_deployment.microservice2_deployment]

  metadata {
    name = "microservice2"
  }
  spec { 
    rule {
      http {
        path {
          backend {
            service {
              name = "microservice2-svc"
              port {
                number = 80
              }
            }
          }
          path = "/version"
        }
      }
    }
    tls {
          secret_name = "microservice2"
          hosts = ["microservice2.maddocks.name"]
    }
  }
}

resource "kubernetes_service_v1" "microservice2" {
  depends_on = [kubernetes_deployment.microservice2_deployment]

  metadata {
    name = "microservice2-svc"
  }
  spec {
    selector = {
      app = kubernetes_deployment.microservice2_deployment.metadata.0.labels.app
    }
    port {
      port  = 80
    }
    type = "ClusterIP"
  }
}

resource "kubectl_manifest" "microservice2-certificate" {

    depends_on = [time_sleep.wait_for_clusterissuer]

    yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: microservice2
  namespace: default
spec:
  secretName: microservice2
  issuerRef:
    name: cloudflare-prod
    kind: ClusterIssuer
  dnsNames:
  - 'microservice2.maddocks.name'   
    YAML
}

resource "cloudflare_record" "clcreative-main-cluster" {
    zone_id = var.cloudflare_zone_id #"your-zone-id"
    name = "microservice2.maddocks.name"
    value =  data.civo_loadbalancer.traefik_lb.public_ip #the public IP
    type = "A"
    proxied = false
}

output "public_ip_addr" {
  value       = data.civo_loadbalancer.traefik_lb.public_ip
  description = "The public IP address of the microservice2 server instance."
}
