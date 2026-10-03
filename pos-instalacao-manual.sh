#!/bin/sh
# Roda DEPOIS de uma instalacao MANUAL do Debian (criar-vm-debian.ps1 -Manual)
# em que a senha do root foi deixada EM BRANCO na instalacao - esse e o
# cenario padrao deste projeto: so existe o usuario "user", sem conta root
# separada, e "user" ja sai do instalador no grupo sudo sozinho (o proprio
# Debian faz isso quando voce nao define senha de root).
#
# Este script completa o que a instalacao manual nao faz sozinha: instala
# Docker e docker-compose, e coloca "user" no grupo docker.
#
# Uso:
#
#   ssh -p 2222 user@localhost
#   sudo sh pos-instalacao-manual.sh
#
# (Se por algum motivo a VM tiver uma senha de root definida, rode como root
# via "su -" em vez de usar sudo - o script funciona do mesmo jeito.)

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode com 'sudo sh pos-instalacao-manual.sh' (ou como root via su -)." >&2
  exit 1
fi

echo "== Atualizando indice de pacotes =="
apt-get update

echo "== Instalando Docker e docker-compose =="
apt-get install -y docker.io docker-compose

echo "== Colocando 'user' no grupo docker =="
usermod -aG docker user

echo "== Habilitando e iniciando o Docker =="
systemctl enable --now docker

echo "== Confirmando =="
echo "Grupos de user: $(id user)"
docker --version
docker compose version

echo "== Garantindo que o login do root continua bloqueado =="
passwd -l root 2>/dev/null || true

echo ""
echo "Pronto. Reiniciando em 5s para o grupo docker ja valer no proximo login..."
sleep 5
reboot
