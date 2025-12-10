#!/usr/bin/env python3
"""
Script para executar propostas no Safe multisig
NOTA: Este script redireciona para safe-execute-complete.py que requer CALLDATA
"""

import sys
import os

def main():
    if len(sys.argv) < 3:
        print("Uso: python3 safe-execute.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        print("")
        print("⚠️  IMPORTANTE: Este script requer o CALLDATA original da proposta!")
        print("")
        print("O Safe TX Hash não contém os dados da transação (to, value, data).")
        print("Você precisa fornecer o CALLDATA usado na proposta original.")
        print("")
        print("💡 Use o script completo que aceita CALLDATA:")
        print("   python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA> [SAFE_TX_HASH]")
        print("")
        print("Exemplo:")
        print("   CALLDATA=$(cast calldata \"setInterchainSecurityModule(address)\" 0xNEW_ISM)")
        print("   python3 script/safe-execute-complete.py 0xPRIVATE_KEY $CALLDATA 0xSAFE_TX_HASH")
        print("")
        print("💡 Para verificar quantas assinaturas você precisa:")
        print("   python3 script/safe-check-signatures.py <SAFE_TX_HASH>")
        sys.exit(1)
    
    private_key = sys.argv[1]
    safe_tx_hash = sys.argv[2]
    
    print("=" * 80)
    print("⚠️  AVISO: safe-execute.py requer CALLDATA")
    print("=" * 80)
    print("")
    print("O Safe TX Hash não contém os dados da transação.")
    print("Para executar, você precisa do CALLDATA original usado na proposta.")
    print("")
    print("📋 Safe TX Hash fornecido:")
    print(f"   {safe_tx_hash}")
    print("")
    print("💡 Para executar, use:")
    print("   python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA> [SAFE_TX_HASH]")
    print("")
    print("💡 Para verificar status das assinaturas:")
    print(f"   python3 script/safe-check-signatures.py {safe_tx_hash}")
    print("")
    print("=" * 80)

if __name__ == "__main__":
    main()

