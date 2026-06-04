# CRDT.Sync

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

## Types

### type State_Vector

```ada
type State_Vector is array (Positive range <>) of Natural with
Default_Component_Value => 0;
```
