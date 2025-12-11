#!/bin/bash

# Script para criar proposta de governance para atualizar IGP Oracle exchange_rate
# Endereço do módulo de governance: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n

IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
GOV_MODULE="terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"

# Novo exchange_rate (BNB @ $897.88, Gas Price REAL: 0.1 Gwei = 100,000,000 wei)
# Cálculo: (147,945,295 × 10^18) / (100000 × 100000000) = 14794529576536
# Gas Price REAL no BSC Testnet: 0.1 Gwei (100,000,000 wei) - verificado via RPC em 2025
# Custo final: ~148 LUNC (~$0.009) por transfer (dobra porque gas_price dobrou)
NEW_EXCHANGE_RATE="${1:-14794529576536}"
GAS_PRICE="${2:-100000000}"

echo "=== Criando Proposta de Governance para Atualizar IGP Oracle ==="
echo ""
echo "IGP Oracle: ${IGP_ORACLE}"
echo "Governance Module: ${GOV_MODULE}"
echo "Novo Exchange Rate: ${NEW_EXCHANGE_RATE}"
echo "Gas Price: ${GAS_PRICE}"
echo ""

# Criar arquivo JSON da proposta
PROPOSAL_FILE="proposal-igp-oracle-update.json"

cat > ${PROPOSAL_FILE} <<EOF
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "${GOV_MODULE}",
      "contract": "${IGP_ORACLE}",
      "msg": {
        "set_remote_gas_data_configs": {
          "configs": [
            {
              "remote_domain": 97,
              "token_exchange_rate": "${NEW_EXCHANGE_RATE}",
              "gas_price": "${GAS_PRICE}"
            }
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update IGP Oracle exchange rate for BSC Testnet domain 97. Fixes gas cost from \$1512 to \$0.0045 per transfer.",
  "deposit": "500000uluna",
  "title": "Update IGP Oracle Exchange Rate for BSC Testnet",
  "summary": "Update token_exchange_rate to ${NEW_EXCHANGE_RATE} for BSC Testnet (domain 97). Uses real gas price 0.1 Gwei (100M wei). Fixes gas cost calculation.",
  "expedited": false
}
EOF

echo "✅ Arquivo de proposta criado: ${PROPOSAL_FILE}"
echo ""
echo "=== Conteúdo da Proposta ==="
cat ${PROPOSAL_FILE} | jq .
echo ""
echo "=== Comando para Enviar a Proposta ==="
echo ""
echo "terrad tx gov submit-proposal ${PROPOSAL_FILE} \\"
echo "  --from hypelane-val-testnet \\"
echo "  --keyring-backend file \\"
echo "  --chain-id rebel-2 \\"
echo "  --node https://rpc.luncblaze.com:443 \\"
echo "  --gas auto \\"
echo "  --gas-adjustment 1.5 \\"
echo "  --gas-prices 28.5uluna \\"
echo "  --yes"
echo ""
echo "=== Após Enviar ==="
echo "1. Anote o PROPOSAL_ID retornado"
echo "2. A proposta entrará em PERÍODO DE DEPÓSITO (não vai direto para votação)"
echo "3. Depósito inicial: 500,000 uluna (0.5 LUNC) - menor que o mínimo de 1,000,000 uluna (1 LUNC)"
echo "4. Outros usuários podem depositar para atingir o depósito mínimo (1,000,000 uluna = 1 LUNC)"
echo "5. Deposite mais tokens (se necessário) para atingir o mínimo:"
echo "   terrad tx gov deposit <PROPOSAL_ID> 500000uluna \\"
echo "     --from hypelane-val-testnet \\"
echo "     --keyring-backend file \\"
echo "     --chain-id rebel-2 \\"
echo "     --node https://rpc.luncblaze.com:443 \\"
echo "     --gas-prices 28.5uluna \\"
echo "     --yes"
echo "6. Após atingir o depósito mínimo, a proposta entrará em PERÍODO DE VOTAÇÃO"
echo "7. Vote na proposta:"
echo "   terrad tx gov vote <PROPOSAL_ID> yes \\"
echo "     --from hypelane-val-testnet \\"
echo "     --keyring-backend file \\"
echo "     --chain-id rebel-2 \\"
echo "     --node https://rpc.luncblaze.com:443 \\"
echo "     --gas-prices 28.5uluna \\"
echo "     --yes"
echo "3. Aguarde o período de votação terminar"
echo "4. Verifique a execução consultando o IGP Oracle"
echo ""

