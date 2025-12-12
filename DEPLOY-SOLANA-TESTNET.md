# Deploy do Programa Solana no Testnet

## Configuração Atual

✅ **Rede**: Testnet (`https://api.testnet.solana.com`)
✅ **Keypair**: `/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json`
✅ **Saldo**: 5 SOL (suficiente para deploy)

## Comando de Deploy

### Opção 1: Usando Keypair Configurado (Recomendado)

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Deploy no Testnet (usando keypair configurado)
solana program deploy target/deploy/hyperlane_sealevel_token.so \
  --url testnet \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

### Opção 2: Usando Keypair Padrão

Como o Solana já está configurado para testnet com o keypair padrão, você pode usar:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Deploy no Testnet (usando keypair padrão)
solana program deploy target/deploy/hyperlane_sealevel_token.so \
  --url testnet
```

**Nota:** O Solana CLI já está configurado para usar o testnet e o keypair padrão, então a Opção 2 deve funcionar diretamente.

## Verificar Deploy

Após o deploy, você receberá um **Program ID**. Verifique com:

```bash
# Substitua <PROGRAM_ID> pelo ID retornado
solana program show <PROGRAM_ID> --url testnet
```

## Exemplo de Saída Esperada

```
Program Id: <PROGRAM_ID>

Buffer: <BUFFER_ID>
Upgrade Authority: <YOUR_ADDRESS>
Data Length: 358400 (0x57800) bytes
```

## Próximos Passos

Após o deploy bem-sucedido:

1. **Anotar o Program ID** - você precisará dele para configurar o warp route
2. **Seguir o guia de Warp Route** - consulte `WARP-ROUTE-TERRA-SOLANA.md`
3. **Configurar o token sintético** - usar o `hyperlane-sealevel-client`

## Troubleshooting

### Erro: "Insufficient funds"

```bash
# Verificar saldo
solana balance --url testnet

# Se necessário, solicitar airdrop (máximo 2 SOL por vez)
solana airdrop 2 --url testnet
```

### Erro: "Program deployment failed"

```bash
# Verificar se o binário existe
ls -lh target/deploy/hyperlane_sealevel_token.so

# Verificar configuração
solana config get
```

### Verificar Status do Programa

```bash
# Listar todos os programas deployados
solana program show --programs --url testnet

# Verificar programa específico
solana program show <PROGRAM_ID> --url testnet
```

## Referências

- [WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)
- [COMPILACAO-SOLANA-SUCESSO.md](./COMPILACAO-SOLANA-SUCESSO.md)

