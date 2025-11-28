import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { GasPrice } from "@cosmjs/stargate";
import { fromBech32 } from "@cosmjs/encoding";

// ==============================
// UTILITY FUNCTIONS
// ==============================
function extractByte32AddrFromBech32(addr: string): string {
  const { data } = fromBech32(addr);
  const hexed = Buffer.from(data).toString("hex");
  const padded = hexed.padStart(64, "0");
  return hexed.length === 64 ? hexed : padded;
}

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const RPC = "https://rpc.luncblaze.com";
const CHAIN_ID = "rebel-2";

const ADMIN = "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n";
const OWNER = ADMIN;

// GET FROM ENVIRONMENT — NEVER HARDCODE
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || "a5123190601045e1266e57c5d5b1a77f0897b39ea63ed2c761946686939c3cb6";

// ==============================
// ADDRESS MAP
// ==============================
const ADDRESSES: Record<string, string> = {};

async function instantiateContract(
  client: SigningCosmWasmClient,
  sender: string,
  name: string,
  codeId: number,
  msg: any
) {
  console.log(`Instantiating ${name} (code_id ${codeId})...`);

  const result = await client.instantiate(
    sender,
    codeId,
    msg,
    `cw-hpl: ${name}`,
    "auto",
    {
      admin: ADMIN,
    }
  );

  const contractAddress = result.contractAddress;
  ADDRESSES[name] = contractAddress;
  var obj = {
    type: name,
    address: contractAddress,
    hexed: extractByte32AddrFromBech32(contractAddress),
  };
  console.log(obj);
  console.log("-------------------------------------");
}

async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error("ERROR: Set the PRIVATE_KEY environment variable.");
    console.error("Execution example:");
    console.error('PRIVATE_KEY="abcdef..." node script.js');
    return;
  }

  // create wallet from private key
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));

  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("Wallet loaded via private key:", sender);

  // Checking required gas rate
  console.log("Connecting to RPC:", RPC);
  
  // Terra Classic Testnet (LUNC) requires higher fees - using 28.5uluna
  const client = await SigningCosmWasmClient.connectWithSigner(RPC, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });
  
  console.log("Gas rate configured: 28.5uluna");

  // ==============================
  // CONTRACT INSTANTIATION - TESTNET
  // ==============================

  console.log("\n" + "=".repeat(80));
  console.log("STARTING HYPERLANE CONTRACTS INSTANTIATION - TESTNET");
  console.log("Network: Terra Classic Testnet (rebel-2)");
  console.log("=".repeat(80) + "\n");

  // --------------------------------------------------
  // 1. MAILBOX - Main Hyperlane Contract
  // --------------------------------------------------
  // The Mailbox is the central contract that manages sending and receiving
  // cross-chain messages. It coordinates ISMs, Hooks and maintains message nonce.
  const mailboxInit = {
    hrp: "terra",          // Human-readable part of Bech32 address (chain prefix)
    domain: 1325,          // Unique chain domain ID in Hyperlane protocol
    owner: OWNER,          // Address that will have admin control of the contract
  };
  console.log("📮 [1/11] MAILBOX - Main cross-chain messaging contract");
  console.log("Instantiation Parameters:", JSON.stringify(mailboxInit, null, 2));
  await instantiateContract(client, sender, "hpl_mailbox", 1981, mailboxInit);

  // --------------------------------------------------
  // 2. VALIDATOR ANNOUNCE - Validator Registry
  // --------------------------------------------------
  // Allows validators to announce their endpoints and locations so
  // relayers can discover how to obtain signatures.
  const validatorAnnounceInit = {
    hrp: "terra",                     // Bech32 chain prefix
    mailbox: ADDRESSES["hpl_mailbox"], // Associated Mailbox address
  };
  console.log("\n📢 [2/11] VALIDATOR ANNOUNCE - Validator registry");
  console.log("Instantiation Parameters:", JSON.stringify(validatorAnnounceInit, null, 2));
  await instantiateContract(client, sender, "hpl_validator_announce", 1982, validatorAnnounceInit);

  // --------------------------------------------------
  // 3. ISM MULTISIG #1 - For BSC (Domain 97)
  // --------------------------------------------------
  // ISM that validates messages using signatures from multiple validators.
  // Requires a minimum threshold of signatures to approve a message.
  const ismMultisigBscInit = {
    owner: OWNER,  // Address that can configure validators and threshold
  };
  console.log("\n🔐 [3/11] ISM MULTISIG #1 - For BSC Testnet (Domain 97)");
  console.log("Instantiation Parameters:", JSON.stringify(ismMultisigBscInit, null, 2));
  console.log("ℹ️  Validators and threshold will be configured later via governance");
  await instantiateContract(client, sender, "hpl_ism_multisig_bsc", 1984, ismMultisigBscInit);

  // --------------------------------------------------
  // 4. ISM MULTISIG #2 - For Solana (Domain 1399811150)
  // --------------------------------------------------
  const ismMultisigSolInit = {
    owner: OWNER,  // Address that can configure validators and threshold
  };
  console.log("\n🔐 [4/11] ISM MULTISIG #2 - For Solana Testnet (Domain 1399811150)");
  console.log("Instantiation Parameters:", JSON.stringify(ismMultisigSolInit, null, 2));
  console.log("ℹ️  Validators and threshold will be configured later via governance");
  await instantiateContract(client, sender, "hpl_ism_multisig_sol", 1984, ismMultisigSolInit);

  // --------------------------------------------------
  // 5. ISM ROUTING - ISM Router for all domains
  // --------------------------------------------------
  // Allows using different ISMs for different domains (chains).
  // Useful for having customized security policies per source chain.
  const ismRoutingInit = {
    owner: OWNER,
    isms: [
      {
        domain: 97,                                 // BSC Testnet
        address: ADDRESSES["hpl_ism_multisig_bsc"], // ISM for BSC messages
      },
      {
        domain: 1399811150,                         // Solana Testnet
        address: ADDRESSES["hpl_ism_multisig_sol"], // ISM for Solana messages
      },
    ],
  };
  console.log("\n🗺️  [5/11] ISM ROUTING - ISM router by domain");
  console.log("Instantiation Parameters:", JSON.stringify(ismRoutingInit, null, 2));
  console.log("ℹ️  Domains: 97 (BSC Testnet), 1399811150 (Solana Testnet)");
  await instantiateContract(client, sender, "hpl_ism_routing", 1986, ismRoutingInit);

  // --------------------------------------------------
  // 6. HOOK MERKLE - Merkle Tree Hook
  // --------------------------------------------------
  // Maintains a Merkle tree of sent messages. This allows efficient
  // inclusion proofs for message validation on the destination chain.
  const hookMerkleInit = {
    mailbox: ADDRESSES["hpl_mailbox"],  // Associated Mailbox
  };
  console.log("\n🌳 [6/11] HOOK MERKLE - Merkle tree for message proofs");
  console.log("Instantiation Parameters:", JSON.stringify(hookMerkleInit, null, 2));
  await instantiateContract(client, sender, "hpl_hook_merkle", 1990, hookMerkleInit);

  // --------------------------------------------------
  // 7. IGP - Interchain Gas Paymaster
  // --------------------------------------------------
  // Manages gas payments for message execution on the destination chain.
  // Users pay gas on the source chain, and relayers are reimbursed on the destination chain.
  const igpInit = {
    hrp: "terra",               // Bech32 prefix
    owner: OWNER,               // Contract admin
    gas_token: "uluna",         // Token used for gas payment (micro-luna)
    beneficiary: OWNER,         // Address that receives accumulated fees
    default_gas_usage: "100000", // Default estimated gas amount for execution
  };
  console.log("\n⛽ [7/11] IGP - Cross-chain gas payment manager");
  console.log("Instantiation Parameters:", JSON.stringify(igpInit, null, 2));
  await instantiateContract(client, sender, "hpl_igp", 1987, igpInit);

  // --------------------------------------------------
  // 8. IGP ORACLE - Gas Price Oracle
  // --------------------------------------------------
  // Provides token exchange rates and gas prices for remote chains.
  // Essential for calculating how much gas to charge at origin to cover destination costs.
  const igpOracleInit = {
    owner: OWNER,  // Address that can update exchange rates and prices
  };
  console.log("\n🔮 [8/11] IGP ORACLE - Gas prices and rates oracle");
  console.log("Instantiation Parameters:", JSON.stringify(igpOracleInit, null, 2));
  console.log("ℹ️  Exchange rates and gas prices will be configured via governance");
  console.log("ℹ️  Domains: 97 (BSC Testnet), 1399811150 (Solana Testnet)");
  await instantiateContract(client, sender, "hpl_igp_oracle", 1998, igpOracleInit);

  // --------------------------------------------------
  // 9. HOOK AGGREGATE #1 - Hook Aggregator (Merkle + IGP)
  // --------------------------------------------------
  // Combines multiple hooks into one. This first aggregator executes:
  // - Hook Merkle: registers message in Merkle tree
  // - IGP: processes gas payment
  const hookAgg1Init = {
    owner: OWNER,
    hooks: [
      ADDRESSES["hpl_hook_merkle"],  // Hook 1: Merkle Tree
      ADDRESSES["hpl_igp"],           // Hook 2: IGP
    ],
  };
  console.log("\n🔗 [9/11] HOOK AGGREGATE #1 - Aggregator (Merkle + IGP)");
  console.log("Instantiation Parameters:", JSON.stringify(hookAgg1Init, null, 2));
  console.log("ℹ️  This hook will be set as 'default_hook' in the Mailbox");
  await instantiateContract(client, sender, "hpl_hook_aggregate", 1988, hookAgg1Init);

  // --------------------------------------------------
  // 10. HOOK PAUSABLE - Pausable Hook
  // --------------------------------------------------
  // Allows pausing message sending in case of emergency.
  // Useful for maintenance or responding to security incidents.
  const hookPausableInit = {
    owner: OWNER,   // Address that can pause/unpause
    paused: false,  // Initial state: not paused
  };
  console.log("\n⏸️  [10/11] HOOK PAUSABLE - Hook with pause capability");
  console.log("Instantiation Parameters:", JSON.stringify(hookPausableInit, null, 2));
  await instantiateContract(client, sender, "hpl_hook_pausable", 1991, hookPausableInit);

  // --------------------------------------------------
  // 11. HOOK FEE - Fee Hook
  // --------------------------------------------------
  // Charges a fixed fee per message sent. Can be used for:
  // - Protocol monetization
  // - Spam prevention
  // - Operations funding
  const hookFeeInit = {
    owner: OWNER,
    fee: {
      denom: "uluna",      // Token denomination (micro-luna)
      amount: "283215",    // Fee amount (0.283215 LUNC)
    },
  };
  console.log("\n💰 [11/11] HOOK FEE - Fixed fee charging hook");
  console.log("Instantiation Parameters:", JSON.stringify(hookFeeInit, null, 2));
  console.log("ℹ️  Fee: 0.283215 LUNC per message");
  await instantiateContract(client, sender, "hpl_hook_fee", 1989, hookFeeInit);

  // --------------------------------------------------
  // 12. HOOK AGGREGATE #2 - Hook Aggregator (Pausable + Fee)
  // --------------------------------------------------
  // Second aggregator that combines:
  // - Hook Pausable: allows pausing message sending
  // - Hook Fee: charges fee per message
  const hookAgg2Init = {
    owner: OWNER,
    hooks: [
      ADDRESSES["hpl_hook_pausable"],  // Hook 1: Pausable
      ADDRESSES["hpl_hook_fee"],       // Hook 2: Fee
    ],
  };
  console.log("\n🔗 [12/11] HOOK AGGREGATE #2 - Aggregator (Pausable + Fee)");
  console.log("Instantiation Parameters:", JSON.stringify(hookAgg2Init, null, 2));
  console.log("ℹ️  This hook will be set as 'required_hook' in the Mailbox");
  await instantiateContract(client, sender, "hpl_hook_aggregate", 1988, hookAgg2Init);

  // --------------------------------------------------
  // MAILBOX CONFIGURATION - Set ISM and Hooks
  // --------------------------------------------------
  // Configure the Mailbox with default ISM, default hook, and required hook
  console.log("\n⚙️  MAILBOX CONFIGURATION - Setting ISM and Hooks");
  console.log("ℹ️  This will be done via governance in production");
  console.log("ℹ️  - Default ISM: ISM Routing (supports BSC Testnet, Solana Testnet)");
  console.log("ℹ️  - Default Hook: Hook Aggregate #1 (Merkle + IGP)");
  console.log("ℹ️  - Required Hook: Hook Aggregate #2 (Pausable + Fee)");

  console.log("\n" + "=".repeat(80));
  console.log("✅ ALL 12 CONTRACTS HAVE BEEN INSTANTIATED SUCCESSFULLY!");
  console.log("=".repeat(80));
  console.log("\n📊 DEPLOYMENT SUMMARY:");
  console.log("  • 1 Mailbox");
  console.log("  • 1 Validator Announce");
  console.log("  • 2 ISM Multisig (BSC Testnet, Solana Testnet)");
  console.log("  • 1 ISM Routing");
  console.log("  • 1 Hook Merkle");
  console.log("  • 1 IGP + 1 IGP Oracle");
  console.log("  • 2 Hook Aggregates");
  console.log("  • 1 Hook Pausable");
  console.log("  • 1 Hook Fee");
  console.log("\n🌐 SUPPORTED CHAINS (TESTNET):");
  console.log("  • BSC Testnet (Domain 97)");
  console.log("  • Solana Testnet (Domain 1399811150)");

  console.log("\n📝 Final addresses:");
  console.log(JSON.stringify(ADDRESSES, null, 2));
}

main().catch((error) => {
  console.error("Error executing:", error);
  process.exit(1);
});

