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

# --- Konfiguracja SSL i certyfikatów ---

# Generowanie klucza prywatnego dla SSL
resource "tls_private_key" "airflow" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generowanie samopodpisanego certyfikatu
resource "tls_self_signed_cert" "airflow" {
  private_key_pem = tls_private_key.airflow.private_key_pem

  subject {
    common_name  = local.kubeconfig_server_ip
    organization = "Airflow Lab"
  }

  validity_period_hours = 8760 # 1 rok

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Stworzenie sekretu z certyfikatem w przestrzeni nazw Airflow
resource "kubernetes_secret" "airflow_tls" {
  metadata {
    name      = "airflow-tls-secret"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
  }

  data = {
    "tls.crt" = tls_self_signed_cert.airflow.cert_pem
    "tls.key" = tls_private_key.airflow.private_key_pem
  }

  type = "kubernetes.io/tls"
}

# Stworzenie sekretu z certyfikatem w przestrzeni nazw Dashboardu (wymagane dla Ingressa dashboardu)
resource "kubernetes_secret" "dashboard_tls" {
  metadata {
    name      = "airflow-tls-secret"
    namespace = "kubernetes-dashboard"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.airflow.cert_pem
    "tls.key" = tls_private_key.airflow.private_key_pem
  }

  type = "kubernetes.io/tls"
}

# Stworzenie sekretu z certyfikatem w przestrzeni nazw default (dla VS Code)
resource "kubernetes_secret" "vscode_tls" {
  metadata {
    name      = "airflow-tls-secret"
    namespace = "default"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.airflow.cert_pem
    "tls.key" = tls_private_key.airflow.private_key_pem
  }

  type = "kubernetes.io/tls"
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

  # Upewnij się, że namespace i sekrety są stworzone przed instalacją chartu
  depends_on = [kubernetes_namespace_v1.airflow, local_file.kubeconfig, kubernetes_secret.airflow_tls]
}

# Stworzenie Ingressu dla Airflow
resource "kubectl_manifest" "airflow_ingress" {
  # Czekamy, aż Airflow zostanie w pełni wdrożony przez Helma
  depends_on = [helm_release.airflow, kubernetes_secret.airflow_tls]

  yaml_body = file("${path.module}/config/airflow-ingress.yaml")
}

output "airflow_url" {
  description = "Adres URL do Apache Airflow (HTTPS)."
  value       = "https://${local.kubeconfig_server_ip}:8080"
}