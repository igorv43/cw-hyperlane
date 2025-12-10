#!/usr/bin/env python3
"""
Script para confirmar propostas no Safe multisig usando safe-eth-py
"""

import sys

try:
    from safe_eth.safe import Safe
    from safe_eth.eth.ethereum_client import EthereumClient
    from eth_account import Account
    from web3 import Web3
except ImportError:
    # Tentar importação alternativa
    try:
        from safe_eth_py import Safe
        from safe_eth_py.eth.ethereum_client import EthereumClient
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
    
    # Criar conta
    try:
        account = Account.from_key(private_key)
        print(f"✅ Conta: {account.address}")
    except Exception as e:
        print(f"❌ Erro ao carregar conta: {e}")
        sys.exit(1)
    
    # Criar EthereumClient (ele cria o Web3 internamente)
    try:
        ethereum_client = EthereumClient(RPC_URL)
        # Verificar conexão
        w3 = ethereum_client.w3
        if not w3.is_connected():
            print(f"❌ Erro: Não foi possível conectar ao RPC: {RPC_URL}")
            sys.exit(1)
        
        print(f"✅ Conectado à BSC Testnet")
        
        # Criar instância do Safe
        safe = Safe(Web3.to_checksum_address(SAFE_ADDRESS), ethereum_client)
        print(f"✅ Safe carregado: {SAFE_ADDRESS}")
    except Exception as e:
        print(f"❌ Erro ao carregar Safe: {e}")
        import traceback
        traceback.print_exc()
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
        # Obter todos os owners do Safe
        owners = safe.retrieve_owners()
        approved_count = 0
        approved_owners = []
        for owner in owners:
            is_approved = safe.contract.functions.approvedHashes(owner, tx_hash_bytes).call()
            if is_approved:
                approved_count += 1
                approved_owners.append(owner)
        print(f"✅ Owners que já aprovaram: {approved_count}/{threshold}")
        for owner in approved_owners:
            print(f"   - {owner}")
    except Exception as e:
        print(f"⚠️  Não foi possível verificar aprovações: {e}")
    
    print("")
    print("🔐 Confirmando proposta...")
    
    try:
        # Aprovar hash usando o contrato diretamente
        tx_hash_bytes = bytes.fromhex(safe_tx_hash.replace("0x", ""))
        
        # Construir transação para approveHash
        approve_tx = safe.contract.functions.approveHash(tx_hash_bytes).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 100000,
            'gasPrice': w3.eth.gas_price,
            'chainId': w3.eth.chain_id
        })
        
        # Assinar e enviar
        signed_txn = w3.eth.account.sign_transaction(approve_tx, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        
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
                owners = safe.retrieve_owners()
                approved_count = 0
                for owner in owners:
                    is_approved = safe.contract.functions.approvedHashes(owner, tx_hash_bytes).call()
                    if is_approved:
                        approved_count += 1
                print(f"📊 Aprovações atuais: {approved_count}/{threshold}")
                if approved_count >= threshold:
                    print("")
                    print("🎉 THRESHOLD ATINGIDO! A proposta está pronta para execução!")
                    print("   Execute via interface web: https://app.safe.global/")
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

