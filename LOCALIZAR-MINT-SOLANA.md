# Como Localizar o Mint Account do Warp Route na Solana

Este guia mostra como encontrar o mint account (endereço do token) do warp route sintético na Solana Testnet.

## Mint Account do Warp Route LUNC → Solana

**Mint Account**: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`

**Explorer**: [Ver no Solana Explorer](https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet)

---

## Métodos para Localizar o Mint Account

### Método 1: Usando `hyperlane-sealevel-client` (Recomendado)

O comando `token query synthetic` retorna todas as informações do warp route, incluindo o mint account.

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"

# Query do token sintético
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic
```

**Saída esperada:**
```json
{
  "mint": "DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA",
  "mint_bump": 255,
  "decimals": 6,
  "name": "Luna Classic",
  "symbol": "wwwwLUNC",
  "total_supply": "0",
  ...
}
```

**Extrair apenas o mint:**
```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic | jq -r '.mint'
```

**Output:**
```
DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
```

---

### Método 2: Verificar no Output do Deploy

Quando você executa `warp-route deploy`, o mint account é exibido no output (se o token for criado pela primeira vez):

```bash
# Durante o deploy inicial, você verá:
Creating token DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA ...
Address: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Decimals: 6
```

**⚠️ Nota**: Se o token já existir, o output mostrará `Warp route token already exists, skipping init` e não exibirá o mint account. Nesse caso, use o Método 1.

---

### Método 3: Usando `spl-token` CLI

Se você tem o Program ID do warp route, pode derivar o mint account usando o PDA (Program Derived Address):

```bash
# Instalar spl-token CLI (se ainda não tiver)
cargo install spl-token-cli

# Verificar informações do mint
MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"

spl-token supply "$MINT_ACCOUNT" --url https://api.testnet.solana.com
spl-token display "$MINT_ACCOUNT" --url https://api.testnet.solana.com
```

**Output esperado:**
```
Supply: 0
Decimals: 6
```

---

### Método 4: Usando Solana CLI

```bash
# Verificar a conta do mint
MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"

solana account "$MINT_ACCOUNT" \
  --url https://api.testnet.solana.com \
  --output json | jq
```

**Output esperado:**
```json
{
  "account": {
    "data": [...],
    "executable": false,
    "lamports": 1461600,
    "owner": "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
    "rentEpoch": 18446744073709551615
  }
}
```

**Nota**: O `owner` deve ser `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` (Token-2022 Program) para tokens sintéticos.

---

### Método 5: Verificar no Solana Explorer

1. Acesse: https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet
2. Verifique as informações:
   - **Account Type**: Token Mint
   - **Mint Authority**: O próprio mint account (self-custody)
   - **Supply**: 0 (inicial)
   - **Decimals**: 6

---

## Script para Extrair o Mint Account

Crie um script para facilitar:

```bash
#!/bin/bash
# Script: get-mint-account.sh

KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"

cd ~/hyperlane-monorepo/rust/sealevel/client

echo "🔍 Buscando mint account do warp route..."
echo ""

MINT_ACCOUNT=$(cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic 2>/dev/null | jq -r '.mint')

if [ -z "$MINT_ACCOUNT" ] || [ "$MINT_ACCOUNT" = "null" ]; then
  echo "❌ Erro: Não foi possível encontrar o mint account"
  exit 1
fi

echo "✅ Mint Account encontrado:"
echo "   $MINT_ACCOUNT"
echo ""
echo "🔗 Links úteis:"
echo "   Explorer: https://explorer.solana.com/address/$MINT_ACCOUNT?cluster=testnet"
echo ""
echo "📋 Informações completas:"
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic | jq
```

**Uso:**
```bash
chmod +x get-mint-account.sh
./get-mint-account.sh
```

---

## Verificar Informações do Mint

### 1. Supply (Quantidade Total)

```bash
MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"

spl-token supply "$MINT_ACCOUNT" --url https://api.testnet.solana.com
```

### 2. Metadata (Nome, Símbolo, etc.)

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x" \
  synthetic | jq '{name, symbol, decimals, total_supply, mint}'
```

**Output:**
```json
{
  "name": "Luna Classic",
  "symbol": "wwwwLUNC",
  "decimals": 6,
  "total_supply": "0",
  "mint": "DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"
}
```

### 3. Verificar no Explorer

Acesse o link direto:
- **Testnet**: https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet

---

## Informações do Mint Account Atual

| Propriedade | Valor |
|------------|-------|
| **Mint Address** | `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA` |
| **Name** | Luna Classic |
| **Symbol** | wwwwLUNC |
| **Decimals** | 6 |
| **Total Supply** | 0 (inicial) |
| **Mint Authority** | Self (o próprio mint account) |
| **Program** | Token-2022 (`TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`) |
| **Warp Route Program ID** | `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x` |

---

## Troubleshooting

### Erro: "Failed to query token"

**Causa**: O warp route pode não estar inicializado ou o Program ID está incorreto.

**Solução**:
1. Verifique se o Program ID está correto:
   ```bash
   solana program show 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x --url https://api.testnet.solana.com
   ```

2. Verifique se o token foi inicializado:
   ```bash
   # Se o token não foi inicializado, execute o deploy novamente
   cd ~/hyperlane-monorepo/rust/sealevel/client
   cargo run -- -k "$KEYPAIR" -u https://api.testnet.solana.com warp-route deploy ...
   ```

### Erro: "Account not found"

**Causa**: O mint account pode não existir ou o endereço está incorreto.

**Solução**: Use o Método 1 para obter o mint account correto do warp route.

---

## Referências

- [Solana Explorer - Mint Account](https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet)
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Guia completo do warp route
- [Hyperlane Solana Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)

