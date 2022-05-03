#microservice2.tf

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
  alias = "alias"
}

resource "kubernetes_deployment" "microservice2_deployment" {
  metadata {
    name = "terraform-microservice2"
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
          image = "ianmaddocks/microservice2:v0.0.3.6"
          name  = "microservice2"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
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
  depends_on = [helm_release.ingress_nginx]
}

resource "kubernetes_ingress" "microservice2_ingress" {
  metadata {
    name = "microservice2-ingress"
    namespace = "default"
  }
  spec { 
    rule {
      http {
        path {
          backend {
            service_name = "microservice2-svc"
            service_port = 80
          }
          path = "/version"
        }
      }
    }
  }
  depends_on = [kubernetes_deployment.microservice2_deployment]
}

resource "kubernetes_service" "microservice2_svc" {
  metadata {
    name = "microservice2-svc"
    namespace = "default"
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
  depends_on = [kubernetes_deployment.microservice2_deployment]
}