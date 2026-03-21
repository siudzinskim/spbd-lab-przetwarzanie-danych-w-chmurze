terraform {
  # Określenie wymaganej wersji Terraform
  required_version = ">= 1.0"

  # Konfiguracja zdalnego przechowywania stanu dla lab-02
  backend "gcs" {
    bucket  = "tu-wpisz-nazwe-twojego-bucketu-na-state" # Ten sam bucket co w lab-01
    prefix  = "terraform/lab-02/state" # INNA ścieżka dla tego modułu
  }

  # Definicja wymaganych providerów i ich wersji
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    # Provider kubectl jest idealny do aplikowania gotowych manifestów YAML
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7"
    }
  }
}
