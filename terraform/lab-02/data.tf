# Pobranie stanu z lab-01, aby uzyskać dostęp do jego outputów
data "terraform_remote_state" "lab_01" {
  backend = "gcs"
  config = {
    bucket = "spdb-2026-tf-state"
    prefix = "terraform/state" # Ścieżka do stanu lab-01
  }
}

# Pobranie zawartości pliku kubeconfig z GCS
# Nazwa bucketu jest pobierana dynamicznie z outputu lab-01
data "google_storage_bucket_object_content" "kubeconfig" {
  bucket = data.terraform_remote_state.lab_01.outputs.bucket_name
  name   = "kubeconfig"
}

# Pobranie zawartości pliku z tokenem do dashboardu
data "google_storage_bucket_object_content" "dashboard_token" {
  bucket = data.terraform_remote_state.lab_01.outputs.bucket_name
  name   = "dashboard_token.txt"
}
