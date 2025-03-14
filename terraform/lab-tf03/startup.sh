#!/bin/bash
echo "Skrypt startowy uruchomiony” >> /dev/sdh/startup.log
date >> /dev/sdh/startup.log
yum install -y ec2-instance-connect
hostname >> /dev/sdh/startup.log
sleep 300 # Czekaj 5 minut (300 sekund)
echo "Wyłączanie systemu..." >> /dev/sdh/startup.log
date >> /dev/sdh/startup.log
shutdown -h now
