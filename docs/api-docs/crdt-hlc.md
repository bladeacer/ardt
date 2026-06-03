# CRDT.HLC

## Types

### type HLC_Time

```ada
type HLC_Time is new Core.HLC_Time;
```

### type Instance

```ada
type Instance is private;
```

## Functions

### function "<" (Left : CRDT.HLC.HLC_Time; Right : CRDT.HLC.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left HLC timestamp. |
| `Right` | Right HLC timestamp. |

**Returns:** True if Left causally precedes Right.

### function "=" (Left : CRDT.HLC.HLC_Time; Right : CRDT.HLC.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left HLC timestamp. |
| `Right` | Right HLC timestamp. |

**Returns:** True if timestamps are identical.

### function ">" (Left : CRDT.HLC.HLC_Time; Right : CRDT.HLC.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left HLC timestamp. |
| `Right` | Right HLC timestamp. |

**Returns:** True if Left causally follows Right.

### function Create (Node : CRDT.Core.Replica_Id) return CRDT.HLC.Instance

| Parameter | Description |
|-----------|-------------|
| `Node` | Replica identifier. |

**Returns:** Initialized HLC clock.

### function Now (Clock : CRDT.HLC.Instance) return CRDT.HLC.HLC_Time

| Parameter | Description |
|-----------|-------------|
| `Clock` | HLC instance to query. |

**Returns:** Current HLC timestamp.

## Procedures

### procedure Recv (Clock : CRDT.HLC.Instance; Remote : CRDT.HLC.HLC_Time)

| Parameter | Description |
|-----------|-------------|
| `Clock` | Local HLC instance. |
| `Remote` | Timestamp received from a remote peer. |

### procedure Tick (Clock : CRDT.HLC.Instance)

| Parameter | Description |
|-----------|-------------|
| `Clock` | HLC instance to tick. |
