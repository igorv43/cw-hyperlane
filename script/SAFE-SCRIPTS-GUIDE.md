# Guia de Uso do Safe CLI e Scripts Python

Este guia explica como instalar e usar o Safe CLI oficial (Node.js) e também os scripts Python alternativos para gerenciar transações no Safe multisig.

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

#### 1. Listar contas Safe disponíveis

```bash
safe account list
```

#### 2. Adicionar um Safe para consulta

```bash
safe account add --address 0xSEU_SAFE --chain-id 97
```

**Chain IDs importantes:**
- BSC Testnet = 97
- BSC Mainnet = 56
- Ethereum Sepolia = 11155111
- Ethereum Mainnet = 1

#### 3. Consultar informações completas do Safe

Este é o comando principal que consulta direto no contrato:

```bash
safe account info --address 0xSEU_SAFE --chain-id 97
```

**Retorna:**
- Owners (proprietários)
- Threshold (número mínimo de aprovações)
- Nonce (contador de transações)
- Versão do contrato
- Fallback handler
- Módulos instalados
- Guard
- Balance (saldo)

**Formato JSON (para auditoria):**
```bash
safe account info --address 0xSEU_SAFE --chain-id 97 --json
```

#### 4. Consultar owners

```bash
safe account owners --address 0xSEU_SAFE --chain-id 97
```

#### 5. Consultar threshold

```bash
safe account threshold --address 0xSEU_SAFE --chain-id 97
```

#### 6. Consultar saldo

```bash
safe account balance --address 0xSEU_SAFE --chain-id 97
```

#### 7. Listar transações pendentes

```bash
safe tx list --address 0xSEU_SAFE --chain-id 97
```

### 📝 Exemplos Práticos com Safe CLI

#### Exemplo: Consultar informações do multisig na BSC Testnet

```bash
# Substitua 0xSEU_SAFE pelo endereço do seu Safe
safe account info --chain-id 97 --address 0xSEU_SAFE
```

#### Exemplo: Listar owners

```bash
safe account owners --chain-id 97 --address 0xSEU_SAFE
```

#### Exemplo: Criar uma transação

```bash
safe transfer --chain-id 97 --safe-address 0xSEU_SAFE --to 0xDEST --value 0
```

### 💡 Vantagens do Safe CLI Node.js

- ✅ Funciona perfeitamente (versão oficial mantida)
- ✅ Consulta direto no contrato (transparente e auditável)
- ✅ Sem dependências Python problemáticas
- ✅ Comandos simples e intuitivos
- ✅ Suporte a múltiplas chains
- ✅ Formato JSON para automação

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

# Exemplo 2: Adicionar validadores (se o contrato tiver essa função)
CALLDATA=$(cast calldata "setValidators(address[],uint8)" "[0x242d8a855a8c932dec51f7999ae7d1e48b10c95e,0xf620f5e3d25a3ae848fec74bccae5de3edcd8796,0x1f030345963c54ff8229720dd3a711c15c554aeb]" 2)

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

```bash
# 1. Codificar função
CALLDATA=$(cast calldata "setInterchainSecurityModule(address)" \
  0xe4245cCB6427Ba0DC483461bb72318f5DC34d090)

# 2. Owner 1 cria proposta
python3 script/safe-propose-direct.py \
  0xOWNER1_PRIVATE_KEY \
  0xWARP_ROUTE_ADDRESS \
  $CALLDATA

# Saída: Safe TX Hash = 0xabc123...

# 3. Owner 2 confirma (se threshold = 2)
python3 script/safe-confirm.py \
  0xOWNER2_PRIVATE_KEY \
  0xabc123...

# 4. Executar via interface web ou script customizado
```

### Exemplo 2: Adicionar Validadores

```bash
# 1. Codificar função (verifique o nome exato da função no contrato)
CALLDATA=$(cast calldata "setValidators(address[],uint8)" \
  "[0x242d8a855a8c932dec51f7999ae7d1e48b10c95e,0xf620f5e3d25a3ae848fec74bccae5de3edcd8796]" \
  2)

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
  safe account info --address 0xSEU_SAFE --chain-id 97
  ```
- Certifique-se de que todos os owners necessários confirmaram
- Verifique o threshold do Safe:
  ```bash
  safe account threshold --address 0xSEU_SAFE --chain-id 97
  ```

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
- [ ] Safe adicionado ao CLI (`safe account add`)
- [ ] Endereço do Safe conhecido
- [ ] Chain ID correto (97 para BSC Testnet, 56 para BSC Mainnet)

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

