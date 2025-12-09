#!/bin/bash
# Script simples usando cast para criar transação no Safe
# NOTA: O Safe requer assinaturas off-chain, então isso é uma abordagem simplificada

SAFE="0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"
TO="$1"
CALLDATA="$2"
PRIVATE_KEY="$3"
RPC="https://data-seed-prebsc-1-s1.binance.org:8545"

if [ -z "$TO" ] || [ -z "$CALLDATA" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "Uso: ./safe-propose-simple.sh <TO_ADDRESS> <CALLDATA> <PRIVATE_KEY>"
    echo ""
    echo "Exemplo:"
    echo "  ./safe-propose-simple.sh 0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA 0xa50e0bb4... 0xPRIVATE_KEY"
    exit 1
fi

echo "⚠️  NOTA: O Safe não tem função pública para criar propostas."
echo "   Este script mostra como usar cast, mas você precisará:"
echo "   1. Criar transação off-chain"
echo "   2. Assinar off-chain"  
echo "   3. Usar approveHash para aprovar"
echo "   4. Coletar assinaturas"
echo "   5. Executar quando threshold atingido"
echo ""
echo "💡 Para uma solução completa, use a biblioteca safe-eth-py ou interface web"
echo ""
echo "📝 Dados da transação:"
echo "   Safe: $SAFE"
echo "   To: $TO"
echo "   Data: $CALLDATA"
echo ""
echo "🔗 Verifique no BscScan quais funções o Safe tem:"
echo "   https://testnet.bscscan.com/address/$SAFE#writeContract"
