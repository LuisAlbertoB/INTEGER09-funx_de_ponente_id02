#!/bin/bash

# ==============================================================================
# Script de configuración inicial para un EC2 de AWS con Ubuntu (22.04 / 24.04)
# ==============================================================================

echo "Actualizando el sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Instalando dependencias base..."
sudo apt-get install -y ca-certificates curl gnupg git

echo "Agregando la llave GPG oficial de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Configurando el repositorio de Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Instalando Docker y Docker Compose..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Agregando el usuario actual al grupo de Docker (para evitar usar sudo docker)..."
sudo usermod -aG docker ubuntu

echo "====================================================================="
echo "✅ Instalación completada."
echo "⚠️  IMPORTANTE: Cierra la sesión SSH y vuelve a conectarte para que los cambios de usuario tengan efecto."
echo ""
echo "Después de reconectarte, navega a la carpeta 'deploy' de tu proyecto y ejecuta:"
echo "   docker compose up -d"
echo "====================================================================="
