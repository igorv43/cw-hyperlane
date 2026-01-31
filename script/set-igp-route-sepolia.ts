import { DirectSecp256k1Wallet } from '@cosmjs/proto-signing';
import { SigningCosmWasmClient } from '@cosmjs/cosmwasm-stargate';
import { GasPrice } from '@cosmjs/stargate';

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = 'rebel-2';
const NODE = 'https://rpc.luncblaze.com:443';

// GET FROM ENVIRONMENT
// IMPORTANTE: A chave privada deve corresponder à conta que tem permissão para configurar o IGP Router
// OBRIGATÓRIO: Defina PRIVATE_KEY ou TERRA_PRIVATE_KEY como variável de ambiente
const PRIVATE_KEY_HEX =
  process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// IGP Router contract address (owner: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze)
const IGP = 'terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r';

// IGP Oracle contract address
const IGP_ORACLE =
  'terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds';

// Domain ID for Sepolia
const DOMAIN_SEPOLIA = 11155111;

// ==============================
// SET IGP ROUTE
// ==============================
async function setIgpRoute(
  client: SigningCosmWasmClient,
  sender: string,
  igpAddress: string,
  domain: number,
  oracleAddress: string,
) {
  console.log(`\n⚙️  Configurando rota IGP Router para domain ${domain}...`);
  console.log('  • IGP Router:', igpAddress);
  console.log('  • IGP Oracle:', oracleAddress);
  console.log('  • Domain:', domain, '(Sepolia Testnet)');

  const msg = {
    router: {
      set_routes: {
        set: [
          {
            domain: domain,
            route: oracleAddress,
          },
        ],
      },
    },
  };

  try {
    const result = await client.execute(
      sender,
      igpAddress,
      msg,
      'auto',
      'Setting IGP Router route for Sepolia',
    );

    console.log('✅ Rota IGP configurada com sucesso!');
    console.log('  • TX Hash:', result.transactionHash);
    console.log('  • Gas Used:', result.gasUsed.toString());
    console.log('  • Height:', result.height);

    return result;
  } catch (error: unknown) {
    console.error('❌ ERROR ao configurar rota IGP!');
    const err = error as { message?: string; logs?: unknown };
    console.error('  • Message:', err.message || String(error));
    if (err.logs) {
      console.error('  • Log:', JSON.stringify(err.logs, null, 2));
    }
    throw error;
  }
}

// ==============================
// MAIN
// ==============================
async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error(
      'ERROR: Set the PRIVATE_KEY or TERRA_PRIVATE_KEY environment variable.',
    );
    console.error(
      'Example: PRIVATE_KEY="abcdef..." npx tsx script/set-igp-route-sepolia.ts',
    );
    process.exit(1);
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, 'hex'));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, 'terra');
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log('='.repeat(80));
  console.log('SET IGP ROUTE FOR SEPOLIA TESTNET');
  console.log('='.repeat(80));
  console.log('\nWallet:', sender);
  console.log('Chain ID:', CHAIN_ID);
  console.log('Node:', NODE);
  console.log('IGP Router:', IGP);
  console.log('IGP Oracle:', IGP_ORACLE);
  console.log('Domain:', DOMAIN_SEPOLIA, '(Sepolia Testnet)');

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString('28.5uluna'),
  });

  console.log('✓ Connected to node\n');

  // Set IGP Route
  await setIgpRoute(client, sender, IGP, DOMAIN_SEPOLIA, IGP_ORACLE);

  console.log('\n' + '='.repeat(80));
  console.log('✅ IGP ROUTE CONFIGURED SUCCESSFULLY!');
  console.log('='.repeat(80));
  console.log('\n📋 CONFIGURATION:');
  console.log('─'.repeat(80));
  console.log('  • Domain:', DOMAIN_SEPOLIA, '(Sepolia Testnet)');
  console.log('  • IGP Router:', IGP);
  console.log('  • IGP Oracle:', IGP_ORACLE);
  console.log('\n📋 VERIFICATION:');
  console.log('─'.repeat(80));
  console.log(
    `  terrad query wasm contract-state smart ${IGP} '{"router":{"get_route":{"domain":${DOMAIN_SEPOLIA}}}}' --chain-id ${CHAIN_ID} --node ${NODE}`,
  );
  console.log('='.repeat(80) + '\n');
}

main().catch((error) => {
  console.error('\nError executing:', error);
  process.exit(1);
});
