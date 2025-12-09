#!/usr/bin/env python3
"""
Script para confirmar propostas no Safe multisig usando safe-eth-py
"""

import sys

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
    if len(sys.argv) < 3:
        print("Uso: python3 safe-confirm.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        print("")
        print("Exemplo:")
        print("  python3 safe-confirm.py 0xPRIVATE_KEY 0xabc123...")
        sys.exit(1)
    
    private_key = sys.argv[1]
    safe_tx_hash = sys.argv[2]
    
    # Conectar à rede
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    if not w3.is_connected():
        print(f"❌ Erro: Não foi possível conectar ao RPC: {RPC_URL}")
        sys.exit(1)
    
    print(f"✅ Conectado à BSC Testnet")
    
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
    
    # Verificar threshold
    try:
        threshold = safe.retrieve_threshold()
        print(f"📊 Threshold: {threshold}")
    except:
        threshold = 1
        print(f"⚠️  Não foi possível obter threshold, assumindo: {threshold}")
    
    # Verificar owners que já aprovaram
    try:
        tx_hash_bytes = bytes.fromhex(safe_tx_hash.replace("0x", ""))
        approved_owners = safe.retrieve_owners_who_approved_hash(tx_hash_bytes)
        print(f"✅ Owners que já aprovaram: {len(approved_owners)}/{threshold}")
        for owner in approved_owners:
            print(f"   - {owner}")
    except Exception as e:
        print(f"⚠️  Não foi possível verificar aprovações: {e}")
    
    print("")
    print("🔐 Confirmando proposta...")
    
    try:
        # Aprovar hash usando safe-eth-py
        tx_hash_bytes = bytes.fromhex(safe_tx_hash.replace("0x", ""))
        tx_hash = safe.approve_hash(tx_hash_bytes, account.key)
        
        print("")
        print("=" * 80)
        print("✅ CONFIRMAÇÃO ENVIADA!")
        print("=" * 80)
        print(f"TX_HASH: {tx_hash.hex()}")
        print("")
        print("🔗 Ver no BscScan:")
        print(f"   https://testnet.bscscan.com/tx/{tx_hash.hex()}")
        print("")
        
        # Aguardar confirmação
        print("⏳ Aguardando confirmação...")
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
        
        if receipt.status == 1:
            print("✅ Confirmação confirmada!")
            print("")
            # Verificar novamente quantos aprovaram
            try:
                approved_owners = safe_contract.functions.getOwnersWhoApprovedTx(tx_hash_bytes).call()
                print(f"📊 Aprovações atuais: {len(approved_owners)}/{threshold}")
                if len(approved_owners) >= threshold:
                    print("")
                    print("🎉 THRESHOLD ATINGIDO! A proposta está pronta para execução!")
                    print("   Execute com: python3 safe-execute.py <PRIVATE_KEY> <SAFE_TX_HASH>")
            except:
                pass
        else:
            print("❌ Confirmação falhou!")
            
    except Exception as e:
        print(f"❌ Erro ao confirmar: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

