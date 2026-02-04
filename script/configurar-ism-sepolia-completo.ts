import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient, CosmWasmClient } from "@cosmjs/cosmwasm-stargate";
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
const ISM_MULTISIG_SEPOLIA = "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa";
const ISM_ROUTING = "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh";

// Domain IDs
const DOMAIN_SEPOLIA = 11155111;

// Validators configuration for Sepolia (Abacus Works)
const SEPOLIA_VALIDATORS = [
  "b22b65f202558adf86a8bb2847b76ae1036686a5",  // Abacus Works Validator 1
  "469f0940684d147defc44f3647146cb90dd0bc8e",  // Abacus Works Validator 2
  "d3c75dcf15056012a4d74c483a0c6ea11d8c2b83",  // Abacus Works Validator 3
];
const SEPOLIA_THRESHOLD = 2; // 2 out of 3 validators

// ============================================================================
// FUNCTIONS
// ============================================================================

/**
 * Query validators configured in ISM Multisig Sepolia
 */
async function queryValidators(client: CosmWasmClient): Promise<void> {
  console.log("\n" + "=".repeat(80));
  console.log("📋 QUERYING ISM MULTISIG SEPOLIA CONFIGURATION");
  console.log("=".repeat(80) + "\n");

  try {
    const queryMsg = {
      multisig_ism: {
        enrolled_validators: {
          domain: DOMAIN_SEPOLIA,
        },
      },
    };

    console.log("Querying ISM Multisig Sepolia...");
    console.log("Contract:", ISM_MULTISIG_SEPOLIA);
    console.log("Domain:", DOMAIN_SEPOLIA);
    console.log("");

    const result = await client.queryContractSmart(ISM_MULTISIG_SEPOLIA, queryMsg);

    console.log("✅ QUERY SUCCESSFUL!");
    console.log("─".repeat(80));
    console.log("Validators:", result.validators?.length || 0);
    console.log("Threshold:", result.threshold || "N/A");
    
    if (result.validators && result.validators.length > 0) {
      console.log("\n📋 Configured Validators:");
      result.validators.forEach((val: string, idx: number) => {
        console.log(`  [${idx + 1}] ${val}`);
      });
    } else {
      console.log("\n⚠️  No validators configured yet.");
    }

    console.log("\n" + "=".repeat(80));
    return result;
  } catch (error: any) {
    console.error("❌ ERROR QUERYING VALIDATORS!");
    console.error("─".repeat(80));
    console.error("Error:", error.message);
    console.log("\n" + "=".repeat(80));
    return null;
  }
}

/**
 * Configure validators in ISM Multisig Sepolia
 */
async function configureValidators(
  client: SigningCosmWasmClient,
  sender: string
): Promise<void> {
  console.log("\n" + "=".repeat(80));
  console.log("⚙️  CONFIGURING VALIDATORS IN ISM MULTISIG SEPOLIA");
  console.log("=".repeat(80) + "\n");

  const execMsg = {
    set_validators: {
      domain: DOMAIN_SEPOLIA,
      threshold: SEPOLIA_THRESHOLD,
      validators: SEPOLIA_VALIDATORS,
    },
  };

  console.log("📋 EXECUTION MESSAGE:");
  console.log("─".repeat(80));
  console.log("Contract:", ISM_MULTISIG_SEPOLIA);
  console.log("Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
  console.log("Threshold:", SEPOLIA_THRESHOLD, "of", SEPOLIA_VALIDATORS.length);
  console.log("Validators:", SEPOLIA_VALIDATORS.length);
  console.log("\nMessage:", JSON.stringify(execMsg, null, 2));
  console.log("");

  console.log("Executing transaction...");
  console.log("");

  try {
    const result = await client.execute(
      sender,
      ISM_MULTISIG_SEPOLIA,
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
    console.log("\n💡 Validators configured successfully!");
    console.log("=".repeat(80) + "\n");
  } catch (error: any) {
    console.error("❌ ERROR!");
    console.error("─".repeat(80));
    console.error("  • Message:", error.message);
    if (error.log) {
      console.error("  • Log:", error.log);
    }
    throw error;
  }
}

/**
 * Try to add ISM Sepolia to ISM Routing (will fail if not owner)
 */
async function tryAddToISMRouting(
  client: SigningCosmWasmClient,
  sender: string
): Promise<void> {
  console.log("\n" + "=".repeat(80));
  console.log("🚀 TENTANDO ADICIONAR ISM SEPOLIA AO ISM ROUTING");
  console.log("=".repeat(80) + "\n");

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
    console.log("\n💡 ISM Sepolia added to ISM Routing successfully!");
    console.log("=".repeat(80) + "\n");
  } catch (error: any) {
    console.error("❌ ERROR!");
    console.error("─".repeat(80));
    console.error("  • Message:", error.message);
    
    if (error.message && error.message.includes("Unauthorized")) {
      console.log("\n" + "=".repeat(80));
      console.log("⚠️  UNAUTHORIZED - ISM Routing Owner Check");
      console.log("=".repeat(80));
      console.log("\nO contrato ISM Routing pertence ao módulo de governança.");
      console.log("Para adicionar o ISM Sepolia, você precisa:");
      console.log("\n1. Criar uma proposta de governança:");
      console.log("   npx tsx script/submit-proposal-sepolia.ts");
      console.log("\n2. A proposta será executada pelo módulo de governança");
      console.log("   (que é o owner do ISM Routing)");
      console.log("\n3. Após votação e aprovação, será executado automaticamente");
      console.log("=".repeat(80) + "\n");
    } else if (error.log) {
      console.error("  • Log:", error.log);
    }
    // Não throw error aqui, apenas informa
  }
}

/**
 * Main function
 */
async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error("ERROR: Set the PRIVATE_KEY environment variable.");
    console.error('Example: PRIVATE_KEY="abcdef..." npx tsx script/configurar-ism-sepolia-completo.ts');
    return;
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("=".repeat(80));
  console.log("🔧 CONFIGURAR ISM SEPOLIA COMPLETO");
  console.log("=".repeat(80));
  console.log("\nConfiguration:");
  console.log("  Wallet:", sender);
  console.log("  Chain ID:", CHAIN_ID);
  console.log("  Node:", NODE);
  console.log("  ISM Multisig Sepolia:", ISM_MULTISIG_SEPOLIA);
  console.log("  ISM Routing:", ISM_ROUTING);
  console.log("  Domain Sepolia:", DOMAIN_SEPOLIA);

  // Connect clients
  const signingClient = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });

  const queryClient = await CosmWasmClient.connect(NODE);

  console.log("\n✓ Connected to node\n");

  // Step 1: Query current validators
  await queryValidators(queryClient);

  // Step 2: Configure validators (if needed or force)
  const mode = process.env.MODE || "query";
  if (mode === "configure" || mode === "execute") {
    await configureValidators(signingClient, sender);
    
    // Wait a bit
    console.log("⏳ Waiting 5 seconds...");
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Query again to verify
    console.log("\n🔍 Verifying validators were configured...");
    await queryValidators(queryClient);
  }

  // Step 3: Try to add to ISM Routing (will show error if not owner)
  if (mode === "execute" || mode === "add") {
    await tryAddToISMRouting(signingClient, sender);
  } else {
    console.log("\n💡 Para tentar adicionar ao ISM Routing, execute com MODE=execute:");
    console.log("   MODE=execute npx tsx script/configurar-ism-sepolia-completo.ts");
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
