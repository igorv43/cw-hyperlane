# 📘 Guia Completo: Deploy e Configuração Hyperlane na Terra Classic

Este guia documenta o processo completo de deploy e configuração dos contratos Hyperlane na Terra Classic (LUNC).

---

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Verificar Contratos Disponíveis](#verificar-contratos-disponíveis)
3. [Deploy dos Contratos (Upload)](#deploy-dos-contratos-upload)
4. [Instanciação dos Contratos](#instanciação-dos-contratos)
5. [Configuração via Governança](#configuração-via-governança)
6. [Verificação da Execução](#verificação-da-execução)
7. [Endereços e Hexed dos Contratos](#endereços-e-hexed-dos-contratos)
8. [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

### Requisitos do Sistema

- **Node.js**: v18+ ou v20+
- **Yarn**: v4.1.0+
- **Terra Classic Node**: LocalTerra ou acesso a um RPC público
- **Wallet**: Chave privada configurada

### Variáveis de Ambiente

```bash
export PRIVATE_KEY="sua_chave_privada_hexadecimal"
```

### Instalação de Dependências

```bash
cd cw-hyperlane
yarn install
```

---

## 1️⃣ Verificar Contratos Disponíveis

Antes de fazer o deploy, verifique quais contratos estão disponíveis no repositório remoto:

```bash
yarn cw-hpl upload remote-list -n terraclassic
```

**Output esperado:**
```
Listing available contracts from remote repository...
- hpl_mailbox
- hpl_validator_announce
- hpl_ism_aggregate
- hpl_ism_multisig
- hpl_ism_pausable
- hpl_ism_routing
- hpl_igp
- hpl_igp_oracle
- hpl_hook_aggregate
- hpl_hook_fee
- hpl_hook_merkle
- hpl_hook_pausable
- hpl_hook_routing
- hpl_hook_routing_custom
- hpl_hook_routing_fallback
- hpl_test_mock_hook
- hpl_test_mock_ism
- hpl_test_mock_msg_receiver
- hpl_warp_cw20
- hpl_warp_native
```

### 📦 Releases Disponíveis

Os contratos WASM compilados estão disponíveis no GitHub Releases:

- **Latest Release**: [v0.0.6-rc8](https://github.com/many-things/cw-hyperlane/releases/tag/v0.0.6-rc8)
- **Download Direto**: https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
- **Todas as Versões**: https://github.com/many-things/cw-hyperlane/releases

### Download Manual (Opcional)

Se preferir baixar manualmente:

```bash
# Baixar o release
wget https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip

# Extrair
unzip cw-hyperlane-v0.0.6-rc8.zip -d artifacts/

# Verificar checksums
cat artifacts/checksums.txt
```

> **⚠️ Segurança:**
> 
> - ✅ **Sempre baixe** dos releases oficiais do GitHub
> - ✅ **Verifique** os checksums antes de fazer upload
> - ✅ **Compare** os hashes da blockchain com os hashes oficiais
> - ❌ **Nunca use** binários WASM de fontes não confiáveis

---

## 2️⃣ Deploy dos Contratos (Upload)

### Upload para a Blockchain

Execute o comando para fazer upload de todos os contratos da versão especificada:

```bash
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic
```

**O que este comando faz:**
- 📥 **Baixa os arquivos WASM** do GitHub release:
  - URL: https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
  - Versão: `v0.0.6-rc8`
  - Contém: 20 contratos compilados (.wasm) + checksums.txt
- 📤 Faz upload para a blockchain Terra Classic
- 💾 Armazena os `code_id` de cada contrato
- 📝 Salva os IDs no arquivo de contexto (`context/terraclassic.json`)

> **📦 Conteúdo do Release:**
> O arquivo ZIP contém todos os contratos WASM compilados e um arquivo `checksums.txt` com os hashes SHA-256 para verificação de integridade.

**Output esperado:**
```
Uploading contracts to terraclassic...
✓ hpl_mailbox uploaded: code_id 1
✓ hpl_validator_announce uploaded: code_id 2
✓ hpl_ism_aggregate uploaded: code_id 3
✓ hpl_ism_multisig uploaded: code_id 4
✓ hpl_ism_pausable uploaded: code_id 5
✓ hpl_ism_routing uploaded: code_id 6
✓ hpl_igp uploaded: code_id 7
✓ hpl_hook_aggregate uploaded: code_id 8
✓ hpl_hook_fee uploaded: code_id 9
✓ hpl_hook_merkle uploaded: code_id 10
✓ hpl_hook_pausable uploaded: code_id 11
✓ hpl_hook_routing uploaded: code_id 12
✓ hpl_hook_routing_custom uploaded: code_id 13
✓ hpl_hook_routing_fallback uploaded: code_id 14
✓ hpl_test_mock_hook uploaded: code_id 15
✓ hpl_test_mock_ism uploaded: code_id 16
✓ hpl_test_mock_msg_receiver uploaded: code_id 17
✓ hpl_igp_oracle uploaded: code_id 18
✓ hpl_warp_cw20 uploaded: code_id 19
✓ hpl_warp_native uploaded: code_id 20

All contracts uploaded successfully!
```

### Hashes dos Contratos (Para Auditoria)

Durante o upload, cada contrato gera um **hash SHA-256** do arquivo WASM. Estes hashes são **cruciais para auditoria** e garantem que não houve manipulação dos binários:

| Contrato | Hash SHA-256 | Code ID (LocalTerra) | TX Hash (Exemplo Mainnet) |
|----------|--------------|----------------------|---------------------------|
| **hpl_mailbox** | `12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525` | 1 | CE57EE3112A0E763B81F6646A73F6E8558FA563C6B7AC130A629BA03F0E7D981 |
| **hpl_validator_announce** | `87cf4cbe4f5b6b3c7a278b4ae0ae980d96c04192f07aa70cc80bd7996b31c6a8` | 2 | 3423021865EFB45A7E603EC1934B671F0BF61CF693622B7D495B3F4FA9C810B8 |
| **hpl_ism_aggregate** | `fae4d22afede6578ce8b4dbfaa185d43a303b8707386a924232aa24632d00f7b` | 3 | A91910622861998F1D2758132E4D514CB9AB6A479D0E31B2F238C28E9551962D |
| **hpl_ism_multisig** | `d1f4705e19414e724d3721edad347003934775313922b7ca183ca6fa64a9e076` | 4 | 1C85143E0EBE5BC92DADE8373EF8A2D968409B255EA3E92A3BC910F0F4707221 |
| **hpl_ism_pausable** | `a6e8cc30b5abf13a032c8cb70128fcd88305eea8133fd2163299cf60298e0e7f` | 5 | D7FCD891ECBCE204F5F91B690884500C493C598D41D4FB92BB380C3168D6B529 |
| **hpl_ism_routing** | `a0b29c373cb5428ef6e8a99908e0e94b62d719c65434d133b14b4674ee937202` | 6 | 6A4FF7090F661E7E5BF04782E812145D4439953170CCA09604A5A5AA42873D69 |
| **hpl_igp** | `99e42faf05c446170167bdf0521eaaeebe33658972d056c4d0dc607d99186044` | 7 | 4068C5CE6C45DDA52F84AA171ECE66198E12C36E542B05C637FE590D3346F91B |
| **hpl_hook_aggregate** | `2ee718217253630b087594a92a6770f8d040a99b087e38deafef2e4685b23e8f` | 8 | B647037852D7D3F16F79F8081520A396904F042DCB5EBCC7488467F68BC1DBF0 |
| **hpl_hook_fee** | `8beeb594aa33ae3ce29f169ac73e2c11c80a7753a2c92518e344b86f701d50fd` | 9 | D05A0532EE4544293B5EA2F99AD0F681B0731CE321BAF832E18F020B4BD7EE2B |
| **hpl_hook_merkle** | `1de731062f05b83aaf44e4abb37f566bb02f0cd7c6ecf58d375cbce25ff53076` | 10 | A2248F5E37310B2C17C6FB9A6BC9E7466C5F3FD1D1C6A6769A8F461FF23A67BF |
| **hpl_hook_pausable** | `8ea810f57c31bd754ba21ac87cfc361f1d6cc55974eefd8ad2308b69bd63d6bf` | 11 | CF6053838160CEB4E820DCB72E9C6ECEE564975859F4BDB91367B33654125168 |
| **hpl_hook_routing** | `cbf712a3ed6881e267ad3b7a82df362c02ae9cb98b68e12c316005d928f611cf` | 12 | 9E66F5B8322F817C6307E3AC8A27B7AAB27B5112A11DAAB12DC25AAC9C1910E6 |
| **hpl_hook_routing_custom** | `f2ffb3a6444da867d7cd81726cb0362ac3cc7ba2e8eef11dcb50f96e6725d09a` | 13 | 7AB3107966F2B0D2EA9446183A175B6F53087B4B7D007FFC3BAB2FCC1668BAD3 |
| **hpl_hook_routing_fallback** | `d701bb43e1aea05ae8bdb3fcbe68b449b6e6d9448420b229a651ed9628a3d309` | 14 | 19545E011C1194AF3F262DAF85E33C16493EEFD20DE00EC718234FFDB6646677 |
| **hpl_test_mock_hook** | `15b7b62a78ce535239443228a0dc625408941182d1b09b338b55d778101e7913` | 15 | 0AAF8A18DA0CDFC79B24E58EFAC2FCD3A8410C495F69FC748494C4ADAC5BD1A0 |
| **hpl_test_mock_ism** | `a5d07479b6d246402438b6e8a5f31adaafa18c2cd769b6dc821f21428ad560ab` | 16 | E93B9A40A0662209B9B10B23DEB05D843DBFFC06DCF8E412DD65635AF1FD4DB8 |
| **hpl_test_mock_msg_receiver** | `35862c951117b77514f959692741d9cabc21ce7c463b9682965fce983140f0c1` | 17 | 60617D659BAED0D48BF952201BA081BCCEA3D0AF3F3CE3F71EDE06D1C5FB24D9 |
| **hpl_igp_oracle** | `a628d5e0e6d8df3b41c60a50aeaee58734ae21b03d443383ebe4a203f1c86609` | 18 | 6E9AF7B37F49BD4EBAA3DF68775B3C3BCFEDF6AAEEACB0DC757B424D0395DD59 |
| **hpl_warp_cw20** | `a97d87804fae105d95b916d1aee72f555dd431ece752a646627cf1ac21aa716d` | 19 | 2AE69E1B45D6CC91120E890611B40E72C16B3085C2A75825459FBEE37EA41A05 |
| **hpl_warp_native** | `5aa1b379e6524a3c2440b61c08c6012cc831403fae0c825b966ceabecfdb172b` | 20 | E7E0C847F1DF98B1A978700579EE060C1DF25F57A2791355005FD30AAE105FE6 |

#### 🔒 Verificação de Integridade

Os hashes SHA-256 acima permitem **verificar a integridade** dos contratos:

1. **Hash do WASM**: Calculado localmente antes do upload
2. **Code ID**: Identificador único na blockchain após o upload
3. **TX Hash**: Hash da transação de upload na blockchain

**Método 1: Verificar contra a blockchain**

```bash
# Baixar o WASM do code ID (exemplo: hpl_mailbox com code_id 1)
terrad query wasm code 1 download.wasm --node http://localhost:26657

# Calcular o hash SHA-256
sha256sum download.wasm

# Comparar com o hash da tabela acima
# Para hpl_mailbox deve ser: 12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525
```

**Método 2: Verificar contra o release oficial**

```bash
# Baixar o release oficial
wget https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
unzip cw-hyperlane-v0.0.6-rc8.zip

# Verificar todos os checksums
sha256sum -c checksums.txt

# Ou verificar um contrato específico
sha256sum hpl_mailbox.wasm
# Output: 12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525
```

> **✅ Arquivo checksums.txt**
> 
> O release inclui um arquivo `checksums.txt` com todos os hashes oficiais. Este arquivo é a fonte confiável para auditoria dos contratos.

> **📝 Nota sobre Code IDs:**
> - **LocalTerra**: Code IDs são sequenciais 1-20
> - **Mainnet/Testnet**: Code IDs dependem de quantos contratos já foram uploadados (ex: 10588-10607)
> - Os TX Hashes na tabela são exemplos de um deploy real no mainnet
> - Sempre verifique `context/terraclassic.json` para os code IDs corretos do seu ambiente

#### 📊 Significado dos Dados

- **Hash SHA-256**: Impressão digital única do arquivo WASM compilado
- **Code ID**: Número sequencial atribuído pela blockchain ao armazenar o código
- **TX Hash**: Identificador da transação que fez o upload
- **[NEW]**: Indica que é um novo upload (não uma atualização)
- **[SUCCESS]**: Confirma que o upload foi bem-sucedido

### Verificar Code IDs

Os `code_id` são salvos em:
```bash
cat context/terraclassic.json
```

**Exemplo de conteúdo:**
```json
{
  "artifacts": {
    "hpl_mailbox": 1,
    "hpl_validator_announce": 2,
    "hpl_ism_aggregate": 3,
    "hpl_ism_multisig": 4,
    "hpl_ism_pausable": 5,
    "hpl_ism_routing": 6,
    "hpl_igp": 7,
    "hpl_hook_aggregate": 8,
    "hpl_hook_fee": 9,
    "hpl_hook_merkle": 10,
    "hpl_hook_pausable": 11,
    "hpl_hook_routing": 12,
    "hpl_hook_routing_custom": 13,
    "hpl_hook_routing_fallback": 14,
    "hpl_test_mock_hook": 15,
    "hpl_test_mock_ism": 16,
    "hpl_test_mock_msg_receiver": 17,
    "hpl_igp_oracle": 18,
    "hpl_warp_cw20": 19,
    "hpl_warp_native": 20
  }
}
```

### Identificando o Módulo de Governança

Para verificar qual é o endereço do módulo de governança em sua rede:

```bash
# Ver informações da governança
terrad query gov params --node http://localhost:26657

# O módulo de governança geralmente tem o endereço:
# terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (Terra Classic)
```

Para verificar se um contrato está controlado pela governança:

```bash
# Verificar o admin de um contrato instanciado
terrad query wasm contract-state smart <CONTRACT_ADDRESS> \
  '{"ownable":{"owner":{}}}' \
  --node http://localhost:26657

# Se o owner for terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
# significa que apenas a governança pode alterar o contrato
```

### Verificação de Integridade dos Contratos

Para auditores e validadores, é possível verificar que os contratos na blockchain correspondem exatamente aos binários oficiais:

```bash
# 1. Baixar o WASM de um contrato específico
terrad query wasm code <CODE_ID> contract.wasm --node http://localhost:26657

# 2. Calcular o hash SHA-256
sha256sum contract.wasm

# 3. Comparar com a tabela de hashes acima
```

**Exemplo prático:**
```bash
# Verificar hpl_mailbox (code_id 1 no LocalTerra)
terrad query wasm code 1 mailbox.wasm --node http://localhost:26657
sha256sum mailbox.wasm
# Output esperado: 12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525

# Se o hash for idêntico, o contrato não foi alterado ✅
```

---

## 3️⃣ Instanciação dos Contratos

### Script: `CustomInstantiateWasm.ts`

Este script instancia todos os contratos na blockchain com suas configurações iniciais.

#### Executar Instanciação

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="sua_chave_hex" ts-node script/CustomInstantiateWasm.ts
```

#### Configuração do Script

O script está configurado com:
- **RPC**: `http://localhost:26657`
- **Chain ID**: `localterra`
- **Admin/Owner**: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` ⚠️
- **Gas Price**: `28.5uluna`

### 📋 Contratos Instanciados - Explicação Detalhada

O script instancia **11 contratos** na seguinte ordem:

---

#### 1. 📮 MAILBOX - Contrato Principal de Mensagens Cross-Chain

**Função:** O Mailbox é o contrato central que gerencia o envio e recebimento de mensagens cross-chain. Ele coordena ISMs, Hooks e mantém o nonce de mensagens.

**Parâmetros de Instanciação:**
```json
{
  "hrp": "terra",
  "domain": 1325,
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Explicação dos Parâmetros:**
- `hrp` (string): Human-readable part do endereço Bech32 - prefixo da chain (ex: "terra" para Terra Classic)
- `domain` (u32): Domain ID único da chain no protocolo Hyperlane. Terra Classic = 1325
- `owner` (string): Endereço que terá controle admin do contrato (módulo de governança)

**Code ID:** `1`

---

#### 2. 📢 VALIDATOR ANNOUNCE - Registro de Validadores

**Função:** Permite que validadores anunciem seus endpoints e localizações para que relayers possam descobrir como obter assinaturas.

**Parâmetros de Instanciação:**
```json
{
  "hrp": "terra",
  "mailbox": "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au"
}
```

**Explicação dos Parâmetros:**
- `hrp` (string): Prefixo Bech32 da chain
- `mailbox` (string): Endereço do Mailbox associado a este anunciador

**Code ID:** `2`

---

#### 3. 🔐 ISM MULTISIG - Interchain Security Module (Multisig)

**Função:** ISM que valida mensagens usando assinaturas de múltiplos validadores. Requer um threshold mínimo de assinaturas para aprovar uma mensagem.

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Endereço que pode configurar validadores e threshold (módulo de governança)

**Nota:** Validadores e threshold serão configurados posteriormente via governança.

**Code ID:** `4`

---

#### 4. 🗺️ ISM ROUTING - Roteador de ISMs

**Função:** Permite usar diferentes ISMs para diferentes domínios (chains). Útil para ter políticas de segurança customizadas por chain de origem.

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "isms": [
    {
      "domain": 1,
      "address": "terra1e7sgpxr50rlxarvjt07n0pxgxre5fcgannucx37309446x5pwacs8qhryp"
    },
    {
      "domain": 56,
      "address": "terra1m9wuxnx2vkv9duapcu9xfdnm9v5cv6eg35yzxmhgeuvch4y24aws8r49c9"
    },
    {
      "domain": 1399811149,
      "address": "terra13l8gwanf37938wgfv5yktmfzxjwaj4ysn4gl96vj78xcqqxlcrgsll77zu"
    }
  ]
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Endereço que pode adicionar/remover rotas de ISMs
- `isms` (array): Lista de mapeamentos domain → ISM
  - `domain` (u32): Domain ID da chain de origem
    - Domain 1 = Ethereum
    - Domain 56 = BSC (Binance Smart Chain)
    - Domain 1399811149 = Solana
  - `address` (string): Endereço do ISM a ser usado para mensagens deste domínio

**Nota:** Cada chain tem seu próprio ISM Multisig com validadores e threshold específicos.

**Code ID:** `6`

---

#### 5. 🌳 HOOK MERKLE - Árvore de Merkle para Provas

**Função:** Mantém uma árvore de Merkle de mensagens enviadas. Isso permite provas eficientes de inclusão de mensagens para validação na chain de destino.

**Parâmetros de Instanciação:**
```json
{
  "mailbox": "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au"
}
```

**Explicação dos Parâmetros:**
- `mailbox` (string): Endereço do Mailbox associado a este hook

**Code ID:** `10`

---

#### 6. ⛽ IGP - Interchain Gas Paymaster

**Função:** Gerencia pagamentos de gas para execução de mensagens na chain de destino. Usuários pagam gas na chain de origem, e relayers são reembolsados na chain de destino.

**Parâmetros de Instanciação:**
```json
{
  "hrp": "terra",
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "gas_token": "uluna",
  "beneficiary": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "default_gas_usage": "100000"
}
```

**Explicação dos Parâmetros:**
- `hrp` (string): Prefixo Bech32
- `owner` (string): Admin do contrato
- `gas_token` (string): Token usado para pagamento de gas (micro-luna = uluna)
- `beneficiary` (string): Endereço que recebe taxas acumuladas
- `default_gas_usage` (string): Quantidade padrão de gas estimada para execução (100000 = 100k gas units)

**Code ID:** `7`

---

#### 7. 🔮 IGP ORACLE - Oráculo de Preços de Gas

**Função:** Fornece taxas de câmbio de tokens e preços de gas para chains remotas. Essencial para calcular quanto gas cobrar na origem para cobrir custos no destino.

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Endereço que pode atualizar taxas de câmbio e preços de gas

**Nota:** Taxas de câmbio e preços de gas serão configurados via governança.

**Code ID:** `18`

---

#### 8. 🔗 HOOK AGGREGATE #1 - Agregador (Merkle + IGP)

**Função:** Combina múltiplos hooks em um. Este primeiro agregador executa:
- **Hook Merkle**: registra mensagem na árvore de Merkle
- **IGP**: processa pagamento de gas

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2",
    "terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth"
  ]
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Admin do contrato
- `hooks` (array): Lista de endereços de hooks a serem executados em sequência
  - Hook 1: Merkle Tree
  - Hook 2: IGP

**Nota:** Este hook será definido como `default_hook` no Mailbox.

**Code ID:** `8`

---

#### 9. ⏸️ HOOK PAUSABLE - Hook com Capacidade de Pausa

**Função:** Permite pausar o envio de mensagens em caso de emergência. Útil para manutenção ou resposta a incidentes de segurança.

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "paused": false
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Endereço que pode pausar/despausar
- `paused` (boolean): Estado inicial (false = não pausado, true = pausado)

**Code ID:** `11`

---

#### 10. 💰 HOOK FEE - Hook de Cobrança de Taxa Fixa

**Função:** Cobra uma taxa fixa por mensagem enviada. Pode ser usado para:
- Monetização do protocolo
- Prevenção de spam
- Funding de operações

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "fee": {
    "denom": "uluna",
    "amount": "283215"
  }
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Admin do contrato
- `fee` (object): Configuração da taxa
  - `denom` (string): Denominação do token (micro-luna = uluna)
  - `amount` (string): Quantidade de taxa (283215 uluna = 0.283215 LUNC)

**Nota:** Taxa de 0.283215 LUNC por mensagem enviada.

**Code ID:** `9`

---

#### 11. 🔗 HOOK AGGREGATE #2 - Agregador (Pausable + Fee)

**Função:** Segundo agregador que combina:
- **Hook Pausable**: permite pausar envio de mensagens
- **Hook Fee**: cobra taxa por mensagem

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt",
    "terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl"
  ]
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Admin do contrato
- `hooks` (array): Lista de hooks
  - Hook 1: Pausable
  - Hook 2: Fee

**Nota:** Este hook será definido como `required_hook` no Mailbox.

**Code ID:** `8`

---

### 🔄 Resumo da Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         MAILBOX                              │
│  (Contrato Central - Gerencia Envio/Recebimento)            │
└─────────────┬───────────────────────────────┬────────────────┘
              │                               │
    ┌─────────▼─────────┐         ┌──────────▼──────────┐
    │  Default ISM      │         │   Hooks             │
    │  (ISM Routing)    │         │                     │
    │                   │         │  Required Hook:     │
    │  Routes to:       │         │  - Pausable         │
    │  - ISM Multisig   │         │  - Fee              │
    │    (domain 56)    │         │                     │
    └───────────────────┘         │  Default Hook:      │
                                  │  - Merkle           │
                                  │  - IGP ──► Oracle   │
                                  └─────────────────────┘
```

**Fluxo de Envio:**
1. Usuário chama `dispatch()` no Mailbox
2. **Required Hook** é executado (Pausable verifica se não está pausado, Fee cobra taxa)
3. **Default Hook** é executado (Merkle registra, IGP processa pagamento via Oracle)
4. Mensagem é emitida como evento

**Fluxo de Recebimento:**
1. Relayer submete mensagem + metadata
2. Mailbox consulta **Default ISM** (ISM Routing)
3. ISM Routing direciona para **ISM Multisig** (se origem = BSC)
4. ISM Multisig valida assinaturas (2/6 threshold)
5. Se válido, mensagem é processada

> **🔒 IMPORTANTE - Módulo de Governança:**
> 
> O endereço `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` é o **módulo de governança** da blockchain.
> 
> **Implicações de Segurança:**
> - ✅ **Após a instanciação**, apenas a governança pode alterar configurações
> - ✅ **Nenhuma pessoa individual** tem controle dos contratos
> - ✅ **Todas as mudanças** devem passar por votação da comunidade
> - ✅ **Descentralização garantida** desde o primeiro momento
> - 🔐 **Contratos são imutáveis** exceto por propostas de governança aprovadas
> 
> **Como funciona:**
> 1. Contratos são instanciados com `admin` = módulo de governança
> 2. Qualquer alteração requer uma proposta de governança
> 3. A comunidade vota na proposta (sim/não)
> 4. Se aprovada, a governança executa as mudanças automaticamente
> 
> Isso garante que o protocolo seja **verdadeiramente descentralizado** e **controlado pela comunidade**.

> **⚠️ Nota Importante sobre Code IDs:**
> 
> Os Code IDs variam dependendo do ambiente:
> 
> - **LocalTerra (Desenvolvimento)**: 1-20 (sequencial desde o início da chain)
> - **Testnet Columbus**: Números variáveis (ex: 1000+)
> - **Mainnet Terra Classic**: Números altos (ex: 10588-10607) pois já existem muitos contratos
> 
> **Sempre verifique** `context/terraclassic.json` após o upload para confirmar os code IDs corretos do seu ambiente antes de instanciar os contratos!

#### Output da Execução

```bash
Wallet carregada via chave privada: terra1lmwng9g3gws5c9v0awxdankjl6a2psfhm8pc8z
Conectando ao RPC: http://localhost:26657
Taxa de gas configurada: 28.5uluna

Instanciando hpl_mailbox (code_id 1)...
{
  type: 'hpl_mailbox',
  address: 'terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au',
  hexed: 'ade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b'
}
-------------------------------------

Instanciando hpl_validator_announce (code_id 2)...
{
  type: 'hpl_validator_announce',
  address: 'terra1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrquka9l6',
  hexed: '9e28beafa966b2407bffb0d48651e94972a56e69f3c0897d9e8facbdaeb98386'
}
-------------------------------------

[... mais contratos ...]

✓ Todos os contratos instanciados com sucesso!
```

---

## 4️⃣ Configuração via Governança

### Script: `submit-proposal.ts`

Após a instanciação, os contratos precisam ser configurados. Como o **owner/admin é o módulo de governança**, todas as configurações devem ser feitas através de **propostas de governança**.

> **🔐 Por que Governança?**
> 
> Os contratos foram instanciados com o módulo de governança como admin. Isso significa:
> - ❌ **Ninguém pode** alterar os contratos diretamente
> - ✅ **Apenas propostas aprovadas** pela comunidade podem fazer mudanças
> - 🗳️ **Votação transparente** de todas as alterações
> - 🔒 **Segurança máxima** contra alterações maliciosas

### 📝 Mensagens de Execução - Explicação Detalhada

A proposta de governança executa **8 mensagens** para configurar o sistema Hyperlane com suporte a **3 chains** (Ethereum, BSC e Solana):

---

#### MENSAGEM 1: Configurar Validadores do ISM Multisig para Ethereum

**Objetivo:** Define o conjunto de validadores que irão assinar mensagens provenientes do domínio 1 (Ethereum). O threshold de 6 significa que pelo menos 6 dos 9 validadores devem assinar para que uma mensagem seja considerada válida.

**Contrato Alvo:** ISM Multisig (`terra1e7sgpxr50rlxarvjt07n0pxgxre5fcgannucx37309446x5pwacs8qhryp`)

**Mensagem Executada:**
```json
{
  "set_validators": {
    "domain": 1,
    "threshold": 6,
    "validators": [
      "03c842db86a6a3e524d4a6615390c1ea8e2b9541",
      "94438a7de38d4548ae54df5c6010c4ebc5239eae",
      "5450447aee7b544c462c9352bef7cad049b0c2dc",
      "b3ac35d3988bca8c2ffd195b1c6bee18536b317b",
      "b683b742b378632a5f73a2a5a45801b3489bba44",
      "3786083ca59dc806d894104e65a13a70c2b39276",
      "4f977a59fdc2d9e39f6d780a84d5b4add1495a36",
      "29d783efb698f9a2d3045ef4314af1f5674f52c5",
      "36a669703ad0e11a0382b098574903d2084be22c"
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `domain` (u32): Domain ID do Ethereum no protocolo Hyperlane (1 = Ethereum)
- `threshold` (u8): Número mínimo de assinaturas necessárias (6 de 9 validadores)
- `validators` (array de HexBinary): Array de 9 endereços hexadecimais (20 bytes cada) dos validadores

**Segurança:** Com threshold 6/9, o sistema tolera até 3 validadores offline ou maliciosos enquanto ainda valida mensagens.

---

#### MENSAGEM 2: Configurar Validadores do ISM Multisig para BSC

**Objetivo:** Define o conjunto de validadores que irão assinar mensagens provenientes do domínio 56 (BSC). O threshold de 2 significa que pelo menos 2 dos 6 validadores devem assinar para que uma mensagem seja considerada válida.

**Contrato Alvo:** ISM Multisig (`terra1m9wuxnx2vkv9duapcu9xfdnm9v5cv6eg35yzxmhgeuvch4y24aws8r49c9`)

**Mensagem Executada:**
```json
{
  "set_validators": {
    "domain": 56,
    "threshold": 2,
    "validators": [
      "570af9b7b36568c8877eebba6c6727aa9dab7268",
      "5450447aee7b544c462c9352bef7cad049b0c2dc",
      "0d4c1394a255568ec0ecd11795b28d1bda183ca4",
      "24c1506142b2c859aee36474e59ace09784f71e8",
      "c67789546a7a983bf06453425231ab71c119153f",
      "2d74f6edfd08261c927ddb6cb37af57ab89f0eff"
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `domain` (u32): Domain ID do BSC no protocolo Hyperlane (56 = BSC/Binance Smart Chain)
- `threshold` (u8): Número mínimo de assinaturas necessárias (2 de 6 validadores)
- `validators` (array de HexBinary): Array de 6 endereços hexadecimais (20 bytes cada) dos validadores

**Segurança:** Com threshold 2/6, o sistema tolera até 4 validadores offline enquanto ainda valida mensagens.

---

#### MENSAGEM 3: Configurar Validadores do ISM Multisig para Solana

**Objetivo:** Define o conjunto de validadores que irão assinar mensagens provenientes do domínio 1399811149 (Solana). O threshold de 3 significa que pelo menos 3 dos 5 validadores devem assinar para que uma mensagem seja considerada válida.

**Contrato Alvo:** ISM Multisig (`terra13l8gwanf37938wgfv5yktmfzxjwaj4ysn4gl96vj78xcqqxlcrgsll77zu`)

**Mensagem Executada:**
```json
{
  "set_validators": {
    "domain": 1399811149,
    "threshold": 3,
    "validators": [
      "28464752829b3ea59a497fca0bdff575c534c3ff",
      "2b7514a2f77bd86bbf093fe6bb67d8611f51c659",
      "cb6bcbd0de155072a7ff486d9d7286b0f71dcc2d",
      "4f977a59fdc2d9e39f6d780a84d5b4add1495a36",
      "5450447aee7b544c462c9352bef7cad049b0c2dc"
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `domain` (u32): Domain ID do Solana no protocolo Hyperlane (1399811149 = Solana)
- `threshold` (u8): Número mínimo de assinaturas necessárias (3 de 5 validadores)
- `validators` (array de HexBinary): Array de 5 endereços hexadecimais (20 bytes cada) dos validadores

**Segurança:** Com threshold 3/5, o sistema tolera até 2 validadores offline ou maliciosos enquanto ainda valida mensagens.

---

#### MENSAGEM 4: Configurar Dados de Gas Remoto no IGP Oracle (Todas as Chains)

**Objetivo:** Define a taxa de câmbio de tokens e o preço de gas para os domínios 1 (Ethereum), 56 (BSC) e 1399811149 (Solana). Isso permite que o IGP calcule quanto gas cobrar na chain de origem (Terra) para cobrir os custos de execução nas chains de destino.

**Contrato Alvo:** IGP Oracle (`terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz`)

**Mensagem Executada:**
```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 1,
        "token_exchange_rate": "1",
        "gas_price": "50000000"
      },
      {
        "remote_domain": 56,
        "token_exchange_rate": "1",
        "gas_price": "50000000"
      },
      {
        "remote_domain": 1399811149,
        "token_exchange_rate": "1",
        "gas_price": "50000000"
      }
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `remote_domain` (u32): Domain ID da chain remota
  - Domain 1 = Ethereum
  - Domain 56 = BSC
  - Domain 1399811149 = Solana
- `token_exchange_rate` (Uint128): Taxa de câmbio entre LUNC e token da chain de destino (1:1 neste caso, ajustável)
- `gas_price` (Uint128): Preço do gas na chain de destino (50 Gwei simplificado)

**Cálculo de Custo:**
```
Custo = (gas_usado_no_destino × gas_price × token_exchange_rate)
```

**Exemplo:** Se uma transação usa 200k gas:
```
Custo = 200000 × 50000000 × 1 = 10000000000000 units
```

**Nota:** Estes valores devem ser atualizados periodicamente para refletir preços de mercado reais de cada chain.

---

#### MENSAGEM 5: Definir Rotas do IGP para o Oracle (Todas as Chains)

**Objetivo:** Configura o IGP para usar o IGP Oracle ao calcular custos de gas para os domínios 1 (Ethereum), 56 (BSC) e 1399811149 (Solana). Estas rotas conectam o IGP ao Oracle que fornece dados atualizados de preços e taxas de câmbio.

**Contrato Alvo:** IGP (`terra1av3qg7rrtwu2anudw8u7d2ncv4f0826yxrndw9esvrp4jdnsmyjqqs62u0`)

**Mensagem Executada:**
```json
{
  "router": {
    "set_routes": {
      "set": [
        {
          "domain": 1,
          "route": "terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz"
        },
        {
          "domain": 56,
          "route": "terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz"
        },
        {
          "domain": 1399811149,
          "route": "terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz"
        }
      ]
    }
  }
}
```

**Explicação dos Parâmetros:**
- `domain` (u32): Domain ID da chain remota
  - Domain 1 = Ethereum
  - Domain 56 = BSC
  - Domain 1399811149 = Solana
- `route` (string): Endereço do IGP Oracle que fornece dados de gas (mesmo Oracle para todas as chains)

**Fluxo de Operação:**
1. IGP recebe pagamento de gas do usuário
2. IGP consulta Oracle via rota configurada para a chain de destino
3. Oracle retorna preço de gas e taxa de câmbio específicos da chain
4. IGP calcula custo total
5. IGP valida se pagamento é suficiente

---

#### MENSAGEM 6: Definir ISM Padrão no Mailbox

**Objetivo:** Configura o ISM (Interchain Security Module) padrão que será usado pelo Mailbox para validar mensagens recebidas. O ISM Routing permite usar diferentes estratégias de validação por domínio de origem.

**Contrato Alvo:** Mailbox (`terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au`)

**Mensagem Executada:**
```json
{
  "set_default_ism": {
    "ism": "terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul"
  }
}
```

**Explicação dos Parâmetros:**
- `ism` (string): Endereço do ISM Routing (que internamente roteia para ISM Multisig apropriado baseado na chain de origem)

**Fluxo de Validação:**
```
Mensagem recebida
    ↓
Mailbox consulta ISM padrão (ISM Routing)
    ↓
ISM Routing verifica origem e direciona para ISM Multisig apropriado:
    ├─► Origem = Ethereum (domain 1) → ISM Multisig ETH (6/9 threshold)
    ├─► Origem = BSC (domain 56) → ISM Multisig BSC (2/6 threshold)
    └─► Origem = Solana (domain 1399811149) → ISM Multisig SOL (3/5 threshold)
    ↓
ISM Multisig valida assinaturas conforme threshold
    ↓
Se válido: mensagem é processada
Se inválido: mensagem é rejeitada
```

**Segurança:** O ISM Routing permite políticas de segurança diferentes para cada chain, aumentando a flexibilidade sem comprometer a segurança.

---

#### MENSAGEM 7: Definir Hook Padrão no Mailbox

**Objetivo:** Configura o Hook padrão que será executado ao enviar mensagens. O Hook Aggregate #1 combina Merkle Tree Hook (para provas) e IGP (para pagamento).

**Contrato Alvo:** Mailbox (`terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au`)

**Mensagem Executada:**
```json
{
  "set_default_hook": {
    "hook": "terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z"
  }
}
```

**Explicação dos Parâmetros:**
- `hook` (string): Endereço do Hook Aggregate #1 (Merkle + IGP)

**Componentes do Hook Padrão:**
1. **Hook Merkle**: Adiciona mensagem à árvore de Merkle para provas de inclusão
2. **IGP Hook**: Processa pagamento de gas para execução na chain de destino

**Fluxo de Envio:**
```
dispatch() chamado
    ↓
Hook padrão executado
    ↓
Hook Merkle: registra mensagem na árvore
    ↓
IGP: valida e processa pagamento de gas
    ↓
Mensagem emitida como evento
```

**Benefícios:**
- **Merkle**: Permite provas criptográficas de que a mensagem foi enviada
- **IGP**: Garante que relayers serão pagos para executar a mensagem

---

#### MENSAGEM 8: Definir Hook Requerido no Mailbox

**Objetivo:** Configura o Hook obrigatório que SEMPRE será executado ao enviar mensagens, independentemente de hooks customizados especificados pelo remetente. O Hook Aggregate #2 combina Hook Pausable (emergência) e Hook Fee (monetização).

**Contrato Alvo:** Mailbox (`terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au`)

**Mensagem Executada:**
```json
{
  "set_required_hook": {
    "hook": "terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq"
  }
}
```

**Explicação dos Parâmetros:**
- `hook` (string): Endereço do Hook Aggregate #2 (Pausable + Fee)

**Componentes do Hook Requerido:**
1. **Hook Pausable**: Permite pausar envio de mensagens em caso de emergência/manutenção
2. **Hook Fee**: Cobra taxa fixa de 0.283215 LUNC por mensagem (anti-spam/monetização)

**Fluxo de Envio (ordem completa):**
```
dispatch() chamado
    ↓
Hook requerido executado (NÃO pode ser ignorado)
    ├─► Pausable: verifica se sistema não está pausado
    └─► Fee: cobra 0.283215 LUNC
    ↓
Hook padrão executado
    ├─► Merkle: registra na árvore
    └─► IGP: processa pagamento de gas
    ↓
Mensagem enviada
```

**IMPORTANTE:** 
- Hook requerido é executado **ANTES** do hook padrão
- Hook requerido **NÃO pode ser ignorado** pelo remetente
- Se o sistema estiver pausado, TODAS as mensagens são bloqueadas
- A taxa é cobrada para TODAS as mensagens sem exceção

---

### 📊 Resumo da Configuração

Após a execução desta proposta, o sistema Hyperlane estará configurado para:

| Componente | Configuração | Benefício |
|------------|--------------|-----------|
| **🔐 Segurança** | Validar mensagens usando multisig:<br>- Ethereum: 6/9 validators<br>- BSC: 2/6 validators<br>- Solana: 3/5 validators | Resistência a falhas e ataques multi-chain |
| **⛽ Pagamento** | Calcular custos via IGP + Oracle (3 chains) | Relayers são compensados adequadamente |
| **🌳 Provas** | Manter árvore de Merkle | Provas criptográficas de envio |
| **⏸️ Controle** | Pausa de emergência via Hook Pausable | Resposta rápida a incidentes |
| **💰 Monetização** | Taxa de 0.283215 LUNC via Hook Fee | Prevenção de spam + funding |

**Status Final:**
- ✅ Sistema pronto para enviar/receber mensagens Terra ↔ Ethereum
- ✅ Sistema pronto para enviar/receber mensagens Terra ↔ BSC
- ✅ Sistema pronto para enviar/receber mensagens Terra ↔ Solana
- ✅ Validação de segurança configurada (multisig por chain)
- ✅ Pagamento de gas configurado para todas as chains (Oracle + IGP)
- ✅ Proteções ativadas (Pausable + Fee)

---

### 🏗️ Arquitetura Final do Sistema

Após a configuração completa, o sistema Hyperlane terá a seguinte arquitetura:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           MAILBOX (Core)                                  │
│          terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au│
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Default ISM: ISM Routing                                                │
│    ├─► Domain 1 (Ethereum) → ISM Multisig (6/9 validators)              │
│    ├─► Domain 56 (BSC) → ISM Multisig (2/6 validators)                  │
│    └─► Domain 1399811149 (Solana) → ISM Multisig (3/5 validators)       │
│                                                                           │
│  Default Hook: Hook Aggregate #1                                         │
│    ├─► Hook Merkle (provas de inclusão)                                 │
│    └─► IGP (pagamento) → Oracle (preços Ethereum/BSC/Solana)            │
│                                                                           │
│  Required Hook: Hook Aggregate #2                                        │
│    ├─► Hook Pausable (controle de emergência)                           │
│    └─► Hook Fee (0.283215 LUNC por mensagem)                            │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

**Fluxo Completo de Envio de Mensagem (Terra → BSC):**

```
1. Usuário chama dispatch(dest=56, recipient, body)
         ↓
2. Required Hook (OBRIGATÓRIO)
   ├─► Pausable: verifica se não está pausado ✓
   └─► Fee: cobra 0.283215 LUNC ✓
         ↓
3. Default Hook (PADRÃO)
   ├─► Merkle: adiciona msg à árvore ✓
   └─► IGP: valida pagamento de gas ✓
       └─► Oracle: consulta preço BSC ✓
         ↓
4. Mailbox emite evento MessageDispatched
         ↓
5. Relayer detecta evento
         ↓
6. Relayer submete mensagem no BSC
```

**Fluxo Completo de Recebimento de Mensagem (BSC → Terra):**

```
1. Relayer submete process(message, metadata)
         ↓
2. Mailbox extrai origin_domain = 56
         ↓
3. Mailbox consulta Default ISM (ISM Routing)
         ↓
4. ISM Routing direciona para ISM Multisig
         ↓
5. ISM Multisig valida metadata (assinaturas)
   ├─► Verifica se há 2+ assinaturas válidas
   ├─► Verifica se assinaturas são de validadores cadastrados
   └─► Retorna valid=true ou valid=false
         ↓
6. Se valid=true:
   └─► Mailbox chama handle() no contrato destinatário
         ↓
7. Mensagem processada ✓
```

**Pontos Críticos de Segurança:**

| Camada | Proteção | Como Funciona |
|--------|----------|---------------|
| **Hook Pausable** | Pausa de emergência | Governança pode pausar envios instantaneamente |
| **Hook Fee** | Anti-spam | Taxa de 0.283215 LUNC torna ataques caros |
| **ISM Multisig** | Validação distribuída | 2/6 validadores = sem ponto único de falha |
| **IGP Oracle** | Preços atualizados | Evita subsídio involuntário de gas |
| **Merkle Tree** | Provas verificáveis | Impossível falsificar histórico de envios |
| **Governança** | Controle descentralizado | Nenhuma entidade pode alterar sozinha |

---

### Modo 1: Criar Proposta de Governança

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="sua_chave_hex" ts-node script/submit-proposal.ts
```

**Output:**
- Gera `proposal.json` e `exec_msgs.json`
- Mostra o comando para submeter via CLI
- Exibe todas as 6 mensagens com detalhes completos em JSON

### Modo 2: Execução Direta (sem governança)

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="sua_chave_hex" MODE=direct ts-node script/submit-proposal.ts
```

Executa as configurações diretamente da sua carteira.

> **⚠️ ATENÇÃO:**
> 
> O **Modo Direto** só funciona se você for o owner dos contratos. Como os contratos foram instanciados com o **módulo de governança** como owner, este modo **NÃO funcionará** em produção.
> 
> **Use o Modo Direto apenas para:**
> - 🧪 Testes em ambiente de desenvolvimento
> - 🔧 Contratos instanciados com sua carteira como owner
> - 📝 Validação de configurações antes de criar proposta
> 
> **Em produção, SEMPRE use o Modo Governança** (Modo 1).

---

### Submeter Proposta via CLI

Após gerar o `proposal.json`, submeta a proposta:

```bash
terrad tx gov submit-proposal proposal.json \
  --from teste01 \
  --chain-id localterra \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node http://localhost:26657 \
  -y
```

### Votar na Proposta

```bash
terrad tx gov vote 1 yes \
  --from teste01 \
  --chain-id localterra \
  --gas-prices 28.5uluna \
  --gas auto \
  --gas-adjustment 2.0 \
  --node http://localhost:26657 \
  -y
```

### Verificar Status da Proposta

```bash
# Ver status
terrad query gov proposal 1 --node http://localhost:26657 | grep "status"

# Ver votos
terrad query gov tally 1 --node http://localhost:26657

# Ver detalhes completos
terrad query gov proposal 1 --node http://localhost:26657
```

**Status possíveis:**
- `PROPOSAL_STATUS_VOTING_PERIOD` - Em votação ⏳
- `PROPOSAL_STATUS_PASSED` - Aprovada ✅
- `PROPOSAL_STATUS_REJECTED` - Rejeitada ❌
- `PROPOSAL_STATUS_FAILED` - Falhou na execução ⚠️

---

## 5️⃣ Verificação da Execução

### Queries para Verificar Configurações

Após a proposta ser aprovada (`PROPOSAL_STATUS_PASSED`), verifique se as configurações foram aplicadas.

> **📋 Sobre as Queries**
> 
> Cada query abaixo verifica uma configuração específica aplicada pela proposta de governança. É **essencial** executar todas as 6 queries para confirmar que o sistema está corretamente configurado antes de usar em produção.

---

#### 1. ✅ ISM Multisig - Validadores Configurados

**O que verifica:** Confirma que os 6 validadores foram registrados no ISM Multisig para o domínio 56 (BSC) com threshold de 2 assinaturas.

**Query:**
```bash
terrad query wasm contract-state smart terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp \
  '{"multisig_ism":{"enrolled_validators":{"domain":56}}}' \
  --node http://localhost:26657
```

**Esperado:**
```yaml
data:
  threshold: 2                              # Mínimo de 2 assinaturas necessárias
  validators:                               # Lista de 6 validadores (endereços hex 20 bytes)
  - 570af9b7b36568c8877eebba6c6727aa9dab7268  # Validador 1
  - 5450447aee7b544c462c9352bef7cad049b0c2dc  # Validador 2
  - 0d4c1394a255568ec0ecd11795b28d1bda183ca4  # Validador 3
  - 24c1506142b2c859aee36474e59ace09784f71e8  # Validador 4
  - c67789546a7a983bf06453425231ab71c119153f  # Validador 5
  - 2d74f6edfd08261c927ddb6cb37af57ab89f0eff  # Validador 6
```

**Explicação dos Campos:**
- `threshold`: Número mínimo de validadores que devem assinar para validar uma mensagem (2 de 6)
- `validators`: Array de endereços hexadecimais dos validadores autorizados (cada um com 20 bytes)

**Segurança:** Sistema tolera até 4 validadores offline/maliciosos. É necessário comprometer 5+ validadores para atacar.

---

#### 2. ✅ IGP Oracle - Gas Price Configurado

**O que verifica:** Confirma que o Oracle tem dados de preço de gas e taxa de câmbio configurados para o BSC (domain 56).

**Query:**
```bash
terrad query wasm contract-state smart terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":56}}}' \
  --node http://localhost:26657
```

**Esperado:**
```yaml
data:
  gas_price: "50000000"       # Preço do gas no BSC (50 Gwei simplificado)
  exchange_rate: "1"          # Taxa de câmbio LUNC:BNB (1:1)
```

**Explicação dos Campos:**
- `gas_price` (Uint128): Preço do gas na chain de destino (BSC) em unidades nativas
  - Valor `50000000` representa aproximadamente 50 Gwei no BSC
  - Este valor deve ser atualizado periodicamente para refletir preços reais
- `exchange_rate` (Uint128): Taxa de conversão entre token local (LUNC) e token remoto (BNB)
  - Valor `1` significa paridade 1:1 (1 LUNC = 1 BNB em valor)
  - Na prática, deve refletir taxas de mercado reais

**Cálculo de Custo:**
```
Custo em LUNC = (gas_units × gas_price × exchange_rate)

Exemplo: Transação que usa 200k gas no BSC
Custo = 200000 × 50000000 × 1 = 10,000,000,000,000 unidades
```

**Importante:** Estes valores devem ser atualizados via governança conforme preços de mercado mudam.

---

#### 3. ✅ IGP - Rota Configurada

**O que verifica:** Confirma que o IGP sabe qual Oracle consultar para obter dados de gas do domínio 56 (BSC).

**Query:**
```bash
terrad query wasm contract-state smart terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth \
  '{"router":{"get_route":{"domain":56}}}' \
  --node http://localhost:26657
```

**Esperado:**
```yaml
data:
  route: terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz  # Endereço do IGP Oracle
```

**Explicação dos Campos:**
- `route` (string): Endereço do contrato Oracle que fornece dados de gas para o domain especificado
  - Este endereço deve corresponder ao IGP Oracle instanciado
  - O IGP consultará este contrato ao processar pagamentos para mensagens destinadas ao BSC

**Fluxo de Operação:**
```
1. Usuário envia mensagem para BSC com pagamento
2. IGP recebe pagamento
3. IGP consulta route (Oracle) para domain 56
4. Oracle retorna: gas_price + exchange_rate
5. IGP calcula: custo_necessario = gas × gas_price × exchange_rate
6. IGP valida: pagamento_recebido >= custo_necessario
7. Se válido: aprova envio da mensagem
```

**Importante:** Se a rota não estiver configurada, o IGP não conseguirá calcular custos para o BSC.

---

#### 4. ✅ Mailbox - ISM Padrão

**O que verifica:** Confirma que o Mailbox tem um ISM configurado para validar mensagens recebidas.

**Query:**
```bash
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_ism":{}}}' \
  --node http://localhost:26657
```

**Esperado:**
```yaml
data:
  default_ism: terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul  # Endereço do ISM Routing
```

**Explicação dos Campos:**
- `default_ism` (string): Endereço do contrato ISM que será usado para validar mensagens recebidas
  - Este endereço deve corresponder ao ISM Routing instanciado
  - O ISM Routing internamente roteia para ISM Multisig quando a origem é BSC (domain 56)

**Fluxo de Validação:**
```
1. Relayer submete mensagem recebida de BSC
2. Mailbox extrai origin_domain = 56
3. Mailbox chama default_ism.verify(message, metadata)
4. ISM Routing verifica que origin = 56
5. ISM Routing delega para ISM Multisig
6. ISM Multisig valida 2+ assinaturas dos 6 validadores
7. Retorna valid=true ou valid=false
8. Se valid=true: Mailbox processa mensagem
   Se valid=false: Mailbox rejeita mensagem
```

**Segurança:** O ISM é a camada crítica de segurança. Sem ele, qualquer mensagem seria aceita sem validação.

---

#### 5. ✅ Mailbox - Hook Padrão

**O que verifica:** Confirma que o Mailbox tem um Hook configurado para processar envios de mensagens.

**Query:**
```bash
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_hook":{}}}' \
  --node http://localhost:26657
```

**Esperado:**
```yaml
data:
  default_hook: terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z  # Endereço do Hook Aggregate #1
```

**Explicação dos Campos:**
- `default_hook` (string): Endereço do Hook Aggregate #1 (Merkle + IGP)
  - Este hook é executado automaticamente ao enviar mensagens (se o usuário não especificar outro)
  - Combina dois hooks: Merkle Tree (para provas) e IGP (para pagamento)

**Componentes do Hook:**
1. **Merkle Hook** (`terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2`):
   - Adiciona o hash da mensagem à árvore de Merkle
   - Permite criar provas criptográficas de que a mensagem foi enviada
   - Essencial para validação na chain de destino

2. **IGP Hook** (`terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth`):
   - Valida que o usuário pagou gas suficiente
   - Consulta Oracle para calcular custo
   - Registra pagamento para reembolso ao relayer

**Fluxo de Execução:**
```
dispatch() chamado
    ↓
default_hook.post_dispatch() executado
    ├─► Merkle: add_to_tree(message_id)
    └─► IGP: validate_payment(dest_domain, gas_amount)
        └─► Oracle: get_gas_price(domain=56)
    ↓
Se tudo válido: mensagem emitida como evento
```

**Importante:** Sem o default_hook, mensagens não teriam provas verificáveis nem pagamento de gas.

---

#### 6. ✅ Mailbox - Hook Requerido

**O que verifica:** Confirma que o Mailbox tem um Hook obrigatório que SEMPRE será executado ao enviar mensagens.

**Query:**
```bash
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"required_hook":{}}}' \
  --node http://localhost:26657
```

**Esperado:**
```yaml
data:
  required_hook: terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq  # Endereço do Hook Aggregate #2
```

**Explicação dos Campos:**
- `required_hook` (string): Endereço do Hook Aggregate #2 (Pausable + Fee)
  - Este hook é **SEMPRE** executado, independentemente de preferências do usuário
  - Combina dois hooks críticos: Pausable (emergência) e Fee (anti-spam)
  - Executado **ANTES** do default_hook

**Componentes do Hook:**
1. **Pausable Hook** (`terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt`):
   - Permite pausar todo o sistema em caso de emergência
   - Controlado pela governança
   - Se pausado, TODAS as mensagens são bloqueadas instantaneamente

2. **Fee Hook** (`terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl`):
   - Cobra taxa fixa de **0.283215 LUNC** por mensagem
   - Previne spam (torna ataques caros)
   - Gera receita para manutenção do protocolo

**Ordem de Execução Completa:**
```
dispatch() chamado pelo usuário
    ↓
1️⃣ REQUIRED HOOK (NÃO pode ser ignorado)
   ├─► Pausable: is_paused()? Se sim, REVERT
   └─► Fee: transfer(0.283215 LUNC) de sender para beneficiary
    ↓
2️⃣ DEFAULT HOOK (ou hook customizado do usuário)
   ├─► Merkle: add_to_tree()
   └─► IGP: validate_payment()
    ↓
3️⃣ Mailbox emite MessageDispatched event
```

**Diferença Critical:**
- **Required Hook**: SEMPRE executado, NÃO pode ser substituído
- **Default Hook**: Executado por padrão, MAS pode ser substituído pelo usuário

**Segurança:**
- **Pausable**: Permite resposta imediata a vulnerabilidades detectadas
- **Fee**: Torna ataques de spam economicamente inviáveis (cada msg = 0.283215 LUNC)

**Importante:** O required_hook é a última linha de defesa do protocolo. Mesmo que outros hooks falhem, este sempre é executado.

---

### 📊 Tabela Resumo das Verificações

| # | Componente | Endereço | O que Verifica | Status Esperado |
|---|------------|----------|----------------|-----------------|
| 1 | **ISM Multisig** | `terra1zwv6...` | 6 validadores + threshold 2 | ✅ 2/6 configurado |
| 2 | **IGP Oracle** | `terra1lnye...` | Preço gas BSC + taxa câmbio | ✅ 50M + rate 1 |
| 3 | **IGP** | `terra1wn62...` | Rota para Oracle (domain 56) | ✅ Rota configurada |
| 4 | **Mailbox ISM** | `terra14hj...` | ISM Routing como padrão | ✅ ISM Routing set |
| 5 | **Mailbox Hook Default** | `terra14hj...` | Hook Agg #1 (Merkle+IGP) | ✅ Hooks configurados |
| 6 | **Mailbox Hook Required** | `terra14hj...` | Hook Agg #2 (Pause+Fee) | ✅ 0.283215 LUNC |

**Interpretação dos Resultados:**

| Se a Query Retorna... | Significa... | Ação Necessária |
|-----------------------|--------------|-----------------|
| ✅ **Valores esperados** | Configuração aplicada corretamente | Nenhuma - sistema pronto |
| ❌ **Valores diferentes** | Proposta não executou corretamente | Investigar logs da proposta |
| ⚠️ **Erro "not found"** | Configuração não foi aplicada | Verificar status da proposta |
| 🔄 **"null" ou vazio** | Campo não inicializado | Reexecutar proposta |

---

### Script de Verificação Completo

Salve este script como `verify-deployment.sh`:

```bash
#!/bin/bash

echo "=========================================="
echo "  VERIFICAÇÃO DO DEPLOYMENT HYPERLANE"
echo "=========================================="
echo ""

echo "✅ 1. ISM Multisig - Validadores (domain 56):"
terrad query wasm contract-state smart terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp \
  '{"multisig_ism":{"enrolled_validators":{"domain":56}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 2. IGP Oracle - Gas Price (domain 56):"
terrad query wasm contract-state smart terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":56}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 3. IGP - Rota (domain 56):"
terrad query wasm contract-state smart terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth \
  '{"router":{"get_route":{"domain":56}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 4. Mailbox - ISM Padrão:"
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_ism":{}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 5. Mailbox - Hook Padrão:"
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_hook":{}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 6. Mailbox - Hook Requerido:"
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"required_hook":{}}}' \
  --node http://localhost:26657
echo ""

echo "=========================================="
echo "  ✅ Verificação Completa!"
echo "=========================================="
```

Execute:
```bash
chmod +x verify-deployment.sh
./verify-deployment.sh
```

---

## 6️⃣ Endereços e Hexed dos Contratos

### Tabela de Endereços

| Contrato | Endereço (Bech32) | Hexed (32 bytes) |
|----------|-------------------|------------------|
| **Mailbox** | `terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au` | `ade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b` |
| **Validator Announce** | `terra1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrquka9l6` | `9e28beafa966b2407bffb0d48651e94972a56e69f3c0897d9e8facbdaeb98386` |
| **ISM Multisig** | `terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp` | `1399a4e782b935d2bb36b97586d3df8747b07dc66902d807eed0ae99e00ed256` |
| **ISM Routing** | `terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul` | `aeb534c45c3049d380b9d9b966f9895f53abd4301bfaff407fa09dea8ae7a924` |
| **Hook Merkle** | `terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2` | `17dcdb32a51ee1c43c3377349dba7f56bdf48e3586f69264656b3b60ceca2bae` |
| **IGP** | `terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth` | `74f4aa42b2c6d967c041f9e83953a2b271a8708c4fa80d306d6c312686eb664f` |
| **IGP Oracle** | `terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz` | `fcc99c4f002f6c4b1e76783e10a060d10d658f47a9e3db8c93ad3c62f4355915` |
| **Hook Aggregate 1** | `terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z` | `6239c3644abd336fad322a24dd2930a5aa3fa844a5d239e3b02584e79c791053` |
| **Hook Pausable** | `terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt` | `454df0808a2ee8f9509a28f28e773151d78290f1fd5452852a76e5379b020525` |
| **Hook Fee** | `terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl` | `46ad7597148564e9d7b64c97116e09bd66c4732eee512cf5811452f01784f8c1` |
| **Hook Aggregate 2** | `terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq` | `06ecf6795483514ce39a326f40ade963e6910e0be8f9956fbcdc613159421ae8` |

### JSON Completo

```json
{
  "hpl_mailbox": "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au",
  "hpl_validator_announce": "terra1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrquka9l6",
  "hpl_ism_multisig": "terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp",
  "hpl_ism_routing": "terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul",
  "hpl_hook_merkle": "terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2",
  "hpl_igp": "terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth",
  "hpl_igp_oracle": "terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz",
  "hpl_hook_aggregate": "terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq",
  "hpl_hook_pausable": "terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt",
  "hpl_hook_fee": "terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl"
}
```

### Uso dos Endereços

**Para Relayer:**
```yaml
mailbox: "0xade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b"
validatorAnnounce: "0x9e28beafa966b2407bffb0d48651e94972a56e69f3c0897d9e8facbdaeb98386"
```

**Para Validadores:**
```yaml
mailbox: "0xade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b"
merkleTreeHook: "0x17dcdb32a51ee1c43c3377349dba7f56bdf48e3586f69264656b3b60ceca2bae"
```

---

## 7️⃣ Troubleshooting

### Erro: "insufficient fees"

**Problema:** Taxa de gas muito baixa.

**Solução:** Aumente o gas price:
```bash
--gas-prices 28.5uluna
--gas-adjustment 2.0
```

### Erro: "out of gas"

**Problema:** Gas limit estimado muito baixo.

**Solução:** Use gas fixo ou aumente o adjustment:
```bash
--gas 1000000
# ou
--gas-adjustment 2.5
```

### Erro: "contract not found"

**Problema:** Contrato não foi instanciado ou endereço incorreto.

**Solução:** Verifique o endereço:
```bash
terrad query wasm contract <ADDRESS> --node http://localhost:26657
```

### Proposta não executa automaticamente

**Problema:** Período de votação ainda não terminou.

**Solução:** Aguarde o `voting_end_time`:
```bash
terrad query gov proposal 1 --node http://localhost:26657 | grep voting_end_time
```

### Query retorna erro de schema

**Problema:** Query incorreta para o contrato.

**Solução:** Use as queries documentadas na seção [Verificação da Execução](#5️⃣-verificação-da-execução).

---

## 📚 Recursos Adicionais

### Documentação Oficial

- [Hyperlane Docs](https://docs.hyperlane.xyz/)
- [Terra Classic Docs](https://docs.terra.money/)
- [CosmWasm Docs](https://docs.cosmwasm.com/)

### Repositório e Releases

- **GitHub Repository**: https://github.com/many-things/cw-hyperlane
- **Releases**: https://github.com/many-things/cw-hyperlane/releases
- **Latest Release (v0.0.6-rc8)**:
  - Tag: https://github.com/many-things/cw-hyperlane/releases/tag/v0.0.6-rc8
  - Download: https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
  - Checksums: Incluído no arquivo ZIP

### Arquivos de Configuração

- `script/CustomInstantiateWasm.ts` - Script de instanciação
- `script/submit-proposal.ts` - Script de configuração via governança
- `config.yaml` - Configuração da rede
- `context/terraclassic.json` - Contexto do deployment

### Scripts Úteis

```bash
# Listar contratos disponíveis
yarn cw-hpl upload remote-list -n terraclassic

# Upload de contratos
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic

# Instanciar contratos
ts-node script/CustomInstantiateWasm.ts

# Criar proposta de governança
ts-node script/submit-proposal.ts

# Executar configurações diretamente
MODE=direct ts-node script/submit-proposal.ts
```

---

## ✅ Checklist de Deploy

### Pré-Deploy
- [ ] Verificar contratos disponíveis (`yarn cw-hpl upload remote-list`)
- [ ] Baixar e verificar checksums dos WASMs
- [ ] Confirmar que admin/owner será o módulo de governança

### Deploy
- [ ] Upload dos contratos (`yarn cw-hpl upload remote`)
- [ ] Verificar code IDs em `context/terraclassic.json`
- [ ] Instanciar contratos (`CustomInstantiateWasm.ts`)
- [ ] **CRÍTICO**: Verificar que owner é o módulo de governança
- [ ] Salvar endereços dos contratos

### Configuração
- [ ] Criar proposta de configuração (`submit-proposal.ts`)
- [ ] Votar na proposta (obter quorum)
- [ ] Aguardar aprovação da proposta
- [ ] Verificar que status = `PROPOSAL_STATUS_PASSED`
- [ ] Verificar configurações aplicadas (todas as 6 queries)

### Verificação de Segurança
- [ ] ✅ Confirmar que todos os contratos têm governança como owner
- [ ] ✅ Verificar que ninguém pode alterar contratos diretamente
- [ ] ✅ Validar hashes dos contratos na blockchain
- [ ] ✅ Comparar endereços com a documentação oficial

### Pós-Deploy
- [ ] Configurar relayer com os endereços hexed
- [ ] Configurar validadores
- [ ] Testar envio de mensagens
- [ ] Documentar todos os endereços e code IDs
- [ ] Publicar informações para auditoria

---

## 🔒 Segurança e Governança

### Modelo de Governança On-Chain

Os contratos Hyperlane são **governados pela comunidade** através do módulo de governança da Terra Classic:

#### Características de Segurança

1. **Controle Descentralizado**
   - ✅ Nenhuma entidade única controla os contratos
   - ✅ Admin/Owner = Módulo de Governança
   - ✅ Todas as mudanças requerem votação

2. **Processo de Alteração**
   ```
   Proposta → Período de Votação → Aprovação → Execução Automática
   ```

3. **Transparência Total**
   - 📊 Todas as propostas são públicas
   - 🗳️ Todos os votos são registrados na blockchain
   - 📝 Histórico completo de mudanças
   - 🔍 Auditável por qualquer pessoa

4. **Proteção Contra Ataques**
   - 🛡️ Impossível alterar contratos sem aprovação da comunidade
   - 🛡️ Período de votação permite análise e discussão
   - 🛡️ Quorum e threshold previnem manipulação
   - 🛡️ Veto da comunidade para propostas maliciosas

### Verificação de Ownership

**Sempre verifique** que os contratos estão sob controle da governança:

```bash
# Verificar owner de cada contrato
for contract in \
  terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp \
  terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul
do
  echo "Verificando: $contract"
  terrad query wasm contract-state smart $contract \
    '{"ownable":{"owner":{}}}' \
    --node http://localhost:26657
done

# Todos devem retornar:
# owner: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
```

### Para Auditores

Ao auditar este deployment, verifique:

1. ✅ **Hashes WASM** correspondem aos releases oficiais
2. ✅ **Owner/Admin** é o módulo de governança
3. ✅ **Code IDs** estão documentados corretamente
4. ✅ **Configurações** foram aplicadas via governança
5. ✅ **Nenhuma backdoor** ou função privilegiada além da governança

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs da execução
2. Consulte o troubleshooting acima
3. Revise a documentação oficial do Hyperlane
4. Verifique os contratos na blockchain usando as queries
5. Confirme que ownership está correto (módulo de governança)

---

**Última atualização:** 2025-11-25  
**Versão dos Contratos:** v0.0.6-rc8  
**Chain:** Terra Classic (LocalTerra)  
**Governança:** Terra Classic On-Chain Governance  
**Admin/Owner:** `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` (Módulo de Governança)

