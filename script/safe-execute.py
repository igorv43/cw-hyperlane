#!/usr/bin/env python3
"""
Script para executar propostas no Safe multisig usando web3.py diretamente
"""

import sys
from web3 import Web3
from eth_account import Account

# Configurações
SAFE_ADDRESS = "0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"
RPC_URL = "https://data-seed-prebsc-1-s1.binance.org:8545"

# ABI do Safe (função executeTransaction)
SAFE_ABI = [
    {
        "inputs": [
            {"internalType": "address", "name": "to", "type": "address"},
            {"internalType": "uint256", "name": "value", "type": "uint256"},
            {"internalType": "bytes", "name": "data", "type": "bytes"},
            {"internalType": "enum Enum.Operation", "name": "operation", "type": "uint8"},
            {"internalType": "uint256", "name": "safeTxGas", "type": "uint256"},
            {"internalType": "uint256", "name": "baseGas", "type": "uint256"},
            {"internalType": "uint256", "name": "gasPrice", "type": "uint256"},
            {"internalType": "address", "name": "gasToken", "type": "address"},
            {"internalType": "address", "name": "refundReceiver", "type": "address"},
            {"internalType": "bytes", "name": "signatures", "type": "bytes"}
        ],
        "name": "executeTransaction",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    }
]

def main():
    if len(sys.argv) < 3:
        print("Uso: python3 safe-execute.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        print("")
        print("⚠️  NOTA: Este script requer que você tenha os dados completos da transação")
        print("   (to, value, data, etc.) para executar. É mais complexo que confirmar.")
        print("")
        print("💡 Recomendação: Use a interface web do Safe para executar:")
        print("   https://app.safe.global/")
        sys.exit(1)
    
    print("⚠️  Executar transações do Safe via script é complexo")
    print("   pois requer coletar todas as assinaturas dos owners.")
    print("")
    print("💡 Use a interface web do Safe para executar:")
    print("   https://app.safe.global/")
    print("")
    print("   Ou use o safe-cli interativo se conseguir corrigir:")
    print("   safe-cli <SAFE_ADDRESS> <RPC_URL>")
    print("   > load_cli_owners <PRIVATE_KEY>")
    print("   > execute-tx <SAFE_TX_HASH>")

if __name__ == "__main__":
    main()

