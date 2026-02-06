import { DirectSecp256k1Wallet } from "@cosmjs/proto-signing";
import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { GasPrice } from "@cosmjs/stargate";

// ==============================
// CONFIGURATION - TERRA CLASSIC TESTNET
// ==============================
const CHAIN_ID = "rebel-2";
const NODE = "https://rpc.luncblaze.com:443";

// GET FROM ENVIRONMENT
const PRIVATE_KEY_HEX = process.env.PRIVATE_KEY || process.env.TERRA_PRIVATE_KEY || undefined;

// ==============================
// CONTRACT ADDRESSES
// ==============================
const WARP_ROUTE_TERRA = "terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml";
const MAILBOX_TERRA = "terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm";
const OWNER_TERRA = "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze";

// Hook que será configurado (defaultHook do Mailbox)
// Será consultado automaticamente do Mailbox
let TARGET_HOOK: string | null = null;

// ==============================
// HELPER FUNCTIONS
// ==============================

/**
 * Consulta o hook atual do Warp Route
 */
async function queryWarpHook(
  client: SigningCosmWasmClient,
  contractAddress: string
): Promise<string | null> {
  try {
    const result = await client.queryContractSmart(contractAddress, {
      connection: {
        get_hook: {},
      },
    });
    return result.hook || null;
  } catch (error: any) {
    console.error("   ❌ Erro ao consultar hook:", error.message);
    return null;
  }
}

/**
 * Consulta o defaultHook do Mailbox
 */
async function queryMailboxDefaultHook(
  client: SigningCosmWasmClient,
  contractAddress: string
): Promise<string | null> {
  try {
    const result = await client.queryContractSmart(contractAddress, {
      mailbox: {
        default_hook: {},
      },
    });
    return result.default_hook || null;
  } catch (error: any) {
    console.error("   ❌ Erro ao consultar defaultHook:", error.message);
    return null;
  }
}

/**
 * Atualiza o hook do Warp Route
 */
async function setWarpHook(
  client: SigningCosmWasmClient,
  sender: string,
  contractAddress: string,
  hookAddress: string
) {
  console.log(`\n⚙️  Atualizando hook do Warp Route...`);
  console.log("  • Warp Route:", contractAddress);
  console.log("  • Novo Hook:", hookAddress);
  console.log("");

  const msg = {
    connection: {
      set_hook: {
        hook: hookAddress,
      },
    },
  };

  console.log("📋 Mensagem de execução:");
  console.log(JSON.stringify(msg, null, 2));
  console.log("");

  try {
    const result = await client.execute(
      sender,
      contractAddress,
      msg,
      "auto"
    );

    console.log("✅ Hook atualizado com sucesso!");
    console.log("  • TX Hash:", result.transactionHash);
    console.log("  • Gas Used:", result.gasUsed);
    console.log("  • Height:", result.height);
    console.log("\n📋 LINK DA TRANSAÇÃO:");
    console.log(`  https://finder.terra-classic.hexxagon.dev/testnet/tx/${result.transactionHash}`);

    return result;
  } catch (error: any) {
    console.error("❌ ERRO ao atualizar hook!");
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
  console.log("🔧 CONFIGURAR WARP ROUTE TERRA CLASSIC");
  console.log("=".repeat(80));
  console.log("\nWarp Route Terra:", WARP_ROUTE_TERRA);
  console.log("Mailbox Terra:", MAILBOX_TERRA);
  console.log("Owner:", OWNER_TERRA);
  console.log("");

  if (!PRIVATE_KEY_HEX) {
    console.error("❌ ERRO: Chave privada não fornecida!");
    console.error("   Por favor, defina a variável de ambiente PRIVATE_KEY:");
    console.error("   PRIVATE_KEY=sua_chave_privada_hex npx tsx script/configurar-warp-terra-classic.ts");
    process.exit(1);
  }

  // Create wallet
  const privateKeyBytes = Uint8Array.from(Buffer.from(PRIVATE_KEY_HEX, "hex"));
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const sender = account.address;

  console.log("Wallet:", sender);
  console.log("Chain ID:", CHAIN_ID);
  console.log("Node:", NODE);
  console.log("");

  // Verificar se o sender é o owner
  if (sender !== OWNER_TERRA) {
    console.error("❌ ERRO: A conta não é o owner do contrato!");
    console.error("   • Conta atual:", sender);
    console.error("   • Owner esperado:", OWNER_TERRA);
    process.exit(1);
  }

  // Connect client
  const client = await SigningCosmWasmClient.connectWithSigner(NODE, wallet, {
    gasPrice: GasPrice.fromString("28.5uluna"),
  });

  console.log("✓ Conectado ao nó Terra Classic\n");

  try {
    // ========================================================================
    // PARTE 1: CONSULTAR CONFIGURAÇÃO ATUAL
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📋 PARTE 1: CONFIGURAÇÃO ATUAL");
    console.log("━".repeat(80));
    console.log("");

    // 1.1 Consultar hook atual do Warp Route
    console.log("1.1 🔍 Consultando hook atual do Warp Route...");
    const warpHookAtual = await queryWarpHook(client, WARP_ROUTE_TERRA);
    if (warpHookAtual) {
      console.log("   📍 Hook atual do Warp Route:", warpHookAtual);
      console.log("   🔗 Link:", `https://finder.terra-classic.hexxagon.dev/testnet/address/${warpHookAtual}`);
    } else {
      console.log("   📍 Hook atual do Warp Route: (não configurado)");
    }
    console.log("");

    // 1.2 Consultar defaultHook do Mailbox
    console.log("1.2 🔍 Consultando defaultHook do Mailbox...");
    const mailboxDefaultHook = await queryMailboxDefaultHook(client, MAILBOX_TERRA);
    if (mailboxDefaultHook) {
      TARGET_HOOK = mailboxDefaultHook;
      console.log("   📍 defaultHook do Mailbox:", mailboxDefaultHook);
      console.log("   🔗 Link:", `https://finder.terra-classic.hexxagon.dev/testnet/address/${mailboxDefaultHook}`);
    } else {
      console.error("   ❌ Não foi possível consultar o defaultHook do Mailbox!");
      process.exit(1);
    }
    console.log("");

    // 1.3 Comparar
    console.log("1.3 🔍 Comparando configurações...");
    const hooksIguais = warpHookAtual?.toLowerCase() === TARGET_HOOK.toLowerCase();
    
    if (hooksIguais) {
      console.log("   ✅ Os hooks já estão iguais!");
      console.log("   ✅ Não é necessário fazer alterações.");
      console.log("");
      console.log("=".repeat(80));
      console.log("✅ CONFIGURAÇÃO JÁ ESTÁ CORRETA!");
      console.log("=".repeat(80) + "\n");
      return;
    } else {
      console.log("   ⚠️  Os hooks são DIFERENTES!");
      console.log("   • Hook do Warp Route:", warpHookAtual || "(não configurado)");
      console.log("   • defaultHook do Mailbox:", TARGET_HOOK);
      console.log("   💡 Será necessário atualizar o hook do Warp Route.");
      console.log("");
    }

    // ========================================================================
    // PARTE 2: ATUALIZAR HOOK DO WARP ROUTE
    // ========================================================================
    console.log("━".repeat(80));
    console.log("🔧 PARTE 2: ATUALIZANDO HOOK DO WARP ROUTE");
    console.log("━".repeat(80));
    console.log("");

    await setWarpHook(
      client,
      sender,
      WARP_ROUTE_TERRA,
      TARGET_HOOK
    );

    console.log("");

    // ========================================================================
    // PARTE 3: VERIFICAR ATUALIZAÇÃO
    // ========================================================================
    console.log("━".repeat(80));
    console.log("✅ PARTE 3: VERIFICANDO ATUALIZAÇÃO");
    console.log("━".repeat(80));
    console.log("");

    console.log("3.1 🔍 Consultando hook atualizado do Warp Route...");
    
    // Aguardar um pouco para garantir que a transação foi processada
    await new Promise((resolve) => setTimeout(resolve, 3000));
    
    const warpHookAtualizado = await queryWarpHook(client, WARP_ROUTE_TERRA);
    
    if (warpHookAtualizado) {
      console.log("   📍 Hook atualizado:", warpHookAtualizado);
      console.log("");
      
      // Verificar se a atualização foi bem-sucedida
      const atualizacaoOk = warpHookAtualizado.toLowerCase() === TARGET_HOOK.toLowerCase();
      
      if (atualizacaoOk) {
        console.log("   ✅ SUCESSO! O hook foi atualizado corretamente!");
        console.log("   ✅ O hook do Warp Route agora corresponde ao defaultHook do Mailbox");
      } else {
        console.log("   ⚠️  O hook ainda não foi atualizado.");
        console.log("   💡 Aguarde mais algumas confirmações e verifique novamente.");
      }
    } else {
      console.log("   ⚠️  Não foi possível consultar o hook atualizado.");
    }
    console.log("");

    // ========================================================================
    // RESUMO FINAL
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📋 RESUMO FINAL");
    console.log("━".repeat(80));
    console.log("");
    console.log("Warp Route Terra:", WARP_ROUTE_TERRA);
    console.log("  • Hook ANTES:", warpHookAtual || "(não configurado)");
    console.log("  • Hook DEPOIS:", warpHookAtualizado || "(não consultado)");
    console.log("  • defaultHook do Mailbox:", TARGET_HOOK);
    console.log("");
    console.log("🔗 LINKS:");
    console.log(`  • Warp Route: https://finder.terra-classic.hexxagon.dev/testnet/address/${WARP_ROUTE_TERRA}`);
    console.log(`  • Mailbox: https://finder.terra-classic.hexxagon.dev/testnet/address/${MAILBOX_TERRA}`);
    if (TARGET_HOOK) {
      console.log(`  • defaultHook: https://finder.terra-classic.hexxagon.dev/testnet/address/${TARGET_HOOK}`);
    }
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
