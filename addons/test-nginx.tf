resource "kubernetes_deployment_v1" "test_nginx" {
  metadata {
    name      = "test-nginx"
    namespace = "default"
    labels = {
      app = "test-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "test-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "test-nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.25"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "test_nginx_lb" {
  metadata {
    name      = "test-nginx-lb"
    namespace = "default"
  }

  spec {
    selector = {
      app = "test-nginx"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}