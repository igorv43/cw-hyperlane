#!/bin/bash

# Script para adicionar chave ao terrad keyring
# Uso: ./script/add-key-terrad.sh

echo "Escolha uma opção:"
echo "1. Adicionar chave usando mnemonic (recomendado)"
echo "2. Adicionar chave usando chave privada"
read -p "Opção (1 ou 2): " option

KEY_NAME="uluna-warp"
KEYRING_BACKEND="file"

case $option in
  1)
    echo ""
    echo "Adicionando chave usando mnemonic..."
    terrad keys add "${KEY_NAME}" --recover --keyring-backend "${KEYRING_BACKEND}"
    ;;
  2)
    echo ""
    echo "Adicionando chave usando chave privada..."
    read -sp "Digite a chave privada (hex, sem 0x): " PRIVATE_KEY
    echo ""
    echo "${PRIVATE_KEY}" | terrad keys add "${KEY_NAME}" --recover --keyring-backend "${KEYRING_BACKEND}" --interactive=false
    ;;
  *)
    echo "Opção inválida"
    exit 1
    ;;
esac

echo ""
echo "✅ Chave adicionada com sucesso!"
echo ""
echo "Para verificar, execute:"
echo "terrad keys list --keyring-backend ${KEYRING_BACKEND}"
echo ""
echo "Para usar esta chave no comando de instanciação, use:"
echo "--from ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND}"

