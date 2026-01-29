import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { SigningStargateClient, GasPrice } from "@cosmjs/stargate";
import { MsgSubmitProposal } from "cosmjs-types/cosmos/gov/v1beta1/tx";
import { toUtf8 } from "@cosmjs/encoding";

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const WALLET_NAME = "hyperlane-testnet";
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// GET FROM ENVIRONMENT
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || "a5123190601045e1266e57c5d5b1a77f0897b39ea63ed2c761946686939c3cb6";

// ---------------------------
// CONTRACT ADDRESSES (TESTNET)
// ---------------------------
const MAILBOX = "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf";
const ISM_MULTISIG_BSC = "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv";
const ISM_MULTISIG_SOL = "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a";
// ⚠️ IMPORTANTE: Substitua pelo endereço do ISM Multisig Sepolia após instanciá-lo
const ISM_MULTISIG_SEPOLIA = process.env.ISM_MULTISIG_SEPOLIA || "terra1REPLACE_WITH_SEPOLIA_ISM_ADDRESS";
const ISM_ROUTING = "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh";
const IGP = "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9";
const IGP_ORACLE = "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg";

// Domain IDs
const DOMAIN_SEPOLIA = 11155111;
const DOMAIN_TERRACLASSIC = 1325;

// ---------------------------
// EXECUTION MESSAGES
// ---------------------------
interface ExecuteMsg {
  contractAddress: string;
  msg: any;
  description?: string;  // Message description
}

// ============================================================================
// EXECUTION MESSAGES DOCUMENTATION - SEPOLIA CONFIGURATION
// ============================================================================
// This governance proposal configures the instantiated Hyperlane contracts
// to allow cross-chain communication between Terra Classic Testnet and Sepolia Testnet.
// Each message is explained in detail below.
// ============================================================================

const EXEC_MSGS: ExecuteMsg[] = [
  // --------------------------------------------------------------------------
  // MESSAGE 1: Configure ISM Multisig Validators for Sepolia Testnet (Domain 11155111)
  // --------------------------------------------------------------------------
  // Defines the set of validators that will sign messages coming from
  // domain 11155111 (Sepolia Testnet). The threshold of 2 means at least 2 out of 3
  // validators must sign for a message to be considered valid.
  //
  // PARAMETERS:
  // - domain: 11155111 (Sepolia Testnet)
  // - threshold: 2 (minimum of 2 signatures required from 3 validators)
  // - validators: Array of 3 hexadecimal addresses (20 bytes each) of validators
  //
  // CONFIGURED VALIDATORS (Abacus Works):
  // Each validator is an off-chain node that monitors messages and provides signatures.
  // Addresses are hexadecimal representations (without 0x) of Ethereum-style addresses.
  {
    contractAddress: ISM_MULTISIG_SEPOLIA,
    description: "Configure multisig validators for domain 11155111 (Sepolia Testnet) with threshold 2/3",
    msg: {
      set_validators: {
        domain: DOMAIN_SEPOLIA,             // Sepolia Testnet domain ID in Hyperlane protocol
        threshold: 2,                        // Minimum number of required signatures (2 of 3)
        validators: [
          "b22b65f202558adf86a8bb2847b76ae1036686a5",  // Abacus Works Validator 1
          "469f0940684d147defc44f3647146cb90dd0bc8e",  // Abacus Works Validator 2
          "d3c75dcf15056012a4d74c483a0c6ea11d8c2b83",  // Abacus Works Validator 3
        ],
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 2: Configure Remote Gas Data in IGP Oracle for Sepolia Testnet
  // --------------------------------------------------------------------------
  // Defines the token exchange rate and gas price for Sepolia Testnet.
  // This allows IGP to calculate how much gas to charge on the source chain (Terra Testnet)
  // to cover execution costs on Sepolia.
  //
  // PARAMETERS:
  // - remote_domain: 11155111 (Sepolia Testnet)
  // - token_exchange_rate: Exchange rate between LUNC and ETH
  // - gas_price: Gas price on Sepolia (in wei)
  //
  // COST CALCULATION:
  // Cost = (gas_used_on_destination * gas_price * token_exchange_rate)
  //
  // NOTE: Ajuste os valores abaixo conforme necessário:
  // - token_exchange_rate: Taxa de câmbio LUNC:ETH (exemplo: 1000000000000000000 para 1:1 em wei)
  // - gas_price: Gas price em Sepolia (exemplo: 20000000000 para 20 Gwei)
  {
    contractAddress: IGP_ORACLE,
    description: "Configure remote gas data for Sepolia Testnet (Domain 11155111)",
    msg: {
      set_remote_gas_data_configs: {
        configs: [
          {
            remote_domain: DOMAIN_SEPOLIA,                      // Sepolia Testnet
            token_exchange_rate: "1000000000000000000",         // LUNC:ETH exchange rate (ajuste conforme necessário)
            gas_price: "20000000000",                           // Gas price on Sepolia (20 Gwei) - ajuste conforme necessário
          },
        ],
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 3: Set IGP Routes to Oracle for Sepolia Testnet
  // --------------------------------------------------------------------------
  // Configures IGP to use IGP Oracle when calculating gas costs for Sepolia Testnet.
  // This route connects IGP to the Oracle that provides updated price and
  // exchange rate data for Sepolia.
  //
  // PARAMETERS:
  // - domain: 11155111 (Sepolia Testnet)
  // - route: IGP Oracle address that provides gas data
  //
  // FLOW:
  // IGP receives payment -> queries Oracle via route -> calculates cost -> validates payment
  {
    contractAddress: IGP,
    description: "Set IGP routes to query Oracle about gas for Sepolia Testnet (Domain 11155111)",
    msg: {
      router: {
        set_routes: {
          set: [
            {
              domain: DOMAIN_SEPOLIA,          // Sepolia Testnet
              route: IGP_ORACLE,               // Oracle address that provides gas data
            },
          ],
        },
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 4: Add Sepolia to ISM Routing
  // --------------------------------------------------------------------------
  // Adds Sepolia domain to the ISM Routing contract so that messages from
  // Sepolia are validated using the Sepolia ISM Multisig.
  //
  // PARAMETERS:
  // - domain: 11155111 (Sepolia Testnet)
  // - ism: ISM Multisig Sepolia address
  //
  // VALIDATION FLOW:
  // Message received from Sepolia -> Mailbox queries default ISM -> ISM Routing directs to
  // Sepolia ISM Multisig -> ISM Multisig validates signatures (2/3 validators)
  {
    contractAddress: ISM_ROUTING,
    description: "Add Sepolia Testnet (Domain 11155111) to ISM Routing",
    msg: {
      router: {
        set_ism: {
          set: {
            domain: DOMAIN_SEPOLIA,              // Sepolia Testnet
            ism: ISM_MULTISIG_SEPOLIA,           // ISM Multisig Sepolia address
          },
        },
      },
    },
  },
];

// ============================================================================
// CONFIGURATION SUMMARY - SEPOLIA TESTNET
// ============================================================================
// After execution of this proposal, the Hyperlane system will be configured to:
//
// 1. SECURITY: Validate messages using multisig validators:
//    - Sepolia Testnet (domain 11155111): 2/3 validators (Abacus Works)
// 2. PAYMENT: Calculate and process gas payments using IGP + Oracle for Sepolia
// 3. ROUTING: ISM Routing will direct Sepolia messages to Sepolia ISM Multisig
//
// The system will be ready to send and receive cross-chain messages between:
// - Terra Classic Testnet (domain 1325)
// - Sepolia Testnet (domain 11155111)
// ============================================================================

// ---------------------------
// FUNCTIONS
// ---------------------------
function saveExecutionMessages() {
  const fs = require("fs");
  fs.writeFileSync("exec_msgs_sepolia.json", JSON.stringify(EXEC_MSGS, null, 2));
  console.log("✓ exec_msgs_sepolia.json file created successfully!");
}

function saveProposalJson() {
  const fs = require("fs");
  
  // Format for Terra Classic v2.x (Cosmos SDK v0.47+)
  const proposal = {
    messages: EXEC_MSGS.map((execMsg) => ({
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      sender: GOV_MODULE, // governance module
      contract: execMsg.contractAddress,
      msg: execMsg.msg,
      funds: [],
    })),
    metadata: "Configuration of Hyperlane contracts for Sepolia Testnet support",
    deposit: "10000000uluna",
    title: "Hyperlane Contracts Configuration - Sepolia Testnet",
    summary: "Proposal to configure Hyperlane contracts for Sepolia Testnet: set ISM validators (2/3 Abacus Works), configure IGP Oracle for Sepolia, set IGP routes, add Sepolia to ISM Routing",
    expedited: false,
  };

  fs.writeFileSync("proposal_sepolia.json", JSON.stringify(proposal, null, 2));
  console.log("✓ proposal_sepolia.json file created successfully!");
}

async function submitGovernanceProposal(
  client: SigningCosmWasmClient,
  proposer: string
) {
  console.log("\n" + "=".repeat(80));
  console.log("PREPARING HYPERLANE GOVERNANCE PROPOSAL - SEPOLIA TESTNET");
  console.log("=".repeat(80) + "\n");

  const proposalTitle = "Hyperlane Contracts Configuration - Sepolia Testnet";
  const proposalDescription = `
Proposal to configure Hyperlane contracts for Sepolia Testnet support:
- Set validators for ISM Multisig:
  * Sepolia Testnet (domain 11155111): 2/3 validators (Abacus Works)
- Configure remote gas data in IGP Oracle for Sepolia Testnet
- Set IGP routes for Sepolia Testnet
- Add Sepolia Testnet to ISM Routing
  `.trim();

  const initialDeposit = [{ denom: "uluna", amount: "10000000" }]; // 10 LUNC

  console.log("📋 PROPOSAL INFORMATION:");
  console.log("─".repeat(80));
  console.log("Title:", proposalTitle);
  console.log("Initial deposit:", JSON.stringify(initialDeposit));
  console.log("\n🌐 SUPPORTED CHAINS (TESTNET):");
  console.log("  • Sepolia Testnet (Domain 11155111) - 2/3 validators (Abacus Works)");
  console.log("\n📝 EXECUTION MESSAGES (" + EXEC_MSGS.length + " messages):");
  console.log("─".repeat(80));
  
  EXEC_MSGS.forEach((execMsg, idx) => {
    console.log(`\n[${idx + 1}/${EXEC_MSGS.length}] ${execMsg.description || Object.keys(execMsg.msg)[0]}`);
    console.log("─".repeat(80));
    console.log("Contract:", execMsg.contractAddress);
    console.log("Message:", JSON.stringify(execMsg.msg, null, 2));
  });

  // Save files
  console.log("\n" + "=".repeat(80));
  console.log("💾 SAVING FILES...");
  console.log("=".repeat(80));
  saveExecutionMessages();
  saveProposalJson();

  // To submit proposal via CLI, use:
  console.log("\n" + "=".repeat(80));
  console.log("🚀 COMMAND TO SUBMIT VIA CLI:");
  console.log("=".repeat(80));
  console.log("\nExecute the command below to submit the proposal:");
  console.log("\n" + "─".repeat(80));
  console.log(`terrad tx gov submit-proposal proposal_sepolia.json \\
  --from ${WALLET_NAME} \\
  --chain-id ${CHAIN_ID} \\
  --gas auto \\
  --gas-adjustment 1.5 \\
  --gas-prices 28.5uluna \\
  --node ${NODE} \\
  -y`);
  console.log("─".repeat(80));

  console.log("\n" + "=".repeat(80));
  console.log("📁 CREATED FILES:");
  console.log("=".repeat(80));
  console.log("  ✓ exec_msgs_sepolia.json      - Individual execution messages");
  console.log("  ✓ proposal_sepolia.json       - Complete proposal formatted for terrad");
  console.log("\n💡 NEXT STEPS:");
  console.log("─".repeat(80));
  console.log("  1. ⚠️  IMPORTANT: Make sure ISM_MULTISIG_SEPOLIA is set correctly!");
  console.log("     Set environment variable: export ISM_MULTISIG_SEPOLIA='terra1...'");
  console.log("  2. Review the created JSON files");
  console.log("  3. Execute the terrad command above to submit the proposal");
  console.log("  4. Vote on the proposal: terrad tx gov vote <PROPOSAL_ID> yes ...");
  console.log("  5. Wait for the voting period to end");
  console.log("  6. Verify execution by querying the contracts");
  console.log("=".repeat(80) + "\n");
}

async function executeContractsDirectly(
  client: SigningCosmWasmClient,
  sender: string
) {
  console.log("\n" + "=".repeat(80));
  console.log("EXECUTING CONTRACTS DIRECTLY (DIRECT MODE - WITHOUT GOVERNANCE)");
  console.log("=".repeat(80));
  console.log("⚠️  WARNING: This mode executes messages directly without going through governance.");
  console.log("    Use only for testing in development environment!");
  console.log("=".repeat(80) + "\n");

  for (let i = 0; i < EXEC_MSGS.length; i++) {
    const { contractAddress, msg, description } = EXEC_MSGS[i];
    const msgKey = Object.keys(msg)[0];

    console.log(`\n[${i + 1}/${EXEC_MSGS.length}] ${description || msgKey}`);
    console.log("─".repeat(80));
    console.log("Contract:", contractAddress);
    console.log("Message:", JSON.stringify(msg, null, 2));
    console.log("Executing...");

    try {
      const result = await client.execute(
        sender,
        contractAddress,
        msg,
        "auto",
        undefined,
        []
      );

      console.log("✅ SUCCESS!");
      console.log("  • TX Hash:", result.transactionHash);
      console.log("  • Gas used:", result.gasUsed);
      console.log("  • Height:", result.height);
    } catch (error: any) {
      console.error("❌ ERROR!");
      console.error("  • Message:", error.message);
      if (error.log) {
        console.error("  • Log:", error.log);
      }
      throw error;
    }
  }

  console.log("\n" + "=".repeat(80));
  console.log("✅ ALL MESSAGES HAVE BEEN EXECUTED SUCCESSFULLY!");
  console.log("=".repeat(80));
  console.log("\n💡 NEXT STEPS:");
  console.log("─".repeat(80));
  console.log("  1. Verify configurations using terrad query commands");
  console.log("  2. Test cross-chain message sending");
  console.log("  3. Monitor contract events and logs");
  console.log("=".repeat(80) + "\n");
}

async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error("ERROR: Set the PRIVATE_KEY environment variable.");
    console.error('Example: PRIVATE_KEY="abcdef..." npx tsx script/submit-proposal-sepolia.ts');
    return;
  }

  // Check if ISM_MULTISIG_SEPOLIA is set
  if (ISM_MULTISIG_SEPOLIA.includes("REPLACE")) {
    console.error("\n" + "=".repeat(80));
    console.error("⚠️  ERROR: ISM_MULTISIG_SEPOLIA not set!");
    console.error("=".repeat(80));
    console.error("\nYou must first instantiate the ISM Multisig for Sepolia.");
    console.error("Then set the environment variable:");
    console.error("  export ISM_MULTISIG_SEPOLIA='terra1...'");
    console.error("\nOr edit this script and replace ISM_MULTISIG_SEPOLIA constant.");
    console.error("=".repeat(80) + "\n");
    process.exit(1);
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("Wallet loaded:", sender);
  console.log("Chain ID:", CHAIN_ID);
  console.log("Node:", NODE);
  console.log("ISM Multisig Sepolia:", ISM_MULTISIG_SEPOLIA);

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });

  console.log("✓ Connected to node\n");

  // Check execution mode
  const mode = process.env.MODE || "proposal";

  if (mode === "direct") {
    // Execute directly (without governance)
    console.log("Mode: DIRECT EXECUTION");
    await executeContractsDirectly(client, sender);
  } else {
    // Prepare governance proposal
    console.log("Mode: GOVERNANCE PROPOSAL");
    await submitGovernanceProposal(client, sender);
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
