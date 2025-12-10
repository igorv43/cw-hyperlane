#!/bin/bash
# Script para transferir BNB para o Safe

SAFE_ADDRESS="0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"
AMOUNT="0.01"  # Ajuste conforme necessário

echo "💰 Transferindo BNB para o Safe..."
echo "   Safe: $SAFE_ADDRESS"
echo "   Amount: $AMOUNT BNB"
echo ""
echo "Use cast ou sua wallet para transferir:"
echo ""
echo "cast send $SAFE_ADDRESS --value ${AMOUNT}ether \\"
echo "  --private-key 0xYOUR_PRIVATE_KEY \\"
echo "  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545"
echo ""
echo "Ou use a interface web do Safe para receber BNB"
