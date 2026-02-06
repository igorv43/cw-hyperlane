# Configuração do Warp Route Terra Classic

Este documento descreve como configurar o Warp Route para Terra Classic Testnet, incluindo a atualização do Hook.

## 📋 Informações da Configuração

### Contratos Terra Classic Testnet

- **Warp Route**: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- **Mailbox**: `terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm`
- **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`
- **defaultHook do Mailbox**: `terra18shx4zhfehscggs9upspl489qd7yg29vdasvrerytppt3am92mnsj5365s`

## 🔧 O que o Script Faz

O script `configurar-warp-terra-classic.ts` realiza as seguintes operações:

1. **Consulta a configuração atual**:
   - Hook atual do Warp Route
   - defaultHook do Mailbox

2. **Atualiza o Hook do Warp Route**:
   - Define o hook do Warp Route para o `defaultHook` do Mailbox
   - Garante que o validador possa monitorar e gerar checkpoints corretamente

3. **Verifica as atualizações**:
   - Confirma que o hook foi atualizado corretamente

## 🚀 Como Executar

### Pré-requisitos

1. **Chave privada Terra Classic**: A conta deve ser o owner do Warp Route
2. **Luna no Terra Classic Testnet**: Para pagar as taxas de gas

### Execução

```bash
# Definir variável de ambiente
export PRIVATE_KEY="sua_chave_privada_terra_classic_hex"

# Executar o script
npx tsx script/configurar-warp-terra-classic.ts
```

### Exemplo Completo

```bash
# 1. Definir chave privada
export PRIVATE_KEY="a5123190601045e1266e57c5d5b1a77f0897b39ea63ed2c761946686939c3cb6"

# 2. Executar
npx tsx script/configurar-warp-terra-classic.ts
```

## 📊 Configuração Atual vs. Esperada

### Antes da Execução

- **Hook do Warp Route**: `null` (não configurado)

### Depois da Execução

- **Hook do Warp Route**: `terra18shx4zhfehscggs9upspl489qd7yg29vdasvrerytppt3am92mnsj5365s` (defaultHook do Mailbox)

## ⚠️ Importante

1. **Validador e Hook**: O validador precisa monitorar o mesmo hook que o Warp Route está usando. Se o hook do Warp Route for alterado, o validador também precisa ser reconfigurado para monitorar o novo hook.

2. **Owner do Contrato**: O script verifica se a conta usada é o owner do Warp Route. Se não for, o script será interrompido.

3. **Gas Fees**: Certifique-se de ter Luna suficiente no Terra Classic Testnet para pagar as taxas de gas.

## 🔍 Verificação Manual

### Verificar Hook do Warp Route

```bash
terrad query wasm contract-state smart terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml '{"connection":{"get_hook":{}}}' --node https://rpc.luncblaze.com:443
```

### Verificar defaultHook do Mailbox

```bash
terrad query wasm contract-state smart terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm '{"mailbox":{"default_hook":{}}}' --node https://rpc.luncblaze.com:443
```

### Verificar Owner do Warp Route

```bash
terrad query wasm contract-state smart terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml '{"ownable":{"get_owner":{}}}' --node https://rpc.luncblaze.com:443
```

## 📝 Links Úteis

- **Terra Classic Finder**: https://finder.terra-classic.hexxagon.dev/testnet
- **Warp Route**: https://finder.terra-classic.hexxagon.dev/testnet/address/terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
- **Mailbox**: https://finder.terra-classic.hexxagon.dev/testnet/address/terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm
- **defaultHook**: https://finder.terra-classic.hexxagon.dev/testnet/address/terra18shx4zhfehscggs9upspl489qd7yg29vdasvrerytppt3am92mnsj5365s

## 📚 Documentação Relacionada

- [Configuração Warp BSC](./CONFIGURAR-WARP-BSC-TESTNET.md)
- [Configuração Warp Sepolia](./CONFIGURAR-WARP-LUNC-SEPOLIA.md)
- [Governança Testnet](./GOVERNANCE-OPERATIONS-TESTNET.md)

## ✅ Status da Configuração

**Última atualização**: Hook configurado com sucesso!

- ✅ Hook do Warp Route: `terra18shx4zhfehscggs9upspl489qd7yg29vdasvrerytppt3am92mnsj5365s`
- ✅ Transação: `A90E3AA5C756E3A8E97644205461E4DED2751F5B6350BC8BA1BEC47D48F84942`
- ✅ Link: https://finder.terra-classic.hexxagon.dev/testnet/tx/A90E3AA5C756E3A8E97644205461E4DED2751F5B6350BC8BA1BEC47D48F84942
