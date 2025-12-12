# Instalar Solana 1.14.20 (Versão Correta para Hyperlane)

Este guia explica como instalar a versão correta do Solana (1.14.20) para compilar programas Hyperlane **sem alterar o código fonte**.

## ⚠️ Problema Identificado

- **Sua versão atual**: Solana CLI `2.0.3` ❌
- **Versão requerida pelo Hyperlane**: Solana CLI `1.14.20` ✅
- **Causa do erro**: Versão 2.0.3 tem mudanças incompatíveis que causam stack overflow

## Solução: Instalar Solana 1.14.20

### Método 1: Usar Script do Hyperlane (Recomendado)

O Hyperlane fornece um script de instalação:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Executar script de instalação
bash programs/install-solana-1.14.20.sh
```

### Método 2: Instalação Manual

Se o script não funcionar, instale manualmente:

```bash
# 1. Baixar e executar instalador do Solana
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

# 2. Instalar versão específica 1.14.20
solana-install init 1.14.20

# 3. Verificar instalação
solana --version
# Deve mostrar: solana-cli 1.14.20
```

### Método 3: Usar Script do Hyperlane com Download Direto

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Executar script
bash programs/install-solana-1.14.20.sh

# Se falhar, tentar com curl direto:
curl -sSfL https://github.com/solana-labs/solana/releases/download/v1.14.20/solana-install-init-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) | sh -s - v1.14.20
```

## Verificar Instalação

Após instalar, verifique todas as versões:

```bash
echo "=== Versão do Solana CLI ==="
solana --version
# Esperado: solana-cli 1.14.20

echo ""
echo "=== Versão do cargo-build-sbf ==="
cargo-build-sbf --version
# Esperado: solana-cargo-build-sbf 1.14.20

echo ""
echo "=== Versão do Rust (do Solana) ==="
~/.local/share/solana/install/active_release/bin/rustc --version
# Esperado: rustc 1.75.0

echo ""
echo "=== PATH ==="
which solana
which cargo-build-sbf
# Deve apontar para: ~/.local/share/solana/install/active_release/bin/
```

## Atualizar PATH (Se Necessário)

Se os comandos não funcionarem, adicione ao PATH:

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Recarregar
source ~/.bashrc  # ou source ~/.zshrc

# Verificar
which solana
```

## Limpar e Recompilar

Após instalar a versão correta:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar build anterior
cargo clean
rm -rf target/

# Tentar compilar
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Se Ainda Falhar

### Verificar se Múltiplas Versões Estão Instaladas

```bash
# Verificar todas as instalações do Solana
ls -la ~/.local/share/solana/install/

# Verificar qual está ativa
ls -la ~/.local/share/solana/install/active_release

# Se houver múltiplas versões, remover as antigas
rm -rf ~/.local/share/solana/install/releases/*  # Exceto 1.14.20
```

### Reinstalação Completa

```bash
# 1. Remover instalação atual
rm -rf ~/.local/share/solana

# 2. Limpar cache do cargo
rm -rf ~/.cargo/registry/cache

# 3. Limpar target do projeto
cd ~/hyperlane-monorepo/rust/sealevel
rm -rf target/

# 4. Instalar Solana 1.14.20
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
solana-install init 1.14.20

# 5. Verificar
solana --version
cargo-build-sbf --version

# 6. Tentar compilar
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Por Que 1.14.20?

1. **Compatibilidade**: Hyperlane foi desenvolvido e testado com 1.14.20
2. **Cargo.toml**: Especifica `solana-program = "=1.14.13"` (compatível com 1.14.20)
3. **Stack Overflow**: Versões mais novas (2.0.x) têm mudanças que causam erros
4. **Script Oficial**: Hyperlane fornece script específico para 1.14.20

## Diferenças Entre Versões

| Versão | Status | Compatibilidade |
|--------|--------|-----------------|
| **1.14.20** | ✅ Requerida | Totalmente compatível |
| **1.14.13** | ✅ Compatível | Usada nas dependências |
| **2.0.3** | ❌ Incompatível | Causa stack overflow |

## Comandos Rápidos

```bash
# Instalar Solana 1.14.20
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)" && solana-install init 1.14.20

# Verificar versão
solana --version

# Limpar e compilar
cd ~/hyperlane-monorepo/rust/sealevel && cargo clean && cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Referências

- Script de instalação: `hyperlane-monorepo/rust/sealevel/programs/install-solana-1.14.20.sh`
- [Solana Release Archive](https://release.anza.xyz/)
- [FIX-SOLANA-VERSION.md](./FIX-SOLANA-VERSION.md)

