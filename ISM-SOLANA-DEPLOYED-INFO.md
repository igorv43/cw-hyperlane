# ISM Solana - Informações do Deploy

## ✅ Deploy Concluído com Sucesso

### Informações do Novo ISM (lunc-solana-v2)

- **Program ID**: `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`
- **Owner**: `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd`
- **Context**: `lunc-solana-v2-ism`
- **Status**: ✅ Inicializado e configurado

### Configuração dos Validadores

- **Domain**: 1325 (Terra Classic)
- **Validator**: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`
- **Threshold**: 1

### Associação ao Warp Route

- **Warp Route Name**: `lunc-solana-v2`
- **Warp Route Program ID**: `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw`
- **ISM Configurado**: `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`
- **Status**: ✅ Associado

### Remote Router Configurado

- **Terra Classic Domain**: 1325
- **Terra Classic Warp Route (Bech32)**: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- **Terra Classic Warp Route (Hex)**: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- **Status**: ✅ Remote Router vinculado na Solana

**Script usado**: `script/vincular-remote-router-solana-lunc-solana-v2.sh`

---

### ISM Anterior (lunc-solana) - Referência

- **Program ID**: `8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS`
- **Warp Route Program ID**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`

---

## Comandos de Verificação

### Verificar Owner do ISM (lunc-solana-v2)

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh
```

### Verificar Validadores Configurados (lunc-solana-v2)

```bash
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh \
  --domains 1325
```

### Verificar ISM no Warp Route (lunc-solana-v2)

```bash
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw \
  synthetic
```

Procure por `interchain_security_module` na saída - deve mostrar: `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`

---

## Histórico do Deploy

### ISM lunc-solana-v2 (Atual)

1. **Deploy Manual**: Usado `solana program deploy` diretamente (sem `--use-rpc`) devido à incompatibilidade com Solana CLI 1.14.20
2. **Inicialização**: Usado `multisig-ism-message-id init` para tornar o deployer o owner
3. **Configuração de Validadores**: Configurado domain 1325 (Terra Classic) com validator `242d8a855a8c932dec51f7999ae7d1e48b10c95e` e threshold 1
4. **Associação ao Warp Route**: Associado ao warp route `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw` (lunc-solana-v2)
5. **Remote Router**: Vinculado Terra Classic (Domain 1325) → `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`

**Scripts usados**: 
- ISM: `script/configurar-ism-lunc-solana-v2-manual.sh`
- Remote Router: `script/vincular-remote-router-solana-lunc-solana-v2.sh`

### ISM lunc-solana (Anterior)

1. **Deploy Manual**: Usado `solana program deploy` diretamente (sem `--use-rpc`)
2. **Inicialização**: Usado `multisig-ism-message-id init`
3. **Configuração de Validadores**: Configurado domain 1325 (Terra Classic)
4. **Associação ao Warp Route**: Associado ao warp route `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x` (lunc-solana)

---

## Resumo das Configurações

### ISM lunc-solana-v2 (Atual - Recomendado)

| Item | Valor |
|------|-------|
| **ISM Program ID** | `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh` |
| **Warp Route Program ID** | `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw` |
| **Warp Route Name** | `lunc-solana-v2` |
| **Context** | `lunc-solana-v2-ism` |
| **Owner** | `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd` |
| **Domain Configurado** | 1325 (Terra Classic) |
| **Validator** | `242d8a855a8c932dec51f7999ae7d1e48b10c95e` |
| **Threshold** | 1 |
| **Status** | ✅ Configurado e Associado |
| **Remote Router** | ✅ Vinculado (Domain 1325) |

### ISM lunc-solana (Anterior)

| Item | Valor |
|------|-------|
| **ISM Program ID** | `8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS` |
| **Warp Route Program ID** | `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x` |
| **Warp Route Name** | `lunc-solana` |
| **Status** | ✅ Configurado |

## Scripts Disponíveis

### ISM
- **`script/configurar-ism-lunc-solana-v2-manual.sh`** - Script completo para configurar ISM do lunc-solana-v2 (recomendado)
- **`script/configurar-ism-warp-lunc-solana-v2.sh`** - Script interativo com pausas
- **`script/configurar-ism-lunc-solana-v2-simples.sh`** - Versão simplificada
- **`script/configurar-ism-lunc-solana-v2-direto.sh`** - Versão direta sem pausas

### Remote Router
- **`script/vincular-remote-router-solana-lunc-solana-v2.sh`** - Script completo para vincular Remote Router (recomendado)
- **`script/vincular-remote-router-lunc-solana-v2-simples.sh`** - Versão simplificada

## Referências

- [LUNC-SOLANA-V2-COMPLETE-INFO.md](./LUNC-SOLANA-V2-COMPLETE-INFO.md) - **📋 Informações completas do lunc-solana-v2** (recomendado)
- [CREATE-NEW-ISM-SOLANA-EN.md](./CREATE-NEW-ISM-SOLANA-EN.md) - Guia completo em inglês
- [CRIAR-NOVO-ISM-SOLANA.md](./CRIAR-NOVO-ISM-SOLANA.md) - Guia completo em português
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Guia completo do warp route
- [CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md) - Guia de configuração de ISM
- [VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md) - Guia de vinculação do Remote Router

