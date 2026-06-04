# CRDT.HLC

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

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
| `Left` |  |
| `Right` |  |

### function "=" (Left : CRDT.HLC.HLC_Time; Right : CRDT.HLC.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function ">" (Left : CRDT.HLC.HLC_Time; Right : CRDT.HLC.HLC_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function Create (Node : CRDT.Core.Replica_Id) return CRDT.HLC.Instance

| Parameter | Description |
|-----------|-------------|
| `Node` |  |

### function Now (Clock : CRDT.HLC.Instance) return CRDT.HLC.HLC_Time

| Parameter | Description |
|-----------|-------------|
| `Clock` |  |

## Procedures

### procedure Recv (Clock : CRDT.HLC.Instance; Remote : CRDT.HLC.HLC_Time)

| Parameter | Description |
|-----------|-------------|
| `Clock` |  |
| `Remote` |  |

### procedure Tick (Clock : CRDT.HLC.Instance)

| Parameter | Description |
|-----------|-------------|
| `Clock` |  |
