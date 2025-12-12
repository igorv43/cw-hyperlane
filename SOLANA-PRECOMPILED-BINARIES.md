# Usar Binários Pré-Compilados do Solana (Como Cosmos .wasm)

Este documento explica como obter e usar programas Solana pré-compilados do Hyperlane, similar ao processo no Cosmos onde você baixa o `.wasm`, verifica o hash e faz o deploy.

## Por Que Usar Binários Pré-Compilados?

1. **Evita Problemas de Compilação**: Não precisa lidar com erros de stack overflow
2. **Auditoria**: Hash verificável garante que o código não foi manipulado
3. **Reprodutibilidade**: Mesmo binário usado por todos
4. **Facilidade**: Apenas baixar e fazer deploy

## Onde Encontrar Binários Pré-Compilados

### ⚠️ Situação Atual

**Infelizmente, o Hyperlane não distribui binários pré-compilados (.so) para Solana como faz para Cosmos (.wasm)**. Você precisa compilar localmente ou usar programas já deployados.

### Opção 1: Usar Programas Já Deployados (Recomendado)

Se os programas já foram deployados na Solana Testnet, você pode:

1. **Usar os Program IDs existentes** (não precisa fazer deploy)
2. **Baixar o binário** do programa deployado para verificar hash
3. **Verificar integridade** antes de usar

**Program IDs do Hyperlane na Solana Testnet** (verificar no Hyperlane Registry ou Explorer):
- Mailbox: `75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR`
- ISM Multisig Message ID: `4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`

### Opção 2: Compilar em Docker (Build Determinístico)

Para garantir builds reproduzíveis e verificáveis:

```bash
# Usar Docker para compilação determinística
docker run --rm -v $(pwd):/workspace \
  -w /workspace/rust/sealevel \
  rust:1.75 \
  bash -c "cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml"
```

### Opção 3: Verificar no Hyperlane Registry

O Hyperlane mantém um registry com programas deployados:

```bash
# Verificar registry do Hyperlane (se configurado)
# Geralmente em: ~/.hyperlane/registry
ls -la ~/.hyperlane/registry 2>/dev/null || echo "Registry não encontrado"
```

## Como Verificar Hash de um Programa Solana

### 1. Obter Hash de um Programa Deployado

```bash
# Program ID do warp route (exemplo)
PROGRAM_ID="SEU_PROGRAM_ID_AQUI"

# Obter dados do programa
solana program dump ${PROGRAM_ID} program.so --url https://api.testnet.solana.com

# Calcular hash SHA256
sha256sum program.so
```

### 2. Comparar com Hash Esperado

```bash
# Hash esperado (do Hyperlane)
EXPECTED_HASH="abc123..."

# Hash do binário baixado
ACTUAL_HASH=$(sha256sum program.so | cut -d' ' -f1)

# Comparar
if [ "${EXPECTED_HASH}" = "${ACTUAL_HASH}" ]; then
    echo "✅ Hash verificado! Binário é autêntico."
else
    echo "❌ Hash não confere! Binário pode estar comprometido."
fi
```

## Processo Recomendado

### ⚠️ IMPORTANTE: Não Há Binários Pré-Compilados Disponíveis

Diferente do Cosmos, o Hyperlane **não distribui binários .so pré-compilados**. Você tem duas opções:

### Opção A: Usar Programas Já Deployados (Mais Seguro)

Se alguém já deployou os programas na Solana, você pode usar os Program IDs existentes sem precisar fazer deploy:

```bash
# 1. Verificar Program ID no Hyperlane Registry ou Explorer
# 2. Usar diretamente no deploy do warp route

# Exemplo: Se o programa já existe, você pode referenciar pelo Program ID
# em vez de fazer deploy novamente
```

### Opção B: Compilar Localmente e Documentar Hash

Se você precisa fazer deploy, compile e documente o hash:

```bash
# 1. Compilar (mesmo com erro de stack, tente outras soluções)
cd ~/hyperlane-monorepo/rust/sealevel
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml

# 2. Se compilou com sucesso, calcular hash
cd target/deploy
sha256sum hyperlane_sealevel_token.so > hyperlane_sealevel_token.sha256

# 3. Documentar hash para auditoria
cat hyperlane_sealevel_token.sha256
# Exemplo: abc123def456...  hyperlane_sealevel_token.so
```

### Opção C: Baixar de Programa Já Deployado

Se o programa já foi deployado, você pode baixar e verificar:

```bash
# Program ID do programa deployado
PROGRAM_ID="SEU_PROGRAM_ID_AQUI"

# Baixar programa da blockchain
solana program dump ${PROGRAM_ID} downloaded_program.so \
  --url https://api.testnet.solana.com

# Calcular hash
sha256sum downloaded_program.so

# Comparar com hash esperado (se disponível)
```

## Alternativa: Usar Programas Já Deployados

Se alguém já deployou os programas na Solana, você pode usar os Program IDs existentes:

### 1. Verificar Programas Deployados

```bash
# Verificar no Hyperlane Registry ou Explorer
# Program IDs comuns do Hyperlane na Solana Testnet:
# - Mailbox: 75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR
# - ISM Multisig: 4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k
```

### 2. Baixar e Verificar

```bash
# Baixar programa do chain
PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
solana program dump ${PROGRAM_ID} downloaded_program.so --url https://api.testnet.solana.com

# Verificar hash
sha256sum downloaded_program.so
```

## Criar Documentação de Hashes

Para auditoria, crie um arquivo com os hashes esperados:

```bash
cat > solana-program-hashes.txt << EOF
# Hyperlane Solana Programs - Testnet
# Hash SHA256 dos binários oficiais

# Token Synthetic
hyperlane_sealevel_token.so: abc123def456...

# Token Native
hyperlane_sealevel_token_native.so: def456ghi789...

# Token Collateral
hyperlane_sealevel_token_collateral.so: ghi789jkl012...

# ISM Multisig Message ID
hyperlane_sealevel_multisig_ism_message_id.so: jkl012mno345...
EOF
```

## Verificação Automática

Script para verificar hashes automaticamente:

```bash
#!/bin/bash
# verify-solana-binaries.sh

BINARY_DIR="~/hyperlane-monorepo/rust/sealevel/target/deploy"
HASH_FILE="solana-program-hashes.txt"

echo "=== Verificando Hashes dos Binários Solana ==="

while IFS=':' read -r filename expected_hash; do
    # Ignorar comentários e linhas vazias
    [[ "$filename" =~ ^#.*$ ]] && continue
    [[ -z "$filename" ]] && continue
    
    filepath="${BINARY_DIR}/${filename}"
    
    if [ -f "$filepath" ]; then
        actual_hash=$(sha256sum "$filepath" | cut -d' ' -f1)
        
        if [ "$expected_hash" = "$actual_hash" ]; then
            echo "✅ ${filename}: Hash verificado"
        else
            echo "❌ ${filename}: Hash não confere!"
            echo "   Esperado: ${expected_hash}"
            echo "   Atual:    ${actual_hash}"
        fi
    else
        echo "⚠️  ${filename}: Arquivo não encontrado"
    fi
done < "$HASH_FILE"
```

## Comparação: Cosmos vs Solana

| Aspecto | Cosmos (CosmWasm) | Solana (Sealevel) |
|---------|-------------------|-------------------|
| **Formato Binário** | `.wasm` | `.so` (shared object) |
| **Verificação Hash** | `sha256sum contract.wasm` | `sha256sum program.so` |
| **Upload** | `terrad tx wasm store` | `solana program deploy` |
| **Verificação** | `terrad query wasm code-info` | `solana program dump` + hash |
| **Registry** | Hyperlane Registry | Hyperlane Registry |

## Recomendação

### ⚠️ Situação Real

**O Hyperlane não distribui binários pré-compilados para Solana**. Diferente do Cosmos onde você pode baixar `.wasm` files, na Solana você precisa:

1. **Compilar localmente** (e lidar com erros de stack overflow)
2. **OU usar programas já deployados** (se disponíveis)
3. **OU compilar em Docker** para builds determinísticos

### Processo Recomendado para Auditoria

1. **Compilar em ambiente determinístico** (Docker)
2. **Calcular hash SHA256** do binário compilado
3. **Documentar hash** em arquivo de auditoria
4. **Fazer deploy** e verificar que o hash na blockchain corresponde
5. **Publicar hash** para verificação pública

### Exemplo de Documentação de Hash

```bash
# Criar arquivo de hashes para auditoria
cat > solana-program-hashes-audit.txt << EOF
# Hyperlane Solana Programs - Testnet
# Compilado em: $(date)
# Ambiente: Docker (determinístico)
# Commit: $(git rev-parse HEAD)

hyperlane_sealevel_token.so: abc123def456...
hyperlane_sealevel_token_native.so: def456ghi789...
hyperlane_sealevel_token_collateral.so: ghi789jkl012...
EOF
```

## Próximos Passos

1. Verificar se o Hyperlane publica binários pré-compilados
2. Se sim, baixar e verificar hashes
3. Se não, considerar usar Docker para compilação determinística
4. Documentar os hashes dos binários usados

---

## Referências

- [Solana Program Verification](https://docs.solana.com/cli/deploy-a-program#verifying-a-program)
- [Hyperlane Registry](https://docs.hyperlane.xyz/docs/operate/registry)
- [WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)

