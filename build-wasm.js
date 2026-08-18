import wabtFactory from "wabt"
import {readFileSync, writeFileSync} from "node:fs"

let wabt = await wabtFactory()
let source = readFileSync(new URL("./wasm/can-merge.wat", import.meta.url), "utf8")
let module = wabt.parseWat("can-merge.wat", source)
let {buffer} = module.toBinary({write_debug_names: false})
let output = `export const canMergeWasm = "${Buffer.from(buffer).toString("base64")}"\n`
writeFileSync(new URL("./src/can-merge-wasm-data.ts", import.meta.url), output)
