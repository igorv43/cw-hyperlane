# Inicializar Token Sintético Solana Manualmente

## Problema

Quando você usa `foreignDeployment` no `token-config.json`, o código do `hyperlane-sealevel-client` **não inicializa** o token sintético, assumindo que tudo já foi feito em outro lugar.

Mas no seu caso, você só fez o deploy do programa (`5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`), mas ainda precisa **inicializar o token sintético**.

## Solução: Remover `foreignDeployment` Temporariamente

Para inicializar o token, você precisa remover o `foreignDeployment` do `token-config.json` temporariamente, executar o deploy, e depois pode adicionar de volta se necessário.

### Passo 1: Remover `foreignDeployment`

Edite o arquivo `~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/token-config.json`:

```json
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0"
  }
}
```

**⚠️ IMPORTANTE**: Remova a linha `"foreignDeployment": "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"`

### Passo 2: Criar `program-ids.json` Manualmente

Como você já tem o Program ID, crie o arquivo manualmente:

```bash
mkdir -p ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana
cat > ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/program-ids.json << 'EOF'
{
  "solanatestnet": {
    "hex": "0x3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d",
    "base58": "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
  }
}
EOF
```

### Passo 3: Executar o Deploy

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

### Passo 4: Resultado Esperado

Agora o comando deve:
1. ✅ Ler o `program-ids.json` e encontrar o Program ID existente
2. ✅ Verificar que o programa existe na blockchain
3. ✅ **Inicializar o token sintético** (criar o PDA do token)
4. ✅ Criar o Mint Account e configurar o Mint Authority
5. ✅ Mostrar mensagens como "Initializing Warp Route program..."

### Passo 5: Verificar Inicialização

Após a execução, você deve ver mensagens como:
- "Initializing Warp Route program: domain_id: ..."
- "Warp route token initialized successfully"
- Informações sobre o Mint Account

## Nota

O `program-ids.json` faz com que o código use o Program ID existente em vez de tentar fazer um novo deploy. Mas sem `foreignDeployment`, o código ainda processa o chain e inicializa o token.

