#!/usr/bin/env bash
# =============================================================================
#  enroll-terra-router.sh
#  Registra a rota EVM (Sepolia) no contrato Warp Terra Classic
#  Resolve o erro: "route not found" ao chamar transfer_remote
#
#  O que faz:
#    Chama router.set_route no contrato Warp da Terra Classic para registrar
#    o endereço do Warp EVM (ex: Sepolia) como roteador do domínio alvo.
#
#  USO:
#    export TERRA_PRIVATE_KEY="sua_chave_hex"
#    ./enroll-terra-router.sh
# =============================================================================
set -euo pipefail

# ─── Cores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_JSON="$SCRIPT_DIR/warp-evm-config.json"

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║   enrollRemoteRouter — TERRA CLASSIC (set_route)    ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
echo -e ""

# ─── Verificar dependências ────────────────────────────────────────────────────
for dep in node jq; do
    if ! command -v "$dep" &>/dev/null; then
        echo -e "${RED}❌ Dependência não encontrada: ${dep}${RESET}"
        exit 1
    fi
done

if [ ! -f "$CONFIG_JSON" ]; then
    echo -e "${RED}❌ Arquivo não encontrado: $CONFIG_JSON${RESET}"
    exit 1
fi

# ─── Localizar node_modules ─────────────────────────────────────────────────
PROJECT_ROOT="$SCRIPT_DIR"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -f "$PROJECT_ROOT/package.json" ]; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
if [ ! -d "$PROJECT_ROOT/node_modules/@cosmjs/cosmwasm-stargate" ]; then
    echo -e "${RED}❌ node_modules não encontrado em $PROJECT_ROOT${RESET}"
    echo -e "   Execute: cd $PROJECT_ROOT && yarn install"
    exit 1
fi

# ─── Ler configuração do config JSON ──────────────────────────────────────────
TERRA_RPC=$(jq -r '.terra_classic.rpc'      "$CONFIG_JSON")
TERRA_CHAIN=$(jq -r '.terra_classic.chain_id' "$CONFIG_JSON")

echo -e "${BOLD}📌 Selecione o TOKEN a vincular:${RESET}"
echo -e ""

# Listar tokens disponíveis com warp_address no Terra
TOKENS=$(jq -r '.terra_classic.tokens | to_entries[] | select(.value.terra_warp.warp_address != "" and .value.terra_warp.warp_address != null) | .key' "$CONFIG_JSON")
TOKEN_LIST=()
while IFS= read -r t; do
    TOKEN_LIST+=("$t")
done <<< "$TOKENS"

if [ ${#TOKEN_LIST[@]} -eq 0 ]; then
    echo -e "${RED}❌ Nenhum token com warp_address configurado no Terra Classic.${RESET}"
    exit 1
fi

for i in "${!TOKEN_LIST[@]}"; do
    TK="${TOKEN_LIST[$i]}"
    SYMBOL=$(jq -r ".terra_classic.tokens.${TK}.symbol" "$CONFIG_JSON")
    WADDR=$(jq -r ".terra_classic.tokens.${TK}.terra_warp.warp_address" "$CONFIG_JSON")
    echo -e "  ${CYAN}[$((i+1))]${RESET} ${BOLD}${SYMBOL}${RESET} — ${WADDR}"
done
echo -e ""
echo -ne "${YELLOW}▶ Digite o número: ${RESET}"
read -r TOKEN_IDX
TOKEN_IDX=$((TOKEN_IDX - 1))
if [ "$TOKEN_IDX" -lt 0 ] || [ "$TOKEN_IDX" -ge "${#TOKEN_LIST[@]}" ]; then
    echo -e "${RED}❌ Opção inválida.${RESET}"; exit 1
fi

TOKEN_KEY="${TOKEN_LIST[$TOKEN_IDX]}"
TERRA_WARP_ADDR=$(jq -r ".terra_classic.tokens.${TOKEN_KEY}.terra_warp.warp_address" "$CONFIG_JSON")
TOKEN_SYMBOL=$(jq -r ".terra_classic.tokens.${TOKEN_KEY}.symbol" "$CONFIG_JSON")

echo -e ""
echo -e "${BOLD}📌 Selecione a rede EVM de destino:${RESET}"
echo -e ""

# Listar redes que têm este token deployado
NETWORKS=$(jq -r --arg tk "$TOKEN_KEY" \
    '.networks | to_entries[] | select(.value.enabled == true and .value.warp_tokens[$tk].deployed == true) | .key' \
    "$CONFIG_JSON")
NET_LIST=()
while IFS= read -r n; do
    NET_LIST+=("$n")
done <<< "$NETWORKS"

if [ ${#NET_LIST[@]} -eq 0 ]; then
    echo -e "${RED}❌ Nenhuma rede EVM com ${TOKEN_KEY} deployado.${RESET}"
    echo -e "${YELLOW}   Verifique warp_tokens.${TOKEN_KEY}.deployed=true no config.${RESET}"
    exit 1
fi

for i in "${!NET_LIST[@]}"; do
    NK="${NET_LIST[$i]}"
    ND=$(jq -r ".networks.${NK}.display_name" "$CONFIG_JSON")
    WADDR=$(jq -r ".networks.${NK}.warp_tokens.${TOKEN_KEY}.address" "$CONFIG_JSON")
    DOM=$(jq -r ".networks.${NK}.domain" "$CONFIG_JSON")
    echo -e "  ${CYAN}[$((i+1))]${RESET} ${BOLD}${ND}${RESET} (domain ${DOM}) — ${WADDR}"
done
echo -e ""
echo -ne "${YELLOW}▶ Digite o número: ${RESET}"
read -r NET_IDX
NET_IDX=$((NET_IDX - 1))
if [ "$NET_IDX" -lt 0 ] || [ "$NET_IDX" -ge "${#NET_LIST[@]}" ]; then
    echo -e "${RED}❌ Opção inválida.${RESET}"; exit 1
fi

NET_KEY="${NET_LIST[$NET_IDX]}"
EVM_DOMAIN=$(jq -r ".networks.${NET_KEY}.domain"                        "$CONFIG_JSON")
EVM_DISPLAY=$(jq -r ".networks.${NET_KEY}.display_name"                  "$CONFIG_JSON")
EVM_WARP_ADDR=$(jq -r ".networks.${NET_KEY}.warp_tokens.${TOKEN_KEY}.address" "$CONFIG_JSON")

# Converter endereço EVM para bytes32 sem 0x
EVM_WARP_HEX="${EVM_WARP_ADDR#0x}"
EVM_WARP_B32=$(printf '%064s' "$EVM_WARP_HEX" | tr ' ' '0')

# ─── Chave privada ────────────────────────────────────────────────────────────
if [ -z "${TERRA_PRIVATE_KEY:-}" ]; then
    echo -e ""
    echo -e "${YELLOW}⚠️  TERRA_PRIVATE_KEY não definida.${RESET}"
    echo -e "   export TERRA_PRIVATE_KEY=\"sua_chave_hex\""
    echo -n "   > "
    read -rs TERRA_PRIVATE_KEY
    echo ""
    if [ -z "$TERRA_PRIVATE_KEY" ]; then
        echo -e "${RED}❌ Chave privada não fornecida. Abortando.${RESET}"; exit 1
    fi
fi
TERRA_PRIVATE_KEY="${TERRA_PRIVATE_KEY#0x}"

# ─── Resumo ───────────────────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}📋 Parâmetros da operação:${RESET}"
echo -e "   ${CYAN}Token         :${RESET} $TOKEN_SYMBOL ($TOKEN_KEY)"
echo -e "   ${CYAN}Terra Warp    :${RESET} $TERRA_WARP_ADDR"
echo -e "   ${CYAN}Rede EVM      :${RESET} $EVM_DISPLAY (domain $EVM_DOMAIN)"
echo -e "   ${CYAN}EVM Warp      :${RESET} $EVM_WARP_ADDR"
echo -e "   ${CYAN}EVM bytes32   :${RESET} $EVM_WARP_B32"
echo -e "   ${CYAN}RPC Terra     :${RESET} $TERRA_RPC"
echo -e ""
echo -e "${BOLD}Mensagem CosmWasm que será executada:${RESET}"
echo -e "${CYAN}{
  \"router\": {
    \"set_route\": {
      \"set\": {
        \"domain\": $EVM_DOMAIN,
        \"route\": \"$EVM_WARP_B32\"
      }
    }
  }
}${RESET}"
echo -e ""

echo -ne "${YELLOW}▶ Confirmar? [s/N]: ${RESET}"
read -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    echo -e "${RED}❌ Cancelado.${RESET}"; exit 0
fi

echo -e ""
echo -e "${BOLD}⏳ Enviando transação...${RESET}"
echo -e ""

# ─── Exportar variáveis para o Node.js via env (heredoc com aspas = sem expansão bash) ───
export _NM="$PROJECT_ROOT"
export _RPC="$TERRA_RPC"
export _WARP="$TERRA_WARP_ADDR"
export _DOMAIN="$EVM_DOMAIN"
export _ROUTE="$EVM_WARP_B32"
export _KEY="$TERRA_PRIVATE_KEY"

# ─── Node.js inline para executar o set_route ────────────────────────────────
# IMPORTANTE: desabilitar set -e para capturar erros manualmente
set +e
RESULT=$(node --no-warnings - 2>&1 <<'NODEJS_EOF'
const path = require('path');
const nm = path.join(process.env._NM, 'node_modules');
const { SigningCosmWasmClient } = require(path.join(nm, '@cosmjs/cosmwasm-stargate'));
const { DirectSecp256k1Wallet }  = require(path.join(nm, '@cosmjs/proto-signing'));
const { GasPrice }               = require(path.join(nm, '@cosmjs/stargate'));
const { fromHex }                = require(path.join(nm, '@cosmjs/encoding'));

async function main() {
    const rpc         = process.env._RPC;
    const terraWarp   = process.env._WARP;
    const evmDomain   = parseInt(process.env._DOMAIN, 10);
    const evmRouteHex = process.env._ROUTE;
    const privKeyHex  = process.env._KEY;
    const gasPrice    = GasPrice.fromString("28.325uluna");

    let privKeyBytes;
    try {
        privKeyBytes = fromHex(privKeyHex);
    } catch(e) {
        console.log("STATUS=error");
        console.log("ERR=Chave privada inválida: " + e.message);
        return;
    }

    const wallet = await DirectSecp256k1Wallet.fromKey(privKeyBytes, 'terra');
    const [account] = await wallet.getAccounts();
    console.log("SENDER=" + account.address);

    const client = await SigningCosmWasmClient.connectWithSigner(rpc, wallet, { gasPrice });

    // Verificar se rota já existe usando list_routes (mais confiável)
    // get_route retorna {route: null} quando NÃO existe — não usar para checar!
    try {
        const routes = await client.queryContractSmart(terraWarp, {
            router: { list_routes: {} }
        });
        const existing = (routes.routes || []).find(r => r.domain === evmDomain);
        if (existing && existing.route) {
            console.log("STATUS=already_set");
            console.log("EXISTING_ROUTE=" + existing.route);
            return;
        }
    } catch(e) {
        // fallback: tentar prosseguir
    }

    const msg = {
        router: {
            set_route: {
                set: {
                    domain: evmDomain,
                    route: evmRouteHex,
                }
            }
        }
    };

    const result = await client.execute(
        account.address, terraWarp, msg,
        "auto",
        "enrollRemoteRouter via enroll-terra-router.sh"
    );

    console.log("TX_HASH=" + result.transactionHash);
    console.log("HEIGHT=" + result.height);
    console.log("GAS_USED=" + result.gasUsed);
    console.log("STATUS=ok");
}

main().catch(e => {
    console.log("STATUS=error");
    console.log("ERR=" + e.message);
});
NODEJS_EOF
)
EXIT_CODE=$?
set -e

# Mostrar output bruto em caso de falha total do node
if [ $EXIT_CODE -ne 0 ] && ! echo "$RESULT" | grep -q "^STATUS="; then
    echo -e "${RED}❌ Falha inesperada no Node.js (exit $EXIT_CODE):${RESET}"
    echo -e "${YELLOW}$RESULT${RESET}"
    exit 1
fi

TX_HASH=$(echo "$RESULT"  | grep "^TX_HASH="       | cut -d= -f2)
HEIGHT=$(echo "$RESULT"   | grep "^HEIGHT="        | cut -d= -f2)
GAS_USED=$(echo "$RESULT" | grep "^GAS_USED="      | cut -d= -f2)
SENDER=$(echo "$RESULT"   | grep "^SENDER="        | cut -d= -f2)
STATUS=$(echo "$RESULT"   | grep "^STATUS="        | cut -d= -f2)
EXISTING=$(echo "$RESULT" | grep "^EXISTING_ROUTE=" | cut -d= -f2)
ERR_MSG=$(echo "$RESULT"  | grep "^ERR="           | cut -d= -f2-)

if [ "$STATUS" = "error" ]; then
    echo -e "${RED}❌ Erro ao executar set_route:${RESET}"
    echo -e "   ${YELLOW}${ERR_MSG}${RESET}"
    echo -e ""
    echo -e "${BOLD}Output completo:${RESET}"
    echo -e "$RESULT"
    exit 1
elif [ "$STATUS" = "already_set" ]; then
    echo -e "${GREEN}✅ Rota já estava configurada!${RESET}"
    echo -e "   ${CYAN}Rota existente:${RESET} $EXISTING"
    echo -e ""
    echo -e "${YELLOW}⚠️  Se o erro 'route not found' persiste, verifique:${RESET}"
    echo -e "   1. Se o endereço EVM bate com o Warp deployado"
    echo -e "   2. Se o domain correto está sendo passado no transfer_remote"
else
    echo -e ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║    ✅ set_route EXECUTADO COM SUCESSO!               ║${RESET}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
    echo -e ""
    echo -e "${BOLD}📦 Transação:${RESET}"
    echo -e "   ${CYAN}TX Hash   :${RESET} ${BOLD}${TX_HASH}${RESET}"
    echo -e "   ${CYAN}Bloco     :${RESET} $HEIGHT"
    echo -e "   ${CYAN}Gas usado :${RESET} $GAS_USED"
    echo -e "   ${CYAN}Remetente :${RESET} $SENDER"
    echo -e ""
    echo -e "   ${BOLD}🔗 Explorer:${RESET}"
    echo -e "   ${CYAN}https://finder.hexxagon.io/${TERRA_CHAIN}/tx/${TX_HASH}${RESET}"
fi

echo -e ""
echo -e "${BOLD}📋 Configuração registrada:${RESET}"
echo -e "   ${CYAN}Terra Warp   :${RESET} $TERRA_WARP_ADDR"
echo -e "   ${CYAN}Domain EVM   :${RESET} $EVM_DOMAIN ($EVM_DISPLAY)"
echo -e "   ${CYAN}EVM Warp     :${RESET} $EVM_WARP_ADDR"
echo -e "   ${CYAN}EVM bytes32  :${RESET} $EVM_WARP_B32"
echo -e ""
echo -e "${GREEN}✅ O contrato Terra Classic agora conhece a rota para $EVM_DISPLAY!${RESET}"
echo -e "   transfer_remote { dest_domain: $EVM_DOMAIN } deve funcionar."
echo -e ""
