output "kubeconfig_server_ip" {
  description = "Adres IP serwera API odczytany z pliku kubeconfig."
  value       = local.kubeconfig_server_ip
}

output "dashboard_url" {
  description = "Adres URL do Kubernetes Dashboard."
  value       = "https://${local.kubeconfig_server_ip}"
}

output "dashboard_token" {
  description = "Token do logowania do Kubernetes Dashboard."
  value       = data.google_storage_bucket_object_content.dashboard_token.content
}

