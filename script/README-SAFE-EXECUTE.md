# Como Executar Transações do Safe

## Scripts Disponíveis

### 1. `safe-execute-complete.py` - Executar com CALLDATA

**Uso:**
```bash
python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA> [SAFE_TX_HASH]
```

**Exemplo:**
```bash
# Com CALLDATA apenas
python3 script/safe-execute-complete.py \
  0x819b680e3578eac4f79b8fde643046e88f.... \
  0x3f4ba83a...

# Com CALLDATA e Safe TX Hash (para validação)
python3 script/safe-execute-complete.py \
  0x819b680e3578eac4f79b8fde643046e88f.... \
  0x3f4ba83a... \
  0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367
```

**O que faz:**
- Reconstrói a transação Safe usando o CALLDATA
- Verifica aprovações e threshold
- Tenta executar usando método execute() do SafeTx
- Se falhar, tenta abordagem alternativa com assinaturas formatadas

### 2. `safe-execute-by-hash.py` - Executar usando Safe TX Hash

**Uso:**
```bash
python3 script/safe-execute-by-hash.py <PRIVATE_KEY> <SAFE_TX_HASH>
```

**Limitação:**
- O Safe TX Hash não contém os dados da transação
- Você ainda precisa do CALLDATA original
- Use `safe-execute-complete.py` em vez disso

## Fluxo Completo

1. **Criar Proposta:**
```bash
CALLDATA=$(cast calldata "setInterchainSecurityModule(address)" 0xNEW_ISM)
python3 script/safe-propose-direct.py 0xPRIVATE_KEY 0xCONTRACT $CALLDATA
# Salve o Safe TX Hash retornado
```

2. **Confirmar (outros owners):**
```bash
python3 script/safe-confirm.py 0xOWNER_PRIVATE_KEY <SAFE_TX_HASH>
```

3. **Executar:**
```bash
python3 script/safe-execute-complete.py 0xPRIVATE_KEY $CALLDATA [SAFE_TX_HASH]
```

## Troubleshooting

### Erro GS013
- Verifique se o Safe tem BNB suficiente
- Verifique se todas as assinaturas necessárias estão presentes
- O script tenta duas abordagens automaticamente

### Safe-cli não funciona (versão Python)

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

# Consultar informações do Safe
safe account info --address 0xSEU_SAFE --chain-id 97
```

Para mais detalhes, consulte o [Guia Completo do Safe CLI](SAFE-SCRIPTS-GUIDE.md#-instalação-do-safe-cli-oficial-recomendado).

**Alternativa:** Use os scripts Python diretamente (veja seção acima).
