## **Scenariusz Laboratorium: Automatyzacja infrastruktury analitycznej w GCP**

### **1\. Wstęp i Cel Laboratorium**

Celem zajęć jest zapoznanie studentów z narzędziem **Terraform** jako standardem w zarządzaniu infrastrukturą chmurową. Zamiast ręcznej konfiguracji w konsoli (tradycyjne podejście), studenci stworzą **deklaratywny kod HCL**, który automatycznie powoła zasoby obliczeniowe i składowania danych.

**Cele szczegółowe:**

*   Konfiguracja dostawcy (providera) GCP.
*   Stworzenie wirtualnej maszyny (VM) o minimalnych kosztach.
*   Automatyczna instalacja środowiska **MicroK8s** przy starcie systemu.
*   Zarządzanie uprawnieniami i bucketem (GCS) do przechowywania plików konfiguracyjnych.
*   Implementacja mechanizmu oszczędzania kosztów (auto-shutdown).

---

### **2\. Struktura Projektu**

Studenci powinni zorganizować kod zgodnie z dobrymi praktykami opisanymi w prezentacji, dzieląc go na moduły i pliki funkcjonalne:

*   **main.tf**: Główny plik z definicją zasobów (resource).
*   **variables.tf**: Parametryzacja środowiska (np. ID projektu, region).
*   **outputs.tf**: Eksport informacji o publicznym IP i nazwie bucketu.
*   **scripts/install-k8s.sh**: Skrypt shellowy instalujący MicroK8s.

---

### **3\. Zadania do wykonania**

#### **Zadanie 1: Konfiguracja dostawcy i zmiennych**

Studenci muszą zdefiniować blok provider dla Google Cloud, używając zmiennych wejściowych, aby kod był uniwersalny i możliwy do użycia w różnych środowiskach (dev/prod).

#### **Zadanie 2: Tworzenie magazynu danych (Storage Bucket)**

Należy utworzyć zasób google\_storage\_bucket. Będzie on służył jako repozytorium dla pliku kubeconfig, co jest typowym zadaniem inżyniera danych przy współdzieleniu dostępu do klastrów.

*   **Wskazówka:** Użyj unikalnej nazwy z wykorzystaniem funkcji join lub losowego sufiksu.

#### **Zadanie 3: Definicja maszyny wirtualnej (Compute Engine)**

Studenci tworzą zasób google\_compute\_instance.

*   **Typ maszyny:** e2-micro (najmniejsza dostępna, zgodna z wymaganiem oszczędności).
*   **Obraz:** Ubuntu Minimal (lekki system pod k8s).
*   **Startup Script:** W argumencie metadata\_startup\_script należy wstrzyknąć treść skryptu instalacyjnego przy użyciu funkcji file().

**Logika Skryptu (Startup Script):**

1.  Instalacja microk8s przez snap.
2.  Wygenerowanie configu: microk8s config \> /tmp/config. 3. Przesłanie configu do utworzonego wcześniej bucketu (wykorzystanie referencji do zasobu: aws\_s3\_bucket.name.id – analogicznie w GCP).
3.  **Auto-shutdown:** Dodanie wpisu do at lub cron, który wykona komendę sudo poweroff za 4 godziny.

#### **Zadanie 4: Zarządzanie stanem i planowanie**

Przed wdrożeniem studenci muszą wykonać:

1.  terraform init: Pobranie pluginów GCP.
2.  terraform plan: Podgląd, co zostanie utworzone (weryfikacja czy powstanie 1 VM i 1 bucket).
3.  terraform apply: Fizyczne utworzenie zasobów.

---

### **4\. Podsumowanie i weryfikacja**

Studenci uznają laboratorium za zaliczone, gdy:

1.  Plik stanu terraform.tfstate odzwierciedla działającą infrastrukturę.
2.  W chmurze GCP pojawi się plik konfiguracyjny w buckecie (wykorzystanie bloku data do weryfikacji może być zadaniem dodatkowym).
3.  Maszyna VM posiada tagi informujące o środowisku (np. Environment \= "lab").

# Przebieg laboratorium

Konfiguracja backendu w GCS (Google Cloud Storage) jest kluczowym elementem pracy inżynierskiej, ponieważ pozwala na bezpieczne przechowywanie pliku stanu (`terraform.tfstate`) w chmurze, a nie na dysku lokalnym. Umożliwia to pracę zespołową i chroni przed utratą danych o infrastrukturze.

Oto jak powinna wyglądać zawartość pliku, który zazwyczaj nazywa się **`versions.tf`** lub jest umieszczany na początku **`main.tf`**:

### **1\. Kod blokady Backend GCS**

```terraform
terraform {
  # Określenie wymaganej wersji Terraform
  required_version = ">= 1.0"

  # Konfiguracja zdalnego przechowywania stanu
  backend "gcs" {
    bucket  = "tu-wpisz-nazwe-twojego-bucketu-na-state" # Nazwa bucketu musi być unikalna
    prefix  = "terraform/state"                       # Ścieżka wewnątrz bucketu
  }

  # Definicja wymaganych providerów i ich wersji
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

### **2\. Ważne uwagi dla studentów (Instrukcja)**

Podczas laboratorium należy zwrócić uwagę na tzw. problem "jajka i kury". Terraform nie może stworzyć bucketu, którego sam chce używać jako backendu w tym samym przebiegu.

**Kroki dla studenta:**

1.  **Ręczne utworzenie bucketu:** Przed uruchomieniem `terraform init`, student musi utworzyć bucket na stan (np. przez konsolę GCP lub komendę `gcloud storage buckets create gs://nazwa-stanu`).
    *   *Alternatywnie:* Można najpierw uruchomić Terraform z zakomentowanym blokiem `backend`, stworzyć bucket zasobem `google_storage_bucket`, a potem odkomentować backend i wykonać `terraform init -migrate-state`.

**Inicjalizacja:** Po dodaniu powyższego bloku, konieczne jest ponowne wykonanie komendy:
```bash
terraform init
```

2.  Terraform zapyta, czy przenieść istniejący plik stanu z dysku lokalnego do chmury GCS.
3.  **Wersjonowanie:** Warto wspomnieć studentom, że bucket na backend powinien mieć włączony **Versioning** (wersjonowanie obiektów). Dzięki temu, jeśli ktoś przypadkowo uszkodzi stan, będzie można go przywrócić z poprzedniej wersji.

### **Dlaczego to robimy w inżynierii danych?**

*   **Współpraca:** Wielu inżynierów może pracować na tym samym kodzie (Terraform blokuje stan, gdy ktoś inny wykonuje `apply`).
*   **Bezpieczeństwo:** Plik stanu często zawiera wrażliwe dane (hasła, klucze). Przechowywanie go w bezpiecznym buckecie z ograniczonym dostępem jest bezpieczniejsze niż trzymanie go na laptopie.
*   **CI/CD:** Automatyzacja (np. GitHub Actions) wymaga zdalnego stanu, aby móc nanosić zmiany w infrastrukturze bez posiadania lokalnych plików `tfstate`.

Oto szczegółowy projekt laboratorium z gotowymi blokami kodu. Scenariusz został przygotowany tak, aby studenci mogli go krok po kroku zaimplementować, rozumiejąc strukturę projektu Terraform.

### **Struktura plików projektu:**

```plaintext
terraform-lab/
├── main.tf             # Główna logika (VM, Bucket, Sieć)
├── variables.tf        # Definicje zmiennych
├── outputs.tf          # Dane wyjściowe (IP, nazwa bucketu)
├── terraform.tfvars    # Wartości zmiennych (ID projektu)
└── scripts/
    └── setup.sh        # Skrypt instalacyjny (startup script)
```

---

### **1\. variables.tf**

Zgodnie z Twoją prezentacją, używamy zmiennych, aby kod był reużywalny.

```terraform
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
```

---

### **2\. terraform.tfvars**

Tu student wpisuje swoje unikalne dane projektu.

```terraform
project_id = "nazwa-twojego-projektu-gcp"
region     = "europe-central2"
```

---

### **3\. scripts/setup.sh**

To jest "serce" automatyzacji wewnątrz maszyny. Skrypt zainstaluje MicroK8s i zaplanuje samobójstwo maszyny.

```bash
#!/bin/bash

# 1. Aktualizacja i instalacja narzędzi
apt-get update
apt-get install -y snapd at

# 2. Instalacja MicroK8s
snap install microk8s --classic
microk8s status --wait-ready

# 3. Przygotowanie kubeconfig
mkdir -p /home/ubuntu/.kube
microk8s config > /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# 4. Wysłanie configu do Bucket (wykorzystujemy gsutil dostępny na VM)
# Zmienna BUCKET_NAME zostanie wstrzyknięta przez Terraform
gsutil cp /home/ubuntu/.kube/config gs://${BUCKET_NAME}/kubeconfig

# 5. AUTO-SHUTDOWN za 4 godziny (240 minut)
echo "sudo poweroff" | at now + 4 hours
```

---

### **4\. main.tf**

Główny plik definiujący infrastrukturę. Wykorzystujemy tutaj funkcję `templatefile`, aby przekazać nazwę bucketu do skryptu bash.

```terraform
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
```

---

### **5\. outputs.tf**

Pozwala studentom szybko sprawdzić, gdzie szukać wyników pracy.

```terraform
output "public_ip" {
  value       = google_compute_instance.k8s_node.network_interface[0].access_config[0].nat_ip
  description = "Publiczny adres IP maszyny"
}

output "bucket_name" {
  value       = google_storage_bucket.config_bucket.name
  description = "Nazwa bucketu z plikiem kubeconfig"
}

output "ssh_command" {
  value = "ssh ubuntu@${google_compute_instance.k8s_node.network_interface[0].access_config[0].nat_ip}"
}
```

---

### **Instrukcja dla studenta (Scenariusz Laboratorium):**

1.  **Inicjalizacja:** Uruchom `terraform init`, aby pobrać providera GCP i moduł `random`.
2.  **Analiza:** Przeczytaj skrypt `setup.sh`. Zwróć uwagę na komendę `at now + 4 hours` – to ona zabezpiecza Twój portfel przed zapomnieniem o wyłączeniu maszyny.
3.  **Planowanie:** Wykonaj `terraform plan`. Sprawdź, ile zasobów zostanie utworzonych. Zwróć uwagę na to, jak funkcja `random_id` modyfikuje nazwę bucketu.
4.  **Wdrożenie:** Wykonaj `terraform apply`. Poczekaj ok. 3-5 minut (tyle zajmuje instalacja MicroK8s przez snap).
5.  **Weryfikacja:**
    *   Zaloguj się do konsoli GCP Storage i sprawdź, czy w Twoim buckecie pojawił się plik `kubeconfig`.
    *   Zaloguj się przez SSH do maszyny i wpisz `sudo microk8s kubectl get nodes`.
    *   Sprawdź listę zaplanowanych zadań komendą `atq` – powinieneś zobaczyć zaplanowany shutdown.
6.  **Sprzątanie:** Na koniec zajęć wykonaj `terraform destroy`, aby usunąć wszystkie zasoby jednym poleceniem.