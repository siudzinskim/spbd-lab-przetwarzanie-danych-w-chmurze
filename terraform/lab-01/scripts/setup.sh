# 1. Aktualizacja i instalacja narzędzi
apt-get update
apt-get install -y snapd at curl

# 2. Instalacja i konfiguracja certyfikatu MicroK8s
snap install microk8s --classic
# 3. Konfiguracja sieci i certyfikatów MicroK8s
echo "Rozpoczynanie konfiguracji sieci i certyfikatów..."
PUBLIC_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
CERT_CONFIG_FILE="/var/snap/microk8s/current/certs/csr.conf.template"
API_SERVER_ARGS="/var/snap/microk8s/current/args/kube-apiserver"

# Zawsze modyfikuj argumenty api-server, aby nasłuchiwał na zewnątrz
if ! grep -q "bind-address=0.0.0.0" "$API_SERVER_ARGS"; then
  echo "--bind-address=0.0.0.0" >> "$API_SERVER_ARGS"
fi

# Zawsze modyfikuj szablon certyfikatu o aktualny IP
if [ -n "$PUBLIC_IP" ]; then
  sed -i "/^IP\\.100 =/d" "$CERT_CONFIG_FILE"
  sed -i "s|#MOREIPS|IP.100 = $PUBLIC_IP\n#MOREIPS|" "$CERT_CONFIG_FILE"
fi

# Zawsze odświeżaj certyfikat serwera i restartuj usługi
echo "Zatrzymywanie MicroK8s w celu odświeżenia certyfikatów..."
microk8s stop
echo "Odświeżanie certyfikatu serwera z nowym IP: $PUBLIC_IP"
microk8s refresh-certs --cert server.crt

echo "Uruchamianie MicroK8s..."
microk8s start

echo "Czekam na gotowość klastra po restarcie..."
microk8s status --wait-ready
sleep 15
microk8s.enable dashboard
microk8s.enable ingress

# Tworzenie katalogów dla DAG-ów i danych Airflow
mkdir -p /opt/airflow/dags
mkdir -p /opt/airflow/data
chmod -R 777 /opt/airflow/dags # Nadanie pełnych uprawnień dla poda
chmod -R 777 /opt/airflow/data # Nadanie pełnych uprawnień dla poda

# 3. Wygenerowanie i wysłanie kubeconfig
TEMP_CONFIG_PATH="/tmp/kubeconfig"
microk8s config > $TEMP_CONFIG_PATH

# Po restarcie, config może nadal zawierać stary IP.
# Dla pewności, podmieniamy adres serwera na publiczny IP.
if [ -n "$PUBLIC_IP" ]; then
  sed -i -E "s/server: https:\/\/[^:]+/server: https:\/\/$PUBLIC_IP/" "$TEMP_CONFIG_PATH"
fi

# 4. Wysłanie configu do Bucket
if [ -s "$TEMP_CONFIG_PATH" ]; then
  BUCKET_NAME=$1
  echo "Wysyłanie kubeconfig do bucketu: ${BUCKET_NAME}"
  gsutil cp $TEMP_CONFIG_PATH "gs://${BUCKET_NAME}/kubeconfig"

  # Generowanie i wysyłanie tokena do dashboardu
  echo "Generowanie tokena do dashboardu..."
  # Czekamy chwilę, aż dashboard i jego service account będą gotowe
  sleep 10
  TOKEN_PATH="/tmp/dashboard_token.txt"
  microk8s kubectl create token default -n kubernetes-dashboard --duration=14400s > $TOKEN_PATH
  
  if [ -s "$TOKEN_PATH" ]; then
    echo "Wysyłanie tokena do bucketu: ${BUCKET_NAME}"
    gsutil cp $TOKEN_PATH "gs://${BUCKET_NAME}/dashboard_token.txt"
  else
    echo "Plik tokena był pusty lub nie został utworzony." >> /tmp/startup-script-error.log
  fi

else
  echo "Plik konfiguracyjny MicroK8s był pusty lub nie został utworzony." > /tmp/startup-script-error.log
fi

# 5. AUTO-SHUTDOWN
echo "sudo poweroff" | at now + 4 hours