provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Losowy ciąg znaków, aby nazwa bucketu była unikalna na świecie
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 1. Tworzenie Bucket na Config
resource "google_storage_bucket" "config_bucket" {
  name          = "k8s-config-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true # Pozwala usunąć bucket z zawartością przy terraform destroy
}

# 2. Konfiguracja sieci (uproszczona - domyślna)
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# 3. Tworzenie Wirtualnej Maszyny
resource "google_compute_instance" "k8s_node" {
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

  # Przekazanie skryptu instalacyjnego z dynamiczną nazwą bucketu
  metadata_startup_script = templatefile("${path.module}/scripts/setup.sh", {
    BUCKET_NAME = google_storage_bucket.config_bucket.name
  })

  # Uprawnienia dla VM, aby mogła wysłać plik do Storage
  service_account {
    scopes = ["https://www.googleapis.com/auth/devstorage.read_write", "cloud-platform"]
  }
}