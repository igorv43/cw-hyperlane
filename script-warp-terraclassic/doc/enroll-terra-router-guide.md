# Guia: `enroll-terra-router.sh`

> Script interativo para registrar a rota EVM no contrato Warp da **Terra Classic**.  
> Resolve o erro `route not found` ao chamar `transfer_remote` e garante o vínculo bidirecional do Warp Route.

---

## 📋 Índice

1. [O que o script faz](#1-o-que-o-script-faz)
2. [Quando usar](#2-quando-usar)
3. [Pré-requisitos](#3-pré-requisitos)
4. [Como executar](#4-como-executar)
5. [O que acontece por baixo](#5-o-que-acontece-por-baixo)
6. [Entendendo o vínculo bidirecional](#6-entendendo-o-vínculo-bidirecional)
7. [Verificando o estado atual](#7-verificando-o-estado-atual)
8. [Troubleshooting](#8-troubleshooting)
9. [Links úteis](#9-links-úteis)

---

## 1. O que o script faz

O `enroll-terra-router.sh` chama a função `router.set_route` no contrato Warp **da Terra Classic** para registrar o endereço do Warp de uma rede EVM (ex: Sepolia) como roteador autorizado.

Sem esse registro, qualquer chamada `transfer_remote` partindo da Terra Classic falha com:

```
route not found: wasmvm error
```

O script:
1. Lê a configuração de `warp-evm-config.json`
2. Apresenta menus para selecionar o **token** e a **rede EVM** de destino
3. Converte o endereço EVM para `bytes32` (formato exigido pelo Warp)
4. Exibe um resumo e pede confirmação
5. Executa a transação via Node.js + `@cosmjs`
6. Verifica se a rota já estava configurada (evita duplicatas)

---

## 2. Quando usar

| Situação | Ação |
|---|---|
| `transfer_remote` falha com `route not found` | Execute este script |
| Deploy feito sem `TERRA_PRIVATE_KEY` (Etapa 7B pulada) | Execute este script |
| Warp EVM foi re-deployado em novo endereço | Execute este script para atualizar a rota |
| Primeira vez adicionando uma rede EVM a um token existente | Execute este script após o deploy EVM |
| Verificação preventiva antes de transferir | Use a seção [Verificando o estado atual](#7-verificando-o-estado-atual) |

> **Contexto:** O `create-warp-evm.sh` executa esta etapa automaticamente (Etapa 7B) quando `TERRA_PRIVATE_KEY` está definida. Use `enroll-terra-router.sh` apenas quando precisar executar manualmente depois.

---

## 3. Pré-requisitos

| Requisito | Verificação |
|---|---|
| `node` 18+ | `node --version` |
| `jq` | `jq --version` |
| Pacotes `@cosmjs` instalados | `ls node_modules/@cosmjs/cosmwasm-stargate` |
| `TERRA_PRIVATE_KEY` com saldo em LUNA | owner do contrato Warp Terra Classic |
| `warp-evm-config.json` atualizado | token com `warp_address` preenchido + rede com `warp_tokens.<token>.deployed: true` |

### Verificar se os dados estão no config:

```bash
# Token XPTO — verificar se warp_address está preenchido
jq '.terra_classic.tokens.xpto.terra_warp' script-warp-terraclassic/warp-evm-config.json

# Rede Sepolia — verificar se warp xpto está deployado
jq '.networks.sepolia.warp_tokens.xpto' script-warp-terraclassic/warp-evm-config.json
```

---

## 4. Como executar

```bash
# 1. Entrar na pasta script-warp-terraclassic
cd ~/cw-hyperlane/script-warp-terraclassic

# 2. Dar permissão (apenas primeira vez)
chmod +x enroll-terra-router.sh

# 3. Definir a chave privada Terra Classic
export TERRA_PRIVATE_KEY="sua_chave_hex"   # sem prefixo 0x

# 4. Executar
./enroll-terra-router.sh
```

### Exemplo de execução

```
╔══════════════════════════════════════════════════════╗
║   enrollRemoteRouter — TERRA CLASSIC (set_route)    ║
╚══════════════════════════════════════════════════════╝

📌 Selecione o TOKEN a vincular:

  [1] XPTO — terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm
  [2] JURIS — terra1stu3c...

▶ Digite o número: 1

📌 Selecione a rede EVM de destino:

  [1] Ethereum Sepolia Testnet (domain 11155111) — 0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048

▶ Digite o número: 1

📋 Parâmetros da operação:
   Token         : XPTO (xpto)
   Terra Warp    : terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm
   Rede EVM      : Ethereum Sepolia Testnet (domain 11155111)
   EVM Warp      : 0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048
   EVM bytes32   : 000000000000000000000000bf43aa4878f5ad0fcac12cd3a835dd3506981048
   RPC Terra     : https://rpc.terra-classic.hexxagon.dev

Mensagem CosmWasm que será executada:
{
  "router": {
    "set_route": {
      "set": {
        "domain": 11155111,
        "route": "000000000000000000000000bf43aa4878f5ad0fcac12cd3a835dd3506981048"
      }
    }
  }
}

▶ Confirmar? [s/N]: s

⏳ Enviando transação...

╔══════════════════════════════════════════════════════╗
║    ✅ set_route EXECUTADO COM SUCESSO!               ║
╚══════════════════════════════════════════════════════╝

📦 Transação:
   TX Hash   : D24446E27DAB952ED26B538358AF687BE19CA8DE98B89BC8A601D617AD8DD8A5
   Bloco     : 24571234
   Gas usado : 180000
   Remetente : terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze

   🔗 Explorer:
   https://finder.hexxagon.io/rebel-2/tx/D24446E27DAB952...
```

---

## 5. O que acontece por baixo

### 5.1 Conversão de endereço EVM → bytes32

O contrato Warp da Terra Classic armazena os roteadores como `bytes32`. O endereço EVM (20 bytes) é convertido para `bytes32` com padding esquerdo de zeros:

```
Endereço EVM (20 bytes / 40 hex chars):
  0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048

bytes32 (32 bytes / 64 hex chars):
  000000000000000000000000bf43aa4878f5ad0fcac12cd3a835dd3506981048
  ^^^^^^^^^^^^^^^^^^^^^^^^  ← 24 zeros de padding (12 bytes)
```

O script usa:
```bash
EVM_WARP_HEX="${EVM_WARP_ADDR#0x}"
EVM_WARP_B32=$(printf '%064s' "$EVM_WARP_HEX" | tr ' ' '0')
```

### 5.2 Verificação de rota existente

Antes de enviar a transação, o script consulta `router.list_routes` para verificar se a rota já existe:

```javascript
const { routes } = await client.queryContractSmart(terraWarp, {
    router: { list_routes: {} }
});
const existing = routes.find(r => r.domain === evmDomain);
if (existing && existing.route) {
    // rota já configurada — não re-enviar
}
```

> ⚠️ **Não use `router.get_route`** para esta verificação. Quando o domínio não existe, ele retorna
> `{"route": null}` em vez de erro, causando falsos positivos. O `list_routes` é confiável.

### 5.3 Execução via @cosmjs

A transação é enviada usando `SigningCosmWasmClient.execute` do pacote `@cosmjs/cosmwasm-stargate`:

```javascript
const result = await client.execute(
    senderAddress,
    terraWarpContract,
    { router: { set_route: { set: { domain: evmDomain, route: evmRouteHex } } } },
    "auto",   // estimativa automática de gas
    "enrollRemoteRouter via enroll-terra-router.sh"
);
```

---

## 6. Entendendo o vínculo bidirecional

Um Warp Route Hyperlane requer configuração **nos dois lados** para funcionar:

```
Terra Classic → Sepolia:
  Contrato Warp Terra Classic sabe que o domain 11155111 usa o endereço 0xbF43aA...
  (configurado por este script via router.set_route)

Sepolia → Terra Classic:
  Contrato Warp Sepolia sabe que o domain 1325 usa o endereço terra16ql6l...
  (configurado pelo create-warp-evm.sh na Etapa 7 via enrollRemoteRouter)
```

### Verificação on-chain dos dois lados:

```bash
RPC="https://ethereum-sepolia-rpc.publicnode.com"

# Lado Sepolia: routers(1325) deve ser o hex do Warp Terra Classic
cast call 0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048 \
  "routers(uint32)(bytes32)" 1325 --rpc-url $RPC
# Esperado: 0xd03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1

# Lado Terra Classic: list_routes deve conter domain 11155111
node -e "
const p=require('path'), nm=p.join('/home/lunc/cw-hyperlane','node_modules');
const {CosmWasmClient}=require(p.join(nm,'@cosmjs/cosmwasm-stargate'));
(async()=>{
  const c=await CosmWasmClient.connect('https://rpc.terra-classic.hexxagon.dev');
  const r=await c.queryContractSmart(
    'terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm',
    {router:{list_routes:{}}}
  );
  console.log(JSON.stringify(r.routes, null, 2));
})();"
# Esperado: [{ domain: 11155111, route: "000000000000000000000000bf43aa4878..." }]
```

---

## 7. Verificando o estado atual

Antes de executar o script, verifique se a rota já está configurada:

```bash
cd ~/cw-hyperlane

# Consultar todas as rotas registradas no XPTO Warp Terra Classic
node --no-warnings -e "
const p=require('path'), nm=p.join(process.cwd(),'node_modules');
const {CosmWasmClient}=require(p.join(nm,'@cosmjs/cosmwasm-stargate'));
(async()=>{
  const c=await CosmWasmClient.connect('https://rpc.terra-classic.hexxagon.dev');
  const r=await c.queryContractSmart(
    'terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm',
    {router:{list_routes:{}}}
  );
  if(!r.routes || r.routes.length === 0) {
    console.log('❌ Nenhuma rota configurada!');
  } else {
    r.routes.forEach(rt => console.log('domain', rt.domain, '→', rt.route));
  }
})().catch(e=>console.log('Erro:', e.message));"
```

**Resultado esperado (tudo configurado):**
```
domain 11155111 → 000000000000000000000000bf43aa4878f5ad0fcac12cd3a835dd3506981048
```

**Resultado que indica problema:**
```
❌ Nenhuma rota configurada!
```
ou
```
domain 11155111 → null
```

---

## 8. Troubleshooting

### ❌ `Nenhum token com warp_address configurado`

**Causa:** O campo `terra_warp.warp_address` está vazio no `warp-evm-config.json`.

**Solução:** Preencher o endereço do Warp Terra Classic após o deploy:

```json
"xpto": {
  "terra_warp": {
    "warp_address": "terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm",
    "warp_hexed":   "0xd03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1",
    "deployed":     true
  }
}
```

---

### ❌ `Nenhuma rede EVM com TOKEN deployado`

**Causa:** `warp_tokens.<token>.deployed` está `false` ou o campo `address` está vazio.

**Solução:** Após o deploy EVM, atualizar o JSON:

```json
"warp_tokens": {
  "xpto": {
    "deployed": true,
    "address":  "0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048"
  }
}
```

---

### ❌ `Chave privada inválida`

**Causa:** O formato da chave está errado.

**Solução:** A chave deve ser hexadecimal sem prefixo `0x`:

```bash
# ✅ Correto:
export TERRA_PRIVATE_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# ❌ Com 0x — o script remove automaticamente, mas verifique se não há espaços:
export TERRA_PRIVATE_KEY="0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### ❌ `out of gas` ou gas insuficiente

**Causa:** O gas estimado (`"auto"`) não foi suficiente, ou o preço configurado é muito baixo.

**Solução:** O script usa `28.325uluna` como gasPrice, que é o padrão da Terra Classic testnet. Se a rede estiver congestionada, pode ser necessário aumentar:

```javascript
// Dentro do script, altere a linha:
const gasPrice = GasPrice.fromString("28.325uluna");
// Para:
const gasPrice = GasPrice.fromString("50uluna");
```

---

### ❌ `account sequence mismatch`

**Causa:** O RPC está atrasado ou outra transação foi enviada simultaneamente.

**Solução:** Aguardar alguns blocos e tentar novamente. Verificar se o RPC está sincronizado:

```bash
curl -s "https://rpc.terra-classic.hexxagon.dev/status" | jq '.result.sync_info.latest_block_height'
```

> Use sempre o RPC do `hexxagon` — é o mais sincronizado para rebel-2.

---

### ✅ Rota já configurada (`already_set`) mas `transfer_remote` ainda falha

**Possíveis causas:**

1. **O lado EVM não está configurado** — verifique `routers(1325)` no Warp Sepolia:
   ```bash
   cast call $WARP_EVM "routers(uint32)(bytes32)" 1325 \
     --rpc-url https://ethereum-sepolia-rpc.publicnode.com
   # Deve ser != 0x000...
   ```

2. **Domain incorreto no `transfer_remote`** — confirme que está passando `11155111` (Sepolia) e não outro valor.

3. **Endereço EVM registrado está desatualizado** — se o Warp EVM foi re-deployado, a rota aponta para o endereço antigo. Re-execute o script para atualizar.

---

## 9. Links úteis

| Recurso | URL |
|---|---|
| Hyperlane Explorer | [explorer.hyperlane.xyz](https://explorer.hyperlane.xyz) |
| Terra Classic Finder (testnet) | [finder.hexxagon.io/rebel-2](https://finder.hexxagon.io/rebel-2) |
| Terra Classic Finder (mainnet) | [finder.terra.money](https://finder.terra.money) |
| Sepolia Etherscan | [sepolia.etherscan.io](https://sepolia.etherscan.io) |
| Documentação Hyperlane Warp Routes | [docs.hyperlane.xyz/docs/protocol/warp-routes](https://docs.hyperlane.xyz/docs/protocol/warp-routes/overview) |
| Guia principal (`create-warp-evm.sh`) | [`create-warp-evm-guide.md`](./create-warp-evm-guide.md) |
