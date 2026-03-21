# 1. Aktualizacja i instalacja narzędzi
apt-get update
apt-get install -y snapd at curl

# 2. Instalacja i konfiguracja certyfikatu MicroK8s
snap install microk8s --classic
microk8s stop # Zatrzymaj, aby bezpiecznie zmodyfikować konfigurację certyfikatu przed pierwszym startem

PUBLIC_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

if [ -n "$PUBLIC_IP" ]; then
  # Upewnij się, że plik jest w poprawnym stanie, usuwając stare wpisy IP.100
  # Używamy /^IP\\.100 =/d aby precyzyjnie namierzyć linię do usunięcia
  sed -i "/^IP\\.100 =/d" /var/snap/microk8s/current/certs/csr.conf.template
  # Użyj placeholdera #MOREIPS, aby wstawić aktualny adres IP we właściwym miejscu
  sed -i "s|#MOREIPS|IP.100 = $PUBLIC_IP\n#MOREIPS|" /var/snap/microk8s/current/certs/csr.conf.template
fi

# Zmodyfikuj konfigurację api-server, aby nasłuchiwał na wszystkich interfejsach
if ! grep -q "bind-address=0.0.0.0" /var/snap/microk8s/current/args/kube-apiserver; then
  echo "--bind-address=0.0.0.0" >> /var/snap/microk8s/current/args/kube-apiserver
fi

# Uruchom ponownie, aby wygenerować certyfikaty z nową konfiguracją i poczekaj na gotowość
microk8s start
microk8s status --wait-ready
sleep 15

# 3. Wygenerowanie i wysłanie kubeconfig
TEMP_CONFIG_PATH="/tmp/kubeconfig"
microk8s config > $TEMP_CONFIG_PATH

# Po restarcie, config może nadal zawierać stary IP.
# Dla pewności, podmieniamy adres wewnętrzny i localhost na publiczny.
if [ -n "$PUBLIC_IP" ]; then
  INTERNAL_IP=$(hostname -I | awk '{print $1}')
  sed -i "s/$INTERNAL_IP/$PUBLIC_IP/g" $TEMP_CONFIG_PATH
  sed -i "s/127.0.0.1/$PUBLIC_IP/g" $TEMP_CONFIG_PATH
fi

# 4. Wysłanie configu do Bucket
if [ -s "$TEMP_CONFIG_PATH" ]; then
  BUCKET_NAME=$1
  gsutil cp $TEMP_CONFIG_PATH "gs://${BUCKET_NAME}/kubeconfig"
else
  echo "Plik konfiguracyjny MicroK8s był pusty lub nie został utworzony." > /tmp/startup-script-error.log
fi

# 5. AUTO-SHUTDOWN
echo "sudo poweroff" | at now + 4 hours