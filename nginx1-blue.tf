# NGINX 1 Test Deployment
#
# TODO: Change your-domain according to your DNS record that you want to create
# TODO: Change your-zone-id according to your DNS zone ID in Cloudflare
# ---

variable "cloudflare_zone_id" {
    type = string
    sensitive = true
}

resource "kubernetes_namespace" "nginx-blue" {

    depends_on = [
        time_sleep.wait_for_kubernetes
    ]

    metadata {
        name = "nginx-blue"
    }
}


resource "kubernetes_deployment" "nginx-blue" {

    depends_on = [
        kubernetes_namespace.nginx-blue
    ]

    yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: nginx
  name: nginx-deploy-blue
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx-blue
  template:
    metadata:
      labels:
        run: nginx-blue
    spec:
      volumes:
      - name: webdata
        emptyDir: {}
      initContainers:
      - name: web-content
        image: busybox
        volumeMounts:
        - name: webdata
          mountPath: "/webdata"
        command: ["/bin/sh", "-c", 'echo "<h1>I am <font color=blue>BLUE</font></h1>" > /webdata/index.html']
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: webdata
          mountPath: "/usr/share/nginx/html"  
    YAML
}


resource "kubernetes_service" "nginx1" {

    depends_on = [
        kubernetes_namespace.nginx-blue
    ]

    metadata {
        name = "nginx-blue"
        namespace = "nginginx-bluenx1"
    }
    spec {
        selector = {
            app = "nginginx-bluenx1"
        }
        port {
            port = 80
        }

        type = "ClusterIP"
    }
}


resource "kubectl_manifest" "nginx-blue-certificate" {

    depends_on = [kubernetes_namespace.nginx-blue, time_sleep.wait_for_clusterissuer]

    yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: nginx-blue
  namespace: nginx-blue
spec:
  secretName: nginx-blue
  issuerRef:
    name: cloudflare-prod
    kind: ClusterIssuer
  dnsNames:
  - 'nginx-blue.maddocks.name'   
    YAML
}


resource "kubernetes_ingress_v1" "nginx-blue" {

    depends_on = [kubernetes_namespace.nginx1]

    metadata {
        name = "nginx-blue"
        namespace = "nginx-blue"
    }

    spec {
        rule {
            host = "nginx-blue.maddocks.name"
            http {
                path {
                    path = "/"
                    backend {
                        service {
                            name = "nginx-blue"
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
        tls {
          secret_name = "nginx-blue"
          hosts = ["nginx-blue.maddocks.name"]
        }
    }
}

resource "cloudflare_record" "clcreative-main-cluster" {
    zone_id = var.cloudflare_zone_id #"your-zone-id"
    name = "nginx-blue.maddocks.name"
    value =  data.civo_loadbalancer.traefik_lb.public_ip #the public IP
    type = "A"
    proxied = false
}

output "public_ip_addr" {
  value       = data.civo_loadbalancer.traefik_lb.public_ip
  description = "The public IP address of the nginx server instance."
}


