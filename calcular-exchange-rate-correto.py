#!/usr/bin/env python3
"""
Cálculo correto do Exchange Rate usando TOKEN_EXCHANGE_RATE_SCALE = 1e10
Baseado no código oficial do InterchainGasPaymaster.sol do Hyperlane
"""

# ============ Preços de Mercado ============
LUNC_PRICE_USD = 0.00003674
ETH_PRICE_USD = 2292.94

# ============ Valores Desejados ============
DESIRED_COST_USD = 0.50  # Custo desejado por transferência em USD
GAS_AMOUNT = 200000  # Gas amount padrão para execução na chain de destino
GAS_OVERHEAD = 200000  # Gas overhead (Mailbox + ISM)

# ============ Constante Oficial do Hyperlane ============
TOKEN_EXCHANGE_RATE_SCALE = 1e10  # !!! CORRETO: 1e10, não 1e18 !!!

print("╔════════════════════════════════════════════════════════════════════╗")
print("║                                                                    ║")
print("║         CÁLCULO CORRETO DE EXCHANGE RATE - HYPERLANE V3          ║")
print("║                                                                    ║")
print("║        TOKEN_EXCHANGE_RATE_SCALE = 1e10 (NÃO 1e18!)              ║")
print("║                                                                    ║")
print("╚════════════════════════════════════════════════════════════════════╝")
print()

print("📊 PREÇOS DE MERCADO:")
print(f"   • LUNC: ${LUNC_PRICE_USD}")
print(f"   • ETH: ${ETH_PRICE_USD}")
print()

print("🎯 OBJETIVO:")
print(f"   • Custo desejado por transferência: ${DESIRED_COST_USD} USD")
print(f"   • Gas amount (aplicação): {GAS_AMOUNT:,}")
print(f"   • Gas overhead (Mailbox + ISM): {GAS_OVERHEAD:,}")
print(f"   • Total gas: {GAS_AMOUNT + GAS_OVERHEAD:,}")
print()

# ============ Cálculo do Custo em ETH e WEI ============
cost_in_eth = DESIRED_COST_USD / ETH_PRICE_USD
cost_in_wei = cost_in_eth * 1e18

print("💰 CUSTO EM ETH/WEI:")
print(f"   • {cost_in_eth:.10f} ETH")
print(f"   • {cost_in_wei:.0f} WEI")
print()

# ============ Definir Gas Price ============
# Vamos usar 38.325 Gwei como gas price (equivalente a 38.325 uluna)
GAS_PRICE_GWEI = 38.325
GAS_PRICE_WEI = int(GAS_PRICE_GWEI * 1e9)

print("⛽ GAS PRICE:")
print(f"   • {GAS_PRICE_GWEI} Gwei")
print(f"   • {GAS_PRICE_WEI:,} WEI")
print()

# ============ Calcular Exchange Rate ============
# Fórmula do InterchainGasPaymaster.sol (linha 211-212):
# return (_destinationGasCost * _tokenExchangeRate) / TOKEN_EXCHANGE_RATE_SCALE;
# 
# Onde _destinationGasCost = gasLimit * gasPrice
#
# Rearranjando para _tokenExchangeRate:
# _tokenExchangeRate = (cost_in_wei * TOKEN_EXCHANGE_RATE_SCALE) / (gasLimit * gasPrice)

total_gas = GAS_AMOUNT + GAS_OVERHEAD
exchange_rate = (cost_in_wei * TOKEN_EXCHANGE_RATE_SCALE) / (total_gas * GAS_PRICE_WEI)
exchange_rate = int(exchange_rate)

print("🧮 CÁLCULO DO EXCHANGE RATE:")
print(f"   • Fórmula: (cost_in_wei × SCALE) / (total_gas × gas_price)")
print(f"   • Fórmula: ({cost_in_wei:.0f} × {TOKEN_EXCHANGE_RATE_SCALE:.0e}) / ({total_gas:,} × {GAS_PRICE_WEI:,})")
print()

print("✅ RESULTADOS FINAIS:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"   Token Exchange Rate: {exchange_rate:,}")
print(f"   Gas Price: {GAS_PRICE_WEI:,} (WEI)")
print(f"   Gas Price: {GAS_PRICE_GWEI} Gwei")
print(f"   Gas Overhead: {GAS_OVERHEAD:,}")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

# ============ Verificação ============
# Calcular custo com os valores obtidos para confirmar
destination_gas_cost = total_gas * GAS_PRICE_WEI
calculated_cost_wei = (destination_gas_cost * exchange_rate) / TOKEN_EXCHANGE_RATE_SCALE
calculated_cost_eth = calculated_cost_wei / 1e18
calculated_cost_usd = calculated_cost_eth * ETH_PRICE_USD

print("🔍 VERIFICAÇÃO:")
print(f"   • Custo calculado: {calculated_cost_wei:.0f} WEI")
print(f"   • Custo calculado: {calculated_cost_eth:.10f} ETH")
print(f"   • Custo calculado: ${calculated_cost_usd:.6f} USD")
print(f"   • Diferença do objetivo: ${abs(calculated_cost_usd - DESIRED_COST_USD):.6f} USD")
print()

if abs(calculated_cost_usd - DESIRED_COST_USD) < 0.01:
    print("   ✅ VERIFICAÇÃO OK! Custo está dentro da margem aceitável")
else:
    print("   ⚠️  ATENÇÃO: Diferença significativa detectada")
print()

# ============ Configuração para Scripts ============
print("📋 CONFIGURAÇÃO PARA SCRIPTS:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f'export TERRA_EXCHANGE_RATE="{exchange_rate}"')
print(f'export TERRA_GAS_PRICE="{GAS_PRICE_WEI}"')
print(f'export GAS_OVERHEAD="{GAS_OVERHEAD}"')
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

# ============ Configuração para Solidity ============
print("📋 VALORES PARA DEPLOY DO STORAGEGAS ORACLE:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"   remoteDomain: 1325")
print(f"   tokenExchangeRate: {exchange_rate}")
print(f"   gasPrice: {GAS_PRICE_WEI}")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

print("╔════════════════════════════════════════════════════════════════════╗")
print("║                                                                    ║")
print("║                    ✅ CÁLCULO CONCLUÍDO!                          ║")
print("║                                                                    ║")
print("╚════════════════════════════════════════════════════════════════════╝")
