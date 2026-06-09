### CRDT 1.1.0

Date: _2026-06-02_

Alire release with packaging fixes and platform compatibility improvements.

## New Features

None.

## Changes

### Alire deployment fixes

Fixed `alr publish` workflow to correctly register the crate in the
community index.

### Makefile automation

Updated `Makefile` with `release`, `publish`, and `test-publish` targets.

### Toolchain validation

Verified build on `gnatprove >= 15.1.0` and `gnatdoc >= 26.0.0`.

### Protocol stability

No API or wire-format changes from 1.0.0.

## Migration from 1.0.0

- No migration needed; this is a drop-in replacement.

## Proof Results

No SPARK proof changes from 1.0.0. Proof results not tracked.

## Breaking Changes

None. The public API is fully backward-compatible with CRDT >= 1.0.0.
