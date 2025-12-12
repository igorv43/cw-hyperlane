# Correção: Erro `--use-rpc` no Deploy Solana

## Problema

Ao executar `warp-route deploy` no Solana, o comando falha com:

```
error: Found argument '--use-rpc' which wasn't expected, or isn't valid in this context
```

Isso ocorre porque o Solana CLI 1.14.20 não suporta a flag `--use-rpc` que o código do `hyperlane-sealevel-client` está tentando usar.

## Solução: Usar `foreignDeployment`

Como você já fez o deploy do programa com o Program ID `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`, use `foreignDeployment` no `token-config.json` para evitar que o código tente fazer um novo deploy.

### 1. Atualizar `token-config.json`

Edite o arquivo `~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/token-config.json`:

```json
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0",
    "foreignDeployment": "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
  }
}
```

### 2. Executar o Deploy

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name lunc-solana \
  --environment testnet \
  --environments-dir ../environments \
  --token-config-file ../environments/testnet/warp-routes/lunc-solana/token-config.json \
  --built-so-dir ../target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 10000000
```

### 3. Resultado Esperado

O comando irá:
1. ✅ Reconhecer o `foreignDeployment` e não tentar fazer deploy
2. ✅ Criar o arquivo `program-ids.json` com o Program ID existente
3. ✅ Inicializar o token sintético usando o Program ID existente

## Nota

O `foreignDeployment` informa ao `hyperlane-sealevel-client` que o programa já foi deployado em outro lugar (ou manualmente) e deve usar esse Program ID em vez de tentar fazer um novo deploy.

