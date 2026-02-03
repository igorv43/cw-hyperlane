#!/bin/bash

# ==============================================================================
# EXEMPLO DE USO: Deploy IGP no Sepolia
# ==============================================================================
#
# Este é um arquivo de exemplo mostrando como usar o script de deploy do IGP.
# 
# IMPORTANTE: 
# 1. Copie este arquivo e ajuste as variáveis conforme necessário
# 2. NUNCA commite este arquivo com sua private key!
# 3. Use variáveis de ambiente ou arquivos .env para segurança
#
# ==============================================================================

# Definir suas credenciais
# ATENÇÃO: Substitua pelos seus valores reais!
export SEPOLIA_PRIVATE_KEY="SUA_PRIVATE_KEY_AQUI"  # ⚠️ NUNCA COMMITE ISSO!

# Endereço do Warp Route que você quer associar ao IGP
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# ==============================================================================
# CONFIGURAÇÕES OPCIONAIS
# ==============================================================================

# Se você quiser usar endereços específicos para owner/beneficiary
# (Se não definir, usará o endereço derivado da private key)
# export OWNER_ADDRESS="0xSEU_ENDERECO_AQUI"
# export BENEFICIARY_ADDRESS="0xSEU_ENDERECO_AQUI"

# Configurações de gas para Terra Classic (já com valores padrão bons)
# Só altere se souber o que está fazendo
# export TERRA_DOMAIN="1325"
# export TERRA_GAS_PRICE="28325000000"  # 28.325 Gwei
# export TERRA_EXCHANGE_RATE="1805936462255558"
# export GAS_OVERHEAD="200000"

# RPC do Sepolia (se quiser usar um específico)
# export SEPOLIA_RPC="https://1rpc.io/sepolia"

# Caminho dos contratos Hyperlane (se não estiver no padrão)
# export CONTRACTS_PATH="$HOME/hyperlane-monorepo/solidity"

# ==============================================================================
# EXECUTAR DEPLOY
# ==============================================================================

# Método 1: Script Foundry (RECOMENDADO - mais simples)
echo "🚀 Iniciando deploy do IGP usando Foundry..."
echo ""
./script/deploy-igp-sepolia-foundry.sh

# Método 2: Script TypeScript (alternativa)
# echo "🚀 Iniciando deploy do IGP usando TypeScript..."
# npx tsx script/criar-igp-e-associar-warp-sepolia.ts

# Método 3: Script Bash (alternativa)
# echo "🚀 Iniciando deploy do IGP usando Bash..."
# ./script/criar-igp-e-associar-warp-sepolia.sh

# ==============================================================================
# APÓS O DEPLOY
# ==============================================================================
#
# O script irá:
# 1. Deployar StorageGasOracle
# 2. Deployar InterchainGasPaymaster
# 3. Configurar tudo automaticamente
# 4. Associar ao Warp Route
# 5. Salvar endereços em: deployments/sepolia-igp-YYYYMMDD-HHMMSS.json
#
# Anote os endereços dos contratos deployados!
#
# ==============================================================================
