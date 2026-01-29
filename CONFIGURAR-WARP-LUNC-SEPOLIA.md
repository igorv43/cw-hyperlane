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
   - **Validador Terra Classic**: `242d8a855a8c932dec51f7999ae7d1e48b10c95e` (único validador anunciado)
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

Crie o arquivo `warp-sepolia.yaml`:

```yaml
sepolia:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "0xSEU_ENDERECO_SEPOLIA_AQUI"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
    threshold: 1
```

**⚠️ IMPORTANTE**: 
- Substitua `0xSEU_ENDERECO_SEPOLIA_AQUI` pelo seu endereço Sepolia
- O validador `242d8a855a8c932dec51f7999ae7d1e48b10c95e` é o único validador anunciado do Terra Classic
- O campo `uri` aponta para o arquivo de metadata JSON com a logo do LUNC

**Nota sobre Metadata/Logo**: 
- O campo `uri` está configurado para apontar ao arquivo de metadata: `warp/sepolia/metadata.json`
- A logo do LUNC está incluída no arquivo de metadata
- **IMPORTANTE**: Faça push do arquivo `warp/sepolia/metadata.json` para o repositório GitHub antes do deploy para que a URI seja acessível

### 4.2. Deploy no Sepolia

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

### 4.3. Salvar Endereços Deployados

A saída será algo como:

```
Deployed warp route on sepolia:
  Token: 0xABCDEF1234567890...
  Router: 0x1234567890ABCDEF...
```

**Salve ambos os endereços** para usar no próximo passo.

### 4.4. Publicar Arquivo de Metadata no GitHub

Antes de fazer o deploy, você precisa publicar o arquivo de metadata no GitHub para que a URI seja acessível:

```bash
# 1. Adicionar o arquivo ao git
git add warp/sepolia/metadata.json

# 2. Fazer commit
git commit -m "Add metadata.json for Sepolia warp route with LUNC logo"

# 3. Fazer push para o repositório
git push origin main
```

**Verificar se a URI está acessível**:

```bash
# Testar se a URI está acessível
curl https://raw.githubusercontent.com/igorv43/cw-hyperlane/main/warp/sepolia/metadata.json
```

**Estrutura do arquivo de metadata** (`warp/sepolia/metadata.json`):

```json
{
  "name": "Luna Classic",
  "symbol": "wLUNC",
  "description": "Wrapped Terra Classic LUNC via Hyperlane Warp Route",
  "image": "https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg",
  "decimals": 6,
  "attributes": []
}
```

**Logo do LUNC**: A URL da logo está configurada: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`

**⚠️ IMPORTANTE**: 
- O campo `uri` no YAML aponta para: `https://raw.githubusercontent.com/igorv43/cw-hyperlane/main/warp/sepolia/metadata.json`
- Certifique-se de fazer push do arquivo antes do deploy
- A logo será exibida em wallets e exploradores que suportam token metadata
- Alguns exploradores (como Etherscan) podem exigir verificação manual do token para exibir a logo

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

A logo do LUNC está configurada no arquivo de metadata:

- **Arquivo**: `warp/sepolia/metadata.json`
- **Logo URL**: `https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg`
- **Fonte**: [classic-terra/assets](https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg)

A logo será exibida em wallets e exploradores que suportam token metadata. Certifique-se de configurar a metadata após o deploy do warp route (ver Passo 4.4).

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
