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
| `By` |  |
| `C` |  |

### function Can_Increment (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `By` |  |
| `C` |  |

### function Value (C : CRDT.Pn_Counters.PN_Counter) return Standard.Integer

| Parameter | Description |
|-----------|-------------|
| `C` |  |

## Procedures

### procedure Decrement (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range; Actor : CRDT.Core.Replica_Id)

| Parameter | Description |
|-----------|-------------|
| `Actor` |  |
| `By` |  |
| `C` |  |

### procedure Increment (C : CRDT.Pn_Counters.PN_Counter; By : CRDT.Pn_Counters.Counter_Range; Actor : CRDT.Core.Replica_Id)

| Parameter | Description |
|-----------|-------------|
| `Actor` |  |
| `By` |  |
| `C` |  |

### procedure Merge (Target : CRDT.Pn_Counters.PN_Counter; Source : CRDT.Pn_Counters.PN_Counter)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |
