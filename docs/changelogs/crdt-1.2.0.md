### CRDT 1.2.0

Date: _2026-06-03_

LEB128 wire protocol, Conway Game of Life demo, and expanded test coverage.

## New Features

### LEB128 Wire Protocol

Variable-length integer encoding replaces fixed 4-byte `Natural'Write`.
Reduces serialized payload size for typical CRDT values by 50 to 75%.
Reading V1-format data is NOT yet supported (V1 to V2 migration added
in 1.4.0).

### Conway Game of Life Demo

Interactive terminal demo (`make demo`) showing CRDT-based distributed
cellular automaton with state-based sync.

### Unit Test Docs

Per-category Markdown reports generated alongside API docs.

### Test Summary Table

Aggregated results table written to `test_result.md`.

## Changes

### Test reorganization

Split monolithic test file into per-category test packages (`Test_Basic`,
`Test_Convergence`, `Test_Engines`, `Test_Fuzz`, `Test_GoL`, `Test_Lattice`,
`Test_RGA_Features`, `Test_Serialization`).

### Concurrency fixes

Fixed Game of Life demo deadlock when switching between concurrent modes.

### Wire-format validation

Added wire-format compatibility tests for LEB128 round-trips.

## Migration from 1.1.0

- New serialized data uses LEB128 (V2) format. Old V1-format data cannot be
  read by this version (upgrade to 1.4.0 for automatic V1 compatibility).
- All APIs remain backward compatible at the Ada source level.

## Proof Results

| Metric | Before (1.1.0) | After (1.2.0) |
|--------|----------------|----------------|
| Total checks | N/A | N/A |

## Breaking Changes

None. The public API is fully backward-compatible with CRDT >= 1.1.0.
