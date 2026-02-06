import axios from "axios";
import { execSync } from "child_process";

// ==============================
// CONFIGURATION
// ==============================
const SEPOLIA_RPC = "https://1rpc.io/sepolia";
const WARP_ROUTE_SEPOLIA = "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4";
const MAILBOX_SEPOLIA = "0xffaef09b3cd11d9b20d1a19becca54eec2884766";

// Function selectors
const SELECTORS = {
  // Warp Route
  warpHook: "0x7f5a7c7b",           // cast sig "hook()"
  warpSetHook: "0x3dfd3873",        // cast sig "setHook(address)"
  
  // Mailbox
  mailboxDefaultHook: "0x3d1250b7",  // cast sig "defaultHook()"
  mailboxRequiredHook: "0xd6d08a09", // cast sig "requiredHook()"
};

// ==============================
// HELPER FUNCTIONS
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
 * Codifica endereço para chamada de função
 */
function encodeAddress(address: string): string {
  // Remove 0x se presente
  const cleanAddr = address.startsWith("0x") ? address.slice(2) : address;
  // Garante que seja lowercase e tenha 40 caracteres
  const normalized = cleanAddr.toLowerCase().padStart(40, "0").slice(0, 40);
  return normalized;
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
  const callData = data ? selector + encodeAddress(data).slice(2) : selector;
  
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
  newHookAddress: string,
  privateKey: string,
  rpcUrl: string
): Promise<string> {
  try {
    // Usa cast send para enviar a transação
    const command = `cast send "${contractAddress}" "setHook(address)" "${newHookAddress}" --private-key "${privateKey}" --rpc-url "${rpcUrl}" --json`;
    
    console.log("   📤 Enviando transação...");
    const result = execSync(command, { 
      encoding: "utf-8", 
      stdio: "pipe",
      maxBuffer: 10 * 1024 * 1024 // 10MB buffer
    });
    
    // Parse do resultado
    const lines = result.trim().split('\n');
    let txHash = '';
    
    // Procura pela linha com transactionHash
    for (const line of lines) {
      try {
        const parsed = JSON.parse(line);
        if (parsed.transactionHash) {
          txHash = parsed.transactionHash;
          break;
        }
      } catch {
        // Ignora linhas que não são JSON
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
      // Tenta extrair de qualquer formato
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
// MAIN FUNCTION
// ==============================
async function main() {
  console.log("=".repeat(80));
  console.log("🔧 CORRIGIR HOOK DO WARP ROUTE SEPOLIA");
  console.log("=".repeat(80));
  console.log("\nWarp Route:", WARP_ROUTE_SEPOLIA);
  console.log("Mailbox:", MAILBOX_SEPOLIA);
  console.log("RPC URL:", SEPOLIA_RPC);
  console.log("");

  // Verificar se há chave privada
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    console.error("❌ ERRO: Chave privada não fornecida!");
    console.error("   Por favor, defina a variável de ambiente PRIVATE_KEY:");
    console.error("   PRIVATE_KEY=sua_chave_privada npx tsx script/corrigir-hook-warp-sepolia.ts");
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
    console.log("1.1 🔍 Consultando hook atual do Warp Route...");
    const warpHookData = await callContract(
      WARP_ROUTE_SEPOLIA,
      SELECTORS.warpHook,
      SEPOLIA_RPC
    );
    const warpHookAtual = decodeAddress(warpHookData);
    console.log("   📍 Hook atual do Warp Route:", warpHookAtual);
    console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${warpHookAtual}`);
    console.log("");

    // 1.2 Consultar defaultHook do Mailbox
    console.log("1.2 🔍 Consultando defaultHook do Mailbox...");
    const mailboxDefaultHookData = await callContract(
      MAILBOX_SEPOLIA,
      SELECTORS.mailboxDefaultHook,
      SEPOLIA_RPC
    );
    const mailboxDefaultHook = decodeAddress(mailboxDefaultHookData);
    console.log("   📍 defaultHook do Mailbox:", mailboxDefaultHook);
    console.log("   🔗 Link:", `https://sepolia.etherscan.io/address/${mailboxDefaultHook}`);
    console.log("");

    // 1.3 Comparar
    console.log("1.3 🔍 Comparando configurações...");
    const hooksIguais = warpHookAtual.toLowerCase() === mailboxDefaultHook.toLowerCase();
    
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
      console.log("   • Hook do Warp Route:", warpHookAtual);
      console.log("   • defaultHook do Mailbox:", mailboxDefaultHook);
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

    console.log("2.1 📤 Atualizando hook do Warp Route...");
    console.log("   • Warp Route:", WARP_ROUTE_SEPOLIA);
    console.log("   • Novo Hook:", mailboxDefaultHook);
    console.log("");

    try {
      const txHash = await sendTransaction(
        WARP_ROUTE_SEPOLIA,
        mailboxDefaultHook,
        privateKey,
        SEPOLIA_RPC
      );

      console.log("   ✅ Transação enviada com sucesso!");
      console.log("   📝 Transaction Hash:", txHash);
      console.log("   🔗 Link:", `https://sepolia.etherscan.io/tx/${txHash}`);
      console.log("");

      // Aguardar confirmação
      console.log("2.2 ⏳ Aguardando confirmação da transação...");
      await new Promise((resolve) => setTimeout(resolve, 5000)); // Aguarda 5 segundos
      console.log("   ✅ Transação confirmada (aguarde mais confirmações no Etherscan)");
      console.log("");

    } catch (error: any) {
      console.error("   ❌ Erro ao enviar transação:", error.message);
      console.error("");
      console.error("   💡 DICAS:");
      console.error("   1. Verifique se a chave privada está correta");
      console.error("   2. Verifique se a conta tem ETH suficiente para gas");
      console.error("   3. Verifique se você é o owner do contrato Warp Route");
      throw error;
    }

    // ========================================================================
    // PARTE 3: VERIFICAR ATUALIZAÇÃO
    // ========================================================================
    console.log("━".repeat(80));
    console.log("✅ PARTE 3: VERIFICANDO ATUALIZAÇÃO");
    console.log("━".repeat(80));
    console.log("");

    console.log("3.1 🔍 Consultando hook atualizado do Warp Route...");
    
    // Aguardar um pouco mais para garantir que a transação foi processada
    await new Promise((resolve) => setTimeout(resolve, 3000));
    
    const warpHookAtualizadoData = await callContract(
      WARP_ROUTE_SEPOLIA,
      SELECTORS.warpHook,
      SEPOLIA_RPC
    );
    const warpHookAtualizado = decodeAddress(warpHookAtualizadoData);
    
    console.log("   📍 Hook atualizado:", warpHookAtualizado);
    console.log("");

    // Verificar se a atualização foi bem-sucedida
    const atualizacaoOk = warpHookAtualizado.toLowerCase() === mailboxDefaultHook.toLowerCase();
    
    if (atualizacaoOk) {
      console.log("   ✅ SUCESSO! O hook foi atualizado corretamente!");
      console.log("   ✅ O hook do Warp Route agora corresponde ao defaultHook do Mailbox");
    } else {
      console.log("   ⚠️  O hook ainda não foi atualizado.");
      console.log("   💡 Aguarde mais algumas confirmações e verifique novamente.");
      console.log("   💡 Ou verifique a transação no Etherscan para ver se houve algum erro.");
    }
    console.log("");

    // ========================================================================
    // RESUMO FINAL
    // ========================================================================
    console.log("━".repeat(80));
    console.log("📋 RESUMO FINAL");
    console.log("━".repeat(80));
    console.log("");
    console.log("Warp Route:", WARP_ROUTE_SEPOLIA);
    console.log("  • Hook ANTES:", warpHookAtual);
    console.log("  • Hook DEPOIS:", warpHookAtualizado);
    console.log("  • defaultHook do Mailbox:", mailboxDefaultHook);
    console.log("");
    console.log("🔗 LINKS:");
    console.log(`  • Warp Route: https://sepolia.etherscan.io/address/${WARP_ROUTE_SEPOLIA}`);
    console.log(`  • Mailbox: https://sepolia.etherscan.io/address/${MAILBOX_SEPOLIA}`);
    console.log(`  • defaultHook: https://sepolia.etherscan.io/address/${mailboxDefaultHook}`);
    console.log("=".repeat(80) + "\n");

  } catch (error: any) {
    console.error("❌ ERRO ao executar correção!");
    console.error("  • Message:", error.message);
    console.error("  • Stack:", error.stack);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("\nError executing:", error);
  process.exit(1);
});
