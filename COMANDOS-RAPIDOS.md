# ⚡ COMANDOS RÁPIDOS

## 📖 Ver Documentação

```bash
# Resumo executivo completo
cat /home/lunc/cw-hyperlane/RESUMO-ANALISE-E-SOLUCAO.md

# Guia de deploy via Remix
cat /home/lunc/cw-hyperlane/DEPLOY-REMIX-CORRETO.md

# Ver contrato TerraClassicIGP
cat /home/lunc/cw-hyperlane/TerraClassicIGP.sol
```

## 🧮 Recalcular Valores

```bash
# Executar script Python para recalcular exchange rate
python3 /home/lunc/cw-hyperlane/calcular-exchange-rate-correto.py
```

## 🔗 Associar IGP ao Warp Route

```bash
# Após fazer deploy no Remix, execute:
export IGP_ADDRESS="<seu_endereço_igp>"
export SEPOLIA_PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"

/home/lunc/cw-hyperlane/associar-igp-ao-warp.sh
```

## 🔍 Verificar Configuração Atual

```bash
RPC="https://1rpc.io/sepolia"
WARP="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
ORACLE="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"

# Ver hook atual do Warp Route
echo "Hook do Warp Route:"
cast call $WARP "hook()(address)" --rpc-url $RPC

# Ver dados do Oracle para Terra Classic
echo -e "\nOracle data (Terra 1325):"
cast call $ORACLE "remoteGasData(uint32)((uint128,uint128))" 1325 --rpc-url $RPC

# Ver saldo da carteira
echo -e "\nSaldo:"
cast balance 0x133fD7F7094DBd17b576907d052a5aCBd48dB526 --rpc-url $RPC | \
  xargs -I {} cast --to-unit {} ether
```

## 🧪 Testar IGP Deployado

```bash
# Substitua pelo endereço do seu IGP deployado
IGP="<seu_endereço_igp>"
RPC="https://1rpc.io/sepolia"

# Ver hook type (deve ser 4 para IGP)
echo "Hook Type:"
cast call $IGP "hookType()(uint8)" --rpc-url $RPC

# Ver gas oracle
echo -e "\nGas Oracle:"
cast call $IGP "gasOracle()(address)" --rpc-url $RPC

# Ver gas overhead
echo -e "\nGas Overhead:"
cast call $IGP "gasOverhead()(uint96)" --rpc-url $RPC

# Ver beneficiary
echo -e "\nBeneficiary:"
cast call $IGP "beneficiary()(address)" --rpc-url $RPC

# Ver owner
echo -e "\nOwner:"
cast call $IGP "owner()(address)" --rpc-url $RPC
```

## 📦 Deploy Alternativo (se Remix falhar)

```bash
# Tentar deploy via Foundry (pode dar erro de permissão)
cd /home/lunc/cw-hyperlane

forge create \
  TerraClassicIGP.sol:TerraClassicIGP \
  --rpc-url https://1rpc.io/sepolia \
  --private-key 0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5 \
  --constructor-args \
    "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c" \
    "200000" \
    "0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
```

## 🌐 Links Úteis

```bash
# Remix IDE
echo "https://remix.ethereum.org"

# Sepolia Etherscan
echo "https://sepolia.etherscan.io"

# Sepolia Faucet
echo "https://sepoliafaucet.com"

# Hyperlane Docs
echo "https://docs.hyperlane.xyz"
```

## 📁 Arquivos Importantes

```bash
# Listar todos os arquivos criados
ls -lh /home/lunc/cw-hyperlane/ | grep -E '\.(sol|md|sh|py|txt)$'
```

## ✅ Valores Corretos (Escala 1e10)

```
Terra Classic Domain:      1325
Token Exchange Rate:       142,244,393
Gas Price:                 38,325,000,000 WEI (38.325 Gwei)
Gas Overhead:              200,000
Warp Route:                0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
StorageGasOracle:          0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
Owner/Beneficiary:         0x133fD7F7094DBd17b576907d052a5aCBd48dB526

Custo estimado: ~$0.50 USD por transferência
```

## 🎯 Workflow Completo

```bash
# 1. Ver o guia
cat /home/lunc/cw-hyperlane/DEPLOY-REMIX-CORRETO.md

# 2. Deploy no Remix IDE
# (Manual - seguir guia acima)

# 3. Salvar endereço do IGP
export IGP_ADDRESS="<endereço_deployado>"

# 4. Associar ao Warp Route
/home/lunc/cw-hyperlane/associar-igp-ao-warp.sh

# 5. Testar transferência
# (No frontend do Warp Route)
```

## 🔄 Atualizar Configuração do Oracle

```bash
# Se precisar reconfigurar o Oracle com novos valores
RPC="https://1rpc.io/sepolia"
ORACLE="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"

# Criar calldata para setRemoteGasDataConfigs
CALLDATA=$(cast calldata "setRemoteGasDataConfigs((uint32,uint128,uint128)[])" \
  "[(1325,142244393,38325000000)]")

# Enviar transação
cast send $ORACLE \
  --rpc-url $RPC \
  --private-key $PRIVATE_KEY \
  "$CALLDATA"
```

## 🆘 Troubleshooting

```bash
# Se cast/forge não funcionar
echo "Use Remix IDE: https://remix.ethereum.org"

# Se aparecer erro de saldo
echo "Obter Sepolia ETH: https://sepoliafaucet.com"
echo "Endereço: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526"

# Se aparecer "destination not supported"
echo "Verifique se está usando escala 1e10 (não 1e18!)"
echo "Exchange Rate correto: 142244393"

# Verificar documentação
cat /home/lunc/cw-hyperlane/RESUMO-ANALISE-E-SOLUCAO.md
```

---

**Tudo pronto!** 🚀

Comece com:
```bash
cat /home/lunc/cw-hyperlane/DEPLOY-REMIX-CORRETO.md
```
