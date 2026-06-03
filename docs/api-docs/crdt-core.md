# CRDT.Core

## Types

### type HLC_Time

```ada
type HLC_Time is record
Wall : Ada.Calendar.Time;
Node : Replica_Id;
Log  : Natural := 0;
end record;
```

### type Lamport_Time

```ada
type Lamport_Time is record
Stamp : Natural := 0;
Node  : Replica_Id := 1;
end record;
```

### type Replica_Id

```ada
type Replica_Id is new Positive;
```

### type VTime

```ada
type VTime is array (Positive range <>) of Natural with
Default_Component_Value => 0;
```

## Functions

### function "<" (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left operand. |
| `Right` | Right operand. |

**Returns:** True if Left causally precedes Right.

### function "=" (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left operand. |
| `Right` | Right operand. |

**Returns:** True if timestamps are identical.

### function ">" (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left operand. |
| `Right` | Right operand. |

**Returns:** True if Left causally follows Right.

### function HLC_Eq (Left : CRDT.Core.HLC_Time; Right : CRDT.Core.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left HLC timestamp. |
| `Right` | Right HLC timestamp. |

**Returns:** True if timestamps are identical.

### function HLC_Less (Left : CRDT.Core.HLC_Time; Right : CRDT.Core.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left HLC timestamp. |
| `Right` | Right HLC timestamp. |

**Returns:** True if Left causally precedes Right.

### function HLC_Max (Left : CRDT.Core.HLC_Time; Right : CRDT.Core.HLC_Time) return CRDT.Core.HLC_Time

| Parameter | Description |
|-----------|-------------|
| `Left` | First HLC timestamp. |
| `Right` | Second HLC timestamp. |

**Returns:** The causally later timestamp.

### function Lamport_Max (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return CRDT.Core.Lamport_Time

| Parameter | Description |
|-----------|-------------|
| `Left` | First timestamp. |
| `Right` | Second timestamp. |

**Returns:** The causally later timestamp.

### function New_Replica_Id return CRDT.Core.Replica_Id

**Returns:** A fresh Replica_Id not previously returned.

### function VTime_Eq (Left : CRDT.Core.VTime; Right : CRDT.Core.VTime) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left vector clock. |
| `Right` | Right vector clock. |

**Returns:** True if Left and Right are identical.

### function VTime_Leq (Left : CRDT.Core.VTime; Right : CRDT.Core.VTime) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left vector clock. |
| `Right` | Right vector clock. |

**Returns:** True if Left is at or behind Right.

### function VTime_Less (Left : CRDT.Core.VTime; Right : CRDT.Core.VTime) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left vector clock. |
| `Right` | Right vector clock. |

**Returns:** True if Left is strictly behind Right.

## Procedures

### procedure VTime_Increment (VT : CRDT.Core.VTime; Idx : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Idx` | Index of the entry to increment. |
| `VT` | Vector clock to modify. |

### procedure VTime_Merge (Target : CRDT.Core.VTime; Source : CRDT.Core.VTime)

| Parameter | Description |
|-----------|-------------|
| `Source` | Vector clock to merge from. |
| `Target` | Vector clock to update. |
