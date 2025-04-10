#!/bin/bash

echo "Starting startup script..." >> /tmp/startup.log 2>&1
date >> /tmp/lab-startup.log

echo "Waiting for /dev/sdh to be available..." >> /tmp/startup.log 2>&1
while [ ! -b /dev/sdh ]; do
  echo "  /dev/sdh not found, waiting..." >> /tmp/startup.log 2>&1
  sleep 5
done
echo "/dev/sdh is now available." >> /tmp/startup.log 2>&1

# Mount the volume
echo "Mounting /dev/sdh1 to /mnt/data..." >> /tmp/startup.log
mount /dev/sdh1 /mnt/data >> /tmp/startup.log 2>&1

# Check if the volume is already formatted and mounted
if ! lsblk -o MOUNTPOINT | grep /mnt/data; then
  echo "Volume not mounted, proceeding with formatting and mounting..." >> /tmp/startup.log

  # Format the volume (if not already formatted)
  if ! blkid /dev/sdh; then
    echo "Formatting /dev/sdh with ext4..." >> /tmp/startup.log 2>&1
    echo 'start=2048, type=83' | sfdisk /dev/sdh >> /tmp/startup.log 2>&1
    mkfs.ext4 /dev/sdh1 >> /tmp/startup.log 2>&1
  else
    echo "/dev/sdh already formatted." >> /tmp/startup.log
  fi

  # Create the mount point directory
  mkdir -p /mnt/data >> /tmp/startup.log 2>&1

  # Mount the volume
  echo "Mounting /dev/sdh1 to /mnt/data..." >> /tmp/startup.log
  mount /dev/sdh1 /mnt/data >> /tmp/startup.log 2>&1

  # Add an entry to /etc/fstab to mount the volume on boot
  echo "/dev/sdh1 /mnt/data ext4 defaults 0 0" >> /etc/fstab

  echo "Volume mounted successfully." >> /tmp/startup.log
else
  echo "Volume already mounted at /mnt/data." >> /tmp/startup.log
fi
mkdir -p /mnt/data/log/install
chmod -R 777 /mnt/data
mv /tmp/startup.log /mnt/data/log/install/


# Install ec2-instance-connect
echo "Installing ec2-instance-connect..." >> /mnt/data/log/lab-startup.log
yum install -y ec2-instance-connect
echo "ec2-instance-connect installed." >> /mnt/data/log/lab-startup.log

# Install Docker
echo "Installing Docker..." >> /mnt/data/log/lab-startup.log
yum update -y
yum install -y docker
echo "Docker installed." >> /mnt/data/log/lab-startup.log

# Start and enable Docker service
echo "Starting Docker service..." >> /mnt/data/log/lab-startup.log
systemctl start docker
echo "Enabling Docker service..." >> /mnt/data/log/lab-startup.log
systemctl enable docker
echo "Docker service started and enabled." >> /mnt/data/log/lab-startup.log

# Add ec2-user to the docker group
echo "Adding ec2-user to the docker group..." >> /mnt/data/log/lab-startup.log
usermod -a -G docker ec2-user
echo "ec2-user added to the docker group." >> /mnt/data/log/lab-startup.log

echo "Startup script completed." >> /mnt/data/log/lab-startup.log
date >> /mnt/data/log/lab-startup.log

docker pull siudzinskim/vscode-dbt
docker run -d  -p 8888:8443 -p 8080:8080 -v /mnt/data/vscode:/config --name vs siudzinskim/vscode-dbt
(crontab -l ; echo "@reboot /usr/bin/docker start vs") | crontab -
