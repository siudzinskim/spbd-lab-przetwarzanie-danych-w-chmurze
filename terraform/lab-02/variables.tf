variable "project_id" {
  description = "ID Twojego projektu w GCP"
  type        = string
}

variable "region" {
  description = "Region dla zasobów"
  type        = string
  default     = "europe-central2" # Warszawa
}

variable "vm_name" {
  description = "Nazwa maszyny wirtualnej MicroK8s."
  type        = string
  default     = "microk8s-lab-vm" # Domyślna nazwa z lab-01
}

variable "dags_base_path" {
  description = "Bazowa ścieżka na maszynie wirtualnej, gdzie znajdują się DAG-i i dane Airflow."
  type        = string
  default     = "/opt/airflow" # Domyślna ścieżka, jeśli nie podano inaczej
}

variable "vscode_password" {
  description = "Hasło do serwera VS Code."
  type        = string
  default     = "dbtlab2026"
}
