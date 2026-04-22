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

# 1. Tworzenie Bucket na Workspace
resource "google_storage_bucket" "workspace_bucket" {
  depends_on    = [google_project_service.storage]
  name          = "${var.project_id}-lab-workspace"
  location      = var.region
  force_destroy = false # Nie pozwala usunąć bucketu z zawartością przy terraform destroy
}

# Wysyłanie skryptu setup.sh do bucketa
resource "google_storage_bucket_object" "setup_script" {
  name   = "setup.sh"
  bucket = google_storage_bucket.workspace_bucket.name
  source = "${path.module}/scripts/setup.sh"
}

# 2. Konfiguracja sieci (uproszczona - domyślna)
resource "google_compute_network" "vpc_network" {
  depends_on = [google_project_service.compute]
  name       = "lab-network"
}

resource "google_compute_firewall" "allow-network-traffic" {
  name    = "allow-network-traffic-lab"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "16443", "8888", "8443", "8080", "8000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# 3. Tworzenie Wirtualnej Maszyny
resource "google_compute_instance" "vm" {
  depends_on   = [google_project_service.compute, google_storage_bucket_object.setup_script]
  name         = "lab-vm"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
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
    VSCODE_PASSWORD="${var.vscode_password}"
    BUCKET_NAME="${google_storage_bucket.workspace_bucket.name}"
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