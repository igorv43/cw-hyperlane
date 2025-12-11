# Fix Sepolia RPC Timeout Error

## Problema

Ao executar `yarn cw-hpl-exp warp link`, você pode receber um erro de timeout:

```
TransactionExecutionError: The request took too long to respond.
URL: https://rpc.sepolia.org
```

## Causa

O RPC público do Sepolia (`https://rpc.sepolia.org`) pode estar lento ou indisponível, causando timeout nas requisições.

## Soluções

### Solução 1: Usar RPC Alternativo (Recomendado)

Use um RPC alternativo mais confiável passando a opção `--endpoint` ou `--rpc`:

```bash
yarn cw-hpl-exp warp link \
  0x2144Be4477202ba2d50c9A8be3181241878cf7D8 \
  1325 \
  terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  --pk '0x819b680e3578eac4f79b8fde643046e88f3f....' \
  --endpoint 'https://ethereum-sepolia.blockpi.network/v1/rpc/public'
```

**RPCs Alternativos para Sepolia:**

1. **BlockPI (Recomendado):**
   ```bash
   --endpoint 'https://ethereum-sepolia.blockpi.network/v1/rpc/public'
   ```

2. **Alchemy (Requer API Key):**
   ```bash
   --endpoint 'https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY'
   ```

3. **Infura (Requer API Key):**
   ```bash
   --endpoint 'https://sepolia.infura.io/v3/YOUR_API_KEY'
   ```

4. **PublicNode:**
   ```bash
   --endpoint 'https://ethereum-sepolia-rpc.publicnode.com'
   ```

5. **Ankr:**
   ```bash
   --endpoint 'https://rpc.ankr.com/eth_sepolia'
   ```

### Solução 2: Usar Variável de Ambiente

Configure o endpoint como variável de ambiente:

```bash
export SEPOLIA_RPC='https://ethereum-sepolia.blockpi.network/v1/rpc/public'

yarn cw-hpl-exp warp link \
  0x2144Be4477202ba2d50c9A8be3181241878cf7D8 \
  1325 \
  terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  --pk '0x819b680e3578eac4f79b8fde643046e88f3f....' \
  --endpoint $SEPOLIA_RPC
```

### Solução 3: Aguardar e Tentar Novamente

Se o RPC público estiver temporariamente indisponível, aguarde alguns minutos e tente novamente:

```bash
# Aguardar 2-3 minutos e tentar novamente
yarn cw-hpl-exp warp link \
  0x2144Be4477202ba2d50c9A8be3181241878cf7D8 \
  1325 \
  terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  --pk '0x819b680e3578eac4f79b8fde643046e88f3f....'
```

## Correção Aplicada

O código foi atualizado para incluir:
- **Timeout de 30 segundos** nas requisições HTTP
- **Retry automático** (até 3 tentativas)
- **Delay entre retries** (1 segundo)

Isso deve melhorar a confiabilidade mesmo com RPCs lentos.

## Verificar Status do RPC

Para verificar se um RPC está funcionando:

```bash
# Testar RPC do Sepolia
curl -X POST https://rpc.sepolia.org \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Testar RPC alternativo (BlockPI)
curl -X POST https://ethereum-sepolia.blockpi.network/v1/rpc/public \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

**Resposta esperada:**
```json
{"jsonrpc":"2.0","id":1,"result":"0xaa36a7"}
```

Onde `0xaa36a7` é o chain ID do Sepolia (11155111 em decimal).

## Comando Completo com RPC Alternativo

```bash
yarn cw-hpl-exp warp link \
  0x2144Be4477202ba2d50c9A8be3181241878cf7D8 \
  1325 \
  terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  --pk '0x819b680e3578eac4f79b8fde643046e88f3f....' \
  --endpoint 'https://ethereum-sepolia.blockpi.network/v1/rpc/public'
```

## Notas

- RPCs públicos podem ter rate limits
- Para uso em produção, considere usar um RPC com API key (Alchemy, Infura)
- O timeout foi aumentado para 30 segundos para lidar com RPCs lentos
- O retry automático ajuda a lidar com falhas temporárias

