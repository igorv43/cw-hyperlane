#!/usr/bin/env python3
"""
Deploy TerraClassicIGP usando Python
Contorna limitações de compilação do forge/solc
"""

import json
import subprocess
import sys
import os
from pathlib import Path

# Configurações
RPC_URL = "https://1rpc.io/sepolia"
PRIVATE_KEY = "0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
ORACLE = "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
OVERHEAD = 200000

def run_command(cmd, shell=True):
    """Executa comando e retorna output"""
    result = subprocess.run(cmd, shell=shell, capture_output=True, text=True)
    return result.stdout.strip(), result.stderr.strip(), result.returncode

def get_owner_address():
    """Obtém endereço do owner a partir da private key"""
    stdout, stderr, code = run_command(f'cast wallet address --private-key "{PRIVATE_KEY}"')
    if code != 0:
        print(f"❌ Erro ao obter endereço: {stderr}")
        sys.exit(1)
    return stdout.strip()

def compile_contract():
    """Tenta compilar o contrato usando diferentes métodos"""
    
    print("🔨 Tentando compilar contrato...")
    print()
    
    # Método 1: solc direto com output em stdout
    print("   Método 1: solc --bin...")
    cmd = "solc --bin --optimize --optimize-runs 200 TerraClassicIGPStandalone.sol 2>&1"
    stdout, stderr, code = run_command(cmd)
    
    if "Binary:" in stdout:
        # Extrair bytecode
        lines = stdout.split('\n')
        for i, line in enumerate(lines):
            if "Binary:" in line and i + 1 < len(lines):
                bytecode = lines[i + 1].strip()
                if bytecode.startswith("0x") or len(bytecode) > 100:
                    if not bytecode.startswith("0x"):
                        bytecode = "0x" + bytecode
                    print(f"   ✅ Sucesso! Bytecode: {bytecode[:20]}...{bytecode[-20:]}")
                    return bytecode
    
    # Método 2: forge inspect
    print("   Método 2: forge inspect...")
    cmd = "forge inspect TerraClassicIGPStandalone bytecode 2>&1"
    stdout, stderr, code = run_command(cmd)
    
    if stdout.startswith("0x") and len(stdout) > 100:
        print(f"   ✅ Sucesso! Bytecode: {stdout[:20]}...{stdout[-20:]}")
        return stdout
    
    # Método 3: Tentar compilar arquivo temporário
    print("   Método 3: Compilação em /tmp...")
    try:
        temp_file = "/tmp/temp_contract.sol"
        with open("TerraClassicIGPStandalone.sol", "r") as f:
            contract_code = f.read()
        
        with open(temp_file, "w") as f:
            f.write(contract_code)
        
        cmd = f"solc --bin --optimize --optimize-runs 200 {temp_file} 2>&1"
        stdout, stderr, code = run_command(cmd)
        
        if "Binary:" in stdout:
            lines = stdout.split('\n')
            for i, line in enumerate(lines):
                if "Binary:" in line and i + 1 < len(lines):
                    bytecode = lines[i + 1].strip()
                    if not bytecode.startswith("0x"):
                        bytecode = "0x" + bytecode
                    print(f"   ✅ Sucesso! Bytecode: {bytecode[:20]}...{bytecode[-20:]}")
                    os.remove(temp_file)
                    return bytecode
        
        os.remove(temp_file)
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    return None

def encode_constructor_args(oracle, overhead, owner):
    """Codifica os argumentos do constructor"""
    print("🔧 Codificando constructor args...")
    cmd = f'cast abi-encode "constructor(address,uint96,address)" "{oracle}" "{overhead}" "{owner}"'
    stdout, stderr, code = run_command(cmd)
    
    if code != 0:
        print(f"❌ Erro ao codificar args: {stderr}")
        sys.exit(1)
    
    args = stdout.strip()
    print(f"   ✅ Args: {args[:20]}...{args[-20:]}")
    return args

def deploy_contract(bytecode, constructor_args):
    """Faz deploy do contrato"""
    
    # Combinar bytecode + args
    if constructor_args.startswith("0x"):
        constructor_args = constructor_args[2:]
    
    deploy_data = bytecode + constructor_args
    
    print()
    print("🚀 Fazendo deploy no Sepolia...")
    print(f"   Deploy data: {deploy_data[:50]}...{deploy_data[-50:]}")
    print()
    
    cmd = f'cast send --create "{deploy_data}" --rpc-url "{RPC_URL}" --private-key "{PRIVATE_KEY}" --json 2>&1'
    stdout, stderr, code = run_command(cmd)
    
    print("📤 Resposta do deploy:")
    print(stdout)
    if stderr:
        print(stderr)
    print()
    
    # Tentar extrair endereço do contrato
    try:
        result = json.loads(stdout)
        if "contractAddress" in result:
            return result["contractAddress"]
        elif "to" in result and result["to"] is None:
            # Calcular endereço do contrato
            tx_hash = result.get("transactionHash")
            if tx_hash:
                print(f"   TX Hash: {tx_hash}")
                print("   Aguardando confirmação...")
                
                # Aguardar receipt
                cmd = f'cast receipt {tx_hash} --rpc-url "{RPC_URL}" --json 2>&1'
                stdout, stderr, code = run_command(cmd)
                
                if code == 0:
                    receipt = json.loads(stdout)
                    if "contractAddress" in receipt and receipt["contractAddress"]:
                        return receipt["contractAddress"]
    except:
        pass
    
    return None

def main():
    print()
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║                                                                ║")
    print("║        🚀 DEPLOY AUTOMÁTICO DO TERRACLASSIC IGP               ║")
    print("║                                                                ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print()
    
    # Obter endereço do owner
    owner = get_owner_address()
    print("📊 Configuração:")
    print(f"   Owner:       {owner}")
    print(f"   Oracle:      {ORACLE}")
    print(f"   Overhead:    {OVERHEAD}")
    print()
    
    # Compilar
    bytecode = compile_contract()
    
    if not bytecode:
        print()
        print("❌ FALHA NA COMPILAÇÃO")
        print()
        print("Todas as tentativas de compilação falharam.")
        print("Recomendação: Deploy manual no Remix IDE")
        print()
        sys.exit(1)
    
    print()
    
    # Codificar args
    constructor_args = encode_constructor_args(ORACLE, OVERHEAD, owner)
    
    # Deploy
    contract_address = deploy_contract(bytecode, constructor_args)
    
    if contract_address:
        print()
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║                                                                ║")
        print("║                    ✅ DEPLOY SUCESSO!                          ║")
        print("║                                                                ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print()
        print(f"📍 Endereço do IGP: {contract_address}")
        print()
        print("Próximos passos:")
        print(f'  export IGP_ADDRESS="{contract_address}"')
        print("  ./deploy-igp-final.sh")
        print()
        
        # Salvar endereço
        with open("IGP_DEPLOYED_ADDRESS.txt", "w") as f:
            f.write(contract_address)
        
        return 0
    else:
        print()
        print("❌ DEPLOY FALHOU")
        print()
        print("Não foi possível extrair o endereço do contrato.")
        print("Verifique a transação manualmente ou use Remix IDE.")
        print()
        return 1

if __name__ == "__main__":
    sys.exit(main())
