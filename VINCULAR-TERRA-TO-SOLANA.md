# Vincular Terra Classic → Solana Warp Route

Este guia mostra como vincular o warp route da Solana como um remote router no contrato warp route do Terra Classic.

## Visão Geral

Após fazer o deploy dos warp routes tanto no Terra Classic quanto na Solana, você precisa vinculá-los bidirecionalmente:
1. **Terra Classic → Solana** (este guia)
2. **Solana → Terra Classic** (já feito - veja [VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md))

## Pré-requisitos

- Warp route Terra Classic: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` (wwwwlunc)
- Program ID do warp route Solana: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- Domain Solana: `1399811150` (Solana Testnet)
- Conta Terra Classic com permissões de owner (owner do contrato warp route Terra Classic)

## Passo 1: Converter Solana Program ID para Formato Hex

O Program ID da Solana (base58) precisa ser convertido para formato hex de 32 bytes para o contrato Terra Classic.

**Solana Program ID (base58):**
```
5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x
```

**Hex Convertido (32 bytes, sem prefixo 0x):**
```
3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d
```

### Como Converter

#### Método 1: Usando Python (Recomendado)

```bash
python3 << EOF
import base58
import binascii

solana_address = "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
# Pad to 64 characters (32 bytes)
hex_padded = hex_address.zfill(64)
print(f"Hex (32 bytes, sem 0x): {hex_padded}")
EOF
```

**Saída esperada:**
```
Hex (32 bytes, sem 0x): 3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d
```

#### Método 2: Usando Node.js

```bash
node -e "
const bs58 = require('bs58');
const solanaAddress = '5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x';
const decoded = bs58.decode(solanaAddress);
const hex = Buffer.from(decoded).toString('hex');
const padded = hex.padStart(64, '0');
console.log('Hex (32 bytes, sem 0x):', padded);
"
```

**Nota**: Você pode precisar instalar `bs58`: `npm install bs58`

## Passo 2: Vincular Remote Router no Terra Classic

No Terra Classic, vincule o warp route da Solana como um remote router usando `terrad`:

```bash
# Variáveis
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
SOLANA_WARP_HEX="3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"

# Vincular remote router (set route)
terrad tx wasm execute "$TERRA_WARP" \
  "{\"router\":{\"set_route\":{\"set\":{\"domain\":$SOLANA_DOMAIN,\"route\":\"$SOLANA_WARP_HEX\"}}}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**⚠️ IMPORTANTE**: 
- O parâmetro `router` deve ter **exatamente 64 caracteres hex** (32 bytes), **sem** o prefixo `0x`
- O domain para Solana Testnet é `1399811150`
- Certifique-se de ter `uluna` suficiente para as taxas (12,000,000 uluna = 0.012 LUNC)

**Saída esperada:**
```
code: 0
txhash: <TRANSACTION_HASH>
```

## Passo 3: Verificar Vinculação

Após a execução, verifique se o router foi vinculado:

```bash
# Consultar o router vinculado para o domain 1399811150
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Saída esperada:**
```json
{
  "data": {
    "route": "3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"
  }
}
```

Ou consultar todas as rotas:

```bash
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"list_routes":{}}}' \
  --node "https://rpc.luncblaze.com:443"
```

## Referência Completa de Comandos

### Comando Completo (Uma linha)

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml" && \
SOLANA_DOMAIN="1399811150" && \
SOLANA_WARP_HEX="3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d" && \
terrad tx wasm execute "$TERRA_WARP" \
  "{\"enroll_remote_router\":{\"domain\":$SOLANA_DOMAIN,\"router\":\"$SOLANA_WARP_HEX\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### Usando Script

Use o script automatizado:

```bash
./script/link-terra-to-solana.sh
```

## Assinatura da Função

A função `router.set_route` no contrato warp route do Terra Classic:

```json
{
  "router": {
    "set_route": {
      "set": {
        "domain": 1399811150,
        "route": "3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"
      }
    }
  }
}
```

**Parâmetros:**
- `domain`: Domain ID da Solana (1399811150)
- `router`: Program ID da Solana em formato hex (32 bytes, 64 caracteres hex, sem prefixo 0x)

## Notas Importantes

1. **Domain ID**: O domain da Solana Testnet é `1399811150` (conforme sua configuração)
2. **Formato de Endereço**: O Program ID da Solana deve ser:
   - Convertido de base58 para hex
   - Preenchido para 64 caracteres (32 bytes)
   - Fornecido **sem** o prefixo `0x` na mensagem JSON
3. **Ownership**: A conta que executa a transação deve ser a owner do contrato warp route Terra Classic
4. **Bidirecional**: Após vincular no Terra Classic, certifique-se de que Solana → Terra Classic também está vinculado (veja [VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md))

## Troubleshooting

### Erro: "insufficient funds"

**Problema**: Sua conta não tem `uluna` suficiente para as taxas.

**Solução**: Verifique seu saldo e ajuste as taxas:
```bash
terrad query bank balances $(terrad keys show hypelane-val-testnet -a --keyring-backend file) \
  --node "https://rpc.luncblaze.com:443"
```

Se necessário, reduza as taxas (mínimo recomendado: 1000000uluna):
```bash
--fees 1000000uluna
```

### Erro: "unauthorized"

**Problema**: Sua conta não é a owner do contrato warp route.

**Solução**: Verifique a ownership:
```bash
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"owner":{}}' \
  --node "https://rpc.luncblaze.com:443"
```

### Erro: "invalid router format"

**Problema**: O formato do endereço router está incorreto.

**Solução**: 
- Certifique-se de que a string hex tem exatamente 64 caracteres (32 bytes)
- Remova o prefixo `0x` se estiver presente
- Verifique se a conversão de base58 para hex está correta

### Erro: "route already exists"

**Problema**: A rota para este domain já está vinculada.

**Solução**: Isso não é um erro - a rota já está configurada. Você pode verificar com:
```bash
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

## Próximos Passos

Após vincular com sucesso o remote router:

1. **Verificar se ambas as direções estão vinculadas:**
   - Terra Classic → Solana: Verificar rota no Terra Classic (este guia)
   - Solana → Terra Classic: Verificar vinculação do router na Solana (veja [VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md))

2. **Testar transferência cross-chain:**
   - Transferir de Terra Classic para Solana
   - Transferir de Solana para Terra Classic

## Referências

- [VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md) - Vinculação Solana → Terra Classic
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Guia completo Terra Classic ↔ Solana
- [LINK-ULUNA-WARP-BSC.md](./LINK-ULUNA-WARP-BSC.md) - Exemplo de vinculação BSC

