# Guia Completo: Criar Warp Route Sintético na Solana

Este guia fornece instruções passo a passo para criar um warp route sintético na Solana Testnet e configurar o ISM com validadores.

## Dados do Seu Deploy

- **Program ID**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- **Token**: 
  - Name: `Luna Classic`
  - Symbol: `wwwwLUNC`
  - Decimals: `6`
  - Type: `synthetic`
- **ISM**: 
  - Type: `messageIdMultisigIsm`
  - Validator: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`
  - Threshold: `1`

---

## Passo 1: Preparar Configuração do Token

### 1.1. Criar Diretório de Configuração

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Criar diretório para a configuração
mkdir -p environments/testnet/warp-routes/lunc-solana
```

### 1.2. Criar Arquivo de Configuração do Token

**⚠️ IMPORTANTE**: O `token-config.json` deve ter o nome da chain como chave:

```bash
cat > environments/testnet/warp-routes/lunc-solana/token-config.json << EOF
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0"
  }
}
EOF
```

**⚠️ IMPORTANTE**: NÃO inclua `foreignDeployment` na configuração inicial. Use `program-ids.json` para referenciar o Program ID existente.

### 1.3. Verificar Arquivo Criado

```bash
cat environments/testnet/warp-routes/lunc-solana/token-config.json
```

---

## Passo 2: Inicializar o Warp Route Sintético

### 2.1. Verificar Keypair

```bash
# Verificar se o keypair existe
ls -lh /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json

# Verificar endereço
solana address --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

### 2.2. Deploy/Inicializar o Warp Route Sintético

**⚠️ IMPORTANTE**: Como você já fez o deploy do programa (`5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`), agora precisa **inicializar** o warp route usando esse Program ID.

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_NAME="lunc-solana"

# ⚠️ IMPORTANTE: Caminhos relativos a partir de client/
# Use ../ (um nível acima), não ../../ (dois níveis)
ENVIRONMENTS_DIR="../environments"
TOKEN_CONFIG="../environments/testnet/warp-routes/lunc-solana/token-config.json"
BUILT_SO_DIR="../target/deploy"

# ⚠️ IMPORTANTE: NÃO use foreignDeployment no token-config.json
# Use program-ids.json para referenciar o Program ID existente
# Isso permite que o código inicialize o token mesmo usando o Program ID existente

# Deploy/Inicializar o warp route sintético
# NOTA: -k e -u são argumentos globais e devem vir ANTES do subcomando
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name ${WARP_ROUTE_NAME} \
  --environment testnet \
  --environments-dir ${ENVIRONMENTS_DIR} \
  --token-config-file ${TOKEN_CONFIG} \
  --built-so-dir ${BUILT_SO_DIR} \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000
```

**Nota**: O comando `warp-route deploy` irá:
1. ✅ Ler o `program-ids.json` e encontrar o Program ID existente
2. ✅ Verificar que o programa existe na blockchain
3. ✅ **Inicializar o token sintético** (criar o PDA do token)
4. ✅ Criar o Mint Account e configurar o Mint Authority
5. ✅ Financiar o ATA payer
6. ✅ Configurar o IGP

**Saída esperada:**
```
Recovered existing program id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x
Initializing Warp Route program: domain_id: 1399811149, mailbox: 75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR, ...
Creating token DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA ...
Address: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Decimals: 9
Signature: ...
initialized metadata pointer. Status: exit status: 0
initialized metadata. Status: exit status: 0
Transferring authority: mint to the mint account DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Set the mint authority to the mint account. Status: exit status: 0
```

**⚠️ IMPORTANTE**: Anote o `Mint Account` (`DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`) retornado. Você precisará dele para linkar com o Terra Classic.

### 2.3. Verificar Inicialização

```bash
# Verificar programa deployado
solana program show ${PROGRAM_ID} --url https://api.testnet.solana.com

# Verificar dados do token (se o comando estiver disponível)
# Nota: O sealevel client pode não ter comando de query direto
```

---

## Passo 3: Configurar ISM no Warp Route

### 3.1. Verificar ISM Padrão do Mailbox

O warp route na Solana usa o ISM padrão do Mailbox por padrão. Se você quiser usar um ISM específico:

```bash
# Program ID do ISM Multisig Message ID (testnet padrão)
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"

# Verificar se o ISM existe
solana program show ${ISM_PROGRAM_ID} --url https://api.testnet.solana.com
```

### 3.2. Configurar ISM Específico (Opcional)

Se você quiser usar um ISM específico no warp route (em vez do padrão do Mailbox):

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"  # ISM padrão do Mailbox
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"

# Configurar ISM no warp route
cargo run -- \
  -k ${KEYPAIR} \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism ${ISM_PROGRAM_ID} \
```

**Nota**: Na maioria dos casos, você **não precisa** fazer isso, pois o warp route já usa o ISM padrão do Mailbox automaticamente.

---

## Passo 4: Configurar Validadores no ISM

### 4.1. Verificar ISM Atual

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325  # Terra Classic Testnet
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"

# Verificar configuração atual do ISM para domain 1325
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
```

### 4.2. Configurar Validadores

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325  # Terra Classic Testnet
THRESHOLD=1
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"

# Configurar validadores no ISM
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators ${VALIDATOR} \
  --threshold ${THRESHOLD} \
```

**Saída esperada:**
```
[INFO] Setting validators and threshold for domain 1325...
[INFO] Validators configured successfully
[INFO] Transaction signature: <TX_SIGNATURE>
```

### 4.3. Verificar Configuração dos Validadores

```bash
# Verificar se os validadores foram configurados corretamente
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
```

**Saída esperada:**
```
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

## Passo 5: Verificar Configuração Completa

### 5.1. Verificar Token Sintético

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"

# Query do token sintético
cargo run -- \
  -k ${KEYPAIR} \
  token query \
  --program-id ${PROGRAM_ID} \
  synthetic \
```

### 5.2. Verificar ISM do Warp Route

```bash
# Verificar ISM configurado no warp route (se configurado)
# Nota: Se não configurado explicitamente, usa o ISM padrão do Mailbox
```

### 5.3. Verificar Validadores no ISM

```bash
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325

cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \
```

---

## Resumo dos Comandos

### Script Completo

```bash
#!/bin/bash
# criar-warp-solana.sh

set -e

# Variáveis
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
TOKEN_CONFIG="environments/testnet/warp-routes/lunc-solana/token-config.json"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN=1325
THRESHOLD=1
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"

echo "=== Passo 1: Criar Configuração do Token ==="
cd ~/hyperlane-monorepo/rust/sealevel
mkdir -p environments/testnet/warp-routes/lunc-solana
cat > ${TOKEN_CONFIG} << EOF
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0"
  }
}
EOF
echo "✅ Configuração do token criada"

echo ""
echo "=== Passo 2: Deploy/Inicializar Warp Route Sintético ==="
cd client
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name lunc-solana \
  --environment testnet \
  --environments-dir ../environments \
  --token-config-file ../environments/testnet/warp-routes/lunc-solana/token-config.json \
  --built-so-dir ../target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000
echo "✅ Warp route sintético inicializado"

echo ""
echo "=== Passo 3: Configurar Validadores no ISM ==="
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id ${ISM_PROGRAM_ID} \
  --domain ${DOMAIN} \
  --validators ${VALIDATOR} \
  --threshold ${THRESHOLD} \
echo "✅ Validadores configurados"

echo ""
echo "=== Passo 4: Verificar Configuração ==="
echo "Verificando validadores no ISM..."
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id ${ISM_PROGRAM_ID} \
  --domains ${DOMAIN} \

echo ""
echo "✅ Configuração completa!"
echo ""
echo "Próximos passos:"
echo "1. Anotar o Mint Account retornado no Passo 2"
echo "2. Linkar o warp route do Terra Classic com o da Solana"
echo "3. Testar transferências cross-chain"
```

---

## Troubleshooting

### Erro: "Program account not found"

**Problema**: O Program ID não existe ou está incorreto.

**Solução**: Verifique se o programa foi deployado:

```bash
solana program show ${PROGRAM_ID} --url https://api.testnet.solana.com
```

### Erro: "Owner not signer"

**Problema**: Você não é o owner do programa.

**Solução**: Use o keypair que foi usado no deploy do programa.

### Erro: "Invalid token config"

**Problema**: O arquivo de configuração do token está incorreto.

**Solução**: Verifique o formato JSON:

```bash
cat environments/testnet/warp-routes/lunc-solana/token-config.json | jq
```

### Erro: "Invalid validator address"

**Problema**: O endereço do validator não está no formato correto.

**Solução**: 
- Use endereços hexadecimais de exatamente 20 bytes (40 caracteres)
- Não inclua `0x` no início
- Exemplo correto: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`

---

## Próximos Passos

Após completar este guia:

1. **Informações Importantes**:
   - Program ID: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
   - Mint Account: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`
   - Mint Authority: Transferido para o próprio mint account

2. **Linkar com Terra Classic**:
   - Consulte `WARP-ROUTE-TERRA-SOLANA-EN.md` para instruções de link bidirecional
   - Use o Program ID (convertido para hex) para linkar o warp route do Terra Classic

3. **Testar Transferências**:
   - Teste transferência Terra Classic → Solana
   - Teste transferência Solana → Terra Classic

---

## Referências

- [SOLANA-WARP-ROUTE-DEPLOYMENT.md](./SOLANA-WARP-ROUTE-DEPLOYMENT.md) - Guia completo em inglês
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Guia completo Terra ↔ Solana em inglês
- [CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md)
- [CONFIGURAR-VALIDADORES-ISM-SOLANA.md](./CONFIGURAR-VALIDADORES-ISM-SOLANA.md)
- [FIX-SOLANA-DEPLOY-USE-RPC.md](./FIX-SOLANA-DEPLOY-USE-RPC.md) - Correção do erro `--use-rpc`
- [Hyperlane Solana Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)

