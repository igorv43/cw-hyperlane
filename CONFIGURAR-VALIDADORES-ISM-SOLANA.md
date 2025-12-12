# Guia: Configurar Validadores no ISM da Solana

Este guia explica como configurar validadores no **ISM Multisig Message ID da Solana** para validar mensagens vindas do Terra Classic (domain 1325).

## Índice

1. [Entendendo o ISM na Solana](#entendendo-o-ism-na-solana)
2. [Pré-requisitos](#pré-requisitos)
3. [Verificar ISM Atual](#verificar-ism-atual)
4. [Configurar Validadores](#configurar-validadores)
5. [Verificar Configuração](#verificar-configuração)
6. [Exemplos Práticos](#exemplos-práticos)

---

## Entendendo o ISM na Solana

### Arquitetura

Na Solana, o ISM Multisig Message ID é um **programa Solana separado** que:

1. **Valida mensagens**: Verifica assinaturas de validadores para mensagens de um domain específico
2. **Configuração por Domain**: Cada domain (ex: 1325 para Terra Classic) tem sua própria configuração de validadores
3. **Owner pode configurar**: O owner do ISM pode configurar validadores diretamente

### Fluxo

```
Mensagem do Terra Classic (domain 1325) 
  → Mailbox Solana 
  → ISM Multisig Message ID 
  → Verifica se tem threshold de assinaturas dos validadores configurados
  → Aprova ou rejeita a mensagem
```

---

## Pré-requisitos

1. **Program ID do ISM**: O endereço do programa ISM Multisig Message ID na Solana
2. **Keypair do Owner**: O keypair que é owner do ISM (usado no deploy)
3. **Validadores**: Lista de endereços hexadecimais (H160, 20 bytes) dos validadores
4. **Domain**: O domain ID da chain de origem (1325 para Terra Classic Testnet)

### Obter Program ID do ISM

O ISM Multisig Message ID padrão na Solana Testnet geralmente é:

```
4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k
```

Você pode verificar no Hyperlane Registry ou no explorer da Solana.

---

## Verificar ISM Atual

### 1. Verificar Configuração de um Domain

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Program ID do ISM Multisig Message ID
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"

# Domain do Terra Classic Testnet
DOMAIN=1325

# Verificar configuração atual
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
  --url https://api.testnet.solana.com
```

**Saída esperada:**
```
Querying domain data for origin domain: 1325
Domain data for 1325:
DomainDataAccount {
    validators: [...],
    threshold: 1,
}
```

### 2. Verificar Owner do ISM

```bash
# Verificar owner (precisa consultar a conta do programa)
solana account ${ISM_PROGRAM_ID} --url https://api.testnet.solana.com --output json | jq
```

---

## Configurar Validadores

### Comando Principal

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325  # Terra Classic Testnet
THRESHOLD=2

# Validadores (endereços hex de 20 bytes, sem 0x)
VALIDATOR_1="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
VALIDATOR_2="f620f5e3d25a3ae848fec74bccae5de3edcd8796"

# Configurar validadores
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators ${VALIDATOR_1},${VALIDATOR_2} \
  --threshold ${THRESHOLD} \
  --url https://api.testnet.solana.com
```

### Formato dos Validadores

- **Tipo**: `H160` (endereço Ethereum de 20 bytes)
- **Formato**: Hexadecimal sem `0x`
- **Tamanho**: Exatamente 40 caracteres hex (20 bytes)
- **Exemplo**: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`

### Parâmetros

| Parâmetro | Descrição | Exemplo |
|-----------|-----------|---------|
| `--program-id` | Program ID do ISM Multisig Message ID | `4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k` |
| `--domain` | Domain ID da chain de origem | `1325` (Terra Classic Testnet) |
| `--validators` | Lista de validadores separados por vírgula | `validator1,validator2,validator3` |
| `--threshold` | Número mínimo de assinaturas necessárias | `2` (2 de 2 validadores) |

---

## Verificar Configuração

### Após Configurar

```bash
# Verificar se os validadores foram configurados corretamente
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
  --url https://api.testnet.solana.com
```

**Saída esperada:**
```
Querying domain data for origin domain: 1325
Domain data for 1325:
DomainDataAccount {
    validators: [
        "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
        "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
    ],
    threshold: 2,
}
```

---

## Exemplos Práticos

### Exemplo 1: Configurar 2 Validadores com Threshold 2

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325
THRESHOLD=2

VALIDATOR_1="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
VALIDATOR_2="f620f5e3d25a3ae848fec74bccae5de3edcd8796"

cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators ${VALIDATOR_1},${VALIDATOR_2} \
  --threshold ${THRESHOLD} \
  --url https://api.testnet.solana.com
```

### Exemplo 2: Configurar 3 Validadores com Threshold 2

```bash
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325
THRESHOLD=2

VALIDATOR_1="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
VALIDATOR_2="f620f5e3d25a3ae848fec74bccae5de3edcd8796"
VALIDATOR_3="1f030345963c54ff8229720dd3a711c15c554aeb"

cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators ${VALIDATOR_1},${VALIDATOR_2},${VALIDATOR_3} \
  --threshold ${THRESHOLD} \
  --url https://api.testnet.solana.com
```

### Exemplo 3: Script Automatizado

```bash
#!/bin/bash
# configure-ism-validators-solana.sh

# Configurações
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325  # Terra Classic Testnet
THRESHOLD=2

# Validadores
VALIDATORS=(
  "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
  "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
)

# Converter array para formato separado por vírgula
VALIDATORS_STR=$(IFS=','; echo "${VALIDATORS[*]}")

echo "=== Configurando Validadores no ISM da Solana ==="
echo "Program ID: ${ISM_PROGRAM_ID}"
echo "Domain: ${DOMAIN} (Terra Classic Testnet)"
echo "Threshold: ${THRESHOLD}"
echo "Validators: ${VALIDATORS_STR}"
echo ""

cd ~/hyperlane-monorepo/rust/sealevel/client

# Configurar validadores
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators ${VALIDATORS_STR} \
  --threshold ${THRESHOLD} \
  --url https://api.testnet.solana.com

echo ""
echo "=== Verificando Configuração ==="

# Verificar configuração
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
  --url https://api.testnet.solana.com
```

---

## Troubleshooting

### Erro: "Owner not signer"

**Problema**: Você não é o owner do ISM.

**Solução**: Use o keypair que foi usado no deploy do ISM (o owner).

```bash
# Verificar se você é o owner
# (precisa consultar a conta do programa ISM)
```

### Erro: "Invalid validator address"

**Problema**: O endereço do validator não está no formato correto.

**Solução**: 
- Use endereços hexadecimais de exatamente 20 bytes (40 caracteres)
- Não inclua `0x` no início
- Exemplo correto: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`

### Erro: "Threshold greater than validators count"

**Problema**: O threshold é maior que o número de validadores.

**Solução**: O threshold deve ser `<= número de validadores`. Exemplo:
- 2 validadores → threshold máximo: 2
- 3 validadores → threshold máximo: 3

### Erro: "Program account not found"

**Problema**: O Program ID do ISM não existe ou está incorreto.

**Solução**: Verifique se o ISM foi deployado:

```bash
solana program show ${ISM_PROGRAM_ID} --url https://api.testnet.solana.com
```

---

## Comparação: Terra Classic vs Solana

| Aspecto | Terra Classic | Solana |
|---------|---------------|--------|
| **Comando** | `terrad tx wasm execute` | `cargo run -- ism multisig-message-id set-validators-and-threshold` |
| **Formato Validators** | Array JSON de strings hex | Lista separada por vírgula |
| **Owner** | Owner do contrato ISM | Owner do programa ISM |
| **Domain** | Mesmo formato (1325) | Mesmo formato (1325) |
| **Threshold** | Mesmo formato (número) | Mesmo formato (número) |

### Exemplo Terra Classic

```bash
terrad tx wasm execute ${ISM_ADDRESS} \
  '{"set_validators":{"domain":1325,"threshold":2,"validators":["242d8a855a8c932dec51f7999ae7d1e48b10c95e","f620f5e3d25a3ae848fec74bccae5de3edcd8796"]}}' \
  --from owner \
  --yes
```

### Exemplo Solana

```bash
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain 1325 \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e,f620f5e3d25a3ae848fec74bccae5de3edcd8796 \
  --threshold 2 \
  --url https://api.testnet.solana.com
```

---

## Resumo

### Comando Completo

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id 4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k \
  --domain 1325 \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e,f620f5e3d25a3ae848fec74bccae5de3edcd8796 \
  --threshold 2 \
  --url https://api.testnet.solana.com
```

### Parâmetros Obrigatórios

- `--program-id`: Program ID do ISM Multisig Message ID
- `--domain`: Domain ID (1325 para Terra Classic Testnet)
- `--validators`: Lista de validadores separados por vírgula
- `--threshold`: Número mínimo de assinaturas

### Verificação

```bash
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains 1325 \
  --url https://api.testnet.solana.com
```

---

## Referências

- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)
- [WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)
- [CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md)

