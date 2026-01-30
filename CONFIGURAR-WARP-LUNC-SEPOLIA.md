# Configurar Warp LUNC para Sepolia (Ethereum Testnet)

Este guia fornece instruções passo a passo para configurar o Warp Route do LUNC (Terra Classic) para Sepolia (Ethereum Testnet), seguindo o mesmo padrão usado para BSC Testnet.

## Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Passo 1: Instanciar ISM Multisig para Sepolia](#passo-1-instanciar-ism-multisig-para-sepolia)
- [Passo 2: Configurar Validadores ISM via Governança](#passo-2-configurar-validadores-ism-via-governança)
- [Passo 3: Deploy Warp Route no Terra Classic](#passo-3-deploy-warp-route-no-terra-classic)
- [Passo 4: Deploy Warp Route no Sepolia](#passo-4-deploy-warp-route-no-sepolia)
- [Passo 5: Link Warp Routes](#passo-5-link-warp-routes)
- [Passo 6: Testar Transferência](#passo-6-testar-transferência)
- [Verificação Final](#verificação-final)

---

## Visão Geral

Este processo configura:

1. **ISM Multisig para Sepolia**: Valida mensagens vindas de Sepolia (Domain 11155111)
   - **Threshold**: 2 de 3 validadores
   - **Validadores Sepolia**:
     - `0xb22b65f202558adf86a8bb2847b76ae1036686a5` (Abacus Works)
     - `0x469f0940684d147defc44f3647146cb90dd0bc8e` (Abacus Works)
     - `0xd3c75dcf15056012a4d74c483a0c6ea11d8c2b83` (Abacus Works)

2. **IGP Oracle**: Configura taxa de câmbio e gas price para Sepolia
3. **Warp Route Terra Classic**: Token nativo LUNC no Terra Classic
4. **Warp Route Sepolia**: Token sintético wLUNC no Sepolia
   - **Validador**: `0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0` (Threshold: 1)
   - **Logo**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`

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

5. **Contratos Hyperlane já deployados** no Terra Classic Testnet (ver `TESTNET-ARTIFACTS.md`)

---

## Passo 1: Instanciar ISM Multisig para Sepolia

Primeiro, precisamos instanciar um novo contrato ISM Multisig específico para Sepolia. Como você é o owner, pode fazer isso diretamente via script (sem governança) ou via governança.

### 1.1. Instanciar via Script (Recomendado - Direto)

Use o script fornecido para instanciar o ISM Multisig:

```bash
cd script
PRIVATE_KEY="sua_chave_privada_terra" npx tsx instantiate-ism-multisig-sepolia.ts
```

**Parâmetros de Instanciação**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Code ID**: 1984 (mesmo usado para BSC e Solana)

**⚠️ IMPORTANTE**: Salve o endereço do contrato retornado! Você precisará dele no Passo 3.

### 1.2. Configurar Variável de Ambiente

Após a instanciação, configure a variável de ambiente:

```bash
export ISM_MULTISIG_SEPOLIA='terra1...'  # Endereço retornado no Passo 1.1
```

### 1.3. Alternativa: Instanciar via Governança

Se preferir fazer via governança, você precisará criar uma proposta de instanciação separada. O processo é similar ao usado para BSC e Solana, mas usando o Code ID 1984 e o nome `hpl_ism_multisig_sepolia`.

---

## Passo 2: Configurar Validadores ISM via Governança

Use o script `submit-proposal-sepolia.ts` fornecido. Este script configura:

1. Validadores ISM Multisig para Sepolia (Domain 11155111)
2. IGP Oracle com dados de gas para Sepolia
3. Rotas IGP para Sepolia
4. Atualização do ISM Routing

### 3.1. Configurar Variável de Ambiente

**⚠️ CRÍTICO**: Antes de executar o script, você DEVE ter o endereço do ISM Multisig Sepolia:

```bash
export ISM_MULTISIG_SEPOLIA='terra1...'  # Do Passo 1.1
```

### 3.2. Executar Script

```bash
cd script
PRIVATE_KEY="sua_chave_privada_terra" ISM_MULTISIG_SEPOLIA="terra1..." npx tsx submit-proposal-sepolia.ts
```

O script criará os arquivos:
- `exec_msgs_sepolia.json` - Mensagens de execução individuais
- `proposal_sepolia.json` - Proposta completa formatada para terrad

### 3.3. Submeter Proposta via terrad

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

### 3.4. Mensagens de Governança

O script criará as seguintes mensagens:

#### Mensagem 1: Configurar Validadores ISM para Sepolia

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
  "contractAddress": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg",
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

**Valores de Referência** (ajuste conforme necessário):
- `token_exchange_rate`: Taxa de câmbio LUNC:ETH (exemplo: `"1000000000000000000"` para 1:1 em wei)
  - Ajuste baseado na taxa de câmbio real entre LUNC e ETH
- `gas_price`: Gas price em Sepolia (exemplo: `"20000000000"` para 20 Gwei)
  - Verifique o gas price atual em Sepolia e ajuste conforme necessário

#### Mensagem 3: Configurar Rotas IGP para Sepolia

```json
{
  "contractAddress": "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9",
  "msg": {
    "router": {
      "set_routes": {
        "set": [
          {
            "domain": 11155111,
            "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
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

## Passo 5: Link Warp Routes

Agora precisamos vincular os dois warp routes (Terra Classic ↔ Sepolia).

### 5.1. Link Terra Classic → Sepolia

```bash
# Defina as variáveis
TERRA_WARP_ADDRESS="terra1..."  # Do Passo 6
SEPOLIA_WARP_ADDRESS="0x..."     # Do Passo 7

# Link Terra → Sepolia
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 11155111 \
  --warp-address $SEPOLIA_WARP_ADDRESS \
  -n terraclassic
```

**Parâmetros**:
- `--asset-type native`: Token nativo (uluna)
- `--asset-id uluna`: ID do asset
- `--target-domain 11155111`: Domain ID do Sepolia
- `--warp-address`: Endereço do warp route no Sepolia
- `-n terraclassic`: Rede Terra Classic

### 5.2. Link Sepolia → Terra Classic

```bash
# Link Sepolia → Terra Classic
hyperlane warp link \
  --warp $SEPOLIA_WARP_ADDRESS \
  --destination terraclassic \
  --destination-warp $TERRA_WARP_ADDRESS \
  --private-key $SEPOLIA_PRIVATE_KEY
```

**Nota**: O Hyperlane CLI pode não reconhecer `terraclassic` como destino. Nesse caso, use o endereço hex do Terra Classic:

```bash
# Converter endereço Terra para hex (64 caracteres)
TERRA_WARP_HEX="000000000000000000000000..."  # Do context/terraclassic.json

# Link via terrad (método alternativo)
terrad tx wasm execute $TERRA_WARP_ADDRESS \
  '{"router":{"set_route":{"set":{"domain":11155111,"route":"'$SEPOLIA_WARP_HEX'"}}}}' \
  --from hyperlane-val-testnet \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  -y
```

Onde `$SEPOLIA_WARP_HEX` é o endereço Sepolia convertido para hex (64 caracteres, lowercase, sem 0x, padded).

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

#### Terra Classic

```bash
TERRA_WARP="terra1..."  # Endereço do warp route

# Verificar rota para Sepolia
terrad query wasm contract-state smart $TERRA_WARP \
  '{"router":{"route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

#### Sepolia

```bash
# Verificar rota para Terra Classic (via Hyperlane CLI)
hyperlane warp show --warp $SEPOLIA_WARP_ADDRESS
```

### Verificar ISM Configurado

#### Terra Classic (ISM Multisig Sepolia)

```bash
ISM_MULTISIG_SEPOLIA="terra1..."  # Endereço do ISM Multisig Sepolia

terrad query wasm contract-state smart $ISM_MULTISIG_SEPOLIA \
  '{"validators_and_threshold":{"domain":11155111}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
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
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

# Verificar dados de gas para Sepolia
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"remote_gas_data":{"remote_domain":11155111}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

---

## Resumo dos Endereços

Após completar todos os passos, você terá:

| Item | Endereço | Descrição |
|------|----------|-----------|
| ISM Multisig Sepolia | `terra1...` | ISM para validar mensagens de Sepolia |
| IGP Oracle | `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg` | Oracle de gas (já existe) |
| IGP | `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9` | Interchain Gas Paymaster (já existe) |
| ISM Routing | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` | ISM Router (já existe) |
| Warp Route Terra | `terra1...` | Warp route LUNC no Terra Classic |
| Warp Route Sepolia | `0x...` | Warp route wLUNC no Sepolia |

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

### Erro: "Insufficient gas payment"

**Problema**: O pagamento de gas não é suficiente.

**Solução**: 
1. Verifique se o IGP Oracle está configurado corretamente para Sepolia
2. Verifique se as rotas IGP estão configuradas
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
