# --- Konfiguracja i deployment VS Code Server ---

# Stworzenie deploymentu dla VS Code w namespace default
resource "kubernetes_deployment" "vscode" {
  metadata {
    name      = "vscode-server"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vscode"
      }
    }

    template {
      metadata {
        labels = {
          app = "vscode"
        }
      }

      spec {
        container {
          name  = "vscode"
          image = "siudzinskim/vscode-dbt:latest"
          
          port {
            container_port = 8443
            name           = "https"
          }

          env {
            name  = "PASSWORD"
            value = var.vscode_password
          }

          env {
            name  = "SUDO_PASSWORD"
            value = var.vscode_password
          }

          env {
            name  = "PUID"
            value = "1000"
          }

          env {
            name  = "PGID"
            value = "1000"
          }

          env {
            name  = "TZ"
            value = "Etc/UTC"
          }

          # Montowanie całego katalogu Airflow jako ścieżki roboczej
          volume_mount {
            name       = "airflow-root"
            mount_path = "/config/workspace"
          }
        }

        volume {
          name = "airflow-root"
          host_path {
            path = "/opt/airflow"
            type = "Directory"
          }
        }
      }
    }
  }
}

# Serwis dla VS Code w namespace default
resource "kubernetes_service" "vscode" {
  metadata {
    name      = "vscode-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "vscode"
    }

    port {
      port        = 8443
      target_port = 8443
      name        = "https"
    }

    type = "ClusterIP"
  }
}

# Zasób Ingress dla VS Code aplikowany z pliku YAML
resource "kubectl_manifest" "vscode_ingress" {
  depends_on = [kubernetes_service.vscode, kubernetes_secret.vscode_tls]

  yaml_body = file("${path.module}/config/vscode-ingress.yaml")
}
