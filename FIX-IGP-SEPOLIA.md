# Corrigir Erro de Gas Oracle para Sepolia

## Problema

Ao tentar transferir LUNC do Terra Classic para Sepolia, você recebe o erro:

```
Query failed with (6): rpc error: code = Unknown desc = failed to execute message; 
message index: 0: Generic error: Querier contract error: gas oracle not found for 11155111: 
query wasm contract failed: execute wasm contract failed
```

## Causa

O erro ocorre porque o **IGP Router não tem uma rota configurada** para o domain 11155111 (Sepolia). Quando o warp route tenta calcular o custo de gas para a transferência, ele consulta o IGP Router, que por sua vez precisa consultar o IGP Oracle. Como a rota não está configurada, o IGP Router não consegue encontrar o Oracle.

### Por que o erro ocorre?

O erro ocorre porque o IGP Router não tem uma rota configurada para o domain 11155111 (Sepolia). Quando o warp route tenta calcular o custo de gas para a transferência, ele consulta o IGP Router, que por sua vez precisa consultar o IGP Oracle. Como a rota não está configurada, o IGP Router não consegue encontrar o Oracle.

## Diagnóstico

Execute o script de verificação:

```bash
./script/check-igp-sepolia.sh
```

**Problemas encontrados:**
1. ❌ **Rota IGP Router não configurada** para Sepolia (domain 11155111) - **ESTE É O PROBLEMA PRINCIPAL**
2. ✅ **IGP Oracle** já está configurado corretamente (`exchange_rate: 177534`, `gas_price: 1000000000`)

## Solução

### ✅ IMPORTANTE: IGP Router é Controlado pela Sua Wallet

O IGP Router (`terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r`) é controlado pela sua wallet (`terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`). Isso significa que **a configuração da rota pode ser feita diretamente**, sem precisar de governança!

### Solução: Configuração Direta

Você pode configurar a rota diretamente usando o script:

```bash
PRIVATE_KEY="sua_chave_privada" SKIP_CONFIRM="1" ./script/set-igp-route-sepolia.sh
```

Ou usando o script TypeScript diretamente:

```bash
PRIVATE_KEY="sua_chave_privada" npx tsx script/set-igp-route-sepolia.ts
```

**Nota:** Como você é o owner do IGP Router, a transação será executada com sucesso sem precisar de governança.

### Passo 2: Verificar IGP Oracle (Já Configurado ✅)

O IGP Oracle já está configurado corretamente. Você pode verificar:

```bash
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"

terrad query wasm contract-state smart "$IGP_ORACLE" \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Valores já configurados:**
- `exchange_rate`: `177534` (Taxa de câmbio LUNC:ETH)
- `gas_price`: `1000000000` (1 Gwei)

**Nota:** Se você precisar atualizar o IGP Oracle no futuro, use:

```bash
PRIVATE_KEY="sua_chave_privada" npx tsx script/update-igp-oracle-sepolia.ts
```

### Passo 3: Verificar Configuração

Após configurar, verifique novamente:

```bash
./script/check-igp-sepolia.sh
```

**Saída esperada:**
```
✅ Rota IGP configurada: terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds
   ✓ Rota aponta para o IGP Oracle correto
✅ IGP Oracle configurado:
   • Exchange Rate: 177534
   • Gas Price: 1000000000
```

## Verificação Manual

### Verificar Rota IGP Router

```bash
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"

terrad query wasm contract-state smart "$IGP" \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada:**
```json
{
  "data": {
    "route": {
      "domain": 11155111,
      "route": "terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
    }
  }
}
```

### Verificar IGP Oracle

```bash
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"

terrad query wasm contract-state smart "$IGP_ORACLE" \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada:**
```json
{
  "data": {
    "exchange_rate": "177534",
    "gas_price": "1000000000"
  }
}
```

## Endereços dos Contratos (Testnet)

- **IGP Router**: `terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r` (Owner: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`)
- **IGP Oracle**: `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds`
- **Sepolia Domain**: `11155111`

## Após Corrigir

Após configurar a rota IGP, você poderá transferir LUNC do Terra Classic para Sepolia sem o erro de "gas oracle not found".

Tente a transferência novamente:

```bash
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --amount 1000000 \
  --recipient 0xSEU_ENDERECO_SEPOLIA \
  --target-domain 11155111 \
  -n terraclassic
```

## Referências

- [CONFIGURAR-WARP-LUNC-SEPOLIA.md](./CONFIGURAR-WARP-LUNC-SEPOLIA.md) - Documentação completa do setup
- [CHECK-IGP-CONFIG.md](./CHECK-IGP-CONFIG.md) - Guia geral de verificação IGP
