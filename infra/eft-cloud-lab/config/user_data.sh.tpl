#!/bin/bash
# Bootstrap de cada nodo del ASG: Docker + Compose + app tienda-vehiculos
# desde Docker Hub (imágenes públicas del alumno; no requiere ECR).
set -xe

dnf install -y docker mariadb105
systemctl enable --now docker

mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

mkdir -p /opt/tienda-vehiculos
cat > /opt/tienda-vehiculos/docker-compose.yml << 'EOF'
services:
  frontend:
    image: docker.io/${dockerhub_username}/tienda-vehiculos-frontend:${image_tag}
    container_name: tienda-vehiculos-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend

  backend:
    image: docker.io/${dockerhub_username}/tienda-vehiculos-backend:${image_tag}
    container_name: tienda-vehiculos-backend
    restart: unless-stopped
    environment:
      DB_HOST: "${db_host}"
      DB_USER: "${db_user}"
      DB_PASSWORD: "${db_password}"
      DB_NAME: "${db_name}"
      DB_PORT: "3306"
    ports:
      - "3001:3001"
EOF

cd /opt/tienda-vehiculos
docker compose pull
docker compose up -d
