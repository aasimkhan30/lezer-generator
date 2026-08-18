import {readFile} from "node:fs/promises"
import {createHash} from "node:crypto"
import {buildParserFile} from "./dist/index.js"
const src = await readFile("./grammars/tsql.grammar","utf8")
const opts = {fileName:"tsql.grammar", moduleStyle:"cjs", includeNames:true}
delete process.env.LEZER_GENERATOR_DISABLE_WASM
let t=Date.now(); const w = buildParserFile(src,opts); console.error("wasm build", ((Date.now()-t)/1000).toFixed(1)+"s")
process.env.LEZER_GENERATOR_DISABLE_WASM="1"
t=Date.now(); const f = buildParserFile(src,opts); console.error("fallback build", ((Date.now()-t)/1000).toFixed(1)+"s")
const h=v=>createHash("sha256").update(Buffer.from(v)).digest("hex")
console.error("parser equal:", h(w.parser)===h(f.parser), "terms equal:", h(w.terms)===h(f.terms))
