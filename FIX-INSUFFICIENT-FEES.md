# Fix: Insufficient Fees Error

## Erro
```
insufficient fees; got: "1000000uluna", required: "10114660uluna"
```

## Solução

O erro indica que você precisa de pelo menos **10,114,660 uluna** de fees, mas enviou apenas **1,000,000 uluna**.

### Comando Corrigido

Use fees maiores (12,000,000 uluna para ter margem):

```bash
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### Alternativa: Usar Gas Price ao Invés de Fees Fixas

Se preferir usar gas price (mais flexível):

```bash
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --yes
```

### Verificar Saldo

Antes de executar, verifique se você tem saldo suficiente:

```bash
terrad query bank balances terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

Você precisa ter pelo menos **12,000,000 uluna** (0.012 LUNC) para as fees.

## Resumo das Mudanças

- **Fees antigas**: `1000000uluna` (0.001 LUNC)
- **Fees novas**: `12000000uluna` (0.012 LUNC)
- **Mudança**: Aumento de 12x nas fees

## Nota sobre Gas

O gas estimado foi **357,093**, que com o gas price de **28.5uluna** resulta em aproximadamente:
- `357093 * 28.5 = 10,177,150 uluna` (≈ 0.010 LUNC)

Por isso as fees de 12,000,000 uluna são suficientes.

