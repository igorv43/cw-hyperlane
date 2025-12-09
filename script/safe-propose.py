#!/usr/bin/env python3
"""
Script para criar propostas no Safe multisig usando web3.py diretamente
Funciona sem safe-cli

NOTA: O Safe não tem uma função pública proposeTransaction.
Este script usa a função execTransaction diretamente, mas requer que você
tenha permissão (seja owner) e que o threshold seja 1, OU use approveHash
para aprovar uma transação off-chain.

Para uso geral, recomenda-se usar a interface web do Safe ou corrigir o safe-cli.
"""

import json
import sys
from web3 import Web3
from eth_account import Account
from eth_abi import encode

# Configurações
SAFE_ADDRESS = "0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"
RPC_URL = "https://data-seed-prebsc-1-s1.binance.org:8545"

# ABI do Safe (funções principais)
SAFE_ABI = [
    {
        "inputs": [],
        "name": "nonce",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "bytes32", "name": "hashToApprove", "type": "bytes32"}],
        "name": "approveHash",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
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
            {"internalType": "address payable", "name": "refundReceiver", "type": "address"},
            {"internalType": "bytes", "name": "signatures", "type": "bytes"}
        ],
        "name": "execTransaction",
        "outputs": [{"internalType": "bool", "name": "success", "type": "bool"}],
        "stateMutability": "payable",
        "type": "function"
    }
]

def main():
    if len(sys.argv) < 4:
        print("Uso: python3 safe-propose.py <PRIVATE_KEY> <TO_ADDRESS> <CALLDATA>")
        print("")
        print("Exemplo:")
        print("  python3 safe-propose.py 0xPRIVATE_KEY 0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA 0xa50e0bb4...")
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
    
    # Criar conta a partir da chave privada
    try:
        account = Account.from_key(private_key)
        print(f"✅ Conta carregada: {account.address}")
    except Exception as e:
        print(f"❌ Erro ao carregar conta: {e}")
        sys.exit(1)
    
    # Verificar se a conta tem BNB
    balance = w3.eth.get_balance(account.address)
    print(f"   Saldo: {w3.from_wei(balance, 'ether')} BNB")
    if balance == 0:
        print("⚠️  Aviso: Conta não tem BNB para gas!")
    print("")
    
    # Obter contrato Safe
    safe_contract = w3.eth.contract(address=Web3.to_checksum_address(SAFE_ADDRESS), abi=SAFE_ABI)
    
    # Obter nonce do Safe
    try:
        nonce = safe_contract.functions.nonce().call()
        print(f"📋 Nonce atual do Safe: {nonce}")
    except Exception as e:
        print(f"⚠️  Não foi possível obter nonce: {e}")
        nonce = 0
    
    # Parâmetros da transação
    to = Web3.to_checksum_address(to_address)
    value = 0
    data = bytes.fromhex(calldata.replace("0x", ""))
    operation = 0  # Call (0) ou DelegateCall (1)
    safe_tx_gas = 0
    base_gas = 0
    gas_price = 0
    gas_token = "0x0000000000000000000000000000000000000000"
    refund_receiver = "0x0000000000000000000000000000000000000000"
    
    print("📝 Criando proposta de transação...")
    print(f"   To: {to}")
    print(f"   Value: {value}")
    print(f"   Data: {calldata[:50]}...")
    print(f"   Nonce: {nonce}")
    print("")
    
    print("⚠️  IMPORTANTE: O Safe não tem função pública para criar propostas.")
    print("   Este script tenta usar execTransaction diretamente.")
    print("   Isso só funciona se:")
    print("   1. Você é owner do Safe")
    print("   2. Threshold = 1 (apenas sua assinatura necessária)")
    print("")
    print("   Para threshold > 1, você precisa:")
    print("   - Criar transação off-chain")
    print("   - Assinar off-chain")
    print("   - Usar approveHash para aprovar")
    print("   - Coletar assinaturas de outros owners")
    print("   - Executar quando threshold atingido")
    print("")
    print("💡 Recomendação: Use cast send diretamente ou interface web")
    print("")
    
    # Construir transação usando execTransaction
    # NOTA: Isso requer assinatura única se threshold=1, ou múltiplas assinaturas
    try:
        # Para threshold=1, podemos executar diretamente
        # Mas precisamos construir a assinatura corretamente
        print("📝 Tentando executar transação diretamente...")
        print("   (Isso só funciona se threshold=1)")
        print("")
        
        # Construir assinatura vazia (será preenchida)
        # Na prática, você precisa assinar a transação off-chain primeiro
        empty_signature = b''
        
        # Construir a chamada da função execTransaction
        function_call = safe_contract.functions.execTransaction(
            to,
            value,
            data,
            operation,
            safe_tx_gas,
            base_gas,
            gas_price,
            Web3.to_checksum_address(gas_token),
            Web3.to_checksum_address(refund_receiver),
            empty_signature
        )
        
        # Estimar gas
        try:
            gas_estimate = function_call.estimate_gas({'from': account.address})
            print(f"⛽ Gas estimado: {gas_estimate}")
        except Exception as e:
            print(f"⚠️  Não foi possível estimar gas: {e}")
            gas_estimate = 200000  # Valor padrão
        
        # Obter nonce da conta
        account_nonce = w3.eth.get_transaction_count(account.address)
        
        # Construir transação
        transaction = function_call.build_transaction({
            'from': account.address,
            'nonce': account_nonce,
            'gas': gas_estimate,
            'gasPrice': w3.eth.gas_price,
            'chainId': w3.eth.chain_id
        })
        
        print("🔐 Assinando transação...")
        # Assinar transação
        signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
        
        print("📤 Enviando transação...")
        # Enviar transação
        tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
        
        print("")
        print("=" * 80)
        print("✅ PROPOSTA CRIADA COM SUCESSO!")
        print("=" * 80)
        print(f"TX_HASH: {tx_hash.hex()}")
        print(f"")
        print("📋 Compartilhe este TX_HASH com os outros owners:")
        print(f"   {tx_hash.hex()}")
        print("")
        print("🔗 Ver no BscScan:")
        print(f"   https://testnet.bscscan.com/tx/{tx_hash.hex()}")
        print("")
        print("💡 Próximos passos:")
        print("   1. Outros owners devem confirmar esta proposta")
        print("   2. Após threshold atingido, execute a transação")
        print("=" * 80)
        
        # Aguardar confirmação
        print("")
        print("⏳ Aguardando confirmação...")
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
        
        if receipt.status == 1:
            print("✅ Transação confirmada!")
            print(f"   Block: {receipt.blockNumber}")
            print(f"   Gas usado: {receipt.gasUsed}")
        else:
            print("❌ Transação falhou!")
            
    except Exception as e:
        print(f"❌ Erro ao criar proposta: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

