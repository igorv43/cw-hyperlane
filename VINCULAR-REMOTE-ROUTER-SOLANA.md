# Vincular Remote Router: Solana Testnet → Terra Classic

Este guia mostra como vincular o warp route do Terra Classic como um remote router no programa warp route do Solana Testnet.

## Visão Geral

Após vincular Terra Classic → Solana, você precisa vincular o router do Terra Classic no lado Solana para que a Solana saiba para onde enviar mensagens para o Terra Classic.

**⚠️ IMPORTANTE**: Diferente das chains BSC/EVM, a Solana **NÃO** usa Safe. Você interage diretamente com o programa Solana usando o `hyperlane-sealevel-client`.

## Pré-requisitos

- Program ID do warp route Solana Testnet: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- Warp route Terra Classic: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- Warp route Terra Classic (hex): `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Domain Terra Classic: `1325`
- Keypair Solana com permissões de owner (owner do warp route Solana)

## Passo 1: Converter Endereço Terra Classic para Formato Hex

O endereço bech32 do Terra Classic precisa ser convertido para formato hex de 32 bytes (H256) para o programa Solana.

**Endereço Terra Classic:**
```
terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
```

**Hex Convertido (32 bytes):**
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

### Como Converter

#### Método 1: Usar cw-hpl CLI (Recomendado)

```bash
yarn cw-hpl wallet bech32-to-hex terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
```

**Saída esperada:**
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

#### Método 2: Usar Node.js

```bash
node -e "
const { fromBech32 } = require('@cosmjs/encoding');
const addr = 'terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml';
const { data } = fromBech32(addr);
const hexed = Buffer.from(data).toString('hex');
const padded = hexed.padStart(64, '0');
console.log('Hex (32 bytes):', '0x' + padded);
"
```

**Saída esperada:**
```
Hex (32 bytes): 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

#### Método 3: Usar do Arquivo de Contexto

Se você fez o deploy do warp route usando `cw-hyperlane`, o endereço hex já está no arquivo de contexto:

```bash
# Ler do contexto
cat context/terraclassic.json | jq -r '.deployments.warp.native[] | select(.id == "wwwwlunc") | .hexed'
```

**Saída esperada:**
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

## Passo 2: Vincular Remote Router na Solana

Na Solana, use o `hyperlane-sealevel-client` para vincular o router do Terra Classic:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
TERRA_DOMAIN="1325"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

# Vincular remote router
# ⚠️ IMPORTANTE: domain e router são argumentos POSICIONAIS, não flags
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  "$TERRA_DOMAIN" \
  "$TERRA_WARP_HEX"
```

**⚠️ IMPORTANTE**: 
- As flags `-k` e `-u` são **argumentos globais** e devem vir **ANTES** do subcomando (`token enroll-remote-router`)
- O parâmetro `router` aceita formato H256, que pode ser:
  - Hex com prefixo `0x`: `0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02`
  - Hex sem prefixo `0x`: `0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02`
  - Endereço bech32: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8` (será convertido automaticamente)
  - Endereço base58: (para endereços Solana)

**Saída esperada:**
```
==== Instructions: ====
Instruction 0: Set compute unit limit to 1400000
Instruction 1: No description provided
==== Transaction in base58: ====
XA722NZHBfvS3g781s13SZ1rEZw8HdutpDsbKV6c8KKLMLivQNc75pdvPQibxFkfGZkZNg3dTaikQFsezB7VAZkhxXg9Wir5rJroeTUmVEpV8ktopNZY6DzJqBYE2Vc9m3NVBD9KDCqysVY772teyH9sYUKZhrh1BBV21UV19L3JGGG2HBGs9eYmzkYesir8V4E7Ybe5ohabah3SbrkBmKB9kjjZB2S4YPtf24PSvT1XN6i5brxRpJEib79QV7ifw3oaNJ1qHbVqWLgJ7KrLiWbig7X7g5KvgWXbYtLjmezuvZ5GtsmwXWg72T3AunjDdSg9ARo8UjNpuKBemwZCb82FhVN7KA6YeDhtsy87Aoj6ppLaQrufmLt2zZQKTK9fpkdVzciDDQtJoZ3GvJ5uGYwwKv71iqydeg683nnwxXxxAfx8yUxXoEQ94oge

==== Message in base58: ====
2LRrjv43KXgzLXGnctLbk3SF1xbwBSC29kDz7k3fsHGybmoK4uCarAcCxiQnbL5UtGn5Nt2hSH2SiN5uoLqkskG8D5LeAtXVsRjqHjkwkFeWaPfNHWK9zzp1Ckfav5vDJTcc5jXDQmcAvKKoXw7iYKRnZNDPCt1wbuXRsMWSnYCaTVEV4WPoqtX6wxcq49oEYkvG5416FCexossEikVmZ8jturVPYWC9ak1MWPaHMMnyjij7CWDkSySHWzEgUxwFYg6PvdByef3w2nCvaa8oYcxniBJJh8unDFeg94aDqjBgq4cGMTJHHkGPQ9DqBzcDzN1XDSkh4rrB2hM4KZHd18KZwyzJ9ymsCpYJ
```

**✅ Sucesso!** A transação foi preparada e enviada. A saída mostra:
- Instruções criadas (limite de compute units + enroll remote router)
- Transação em formato base58
- Mensagem em formato base58

**Nota**: Se precisar verificar a transação on-chain, você pode:
1. Verificar no Solana Explorer usando o transaction signature (se exibido)
2. Consultar o estado do warp route para confirmar que o router foi vinculado (veja Passo 3 abaixo)

## Passo 3: Verificar Vinculação

Após a execução, verifique se o router foi vinculado:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Consultar o router vinculado para o domain 1325
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  synthetic
```

Procure por `remote_routers` na saída. Deve mostrar:

```
remote_routers: {
    1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b,
},
```

**✅ Exemplo de Saída de Sucesso:**

```
AccountData {
    data: HyperlaneToken {
        bump: 250,
        mailbox: 75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR,
        mailbox_process_authority: s9Jd399kbL2prRtWCJku7Q4AaQQaxNhUhUi9LvG8Ue9,
        dispatch_authority_bump: 254,
        decimals: 6,
        remote_decimals: 6,
        owner: Some(
            EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd,
        ),
        interchain_security_module: Some(
            8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS,
        ),
        interchain_gas_paymaster: None,
        destination_gas: {},
        remote_routers: {
            1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b,
        },
        plugin_data: SyntheticPlugin {
            mint: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA,
            mint_bump: 255,
            ata_payer_bump: 255,
        },
    },
}
```

**✅ Confirmado!** O router do Terra Classic (domain 1325) foi vinculado com sucesso. O endereço hex `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b` corresponde ao seu warp route do Terra Classic.

## Referência Completa de Comandos

### Comando Completo (Uma linha)

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client && \
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  1325 \
  0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

**⚠️ IMPORTANTE**: `domain` e `router` são **argumentos posicionais**, não flags. A sintaxe correta é:
- `--program-id` (flag opcional, usa padrão se omitido)
- `DOMAIN` (argumento posicional)
- `ROUTER` (argumento posicional)

### Usando Endereço Bech32 Diretamente

O `hyperlane-sealevel-client` pode converter automaticamente endereços bech32 para H256:

```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  1325 \
  terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
```

**Nota**: `domain` e `router` são argumentos posicionais, não flags.

**Nota**: O client usa `hex_or_base58_or_bech32_to_h256` internamente, então pode lidar com endereços bech32 diretamente.

## Assinatura da Função

A função `enrollRemoteRouter` no programa Solana:

```rust
pub fn enroll_remote_routers(
    ctx: Context<EnrollRemoteRouters>,
    router_configs: Vec<RemoteRouterConfig>,
) -> Result<()>
```

Onde `RemoteRouterConfig` é:
```rust
pub struct RemoteRouterConfig {
    pub domain: u32,
    pub router: H256,  // Hash de 32 bytes
}
```

**Parâmetros:**
- `domain`: Domain ID do Terra Classic (1325)
- `router`: Endereço do warp route Terra Classic como H256 (formato hex de 32 bytes)

## Comparação: BSC vs Solana

| Aspecto | BSC (EVM) | Solana (SVM) |
|---------|-----------|--------------|
| **Método** | Safe CLI + `cast calldata` | `hyperlane-sealevel-client` diretamente |
| **Formato de Endereço** | Hex de 32 bytes (0x...) | H256 (aceita hex, base58 ou bech32) |
| **Comando** | `cast calldata` + `safe tx create` | `token enroll-remote-router` |
| **Verificação de Owner** | Safe deve ser owner | Signer do keypair deve ser owner |
| **Transação** | Multi-etapas (create → sign → execute) | Comando único |

## Notas Importantes

1. **Domain ID**: O domain do Terra Classic é `1325` (não confundir com outras redes)
2. **Formato de Endereço**: O endereço Terra Classic pode ser fornecido como:
- Hex com prefixo `0x`: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Hex sem prefixo `0x`: `17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Bech32: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` (convertido automaticamente)
3. **Ownership**: O signer do keypair deve ser o owner do programa warp route Solana
4. **Bidirecional**: Após vincular na Solana, certifique-se de que Terra Classic → Solana também está vinculado (veja `LINK-ULUNA-WARP-BSC.md` para o lado Terra Classic)

## Troubleshooting

### Erro: "Owner not signer"

**Problema**: O signer do keypair não é o owner do programa warp route.

**Solução**: Verifique o owner:
```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  synthetic
```

Procure por `owner` na saída. Se não for o endereço do seu keypair, você precisa usar o keypair do owner ou transferir o ownership.

### Erro: "Invalid router format"

**Problema**: O formato do endereço router está incorreto.

**Solução**: 
- Use formato hex: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Ou use bech32: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- O client converterá automaticamente bech32 para H256

### Erro: "Account has insufficient funds"

**Problema**: Sua conta Solana não tem SOL suficiente para a transação.

**Solução**: Solicite airdrop:
```bash
solana airdrop 1 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

## Próximos Passos

Após vincular com sucesso o remote router:

1. **Verificar se ambas as direções estão vinculadas:**
   - Terra Classic → Solana: Verificar rota no Terra Classic
   - Solana → Terra Classic: Verificar vinculação do router na Solana

2. **Testar transferência cross-chain:**
   - Transferir de Terra Classic para Solana
   - Transferir de Solana para Terra Classic

## Referências

- [ENROLL-REMOTE-ROUTER-BSC.md](./ENROLL-REMOTE-ROUTER-BSC.md) - Exemplo BSC (usa Safe)
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Guia completo Terra Classic ↔ Solana
- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)

