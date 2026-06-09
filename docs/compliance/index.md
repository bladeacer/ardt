# DO-178C Compliance Artifacts

## Scope

This directory contains planning, requirements, and verification artifacts
for developing CRDT as a DAL-C (Development Assurance Level C) software
component per DO-178C / ED-12C.

## Artifacts

| Artifact | File | Description |
|----------|------|-------------|
| PSAC | `PSAC.md` | Plan for Software Aspects of Certification |
| HLR | `HLR.md` | High-Level Requirements |
| LLR | `LLR.md` | Low-Level Requirements (mapped to Ada packages) |
| Trace | `TRACE.md` | Bidirectional traceability matrix (auto-verified by Makefile) |
| Verification | `VERIFICATION.md` | SPARK proof results, test counts, artifact inventory |
| Verification | `docs/api-docs/*.md` | Generated API documentation |
| Verification | `obj/gnatprove/*.out` | SPARK proof results |
| Verification | test output | Test harness results (`make run`) |

## Verification Summary

- SPARK Gold: Postconditions on all 35 public subprograms
- SPARK Platinum: Depends/Global contracts on all procedures
- 0 unproved checks, 0 medium warnings
- 10218 test cases pass
