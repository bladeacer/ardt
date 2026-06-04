# CRDT.Bounded

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

## Types

### type Bounded_PN_Counter

```ada
subtype Bounded_PN_Counter is Pn_Counters.PN_Counter;
```
