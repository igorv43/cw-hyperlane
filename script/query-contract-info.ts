import { CosmWasmClient } from "@cosmjs/cosmwasm-stargate";

const NODE = "https://rpc.luncblaze.com:443";
const CONTRACT = process.env.CONTRACT || "terra1na6ljyf4m5x2u7llfvvxxe2nyq0t8628qyk0vnwu4ttpq86tt0cse47t68";
const USER_WALLET = "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze";

async function main() {
  const client = await CosmWasmClient.connect(NODE);
  
  console.log("=".repeat(80));
  console.log("🔍 VERIFICANDO CONTRATO");
  console.log("=".repeat(80));
  console.log("\nContrato:", CONTRACT);
  console.log("Sua Wallet:", USER_WALLET);
  console.log("");
  
  // Query 1: Informações básicas do contrato
  try {
    console.log("1️⃣  Informações do Contrato");
    const contractInfo = await client.getContract(CONTRACT);
    console.log("✅ Code ID:", contractInfo.codeId);
    console.log("✅ Creator:", contractInfo.creator);
    console.log("✅ Label:", contractInfo.label || "N/A");
    console.log("");
  } catch (e: any) {
    console.log("❌ Erro ao obter info do contrato:", e.message);
    console.log("");
  }
  
  // Query 2: Verificar owner (tentar diferentes formatos)
  try {
    console.log("2️⃣  Query: Owner (formato ownable)");
    const owner = await client.queryContractSmart(CONTRACT, {
      ownable: { get_owner: {} }
    });
    console.log("✅ Owner:", owner.owner);
    console.log("✅ É sua wallet?", owner.owner === USER_WALLET ? "SIM ✅" : "NÃO ❌");
    if (owner.owner !== USER_WALLET) {
      console.log("⚠️  Owner diferente da sua wallet!");
      console.log("   Owner atual:", owner.owner);
    }
    console.log("");
  } catch (e: any) {
    console.log("❌ Erro ao query owner (get_owner):", e.message);
    // Tentar formato alternativo
    try {
      console.log("   Tentando formato alternativo...");
      const owner2 = await client.queryContractSmart(CONTRACT, {
        ownable: { owner: {} }
      });
      console.log("✅ Owner (formato alternativo):", owner2.owner);
      console.log("✅ É sua wallet?", owner2.owner === USER_WALLET ? "SIM ✅" : "NÃO ❌");
      console.log("");
    } catch (e2: any) {
      console.log("❌ Também falhou:", e2.message);
      console.log("");
    }
  }
  
  // Query 3: Tentar descobrir o tipo de contrato (ISM)
  try {
    console.log("3️⃣  Query: Module Type (para identificar tipo de contrato)");
    const moduleType = await client.queryContractSmart(CONTRACT, {
      ism: { module_type: {} }
    });
    console.log("✅ Tipo de módulo:", moduleType);
    console.log("");
  } catch (e: any) {
    console.log("ℹ️  Não é um ISM ou não tem module_type");
    console.log("");
  }
  
  // Query 4: Tentar query de configuração (se for ISM Multisig)
  try {
    console.log("4️⃣  Query: Configuração ISM Multisig (Domain Sepolia)");
    const config = await client.queryContractSmart(CONTRACT, {
      multisig_ism: {
        enrolled_validators: {
          domain: 11155111
        }
      }
    });
    console.log("✅ É ISM Multisig!");
    console.log("   Validators:", config.validators?.length || 0);
    console.log("   Threshold:", config.threshold || "N/A");
    if (config.validators && config.validators.length > 0) {
      console.log("   Validators list:");
      config.validators.forEach((v: string, i: number) => {
        console.log(`     [${i + 1}] ${v}`);
      });
    }
    console.log("");
  } catch (e: any) {
    console.log("ℹ️  Não é ISM Multisig ou não tem validators configurados para Sepolia");
    console.log("");
  }
  
  // Query 5: Tentar query de configuração (se for ISM Routing)
  try {
    console.log("5️⃣  Query: Configuração ISM Routing");
    const routing = await client.queryContractSmart(CONTRACT, {
      routing_ism: {
        ism: {
          domain: 11155111
        }
      }
    });
    console.log("✅ É ISM Routing!");
    console.log("   ISM para Sepolia:", routing);
    console.log("");
  } catch (e: any) {
    console.log("ℹ️  Não é ISM Routing ou não tem ISM configurado para Sepolia");
    console.log("");
  }
  
  console.log("=".repeat(80));
  console.log("\n💡 Para verificar outro contrato:");
  console.log("   CONTRACT=<endereço> npx tsx script/query-contract-info.ts");
  console.log("=".repeat(80));
}

main().catch(console.error);
