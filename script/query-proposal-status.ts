import { CosmWasmClient } from "@cosmjs/cosmwasm-stargate";

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// ---------------------------
// CONTRACT ADDRESSES (TESTNET)
// ---------------------------
const MAILBOX = "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf";
const ISM_MULTISIG_BSC = "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv";
const ISM_MULTISIG_SOL = "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a";
const ISM_ROUTING = "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh";
const IGP = "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9";
const IGP_ORACLE = "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg";
const HOOK_MERKLE = "terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df";
const HOOK_AGG_1 = "terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh";
const HOOK_PAUSABLE = "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l";
const HOOK_FEE = "terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j";
const HOOK_AGG_2 = "terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj";

// ==============================
// TYPES
// ==============================
interface ProposalStatus {
  id: string;
  status: string;
  finalTallyResult?: {
    yes: string;
    no: string;
    abstain: string;
    noWithVeto: string;
  };
  submitTime?: string;
  depositEndTime?: string;
  votingStartTime?: string;
  votingEndTime?: string;
  messages?: any[];
}

interface ContractQueryResult {
  contract: string;
  query: string;
  result: any;
  success: boolean;
  error?: string;
}

// ==============================
// FUNCTIONS
// ==============================

/**
 * Queries proposal status using terrad CLI
 */
async function queryProposalStatus(
  proposalId: string
): Promise<ProposalStatus | null> {
  const { execSync } = require("child_process");
  
  try {
    const command = `terrad query gov proposal ${proposalId} --node ${NODE} --chain-id ${CHAIN_ID} --output json`;
    const output = execSync(command, { encoding: "utf-8", stdio: "pipe" });
    const data = JSON.parse(output);

    if (!data) {
      return null;
    }

    // Map terrad format to our format
    return {
      id: proposalId,
      status: data.status || "UNKNOWN",
      finalTallyResult: data.final_tally_result
        ? {
            yes: data.final_tally_result.yes_count || data.final_tally_result.yes || "0",
            no: data.final_tally_result.no_count || data.final_tally_result.no || "0",
            abstain: data.final_tally_result.abstain_count || data.final_tally_result.abstain || "0",
            noWithVeto: data.final_tally_result.no_with_veto_count || data.final_tally_result.no_with_veto || "0",
          }
        : undefined,
      submitTime: data.submit_time,
      depositEndTime: data.deposit_end_time,
      votingStartTime: data.voting_start_time,
      votingEndTime: data.voting_end_time,
      messages: data.messages || [],
    };
  } catch (error: any) {
    console.error(`Error executing terrad: ${error.message}`);
    if (error.stderr) {
      console.error(`Stderr: ${error.stderr.toString()}`);
    }
    return null;
  }
}

/**
 * Checks if a proposal was approved
 */
function isProposalApproved(status: ProposalStatus): boolean {
  // Terra Classic may use different status formats
  const statusUpper = status.status.toUpperCase();
  return (
    statusUpper === "PROPOSAL_STATUS_PASSED" ||
    statusUpper === "PASSED" ||
    statusUpper === "3" // Numeric code for PASSED
  );
}

/**
 * Queries the state of a CosmWasm contract
 */
async function queryContract(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string,
  queryMsg: any
): Promise<any> {
  try {
    return await cosmwasmClient.queryContractSmart(contractAddress, queryMsg);
  } catch (error: any) {
    throw new Error(`Error querying contract ${contractAddress}: ${error.message}`);
  }
}

/**
 * Verifies ISM Multisig configuration for a domain
 */
async function verifyISMValidators(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string,
  domain: number,
  expectedValidators: string[],
  expectedThreshold: number
): Promise<ContractQueryResult> {
  try {
    const result = await queryContract(cosmwasmClient, contractAddress, {
      multisig_ism: { enrolled_validators: { domain } },
    });

    const actualValidators = result.validators || [];
    const actualThreshold = result.threshold || 0;

    const validatorsMatch =
      actualValidators.length === expectedValidators.length &&
      actualValidators.every((v: string) => expectedValidators.includes(v));

    const thresholdMatch = actualThreshold === expectedThreshold;

    return {
      contract: contractAddress,
      query: `validators for domain ${domain}`,
      result: {
        validators: actualValidators,
        threshold: actualThreshold,
        expectedValidators,
        expectedThreshold,
        validatorsMatch,
        thresholdMatch,
        allMatch: validatorsMatch && thresholdMatch,
      },
      success: validatorsMatch && thresholdMatch,
    };
  } catch (error: any) {
    return {
      contract: contractAddress,
      query: `validators for domain ${domain}`,
      result: null,
      success: false,
      error: error.message,
    };
  }
}

/**
 * Verifies IGP Oracle configuration
 */
async function verifyIGPOracle(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string,
  expectedConfigs: Array<{
    remote_domain: number;
    token_exchange_rate: string;
    gas_price: string;
  }>
): Promise<ContractQueryResult> {
  try {
    const results = [];
    let allMatch = true;

    for (const expectedConfig of expectedConfigs) {
      const result = await queryContract(cosmwasmClient, contractAddress, {
        oracle: { get_exchange_rate_and_gas_price: { dest_domain: expectedConfig.remote_domain } },
      });

      const actualExchangeRate = result.exchange_rate || result.token_exchange_rate || "0";
      const actualGasPrice = result.gas_price || "0";

      const exchangeRateMatch = actualExchangeRate === expectedConfig.token_exchange_rate;
      const gasPriceMatch = actualGasPrice === expectedConfig.gas_price;

      if (!exchangeRateMatch || !gasPriceMatch) {
        allMatch = false;
      }

      results.push({
        domain: expectedConfig.remote_domain,
        expected: expectedConfig,
        actual: {
          token_exchange_rate: actualExchangeRate,
          gas_price: actualGasPrice,
        },
        match: exchangeRateMatch && gasPriceMatch,
      });
    }

    return {
      contract: contractAddress,
      query: "remote_gas_data configs",
      result: {
        configs: results,
        allMatch,
      },
      success: allMatch,
    };
  } catch (error: any) {
    return {
      contract: contractAddress,
      query: "remote_gas_data configs",
      result: null,
      success: false,
      error: error.message,
    };
  }
}

/**
 * Verifies IGP routes
 */
async function verifyIGPRoutes(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string,
  expectedRoutes: Array<{ domain: number; route: string }>
): Promise<ContractQueryResult> {
  try {
    const results = [];
    let allMatch = true;

    for (const expectedRoute of expectedRoutes) {
      const result = await queryContract(cosmwasmClient, contractAddress, {
        router: { get_route: { domain: expectedRoute.domain } },
      });

      // A resposta vem como RouteResponse { route: DomainRouteSet { domain, route } }
      const actualRoute = result.route?.route || result.route || "";

      if (actualRoute !== expectedRoute.route) {
        allMatch = false;
      }

      results.push({
        domain: expectedRoute.domain,
        expected: expectedRoute.route,
        actual: actualRoute,
        match: actualRoute === expectedRoute.route,
      });
    }

    return {
      contract: contractAddress,
      query: "IGP routes",
      result: {
        routes: results,
        allMatch,
      },
      success: allMatch,
    };
  } catch (error: any) {
    return {
      contract: contractAddress,
      query: "IGP routes",
      result: null,
      success: false,
      error: error.message,
    };
  }
}

/**
 * Verifies Mailbox configuration
 */
async function verifyMailboxConfig(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string,
  expectedDefaultISM?: string,
  expectedDefaultHook?: string,
  expectedRequiredHook?: string
): Promise<ContractQueryResult[]> {
  const results: ContractQueryResult[] = [];

  // Verify Default ISM
  if (expectedDefaultISM) {
    try {
      const result = await queryContract(cosmwasmClient, contractAddress, {
        mailbox: { default_ism: {} },
      });
      const actualISM = result.default_ism || "";
      results.push({
        contract: contractAddress,
        query: "default_ism",
        result: {
          expected: expectedDefaultISM,
          actual: actualISM,
          match: actualISM === expectedDefaultISM,
        },
        success: actualISM === expectedDefaultISM,
      });
    } catch (error: any) {
      results.push({
        contract: contractAddress,
        query: "default_ism",
        result: null,
        success: false,
        error: error.message,
      });
    }
  }

  // Verify Default Hook
  if (expectedDefaultHook) {
    try {
      const result = await queryContract(cosmwasmClient, contractAddress, {
        mailbox: { default_hook: {} },
      });
      const actualHook = result.default_hook || "";
      results.push({
        contract: contractAddress,
        query: "default_hook",
        result: {
          expected: expectedDefaultHook,
          actual: actualHook,
          match: actualHook === expectedDefaultHook,
        },
        success: actualHook === expectedDefaultHook,
      });
    } catch (error: any) {
      results.push({
        contract: contractAddress,
        query: "default_hook",
        result: null,
        success: false,
        error: error.message,
      });
    }
  }

  // Verify Required Hook
  if (expectedRequiredHook) {
    try {
      const result = await queryContract(cosmwasmClient, contractAddress, {
        mailbox: { required_hook: {} },
      });
      const actualHook = result.required_hook || "";
      results.push({
        contract: contractAddress,
        query: "required_hook",
        result: {
          expected: expectedRequiredHook,
          actual: actualHook,
          match: actualHook === expectedRequiredHook,
        },
        success: actualHook === expectedRequiredHook,
      });
    } catch (error: any) {
      results.push({
        contract: contractAddress,
        query: "required_hook",
        result: null,
        success: false,
        error: error.message,
      });
    }
  }

  return results;
}

/**
 * Verifica a configuração do Hook Fee
 */
async function verifyHookFee(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string,
  expectedFee?: { denom: string; amount: string }
): Promise<ContractQueryResult> {
  try {
    const result = await queryContract(cosmwasmClient, contractAddress, {
      fee_hook: { fee: {} },
    });

    const actualFee = result.fee || { denom: "", amount: "0" };

    const feeMatch =
      expectedFee &&
      actualFee.denom === expectedFee.denom &&
      actualFee.amount === expectedFee.amount;

    return {
      contract: contractAddress,
      query: "fee",
      result: {
        expected: expectedFee,
        actual: actualFee,
        match: feeMatch,
      },
      success: feeMatch || false,
    };
  } catch (error: any) {
    return {
      contract: contractAddress,
      query: "fee",
      result: null,
      success: false,
      error: error.message,
    };
  }
}

/**
 * Verifies Hook Pausable status
 */
async function verifyHookPausable(
  cosmwasmClient: CosmWasmClient,
  contractAddress: string
): Promise<ContractQueryResult> {
  try {
    const result = await queryContract(cosmwasmClient, contractAddress, {
      pausable: { pause_info: {} },
    });

    const paused = result.paused || false;

    return {
      contract: contractAddress,
      query: "paused",
      result: {
        paused: paused,
      },
      success: true,
    };
  } catch (error: any) {
    return {
      contract: contractAddress,
      query: "paused",
      result: null,
      success: false,
      error: error.message,
    };
  }
}

/**
 * Main function to verify a proposal and its contracts
 */
async function verifyProposalAndContracts(proposalId: string) {
  console.log("\n" + "=".repeat(80));
  console.log("PROPOSAL AND CONTRACT EXECUTION VERIFICATION");
  console.log("=".repeat(80));
  console.log(`Proposal ID: ${proposalId}`);
  console.log(`Chain ID: ${CHAIN_ID}`);
  console.log(`Node: ${NODE}\n`);

  // Connect to CosmWasm client
  const cosmwasmClient = await CosmWasmClient.connect(NODE);

  // 1. Query proposal status
  console.log("📋 QUERYING PROPOSAL STATUS...");
  console.log("─".repeat(80));
  console.log("Using terrad CLI to query the proposal...\n");
  const proposalStatus = await queryProposalStatus(proposalId);

  if (!proposalStatus) {
    console.error(`❌ Proposal ${proposalId} not found!`);
    return;
  }

  console.log(`Status: ${proposalStatus.status}`);
  if (proposalStatus.finalTallyResult) {
    console.log(`Yes Votes: ${proposalStatus.finalTallyResult.yes}`);
    console.log(`No Votes: ${proposalStatus.finalTallyResult.no}`);
    console.log(`Abstentions: ${proposalStatus.finalTallyResult.abstain}`);
    console.log(`Veto: ${proposalStatus.finalTallyResult.noWithVeto}`);
  }
  if (proposalStatus.votingEndTime) {
    console.log(`Voting End: ${proposalStatus.votingEndTime}`);
  }

  const approved = isProposalApproved(proposalStatus);
  console.log(`\n${approved ? "✅ PROPOSAL APPROVED" : "❌ PROPOSAL NOT APPROVED"}`);

  if (!approved) {
    console.log("\n⚠️  The proposal was not approved. Cannot verify contract execution.");
    return;
  }

  // 2. Verify contract execution
  console.log("\n" + "=".repeat(80));
  console.log("🔍 VERIFYING CONTRACT EXECUTION...");
  console.log("=".repeat(80));

  // Verify ISM Multisig BSC (Domain 97)
  console.log("\n[1/7] Verifying ISM Multisig BSC (Domain 97)...");
  const ismBSCResult = await verifyISMValidators(
    cosmwasmClient,
    ISM_MULTISIG_BSC,
    97,
    [
      "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
      "f620f5e3d25a3ae848fec74bccae5de3edcd8796",
      "1f030345963c54ff8229720dd3a711c15c554aeb",
    ],
    2
  );
  console.log(ismBSCResult.success ? "✅ Configuration correct" : "❌ Configuration incorrect");
  if (ismBSCResult.error) {
    console.log(`   Error: ${ismBSCResult.error}`);
  } else if (ismBSCResult.result) {
    console.log(`   Validators: ${ismBSCResult.result.validators.length}`);
    console.log(`   Threshold: ${ismBSCResult.result.threshold}`);
    console.log(`   Match: ${ismBSCResult.result.allMatch ? "✅" : "❌"}`);
  }

  // Verify ISM Multisig Solana (Domain 1399811150)
  console.log("\n[2/7] Verifying ISM Multisig Solana (Domain 1399811150)...");
  const ismSOLResult = await verifyISMValidators(
    cosmwasmClient,
    ISM_MULTISIG_SOL,
    1399811150,
    ["d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"],
    1
  );
  console.log(ismSOLResult.success ? "✅ Configuration correct" : "❌ Configuration incorrect");
  if (ismSOLResult.error) {
    console.log(`   Error: ${ismSOLResult.error}`);
  } else if (ismSOLResult.result) {
    console.log(`   Validators: ${ismSOLResult.result.validators.length}`);
    console.log(`   Threshold: ${ismSOLResult.result.threshold}`);
    console.log(`   Match: ${ismSOLResult.result.allMatch ? "✅" : "❌"}`);
  }

  // Verify IGP Oracle
  console.log("\n[3/7] Verifying IGP Oracle...");
  const igpOracleResult = await verifyIGPOracle(cosmwasmClient, IGP_ORACLE, [
    {
      remote_domain: 97,
      token_exchange_rate: "1805936462255558",
      gas_price: "50000000",
    },
    {
      remote_domain: 1399811150,
      token_exchange_rate: "57675000000000000",
      gas_price: "1",
    },
  ]);
  console.log(igpOracleResult.success ? "✅ Configuration correct" : "❌ Configuration incorrect");
  if (igpOracleResult.error) {
    console.log(`   Error: ${igpOracleResult.error}`);
  } else if (igpOracleResult.result) {
    console.log(`   Configs verified: ${igpOracleResult.result.configs.length}`);
    console.log(`   All correct: ${igpOracleResult.result.allMatch ? "✅" : "❌"}`);
  }

  // Verify IGP Routes
  console.log("\n[4/7] Verifying IGP Routes...");
  const igpRoutesResult = await verifyIGPRoutes(cosmwasmClient, IGP, [
    { domain: 97, route: IGP_ORACLE },
    { domain: 1399811150, route: IGP_ORACLE },
  ]);
  console.log(igpRoutesResult.success ? "✅ Configuration correct" : "❌ Configuration incorrect");
  if (igpRoutesResult.error) {
    console.log(`   Error: ${igpRoutesResult.error}`);
  } else if (igpRoutesResult.result) {
    console.log(`   Routes verified: ${igpRoutesResult.result.routes.length}`);
    console.log(`   All correct: ${igpRoutesResult.result.allMatch ? "✅" : "❌"}`);
  }

  // Verify Mailbox Config
  console.log("\n[5/7] Verifying Mailbox Configuration...");
  const mailboxResults = await verifyMailboxConfig(
    cosmwasmClient,
    MAILBOX,
    ISM_ROUTING,
    HOOK_AGG_1,
    HOOK_AGG_2
  );
  mailboxResults.forEach((result) => {
    console.log(
      `   ${result.query}: ${result.success ? "✅" : "❌"} ${
        result.error ? `(${result.error})` : ""
      }`
    );
    if (result.result && !result.error) {
      console.log(`      Expected: ${result.result.expected}`);
      console.log(`      Actual: ${result.result.actual}`);
    }
  });

  // Verify Hook Fee
  console.log("\n[6/7] Verifying Hook Fee...");
  const hookFeeResult = await verifyHookFee(cosmwasmClient, HOOK_FEE, {
    denom: "uluna",
    amount: "283215",
  });
  console.log(hookFeeResult.success ? "✅ Configuration correct" : "❌ Configuration incorrect");
  if (hookFeeResult.error) {
    console.log(`   Error: ${hookFeeResult.error}`);
  } else if (hookFeeResult.result) {
    console.log(
      `   Fee: ${hookFeeResult.result.actual.amount} ${hookFeeResult.result.actual.denom}`
    );
    console.log(`   Match: ${hookFeeResult.result.match ? "✅" : "❌"}`);
  }

  // Verify Hook Pausable
  console.log("\n[7/7] Verifying Hook Pausable...");
  const hookPausableResult = await verifyHookPausable(cosmwasmClient, HOOK_PAUSABLE);
  console.log(hookPausableResult.success ? "✅ Status queried" : "❌ Query error");
  if (hookPausableResult.error) {
    console.log(`   Error: ${hookPausableResult.error}`);
  } else if (hookPausableResult.result) {
    console.log(`   Paused: ${hookPausableResult.result.paused ? "Yes ⚠️" : "No ✅"}`);
  }

  // Final summary
  console.log("\n" + "=".repeat(80));
  console.log("📊 VERIFICATION SUMMARY");
  console.log("=".repeat(80));
  console.log(`Proposal: ${proposalId}`);
  console.log(`Status: ${proposalStatus.status}`);
  console.log(`Approved: ${approved ? "Yes ✅" : "No ❌"}`);

  if (approved) {
    const allResults = [
      ismBSCResult,
      ismSOLResult,
      igpOracleResult,
      igpRoutesResult,
      ...mailboxResults,
      hookFeeResult,
      hookPausableResult,
    ];
    const successCount = allResults.filter((r) => r.success).length;
    const totalCount = allResults.length;

    console.log(`\nContracts verified: ${successCount}/${totalCount}`);
    if (successCount === totalCount) {
      console.log("✅ ALL CONTRACTS WERE EXECUTED CORRECTLY!");
    } else {
      console.log("⚠️  SOME CONTRACTS MAY NOT HAVE BEEN EXECUTED CORRECTLY");
    }
  }

  console.log("=".repeat(80) + "\n");
}

// ==============================
// MAIN
// ==============================
async function main() {
  const proposalId = process.argv[2];

  if (!proposalId) {
    console.error("❌ Error: Provide proposal ID as argument");
    console.error("Usage: npx tsx script/query-proposal-status.ts <PROPOSAL_ID>");
    console.error("Example: npx tsx script/query-proposal-status.ts 1");
    process.exit(1);
  }

  try {
    await verifyProposalAndContracts(proposalId);
  } catch (error: any) {
    console.error("\n❌ Error verifying proposal:", error.message);
    console.error(error);
    process.exit(1);
  }
}

main();

