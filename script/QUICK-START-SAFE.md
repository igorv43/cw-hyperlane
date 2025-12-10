# Guia Rápido - Executar Transação Safe

## ⚡ Instalação Rápida do Safe CLI (Recomendado)

Antes de usar os scripts Python, considere instalar o Safe CLI oficial do Node.js:

```bash
# Instalar Safe CLI oficial
npm install -g @safe-global/safe-cli

# Verificar instalação
safe --version

# Consultar informações do Safe (formato EIP-3770: shortName:address)
safe account info bnb:0xSEU_SAFE

# Listar transações pendentes
safe tx list bnb:0xSEU_SAFE

# Ver status de uma transação
safe tx status <SAFE_TX_HASH>
```

**⚠️ IMPORTANTE:** O Safe CLI usa formato EIP-3770 (`shortName:address`), não `--address` ou `--chain-id`.

**ShortNames comuns:**
- BSC Mainnet (56): `bnb`
- BSC Testnet (97): `tbnb` (adicionar com `safe config chains add`)
- Ethereum Mainnet (1): `eth`
- Sepolia Testnet (11155111): `sep`

**Adicionar BSC Testnet:**
```bash
safe config chains add
# Informe: Chain ID: 97, Name: BSC Testnet, Short name: tbnb, RPC: https://data-seed-prebsc-1-s1.binance.org:8545
```

**Abrir Safe na BSC Testnet:**
```bash
safe account open tbnb:0xSEU_SAFE --name "BSC Testnet Safe"
```

Para mais detalhes, consulte o [Guia Completo do Safe CLI](SAFE-SCRIPTS-GUIDE.md#-instalação-do-safe-cli-oficial-recomendado).

---

## 📝 Usando Scripts Python (Alternativa)

### 1. Verificar Assinaturas

```bash
python3 script/safe-check-signatures.py <SAFE_TX_HASH>
```

**Exemplo:**
```bash
python3 script/safe-check-signatures.py 0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367
```

**O que mostra:**
- Threshold necessário
- Quantas aprovações já foram feitas
- Quais owners aprovaram
- Se está pronto para execução

## 2. Executar Transação

**⚠️ IMPORTANTE: Você precisa do CALLDATA original!**

```bash
python3 script/safe-execute-complete.py <PRIVATE_KEY> <CALLDATA> [SAFE_TX_HASH]
```

**Exemplo:**
```bash
# Se você tem o CALLDATA
CALLDATA=0x3f4ba83a...
python3 script/safe-execute-complete.py \
  0x819b680e3578eac4f79b8fde643046e88f.... \
  $CALLDATA \
  0x73b17378c1d8d5a48dd32dc483faa17aa6e23538ff5e68473f634b91cfe49367
```

## Por que preciso do CALLDATA?

O Safe TX Hash é apenas um **identificador** da proposta. Ele não contém:
- Endereço destino (to)
- Valor (value)  
- Dados da função (data/calldata)

Para executar, o Safe precisa reconstruir a transação com os mesmos dados da proposta original.

## Se você não tem o CALLDATA

1. **Verifique o histórico da proposta** - onde você criou a proposta originalmente
2. **Use o mesmo CALLDATA** que você usou em `safe-propose-direct.py`
3. **Ou recrie a proposta** com os mesmos dados

## Resumo dos Scripts

| Script | Uso |
|--------|-----|
| `safe-check-signatures.py` | Verificar quantas assinaturas são necessárias |
| `safe-execute-complete.py` | Executar transação (requer CALLDATA) |
| `safe-propose-direct.py` | Criar nova proposta |
| `safe-confirm.py` | Confirmar proposta existente |

