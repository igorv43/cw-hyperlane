# 📋 Script: Adicionar ISM Sepolia ao ISM Routing

## 🎯 Objetivo

Este script executa **apenas** a inclusão do ISM Sepolia no contrato ISM Routing (linhas 160-173 do `submit-proposal-sepolia.ts`) e permite consultar todos os ISMs configurados.

---

## 📋 Funcionalidades

1. ✅ **Query de todos os ISMs configurados** - Lista todos os ISMs já configurados no contrato
2. ✅ **Adicionar ISM Sepolia** - Executa a mensagem para adicionar Sepolia ao ISM Routing

---

## 🚀 Como Usar

### 1. Query apenas (modo padrão)

Para apenas consultar os ISMs configurados:

```bash
# Definir chave privada (necessária para conectar, mas não executa transação)
export PRIVATE_KEY='0xSUA_CHAVE_PRIVADA'
# ou
export TERRA_PRIVATE_KEY='0xSUA_CHAVE_PRIVADA'

# Executar query
npx tsx script/add-ism-sepolia-sepolia.ts
```

**Ou sem chave privada (apenas query):**

```bash
# Modificar o script temporariamente para usar apenas CosmWasmClient
# Ou usar terrad diretamente:
terrad query wasm contract-state smart terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh \
  '{"router":{"list_isms":{}}}' \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq '.'
```

### 2. Executar adição do ISM Sepolia

Para adicionar o ISM Sepolia ao ISM Routing:

```bash
# 1. Definir chave privada
export PRIVATE_KEY='0xSUA_CHAVE_PRIVADA'
# ou
export TERRA_PRIVATE_KEY='0xSUA_CHAVE_PRIVADA'

# 2. Definir endereço do ISM Multisig Sepolia
export ISM_MULTISIG_SEPOLIA='terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa'

# 3. Executar com modo execute
MODE=execute npx tsx script/add-ism-sepolia-sepolia.ts
```

**Ou:**

```bash
MODE=add npx tsx script/add-ism-sepolia-sepolia.ts
```

---

## ⚙️ Configuração

### Variáveis de Ambiente

```bash
# Obrigatório para executar transações
PRIVATE_KEY='0x...'              # Chave privada hex (sem 0x)
# ou
TERRA_PRIVATE_KEY='0x...'         # Mesmo que PRIVATE_KEY

# Obrigatório para adicionar ISM
ISM_MULTISIG_SEPOLIA='terra1...' # Endereço do ISM Multisig Sepolia

# Opcional
MODE='query'                      # Modo: 'query' (padrão) ou 'execute'/'add'
```

### Endereços no Script

```typescript
const ISM_ROUTING = "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh";
const ISM_MULTISIG_SEPOLIA = process.env.ISM_MULTISIG_SEPOLIA || "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa";
const DOMAIN_SEPOLIA = 11155111;
```

---

## 📊 O que o Script Faz

### Modo Query (padrão)

1. Conecta ao node Terra Classic
2. Consulta o contrato ISM Routing
3. Lista todos os ISMs configurados
4. Verifica se Sepolia já está configurado
5. Mostra informações de cada ISM (domain, address, chain name)

### Modo Execute

1. Executa todas as etapas do modo Query
2. Executa a transação para adicionar ISM Sepolia
3. Aguarda confirmação (5 segundos)
4. Consulta novamente para verificar se foi adicionado

---

## 📋 Exemplo de Saída

### Query Mode

```
================================================================================
📋 QUERYING ALL ISMs CONFIGURED IN ISM ROUTING
================================================================================

Querying ISM Routing contract...
Contract: terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh
Query: {
  "router": {
    "list_isms": {}
  }
}

✅ QUERY SUCCESSFUL!
────────────────────────────────────────────────────────────────────────────────

📊 Total ISMs configured: 2

📋 CONFIGURED ISMs:
────────────────────────────────────────────────────────────────────────────────

[1] Domain: 97
    ISM Address: terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv
    Chain: BSC Testnet

[2] Domain: 1399811150
    ISM Address: terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a
    Chain: Solana Testnet

⚠️  Sepolia ISM is NOT configured yet.
   You need to add it using this script.
```

### Execute Mode

```
================================================================================
🚀 ADDING SEPOLIA ISM TO ISM ROUTING
================================================================================

📋 EXECUTION MESSAGE:
────────────────────────────────────────────────────────────────────────────────
Contract: terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh
Domain: 11155111 (Sepolia Testnet)
ISM Multisig: terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa

Message: {
  "router": {
    "set_ism": {
      "set": {
        "domain": 11155111,
        "ism": "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa"
      }
    }
  }
}

Executing transaction...

✅ SUCCESS!
────────────────────────────────────────────────────────────────────────────────
  • TX Hash: ABC123...
  • Gas used: 123456
  • Height: 12345

💡 Next steps:
  1. Wait for transaction confirmation
  2. Query ISMs again to verify Sepolia was added
  3. Test cross-chain message sending from Sepolia
```

---

## 🔍 Query Manual (Alternativa)

Se preferir usar `terrad` diretamente:

```bash
# Query todos os ISMs
terrad query wasm contract-state smart terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh \
  '{"router":{"list_isms":{}}}' \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq '.data'

# Ou formatado
terrad query wasm contract-state smart terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh \
  '{"router":{"list_isms":{}}}' \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq '.data.isms[] | {domain: .domain, ism: .ism}'
```

---

## ⚠️ Importante

1. **ISM Multisig Sepolia deve estar deployado** antes de adicionar ao ISM Routing
2. **Chave privada** deve ter permissões para executar no contrato ISM Routing
3. **Verifique o endereço** do ISM Multisig Sepolia antes de executar

---

## 🐛 Troubleshooting

### Erro: "ISM_MULTISIG_SEPOLIA not set correctly"
**Solução:** Defina a variável de ambiente:
```bash
export ISM_MULTISIG_SEPOLIA='terra1...'
```

### Erro: "PRIVATE_KEY not set"
**Solução:** Defina a chave privada:
```bash
export PRIVATE_KEY='0x...'
```

### Erro na query: "Query failed"
**Solução:** Tente a query manual com `terrad` ou verifique se o contrato está correto.

### ISM já configurado
**Solução:** O script detecta automaticamente se Sepolia já está configurado e informa.

---

## 📝 Diferença do Script Original

Este script é uma versão simplificada que executa **apenas** a mensagem 4 do `submit-proposal-sepolia.ts`:

**Original (`submit-proposal-sepolia.ts`):**
- 4 mensagens (validators, IGP Oracle, IGP Routes, ISM Routing)
- Modo governance proposal
- Modo direct execution

**Este script (`add-ism-sepolia-sepolia.ts`):**
- 1 mensagem (ISM Routing apenas)
- Query de todos os ISMs configurados
- Modo query (padrão) ou execute

---

## ✅ Checklist

Antes de executar:

- [ ] ISM Multisig Sepolia está deployado
- [ ] Endereço do ISM Multisig Sepolia está correto
- [ ] Chave privada configurada (se for executar)
- [ ] Node RPC está acessível
- [ ] Verificou os ISMs atuais (query mode)

---

**Última atualização:** 2026-02-03  
**Network:** Terra Classic Testnet  
**Script:** `add-ism-sepolia-sepolia.ts`
