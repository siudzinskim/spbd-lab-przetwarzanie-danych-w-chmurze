provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Włączenie wymaganych API, aby uniknąć błędu "SERVICE_DISABLED"
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Losowy ciąg znaków, aby nazwa bucketu była unikalna na świecie
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 1. Tworzenie Bucket na Config
resource "google_storage_bucket" "config_bucket" {
  depends_on    = [google_project_service.storage]
  name          = "${var.project_id}-k8s-config"
  location      = var.region
  force_destroy = true # Pozwala usunąć bucket z zawartością przy terraform destroy
}

# Wysyłanie skryptu setup.sh do bucketa
resource "google_storage_bucket_object" "setup_script" {
  name   = "setup.sh"
  bucket = google_storage_bucket.config_bucket.name
  source = "${path.module}/scripts/setup.sh"
}

# 2. Konfiguracja sieci (uproszczona - domyślna)
resource "google_compute_network" "vpc_network" {
  depends_on = [google_project_service.compute]
  name       = "terraform-network"
}

resource "google_compute_firewall" "allow-network-traffic" {
  name    = "allow-network-traffic"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "16443", "443", "8080", "8000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# 3. Tworzenie Wirtualnej Maszyny
resource "google_compute_instance" "k8s_node" {
  depends_on   = [google_project_service.compute, google_storage_bucket_object.setup_script]
  name         = "microk8s-lab-vm"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20 # MicroK8s potrzebuje trochę miejsca
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      # Pusty blok generuje publiczne IP
    }
  }

  # Statyczny skrypt startowy, który pobiera i uruchamia główny skrypt z GCS.
  # Zmiany w setup.sh nie będą już powodować odtwarzania maszyny.
  metadata_startup_script = <<-EOT
    #!/bin/bash
    BUCKET_NAME="${google_storage_bucket.config_bucket.name}"
    gsutil cp "gs://$${BUCKET_NAME}/setup.sh" /tmp/setup.sh
    chmod +x /tmp/setup.sh
    /tmp/setup.sh "$BUCKET_NAME"
  EOT

  # Uprawnienia dla VM, aby mogła wysłać plik do Storage
  service_account {
    scopes = ["https://www.googleapis.com/auth/devstorage.read_write", "cloud-platform"]
  }

  desired_status = "RUNNING"

}