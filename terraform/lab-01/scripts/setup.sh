if ! command -v microk8s &> /dev/null; then
  # 1. Aktualizacja i instalacja narzędzi
  apt-get update
  apt-get install -y snapd at curl

  # 2. Instalacja i konfiguracja certyfikatu MicroK8s
  snap install microk8s --classic
fi
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
# 5. Konfiguracja
sleep 5
microk8s.enable dns
microk8s.enable dashboard
microk8s.enable ingress

# Poprawka MTU i MSS dla sieci podów (konieczne w chmurach jak GCP/AWS)
# 1. Ustawienie MTU w ConfigMap Calico (standard w nowych wersjach MicroK8s)
echo "Ustawiam MTU 1410 w konfiguracji Calico..."
sudo microk8s kubectl patch configmap calico-config -n kube-system --type merge -p '{"data": {"veth_mtu": "1410"}}' || true

# 2. Wymuszenie TCP MSS Clamping na poziomie iptables hosta (łańcuchy FORWARD i POSTROUTING)
# Ustawiamy na 1300 dla absolutnego bezpieczeństwa w tunelach VXLAN/GCP
echo "Aplikuję agresywny TCP MSS Clamping (1300)..."
sudo iptables -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1300 2>/dev/null || true
sudo iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1300
sudo iptables -t mangle -D POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1300 2>/dev/null || true
sudo iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1300

# Wymuszenie restartu podów sieciowych (calico/flannel), aby przejęły nowe MTU
sudo microk8s kubectl rollout restart ds -n kube-system calico-node || true
sudo microk8s kubectl rollout restart ds -n kube-system flannel-ds || true

# Wymuszenie restartu Twoich deploymentów, aby pody pobrały nową konfigurację DNS
echo "Restartuję deploymenty w celu odświeżenia konfiguracji sieci..."
sudo microk8s kubectl rollout restart deployment -n default vscode-server || true
sudo microk8s kubectl rollout restart deployment -n airflow airflow-scheduler || true
sudo microk8s kubectl rollout restart deployment -n airflow airflow-webserver || true
sudo microk8s kubectl rollout restart deployment -n airflow airflow-worker || true

# Tworzenie katalogów dla DAG-ów i danych Airflow
mkdir -p /opt/airflow/dags
mkdir -p /opt/airflow/data
chmod -R 777 /opt/airflow # Nadanie pełnych uprawnień dla całego katalogu roboczego

# 6. AUTO-SHUTDOWN
echo "sudo poweroff" | at now + 4 hours


# 7. Konfiguracja ingressu
# 7.a. Aktualizacja ConfigMapy dla usług TCP
# Używamy patch typu 'merge', aby dodać porty bez usuwania istniejących wpisów
echo "Aktualizuję ConfigMap nginx-ingress-tcp-microk8s-conf..."
sudo microk8s kubectl patch cm nginx-ingress-tcp-microk8s-conf -n ingress \
  --type merge \
  -p '{"data":{"8080":"airflow/airflow-api-server:8080"}}'
sudo microk8s kubectl patch cm nginx-ingress-tcp-microk8s-conf -n ingress \
  --type merge \
  -p '{"data":{"8443":"default/vscode-service:8443"}}'

# 7.b. Aktualizacja DaemonSetu - dodanie portu do listy ports
# Tutaj używamy JSON patch, aby precyzyjnie dodać element do tablicy ports
echo "Dodaję porty 8080 i 8443 do DaemonSetu (hostPort)..."
if ! sudo microk8s kubectl get ds nginx-ingress-microk8s-controller -n ingress -o jsonpath='{.spec.template.spec.containers[0].ports[*].containerPort}' | grep -q 8080; then
  sudo microk8s kubectl patch ds nginx-ingress-microk8s-controller -n ingress --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 8080, "hostPort": 8080, "name": "tcp-8080", "protocol": "TCP"}}]'
fi

if ! sudo microk8s kubectl get ds nginx-ingress-microk8s-controller -n ingress -o jsonpath='{.spec.template.spec.containers[0].ports[*].containerPort}' | grep -q 8443; then
  sudo microk8s kubectl patch ds nginx-ingress-microk8s-controller -n ingress --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 8443, "hostPort": 8443, "name": "tcp-8443", "protocol": "TCP"}}]'
fi

# 7.x. Restart DaemonSetu (wymagane, aby zmiany w hostPort weszły w życie)
echo "Restartuję Ingress Controller..."
sudo microk8s kubectl rollout restart ds nginx-ingress-microk8s-controller -n ingress

# 8. Restart usługi kong:
sudo microk8s kubectl delete pod -l app.kubernetes.io/name=kong -n kubernetes-dashboard