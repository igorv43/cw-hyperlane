#!/usr/bin/env python3
"""
Script para calcular Token Exchange Rate para IGP Hyperlane
Calcula automaticamente baseado em preços atuais de mercado

Usage:
  python3 script/calcular-exchange-rate.py
  python3 script/calcular-exchange-rate.py --lunc 0.00003674 --eth 2292.94
"""

import argparse
import sys
from decimal import Decimal, getcontext

# Configurar precisão decimal
getcontext().prec = 50


def calcular_exchange_rate_evm(lunc_usd: float, eth_usd: float) -> tuple[int, str]:
    """
    Calcula exchange rate para EVM chains (Sepolia, Ethereum, BSC)
    
    Fórmula: exchange_rate = (LUNC_USD / ETH_USD) × 10^18
    
    Args:
        lunc_usd: Preço do LUNC em USD
        eth_usd: Preço do ETH em USD
    
    Returns:
        Tuple (exchange_rate_int, exchange_rate_str)
    """
    lunc = Decimal(str(lunc_usd))
    eth = Decimal(str(eth_usd))
    
    # Calcular razão
    ratio = lunc / eth
    
    # Aplicar escala 10^18
    scale = Decimal('1000000000000000000')  # 10^18
    exchange_rate = ratio * scale
    
    # Arredondar para inteiro
    exchange_rate_int = int(exchange_rate)
    
    return exchange_rate_int, str(exchange_rate_int)


def calcular_exchange_rate_cosmos(lunc_usd: float, dest_token_usd: float) -> tuple[int, str]:
    """
    Calcula exchange rate para Cosmos chains (Solana, Osmosis, etc)
    
    Fórmula: exchange_rate = (LUNC_USD / DEST_TOKEN_USD) × 10^10
    
    Args:
        lunc_usd: Preço do LUNC em USD
        dest_token_usd: Preço do token de destino em USD
    
    Returns:
        Tuple (exchange_rate_int, exchange_rate_str)
    """
    lunc = Decimal(str(lunc_usd))
    dest = Decimal(str(dest_token_usd))
    
    # Calcular razão
    ratio = lunc / dest
    
    # Aplicar escala 10^10
    scale = Decimal('10000000000')  # 10^10
    exchange_rate = ratio * scale
    
    # Arredondar para inteiro
    exchange_rate_int = int(exchange_rate)
    
    return exchange_rate_int, str(exchange_rate_int)


def calcular_custo_estimado(
    gas_usado: int,
    gas_price: int,
    exchange_rate: int,
    decimals: int = 18
) -> dict:
    """
    Calcula custo estimado de uma transação
    
    Args:
        gas_usado: Gas estimado para a transação
        gas_price: Gas price em unidade base (ex: nano-uluna)
        exchange_rate: Exchange rate calculado
        decimals: Decimais do token de origem (18 para ETH)
    
    Returns:
        Dict com custos calculados
    """
    # Usar Decimal para precisão
    gas = Decimal(gas_usado)
    price = Decimal(gas_price)
    rate = Decimal(exchange_rate)
    scale = Decimal(10 ** decimals)
    
    # Custo em unidade base (wei para ETH)
    # Fórmula: (gas_usado * gas_price * exchange_rate) / 10^decimals
    custo_base = (gas * price * rate) / scale
    custo_base_int = int(custo_base)
    
    # Custo em unidade principal (ETH)
    # Converter de wei para ETH: dividir por 10^18
    custo_principal = float(custo_base_int) / (10 ** decimals)
    
    return {
        'custo_wei': custo_base_int,
        'custo_eth': custo_principal,
        'gas_usado': gas_usado,
        'gas_price': gas_price,
        'exchange_rate': exchange_rate,
    }


def formatar_gas_price(uluna: float) -> tuple[int, str]:
    """
    Converte uluna para unidade base (nano-uluna)
    
    Args:
        uluna: Valor em uluna (micro-LUNC)
    
    Returns:
        Tuple (gas_price_int, gas_price_str)
    """
    # 1 uluna = 10^9 nano-uluna
    gas_price = int(uluna * 1_000_000_000)
    return gas_price, str(gas_price)


def main():
    parser = argparse.ArgumentParser(
        description='Calcular Token Exchange Rate para IGP Hyperlane',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  # Usar valores padrão (LUNC: $0.00003674, ETH: $2,292.94)
  %(prog)s
  
  # Especificar preços customizados
  %(prog)s --lunc 0.00004 --eth 2500
  
  # Calcular para BSC (BNB)
  %(prog)s --lunc 0.00003674 --bnb 350 --chain bsc
  
  # Calcular para Solana
  %(prog)s --lunc 0.00003674 --sol 105 --chain solana
        """
    )
    
    parser.add_argument(
        '--lunc',
        type=float,
        default=0.00003674,
        help='Preço do LUNC em USD (padrão: 0.00003674)'
    )
    
    parser.add_argument(
        '--eth',
        type=float,
        help='Preço do ETH em USD'
    )
    
    parser.add_argument(
        '--bnb',
        type=float,
        help='Preço do BNB em USD (para BSC)'
    )
    
    parser.add_argument(
        '--sol',
        type=float,
        help='Preço do SOL em USD (para Solana)'
    )
    
    parser.add_argument(
        '--chain',
        choices=['sepolia', 'ethereum', 'bsc', 'solana', 'osmosis'],
        default='sepolia',
        help='Chain de destino (padrão: sepolia)'
    )
    
    parser.add_argument(
        '--gas-price-uluna',
        type=float,
        default=38.325,
        help='Gas price em uluna (padrão: 38.325)'
    )
    
    parser.add_argument(
        '--gas-overhead',
        type=int,
        default=200000,
        help='Gas overhead estimado (padrão: 200000)'
    )
    
    args = parser.parse_args()
    
    # Determinar preço do token de destino
    if args.chain in ['sepolia', 'ethereum']:
        if not args.eth:
            print("❌ Erro: Especifique --eth para chains Ethereum/Sepolia", file=sys.stderr)
            sys.exit(1)
        dest_token_usd = args.eth
        dest_token_name = 'ETH'
        is_evm = True
    elif args.chain == 'bsc':
        if not args.bnb:
            print("❌ Erro: Especifique --bnb para BSC", file=sys.stderr)
            sys.exit(1)
        dest_token_usd = args.bnb
        dest_token_name = 'BNB'
        is_evm = True
    elif args.chain == 'solana':
        if not args.sol:
            print("❌ Erro: Especifique --sol para Solana", file=sys.stderr)
            sys.exit(1)
        dest_token_usd = args.sol
        dest_token_name = 'SOL'
        is_evm = False
    elif args.chain == 'osmosis':
        print("❌ Erro: Osmosis não implementado ainda", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"❌ Erro: Chain '{args.chain}' não suportada", file=sys.stderr)
        sys.exit(1)
    
    # Calcular exchange rate
    if is_evm:
        exchange_rate, exchange_rate_str = calcular_exchange_rate_evm(
            args.lunc, dest_token_usd
        )
        scale_text = "10^18 (EVM)"
    else:
        exchange_rate, exchange_rate_str = calcular_exchange_rate_cosmos(
            args.lunc, dest_token_usd
        )
        scale_text = "10^10 (Cosmos)"
    
    # Formatar gas price
    gas_price, gas_price_str = formatar_gas_price(args.gas_price_uluna)
    
    # Calcular custo estimado
    custo = calcular_custo_estimado(
        args.gas_overhead,
        gas_price,
        exchange_rate,
        decimals=18 if is_evm else 9
    )
    
    # Custo em USD
    custo_usd = custo['custo_eth'] * dest_token_usd
    
    # Imprimir resultados
    print("=" * 80)
    print(f"CÁLCULO DE EXCHANGE RATE - {args.chain.upper()}")
    print("=" * 80)
    print()
    
    print("📊 PREÇOS DE MERCADO:")
    print(f"   LUNC: ${args.lunc:.8f}")
    print(f"   {dest_token_name}: ${dest_token_usd:,.2f}")
    print()
    
    print("🧮 CÁLCULO:")
    print(f"   Razão: {args.lunc} / {dest_token_usd} = {args.lunc/dest_token_usd:.15e}")
    print(f"   Escala: {scale_text}")
    print()
    
    print("✅ RESULTADOS:")
    print(f"   Exchange Rate: {exchange_rate_str}")
    print(f"   Gas Price: {gas_price_str} (nano-uluna)")
    print(f"   Gas Price: {args.gas_price_uluna} uluna")
    print()
    
    print("💰 CUSTO ESTIMADO (para {:.0f} gas):".format(args.gas_overhead))
    print(f"   {custo['custo_wei']:,} wei")
    print(f"   {custo['custo_eth']:.18f} {dest_token_name}")
    print(f"   ${custo_usd:.6f} USD")
    print()
    
    print("📋 CONFIGURAÇÃO PARA SCRIPTS:")
    print("-" * 80)
    print(f"export TERRA_EXCHANGE_RATE=\"{exchange_rate_str}\"")
    print(f"export TERRA_GAS_PRICE=\"{gas_price_str}\"")
    print(f"export GAS_OVERHEAD=\"{args.gas_overhead}\"")
    print()
    
    if args.chain in ['sepolia', 'ethereum']:
        print("📋 CONFIGURAÇÃO PARA config-testnet.yaml:")
        print("-" * 80)
        print(f"    11155111:  # Sepolia/Ethereum domain")
        print(f"      exchange_rate: {exchange_rate_str}")
        print(f"      gas_price: {gas_price_str}")
        print()
    
    print("=" * 80)


if __name__ == '__main__':
    main()
