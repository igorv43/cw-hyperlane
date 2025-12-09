# Guia de Uso dos Scripts Safe CLI

Este guia explica como usar os scripts Python para gerenciar transações no Safe multisig quando o `safe-cli` não está funcionando ou a interface web não está disponível.

## 📋 Pré-requisitos

### 1. Instalar Dependências

```bash
# Instalar bibliotecas Python necessárias
pip3 install safe-eth-py web3 eth-account

# Verificar instalação
python3 -c "from safe_eth_py import Safe; print('✅ safe-eth-py instalado')"
```

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

### Erro: "ModuleNotFoundError: No module named 'safe_eth_py'"

```bash
# Instalar no ambiente correto
pip3 install safe-eth-py web3 eth-account

# Ou em um venv
python3 -m venv safe-env
source safe-env/bin/activate
pip install safe-eth-py web3 eth-account
```

### Erro: "Não foi possível conectar ao RPC"

- Verifique se a RPC URL está correta
- Tente uma RPC alternativa:
  ```bash
  # Edite o script e altere RPC_URL para:
  RPC_URL = "https://bsc-testnet.publicnode.com"
  ```

### Erro: "Erro ao carregar conta"

- Verifique se a chave privada está no formato correto (com `0x`)
- Certifique-se de que a chave privada tem BNB para gas

### Erro: "Threshold não atingido"

- Verifique quantos owners já confirmaram
- Certifique-se de que todos os owners necessários confirmaram
- Verifique o threshold do Safe: `safe.retrieve_threshold()`

---

## 📝 Checklist de Uso

- [ ] Dependências instaladas (`safe-eth-py`, `web3`, `eth-account`)
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

- **BscScan Testnet**: https://testnet.bscscan.com
- **Safe Interface**: https://app.safe.global/
- **Hyperlane Docs**: https://docs.hyperlane.xyz/
- **Foundry (cast)**: https://book.getfoundry.sh/

---

## 💡 Dicas

1. **Sempre teste em testnet primeiro** antes de usar em mainnet
2. **Salve o Safe TX Hash** - você precisará dele para confirmar e executar
3. **Verifique o threshold** do Safe antes de criar propostas
4. **Use um gerenciador de senhas** para armazenar chaves privadas com segurança
5. **Verifique o saldo de BNB** antes de criar propostas (precisa de gas)
6. **Confirme os nomes das funções** no contrato antes de codificar

