import { DirectSecp256k1Wallet } from '@cosmjs/proto-signing';
import { SigningCosmWasmClient } from '@cosmjs/cosmwasm-stargate';
import { GasPrice } from '@cosmjs/stargate';

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = 'rebel-2';
const NODE = 'https://rpc.luncblaze.com:443';

// GET FROM ENVIRONMENT
// Support both PRIVATE_KEY and TERRA_PRIVATE_KEY for compatibility
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY;
const TERRA_WARP = process.env.TERRA_WARP;
const SEPOLIA_DOMAIN = process.env.SEPOLIA_DOMAIN || '11155111';
const SEPOLIA_WARP_HEX = process.env.SEPOLIA_WARP_HEX;

if (!PRIVATE_KEY_HEX) {
  console.error('ERROR: Set the PRIVATE_KEY or TERRA_PRIVATE_KEY environment variable.');
  process.exit(1);
}

if (!TERRA_WARP) {
  console.error('ERROR: Set the TERRA_WARP environment variable.');
  process.exit(1);
}

if (!SEPOLIA_WARP_HEX) {
  console.error('ERROR: Set the SEPOLIA_WARP_HEX environment variable.');
  process.exit(1);
}

// ==============================
// ENROLL REMOTE ROUTER
// ==============================
async function enrollRemoteRouter(
  client: SigningCosmWasmClient,
  sender: string,
  contractAddress: string,
  domain: number,
  router: string
) {
  console.log(`\n🔗 Enrolling remote router...`);
  console.log('  • Domain:', domain);
  console.log('  • Router (hex):', router);
  
  // Remove 0x prefix if present - contract expects hex without prefix
  const routerHex = router.startsWith('0x') ? router.slice(2) : router;

  const msg = {
    router: {
      set_route: {
        set: {
          domain: domain,
          route: routerHex,
        },
      },
    },
  };

  try {
    const result = await client.execute(
      sender,
      contractAddress,
      msg,
      'auto',
      'Enrolling remote router for Sepolia'
    );

    console.log('✅ Remote router enrolled successfully!');
    console.log('TX Hash:', result.transactionHash);
    console.log('  • Gas Used:', result.gasUsed.toString());
    console.log('  • Height:', result.height);

    return result.transactionHash;
  } catch (error: any) {
    console.error('❌ ERROR enrolling remote router!');
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
  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, 'hex'));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, 'terra');
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log('='.repeat(80));
  console.log('ENROLL REMOTE ROUTER - TERRA CLASSIC → SEPOLIA');
  console.log('='.repeat(80));
  console.log('\nWallet:', sender);
  console.log('Chain ID:', CHAIN_ID);
  console.log('Node:', NODE);
  console.log('Terra Warp Route:', TERRA_WARP);
  console.log('Sepolia Domain:', SEPOLIA_DOMAIN);
  console.log('Sepolia Router (hex):', SEPOLIA_WARP_HEX);

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString('28.5uluna'),
  });

  console.log('✓ Connected to node\n');

  // Enroll remote router
  const txHash = await enrollRemoteRouter(
    client,
    sender,
    TERRA_WARP,
    parseInt(SEPOLIA_DOMAIN),
    SEPOLIA_WARP_HEX
  );

  console.log('\n' + '='.repeat(80));
  console.log('✅ REMOTE ROUTER ENROLLED SUCCESSFULLY!');
  console.log('='.repeat(80));
  console.log('\n📋 TRANSACTION:');
  console.log('─'.repeat(80));
  console.log('  • TX Hash:', txHash);
  console.log('  • Domain:', SEPOLIA_DOMAIN, '(Sepolia Testnet)');
  console.log('  • Router:', SEPOLIA_WARP_HEX);
  console.log('='.repeat(80) + '\n');
}

main().catch((error) => {
  console.error('\nError executing:', error);
  process.exit(1);
});
