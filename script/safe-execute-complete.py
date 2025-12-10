#!/usr/bin/env python3
"""
Script para executar uma transação do Safe após threshold atingido
Usa os dados da proposta original para reconstruir e executar
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

# Dados da transação original (da proposta anterior)
# Se você tiver uma nova proposta, atualize estes valores
TO_ADDRESS = "0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA"  # Warp Route
SAFE_TX_HASH = "73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367"

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 safe-execute-complete.py <PRIVATE_KEY> <CALLDATA> [SAFE_TX_HASH]")
        print("")
        print("Exemplo:")
        print("  python3 safe-execute-complete.py 0xPRIVATE_KEY 0x3f4ba83a...")
        print("  python3 safe-execute-complete.py 0xPRIVATE_KEY 0x3f4ba83a... 0x73b17378...")
        print("")
        print("⚠️  NOTA: CALLDATA é obrigatório. Safe TX Hash é opcional (para validação)")
        sys.exit(1)
    
    private_key = sys.argv[1]
    calldata = sys.argv[2] if len(sys.argv) > 2 else None
    safe_tx_hash_provided = sys.argv[3] if len(sys.argv) > 3 else None
    
    if not calldata:
        print("❌ Erro: CALLDATA é obrigatório!")
        print("   Forneça o CALLDATA usado na proposta original")
        sys.exit(1)
    
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
        
        # Usar Safe TX Hash fornecido ou o padrão
        safe_tx_hash_to_check = safe_tx_hash_provided if safe_tx_hash_provided else SAFE_TX_HASH
        tx_hash_bytes = bytes.fromhex(safe_tx_hash_to_check.replace("0x", ""))
        
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
        
        # Verificar saldo do Safe
        safe_balance = w3.eth.get_balance(SAFE_ADDRESS)
        print(f"💰 Saldo do Safe: {w3.from_wei(safe_balance, 'ether')} BNB")
        if safe_balance == 0:
            print("⚠️  AVISO: Safe não tem BNB!")
            print("   O Safe precisa de BNB para pagar o gas da execução.")
            print("   Transfira BNB para o Safe antes de executar.")
            print("")
            print("   Endereço do Safe: " + SAFE_ADDRESS)
            sys.exit(1)
        print("")
    except Exception as e:
        print(f"⚠️  Erro ao verificar aprovações: {e}")
        print("   Continuando mesmo assim...")
        print("")
    
    # Preparar dados da transação
    if calldata:
        data = bytes.fromhex(calldata.replace("0x", ""))
        print(f"📝 Usando CALLDATA fornecido: {calldata[:50]}...")
    else:
        print("⚠️  CALLDATA não fornecido. Você precisa fornecer o calldata da transação original.")
        print("   Execute novamente com: python3 safe-execute-complete.py <PRIVATE_KEY> <CALLDATA>")
        sys.exit(1)
    
    to = Web3.to_checksum_address(TO_ADDRESS)
    value = 0
    operation = 0  # Call
    
    print("")
    print("📝 Reconstruindo transação Safe...")
    print(f"   To: {to}")
    print(f"   Value: {value}")
    print(f"   Data: {calldata[:50]}...")
    print("")
    
    try:
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
        
        print(f"✅ Transação Safe reconstruída!")
        print(f"   Safe TX Hash: {safe_tx.safe_tx_hash.hex()}")
        
        # Verificar se o hash corresponde (se fornecido)
        if safe_tx_hash_provided:
            if safe_tx.safe_tx_hash.hex() != safe_tx_hash_provided.replace("0x", ""):
                print(f"⚠️  AVISO: Safe TX Hash não corresponde!")
                print(f"   Esperado: {safe_tx_hash_provided}")
                print(f"   Obtido: {safe_tx.safe_tx_hash.hex()}")
                print("   Continuando mesmo assim...")
        else:
            print(f"📋 Safe TX Hash gerado: {safe_tx.safe_tx_hash.hex()}")
            print(f"   (Use este hash para referência futura)")
        
        print("")
        print("🔐 Coletando assinaturas dos owners que aprovaram...")
        
        # Coletar assinaturas
        # NOTA: Para executar, precisamos das assinaturas de TODOS os owners que aprovaram
        # Se você tem apenas uma chave privada, só pode assinar com ela
        # Os outros owners precisam assinar off-chain e você precisa coletar as assinaturas
        
        # Verificar signers antes de assinar
        print(f"📋 Signers antes de assinar: {len(safe_tx.signers)}")
        
        # Assinar com a chave privada fornecida
        signature_bytes = safe_tx.sign(private_key)
        print(f"✅ Assinado com: {account.address}")
        print(f"📋 Signers após assinar: {len(safe_tx.signers)}")
        
        # Verificar se o owner está nos signers
        signer_addresses = [Web3.to_checksum_address(s) for s in safe_tx.signers]
        if account.address not in signer_addresses:
            print(f"⚠️  AVISO: Owner {account.address} não está nos signers!")
            print(f"   Signers: {signer_addresses}")
        
        # Para executar, você precisa de todas as assinaturas
        # Verificar se threshold foi atingido e se o owner atual aprovou
        owner_approved = account.address.lower() in [o.lower() for o in approved_owners]
        
        print(f"📋 Status:")
        print(f"   Threshold: {threshold}")
        print(f"   Aprovações: {approved_count}")
        print(f"   Owner atual aprovou: {'✅ Sim' if owner_approved else '❌ Não'}")
        print(f"   Owner atual: {account.address}")
        print("")
        
        if approved_count >= threshold and owner_approved:
            print("")
            print("🚀 Executando transação...")
            
            # Verificar se temos assinaturas suficientes
            if len(safe_tx.signers) < threshold:
                print(f"❌ Erro: Assinaturas insuficientes!")
                print(f"   Signers: {len(safe_tx.signers)}")
                print(f"   Threshold: {threshold}")
                print("")
                print("💡 O problema é que o SafeTx precisa ter assinaturas de TODOS os owners")
                print("   que aprovaram o hash. Apenas aprovar o hash não é suficiente -")
                print("   você também precisa assinar a transação Safe.")
                print("")
                print("💡 SOLUÇÃO: Use a interface web do Safe:")
                print("   https://app.safe.global/")
                print("   A interface web gerencia isso automaticamente.")
                sys.exit(1)
            
            # Usar o método execute() do SafeTx que formata as assinaturas corretamente
            print("📝 Usando método execute() do SafeTx para formatar assinaturas corretamente...")
            
            # Tentar usar o método execute() do SafeTx primeiro
            print("📝 Tentando executar com método execute() do SafeTx...")
            
            try:
                # Executar usando o método do SafeTx
                tx_hash, tx_params = safe_tx.execute(
                    tx_sender_private_key=private_key,
                    tx_gas=None,
                    tx_gas_price=None,
                    tx_nonce=None,
                    block_identifier='latest'
                )
                print("✅ Método execute() funcionou!")
            except Exception as e:
                error_msg = str(e)
                if 'GS013' in error_msg:
                    print("⚠️  Método execute() falhou com GS013, tentando abordagem alternativa...")
                    print("")
                    
                    # Abordagem alternativa: usar w3_tx do SafeTx que já tem assinaturas formatadas
                    # O w3_tx é a transação Web3 já construída com assinaturas
                    try:
                        print("📝 Tentando usar w3_tx do SafeTx...")
                        
                        # O w3_tx já tem as assinaturas formatadas corretamente
                        if hasattr(safe_tx, 'w3_tx'):
                            exec_tx = safe_tx.w3_tx
                            
                            # Verificar se a transação tem as assinaturas
                            if 'data' in exec_tx:
                                print(f"✅ Transação construída com {len(exec_tx.get('data', ''))} bytes de dados")
                            
                            # Estimar gas manualmente sem validar assinaturas
                            print("⛽ Estimando gas...")
                            try:
                                # Tentar estimar gas diretamente na função execTransaction
                                gas_estimate = safe.contract.functions.execTransaction(
                                    to,
                                    value,
                                    data,
                                    operation,
                                    0,  # safeTxGas
                                    0,  # baseGas  
                                    0,  # gasPrice
                                    "0x0000000000000000000000000000000000000000",  # gasToken
                                    "0x0000000000000000000000000000000000000000",  # refundReceiver
                                    safe_tx.sorted_signers  # Usar sorted_signers que já tem formato correto
                                ).estimate_gas({'from': account.address})
                                print(f"✅ Gas estimado: {gas_estimate}")
                            except Exception as gas_err:
                                print(f"⚠️  Não foi possível estimar gas: {gas_err}")
                                gas_estimate = 300000  # Valor maior para garantir
                                print(f"   Usando gas fixo: {gas_estimate}")
                            
                            # Construir transação manualmente
                            print("🔨 Construindo transação manualmente...")
                            
                            # Obter assinaturas formatadas
                            # O SafeTx mantém as assinaturas nos signers
                            # Precisamos construir no formato: owner_address (20) + r (32) + s (32) + v (1) = 85 bytes por owner
                            
                            # Verificar o que sorted_signers retorna
                            print(f"📋 Signers: {safe_tx.signers}")
                            print(f"📋 Sorted signers: {safe_tx.sorted_signers}")
                            
                            # Construir assinaturas no formato correto
                            # Para cada signer, precisamos: owner_address + signature
                            signatures_data = b''
                            
                            # Os signers são endereços, precisamos encontrar as assinaturas correspondentes
                            # O SafeTx armazena assinaturas por endereço
                            # Vamos usar a assinatura que já temos
                            
                            # Para threshold = 1, precisamos apenas da assinatura do owner que aprovou
                            # Formato: owner_address (20 bytes) + r (32) + s (32) + v (1) = 85 bytes
                            owner_bytes = bytes.fromhex(account.address.replace("0x", ""))
                            signatures_data = owner_bytes + signature_bytes
                            
                            print(f"📝 Formato da assinatura:")
                            print(f"   Owner: {account.address} ({len(owner_bytes)} bytes)")
                            print(f"   Signature: {len(signature_bytes)} bytes (r+s+v)")
                            print(f"   Total: {len(signatures_data)} bytes")
                            
                            # Construir transação
                            exec_tx = safe.contract.functions.execTransaction(
                                to,
                                value,
                                data,
                                operation,
                                0,  # safeTxGas
                                0,  # baseGas
                                0,  # gasPrice
                                "0x0000000000000000000000000000000000000000",  # gasToken
                                "0x0000000000000000000000000000000000000000",  # refundReceiver
                                signatures_data
                            ).build_transaction({
                                'from': account.address,
                                'nonce': w3.eth.get_transaction_count(account.address),
                                'gas': gas_estimate,
                                'gasPrice': w3.eth.gas_price,
                                'chainId': w3.eth.chain_id,
                                'value': 0
                            })
                            
                            # Assinar e enviar
                            print("🔐 Assinando e enviando transação...")
                            signed_exec_tx = w3.eth.account.sign_transaction(exec_tx, private_key)
                            tx_hash = w3.eth.send_raw_transaction(signed_exec_tx.raw_transaction)
                            tx_hash_str = tx_hash.hex()
                            print("✅ Transação enviada!")
                            
                        else:
                            raise Exception("SafeTx não tem w3_tx")
                            
                    except Exception as alt_err:
                        print(f"❌ Abordagem alternativa também falhou: {alt_err}")
                        print("")
                        print("💡 O problema é que o Safe precisa de assinaturas no formato específico")
                        print("   e o SafeTx pode não estar coletando corretamente dos approvedHashes.")
                        print("")
                        print("💡 SOLUÇÕES ALTERNATIVAS:")
                        print("   1. Use cast send diretamente (mais complexo)")
                        print("   2. Use safe-cli interativo (se conseguir corrigir)")
                        print("   3. Use um script que coleta assinaturas de todos os owners")
                        raise
                else:
                    raise
            
            # tx_hash já é um HexBytes, converter para string
            tx_hash_str = tx_hash.hex() if hasattr(tx_hash, 'hex') else str(tx_hash)
            
            print("")
            print("=" * 80)
            print("✅ TRANSAÇÃO EXECUTADA COM SUCESSO!")
            print("=" * 80)
            print(f"TX_HASH: {tx_hash_str}")
            print("")
            print("🔗 Ver no BscScan:")
            print(f"   https://testnet.bscscan.com/tx/{tx_hash_str}")
            print("=" * 80)
            
            # Aguardar confirmação
            print("")
            print("⏳ Aguardando confirmação...")
            # Usar o tx_hash diretamente (pode ser HexBytes ou string)
            if isinstance(tx_hash, bytes):
                receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
            else:
                receipt = w3.eth.wait_for_transaction_receipt(tx_hash_str, timeout=120)
            
            # Receipt é um dict, não um objeto
            status = receipt.get('status') if isinstance(receipt, dict) else receipt.status
            if status == 1:
                print("✅ Transação confirmada!")
                block_number = receipt.get('blockNumber') if isinstance(receipt, dict) else receipt.blockNumber
                gas_used = receipt.get('gasUsed') if isinstance(receipt, dict) else receipt.gasUsed
                print(f"   Block: {block_number}")
                print(f"   Gas usado: {gas_used}")
            else:
                print("❌ Transação falhou!")
                print("   Erro: GS013 - Invalid signatures or insufficient signatures")
                print("   Isso geralmente significa que as assinaturas não estão no formato correto")
                print("")
                print("💡 SOLUÇÃO: Use a interface web do Safe para executar:")
                print("   https://app.safe.global/")
                print("   A interface web coleta e formata as assinaturas corretamente")
        else:
            print("")
            if approved_count < threshold:
                print(f"❌ Threshold não atingido!")
                print(f"   Aprovações: {approved_count}/{threshold}")
                print(f"   Faltam {threshold - approved_count} aprovação(ões)")
            elif not owner_approved:
                print(f"⚠️  Você não aprovou esta transação!")
                print(f"   Aprovações: {approved_count}/{threshold}")
                print(f"   Owners que aprovaram:")
                for owner in approved_owners:
                    print(f"     - {owner}")
                print("")
                print("💡 Você precisa aprovar primeiro:")
                print("   python3 script/safe-confirm.py <PRIVATE_KEY> <SAFE_TX_HASH>")
            else:
                print("⚠️  Condição não atendida para execução")
                print(f"   Aprovações: {approved_count}/{threshold}")
                print(f"   Owner aprovou: {owner_approved}")
            print("")
            print("💡 Para verificar status completo:")
            print("   python3 script/safe-check-signatures.py <SAFE_TX_HASH>")
            
    except Exception as e:
        print(f"❌ Erro ao executar transação: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

