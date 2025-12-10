# Guia de Uso do Safe CLI e Scripts Python

Este guia explica como instalar e usar o Safe CLI oficial (Node.js) e também os scripts Python alternativos para gerenciar transações no Safe multisig.

## 🚀 Resumo Rápido - Criar e Executar Transação

1. **Instalar:** `npm install -g @safe-global/safe-cli`
2. **Configurar chain:** `safe config chains add` (Chain ID: 97, Short name: `tbnb`)
3. **Importar wallet:** `safe wallet import --private-key 0xKEY --name "Wallet"`
4. **Abrir Safe:** `safe account open tbnb:0xSEU_SAFE --name "Safe"`
5. **Criar transação:** `safe tx create` (forneça to, value, data)
6. **Assinar:** Escolha "Yes" quando perguntado
7. **Executar:** Se der erro GS013, use `cast` diretamente (veja seção [Erro GS013](#erro-gs013-ao-executar-transação))

**⚠️ IMPORTANTE:** 
- Para BSC Testnet, você pode precisar executar via `cast` após aprovar o hash on-chain devido a limitações do Safe CLI sem Safe Transaction Service configurado.
- **Para atualizar ISM do Warp Route:** O ISM atual é imutável. Você precisa criar um novo ISM via factory e atualizar o Warp Route (veja [Exemplo 1: Atualizar ISM](#exemplo-1-atualizar-ism-de-um-warp-route)).

## 🎯 Instalação do Safe CLI Oficial (Recomendado)

### ⚠️ Por que usar a versão Node.js?

O Safe CLI Python (`safe-cli` via pip) **não funciona mais** porque:
- O pacote `safe-eth-py` foi removido/descontinuado
- O Safe CLI Python depende desse pacote
- Nenhuma versão disponível contém o módulo esperado
- O repositório foi descontinuado

**✅ Solução: Use o Safe CLI oficial do Node.js**

### 📦 Instalação (Funciona 100%)

#### Passo 1: Remover qualquer instalação antiga (se houver)

```bash
# Desativar virtualenv Python antigo (se existir)
deactivate 2>/dev/null
rm -rf safe-cli-env
```

#### Passo 2: Instalar a CLI Node.js oficial

```bash
npm install -g @safe-global/safe-cli
```

#### Passo 3: Verificar instalação

```bash
safe --version
# ou
safe version
```

**Saída esperada:**
```
safe-cli version 0.1.0
```

#### Passo 4: Verificar comandos disponíveis

```bash
safe help
```

**Saída esperada:**
```
Usage: safe [options] [command]

Modern CLI for Safe Smart Account management

Commands:
  config                  Manage CLI configuration
  wallet                  Manage wallets and signers
  account                 Manage Safe accounts
  tx                      Manage Safe transactions
  help [command]          display help for command
```

### 🔧 Comandos Básicos do Safe CLI

**⚠️ IMPORTANTE:** O Safe CLI usa o formato **EIP-3770**: `shortName:address`

O formato é: `shortName:0xENDEREÇO` (sem `--address` ou `--chain-id`)

#### 1. Listar contas Safe disponíveis

```bash
safe account list
```

#### 2. Abrir/Adicionar um Safe existente

**Formato EIP-3770 (recomendado):**
```bash
safe account open shortName:0xSEU_SAFE --name "Nome do Safe"
```

**Exemplo para BSC Testnet:**
```bash
safe account open tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee --name "BSC Testnet Safe"
```

**Saída esperada:**
```
✓ Safe Added to Workspace!

Name:  BSC Testnet Safe

Safe Information:
  Address:  0xa047...f5ee
  Chain:    BSC Testnet
  Version:  1.4.1
  Owners:   2
  Threshold: 1 / 2
  Nonce:    0
  Balance:  0.0200 BNB

Safe ready to use
```

**Nota:** Use o formato EIP-3770 (`shortName:address`) para especificar a chain corretamente.

#### 3. Consultar informações completas do Safe

**Formato correto (EIP-3770):**
```bash
safe account info shortName:0xSEU_SAFE
```

**Exemplos:**
```bash
# BSC Mainnet (chain ID 56)
safe account info bnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee

# BSC Testnet (chain ID 97) - após adicionar a chain
safe account info tbnb:0xSEU_SAFE

# Ethereum Mainnet
safe account info eth:0xSEU_SAFE

# Sepolia Testnet
safe account info sep:0xSEU_SAFE
```

**Retorna:**
- Address (endereço)
- Chain (rede)
- Status (Deployed/Not deployed)
- Version (versão do contrato)
- Nonce (contador de transações)
- Owners (proprietários)
- Threshold (número mínimo de aprovações)
- Explorer (link para o block explorer)

**Formato JSON (para auditoria):**
```bash
safe account info bnb:0xSEU_SAFE --json
```

#### 4. Listar transações

```bash
# Listar todas as transações
safe tx list

# Listar transações de um Safe específico
safe tx list bnb:0xSEU_SAFE
```

#### 5. Ver status de uma transação

```bash
safe tx status <SAFE_TX_HASH>
```

#### 6. Gerenciar owners

```bash
# Adicionar owner
safe account add-owner bnb:0xSEU_SAFE 0xNOVO_OWNER --threshold 2

# Remover owner
safe account remove-owner bnb:0xSEU_SAFE 0xOWNER_REMOVIDO

# Alterar threshold
safe account change-threshold bnb:0xSEU_SAFE
```

#### 7. Gerenciar transações

**⚠️ IMPORTANTE:** Antes de criar transações, você precisa:
1. Ter uma wallet importada: `safe wallet import --private-key 0xKEY --name "Wallet"`
2. Ter um Safe aberto: `safe account open tbnb:0xSEU_SAFE --name "Safe"`

```bash
# Criar transação (interativo)
safe tx create

# Assinar transação
safe tx sign <SAFE_TX_HASH>

# Executar transação
safe tx execute <SAFE_TX_HASH>

# Listar transações do Safe
safe tx list tbnb:0xSEU_SAFE

# Ver status de uma transação
safe tx status <SAFE_TX_HASH>
```

### 📝 Processo Completo: Criar e Executar Transação

#### Passo 1: Importar Wallet

```bash
safe wallet import --private-key 0xSUA_PRIVATE_KEY --name "Minha Wallet"
```

#### Passo 2: Abrir Safe

```bash
safe account open tbnb:0xSEU_SAFE --name "BSC Testnet Safe"
```

#### Passo 3: Criar Transação

```bash
safe tx create
```

O CLI vai abrir um assistente interativo. Siga os passos:

**3.1. Select Safe to create transaction for**
- O CLI mostrará os Safes disponíveis
- Selecione o Safe desejado (ex: `BSC Testnet Safe (tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee)`)
- Pressione Enter

**3.2. To address (supports EIP-3770 format: shortName:address)**
- Informe o endereço do contrato destino
- Use formato EIP-3770: `tbnb:0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA`
- Pressione Enter

**Nota:** Se o contrato for detectado, o CLI tentará buscar o ABI automaticamente. Se não encontrar, continuará com entrada manual.

**3.3. Value in wei (0 for token transfer)**
- Para chamadas de função, geralmente é `0`
- Digite `0` e pressione Enter

**3.4. Transaction data (hex)**
- Cole o calldata gerado com `cast`
- Exemplo: `0x46c9aba8000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000242d8a855a8c932dec51f7999ae7d1e48b10c95e000000000000000000000000f620f5e3d25a3ae848fec74bccae5de3edcd87960000000000000000000000001f030345963c54ff8229720dd3a711c15c554aeb`
- Pressione Enter

**Gerar calldata com cast (antes de criar a transação):**
```bash
# Exemplo: Atualizar ISM
cast calldata "setInterchainSecurityModule(address)" 0xNOVO_ISM

# Exemplo: Pausar contrato
cast calldata "pause()"

# Exemplo: Adicionar validadores (Hyperlane ISM Multisig)
# Assinatura correta: setValidators(uint32 domain, uint8 threshold, address[] validators)
cast calldata "setValidators(uint32,uint8,address[])" 97 2 "[0xADDR1,0xADDR2,0xADDR3]"
# Parâmetros: domain (97 para BSC Testnet), threshold (2), validators (array)
```

**3.5. Operation type**
- Escolha entre:
  - `Call` (Standard transaction call) - **Recomendado para a maioria dos casos**
  - `DelegateCall` - Use apenas se souber o que está fazendo
- Use as setas para selecionar e pressione Enter

**3.6. Transaction nonce (leave empty for default)**
- Deixe vazio e pressione Enter (o CLI usará o nonce atual automaticamente)
- Ou informe um nonce específico se necessário

**Saída esperada:**
```
✓ Transaction created successfully!

  Safe TX Hash: 0x90a0006f32b660ddeaa3f984010a59ded306529fb57e9acec2706a29d0301d08
```

**⚠️ IMPORTANTE:** Salve o **Safe TX Hash** - você precisará dele para os próximos passos!

#### Passo 4: Assinar Transação

Após criar a transação, o CLI perguntará:

**"Would you like to sign this transaction now?"**
- Escolha **Yes** (use as setas e pressione Enter)

O CLI abrirá a tela de assinatura:

**4.1. Enter wallet password**
- Se você definiu `SAFE_WALLET_PASSWORD`, o CLI usará automaticamente
- Caso contrário, digite a senha da wallet e pressione Enter
- A senha não será exibida na tela (aparecerá como `▪▪▪▪▪▪▪▪▪▪▪`)

**Para evitar digitar a senha toda vez, defina a variável de ambiente:**
```bash
export SAFE_WALLET_PASSWORD="sua_senha"
```

**Saída esperada:**
```
✓ Signature added (1/1 required)

✓ Transaction is ready to execute!
```

**Nota:** Se o threshold for maior que 1, você precisará que outros owners também assinem a transação.

#### Passo 5: Executar Transação

Após assinar, o CLI perguntará:

**"What would you like to do?"**
- **Execute transaction on-chain (Recommended)** - Tenta executar imediatamente
- **Push to Safe Transaction Service** - Apenas envia para o serviço (não executa)
- **Skip for now** - Não faz nada agora

Escolha **Execute transaction on-chain**.

O CLI mostrará os detalhes da transação e perguntará:

**"Execute this transaction on-chain?"**
- Escolha **Yes**

Você precisará informar a senha da wallet novamente (ou será usada automaticamente se `SAFE_WALLET_PASSWORD` estiver definida).

**⚠️ PROBLEMA COMUM:** O Safe CLI pode falhar com erro **GS013** ao executar transações na BSC Testnet quando o Safe Transaction Service não está configurado corretamente ou quando há problemas com o formato das assinaturas.

**Se o erro GS013 ocorrer, use a solução abaixo:**

**Solução:** Execute diretamente via `cast` após aprovar o hash on-chain:

##### 5.1. Aprovar Hash On-Chain

```bash
cast send 0xSEU_SAFE "approveHash(bytes32)" <SAFE_TX_HASH> \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

##### 5.2. Verificar Aprovação

```bash
cast call 0xSEU_SAFE "approvedHashes(address,bytes32)(uint256)" \
  0xSEU_ENDERECO 0xSAFE_TX_HASH \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

Deve retornar `1` se aprovado.

##### 5.3. Executar Transação via Cast

```bash
cast send 0xSEU_SAFE "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0xTO_ADDRESS \
  0 \
  0xCALLDATA \
  0 \
  200000 \
  0 \
  100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x000000000000000000000000SEU_ENDERECO000000000000000000000000000000000000000000000000000000000000000001 \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --gas-price 100000000
```

**Parâmetros importantes:**
- `safeTxGas`: `200000` (ou maior se necessário)
- `gasPrice`: `100000000` (ou o mínimo da rede)
- `signatures`: Formato `0x000000000000000000000000SEU_ENDERECO000000000000000000000000000000000000000000000000000000000000000001`
  - Address do owner (20 bytes)
  - `v = 0x01` (1 byte) quando hash foi aprovado via `approveHash`
  - `r` e `s` = zeros (64 bytes)

**⚠️ IMPORTANTE - Problemas Comuns:**

1. **Erro "execution reverted" após execução bem-sucedida do Safe:**
   - Verifique se o Safe é o **owner** do contrato destino
   - Se não for, transfira a ownership primeiro: `cast send CONTRATO "transferOwnership(address)" 0xSEU_SAFE --private-key 0xKEY --rpc-url URL`

2. **Assinatura incorreta da função:**
   - Para Hyperlane ISM Multisig, use: `setValidators(uint32,uint8,address[])`
   - **NÃO** use: `setValidators(address[],uint8)` (assinatura incorreta)
   - Parâmetros corretos: `domain` (uint32), `threshold` (uint8), `validators` (address[])

3. **Erro de gas price no cast:**
   - Use `--legacy` quando usar `--gas-price` para evitar conflitos com EIP-1559

**Exemplo completo:**
```bash
# 1. Aprovar hash
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "approveHash(bytes32)" 0x90a0006f32b660ddeaa3f984010a59ded306529fb57e9acec2706a29d0301d08 \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545

# 2. Executar (exemplo com setValidators correto para Hyperlane ISM Multisig)
# Calldata correto: setValidators(uint32,uint8,address[])
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  0 \
  0xa50e0bb40000000000000000000000000000000000000000000000000000000000000061000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000003000000000000000000000000242d8a855a8c932dec51f7999ae7d1e48b10c95e000000000000000000000000f620f5e3d25a3ae848fec74bccae5de3edcd87960000000000000000000000001f030345963c54ff8229720dd3a711c15c554aeb \
  0 \
  200000 \
  0 \
  100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000008BD456605473ad4727ACfDCA0040a0dBD4be2DEA000000000000000000000000000000000000000000000000000000000000000001 \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

#### 8. Configurar chains

```bash
# Listar chains configuradas
safe config chains list

# Adicionar nova chain
safe config chains add

# Ver configuração atual
safe config show
```

### 📝 Exemplos Práticos com Safe CLI

#### Exemplo: Consultar informações do multisig na BSC Mainnet

```bash
# Formato EIP-3770: shortName:address
safe account info bnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee
```

#### Exemplo: Listar transações de um Safe

```bash
safe tx list bnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee
```

#### Exemplo: Ver status de uma transação

```bash
safe tx status 0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367
```

#### Exemplo: Adicionar um owner

```bash
safe account add-owner bnb:0xSEU_SAFE 0xNOVO_OWNER --threshold 2
```

**⚠️ Nota sobre BSC Testnet (Chain ID 97):**
- A BSC Testnet pode não estar configurada por padrão
- Você precisará adicioná-la usando `safe config chains add` (veja seção [Configurar Chains](#-configurar-chains-adicionar-bsc-testnet))
- Após adicionar, use o short name escolhido no formato EIP-3770 (ex: `tbnb:0xSEU_SAFE`)

### 💡 Vantagens do Safe CLI Node.js

- ✅ Funciona perfeitamente (versão oficial mantida)
- ✅ Consulta direto no contrato (transparente e auditável)
- ✅ Sem dependências Python problemáticas
- ✅ Comandos simples e intuitivos
- ✅ Suporte a múltiplas chains
- ✅ Formato JSON para automação

### ⚙️ Configurar Chains (Adicionar BSC Testnet)

Por padrão, o Safe CLI vem com várias chains configuradas, mas pode não incluir a BSC Testnet (Chain ID 97). Para adicionar:

#### Listar chains configuradas

```bash
safe config chains list
```

#### Adicionar BSC Testnet

Execute o comando interativo:

```bash
safe config chains add
```

**Valores para BSC Testnet:**

Quando solicitado, informe:

- **Chain ID:** `97`
- **Chain name:** `BSC Testnet`
- **Short name (EIP-3770):** `tbnb` (ou outro nome de sua preferência, ex: `bsc-testnet`)
- **RPC URL:** `https://data-seed-prebsc-1-s1.binance.org:8545`
- **Block explorer URL (optional):** `https://testnet.bscscan.com`
- **Native currency symbol:** `BNB`
- **Safe Transaction Service URL (optional):** `https://safe-transaction-bsc.safe.global` (use o do BSC Mainnet, mas pode não funcionar para testnet)

**Exemplo de saída:**
```
✓ Chain Added Successfully!

Name:      BSC Testnet
Chain ID:  97

Chain configuration saved
```

**Após adicionar, você pode usar:**
```bash
# Abrir Safe na BSC Testnet
safe account open tbnb:0xSEU_SAFE --name "BSC Testnet Safe"

# Consultar Safe na BSC Testnet
safe account info tbnb:0xSEU_SAFE

# Listar transações
safe tx list tbnb:0xSEU_SAFE
```

**Nota:** O short name que você escolher (ex: `tbnb`) será usado no formato EIP-3770 para identificar a chain.

#### Configurar Safe Transaction Service (Opcional)

**⚠️ IMPORTANTE:** O Safe Transaction Service pode não estar disponível para BSC Testnet. Se configurado, você pode usar o URL do BSC Mainnet, mas pode não funcionar corretamente para testnet.

Para adicionar/editar o Transaction Service URL:

```bash
# Editar configuração das chains
safe config chains edit
```

Procure pela chain ID 97 (BSC Testnet) e adicione:
```json
"transactionServiceUrl": "https://safe-transaction-bsc.safe.global"
```

**Nota:** Mesmo com o Transaction Service configurado, você pode precisar executar transações diretamente via `cast` devido a limitações com BSC Testnet.

#### Verificar configuração

```bash
# Ver todas as chains configuradas
safe config chains list

# Ver configuração completa
safe config show
```

---

## 📋 Scripts Python (Alternativa)

Se preferir usar scripts Python ou precisar de funcionalidades específicas, você pode usar os scripts Python abaixo. **Nota:** Estes scripts dependem de bibliotecas Python que podem ter problemas de compatibilidade.

### 1. Instalar Dependências Python (Opcional)

```bash
# Instalar bibliotecas Python necessárias
pip3 install safe-eth-py web3 eth-account

# Verificar instalação
python3 -c "from safe_eth_py import Safe; print('✅ safe-eth-py instalado')"
```

**⚠️ AVISO:** O `safe-eth-py` pode não funcionar corretamente devido a problemas de compatibilidade. Recomendamos usar o Safe CLI Node.js acima.

### 2. Ter Instalado o `cast` (Foundry)

Para codificar chamadas de função, você precisa do `cast`:

```bash
# Verificar se cast está instalado
cast --version

# Se não estiver, instale Foundry:
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## 🔧 Configuração

Os scripts estão configurados para usar:
- **Safe Address**: `0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee`
- **RPC URL**: `https://data-seed-prebsc-1-s1.binance.org:8545` (BSC Testnet)

Para alterar, edite as variáveis no início de cada script.

---

## 📝 Script 1: `safe-propose-direct.py` - Criar Proposta

Este script cria uma nova proposta de transação no Safe.

### Sintaxe

```bash
python3 script/safe-propose-direct.py <PRIVATE_KEY> <TO_ADDRESS> <CALLDATA>
```

### Parâmetros

- **PRIVATE_KEY**: Chave privada do owner (com `0x`)
- **TO_ADDRESS**: Endereço do contrato destino (ex: Warp Route)
- **CALLDATA**: Dados codificados da função (gerado com `cast`)

### Exemplo Completo

#### Passo 1: Codificar a Função

Primeiro, você precisa codificar a chamada da função usando `cast`:

```bash
# Exemplo 1: Atualizar ISM
CALLDATA=$(cast calldata "setInterchainSecurityModule(address)" 0xe4245cCB6427Ba0DC483461bb72318f5DC34d090)

# Exemplo 2: Adicionar validadores (Hyperlane ISM Multisig)
# Assinatura correta: setValidators(uint32 domain, uint8 threshold, address[] validators)
CALLDATA=$(cast calldata "setValidators(uint32,uint8,address[])" 97 2 "[0x242d8a855a8c932dec51f7999ae7d1e48b10c95e,0xf620f5e3d25a3ae848fec74bccae5de3edcd8796,0x1f030345963c54ff8229720dd3a711c15c554aeb]")
# Parâmetros: domain (97 para BSC Testnet), threshold (2), validators (array de 3 endereços)

# Exemplo 3: Pausar contrato
CALLDATA=$(cast calldata "pause()")

# Exemplo 4: Despausar contrato
CALLDATA=$(cast calldata "unpause()")
```

#### Passo 2: Criar a Proposta

```bash
# Substitua pelos seus valores reais
python3 script/safe-propose-direct.py \
  0x819b680e3578eac4f79b8fde643046e... \
  0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA \
  $CALLDATA
```

### Saída Esperada

```
✅ Conectado à BSC Testnet
   Chain ID: 97

✅ Conta: 0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA
✅ Safe carregado: 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee

📝 Criando proposta de transação...
   To: 0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA
   Value: 0
   Data: 0xa50e0bb4...

✅ Transação Safe criada!
   Safe TX Hash: 0xabc123def456...

🔐 Assinando transação off-chain...
✅ Transação assinada!

📤 Aprovando hash (criando proposta)...
================================================================================
✅ PROPOSTA CRIADA COM SUCESSO!
================================================================================
TX_HASH: 0xf74c6109158ab607d7312a7ddfc7a541d1465fabe25b8ce57018fe7d9201cb72
Safe TX Hash: 0xabc123def456...

📋 Compartilhe o Safe TX Hash com os outros owners:
   0xabc123def456...

🔗 Ver no BscScan:
   https://testnet.bscscan.com/tx/0xf74c6109158ab607d7312a7ddfc7a541d1465fabe25b8ce57018fe7d9201cb72

💡 Próximos passos:
   1. Outros owners devem confirmar usando:
      python3 safe-confirm.py <PRIVATE_KEY> <SAFE_TX_HASH>
   2. Após threshold atingido, execute a transação
================================================================================
```

**⚠️ IMPORTANTE**: Salve o **Safe TX Hash** - você precisará dele para os próximos passos!

---

## ✅ Script 2: `safe-confirm.py` - Confirmar Proposta

Este script permite que outros owners confirmem uma proposta existente.

### Sintaxe

```bash
python3 script/safe-confirm.py <PRIVATE_KEY> <SAFE_TX_HASH>
```

### Parâmetros

- **PRIVATE_KEY**: Chave privada do owner que está confirmando (com `0x`)
- **SAFE_TX_HASH**: O hash da transação Safe retornado pelo script `safe-propose-direct.py`

### Exemplo Completo

```bash
# Owner 1 confirma (pode ser o mesmo que criou a proposta)
python3 script/safe-confirm.py \
  0x819b680e3578eac4f79b8fde643046e... \
  0xabc123def4567890123456789012345678901234567890123456789012345678

# Owner 2 confirma (se threshold for 2 ou mais)
python3 script/safe-confirm.py \
  0x867f9CE9F0D7218b016351CB6122406E6D247a5e... \
  0xabc123def4567890123456789012345678901234567890123456789012345678
```

### Saída Esperada

```
✅ Conectado à BSC Testnet
✅ Conta: 0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA
✅ Safe carregado: 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee
📊 Threshold: 1
✅ Owners que já aprovaram: 1/1
   - 0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA

🔐 Confirmando proposta...
================================================================================
✅ CONFIRMAÇÃO ENVIADA!
================================================================================
TX_HASH: 0x1234567890abcdef...

🔗 Ver no BscScan:
   https://testnet.bscscan.com/tx/0x1234567890abcdef...

⏳ Aguardando confirmação...
✅ Confirmação confirmada!

📊 Aprovações atuais: 2/2

🎉 THRESHOLD ATINGIDO! A proposta está pronta para execução!
   Execute com: python3 safe-execute.py <PRIVATE_KEY> <SAFE_TX_HASH>
================================================================================
```

---

## 🚀 Script 3: `safe-execute.py` - Executar Transação

**⚠️ NOTA**: Executar transações do Safe via script é complexo pois requer coletar todas as assinaturas dos owners. Este script atualmente é apenas um placeholder.

### Opções para Executar

#### Opção 1: Usar Interface Web (Recomendado)

1. Acesse https://app.safe.global/
2. Conecte sua wallet (um dos owners)
3. Vá para "Queue" ou "History"
4. Encontre a transação pendente
5. Clique em "Execute"

#### Opção 2: Usar safe-eth-py Diretamente (Avançado)

Você precisaria criar um script customizado que:
1. Coleta todas as assinaturas dos owners
2. Constrói a transação com todas as assinaturas
3. Executa usando `safe_tx.execute()`

---

## 📚 Exemplos Práticos Completos

### Exemplo 1: Atualizar ISM de um Warp Route

#### ⚠️ Por que criar um novo ISM?

O ISM atual do Warp Route é tipicamente um `StaticMessageIdMultisigIsm` (imutável), criado via `StaticMessageIdMultisigIsmFactory`. Este tipo de contrato:

- **Não pode ser atualizado**: Os validadores são definidos no deployment e armazenados no metadata do proxy
- **Não tem função `setValidatorsAndThreshold`**: Tentar chamar essa função resultará em erro
- **Não tem owner**: Não há função `owner()` porque o contrato é imutável

**Solução:** Criar um novo ISM via factory com os novos validadores e atualizar o Warp Route para usar o novo ISM.

#### 📝 Nota sobre Owner do Warp Route

**Ao fazer deploy do Warp Route:**
- O `owner` especificado no arquivo de configuração (`warp-config.yaml`) se torna o owner do contrato Warp Route
- **Recomendação:** Use o endereço do Safe como owner no arquivo de configuração:
  ```yaml
  bsctestnet:
    owner: "0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"  # Endereço do Safe
    # ... outras configurações ...
  ```
- Isso permite que o Safe gerencie o Warp Route (atualizar ISM, pausar, etc.)
- **Verificar owner atual:**
  ```bash
  cast call 0xWARP_ROUTE_ADDRESS "owner()(address)" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
  ```

#### Processo Completo

Para atualizar os validadores do ISM, você precisa:
1. **Criar um novo ISM** via factory com os novos validadores
2. **Atualizar o Warp Route** para usar o novo ISM

#### Passo 1: Criar Novo ISM via Factory

O factory `StaticMessageIdMultisigIsmFactory` cria contratos ISM imutáveis. Execute diretamente (não via Safe):

```bash
# Criar novo ISM com 3 validadores e threshold 2
cast send 0x0D96aF0c01c4bbbadaaF989Eb489c8783F35B763 \
  "deploy(address[],uint8)" \
  "[0x242d8a855a8c932dec51f7999ae7d1e48b10c95e,0xf620f5e3d25a3ae848fec74bccae5de3edcd8796,0x1f030345963c54ff8229720dd3a711c15c554aeb]" \
  2 \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

**Saída esperada:**
```
status: 1 (success)
transactionHash: 0x...
```

**Obter o endereço do novo ISM:**
```bash
# O factory retorna o endereço do novo contrato
cast call 0x0D96aF0c01c4bbbadaaF989Eb489c8783F35B763 \
  "deploy(address[],uint8)(address)" \
  "[0x242d8a855a8c932dec51f7999ae7d1e48b10c95e,0xf620f5e3d25a3ae848fec74bccae5de3edcd8796,0x1f030345963c54ff8229720dd3a711c15c554aeb]" \
  2 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
# Retorna: 0xABeCf81b2Bd1E1d700E2f3B2ECcfb04e75dD7aB2 (exemplo)
```

**Verificar se o novo ISM foi criado corretamente:**
```bash
cast call 0xABeCf81b2Bd1E1d700E2f3B2ECcfb04e75dD7aB2 \
  "validatorsAndThreshold(bytes)(address[],uint8)" \
  0x \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
# Deve retornar os validadores e threshold configurados
```

#### Passo 2: Atualizar ISM no Warp Route

**⚠️ IMPORTANTE - Owner do Warp Route:**
Ao fazer o deploy do Warp Route usando `hyperlane warp deploy`, o `owner` especificado no arquivo de configuração (`warp-config.yaml`) se torna o owner do contrato Warp Route. Se você especificou o endereço do Safe como owner, então o Safe pode atualizar o ISM. Verifique o owner atual:

```bash
cast call 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  "owner()(address)" \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

Agora atualize o Warp Route para usar o novo ISM. Você tem **duas opções**:

##### Opção A: Executar via Safe CLI (Recomendado quando funciona)

```bash
# 1. Gerar calldata para setInterchainSecurityModule
cast calldata "setInterchainSecurityModule(address)" 0xABeCf81b2Bd1E1d700E2f3B2ECcfb04e75dD7aB2
# Retorna: 0x0e72cc06000000000000000000000000abecf81b2bd1e1d700e2f3b2eccfb04e75dd7ab2

# 2. Criar transação no Safe
safe tx create
```

**Preencher os campos no Safe CLI:**

1. **Select Safe**: Escolha `BSC Testnet Safe (tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee)`

2. **To address**: 
   ```
   tbnb:0x63B2f9C469F422De8069Ef6FE382672F16a367d3
   ```
   (Endereço do contrato Warp Route)

3. **Value in wei**: 
   ```
   0
   ```

4. **Transaction data (hex)**: Cole o calldata gerado:
   ```
   0x0e72cc06000000000000000000000000abecf81b2bd1e1d700e2f3b2eccfb04e75dd7ab2
   ```

5. **Operation type**: `Call`

6. **Transaction nonce**: Deixe vazio (ou use o próximo nonce)

7. **Would you like to sign this transaction now?**: Escolha `Yes` e forneça a senha

8. **What would you like to do?**: Escolha `Execute transaction on-chain`

9. **Execute this transaction on-chain?**: Escolha `Yes` e forneça a senha novamente

**Saída esperada (sucesso):**
```
✓ Transaction Executed Successfully!

Tx Hash:  0x924d3e95cb44972e5ed08d0a119ede11a78a99c5a19f12a3c8329a04e87e22c1

Transaction confirmed on-chain
```

**Se der erro GS013:** Use a Opção B abaixo.

##### Opção B: Executar via Cast (Quando Safe CLI falha com GS013)

Se o Safe CLI falhar com erro GS013, você pode aprovar o hash e executar separadamente via `cast`:

**Passo 2.1: Criar e assinar transação no Safe CLI**

```bash
# Criar transação (mesmo processo da Opção A, mas NÃO execute)
safe tx create
# ... preencha os campos ...
# Quando perguntar "What would you like to do?", escolha "Exit" ou "Cancel"
# Salve o Safe TX Hash que foi gerado
```

**Exemplo de Safe TX Hash gerado:**
```
Safe TX Hash: 0xe27c3468f397c7ee4019f7ee3a839ba1c35f406542481ad8e8d971405374128a
```

**Passo 2.2: Aprovar Hash On-Chain via Cast**

```bash
# Aprovar o hash da transação no contrato Safe
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "approveHash(bytes32)" 0xe27c3468f397c7ee4019f7ee3a839ba1c35f406542481ad8e8d971405374128a \
  --private-key 0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

**Verificar aprovação:**
```bash
cast call 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "approvedHashes(address,bytes32)(uint256)" \
  0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA \
  0xe27c3468f397c7ee4019f7ee3a839ba1c35f406542481ad8e8d971405374128a \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
# Deve retornar: 1 (se aprovado)
```

**Passo 2.3: Executar Transação via Cast**

```bash
# Executar a transação diretamente via cast
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  0 \
  0x0e72cc06000000000000000000000000abecf81b2bd1e1d700e2f3b2eccfb04e75dd7ab2 \
  0 \
  200000 \
  0 \
  100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000008BD456605473ad4727ACfDCA0040a0dBD4be2DEA000000000000000000000000000000000000000000000000000000000000000001 \
  --private-key 0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

**Parâmetros importantes:**
- `to`: `0x63B2f9C469F422De8069Ef6FE382672F16a367d3` (endereço do Warp Route)
- `data`: `0x0e72cc06000000000000000000000000abecf81b2bd1e1d700e2f3b2eccfb04e75dd7ab2` (calldata de `setInterchainSecurityModule`)
- `safeTxGas`: `200000` (gas para execução interna)
- `gasPrice`: `100000000` (preço do gas na BSC Testnet)
- `signatures`: Formato especial quando hash foi aprovado via `approveHash`
  - Address do owner: `0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA` (20 bytes)
  - `v = 0x01` (1 byte) - indica hash aprovado
  - `r` e `s` = zeros (64 bytes)

**Saída esperada:**
```
status: 1 (success)
transactionHash: 0x...
```

**⚠️ Nota:** A Opção B é necessária quando o Safe CLI falha com erro GS013 na BSC Testnet. A Opção A (Safe CLI) é mais simples e deve ser tentada primeiro.

#### Resumo do Processo

1. ✅ **Criar novo ISM** via factory (execução direta, não via Safe)
2. ✅ **Verificar novo ISM** (validators e threshold corretos)
3. ✅ **Atualizar Warp Route** via Safe CLI usando `setInterchainSecurityModule(address)`
4. ✅ **Verificar atualização** (opcional: verificar o ISM atual do Warp Route)

### Exemplo 2: Adicionar Validadores

```bash
# 1. Codificar função (Hyperlane ISM Multisig)
# Assinatura correta: setValidators(uint32 domain, uint8 threshold, address[] validators)
CALLDATA=$(cast calldata "setValidators(uint32,uint8,address[])" \
  97 \
  2 \
  "[0x242d8a855a8c932dec51f7999ae7d1e48b10c95e,0xf620f5e3d25a3ae848fec74bccae5de3edcd8796]")
# Parâmetros: domain (97 para BSC Testnet), threshold (2), validators (array)

# 2. Criar proposta
python3 script/safe-propose-direct.py \
  0xOWNER1_PRIVATE_KEY \
  0xWARP_ROUTE_ADDRESS \
  $CALLDATA

# 3. Outros owners confirmam
python3 script/safe-confirm.py 0xOWNER2_PRIVATE_KEY <SAFE_TX_HASH>
```

### Exemplo 3: Pausar Warp Route

```bash
# 1. Codificar função pause
CALLDATA=$(cast calldata "pause()")

# 2. Criar proposta
python3 script/safe-propose-direct.py \
  0xOWNER1_PRIVATE_KEY \
  0xWARP_ROUTE_ADDRESS \
  $CALLDATA

# 3. Confirmar e executar
```

---

## 🔍 Como Descobrir os Métodos do Contrato

### Método 1: Usar BscScan

1. Acesse https://testnet.bscscan.com/address/0xWARP_ROUTE_ADDRESS
2. Clique na aba "Contract"
3. Clique em "Read Contract" ou "Write Contract"
4. Veja as funções disponíveis

### Método 2: Usar `cast`

```bash
# Listar funções do contrato (se tiver ABI)
cast interface 0xWARP_ROUTE_ADDRESS --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

### Método 3: Verificar Documentação do Hyperlane

Consulte a documentação do Hyperlane para os contratos Warp Route:
- https://docs.hyperlane.xyz/

---

## ⚠️ Troubleshooting

### Safe CLI não funciona / Erro de instalação Python

**Problema:** O Safe CLI Python (`safe-cli` via pip) não funciona mais.

**Solução:** Use o Safe CLI oficial do Node.js:

```bash
# Remover instalação Python antiga
deactivate 2>/dev/null
rm -rf safe-cli-env

# Instalar versão Node.js oficial
npm install -g @safe-global/safe-cli

# Verificar
safe --version
```

### Erro: "ModuleNotFoundError: No module named 'safe_eth_py'"

**Se você está usando scripts Python:**

```bash
# Instalar no ambiente correto
pip3 install safe-eth-py web3 eth-account

# Ou em um venv
python3 -m venv safe-env
source safe-env/bin/activate
pip install safe-eth-py web3 eth-account
```

**⚠️ Nota:** Mesmo após instalar, o `safe-eth-py` pode não funcionar devido a problemas de compatibilidade. **Recomendamos usar o Safe CLI Node.js** (veja seção de instalação acima).

### Erro: "Não foi possível conectar ao RPC"

- Verifique se a RPC URL está correta
- Tente uma RPC alternativa:
  ```bash
  # Para BSC Testnet, tente:
  https://bsc-testnet.publicnode.com
  https://data-seed-prebsc-1-s1.binance.org:8545
  ```

### Erro: "Erro ao carregar conta"

- Verifique se a chave privada está no formato correto (com `0x`)
- Certifique-se de que a chave privada tem BNB para gas

### Erro: "Threshold não atingido"

- Verifique quantos owners já confirmaram usando:
  ```bash
  safe account info bnb:0xSEU_SAFE
  ```
- Certifique-se de que todos os owners necessários confirmaram
- Verifique o status da transação:
  ```bash
  safe tx status <SAFE_TX_HASH>
  ```

### Erro: "unknown option '--address'"

**Problema:** O Safe CLI não usa `--address` ou `--chain-id` como opções.

**Solução:** Use o formato EIP-3770: `shortName:address`

```bash
# ❌ ERRADO
safe account info --address 0xSEU_SAFE --chain-id 97

# ✅ CORRETO
safe account info bnb:0xSEU_SAFE
```

### Erro: GS013 ao executar transação

**Problema:** O Safe CLI falha ao executar transações na BSC Testnet com erro GS013.

**Causa:** O Safe CLI não formata as assinaturas corretamente quando o Safe Transaction Service não está disponível para a chain.

**Solução:** Execute diretamente via `cast` após aprovar o hash on-chain:

1. **Aprovar hash on-chain:**
```bash
cast send 0xSEU_SAFE "approveHash(bytes32)" <SAFE_TX_HASH> \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

2. **Verificar aprovação:**
```bash
cast call 0xSEU_SAFE "approvedHashes(address,bytes32)(uint256)" \
  0xSEU_ENDERECO <SAFE_TX_HASH> \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

3. **Executar via cast com parâmetros corretos:**
```bash
cast send 0xSEU_SAFE "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0xTO_ADDRESS 0 0xCALLDATA 0 200000 0 100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x000000000000000000000000SEU_ENDERECO000000000000000000000000000000000000000000000000000000000000000001 \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --gas-price 100000000
```

**Parâmetros importantes:**
- `safeTxGas`: Use `200000` ou maior
- `gasPrice`: Use `100000000` (ou o mínimo da rede)
- `signatures`: Formato `address (20 bytes) + v (0x01) + r (32 bytes zeros) + s (32 bytes zeros)`

### Erro: GS025 ao executar transação

**Problema:** `safeTxGas` insuficiente.

**Solução:** Aumente o valor de `safeTxGas` para `200000` ou maior.

### Erro: "transaction gas price below minimum"

**Problema:** Gas price muito baixo.

**Solução:** Especifique um gas price maior:
```bash
cast send ... --gas-price 100000000
```

### Erro: "execution reverted" na chamada interna

**Problema:** A transação do Safe foi executada com sucesso, mas a chamada interna ao contrato destino reverteu.

**Causas possíveis:**
1. O Safe não é o owner do contrato destino
2. A função não existe ou tem assinatura diferente
3. Parâmetros inválidos (ex: threshold maior que número de validadores)
4. Alguma validação falhou dentro da função

**Como verificar:**

1. **Verificar se o Safe é o owner:**
```bash
# Tentar diferentes variações da função owner
cast call 0xCONTRATO "owner()" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
cast call 0xCONTRATO "getOwner()" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
cast call 0xCONTRATO "owner(address)" 0xSEU_SAFE --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

2. **Verificar se a função existe:**
```bash
# Verificar o código do contrato no BscScan
# https://testnet.bscscan.com/address/0xCONTRATO#code
```

3. **Verificar os parâmetros:**
- Threshold não pode ser maior que o número de validadores
- Endereços devem ser válidos
- Função deve existir no contrato

**Solução:**
- Verifique no BscScan se o Safe é o owner do contrato
- Confirme que a função existe e tem a assinatura correta
- Verifique se os parâmetros estão corretos
- Se necessário, transfira a ownership para o Safe primeiro

### Como descobrir o shortName de uma chain

```bash
# Listar todas as chains configuradas
safe config chains list

# Ver configuração completa
safe config show
```

Os shortNames comuns:
- BSC Mainnet (56): `bnb`
- BSC Testnet (97): `tbnb` (ou outro nome que você escolher ao adicionar)
- Ethereum Mainnet (1): `eth`
- Sepolia Testnet (11155111): `sep`

**Para adicionar BSC Testnet, veja a seção [Configurar Chains](#-configurar-chains-adicionar-bsc-testnet)**

### Comando Safe CLI não encontrado

Se o comando `safe` não for encontrado após instalação:

```bash
# Verificar se npm está instalado
npm --version

# Verificar se o caminho global do npm está no PATH
npm config get prefix

# Adicionar ao PATH se necessário (adicione ao ~/.bashrc ou ~/.zshrc)
export PATH="$(npm config get prefix)/bin:$PATH"
```

---

## 📝 Checklist de Uso

### Para Safe CLI Node.js (Recomendado)

- [ ] Node.js e npm instalados
- [ ] Safe CLI instalado (`npm install -g @safe-global/safe-cli`)
- [ ] Safe CLI funcionando (`safe --version`)
- [ ] Chain BSC Testnet configurada (`safe config chains add`)
- [ ] Wallet importada (`safe wallet import`)
- [ ] Safe aberto no CLI (`safe account open`)
- [ ] Endereço do Safe conhecido
- [ ] Chain ID correto (97 para BSC Testnet, 56 para BSC Mainnet)
- [ ] `cast` instalado (Foundry) para gerar calldata e executar quando necessário

### Para Scripts Python (Alternativa)

- [ ] Dependências Python instaladas (`safe-eth-py`, `web3`, `eth-account`)
- [ ] `cast` instalado (Foundry)
- [ ] Chaves privadas dos owners disponíveis
- [ ] Contas têm BNB suficiente para gas
- [ ] Endereço do contrato destino conhecido
- [ ] Função a ser chamada identificada
- [ ] Calldata gerado com `cast`
- [ ] Safe TX Hash salvo após criar proposta
- [ ] Todos os owners confirmaram (threshold atingido)
- [ ] Transação executada (via web ou script)

---

## 🔗 Links Úteis

- **Safe CLI Node.js (Oficial)**: https://www.npmjs.com/package/@safe-global/safe-cli
- **Safe Interface Web**: https://app.safe.global/
- **BscScan Testnet**: https://testnet.bscscan.com
- **BscScan Mainnet**: https://bscscan.com
- **Hyperlane Docs**: https://docs.hyperlane.xyz/
- **Foundry (cast)**: https://book.getfoundry.sh/
- **Node.js**: https://nodejs.org/

---

## 💡 Dicas

1. **Sempre teste em testnet primeiro** antes de usar em mainnet
2. **Salve o Safe TX Hash** - você precisará dele para confirmar e executar
3. **Verifique o threshold** do Safe antes de criar propostas
4. **Use um gerenciador de senhas** para armazenar chaves privadas com segurança
5. **Verifique o saldo de BNB** antes de criar propostas (precisa de gas)
6. **Confirme os nomes das funções** no contrato antes de codificar
7. **Para BSC Testnet**, esteja preparado para executar via `cast` se o Safe CLI falhar com GS013

## 📋 Fluxo Completo Resumido

### Setup Inicial (Uma vez)

```bash
# 1. Instalar Safe CLI
npm install -g @safe-global/safe-cli

# 2. Adicionar BSC Testnet
safe config chains add
# Informe: Chain ID: 97, Name: BSC Testnet, Short name: tbnb, RPC: https://data-seed-prebsc-1-s1.binance.org:8545

# 3. Importar wallet
safe wallet import --private-key 0xSUA_PRIVATE_KEY --name "Minha Wallet"

# 4. Abrir Safe
safe account open tbnb:0xSEU_SAFE --name "BSC Testnet Safe"
```

### Criar e Executar Transação

```bash
# 1. Gerar calldata
CALLDATA=$(cast calldata "nomeFuncao(tipo)" parametro)

# 2. Criar transação
safe tx create
# Informe: to (tbnb:0xENDEREÇO), value (0), data ($CALLDATA), operation (Call), nonce (vazio)

# 3. Assinar (quando perguntado, escolha Yes)
# Defina senha: export SAFE_WALLET_PASSWORD="sua_senha"

# 4. Se executar falhar com GS013, execute via cast:
# 4.1. Aprovar hash on-chain
cast send 0xSEU_SAFE "approveHash(bytes32)" <SAFE_TX_HASH> \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545

# 4.2. Executar transação
cast send 0xSEU_SAFE "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0xTO_ADDRESS 0 0xCALLDATA 0 200000 0 100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x000000000000000000000000SEU_ENDERECO000000000000000000000000000000000000000000000000000000000000000001 \
  --private-key 0xSUA_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --gas-price 100000000
```

