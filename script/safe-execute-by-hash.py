#!/usr/bin/env python3
"""
Script para executar uma transação do Safe usando o Safe TX Hash
Similar ao comando: safe-cli execute --tx-hash <HASH>
"""

import sys

try:
    from safe_eth.safe import Safe
    from safe_eth.eth.ethereum_client import EthereumClient
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
    if len(sys.argv) < 3:
        print("Uso: python3 safe-execute-by-hash.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        print("")
        print("Exemplo:")
        print("  python3 safe-execute-by-hash.py 0xPRIVATE_KEY 0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367")
        print("")
        print("⚠️  NOTA: Este script executa uma transação do Safe usando o Safe TX Hash.")
        print("   O Safe TX Hash identifica a transação proposta no Safe.")
        sys.exit(1)
    
    private_key = sys.argv[1]
    safe_tx_hash = sys.argv[2]
    
    # Criar conta
    try:
        account = Account.from_key(private_key)
        print(f"✅ Conta: {account.address}")
    except Exception as e:
        print(f"❌ Erro ao carregar conta: {e}")
        sys.exit(1)
    
    # Criar EthereumClient e Safe
    try:
        ethereum_client = EthereumClient(RPC_URL)
        w3 = ethereum_client.w3
        if not w3.is_connected():
            print(f"❌ Erro: Não foi possível conectar ao RPC: {RPC_URL}")
            sys.exit(1)
        
        print(f"✅ Conectado à BSC Testnet")
        print(f"   Chain ID: {w3.eth.chain_id}")
        print("")
        
        safe = Safe(Web3.to_checksum_address(SAFE_ADDRESS), ethereum_client)
        print(f"✅ Safe carregado: {SAFE_ADDRESS}")
    except Exception as e:
        print(f"❌ Erro ao carregar Safe: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # Verificar threshold e aprovações
    try:
        threshold = safe.retrieve_threshold()
        owners = safe.retrieve_owners()
        tx_hash_bytes = bytes.fromhex(safe_tx_hash.replace("0x", ""))
        
        print(f"📊 Threshold: {threshold}")
        print(f"👥 Total de owners: {len(owners)}")
        print("")
        
        approved_count = 0
        approved_owners = []
        for owner in owners:
            is_approved = safe.contract.functions.approvedHashes(owner, tx_hash_bytes).call()
            if is_approved:
                approved_count += 1
                approved_owners.append(owner)
                print(f"   ✅ {owner} - APROVADO")
        
        print(f"\n📈 Aprovações: {approved_count}/{threshold}")
        if approved_count < threshold:
            print(f"❌ Threshold não atingido! Faltam {threshold - approved_count} aprovação(ões)")
            sys.exit(1)
        
        print("✅ Threshold atingido! Prosseguindo com execução...")
        print("")
    except Exception as e:
        print(f"⚠️  Erro ao verificar aprovações: {e}")
        print("   Continuando mesmo assim...")
        print("")
    
    # Verificar saldo do Safe
    safe_balance = w3.eth.get_balance(SAFE_ADDRESS)
    print(f"💰 Saldo do Safe: {w3.from_wei(safe_balance, 'ether')} BNB")
    if safe_balance == 0:
        print("⚠️  AVISO: Safe não tem BNB!")
        print("   O Safe precisa de BNB para pagar o gas da execução.")
        sys.exit(1)
    print("")
    
    # PROBLEMA: O Safe não armazena os dados da transação on-chain
    # O Safe TX Hash é apenas um hash, não contém os dados (to, value, data)
    # Precisamos ter os dados da transação original
    
    print("⚠️  IMPORTANTE: O Safe TX Hash não contém os dados da transação.")
    print("   Para executar, você precisa fornecer:")
    print("   - Endereço destino (to)")
    print("   - Valor (value)")
    print("   - Dados (data/calldata)")
    print("")
    print("💡 SOLUÇÃO: Use o script safe-execute-complete.py que já tem os dados:")
    print("   python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA>")
    print("")
    print("   Ou forneça os dados manualmente abaixo:")
    print("")
    
    # Tentar recuperar da última proposta conhecida
    # (você pode adicionar os dados aqui se souber)
    TO_ADDRESS = "0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA"  # Warp Route
    VALUE = 0
    
    print(f"📝 Usando dados da última proposta conhecida:")
    print(f"   To: {TO_ADDRESS}")
    print(f"   Value: {VALUE}")
    print(f"   Data: [PRECISA DO CALLDATA ORIGINAL]")
    print("")
    print("❌ Não é possível executar sem o CALLDATA original.")
    print("")
    print("💡 ALTERNATIVAS:")
    print("   1. Use safe-execute-complete.py com o CALLDATA:")
    print("      python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA>")
    print("")
    print("   2. Se você tem o CALLDATA, pode executar diretamente:")
    print("      CALLDATA=0x3f4ba83a...")
    print("      python3 script/safe-execute-complete.py <PRIVATE_KEY> $CALLDATA")

if __name__ == "__main__":
    main()







