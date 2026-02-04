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
const ISM_ROUTING = "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh";
const ISM_MULTISIG_SEPOLIA = process.env.ISM_MULTISIG_SEPOLIA || "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa";

// Domain IDs
const DOMAIN_SEPOLIA = 11155111;

/**
 * Execute the message to add Sepolia ISM to ISM Routing
 */
async function addSepoliaISM(
  client: SigningCosmWasmClient,
  sender: string
): Promise<void> {
  console.log("\n" + "=".repeat(80));
  console.log("🚀 ADDING SEPOLIA ISM TO ISM ROUTING");
  console.log("=".repeat(80) + "\n");

  // Format from contracts/isms/routing/src/contract.rs
  // ExecuteMsg::Set { ism: IsmSet }
  // IsmSet { domain: u32, address: String }
  const execMsg = {
    set: {
      ism: {
        domain: DOMAIN_SEPOLIA,
        address: ISM_MULTISIG_SEPOLIA,
      },
    },
  };

  console.log("📋 EXECUTION MESSAGE:");
  console.log("─".repeat(80));
  console.log("Contract:", ISM_ROUTING);
  console.log("Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
  console.log("ISM Multisig:", ISM_MULTISIG_SEPOLIA);
  console.log("\nMessage:", JSON.stringify(execMsg, null, 2));
  console.log("");

  // Check if ISM_MULTISIG_SEPOLIA is set correctly
  if (ISM_MULTISIG_SEPOLIA.includes("REPLACE") || !ISM_MULTISIG_SEPOLIA.startsWith("terra")) {
    console.error("⚠️  ERROR: ISM_MULTISIG_SEPOLIA not set correctly!");
    console.error("=".repeat(80));
    console.error("\nYou must set the ISM Multisig Sepolia address.");
    console.error("Set environment variable:");
    console.error("  export ISM_MULTISIG_SEPOLIA='terra1...'");
    console.error("=".repeat(80) + "\n");
    process.exit(1);
  }

  console.log("Executing transaction...");
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

    console.log("✅ SUCCESS!");
    console.log("─".repeat(80));
    console.log("  • TX Hash:", result.transactionHash);
    console.log("  • Gas used:", result.gasUsed);
    console.log("  • Height:", result.height);
    console.log("\n💡 Next steps:");
    console.log("  1. Wait for transaction confirmation");
    console.log("  2. Test cross-chain message sending from Sepolia");
    console.log("=".repeat(80) + "\n");
  } catch (error: any) {
    console.error("❌ ERROR!");
    console.error("─".repeat(80));
    console.error("  • Message:", error.message);
    if (error.log) {
      console.error("  • Log:", error.log);
    }
    
    // Check if it's already configured
    if (error.message && error.message.includes("already") || error.message.includes("duplicate")) {
      console.log("\n✅ ISM Sepolia may already be configured!");
    }
    
    throw error;
  }
}

/**
 * Main function
 */
async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error("ERROR: Set the PRIVATE_KEY environment variable.");
    console.error('Example: PRIVATE_KEY="abcdef..." npx tsx script/add-ism-sepolia-simples.ts');
    return;
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("=".repeat(80));
  console.log("🔧 ADD SEPOLIA ISM TO ISM ROUTING");
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

  // Execute
  await addSepoliaISM(client, sender);
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
