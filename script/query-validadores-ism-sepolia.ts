import { CosmWasmClient } from "@cosmjs/cosmwasm-stargate";

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const NODE = "https://rpc.luncblaze.com:443";

// ISM Multisig Sepolia
const ISM_MULTISIG_SEPOLIA = process.env.ISM_MULTISIG_SEPOLIA || "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa";

// Domain ID for Sepolia
const DOMAIN_SEPOLIA = 11155111;

async function main() {
  console.log("=".repeat(80));
  console.log("🔍 QUERY: VALIDADORES CONFIGURADOS NO ISM MULTISIG SEPOLIA");
  console.log("=".repeat(80));
  console.log("\nContract:", ISM_MULTISIG_SEPOLIA);
  console.log("Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
  console.log("Node:", NODE);
  console.log("");

  try {
    const client = await CosmWasmClient.connect(NODE);
    console.log("✓ Connected to node\n");

    // Query validators for Sepolia domain
    const queryMsg = {
      multisig_ism: {
        enrolled_validators: {
          domain: DOMAIN_SEPOLIA,
        },
      },
    };

    console.log("📋 Query Message:");
    console.log(JSON.stringify(queryMsg, null, 2));
    console.log("");

    const result = await client.queryContractSmart(ISM_MULTISIG_SEPOLIA, queryMsg);

    console.log("=".repeat(80));
    console.log("✅ RESULTADO DA QUERY");
    console.log("=".repeat(80));
    console.log("\n" + JSON.stringify(result, null, 2));
    console.log("");

    if (result && result.validators) {
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log("📋 VALIDADORES CONFIGURADOS:");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log("  • Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
      console.log("  • Threshold:", result.threshold || "N/A");
      console.log("  • Número de validadores:", result.validators?.length || 0);
      console.log("  • Validadores:");
      if (result.validators && Array.isArray(result.validators)) {
        result.validators.forEach((validator: string, index: number) => {
          console.log(`    ${index + 1}. 0x${validator}`);
        });
      }
      console.log("");
    }

    // Also query threshold
    try {
      const thresholdQuery = {
        ism: {
          threshold: {
            domain: DOMAIN_SEPOLIA,
          },
        },
      };
      const thresholdResult = await client.queryContractSmart(ISM_MULTISIG_SEPOLIA, thresholdQuery);
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log("📋 THRESHOLD CONFIGURADO:");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log("  • Threshold:", thresholdResult.threshold || "N/A");
      console.log("");
    } catch (e) {
      // Ignore if threshold query fails
    }

    console.log("=".repeat(80));
  } catch (error: any) {
    console.error("=".repeat(80));
    console.error("❌ ERRO AO CONSULTAR");
    console.error("=".repeat(80));
    console.error("\n  • Message:", error.message);
    if (error.log) {
      console.error("  • Log:", error.log);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
