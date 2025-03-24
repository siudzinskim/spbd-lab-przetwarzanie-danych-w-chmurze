#!/bin/bash
docker stop vs && docker container rm vs
mkdir -p ./config/workspace
docker run -d \
  --name=vs \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e TZ=Etc/UTC \
  -e DEFAULT_WORKSPACE=/config/workspace \
  -p 8443:8443 \
  -v ./config:/config \
  --restart unless-stopped \
  siudzinskim/vscode-dbt
#  lscr.io/linuxserver/code-server:latest
