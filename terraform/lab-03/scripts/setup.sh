mkdir -p /app/workspace/log
echo "----------------------------------------------" >> /app/workspace/log/lab-startup.log
echo "# Setup started at: $(date)   #" >> /app/workspace/log/lab-startup.log
echo "----------------------------------------------" >> /app/workspace/log/lab-startup.log
if ! command -v at &> /dev/null; then
  sudo apt update
  sudo apt install -y at
fi
if ! command -v docker &> /dev/null; then
  # Install Docker
  echo "Installing Docker..." >> /app/workspace/log/lab-startup.log
  # Add Docker's official GPG key:
  sudo apt update
  sudo apt install ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update >> /app/workspace/log/lab-startup.log
  apt-cache policy docker-ce >> /app/workspace/log/lab-startup.log

  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> /app/workspace/log/lab-startup.log
  echo "Docker installed." >> /app/workspace/log/lab-startup.log

  # Start and enable Docker service
  echo "Starting Docker service..." >> /app/workspace/log/lab-startup.log
  systemctl start docker >> /app/workspace/log/lab-startup.log
  systemctl status docker  >> /app/workspace/log/lab-startup.log
  echo "Enabling Docker service..." >> /app/workspace/log/lab-startup.log
fi


systemctl enable docker
echo "Docker service started and enabled." >> /app/workspace/log/lab-startup.log
# Ensure all members of google-sudoers are added to the docker group on login
echo "Configuring auto-group assignment for google-sudoers..." >> /app/workspace/log/lab-startup.log
cat << 'EOF' > /etc/profile.d/docker-group.sh
if id -nG "$USER" | grep -q "google-sudoers" && ! id -nG "$USER" | grep -q "docker"; then
    sudo usermod -aG docker "$USER" > /dev/null 2>&1
fi
EOF
chmod +x /etc/profile.d/docker-group.sh
echo "Profile script created." >> /app/workspace/log/lab-startup.log



# Tworzenie katalogów dla DAG-ów i danych Airflow
mkdir -p /app/workspace
chmod -R 777 /app/workspace # Nadanie pełnych uprawnień dla całego katalogu roboczego

# 6. AUTO-SHUTDOWN
echo "sudo poweroff" | at now + 4 hours

docker pull siudzinskim/vscode-dbt:latest
docker stop vs && docker container rm vs
docker run -d -p 8888:8443 -p 8080:8080 -p 8000:8000 -v /app/workspace:/config -e SUDO_PASSWORD=$VSCODE_PASSWORD -e PASSWORD=$VSCODE_PASSWORD --name vs siudzinskim/vscode-dbt

echo "______________________________________________" >> /app/workspace/log/lab-startup.log
echo "# Setup finished at: $(date)   #" >> /app/workspace/log/lab-startup.log
echo "______________________________________________" >> /app/workspace/log/lab-startup.log