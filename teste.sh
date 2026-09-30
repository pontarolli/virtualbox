#!/usr/bin/env bash
# Teste básico de verificação da VM (Debian x86_64 acessível via SSH).
# Uso: ./teste.sh <IP_DA_VM> <USUARIO_SSH> [PORTA_SSH]
# A porta é opcional (padrão 22). Ex.: VM em NAT no VirtualBox:
#   ./teste.sh localhost user 2222
#
# Este script é IDÊNTICO em cloud/ e virtualbox/ — só muda o IP que você passa.
set -euo pipefail

IP="${1:-}"
USUARIO="${2:-}"
PORTA="${3:-22}"

if [ -z "$IP" ] || [ -z "$USUARIO" ]; then
  echo "Uso: ./teste.sh <IP_DA_VM> <USUARIO_SSH> [PORTA_SSH]"
  exit 1
fi

echo "Conectando em ${USUARIO}@${IP} (porta ${PORTA})..."
SAIDA=$(ssh -p "$PORTA" -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${USUARIO}@${IP}" \
  "cat /etc/os-release; echo ---; uname -m; echo ---; hostname; echo ---; uptime")

echo "$SAIDA"
echo
echo "== Verificação =="

OK=1

if echo "$SAIDA" | grep -qi "debian"; then
  echo "[OK] Sistema é Debian"
else
  echo "[FALHOU] Sistema não é Debian"
  OK=0
fi

if echo "$SAIDA" | grep -q "x86_64"; then
  echo "[OK] Arquitetura é x86_64"
else
  echo "[FALHOU] Arquitetura não é x86_64"
  OK=0
fi

if [ "$OK" -eq 1 ]; then
  echo
  echo "TESTE PASSOU: VM pronta (Debian x86_64, acessível via SSH)."
  exit 0
else
  echo
  echo "TESTE FALHOU: revise os passos do README antes de continuar."
  exit 1
fi
