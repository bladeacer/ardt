# CRDT.Pn_Counters

## Types

### type Counter_Range

```ada
subtype Counter_Range is Natural;
```

### type PN_Counter

```ada
type PN_Counter (Max_Actors : Positive) is private with
Default_Initial_Condition;
```

## Functions

### function Can_Decrement (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `By` | Amount to decrement. |
| `C` | The counter. |

**Returns:** Always True.

### function Can_Increment (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `By` | Amount to increment. |
| `C` | The counter. |

**Returns:** Always True.

### function Value (C : CRDT.Pn_Counters.PN_Counter) return Standard.Integer

| Parameter | Description |
|-----------|-------------|
| `C` | The counter to query. |

**Returns:** Net value (sum P minus sum N).

## Procedures

### procedure Decrement (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range; Actor : CRDT.Core.Replica_Id)

| Parameter | Description |
|-----------|-------------|
| `Actor` | Replica performing the decrement. |
| `By` | Amount to decrement (default 1). |
| `C` | The counter to modify. |

### procedure Increment (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range; Actor : CRDT.Core.Replica_Id)

| Parameter | Description |
|-----------|-------------|
| `Actor` | Replica performing the increment. |
| `By` | Amount to increment (default 1). |
| `C` | The counter to modify. |

### procedure Merge (Target : CRDT.Pn_Counters.PN_Counter; Source : CRDT.Pn_Counters.PN_Counter)

| Parameter | Description |
|-----------|-------------|
| `Source` | Counter to merge from. |
| `Target` | Counter to merge into. |
