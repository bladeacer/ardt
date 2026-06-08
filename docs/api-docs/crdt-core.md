# CRDT.Core

Unique identifier for a replica in the distributed system.

> **Note:** All items in this package are public.

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
| `Left` |  |
| `Right` |  |

### function "=" (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function ">" (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function HLC_Eq (Left : CRDT.Core.HLC_Time; Right : CRDT.Core.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function HLC_Less (Left : CRDT.Core.HLC_Time; Right : CRDT.Core.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function HLC_Max (Left : CRDT.Core.HLC_Time; Right : CRDT.Core.HLC_Time) return CRDT.Core.HLC_Time

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function Lamport_Max (Left : CRDT.Core.Lamport_Time; Right : CRDT.Core.Lamport_Time) return CRDT.Core.Lamport_Time

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function New_Replica_Id return CRDT.Core.Replica_Id

### function VTime_Eq (Left : CRDT.Core.VTime; Right : CRDT.Core.VTime) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function VTime_Leq (Left : CRDT.Core.VTime; Right : CRDT.Core.VTime) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function VTime_Less (Left : CRDT.Core.VTime; Right : CRDT.Core.VTime) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

## Procedures

### procedure VTime_Increment (VT : CRDT.Core.VTime; Idx : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Idx` |  |
| `VT` |  |

### procedure VTime_Merge (Target : CRDT.Core.VTime; Source : CRDT.Core.VTime)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |
