# Fix: Erro de Stack Overflow ao Compilar Solana

Este documento explica como resolver o erro de stack overflow ao compilar programas Solana com `cargo build-sbf`.

## Erro

```
Error: Function _ZN112_$LT$solana_program..instruction..InstructionError$u20$as$u20$solana_frozen_abi..abi_example..AbiEnumVisitor$GT$13visit_for_abi17h0b6c3fda7bedb8c3E Stack offset of 4608 exceeded max offset of 4096 by 512 bytes, please minimize large stack variables
```

## Causa

O erro ocorre quando uma função usa mais de 4096 bytes na stack (limite do Solana BPF). Isso geralmente acontece com:
- Variáveis grandes alocadas na stack
- Estruturas grandes passadas por valor
- Muitas variáveis locais grandes

## Soluções

### ⚠️ IMPORTANTE: Este erro está vindo do `solana-program` (dependência)

O erro está na função `AbiEnumVisitor` do `solana-program`, não no seu código. Isso é um problema conhecido com algumas versões do Solana.

### Solução 1: Tentar Compilar com Menos Otimizações

Paradoxalmente, às vezes menos otimização ajuda. Tente remover ou ajustar as otimizações:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Editar Cargo.toml temporariamente
# Comentar ou remover as linhas de [profile.release] que adicionamos
# Ou mudar opt-level de "z" para "s" (otimização para tamanho, menos agressiva)
```

Ou tente compilar sem as otimizações customizadas:

```bash
# Limpar
cargo clean

# Compilar sem flags extras
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

### Solução 2: Adicionar Configurações de Otimização no Cargo.toml

Adicione ou atualize o `[profile.release]` no `Cargo.toml` do workspace:

```toml
[profile.release]
opt-level = "z"      # Otimização para tamanho (reduz uso de stack)
lto = "fat"          # Link Time Optimization
codegen-units = 1    # Reduz unidades de código (melhor otimização)
panic = "abort"      # Reduz overhead
```

**Localização**: `/home/lunc/hyperlane-monorepo/rust/sealevel/Cargo.toml`

### Solução 3: Adicionar Configuração Específica para solana-program

Adicione configurações específicas para reduzir o stack usage do `solana-program`:

```bash
cd ~/hyperlane-monorepo/rust/sealevel
```

Edite o `Cargo.toml` e adicione após as configurações de `[profile.release.package.*]`:

```toml
[profile.release.package.solana-program]
opt-level = "s"          # Otimização para tamanho (menos agressiva que "z")
lto = false              # Desabilitar LTO para solana-program (pode ajudar)
codegen-units = 16       # Mais unidades de código (menos otimização agressiva)
```

### Solução 4: Compilar com Flags Específicas

Use flags adicionais para reduzir o uso de stack:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar build anterior
cargo clean

# Compilar com otimizações máximas
# NOTA: cargo build-sbf já compila em release por padrão, não use --release
cargo build-sbf -- -Z build-std=std,panic_abort \
  -C opt-level=z \
  -C lto=fat \
  -C codegen-units=1
```

### Solução 5: Compilar Programas Individuais

Em vez de compilar tudo, compile apenas o programa que você precisa:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Compilar apenas o programa de token sintético
# NOTA: cargo build-sbf já compila em release por padrão
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml

# Ou o programa de token nativo
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token-native/Cargo.toml
```

### Solução 6: Tentar Versão Diferente do Solana (Último Recurso)

Se nada funcionar, pode ser necessário atualizar o fork do Solana usado pelo Hyperlane. Verifique se há uma versão mais recente:

```bash
# Verificar tag atual no Cargo.toml
grep "hyperlane-1.14.13" ~/hyperlane-monorepo/rust/sealevel/Cargo.toml

# Verificar se há uma tag mais recente no repositório
# https://github.com/hyperlane-xyz/solana/tags
```

**⚠️ AVISO**: Mudar a versão do Solana pode quebrar compatibilidade. Use apenas como último recurso.

Crie ou atualize um arquivo `.cargo/config.toml` no diretório `sealevel`:

```bash
cd ~/hyperlane-monorepo/rust/sealevel
mkdir -p .cargo

cat > .cargo/config.toml << EOF
[build]
rustflags = [
    "-C", "opt-level=z",
    "-C", "lto=fat",
    "-C", "codegen-units=1",
]

[target.bpf-unknown-unknown]
rustflags = [
    "-C", "opt-level=z",
    "-C", "lto=fat",
    "-C", "codegen-units=1",
]
EOF
```

### Solução 7: Usar Versão Específica do Solana Tools

O erro pode estar relacionado à versão das ferramentas Solana. Verifique e atualize:

```bash
# Verificar versão atual
solana --version
cargo build-sbf --version

# Atualizar Solana tools (se necessário)
solana-install init 1.18.1  # ou versão mais recente

# Verificar se resolveu
cargo build-sbf --version
```

### Solução 8: Compilar com Menos Paralelismo

Reduzir o paralelismo pode ajudar em alguns casos:

```bash
# Compilar com apenas 1 job
cargo build-sbf -j 1 -- --release
```

### Solução 9: Limpar e Recompilar

Às vezes, um build limpo resolve:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar completamente
cargo clean
rm -rf target/

# Recompilar (cargo build-sbf já usa release por padrão)
cargo build-sbf
```

## Solução Recomendada (Passo a Passo)

### 1. Primeiro, Tente Sem Otimizações Agressivas

O erro está no `solana-program`, então vamos tentar compilar sem otimizações muito agressivas primeiro:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar
cargo clean

# Tentar compilar sem otimizações customizadas
# (comentar temporariamente o [profile.release] que adicionamos)
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

### 2. Se Falhar, Adicionar Configuração Específica para solana-program

Edite o `Cargo.toml` e adicione após as outras configurações de `[profile.release.package.*]`:

```toml
[profile.release.package.solana-program]
opt-level = "s"          # Otimização para tamanho (menos agressiva)
lto = false              # Desabilitar LTO
codegen-units = 16       # Mais unidades (menos otimização)
```

### 3. Limpar e Recompilar

```bash
cargo clean
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

### 4. Se Ainda Falhar

Tente compilar outros programas para ver se o problema é específico:

```bash
# Token nativo
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token-native/Cargo.toml

# Token collateral
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token-collateral/Cargo.toml
```

## Verificar se Funcionou

Após compilar, verifique se os arquivos `.so` foram gerados:

```bash
# Verificar arquivos compilados
find ~/hyperlane-monorepo/rust/sealevel/target/deploy -name "*.so" -type f

# Deve mostrar arquivos como:
# hyperlane_sealevel_token.so
# hyperlane_sealevel_token_native.so
# hyperlane_sealevel_token_collateral.so
```

## Troubleshooting Adicional

### Se o erro persistir

1. **Verificar versão do Rust**:
   ```bash
   rustc --version
   # Deve ser compatível com Solana 1.14.13
   ```

2. **Verificar versão do Solana**:
   ```bash
   solana --version
   cargo build-sbf --version
   ```

3. **Tentar build sem otimizações** (apenas para teste):
   ```bash
   # cargo build-sbf sempre compila em release
   # Para debug, use cargo build-sbf --features debug
   cargo build-sbf
   ```

4. **Verificar dependências**:
   ```bash
   cargo tree | grep solana-program
   # Deve mostrar versão 1.14.13
   ```

## Referências

- [Solana BPF Stack Limits](https://docs.solana.com/developing/on-chain-programs/overview#stack)
- [Rust Optimization Guide](https://doc.rust-lang.org/cargo/reference/profiles.html)
- [Hyperlane Sealevel Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)

