# Criar IGP e Associar ao Warp Route - Sepolia

Este guia explica como criar um novo InterchainGasPaymaster (IGP) na rede Sepolia e associá-lo a um Warp Route.

## 📋 Pré-requisitos

### Ferramentas Necessárias

1. **Foundry** (para script bash):
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Node.js e TypeScript** (para script TypeScript):
   ```bash
   # Já deve estar instalado se você usa este projeto
   npm install -g tsx
   ```

3. **Contratos Hyperlane compilados**:
   ```bash
   cd ~/hyperlane-monorepo/solidity
   forge build
   ```

### Informações Necessárias

Antes de executar o script, você precisará de:

- ✅ **Private Key** da conta Sepolia (com ETH para gas)
- ✅ **Endereço do Warp Route** (ex: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`)
- ✅ Ser o **owner** do Warp Route (ou ter permissão para configurar hooks)
- ✅ **Configurações de gas** para Terra Classic (fornecidas como padrão)

## 🚀 Opção 1: Script TypeScript (Recomendado)

O script TypeScript oferece melhor tratamento de erros e validações.

### Uso Básico

```bash
# Definir variáveis de ambiente
export SEPOLIA_PRIVATE_KEY="0xsua_private_key_aqui"
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# Executar script
npx tsx script/criar-igp-e-associar-warp-sepolia.ts
```

### Configuração Avançada

```bash
# Todas as variáveis disponíveis
export SEPOLIA_PRIVATE_KEY="0x..."
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
export OWNER_ADDRESS="0x..."              # Opcional: padrão = endereço da private key
export BENEFICIARY_ADDRESS="0x..."        # Opcional: padrão = owner
export TERRA_GAS_PRICE="38325000000"      # Opcional: 38.325 uluna (atualizado 03/02/2026)
export TERRA_EXCHANGE_RATE="16020660000000"  # Opcional: (0.00003674/2292.94)*10^18 (atualizado 03/02/2026)
export GAS_OVERHEAD="200000"              # Opcional: overhead de gas
export RPC_URL="https://1rpc.io/sepolia"  # Opcional: RPC customizado

# Executar
npx tsx script/criar-igp-e-associar-warp-sepolia.ts
```

### Saída Esperada

```
================================================================================
CRIAR IGP E ASSOCIAR AO WARP ROUTE - SEPOLIA
================================================================================

🔗 Conectando ao Sepolia...
   RPC: https://1rpc.io/sepolia
✅ Conectado!
   Deployer: 0x...
   Owner: 0x...
   Beneficiary: 0x...

💰 Saldo: 0.1234 ETH

📋 Configuração:
   Warp Route: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
   Terra Domain: 1325
   ...

================================================================================
🚀 PASSO 1: Deploy StorageGasOracle
================================================================================

📤 Fazendo deploy do StorageGasOracle...
✅ StorageGasOracle deployado!
   Endereço: 0x...

...

================================================================================
✅ PROCESSO CONCLUÍDO!
================================================================================

📋 Endereços dos Contratos:
────────────────────────────────────────────────────────────────────────────
StorageGasOracle:         0x...
InterchainGasPaymaster:   0x...
Warp Route:               0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

💾 Salvando endereços em arquivo...
✅ Endereços salvos em: deployments/sepolia-igp.json
```

## 🔧 Opção 2: Script Bash

O script bash é mais leve, mas requer que os contratos já estejam compilados.

### Uso Básico

```bash
# Tornar executável
chmod +x script/criar-igp-e-associar-warp-sepolia.sh

# Modo Interativo
./script/criar-igp-e-associar-warp-sepolia.sh
```

### Modo Não-Interativo

```bash
# Definir todas as variáveis
export SEPOLIA_PRIVATE_KEY="0x..."
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
export OWNER_ADDRESS="0x..."
export BENEFICIARY_ADDRESS="0x..."
export SKIP_CONFIRM=true

# Executar
./script/criar-igp-e-associar-warp-sepolia.sh
```

## 📝 O Que o Script Faz

1. **Deploy StorageGasOracle**
   - Contrato que armazena taxas de câmbio e preços de gas
   - Configurado com dados da Terra Classic

2. **Configurar Gas Oracle**
   - Define exchange rate LUNC/ETH
   - Define gas price da Terra Classic
   - Configurado para domain 1325 (Terra Classic)

3. **Deploy InterchainGasPaymaster**
   - Contrato principal que gerencia pagamentos de gas interchain
   - Inicializado com owner e beneficiary
   - Conectado ao StorageGasOracle

4. **Configurar Destination Gas Configs**
   - Associa o StorageGasOracle ao IGP
   - Define gas overhead para Terra Classic

5. **Associar IGP ao Warp Route**
   - Chama `setHook(address)` no Warp Route
   - Configura o IGP como hook padrão

## 🔍 Verificação

Após a execução, você pode verificar os contratos:

```bash
# Verificar configuração do Gas Oracle
cast call "STORAGE_GAS_ORACLE_ADDRESS" \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  1325 \
  --rpc-url https://1rpc.io/sepolia

# Verificar owner do IGP
cast call "IGP_ADDRESS" \
  "owner()(address)" \
  --rpc-url https://1rpc.io/sepolia

# Verificar hook do Warp Route
cast call "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "hook()(address)" \
  --rpc-url https://1rpc.io/sepolia
```

## ⚠️ Possíveis Problemas

### 1. "Você não é o owner do Warp Route"

**Causa**: A conta que você está usando não é o owner do Warp Route.

**Solução**: 
- Verifique quem é o owner atual
- Use a conta correta ou peça ao owner para configurar o hook

```bash
cast call "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "owner()(address)" \
  --rpc-url https://1rpc.io/sepolia
```

### 2. "Bytecode não encontrado"

**Causa**: Os contratos Hyperlane não foram compilados.

**Solução**:
```bash
cd ~/hyperlane-monorepo/solidity
forge build
```

### 3. "Saldo insuficiente"

**Causa**: Conta não tem ETH suficiente para pagar o gas.

**Solução**: 
- Obtenha ETH de Sepolia faucet:
  - https://sepoliafaucet.com/
  - https://www.alchemy.com/faucets/ethereum-sepolia

### 4. "RPC falhou"

**Causa**: O RPC está fora do ar ou com problemas.

**Solução**: O script tentará automaticamente outros RPCs. Você também pode especificar um customizado:

```bash
export SEPOLIA_RPC="https://seu-rpc-preferido.com"
```

## 🔐 Segurança

- ⚠️ **NUNCA** compartilhe sua private key
- ⚠️ Use variáveis de ambiente, não hardcode a chave
- ✅ Teste primeiro em testnet antes de usar em mainnet
- ✅ Guarde os endereços dos contratos deployados em local seguro

## 📚 Referências

- [Documentação Hyperlane](https://docs.hyperlane.xyz/)
- [IGP (Interchain Gas Paymaster)](https://docs.hyperlane.xyz/docs/reference/hooks/interchain-gas-paymaster)
- [Warp Routes](https://docs.hyperlane.xyz/docs/reference/applications/warp-routes)

## 💡 Exemplos de Uso

### Criar IGP para outro domínio (ex: BSC)

Modifique as variáveis:

```bash
export TERRA_DOMAIN=97  # BSC Testnet
export TERRA_GAS_PRICE="5000000000"  # 5 Gwei
export TERRA_EXCHANGE_RATE="..." # Calcule a taxa de câmbio
```

### Atualizar configurações de gas após deploy

```bash
# Usar StorageGasOracle já deployado
cast send "STORAGE_GAS_ORACLE_ADDRESS" \
  "setRemoteGasData((uint32,uint128,uint128))" \
  "(1325,NEW_EXCHANGE_RATE,NEW_GAS_PRICE)" \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --rpc-url https://1rpc.io/sepolia
```

## 🆘 Suporte

Se encontrar problemas:

1. Verifique os logs do script
2. Confirme que todas as ferramentas estão instaladas
3. Verifique que os contratos estão compilados
4. Consulte a documentação do Hyperlane
