### CRDT 1.4.0

Date: _2026-06-04_

Protocol migration, SPARK proof hardening, and fuzz testing.

## New Features

### Protocol Migration: V1 to V2 Auto-Detection

`Read_Header` now transparently detects V1 (fixed 4-byte `Natural'Read`) vs V2
(LEB128) wire formats by inspecting the first 4 header bytes. Users with
existing V1-format serialized data can upgrade without any migration steps.

### Fuzz Testing

10,000+ chaos iterations covering clock skew, out-of-order delivery, partition
merges, and bit-flip injection.

### SPARK Proof Hardening

All package bodies now have `SPARK_Mode => On`. Function preconditions, type
invariants, loop invariants, and postconditions added throughout. Unproved
checks reduced from 36 to 0.

## Changes

### Modularised unit tests

Test runner split from a monolithic 2728-line file into `CRDT.Test_Support`
and 8 group packages with an auto-counted summary table.

### Source reorganization

Flat `src/` restructured into `core/`, `sequences/`, `sync/`, `serialization/`,
and `tests/` subdirectories.

### Test docs excluded

`make api-docs` strips test package documentation and corresponding index links.

### SPARK_Mode Restructuring

Removed factored `SPARK_Mode => Off` from all non-test body packages; remaining
Off annotations are scoped to individual subprograms using RNG or wall-clock time.

## Wire-Format Migration Guide

If you have existing serialized data written by CRDT <= 1.2.0 (V1 protocol):

1. Reading is automatic: `Read_Header` detects V1 vs V2 and dispatches
`Read_Natural` accordingly. Your existing reader code requires zero changes.
2. Writing: The library always writes V2 (LEB128). If you need to write V1 for
compatibility with older readers, use `CRDT.Serialization.Legacy.Read_Natural_V1`
directly (not recommended; upgrade all peers to >= 1.4.0).

See `docs/changelogs/crdt-1.4.0-migration.md` for a worked example.

## Migration from 1.3.0

- V1 protocol data is read transparently; no source-code changes needed.
- All V2 data continues to work unchanged.
- Rebuild your project with `alr update crdt`.

## Proof Results

| Metric | Before (1.3.0) | After (1.4.0) |
|--------|----------------|----------------|
| Total checks | Not tracked | 112 |
| Unproved | N/A | 0 |
| Functional Contracts | N/A | 0 |
| Assertions | N/A | 8 |
| Loop Invariants | N/A | 4 |

## Breaking Changes

None. The public API is fully backward-compatible with CRDT >= 1.3.0.
