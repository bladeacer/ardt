### CRDT 1.3.0

Date: _2026-06-03_

Documentation overhaul, improved docstrings, and Game of Life stability fixes.

## New Features

### Doc badge generation

Inline badges in generated docs for SPARK proof coverage and test status.

## Changes

### Docstring improvements

Param/return annotations on all public subprograms, meaningful top-level package
descriptions, and consistent formatting.

### Documentation generation fixes

RST-to-Markdown conversion now handles nested package hierarchies and
cross-references correctly.

### Game of Life fixes

Fixed demo entering infinite loop when switching between concurrent modes under
state-based sync.

### Release packaging

Fixed `alire.toml` release format for community index.

## Migration from 1.2.0

- No API or wire-format changes from 1.2.0.
- Rebuild your project with `alr update crdt` or bump the dependency in `alire.toml`.

## Proof Results

No SPARK proof changes from 1.2.0. Proof results not tracked.

## Breaking Changes

None. The public API is fully backward-compatible with CRDT >= 1.2.0.
