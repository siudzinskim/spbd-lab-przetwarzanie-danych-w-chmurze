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
resource "kubernetes_namespace_v1" "airflow" {
  metadata {
    name = "airflow"
  }
}

# Instalacja Airflow z Helma
resource "helm_release" "airflow" {
  repository = "https://airflow.apache.org"
  name       = "airflow"
  chart      = "airflow"
  version    = "1.19.0"
  namespace  = kubernetes_namespace_v1.airflow.metadata[0].name
  timeout    = 900  #TODO: zwiększyć czas timeoutu!

  values = [
    templatefile("${path.module}/config/airflow-values.yaml", { DAGS_BASE_PATH = var.dags_base_path })
  ]

  # Upewnij się, że namespace jest stworzony przed instalacją chartu
  depends_on = [kubernetes_namespace_v1.airflow, local_file.kubeconfig, kubectl_manifest.dashboard_ingress]
}

# Stworzenie Ingressu dla Airflow
resource "kubectl_manifest" "airflow_ingress" {
  # Czekamy, aż Airflow zostanie w pełni wdrożony przez Helma
  depends_on = [helm_release.airflow]

  yaml_body = file("${path.module}/config/airflow-ingress.yaml")
}

output "airflow_url" {
  description = "Adres URL do Apache Airflow."
  value       = "http://${local.kubeconfig_server_ip}:8080"
}