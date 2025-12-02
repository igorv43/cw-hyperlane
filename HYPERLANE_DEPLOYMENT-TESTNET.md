# 📘 Guia Completo: Deploy e Configuração Hyperlane na Terra Classic Testnet

Este guia documenta o processo completo de deploy e configuração dos contratos Hyperlane na Terra Classic Testnet (rebel-2).

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
- **Terra Classic Testnet Node**: Acesso ao RPC público
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

---

## 2️⃣ Deploy dos Contratos (Upload)

### Upload para a Blockchain

Execute o comando para fazer upload de todos os contratos da versão especificada:

```bash
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic
```

**O que este comando faz:**
- 📥 **Baixa os arquivos WASM** do GitHub release
- 📤 Faz upload para a blockchain Terra Classic Testnet
- 💾 Armazena os `code_id` de cada contrato
- 📝 Salva os IDs no arquivo de contexto (`context/terraclassic.json`)

### Hashes dos Contratos (Para Auditoria)

Durante o upload, cada contrato gera um **hash SHA-256** do arquivo WASM. Estes hashes são **cruciais para auditoria** e garantem que não houve manipulação dos binários:

| Contrato | Hash SHA-256 | Code ID (Testnet) | TX Hash |
|----------|--------------|-------------------|---------|
| **hpl_mailbox** | `12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525` | 1981 | `E5D465100CDAE4A8E9CF91996D0F79CDB0818FE959A9DE26AB0731001A0FE74A` |
| **hpl_validator_announce** | `87cf4cbe4f5b6b3c7a278b4ae0ae980d96c04192f07aa70cc80bd7996b31c6a8` | 1982 | `781048E6DB6ADF70F132F7823F729BE185C994A4FF93051EB0CD8D5DEE44653A` |
| **hpl_ism_aggregate** | `fae4d22afede6578ce8b4dbfaa185d43a303b8707386a924232aa24632d00f7b` | 1983 | `5C66E34A32812F4AB9EA4927FA775160FD3855D5396A931D05B53D90EBCCE34A` |
| **hpl_ism_multisig** | `d1f4705e19414e724d3721edad347003934775313922b7ca183ca6fa64a9e076` | 1984 | `CE0EF5E9C74B6AFD7A4DFFEA72F09CDC9641B7580EA66201EA4E3B59929771E8` |
| **hpl_ism_pausable** | `a6e8cc30b5abf13a032c8cb70128fcd88305eea8133fd2163299cf60298e0e7f` | 1985 | `3D188F0BFB7A96C37586A33EDB8B2FA1FBC6CC60CAEB444BA27BDB9DA9D7BD3E` |
| **hpl_ism_routing** | `a0b29c373cb5428ef6e8a99908e0e94b62d719c65434d133b14b4674ee937202` | 1986 | `F0DEA9FEEE0923A159181A06AF7392F4906931AC86F8E4F491B5444F9CBB77B9` |
| **hpl_igp** | `99e42faf05c446170167bdf0521eaaeebe33658972d056c4d0dc607d99186044` | 1987 | `7BB862772DE9769E21FEDDC2A32EF928A1E752B433549F353D70B146C2EC5051` |
| **hpl_hook_aggregate** | `2ee718217253630b087594a92a6770f8d040a99b087e38deafef2e4685b23e8f` | 1988 | `9C7C6C2399F7F687D75F7CFDEC2D5D442C3A7F36BB3A7690042658A5F8198188` |
| **hpl_hook_fee** | `8beeb594aa33ae3ce29f169ac73e2c11c80a7753a2c92518e344b86f701d50fd` | 1989 | `6E43F59DB33637770BDC482177847AE87BA36CC143E06E02651F48C390F39B42` |
| **hpl_hook_merkle** | `1de731062f05b83aaf44e4abb37f566bb02f0cd7c6ecf58d375cbce25ff53076` | 1990 | `B466AE86528BA0F01AFE06FF0D5275AEA73399DE3E064CCABC8500A2F0487194` |
| **hpl_hook_pausable** | `8ea810f57c31bd754ba21ac87cfc361f1d6cc55974eefd8ad2308b69bd63d6bf` | 1991 | `D9454A2C9D58E81791134D9F06D58652A3A3592DFDD84F8781668169FAF70C5D` |
| **hpl_hook_routing** | `cbf712a3ed6881e267ad3b7a82df362c02ae9cb98b68e12c316005d928f611cf` | 1992 | `788968FF912DB6C84B846C2C64A114BCB6B9B6D8F26BF91B05944F46ACECAD52` |
| **hpl_hook_routing_custom** | `f2ffb3a6444da867d7cd81726cb0362ac3cc7ba2e8eef11dcb50f96e6725d09a` | 1993 | `7E72C154E743E6A57D7AED43BE99751D72B48A85EEF54C308539D68021F68952` |
| **hpl_hook_routing_fallback** | `d701bb43e1aea05ae8bdb3fcbe68b449b6e6d9448420b229a651ed9628a3d309` | 1994 | `FF2C219C59B2DF6500F8F40E563247F6F78C66E7852C57794A7BCC6805227DCC` |
| **hpl_test_mock_hook** | `15b7b62a78ce535239443228a0dc625408941182d1b09b338b55d778101e7913` | 1995 | `E797929E1C41151A6B3892E75583B48DB766155CA36F15B4E206A3F212EA9EFA` |
| **hpl_test_mock_ism** | `a5d07479b6d246402438b6e8a5f31adaafa18c2cd769b6dc821f21428ad560ab` | 1996 | `F20D52763BFDD7B18888CCF667CFED053B445BB2E4F0310F67D6FC48DC426B8B` |
| **hpl_test_mock_msg_receiver** | `35862c951117b77514f959692741d9cabc21ce7c463b9682965fce983140f0c1` | 1997 | `C40928D341D14A8C9EAC9EC086FC644273AE9392A90DDB50495517B68524F899` |
| **hpl_igp_oracle** | `a628d5e0e6d8df3b41c60a50aeaee58734ae21b03d443383ebe4a203f1c86609` | 1998 | `A65B92159B6CD64F6BE58B7E8626B066F6F386AB6C540F05FAC0B76E64889765` |
| **hpl_warp_cw20** | `a97d87804fae105d95b916d1aee72f555dd431ece752a646627cf1ac21aa716d` | 1999 | `18FD9952226B3B834BB63BDD095D2129D2BE24C9A750455C0289CBAC03B2C1D4` |
| **hpl_warp_native** | `5aa1b379e6524a3c2440b61c08c6012cc831403fae0c825b966ceabecfdb172b` | 2000 | `5D8E697027851176A4FE0AB5B6C5FF32EE28D609D4F934DA3AC4A0BBB6B24812` |

#### 🔒 Verificação de Integridade

Os hashes SHA-256 acima permitem **verificar a integridade** dos contratos:

**Método 1: Verificar contra a blockchain**

```bash
# Baixar o WASM do code ID (exemplo: hpl_mailbox com code_id 1981)
terrad query wasm code 1981 download.wasm \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2

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

### Verificar Code IDs

Os `code_id` são salvos em:
```bash
cat context/terraclassic.json
```

**Exemplo de conteúdo:**
```json
{
  "artifacts": {
    "hpl_mailbox": 1981,
    "hpl_validator_announce": 1982,
    "hpl_ism_aggregate": 1983,
    "hpl_ism_multisig": 1984,
    "hpl_ism_pausable": 1985,
    "hpl_ism_routing": 1986,
    "hpl_igp": 1987,
    "hpl_hook_aggregate": 1988,
    "hpl_hook_fee": 1989,
    "hpl_hook_merkle": 1990,
    "hpl_hook_pausable": 1991,
    "hpl_hook_routing": 1992,
    "hpl_hook_routing_custom": 1993,
    "hpl_hook_routing_fallback": 1994,
    "hpl_test_mock_hook": 1995,
    "hpl_test_mock_ism": 1996,
    "hpl_test_mock_msg_receiver": 1997,
    "hpl_igp_oracle": 1998,
    "hpl_warp_cw20": 1999,
    "hpl_warp_native": 2000
  }
}
```

### Identificando o Módulo de Governança

Para verificar qual é o endereço do módulo de governança em sua rede:

```bash
# Ver informações da governança
terrad query gov params \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2

# O módulo de governança geralmente tem o endereço:
# terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (Terra Classic)
```

---

## 3️⃣ Instanciação dos Contratos

### Script: `CustomInstantiateWasm-testnet.ts`

Este script instancia todos os contratos na blockchain com suas configurações iniciais.

#### Executar Instanciação

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="sua_chave_hex" yarn tsx script/CustomInstantiateWasm-testnet.ts
```

#### Configuração do Script

O script está configurado com:
- **RPC**: `https://rpc.luncblaze.com`
- **Chain ID**: `rebel-2`
- **Admin/Owner**: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` ⚠️
- **Gas Price**: `28.5uluna`

### 📋 Contratos Instanciados - Explicação Detalhada

O script instancia **12 contratos** na seguinte ordem:

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

**Code ID:** `1981`

**Endereço Instanciado:**
- **Address**: `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`
- **Hexed**: `18111026c945381eb4a6e6852a4affd2b4023e918787379cea28d001314ee44b`

---

#### 2. 📢 VALIDATOR ANNOUNCE - Registro de Validadores

**Função:** Permite que validadores anunciem seus endpoints e localizações para que relayers possam descobrir como obter assinaturas.

**Parâmetros de Instanciação:**
```json
{
  "hrp": "terra",
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
```

**Explicação dos Parâmetros:**
- `hrp` (string): Prefixo Bech32 da chain
- `mailbox` (string): Endereço do Mailbox associado a este anunciador

**Code ID:** `1982`

**Endereço Instanciado:**
- **Address**: `terra10szy9ppjpgt8xk3tkywu3dhss8s5scsga85f4cgh452p6mwd092qdzfyup`
- **Hexed**: `7c044284320a16735a2bb11dc8b6f081e1486208e9e89ae117ad141d6dcd7954`

---

#### 3. 🔐 ISM MULTISIG #1 - Para BSC Testnet (Domain 97)

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

**Code ID:** `1984`

**Endereço Instanciado:**
- **Address**: `terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv`
- **Hexed**: `18d6fb643be899d66edc8305aa1cbfa1115d8256a9679581205ae7b4a895c9b6`

---

#### 4. 🔐 ISM MULTISIG #2 - Para Solana Testnet (Domain 1399811150)

**Função:** ISM que valida mensagens usando assinaturas de múltiplos validadores para Solana Testnet.

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Code ID:** `1984`

**Endereço Instanciado:**
- **Address**: `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a`
- **Hexed**: `6fbb4504dc8bcb2c218740f16f482877d2ef608f16665e5543034712af292a3c`

---

#### 5. 🗺️ ISM ROUTING - Roteador de ISMs

**Função:** Permite usar diferentes ISMs para diferentes domínios (chains). Útil para ter políticas de segurança customizadas por chain de origem.

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "isms": [
    {
      "domain": 97,
      "address": "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv"
    },
    {
      "domain": 1399811150,
      "address": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"
    }
  ]
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Endereço que pode adicionar/remover rotas de ISMs
- `isms` (array): Lista de mapeamentos domain → ISM
  - `domain` (u32): Domain ID da chain de origem
    - Domain 97 = BSC Testnet
    - Domain 1399811150 = Solana Testnet
  - `address` (string): Endereço do ISM a ser usado para mensagens deste domínio

**Code ID:** `1986`

**Endereço Instanciado:**
- **Address**: `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh`
- **Hexed**: `bd60d3a486bb73e6e0ae290a2be159086e887a80f08494456924f67030398cbf`

---

#### 6. 🌳 HOOK MERKLE - Árvore de Merkle para Provas

**Função:** Mantém uma árvore de Merkle de mensagens enviadas. Isso permite provas eficientes de inclusão de mensagens para validação na chain de destino.

**Parâmetros de Instanciação:**
```json
{
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
```

**Explicação dos Parâmetros:**
- `mailbox` (string): Endereço do Mailbox associado a este hook

**Code ID:** `1990`

**Endereço Instanciado:**
- **Address**: `terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df`
- **Hexed**: `3152bdec927acb3783fe38d4c6a6c582cc8a0b4c9ba6e91365df824d7d8611ff`

---

#### 7. ⛽ IGP - Interchain Gas Paymaster

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

**Code ID:** `1987`

**Endereço Instanciado:**
- **Address**: `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9`
- **Hexed**: `9f9e88b11e3233a01f75a8f8ddd49a4ef59f860174109da43784579c883db6b1`

---

#### 8. 🔮 IGP ORACLE - Oráculo de Preços de Gas

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

**Code ID:** `1998`

**Endereço Instanciado:**
- **Address**: `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg`
- **Hexed**: `3ac80cf8a4b2fb8d063dfb229a96cfd1813ea81452dc4ea7e315280b74b9ddc7`

---

#### 9. 🔗 HOOK AGGREGATE #1 - Agregador (Merkle + IGP)

**Função:** Combina múltiplos hooks em um. Este primeiro agregador executa:
- **Hook Merkle**: registra mensagem na árvore de Merkle
- **IGP**: processa pagamento de gas

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df",
    "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
  ]
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Admin do contrato
- `hooks` (array): Lista de endereços de hooks a serem executados em sequência
  - Hook 1: Merkle Tree
  - Hook 2: IGP

**Nota:** Este hook será definido como `default_hook` no Mailbox.

**Code ID:** `1988`

**Endereço Instanciado:**
- **Address**: `terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh`
- **Hexed**: `a825b2bfd4d9db2e42abf9f5fc526a34e0ce745987e8a6009c1683becab6a428`

---

#### 10. ⏸️ HOOK PAUSABLE - Hook com Capacidade de Pausa

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

**Code ID:** `1991`

**Endereço Instanciado:**
- **Address**: `terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l`
- **Hexed**: `93eb6eef8e84118b4bd42a9d4646ff5af7f07f85c02c2630d092ce30117182c3`

---

#### 11. 💰 HOOK FEE - Hook de Cobrança de Taxa Fixa

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

**Code ID:** `1989`

**Endereço Instanciado:**
- **Address**: `terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j`
- **Hexed**: `8934c864640024f2f385ef51639ad0ab46548d417987176913434526c74abd2b`

---

#### 12. 🔗 HOOK AGGREGATE #2 - Agregador (Pausable + Fee)

**Função:** Segundo agregador que combina:
- **Hook Pausable**: permite pausar envio de mensagens
- **Hook Fee**: cobra taxa por mensagem

**Parâmetros de Instanciação:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l",
    "terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j"
  ]
}
```

**Explicação dos Parâmetros:**
- `owner` (string): Admin do contrato
- `hooks` (array): Lista de hooks
  - Hook 1: Pausable
  - Hook 2: Fee

**Nota:** Este hook será definido como `required_hook` no Mailbox.

**Code ID:** `1988`

**Endereço Instanciado:**
- **Address**: `terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj`
- **Hexed**: `3343dbbd999bd51909a7781cf9d8359b646255be450852b6e14bb2b277fa06a4`

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
    │    (domain 97)    │         │                     │
    │  - ISM Multisig   │         │  Default Hook:      │
    │    (domain        │         │  - Merkle           │
    │    1399811150)    │         │  - IGP ──► Oracle   │
    └───────────────────┘         └─────────────────────┘
```

**Fluxo de Envio:**
1. Usuário chama `dispatch()` no Mailbox
2. **Required Hook** é executado (Pausable verifica se não está pausado, Fee cobra taxa)
3. **Default Hook** é executado (Merkle registra, IGP processa pagamento via Oracle)
4. Mensagem é emitida como evento

**Fluxo de Recebimento:**
1. Relayer submete mensagem + metadata
2. Mailbox consulta **Default ISM** (ISM Routing)
3. ISM Routing direciona para **ISM Multisig** apropriado (BSC ou Solana)
4. ISM Multisig valida assinaturas (threshold configurado)
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

---

## 4️⃣ Configuração via Governança

### Script: `submit-proposal-testnet.ts`

Após a instanciação, os contratos precisam ser configurados. Como o **owner/admin é o módulo de governança**, todas as configurações devem ser feitas através de **propostas de governança**.

### 📝 Mensagens de Execução - Explicação Detalhada

A proposta de governança executa **7 mensagens** para configurar o sistema Hyperlane com suporte a **2 chains** (BSC Testnet e Solana Testnet):

---

#### MENSAGEM 1: Configurar Validadores do ISM Multisig para BSC Testnet

**Objetivo:** Define o conjunto de validadores que irão assinar mensagens provenientes do domínio 97 (BSC Testnet). O threshold de 2 significa que pelo menos 2 dos 3 validadores devem assinar para que uma mensagem seja considerada válida.

**Contrato Alvo:** ISM Multisig (`terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv`)

**Mensagem Executada:**
```json
{
  "set_validators": {
    "domain": 97,
    "threshold": 2,
    "validators": [
      "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
      "f620f5e3d25a3ae848fec74bccae5de3edcd8796",
      "1f030345963c54ff8229720dd3a711c15c554aeb"
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `domain` (u32): Domain ID do BSC Testnet no protocolo Hyperlane (97 = BSC Testnet)
- `threshold` (u8): Número mínimo de assinaturas necessárias (2 de 3 validadores)
- `validators` (array de HexBinary): Array de 3 endereços hexadecimais (20 bytes cada) dos validadores

**Segurança:** Com threshold 2/3, o sistema tolera até 1 validador offline ou malicioso enquanto ainda valida mensagens.

---

#### MENSAGEM 2: Configurar Validadores do ISM Multisig para Solana Testnet

**Objetivo:** Define o conjunto de validadores que irão assinar mensagens provenientes do domínio 1399811150 (Solana Testnet). O threshold de 1 significa que pelo menos 1 dos 1 validadores deve assinar para que uma mensagem seja considerada válida.

**Contrato Alvo:** ISM Multisig (`terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a`)

**Mensagem Executada:**
```json
{
  "set_validators": {
    "domain": 1399811150,
    "threshold": 1,
    "validators": [
      "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `domain` (u32): Domain ID do Solana Testnet no protocolo Hyperlane (1399811150 = Solana Testnet)
- `threshold` (u8): Número mínimo de assinaturas necessárias (1 de 1 validadores)
- `validators` (array de HexBinary): Array de 1 endereço hexadecimal (20 bytes) do validador

---

#### MENSAGEM 3: Configurar Dados de Gas Remoto no IGP Oracle (BSC e Solana Testnet)

**Objetivo:** Define a taxa de câmbio de tokens e o preço de gas para os domínios 97 (BSC Testnet) e 1399811150 (Solana Testnet). Isso permite que o IGP calcule quanto gas cobrar na chain de origem (Terra) para cobrir os custos de execução nas chains de destino.

**Contrato Alvo:** IGP Oracle (`terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg`)

**Mensagem Executada:**
```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "1805936462255558",
        "gas_price": "50000000"
      },
      {
        "remote_domain": 1399811150,
        "token_exchange_rate": "57675000000000000",
        "gas_price": "1"
      }
    ]
  }
}
```

**Explicação dos Parâmetros:**
- `remote_domain` (u32): Domain ID da chain remota
  - Domain 97 = BSC Testnet
  - Domain 1399811150 = Solana Testnet
- `token_exchange_rate` (Uint128): Taxa de câmbio entre LUNC e token da chain de destino
- `gas_price` (Uint128): Preço do gas na chain de destino

---

#### MENSAGEM 4: Definir Rotas do IGP para o Oracle (BSC e Solana Testnet)

**Objetivo:** Configura o IGP para usar o IGP Oracle ao calcular custos de gas para os domínios 97 (BSC Testnet) e 1399811150 (Solana Testnet). Estas rotas conectam o IGP ao Oracle que fornece dados atualizados de preços e taxas de câmbio.

**Contrato Alvo:** IGP (`terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9`)

**Mensagem Executada:**
```json
{
  "router": {
    "set_routes": {
      "set": [
        {
          "domain": 97,
          "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
        },
        {
          "domain": 1399811150,
          "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
        }
      ]
    }
  }
}
```

---

#### MENSAGEM 5: Definir ISM Padrão no Mailbox

**Objetivo:** Configura o ISM (Interchain Security Module) padrão que será usado pelo Mailbox para validar mensagens recebidas. O ISM Routing permite usar diferentes estratégias de validação por domínio de origem.

**Contrato Alvo:** Mailbox (`terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`)

**Mensagem Executada:**
```json
{
  "set_default_ism": {
    "ism": "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh"
  }
}
```

---

#### MENSAGEM 6: Definir Hook Padrão no Mailbox

**Objetivo:** Configura o Hook padrão que será executado ao enviar mensagens. O Hook Aggregate #1 combina Merkle Tree Hook (para provas) e IGP (para pagamento).

**Contrato Alvo:** Mailbox (`terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`)

**Mensagem Executada:**
```json
{
  "set_default_hook": {
    "hook": "terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh"
  }
}
```

---

#### MENSAGEM 7: Definir Hook Requerido no Mailbox

**Objetivo:** Configura o Hook obrigatório que SEMPRE será executado ao enviar mensagens, independentemente de hooks customizados especificados pelo remetente. O Hook Aggregate #2 combina Hook Pausable (emergência) e Hook Fee (monetização).

**Contrato Alvo:** Mailbox (`terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`)

**Mensagem Executada:**
```json
{
  "set_required_hook": {
    "hook": "terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj"
  }
}
```

---

### 📊 Proposta 162 - Status e Detalhes

A proposta de configuração foi submetida e aprovada com sucesso:

**ID da Proposta:** `162`

**Status:** `PROPOSAL_STATUS_PASSED`

**Votos:**
- **Sim**: `82020035955749071`
- **Não**: `0`
- **Abstenções**: `0`
- **Veto**: `0`

**Timestamps:**
- **Submetida**: `2025-12-01T17:16:48.606969070Z`
- **Fim do Depósito**: `2025-12-04T17:16:48.606969070Z`
- **Início da Votação**: `2025-12-01T17:16:48.606969070Z`
- **Fim da Votação**: `2025-12-02T05:16:48.606969070Z`

**Título:** `Hyperlane Contracts Configuration - Testnet Multi-Chain`

**Resumo:** `Proposal to configure Hyperlane contracts for BSC Testnet and Solana Testnet: set ISM validators (BSC 2/3, Solana 1/1), configure IGP Oracle for testnet chains, set IGP routes, configure default ISM and hooks (default and required) in Mailbox`

**Proponente:** `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`

**Depósito Total:** `10000000 uluna`

---

## 5️⃣ Verificação da Execução

### Queries para Verificar Configurações

Após a proposta ser aprovada (`PROPOSAL_STATUS_PASSED`), verifique se as configurações foram aplicadas.

#### 1. ✅ ISM Multisig BSC - Validadores Configurados

**O que verifica:** Confirma que os 3 validadores foram registrados no ISM Multisig para o domínio 97 (BSC Testnet) com threshold de 2 assinaturas.

**Query:**
```bash
terrad query wasm contract-state smart terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv \
  '{"multisig_ism":{"enrolled_validators":{"domain":97}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

**Esperado:**
```yaml
data:
  threshold: 2                              # Mínimo de 2 assinaturas necessárias
  validators:                               # Lista de 3 validadores (endereços hex 20 bytes)
  - 242d8a855a8c932dec51f7999ae7d1e48b10c95e  # Validador 1
  - f620f5e3d25a3ae848fec74bccae5de3edcd8796  # Validador 2
  - 1f030345963c54ff8229720dd3a711c15c554aeb  # Validador 3
```

---

#### 2. ✅ ISM Multisig Solana - Validadores Configurados

**O que verifica:** Confirma que o validador foi registrado no ISM Multisig para o domínio 1399811150 (Solana Testnet) com threshold de 1 assinatura.

**Query:**
```bash
terrad query wasm contract-state smart terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a \
  '{"multisig_ism":{"enrolled_validators":{"domain":1399811150}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

---

#### 3. ✅ IGP Oracle - Gas Price Configurado

**O que verifica:** Confirma que o Oracle tem dados de preço de gas e taxa de câmbio configurados para BSC Testnet (domain 97) e Solana Testnet (domain 1399811150).

**Query:**
```bash
# Para BSC Testnet
terrad query wasm contract-state smart terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2

# Para Solana Testnet
terrad query wasm contract-state smart terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":1399811150}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

---

#### 4. ✅ IGP - Rota Configurada

**O que verifica:** Confirma que o IGP tem rotas configuradas apontando para o Oracle.

**Query:**
```bash
# Para BSC Testnet
terrad query wasm contract-state smart terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9 \
  '{"router":{"get_route":{"domain":97}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2

# Para Solana Testnet
terrad query wasm contract-state smart terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9 \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

---

#### 5. ✅ Mailbox - ISM Padrão

**O que verifica:** Confirma que o Mailbox tem um ISM configurado para validar mensagens recebidas.

**Query:**
```bash
terrad query wasm contract-state smart terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"mailbox":{"default_ism":{}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

**Esperado:**
```yaml
data:
  default_ism: terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh  # Endereço do ISM Routing
```

---

#### 6. ✅ Mailbox - Hook Padrão

**O que verifica:** Confirma que o Mailbox tem um Hook configurado para processar envios de mensagens.

**Query:**
```bash
terrad query wasm contract-state smart terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"mailbox":{"default_hook":{}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

**Esperado:**
```yaml
data:
  default_hook: terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh  # Endereço do Hook Aggregate #1
```

---

#### 7. ✅ Mailbox - Hook Requerido

**O que verifica:** Confirma que o Mailbox tem um Hook obrigatório que SEMPRE será executado ao enviar mensagens.

**Query:**
```bash
terrad query wasm contract-state smart terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"mailbox":{"required_hook":{}}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

**Esperado:**
```yaml
data:
  required_hook: terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj  # Endereço do Hook Aggregate #2
```

---

### Script de Verificação Completo

Use o script `query-proposal-status.ts` para verificação automatizada:

```bash
npx tsx script/query-proposal-status.ts 162
```

Este script verifica automaticamente todas as configurações acima.

---

## 6️⃣ Endereços e Hexed dos Contratos

### Tabela de Endereços

| Contrato | Endereço (Bech32) | Hexed (32 bytes) |
|----------|-------------------|------------------|
| **Mailbox** | `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf` | `18111026c945381eb4a6e6852a4affd2b4023e918787379cea28d001314ee44b` |
| **Validator Announce** | `terra10szy9ppjpgt8xk3tkywu3dhss8s5scsga85f4cgh452p6mwd092qdzfyup` | `7c044284320a16735a2bb11dc8b6f081e1486208e9e89ae117ad141d6dcd7954` |
| **ISM Multisig BSC** | `terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv` | `18d6fb643be899d66edc8305aa1cbfa1115d8256a9679581205ae7b4a895c9b6` |
| **ISM Multisig Solana** | `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a` | `6fbb4504dc8bcb2c218740f16f482877d2ef608f16665e5543034712af292a3c` |
| **ISM Routing** | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` | `bd60d3a486bb73e6e0ae290a2be159086e887a80f08494456924f67030398cbf` |
| **Hook Merkle** | `terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df` | `3152bdec927acb3783fe38d4c6a6c582cc8a0b4c9ba6e91365df824d7d8611ff` |
| **IGP** | `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9` | `9f9e88b11e3233a01f75a8f8ddd49a4ef59f860174109da43784579c883db6b1` |
| **IGP Oracle** | `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg` | `3ac80cf8a4b2fb8d063dfb229a96cfd1813ea81452dc4ea7e315280b74b9ddc7` |
| **Hook Aggregate 1** | `terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh` | `a825b2bfd4d9db2e42abf9f5fc526a34e0ce745987e8a6009c1683becab6a428` |
| **Hook Pausable** | `terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l` | `93eb6eef8e84118b4bd42a9d4646ff5af7f07f85c02c2630d092ce30117182c3` |
| **Hook Fee** | `terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j` | `8934c864640024f2f385ef51639ad0ab46548d417987176913434526c74abd2b` |
| **Hook Aggregate 2** | `terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj` | `3343dbbd999bd51909a7781cf9d8359b646255be450852b6e14bb2b277fa06a4` |

### JSON Completo

```json
{
  "hpl_mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf",
  "hpl_validator_announce": "terra10szy9ppjpgt8xk3tkywu3dhss8s5scsga85f4cgh452p6mwd092qdzfyup",
  "hpl_ism_multisig_bsc": "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv",
  "hpl_ism_multisig_sol": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
  "hpl_ism_routing": "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh",
  "hpl_hook_merkle": "terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df",
  "hpl_igp": "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9",
  "hpl_igp_oracle": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg",
  "hpl_hook_aggregate_default": "terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh",
  "hpl_hook_pausable": "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l",
  "hpl_hook_fee": "terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j",
  "hpl_hook_aggregate_required": "terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj"
}
```

### Uso dos Endereços

**Para Relayer:**
```yaml
mailbox: "0x18111026c945381eb4a6e6852a4affd2b4023e918787379cea28d001314ee44b"
validatorAnnounce: "0x7c044284320a16735a2bb11dc8b6f081e1486208e9e89ae117ad141d6dcd7954"
```

**Para Validadores:**
```yaml
mailbox: "0x18111026c945381eb4a6e6852a4affd2b4023e918787379cea28d001314ee44b"
merkleTreeHook: "0x3152bdec927acb3783fe38d4c6a6c582cc8a0b4c9ba6e91365df824d7d8611ff"
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
terrad query wasm contract <ADDRESS> \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

### Proposta não executa automaticamente

**Problema:** Período de votação ainda não terminou.

**Solução:** Aguarde o `voting_end_time`:
```bash
terrad query gov proposal 162 \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2 | grep voting_end_time
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

- `script/CustomInstantiateWasm-testnet.ts` - Script de instanciação (testnet)
- `script/submit-proposal-testnet.ts` - Script de configuração via governança (testnet)
- `script/query-proposal-status.ts` - Script de verificação de proposta
- `config.yaml` - Configuração da rede
- `context/terraclassic.json` - Contexto do deployment

### Scripts Úteis

```bash
# Listar contratos disponíveis
yarn cw-hpl upload remote-list -n terraclassic

# Upload de contratos
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic

# Instanciar contratos (testnet)
yarn tsx script/CustomInstantiateWasm-testnet.ts

# Criar proposta de governança (testnet)
yarn tsx script/submit-proposal-testnet.ts

# Verificar status da proposta
npx tsx script/query-proposal-status.ts 162
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
- [ ] Instanciar contratos (`CustomInstantiateWasm-testnet.ts`)
- [ ] **CRÍTICO**: Verificar que owner é o módulo de governança
- [ ] Salvar endereços dos contratos

### Configuração
- [ ] Criar proposta de configuração (`submit-proposal-testnet.ts`)
- [ ] Votar na proposta (obter quorum)
- [ ] Aguardar aprovação da proposta
- [ ] Verificar que status = `PROPOSAL_STATUS_PASSED`
- [ ] Verificar configurações aplicadas (todas as queries ou usar script)

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
  terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv \
  terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh
do
  echo "Verificando: $contract"
  terrad query wasm contract-state smart $contract \
    '{"ownable":{"owner":{}}}' \
    --node https://rpc.luncblaze.com:443 \
    --chain-id rebel-2
done

# Todos devem retornar:
# owner: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
```

### Para Auditores

Ao auditar este deployment, verifique:

1. ✅ **Hashes WASM** correspondem aos releases oficiais
2. ✅ **Owner/Admin** é o módulo de governança
3. ✅ **Code IDs** estão documentados corretamente
4. ✅ **Configurações** foram aplicadas via governança (Proposta 162)
5. ✅ **Nenhuma backdoor** ou função privilegiada além da governança

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs da execução
2. Consulte o troubleshooting acima
3. Revise a documentação oficial do Hyperlane
4. Verifique os contratos na blockchain usando as queries
5. Confirme que ownership está correto (módulo de governança)
6. Use o script `query-proposal-status.ts` para verificação automatizada

---

**Última atualização:** 2025-12-02  
**Versão dos Contratos:** v0.0.6-rc8  
**Chain:** Terra Classic Testnet (rebel-2)  
**RPC:** https://rpc.luncblaze.com  
**Governança:** Terra Classic On-Chain Governance  
**Admin/Owner:** `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` (Módulo de Governança)  
**Proposta de Configuração:** #162 (APROVADA)  
**Chains Suportadas:** BSC Testnet (Domain 97), Solana Testnet (Domain 1399811150)

