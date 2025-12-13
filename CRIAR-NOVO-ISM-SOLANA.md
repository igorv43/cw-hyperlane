# Criar Novo ISM na Solana e Associar ao Warp Route

## Problema

O ISM existente (`4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`) tem um owner diferente (`6DjHX6Ezjpq3zZMZ8KsqyoFYo1zPSDoiZmLLkxD4xKXS`), então você não pode configurar validadores nele.

**Solução**: Assim como no BSC, você precisa criar um **novo ISM**, configurá-lo com seus validadores e associá-lo ao warp route.

---

## Passo 1: Compilar o Programa ISM (Se Necessário)

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Compilar o programa ISM Multisig Message ID
cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml

# Verificar se compilou
ls -lh target/deploy/hyperlane_sealevel_multisig_ism_message_id.so
```

---

## Passo 2: Deploy do Novo ISM

**⚠️ IMPORTANTE**: O `hyperlane-sealevel-client` usa `--use-rpc` que não é suportado pelo Solana CLI 1.14.20. Precisamos fazer o deploy manualmente.

### Opção 1: Deploy Manual (Recomendado)

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Deploy do programa ISM (isso retornará um novo Program ID)
solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

**Saída esperada:**
```
Program Id: 8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS
```

**⚠️ IMPORTANTE**: Anote o novo Program ID retornado. Você precisará dele nos próximos passos.

**Salve o Program ID:**
```bash
NOVO_ISM_PROGRAM_ID="8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS"
```

**Nota**: Certifique-se de ter pelo menos 1.5 SOL na sua conta para o deploy. Se precisar de mais SOL:
```bash
solana airdrop 2 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

### Opção 2: Usando hyperlane-sealevel-client (Pode Falhar)

Se quiser tentar usar o client (pode falhar devido ao problema do `--use-rpc`):

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
CHAIN="solanatestnet"
CONTEXT="lunc-solana-ism"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"
ENVIRONMENTS_DIR="../environments"

# Deploy do ISM (pode falhar com erro --use-rpc)
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --built-so-dir "$BUILT_SO_DIR" \
  --chain "$CHAIN" \
  --context "$CONTEXT" \
  --registry "$REGISTRY_DIR"
```

---

## Passo 3: Inicializar o ISM

Após fazer o deploy, você precisa inicializar o ISM para se tornar o owner:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Inicializar o ISM (use o Program ID do Passo 2)
NOVO_ISM_PROGRAM_ID="8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS"

cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id init \
  --program-id "$NOVO_ISM_PROGRAM_ID"
```

**Saída esperada:**
```
==== Instructions: ====
Instruction 0: Set compute unit limit to 1400000
Instruction 1: No description provided
Transaction signature: <TX_SIGNATURE>
```

## Passo 4: Verificar Owner

Verifique se você é o owner:

```bash
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$NOVO_ISM_PROGRAM_ID"
```

**Saída esperada:**
```
Access control: AccessControlData {
    bump_seed: 253,
    owner: Some(
        EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd,  # Você é o owner!
    ),
}
```

## Passo 5: Configurar Validadores no Novo ISM

Agora que você é o owner do novo ISM, pode configurar os validadores:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
ISM_PROGRAM_ID="$NOVO_ISM_PROGRAM_ID"  # Use o novo Program ID
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
THRESHOLD="1"

# Configurar validadores
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"
```

**Saída esperada:**
```
Set for remote domain 1325 validators and threshold: ValidatorsAndThreshold { validators: [0x242d8a855a8c932dec51f7999ae7d1e48b10c95e], threshold: 1 }
Transaction signature: <TX_SIGNATURE>
```

---

## Passo 4: Verificar Configuração dos Validadores

```bash
# Verificar se os validadores foram configurados corretamente
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$ISM_PROGRAM_ID" \
  --domains "$DOMAIN"
```

**Saída esperada:**
```
Access control: AccessControlData {
    bump_seed: 255,
    owner: Some(
        EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd,  # Você é o owner!
    ),
}
Querying domain data for origin domain: 1325
Domain data for 1325:
DomainDataAccount {
    validators: [
        "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
    ],
    threshold: 1,
}
```

---

## Passo 5: Associar o Novo ISM ao Warp Route

Agora associe o novo ISM ao seu warp route:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
NOVO_ISM_PROGRAM_ID="$NOVO_ISM_PROGRAM_ID"  # Use o novo ISM Program ID

# Associar o novo ISM ao warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  --ism "$NOVO_ISM_PROGRAM_ID"
```

**Saída esperada:**
```
Set ISM to Some(<NOVO_ISM_PROGRAM_ID>)
Transaction signature: <TX_SIGNATURE>
```

---

## Passo 6: Verificar ISM Configurado no Warp Route

```bash
# Verificar qual ISM está configurado no warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  synthetic
```

Procure na saída por `interchain_security_module` - deve mostrar o novo Program ID do ISM.

---

## Resumo dos Comandos

```bash
# 1. Deploy do novo ISM
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir ../environments \
  --built-so-dir ../target/deploy \
  --chain solanatestnet \
  --context lunc-solana-ism \
  --registry ~/.hyperlane/registry

# 2. Configurar validadores (use o novo Program ID)
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$NOVO_ISM_PROGRAM_ID" \
  --domain 1325 \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e \
  --threshold 1

# 3. Associar ISM ao warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  --ism "$NOVO_ISM_PROGRAM_ID"
```

---

## Diferença: BSC vs Solana

| Aspecto | BSC (EVM) | Solana (SVM) |
|---------|-----------|--------------|
| **Criar Novo ISM** | Deploy via Hyperlane CLI ou Factory | Deploy via `multisig-ism-message-id deploy` |
| **Configurar Validadores** | `terrad tx wasm execute` (se owner) ou Governance | `multisig-ism-message-id set-validators-and-threshold` (se owner) |
| **Associar ao Warp Route** | `setInterchainSecurityModule` via Safe/Contract | `token set-interchain-security-module` via sealevel client |
| **Owner** | Pode ser sua conta ou governance | Você se torna owner no deploy |

---

## Notas Importantes

1. **Você se torna owner automaticamente**: Quando você faz o deploy do ISM, você se torna o owner automaticamente (o payer é o owner).

2. **Não precisa de governance**: Como você é o owner, pode configurar validadores diretamente sem precisar de proposta de governança.

3. **Warp Route Owner**: Você precisa ser o owner do warp route para associar um novo ISM. Verifique se você é o owner do warp route antes de tentar associar o ISM.

4. **Program ID do ISM**: O Program ID do novo ISM será salvo em:
   ```
   ~/hyperlane-monorepo/rust/sealevel/environments/testnet/multisig-ism-message-id/solanatestnet/lunc-solana-ism/program-ids.json
   ```

---

## Troubleshooting

### Erro: "Owner not signer" ao associar ISM ao warp route

**Problema**: Você não é o owner do warp route.

**Solução**: Verifique o owner do warp route:
```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  synthetic
```

Procure por `owner` na saída. Se não for você, você precisará usar o keypair do owner ou transferir o ownership.

### Erro: "Program account not found" no deploy

**Problema**: O programa não foi compilado ou o caminho está incorreto.

**Solução**: 
1. Compile o programa: `cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml`
2. Verifique o caminho: `--built-so-dir ../target/deploy`

### Erro: "Found argument '--use-rpc' which wasn't expected" ao usar `multisig-ism-message-id deploy`

**Problema**: O `hyperlane-sealevel-client` tenta usar `--use-rpc` que não é suportado pelo Solana CLI 1.14.20.

**Solução**: Faça o deploy manualmente usando `solana program deploy` sem a flag `--use-rpc`:

```bash
cd ~/hyperlane-monorepo/rust/sealevel
solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

Depois inicialize o ISM separadamente usando `multisig-ism-message-id init`.

### Erro: "Account has insufficient funds"

**Problema**: Sua conta Solana não tem SOL suficiente para o deploy (precisa de ~1.5 SOL).

**Solução**: Solicite airdrop:
```bash
solana airdrop 2 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

Se o airdrop falhar devido ao rate limit, aguarde alguns minutos e tente novamente, ou use um faucet do Solana: https://faucet.solana.com/

---

## Referências

- [CONFIGURE-ISM-SOLANA-WARP-EN.md](./CONFIGURE-ISM-SOLANA-WARP-EN.md)
- [CONFIGURE-ISM-VALIDATORS-SOLANA-EN.md](./CONFIGURE-ISM-VALIDATORS-SOLANA-EN.md)
- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)

