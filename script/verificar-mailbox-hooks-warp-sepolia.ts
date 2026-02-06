import axios from "axios";
import { keccak256 } from "@hyperlane-xyz/utils";

// ==============================
// CONFIGURATION
// ==============================
const SEPOLIA_RPC = "https://1rpc.io/sepolia";
const WARP_ROUTE_SEPOLIA = "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4";

// Function selectors (primeiros 4 bytes do hash keccak256 da assinatura)
// Calculados usando: cast sig "functionName()"
const FUNCTION_SELECTORS: { [key: string]: string } = {
  mailbox: "0xd5438eae",      // cast sig "mailbox()"
  hook: "0x7f5a7c7b",          // cast sig "hook()"
  localDomain: "0x8d3638f4",   // cast sig "localDomain()"
  token: "0xfc0c546a",          // cast sig "token()"
};

// ==============================
// HELPER FUNCTIONS
// ==============================

/**
 * Codifica a chamada de função usando o selector
 */
function encodeFunctionCall(functionName: string): string {
  const selector = FUNCTION_SELECTORS[functionName];
  if (!selector) {
    throw new Error(`Function selector for ${functionName} not found`);
  }
  return selector;
}

/**
 * Decodifica a resposta de uma chamada de função
 */
function decodeFunctionResult(data: string, returnType: "address" | "uint32"): any {
  if (!data || data === "0x") {
    throw new Error("Empty response data");
  }

  // Remove o 0x
  const hexData = data.startsWith("0x") ? data.slice(2) : data;

  // Para endereços (address), pegar os últimos 40 caracteres hex (20 bytes)
  if (returnType === "address") {
    const addressHex = hexData.slice(-40).padStart(40, "0");
    return `0x${addressHex.toLowerCase()}`;
  }

  // Para uint32, pegar os últimos 64 caracteres hex e converter
  if (returnType === "uint32") {
    const uintHex = hexData.slice(-64).padStart(64, "0");
    return parseInt(uintHex, 16);
  }

  return hexData;
}

/**
 * Faz uma chamada RPC eth_call
 */
async function callContract(
  contractAddress: string,
  functionName: string,
  rpcUrl: string
): Promise<string> {
  const selector = encodeFunctionCall(functionName);

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

// ==============================
// MAIN FUNCTION
// ==============================
async function main() {
  console.log("=".repeat(80));
  console.log("🔍 VERIFICAR MAILBOX E HOOKS DO WARP ROUTE SEPOLIA");
  console.log("=".repeat(80));
  console.log("\nWarp Route Sepolia:", WARP_ROUTE_SEPOLIA);
  console.log("RPC URL:", SEPOLIA_RPC);
  console.log("");

  try {
    // 1. Consultar Mailbox
    console.log("📮 Consultando Mailbox...");
    const mailboxData = await callContract(WARP_ROUTE_SEPOLIA, "mailbox", SEPOLIA_RPC);
    const mailbox = decodeFunctionResult(mailboxData, "address");
    console.log("   ✅ Mailbox:", mailbox);
    console.log("");

    // 2. Consultar Hook
    console.log("🔗 Consultando Hook...");
    const hookData = await callContract(WARP_ROUTE_SEPOLIA, "hook", SEPOLIA_RPC);
    const hook = decodeFunctionResult(hookData, "address");
    console.log("   ✅ Hook:", hook);
    console.log("");

    // 3. Consultar Local Domain
    console.log("🌐 Consultando Local Domain...");
    const domainData = await callContract(WARP_ROUTE_SEPOLIA, "localDomain", SEPOLIA_RPC);
    const localDomain = decodeFunctionResult(domainData, "uint32");
    console.log("   ✅ Local Domain:", localDomain, `(${localDomain === 11155111 ? "Sepolia" : "Unknown"})`);
    console.log("");

    // 4. Consultar Token
    console.log("🪙 Consultando Token...");
    const tokenData = await callContract(WARP_ROUTE_SEPOLIA, "token", SEPOLIA_RPC);
    const token = decodeFunctionResult(tokenData, "address");
    console.log("   ✅ Token:", token);
    console.log("");

    // Resumo
    console.log("=".repeat(80));
    console.log("📋 RESUMO");
    console.log("=".repeat(80));
    console.log("  • Warp Route:", WARP_ROUTE_SEPOLIA);
    console.log("  • Mailbox:", mailbox);
    console.log("  • Hook:", hook);
    console.log("  • Local Domain:", localDomain);
    console.log("  • Token:", token);
    console.log("");

    // Links
    console.log("🔗 LINKS:");
    console.log("  • Warp Route:", `https://sepolia.etherscan.io/address/${WARP_ROUTE_SEPOLIA}`);
    console.log("  • Mailbox:", `https://sepolia.etherscan.io/address/${mailbox}`);
    console.log("  • Hook:", `https://sepolia.etherscan.io/address/${hook}`);
    console.log("  • Token:", `https://sepolia.etherscan.io/address/${token}`);
    console.log("=".repeat(80) + "\n");
  } catch (error: any) {
    console.error("❌ ERRO ao consultar contrato!");
    console.error("  • Message:", error.message);
    console.error("  • Stack:", error.stack);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
