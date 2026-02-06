import axios from "axios";

// ==============================
// CONFIGURATION
// ==============================
const SEPOLIA_RPC = "https://1rpc.io/sepolia";
const WARP_ROUTE_SEPOLIA = "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4";

// Function selectors para Warp Route
const WARP_SELECTORS: { [key: string]: string } = {
  mailbox: "0xd5438eae",      // cast sig "mailbox()"
  hook: "0x7f5a7c7b",          // cast sig "hook()"
  localDomain: "0x8d3638f4",   // cast sig "localDomain()"
  token: "0xfc0c546a",          // cast sig "token()"
};

// Function selectors para Mailbox (Hyperlane Mailbox EVM)
// Calculados usando: cast sig "functionName()"
const MAILBOX_SELECTORS: { [key: string]: string } = {
  defaultHook: "0x3d1250b7",    // cast sig "defaultHook()"
  requiredHook: "0xd6d08a09",   // cast sig "requiredHook()"
  default_hook: "0x3e556890",    // cast sig "default_hook()" (alternativa)
  required_hook: "0xd3834d52",   // cast sig "required_hook()" (alternativa)
};

// ==============================
// HELPER FUNCTIONS
// ==============================

/**
 * Decodifica endereço de resposta
 */
function decodeAddress(data: string): string {
  if (!data || data === "0x") {
    return "0x0000000000000000000000000000000000000000";
  }
  const hexData = data.startsWith("0x") ? data.slice(2) : data;
  const addressHex = hexData.slice(-40).padStart(40, "0");
  return `0x${addressHex.toLowerCase()}`;
}

/**
 * Decodifica uint32
 */
function decodeUint32(data: string): number {
  if (!data || data === "0x") {
    return 0;
  }
  const hexData = data.startsWith("0x") ? data.slice(2) : data;
  const uintHex = hexData.slice(-64).padStart(64, "0");
  return parseInt(uintHex, 16);
}

/**
 * Faz uma chamada RPC eth_call
 */
async function callContract(
  contractAddress: string,
  selector: string,
  rpcUrl: string
): Promise<string> {
  const payload = {
    jsonrpc: "2.0",
    method: "eth_call",
    params: [
      {
        to: contractAddress,
        data: selector,
      },
      "latest",
    ],
    id: 1,
  };

  try {
    const response = await axios.post(rpcUrl, payload, {
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
    });

    if (response.data.error) {
      throw new Error(`RPC Error: ${response.data.error.message}`);
    }

    return response.data.result;
  } catch (error: any) {
    throw new Error(`Failed to call contract: ${error.message}`);
  }
}

/**
 * Consulta storage slot do Mailbox (para defaultHook e requiredHook)
 * Os hooks podem estar armazenados em storage slots específicos
 */
async function getStorageSlot(
  contractAddress: string,
  slot: string,
  rpcUrl: string
): Promise<string> {
  const payload = {
    jsonrpc: "2.0",
    method: "eth_getStorageAt",
    params: [contractAddress, slot, "latest"],
    id: 1,
  };

  try {
    const response = await axios.post(rpcUrl, payload, {
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
    });

    if (response.data.error) {
      throw new Error(`RPC Error: ${response.data.error.message}`);
    }

    return response.data.result;
  } catch (error: any) {
    throw new Error(`Failed to get storage: ${error.message}`);
  }
}

// ==============================
// MAIN FUNCTION
// ==============================
async function main() {
  console.log("=".repeat(80));
  console.log("🔍 DIAGNÓSTICO COMPLETO - WARP ROUTE SEPOLIA");
  console.log("=".repeat(80));
  console.log("\nWarp Route:", WARP_ROUTE_SEPOLIA);
  console.log("RPC URL:", SEPOLIA_RPC);
  console.log("");

  let warpMailbox: string = "";
  let warpHook: string = "";
  let mailboxDefaultHook: string = "";
  let mailboxRequiredHook: string = "";

  try {
    // ========================================================================
    // PARTE 1: CONSULTAR WARP ROUTE
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📦 PARTE 1: CONFIGURAÇÃO DO WARP ROUTE");
    console.log("━".repeat(80));
    console.log("");

    // 1.1 Consultar Mailbox do Warp Route
    console.log("1.1 📮 Consultando Mailbox configurado no Warp Route...");
    try {
      const mailboxData = await callContract(
        WARP_ROUTE_SEPOLIA,
        WARP_SELECTORS.mailbox,
        SEPOLIA_RPC
      );
      warpMailbox = decodeAddress(mailboxData);
      console.log("   ✅ Mailbox:", warpMailbox);
      console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${warpMailbox}`);
    } catch (error: any) {
      console.error("   ❌ Erro:", error.message);
    }
    console.log("");

    // 1.2 Consultar Hook do Warp Route
    console.log("1.2 🔗 Consultando Hook configurado no Warp Route...");
    try {
      const hookData = await callContract(
        WARP_ROUTE_SEPOLIA,
        WARP_SELECTORS.hook,
        SEPOLIA_RPC
      );
      warpHook = decodeAddress(hookData);
      console.log("   ✅ Hook:", warpHook);
      console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${warpHook}`);
    } catch (error: any) {
      console.error("   ❌ Erro:", error.message);
    }
    console.log("");

    // 1.3 Consultar Local Domain
    console.log("1.3 🌐 Consultando Local Domain...");
    try {
      const domainData = await callContract(
        WARP_ROUTE_SEPOLIA,
        WARP_SELECTORS.localDomain,
        SEPOLIA_RPC
      );
      const localDomain = decodeUint32(domainData);
      console.log("   ✅ Local Domain:", localDomain, `(${localDomain === 11155111 ? "Sepolia ✓" : "⚠️  Esperado: 11155111"})`);
    } catch (error: any) {
      console.error("   ❌ Erro:", error.message);
    }
    console.log("");

    // 1.4 Consultar Token
    console.log("1.4 🪙 Consultando Token...");
    try {
      const tokenData = await callContract(
        WARP_ROUTE_SEPOLIA,
        WARP_SELECTORS.token,
        SEPOLIA_RPC
      );
      const token = decodeAddress(tokenData);
      console.log("   ✅ Token:", token);
      console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${token}`);
    } catch (error: any) {
      console.error("   ❌ Erro:", error.message);
    }
    console.log("");

    // ========================================================================
    // PARTE 2: CONSULTAR MAILBOX
    // ========================================================================
    if (!warpMailbox || warpMailbox === "0x0000000000000000000000000000000000000000") {
      console.log("⚠️  Não foi possível obter o endereço do Mailbox do Warp Route.");
      console.log("   Pulando verificação do Mailbox.\n");
    } else {
      console.log("━".repeat(80));
      console.log("📮 PARTE 2: CONFIGURAÇÃO DO MAILBOX");
      console.log("━".repeat(80));
      console.log("");

      // 2.1 Verificar se o Mailbox existe
      console.log("2.1 🔍 Verificando se o Mailbox existe...");
      try {
        const code = await axios.post(
          SEPOLIA_RPC,
          {
            jsonrpc: "2.0",
            method: "eth_getCode",
            params: [warpMailbox, "latest"],
            id: 1,
          },
          {
            headers: { "Content-Type": "application/json" },
            timeout: 10000,
          }
        );

        if (code.data.result && code.data.result !== "0x") {
          console.log("   ✅ Mailbox existe e tem código");
        } else {
          console.log("   ❌ Mailbox não existe ou não tem código");
        }
      } catch (error: any) {
        console.error("   ❌ Erro:", error.message);
      }
      console.log("");

      // 2.2 Consultar defaultHook do Mailbox
      console.log("2.2 🔍 Consultando defaultHook do Mailbox...");
      try {
        const defaultHookData = await callContract(
          warpMailbox,
          MAILBOX_SELECTORS.defaultHook,
          SEPOLIA_RPC
        );
        mailboxDefaultHook = decodeAddress(defaultHookData);
        if (mailboxDefaultHook && mailboxDefaultHook !== "0x0000000000000000000000000000000000000000") {
          console.log("   ✅ defaultHook:", mailboxDefaultHook);
          console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${mailboxDefaultHook}`);
        } else {
          console.log("   ⚠️  defaultHook não configurado (endereço zero)");
        }
      } catch (error: any) {
        console.log("   ⚠️  Erro ao consultar defaultHook:", error.message);
        console.log("   💡 Tente verificar manualmente no Etherscan:");
        console.log(`      https://sepolia.etherscan.io/address/${warpMailbox}#readContract`);
      }
      console.log("");

      // 2.3 Consultar requiredHook do Mailbox
      console.log("2.3 🔍 Consultando requiredHook do Mailbox...");
      try {
        const requiredHookData = await callContract(
          warpMailbox,
          MAILBOX_SELECTORS.requiredHook,
          SEPOLIA_RPC
        );
        mailboxRequiredHook = decodeAddress(requiredHookData);
        if (mailboxRequiredHook && mailboxRequiredHook !== "0x0000000000000000000000000000000000000000") {
          console.log("   ✅ requiredHook:", mailboxRequiredHook);
          console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${mailboxRequiredHook}`);
        } else {
          console.log("   ⚠️  requiredHook não configurado (endereço zero)");
        }
      } catch (error: any) {
        console.log("   ⚠️  Erro ao consultar requiredHook:", error.message);
        console.log("   💡 Tente verificar manualmente no Etherscan:");
        console.log(`      https://sepolia.etherscan.io/address/${warpMailbox}#readContract`);
      }
      console.log("");
    }

    // ========================================================================
    // PARTE 3: ANÁLISE E DIAGNÓSTICO
    // ========================================================================
    console.log("━".repeat(80));
    console.log("🔬 PARTE 3: ANÁLISE E DIAGNÓSTICO");
    console.log("━".repeat(80));
    console.log("");

    // 3.1 Verificar se Warp Route está usando o Mailbox correto
    console.log("3.1 ✅ Verificação do Mailbox:");
    if (warpMailbox && warpMailbox !== "0x0000000000000000000000000000000000000000") {
      console.log("   ✅ Warp Route está configurado com um Mailbox");
      console.log("   📍 Mailbox:", warpMailbox);
    } else {
      console.log("   ❌ Warp Route NÃO tem Mailbox configurado!");
      console.log("   ⚠️  PROBLEMA CRÍTICO: O Warp Route precisa de um Mailbox válido.");
    }
    console.log("");

    // 3.2 Verificar se Warp Route está usando um Hook
    console.log("3.2 ✅ Verificação do Hook do Warp Route:");
    if (warpHook && warpHook !== "0x0000000000000000000000000000000000000000") {
      console.log("   ✅ Warp Route está configurado com um Hook");
      console.log("   📍 Hook:", warpHook);
      console.log("");
      console.log("   ⚠️  IMPORTANTE: O Hook do Warp Route é usado quando o Warp Route");
      console.log("      envia mensagens. Mas o Mailbox também precisa ter hooks");
      console.log("      configurados (defaultHook e requiredHook) para processar");
      console.log("      mensagens recebidas.");
    } else {
      console.log("   ⚠️  Warp Route NÃO tem Hook configurado");
      console.log("   💡 Isso pode ser normal se o Warp Route usar o hook padrão do Mailbox");
    }
    console.log("");

    // 3.3 Diagnóstico do problema
    console.log("3.3 🔬 DIAGNÓSTICO DO PROBLEMA:");
    console.log("");
    console.log("   📋 Baseado na análise fornecida:");
    console.log("   • O validador está configurado corretamente");
    console.log("   • O Warp Route chama o Mailbox");
    console.log("   • O Mailbox emite eventos Dispatch");
    console.log("   • O Mailbox NÃO está chamando hooks quando recebe mensagens");
    console.log("");
    
    // Verificar se hooks estão configurados
    const hasDefaultHook = mailboxDefaultHook && mailboxDefaultHook !== "0x0000000000000000000000000000000000000000";
    const hasRequiredHook = mailboxRequiredHook && mailboxRequiredHook !== "0x0000000000000000000000000000000000000000";
    
    console.log("   🔍 VERIFICAÇÃO DOS HOOKS DO MAILBOX:");
    if (hasDefaultHook) {
      console.log("   ✅ defaultHook está configurado:", mailboxDefaultHook);
    } else {
      console.log("   ❌ defaultHook NÃO está configurado!");
      console.log("      ⚠️  PROBLEMA: O Mailbox precisa de um defaultHook para processar mensagens");
    }
    
    if (hasRequiredHook) {
      console.log("   ✅ requiredHook está configurado:", mailboxRequiredHook);
    } else {
      console.log("   ⚠️  requiredHook não está configurado (pode ser opcional)");
    }
    console.log("");
    
    // Comparar hook do Warp Route com hooks do Mailbox
    if (warpHook && hasDefaultHook) {
      const hookMatch = warpHook.toLowerCase() === mailboxDefaultHook.toLowerCase();
      if (hookMatch) {
        console.log("   ✅ O Hook do Warp Route corresponde ao defaultHook do Mailbox");
      } else {
        console.log("   ⚠️  O Hook do Warp Route NÃO corresponde ao defaultHook do Mailbox");
        console.log("      • Hook do Warp Route:", warpHook);
        console.log("      • defaultHook do Mailbox:", mailboxDefaultHook);
        console.log("      💡 Isso pode ser normal se o Warp Route usar um hook customizado");
      }
    }
    console.log("");
    
    console.log("   🔍 POSSÍVEIS CAUSAS:");
    if (!hasDefaultHook) {
      console.log("   ❌ 1. O Mailbox NÃO tem defaultHook configurado (PROBLEMA CRÍTICO)");
    } else {
      console.log("   ✅ 1. O Mailbox tem defaultHook configurado");
    }
    console.log("   2. O Warp Route pode estar chamando o Mailbox.dispatch() diretamente");
    console.log("      sem passar pelos hooks (isso é normal, os hooks são chamados pelo Mailbox)");
    console.log("   3. Os hooks podem não estar sendo acionados porque:");
    console.log("      • O Mailbox pode ter uma lógica que pula hooks em certas condições");
    console.log("      • Pode haver uma configuração específica necessária");
    console.log("      • O Warp Route pode precisar ser configurado de forma diferente");
    console.log("");
    console.log("   💡 PRÓXIMOS PASSOS:");
    console.log("   1. Verifique no Etherscan se o Mailbox tem defaultHook e requiredHook:");
    console.log(`      https://sepolia.etherscan.io/address/${warpMailbox}#readContract`);
    console.log("   2. Verifique o código do Warp Route para ver como ele chama o Mailbox:");
    console.log(`      https://sepolia.etherscan.io/address/${WARP_ROUTE_SEPOLIA}#code`);
    console.log("   3. Verifique se há eventos de hook sendo emitidos nas transações");
    console.log("   4. Verifique a documentação do Hyperlane sobre como configurar hooks");
    console.log("");

    // ========================================================================
    // RESUMO FINAL
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📋 RESUMO FINAL");
    console.log("━".repeat(80));
    console.log("");
    console.log("Warp Route:", WARP_ROUTE_SEPOLIA);
    console.log("  • Mailbox:", warpMailbox || "N/A");
    console.log("  • Hook:", warpHook || "N/A");
    console.log("");
    if (warpMailbox) {
      console.log("Mailbox:", warpMailbox);
      console.log("  • defaultHook:", mailboxDefaultHook || "N/A");
      console.log("  • requiredHook:", mailboxRequiredHook || "N/A");
      console.log("");
    }
    console.log("🔗 LINKS ÚTEIS:");
    console.log(`  • Warp Route: https://sepolia.etherscan.io/address/${WARP_ROUTE_SEPOLIA}`);
    if (warpMailbox) {
      console.log(`  • Mailbox: https://sepolia.etherscan.io/address/${warpMailbox}`);
      console.log(`  • Mailbox (Read Contract): https://sepolia.etherscan.io/address/${warpMailbox}#readContract`);
    }
    if (warpHook) {
      console.log(`  • Hook: https://sepolia.etherscan.io/address/${warpHook}`);
    }
    console.log("=".repeat(80) + "\n");
  } catch (error: any) {
    console.error("❌ ERRO ao executar diagnóstico!");
    console.error("  • Message:", error.message);
    console.error("  • Stack:", error.stack);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
