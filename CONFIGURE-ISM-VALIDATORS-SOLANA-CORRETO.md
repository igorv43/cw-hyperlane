# Configurar Validadores ISM na Solana - Comando Correto

## ⚠️ PROBLEMA IMPORTANTE

O ISM existente (`4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`) tem um owner diferente, então você **não pode configurar validadores nele**.

**Solução**: Você precisa criar um **novo ISM** e associá-lo ao warp route. Veja [CRIAR-NOVO-ISM-SOLANA.md](./CRIAR-NOVO-ISM-SOLANA.md) para instruções completas.

---

## Comando Correto (Se Você For o Owner)

O comando `ism multisig-message-id set-validators-and-threshold` não existe. O comando correto é `multisig-ism-message-id set-validators-and-threshold` (com hífens).

## Comando Correto

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
THRESHOLD="1"

# Configure validators
# ⚠️ IMPORTANTE: Use "multisig-ism-message-id" (com hífens), não "ism multisig-message-id"
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"
```

## Diferença

- ❌ **Incorreto**: `ism multisig-message-id set-validators-and-threshold`
- ✅ **Correto**: `multisig-ism-message-id set-validators-and-threshold`

## Múltiplos Validadores

Para configurar múltiplos validadores, separe-os por vírgula:

```bash
VALIDATOR_1="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
VALIDATOR_2="f620f5e3d25a3ae848fec74bccae5de3edcd8796"
VALIDATORS="${VALIDATOR_1},${VALIDATOR_2}"
THRESHOLD="2"

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATORS" \
  --threshold "$THRESHOLD"
```

## Verificar Configuração

```bash
# Query validators and threshold for a domain
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$ISM_PROGRAM_ID" \
  --domains "$DOMAIN"
```

## Estrutura do Comando

```
cargo run -- \
  -k <keypair> \
  -u <url> \
  multisig-ism-message-id <subcommand> \
  --program-id <program_id> \
  --domain <domain> \
  --validators <validator1>,<validator2>,... \
  --threshold <threshold>
```

## Subcomandos Disponíveis

- `deploy` - Deploy do programa ISM
- `init` - Inicializar o programa ISM
- `set-validators-and-threshold` - Configurar validadores e threshold
- `query` - Consultar configuração
- `transfer-ownership` - Transferir ownership
- `configure` - Configurar via arquivo JSON

