variable "project_id" {
  description = "ID Twojego projektu w GCP"
  type        = string
}

variable "region" {
  description = "Region dla zasobów"
  type        = string
  default     = "europe-central2" # Warszawa
}

variable "zone" {
  description = "Strefa dla VM"
  type        = string
  default     = "europe-central2-a"
}

variable "instance_type" {
  description = "Typ maszyny wirtualnej"
  type        = string
  default     = "e2-micro" # Bardzo tania opcja
}