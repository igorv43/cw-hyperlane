# Atualizar IGP Oracle via Governance

Como o IGP Oracle tem o módulo de governança (`terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`) como owner, você precisa criar uma proposta de governança para atualizar o `token_exchange_rate`.

## Endereços Importantes

- **IGP Oracle**: `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg`
- **Governance Module**: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`

## Criar Proposta de Governance

### Método 1: Usando o Script (Recomendado)

```bash
# Executar o script para gerar o arquivo de proposta
bash script/create-igp-oracle-proposal.sh

# O script criará o arquivo: proposal-igp-oracle-update.json
```

### Método 2: Criar Manualmente

Crie um arquivo `proposal-igp-oracle-update.json`:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg",
      "msg": {
        "set_remote_gas_data_configs": {
          "configs": [
            {
              "remote_domain": 97,
              "token_exchange_rate": "14794529576536",
              "gas_price": "50000000"
            }
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update IGP Oracle exchange rate for BSC Testnet (domain 97) to reflect current BNB price ($897.88). This fixes the gas cost calculation from ~$1512 to ~$0.0045 per cross-chain transfer.",
  "deposit": "500000uluna",
  "title": "Update IGP Oracle Exchange Rate for BSC Testnet",
  "summary": "Update token_exchange_rate from 1805936462255558 to 14794529576536 for BSC Testnet (domain 97) to correctly calculate gas costs. Current rate results in ~$1512 per transfer (incorrect). New rate will result in ~74 LUNC (~$0.0045) per transfer, accurately covering 0.000005 BNB gas cost on BSC.",
  "expedited": false
}
```

## Enviar a Proposta

```bash
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

**Nota:** O depósito inicial é de 0.5 LUNC (500000uluna), que é menor que o depósito mínimo de 1 LUNC (1000000uluna). A proposta entrará em **período de depósito** e precisará atingir o depósito mínimo de 1 LUNC antes de entrar em votação. Outros usuários podem contribuir com depósitos adicionais.

## Período de Depósito

Após enviar, a proposta entrará em **período de depósito**. O depósito inicial é de 1 LUNC (1,000,000 uluna), que é o depósito mínimo. Se você quiser que outros usuários possam contribuir, você pode usar um depósito inicial menor.

### Verificar Status da Proposta

```bash
terrad query gov proposal <PROPOSAL_ID> \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Status esperado:** `DepositPeriod` (período de depósito)

### Adicionar Depósito (se necessário)

Como o depósito inicial é de 0.5 LUNC (500,000 uluna) e o mínimo é 1 LUNC (1,000,000 uluna), você ou outros usuários precisam adicionar mais 0.5 LUNC:

```bash
terrad tx gov deposit <PROPOSAL_ID> 500000uluna \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas-prices 28.5uluna \
  --yes
```

**Nota:** O depósito mínimo é 1,000,000 uluna (1 LUNC). Quando o total de depósitos atingir esse valor, a proposta automaticamente entrará no período de votação. Você pode verificar o total de depósitos com:
```bash
terrad query gov deposits <PROPOSAL_ID> \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

## Votar na Proposta

Após o período de depósito e quando a proposta entrar em **período de votação** (status `VotingPeriod`), anote o `PROPOSAL_ID` e vote:

```bash
terrad tx gov vote <PROPOSAL_ID> yes \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas-prices 28.5uluna \
  --yes
```

## Verificar Status da Proposta

```bash
# Ver detalhes da proposta
terrad query gov proposal <PROPOSAL_ID> \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Ver todas as propostas
terrad query gov proposals \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Ver depósitos da proposta
terrad query gov deposits <PROPOSAL_ID> \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Status possíveis:**
- `DepositPeriod`: Proposta está em período de depósito (aguardando atingir o mínimo)
- `VotingPeriod`: Proposta está em período de votação
- `Passed`: Proposta foi aprovada
- `Rejected`: Proposta foi rejeitada

## Verificar Execução

Após a proposta ser aprovada e executada, verifique se o exchange_rate foi atualizado:

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

# Verificar configuração para domain 97
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"remote_gas_data":{"remote_domain":97}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Expected output:**
```json
{
  "token_exchange_rate": "14794529576536",
  "gas_price": "50000000"
}
```

## Cálculo do Exchange Rate

**Com BNB @ $897.88:**
- Custo em BNB: 0.000005 BNB
- Custo em USD: 0.000005 × $897.88 = $0.004489
- Custo em LUNC: $0.004489 / $0.00006069 = 73.97 LUNC
- Custo em uluna: 73,972,647 uluna
- Exchange rate: `(73,972,647 × 10^18) / (100000 × 50000000) = 14794529576536`

**Nota:** Se o preço do BNB mudar significativamente, você precisará atualizar o exchange_rate novamente via governance.

