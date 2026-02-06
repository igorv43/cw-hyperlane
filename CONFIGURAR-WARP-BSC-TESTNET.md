# Configuração do Warp Route BSC Testnet

Este documento descreve como configurar o Warp Route para BSC Testnet, incluindo a atualização do ISM (Interchain Security Module) e do Hook.

## 📋 Informações da Configuração

### Contratos BSC Testnet

- **Warp Route**: `0x2144Be4477202ba2d50c9A8be3181241878cf7D8`
- **Mailbox**: `0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D`
- **Merkle Tree Hook**: `0xc6cbF39A747f5E28d1bDc8D9dfDAb2960Abd5A8f`
- **ISM Multisig (EVM)**: `0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA`

### Contratos Terra Classic Testnet

- **ISM Multisig BSC**: `terra1ksq6cekt0as2f9vv5txld90s854y4pkr2k0jn5p83vqpa5zzzfysuavxr0`
- **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze` (não requer governança)
- **Domain ID**: `97` (BSC Testnet)

### Configuração de Validadores

- **Threshold**: `1` (1 de 1 validadores)
- **Validators**:
  - `0x8bd456605473ad4727acfdca0040a0dbd4be2dea` (Abacus Works Validator 1)

## 🔧 O que o Script Faz

O script `configurar-warp-bsc.ts` realiza as seguintes operações:

1. **Consulta a configuração atual**:
   - Hook atual do Warp Route
   - ISM atual do Warp Route
   - defaultHook do Mailbox

2. **Configura validadores no Terra Classic**:
   - Atualiza o ISM Multisig BSC no Terra Classic com os novos validadores
   - Define threshold e lista de validadores para o domain 97 (BSC Testnet)

3. **Atualiza o Hook do Warp Route (BSC)**:
   - Define o hook do Warp Route para o `merkleTreeHook` fornecido
   - Garante que o validador possa monitorar e gerar checkpoints corretamente

4. **Atualiza o ISM do Warp Route (BSC)**:
   - Define o ISM do Warp Route para o `ISM_MULTISIG_BSC_EVM`
   - Garante que as mensagens sejam validadas corretamente

5. **Verifica as atualizações**:
   - Confirma que o hook foi atualizado corretamente
   - Confirma que o ISM foi atualizado corretamente

## 🚀 Como Executar

### Pré-requisitos

1. **Chave privada Terra Classic**: Para configurar os validadores no ISM Multisig BSC
2. **Chave privada BSC**: Para atualizar o Warp Route no BSC Testnet
3. **BNB no BSC Testnet**: Para pagar as taxas de gas

### Execução

```bash
# Definir variáveis de ambiente
export PRIVATE_KEY="sua_chave_privada_terra_classic_hex"
export BSC_PRIVATE_KEY="sua_chave_privada_bsc_hex"

# Executar o script
npx tsx script/configurar-warp-bsc.ts
```

### Exemplo Completo

```bash
# 1. Definir chaves privadas
export PRIVATE_KEY="a5123190601045e1266e57c5d5b1a77f0897b39ea63ed2c761946686939c3cb6"
export BSC_PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"

# 2. Executar
npx tsx script/configurar-warp-bsc.ts
```

## 📊 Configuração Atual vs. Esperada

### Antes da Execução

- **Hook do Warp Route**: `0xdFb118e0a9B4a4c523A2297F73a87b58E9795E6E`
- **ISM do Warp Route**: `0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA`
- **Validadores**: 3 validadores com threshold 2/3

### Depois da Execução

- **Hook do Warp Route**: `0xc6cbF39A747f5E28d1bDc8D9dfDAb2960Abd5A8f` (merkleTreeHook)
- **ISM do Warp Route**: `0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA` (mantém o mesmo)
- **Validadores**: 1 validador com threshold 1/1

## ⚠️ Importante

1. **Validador e Hook**: O validador precisa monitorar o mesmo hook que o Warp Route está usando. Se o hook do Warp Route for alterado, o validador também precisa ser reconfigurado para monitorar o novo hook.

2. **Owner dos Contratos**:
   - O ISM Multisig BSC no Terra Classic precisa ter o owner correto (verificar com `terrad query wasm contract-state smart terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv '{"ownable":{"get_owner":{}}}'`)
   - O Warp Route BSC precisa ter o owner correto (verificar no BscScan)

3. **Gas Fees**: Certifique-se de ter BNB suficiente no BSC Testnet para pagar as taxas de gas.

## 🔍 Verificação Manual

### Verificar Hook do Warp Route

```bash
cast call 0x2144Be4477202ba2d50c9A8be3181241878cf7D8 "hook()(address)" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

### Verificar ISM do Warp Route

```bash
cast call 0x2144Be4477202ba2d50c9A8be3181241878cf7D8 "interchainSecurityModule()(address)" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

### Verificar Validadores no Terra Classic

```bash
terrad query wasm contract-state smart terra1ksq6cekt0as2f9vv5txld90s854y4pkr2k0jn5p83vqpa5zzzfysuavxr0 '{"multisig_ism":{"enrolled_validators":{"domain":97}}}' --node https://rpc.luncblaze.com:443
```

## 📝 Links Úteis

- **BscScan Testnet**: https://testnet.bscscan.com
- **Terra Classic Finder**: https://finder.terra-classic.hexxagon.dev/testnet
- **Warp Route**: https://testnet.bscscan.com/address/0x2144Be4477202ba2d50c9A8be3181241878cf7D8
- **Mailbox**: https://testnet.bscscan.com/address/0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D
- **Merkle Tree Hook**: https://testnet.bscscan.com/address/0xc6cbF39A747f5E28d1bDc8D9dfDAb2960Abd5A8f
- **ISM Multisig Terra**: https://finder.terra-classic.hexxagon.dev/testnet/address/terra1ksq6cekt0as2f9vv5txld90s854y4pkr2k0jn5p83vqpa5zzzfysuavxr0

## 🔄 Alteração de Validadores

### Com Governança

Se o ISM Multisig BSC for owned pela governança, você precisará criar uma proposta de governança para alterar os validadores. Veja `script/submit-proposal-testnet.ts` para um exemplo.

### Sem Governança

O ISM Multisig BSC (`terra1ksq6cekt0as2f9vv5txld90s854y4pkr2k0jn5p83vqpa5zzzfysuavxr0`) é owned por `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`, então você pode executar diretamente:

```bash
export PRIVATE_KEY="sua_chave_privada_terra_classic_hex"
npx tsx script/configurar-warp-bsc.ts
```

O script irá configurar os validadores automaticamente.

## 📚 Documentação Relacionada

- [Configuração Warp Sepolia](./CONFIGURAR-WARP-LUNC-SEPOLIA.md)
- [Governança Testnet](./GOVERNANCE-OPERATIONS-TESTNET.md)
