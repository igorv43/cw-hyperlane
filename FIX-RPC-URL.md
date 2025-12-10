# Fix: RPC URL Error

## Erro
```
Error: post failed: Post "https://rpc.luncblaze.com": dial tcp: address rpc.luncblaze.com: missing port in address
```

## Solução

O problema é que a URL do RPC precisa da porta explícita. Use uma das opções abaixo:

### Opção 1: Adicionar porta 443 (HTTPS)

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
  --fees 1000000uluna \
  --yes
```

### Opção 2: Usar URL alternativa (sem porta)

Algumas versões do terrad aceitam sem porta explícita, mas se não funcionar, tente:

```bash
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://terra-classic-rpc.publicnode.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 1000000uluna \
  --yes
```

### Opção 3: Verificar conectividade

Teste se o RPC está acessível:

```bash
# Testar conectividade
curl -s https://rpc.luncblaze.com:443/status | jq .

# Ou testar sem porta (pode funcionar via curl mas não via terrad)
curl -s https://rpc.luncblaze.com/status | jq .
```

## Comando Corrigido Completo

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
  --fees 1000000uluna \
  --yes
```

**Mudança principal:** `--node "https://rpc.luncblaze.com:443"` (adicionado `:443`)

