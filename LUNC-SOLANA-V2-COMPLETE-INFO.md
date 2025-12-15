# Warp Route lunc-solana-v2 - Informações Completas

## ✅ Status: Totalmente Configurado

Este documento contém todas as informações do warp route `lunc-solana-v2` entre Terra Classic e Solana Testnet.

---

## 📋 Informações do Warp Route

### Solana

- **Name**: `lunc-solana-v2`
- **Program ID**: `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw`
- **Owner**: `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd`
- **Mint**: `3yhG9dDHVX6K1duf8znEcaJcuTiKSLYvfBD4xy6akxfu`
- **Decimals**: 6
- **Remote Decimals**: 6
- **Mailbox**: `75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR`
- **Mailbox Process Authority**: `BmHuXi78dfykjuLtoRuKRi193xuVNFf7FkpxrerqyWip`

### Terra Classic

- **Address (Bech32)**: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- **Address (Hex)**: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- **Domain**: 1325
- **Asset Type**: Native (uluna)
- **Asset ID**: uluna

---

## 🔐 ISM (Interchain Security Module)

- **Program ID**: `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`
- **Owner**: `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd`
- **Context**: `lunc-solana-v2-ism`
- **Status**: ✅ Inicializado, Configurado e Associado

### Configuração dos Validadores

- **Domain**: 1325 (Terra Classic)
- **Validator**: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`
- **Threshold**: 1

**Verificar ISM:**
```bash
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh \
  --domains 1325
```

---

## 🔗 Remote Router

### Solana → Terra Classic
- **Terra Classic Domain**: 1325
- **Terra Classic Router (Bech32)**: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- **Terra Classic Router (Hex)**: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- **Status**: ✅ Vinculado na Solana

### Terra Classic → Solana
- **Solana Domain**: 1399811150
- **Solana Router (Base58)**: `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw`
- **Solana Router (Hex)**: `f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa`
- **Transaction Hash**: `0630750886AC1FE214234BDB5B891DE1299883169C37130BB9C62E2EC64930F9`
- **Status**: ✅ Transação enviada e confirmada no Terra Classic

**Verificar Remote Router (Solana → Terra Classic):**
```bash
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw \
  synthetic
```

**Saída esperada:**
```
remote_routers: {
    1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b,
}
```

**Verificar Remote Router (Terra Classic → Solana):**
```bash
terrad query wasm contract-state smart terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Saída esperada (após confirmação):**
```json
{
  "data": {
    "route": "f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"
  }
}
```

---

## ⛽ IGP (Interchain Gas Paymaster)

- **IGP Program ID**: `5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2`
- **IGP Oracle**: `9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy`
- **Status**: ✅ Configurado

---

## 📝 Scripts Utilizados

### 1. Deploy do Warp Route
**Script**: `script/criar-novo-warp-solana.sh`

### 2. Configuração do ISM
**Script**: `script/configurar-ism-lunc-solana-v2-manual.sh`

**Passos executados:**
1. Deploy manual do ISM (evita erro `--use-rpc`)
2. Inicialização do ISM
3. Configuração de validadores (Domain 1325)
4. Associação do ISM ao warp route

### 3. Vinculação do Remote Router (Solana → Terra Classic)
**Script**: `script/vincular-remote-router-solana-lunc-solana-v2.sh`

**Passos executados:**
1. Verificação de informações
2. Vinculação do Remote Router (Domain 1325)
3. Verificação da vinculação

### 4. Vinculação do Remote Router (Terra Classic → Solana)
**Script**: `script/vincular-terra-to-solana-lunc-solana-v2.sh`

**Passos executados:**
1. Conversão do Program ID Solana para hex
2. Verificação de informações
3. Vinculação do Remote Router (Domain 1399811150)
4. Verificação da vinculação

**Transaction Hash**: `0630750886AC1FE214234BDB5B891DE1299883169C37130BB9C62E2EC64930F9`

---

## ✅ Verificação Completa

### Verificar Estado Completo do Warp Route

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw \
  synthetic
```

**Verificar na saída:**
- ✅ `interchain_security_module`: `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`
- ✅ `remote_routers`: `{ 1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b }`
- ✅ `interchain_gas_paymaster`: Configurado
- ✅ `owner`: `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd`
- ✅ `mint`: `3yhG9dDHVX6K1duf8znEcaJcuTiKSLYvfBD4xy6akxfu`

---

## 📊 Resumo de Status

| Componente | Status | Detalhes |
|------------|--------|----------|
| **Warp Route Solana** | ✅ | Deployado e operacional |
| **Warp Route Terra Classic** | ✅ | Deployado e operacional |
| **ISM** | ✅ | Configurado, validadores definidos, associado |
| **Remote Router (Solana → Terra)** | ✅ | Vinculado (Domain 1325) |
| **Remote Router (Terra → Solana)** | ✅ | Vinculado (Domain 1399811150) |
| **IGP** | ✅ | Configurado |
| **Pronto para Transferências** | ✅ | Sim (Bidirecional) |

---

## 🔍 Exploradores

### Solana
- **Program**: [Solana Explorer](https://explorer.solana.com/address/HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw?cluster=testnet)
- **Mint**: [Solana Explorer](https://explorer.solana.com/address/3yhG9dDHVX6K1duf8znEcaJcuTiKSLYvfBD4xy6akxfu?cluster=testnet)
- **ISM**: [Solana Explorer](https://explorer.solana.com/address/5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh?cluster=testnet)

### Terra Classic
- **Warp Route**: [Terra Classic Finder](https://finder.terra-classic.hexxagon.dev/testnet/address/terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml)

---

## 📚 Documentação Relacionada

- [WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md) - Guia completo do warp route
- [ISM-SOLANA-DEPLOYED-INFO.md](./ISM-SOLANA-DEPLOYED-INFO.md) - Informações do ISM
- [VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md) - Guia de vinculação do Remote Router
- [CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md) - Guia de configuração de ISM

---

## 🎯 Próximos Passos

1. ✅ **Deploy do Warp Route** - Concluído
2. ✅ **Configuração do ISM** - Concluído
3. ✅ **Vinculação do Remote Router** - Concluído
4. ✅ **Verificar Terra Classic → Solana** - Link bidirecional completo
5. ⏳ **Testar Transferências** - Testar transferências cross-chain em ambas as direções

---

**Última atualização**: Após vinculação bem-sucedida do Remote Router

