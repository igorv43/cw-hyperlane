import { ethers } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';

// ==============================
// CONFIGURAÇÃO
// ==============================

const SEPOLIA_RPC = process.env.RPC_URL || 'https://1rpc.io/sepolia';
const PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
const OWNER_ADDRESS = process.env.OWNER_ADDRESS;
const BENEFICIARY_ADDRESS = process.env.BENEFICIARY_ADDRESS;
const WARP_ROUTE = process.env.WARP_ROUTE || '0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4';

// Domain IDs
const TERRA_DOMAIN = 1325;
const SEPOLIA_DOMAIN = 11155111;

// Configurações de Gas (podem ser sobrescritas por variáveis de ambiente)
// Valores atualizados baseados em: LUNC: $0.00003674, ETH: $2,292.94 (03/02/2026)
// Fórmula: exchange_rate = (LUNC_USD / ETH_USD) × 10^18
const TERRA_GAS_PRICE = process.env.TERRA_GAS_PRICE || '38325000000'; // 38.325 uluna
const TERRA_EXCHANGE_RATE = process.env.TERRA_EXCHANGE_RATE || '16020660000000'; // (0.00003674/2292.94)*10^18
const GAS_OVERHEAD = process.env.GAS_OVERHEAD || '200000';

// ==============================
// ABIS DOS CONTRATOS
// ==============================

const STORAGE_GAS_ORACLE_ABI = [
  'constructor()',
  'function setRemoteGasDataConfigs((uint32 remoteDomain, uint128 tokenExchangeRate, uint128 gasPrice)[] _configs) external',
  'function setRemoteGasData((uint32 remoteDomain, uint128 tokenExchangeRate, uint128 gasPrice) _config) external',
  'function getExchangeRateAndGasPrice(uint32 _destinationDomain) external view returns (uint128 tokenExchangeRate, uint128 gasPrice)',
  'function owner() external view returns (address)',
  'function transferOwnership(address newOwner) external',
];

const INTERCHAIN_GAS_PAYMASTER_ABI = [
  'function initialize(address _owner, address _beneficiary) external',
  'function setDestinationGasConfigs((uint32 remoteDomain, address gasOracle, uint96 gasOverhead)[] _configs) external',
  'function setBeneficiary(address _beneficiary) external',
  'function owner() external view returns (address)',
  'function beneficiary() external view returns (address)',
  'function destinationGasConfigs(uint32) external view returns (address gasOracle, uint96 gasOverhead)',
  'function hookType() external pure returns (uint8)',
];

const WARP_ROUTE_ABI = [
  'function setHook(address _hook) external',
  'function hook() external view returns (address)',
  'function owner() external view returns (address)',
];

// ==============================
// BYTECODES DOS CONTRATOS
// ==============================

// Nota: Estes são bytecodes compilados dos contratos Hyperlane
// Em produção, você deve compilar os contratos usando Foundry ou Hardhat
// Para este exemplo, vamos usar uma abordagem simplificada

async function getContractBytecode(contractName: string): Promise<string> {
  // Tentar compilar usando foundry
  const contractsPath = path.join(process.env.HOME || '', 'hyperlane-monorepo/solidity/contracts');
  
  console.log(`⚙️  Compilando ${contractName}...`);
  
  // Esta é uma simplificação - em produção você usaria:
  // forge build ou hardhat compile
  
  // Por enquanto, vamos retornar os bytecodes vazios e avisar o usuário
  console.log(`⚠️  AVISO: Bytecode não incluído neste script.`);
  console.log(`   Para compilar os contratos, execute:`);
  console.log(`   cd ~/hyperlane-monorepo/solidity`);
  console.log(`   forge build`);
  
  return '';
}

// ==============================
// FUNÇÕES AUXILIARES
// ==============================

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function waitForTransaction(tx: ethers.ContractTransactionResponse, description: string) {
  console.log(`⏳ Aguardando confirmação: ${description}...`);
  console.log(`   TX Hash: ${tx.hash}`);
  
  const receipt = await tx.wait();
  
  if (receipt?.status === 1) {
    console.log(`✅ Confirmado! Gas usado: ${receipt.gasUsed.toString()}`);
  } else {
    throw new Error(`❌ Transação falhou: ${description}`);
  }
  
  return receipt;
}

// ==============================
// MAIN
// ==============================

async function main() {
  console.log('='.repeat(80));
  console.log('CRIAR IGP E ASSOCIAR AO WARP ROUTE - SEPOLIA');
  console.log('='.repeat(80));
  console.log('');

  // Validar variáveis de ambiente
  if (!PRIVATE_KEY) {
    console.error('❌ ERROR: Defina SEPOLIA_PRIVATE_KEY como variável de ambiente.');
    console.error('Exemplo: SEPOLIA_PRIVATE_KEY="0x..." npx tsx script/criar-igp-e-associar-warp-sepolia.ts');
    process.exit(1);
  }

  // Conectar ao provider
  console.log('🔗 Conectando ao Sepolia...');
  console.log(`   RPC: ${SEPOLIA_RPC}`);
  
  // Suporte para ethers v5 e v6
  const JsonRpcProvider = ethers.JsonRpcProvider || ethers.providers?.JsonRpcProvider;
  if (!JsonRpcProvider) {
    throw new Error('JsonRpcProvider não encontrado. Verifique a versão do ethers.js');
  }
  
  const provider = new JsonRpcProvider(SEPOLIA_RPC);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  const deployerAddress = await wallet.getAddress();
  
  const ownerAddress = OWNER_ADDRESS || deployerAddress;
  const beneficiaryAddress = BENEFICIARY_ADDRESS || ownerAddress;

  console.log('✅ Conectado!');
  console.log(`   Deployer: ${deployerAddress}`);
  console.log(`   Owner: ${ownerAddress}`);
  console.log(`   Beneficiary: ${beneficiaryAddress}`);
  console.log('');

  // Verificar saldo
  const balance = await provider.getBalance(deployerAddress);
  console.log(`💰 Saldo: ${ethers.formatEther(balance)} ETH`);
  
  if (balance < ethers.parseEther('0.01')) {
    console.warn('⚠️  AVISO: Saldo baixo! Certifique-se de ter ETH suficiente para gas.');
  }
  console.log('');

  console.log('📋 Configuração:');
  console.log(`   Warp Route: ${WARP_ROUTE}`);
  console.log(`   Terra Domain: ${TERRA_DOMAIN}`);
  console.log(`   Terra Gas Price: ${TERRA_GAS_PRICE}`);
  console.log(`   Terra Exchange Rate: ${TERRA_EXCHANGE_RATE}`);
  console.log(`   Gas Overhead: ${GAS_OVERHEAD}`);
  console.log('');

  // ============================================================================
  // PASSO 1: Deploy StorageGasOracle
  // ============================================================================

  console.log('='.repeat(80));
  console.log('🚀 PASSO 1: Deploy StorageGasOracle');
  console.log('='.repeat(80));
  console.log('');

  // Ler bytecode compilado
  // NOTA: Este é um placeholder - você precisa compilar o contrato primeiro
  const storageGasOracleBytecode = await getCompiledBytecode('StorageGasOracle');
  
  if (!storageGasOracleBytecode) {
    console.error('❌ Erro: Não foi possível obter o bytecode do StorageGasOracle');
    console.error('');
    console.error('SOLUÇÃO:');
    console.error('1. Navegue até: ~/hyperlane-monorepo/solidity');
    console.error('2. Execute: forge build');
    console.error('3. Copie o bytecode de: out/StorageGasOracle.sol/StorageGasOracle.json');
    console.error('');
    console.error('Ou use o script de deploy fornecido pelo Hyperlane.');
    process.exit(1);
  }

  const StorageGasOracleFactory = new ethers.ContractFactory(
    STORAGE_GAS_ORACLE_ABI,
    storageGasOracleBytecode,
    wallet
  );

  console.log('📤 Fazendo deploy do StorageGasOracle...');
  const storageGasOracle = await StorageGasOracleFactory.deploy();
  await storageGasOracle.waitForDeployment();
  const storageGasOracleAddress = await storageGasOracle.getAddress();

  console.log('✅ StorageGasOracle deployado!');
  console.log(`   Endereço: ${storageGasOracleAddress}`);
  console.log('');

  // ============================================================================
  // PASSO 2: Configurar Gas Oracle
  // ============================================================================

  console.log('='.repeat(80));
  console.log('⚙️  PASSO 2: Configurar Gas Oracle');
  console.log('='.repeat(80));
  console.log('');

  console.log(`Configurando dados de gas para Terra Classic (domain ${TERRA_DOMAIN})...`);

  const gasConfig = {
    remoteDomain: TERRA_DOMAIN,
    tokenExchangeRate: TERRA_EXCHANGE_RATE,
    gasPrice: TERRA_GAS_PRICE,
  };

  const tx1 = await storageGasOracle.setRemoteGasDataConfigs([gasConfig]);
  await waitForTransaction(tx1, 'Configurar Gas Oracle');
  console.log('');

  // Verificar configuração
  const [exchangeRate, gasPrice] = await storageGasOracle.getExchangeRateAndGasPrice(TERRA_DOMAIN);
  console.log('✅ Configuração verificada:');
  console.log(`   Exchange Rate: ${exchangeRate.toString()}`);
  console.log(`   Gas Price: ${gasPrice.toString()}`);
  console.log('');

  // ============================================================================
  // PASSO 3: Deploy InterchainGasPaymaster
  // ============================================================================

  console.log('='.repeat(80));
  console.log('🚀 PASSO 3: Deploy InterchainGasPaymaster');
  console.log('='.repeat(80));
  console.log('');

  const igpBytecode = await getCompiledBytecode('InterchainGasPaymaster');
  
  if (!igpBytecode) {
    console.error('❌ Erro: Não foi possível obter o bytecode do InterchainGasPaymaster');
    process.exit(1);
  }

  const IGPFactory = new ethers.ContractFactory(
    INTERCHAIN_GAS_PAYMASTER_ABI,
    igpBytecode,
    wallet
  );

  console.log('📤 Fazendo deploy do InterchainGasPaymaster...');
  const igp = await IGPFactory.deploy();
  await igp.waitForDeployment();
  const igpAddress = await igp.getAddress();

  console.log('✅ InterchainGasPaymaster deployado!');
  console.log(`   Endereço: ${igpAddress}`);
  console.log('');

  // Inicializar IGP
  console.log('⚙️  Inicializando IGP...');
  const tx2 = await igp.initialize(ownerAddress, beneficiaryAddress);
  await waitForTransaction(tx2, 'Inicializar IGP');
  console.log('');

  // Configurar destination gas configs
  console.log('⚙️  Configurando destination gas configs...');
  
  const destGasConfig = {
    remoteDomain: TERRA_DOMAIN,
    gasOracle: storageGasOracleAddress,
    gasOverhead: GAS_OVERHEAD,
  };

  const tx3 = await igp.setDestinationGasConfigs([destGasConfig]);
  await waitForTransaction(tx3, 'Configurar destination gas configs');
  console.log('');

  // Verificar configuração
  const [configGasOracle, configGasOverhead] = await igp.destinationGasConfigs(TERRA_DOMAIN);
  console.log('✅ Configuração verificada:');
  console.log(`   Gas Oracle: ${configGasOracle}`);
  console.log(`   Gas Overhead: ${configGasOverhead.toString()}`);
  console.log('');

  // ============================================================================
  // PASSO 4: Associar IGP ao Warp Route
  // ============================================================================

  console.log('='.repeat(80));
  console.log('🔗 PASSO 4: Associar IGP ao Warp Route');
  console.log('='.repeat(80));
  console.log('');

  console.log(`Associando IGP ${igpAddress} ao Warp Route ${WARP_ROUTE}...`);

  const warpRoute = new ethers.Contract(WARP_ROUTE, WARP_ROUTE_ABI, wallet);

  try {
    // Verificar owner do Warp Route
    const warpOwner = await warpRoute.owner();
    console.log(`   Warp Route Owner: ${warpOwner}`);
    
    if (warpOwner.toLowerCase() !== deployerAddress.toLowerCase()) {
      console.warn('⚠️  AVISO: Você não é o owner do Warp Route!');
      console.warn(`   Owner atual: ${warpOwner}`);
      console.warn(`   Seu endereço: ${deployerAddress}`);
      console.warn('   A transação provavelmente falhará.');
      console.log('');
    }

    const tx4 = await warpRoute.setHook(igpAddress);
    await waitForTransaction(tx4, 'Associar IGP ao Warp Route');

    // Verificar
    const currentHook = await warpRoute.hook();
    console.log('✅ Hook verificado:');
    console.log(`   Hook atual: ${currentHook}`);
    console.log('');

  } catch (error: any) {
    console.error('❌ Erro ao associar IGP ao Warp Route:');
    console.error(`   ${error.message}`);
    console.log('');
    console.log('Isso pode acontecer se:');
    console.log('  • Você não é o owner do Warp Route');
    console.log('  • O Warp Route não possui a função setHook');
    console.log('  • O Warp Route usa um padrão diferente');
    console.log('');
    console.log('Tente verificar o contrato do Warp Route e chamar a função apropriada.');
  }

  // ============================================================================
  // RESUMO FINAL
  // ============================================================================

  console.log('');
  console.log('='.repeat(80));
  console.log('✅ PROCESSO CONCLUÍDO!');
  console.log('='.repeat(80));
  console.log('');
  console.log('📋 Endereços dos Contratos:');
  console.log('─'.repeat(80));
  console.log(`StorageGasOracle:         ${storageGasOracleAddress}`);
  console.log(`InterchainGasPaymaster:   ${igpAddress}`);
  console.log(`Warp Route:               ${WARP_ROUTE}`);
  console.log('');
  console.log('📋 Configurações:');
  console.log('─'.repeat(80));
  console.log(`Owner:                    ${ownerAddress}`);
  console.log(`Beneficiary:              ${beneficiaryAddress}`);
  console.log(`Terra Domain:             ${TERRA_DOMAIN}`);
  console.log(`Terra Gas Price:          ${TERRA_GAS_PRICE}`);
  console.log(`Terra Exchange Rate:      ${TERRA_EXCHANGE_RATE}`);
  console.log(`Gas Overhead:             ${GAS_OVERHEAD}`);
  console.log('');
  console.log('💾 Salvando endereços em arquivo...');
  
  const addresses = {
    storageGasOracle: storageGasOracleAddress,
    interchainGasPaymaster: igpAddress,
    warpRoute: WARP_ROUTE,
    owner: ownerAddress,
    beneficiary: beneficiaryAddress,
    configuration: {
      terraDomain: TERRA_DOMAIN,
      terraGasPrice: TERRA_GAS_PRICE,
      terraExchangeRate: TERRA_EXCHANGE_RATE,
      gasOverhead: GAS_OVERHEAD,
    },
    deployedAt: new Date().toISOString(),
    network: 'sepolia',
  };

  const outputPath = path.join(__dirname, '..', 'deployments', 'sepolia-igp.json');
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(addresses, null, 2));

  console.log(`✅ Endereços salvos em: ${outputPath}`);
  console.log('');
  console.log('='.repeat(80));
}

// ==============================
// FUNÇÃO PARA OBTER BYTECODE COMPILADO
// ==============================

async function getCompiledBytecode(contractName: string): Promise<string> {
  try {
    const artifactPath = path.join(
      process.env.HOME || '',
      'hyperlane-monorepo',
      'solidity',
      'out',
      `${contractName}.sol`,
      `${contractName}.json`
    );

    if (fs.existsSync(artifactPath)) {
      const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
      return artifact.bytecode?.object || artifact.bytecode || '';
    }

    console.warn(`⚠️  Artifact não encontrado: ${artifactPath}`);
    console.warn('   Compile os contratos primeiro:');
    console.warn('   cd ~/hyperlane-monorepo/solidity && forge build');
    
    return '';
  } catch (error) {
    console.error(`❌ Erro ao ler artifact: ${error}`);
    return '';
  }
}

// ==============================
// EXECUTAR
// ==============================

main().catch((error) => {
  console.error('\n❌ Erro durante execução:', error);
  process.exit(1);
});
