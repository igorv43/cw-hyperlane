# Quick Fix: Adicionar Chave ao Terrad Keyring

## Problema
```
Error: uluna-warp.info: key not found
```

## Solução Rápida

### Passo 1: Adicionar a Chave

Você precisa adicionar a chave ao keyring primeiro. Escolha uma opção:

#### Opção A: Usando Mnemonic (Recomendado)

```bash
terrad keys add uluna-warp --recover --keyring-backend file
```

Você será solicitado a:
1. **Enter your bip39 mnemonic**: Digite sua frase mnemonic (12 ou 24 palavras)
2. **Enter keyring passphrase**: Crie uma senha para proteger a chave
3. **Re-enter keyring passphrase**: Confirme a senha

#### Opção B: Usando Chave Privada (Hex)

Se você tem a chave privada em formato hexadecimal:

```bash
# Método 1: Interativo (recomendado)
terrad keys add uluna-warp --recover --keyring-backend file
# Quando solicitado, cole sua chave privada (hex, sem 0x)

# Método 2: Via pipe (menos seguro)
echo "SUA_CHAVE_PRIVADA_HEX_AQUI" | terrad keys add uluna-warp --recover --keyring-backend file
```

### Passo 2: Verificar se a Chave foi Adicionada

```bash
# Listar todas as chaves
terrad keys list --keyring-backend file

# Verificar endereço da chave específica
terrad keys show uluna-warp --keyring-backend file --address
```

**Importante:** O endereço deve ser `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`

### Passo 3: Executar o Comando de Instanciação

Depois que a chave for adicionada com sucesso:

```bash
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from uluna-warp \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 1000000uluna \
  --yes
```

## Alternativa: Usar Chave Existente

Se você já tem uma chave configurada, pode usar o nome dela:

```bash
# 1. Listar chaves existentes
terrad keys list --keyring-backend file

# 2. Usar o nome da chave existente no comando
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from NOME_DA_SUA_CHAVE_EXISTENTE \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 1000000uluna \
  --yes
```

## Verificar Endereço da Chave

Para garantir que está usando a chave correta:

```bash
# Ver endereço da chave
terrad keys show uluna-warp --keyring-backend file --address

# Deve retornar: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze
```

Se o endereço não corresponder, você precisa adicionar a chave correta que corresponde ao endereço desejado.

## Troubleshooting

### Erro: "too many failed passphrase attempts"

Se você viu este erro antes, pode precisar limpar o keyring ou usar um nome diferente:

```bash
# Usar um nome diferente
terrad keys add uluna-warp-new --recover --keyring-backend file
```

### Não tenho mnemonic nem chave privada

Se você não tem acesso à mnemonic ou chave privada do endereço `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`, você precisa:

1. Recuperar a mnemonic/chave privada da sua wallet
2. Ou usar um endereço diferente que você controla
3. Ou criar uma nova wallet:

```bash
# Criar nova wallet
terrad keys add nova-wallet --keyring-backend file

# Ver endereço
terrad keys show nova-wallet --keyring-backend file --address

# Atualizar o uluna-msg.json com o novo endereço
```

