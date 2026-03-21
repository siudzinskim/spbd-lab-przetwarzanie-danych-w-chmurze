locals {
  # Wyciągnięcie adresu IP z kubeconfig do zmiennej lokalnej, aby uniknąć powtórzeń
  kubeconfig_server_ip = regex("https://([^:]+)", yamldecode(data.google_storage_bucket_object_content.kubeconfig.content).clusters[0].cluster.server)[0]
}
