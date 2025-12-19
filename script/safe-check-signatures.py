#!/usr/bin/env python3
"""
Script para verificar quantas assinaturas são necessárias e quantas já foram coletadas
"""

import sys

try:
    from safe_eth.safe import Safe
    from safe_eth.eth.ethereum_client import EthereumClient
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
    if len(sys.argv) < 2:
        print("Uso: python3 safe-check-signatures.py <SAFE_TX_HASH>")
        print("")
        print("Exemplo:")
        print("  python3 safe-check-signatures.py 0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367")
        sys.exit(1)
    
    safe_tx_hash = sys.argv[1]
    
    # Criar EthereumClient e Safe
    try:
        ethereum_client = EthereumClient(RPC_URL)
        w3 = ethereum_client.w3
        if not w3.is_connected():
            print(f"❌ Erro: Não foi possível conectar ao RPC: {RPC_URL}")
            sys.exit(1)
        
        print(f"✅ Conectado à BSC Testnet")
        print("")
        
        safe = Safe(Web3.to_checksum_address(SAFE_ADDRESS), ethereum_client)
        print(f"✅ Safe carregado: {SAFE_ADDRESS}")
    except Exception as e:
        print(f"❌ Erro ao carregar Safe: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # Obter informações do Safe
    try:
        threshold = safe.retrieve_threshold()
        owners = safe.retrieve_owners()
        
        print("")
        print("=" * 80)
        print("📊 INFORMAÇÕES DO SAFE")
        print("=" * 80)
        print(f"Threshold: {threshold}")
        print(f"Total de owners: {len(owners)}")
        print("")
        print("👥 Owners do Safe:")
        for i, owner in enumerate(owners, 1):
            print(f"   {i}. {owner}")
        print("")
        
        # Verificar aprovações do hash
        tx_hash_bytes = bytes.fromhex(safe_tx_hash.replace("0x", ""))
        
        print("=" * 80)
        print(f"🔍 VERIFICANDO APROVAÇÕES DO HASH")
        print("=" * 80)
        print(f"Safe TX Hash: {safe_tx_hash}")
        print("")
        
        approved_count = 0
        approved_owners = []
        not_approved_owners = []
        
        for owner in owners:
            is_approved = safe.contract.functions.approvedHashes(owner, tx_hash_bytes).call()
            if is_approved:
                approved_count += 1
                approved_owners.append(owner)
                print(f"   ✅ {owner} - APROVADO")
            else:
                not_approved_owners.append(owner)
                print(f"   ❌ {owner} - NÃO APROVADO")
        
        print("")
        print("=" * 80)
        print("📈 RESUMO")
        print("=" * 80)
        print(f"Aprovações: {approved_count}/{threshold}")
        print(f"")
        
        if approved_count >= threshold:
            print("✅ THRESHOLD ATINGIDO!")
            print("   A transação está pronta para execução.")
            print("")
            print("💡 Para executar:")
            print("   python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA>")
        else:
            needed = threshold - approved_count
            print(f"⏳ FALTAM {needed} APROVAÇÃO(ÕES)")
            print("")
            if not_approved_owners:
                print("👥 Owners que ainda precisam aprovar:")
                for owner in not_approved_owners:
                    print(f"   - {owner}")
                print("")
                print("💡 Para aprovar:")
                print("   python3 script/safe-confirm.py <PRIVATE_KEY> <SAFE_TX_HASH>")
        
        print("")
        print("=" * 80)
        print("📝 SOBRE ASSINATURAS")
        print("=" * 80)
        print("")
        print("⚠️  IMPORTANTE: Há uma diferença entre:")
        print("")
        print("1. ✅ APROVAR o hash (approveHash):")
        print("   - Isso é feito com: python3 script/safe-confirm.py")
        print("   - Aprova o hash da transação no Safe")
        print("   - Status atual: " + ("✅ Threshold atingido" if approved_count >= threshold else f"⏳ Faltam {threshold - approved_count}"))
        print("")
        print("2. 🔐 ASSINAR a transação Safe (sign):")
        print("   - Isso é feito automaticamente quando você executa")
        print("   - Assina a transação Safe para execução")
        print("   - Requer que você tenha a chave privada do owner")
        print("")
        print("💡 Para executar uma transação, você precisa:")
        print(f"   - Threshold atingido: {'✅ Sim' if approved_count >= threshold else '❌ Não'}")
        print("   - Assinar a transação Safe (feito automaticamente no script)")
        print("   - Safe ter BNB suficiente para gas")
        print("")
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()




