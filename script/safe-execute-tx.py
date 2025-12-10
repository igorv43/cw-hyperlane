#!/usr/bin/env python3
"""
Script para executar uma transação do Safe após threshold atingido
"""

import sys

try:
    from safe_eth.safe import Safe
    from safe_eth.eth.ethereum_client import EthereumClient
    from safe_eth.safe.safe_tx import SafeTx
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
        print("Uso: python3 safe-execute-tx.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        print("")
        print("Exemplo:")
        print("  python3 safe-execute-tx.py 0xPRIVATE_KEY 0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367")
        print("")
        print("⚠️  NOTA: Este script tenta recuperar a transação do Safe e executá-la.")
        print("   Se a transação não estiver no Safe, você precisará fornecer os dados manualmente.")
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
        
        print(f"✅ Aprovações: {approved_count}/{threshold}")
        if approved_count < threshold:
            print(f"❌ Threshold não atingido! Faltam {threshold - approved_count} aprovação(ões)")
            sys.exit(1)
        
        print("✅ Threshold atingido! Prosseguindo com execução...")
        print("")
    except Exception as e:
        print(f"⚠️  Erro ao verificar aprovações: {e}")
        print("   Continuando mesmo assim...")
        print("")
    
    # Tentar recuperar a transação do Safe
    # NOTA: O Safe não armazena transações pendentes on-chain, então precisamos
    # reconstruir a transação ou usar a interface web
    
    print("⚠️  IMPORTANTE: Para executar uma transação do Safe via script,")
    print("   você precisa ter todos os dados da transação original:")
    print("   - to (endereço destino)")
    print("   - value (valor em wei)")
    print("   - data (calldata)")
    print("   - operation (0 = Call, 1 = DelegateCall)")
    print("")
    print("💡 RECOMENDAÇÃO: Use a interface web do Safe para executar:")
    print("   1. Acesse: https://app.safe.global/")
    print("   2. Conecte sua wallet")
    print("   3. Selecione o Safe")
    print("   4. Vá em 'Queue' ou 'History'")
    print("   5. Encontre a transação e clique em 'Execute'")
    print("")
    print("🔗 Ver transação no BscScan:")
    print(f"   https://testnet.bscscan.com/address/{SAFE_ADDRESS}")
    print("")
    print("📋 Safe TX Hash para referência:")
    print(f"   {safe_tx_hash}")
    
    # Se você tiver os dados da transação, pode executar assim:
    # (descomente e preencha os valores)
    """
    try:
        # Dados da transação (preencha com os valores corretos)
        to = Web3.to_checksum_address("0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA")
        value = 0
        data = bytes.fromhex("3f4ba83a...")  # Seu calldata
        operation = 0  # Call
        
        # Reconstruir transação Safe
        safe_tx = safe.build_multisig_tx(
            to=to,
            value=value,
            data=data,
            operation=operation,
            safe_tx_gas=0,
            base_gas=0,
            gas_price=0,
            gas_token=None,
            refund_receiver=None,
            signatures=None
        )
        
        # Coletar assinaturas dos owners que aprovaram
        signatures = b''
        for owner in approved_owners:
            # Cada owner precisa assinar a transação
            # Isso requer a chave privada de cada owner
            pass
        
        # Executar transação
        # tx_hash = safe_tx.execute(account.key)
        # print(f"✅ Transação executada: {tx_hash.hex()}")
        
    except Exception as e:
        print(f"❌ Erro ao executar: {e}")
        import traceback
        traceback.print_exc()
    """

if __name__ == "__main__":
    main()

