# ISM Solana - Informações do Deploy

## ✅ Deploy Concluído com Sucesso

### Informações do Novo ISM

- **Program ID**: `8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS`
- **Owner**: `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd`
- **Status**: ✅ Inicializado e configurado

### Configuração dos Validadores

- **Domain**: 1325 (Terra Classic)
- **Validator**: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`
- **Threshold**: 1

### Associação ao Warp Route

- **Warp Route Program ID**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- **ISM Configurado**: `8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS`
- **Status**: ✅ Associado

---

## Comandos de Verificação

### Verificar Owner do ISM

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS
```

### Verificar Validadores Configurados

```bash
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS \
  --domains 1325
```

### Verificar ISM no Warp Route

```bash
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  synthetic
```

Procure por `interchain_security_module` na saída - deve mostrar: `8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS`

---

## Histórico do Deploy

1. **Deploy Manual**: Usado `solana program deploy` diretamente (sem `--use-rpc`) devido à incompatibilidade com Solana CLI 1.14.20
2. **Inicialização**: Usado `multisig-ism-message-id init` para tornar o deployer o owner
3. **Configuração de Validadores**: Configurado domain 1325 (Terra Classic) com validator `242d8a855a8c932dec51f7999ae7d1e48b10c95e` e threshold 1
4. **Associação ao Warp Route**: Associado ao warp route `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`

---

## Referências

- [CREATE-NEW-ISM-SOLANA-EN.md](./CREATE-NEW-ISM-SOLANA-EN.md) - Guia completo em inglês
- [CRIAR-NOVO-ISM-SOLANA.md](./CRIAR-NOVO-ISM-SOLANA.md) - Guia completo em português
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Guia completo do warp route

