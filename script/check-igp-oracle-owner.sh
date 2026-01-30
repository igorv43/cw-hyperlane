#!/bin/bash

# Script para verificar o owner do IGP Oracle
# Usage: ./script/check-igp-oracle-owner.sh

IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"

echo "Verificando owner do IGP Oracle..."
echo "======================================================================"
echo "IGP Oracle: ${IGP_ORACLE}"
echo ""

# Query owner
echo "Querying contract owner..."
terrad query wasm contract-state smart ${IGP_ORACLE} '{"owner":{}}' \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} 2>/dev/null | jq -r '.data.owner' || echo "Erro ao consultar owner"

echo ""
echo "Para verificar se sua conta é o owner, compare o endereço acima com sua wallet."
