terraform {
  # Określenie wymaganej wersji Terraform
  required_version = ">= 1.0"

  # Konfiguracja zdalnego przechowywania stanu
  backend "gcs" {
    bucket  = "spdb-2026-tf-state" # Nazwa bucketu musi być unikalna
    prefix  = "terraform/state"                       # Ścieżka wewnątrz bucketu
  }

  # Definicja wymaganych providerów i ich wersji
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
    }
  }
}