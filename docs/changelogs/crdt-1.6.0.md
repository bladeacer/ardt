### CRDT 1.6.0

Date: _2026-06-09_

Demo stability improvements, docstring rendering fix, LEB128 unit tests,
and expanded SPARK coverage.

## New Features

### LEB128 Unit Tests

9 new boundary-case round-trip tests for `CRDT.Core.LEB128.Encode`/`Decode`:
0, 1, 127 (max single byte), 128 (min two bytes), 16383 (max two bytes),
16384 (min three bytes), 2097151 (max three bytes), 2097152 (min four bytes),
Natural'Last.

### SPARK Coverage: CRDT.Sync

`SPARK_Mode` added to `CRDT.Sync` (type-only package with `State_Vector`).
Trivially proved (0 checks).

## Changes

### Demo: mode switch no longer speed-ups

Removed force-unpause (`S.N1.Paused := False` etc.) from the M-key mode
switch handler. Previously each switch burst all 3 nodes into simultaneous
evolution; repeated switches compounded the effect. Now sync happens for
display conversion only — nodes keep their individual pause states.

Removed `S.Gen := 0` from mode switch — the generation counter tracks
actual evolution without jumping back to zero on display-mode change.

### Demo: Yjs-mode refactored to use matrix cells

`Next_Generation` for Yjs mode now computes on matrix cells (`Is_Alive`)
and applies mutations to `Cell_Sets` (same as Matrix mode). Yjs display
rows are rebuilt via `Sync_Yjs_From_Matrix` after each generation.

`Merge_Nodes` for Yjs mode merges matrix cells (`Cell_Sets.Merge`) then
re-syncs Yjs for display. This eliminates the fundamental position-based
interleaving bug where Yjs merge would scramble column-to-character
mapping.

### API docs: @param descriptions now render

`package_to_ads_path` in `tools/rst2md.py` only searched `src/<flat>.ads`
and wrongly resolved subdirectory packages (e.g. `CRDT.Core` to
`src/crdt.ads`). Fixed by walking `src/` subdirectories recursively.
All existing `@param`/`@return` docstrings now appear correctly in the
generated Markdown.

### Test result table alignment

Hardcoded `"PASS    "` (8 chars) replaced with `Ljust("PASS", Sta_W - 2)`
(6 chars), matching the `"Status"` header width.

## Proof Results

| Metric | Before (1.5.0) | After (1.6.0) |
|--------|----------------|----------------|
| Total checks | 217 | 217 |
| Proved | 175 (81%) | 175 (81%) |
| Justified | 5 (2%) | 5 (2%) |
| Unproved | 0 | 0 |
| Functional Contracts | 35 | 35 |
| Assertions | 26 | 26 |
| Loop Invariants | 11 | 11 |

## Test Results

| Metric | Before (1.5.0) | After (1.6.0) |
|--------|----------------|----------------|
| Tests | 10229 | 10250 |
| New tests | | LEB128 round-trip (9) |

## Breaking Changes

None. The public API is fully backward-compatible with CRDT >= 1.4.0.
