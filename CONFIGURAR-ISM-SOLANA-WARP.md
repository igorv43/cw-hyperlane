# Guia: Configurar ISM no Warp Route da Solana

Este guia explica como configurar o Interchain Security Module (ISM) no **warp route da Solana**, permitindo que o warp route use um ISM específico para validar mensagens vindas do Terra Classic.

## Índice

1. [Entendendo o ISM na Solana](#entendendo-o-ism-na-solana)
2. [Verificar ISM Atual do Warp Route](#verificar-ism-atual-do-warp-route)
3. [Configurar ISM no Warp Route](#configurar-ism-no-warp-route)
4. [ISM na Solana vs Terra Classic](#ism-na-solana-vs-terra-classic)
5. [Troubleshooting](#troubleshooting)

---

## Entendendo o ISM na Solana

### Arquitetura

Na Solana, o ISM funciona de forma diferente:

1. **ISM é um Programa Solana**: O ISM é um programa Sealevel separado (como `multisig-ism-message-id`)
2. **Warp Route pode usar ISM**: O warp route pode configurar qual ISM usar via função `SetInterchainSecurityModule`
3. **ISM Padrão**: Se não configurado, o warp route usa o ISM padrão do Mailbox da Solana

### Fluxo de Validação

```
Mensagem do Terra Classic → Mailbox Solana → ISM (configurado no warp route) → Valida assinaturas → Warp Route processa
```

---

## Verificar ISM Atual do Warp Route

### 1. Usando Solana CLI

```bash
# Program ID do warp route na Solana
WARP_ROUTE_PROGRAM_ID="SEU_PROGRAM_ID_AQUI"

# Verificar dados do token (inclui ISM)
solana account ${WARP_ROUTE_PROGRAM_ID} --url https://api.testnet.solana.com --output json | jq
```

### 2. Usando sealevel client

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Query do ISM atual
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token query \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  synthetic \
  --url https://api.testnet.solana.com
```

**Nota:** O comando `token query` pode não mostrar o ISM diretamente. Você precisará verificar os dados da conta do programa.

---

## Configurar ISM no Warp Route

### Pré-requisitos

1. **Program ID do Warp Route**: O endereço do programa warp route na Solana
2. **Keypair do Owner**: O keypair que é owner do warp route (usado no deploy)
3. **Program ID do ISM (Opcional)**: Se você quiser usar um ISM específico

### Opção 1: Usar ISM Padrão do Mailbox (Recomendado)

Se você não especificar um ISM, o warp route usará o ISM padrão configurado no Mailbox da Solana. Isso é geralmente suficiente.

**Não é necessário fazer nada** - o warp route já usa o ISM padrão automaticamente.

### Opção 2: Configurar ISM Específico

Se você quiser usar um ISM específico (por exemplo, um Multisig ISM Message ID customizado):

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Program ID do warp route
WARP_ROUTE_PROGRAM_ID="SEU_PROGRAM_ID_AQUI"

# Program ID do ISM (Multisig ISM Message ID)
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"  # Exemplo para testnet

# Configurar ISM no warp route
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism ${ISM_PROGRAM_ID} \
  --url https://api.testnet.solana.com
```

### Opção 3: Remover ISM Customizado (Voltar ao Padrão)

Para remover um ISM customizado e voltar a usar o ISM padrão do Mailbox:

```bash
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism None \
  --url https://api.testnet.solana.com
```

---

## ISM na Solana vs Terra Classic

### Comparação

| Aspecto | Terra Classic | Solana |
|---------|---------------|--------|
| **ISM no Deploy** | ✅ Pode configurar via `--ism` flag | ❌ Não há campo no `token-config.json` |
| **ISM Após Deploy** | ✅ Pode configurar via `terrad tx wasm execute` | ✅ Pode configurar via `sealevel client` |
| **ISM Padrão** | Usa ISM do Mailbox se não especificado | Usa ISM do Mailbox se não especificado |
| **Formato ISM** | Endereço Bech32 (Cosmos) | Program ID (Solana Pubkey) |
| **Owner** | Owner do warp route pode configurar | Owner do warp route pode configurar |

### Importante

**Na Solana, o ISM é um programa separado** que precisa ser deployado. Os ISMs comuns na Solana incluem:

- **Multisig ISM Message ID**: Valida mensagens usando assinaturas de múltiplos validadores
- **Test ISM**: Para testes (aceita todas as mensagens)

O ISM padrão do Mailbox na Solana geralmente é um **Multisig ISM Message ID** que já tem validadores configurados.

---

## Configurar Validadores no ISM da Solana

### ⚠️ Importante

Se você usar um ISM customizado (não o padrão do Mailbox), você precisará configurar validadores nesse ISM. Isso é feito no **programa ISM**, não no warp route.

**📖 Guia Completo:** Veja [CONFIGURAR-VALIDADORES-ISM-SOLANA.md](./CONFIGURAR-VALIDADORES-ISM-SOLANA.md) para instruções detalhadas.

### Comando Rápido

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Program ID do ISM Multisig Message ID
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"

# Domain do Terra Classic Testnet
DOMAIN=1325

# Configurar validadores
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e,f620f5e3d25a3ae848fec74bccae5de3edcd8796 \
  --threshold 2 \
  --url https://api.testnet.solana.com
```

### 1. Verificar ISM do Mailbox

O Mailbox da Solana já tem um ISM configurado. Você pode verificar qual ISM o Mailbox usa:

```bash
# Mailbox Program ID (testnet)
MAILBOX_PROGRAM_ID="75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR"

# Verificar ISM padrão do Mailbox
solana account ${MAILBOX_PROGRAM_ID} --url https://api.testnet.solana.com --output json | jq
```

### 2. Configurar Validadores no ISM

O ISM Multisig Message ID na Solana permite configurar validadores por domain:

```bash
# Verificar configuração atual
cargo run -- \
  -k ~/solana-ism-owner-key.json \
  ism multisig-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
  --url https://api.testnet.solana.com
```

**Nota:** O processo completo está documentado em [CONFIGURAR-VALIDADORES-ISM-SOLANA.md](./CONFIGURAR-VALIDADORES-ISM-SOLANA.md).

---

## Troubleshooting

### Erro: "Owner not signer"

**Problema**: Você não é o owner do warp route.

**Solução**: Use o keypair que foi usado no deploy do warp route (o owner).

```bash
# Verificar owner do warp route
# (precisa consultar os dados da conta do programa)
```

### Erro: "Invalid ISM program ID"

**Problema**: O Program ID do ISM não existe ou não é um ISM válido.

**Solução**: Verifique se o ISM foi deployado corretamente:

```bash
# Verificar se o programa existe
solana program show ${ISM_PROGRAM_ID} --url https://api.testnet.solana.com
```

### Erro: "ISM not found"

**Problema**: O ISM especificado não está configurado no Mailbox.

**Solução**: Use `None` para usar o ISM padrão do Mailbox:

```bash
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism None \
  --url https://api.testnet.solana.com
```

### Como Verificar se Funcionou

```bash
# 1. Verificar transação
solana confirm -v ${TRANSACTION_SIGNATURE} --url https://api.testnet.solana.com

# 2. Verificar dados do programa (se possível)
solana account ${WARP_ROUTE_PROGRAM_ID} --url https://api.testnet.solana.com --output json | jq
```

---

## Resumo

### Comandos Principais

```bash
# 1. Configurar ISM específico
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism ${ISM_PROGRAM_ID} \
  --url https://api.testnet.solana.com

# 2. Remover ISM customizado (usar padrão)
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism None \
  --url https://api.testnet.solana.com
```

### Recomendação

**Para a maioria dos casos, não é necessário configurar um ISM customizado.** O ISM padrão do Mailbox da Solana já está configurado e funcionando. Apenas configure um ISM customizado se você tiver requisitos específicos de segurança.

---

## Referências

- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)
- [WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)
- [Hyperlane Solana Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)

