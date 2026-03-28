output "public_ip" {
  value       = google_compute_instance.k8s_node.network_interface[0].access_config[0].nat_ip
  description = "Publiczny adres IP maszyny"
  depends_on  = [google_compute_instance.k8s_node]
}

output "bucket_name" {
  value       = google_storage_bucket.config_bucket.name
  description = "Nazwa bucketu z plikiem kubeconfig"
}

output "ssh_command" {
  description = "Rekomendowana komenda do połączenia się z maszyną przez SSH"
  value       = "gcloud compute ssh --project ${var.project_id} --zone ${var.zone} ${google_compute_instance.k8s_node.name}"
}

output "start_vm_command" {
  description = "Komenda do uruchomienia maszyny wirtualnej"
  value       = "gcloud compute instances start ${google_compute_instance.k8s_node.name} --project ${var.project_id} --zone ${var.zone}"
}

output "kubeconfig_path" {
  description = "Rekomendowana komenda do skopiowania konfiguracji k8s"
  value       = "gs://${google_storage_bucket.config_bucket.name}/kubeconfig"
}

output "kubeconfig_copy_command" {
  description = "Rekomendowana komenda do skopiowania konfiguracji k8s"
  value       = "mkdir -p ~/.kube/ && gsutil cp gs://${google_storage_bucket.config_bucket.name}/kubeconfig ~/.kube/config"
}