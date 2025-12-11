# Comando para Atualizar IGP Oracle Exchange Rate

## ⚠️ IMPORTANTE: Atualização via Governance

O IGP Oracle tem o módulo de governança (`terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`) como owner. **Você NÃO pode executar diretamente**. É necessário criar uma proposta de governança.

**Veja:** `UPDATE-IGP-ORACLE-GOVERNANCE.md` para instruções completas.

## Método Rápido: Usar o Script

```bash
# 1. Gerar arquivo de proposta
bash script/create-igp-oracle-proposal.sh

# 2. Enviar a proposta
terrad tx gov submit-proposal proposal-igp-oracle-update.json \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --yes
```

## ❌ Comando Direto (NÃO FUNCIONA - Retorna "unauthorized")

O comando abaixo **NÃO funcionará** porque o contrato requer permissão do owner (governance):

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
KEY_NAME="hypelane-val-testnet"

terrad tx wasm execute ${IGP_ORACLE} \
  '{"set_remote_gas_data_configs":{"configs":[{"remote_domain":97,"token_exchange_rate":"14794529576536","gas_price":"50000000"}]}}' \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes

# Erro esperado: "unauthorized: execute wasm contract failed"
```

**Cálculo do Exchange Rate (com BNB @ $897.88):**
- Custo real: 100000 gas × 50000000 wei = 0.000005 BNB
- Custo em USD: 0.000005 BNB × $897.88 = $0.004489
- Custo em LUNC: $0.004489 / $0.00006069 = 73.97 LUNC = 73,972,647 uluna
- Exchange rate: (73,972,647 × 10^18) / (100000 × 50000000) = 14794529576536
- **Resultado:** ~74 LUNC para pagar gas no BSC (cobre 0.000005 BNB = $0.004489)

## Verificação Após Atualização

### 1. Verificar configuração do Oracle

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output:**
```json
{
  "token_exchange_rate": "14794529576536",
  "gas_price": "50000000"
}
```

**Nota:** Este exchange_rate está baseado no preço atual do BNB ($897.88). Se o preço do BNB mudar significativamente, você precisará atualizar o exchange_rate novamente.

### 2. Verificar cálculo do IGP

```bash
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":97,"gas_amount":"100000"}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output:**
```
data:
  gas_needed: "73972647"  # ~74 LUNC = $0.004489 (não 902 trilhões ou $1512!)
```

## Valores

- **Valor atual (incorreto)**: `1805936462255558` → resulta em 902 trilhões uluna ou $1512.01
- **Valor recomendado**: `14794529576536` → resulta em 73,972,647 uluna (~74 LUNC = $0.004489)
- **Gas price**: `50000000` (mantém o mesmo)

**Cálculo do Exchange Rate (BNB @ $897.88):**
- Custo necessário: 73,972,647 uluna (para pagar 0.000005 BNB de gas)
- Fórmula: `exchange_rate = (cost_uluna × 10^18) / (gas × gas_price)`
- Exchange rate: `(73,972,647 × 10^18) / (100000 × 50000000) = 14794529576536`

**Nota:** O exchange_rate precisa ser atualizado quando o preço do BNB muda significativamente.

## Após Atualização

Depois de atualizar, tente o transfer novamente:

```bash
terrad tx wasm execute terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8 \
  '{"transfer_remote":{"dest_domain":97,"recipient":"00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3","amount":"1"}}' \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount 283216uluna \
  --yes
```

O custo total deve ser aproximadamente 74,255,862 uluna (73,972,647 IGP + 283215 hook fee = ~74.26 LUNC = $0.0045) em vez de 902 trilhões ou $1512!

## Documentação Completa

Para instruções detalhadas sobre como criar e enviar a proposta de governança, consulte:
- **`UPDATE-IGP-ORACLE-GOVERNANCE.md`** - Guia completo passo a passo

