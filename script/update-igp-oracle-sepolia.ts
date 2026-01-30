import { DirectSecp256k1Wallet } from '@cosmjs/proto-signing';
import { SigningCosmWasmClient } from '@cosmjs/cosmwasm-stargate';
import { GasPrice } from '@cosmjs/stargate';

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = 'rebel-2';
const NODE = 'https://rpc.luncblaze.com:443';

// GET FROM ENVIRONMENT
// IMPORTANTE: A chave privada deve corresponder à conta que é OWNER do IGP Oracle
// Por padrão, o owner é o módulo de governança: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
// Se você transferiu o ownership para outra conta, use a chave privada dessa conta
const PRIVATE_KEY_HEX =
  process.env.PRIVATE_KEY ||
  'a5123190601045e1266e57c5d5b1a77f0897b39ea63ed2c761946686939c3cb6';

// IGP Oracle contract address
const IGP_ORACLE = 'terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds';

// Domain ID for Sepolia
const DOMAIN_SEPOLIA = 11155111;

// Gas data configuration for Sepolia
// Taxa de Câmbio: 177534
// Gas Price: 1000000000 (1 Gwei)
const TOKEN_EXCHANGE_RATE = '177534';
const GAS_PRICE = '1000000000';

// ==============================
// UPDATE IGP ORACLE
// ==============================
async function updateIgpOracle(
  client: SigningCosmWasmClient,
  sender: string,
  contractAddress: string,
  domain: number,
  exchangeRate: string,
  gasPrice: string
) {
  console.log(`\n⚙️  Updating IGP Oracle for domain ${domain}...`);
  console.log('  • Exchange Rate:', exchangeRate);
  console.log('  • Gas Price:', gasPrice);

  const msg = {
    set_remote_gas_data_configs: {
      configs: [
        {
          remote_domain: domain,
          token_exchange_rate: exchangeRate,
          gas_price: gasPrice,
        },
      ],
    },
  };

  try {
    const result = await client.execute(
      sender,
      contractAddress,
      msg,
      'auto',
      'Updating IGP Oracle gas data for Sepolia'
    );

    console.log('✅ IGP Oracle updated successfully!');
    console.log('  • TX Hash:', result.transactionHash);
    console.log('  • Gas Used:', result.gasUsed.toString());
    console.log('  • Height:', result.height);

    return result;
  } catch (error: any) {
    console.error('❌ ERROR updating IGP Oracle!');
    console.error('  • Message:', error.message);
    if (error.logs) {
      console.error('  • Log:', JSON.stringify(error.logs, null, 2));
    }
    throw error;
  }
}

// ==============================
// MAIN
// ==============================
async function main() {
  if (!PRIVATE_KEY_HEX) {
    console.error('ERROR: Set the PRIVATE_KEY environment variable.');
    console.error(
      'Example: PRIVATE_KEY="abcdef..." npx tsx script/update-igp-oracle-sepolia.ts'
    );
    process.exit(1);
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, 'hex'));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, 'terra');
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log('='.repeat(80));
  console.log('UPDATE IGP ORACLE FOR SEPOLIA TESTNET');
  console.log('='.repeat(80));
  console.log('\nWallet:', sender);
  console.log('Chain ID:', CHAIN_ID);
  console.log('Node:', NODE);
  console.log('IGP Oracle:', IGP_ORACLE);
  console.log('Domain:', DOMAIN_SEPOLIA, '(Sepolia Testnet)');
  console.log('\n⚠️  IMPORTANTE: Esta wallet deve ser o OWNER do IGP Oracle.');
  console.log('   Se você receber erro "unauthorized", verifique se a conta é o owner.');
  console.log('   Owner padrão: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (governance)');

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString('28.5uluna'),
  });

  console.log('✓ Connected to node\n');

  // Update IGP Oracle
  await updateIgpOracle(
    client,
    sender,
    IGP_ORACLE,
    DOMAIN_SEPOLIA,
    TOKEN_EXCHANGE_RATE,
    GAS_PRICE
  );

  console.log('\n' + '='.repeat(80));
  console.log('✅ IGP ORACLE UPDATED SUCCESSFULLY!');
  console.log('='.repeat(80));
  console.log('\n📋 CONFIGURATION:');
  console.log('─'.repeat(80));
  console.log('  • Domain:', DOMAIN_SEPOLIA, '(Sepolia Testnet)');
  console.log('  • Exchange Rate:', TOKEN_EXCHANGE_RATE);
  console.log('  • Gas Price:', GAS_PRICE, '(1 Gwei)');
  console.log('\n📋 VERIFICATION:');
  console.log('─'.repeat(80));
  console.log(
    `  terrad query wasm contract-state smart ${IGP_ORACLE} '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":${DOMAIN_SEPOLIA}}}}' --chain-id ${CHAIN_ID} --node ${NODE}`
  );
  console.log('='.repeat(80) + '\n');
}

main().catch((error) => {
  console.error('\nError executing:', error);
  process.exit(1);
});
