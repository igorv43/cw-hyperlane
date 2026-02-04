import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { GasPrice } from "@cosmjs/stargate";

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// GET FROM ENVIRONMENT
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// ---------------------------
// CONTRACT ADDRESSES (TESTNET)
// ---------------------------
// ISM Routing que você É owner (pode executar diretamente)
const ISM_ROUTING = process.env.ISM_ROUTING || "terra1na6ljyf4m5x2u7llfvvxxe2nyq0t8628qyk0vnwu4ttpq86tt0cse47t68";

// ISM Multisig Sepolia (já configurado)
const ISM_MULTISIG_SEPOLIA = process.env.ISM_MULTISIG_SEPOLIA || "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa";

// Domain IDs
const DOMAIN_SEPOLIA = 11155111;

// ============================================================================
// MAIN FUNCTION
// ============================================================================

async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error("ERROR: Set the PRIVATE_KEY environment variable.");
    console.error('Example: PRIVATE_KEY="abcdef..." npx tsx script/add-ism-sepolia-to-routing.ts');
    return;
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("=".repeat(80));
  console.log("🚀 ADICIONAR ISM SEPOLIA AO ISM ROUTING");
  console.log("=".repeat(80));
  console.log("\nConfiguration:");
  console.log("  Wallet:", sender);
  console.log("  Chain ID:", CHAIN_ID);
  console.log("  Node:", NODE);
  console.log("  ISM Routing:", ISM_ROUTING);
  console.log("  ISM Multisig Sepolia:", ISM_MULTISIG_SEPOLIA);
  console.log("  Domain Sepolia:", DOMAIN_SEPOLIA);

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });

  console.log("\n✓ Connected to node\n");

  // Prepare execution message
  const execMsg = {
    set: {
      ism: {
        domain: DOMAIN_SEPOLIA,
        address: ISM_MULTISIG_SEPOLIA,
      },
    },
  };

  console.log("=".repeat(80));
  console.log("📋 EXECUTION MESSAGE");
  console.log("=".repeat(80));
  console.log("\nContract:", ISM_ROUTING);
  console.log("Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
  console.log("ISM Multisig:", ISM_MULTISIG_SEPOLIA);
  console.log("\nMessage:", JSON.stringify(execMsg, null, 2));
  console.log("");

  // Execute
  console.log("⏳ Executando transação...");
  console.log("");

  try {
    const result = await client.execute(
      sender,
      ISM_ROUTING,
      execMsg,
      "auto",
      undefined,
      []
    );

    console.log("=".repeat(80));
    console.log("✅ SUCESSO!");
    console.log("=".repeat(80));
    console.log("\n📋 RESULTADO:");
    console.log("─".repeat(80));
    console.log("  • TX Hash:", result.transactionHash);
    console.log("  • Gas used:", result.gasUsed);
    console.log("  • Height:", result.height);
    console.log("\n💡 ISM Sepolia adicionado ao ISM Routing com sucesso!");
    console.log("\n📋 LINK DA TRANSAÇÃO:");
    console.log("─".repeat(80));
    console.log(`  https://finder.terra-classic.hexxagon.dev/testnet/tx/${result.transactionHash}`);
    console.log("\n" + "=".repeat(80));
  } catch (error: any) {
    console.error("=".repeat(80));
    console.error("❌ ERRO!");
    console.error("=".repeat(80));
    console.error("\n  • Message:", error.message);
    
    if (error.message && error.message.includes("Unauthorized")) {
      console.log("\n⚠️  UNAUTHORIZED");
      console.log("─".repeat(80));
      console.log("A wallet não é owner do ISM Routing.");
      console.log("Verifique se o endereço do ISM Routing está correto:");
      console.log("  ISM_ROUTING=" + ISM_ROUTING);
      console.log("\nPara usar outro ISM Routing:");
      console.log("  ISM_ROUTING=<endereço> npx tsx script/add-ism-sepolia-to-routing.ts");
    } else if (error.log) {
      console.error("  • Log:", error.log);
    }
    
    console.log("\n" + "=".repeat(80));
    throw error;
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
