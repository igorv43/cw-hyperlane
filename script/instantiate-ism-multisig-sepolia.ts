import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { SigningStargateClient, GasPrice } from "@cosmjs/stargate";

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// GET FROM ENVIRONMENT
// OBRIGATÓRIO: Defina PRIVATE_KEY ou TERRA_PRIVATE_KEY como variável de ambiente
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// Owner address (governance module)
//const OWNER = "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n";
const OWNER = "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze";

// Code ID for ISM Multisig (same as BSC and Solana)
const CODE_ID_ISM_MULTISIG = 1984;

// Contract name for identification
const CONTRACT_NAME = "hpl_ism_multisig_sepolia";

// Domain ID for Sepolia
const DOMAIN_SEPOLIA = 11155111;

// Validators configuration for Sepolia (Abacus Works)
const SEPOLIA_VALIDATORS = [
  "0x01227B3361d200722c3656f899b48dE187A32494",  // Abacus Works Validator 1

];
const SEPOLIA_THRESHOLD = 1; // 2 out of 3 validators

// ==============================
// INSTANTIATE CONTRACT
// ==============================
async function instantiateContract(
  client: SigningCosmWasmClient,
  sender: string,
  name: string,
  codeId: number,
  msg: any
) {
  console.log(`\n📝 Instantiating ${name}...`);
  console.log("Code ID:", codeId);
  console.log("Init Message:", JSON.stringify(msg, null, 2));

  try {
    const result = await client.instantiate(
      sender,
      codeId,
      msg,
      name,
      "auto",
      {
        admin: OWNER, // Governance module as admin
      }
    );

    console.log("✅ SUCCESS!");
    console.log("  • Contract Address:", result.contractAddress);
    console.log("  • TX Hash:", result.transactionHash);
    console.log("  • Gas Used:", result.gasUsed);
    console.log("  • Height:", result.height);

    return result.contractAddress;
  } catch (error: any) {
    console.error("❌ ERROR!");
    console.error("  • Message:", error.message);
    if (error.log) {
      console.error("  • Log:", error.log);
    }
    throw error;
  }
}

// ==============================
// EXECUTE CONTRACT (Configure Validators)
// ==============================
async function configureValidators(
  client: SigningCosmWasmClient,
  sender: string,
  contractAddress: string,
  domain: number,
  threshold: number,
  validators: string[]
) {
  console.log(`\n⚙️  Configuring validators for domain ${domain}...`);
  console.log("  • Threshold:", threshold);
  console.log("  • Validators:", validators.length);
  console.log("  • Validator addresses:", validators);

  const msg = {
    set_validators: {
      domain: domain,
      threshold: threshold,
      validators: validators,
    },
  };

  try {
    const result = await client.execute(
      sender,
      contractAddress,
      msg,
      "auto"
    );

    console.log("✅ Validators configured successfully!");
    console.log("  • TX Hash:", result.transactionHash);
    console.log("  • Gas Used:", result.gasUsed);
    console.log("  • Height:", result.height);

    return result;
  } catch (error: any) {
    console.error("❌ ERROR configuring validators!");
    console.error("  • Message:", error.message);
    if (error.log) {
      console.error("  • Log:", error.log);
    }
    throw error;
  }
}

async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error("ERROR: Set the PRIVATE_KEY environment variable.");
    console.error('Example: PRIVATE_KEY="abcdef..." npx tsx script/instantiate-ism-multisig-sepolia.ts');
    return;
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("=".repeat(80));
  console.log("INSTANTIATE ISM MULTISIG FOR SEPOLIA TESTNET");
  console.log("=".repeat(80));
  console.log("\nWallet:", sender);
  console.log("Chain ID:", CHAIN_ID);
  console.log("Node:", NODE);
  console.log("Owner (Admin):", OWNER);

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });

  console.log("✓ Connected to node\n");

  // --------------------------------------------------
  // ISM MULTISIG - For Sepolia (Domain 11155111)
  // --------------------------------------------------
  // ISM that validates messages using signatures from multiple validators.
  // Requires a minimum threshold of signatures to approve a message.
  const ismMultisigSepoliaInit = {
    owner: OWNER,  // Address that can configure validators and threshold
  };

  console.log("\n🔐 Instantiating ISM MULTISIG for Sepolia Testnet (Domain 11155111)");
  console.log("Instantiation Parameters:", JSON.stringify(ismMultisigSepoliaInit, null, 2));

  // Step 1: Instantiate the contract
  const contractAddress = await instantiateContract(
    client,
    sender,
    CONTRACT_NAME,
    CODE_ID_ISM_MULTISIG,
    ismMultisigSepoliaInit
  );

  // Step 2: Configure validators immediately after instantiation
  console.log("\n" + "─".repeat(80));
  await configureValidators(
    client,
    sender,
    contractAddress,
    DOMAIN_SEPOLIA,
    SEPOLIA_THRESHOLD,
    SEPOLIA_VALIDATORS
  );

  console.log("\n" + "=".repeat(80));
  console.log("✅ ISM MULTISIG SEPOLIA INSTANTIATED AND CONFIGURED SUCCESSFULLY!");
  console.log("=".repeat(80));
  console.log("\n📋 CONTRACT INFORMATION:");
  console.log("─".repeat(80));
  console.log("  • Contract Address:", contractAddress);
  console.log("  • Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
  console.log("  • Threshold:", SEPOLIA_THRESHOLD, "of", SEPOLIA_VALIDATORS.length);
  console.log("  • Validators configured:", SEPOLIA_VALIDATORS.length);
  console.log("\n📋 NEXT STEPS:");
  console.log("─".repeat(80));
  console.log("1. Save the contract address above");
  console.log("2. Set environment variable:");
  console.log(`   export ISM_MULTISIG_SEPOLIA='${contractAddress}'`);
  console.log("3. Continue with IGP and ISM Routing configuration via governance:");
  console.log("   PRIVATE_KEY=... ISM_MULTISIG_SEPOLIA=" + contractAddress + " npx tsx script/submit-proposal-sepolia.ts");
  console.log("   (Note: Validators are already configured, so you can skip that message in the proposal)");
  console.log("=".repeat(80) + "\n");
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
