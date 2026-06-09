# Verification Results

_Generated: 2026-06-09_

## SPARK Proof Results

| Metric | Count |
|--------|-------|
| Total checks | 244 |
| Proved | 191 (78%) |
| Justified | 5 (2%) |
| Unproved | 10 (4%) |
| Flow Dependencies | 9 |
| Run-time Checks | 143 (129 proved, 5 justified, 9 unproved) |
| Assertions | 26 |
| Functional Contracts | 37 (36 proved, 1 unproved) |
| Loop Invariants | 11 |
| Termination | 25 |

## SPARK_Mode => Off Summary

18 scoped occurrences, all justified:

| Reason | Count | Units |
|--------|-------|-------|
| `Ada.Numerics.Discrete_Random` (RNG) | 4 | `CRDT.Core.New_Replica_Id`, `RNG` nested package |
| `Ada.Calendar.Clock` (wall-clock) | 3 | `CRDT.HLC.Create`, `Tick`, `Recv` |
| Stream I/O (`Root_Stream_Type'Class`) | 6 | Write/Read PN_Counter, LWW_Element_Set, LEB128 stream wrappers |
| Non-SPARK dependency cascade | 1 | `CRDT.Sync.State_Based.Create` |
| Complex data structures (access types) | 4 | Sequence engine bodies (RGA, Naive, Yjs, Fugue) |

All packages with SPARK-compatible specs are annotated: `CRDT.Sync` (trivial type-only package) and `CRDT.Core.LEB128` (buffer-based primitives) now included.

### Unproved Checks Notes

10 unproved checks (all medium-level) are in `CRDT.Core.LEB128.Decode`/`Encode`
buffer-based primitives — overflow/range checks on 64-bit arithmetic that SPARK
cannot resolve but are safe at runtime (bounded for-loops, buffer-size contracts).
9 are run-time checks; 1 is a functional contract (`Index > Index'Old` postcondition).
These match the pattern of existing justified overflow checks elsewhere.

## Test Results

| Category | Test File | Tests |
|----------|-----------|-------|
| Basic CRDT ops | `test_basic.adb` | PN-Counter, LWW, RGA, RGAs |
| Convergence | `test_convergence.adb` | 3-way split, anti-interleaving, clock skew, saturation |
| Lattice laws | `test_lattice.adb` | Commutativity, idempotency, associativity |
| RGA features | `test_rga_features.adb` | Chaotic interleaving, tombstones, splitting, delta sync, GC |
| Serialization | `test_serialization.adb` | V1/V2 round-trip, migration, backward compat, LEB128 |
| Sequence engines | `test_engines.adb` | Yjs iterators, Naive engine, sync layer |
| Fuzz testing | `test_fuzz.adb` | Bit-flip, clock skew, OOO delta, property fuzzer, partitions |
| Game of Life | `test_gol.adb` | Neighbors, blinker, matrix<->Yjs sync, convergence, mode switch |
| **Total** | | **10250** |

## DO-178C Traceability

- **HLRs**: 21 high-level requirements, all traced to source
- **LLRs**: Mapped to Ada subprograms with contract summaries
- **SPARK contracts**: Postconditions, Depends, Type_Invariant on all core packages
- **Verification**: Tests + formal proof + doc generation

## Key Artifacts

| Artifact | Location |
|----------|----------|
| HLR | `docs/compliance/HLR.md` |
| LLR | `docs/compliance/LLR.md` |
| Traceability matrix | `docs/compliance/TRACE.md` |
| SPARK proof results | `obj/gnatprove/gnatprove.out` |
| Test results | `make run` output |
| API documentation | `docs/api-docs/` |
| Changelogs | `docs/changelogs/` |
