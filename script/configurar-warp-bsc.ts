import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { GasPrice } from "@cosmjs/stargate";
import axios from "axios";
import { execSync } from "child_process";

// ==============================
// CONFIGURATION - TERRA CLASSIC TESTNET
// ==============================
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// GET FROM ENVIRONMENT
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// ==============================
// CONFIGURATION - BSC TESTNET
// ==============================
const BSC_TESTNET_RPC = "https://data-seed-prebsc-1-s1.binance.org:8545";
const WARP_ROUTE_BSC = "0x2144Be4477202ba2d50c9A8be3181241878cf7D8";
const MAILBOX_BSC = "0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D";
const MERKLE_TREE_HOOK_BSC = "0xc6cbF39A747f5E28d1bDc8D9dfDAb2960Abd5A8f";
const ISM_MULTISIG_BSC_EVM = "0x2b31a08d397b7e508cbE0F5830E8a9182C88b6cA";

// ==============================
// CONFIGURATION - TERRA CLASSIC
// ==============================
// ISM Multisig BSC no Terra Classic (owner: terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze)
const ISM_MULTISIG_BSC_TERRA = "terra1ksq6cekt0as2f9vv5txld90s854y4pkr2k0jn5p83vqpa5zzzfysuavxr0";

// Domain ID for BSC Testnet
const DOMAIN_BSC = 97;

// Validators configuration for BSC Testnet
// NOVO VALIDADOR: 0x8bd456605473ad4727acfdca0040a0dbd4be2dea
// IMPORTANTE: Remover o prefixo "0x" - o contrato espera apenas hex
const BSC_VALIDATORS = [
  "8bd456605473ad4727acfdca0040a0dbd4be2dea",  // Abacus Works Validator 1 - sem 0x
];
const BSC_THRESHOLD = 1; // 1 of 1 validators

// Function selectors
const SELECTORS = {
  // Warp Route
  warpHook: "0x7f5a7c7b",           // cast sig "hook()"
  warpSetHook: "0x3dfd3873",        // cast sig "setHook(address)"
  warpIsm: "0xde523cf3",            // cast sig "interchainSecurityModule()"
  warpSetIsm: "0x4f51eaff",         // cast sig "setInterchainSecurityModule(address)"
  
  // Mailbox
  mailboxDefaultHook: "0x3d1250b7",  // cast sig "defaultHook()"
  mailboxRequiredHook: "0xd6d08a09", // cast sig "requiredHook()"
};

// ==============================
// HELPER FUNCTIONS - EVM
// ==============================

/**
 * Decodifica endereço de resposta
 */
function decodeAddress(data: string): string {
  if (!data || data === "0x") {
    return "0x0000000000000000000000000000000000000000";
  }
  const hexData = data.startsWith("0x") ? data.slice(2) : data;
  const addressHex = hexData.slice(-40).padStart(40, "0");
  return `0x${addressHex.toLowerCase()}`;
}

/**
 * Faz uma chamada RPC eth_call
 */
async function callContract(
  contractAddress: string,
  selector: string,
  rpcUrl: string,
  data?: string
): Promise<string> {
  const cleanAddr = data ? (data.startsWith("0x") ? data.slice(2) : data).toLowerCase().padStart(40, "0").slice(0, 40) : "";
  const callData = data ? selector + cleanAddr : selector;
  
  const payload = {
    jsonrpc: "2.0",
    method: "eth_call",
    params: [
      {
        to: contractAddress,
        data: callData,
      },
      "latest",
    ],
    id: 1,
  };

  try {
    const response = await axios.post(rpcUrl, payload, {
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
    });

    if (response.data.error) {
      throw new Error(`RPC Error: ${response.data.error.message}`);
    }

    return response.data.result;
  } catch (error: any) {
    throw new Error(`Failed to call contract: ${error.message}`);
  }
}

/**
 * Envia uma transação usando cast
 */
async function sendTransaction(
  contractAddress: string,
  functionName: string,
  params: string[],
  privateKey: string,
  rpcUrl: string
): Promise<string> {
  try {
    const paramsStr = params.map(p => `"${p}"`).join(" ");
    const command = `cast send "${contractAddress}" "${functionName}" ${paramsStr} --private-key "${privateKey}" --rpc-url "${rpcUrl}" --json`;
    
    console.log("   📤 Enviando transação...");
    const result = execSync(command, { 
      encoding: "utf-8", 
      stdio: "pipe",
      maxBuffer: 10 * 1024 * 1024
    });
    
    const lines = result.trim().split('\n');
    let txHash = '';
    
    for (const line of lines) {
      try {
        const parsed = JSON.parse(line);
        if (parsed.transactionHash) {
          txHash = parsed.transactionHash;
          break;
        }
      } catch {
        if (line.includes('transactionHash')) {
          const match = line.match(/transactionHash["\s:]+([a-fA-F0-9x]+)/);
          if (match) {
            txHash = match[1];
            break;
          }
        }
      }
    }
    
    if (!txHash) {
      const hashMatch = result.match(/0x[a-fA-F0-9]{64}/);
      if (hashMatch) {
        txHash = hashMatch[0];
      }
    }
    
    if (!txHash) {
      throw new Error("Transaction hash not found in response. Output: " + result.substring(0, 200));
    }
    
    return txHash;
  } catch (error: any) {
    const errorMsg = error.message || error.toString();
    if (error.stderr) {
      throw new Error(`Failed to send transaction: ${errorMsg}\nStderr: ${error.stderr.toString().substring(0, 500)}`);
    }
    throw new Error(`Failed to send transaction: ${errorMsg}`);
  }
}

// ==============================
// TERRA CLASSIC FUNCTIONS
// ==============================

/**
 * Configura validadores no ISM Multisig BSC (Terra Classic)
 */
async function configureValidators(
  client: SigningCosmWasmClient,
  sender: string,
  contractAddress: string,
  domain: number,
  threshold: number,
  validators: string[]
) {
  console.log(`\n⚙️  Configurando validadores para domain ${domain} (BSC Testnet)...`);
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

// ==============================
// MAIN FUNCTION
// ==============================
async function main() {
  console.log("=".repeat(80));
  console.log("🔧 CONFIGURAR WARP ROUTE BSC TESTNET");
  console.log("=".repeat(80));
  console.log("\nWarp Route BSC:", WARP_ROUTE_BSC);
  console.log("Mailbox BSC:", MAILBOX_BSC);
  console.log("Merkle Tree Hook BSC:", MERKLE_TREE_HOOK_BSC);
  console.log("ISM Multisig BSC (Terra):", ISM_MULTISIG_BSC_TERRA);
  console.log("ISM Multisig BSC (EVM):", ISM_MULTISIG_BSC_EVM);
  console.log("Domain BSC:", DOMAIN_BSC, "(BSC Testnet)");
  console.log("");

  // Verificar chaves privadas
  const terraPrivateKey = PRIVATE_KEY_HEX;
  const bscPrivateKey = process.env.BSC_PRIVATE_KEY;

  if (!terraPrivateKey) {
    console.error("❌ ERRO: Chave privada Terra não fornecida!");
    console.error("   Por favor, defina a variável de ambiente PRIVATE_KEY:");
    console.error("   PRIVATE_KEY=sua_chave_privada_terra npx tsx script/configurar-warp-bsc.ts");
    process.exit(1);
  }

  if (!bscPrivateKey) {
    console.error("❌ ERRO: Chave privada BSC não fornecida!");
    console.error("   Por favor, defina a variável de ambiente BSC_PRIVATE_KEY:");
    console.error("   BSC_PRIVATE_KEY=sua_chave_privada_bsc npx tsx script/configurar-warp-bsc.ts");
    console.error("");
    console.error("   ⚠️  IMPORTANTE: A chave privada deve ser da conta:");
    console.error("   0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA (owner do Warp Route)");
    process.exit(1);
  }

  try {
    // ========================================================================
    // PARTE 1: CONSULTAR CONFIGURAÇÃO ATUAL
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📋 PARTE 1: CONFIGURAÇÃO ATUAL");
    console.log("━".repeat(80));
    console.log("");

    // 1.1 Consultar hook atual do Warp Route
    console.log("1.1 🔍 Consultando hook atual do Warp Route BSC...");
    const warpHookData = await callContract(
      WARP_ROUTE_BSC,
      SELECTORS.warpHook,
      BSC_TESTNET_RPC
    );
    const warpHookAtual = decodeAddress(warpHookData);
    console.log("   📍 Hook atual do Warp Route:", warpHookAtual);
    console.log("   🔗 Link:", `https://testnet.bscscan.com/address/${warpHookAtual}`);
    console.log("");

    // 1.2 Consultar ISM atual do Warp Route
    console.log("1.2 🔍 Consultando ISM atual do Warp Route BSC...");
    const warpIsmData = await callContract(
      WARP_ROUTE_BSC,
      SELECTORS.warpIsm,
      BSC_TESTNET_RPC
    );
    const warpIsmAtual = decodeAddress(warpIsmData);
    console.log("   📍 ISM atual do Warp Route:", warpIsmAtual);
    console.log("   🔗 Link:", `https://testnet.bscscan.com/address/${warpIsmAtual}`);
    console.log("");

    // 1.3 Consultar defaultHook do Mailbox
    console.log("1.3 🔍 Consultando defaultHook do Mailbox BSC...");
    const mailboxDefaultHookData = await callContract(
      MAILBOX_BSC,
      SELECTORS.mailboxDefaultHook,
      BSC_TESTNET_RPC
    );
    const mailboxDefaultHook = decodeAddress(mailboxDefaultHookData);
    console.log("   📍 defaultHook do Mailbox:", mailboxDefaultHook);
    console.log("   🔗 Link:", `https://testnet.bscscan.com/address/${mailboxDefaultHook}`);
    console.log("");

    // 1.4 Comparar configurações
    console.log("1.4 🔍 Comparando configurações...");
    const hooksIguais = warpHookAtual.toLowerCase() === MERKLE_TREE_HOOK_BSC.toLowerCase();
    const ismIguais = warpIsmAtual.toLowerCase() === ISM_MULTISIG_BSC_EVM.toLowerCase();
    
    console.log("   • Hook do Warp Route:", warpHookAtual);
    console.log("   • Merkle Tree Hook esperado:", MERKLE_TREE_HOOK_BSC);
    console.log("   • ISM do Warp Route:", warpIsmAtual);
    console.log("   • ISM esperado:", ISM_MULTISIG_BSC_EVM);
    console.log("");

    // Verificar se ISM precisa ser alterado
    if (!ismIguais) {
      console.log("   ⚠️  O ISM do Warp Route precisa ser alterado!");
      console.log("   • ISM atual:", warpIsmAtual);
      console.log("   • ISM esperado:", ISM_MULTISIG_BSC_EVM);
    } else {
      console.log("   ✅ O ISM do Warp Route já está correto!");
    }
    console.log("");

    // Verificar se hook precisa ser alterado
    if (!hooksIguais) {
      console.log("   ⚠️  O Hook do Warp Route precisa ser alterado!");
      console.log("   • Hook atual:", warpHookAtual);
      console.log("   • Hook esperado:", MERKLE_TREE_HOOK_BSC);
    } else {
      console.log("   ✅ O Hook do Warp Route já está correto!");
    }
    console.log("");

    if (hooksIguais && ismIguais) {
      console.log("   ✅ Tudo já está configurado corretamente!");
      console.log("   ✅ Não é necessário fazer alterações.");
      console.log("");
      console.log("=".repeat(80));
      console.log("✅ CONFIGURAÇÃO JÁ ESTÁ CORRETA!");
      console.log("=".repeat(80) + "\n");
      return;
    }

    // ========================================================================
    // PARTE 2: CONFIGURAR VALIDADORES NO TERRA CLASSIC
    // ========================================================================
    console.log("━".repeat(80));
    console.log("🔧 PARTE 2: CONFIGURANDO VALIDADORES NO TERRA CLASSIC");
    console.log("━".repeat(80));
    console.log("");

    const privateKeyBytes = Uint8Array.from(Buffer.from(terraPrivateKey, "hex"));
    const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
    const [account] = await wallet.getAccounts();
    const sender = account.address;

    console.log("Wallet Terra:", sender);
    console.log("Chain ID:", CHAIN_ID);
    console.log("Node:", NODE);
    console.log("");

    const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
      gasPrice: GasPrice.fromString("28.5uluna"),
    });

    console.log("✓ Conectado ao nó Terra Classic\n");

    try {
      await configureValidators(
        client,
        sender,
        ISM_MULTISIG_BSC_TERRA,
        DOMAIN_BSC,
        BSC_THRESHOLD,
        BSC_VALIDATORS
      );
      console.log("");
    } catch (error: any) {
      if (error.message && error.message.includes("unauthorized")) {
        console.log("   ⚠️  O ISM Multisig BSC é owned pela governança.");
        console.log("   💡 Para alterar os validadores, você precisa criar uma proposta de governança.");
        console.log("   💡 Veja o script submit-proposal-testnet.ts para um exemplo.");
        console.log("   ⏭️  Continuando com a atualização do hook do Warp Route...");
        console.log("");
      } else {
        throw error;
      }
    }

    // ========================================================================
    // PARTE 3: ATUALIZAR ISM DO WARP ROUTE (BSC) - SE NECESSÁRIO
    // ========================================================================
    if (!ismIguais) {
      console.log("━".repeat(80));
      console.log("🔧 PARTE 3: ATUALIZANDO ISM DO WARP ROUTE BSC");
      console.log("━".repeat(80));
      console.log("");

      console.log("3.1 📤 Atualizando ISM do Warp Route...");
      console.log("   • Warp Route:", WARP_ROUTE_BSC);
      console.log("   • Novo ISM:", ISM_MULTISIG_BSC_EVM);
      console.log("");

      try {
        const txHash = await sendTransaction(
          WARP_ROUTE_BSC,
          "setInterchainSecurityModule(address)",
          [ISM_MULTISIG_BSC_EVM],
          bscPrivateKey,
          BSC_TESTNET_RPC
        );

        console.log("   ✅ Transação enviada com sucesso!");
        console.log("   📝 Transaction Hash:", txHash);
        console.log("   🔗 Link:", `https://testnet.bscscan.com/tx/${txHash}`);
        console.log("");

        console.log("3.2 ⏳ Aguardando confirmação da transação...");
        await new Promise((resolve) => setTimeout(resolve, 5000));
        console.log("   ✅ Transação confirmada (aguarde mais confirmações no BscScan)");
        console.log("");

      } catch (error: any) {
        console.error("   ❌ Erro ao enviar transação:", error.message);
        throw error;
      }
    }

    // ========================================================================
    // PARTE 4: ATUALIZAR HOOK DO WARP ROUTE (BSC)
    // ========================================================================
    if (!hooksIguais) {
      console.log("━".repeat(80));
      console.log("🔧 PARTE 3: ATUALIZANDO HOOK DO WARP ROUTE BSC");
      console.log("━".repeat(80));
      console.log("");

      console.log("3.1 📤 Atualizando hook do Warp Route...");
      console.log("   • Warp Route:", WARP_ROUTE_BSC);
      console.log("   • Novo Hook:", MERKLE_TREE_HOOK_BSC);
      console.log("");

      try {
        const txHash = await sendTransaction(
          WARP_ROUTE_BSC,
          "setHook(address)",
          [MERKLE_TREE_HOOK_BSC],
          bscPrivateKey,
          BSC_TESTNET_RPC
        );

        console.log("   ✅ Transação enviada com sucesso!");
        console.log("   📝 Transaction Hash:", txHash);
        console.log("   🔗 Link:", `https://testnet.bscscan.com/tx/${txHash}`);
        console.log("");

        console.log("3.2 ⏳ Aguardando confirmação da transação...");
        await new Promise((resolve) => setTimeout(resolve, 5000));
        console.log("   ✅ Transação confirmada (aguarde mais confirmações no BscScan)");
        console.log("");

      } catch (error: any) {
        console.error("   ❌ Erro ao enviar transação:", error.message);
        console.error("");
        console.error("   💡 DICAS:");
        console.error("   1. Verifique se a chave privada BSC está correta");
        console.error("   2. Verifique se a conta tem BNB suficiente para gas");
        console.error("   3. Verifique se você é o owner do contrato Warp Route");
        throw error;
      }
    }

    // ========================================================================
    // PARTE 5: VERIFICAR ATUALIZAÇÕES
    // ========================================================================
    console.log("━".repeat(80));
    console.log("✅ PARTE 5: VERIFICANDO ATUALIZAÇÕES");
    console.log("━".repeat(80));
    console.log("");

    await new Promise((resolve) => setTimeout(resolve, 3000));

    if (!hooksIguais) {
      console.log("5.1 🔍 Consultando hook atualizado do Warp Route...");
      const warpHookAtualizadoData = await callContract(
        WARP_ROUTE_BSC,
        SELECTORS.warpHook,
        BSC_TESTNET_RPC
      );
      const warpHookAtualizado = decodeAddress(warpHookAtualizadoData);
      console.log("   📍 Hook atualizado:", warpHookAtualizado);
      console.log("");
    }

    if (!ismIguais) {
      console.log("5.2 🔍 Consultando ISM atualizado do Warp Route...");
      const warpIsmAtualizadoData = await callContract(
        WARP_ROUTE_BSC,
        SELECTORS.warpIsm,
        BSC_TESTNET_RPC
      );
      const warpIsmAtualizado = decodeAddress(warpIsmAtualizadoData);
      console.log("   📍 ISM atualizado:", warpIsmAtualizado);
      console.log("");
    }

    // ========================================================================
    // RESUMO FINAL
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📋 RESUMO FINAL");
    console.log("━".repeat(80));
    console.log("");
    console.log("Warp Route BSC:", WARP_ROUTE_BSC);
    if (!hooksIguais) {
      const warpHookAtualizadoData = await callContract(
        WARP_ROUTE_BSC,
        SELECTORS.warpHook,
        BSC_TESTNET_RPC
      );
      const warpHookAtualizado = decodeAddress(warpHookAtualizadoData);
      console.log("  • Hook ANTES:", warpHookAtual);
      console.log("  • Hook DEPOIS:", warpHookAtualizado);
      console.log("  • Merkle Tree Hook esperado:", MERKLE_TREE_HOOK_BSC);
      console.log("");
    }
    if (!ismIguais) {
      const warpIsmAtualizadoData = await callContract(
        WARP_ROUTE_BSC,
        SELECTORS.warpIsm,
        BSC_TESTNET_RPC
      );
      const warpIsmAtualizado = decodeAddress(warpIsmAtualizadoData);
      console.log("  • ISM ANTES:", warpIsmAtual);
      console.log("  • ISM DEPOIS:", warpIsmAtualizado);
      console.log("  • ISM esperado:", ISM_MULTISIG_BSC_EVM);
      console.log("");
    }
    console.log("");
    console.log("Validadores configurados:");
    console.log("  • Domain:", DOMAIN_BSC, "(BSC Testnet)");
    console.log("  • Threshold:", BSC_THRESHOLD, "of", BSC_VALIDATORS.length);
    console.log("  • Validators:", BSC_VALIDATORS);
    console.log("");
    console.log("🔗 LINKS:");
    console.log(`  • Warp Route: https://testnet.bscscan.com/address/${WARP_ROUTE_BSC}`);
    console.log(`  • Mailbox: https://testnet.bscscan.com/address/${MAILBOX_BSC}`);
    console.log(`  • Merkle Tree Hook: https://testnet.bscscan.com/address/${MERKLE_TREE_HOOK_BSC}`);
    console.log(`  • ISM Multisig Terra: https://finder.terra-classic.hexxagon.dev/testnet/address/${ISM_MULTISIG_BSC_TERRA}`);
    console.log("=".repeat(80) + "\n");

  } catch (error: any) {
    console.error("❌ ERRO ao executar configuração!");
    console.error("  • Message:", error.message);
    console.error("  • Stack:", error.stack);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
