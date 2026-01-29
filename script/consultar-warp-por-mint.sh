#!/bin/bash
# Script: consultar-warp-por-mint.sh
# Descrição: Consulta informações completas do warp route Solana a partir do mint address
# Uso: ./consultar-warp-por-mint.sh <MINT_ADDRESS> [PROGRAM_ID]

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Verificar argumentos
if [ $# -lt 1 ]; then
    echo -e "${RED}❌ Erro: Mint address é obrigatório${NC}"
    echo ""
    echo "Uso: $0 <MINT_ADDRESS> [PROGRAM_ID]"
    echo ""
    echo "Exemplo:"
    echo "  $0 3yhG9dDHVX6K1duf8znEcaJcuTiKSLYvfBD4xy6akxfu"
    echo "  $0 3yhG9dDHVX6K1duf8znEcaJcuTiKSLYvfBD4xy6akxfu HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
    exit 1
fi

MINT_ADDRESS="$1"
PROGRAM_ID="${2:-}"  # Opcional
TERRA_DOMAIN="1325"  # Terra Classic domain
RPC_URL="${RPC_URL:-https://api.testnet.solana.com}"
KEYPAIR="${KEYPAIR:-/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json}"
CLIENT_DIR="${CLIENT_DIR:-$HOME/hyperlane-monorepo/rust/sealevel/client}"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CONSULTAR WARP ROUTE POR MINT ADDRESS                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Mint Address:${NC} ${GREEN}${MINT_ADDRESS}${NC}"
echo ""

# Verificar se o diretório do client existe
if [ ! -d "$CLIENT_DIR" ]; then
    echo -e "${RED}❌ Erro: Diretório do client não encontrado: $CLIENT_DIR${NC}"
    exit 1
fi

cd "$CLIENT_DIR"

# Se o PROGRAM_ID não foi fornecido, tentar encontrar
if [ -z "$PROGRAM_ID" ]; then
    echo -e "${YELLOW}🔍 Program ID não fornecido. Tentando encontrar...${NC}"
    echo ""
    
    # Tentar alguns program IDs conhecidos
    KNOWN_PROGRAM_IDS=(
        "HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"  # lunc-solana-v2
        "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"  # lunc-solana-v1
    )
    
    PROGRAM_ID_FOUND=""
    for TEST_PROGRAM_ID in "${KNOWN_PROGRAM_IDS[@]}"; do
        echo -e "${CYAN}   Testando: ${TEST_PROGRAM_ID}${NC}"
        TEST_MINT=$(cargo run -- \
            -k "$KEYPAIR" \
            -u "$RPC_URL" \
            token query \
            --program-id "$TEST_PROGRAM_ID" \
            synthetic 2>/dev/null | jq -r '.mint // empty' || echo "")
        
        if [ "$TEST_MINT" = "$MINT_ADDRESS" ]; then
            PROGRAM_ID_FOUND="$TEST_PROGRAM_ID"
            echo -e "${GREEN}   ✅ Encontrado!${NC}"
            break
        fi
    done
    
    if [ -z "$PROGRAM_ID_FOUND" ]; then
        echo -e "${RED}❌ Não foi possível encontrar o Program ID automaticamente${NC}"
        echo -e "${YELLOW}   Por favor, forneça o Program ID como segundo argumento${NC}"
        exit 1
    fi
    
    PROGRAM_ID="$PROGRAM_ID_FOUND"
fi

echo -e "${CYAN}Program ID:${NC} ${GREEN}${PROGRAM_ID}${NC}"
echo ""

# 1. Consultar informações do token sintético
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1️⃣  INFORMAÇÕES DO TOKEN SINTÉTICO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOKEN_INFO=$(cargo run -- \
    -k "$KEYPAIR" \
    -u "$RPC_URL" \
    token query \
    --program-id "$PROGRAM_ID" \
    synthetic 2>/dev/null || echo "{}")

if [ -z "$TOKEN_INFO" ] || [ "$TOKEN_INFO" = "{}" ]; then
    echo -e "${RED}❌ Erro: Não foi possível consultar informações do token${NC}"
    exit 1
fi

echo "$TOKEN_INFO" | jq '{
    mint,
    name,
    symbol,
    decimals,
    total_supply
}'

MINT_FROM_QUERY=$(echo "$TOKEN_INFO" | jq -r '.mint // empty')
if [ "$MINT_FROM_QUERY" != "$MINT_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️  Aviso: O mint retornado (${MINT_FROM_QUERY}) não corresponde ao fornecido${NC}"
fi

echo ""

# 2. Consultar informações do warp route (mailbox, ISM, etc)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2️⃣  INFORMAÇÕES DO WARP ROUTE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Extrair informações do token query
MAILBOX=$(echo "$TOKEN_INFO" | jq -r '.mailbox // "N/A"')
ISM=$(echo "$TOKEN_INFO" | jq -r '.ism // "N/A"')

echo -e "${CYAN}Program ID (Base58):${NC} ${GREEN}${PROGRAM_ID}${NC}"

# Converter Program ID para hex
PROGRAM_ID_HEX=$(echo "$PROGRAM_ID" | base58 -d 2>/dev/null | xxd -p -c 32 | tr -d '\n' || echo "N/A")
if [ "$PROGRAM_ID_HEX" != "N/A" ]; then
    echo -e "${CYAN}Program ID (Hex):${NC} ${GREEN}${PROGRAM_ID_HEX}${NC}"
fi

echo ""
echo -e "${CYAN}Mailbox:${NC} ${GREEN}${MAILBOX}${NC}"
echo -e "${CYAN}ISM:${NC} ${GREEN}${ISM}${NC}"
echo ""

# 3. Consultar Remote Router para Terra Classic
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3️⃣  REMOTE ROUTER: Solana → Terra Classic${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

REMOTE_ROUTER_INFO=$(cargo run -- \
    -k "$KEYPAIR" \
    -u "$RPC_URL" \
    token query \
    --program-id "$PROGRAM_ID" \
    synthetic 2>/dev/null | jq -r ".remote_routers[] | select(.domain == $TERRA_DOMAIN) // empty" || echo "")

if [ -n "$REMOTE_ROUTER_INFO" ] && [ "$REMOTE_ROUTER_INFO" != "null" ]; then
    REMOTE_ROUTER_HEX=$(echo "$REMOTE_ROUTER_INFO" | jq -r '.router // empty')
    REMOTE_ROUTER_DOMAIN=$(echo "$REMOTE_ROUTER_INFO" | jq -r '.domain // empty')
    
    echo -e "${GREEN}✅ Remote Router configurado!${NC}"
    echo ""
    echo -e "${CYAN}Domain:${NC} ${GREEN}${REMOTE_ROUTER_DOMAIN}${NC} (Terra Classic)"
    echo -e "${CYAN}Router (Hex):${NC} ${GREEN}${REMOTE_ROUTER_HEX}${NC}"
    
    # Converter hex para bech32 (Terra Classic)
    if [ -n "$REMOTE_ROUTER_HEX" ] && [ "$REMOTE_ROUTER_HEX" != "null" ] && [ "$REMOTE_ROUTER_HEX" != "N/A" ]; then
        # Remover 0x se presente
        REMOTE_ROUTER_HEX_CLEAN=$(echo "$REMOTE_ROUTER_HEX" | sed 's/^0x//')
        
        # Converter para bech32 usando cw-hpl
        if command -v yarn &> /dev/null && [ -f "$HOME/cw-hyperlane/package.json" ]; then
            cd "$HOME/cw-hyperlane"
            REMOTE_ROUTER_BECH32=$(yarn cw-hpl wallet hex-to-bech32 "$REMOTE_ROUTER_HEX_CLEAN" 2>/dev/null || echo "N/A")
            cd "$CLIENT_DIR"
            
            if [ "$REMOTE_ROUTER_BECH32" != "N/A" ] && [ -n "$REMOTE_ROUTER_BECH32" ]; then
                echo -e "${CYAN}Router (Bech32):${NC} ${GREEN}${REMOTE_ROUTER_BECH32}${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Remote Router para Terra Classic não configurado${NC}"
fi

echo ""

# 4. Verificar no Terra Classic se o link está configurado
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4️⃣  VERIFICAÇÃO NO TERRA CLASSIC${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -n "$REMOTE_ROUTER_HEX" ] && [ "$REMOTE_ROUTER_HEX" != "null" ] && [ "$REMOTE_ROUTER_HEX" != "N/A" ]; then
    # Tentar encontrar o warp route no Terra Classic que tem este router configurado
    # Vamos verificar os warp routes conhecidos
    KNOWN_TERRA_WARPS=(
        "terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"  # wwwwlunc
        "terra1rnpvpwvqcf94keldtm2udt4tqhwthpw5cu94m443rz5ue7rvvkjq9nklml"  # wwwustc
    )
    
    SOLANA_DOMAIN="1399811150"
    FOUND_WARP=""
    
    for TERRA_WARP in "${KNOWN_TERRA_WARPS[@]}"; do
        TERRA_ROUTE=$(terrad query wasm contract-state smart "$TERRA_WARP" \
            "{\"router\":{\"get_route\":{\"domain\":${SOLANA_DOMAIN}}}}" \
            --chain-id "$CHAIN_ID" \
            --node "$NODE" \
            --output json 2>/dev/null | jq -r '.data.route // empty' || echo "")
        
        if [ -n "$TERRA_ROUTE" ] && [ "$TERRA_ROUTE" != "null" ]; then
            # Converter para hex para comparar
            TERRA_ROUTE_HEX=$(echo "$TERRA_ROUTE" | sed 's/^0x//' | tr '[:upper:]' '[:lower:]')
            REMOTE_ROUTER_HEX_CLEAN_COMPARE=$(echo "$REMOTE_ROUTER_HEX" | sed 's/^0x//' | tr '[:upper:]' '[:lower:]')
            
            # Comparar (pode ter padding diferente, então vamos comparar os últimos 64 caracteres)
            TERRA_ROUTE_HEX_LAST64=$(echo "$TERRA_ROUTE_HEX" | tail -c 65)
            REMOTE_ROUTER_HEX_LAST64=$(echo "$REMOTE_ROUTER_HEX_CLEAN_COMPARE" | tail -c 65)
            
            if [ "$TERRA_ROUTE_HEX_LAST64" = "$REMOTE_ROUTER_HEX_LAST64" ] || [ "$TERRA_ROUTE_HEX" = "$REMOTE_ROUTER_HEX_CLEAN_COMPARE" ]; then
                FOUND_WARP="$TERRA_WARP"
                break
            fi
        fi
    done
    
    if [ -n "$FOUND_WARP" ]; then
        echo -e "${GREEN}✅ Link bidirecional confirmado!${NC}"
        echo ""
        echo -e "${CYAN}Terra Classic Warp Route:${NC} ${GREEN}${FOUND_WARP}${NC}"
        
        # Converter Program ID Solana para hex e verificar se corresponde
        if [ "$PROGRAM_ID_HEX" != "N/A" ]; then
            PROGRAM_ID_HEX_CLEAN=$(echo "$PROGRAM_ID_HEX" | sed 's/^0x//' | tr '[:upper:]' '[:lower:]')
            TERRA_ROUTE_FULL=$(terrad query wasm contract-state smart "$FOUND_WARP" \
                "{\"router\":{\"get_route\":{\"domain\":${SOLANA_DOMAIN}}}}" \
                --chain-id "$CHAIN_ID" \
                --node "$NODE" \
                --output json 2>/dev/null | jq -r '.data.route // empty' || echo "")
            
            if [ -n "$TERRA_ROUTE_FULL" ]; then
                echo -e "${CYAN}Router configurado no Terra:${NC} ${GREEN}${TERRA_ROUTE_FULL}${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Não foi possível verificar o link no Terra Classic${NC}"
        echo -e "${CYAN}   Router Hex encontrado:${NC} ${REMOTE_ROUTER_HEX}"
    fi
else
    echo -e "${YELLOW}⚠️  Não há remote router configurado para verificar${NC}"
fi

echo ""

# 5. Resumo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 RESUMO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Mint Address:${NC} ${GREEN}${MINT_ADDRESS}${NC}"
echo -e "${CYAN}Warp Route Program ID:${NC} ${GREEN}${PROGRAM_ID}${NC}"
if [ "$PROGRAM_ID_HEX" != "N/A" ]; then
    echo -e "${CYAN}Program ID (Hex):${NC} ${GREEN}${PROGRAM_ID_HEX}${NC}"
fi
echo -e "${CYAN}Mailbox:${NC} ${GREEN}${MAILBOX}${NC}"
echo -e "${CYAN}ISM:${NC} ${GREEN}${ISM}${NC}"
if [ -n "$REMOTE_ROUTER_HEX" ] && [ "$REMOTE_ROUTER_HEX" != "null" ] && [ "$REMOTE_ROUTER_HEX" != "N/A" ]; then
    echo -e "${CYAN}Remote Router (Hex):${NC} ${GREEN}${REMOTE_ROUTER_HEX}${NC}"
    if [ -n "$REMOTE_ROUTER_BECH32" ] && [ "$REMOTE_ROUTER_BECH32" != "N/A" ]; then
        echo -e "${CYAN}Remote Router (Bech32):${NC} ${GREEN}${REMOTE_ROUTER_BECH32}${NC}"
    fi
fi
if [ -n "$FOUND_WARP" ]; then
    echo -e "${CYAN}Terra Classic Warp Route:${NC} ${GREEN}${FOUND_WARP}${NC}"
fi
echo ""
echo -e "${BLUE}🔗 Links úteis:${NC}"
echo -e "   Solana Explorer: ${GREEN}https://explorer.solana.com/address/${MINT_ADDRESS}?cluster=testnet${NC}"
echo -e "   Program Explorer: ${GREEN}https://explorer.solana.com/address/${PROGRAM_ID}?cluster=testnet${NC}"
if [ -n "$FOUND_WARP" ]; then
    echo -e "   Terra Finder: ${GREEN}https://finder.terra-classic.hexxagon.dev/testnet/address/${FOUND_WARP}${NC}"
fi
echo ""




