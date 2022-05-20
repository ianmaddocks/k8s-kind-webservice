provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
  alias = "alias"
}

resource "time_sleep" "wait_for_ingress" {
    depends_on = [helm_release.ingress_nginx]
    create_duration = "1s"
}

resource "kubernetes_deployment" "webapp1_deployment" {
  depends_on = [time_sleep.wait_for_ingress]
  metadata {
    name = "webapp1"
    labels = {
      app = "webapp1"
    }
    namespace = "default"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "webapp1"
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
           app = "webapp1"
        }
      }
      spec {
        container {
          image = "ianmaddocks/webapp1:latest"
          name  = "webapp1"

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
}

resource "kubernetes_ingress" "webapp1_ingress" {
  metadata {
    name = "webapp1-ingress"
    namespace = "default"
  }
  spec { 
    rule {
      http {
        path {
          backend {
            service_name = "webapp1-svc"
            service_port = 80
          }
          path = "/"
        }
      }
    }
  }
  depends_on = [kubernetes_deployment.webapp1_deployment]
}

resource "kubernetes_service" "webapp1_svc" {
  metadata {
    name = "webapp1-svc"
    namespace = "default"
  }
  spec {
    selector = {
      app = kubernetes_deployment.webapp1_deployment.metadata.0.labels.app
    }
    port {
      port  = 80
    }
    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment.webapp1_deployment]
}