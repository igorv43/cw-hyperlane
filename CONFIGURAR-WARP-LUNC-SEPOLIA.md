# Configurar Warp LUNC para Sepolia (Ethereum Testnet)

Este guia fornece instruções passo a passo para configurar o Warp Route do LUNC (Terra Classic) para Sepolia (Ethereum Testnet), seguindo o mesmo padrão usado para BSC Testnet.

## Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Passo 1: Instanciar ISM Multisig para Sepolia](#passo-1-instanciar-ism-multisig-para-sepolia)
- [Passo 2: Configurar IGP e ISM Routing via Governança](#passo-2-configurar-igp-e-ism-routing-via-governança)
  - [Passo 2.1: Atualizar IGP Oracle para Sepolia (Direto - Sem Governança)](#passo-21-atualizar-igp-oracle-para-sepolia-direto---sem-governança)
  - [Passo 2.2: Configurar Rota IGP Router para Sepolia (Direto - Sem Governança)](#passo-22-configurar-rota-igp-router-para-sepolia-direto---sem-governança)
- [Passo 3: Deploy Warp Route no Terra Classic](#passo-3-deploy-warp-route-no-terra-classic)
- [Passo 3.5: Scripts para Criação e Associação do IGP ao Warp Route (Sepolia)](#passo-35-scripts-para-criação-e-associação-do-igp-ao-warp-route-sepolia) 🎉 **NOVO**
- [Passo 4: Deploy Warp Route no Sepolia](#passo-4-deploy-warp-route-no-sepolia)
- [Passo 5: Link Warp Routes](#passo-5-link-warp-routes)
- [Passo 6: Testar Transferência](#passo-6-testar-transferência)
- [Verificação Final](#verificação-final)

---

## Visão Geral

Este processo configura:

1. **ISM Multisig para Sepolia**: Valida mensagens vindas de Sepolia (Domain 11155111)
   - **Contrato Deployado (Testnet)**: `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`
   - **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze` ⚠️ **IMPORTANTE**: Como você é o owner, pode alterar os validadores **diretamente (sem governança)** ou via proposta de governança
   - **Threshold Atual**: 1 de 1 validadores
   - **Validador Configurado**:
     - `0x01227B3361d200722c3656f899b48dE187A32494` (Abacus Works Validator 1)
   - **TX Configuração Atual**: `2D18C0500B12E6F0A63A8737881E9FE990D97BFDFAE3E95FB509ADFCB820E5E5`
   - **Como Alterar Validadores**:
     - **Direto (Recomendado)**: Use o script `script/configurar-validadores-ism-sepolia.ts` (execução direta, sem governança)
     - **Via Governança**: Use o script `script/submit-proposal-sepolia.ts` (requer proposta de governança)

2. **IGP Oracle**: Configura taxa de câmbio e gas price para Sepolia
   - **Contrato**: `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds`
   - **Exchange Rate**: 177534
   - **Gas Price**: 1000000000 (1 Gwei)
3. **IGP Router**: Roteia consultas de gas para o IGP Oracle correto
   - **Contrato**: `terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r`
   - **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze` (pode configurar diretamente)
   - **Rota Configurada**: Aponta para o IGP Oracle acima
3. **Warp Route Terra Classic**: Token nativo LUNC no Terra Classic
4. **Warp Route Sepolia**: Token sintético wLUNC no Sepolia
   - **Validador**: `0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0` (Threshold: 1)
   - **Token Address (Testnet)**: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
   - **Logo**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`

### Referência Rápida - Contratos Deployados (Testnet)

**ISM Multisig Sepolia**:
- **Address**: `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`
- **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze` ⚠️ **Pode alterar com ou sem governança**
- **TX Instanciação**: `E21DAF985480B3A712F50A45B35FDDD0740085013895A7244F3A29FC914F5E37`
- **TX Configuração Inicial**: `EC1FADAD3C8453C1FB7C7698948006967C36F55A200D2A55EB7CB391F3D3F12A`
- **TX Configuração Atual (Threshold 1/1)**: `2D18C0500B12E6F0A63A8737881E9FE990D97BFDFAE3E95FB509ADFCB820E5E5`
- **Threshold Atual**: 1 de 1 validadores
- **Validador Configurado**: `0x01227B3361d200722c3656f899b48dE187A32494`
- **Scripts Disponíveis**:
  - **Alteração Direta (Sem Governança)**: `script/configurar-validadores-ism-sepolia.ts`
  - **Alteração Via Governança**: `script/submit-proposal-sepolia.ts`
  - **Consulta Validadores**: `script/query-validadores-ism-sepolia.ts`

**IGP Oracle Sepolia**:
- **Address**: `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds`
- **TX Atualização**: `20F52E56B6E387F9DE48A43EEE9C35737B3228C640E5DEBAA634BEFFCAEC1627`
- **Exchange Rate**: 177534
- **Gas Price**: 1000000000 (1 Gwei)

**IGP Router Sepolia**:
- **Address**: `terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r`
- **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze` (pode configurar diretamente)
- **TX Configuração Rota**: `8228C79919C32143E2DBE293EB8C5CF05DF8009A8D6D8C44DD2D8AD41437C9A0`
- **Rota Configurada**: `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds` (IGP Oracle)

**Warp Route Sepolia**:
- **Token Address**: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
- **Etherscan**: https://sepolia.etherscan.io/token/0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

**Warp Route Terra Classic**:
- **Address**: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- **Hex (32 bytes)**: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`

**Rotas Vinculadas**:
- ✅ Terra Classic → Sepolia: Configurado
- ✅ Sepolia → Terra Classic: Configurado

### 🎉 Sepolia IGP Deployado (03/02/2026)

**StorageGasOracle (Sepolia)**:
- **Endereço**: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`
- **TX Deploy**: `0x508f6a4bfbd0e049d5dfc3f69208938118818e351e97290170979189140be347`
- **TX Config**: `0x93dc53a27c5dbccae3932619425d4328bfd0cf5f746ee8a663bf29fa4a22c5f4`
- **Owner**: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526` ✅
- **Status**: Deployado e Configurado ✅

**Configuração do Oracle para Terra Classic**:
- **Domain**: 1325 (Terra Classic)
- **Exchange Rate**: `28,444,000,000,000,000` (~$0.50/tx)
- **Gas Price**: `38,325,000,000` (38.325 uluna)
- **Status**: Configurado ✅

**Cálculo baseado em** (03/02/2026):
- LUNC: $0.00003674
- ETH: $2,292.94
- Custo alvo: ~$0.50 por transferência de 200k gas

**Etherscan Links**:
- Oracle: https://sepolia.etherscan.io/address/0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
- Warp Route: https://sepolia.etherscan.io/address/0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

**Verificar Configuração**:
```bash
# Verificar Oracle configurado para Terra Classic
cast call "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c" \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  1325 \
  --rpc-url https://1rpc.io/sepolia

# Retorna:
# 28444000000000000 [2.844e16]
# 38325000000 [3.832e10]
```

**⏳ Próximo Passo**: Deploy do IGP (InterchainGasPaymaster) e associação ao Warp Route.

Para completar o deploy do IGP, consulte: `RESUMO-DEPLOY-IGP.md` ou use Remix IDE conforme instruções.

---

## Pré-requisitos

1. **Node.js e npm/yarn instalados** (v18 ou superior)
2. **Hyperlane CLI instalado**:
   ```bash
   npm install -g @hyperlane-xyz/cli
   ```

3. **Contas com fundos**:
   - Terra Classic Testnet (LUNC)
   - Sepolia Testnet (ETH) - [Faucet](https://sepolia-faucet.pk910.de/)

4. **Chaves privadas**:
   - Terra Classic Testnet private key
   - Sepolia Testnet private key
   - **⚠️ IMPORTANTE**: **NUNCA** compartilhe suas chaves privadas reais. Os exemplos na documentação usam chaves fictícias apenas para referência de formato.

5. **Contratos Hyperlane já deployados** no Terra Classic Testnet (ver `TESTNET-ARTIFACTS.md`)

---

## Passo 1: Instanciar ISM Multisig para Sepolia

Primeiro, precisamos instanciar um novo contrato ISM Multisig específico para Sepolia. Como você é o owner, pode fazer isso diretamente via script (sem governança).

### 1.1. Instanciar via Script (Recomendado - Direto)

Use o script fornecido para instanciar o ISM Multisig e configurar os validadores automaticamente:

```bash
cd script
PRIVATE_KEY="sua_chave_privada_terra" npx tsx instantiate-ism-multisig-sepolia.ts
```

**O que o script faz**:
1. **Instancia o contrato ISM Multisig** com:
   - Code ID: 1984 (mesmo usado para BSC e Solana)
   - Nome: `hpl_ism_multisig_sepolia`
   - Owner: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` (governance module)

2. **Configura os validadores automaticamente**:
   - Domain: 11155111 (Sepolia Testnet)
   - Threshold: 2 de 3 validadores
   - Validadores (Abacus Works):
     - `b22b65f202558adf86a8bb2847b76ae1036686a5`
     - `469f0940684d147defc44f3647146cb90dd0bc8e`
     - `d3c75dcf15056012a4d74c483a0c6ea11d8c2b83`

**⚠️ IMPORTANTE**: 
- Salve o endereço do contrato retornado! Você precisará dele no Passo 2.
- Os validadores já estarão configurados, então você pode pular a mensagem de configuração de validadores na proposta de governança

**Exemplo de saída completa**:
```
INSTANTIATE ISM MULTISIG FOR SEPOLIA TESTNET
================================================================================

Wallet: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze
Chain ID: rebel-2
Node: https://rpc.luncblaze.com:443
Owner (Admin): terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze
✓ Connected to node

🔐 Instantiating ISM MULTISIG for Sepolia Testnet (Domain 11155111)
Instantiation Parameters: {
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"
}

📝 Instantiating hpl_ism_multisig_sepolia...
Code ID: 1984
Init Message: {
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"
}
✅ SUCCESS!
  • Contract Address: terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa
  • TX Hash: E21DAF985480B3A712F50A45B35FDDD0740085013895A7244F3A29FC914F5E37
  • Gas Used: 209092
  • Height: 29249714

────────────────────────────────────────────────────────────────────────────────

⚙️  Configuring validators for domain 11155111...
  • Threshold: 2
  • Validators: 3
  • Validator addresses: [
    'b22b65f202558adf86a8bb2847b76ae1036686a5',
    '469f0940684d147defc44f3647146cb90dd0bc8e',
    'd3c75dcf15056012a4d74c483a0c6ea11d8c2b83'
  ]
✅ Validators configured successfully!
  • TX Hash: EC1FADAD3C8453C1FB7C7698948006967C36F55A200D2A55EB7CB391F3D3F12A
  • Gas Used: 185930
  • Height: 29249715

================================================================================
✅ ISM MULTISIG SEPOLIA INSTANTIATED AND CONFIGURED SUCCESSFULLY!
================================================================================

📋 CONTRACT INFORMATION:
────────────────────────────────────────────────────────────────────────────────
  • Contract Address: terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa
  • Domain: 11155111 (Sepolia Testnet)
  • Threshold: 2 of 3
  • Validators configured: 3
```

**⚠️ IMPORTANTE**: Salve o endereço do contrato retornado! Você precisará dele nos próximos passos.

### 1.2. Alterar Validadores do ISM Multisig Sepolia (Após Instanciação)

**⚠️ IMPORTANTE**: Como você é o **owner** do contrato ISM Multisig Sepolia (`terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`), você pode alterar os validadores **diretamente (sem governança)** ou via proposta de governança.

#### Opção 1: Alteração Direta (Sem Governança) - Recomendado

Use o script `configurar-validadores-ism-sepolia.ts` para alterar os validadores diretamente:

```bash
PRIVATE_KEY="sua_chave_privada_terra" npx tsx script/configurar-validadores-ism-sepolia.ts
```

**Configuração Atual (2025)**:
- **Threshold**: 1 de 1 validadores
- **Validador**: `0x01227B3361d200722c3656f899b48dE187A32494`
- **TX Configuração**: `2D18C0500B12E6F0A63A8737881E9FE990D97BFDFAE3E95FB509ADFCB820E5E5`

**Para alterar**, edite o script `script/configurar-validadores-ism-sepolia.ts` e modifique:
- `SEPOLIA_THRESHOLD`: Threshold desejado
- `SEPOLIA_VALIDATORS`: Array de validadores (sem prefixo 0x)

#### Opção 2: Alteração Via Governança

Use o script `submit-proposal-sepolia.ts` para criar uma proposta de governança:

```bash
PRIVATE_KEY="sua_chave_privada_terra" \
ISM_MULTISIG_SEPOLIA="terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa" \
npx tsx script/submit-proposal-sepolia.ts
```

#### Consultar Validadores Configurados

Para verificar os validadores atualmente configurados:

```bash
npx tsx script/query-validadores-ism-sepolia.ts
```

Ou usando `terrad`:

```bash
terrad query wasm contract-state smart terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa \
  '{"multisig_ism":{"enrolled_validators":{"domain":11155111}}}' \
  --node https://rpc.luncblaze.com:443
```

### 1.2. Configurar Variável de Ambiente

Após a instanciação, configure a variável de ambiente com o endereço retornado:

```bash
export ISM_MULTISIG_SEPOLIA='terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa'
```

**⚠️ CRÍTICO**: Você DEVE ter essa variável configurada antes de executar o Passo 2 (governança).

#### Informações do Contrato Deployado (Testnet)

**Endereço do ISM Multisig Sepolia (Testnet)**:
- **Contract Address**: `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`
- **TX Hash (Instanciação)**: `E21DAF985480B3A712F50A45B35FDDD0740085013895A7244F3A29FC914F5E37`
- **TX Hash (Configuração Validadores)**: `EC1FADAD3C8453C1FB7C7698948006967C36F55A200D2A55EB7CB391F3D3F12A`
- **Gas Used (Instanciação)**: 209092
- **Gas Used (Configuração)**: 185930
- **Height (Instanciação)**: 29249714
- **Height (Configuração)**: 29249715

**Configuração dos Validadores**:
- **Domain**: 11155111 (Sepolia Testnet)
- **Threshold**: 2 de 3
- **Validadores**:
  - `b22b65f202558adf86a8bb2847b76ae1036686a5` (Abacus Works Validator 1)
  - `469f0940684d147defc44f3647146cb90dd0bc8e` (Abacus Works Validator 2)
  - `d3c75dcf15056012a4d74c483a0c6ea11d8c2b83` (Abacus Works Validator 3)

**Para outros desenvolvedores testarem**:
```bash
export ISM_MULTISIG_SEPOLIA='terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa'
```

#### Informações do Contrato Deployado (Testnet)

**Endereço do ISM Multisig Sepolia (Testnet)**:
- **Contract Address**: `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`
- **TX Hash (Instanciação)**: `E21DAF985480B3A712F50A45B35FDDD0740085013895A7244F3A29FC914F5E37`
- **TX Hash (Configuração Validadores)**: `EC1FADAD3C8453C1FB7C7698948006967C36F55A200D2A55EB7CB391F3D3F12A`
- **Gas Used (Instanciação)**: 209092
- **Gas Used (Configuração)**: 185930
- **Height (Instanciação)**: 29249714
- **Height (Configuração)**: 29249715

**Configuração dos Validadores**:
- **Domain**: 11155111 (Sepolia Testnet)
- **Threshold**: 2 de 3
- **Validadores**:
  - `b22b65f202558adf86a8bb2847b76ae1036686a5` (Abacus Works Validator 1)
  - `469f0940684d147defc44f3647146cb90dd0bc8e` (Abacus Works Validator 2)
  - `d3c75dcf15056012a4d74c483a0c6ea11d8c2b83` (Abacus Works Validator 3)

**Para outros desenvolvedores testarem**:
```bash
export ISM_MULTISIG_SEPOLIA='terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa'
```

### 1.3. Alternativa: Instanciar via Governança

Se preferir fazer via governança, você precisará criar uma proposta de instanciação separada. O processo é similar ao usado para BSC e Solana, mas usando o Code ID 1984 e o nome `hpl_ism_multisig_sepolia`.

**Exemplo de mensagem de governança para instanciação**:
```json
{
  "wasm": {
    "instantiate": {
      "admin": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "code_id": 1984,
      "label": "hpl_ism_multisig_sepolia",
      "msg": {
        "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
      },
      "funds": []
    }
  }
}
```

---

## Passo 2: Configurar IGP e ISM Routing via Governança

**⚠️ IMPORTANTE**: Se você usou o script do Passo 1.1, os validadores já estão configurados automaticamente. Você pode pular a mensagem de configuração de validadores na proposta de governança.

Use o script `submit-proposal-sepolia.ts` fornecido. Este script configura:

1. ~~Validadores ISM Multisig para Sepolia~~ ✅ **Já configurado no Passo 1.1** (pode pular esta mensagem)
2. IGP Oracle com dados de gas para Sepolia
3. Rotas IGP para Sepolia
4. Atualização do ISM Routing

### 2.1. Configurar Variável de Ambiente

**⚠️ CRÍTICO**: Antes de executar o script, você DEVE ter o endereço do ISM Multisig Sepolia:

```bash
export ISM_MULTISIG_SEPOLIA='terra1...'  # Do Passo 1.1
```

### 2.2. Executar Script

```bash
cd script
PRIVATE_KEY="sua_chave_privada_terra" ISM_MULTISIG_SEPOLIA="terra1..." npx tsx submit-proposal-sepolia.ts
```

**⚠️ NOTA**: O script criará uma proposta com a mensagem de configuração de validadores. Se os validadores já foram configurados no Passo 1.1, você pode:
- **Opção 1**: Remover a primeira mensagem do array `EXEC_MSGS` no script antes de executar
- **Opção 2**: Deixar como está (a mensagem será executada novamente, mas não causará problemas)

O script criará os arquivos:
- `exec_msgs_sepolia.json` - Mensagens de execução individuais
- `proposal_sepolia.json` - Proposta completa formatada para terrad

### 2.3. Submeter Proposta via terrad

```bash
terrad tx gov submit-proposal proposal_sepolia.json \
  --from hyperlane-val-testnet \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

**Nota**: Como você é o owner, pode aprovar a proposta diretamente com sua conta.

### 2.4. Mensagens de Governança

O script criará as seguintes mensagens:

#### Mensagem 1: Configurar Validadores ISM para Sepolia

**⚠️ NOTA**: Se você executou o script do Passo 1.1, esta mensagem **já foi executada automaticamente**. Você pode pular esta mensagem na proposta de governança ou deixá-la (não causará problemas se executada novamente).

```json
{
  "contractAddress": "<ISM_MULTISIG_SEPOLIA>",
  "msg": {
    "set_validators": {
      "domain": 11155111,
      "threshold": 2,
      "validators": [
        "b22b65f202558adf86a8bb2847b76ae1036686a5",  // Abacus Works Validator 1
        "469f0940684d147defc44f3647146cb90dd0bc8e",  // Abacus Works Validator 2
        "d3c75dcf15056012a4d74c483a0c6ea11d8c2b83"   // Abacus Works Validator 3
      ]
    }
  }
}
```

**⚠️ IMPORTANTE**: Substitua `<ISM_MULTISIG_SEPOLIA>` pelo endereço do contrato instanciado no Passo 1.1.

#### Mensagem 2: Configurar IGP Oracle para Sepolia

```json
{
  "contractAddress": "terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds",
  "msg": {
    "set_remote_gas_data_configs": {
      "configs": [
        {
          "remote_domain": 11155111,
          "token_exchange_rate": "1000000000000000000",
          "gas_price": "20000000000"
        }
      ]
    }
  }
}
```

**Valores Atuais Configurados** (Testnet):
- `token_exchange_rate`: `"177534"` (Taxa de câmbio LUNC:ETH)
- `gas_price`: `"1000000000"` (1 Gwei)

**⚠️ NOTA**: Se você atualizou o IGP Oracle via script (Passo 2.1), esta mensagem já foi executada. Você pode pular esta mensagem na proposta de governança ou deixá-la (não causará problemas se executada novamente).

#### Mensagem 3: Configurar Rotas IGP para Sepolia

**⚠️ NOTA**: Se você configurou o IGP Router via script (Passo 2.2), esta mensagem já foi executada. Você pode pular esta mensagem na proposta de governança ou deixá-la (não causará problemas se executada novamente).

**⚠️ IMPORTANTE**: O IGP Router usado no Passo 2.2 (`terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r`) é diferente do IGP Router controlado por governança (`terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9`). Se você já configurou via Passo 2.2, não precisa desta mensagem.

```json
{
  "contractAddress": "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9",
  "msg": {
    "router": {
      "set_routes": {
        "set": [
          {
            "domain": 11155111,
            "route": "terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
          }
        ]
      }
    }
  }
}
```

#### Mensagem 4: Adicionar Sepolia ao ISM Routing

```json
{
  "contractAddress": "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh",
  "msg": {
    "router": {
      "set_ism": {
        "set": {
          "domain": 11155111,
          "ism": "<ISM_MULTISIG_SEPOLIA>"
        }
      }
    }
  }
}
```

**⚠️ IMPORTANTE**: Substitua `<ISM_MULTISIG_SEPOLIA>` pelo endereço do contrato instanciado no Passo 1.1.

---

## Passo 2.1: Atualizar IGP Oracle para Sepolia (Direto - Sem Governança)

**⚠️ IMPORTANTE**: Se você é o owner do IGP Oracle, pode atualizar diretamente sem precisar de proposta de governança.

### 2.1.1. Atualizar via Script TypeScript (Recomendado)

Use o script fornecido para atualizar o IGP Oracle diretamente:

```bash
cd script
PRIVATE_KEY="sua_chave_privada_terra" npx tsx update-igp-oracle-sepolia.ts
```

**O que o script faz**:
1. Conecta à rede Terra Classic Testnet
2. Atualiza o IGP Oracle com:
   - **Domain**: 11155111 (Sepolia Testnet)
   - **Exchange Rate**: 177534
   - **Gas Price**: 1000000000 (1 Gwei)

**⚠️ IMPORTANTE**: 
- A chave privada deve corresponder à conta que é **OWNER** do IGP Oracle
- Se você receber erro "unauthorized", verifique se a conta é o owner

**Exemplo de saída bem-sucedida**:
```
================================================================================
UPDATE IGP ORACLE FOR SEPOLIA TESTNET
================================================================================

Wallet: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze
Chain ID: rebel-2
Node: https://rpc.luncblaze.com:443
IGP Oracle: terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds
Domain: 11155111 (Sepolia Testnet)

⚠️  IMPORTANTE: Esta wallet deve ser o OWNER do IGP Oracle.
   Se você receber erro "unauthorized", verifique se a conta é o owner.
   Owner padrão: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (governance)
✓ Connected to node

⚙️  Updating IGP Oracle for domain 11155111...
  • Exchange Rate: 177534
  • Gas Price: 1000000000
✅ IGP Oracle updated successfully!
  • TX Hash: 20F52E56B6E387F9DE48A43EEE9C35737B3228C640E5DEBAA634BEFFCAEC1627
  • Gas Used: 178317
  • Height: 29251168

================================================================================
✅ IGP ORACLE UPDATED SUCCESSFULLY!
================================================================================

📋 CONFIGURATION:
────────────────────────────────────────────────────────────────────────────────
  • Domain: 11155111 (Sepolia Testnet)
  • Exchange Rate: 177534
  • Gas Price: 1000000000 (1 Gwei)

📋 VERIFICATION:
────────────────────────────────────────────────────────────────────────────────
  terrad query wasm contract-state smart terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' --chain-id rebel-2 --node https://rpc.luncblaze.com:443
================================================================================
```

#### Informações do Contrato Atualizado (Testnet)

**IGP Oracle Sepolia (Testnet)**:
- **Contract Address**: `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds`
- **TX Hash (Atualização)**: `20F52E56B6E387F9DE48A43EEE9C35737B3228C640E5DEBAA634BEFFCAEC1627`
- **Gas Used**: 178317
- **Height**: 29251168

**Configuração**:
- **Domain**: 11155111 (Sepolia Testnet)
- **Exchange Rate**: 177534
- **Gas Price**: 1000000000 (1 Gwei)

### 2.1.2. Atualizar via Script Bash (terrad CLI)

Alternativamente, você pode usar o script bash com terrad:

```bash
cd script
KEY_NAME="hypelane-val-testnet" ./update-igp-oracle-sepolia.sh 177534 1000000000
```

**Parâmetros**:
- `177534`: Taxa de câmbio (exchange rate)
- `1000000000`: Gas price (1 Gwei)

**⚠️ IMPORTANTE**: 
- `KEY_NAME` deve ser o nome da chave no keyring do terrad que é owner do IGP Oracle
- O script solicitará confirmação antes de executar

### 2.1.3. Verificar Atualização

Após atualizar, verifique se a configuração foi aplicada:

```bash
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"

# Verificar dados de gas para Sepolia
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

---

## Passo 2.2: Configurar Rota IGP Router para Sepolia (Direto - Sem Governança)

**⚠️ IMPORTANTE**: O IGP Router (`terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r`) é controlado pela sua wallet (`terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`). Isso significa que você pode configurar a rota diretamente, sem precisar de proposta de governança.

**Por que isso é necessário?**
O IGP Router precisa saber qual IGP Oracle usar para calcular os custos de gas para transferências para Sepolia. Sem esta configuração, você receberá o erro: `gas oracle not found for 11155111`.

### 2.2.1. Configurar via Script TypeScript (Recomendado)

Use o script fornecido para configurar a rota IGP Router diretamente:

```bash
cd script
PRIVATE_KEY="sua_chave_privada_terra" npx tsx set-igp-route-sepolia.ts
```

**O que o script faz**:
1. Conecta à rede Terra Classic Testnet
2. Configura o IGP Router para usar o IGP Oracle quando calcular custos de gas para Sepolia:
   - **Domain**: 11155111 (Sepolia Testnet)
   - **Rota**: `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds` (IGP Oracle)

**⚠️ IMPORTANTE**: 
- A chave privada deve corresponder à conta que é **OWNER** do IGP Router (`terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`)
- Se você receber erro "unauthorized", verifique se a conta é o owner

**Exemplo de saída bem-sucedida**:
```
================================================================================
SET IGP ROUTE FOR SEPOLIA TESTNET
================================================================================

Wallet: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze
Chain ID: rebel-2
Node: https://rpc.luncblaze.com:443
IGP Router: terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r
IGP Oracle: terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds
Domain: 11155111 (Sepolia Testnet)
✓ Connected to node

⚙️  Configurando rota IGP Router para domain 11155111...
  • IGP Router: terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r
  • IGP Oracle: terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds
  • Domain: 11155111 (Sepolia Testnet)
✅ Rota IGP configurada com sucesso!
  • TX Hash: 8228C79919C32143E2DBE293EB8C5CF05DF8009A8D6D8C44DD2D8AD41437C9A0
  • Gas Used: 178278
  • Height: 29257783

================================================================================
✅ IGP ROUTE CONFIGURED SUCCESSFULLY!
================================================================================
```

### 2.2.2. Configurar via Script Bash

Alternativamente, você pode usar o script bash:

```bash
PRIVATE_KEY="sua_chave_privada_terra" SKIP_CONFIRM="1" ./script/set-igp-route-sepolia.sh
```

Ou usando keyring do terrad:

```bash
KEY_NAME="hypelane-val-testnet" ./script/set-igp-route-sepolia.sh
```

**Notas**:
- `KEY_NAME` deve ser o nome da chave no keyring do terrad que é owner do IGP Router
- O script solicitará confirmação antes de executar (a menos que `SKIP_CONFIRM="1"` seja definido)

### 2.2.3. Verificar Configuração

Após configurar, verifique se a rota foi configurada corretamente:

```bash
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"

# Verificar rota para Sepolia
terrad query wasm contract-state smart "$IGP" \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada**:
```json
{
  "data": {
    "route": {
      "domain": 11155111,
      "route": "terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
    }
  }
}
```

### 2.2.4. Verificação Completa com Script

Para verificar tanto o IGP Router quanto o IGP Oracle de uma vez:

```bash
./script/check-igp-sepolia.sh
```

**Saída esperada**:
```
✅ Rota IGP configurada: terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds
   ✓ Rota aponta para o IGP Oracle correto
✅ IGP Oracle configurado:
   • Exchange Rate: 177534
   • Gas Price: 1000000000

✅ Tudo configurado corretamente!
```

**⚠️ IMPORTANTE**: Sem esta configuração, você receberá o erro `gas oracle not found for 11155111` ao tentar transferir LUNC para Sepolia.

---

## Passo 3: Deploy Warp Route no Terra Classic

### 3.1. Criar Arquivo de Configuração

Crie o arquivo `example/warp/terraclassic-native-sepolia.json`:

```json
{
  "type": "native",
  "mode": "collateral",
  "id": "uluna",
  "owner": "<signer>",
  "config": {
    "collateral": {
      "denom": "uluna"
    }
  }
}
```

**Nota**: O owner será substituído automaticamente pelo signer do `config-testnet.yaml`.

### 3.2. Deploy no Terra Classic

```bash
yarn cw-hpl warp create ./example/warp/terraclassic-native-sepolia.json -n terraclassic
```

**Salve o endereço do contrato** retornado. Você pode também consultá-lo em:

```bash
cat context/terraclassic.json | jq '.deployments.warp.native[] | select(.id == "uluna")'
```

**Exemplo de saída**:
```json
{
  "id": "uluna",
  "address": "terra1...",
  "hexed": "000000000000000000000000..."
}
```

---

## Passo 3.5: Scripts para Criação e Associação do IGP ao Warp Route (Sepolia)

Após ter o Oracle deployado e configurado (veja seção acima), você precisa:
1. Deploy do InterchainGasPaymaster (IGP)
2. Configurar o IGP com o Oracle
3. Associar o IGP ao Warp Route

### 📋 Scripts Disponíveis

#### Opção 1: Script Bash Completo (Foundry)
```bash
cd /home/lunc/cw-hyperlane
./deploy-igp-completo.sh
```

Este script faz:
- ✅ Deploy do StorageGasOracle
- ✅ Configuração do Oracle para Terra Classic
- ✅ Deploy do InterchainGasPaymaster
- ✅ Configuração do IGP
- ✅ Associação ao Warp Route

**Variáveis de Ambiente**:
```bash
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
OWNER_ADDRESS="0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
ORACLE_ADDRESS="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
```

#### Opção 2: Usar IGP Oficial do Hyperlane (Mais Rápido)
```bash
# Associar IGP existente ao Warp Route
cast send "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "setHook(address)" \
  "0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56" \
  --private-key "0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5" \
  --rpc-url "https://1rpc.io/sepolia"
```

**⚠️ Nota**: O IGP oficial pode não estar configurado para Terra Classic. Use a Opção 3 para ter controle total.

#### Opção 3: Deploy Manual via Remix IDE (Recomendado)

**Passo a Passo Detalhado**:

1. **Acesse**: https://remix.ethereum.org

2. **Crie `SimpleIGP.sol`** com o código fornecido em `RESUMO-DEPLOY-IGP.md`

3. **Compile**: Solidity 0.8.13+, Optimization: Enabled

4. **Deploy** com MetaMask:
   - Network: Sepolia
   - Constructor:
     - `_owner`: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
     - `_beneficiary`: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`

5. **Configure o IGP** (após deploy):
   ```
   Função: setDestinationGasConfig
   Parâmetros:
   - remoteDomain: 1325
   - gasOracle: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
   - gasOverhead: 200000
   ```

6. **Associe ao Warp Route**:
   ```bash
   cast send "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
     "setHook(address)" \
     "[IGP_DEPLOYADO]" \
     --private-key "0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5" \
     --rpc-url "https://1rpc.io/sepolia"
   ```

### 🔍 Verificação Pós-Deploy

Após associar o IGP:

```bash
# Verificar hook do Warp Route
cast call "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "hook()(address)" \
  --rpc-url "https://1rpc.io/sepolia"

# Deve retornar o endereço do IGP deployado

# Verificar Oracle no IGP (se deployou seu próprio)
cast call "[IGP_ADDRESS]" \
  "gasOracles(uint32)(address)" \
  1325 \
  --rpc-url "https://1rpc.io/sepolia"

# Deve retornar: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c

# Testar quote de gas
cast call "[IGP_ADDRESS]" \
  "quoteGasPayment(uint32,uint256)(uint256)" \
  1325 200000 \
  --rpc-url "https://1rpc.io/sepolia"
```

### 📄 Documentação Completa

Para instruções detalhadas sobre cada opção, consulte:
- `RESUMO-DEPLOY-IGP.md` - Guia completo com 3 opções de deploy
- `CALCULO-EXCHANGE-RATE.md` - Explicação das fórmulas de cálculo
- `calcular-exchange-rate.py` - Script para recalcular valores

---

## Passo 4: Deploy Warp Route no Sepolia

### 4.1. Criar Arquivo de Configuração YAML

Crie o arquivo `warp-sepolia.yaml` com o seguinte comando:

```bash
cat > warp-sepolia.yaml << EOF
sepolia:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "LUNC"
  decimals: 6
  owner: "0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
    threshold: 1
EOF
```

**⚠️ IMPORTANTE**: 
- Substitua `0x133fD7F7094DBd17b576907d052a5aCBd48dB526` pelo seu endereço Sepolia (owner do contrato)
- O validador `0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0` é o validador do warp route no Sepolia (Threshold: 1)
- **Os validadores DEVEM ter o prefixo `0x`** (formato hexadecimal completo)

**Nota sobre Domain e Validadores**:
- O domain **não é especificado explicitamente** no YAML do Hyperlane CLI para EVM chains
- O Hyperlane CLI determina automaticamente o domain baseado na chain onde o warp route está sendo deployado:
  - **Sepolia**: Domain 11155111 (inferido automaticamente)
- Os validadores especificados no `interchainSecurityModule` são para validar mensagens vindas do **Terra Classic (Domain 1325)**
- Quando uma mensagem vem do Terra Classic para o warp route no Sepolia, o ISM usa esses validadores para verificar as assinaturas

**⚠️ IMPORTANTE sobre Logo**:
- **O YAML do Hyperlane CLI NÃO possui campo para logo** - o contrato ERC20 não armazena logo
- A logo deve ser configurada **após o deploy** através do formulário oficial do Etherscan (ver Passo 4.4)
- **Logo URL para usar no Etherscan**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`

### 4.2. Deploy no Sepolia

Execute o comando de deploy:

```bash
hyperlane warp deploy \
  --config warp-sepolia.yaml \
  --private-key 0xSUA_CHAVE_PRIVADA_SEPOLIA
```

**⚠️ SEGURANÇA**: Use variáveis de ambiente para a chave privada:

```bash
export SEPOLIA_PRIVATE_KEY="0x..."
hyperlane warp deploy \
  --config warp-sepolia.yaml \
  --private-key $SEPOLIA_PRIVATE_KEY
```

**⚠️ IMPORTANTE**: 
- Substitua `0x133fD7F7094DBd17b576907d052a5aCBd48dB526` pelo seu endereço Sepolia (owner do contrato)
- O validador `0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0` é o validador do warp route no Sepolia (Threshold: 1)
- **Os validadores DEVEM ter o prefixo `0x`** (formato hexadecimal completo)
- Sem o prefixo `0x`, o Hyperlane CLI retornará erro de validação regex
- O campo `logoURI` configura a logo do token que será exibida na blockchain

**Nota sobre Domain e Validadores**:
- O domain **não é especificado explicitamente** no YAML do Hyperlane CLI para EVM chains
- O Hyperlane CLI determina automaticamente o domain baseado na chain onde o warp route está sendo deployado:
  - **Sepolia**: Domain 11155111 (inferido automaticamente)
- Os validadores especificados no `interchainSecurityModule` são para validar mensagens vindas do **Terra Classic (Domain 1325)**
- Quando uma mensagem vem do Terra Classic para o warp route no Sepolia, o ISM usa esses validadores para verificar as assinaturas

**Nota sobre Logo**:
- O campo `logoURI` aponta diretamente para a URL da logo do LUNC
- A logo será armazenada no contrato do token e exibida em wallets e exploradores
- **Logo URL**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`

### 4.2. Deploy no Sepolia

Execute o comando de deploy:

```bash
hyperlane warp deploy \
  --config warp-sepolia.yaml \
  --private-key 0xSUA_CHAVE_PRIVADA_SEPOLIA
```

**⚠️ SEGURANÇA**: Use variáveis de ambiente para a chave privada:

```bash
export SEPOLIA_PRIVATE_KEY="0x..."
hyperlane warp deploy \
  --config warp-sepolia.yaml \
  --private-key $SEPOLIA_PRIVATE_KEY
```

**⚠️ IMPORTANTE**: 
- **Os validadores DEVEM ter o prefixo `0x`** no YAML
- Sem o prefixo `0x`, o Hyperlane CLI retornará erro de validação regex

### 4.3. Salvar Endereços Deployados

A saída será algo como:

```
Done adding warp route at filesystem registry
    tokens:
      - chainName: sepolia
        standard: EvmHypSynthetic
        decimals: 6
        symbol: LUNC
        name: Wrapped Terra Classic LUNC
        addressOrDenom: "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
```

**⚠️ IMPORTANTE**: Salve o endereço do contrato (`addressOrDenom`) para usar nos próximos passos.

#### Endereço do Warp Route Deployado (Sepolia Testnet)

Para outros desenvolvedores testarem, o endereço do contrato warp route deployado é:

- **Chain**: Sepolia Testnet
- **Token Address**: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
- **Token Name**: Wrapped Terra Classic LUNC
- **Token Symbol**: LUNC
- **Decimals**: 6
- **Standard**: EvmHypSynthetic
- **Etherscan**: https://sepolia.etherscan.io/address/0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

**Você pode usar este endereço para**:
- Verificar o contrato no Etherscan
- Adicionar o token em wallets (MetaMask, etc.)
- Testar transferências cross-chain
- Verificar o saldo do token

### 4.3. Salvar Endereços Deployados

A saída do deploy será algo como:

```
Done adding warp route at filesystem registry
    tokens:
      - chainName: sepolia
        standard: EvmHypSynthetic
        decimals: 6
        symbol: LUNC
        name: Wrapped Terra Classic LUNC
        addressOrDenom: "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
```

**⚠️ IMPORTANTE**: Salve o endereço do contrato (`addressOrDenom`) para usar nos próximos passos.

#### Endereço do Warp Route Deployado (Sepolia Testnet)

Para outros desenvolvedores testarem, o endereço do contrato warp route deployado é:

- **Chain**: Sepolia Testnet
- **Token Address**: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
- **Token Name**: Wrapped Terra Classic LUNC
- **Token Symbol**: LUNC
- **Decimals**: 6
- **Standard**: EvmHypSynthetic
- **Etherscan**: https://sepolia.etherscan.io/address/0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

**Você pode usar este endereço para**:
- Verificar o contrato no Etherscan
- Adicionar o token em wallets (MetaMask, etc.)
- Testar transferências cross-chain
- Verificar o saldo do token

### 4.4. Atualizar Logo do Token no Etherscan

**⚠️ IMPORTANTE**: O contrato `HypERC20` do Hyperlane **não possui métodos para armazenar ou atualizar a logo do token**. O padrão ERC20 não inclui logo no contrato - isso é gerenciado externamente.

**⚠️ IMPORTANTE**: O contrato `HypERC20` do Hyperlane **não possui métodos para armazenar ou atualizar a logo do token**. O padrão ERC20 não inclui logo no contrato - isso é gerenciado externamente.

**O YAML do Hyperlane CLI NÃO possui campo para logo** - o contrato ERC20 não armazena logo. A logo exibida no Etherscan precisa ser atualizada através do **formulário oficial do Etherscan**.

**Logo URL para usar no Etherscan**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`

#### Como Atualizar a Logo no Etherscan

**Referência oficial**: [Token Info Submission Guidelines - Etherscan](https://support.etherscan.com/support/solutions/articles/69000775720-token-info-submission-guidelines)

**Pré-requisitos** (obrigatórios):

1. **Verificar propriedade do contrato**:
   - Você precisa verificar que é o owner do contrato
   - Acesse: https://sepolia.etherscan.io/verifyContract
   - Siga o processo de verificação de propriedade do endereço do contrato

2. **Publicar o código-fonte do contrato**:
   - O código-fonte do contrato deve estar verificado e publicado no Etherscan
   - Acesse: https://sepolia.etherscan.io/verifyContract
   - Faça a verificação do código-fonte do contrato

**Processo de Atualização**:

1. **Acesse o formulário oficial do Etherscan**:
   - **⚠️ IMPORTANTE**: Use APENAS o formulário oficial do Etherscan
   - Não envie solicitações por outros canais (email, redes sociais, etc.)
   - O formulário está disponível na página do token ou através do suporte do Etherscan

2. **Preencha o formulário com as informações**:

   **Informações Básicas**:
   - **Token Address**: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
   - **Token Name**: Wrapped Terra Classic LUNC
   - **Token Symbol**: LUNC
   - **Decimals**: 6
   - **Website**: URL do projeto (se aplicável)
   - **Email oficial**: Email do domínio do projeto
   - **Descrição**: Descrição neutra do projeto (sem exageros)

   **Logo do Token**:
   - **Formato**: PNG (recomendado)
   - **Resolução**: 256x256 pixels
   - **URL da Logo**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`
   - **⚠️ IMPORTANTE**: 
     - O link para download da logo NÃO deve ser privado (sem senha)
     - Se a logo estiver protegida por senha, forneça a senha no campo "Comment/Message"
     - A URL deve ser acessível publicamente

3. **Submeta o formulário**:
   - Após preencher todas as informações, submeta o formulário
   - O Etherscan revisará sua solicitação
   - **NÃO** envie múltiplas submissões para o mesmo contrato (isso aumenta o tempo de processamento)

**Regras Importantes** (conforme Etherscan):

- ✅ **Use APENAS o formulário oficial** - solicitações por outros canais não serão atendidas
- ✅ **NÃO** entre em contato com membros da equipe pessoalmente
- ✅ **NÃO** envie múltiplas submissões para o mesmo contrato
- ✅ **NÃO** ofereça dinheiro ou incentivos para acelerar o processo
- ✅ A atualização é **gratuita**, mas há um plano pago para atualizações urgentes (24 horas)
- ✅ Cada submissão é **final** - não será possível editar após o envio
- ✅ Certifique-se de que a logo, nome e símbolo não sejam fraudulentos ou infrinjam direitos autorais

**Tempo de Processamento**:

- **Gratuito**: Processamento normal (pode levar alguns dias)
- **Pago**: Atualização urgente (24 horas) - [Mais informações](https://support.etherscan.com)

**Verificação após Submissão**:

- Após a submissão, o Etherscan revisará sua solicitação
- Se necessário, podem solicitar informações adicionais
- Se a equipe estiver demorando, responda ao email original da submissão (não envie um novo email)

**Página do Token**:
- URL: https://sepolia.etherscan.io/token/0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

**Logo URL para usar**:
```
https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg
```

#### Análise Técnica do Contrato

Após análise do contrato `HypERC20.sol` no projeto Hyperlane (`/home/lunc/hyperlane-monorepo/solidity/contracts/token/HypERC20.sol`):

- O contrato estende `ERC20Upgradeable` do OpenZeppelin
- O método `initialize()` define apenas `name` e `symbol` através de `__ERC20_init(_name, _symbol)`
- **Não existem métodos** como `setLogo()`, `setLogoURI()`, `updateLogo()` ou similares no contrato
- O padrão ERC20 não inclui logo - isso é gerenciado externamente por exploradores (Etherscan) ou Token Lists
- O YAML do Hyperlane CLI NÃO possui campo para logo - o contrato ERC20 não armazena logo

**Conclusão**: A logo deve ser atualizada manualmente no Etherscan, não através de chamadas ao contrato.

---

## Passo 5: Link Warp Routes (Terra Classic ↔ Sepolia)

Agora precisamos vincular os dois warp routes bidirecionalmente. Este passo configura as rotas para permitir transferências cross-chain em ambas as direções.

### 5.1. Usar Script Automatizado (Recomendado)

O script `link-terra-sepolia.sh` automatiza todo o processo de vinculação bidirecional, incluindo conversão de endereços e verificação.

#### 5.1.1. Modo Interativo

Execute o script sem variáveis de ambiente para modo interativo:

```bash
cd /home/lunc/cw-hyperlane
./script/link-terra-sepolia.sh
```

O script solicitará:
- **Terra Classic Warp Route**: Endereço bech32 do warp route no Terra Classic
- **Sepolia Domain**: Domain ID do Sepolia (padrão: 11155111)
- **Sepolia Warp Route**: Endereço hex (0x...) do warp route no Sepolia
- **Sepolia Private Key**: Chave privada para executar transação no Sepolia
- **Terra Classic Auth**: Escolha entre chave privada ou keyring

#### 5.1.2. Modo Não-Interativo (Variáveis de Ambiente)

**⚠️ SEGURANÇA**: As chaves privadas nos exemplos abaixo são **FICTÍCIAS** e servem apenas como referência de formato. **NUNCA** compartilhe suas chaves privadas reais.

Para execução automatizada, defina as variáveis de ambiente:

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml" \
TERRA_PRIVATE_KEY="0000000000000000000000000000000000000000000000000000000000000000" \
SEPOLIA_WARP="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
SEPOLIA_PRIVATE_KEY="0x0000000000000000000000000000000000000000000000000000000000000000" \
SEPOLIA_DOMAIN="11155111" \
SKIP_CONFIRM="1" \
./script/link-terra-sepolia.sh
```

**Variáveis de Ambiente**:
- `TERRA_WARP`: Endereço bech32 do warp route no Terra Classic
- `TERRA_PRIVATE_KEY`: Chave privada Terra Classic (hex, sem 0x) - **opcional** (pode usar `KEY_NAME` em vez disso)
  - **⚠️ Exemplo fictício**: `0000000000000000000000000000000000000000000000000000000000000000`
- `KEY_NAME`: Nome da chave no keyring do terrad (padrão: `hypelane-val-testnet`) - **opcional** (se não usar `TERRA_PRIVATE_KEY`)
- `SEPOLIA_WARP`: Endereço hex do warp route no Sepolia (com 0x)
- `SEPOLIA_PRIVATE_KEY`: Chave privada Sepolia (com 0x)
  - **⚠️ Exemplo fictício**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- `SEPOLIA_DOMAIN`: Domain ID do Sepolia (padrão: 11155111)
- `SKIP_CONFIRM`: Pular confirmação (1 = sim, vazio = não)

**⚠️ IMPORTANTE**:
- O script tenta múltiplos RPCs do Sepolia automaticamente se um falhar
- RPCs testados e funcionando: `https://1rpc.io/sepolia`, `https://sepolia.drpc.org`
- O script converte automaticamente os endereços para o formato correto (hex 32 bytes)

#### 5.1.3. O que o Script Faz

1. **Converte endereços para formato hex**:
   - Sepolia → hex 32 bytes (padded com zeros à esquerda)
   - Terra Classic → hex 32 bytes (converte bech32 para hex)

2. **Vincular Terra Classic → Sepolia**:
   - Executa `router.set_route` no contrato Terra Classic
   - Usa chave privada ou keyring conforme especificado
   - Registra o endereço Sepolia (hex) como rota para domain 11155111

3. **Vincular Sepolia → Terra Classic**:
   - Executa `enrollRemoteRouter(uint32,bytes32)` no contrato Sepolia
   - Usa chave privada Sepolia
   - Registra o endereço Terra Classic (hex) como rota para domain 1325

4. **Verifica as vinculações**:
   - Consulta Terra Classic para verificar rota → Sepolia
   - Consulta Sepolia para verificar rota → Terra Classic
   - Lista todas as rotas configuradas no Terra Classic

#### 5.1.4. Exemplo de Saída

```
======================================================================
Vincular Warp Routes: Terra Classic ↔ Sepolia
======================================================================

📝 Modo não-interativo: usando variáveis de ambiente

======================================================================
📋 Resumo da Configuração:
======================================================================
Terra Classic Warp Route: terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
Terra Classic Domain: 1325
Sepolia Warp Route: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
Sepolia Domain: 11155111
Terra Classic Auth: Private Key (64 chars)

======================================================================
🔄 Convertendo endereços para formato hex...
======================================================================
✅ Sepolia Warp Route (hex 32 bytes): 0x000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4
Convertendo Terra Classic address para hex...
✅ Terra Classic Warp Route (hex 32 bytes): 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b

======================================================================
🔗 Passo 1: Vincular Terra Classic → Sepolia
======================================================================
Executando transação no Terra Classic usando chave privada...
✅ Terra Classic → Sepolia vinculado com sucesso!
  • TX Hash: ABC123...
  • Gas Used: 123456

======================================================================
🔗 Passo 2: Vincular Sepolia → Terra Classic
======================================================================
Executando transação no Sepolia...
Tentando RPC: https://1rpc.io/sepolia
✅ Sucesso com RPC: https://1rpc.io/sepolia
✅ Sepolia → Terra Classic vinculado com sucesso!
  • TX Hash: 0xDEF456...
  • Gas Used: 21000

======================================================================
✅ Verificação das Vinculações
======================================================================
1. Verificando Terra Classic → Sepolia...
✅ Rota encontrada: 0x000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4

2. Verificando Sepolia → Terra Classic...
✅ Rota encontrada: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b

3. Listando todas as rotas no Terra Classic...
[... lista de rotas ...]

======================================================================
✅ Processo concluído!
======================================================================

📋 Resumo das Transações:
  • Terra Classic → Sepolia: ABC123...
  • Sepolia → Terra Classic: 0xDEF456...
```

### 5.2. Método Manual (Alternativo)

Se preferir executar manualmente, siga os passos abaixo:

#### 5.2.1. Link Terra Classic → Sepolia

**Converter endereço Sepolia para hex**:

```bash
# Sepolia Warp Route: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
# Converter para hex 32 bytes (sem 0x, padded)
node -e "
const addr = '0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4';
const hex = addr.replace('0x', '').toLowerCase();
const padded = hex.padStart(64, '0');
console.log(padded);
"
# Resultado: 000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4
```

**Executar transação no Terra Classic**:

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SEPOLIA_WARP_HEX="000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"
SEPOLIA_DOMAIN="11155111"

# Usando chave privada (TypeScript script)
TERRA_PRIVATE_KEY="0000000000000000000000000000000000000000000000000000000000000000" \
npx tsx script/enroll-remote-router-terra.ts

# OU usando terrad CLI
terrad tx wasm execute "$TERRA_WARP" \
  "{\"router\":{\"set_route\":{\"domain\":$SEPOLIA_DOMAIN,\"route\":\"$SEPOLIA_WARP_HEX\"}}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**⚠️ IMPORTANTE**: 
- O endereço hex **NÃO deve ter prefixo `0x`** ao enviar para o contrato Terra Classic
- O contrato espera exatamente 64 caracteres hexadecimais (32 bytes)

#### 5.2.2. Link Sepolia → Terra Classic

**Converter endereço Terra Classic para hex**:

```bash
# Terra Classic Warp Route: terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
# Converter bech32 para hex 32 bytes
node -e "
const { fromBech32 } = require('@cosmjs/encoding');
const addr = 'terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml';
const { data } = fromBech32(addr);
const hexed = Buffer.from(data).toString('hex');
const padded = hexed.padStart(64, '0');
console.log('Hex (32 bytes):', '0x' + padded);
"
# Resultado: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

**Executar transação no Sepolia**:

```bash
SEPOLIA_WARP="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
TERRA_DOMAIN="1325"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"
SEPOLIA_PRIVATE_KEY="0x0000000000000000000000000000000000000000000000000000000000000000"

# Usar cast (Foundry) para executar
cast send "$SEPOLIA_WARP" \
  "enrollRemoteRouter(uint32,bytes32)" \
  $TERRA_DOMAIN \
  $TERRA_WARP_HEX \
  --private-key "$SEPOLIA_PRIVATE_KEY" \
  --rpc-url "https://1rpc.io/sepolia" \
  --legacy \
  --gas-price 1000000000
```

**⚠️ IMPORTANTE**: 
- O endereço hex **deve ter prefixo `0x`** ao usar `cast send`
- O Sepolia RPC pode falhar - o script tenta múltiplos RPCs automaticamente

### 5.3. Verificar Vinculações

Após vincular, verifique se as rotas foram configuradas corretamente:

#### 5.3.1. Verificar Terra Classic → Sepolia

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SEPOLIA_DOMAIN="11155111"

terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"get_route":{"domain":'$SEPOLIA_DOMAIN'}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Saída esperada**:
```json
{
  "route": "000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"
}
```

#### 5.3.2. Verificar Sepolia → Terra Classic

```bash
SEPOLIA_WARP="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
TERRA_DOMAIN="1325"

cast call "$SEPOLIA_WARP" \
  "routers(uint32)(bytes32)" \
  $TERRA_DOMAIN \
  --rpc-url "https://1rpc.io/sepolia"
```

**Saída esperada**:
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

#### 5.3.3. Listar Todas as Rotas no Terra Classic

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"list_routes":{}}}' \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq '.data.routes'
```

### 5.4. Scripts Auxiliares

#### 5.4.1. `enroll-remote-router-terra.ts`

Script TypeScript para vincular rota remota no Terra Classic usando chave privada:

**⚠️ SEGURANÇA**: As chaves privadas nos exemplos abaixo são **FICTÍCIAS** e servem apenas como referência de formato.

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml" \
TERRA_PRIVATE_KEY="0000000000000000000000000000000000000000000000000000000000000000" \
SEPOLIA_DOMAIN="11155111" \
SEPOLIA_WARP_HEX="000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4" \
npx tsx script/enroll-remote-router-terra.ts
```

**Variáveis de Ambiente**:
- `TERRA_WARP`: Endereço bech32 do warp route no Terra Classic
- `TERRA_PRIVATE_KEY`: Chave privada Terra Classic (hex, sem 0x)
  - **⚠️ Exemplo fictício**: `0000000000000000000000000000000000000000000000000000000000000000`
- `SEPOLIA_DOMAIN`: Domain ID do Sepolia (padrão: 11155111)
- `SEPOLIA_WARP_HEX`: Endereço Sepolia em hex (64 chars, sem 0x)

**⚠️ IMPORTANTE**: 
- O script remove automaticamente o prefixo `0x` do `SEPOLIA_WARP_HEX` se presente
- O contrato Terra Classic espera exatamente 64 caracteres hexadecimais (sem 0x)

### 5.5. Troubleshooting

#### Erro: "Error parsing into type hpl_interface::warp::native::ExecuteMsg: unknown variant `enroll_remote_router`"

**Problema**: O método `enroll_remote_router` não existe no contrato native warp.

**Solução**: Use `router.set_route` em vez de `enroll_remote_router`:

```json
{
  "router": {
    "set_route": {
      "domain": 11155111,
      "route": "000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"
    }
  }
}
```

#### Erro: "Error parsing into type hpl_interface::warp::native::ExecuteMsg: invalid hex: 0x..."

**Problema**: O contrato Terra Classic não aceita prefixo `0x` no endereço hex.

**Solução**: Remova o prefixo `0x` antes de enviar ao contrato:

```bash
# ❌ ERRADO
SEPOLIA_WARP_HEX="0x000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"

# ✅ CORRETO
SEPOLIA_WARP_HEX="000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"
```

#### Erro: RPC Sepolia retorna 522 (Cloudflare timeout)

**Problema**: O RPC `https://rpc.sepolia.org` pode estar indisponível.

**Solução**: O script `link-terra-sepolia.sh` tenta automaticamente múltiplos RPCs:
- `https://1rpc.io/sepolia` ✅ (testado e funcionando)
- `https://sepolia.drpc.org` ✅ (testado e funcionando)
- `https://rpc.sepolia.org` (pode falhar)
- `https://rpc.ankr.com/eth_sepolia` (pode falhar)
- `https://eth-sepolia-public.unifra.io` (pode falhar)

Se todos falharem, verifique sua conexão de internet ou aguarde alguns minutos e tente novamente.

---

## Passo 6: Testar Transferência

### 6.1. Transferir LUNC Terra → Sepolia

```bash
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --amount 1000000 \
  --recipient 0xSEU_ENDERECO_SEPOLIA \
  --target-domain 11155111 \
  -n terraclassic
```

**Parâmetros**:
- `--amount 1000000`: 1 LUNC (6 decimais)
- `--recipient`: Endereço Sepolia que receberá os wLUNC
- `--target-domain 11155111`: Sepolia

### 6.2. Transferir wLUNC Sepolia → Terra

```bash
hyperlane warp transfer \
  --warp $SEPOLIA_WARP_ADDRESS \
  --amount 1000000 \
  --recipient terra1SEU_ENDERECO_TERRA \
  --destination terraclassic \
  --private-key $SEPOLIA_PRIVATE_KEY
```

---

## Verificação Final

### Verificar Rotas Configuradas

#### Terra Classic → Sepolia

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SEPOLIA_DOMAIN="11155111"

# Verificar rota para Sepolia
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"get_route":{"domain":'$SEPOLIA_DOMAIN'}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada**:
```json
{
  "route": "000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"
}
```

#### Sepolia → Terra Classic

```bash
SEPOLIA_WARP="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
TERRA_DOMAIN="1325"

# Verificar rota para Terra Classic
cast call "$SEPOLIA_WARP" \
  "routers(uint32)(bytes32)" \
  $TERRA_DOMAIN \
  --rpc-url "https://1rpc.io/sepolia"
```

**Saída esperada**:
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

#### Listar Todas as Rotas no Terra Classic

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"list_routes":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq '.data.routes'
```

### Verificar ISM Configurado

#### Terra Classic (ISM Multisig Sepolia)

**⚠️ IMPORTANTE**: O contrato ISM Multisig Sepolia (`terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`) é controlado pela sua wallet (`terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`). Isso significa que você pode alterar os validadores **diretamente (sem governança)** usando o script `script/configurar-validadores-ism-sepolia.ts` ou via proposta de governança usando `script/submit-proposal-sepolia.ts`.

**Configuração Atual (2025)**:
- **Threshold**: 1 de 1 validadores
- **Validador**: `0x01227B3361d200722c3656f899b48dE187A32494`
- **TX Configuração**: `2D18C0500B12E6F0A63A8737881E9FE990D97BFDFAE3E95FB509ADFCB820E5E5`

**Consultar validadores configurados**:

```bash
ISM_MULTISIG_SEPOLIA="terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa"

# Usando terrad
terrad query wasm contract-state smart $ISM_MULTISIG_SEPOLIA \
  '{"multisig_ism":{"enrolled_validators":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Ou usando o script TypeScript
npx tsx script/query-validadores-ism-sepolia.ts
```

**Alterar validadores**:

```bash
# Opção 1: Direto (sem governança) - Recomendado
PRIVATE_KEY="sua_chave_privada" npx tsx script/configurar-validadores-ism-sepolia.ts

# Opção 2: Via governança
PRIVATE_KEY="sua_chave_privada" \
ISM_MULTISIG_SEPOLIA="terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa" \
npx tsx script/submit-proposal-sepolia.ts
```

#### Sepolia (ISM do Warp Route)

```bash
# Verificar validadores no ISM do warp route em Sepolia
hyperlane ism multisig-message-id get-validators-and-threshold \
  --ism <ISM_ADDRESS> \
  --domain 1325
```

### Verificar IGP Configurado

```bash
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"

# Verificar dados de gas para Sepolia
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"remote_gas_data":{"remote_domain":11155111}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

---

## Resumo dos Endereços

Após completar todos os passos, você terá:

### Terra Classic (Domain 1325)

| Item | Endereço | Descrição |
|------|----------|-----------|
| ISM Multisig Sepolia | `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa` | ISM para validar mensagens de Sepolia |
| IGP Oracle (Terra) | `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds` | Oracle de gas (atualizado para Sepolia) |
| IGP Router | `terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r` | IGP Router (owner: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze) |
| IGP (Governance) | `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9` | Interchain Gas Paymaster controlado por governança |
| ISM Routing | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` | ISM Router (já existe) |
| Warp Route Terra | `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` | Warp route LUNC no Terra Classic |

### Sepolia (Domain 11155111)

| Item | Endereço | Status | Descrição |
|------|----------|--------|-----------|
| **StorageGasOracle** | `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` | ✅ Deployado | Oracle de gas para Terra Classic |
| **IGP (Oficial)** | `0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56` | ⚠️ Parcial | IGP existente (não usa Oracle deployado) |
| **IGP (Custom)** | *Pendente deploy* | ⏳ Pendente | IGP para usar Oracle deployado |
| **Warp Route** | `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` | ✅ Deployado | Warp route wLUNC no Sepolia |

**Configuração do StorageGasOracle**:
- Domain: 1325 (Terra Classic)
- Exchange Rate: `28,444,000,000,000,000`
- Gas Price: `38,325,000,000` (38.325 uluna)
- TX Deploy: `0x508f6a4bfbd0e049d5dfc3f69208938118818e351e97290170979189140be347`
- TX Config: `0x93dc53a27c5dbccae3932619425d4328bfd0cf5f746ee8a663bf29fa4a22c5f4`

**Hook do Warp Route**:
- Hook atual: `0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56` (IGP Oficial do Hyperlane)
- TX Hook: `0x47b2a34dfdb52774e1b1b35e5b46c4ff459999f75d4ef15fcd35c52350d0c247`

**⚠️ Nota**: Para usar o Oracle deployado (`0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`) com os valores personalizados, você precisa deployar um novo IGP e associá-lo ao Warp Route. Veja Passo 3.5 para instruções.

## Logo do Token

**⚠️ IMPORTANTE**: O YAML do Hyperlane CLI **NÃO possui campo para logo**. O contrato ERC20 não armazena logo no contrato.

A logo deve ser configurada **após o deploy** através do formulário oficial do Etherscan (ver **Passo 4.4**).

- **Logo URL para usar no Etherscan**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`
- **Fonte**: [classic-terra/assets](https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg)
- **Formato recomendado**: PNG, 256x256 pixels

---

## Troubleshooting

### Erro: "Route address format incorrect"

**Problema**: O endereço da rota não está no formato correto.

**Solução**: O endereço deve ser:
- 64 caracteres hexadecimais (32 bytes)
- Lowercase
- Padded com zeros à esquerda
- Sem prefixo `0x`

**Exemplo de conversão**:
```bash
# Endereço Sepolia: 0xABCDEF1234567890...
# Converter para formato de rota:
node -e "
const addr = '0xABCDEF1234567890...';
const hex = addr.replace('0x', '').toLowerCase();
const padded = hex.padStart(64, '0');
console.log(padded);
"
```

### Erro: "Domain not found in ISM Routing"

**Problema**: O domain 11155111 não está configurado no ISM Routing.

**Solução**: Certifique-se de que executou o Passo 2 e adicionou Sepolia ao ISM Routing via governança.

### Erro: "gas oracle not found for 11155111"

**Problema**: O IGP Router não tem uma rota configurada para Sepolia.

**Solução**: 
1. Execute o Passo 2.2 para configurar a rota IGP Router:
   ```bash
   PRIVATE_KEY="sua_chave_privada" npx tsx script/set-igp-route-sepolia.ts
   ```
2. Verifique a configuração:
   ```bash
   ./script/check-igp-sepolia.sh
   ```
3. Certifique-se de que o IGP Oracle está configurado (Passo 2.1)

### Erro: "Insufficient gas payment"

**Problema**: O pagamento de gas não é suficiente.

**Solução**: 
1. Verifique se o IGP Oracle está configurado corretamente para Sepolia
2. Verifique se as rotas IGP estão configuradas (Passo 2.2)
3. Ajuste o exchange rate e gas price se necessário

---

## Próximos Passos

Após configurar com sucesso:

1. **Monitorar Transferências**: Acompanhe as transferências cross-chain
2. **Ajustar Parâmetros**: Ajuste exchange rates e gas prices conforme necessário
3. **Documentar Endereços**: Mantenha um registro de todos os endereços deployados
4. **Backup de Configurações**: Faça backup dos arquivos de configuração

---

## Referências

- [Hyperlane Documentation](https://docs.hyperlane.xyz/)
- [WARP-ROUTES-TESTNET.md](./WARP-ROUTES-TESTNET.md) - Guia geral de warp routes
- [LINK-ULUNA-WARP-BSC.md](./LINK-ULUNA-WARP-BSC.md) - Exemplo de link com BSC
- [TESTNET-ARTIFACTS.md](./TESTNET-ARTIFACTS.md) - Endereços dos contratos deployados
- [GOVERNANCE-OPERATIONS-TESTNET.md](./GOVERNANCE-OPERATIONS-TESTNET.md) - Operações de governança
