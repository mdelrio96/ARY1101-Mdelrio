#!/bin/bash
# Bootstrap de cada nodo del ASG: Docker + Compose + app tienda-vehiculos
# desde Docker Hub (imágenes públicas del alumno; no requiere ECR).
set -xe

# Auto-nombrado: cada nodo sobreescribe su tag Name con un sufijo único
# (su propio instance ID), ya que el ASG propaga el mismo Name a todos.
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)
SUFFIX=$${INSTANCE_ID#i-}
aws ec2 create-tags --region "$REGION" --resources "$INSTANCE_ID" \
  --tags "Key=Name,Value=${node_name_prefix}-$${SUFFIX: -4}" || true

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
