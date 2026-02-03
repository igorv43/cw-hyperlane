# Deployments

Este diretório contém os endereços dos contratos deployados.

## Estrutura

Os scripts de deploy salvam os endereços neste formato:

```json
{
  "storageGasOracle": "0x...",
  "interchainGasPaymaster": "0x...",
  "warpRoute": "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4",
  "owner": "0x...",
  "beneficiary": "0x...",
  "configuration": {
    "terraDomain": 1325,
    "terraGasPrice": "28325000000",
    "terraExchangeRate": "1805936462255558",
    "gasOverhead": "200000"
  },
  "deployedAt": "2026-02-03T...",
  "network": "sepolia",
  "deployer": "0x..."
}
```

## Arquivos

- `sepolia-igp-YYYYMMDD-HHMMSS.json` - Deployment do IGP no Sepolia com timestamp

## Segurança

⚠️ **IMPORTANTE:** 
- Estes arquivos podem conter informações sensíveis
- Eles estão no `.gitignore` por padrão
- Faça backup seguro destes endereços
- Não compartilhe publicamente sem revisar
