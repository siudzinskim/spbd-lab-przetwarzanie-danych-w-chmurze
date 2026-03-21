#!/bin/bash

# 1. Aktualizacja i instalacja narzędzi
apt-get update
apt-get install -y snapd at curl

# 2. Instalacja MicroK8s i włączenie dodatków
snap install microk8s --classic
microk8s status --wait-ready
echo "Włączanie dodatku dashboard PRZED konfiguracją sieci..."
microk8s enable dashboard
sleep 15 # Daj chwilę na inicjalizację dodatku

# 3. Konfiguracja sieci i certyfikatów MicroK8s
echo "Zatrzymywanie MicroK8s w celu modyfikacji konfiguracji..."
microk8s stop

PUBLIC_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

if [ -n "$PUBLIC_IP" ]; then
  # Upewnij się, że plik jest w poprawnym stanie, usuwając stare wpisy IP.100
  sed -i "/^IP\\.100 =/d" /var/snap/microk8s/current/certs/csr.conf.template
  # Użyj placeholdera #MOREIPS, aby wstawić aktualny adres IP we właściwym miejscu
  sed -i "s|#MOREIPS|IP.100 = $PUBLIC_IP\n#MOREIPS|" /var/snap/microk8s/current/certs/csr.conf.template
fi

# Zmodyfikuj konfigurację api-server, aby nasłuchiwał na wszystkich interfejsach
if ! grep -q "bind-address=0.0.0.0" /var/snap/microk8s/current/args/kube-apiserver; then
  echo "--bind-address=0.0.0.0" >> /var/snap/microk8s/current/args/kube-apiserver
fi

echo "Ponowne uruchamianie MicroK8s z nową konfiguracją..."
microk8s start
microk8s status --wait-ready
sleep 15

# 4. Wygenerowanie i wysłanie kubeconfig
TEMP_CONFIG_PATH="/tmp/kubeconfig"
microk8s config > $TEMP_CONFIG_PATH

# Dla pewności, podmieniamy adres wewnętrzny i localhost na publiczny.
if [ -n "$PUBLIC_IP" ]; then
  INTERNAL_IP=$(hostname -I | awk '{print $1}')
  sed -i "s/$INTERNAL_IP/$PUBLIC_IP/g" $TEMP_CONFIG_PATH
  sed -i "s/127.0.0.1/$PUBLIC_IP/g" $TEMP_CONFIG_PATH
fi

# Wysłanie configu do Bucket
if [ -s "$TEMP_CONFIG_PATH" ]; then
  BUCKET_NAME=$1
  gsutil cp $TEMP_CONFIG_PATH "gs://${BUCKET_NAME}/kubeconfig"
else
  echo "Plik konfiguracyjny MicroK8s był pusty lub nie został utworzony." > /tmp/startup-script-error.log
fi

# 5. Konfiguracja przekierowania portu dla dashboardu
KONG_PROXY_IP=""
while [ -z "$KONG_PROXY_IP" ]; do
  echo "Czekam na serwis kubernetes-dashboard-kong-proxy..."
  KONG_PROXY_IP=$(microk8s kubectl get svc kubernetes-dashboard-kong-proxy -n kubernetes-dashboard -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
  [ -z "$KONG_PROXY_IP" ] && sleep 5
done
echo "Znaleziono ClusterIP dla kong-proxy: $KONG_PROXY_IP"

# Włącz IP forwarding i route_localnet w kernelu i uczyń je trwałymi po restarcie
cat <<EOF > /etc/sysctl.d/99-forwarding.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.route_localnet=1
EOF
sysctl -p /etc/sysctl.d/99-forwarding.conf

# Dodaj reguły iptables do przekierowania portu 443
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination "${KONG_PROXY_IP}:443"
iptables -t nat -A OUTPUT -o lo -p tcp --dport 443 -j DNAT --to-destination "${KONG_PROXY_IP}:443"
iptables -t nat -A POSTROUTING -p tcp -d "${KONG_PROXY_IP}" --dport 443 -j MASQUERADE

# Zainstaluj iptables-persistent, aby zapisać reguły na stałe
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get -y install iptables-persistent

# 6. Tworzenie tokenu do logowania do dashboardu
ADMIN_USER_YAML="/tmp/dashboard-admin.yaml"
cat <<EOF > $ADMIN_USER_YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

microk8s kubectl apply -f $ADMIN_USER_YAML

# Czekaj na ServiceAccount
while ! microk8s kubectl get sa admin-user -n kubernetes-dashboard > /dev/null 2>&1; do
  echo "Czekam na ServiceAccount admin-user..."
  sleep 2
done

# Wygeneruj token i zapisz do pliku
DASHBOARD_TOKEN_PATH="/tmp/dashboard_token.txt"
microk8s kubectl create token admin-user -n kubernetes-dashboard --duration=8760h > $DASHBOARD_TOKEN_PATH

# Wysłanie tokenu do Bucket
if [ -s "$DASHBOARD_TOKEN_PATH" ]; then
  gsutil cp $DASHBOARD_TOKEN_PATH "gs://${BUCKET_NAME}/dashboard_token.txt"
else
  echo "Plik tokenu był pusty lub nie został utworzony." >> /tmp/startup-script-error.log
fi

# 7. AUTO-SHUTDOWN
echo "sudo poweroff" | at now + 4 hours