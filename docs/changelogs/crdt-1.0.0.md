### CRDT 1.0.0

Date: _2026-06-02_

Initial stable release.

## New Features

### PN-Counter

Operation-based and merge-idempotent state-based counter.

### LWW-Element-Set

Last-writer-wins set with per-element timestamps.

### Replicated Growable Array (RGA)

Text-sequence CRDT with multiple backend engines (Naive, Yjs, Fugue). Naive
provides a simple array-based engine for small sequences. Yjs implements a
YATA-inspired linked-list engine for collaborative editing. Fugue provides an
undo-capable engine with operation buffers.

### Synchronization Engines

Operation-based (Op-Based) synchronization provides reliable channel sync with
GC and compaction. State-based (State-Based) synchronization enables delta-state
exchange over lossy channels. Hybrid Logical Clock (HLC) provides causal
ordering with physical-clock integration.

### Thread Safety

`Shared_LWW` and `Shared_RGA` serve as protected wrappers for multi-task access.

### Serialization

V1 Protocol implements fixed 4-byte `Natural'Write` encoding for all integer
values (header fields, node IDs, lengths).

### Testing & Verification

8000+ unit tests covering convergence, causality, merge, and GC. GNATprove
SPARK analysis is included with partial proof coverage.

## Changes

None. Initial release.

## Known Issues

- Serialization uses V1 protocol only (fixed-width integers, no auto-detection)
- No fuzz testing
- SPARK_Mode is Off on all package bodies; no preconditions or loop invariants

## Migration

Initial release. No prior versions exist.

## Proof Results

SPARK proof results were not tracked for this version. SPARK_Mode was Off on
all package bodies; preconditions and loop invariants were absent.

## Breaking Changes

None. This is the initial stable baseline.
