output "public_ip" {
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
  description = "Publiczny adres IP maszyny"
  depends_on  = [google_compute_instance.vm]
}

output "bucket_name" {
  value       = google_storage_bucket.workspace_bucket.name
  description = "Nazwa bucketu workspace"
}

output "ssh_command" {
  description = "Rekomendowana komenda do połączenia się z maszyną przez SSH"
  value       = "gcloud compute ssh --project ${var.project_id} --zone ${var.zone} ${google_compute_instance.vm.name}"
}

output "start_vm_command" {
  description = "Komenda do uruchomienia maszyny wirtualnej"
  value       = "gcloud compute instances start ${google_compute_instance.vm.name} --project ${var.project_id} --zone ${var.zone}"
}

output "vscode_url" {
  description = "Adres URL do serwera VS Code (HTTPS)."
  value       = "http://${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}:8888"
}

output "vscode_password" {
  description = "Hasło do logowania do VS Code Server."
  value       = var.vscode_password
}
