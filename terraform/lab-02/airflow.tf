# --- Konfiguracja i deployment Airflow ---

# Konfiguracja providera kubernetes, potrzebnego do stworzenia namespace
provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

# Konfiguracja providera helm
provider "helm" {
  kubernetes = {
    config_path = local_file.kubeconfig.filename
  }
}

# Stworzenie dedykowanej przestrzeni nazw dla Airflow
resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

# # Instalacja Airflow z Helma
# resource "helm_release" "airflow" {
#   name       = "airflow"
#   repository = "https://airflow.apache.org"
#   chart      = "airflow"
#   namespace  = kubernetes_namespace.airflow.metadata[0].name
#   version    = "1.19.0" # Użycie konkretnej wersji dla stabilności
#
#   values = [
#     file("${path.module}/config/airflow-values.yaml")
#   ]
#
#   # Upewnij się, że namespace jest stworzony przed instalacją chartu
#   depends_on = [kubernetes_namespace.airflow]
# }
#
# # Stworzenie Ingressu dla Airflow
# resource "kubectl_manifest" "airflow_ingress" {
#   # Czekamy, aż Airflow zostanie w pełni wdrożony przez Helma
#   depends_on = [helm_release.airflow]
#
#   yaml_body = file("${path.module}/config/airflow-ingress.yaml")
# }
#
# output "airflow_url" {
#   description = "Adres URL do Apache Airflow."
#   value       = "http://$${local.kubeconfig_server_ip}:8080"
# }