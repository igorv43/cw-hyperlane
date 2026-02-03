# 🔍 DIAGNÓSTICO COMPLETO - ERRO "destination not supported"

**Data:** 2026-02-03  
**Status:** ❌ PROBLEMA IDENTIFICADO

---

## 🚨 PROBLEMA CONFIRMADO

### O Hook Atual Tem o Tipo ERRADO!

```
Endereço do Hook:  0x7D4d3da2cf0c411626280Be6959011d947B9456c
Hook Type Atual:   2 (AGGREGATION)  ❌
Hook Type Correto: 4 (IGP)          ✅
```

### Por Que o Erro Acontece?

O Warp Route chama `quoteTransferRemote()` que internamente usa o hook para calcular o custo do gas. Quando o hook não é do tipo correto (IGP = 4), o contrato não reconhece os métodos necessários e retorna **"destination not supported"**.

---

## 📖 TIPOS DE HOOK NO HYPERLANE

Conforme `IPostDispatchHook.sol`:

```solidity
enum HookTypes {
    UNUSED,                        // 0
    ROUTING,                       // 1
    AGGREGATION,                   // 2  ← Tipo atual ❌
    MERKLE_TREE,                   // 3
    INTERCHAIN_GAS_PAYMASTER,      // 4  ← Tipo correto ✅
    FALLBACK_ROUTING,              // 5
    ID_AUTH_ISM,                   // 6
    PAUSABLE,                      // 7
    PROTOCOL_FEE,                  // 8
    DEPRECATED,                    // 9
    RATE_LIMITED,                  // 10
    ARB_L2_TO_L1,                  // 11
    OP_L2_TO_L1,                   // 12
    MAILBOX_DEFAULT_HOOK,          // 13
    AMOUNT_ROUTING,                // 14
    CCTP                           // 15
}
```

---

## 🔍 VERIFICAÇÃO REALIZADA

### 1. Hook do Warp Route
```bash
$ cast call 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "hook()(address)" \
  --rpc-url https://1rpc.io/sepolia

Resultado: 0x7D4d3da2cf0c411626280Be6959011d947B9456c
```

### 2. Tipo do Hook
```bash
$ cast call 0x7D4d3da2cf0c411626280Be6959011d947B9456c \
  "hookType()(uint8)" \
  --rpc-url https://1rpc.io/sepolia

Resultado: 2  ❌ (Deveria ser 4)
```

### 3. Beneficiary
```bash
$ cast call 0x7D4d3da2cf0c411626280Be6959011d947B9456c \
  "beneficiary()(address)" \
  --rpc-url https://1rpc.io/sepolia

Resultado: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526 ✅
```

---

## ❌ CAUSA RAIZ

Este é o `CustomIGP` que foi deployado anteriormente com um **bug no código**:

```solidity
// CustomIGP.sol (INCORRETO)
function hookType() external pure override returns (uint8) {
    return 2; // ❌ ERRADO! (AGGREGATION)
}
```

Deveria ser:

```solidity
// TerraClassicIGP.sol (CORRETO)
function hookType() external pure override returns (uint8) {
    return 4; // ✅ CORRETO! (INTERCHAIN_GAS_PAYMASTER)
}
```

---

## ✅ SOLUÇÃO

### Passo 1: Deploy do Contrato Correto

Deploy `TerraClassicIGP.sol` que **JÁ TEM** o hookType correto (4).

**Arquivo:** `/home/lunc/cw-hyperlane/TerraClassicIGP.sol`

**Código relevante:**
```solidity
/// @inheritdoc IPostDispatchHook
function hookType() external pure override returns (uint8) {
    return IGP_HOOK_TYPE; // = 4 ✅
}
```

### Passo 2: Associar ao Warp Route

Após o deploy, associar o novo IGP:

```bash
export IGP_ADDRESS="<endereço_do_novo_igp>"
./associar-igp-ao-warp.sh
```

---

## 📋 GUIA DE DEPLOY

### Via Remix IDE (Recomendado)

1. **Abrir Remix:**
   ```
   https://remix.ethereum.org
   ```

2. **Criar arquivo:**
   - Nome: `TerraClassicIGP.sol`
   - Copiar conteúdo de: `/home/lunc/cw-hyperlane/TerraClassicIGP.sol`

3. **Compilar:**
   - Compiler: Solidity 0.8.13+
   - Optimization: Enabled (200 runs)

4. **Deploy:**
   - Environment: Injected Provider - MetaMask
   - Network: Sepolia
   - Contract: TerraClassicIGP
   
   **Constructor Parameters:**
   ```
   _gasOracle:    0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
   _gasOverhead:  200000
   _beneficiary:  0x133fD7F7094DBd17b576907d052a5aCBd48dB526
   ```

5. **Copiar endereço do contrato deployado**

6. **Associar ao Warp Route:**
   ```bash
   export IGP_ADDRESS="<endereço_copiado>"
   cd /home/lunc/cw-hyperlane
   ./associar-igp-ao-warp.sh
   ```

---

## 🔄 COMPARAÇÃO: CustomIGP vs TerraClassicIGP

| Aspecto | CustomIGP (Atual) | TerraClassicIGP (Novo) |
|---------|-------------------|------------------------|
| **Hook Type** | 2 (AGGREGATION) ❌ | 4 (IGP) ✅ |
| **Exchange Rate Scale** | 1e18 ❌ | 1e10 ✅ |
| **Parsing Destination** | Incorreto ❌ | Correto (bytes 41-45) ✅ |
| **Parsing Gas Limit** | Incorreto ❌ | Correto (bytes 34-66) ✅ |
| **Interface** | Incompleta ❌ | IPostDispatchHook completo ✅ |
| **Baseado em** | Implementação custom | InterchainGasPaymaster oficial ✅ |
| **Status** | **NÃO FUNCIONA** ❌ | **DEVE FUNCIONAR** ✅ |

---

## 🎯 RESULTADO ESPERADO

Após deploy e associação do `TerraClassicIGP.sol`:

✅ Hook Type = 4 (IGP)  
✅ Warp Route reconhece o hook como IGP válido  
✅ Cálculo de custo funciona corretamente  
✅ Erro "destination not supported" **desaparece**  
✅ Transferências Sepolia → Terra Classic **funcionam**

---

## 📊 RESUMO EXECUTIVO

### Problema
```
Hook atual: 0x7D4d3da2cf0c411626280Be6959011d947B9456c
Hook Type:  2 (AGGREGATION) ❌
Erro:       "destination not supported"
```

### Solução
```
Deploy:     TerraClassicIGP.sol
Hook Type:  4 (INTERCHAIN_GAS_PAYMASTER) ✅
Resultado:  Transferências funcionando ✅
```

---

## 🚀 PRÓXIMO PASSO

```bash
cat DEPLOY-REMIX-CORRETO.md
```

Ou veja o guia rápido:

```bash
cat START-HERE.txt
```

---

## 📞 VERIFICAÇÃO PÓS-DEPLOY

Após fazer o deploy e associação, verifique:

```bash
RPC="https://1rpc.io/sepolia"
WARP="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# Ver novo hook
NEW_HOOK=$(cast call $WARP "hook()(address)" --rpc-url $RPC)
echo "Novo Hook: $NEW_HOOK"

# Verificar tipo
HOOK_TYPE=$(cast call $NEW_HOOK "hookType()(uint8)" --rpc-url $RPC)
echo "Hook Type: $HOOK_TYPE"

# Deve ser 4!
if [ "$HOOK_TYPE" = "4" ]; then
    echo "✅ Hook Type correto!"
else
    echo "❌ Hook Type ainda incorreto"
fi
```

---

**Status:** ⏳ Aguardando deploy do TerraClassicIGP.sol  
**Próximo passo:** Deploy via Remix IDE
