#!/usr/bin/env bash
# =============================================================================
#  transfer-cw20-terra.sh
#  Transfere tokens CW20 na Terra Classic via CosmWasm
# =============================================================================
set -euo pipefail

# ─── Cores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Configurações padrão (editáveis) ────────────────────────────────────────
CW20_CONTRACT="${CW20_CONTRACT:-terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch}"
SENDER="${SENDER:-terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze}"
RECIPIENT="${RECIPIENT:-terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k}"
AMOUNT="${AMOUNT:-100000000000}"
TOKEN_SYMBOL="${TOKEN_SYMBOL:-XPTO}"

# RPC / LCD da Terra Classic (lê do warp-evm-config.json se existir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_JSON="$SCRIPT_DIR/warp-evm-config.json"

if command -v jq &>/dev/null && [ -f "$CONFIG_JSON" ]; then
    RPC_URL=$(jq -r '.terra_classic.rpc // "https://rpc.terra-classic.hexxagon.dev"' "$CONFIG_JSON")
    LCD_URL=$(jq -r '.terra_classic.lcd // "https://lcd.terra-classic.hexxagon.dev"' "$CONFIG_JSON")
    CHAIN_ID=$(jq -r '.terra_classic.chain_id // "rebel-2"' "$CONFIG_JSON")
else
    RPC_URL="https://rpc.terra-classic.hexxagon.dev"
    LCD_URL="https://lcd.terra-classic.hexxagon.dev"
    CHAIN_ID="rebel-2"
fi

GAS_PRICE="${GAS_PRICE:-28.325}"
GAS_DENOM="${GAS_DENOM:-uluna}"
GAS_MULTIPLIER="${GAS_MULTIPLIER:-1.4}"

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║      TRANSFERÊNCIA CW20 — TERRA CLASSIC              ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
echo -e ""

# ─── Checar dependências ──────────────────────────────────────────────────────
for dep in node jq curl; do
    if ! command -v "$dep" &>/dev/null; then
        echo -e "${RED}❌ Dependência não encontrada: ${dep}${RESET}"
        echo -e "   Instale com: sudo apt install ${dep}"
        exit 1
    fi
done

# Localizar node_modules do projeto
PROJECT_ROOT="$SCRIPT_DIR"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -f "$PROJECT_ROOT/package.json" ]; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

if [ ! -d "$PROJECT_ROOT/node_modules/@cosmjs/cosmwasm-stargate" ]; then
    echo -e "${RED}❌ node_modules não encontrado em $PROJECT_ROOT${RESET}"
    echo -e "   Execute: cd $PROJECT_ROOT && yarn install"
    exit 1
fi

echo -e "${GREEN}✅ node_modules encontrado em: ${PROJECT_ROOT}${RESET}"

# ─── Chave privada ─────────────────────────────────────────────────────────────
if [ -z "${TERRA_PRIVATE_KEY:-}" ]; then
    echo -e ""
    echo -e "${YELLOW}⚠️  TERRA_PRIVATE_KEY não definida.${RESET}"
    echo -e "   Opção 1: export TERRA_PRIVATE_KEY=\"sua_chave_hex\""
    echo -e "   Opção 2: digite agora (não será exibida):"
    echo -n "   > "
    read -rs TERRA_PRIVATE_KEY
    echo ""
    if [ -z "$TERRA_PRIVATE_KEY" ]; then
        echo -e "${RED}❌ Chave privada não fornecida. Abortando.${RESET}"
        exit 1
    fi
fi

# Remover prefixo 0x se presente
TERRA_PRIVATE_KEY="${TERRA_PRIVATE_KEY#0x}"

# ─── Resumo da transação ───────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}📋 Detalhes da transferência:${RESET}"
echo -e "   ${CYAN}Rede      :${RESET} $CHAIN_ID"
echo -e "   ${CYAN}RPC       :${RESET} $RPC_URL"
echo -e "   ${CYAN}Contrato  :${RESET} $CW20_CONTRACT"
echo -e "   ${CYAN}Token     :${RESET} $TOKEN_SYMBOL"
echo -e "   ${CYAN}Remetente :${RESET} $SENDER"
echo -e "   ${CYAN}Destinat. :${RESET} $RECIPIENT"
echo -e "   ${CYAN}Valor     :${RESET} $AMOUNT (unidades base)"
echo -e ""

# Confirmação
echo -ne "${YELLOW}▶ Confirmar a transferência? [s/N]: ${RESET}"
read -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    echo -e "${RED}❌ Transferência cancelada.${RESET}"
    exit 0
fi

echo -e ""
echo -e "${BOLD}⏳ Processando...${RESET}"
echo -e ""

# ─── Script Node.js inline ────────────────────────────────────────────────────
RESULT=$(node --no-warnings - <<EOF
const path = require('path');
const PROJECT_ROOT = "${PROJECT_ROOT}";

// Carregar módulos do node_modules do projeto
const nmPath = path.join(PROJECT_ROOT, 'node_modules');
const { SigningCosmWasmClient } = require(path.join(nmPath, '@cosmjs/cosmwasm-stargate'));
const { DirectSecp256k1Wallet } = require(path.join(nmPath, '@cosmjs/proto-signing'));
const { GasPrice, calculateFee } = require(path.join(nmPath, '@cosmjs/stargate'));
const { fromHex } = require(path.join(nmPath, '@cosmjs/encoding'));

async function main() {
    const rpcUrl   = "${RPC_URL}";
    const contract = "${CW20_CONTRACT}";
    const sender   = "${SENDER}";
    const recipient= "${RECIPIENT}";
    const amount   = "${AMOUNT}";
    const privKeyHex = "${TERRA_PRIVATE_KEY}";
    const gasPrice = GasPrice.fromString("${GAS_PRICE}${GAS_DENOM}");

    // Criar wallet a partir da chave privada hex
    let privKeyBytes;
    try {
        privKeyBytes = fromHex(privKeyHex);
    } catch(e) {
        throw new Error("Chave privada inválida: " + e.message);
    }

    const wallet = await DirectSecp256k1Wallet.fromKey(privKeyBytes, 'terra');
    const [account] = await wallet.getAccounts();

    // Verificar se o endereço bate com o sender esperado
    if (account.address !== sender) {
        process.stderr.write("⚠️  AVISO: endereço derivado da chave: " + account.address + "\n");
        process.stderr.write("          endereço configurado (SENDER): " + sender + "\n");
        process.stderr.write("          Usando o endereço derivado da chave.\n\n");
    }

    // Conectar ao cliente
    const client = await SigningCosmWasmClient.connectWithSigner(rpcUrl, wallet, {
        gasPrice: gasPrice,
    });

    // Checar saldo CW20 antes
    let balanceBefore = "0";
    let balanceRecipientBefore = "0";
    try {
        const res = await client.queryContractSmart(contract, {
            balance: { address: account.address }
        });
        balanceBefore = res.balance;
        const resR = await client.queryContractSmart(contract, {
            balance: { address: recipient }
        });
        balanceRecipientBefore = resR.balance;
    } catch(e) {
        // query pode falhar em redes testnet
    }

    console.log("BALANCE_SENDER_BEFORE=" + balanceBefore);
    console.log("BALANCE_RECIPIENT_BEFORE=" + balanceRecipientBefore);

    // Mensagem CW20 transfer
    const transferMsg = {
        transfer: {
            recipient: recipient,
            amount: amount
        }
    };

    // Estimar gas
    let gasEstimate;
    try {
        gasEstimate = await client.simulate(account.address, [
            {
                typeUrl: "/cosmwasm.wasm.v1.MsgExecuteContract",
                value: {
                    sender: account.address,
                    contract: contract,
                    msg: Buffer.from(JSON.stringify(transferMsg)),
                    funds: []
                }
            }
        ], "");
    } catch(e) {
        process.stderr.write("⚠️  Falha ao estimar gas: " + e.message + "\n");
        process.stderr.write("   Usando gas padrão: 200000\n");
        gasEstimate = null;
    }

    const gasLimit = gasEstimate ? Math.ceil(gasEstimate * ${GAS_MULTIPLIER}) : 200000;
    const fee = calculateFee(gasLimit, gasPrice);

    console.log("GAS_LIMIT=" + gasLimit);
    console.log("FEE_AMOUNT=" + fee.amount[0].amount + fee.amount[0].denom);

    // Executar transferência
    const result = await client.execute(
        account.address,
        contract,
        transferMsg,
        fee,
        "CW20 transfer via transfer-cw20-terra.sh"
    );

    console.log("TX_HASH=" + result.transactionHash);
    console.log("HEIGHT=" + result.height);
    console.log("GAS_USED=" + result.gasUsed);
    console.log("GAS_WANTED=" + result.gasWanted);
    console.log("SENDER_USED=" + account.address);

    // Checar saldo CW20 depois
    try {
        const resAfter = await client.queryContractSmart(contract, {
            balance: { address: account.address }
        });
        const resRAfter = await client.queryContractSmart(contract, {
            balance: { address: recipient }
        });
        console.log("BALANCE_SENDER_AFTER=" + resAfter.balance);
        console.log("BALANCE_RECIPIENT_AFTER=" + resRAfter.balance);
    } catch(e) {}
}

main().catch(e => {
    process.stderr.write("ERRO: " + e.message + "\n");
    process.exit(1);
});
EOF
)

EXIT_CODE=$?

# ─── Processar resultado ───────────────────────────────────────────────────────
if [ $EXIT_CODE -ne 0 ]; then
    echo -e "${RED}❌ Falha na transferência!${RESET}"
    echo -e "${RED}   Verifique os logs acima para mais detalhes.${RESET}"
    exit 1
fi

# Extrair variáveis do output do Node.js
TX_HASH=$(echo "$RESULT"             | grep "^TX_HASH="                  | cut -d= -f2)
HEIGHT=$(echo "$RESULT"              | grep "^HEIGHT="                   | cut -d= -f2)
GAS_USED=$(echo "$RESULT"            | grep "^GAS_USED="                 | cut -d= -f2)
GAS_LIMIT=$(echo "$RESULT"           | grep "^GAS_LIMIT="                | cut -d= -f2)
FEE_AMOUNT=$(echo "$RESULT"          | grep "^FEE_AMOUNT="               | cut -d= -f2)
SENDER_USED=$(echo "$RESULT"         | grep "^SENDER_USED="              | cut -d= -f2)
BAL_S_BEFORE=$(echo "$RESULT"        | grep "^BALANCE_SENDER_BEFORE="    | cut -d= -f2)
BAL_S_AFTER=$(echo "$RESULT"         | grep "^BALANCE_SENDER_AFTER="     | cut -d= -f2)
BAL_R_BEFORE=$(echo "$RESULT"        | grep "^BALANCE_RECIPIENT_BEFORE=" | cut -d= -f2)
BAL_R_AFTER=$(echo "$RESULT"         | grep "^BALANCE_RECIPIENT_AFTER="  | cut -d= -f2)

# ─── Relatório final ───────────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║       ✅ TRANSFERÊNCIA REALIZADA COM SUCESSO!        ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo -e ""
echo -e "${BOLD}📦 Transação:${RESET}"
echo -e "   ${CYAN}TX Hash   :${RESET} ${BOLD}${TX_HASH}${RESET}"
echo -e "   ${CYAN}Bloco     :${RESET} $HEIGHT"
echo -e "   ${CYAN}Gas usado :${RESET} ${GAS_USED} / ${GAS_LIMIT}"
echo -e "   ${CYAN}Taxa paga :${RESET} $FEE_AMOUNT"
echo -e ""
echo -e "${BOLD}💰 Saldos:${RESET}"
echo -e "   ${CYAN}Remetente (antes) :${RESET} $BAL_S_BEFORE $TOKEN_SYMBOL"
echo -e "   ${CYAN}Remetente (depois):${RESET} $BAL_S_AFTER $TOKEN_SYMBOL"
echo -e "   ${CYAN}Destinat. (antes) :${RESET} $BAL_R_BEFORE $TOKEN_SYMBOL"
echo -e "   ${CYAN}Destinat. (depois):${RESET} $BAL_R_AFTER $TOKEN_SYMBOL"
echo -e ""
echo -e "${BOLD}🔗 Verificar no Explorer:${RESET}"
echo -e "   ${CYAN}https://finder.terra-classic.hexxagon.dev/testnet/tx/${TX_HASH}${RESET}"
echo -e ""

# ─── Salvar relatório ──────────────────────────────────────────────────────────
REPORT_FILE="$SCRIPT_DIR/TRANSFER-CW20-$(date +%Y%m%d-%H%M%S).txt"
cat > "$REPORT_FILE" <<REPORT
TRANSFERÊNCIA CW20 — TERRA CLASSIC
====================================
Data/Hora  : $(date "+%Y-%m-%d %H:%M:%S")
Chain      : $CHAIN_ID
RPC        : $RPC_URL

PARÂMETROS
-----------
Token      : $TOKEN_SYMBOL
Contrato   : $CW20_CONTRACT
Remetente  : $SENDER_USED
Destinat.  : $RECIPIENT
Valor      : $AMOUNT

RESULTADO
----------
TX Hash    : $TX_HASH
Bloco      : $HEIGHT
Gas Usado  : $GAS_USED / $GAS_LIMIT
Taxa       : $FEE_AMOUNT

SALDOS
-------
Remetente antes : $BAL_S_BEFORE $TOKEN_SYMBOL
Remetente depois: $BAL_S_AFTER $TOKEN_SYMBOL
Destinat. antes : $BAL_R_BEFORE $TOKEN_SYMBOL
Destinat. depois: $BAL_R_AFTER $TOKEN_SYMBOL

Explorer: https://finder.terra-classic.hexxagon.dev/testnet/tx/$TX_HASH
REPORT

echo -e "${GREEN}📄 Relatório salvo: ${REPORT_FILE}${RESET}"
echo -e ""
