# NGINX 1 Test Deployment
#
# TODO: Change your-domain according to your DNS record that you want to create
# TODO: Change your-zone-id according to your DNS zone ID in Cloudflare
# ---

variable "cloudflare_zone_id" {
    type = string
    sensitive = true
}

resource "kubernetes_namespace" "nginx1" {

    depends_on = [
        time_sleep.wait_for_kubernetes
    ]

    metadata {
        name = "nginx1"
    }
}


resource "kubernetes_deployment" "nginx1" {

    depends_on = [
        kubernetes_namespace.nginx1
    ]

    metadata {
        name = "nginx1"
        namespace = "nginx1"
        labels = {
            app = "nginx1"
        }
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "nginx1"
            }
        }

        template {
            metadata {
                labels = {
                    app = "nginx1"
                }
            }

            spec {
                container {
                    image = "nginx:latest"
                    name  = "nginx"

                    port {
                        container_port = 80
                    }
                }
            }
        }
    }
}


resource "kubernetes_service" "nginx1" {

    depends_on = [
        kubernetes_namespace.nginx1
    ]

    metadata {
        name = "nginx1"
        namespace = "nginx1"
    }
    spec {
        selector = {
            app = "nginx1"
        }
        port {
            port = 80
        }

        type = "ClusterIP"
    }
}


resource "kubectl_manifest" "nginx1-certificate" {

    depends_on = [kubernetes_namespace.nginx1, time_sleep.wait_for_clusterissuer]

    yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: nginx1
  namespace: nginx1
spec:
  secretName: nginx1
  issuerRef:
    name: cloudflare-prod
    kind: ClusterIssuer
  dnsNames:
  - 'nginx1.maddocks.name'   
    YAML
}

resource "kubernetes_ingress_v1" "nginx1" {

    depends_on = [kubernetes_namespace.nginx1]

    metadata {
        name = "nginx1"
        namespace = "nginx1"
    }

    spec {
        rule {

            host = "nginx1.maddocks.name"

            http {

                path {
                    path = "/"

                    backend {
                        service {
                            name = "nginx1"
                            port {
                                number = 80
                            }
                        }
                    }

                }
            }
        }

        tls {
          secret_name = "nginx1"
          hosts = ["nginx1.maddocks.name"]
        }
    }
}

resource "cloudflare_record" "clcreative-main-cluster" {
    zone_id = var.cloudflare_zone_id #"your-zone-id"
    name = "nginx1.maddocks.name"
    value =  data.civo_loadbalancer.traefik_lb.public_ip #the public IP
    type = "A"
    proxied = false
}

output "public_ip_addr" {
  value       = data.civo_loadbalancer.traefik_lb.public_ip
  description = "The public IP address of the nginx server instance."
}
