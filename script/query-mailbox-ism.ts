import { CosmWasmClient } from "@cosmjs/cosmwasm-stargate";

const NODE = "https://rpc.luncblaze.com:443";
const ISM_ROUTING = process.env.ISM_ROUTING || "terra1na6ljyf4m5x2u7llfvvxxe2nyq0t8628qyk0vnwu4ttpq86tt0cse47t68";

// Mailboxes conhecidos no testnet
const KNOWN_MAILBOXES = [
  "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf", // Mailbox principal (TESTNET-ARTIFACTS.md)
  "terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm", // Mailbox do contexto (terraclassic.json)
];

async function queryMailboxDefaultISM(client: CosmWasmClient, mailbox: string): Promise<string | null> {
  try {
    const result = await client.queryContractSmart(mailbox, {
      mailbox: { default_ism: {} }
    });
    return result.default_ism || result.ism || null;
  } catch (e: any) {
    return null;
  }
}

async function queryMailboxInfo(client: CosmWasmClient, mailbox: string): Promise<any> {
  try {
    const domain = await client.queryContractSmart(mailbox, {
      mailbox: { domain: {} }
    });
    const owner = await client.queryContractSmart(mailbox, {
      ownable: { get_owner: {} }
    });
    return { domain, owner: owner.owner };
  } catch (e: any) {
    return null;
  }
}

async function main() {
  const client = await CosmWasmClient.connect(NODE);
  
  console.log("=".repeat(80));
  console.log("🔍 VERIFICANDO QUAL MAILBOX USA ESTE ISM ROUTING");
  console.log("=".repeat(80));
  console.log("\nISM Routing:", ISM_ROUTING);
  console.log("");
  
  // Verificar mailboxes conhecidos
  console.log("1️⃣  Verificando mailboxes conhecidos...");
  console.log("");
  
  let found = false;
  for (const mailbox of KNOWN_MAILBOXES) {
    console.log(`   Verificando: ${mailbox}`);
    
    // Verificar se é um mailbox válido
    const info = await queryMailboxInfo(client, mailbox);
    if (!info) {
      console.log("   ❌ Não é um mailbox válido ou erro ao query");
      console.log("");
      continue;
    }
    
    console.log(`   ✅ É um mailbox válido`);
    console.log(`      Domain: ${info.domain}`);
    console.log(`      Owner: ${info.owner}`);
    
    // Verificar default ISM
    const defaultISM = await queryMailboxDefaultISM(client, mailbox);
    if (defaultISM) {
      console.log(`      Default ISM: ${defaultISM}`);
      
      if (defaultISM === ISM_ROUTING) {
        console.log(`   🎯 ENCONTRADO! Este mailbox usa o ISM Routing!`);
        found = true;
        console.log("");
        console.log("=".repeat(80));
        console.log("✅ RESULTADO");
        console.log("=".repeat(80));
        console.log("\nMailbox:", mailbox);
        console.log("Domain:", info.domain);
        console.log("Owner:", info.owner);
        console.log("Default ISM:", defaultISM);
        console.log("\n" + "=".repeat(80));
      } else {
        console.log(`   ⚠️  Default ISM diferente: ${defaultISM}`);
      }
    } else {
      console.log(`   ⚠️  Não foi possível query default ISM`);
    }
    console.log("");
  }
  
  if (!found) {
    console.log("=".repeat(80));
    console.log("⚠️  NENHUM MAILBOX ENCONTRADO");
    console.log("=".repeat(80));
    console.log("\nNenhum dos mailboxes conhecidos está usando este ISM Routing.");
    console.log("\n💡 Possibilidades:");
    console.log("   1. Este ISM Routing ainda não foi configurado como default ISM em nenhum mailbox");
    console.log("   2. O mailbox que usa este ISM Routing não está na lista de conhecidos");
    console.log("   3. Este ISM Routing pode ser usado apenas para rotas específicas (não como default)");
    console.log("\n💡 Para verificar todos os mailboxes, você pode:");
    console.log("   - Verificar no explorer do Terra Classic");
    console.log("   - Verificar nos arquivos de deployment");
    console.log("   - Query manualmente outros endereços de mailbox");
    console.log("\n" + "=".repeat(80));
  }
  
  // Verificar se há outros mailboxes no contexto
  console.log("\n2️⃣  Verificando arquivos de contexto...");
  try {
    const fs = require('fs');
    const contextFile = './context/terraclassic.json';
    if (fs.existsSync(contextFile)) {
      const context = JSON.parse(fs.readFileSync(contextFile, 'utf8'));
      if (context.deployments?.core?.mailbox?.address) {
        const mailboxFromContext = context.deployments.core.mailbox.address;
        console.log(`   Mailbox do contexto: ${mailboxFromContext}`);
        
        if (!KNOWN_MAILBOXES.includes(mailboxFromContext)) {
          console.log(`   ⚠️  Este mailbox não estava na lista! Verificando...`);
          const info = await queryMailboxInfo(client, mailboxFromContext);
          if (info) {
            const defaultISM = await queryMailboxDefaultISM(client, mailboxFromContext);
            if (defaultISM === ISM_ROUTING) {
              console.log(`   🎯 ENCONTRADO! Este mailbox usa o ISM Routing!`);
              console.log("");
              console.log("=".repeat(80));
              console.log("✅ RESULTADO");
              console.log("=".repeat(80));
              console.log("\nMailbox:", mailboxFromContext);
              console.log("Domain:", info.domain);
              console.log("Owner:", info.owner);
              console.log("Default ISM:", defaultISM);
              console.log("\n" + "=".repeat(80));
              found = true;
            }
          }
        }
      }
    }
  } catch (e) {
    // Ignorar erros
  }
}

main().catch(console.error);
