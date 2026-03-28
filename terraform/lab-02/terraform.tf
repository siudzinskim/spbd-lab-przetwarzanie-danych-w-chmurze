terraform {
  # Określenie wymaganej wersji Terraform
  required_version = ">= 1.0"

  # Konfiguracja zdalnego przechowywania stanu dla lab-02
  backend "gcs" {
    bucket  = "spdb-2026-tf-state" # Ten sam bucket co w lab-01
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
    # Provider local jest potrzebny do zapisania kubeconfig w pliku tymczasowym
    local = {
      source = "hashicorp/local"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
