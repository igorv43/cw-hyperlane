# Guia Completo: Configurar Validadores ISM sem Credenciais do Mailbox

Este guia explica como configurar validadores do ISM Multisig para Solana (ou outras chains) **sem precisar de credenciais do Mailbox**. O ISM Multisig tem um `owner` que pode configurar validadores diretamente.

## Índice

1. [Entendendo a Autorização](#entendendo-a-autorização)
2. [Verificar Owner do ISM](#verificar-owner-do-ism)
3. [Configurar Validadores Diretamente (Se Você é o Owner)](#configurar-validadores-diretamente-se-você-é-o-owner)
4. [Configurar Validadores via Governance (Se Owner é Governance)](#configurar-validadores-via-governance-se-owner-é-governance)
5. [Transferir Ownership (Se Necessário)](#transferir-ownership-se-necessário)
6. [Exemplos Práticos](#exemplos-práticos)

---

## Entendendo a Autorização

### Como Funciona

O contrato ISM Multisig usa o padrão **Ownable** do Hyperlane:

1. **Owner**: Definido no `instantiate` do contrato
2. **Função `set_validators`**: Verifica se `info.sender == owner`
3. **Se você é o owner**: Pode chamar `set_validators` diretamente
4. **Se o owner é governance**: Precisa fazer via proposta de governança

### Código do Contrato

```rust
// contracts/isms/multisig/src/contract.rs
SetValidators {
    domain,
    threshold,
    validators,
} => {
    ensure_eq!(
        info.sender,
        get_owner(deps.storage)?,  // Verifica se sender é o owner
        ContractError::Unauthorized {}
    );
    // ... configura validators
}
```

---

## Verificar Owner do ISM

### 1. Verificar Owner do ISM Multisig Solana

```bash
# ISM Multisig Solana Testnet
ISM_SOLANA="terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"

# Verificar owner
terrad query wasm contract-state smart ${ISM_SOLANA} \
  '{"ownable":{"owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada:**
```json
{
  "data": {
    "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
  }
}
```

### 2. Verificar Validadores Atuais

```bash
# Verificar validadores configurados para Solana Testnet (domain 1399811150)
terrad query wasm contract-state smart ${ISM_SOLANA} \
  '{"multisig_ism":{"enrolled_validators":{"domain":1399811150}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada:**
```json
{
  "data": {
    "validators": [
      "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"
    ],
    "threshold": 1
  }
}
```

---

## Configurar Validadores Diretamente (Se Você é o Owner)

### ⚠️ Importante

Se o owner do ISM for **sua conta** (não o módulo de governance), você pode configurar validadores diretamente usando `terrad tx wasm execute`.

### Comando Direto

```bash
# Variáveis
ISM_SOLANA="terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"
KEY_NAME="hypelane-val-testnet"
DOMAIN=1399811150  # Solana Testnet
THRESHOLD=2

# Validadores (endereços hex de 20 bytes, sem 0x)
VALIDATOR_1="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
VALIDATOR_2="f620f5e3d25a3ae848fec74bccae5de3edcd8796"
VALIDATOR_3="1f030345963c54ff8229720dd3a711c15c554aeb"

# Configurar validadores
terrad tx wasm execute ${ISM_SOLANA} \
  "{\"set_validators\":{\"domain\":${DOMAIN},\"threshold\":${THRESHOLD},\"validators\":[\"${VALIDATOR_1}\",\"${VALIDATOR_2}\",\"${VALIDATOR_3}\"]}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### Verificar Sucesso

```bash
# Verificar se os validadores foram configurados
terrad query wasm contract-state smart ${ISM_SOLANA} \
  '{"multisig_ism":{"enrolled_validators":{"domain":1399811150}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

---

## Configurar Validadores via Governance (Se Owner é Governance)

### ⚠️ Situação Atual

No Terra Classic Testnet, o owner do ISM Multisig Solana é o **módulo de governance**:
- **Owner**: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` (governance module)

Portanto, **é necessário fazer via proposta de governança**.

### Passo 1: Criar Proposta JSON

```bash
cat > proposal-ism-solana-validators.json << EOF
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
      "msg": {
        "set_validators": {
          "domain": 1399811150,
          "threshold": 2,
          "validators": [
            "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
            "f620f5e3d25a3ae848fec74bccae5de3edcd8796",
            "1f030345963c54ff8229720dd3a711c15c554aeb"
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update Solana Testnet validators to 3 validators with threshold 2",
  "deposit": "500000uluna",
  "title": "Update Hyperlane Solana Testnet Validators",
  "summary": "Configure 3 validators for Solana Testnet ISM with threshold 2/3",
  "expedited": false
}
EOF
```

### Passo 2: Submeter Proposta

```bash
terrad tx gov submit-proposal proposal-ism-solana-validators.json \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --yes
```

### Passo 3: Verificar Proposta

```bash
# Listar propostas
terrad query gov proposals --chain-id rebel-2 --node https://rpc.luncblaze.com:443

# Ver detalhes da proposta (substitua PROPOSAL_ID)
terrad query gov proposal PROPOSAL_ID \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

### Passo 4: Depositar e Votar

```bash
# Depositar (se necessário)
terrad tx gov deposit PROPOSAL_ID 500000uluna \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes

# Votar
terrad tx gov vote PROPOSAL_ID yes \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

---

## Transferir Ownership (Se Necessário)

### ⚠️ Aviso

Transferir ownership do ISM é uma operação **irreversível** e deve ser feita com cuidado. Se você transferir para sua conta, poderá configurar validadores diretamente sem governance.

### Verificar se Pode Transferir

```bash
# Verificar owner atual
terrad query wasm contract-state smart ${ISM_SOLANA} \
  '{"ownable":{"owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

### Transferir Ownership (Se Você é o Owner Atual)

```bash
# Sua nova conta que será o owner
NEW_OWNER="terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"

# Transferir ownership
terrad tx wasm execute ${ISM_SOLANA} \
  "{\"ownable\":{\"transfer_ownership\":{\"new_owner\":\"${NEW_OWNER}\"}}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### Transferir Ownership via Governance (Se Owner é Governance)

```bash
cat > proposal-transfer-ism-ownership.json << EOF
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
      "msg": {
        "ownable": {
          "transfer_ownership": {
            "new_owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"
          }
        }
      },
      "funds": []
    }
  ],
  "metadata": "Transfer ISM Multisig Solana ownership to new account",
  "deposit": "500000uluna",
  "title": "Transfer ISM Solana Ownership",
  "summary": "Transfer ownership of ISM Multisig Solana to enable direct validator configuration",
  "expedited": false
}
EOF

# Submeter proposta
terrad tx gov submit-proposal proposal-transfer-ism-ownership.json \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --yes
```

---

## Exemplos Práticos

### Exemplo 1: Adicionar 2 Novos Validadores (Total: 3, Threshold: 2)

**Situação**: Atualmente tem 1 validator, quer adicionar mais 2.

```bash
# Validadores atuais + novos
VALIDATOR_1="d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"  # Existente
VALIDATOR_2="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Novo
VALIDATOR_3="f620f5e3d25a3ae848fec74bccae5de3edcd8796"  # Novo

# Via governance (owner é governance)
cat > proposal-add-solana-validators.json << EOF
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
      "msg": {
        "set_validators": {
          "domain": 1399811150,
          "threshold": 2,
          "validators": [
            "${VALIDATOR_1}",
            "${VALIDATOR_2}",
            "${VALIDATOR_3}"
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Add 2 new validators to Solana Testnet ISM",
  "deposit": "500000uluna",
  "title": "Add Solana Testnet Validators",
  "summary": "Increase validators from 1/1 to 2/3 for improved security",
  "expedited": false
}
EOF
```

### Exemplo 2: Remover 1 Validator (Total: 2, Threshold: 2)

```bash
# Manter apenas 2 validators
VALIDATOR_1="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
VALIDATOR_2="f620f5e3d25a3ae848fec74bccae5de3edcd8796"

# Via governance
cat > proposal-remove-solana-validator.json << EOF
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
      "msg": {
        "set_validators": {
          "domain": 1399811150,
          "threshold": 2,
          "validators": [
            "${VALIDATOR_1}",
            "${VALIDATOR_2}"
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Remove validator from Solana Testnet ISM",
  "deposit": "500000uluna",
  "title": "Remove Solana Testnet Validator",
  "summary": "Reduce validators from 3 to 2, maintaining threshold 2",
  "expedited": false
}
EOF
```

### Exemplo 3: Script Automatizado

```bash
#!/bin/bash
# configure-ism-validators.sh

ISM_SOLANA="terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"
KEY_NAME="hypelane-val-testnet"
DOMAIN=1399811150
THRESHOLD=2

# Validadores
VALIDATORS=(
  "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
  "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
  "1f030345963c54ff8229720dd3a711c15c554aeb"
)

# Converter array para formato JSON
VALIDATORS_JSON=$(printf '"%s",' "${VALIDATORS[@]}" | sed 's/,$//')
VALIDATORS_JSON="[${VALIDATORS_JSON}]"

# Criar mensagem
MSG=$(cat <<EOF
{
  "set_validators": {
    "domain": ${DOMAIN},
    "threshold": ${THRESHOLD},
    "validators": ${VALIDATORS_JSON}
  }
}
EOF
)

# Verificar owner primeiro
echo "=== Verificando owner do ISM ==="
OWNER=$(terrad query wasm contract-state smart ${ISM_SOLANA} \
  '{"ownable":{"owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.owner')

echo "Owner atual: ${OWNER}"

# Verificar se é governance
if [ "${OWNER}" = "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n" ]; then
  echo "⚠️  Owner é governance. Criando proposta..."
  
  # Criar proposta
  cat > proposal-ism-validators.json <<PROPOSAL
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "${OWNER}",
      "contract": "${ISM_SOLANA}",
      "msg": ${MSG},
      "funds": []
    }
  ],
  "metadata": "Update Solana Testnet validators",
  "deposit": "500000uluna",
  "title": "Update ISM Solana Validators",
  "summary": "Configure ${#VALIDATORS[@]} validators with threshold ${THRESHOLD}",
  "expedited": false
}
PROPOSAL

  echo "✅ Proposta criada: proposal-ism-validators.json"
  echo "Execute: terrad tx gov submit-proposal proposal-ism-validators.json --from ${KEY_NAME} ..."
else
  echo "✅ Owner não é governance. Executando diretamente..."
  
  # Executar diretamente
  terrad tx wasm execute ${ISM_SOLANA} "${MSG}" \
    --from ${KEY_NAME} \
    --keyring-backend file \
    --chain-id "rebel-2" \
    --node "https://rpc.luncblaze.com:443" \
    --gas auto \
    --gas-adjustment 1.5 \
    --fees 12000000uluna \
    --yes
fi
```

---

## Resumo

### Quando Usar Cada Método

| Situação | Método | Comando |
|----------|--------|---------|
| **Você é o owner** | Direto | `terrad tx wasm execute` |
| **Owner é governance** | Governance | `terrad tx gov submit-proposal` |
| **Quer transferir ownership** | Direto ou Governance | `ownable.transfer_ownership` |

### Endereços Importantes

- **ISM Multisig Solana Testnet**: `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a`
- **Governance Module**: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`
- **Domain Solana Testnet**: `1399811150`

### Formato dos Validadores

- **Tipo**: Hexadecimal (sem `0x`)
- **Tamanho**: Exatamente 20 bytes (40 caracteres hex)
- **Exemplo**: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`

---

## Referências

- [Código Fonte ISM Multisig](../../contracts/isms/multisig/src/contract.rs)
- [GOVERNANCE-OPERATIONS-TESTNET.md](./GOVERNANCE-OPERATIONS-TESTNET.md)
- [Hyperlane Ownable Pattern](https://docs.hyperlane.xyz/docs/protocol/core/security-modules)

