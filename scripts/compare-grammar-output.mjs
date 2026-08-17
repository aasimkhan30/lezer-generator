import {createHash} from "node:crypto"
import {readFile} from "node:fs/promises"
import {fileURLToPath} from "node:url"
import path from "node:path"

import {buildParserFile as buildOptimized} from "../dist/index.js"
import {buildParserFile as buildReference} from "lezer-generator-reference"

const grammarDir = fileURLToPath(new URL("../grammars/", import.meta.url))
const grammarFiles = [
  "cpp.grammar",
  "java.grammar",
  "python.grammar",
  "tsql.grammar"
]

function hash(value) {
  return createHash("sha256").update(value).digest("hex")
}

function compareBytes(grammar, output, reference, optimized) {
  const referenceBytes = Buffer.from(reference)
  const optimizedBytes = Buffer.from(optimized)
  if (referenceBytes.equals(optimizedBytes)) return

  const sharedLength = Math.min(referenceBytes.length, optimizedBytes.length)
  let firstDifference = 0
  while (firstDifference < sharedLength &&
         referenceBytes[firstDifference] == optimizedBytes[firstDifference]) {
    firstDifference++
  }

  throw new Error(
    `${grammar} ${output} differs at byte ${firstDifference}: ` +
    `reference ${referenceBytes.length} bytes (${hash(referenceBytes)}), ` +
    `optimized ${optimizedBytes.length} bytes (${hash(optimizedBytes)})`
  )
}

for (const grammarFile of grammarFiles) {
  const source = await readFile(path.join(grammarDir, grammarFile), "utf8")
  const options = {
    fileName: grammarFile,
    moduleStyle: "cjs",
    includeNames: true
  }
  const reference = buildReference(source, options)
  const optimized = buildOptimized(source, options)

  compareBytes(grammarFile, "parser", reference.parser, optimized.parser)
  compareBytes(grammarFile, "terms", reference.terms, optimized.terms)
  console.log(
    `${grammarFile}: parser ${Buffer.byteLength(optimized.parser)} bytes, ` +
    `terms ${Buffer.byteLength(optimized.terms)} bytes`
  )
}

console.log("All grammar outputs are byte-identical.")
