#!/usr/bin/env python3
"""
Script para criar propostas no Safe usando safe-eth-py diretamente
Funciona sem safe-cli, usando a biblioteca safe-eth-py
"""

import sys
import os

try:
    from safe_eth_py import Safe
    from eth_account import Account
    from web3 import Web3
except ImportError:
    print("❌ Bibliotecas necessárias não instaladas!")
    print("")
    print("Instale com:")
    print("  pip install safe-eth-py web3 eth-account")
    sys.exit(1)

# Configurações
SAFE_ADDRESS = "0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"
RPC_URL = "https://data-seed-prebsc-1-s1.binance.org:8545"

def main():
    if len(sys.argv) < 4:
        print("Uso: python3 safe-propose-direct.py <PRIVATE_KEY> <TO_ADDRESS> <CALLDATA>")
        print("")
        print("Exemplo:")
        print("  python3 safe-propose-direct.py 0xPRIVATE_KEY 0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA 0xa50e0bb4...")
        sys.exit(1)
    
    private_key = sys.argv[1]
    to_address = sys.argv[2]
    calldata = sys.argv[3]
    
    # Conectar à rede
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    if not w3.is_connected():
        print(f"❌ Erro: Não foi possível conectar ao RPC: {RPC_URL}")
        sys.exit(1)
    
    print(f"✅ Conectado à BSC Testnet")
    print(f"   Chain ID: {w3.eth.chain_id}")
    print("")
    
    # Criar conta
    try:
        account = Account.from_key(private_key)
        print(f"✅ Conta: {account.address}")
    except Exception as e:
        print(f"❌ Erro ao carregar conta: {e}")
        sys.exit(1)
    
    # Criar instância do Safe
    try:
        safe = Safe(SAFE_ADDRESS, RPC_URL)
        print(f"✅ Safe carregado: {SAFE_ADDRESS}")
    except Exception as e:
        print(f"❌ Erro ao carregar Safe: {e}")
        sys.exit(1)
    
    # Preparar transação
    to = Web3.to_checksum_address(to_address)
    value = 0
    data = bytes.fromhex(calldata.replace("0x", ""))
    
    print("")
    print("📝 Criando proposta de transação...")
    print(f"   To: {to}")
    print(f"   Value: {value}")
    print(f"   Data: {calldata[:50]}...")
    print("")
    
    try:
        # Criar transação Safe
        safe_tx = safe.build_multisig_tx(
            to=to,
            value=value,
            data=data,
            operation=0,  # Call
            safe_tx_gas=0,
            base_gas=0,
            gas_price=0,
            gas_token=None,
            refund_receiver=None,
            signatures=None
        )
        
        print("✅ Transação Safe criada!")
        print(f"   Safe TX Hash: {safe_tx.safe_tx_hash.hex()}")
        print("")
        
        # Assinar transação off-chain
        print("🔐 Assinando transação off-chain...")
        safe_tx.sign(account.key)
        
        print("✅ Transação assinada!")
        print("")
        
        # Aprovar hash (propor)
        print("📤 Aprovando hash (criando proposta)...")
        tx_hash = safe.approve_hash(safe_tx.safe_tx_hash, account.key)
        
        print("")
        print("=" * 80)
        print("✅ PROPOSTA CRIADA COM SUCESSO!")
        print("=" * 80)
        print(f"TX_HASH: {tx_hash.hex()}")
        print(f"Safe TX Hash: {safe_tx.safe_tx_hash.hex()}")
        print("")
        print("📋 Compartilhe o Safe TX Hash com os outros owners:")
        print(f"   {safe_tx.safe_tx_hash.hex()}")
        print("")
        print("🔗 Ver no BscScan:")
        print(f"   https://testnet.bscscan.com/tx/{tx_hash.hex()}")
        print("")
        print("💡 Próximos passos:")
        print("   1. Outros owners devem confirmar usando:")
        print("      python3 safe-confirm.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        print("   2. Após threshold atingido, execute a transação")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Erro ao criar proposta: {e}")
        import traceback
        traceback.print_exc()
        print("")
        print("💡 Alternativa: Use cast send diretamente:")
        print(f"   cast send {SAFE_ADDRESS} 'approveHash(bytes32)' <HASH> \\")
        print(f"     --private-key {private_key[:10]}... \\")
        print(f"     --rpc-url {RPC_URL}")
        sys.exit(1)

if __name__ == "__main__":
    main()

