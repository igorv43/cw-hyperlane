import { fromBech32, toHex } from "@cosmjs/encoding";

const MAILBOX_BECH32 = "terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm";

function bech32ToHex(bech32Address: string): string {
  try {
    const decoded = fromBech32(bech32Address);
    const hex = toHex(decoded.data);
    return "0x" + hex;
  } catch (error: any) {
    throw new Error(`Erro ao converter: ${error.message}`);
  }
}

function main() {
  console.log("=".repeat(80));
  console.log("🔄 CONVERSÃO BECH32 → HEX");
  console.log("=".repeat(80));
  console.log("\nEndereço Bech32:", MAILBOX_BECH32);
  console.log("");
  
  try {
    const hexAddress = bech32ToHex(MAILBOX_BECH32);
    console.log("✅ Conversão realizada com sucesso!");
    console.log("");
    console.log("=".repeat(80));
    console.log("📋 RESULTADO");
    console.log("=".repeat(80));
    console.log("\nBech32:", MAILBOX_BECH32);
    console.log("Hex:", hexAddress);
    console.log("\n" + "=".repeat(80));
  } catch (error: any) {
    console.error("❌ Erro:", error.message);
    process.exit(1);
  }
}

main();
