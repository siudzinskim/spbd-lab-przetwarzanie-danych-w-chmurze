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