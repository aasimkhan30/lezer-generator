# T-SQL Generator Performance

## Benchmark

Grammar: `/Users/aasim/src/work/vscode-mssql/packages/tsql-language-service/src/syntax/lezer/grammar/tsql.grammar`

Options:

```js
{fileName: "tsql.grammar", moduleStyle: "cjs", includeNames: true}
```

Runtime: Node 24.14.0 with `--max-old-space-size=12288`.

| Metric | npm `@lezer/generator` 1.8.0 | Optimized | Optimized 2 | Optimized 2 vs npm |
| --- | ---: | ---: | ---: | ---: |
| Total generation | 431.8s | 249.5s | 71.43s | 83.5% less time |
| Relative throughput | 1.00x | 1.73x | 6.04x | 504% higher |
| Finish automaton | 400.0s | 217.9s | 36.81s | 90.8% less time |
| Peak RSS | 3.84 GiB | 2.73 GiB | 3.34 GiB | 13.1% lower |
| Final RSS | 3.79 GiB | 2.36 GiB | 1.48 GiB | 61.0% lower |

The Optimized 2 build saves 360.4 seconds per generation relative to the recorded npm run.

Optimized 2 was measured at generator commit `c51536e`. The current grammar
produced 206,652 canonical LR states and different output hashes from the
earlier recorded fixture, so comparisons with the npm and Optimized columns are
directional rather than strictly apples-to-apples.

## Correctness

The npm, clean local `HEAD`, and optimized generators produce identical output:

```text
parser  dcab447a66b8082c527d08bf73e0809b7697eb8f21da9e9797e9ede8d12d4c93  362899 bytes
terms   9cf470ef4c561a74acfb0bf0196508bdab44f0ebb85da944c5b3f8e69dee79ef   28818 bytes
```

The generator test suite passes: 134 tests.

## Phase Results

| Phase | npm | Optimized | Optimized 2 | Priority |
| --- | ---: | ---: | ---: | --- |
| Parse | 0.01s | 0.01s | 0.01s | None |
| Build rules | 0.04s | 0.04s | 0.03s | None |
| Simplify rules | 0.02s | 0.02s | 0.01s | None |
| Build full automaton | 26.22s | 26.57s | 30.00s | Secondary |
| Build token groups | 0.15s | 0.18s | 0.10s | None |
| Finish automaton | 399.99s | 217.92s | 36.81s | Primary |
| Finish states | 5.26s | 4.75s | 4.41s | Low |

`Finish automaton` is 52% of Optimized 2 generation time.

## Implemented

### LR(0)-core hash for initial collapse grouping

`collapseAutomaton` now indexes candidate groups by a hash of `(rule ID, dot position)`. `samePosSet` remains the collision check and insertion order is preserved.

This removes the scan of every existing group for each of the 165,396 canonical LR states.

### Linear goto comparison

`canMerge` now compares sorted goto arrays with two pointers instead of a Cartesian product.

Complexity changes from `O(a * b)` to `O(a + b)`.

### Allocation-free action comparison

The previous `actionsByTerm()` cache retained an object and arrays on every state touched by collapse. On this grammar that materially increased heap use.

The optimized implementation walks the separately sorted shift and reduce segments without retaining per-state term indexes. It preserves the original all-pairs conflict semantics and generated output.

## Suggestion Assessment

| Suggestion | Decision | Reason |
| --- | --- | --- |
| Optimize `closure()` | Defer | Full automaton construction is only 26.6s. Even eliminating it entirely would save 10.6%. Profile before changing it. |
| Index build-time action insertion | Measure first | It belongs to the 26.6s full-automaton phase. Add comparison counters before accepting extra state bookkeeping. |
| Linear goto comparison | Done | It is low risk and directly affects the dominant collapse phase. |
| Hash initial LR(0)-core grouping | Done | It avoids quadratic candidate discovery before collapse. |
| Hash `mergeIdentical()` | Do not pursue | All 15 passes total about 3s. The maximum possible gain is negligible. |
| Optimize rule simplification | Do not pursue | The phase takes 0.02s. |
| Optimize token DFA minimization | Do not pursue | Token groups take 0.18s. |
| Factor large grammar rules | Separate experiment | It may reduce the 165,396-state input, but can change parse trees, recovery, precedence, and incremental reuse. Benchmark corpus compatibility before adopting it. |

## Remaining Work

The next useful work is inside `collapseAutomaton` and `canMerge`, not the other generator phases.

1. Add counters for `canMerge` calls, goto comparisons, action comparisons, group sizes, and `spill` searches.
2. Record a CPU profile for one optimized generation.
3. Optimize only the dominant comparison or spill path shown by that profile.
4. Require identical parser and terms hashes after every change.

A compact per-state action index may outperform repeated segmented scans, but it must avoid the object-per-state memory cost of `actionsByTerm()`. A dense or lazily pooled representation is the most credible next implementation experiment.
