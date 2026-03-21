# Provider google jest potrzebny do odczytania obiektu z GCS
provider "google" {
  project = var.project_id
  region  = var.region
}

# Zapisanie pobranej zawartości kubeconfig do tymczasowego pliku w folderze .tmp
# Provider kubectl będzie używał tego pliku do uwierzytelnienia.
# Użycie nazwy bucketa w nazwie pliku zapewnia unikalność.
resource "local_file" "kubeconfig" {
  content  = data.google_storage_bucket_object_content.kubeconfig.content
  filename = "${path.module}/.tmp/kubeconfig_${data.terraform_remote_state.lab_01.outputs.bucket_name}.tmp"
}

# Konfiguracja providera kubectl, który pozwala na aplikowanie manifestów YAML.
# Wskazujemy na tymczasowy plik kubeconfig.
provider "kubectl" {
  config_path = local_file.kubeconfig.filename
}

# Utworzenie zasobu Ingress na podstawie pliku YAML z folderu config
# To podejście jest elastyczne i pozwala zarządzać dowolnymi zasobami K8s
# bez potrzeby mapowania ich na dedykowane zasoby terraformowe (np. kubernetes_ingress).
resource "kubectl_manifest" "dashboard_ingress" {
  # Zależność od zasobu local_file zapewnia, że plik zostanie utworzony
  # zanim kubectl spróbuje go użyć.
  depends_on = [local_file.kubeconfig]
  
  yaml_body = file("${path.module}/config/dashboard-ingress.yaml")
}