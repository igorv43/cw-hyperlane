# 🚀 Guia Rápido: Criar IGP no Sepolia

## ⚡ Início Rápido (Método Recomendado)

Use o script Foundry - é o mais simples e direto:

```bash
# 1. Definir variáveis de ambiente
export SEPOLIA_PRIVATE_KEY="0xsua_private_key_aqui"
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# 2. Executar script
./script/deploy-igp-sepolia-foundry.sh
```

**Pronto!** O script irá:
- ✅ Compilar os contratos automaticamente
- ✅ Deploy do StorageGasOracle
- ✅ Deploy do InterchainGasPaymaster
- ✅ Configurar tudo automaticamente
- ✅ Associar ao Warp Route
- ✅ Salvar os endereços em arquivo JSON

## 📋 Pré-requisitos

### Instalar Foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Ter os Contratos Hyperlane
```bash
# Clonar o repositório (se ainda não tiver)
cd ~
git clone https://github.com/hyperlane-xyz/hyperlane-monorepo.git

# Ou especificar o caminho se já tiver
export CONTRACTS_PATH="/caminho/para/hyperlane-monorepo/solidity"
```

### Ter ETH no Sepolia
Obtenha ETH de testnet em:
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

## 🎯 Três Opções de Scripts

### Opção 1: Script Foundry (⭐ RECOMENDADO)

**Arquivo:** `deploy-igp-sepolia-foundry.sh`

**Vantagens:**
- ✅ Mais simples e direto
- ✅ Compila contratos automaticamente
- ✅ Usa ferramentas Foundry nativamente
- ✅ Melhor para desenvolvimento

**Uso:**
```bash
export SEPOLIA_PRIVATE_KEY="0x..."
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
./script/deploy-igp-sepolia-foundry.sh
```

### Opção 2: Script TypeScript

**Arquivo:** `criar-igp-e-associar-warp-sepolia.ts`

**Vantagens:**
- ✅ Melhor tratamento de erros
- ✅ Mais flexível
- ✅ Salva resultado em JSON estruturado

**Uso:**
```bash
export SEPOLIA_PRIVATE_KEY="0x..."
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
npx tsx script/criar-igp-e-associar-warp-sepolia.ts
```

**Nota:** Requer contratos compilados previamente

### Opção 3: Script Bash

**Arquivo:** `criar-igp-e-associar-warp-sepolia.sh`

**Vantagens:**
- ✅ Modo interativo disponível
- ✅ Não requer Node.js

**Uso:**
```bash
export SEPOLIA_PRIVATE_KEY="0x..."
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
./script/criar-igp-e-associar-warp-sepolia.sh
```

## 🔧 Configurações Avançadas

Todas as opções suportam estas variáveis de ambiente opcionais:

```bash
# Obrigatórias
export SEPOLIA_PRIVATE_KEY="0x..."
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# Opcionais - com valores padrão
export OWNER_ADDRESS="0x..."              # Padrão: endereço da private key
export BENEFICIARY_ADDRESS="0x..."        # Padrão: owner
export TERRA_DOMAIN="1325"                # Domain da Terra Classic
export TERRA_GAS_PRICE="28325000000"      # Gas price Terra (28.325 Gwei)
export TERRA_EXCHANGE_RATE="1805936462255558"  # Taxa LUNC/ETH * 1e10
export GAS_OVERHEAD="200000"              # Gas overhead
export SEPOLIA_RPC="https://1rpc.io/sepolia"  # RPC customizado
export CONTRACTS_PATH="$HOME/hyperlane-monorepo/solidity"  # Caminho dos contratos
```

## 📊 Exemplo de Saída

```
======================================================================
✅ DEPLOY CONCLUÍDO!
======================================================================

📋 Endereços dos Contratos:
──────────────────────────────────────────────────────────────────
StorageGasOracle:         0x1234...5678
InterchainGasPaymaster:   0xabcd...ef01
Warp Route:               0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

📋 Configuração:
──────────────────────────────────────────────────────────────────
Owner:                    0x9876...5432
Beneficiary:              0x9876...5432
Terra Domain:             1325
Terra Gas Price:          28325000000
Terra Exchange Rate:      1805936462255558
Gas Overhead:             200000

💾 Endereços salvos em: deployments/sepolia-igp-20260203-062345.json
```

## 🔍 Verificar Deploy

Após o deploy, verifique os contratos:

```bash
# Definir endereços (use os que foram deployados)
STORAGE_GAS_ORACLE="0x..."
IGP_ADDRESS="0x..."
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# Verificar configuração do Gas Oracle
cast call "$STORAGE_GAS_ORACLE" \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  1325 \
  --rpc-url https://1rpc.io/sepolia

# Verificar owner do IGP
cast call "$IGP_ADDRESS" \
  "owner()(address)" \
  --rpc-url https://1rpc.io/sepolia

# Verificar hook do Warp Route
cast call "$WARP_ROUTE" \
  "hook()(address)" \
  --rpc-url https://1rpc.io/sepolia
```

## ❓ Solução de Problemas

### "Foundry não encontrado"
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### "Contratos não encontrados"
```bash
# Especificar caminho customizado
export CONTRACTS_PATH="/caminho/para/hyperlane-monorepo/solidity"
```

### "Não é owner do Warp Route"
O script tentará associar o IGP ao Warp Route, mas isso só funcionará se você for o owner. Se não for, o script mostrará o comando para o owner executar.

### "Saldo insuficiente"
Obtenha ETH de testnet em https://sepoliafaucet.com/

## 📚 Documentação Completa

Para mais detalhes, consulte:
- [`README-IGP-SEPOLIA.md`](./README-IGP-SEPOLIA.md) - Documentação completa
- [Hyperlane Docs](https://docs.hyperlane.xyz/) - Documentação oficial

## 💡 Próximos Passos

Após criar o IGP:

1. **Configurar Relayer** para usar o novo IGP
2. **Testar transferências** entre Terra Classic e Sepolia
3. **Monitorar gas costs** e ajustar exchange rate se necessário
4. **Configurar outros domínios** (BSC, Solana, etc.) conforme necessário

## 🔐 Segurança

⚠️ **IMPORTANTE:**
- NUNCA compartilhe sua private key
- Use variáveis de ambiente, não hardcode
- Teste em testnet antes de produção
- Guarde os endereços dos contratos deployados
