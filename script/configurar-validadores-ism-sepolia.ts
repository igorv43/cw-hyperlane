import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { GasPrice } from "@cosmjs/stargate";

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// GET FROM ENVIRONMENT
// OBRIGATÓRIO: Defina PRIVATE_KEY ou TERRA_PRIVATE_KEY como variável de ambiente
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// ---------------------------
// CONTRACT ADDRESSES (TESTNET)
// ---------------------------
// ISM Multisig Sepolia (owner: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze)
const ISM_MULTISIG_SEPOLIA = process.env.ISM_MULTISIG_SEPOLIA || "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa";

// Domain ID for Sepolia
const DOMAIN_SEPOLIA = 11155111;

// Validators configuration for Sepolia
// NOVO VALIDADOR: 0x133fd7f7094dbd17b576907d052a5acbd48db526
// IMPORTANTE: Remover o prefixo "0x" - o contrato espera apenas hex
const SEPOLIA_VALIDATORS = [
  "133fd7f7094dbd17b576907d052a5acbd48db526",  // Abacus Works Validator (Novo) - sem 0x
];
const SEPOLIA_THRESHOLD = 1; // 1 of 1 validators

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
  console.log(`\n⚙️  Configurando validadores para domain ${domain}...`);
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

  console.log("\n📋 Mensagem de execução:");
  console.log(JSON.stringify(msg, null, 2));
  console.log("");

  try {
    const result = await client.execute(
      sender,
      contractAddress,
      msg,
      "auto"
    );

    console.log("✅ Validadores configurados com sucesso!");
    console.log("  • TX Hash:", result.transactionHash);
    console.log("  • Gas Used:", result.gasUsed);
    console.log("  • Height:", result.height);
    console.log("\n📋 LINK DA TRANSAÇÃO:");
    console.log(`  https://finder.terra-classic.hexxagon.dev/testnet/tx/${result.transactionHash}`);

    return result;
  } catch (error: any) {
    console.error("❌ ERRO ao configurar validadores!");
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
    console.error('Example: PRIVATE_KEY="abcdef..." npx tsx script/configurar-validadores-ism-sepolia.ts');
    return;
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("=".repeat(80));
  console.log("⚙️  CONFIGURAR VALIDADORES ISM MULTISIG SEPOLIA");
  console.log("=".repeat(80));
  console.log("\nWallet:", sender);
  console.log("Chain ID:", CHAIN_ID);
  console.log("Node:", NODE);
  console.log("ISM Multisig Sepolia:", ISM_MULTISIG_SEPOLIA);
  console.log("Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });

  console.log("✓ Connected to node\n");

  // Configure validators
  await configureValidators(
    client,
    sender,
    ISM_MULTISIG_SEPOLIA,
    DOMAIN_SEPOLIA,
    SEPOLIA_THRESHOLD,
    SEPOLIA_VALIDATORS
  );

  console.log("\n" + "=".repeat(80));
  console.log("✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!");
  console.log("=".repeat(80));
  console.log("\n📋 RESUMO:");
  console.log("─".repeat(80));
  console.log("  • Contract Address:", ISM_MULTISIG_SEPOLIA);
  console.log("  • Domain:", DOMAIN_SEPOLIA, "(Sepolia Testnet)");
  console.log("  • Threshold:", SEPOLIA_THRESHOLD, "of", SEPOLIA_VALIDATORS.length);
  console.log("  • Validators:", SEPOLIA_VALIDATORS);
  console.log("=".repeat(80) + "\n");
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
