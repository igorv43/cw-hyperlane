import { DirectSecp256k1Wallet } from '@cosmjs/proto-signing';
import { SigningCosmWasmClient } from '@cosmjs/cosmwasm-stargate';
import { GasPrice } from '@cosmjs/stargate';
import * as fs from 'fs';

// ==============================
// CONFIGURATION - TESTNET
// ==============================
const CHAIN_ID = 'rebel-2';
const NODE = 'https://rpc.luncblaze.com:443';

// GET FROM ENVIRONMENT
const PRIVATE_KEY_HEX =
  process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// IGP Router contract address
const IGP = 'terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9';

// IGP Oracle contract address
const IGP_ORACLE =
  'terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds';

// Domain ID for Sepolia
const DOMAIN_SEPOLIA = 11155111;

// Governance module address
const GOV_MODULE = 'terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n';

// ==============================
// GENERATE GOVERNANCE PROPOSAL
// ==============================
function generateProposal() {
  const proposal = {
    messages: [
      {
        '@type': '/cosmwasm.wasm.v1.MsgExecuteContract',
        sender: GOV_MODULE,
        contract: IGP,
        msg: {
          router: {
            set_routes: {
              set: [
                {
                  domain: DOMAIN_SEPOLIA,
                  route: IGP_ORACLE,
                },
              ],
            },
          },
        },
        funds: [],
      },
    ],
    metadata: 'Configure IGP Router route for Sepolia Testnet',
    deposit: '10000000uluna',
    title: 'Configure IGP Router Route - Sepolia Testnet',
    summary:
      'Proposal to configure IGP Router route for Sepolia Testnet (Domain 11155111) to use IGP Oracle for gas calculations',
    expedited: false,
  };

  // Save proposal JSON
  fs.writeFileSync(
    'proposal-igp-route-sepolia.json',
    JSON.stringify(proposal, null, 2),
  );
  console.log('✅ proposal-igp-route-sepolia.json created successfully!');
  console.log('\n📋 PROPOSAL DETAILS:');
  console.log('─'.repeat(80));
  console.log('Title:', proposal.title);
  console.log('Summary:', proposal.summary);
  console.log('Deposit:', proposal.deposit);
  console.log('\n📝 EXECUTION MESSAGE:');
  console.log('─'.repeat(80));
  console.log('Contract:', IGP);
  console.log('Message:', JSON.stringify(proposal.messages[0].msg, null, 2));
  console.log('\n🚀 COMMAND TO SUBMIT:');
  console.log('─'.repeat(80));
  console.log(
    `terrad tx gov submit-proposal proposal-igp-route-sepolia.json \\
  --from <your-wallet> \\
  --chain-id ${CHAIN_ID} \\
  --gas auto \\
  --gas-adjustment 1.5 \\
  --gas-prices 28.5uluna \\
  --node ${NODE} \\
  -y`,
  );
  console.log('─'.repeat(80));
}

// ==============================
// MAIN
// ==============================
async function main() {
  console.log('='.repeat(80));
  console.log('GENERATE GOVERNANCE PROPOSAL - IGP ROUTE FOR SEPOLIA');
  console.log('='.repeat(80));
  console.log('\n⚠️  IMPORTANTE:');
  console.log('   O IGP Router é controlado pelo governance.');
  console.log('   Esta configuração DEVE ser feita via proposta de governança.');
  console.log('   Owner do IGP Router:', GOV_MODULE);
  console.log('\n📋 CONFIGURATION:');
  console.log('─'.repeat(80));
  console.log('IGP Router:', IGP);
  console.log('IGP Oracle:', IGP_ORACLE);
  console.log('Domain:', DOMAIN_SEPOLIA, '(Sepolia Testnet)');
  console.log('');

  generateProposal();

  console.log('\n💡 NEXT STEPS:');
  console.log('─'.repeat(80));
  console.log('1. Review the generated proposal-igp-route-sepolia.json file');
  console.log('2. Submit the proposal using the command above');
  console.log('3. Vote on the proposal: terrad tx gov vote <PROPOSAL_ID> yes ...');
  console.log('4. Wait for the voting period to end');
  console.log('5. Verify execution by querying the IGP Router:');
  console.log(
    `   terrad query wasm contract-state smart ${IGP} '{"router":{"get_route":{"domain":${DOMAIN_SEPOLIA}}}}' --chain-id ${CHAIN_ID} --node ${NODE}`,
  );
  console.log('='.repeat(80) + '\n');
}

main().catch((error) => {
  console.error('\nError executing:', error);
  process.exit(1);
});
