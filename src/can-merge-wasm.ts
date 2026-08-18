import {canMergeWasm} from "./can-merge-wasm-data"

export interface CollapseData {
  mapping: readonly number[]
  gotoStart: Int32Array
  gotoTerm: Int32Array
  gotoTarget: Int32Array
  actionStart: Int32Array
  actionSplit: Int32Array
  actionTerm: Int32Array
  actionKind: Int32Array
  actionValue: Int32Array
  actionAux: Int32Array
  depStart: Int32Array
  depIds: Int32Array
  groups: readonly {origin: number, members: readonly number[]}[]
}

export interface WasmCollapse {
  collapse(mapping: number[]): {passes: number, scanned: number, skipped: number}
}

let compiled: WebAssembly.Module | null | undefined

function decodeBase64(value: string) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let padding = value.endsWith("==") ? 2 : value.endsWith("=") ? 1 : 0
  let result = new Uint8Array(value.length / 4 * 3 - padding), out = 0
  for (let i = 0; i < value.length; i += 4) {
    let bits = alphabet.indexOf(value[i]) << 18 |
      alphabet.indexOf(value[i + 1]) << 12 |
      Math.max(0, alphabet.indexOf(value[i + 2])) << 6 |
      Math.max(0, alphabet.indexOf(value[i + 3]))
    result[out++] = bits >> 16
    if (out < result.length) result[out++] = bits >> 8
    if (out < result.length) result[out++] = bits
  }
  return result
}

function compile() {
  if (compiled !== undefined) return compiled
  if (typeof WebAssembly == "undefined") return compiled = null
  try {
    return compiled = new WebAssembly.Module(decodeBase64(canMergeWasm))
  } catch {
    return compiled = null
  }
}

export function createWasmCollapse(data: CollapseData): WasmCollapse | null {
  if (typeof process != "undefined" && process.env.LEZER_GENERATOR_DISABLE_WASM) return null
  let module = compile()
  if (!module) return null

  let stateCount = data.mapping.length
  let groupHead = new Int32Array(stateCount), groupTail = new Int32Array(stateCount)
  let groupLength = new Int32Array(stateCount), groupOrigin = new Int32Array(stateCount)
  let groupVerified = new Int32Array(stateCount), memberNext = new Int32Array(stateCount)
  let memberPrev = new Int32Array(stateCount), mappingEpoch = new Int32Array(stateCount)
  groupHead.fill(-1)
  groupTail.fill(-1)
  memberNext.fill(-1)
  memberPrev.fill(-1)
  for (let i = 0; i < data.groups.length; i++) {
    let group = data.groups[i]
    groupLength[i] = group.members.length
    groupOrigin[i] = group.origin
    if (group.members.length) {
      groupHead[i] = group.members[0]
      groupTail[i] = group.members[group.members.length - 1]
      for (let j = 0; j < group.members.length; j++) {
        let member = group.members[j]
        if (j) memberPrev[member] = group.members[j - 1]
        if (j + 1 < group.members.length) memberNext[member] = group.members[j + 1]
      }
    }
  }
  let meta = new Int32Array([data.groups.length, 1, 0, 0, 0])
  let arrays: readonly (readonly number[] | Int32Array)[] = [
    data.mapping, data.gotoStart, data.gotoTerm, data.gotoTarget,
    data.actionStart, data.actionSplit, data.actionTerm, data.actionKind,
    data.actionValue, data.actionAux, data.depStart, data.depIds,
    groupHead, groupTail, groupLength, groupOrigin, groupVerified,
    memberNext, memberPrev, mappingEpoch, meta
  ]
  let byteLength = arrays.length * 4
  for (let array of arrays) byteLength += array.length * 4
  let memory = new WebAssembly.Memory({initial: Math.ceil(byteLength / 65536)})
  let values = new Int32Array(memory.buffer), offset = arrays.length
  for (let i = 0; i < arrays.length; i++) {
    values[i] = offset * 4
    values.set(arrays[i], offset)
    offset += arrays[i].length
  }

  let instance: WebAssembly.Instance
  try {
    instance = new WebAssembly.Instance(module, {env: {memory}})
  } catch {
    return null
  }
  let collapse = instance.exports.collapse
  if (typeof collapse != "function") return null
  let mappingOffset = values[0] / 4
  let metaOffset = values[20] / 4
  return {
    collapse(mapping) {
      collapse()
      for (let i = 0; i < mapping.length; i++) mapping[i] = values[mappingOffset + i]
      return {
        passes: values[metaOffset + 2],
        scanned: values[metaOffset + 3],
        skipped: values[metaOffset + 4]
      }
    }
  }
}
