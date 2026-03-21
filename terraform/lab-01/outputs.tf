output "public_ip" {
  value       = google_compute_instance.k8s_node.network_interface[0].access_config[0].nat_ip
  description = "Publiczny adres IP maszyny"
}

output "bucket_name" {
  value       = google_storage_bucket.config_bucket.name
  description = "Nazwa bucketu z plikiem kubeconfig"
}

output "ssh_command" {
  description = "Rekomendowana komenda do połączenia się z maszyną przez SSH"
  value       = "gcloud compute ssh --project ${var.project_id} --zone ${var.zone} ${google_compute_instance.k8s_node.name}"
}