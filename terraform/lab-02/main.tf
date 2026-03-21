# Provider google jest potrzebny do odczytania obiektu z GCS
provider "google" {
  project = var.project_id
  region  = var.region
}

# Konfiguracja providera kubectl, który pozwala na aplikowanie manifestów YAML.
# Używamy zawartości kubeconfig pobranej z GCS (output z lab-01).
provider "kubectl" {
  config_content = data.google_storage_bucket_object_content.kubeconfig.content
}

# Utworzenie zasobu Ingress na podstawie pliku YAML.
# To podejście jest elastyczne i pozwala zarządzać dowolnymi zasobami K8s
# bez potrzeby mapowania ich na dedykowane zasoby terraformowe (np. kubernetes_ingress).
resource "kubectl_manifest" "dashboard_ingress" {
  yaml_body = file("${path.module}/dashboard-ingress.yaml")
}
