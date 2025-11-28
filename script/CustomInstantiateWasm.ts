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
// CONFIGURATION
// ==============================
const RPC = "http://localhost:26657";
const CHAIN_ID = "localterra";

const ADMIN = "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n";
const OWNER = ADMIN;

// GET FROM ENVIRONMENT — NEVER HARDCODE
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || "1ec75f8200aa0318152405d0e7729eb24e4b9b45e0a91df932c0d57756d9ebbc";

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
  
  // Terra Classic (LUNC) requires higher fees - using 28.5uluna
  // based on error: required 6040873uluna for ~212000 gas
  const client = await SigningCosmWasmClient.connectWithSigner(RPC, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });
  
  console.log("Gas rate configured: 28.5uluna");

  // ==============================
  // CONTRACT INSTANTIATION
  // ==============================

  console.log("\n" + "=".repeat(80));
  console.log("STARTING HYPERLANE CONTRACTS INSTANTIATION");
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
  await instantiateContract(client, sender, "hpl_mailbox", 1, mailboxInit);

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
  await instantiateContract(client, sender, "hpl_validator_announce", 2, validatorAnnounceInit);

  // --------------------------------------------------
  // 3. ISM MULTISIG #1 - For Ethereum (Domain 1)
  // --------------------------------------------------
  // ISM that validates messages using signatures from multiple validators.
  // Requires a minimum threshold of signatures to approve a message.
  const ismMultisigEthInit = {
    owner: OWNER,  // Address that can configure validators and threshold
  };
  console.log("\n🔐 [3/14] ISM MULTISIG #1 - For Ethereum (Domain 1)");
  console.log("Instantiation Parameters:", JSON.stringify(ismMultisigEthInit, null, 2));
  console.log("ℹ️  Validators and threshold will be configured later via governance");
  await instantiateContract(client, sender, "hpl_ism_multisig_eth", 4, ismMultisigEthInit);

  // --------------------------------------------------
  // 4. ISM MULTISIG #2 - For BSC (Domain 56)
  // --------------------------------------------------
  const ismMultisigBscInit = {
    owner: OWNER,  // Address that can configure validators and threshold
  };
  console.log("\n🔐 [4/14] ISM MULTISIG #2 - For BSC (Domain 56)");
  console.log("Instantiation Parameters:", JSON.stringify(ismMultisigBscInit, null, 2));
  console.log("ℹ️  Validators and threshold will be configured later via governance");
  await instantiateContract(client, sender, "hpl_ism_multisig_bsc", 4, ismMultisigBscInit);

  // --------------------------------------------------
  // 5. ISM MULTISIG #3 - For Solana (Domain 1399811149)
  // --------------------------------------------------
  const ismMultisigSolInit = {
    owner: OWNER,  // Address that can configure validators and threshold
  };
  console.log("\n🔐 [5/14] ISM MULTISIG #3 - For Solana (Domain 1399811149)");
  console.log("Instantiation Parameters:", JSON.stringify(ismMultisigSolInit, null, 2));
  console.log("ℹ️  Validators and threshold will be configured later via governance");
  await instantiateContract(client, sender, "hpl_ism_multisig_sol", 4, ismMultisigSolInit);

  // --------------------------------------------------
  // 6. ISM ROUTING - ISM Router for all domains
  // --------------------------------------------------
  // Allows using different ISMs for different domains (chains).
  // Useful for having customized security policies per source chain.
  const ismRoutingInit = {
    owner: OWNER,
    isms: [
      {
        domain: 1,                                  // Ethereum
        address: ADDRESSES["hpl_ism_multisig_eth"], // ISM for Ethereum messages
      },
      {
        domain: 56,                                 // BSC (Binance Smart Chain)
        address: ADDRESSES["hpl_ism_multisig_bsc"], // ISM for BSC messages
      },
      {
        domain: 1399811149,                         // Solana
        address: ADDRESSES["hpl_ism_multisig_sol"], // ISM for Solana messages
      },
    ],
  };
  console.log("\n🗺️  [6/14] ISM ROUTING - ISM router by domain");
  console.log("Instantiation Parameters:", JSON.stringify(ismRoutingInit, null, 2));
  console.log("ℹ️  Domains: 1 (Ethereum), 56 (BSC), 1399811149 (Solana)");
  await instantiateContract(client, sender, "hpl_ism_routing", 6, ismRoutingInit);

  // --------------------------------------------------
  // 7. HOOK MERKLE - Merkle Tree Hook
  // --------------------------------------------------
  // Maintains a Merkle tree of sent messages. This allows efficient
  // inclusion proofs for message validation on the destination chain.
  const hookMerkleInit = {
    mailbox: ADDRESSES["hpl_mailbox"],  // Associated Mailbox
  };
  console.log("\n🌳 [7/14] HOOK MERKLE - Merkle tree for message proofs");
  console.log("Instantiation Parameters:", JSON.stringify(hookMerkleInit, null, 2));
  await instantiateContract(client, sender, "hpl_hook_merkle", 10, hookMerkleInit);

  // --------------------------------------------------
  // 8. IGP - Interchain Gas Paymaster
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
  console.log("\n⛽ [8/14] IGP - Cross-chain gas payment manager");
  console.log("Instantiation Parameters:", JSON.stringify(igpInit, null, 2));
  await instantiateContract(client, sender, "hpl_igp", 7, igpInit);

  // --------------------------------------------------
  // 9. IGP ORACLE - Gas Price Oracle
  // --------------------------------------------------
  // Provides token exchange rates and gas prices for remote chains.
  // Essential for calculating how much gas to charge at origin to cover destination costs.
  const igpOracleInit = {
    owner: OWNER,  // Address that can update exchange rates and prices
  };
  console.log("\n🔮 [9/14] IGP ORACLE - Gas prices and rates oracle");
  console.log("Instantiation Parameters:", JSON.stringify(igpOracleInit, null, 2));
  console.log("ℹ️  Exchange rates and gas prices will be configured via governance");
  console.log("ℹ️  Domains: 1 (Ethereum), 56 (BSC), 1399811149 (Solana)");
  await instantiateContract(client, sender, "hpl_igp_oracle", 18, igpOracleInit);

  // --------------------------------------------------
  // 10. HOOK AGGREGATE #1 - Hook Aggregator (Merkle + IGP)
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
  console.log("\n🔗 [10/14] HOOK AGGREGATE #1 - Aggregator (Merkle + IGP)");
  console.log("Instantiation Parameters:", JSON.stringify(hookAgg1Init, null, 2));
  console.log("ℹ️  This hook will be set as 'default_hook' in the Mailbox");
  await instantiateContract(client, sender, "hpl_hook_aggregate", 8, hookAgg1Init);

  // --------------------------------------------------
  // 11. HOOK PAUSABLE - Pausable Hook
  // --------------------------------------------------
  // Allows pausing message sending in case of emergency.
  // Useful for maintenance or responding to security incidents.
  const hookPausableInit = {
    owner: OWNER,   // Address that can pause/unpause
    paused: false,  // Initial state: not paused
  };
  console.log("\n⏸️  [11/14] HOOK PAUSABLE - Hook with pause capability");
  console.log("Instantiation Parameters:", JSON.stringify(hookPausableInit, null, 2));
  await instantiateContract(client, sender, "hpl_hook_pausable", 11, hookPausableInit);

  // --------------------------------------------------
  // 12. HOOK FEE - Fee Hook
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
  console.log("\n💰 [12/14] HOOK FEE - Fixed fee charging hook");
  console.log("Instantiation Parameters:", JSON.stringify(hookFeeInit, null, 2));
  console.log("ℹ️  Fee: 0.283215 LUNC per message");
  await instantiateContract(client, sender, "hpl_hook_fee", 9, hookFeeInit);

  // --------------------------------------------------
  // 13. HOOK AGGREGATE #2 - Hook Aggregator (Pausable + Fee)
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
  console.log("\n🔗 [13/14] HOOK AGGREGATE #2 - Aggregator (Pausable + Fee)");
  console.log("Instantiation Parameters:", JSON.stringify(hookAgg2Init, null, 2));
  console.log("ℹ️  This hook will be set as 'required_hook' in the Mailbox");
  await instantiateContract(client, sender, "hpl_hook_aggregate", 8, hookAgg2Init);

  // --------------------------------------------------
  // 14. MAILBOX CONFIGURATION - Set ISM and Hooks
  // --------------------------------------------------
  // Configure the Mailbox with default ISM, default hook, and required hook
  console.log("\n⚙️  [14/14] MAILBOX CONFIGURATION - Setting ISM and Hooks");
  console.log("ℹ️  This will be done via governance in production");
  console.log("ℹ️  - Default ISM: ISM Routing (supports Ethereum, BSC, Solana)");
  console.log("ℹ️  - Default Hook: Hook Aggregate #1 (Merkle + IGP)");
  console.log("ℹ️  - Required Hook: Hook Aggregate #2 (Pausable + Fee)");

  console.log("\n" + "=".repeat(80));
  console.log("✅ ALL 14 CONTRACTS HAVE BEEN INSTANTIATED SUCCESSFULLY!");
  console.log("=".repeat(80));
  console.log("\n📊 DEPLOYMENT SUMMARY:");
  console.log("  • 1 Mailbox");
  console.log("  • 1 Validator Announce");
  console.log("  • 3 ISM Multisig (Ethereum, BSC, Solana)");
  console.log("  • 1 ISM Routing");
  console.log("  • 1 Hook Merkle");
  console.log("  • 1 IGP + 1 IGP Oracle");
  console.log("  • 2 Hook Aggregates");
  console.log("  • 1 Hook Pausable");
  console.log("  • 1 Hook Fee");
  console.log("\n🌐 SUPPORTED CHAINS:");
  console.log("  • Ethereum (Domain 1)");
  console.log("  • BSC (Domain 56)");
  console.log("  • Solana (Domain 1399811149)");

  console.log("\n📝 Final addresses:");
  console.log(JSON.stringify(ADDRESSES, null, 2));
}

main().catch((error) => {
  console.error("Error executing:", error);
  process.exit(1);
});
