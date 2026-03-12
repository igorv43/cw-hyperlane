#!/usr/bin/env bash
# =============================================================================
#  transfer-remote-to-terra.sh
#  Envia tokens via Hyperlane Warp Route: EVM / Sealevel → Terra Classic
#
#  Modo interativo:
#    ./transfer-remote-to-terra.sh
#
#  Modo não-interativo (EVM):
#    export ETH_PRIVATE_KEY="0x..."
#    TOKEN_KEY=xpto SOURCE_NETWORK=sepolia \
#      RECIPIENT="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k" \
#      AMOUNT=10000000 AUTO_CONFIRM=s \
#      ./transfer-remote-to-terra.sh
#
#  Modo não-interativo (Sealevel):
#    TOKEN_KEY=xpto SOURCE_NETWORK=solanatestnet \
#      RECIPIENT="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k" \
#      AMOUNT=1000000 AUTO_CONFIRM=s \
#      ./transfer-remote-to-terra.sh
#
#  Variáveis opcionais:
#    ETH_PRIVATE_KEY  = chave privada EVM (0x...)
#    SOL_KEYPAIR      = path do keypair Solana (default: do config)
#    AUTO_CONFIRM     = s → sem confirmação
# =============================================================================
set -euo pipefail

# ─── Cores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'; DIM='\033[2m'

# ─── Caminhos ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/transfer-remote-to-terra.log"
EVM_CFG="$SCRIPT_DIR/warp-evm-config.json"
SOL_CFG="$SCRIPT_DIR/warp-sealevel-config.json"

# Terra Classic
TC_DOMAIN=1325
SEALEVEL_CLIENT="/home/lunc/hyperlane-monorepo/rust/sealevel/target/debug/hyperlane-sealevel-client"

# ─── Banner ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║   🌉  TRANSFER REMOTE — Outra Rede → Terra Classic        ║${RESET}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ─── Dependências ─────────────────────────────────────────────────────────────
for dep in jq curl python3; do
    command -v "$dep" &>/dev/null || { echo -e "${RED}❌ Dependência: ${dep}${RESET}"; exit 1; }
done

[ ! -f "$EVM_CFG" ] && echo -e "${RED}❌ Não encontrado: $EVM_CFG${RESET}" && exit 1
[ ! -f "$SOL_CFG" ] && echo -e "${RED}❌ Não encontrado: $SOL_CFG${RESET}" && exit 1

# ─── Função: Converter Terra Classic bech32 → bytes32 (hex 64 chars sem 0x) ──
bech32_to_b32() {
    local addr="$1"
    python3 -c "
import sys
addr = '${addr}'
# Validação básica
if not addr.startswith('terra1'):
    sys.stderr.write('ERR: endereço deve começar com terra1\n'); sys.exit(1)
try:
    import bech32 as b32mod
    hrp, data = b32mod.bech32_decode(addr)
    raw = bytes(b32mod.convertbits(data, 5, 8, False))
except ImportError:
    # Fallback: implementação manual
    CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'
    pos = addr.rfind('1')
    data_chars = [CHARSET.find(c) for c in addr[pos+1:]]
    acc=0; bits=0; result=[]
    for val in data_chars[:-6]:
        acc = ((acc<<5)|val)
        bits += 5
        while bits >= 8:
            bits -= 8
            result.append((acc>>bits)&0xff)
    raw = bytes(result)
if len(raw) != 20:
    sys.stderr.write('ERR: tamanho inesperado: ' + str(len(raw)) + '\n'); sys.exit(1)
print(raw.hex().zfill(64))
" 2>&1
}

# ─── Construir lista de opções ────────────────────────────────────────────────
declare -a OPTIONS=()
declare -a LABELS=()

# EVM → Terra Classic
while IFS= read -r entry; do
    NET=$(echo "$entry"    | cut -d'|' -f1)
    TOKEN=$(echo "$entry"  | cut -d'|' -f2)
    WARP=$(echo "$entry"   | cut -d'|' -f3)
    DOMAIN=$(echo "$entry" | cut -d'|' -f4)
    SYM=$(jq -r --arg t "$TOKEN" '.terra_classic.tokens[$t].symbol // $t' "$EVM_CFG")
    DISP=$(jq -r --arg n "$NET" '.networks[$n].display_name // $n' "$EVM_CFG")
    RPC_LIST=$(jq -r --arg n "$NET" '.networks[$n].rpc_urls[0] // ""' "$EVM_CFG")
    OPTIONS+=("${TOKEN}|${NET}|${WARP}|${DOMAIN}|evm|${RPC_LIST}")
    LABELS+=("  ${SYM} ← ${DISP}  (domain ${DOMAIN})")
done < <(jq -r '
  .networks | to_entries[]
  | select(.value.enabled == true)
  | .key as $net
  | .value.domain as $dom
  | .value.warp_tokens | to_entries[]
  | select((.value | type) == "object")
  | select(.value.deployed == true and (.value.address // "") != "")
  | [$net, .key, .value.address, ($dom|tostring)] | join("|")
' "$EVM_CFG" 2>/dev/null)

# Sealevel → Terra Classic
while IFS= read -r entry; do
    NET=$(echo "$entry"       | cut -d'|' -f1)
    TOKEN=$(echo "$entry"     | cut -d'|' -f2)
    PROG_ID=$(echo "$entry"   | cut -d'|' -f3)
    DOMAIN=$(echo "$entry"    | cut -d'|' -f4)
    SOL_RPC_V=$(echo "$entry" | cut -d'|' -f5)
    KEYPAIR_V=$(echo "$entry" | cut -d'|' -f6)
    SYM=$(jq -r --arg t "$TOKEN" '.terra_classic.tokens[$t].symbol // $t' "$EVM_CFG")
    DISP=$(jq -r --arg n "$NET" '.networks[$n].display_name // $n' "$SOL_CFG")
    OPTIONS+=("${TOKEN}|${NET}|${PROG_ID}|${DOMAIN}|sealevel|${SOL_RPC_V}|${KEYPAIR_V}")
    LABELS+=("  ${SYM} ← ${DISP}  (domain ${DOMAIN})")
done < <(jq -r '
  .networks | to_entries[]
  | select(.value.enabled == true)
  | .key as $net
  | .value.domain as $dom
  | .value.rpc as $rpc
  | .value.keypair as $kp
  | .value.warp_tokens | to_entries[]
  | select(.value.deployed == true and (.value.program_id // "") != "")
  | [$net, .key, .value.program_id, ($dom|tostring), $rpc, $kp] | join("|")
' "$SOL_CFG" 2>/dev/null)

if [ ${#OPTIONS[@]} -eq 0 ]; then
    echo -e "${RED}❌ Nenhuma opção disponível nos configs.${RESET}"; exit 1
fi

# ─── Seleção ──────────────────────────────────────────────────────────────────
SELECTED_IDX=""
if [ -n "${TOKEN_KEY:-}" ] && [ -n "${SOURCE_NETWORK:-}" ]; then
    for i in "${!OPTIONS[@]}"; do
        T=$(echo "${OPTIONS[$i]}" | cut -d'|' -f1)
        N=$(echo "${OPTIONS[$i]}" | cut -d'|' -f2)
        [ "$T" = "$TOKEN_KEY" ] && [ "$N" = "$SOURCE_NETWORK" ] && SELECTED_IDX="$i" && break
    done
    [ -z "$SELECTED_IDX" ] && \
        echo -e "${RED}❌ Combinação TOKEN_KEY='${TOKEN_KEY}' + SOURCE_NETWORK='${SOURCE_NETWORK}' não encontrada.${RESET}" && exit 1
else
    echo -e "${BOLD}Selecione o token e a rede de origem:${RESET}"
    echo ""
    for i in "${!LABELS[@]}"; do
        echo -e "  ${CYAN}[$((i+1))]${RESET} ${LABELS[$i]}"
    done
    echo ""
    echo -n "  Opção [1-${#OPTIONS[@]}]: "
    read -r SEL
    [[ ! "$SEL" =~ ^[0-9]+$ ]] || [ "$SEL" -lt 1 ] || [ "$SEL" -gt "${#OPTIONS[@]}" ] && \
        echo -e "${RED}❌ Opção inválida.${RESET}" && exit 1
    SELECTED_IDX=$((SEL-1))
fi

# ─── Extrair dados ────────────────────────────────────────────────────────────
SEL_OPT="${OPTIONS[$SELECTED_IDX]}"
TOKEN_KEY=$(echo "$SEL_OPT"   | cut -d'|' -f1)
SOURCE_NET=$(echo "$SEL_OPT"  | cut -d'|' -f2)
WARP_SRC=$(echo "$SEL_OPT"    | cut -d'|' -f3)   # EVM: 0x... | Sealevel: program_id
SRC_DOMAIN=$(echo "$SEL_OPT"  | cut -d'|' -f4)
SRC_TYPE=$(echo "$SEL_OPT"    | cut -d'|' -f5)   # evm | sealevel
SRC_RPC=$(echo "$SEL_OPT"     | cut -d'|' -f6)
SOL_KEYPAIR_CFG=$(echo "$SEL_OPT" | cut -d'|' -f7 2>/dev/null || echo "")

TOKEN_UPPER="${TOKEN_KEY^^}"
NET_UPPER="${SOURCE_NET^^}"
TOKEN_SYM=$(jq -r --arg t "$TOKEN_KEY" '.terra_classic.tokens[$t].symbol // $t' "$EVM_CFG")

echo ""
echo -e "${BOLD}${GREEN}✅ Selecionado:${RESET}  ${TOKEN_UPPER}  ←  ${NET_UPPER}  (domain origem ${SRC_DOMAIN} → TC domain ${TC_DOMAIN})"
echo -e "   Tipo        : ${SRC_TYPE}"
echo -e "   Warp origem : ${WARP_SRC}"
echo -e "   RPC origem  : ${SRC_RPC}"
echo ""

# ─── Recipient (Terra Classic) ─────────────────────────────────────────────────
if [ -z "${RECIPIENT:-}" ]; then
    echo -e "${DIM}  Formato: terra1... (bech32 da carteira Terra Classic)${RESET}"
    echo -n "  Endereço do destinatário (terra1...): "
    read -r RECIPIENT
fi
[ -z "$RECIPIENT" ] && echo -e "${RED}❌ Destinatário não informado.${RESET}" && exit 1

# Converter para bytes32
RECIPIENT_B32=$(bech32_to_b32 "$RECIPIENT")
if [[ "$RECIPIENT_B32" == ERR* ]] || [ -z "$RECIPIENT_B32" ]; then
    echo -e "${RED}❌ Erro ao converter endereço Terra Classic: ${RECIPIENT_B32}${RESET}"
    echo -e "   Certifique-se de usar um endereço bech32 válido (terra1...)"
    exit 1
fi
echo -e "   Recipient bytes32 : ${RECIPIENT_B32}"

# ─── Amount ───────────────────────────────────────────────────────────────────
if [ -z "${AMOUNT:-}" ]; then
    DECIMALS=$(jq -r --arg t "$TOKEN_KEY" '.terra_classic.tokens[$t].decimals // 6' "$EVM_CFG")
    echo ""
    echo -e "${DIM}  Decimais: ${DECIMALS} — ex: 1 ${TOKEN_SYM} = 1$(python3 -c "print('0'*${DECIMALS})")${RESET}"
    echo -n "  Quantidade (unidades mínimas, ex: 10000000): "
    read -r AMOUNT
fi
[[ ! "$AMOUNT" =~ ^[0-9]+$ ]] || [ "$AMOUNT" -eq 0 ] 2>/dev/null && \
    echo -e "${RED}❌ Quantidade inválida: ${AMOUNT}${RESET}" && exit 1
echo -e "   Amount            : ${AMOUNT}"
echo ""

# ─── EVM: quote gas payment ───────────────────────────────────────────────────
EVM_GAS_FEE=""
if [ "$SRC_TYPE" = "evm" ]; then
    # Verificar cast
    if ! command -v cast &>/dev/null; then
        echo -e "${RED}❌ 'cast' (Foundry) não encontrado. Instale: curl -L https://foundry.paradigm.xyz | bash${RESET}"
        exit 1
    fi

    echo -e "${DIM}  Consultando quoteGasPayment para TC (domain ${TC_DOMAIN})...${RESET}"
    EVM_GAS_FEE=$(cast call "$WARP_SRC" \
        "quoteGasPayment(uint32)(uint256)" \
        "$TC_DOMAIN" \
        --rpc-url "$SRC_RPC" 2>/dev/null || echo "")

    if [ -z "$EVM_GAS_FEE" ] || ! [[ "$EVM_GAS_FEE" =~ ^[0-9]+$ ]]; then
        # Fallback: tentar RPC alternativo
        for RPC_ALT in $(jq -r --arg n "$SOURCE_NET" '.networks[$n].rpc_urls[]' "$EVM_CFG" 2>/dev/null); do
            EVM_GAS_FEE=$(cast call "$WARP_SRC" \
                "quoteGasPayment(uint32)(uint256)" \
                "$TC_DOMAIN" \
                --rpc-url "$RPC_ALT" 2>/dev/null || echo "")
            if [ -n "$EVM_GAS_FEE" ] && [[ "$EVM_GAS_FEE" =~ ^[0-9]+$ ]]; then
                SRC_RPC="$RPC_ALT"
                break
            fi
        done
    fi

    if [ -z "$EVM_GAS_FEE" ] || ! [[ "$EVM_GAS_FEE" =~ ^[0-9]+$ ]]; then
        echo -e "${YELLOW}⚠️  quoteGasPayment falhou. Informe o fee manualmente (em wei).${RESET}"
        echo -e "${DIM}  (ex: 109030327234501 para Sepolia)${RESET}"
        while true; do
            echo -n "  EVM_GAS_FEE (wei): "
            read -r EVM_GAS_FEE
            [[ "$EVM_GAS_FEE" =~ ^[0-9]+$ ]] && break
            echo -e "${RED}  Valor inválido. Digite somente números.${RESET}"
        done
    fi

    # Converter para ETH para exibição
    CHAIN_NATIVE=$(jq -r --arg n "$SOURCE_NET" '.networks[$n].native_token.symbol // "ETH"' "$EVM_CFG")
    EVM_FEE_ETH=$(python3 -c "print(f'{${EVM_GAS_FEE}/1e18:.8f}')" 2>/dev/null || echo "?")
    echo -e "${GREEN}✅ Gas fee: ${EVM_GAS_FEE} wei  (~${EVM_FEE_ETH} ${CHAIN_NATIVE})${RESET}"

    # Chave privada EVM
    if [ -z "${ETH_PRIVATE_KEY:-}" ]; then
        echo ""
        echo -n "  ETH_PRIVATE_KEY (0x...): "
        read -rs ETH_PRIVATE_KEY; echo ""
    fi
    [ -z "$ETH_PRIVATE_KEY" ] && echo -e "${RED}❌ ETH_PRIVATE_KEY não fornecida.${RESET}" && exit 1
fi

# ─── Sealevel: keypair ────────────────────────────────────────────────────────
if [ "$SRC_TYPE" = "sealevel" ]; then
    if [ ! -f "$SEALEVEL_CLIENT" ]; then
        echo -e "${RED}❌ hyperlane-sealevel-client não encontrado em: ${SEALEVEL_CLIENT}${RESET}"
        echo -e "   Compile com: cd /home/lunc/hyperlane-monorepo/rust/sealevel && cargo build"
        exit 1
    fi

    # Keypair: variável de ambiente > config
    SOL_KEYPAIR="${SOL_KEYPAIR:-${SOL_KEYPAIR_CFG}}"
    if [ -z "$SOL_KEYPAIR" ] || [ ! -f "$SOL_KEYPAIR" ]; then
        echo ""
        echo -e "${YELLOW}  Keypair Solana não configurado.${RESET}"
        echo -n "  Caminho do keypair (.json): "
        read -r SOL_KEYPAIR
    fi
    [ ! -f "$SOL_KEYPAIR" ] && echo -e "${RED}❌ Keypair não encontrado: ${SOL_KEYPAIR}${RESET}" && exit 1

    # Extrair public key
    SENDER_PUBKEY=$(python3 -c "
import json
with open('${SOL_KEYPAIR}') as f:
    data = json.load(f)
# Keypair Solana é [privkey...pubkey] ou objeto
if isinstance(data, list):
    import base64
    privkey_bytes = bytes(data)
    # Ed25519: primeiros 32 bytes = seed, últimos 32 bytes = pubkey
    pubkey_bytes = privkey_bytes[32:]
    try:
        import base58
        print(base58.b58encode(pubkey_bytes).decode())
    except ImportError:
        # Fallback: usar bs58 via node
        print('USE_NODE')
else:
    print(data.get('publicKey', '?'))
" 2>/dev/null || echo "USE_NODE")

    if [ "$SENDER_PUBKEY" = "USE_NODE" ] || [ -z "$SENDER_PUBKEY" ] || [ "$SENDER_PUBKEY" = "?" ]; then
        # Tentar via solana CLI
        if command -v solana &>/dev/null; then
            SENDER_PUBKEY=$(solana-keygen pubkey "$SOL_KEYPAIR" 2>/dev/null || echo "")
        fi
    fi

    [ -z "$SENDER_PUBKEY" ] && \
        echo -e "${RED}❌ Não foi possível extrair a public key do keypair.${RESET}" && exit 1

    echo -e "   Sender Solana : ${SENDER_PUBKEY}"
fi

# ─── Resumo e confirmação ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Resumo da transferência${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  Token          : ${TOKEN_UPPER} / ${TOKEN_SYM}"
echo -e "  Origem         : ${NET_UPPER}  (${SRC_TYPE}, domain ${SRC_DOMAIN})"
echo -e "  Destino        : Terra Classic  (domain ${TC_DOMAIN})"
echo -e "  Recipient TC   : ${RECIPIENT}"
echo -e "  Recipient b32  : ${RECIPIENT_B32}"
echo -e "  Amount         : ${AMOUNT}"
echo -e "  Warp origem    : ${WARP_SRC}"
[ -n "$EVM_GAS_FEE" ] && echo -e "  Gas fee (EVM)  : ${EVM_GAS_FEE} wei  (~${EVM_FEE_ETH} ${CHAIN_NATIVE:-ETH})"
echo ""

if [[ "${AUTO_CONFIRM:-}" =~ ^[sStTyY1]$ ]]; then
    echo -e "${DIM}  (AUTO_CONFIRM ativado)${RESET}"
else
    echo -n "  Confirmar e enviar? [s/N]: "
    read -r CONF
    [[ ! "$CONF" =~ ^[sS]$ ]] && echo -e "${YELLOW}⚠️  Cancelado.${RESET}" && exit 0
fi

echo ""
echo -e "${BOLD}${GREEN}▶ Executando transferência...${RESET}"
echo ""

TX_HASH=""

# ══════════════════════════════════════════════════════════════════════════════
# EVM → Terra Classic
# ══════════════════════════════════════════════════════════════════════════════
if [ "$SRC_TYPE" = "evm" ]; then
    # cast send: transferRemote(uint32 destDomain, bytes32 recipient, uint256 amount)
    # --value = gas fee em wei (native token: ETH/BNB)
    CAST_OUT=$(cast send "$WARP_SRC" \
        "transferRemote(uint32,bytes32,uint256)" \
        "$TC_DOMAIN" \
        "0x${RECIPIENT_B32}" \
        "$AMOUNT" \
        --value "${EVM_GAS_FEE}" \
        --private-key "$ETH_PRIVATE_KEY" \
        --rpc-url "$SRC_RPC" \
        --json 2>&1 || true)

    TX_HASH=$(echo "$CAST_OUT" | jq -r '.transactionHash // ""' 2>/dev/null || true)

    if [ -z "$TX_HASH" ] || [ "$TX_HASH" = "null" ]; then
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${RED}║  ❌  ERRO NA TRANSFERÊNCIA (EVM)                          ║${RESET}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "${RED}  Saída do cast:${RESET}"
        echo "$CAST_OUT" | head -20
        echo ""
        echo -e "${YELLOW}  Dicas:${RESET}"
        echo -e "  • Verifique saldo de ${CHAIN_NATIVE:-ETH} para cobrir gas fee + tx fee"
        echo -e "  • Saldo do token na carteira de origem"
        echo -e "  • Confirme que ETH_PRIVATE_KEY tem fundos: cast balance <addr> --rpc-url ${SRC_RPC}"
        exit 1
    fi

    # Determinar explorer
    EXPLORER=$(jq -r --arg n "$SOURCE_NET" '.networks[$n].explorer // ""' "$EVM_CFG")
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║  ✅  TRANSFERÊNCIA EVM ENVIADA COM SUCESSO!               ║${RESET}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}TX Hash :${RESET} ${TX_HASH}"
    [ -n "$EXPLORER" ] && echo -e "  ${BOLD}Explorer:${RESET} ${EXPLORER}/tx/${TX_HASH}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Sealevel → Terra Classic
# ══════════════════════════════════════════════════════════════════════════════
if [ "$SRC_TYPE" = "sealevel" ]; then
    # hyperlane-sealevel-client token transfer-remote
    #   <SENDER> <AMOUNT> <DEST_DOMAIN> <RECIPIENT> <TOKEN_TYPE>
    #   --program-id <PROGRAM_ID>
    #   -u <RPC> -k <KEYPAIR>
    #
    # TOKEN_TYPE = synthetic (SealevelHypSynthetic)
    TOKEN_TYPE_SOL="synthetic"

    SOL_OUT=$("$SEALEVEL_CLIENT" \
        --url "$SRC_RPC" \
        --keypair "$SOL_KEYPAIR" \
        token transfer-remote \
        "$SENDER_PUBKEY" \
        "$AMOUNT" \
        "$TC_DOMAIN" \
        "$RECIPIENT_B32" \
        "$TOKEN_TYPE_SOL" \
        --program-id "$WARP_SRC" \
        2>&1 || true)

    echo "$SOL_OUT"
    echo ""

    # Tentar extrair signature/txhash do output
    TX_HASH=$(echo "$SOL_OUT" | grep -oE '[A-Za-z0-9]{87,88}' | head -1 || true)

    if echo "$SOL_OUT" | grep -qi "error\|failed\|panicked"; then
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${RED}║  ❌  ERRO NA TRANSFERÊNCIA (SEALEVEL)                     ║${RESET}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "${YELLOW}  Dicas:${RESET}"
        echo -e "  • Verifique saldo de SOL na wallet para IGP fee"
        echo -e "  • Confirme saldo do token SPL: spl-token balance --address <MINT> --owner ${SENDER_PUBKEY}"
        echo -e "  • Confirme RPC: ${SRC_RPC}"
        exit 1
    fi

    SOL_EXPLORER_BASE=$(jq -r --arg n "$SOURCE_NET" '.networks[$n].explorer // ""' "$SOL_CFG")
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║  ✅  TRANSFERÊNCIA SEALEVEL ENVIADA!                      ║${RESET}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    [ -n "$TX_HASH" ] && echo -e "  ${BOLD}TX Signature :${RESET} ${TX_HASH}"
    if [ -n "$TX_HASH" ] && [ -n "$SOL_EXPLORER_BASE" ]; then
        # Extrair cluster da URL (ex: ?cluster=testnet) e montar link /tx/{sig}?cluster=...
        SOL_CLUSTER=$(echo "$SOL_EXPLORER_BASE" | grep -oE 'cluster=[^&]+' || echo "")
        SOL_EXPLORER_HOST=$(echo "$SOL_EXPLORER_BASE" | sed 's/?.*$//' | sed 's|/$||')
        if [ -n "$SOL_CLUSTER" ]; then
            echo -e "  ${BOLD}Explorer     :${RESET} ${SOL_EXPLORER_HOST}/tx/${TX_HASH}?${SOL_CLUSTER}"
        else
            echo -e "  ${BOLD}Explorer     :${RESET} ${SOL_EXPLORER_HOST}/tx/${TX_HASH}"
        fi
    fi
fi

# ─── Informações de rastreamento ──────────────────────────────────────────────
echo ""
echo -e "${DIM}  A mensagem será relayada pelo Hyperlane Relayer."
echo -e "  Rastreie em: https://explorer.hyperlane.xyz"
echo -e "  Tempo estimado: 1–5 minutos.${RESET}"

# ─── Relatório ────────────────────────────────────────────────────────────────
REPORT_FILE="$LOG_DIR/TRANSFER-TO-TERRA-${NET_UPPER}-${TOKEN_UPPER}-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "TRANSFER REMOTE — ${NET_UPPER} → Terra Classic"
    echo "Data           : $(date)"
    echo "Token          : ${TOKEN_UPPER} / ${TOKEN_SYM}"
    echo "Origem         : ${NET_UPPER}  (${SRC_TYPE}, domain ${SRC_DOMAIN})"
    echo "Destino        : Terra Classic  (domain ${TC_DOMAIN})"
    echo "Recipient TC   : ${RECIPIENT}"
    echo "Recipient b32  : ${RECIPIENT_B32}"
    echo "Amount         : ${AMOUNT}"
    echo "Warp origem    : ${WARP_SRC}"
    [ -n "${EVM_GAS_FEE:-}" ] && echo "Gas fee (wei)  : ${EVM_GAS_FEE}"
    [ -n "$TX_HASH" ] && echo "TX Hash        : ${TX_HASH}"
} > "$REPORT_FILE"

echo ""
echo -e "  ${BOLD}Relatório :${RESET} ${REPORT_FILE}"
echo ""
echo "$(date) | ${NET_UPPER}→TC | ${TOKEN_UPPER} | amount=${AMOUNT} | tx=${TX_HASH:-?}" >> "$LOG_FILE"
