import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { SigningStargateClient, GasPrice } from "@cosmjs/stargate";
import { MsgSubmitProposal } from "cosmjs-types/cosmos/gov/v1beta1/tx";
import { toUtf8 } from "@cosmjs/encoding";

// ==============================
// CONFIGURATION
// ==============================
const WALLET_NAME = "teste01";
const CHAIN_ID = "localterra";
const NODE = "http://localhost:26657";

// GET FROM ENVIRONMENT
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || "1ec75f8200aa0318152405d0e7729eb24e4b9b45e0a91df932c0d57756d9ebbc";

// ---------------------------
// CONTRACT ADDRESSES
// ---------------------------
const MAILBOX = "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au";
const ISM_MULTISIG = "terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp";
const ISM_ROUTING = "terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul";
const IGP = "terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth";
const IGP_ORACLE = "terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz";
const HOOK_MERKLE = "terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2";
const HOOK_AGG_1 = "terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z";
const HOOK_PAUSABLE = "terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt";
const HOOK_FEE = "terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl";
const HOOK_AGG_2 = "terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq";

// AGGREGATE 1 = merkle + igp
const AGG_HOOK_DEFAULT = HOOK_AGG_1;

// AGGREGATE 2 = pausable + fee
const AGG_HOOK_REQUIRED = HOOK_AGG_2;

// ---------------------------
// EXECUTION MESSAGES
// ---------------------------
interface ExecuteMsg {
  contractAddress: string;
  msg: any;
  description?: string;  // Message description
}

// ============================================================================
// EXECUTION MESSAGES DOCUMENTATION
// ============================================================================
// This governance proposal configures the instantiated Hyperlane contracts
// to allow cross-chain communication between Terra Classic and BSC (Binance Smart Chain).
// Each message is explained in detail below.
// ============================================================================

const EXEC_MSGS: ExecuteMsg[] = [
  // --------------------------------------------------------------------------
  // MESSAGE 1: Configure ISM Multisig Validators for Ethereum (Domain 1)
  // --------------------------------------------------------------------------
  // Defines the set of validators that will sign messages coming from
  // domain 1 (Ethereum). The threshold of 6 means at least 6 out of 9
  // validators must sign for a message to be considered valid.
  //
  // PARAMETERS:
  // - domain: 1 (Ethereum)
  // - threshold: 6 (minimum of 6 signatures required from 9 validators)
  // - validators: Array of 9 hexadecimal addresses (20 bytes each) of validators
  //
  // CONFIGURED VALIDATORS:
  // Each validator is an off-chain node that monitors messages and provides signatures.
  // Addresses are hexadecimal representations (without 0x) of Ethereum-style addresses.
  {
    contractAddress: ISM_MULTISIG,
    description: "Configure multisig validators for domain 1 (Ethereum) with threshold 6/9",
    msg: {
      set_validators: {
        domain: 1,              // Ethereum domain ID in Hyperlane protocol
        threshold: 6,           // Minimum number of required signatures (6 of 9)
        validators: [
          "03c842db86a6a3e524d4a6615390c1ea8e2b9541",  // Validator 1
          "94438a7de38d4548ae54df5c6010c4ebc5239eae",  // Validator 2
          "5450447aee7b544c462c9352bef7cad049b0c2dc",  // Validator 3
          "b3ac35d3988bca8c2ffd195b1c6bee18536b317b",  // Validator 4
          "b683b742b378632a5f73a2a5a45801b3489bba44",  // Validator 5
          "3786083ca59dc806d894104e65a13a70c2b39276",  // Validator 6
          "4f977a59fdc2d9e39f6d780a84d5b4add1495a36",  // Validator 7
          "29d783efb698f9a2d3045ef4314af1f5674f52c5",  // Validator 8
          "36a669703ad0e11a0382b098574903d2084be22c",  // Validator 9
        ],
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 2: Configure ISM Multisig Validators for BSC (Domain 56)
  // --------------------------------------------------------------------------
  // Defines the set of validators that will sign messages coming from
  // domain 56 (BSC). The threshold of 2 means at least 2 out of 6
  // validators must sign for a message to be considered valid.
  //
  // PARAMETERS:
  // - domain: 56 (BSC - Binance Smart Chain)
  // - threshold: 2 (minimum of 2 signatures required from 6 validators)
  // - validators: Array of 6 hexadecimal addresses (20 bytes each) of validators
  {
    contractAddress: ISM_MULTISIG,
    description: "Configure multisig validators for domain 56 (BSC) with threshold 2/6",
    msg: {
      set_validators: {
        domain: 56,             // BSC domain ID in Hyperlane protocol
        threshold: 2,           // Minimum number of required signatures (2 of 6)
        validators: [
          "570af9b7b36568c8877eebba6c6727aa9dab7268",  // Validator 1
          "5450447aee7b544c462c9352bef7cad049b0c2dc",  // Validator 2
          "0d4c1394a255568ec0ecd11795b28d1bda183ca4",  // Validator 3
          "24c1506142b2c859aee36474e59ace09784f71e8",  // Validator 4
          "c67789546a7a983bf06453425231ab71c119153f",  // Validator 5
          "2d74f6edfd08261c927ddb6cb37af57ab89f0eff",  // Validator 6
        ],
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 3: Configure ISM Multisig Validators for Solana (Domain 1399811149)
  // --------------------------------------------------------------------------
  // Defines the set of validators that will sign messages coming from
  // domain 1399811149 (Solana). The threshold of 3 means at least 3 out of 5
  // validators must sign for a message to be considered valid.
  //
  // PARAMETERS:
  // - domain: 1399811149 (Solana)
  // - threshold: 3 (minimum of 3 signatures required from 5 validators)
  // - validators: Array of 5 hexadecimal addresses (20 bytes each) of validators
  {
    contractAddress: ISM_MULTISIG,
    description: "Configure multisig validators for domain 1399811149 (Solana) with threshold 3/5",
    msg: {
      set_validators: {
        domain: 1399811149,     // Solana domain ID in Hyperlane protocol
        threshold: 3,           // Minimum number of required signatures (3 of 5)
        validators: [
          "28464752829b3ea59a497fca0bdff575c534c3ff",  // Validator 1
          "2b7514a2f77bd86bbf093fe6bb67d8611f51c659",  // Validator 2
          "cb6bcbd0de155072a7ff486d9d7286b0f71dcc2d",  // Validator 3
          "4f977a59fdc2d9e39f6d780a84d5b4add1495a36",  // Validator 4
          "5450447aee7b544c462c9352bef7cad049b0c2dc",  // Validator 5
        ],
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 4: Configure Remote Gas Data in IGP Oracle (All Chains)
  // --------------------------------------------------------------------------
  // Defines the token exchange rate and gas price for all supported domains:
  // - Domain 1 (Ethereum)
  // - Domain 56 (BSC)
  // - Domain 1399811149 (Solana)
  //
  // This allows IGP to calculate how much gas to charge on the source chain (Terra)
  // to cover execution costs on the destination chains.
  //
  // PARAMETERS:
  // - remote_domain: Chain domain ID
  // - token_exchange_rate: Exchange rate between LUNC and destination chain token
  // - gas_price: Gas price on destination chain
  //
  // COST CALCULATION:
  // Cost = (gas_used_on_destination * gas_price * token_exchange_rate)
  {
    contractAddress: IGP_ORACLE,
    description: "Configure remote gas data for all domains (Ethereum, BSC, Solana)",
    msg: {
      set_remote_gas_data_configs: {
        configs: [
          {
            remote_domain: 1,               // Ethereum
            token_exchange_rate: "1",       // LUNC:ETH exchange rate (1:1)
            gas_price: "50000000",          // Gas price on Ethereum (50 Gwei simplified)
          },
          {
            remote_domain: 56,              // BSC
            token_exchange_rate: "1",       // LUNC:BNB exchange rate (1:1)
            gas_price: "50000000",          // Gas price on BSC (50 Gwei simplified)
          },
          {
            remote_domain: 1399811149,      // Solana
            token_exchange_rate: "1",       // LUNC:SOL exchange rate (1:1)
            gas_price: "50000000",          // Gas price on Solana (simplified)
          },
        ],
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 5: Set IGP Routes to Oracle (All Chains)
  // --------------------------------------------------------------------------
  // Configures IGP to use IGP Oracle when calculating gas costs for all domains:
  // - Domain 1 (Ethereum)
  // - Domain 56 (BSC)
  // - Domain 1399811149 (Solana)
  //
  // These routes connect IGP to the Oracle that provides updated price and
  // exchange rate data for each destination chain.
  //
  // PARAMETERS:
  // - domain: Chain domain ID
  // - route: IGP Oracle address that provides gas data
  //
  // FLOW:
  // IGP receives payment -> queries Oracle via route -> calculates cost -> validates payment
  {
    contractAddress: IGP,
    description: "Set IGP routes to query Oracle about gas for all domains (Ethereum, BSC, Solana)",
    msg: {
      router: {
        set_routes: {
          set: [
            {
              domain: 1,           // Ethereum
              route: IGP_ORACLE,   // Oracle address that provides gas data
            },
            {
              domain: 56,          // BSC
              route: IGP_ORACLE,   // Oracle address that provides gas data
            },
            {
              domain: 1399811149,  // Solana
              route: IGP_ORACLE,   // Oracle address that provides gas data
            },
          ],
        },
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 6: Set Default ISM in Mailbox
  // --------------------------------------------------------------------------
  // Configures the default ISM (Interchain Security Module) that will be used by
  // Mailbox to validate received messages. ISM Routing allows using
  // different validation strategies per source domain.
  //
  // PARAMETERS:
  // - ism: ISM Routing address (routes to different ISM Multisig for each chain)
  //
  // VALIDATION FLOW:
  // Message received -> Mailbox queries default ISM -> ISM Routing directs to
  // appropriate ISM Multisig based on origin domain -> ISM Multisig validates signatures
  // - Domain 1 (Ethereum): 6/9 validators
  // - Domain 56 (BSC): 2/6 validators
  // - Domain 1399811149 (Solana): 3/5 validators
  {
    contractAddress: MAILBOX,
    description: "Set ISM Routing as Mailbox default security module (supports Ethereum, BSC, Solana)",
    msg: {
      set_default_ism: {
        ism: ISM_ROUTING,  // ISM Routing address
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 7: Set Default Hook in Mailbox
  // --------------------------------------------------------------------------
  // Configures the default Hook that will be executed when sending messages.
  // Hook Aggregate #1 combines Merkle Tree Hook (for proofs) and IGP (for payment).
  //
  // DEFAULT HOOK COMPONENTS:
  // 1. Merkle Hook: Adds message to Merkle tree for inclusion proofs
  // 2. IGP Hook: Processes gas payment for execution on destination chain
  //
  // SEND FLOW:
  // dispatch() called -> Default hook executed -> Merkle registers message ->
  // IGP processes payment -> Message emitted as event
  {
    contractAddress: MAILBOX,
    description: "Set Hook Aggregate #1 (Merkle + IGP) as default hook for message sending",
    msg: {
      set_default_hook: {
        hook: AGG_HOOK_DEFAULT,  // Hook Aggregate #1 (Merkle + IGP)
      },
    },
  },

  // --------------------------------------------------------------------------
  // MESSAGE 8: Set Required Hook in Mailbox
  // --------------------------------------------------------------------------
  // Configures the mandatory Hook that will ALWAYS be executed when sending messages,
  // regardless of custom hooks specified by the sender.
  // Hook Aggregate #2 combines Hook Pausable (emergency) and Hook Fee (monetization).
  //
  // REQUIRED HOOK COMPONENTS:
  // 1. Hook Pausable: Allows pausing message sending in case of emergency/maintenance
  // 2. Hook Fee: Charges fixed fee of 0.283215 LUNC per message (anti-spam/monetization)
  //
  // SEND FLOW (complete order):
  // dispatch() -> Required hook (Pausable checks if not paused, Fee charges fee) ->
  // Default hook (Merkle + IGP) -> Message sent
  //
  // IMPORTANT: Required hook is executed BEFORE default hook and cannot be bypassed.
  {
    contractAddress: MAILBOX,
    description: "Set Hook Aggregate #2 (Pausable + Fee) as required (mandatory) hook for sending",
    msg: {
      set_required_hook: {
        hook: AGG_HOOK_REQUIRED,  // Hook Aggregate #2 (Pausable + Fee)
      },
    },
  },
];

// ============================================================================
// CONFIGURATION SUMMARY
// ============================================================================
// After execution of this proposal, the Hyperlane system will be configured to:
//
// 1. SECURITY: Validate messages using multisig validators:
//    - Ethereum (domain 1): 6/9 validators
//    - BSC (domain 56): 2/6 validators
//    - Solana (domain 1399811149): 3/5 validators
// 2. PAYMENT: Calculate and process gas payments using IGP + Oracle for all chains
// 3. PROOFS: Maintain Merkle tree of sent messages
// 4. CONTROL: Allow emergency pause via Hook Pausable
// 5. MONETIZATION: Charge fee of 0.283215 LUNC per message via Hook Fee
//
// The system will be ready to send and receive cross-chain messages between:
// - Terra Classic (domain 1325)
// - Ethereum (domain 1)
// - BSC (domain 56)
// - Solana (domain 1399811149)
// ============================================================================

// ---------------------------
// FUNCTIONS
// ---------------------------
function saveExecutionMessages() {
  const fs = require("fs");
  fs.writeFileSync("exec_msgs.json", JSON.stringify(EXEC_MSGS, null, 2));
  console.log("✓ exec_msgs.json file created successfully!");
}

function saveProposalJson() {
  const fs = require("fs");
  
  // Format for Terra Classic v2.x (Cosmos SDK v0.47+)
  const proposal = {
    messages: EXEC_MSGS.map((execMsg) => ({
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      sender: "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n", // gov module or proposer
      contract: execMsg.contractAddress,
      msg: execMsg.msg,
      funds: [],
    })),
    metadata: "Initial configuration of Hyperlane contracts for multi-chain support",
    deposit: "10000000uluna",
    title: "Hyperlane Contracts Configuration - Multi-Chain",
    summary: "Proposal to configure Hyperlane contracts for Ethereum, BSC, and Solana: set ISM validators (Ethereum 6/9, BSC 2/6, Solana 3/5), configure IGP Oracle for all chains, set IGP routes, configure default ISM and hooks (default and required) in Mailbox",
    expedited: false,
  };

  fs.writeFileSync("proposal.json", JSON.stringify(proposal, null, 2));
  console.log("✓ proposal.json file created successfully!");
}

async function submitGovernanceProposal(
  client: SigningCosmWasmClient,
  proposer: string
) {
  console.log("\n" + "=".repeat(80));
  console.log("PREPARING HYPERLANE GOVERNANCE PROPOSAL - MULTI-CHAIN");
  console.log("=".repeat(80) + "\n");

  const proposalTitle = "Hyperlane Contracts Configuration - Multi-Chain";
  const proposalDescription = `
Proposal to configure Hyperlane contracts for multi-chain support:
- Set validators for ISM Multisig:
  * Ethereum (domain 1): 6/9 validators
  * BSC (domain 56): 2/6 validators
  * Solana (domain 1399811149): 3/5 validators
- Configure remote gas data in IGP Oracle for all chains
- Set IGP routes for all chains
- Set default ISM in Mailbox (ISM Routing)
- Set default and required hooks in Mailbox
  `.trim();

  const initialDeposit = [{ denom: "uluna", amount: "10000000" }]; // 10 LUNC

  console.log("📋 PROPOSAL INFORMATION:");
  console.log("─".repeat(80));
  console.log("Title:", proposalTitle);
  console.log("Initial deposit:", JSON.stringify(initialDeposit));
  console.log("\n🌐 SUPPORTED CHAINS:");
  console.log("  • Ethereum (Domain 1) - 6/9 validators");
  console.log("  • BSC (Domain 56) - 2/6 validators");
  console.log("  • Solana (Domain 1399811149) - 3/5 validators");
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
  console.log(`terrad tx gov submit-proposal proposal.json \\
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
  console.log("  ✓ exec_msgs.json      - Individual execution messages");
  console.log("  ✓ proposal.json       - Complete proposal formatted for terrad");
  console.log("\n💡 NEXT STEPS:");
  console.log("─".repeat(80));
  console.log("  1. Review the created JSON files");
  console.log("  2. Execute the terrad command above to submit the proposal");
  console.log("  3. Vote on the proposal: terrad tx gov vote <PROPOSAL_ID> yes ...");
  console.log("  4. Wait for the voting period to end");
  console.log("  5. Verify execution by querying the contracts");
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
    console.error('Example: PRIVATE_KEY="abcdef..." ts-node script/submit-proposal.ts');
    return;
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("Wallet loaded:", sender);
  console.log("Chain ID:", CHAIN_ID);
  console.log("Node:", NODE);

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

