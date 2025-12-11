import { Command } from 'commander';
import { Container } from 'inversify';
import {
  Account,
  Chain,
  Hex,
  PublicClient,
  Transport,
  WalletClient,
  createPublicClient,
  createWalletClient,
  http,
} from 'viem';
import { mnemonicToAccount, privateKeyToAccount } from 'viem/accounts';
import { sepolia, bscTestnet } from 'viem/chains';

export class Dependencies {
  account: Account;
  provider: {
    query: PublicClient<Transport, Chain>;
    exec: WalletClient<Transport, Chain, Account>;
  };
}

export const CONTAINER = new Container({
  autoBindInjectable: true,
  defaultScope: 'Singleton',
});

export async function injectDependencies(cmd: Command): Promise<void> {
  const { privateKey, mnemonic, endpoint } = cmd.optsWithGlobals();

  if (privateKey && mnemonic) {
    throw new Error('Cannot specify both private key and mnemonic');
  } else if (!privateKey && !mnemonic) {
    throw new Error('Must specify either private key or mnemonic');
  }

  const account = mnemonic
    ? mnemonicToAccount(mnemonic)
    : privateKeyToAccount(privateKey as Hex);

  // Default to Sepolia RPC if no endpoint provided
  // Using PublicNode RPC to avoid timeout issues with rpc.sepolia.org
  // PublicNode is free and reliable: https://ethereum-sepolia-rpc.publicnode.com
  const rpcEndpoint = endpoint || 'https://ethereum-sepolia-rpc.publicnode.com';
  
  // Configure HTTP transport with timeout and retry
  const transport = http(rpcEndpoint, {
    timeout: 30000, // 30 seconds timeout
    retryCount: 3,  // Retry up to 3 times
    retryDelay: 1000, // 1 second between retries
  });

  // Detect chain automatically based on endpoint
  // Query the chain ID from the RPC endpoint
  const tempClient = createPublicClient({
    transport,
  });
  
  let chainId: number;
  try {
    chainId = await tempClient.getChainId();
  } catch (error) {
    console.warn('Failed to detect chain ID, defaulting to Sepolia');
    chainId = 11155111; // Sepolia
  }

  // Select chain based on detected chain ID
  let chain: Chain;
  if (chainId === 97) {
    chain = bscTestnet;
  } else if (chainId === 11155111) {
    chain = sepolia;
  } else {
    // Fallback: create a custom chain definition
    chain = {
      id: chainId,
      name: `Chain ${chainId}`,
      network: `chain-${chainId}`,
      nativeCurrency: {
        name: 'Ether',
        symbol: 'ETH',
        decimals: 18,
      },
      rpcUrls: {
        default: {
          http: [rpcEndpoint],
        },
        public: {
          http: [rpcEndpoint],
        },
      },
    } as Chain;
  }

  const provider = {
    query: createPublicClient({
      chain,
      transport,
    }),
    exec: createWalletClient({
      chain,
      account,
      transport,
    }),
  };

  CONTAINER.bind(Dependencies).toConstantValue({ account, provider });
}
